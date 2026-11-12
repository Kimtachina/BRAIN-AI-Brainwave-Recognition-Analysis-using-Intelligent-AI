"""Test ของส่วนเตรียมข้อมูลใน emotion_api/train_depression_model.py (ไม่ต้องใช้ tensorflow)"""

import itertools
import json

import numpy as np
import pandas as pd
import pytest
import train_depression_model as tdm


def write_csv(path, rows):
    pd.DataFrame(rows).to_csv(path, index=False)
    return str(path)


def test_load_basic_csv(tmp_path):
    csv = write_csv(tmp_path / "d.csv", {
        "delta": [1, 2], "theta": [3, 4], "alpha": [5, 6], "beta": [7, 8], "gamma": [9, 10],
        "label": [0, 1],
    })
    X, y, features = tdm.load_and_prepare_data(csv)
    assert features == tdm.FEATURE_COLUMNS
    assert X.shape == (2, 5)
    assert X.dtype == np.float32
    assert y.tolist() == [0.0, 1.0]


def test_load_renames_uppercase_columns_and_label_alias(tmp_path):
    csv = write_csv(tmp_path / "d.csv", {
        "Delta": [1, 2], "Theta": [3, 4], "Alpha": [5, 6], "Beta": [7, 8], "Gamma": [9, 10],
        "target": [1, 0],
    })
    _, y, features = tdm.load_and_prepare_data(csv)
    assert features == tdm.FEATURE_COLUMNS
    assert y.tolist() == [1.0, 0.0]


def test_load_adds_optional_features(tmp_path):
    csv = write_csv(tmp_path / "d.csv", {
        "delta": [1], "theta": [1], "alpha": [1], "beta": [1], "gamma": [1],
        "attention": [50], "label": [0],
    })
    _, _, features = tdm.load_and_prepare_data(csv)
    assert features == tdm.FEATURE_COLUMNS + ["attention"]


def test_load_converts_multiclass_label_to_binary(tmp_path):
    csv = write_csv(tmp_path / "d.csv", {
        "delta": [1, 1, 1], "theta": [1, 1, 1], "alpha": [1, 1, 1], "beta": [1, 1, 1],
        "gamma": [1, 1, 1], "label": [0, 1, 2],
    })
    _, y, _ = tdm.load_and_prepare_data(csv)
    assert y.tolist() == [0.0, 0.0, 1.0]


def test_load_missing_feature_exits(tmp_path):
    csv = write_csv(tmp_path / "d.csv", {"delta": [1], "label": [0]})
    with pytest.raises(SystemExit):
        tdm.load_and_prepare_data(csv)


def test_load_missing_label_exits(tmp_path):
    csv = write_csv(tmp_path / "d.csv", {
        "delta": [1], "theta": [1], "alpha": [1], "beta": [1], "gamma": [1], "foo": [0],
    })
    with pytest.raises(SystemExit):
        tdm.load_and_prepare_data(csv)


def test_scale_features_uses_train_statistics():
    X_train = np.array([[1.0, 5.0], [3.0, 5.0]])
    X_test = np.array([[2.0, 5.0]])
    train_s, test_s, mean, std = tdm.scale_features(X_train, X_test)

    assert mean.tolist() == [2.0, 5.0]
    assert std.tolist() == [1.0, 1.0]  # คอลัมน์ที่ค่าคงที่ (std=0) ถูกแทนด้วย 1 กันหาร 0
    assert train_s.tolist() == [[-1.0, 0.0], [1.0, 0.0]]
    assert test_s.tolist() == [[0.0, 0.0]]


def test_save_scaler_params(tmp_path, monkeypatch):
    out = tmp_path / "scaler.json"
    monkeypatch.setattr(tdm, "OUTPUT_SCALER", str(out))
    tdm.save_scaler_params(np.array([1.0, 2.0]), np.array([0.5, 1.5]), ["alpha", "beta"])

    data = json.loads(out.read_text(encoding="utf-8"))
    assert data["mean"] == [1.0, 2.0]
    assert data["scale"] == [0.5, 1.5]
    assert data["n_features"] == 2
    assert data["feature_names"] == ["alpha", "beta"]


def test_save_label_info_risk_levels_cover_0_to_100(tmp_path, monkeypatch):
    out = tmp_path / "labels.json"
    monkeypatch.setattr(tdm, "OUTPUT_LABELS", str(out))
    tdm.save_label_info()

    levels = json.loads(out.read_text(encoding="utf-8"))["risk_levels"]
    ranges = sorted((v["min"], v["max"]) for v in levels.values())
    assert ranges[0][0] == 0
    assert ranges[-1][1] == 100
    for (_, prev_max), (next_min, _) in itertools.pairwise(ranges):
        assert next_min == prev_max + 1


# ---------- เทรนและแปลงโมเดล (ใช้ tensorflow / scikit-learn ปลอมจาก conftest) ----------

