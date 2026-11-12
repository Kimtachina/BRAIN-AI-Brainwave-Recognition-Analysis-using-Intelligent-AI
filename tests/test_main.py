"""Test ของ emotion_api/main.py: ระบบ rule-based, endpoint ของ API และค่า CORS

ไม่ได้โหลดโมเดล TensorFlow (TestClient ที่ไม่ใช้ `with` จะไม่รัน startup event)
จึงทดสอบเส้นทาง rule-based และ fallback ได้โดยไม่ต้องมีไฟล์โมเดล
"""

import main
import pytest
from fastapi.testclient import TestClient
from main import EMOTION_LABELS_TH, EEGData, predict_with_rules


@pytest.fixture(autouse=True)
def no_model(monkeypatch):
    monkeypatch.setattr(main, "model", None)
    monkeypatch.setattr(main, "scaler", None)
    monkeypatch.setattr(main, "label_encoder", None)


@pytest.fixture
def client():
    return TestClient(main.app)


def eeg(alpha=10.0, beta=10.0, theta=10.0, delta=10.0, gamma=10.0):
    return {"alpha": alpha, "beta": beta, "theta": theta, "delta": delta, "gamma": gamma}


# ---------- predict_with_rules ----------

def test_rules_high_alpha_is_calm():
    result = predict_with_rules(EEGData(**eeg(alpha=60, beta=5, theta=10, delta=10, gamma=5)))
    assert result["emotion_type"] == "calm"
    assert result["confidence"] == 1.0
    assert result["method"] == "rule_based"


def test_rules_high_beta_and_gamma_scores_tension_above_calm():
    result = predict_with_rules(EEGData(**eeg(alpha=5, beta=50, theta=5, delta=5, gamma=35)))
    scores = result["all_scores"]
    assert result["emotion_type"] in {"angry", "stressed", "fearful"}
    assert scores["stressed"] > scores["calm"]


def test_rules_scores_are_normalized_to_max_one():
    result = predict_with_rules(EEGData(**eeg(alpha=12, beta=30, theta=8, delta=20, gamma=4)))
    scores = result["all_scores"]
    assert max(scores.values()) == 1.0
    assert all(0.0 <= v <= 1.0 for v in scores.values())
    assert result["confidence"] == scores[result["emotion_type"]]


def test_rules_all_zero_input_does_not_divide_by_zero():
    result = predict_with_rules(EEGData(**eeg(0, 0, 0, 0, 0)))
    assert result["emotion_type"] in result["all_scores"]
    assert result["confidence"] == 1.0


# ---------- endpoints ----------

@pytest.mark.parametrize("path", ["/", "/health"])
def test_health_reports_no_model_loaded(client, path):
    res = client.get(path)
    assert res.status_code == 200
    assert res.json() == {
        "status": "running",
        "model_loaded": False,
        "scaler_loaded": False,
        "label_encoder_loaded": False,
    }


def test_predict_uses_rules_without_model(client):
    res = client.post("/predict", json=eeg(alpha=60, beta=5, theta=10, delta=10, gamma=5))
    assert res.status_code == 200
    body = res.json()
    assert body["success"] is True
    assert body["method"] == "rule_based"
    assert body["emotion_type"] == "calm"
    assert body["emotion_label_th"] == EMOTION_LABELS_TH["calm"]
    assert body["emoji"] == "😌"


def test_predict_falls_back_to_rules_when_model_fails(client, monkeypatch):
    def broken_model(_features):
        raise RuntimeError("model crashed")

    monkeypatch.setattr(main, "model", object())
    monkeypatch.setattr(main, "predict_with_model", broken_model)

    res = client.post("/predict", json=eeg())
    assert res.status_code == 200
    assert res.json()["method"] == "rule_based_fallback"


def test_predict_uses_model_result_when_available(client, monkeypatch):
    monkeypatch.setattr(main, "model", object())
    monkeypatch.setattr(main, "predict_with_model", lambda _f: {
        "emotion_type": "happy",
        "confidence": 0.9,
        "all_scores": {"happy": 0.9, "sad": 0.1},
        "method": "tsception_model",
    })

    body = client.post("/predict", json=eeg()).json()
    assert body["emotion_type"] == "happy"
    assert body["emotion_label_th"] == "มีความสุข"
    assert body["method"] == "tsception_model"


def test_predict_unknown_label_uses_english_name(client, monkeypatch):
    monkeypatch.setattr(main, "model", object())
    monkeypatch.setattr(main, "predict_with_model", lambda _f: {
        "emotion_type": "bored",
        "confidence": 0.7,
        "all_scores": {"bored": 0.7},
        "method": "tsception_model",
    })

    body = client.post("/predict", json=eeg()).json()
    assert body["emotion_label_th"] == "bored"
    assert body["emoji"] == "😐"


def test_predict_rejects_missing_field(client):
    res = client.post("/predict", json={"alpha": 1, "beta": 1})
    assert res.status_code == 422


def test_batch_rejects_empty_list(client):
    res = client.post("/predict/batch", json={"data": []})
    assert res.status_code == 400


def test_batch_averages_scores(client):
    a = eeg(alpha=60, beta=5, theta=10, delta=10, gamma=5)
    b = eeg(alpha=5, beta=50, theta=5, delta=5, gamma=35)
    expected_a = predict_with_rules(EEGData(**a))["all_scores"]
    expected_b = predict_with_rules(EEGData(**b))["all_scores"]

    body = client.post("/predict/batch", json={"data": [a, b]}).json()

    for k, v in body["all_scores"].items():
        assert v == pytest.approx((expected_a[k] + expected_b[k]) / 2, abs=1e-4)
    assert body["emotion_type"] == max(body["all_scores"], key=lambda k: body["all_scores"][k])
    assert body["method"] == "rule_based"


# ---------- CORS ----------

@pytest.mark.parametrize("origin,allowed", [
    ("http://localhost:5173", True),
    ("http://127.0.0.1:8080", True),
    ("http://localhost", True),
    ("https://evil.example.com", False),
    ("http://localhost.evil.com", False),
])
def test_default_cors_allows_only_localhost(origin, allowed):
    import re
    assert bool(re.match(main.LOCALHOST_ORIGIN_REGEX, origin)) is allowed


def test_predict_returns_500_when_fallback_also_fails(client, monkeypatch):
    def broken(*_args):
        raise RuntimeError("boom")

    monkeypatch.setattr(main, "model", object())
    monkeypatch.setattr(main, "predict_with_model", broken)
    monkeypatch.setattr(main, "predict_with_rules", broken)

    res = client.post("/predict", json=eeg())
    assert res.status_code == 500


def test_batch_uses_model_and_falls_back_per_item(client, monkeypatch):
    calls = []

    def flaky_model(features):
        calls.append(features)
        if len(calls) == 1:
            return {"emotion_type": "happy", "confidence": 1.0,
                    "all_scores": {"happy": 1.0}, "method": "tsception_model"}
        raise RuntimeError("model crashed")

    monkeypatch.setattr(main, "model", object())
    monkeypatch.setattr(main, "predict_with_model", flaky_model)

    body = client.post("/predict/batch", json={"data": [eeg(), eeg(alpha=60)]}).json()
    assert len(calls) == 2
    assert body["method"] == "tsception_model"
    assert body["all_scores"]["happy"] > 0
