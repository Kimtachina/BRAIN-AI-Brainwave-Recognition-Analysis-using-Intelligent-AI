"""Test ของ emotion_api/main.py ส่วนที่ปกติต้องใช้ไฟล์โมเดล (predict_with_model, load_models)
โดยใช้โมเดลปลอมที่เขียนด้วย numpy แทน TensorFlow
"""

import sys
import types

import main
import numpy as np
import pytest

FEATURES = np.array([10.0, 20.0, 5.0, 3.0, 2.0, 50.0, 40.0])


class FakeModel:
    """โมเดลปลอม: เก็บ input ที่ได้รับ แล้วคืนค่า predictions ที่กำหนดไว้"""

    def __init__(self, input_shape, predictions):
        self.input_shape = input_shape
        self._predictions = np.array(predictions, dtype=float)
        self.received: np.ndarray | None = None

    def predict(self, x, verbose=0):
        self.received = x
        return self._predictions

    def last_input(self) -> np.ndarray:
        """input ที่ predict() ได้รับครั้งล่าสุด (ล้มถ้ายังไม่ถูกเรียก)"""
        assert self.received is not None, "predict() was not called"
        return self.received


class FakeLabelEncoder:
    def __init__(self, classes):
        self.classes_ = np.array(classes)


class DoubleScaler:
    def transform(self, x):
        return x * 2


@pytest.fixture(autouse=True)
def reset_globals(monkeypatch):
    monkeypatch.setattr(main, "model", None)
    monkeypatch.setattr(main, "scaler", None)
    monkeypatch.setattr(main, "label_encoder", None)


# ---------- predict_with_model ----------

def test_model_not_loaded_raises():
    with pytest.raises(Exception, match="Model not loaded"):
        main.predict_with_model(FEATURES)


def test_multiclass_with_label_encoder(monkeypatch):
    monkeypatch.setattr(main, "model", FakeModel((None, 7), [[0.1, 0.7, 0.2]]))
    monkeypatch.setattr(main, "label_encoder", FakeLabelEncoder(["calm", "happy", "sad"]))

    result = main.predict_with_model(FEATURES)
    assert result["emotion_type"] == "happy"
    assert result["confidence"] == pytest.approx(0.7)
    assert result["all_scores"] == pytest.approx({"calm": 0.1, "happy": 0.7, "sad": 0.2})
    assert result["method"] == "tsception_model"


def test_multiclass_without_label_encoder_uses_default_labels(monkeypatch):
    monkeypatch.setattr(main, "model", FakeModel((None, 7), [[0.1, 0.2, 0.9]]))

    result = main.predict_with_model(FEATURES)
    assert result["emotion_type"] == main.EMOTION_LABELS[2]
    assert set(result["all_scores"]) == {main.EMOTION_LABELS[i] for i in range(3)}


def test_binary_output(monkeypatch):
    monkeypatch.setattr(main, "model", FakeModel((None, 7), [[0.8]]))
    monkeypatch.setattr(main, "label_encoder", FakeLabelEncoder(["neutral", "stressed"]))

    result = main.predict_with_model(FEATURES)
    assert result["emotion_type"] == "stressed"
    assert result["all_scores"] == pytest.approx({"stressed": 0.8})


def test_binary_output_without_label_encoder(monkeypatch):
    monkeypatch.setattr(main, "model", FakeModel((None, 7), [[0.2]]))
    result = main.predict_with_model(FEATURES)
    assert result["emotion_type"] == main.EMOTION_LABELS[0]


def test_scaler_is_applied_before_predict(monkeypatch):
    fake = FakeModel((None, 7), [[0.5, 0.5]])
    monkeypatch.setattr(main, "model", fake)
    monkeypatch.setattr(main, "scaler", DoubleScaler())

    main.predict_with_model(FEATURES)
    np.testing.assert_allclose(fake.last_input(), (FEATURES * 2).reshape(1, -1))