@pytest.fixture
def outputs(monkeypatch, tmp_path):
    """ให้ไฟล์ output ทั้งหมดไปอยู่ใน tmp_path แทน assets/models"""
    paths = {
        "MODELS_DIR": tmp_path,
        "OUTPUT_TFLITE": tmp_path / "depression_model.tflite",
        "OUTPUT_KERAS": tmp_path / "depression_model.keras",
        "OUTPUT_SCALER": tmp_path / "depression_scaler.json",
        "OUTPUT_LABELS": tmp_path / "depression_labels.json",
        "SAMPLE_CSV": tmp_path / "sample.csv",
    }
    for name, path in paths.items():
        monkeypatch.setattr(tdm, name, str(path))
    return paths


def test_build_model_ends_with_single_sigmoid(fake_tf):
    model = tdm.build_model(n_features=5)
    last = model.layers[-1]
    assert last.args == (1,)
    assert last.kwargs["activation"] == "sigmoid"
    assert model.compiled["loss"] == "binary_crossentropy"


@pytest.mark.parametrize("y,expected", [
    ([0, 0, 0, 1], {0: 4 / 6, 1: 2.0}),
    ([1, 1], {0: 1.0, 1: 0.5}),  # คลาสที่ไม่มีข้อมูลได้ 1.0
    ([0, 0], {0: 0.5, 1: 1.0}),
])
def test_compute_class_weight(y, expected):
    weights = tdm.compute_class_weight(np.array(y, dtype=np.float32))
    assert weights == pytest.approx(expected)


@pytest.mark.parametrize("score,level", [
    (0, "ต่ำ"), (28, "ต่ำ"), (28.5, "ปานกลาง"), (48, "ปานกลาง"), (48.1, "สูง"), (100, "สูง"),
])
def test_risk_level_matches_label_file_boundaries(score, level):
    assert tdm.risk_level(score) == level


def test_train_model_fits_with_scaled_data_and_class_weight(fake_tf, fake_sklearn):
    rng = np.random.default_rng(0)
    X = rng.normal(size=(20, 5)).astype(np.float32)
    y = np.array([0, 1] * 10, dtype=np.float32)

    model, mean, std, features, accuracy = tdm.train_model(X, y, tdm.FEATURE_COLUMNS)

    X_fit, _y_fit, kwargs = model.fitted
    assert X_fit.shape == (16, 5)
    np.testing.assert_allclose(X_fit.mean(axis=0), 0, atol=1e-5)
    assert set(kwargs["class_weight"]) == {0, 1}
    assert features == tdm.FEATURE_COLUMNS
    assert accuracy == 0.9
    assert mean.shape == std.shape == (5,)


def test_convert_to_tflite_writes_keras_and_tflite(fake_tf, outputs):
    from conftest import FakeKerasModel

    tdm.convert_to_tflite(FakeKerasModel())
    assert outputs["OUTPUT_KERAS"].read_bytes() == b"keras"
    assert outputs["OUTPUT_TFLITE"].read_bytes() == b"TFLITE-BYTES"
    assert fake_tf.converters[0].optimizations == ["DEFAULT"]


def test_create_sample_dataset_is_balanced_and_non_negative(outputs):
    path = tdm.create_sample_dataset()
    df = pd.read_csv(path)
    assert path == str(outputs["SAMPLE_CSV"])
    assert set(df["label"]) == {0, 1}
    assert (df["label"] == 0).sum() == (df["label"] == 1).sum()
    assert (df[tdm.FEATURE_COLUMNS] >= 0).all().all()


@pytest.mark.parametrize("argv", [["--sample"], []])
def test_main_runs_whole_pipeline_on_sample_data(monkeypatch, fake_tf, fake_sklearn, outputs, argv, capsys):
    monkeypatch.setattr("sys.argv", ["train_depression_model.py", *argv])
    tdm.main()

    for name in ("OUTPUT_TFLITE", "OUTPUT_KERAS", "OUTPUT_SCALER", "OUTPUT_LABELS", "SAMPLE_CSV"):
        assert outputs[name].exists(), name
    scaler = json.loads(outputs["OUTPUT_SCALER"].read_text(encoding="utf-8"))
    assert scaler["feature_names"] == tdm.FEATURE_COLUMNS
    assert "เทรนเสร็จสมบูรณ์" in capsys.readouterr().out


def test_main_uses_given_csv(monkeypatch, fake_tf, fake_sklearn, outputs, tmp_path):
    csv = write_csv(tmp_path / "real.csv", {
        "delta": range(10), "theta": range(10), "alpha": range(10), "beta": range(10), "gamma": range(10),
        "label": [0, 1] * 5,
    })
    monkeypatch.setattr("sys.argv", ["train_depression_model.py", "--csv", csv])
    tdm.main()
    assert not outputs["SAMPLE_CSV"].exists()
    assert outputs["OUTPUT_TFLITE"].exists()
