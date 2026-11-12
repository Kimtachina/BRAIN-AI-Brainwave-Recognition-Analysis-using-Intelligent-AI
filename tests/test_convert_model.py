"""Test ของ emotion_api/convert_model.py: แปลงโมเดล, scaler และ label encoder ให้ Flutter ใช้"""

import json
import sys
import types

import convert_model
import joblib
import numpy as np
import pytest
from conftest import make_fake_tf


class FakeStandardScaler:
    mean_ = np.array([1.0, 2.0])
    scale_ = np.array([0.5, 0.25])
    var_ = np.array([0.25, 0.0625])
    n_features_in_ = 2


class FakeKMeans:
    classes_ = np.array(["calm", "stressed"])
    cluster_centers_ = np.array([[0.0, 1.0], [1.0, 0.0]])
    n_clusters = 2


def point_convert_paths(monkeypatch, tmp_path):
    src_scaler = tmp_path / "scaler.pkl"
    src_encoder = tmp_path / "encoder.pkl"
    src_scaler.write_bytes(b"x")
    src_encoder.write_bytes(b"x")
    monkeypatch.setattr(convert_model, "SCALER_PATH", str(src_scaler))
    monkeypatch.setattr(convert_model, "LABEL_ENCODER_PATH", str(src_encoder))
    monkeypatch.setattr(convert_model, "OUTPUT_SCALER_JSON", str(tmp_path / "scaler.json"))
    monkeypatch.setattr(convert_model, "OUTPUT_LABELS_JSON", str(tmp_path / "labels.json"))
    return src_scaler, src_encoder


def test_convert_scaler_to_json(monkeypatch, tmp_path):
    point_convert_paths(monkeypatch, tmp_path)
    monkeypatch.setattr(joblib, "load", lambda _path: FakeStandardScaler())

    assert convert_model.convert_scaler_to_json() is True
    data = json.loads((tmp_path / "scaler.json").read_text())
    assert data["mean"] == [1.0, 2.0]
    assert data["scale"] == [0.5, 0.25]
    assert data["n_features"] == 2
    assert data["type"] == "FakeStandardScaler"


def test_convert_label_encoder_to_json(monkeypatch, tmp_path):
    point_convert_paths(monkeypatch, tmp_path)
    monkeypatch.setattr(joblib, "load", lambda _path: FakeKMeans())

    assert convert_model.convert_label_encoder_to_json() is True
    data = json.loads((tmp_path / "labels.json").read_text(encoding="utf-8"))
    assert data["classes"] == ["calm", "stressed"]
    assert data["index_to_label"] == {"0": "calm", "1": "stressed"}
    assert data["label_to_index"] == {"calm": 0, "stressed": 1}
    assert data["n_clusters"] == 2


def test_convert_returns_false_when_source_missing(monkeypatch, tmp_path):
    monkeypatch.setattr(convert_model, "SCALER_PATH", str(tmp_path / "none.pkl"))
    monkeypatch.setattr(convert_model, "LABEL_ENCODER_PATH", str(tmp_path / "none2.pkl"))
    assert convert_model.convert_scaler_to_json() is False
    assert convert_model.convert_label_encoder_to_json() is False


def test_convert_returns_false_when_pickle_is_broken(monkeypatch, tmp_path):
    point_convert_paths(monkeypatch, tmp_path)

    def broken(_path):
        raise ValueError("corrupt file")

    monkeypatch.setattr(joblib, "load", broken)
    assert convert_model.convert_scaler_to_json() is False
    assert convert_model.convert_label_encoder_to_json() is False


def test_convert_h5_returns_false_when_model_missing(monkeypatch, tmp_path):
    monkeypatch.setitem(sys.modules, "tensorflow", types.ModuleType("tensorflow"))
    monkeypatch.setattr(convert_model, "MODEL_PATH", str(tmp_path / "none.h5"))
    assert convert_model.convert_h5_to_tflite() is False


def test_convert_h5_writes_tflite_with_select_ops(monkeypatch, tmp_path, fake_tf):
    model_file = tmp_path / "model.h5"
    model_file.write_bytes(b"h5")
    out = tmp_path / "out.tflite"
    monkeypatch.setattr(convert_model, "MODEL_PATH", str(model_file))
    monkeypatch.setattr(convert_model, "OUTPUT_TFLITE", str(out))

    assert convert_model.convert_h5_to_tflite() is True
    assert out.read_bytes() == b"TFLITE-BYTES"
    converter = fake_tf.converters[0]
    assert converter.optimizations == ["DEFAULT"]
    assert converter.target_spec.supported_ops == ["TFLITE_BUILTINS", "SELECT_TF_OPS"]


def test_convert_h5_returns_false_when_load_fails(monkeypatch, tmp_path):
    def broken(path, compile=False):
        raise OSError("bad h5")

    monkeypatch.setitem(sys.modules, "tensorflow", make_fake_tf(load_model=broken))
    model_file = tmp_path / "model.h5"
    model_file.write_bytes(b"h5")
    monkeypatch.setattr(convert_model, "MODEL_PATH", str(model_file))
    assert convert_model.convert_h5_to_tflite() is False


def test_scaler_params_skips_missing_attributes_and_converts_arrays():
    class MinMax:
        data_min_ = np.array([0.0, 1.0])
        data_max_ = np.array([2.0, 3.0])
        min_ = 0.5

    assert convert_model._scaler_params(MinMax()) == {
        "data_min": [0.0, 1.0],
        "data_max": [2.0, 3.0],
        "min": 0.5,
    }


def test_encoder_without_classes_has_no_class_data():
    assert convert_model._encoder_classes_data(object()) == {}


@pytest.mark.parametrize("results,expected", [
    ((True, True, True), True),
    ((True, False, True), False),
])
def test_main_reports_overall_result(monkeypatch, capsys, results, expected):
    monkeypatch.setattr(convert_model, "convert_h5_to_tflite", lambda: results[0])
    monkeypatch.setattr(convert_model, "convert_scaler_to_json", lambda: results[1])
    monkeypatch.setattr(convert_model, "convert_label_encoder_to_json", lambda: results[2])

    assert convert_model.main() is expected
    out = capsys.readouterr().out
    assert ("แปลงทั้งหมดสำเร็จ" in out) is expected