def test_3d_input_repeats_features_over_time_steps(monkeypatch):
    fake = FakeModel((None, 4, 7), [[0.3, 0.7]])
    monkeypatch.setattr(main, "model", fake)

    main.predict_with_model(FEATURES)
    assert fake.last_input().shape == (1, 4, 7)
    for t in range(4):
        np.testing.assert_allclose(fake.last_input()[0, t], FEATURES)


def test_4d_input_fills_channels(monkeypatch):
    fake = FakeModel((None, 2, 7, 1), [[0.3, 0.7]])
    monkeypatch.setattr(main, "model", fake)

    main.predict_with_model(FEATURES)
    assert fake.last_input().shape == (1, 2, 7, 1)
    np.testing.assert_allclose(fake.last_input()[0, 1, :, 0], FEATURES)


# ---------- load_models ----------

def test_load_models_with_missing_files_keeps_everything_empty(monkeypatch, tmp_path):
    monkeypatch.setitem(sys.modules, "tensorflow", types.ModuleType("tensorflow"))
    monkeypatch.setattr(main, "MODEL_PATH", str(tmp_path / "none.h5"))
    monkeypatch.setattr(main, "SCALER_PATH", str(tmp_path / "none.pkl"))
    monkeypatch.setattr(main, "LABEL_ENCODER_PATH", str(tmp_path / "none2.pkl"))

    main.load_models()
    assert main.model is None
    assert main.scaler is None
    assert main.label_encoder is None


def test_load_models_loads_scaler_and_encoder(monkeypatch, tmp_path):
    monkeypatch.setitem(sys.modules, "tensorflow", types.ModuleType("tensorflow"))
    scaler_file = tmp_path / "scaler.pkl"
    encoder_file = tmp_path / "encoder.pkl"
    scaler_file.write_bytes(b"x")
    encoder_file.write_bytes(b"x")
    monkeypatch.setattr(main, "MODEL_PATH", str(tmp_path / "none.h5"))
    monkeypatch.setattr(main, "SCALER_PATH", str(scaler_file))
    monkeypatch.setattr(main, "LABEL_ENCODER_PATH", str(encoder_file))

    loaded = {str(scaler_file): DoubleScaler(), str(encoder_file): FakeLabelEncoder(["a", "b"])}
    monkeypatch.setattr(main.joblib, "load", lambda path: loaded[path])

    main.load_models()
    assert isinstance(main.scaler, DoubleScaler)
    assert list(main.label_encoder.classes_) == ["a", "b"]


def test_load_models_loads_keras_model(monkeypatch, tmp_path):
    from conftest import make_fake_tf

    monkeypatch.setitem(sys.modules, "tensorflow", make_fake_tf())
    model_file = tmp_path / "model.h5"
    model_file.write_bytes(b"h5")
    monkeypatch.setattr(main, "MODEL_PATH", str(model_file))
    monkeypatch.setattr(main, "SCALER_PATH", str(tmp_path / "none.pkl"))
    monkeypatch.setattr(main, "LABEL_ENCODER_PATH", str(tmp_path / "none2.pkl"))

    main.load_models()
    assert main.model is not None
    assert main.model.input_shape == (None, 7)


def test_load_models_survives_broken_files(monkeypatch, tmp_path):
    def broken(*_args, **_kwargs):
        raise OSError("corrupt")

    from conftest import make_fake_tf

    monkeypatch.setitem(sys.modules, "tensorflow", make_fake_tf(load_model=broken))
    for name in ("MODEL_PATH", "SCALER_PATH", "LABEL_ENCODER_PATH"):
        f = tmp_path / name
        f.write_bytes(b"x")
        monkeypatch.setattr(main, name, str(f))
    monkeypatch.setattr(main.joblib, "load", broken)

    main.load_models()
    assert main.model is None
    assert main.scaler is None
    assert main.label_encoder is None


def test_startup_event_loads_models(monkeypatch):
    import asyncio

    called = []
    monkeypatch.setattr(main, "load_models", lambda: called.append(True))
    asyncio.run(main.startup_event())
    assert called == [True]
