"""Fixture ร่วมของ test: TensorFlow และ scikit-learn ปลอม

ใช้ทดสอบโค้ดเทรน/แปลงโมเดลได้โดยไม่ต้องติดตั้ง tensorflow หรือ scikit-learn
(requirements-dev.txt ไม่มีสองแพ็กเกจนี้)
"""

import sys
from types import SimpleNamespace

import numpy as np
import pytest


class FakeLayer:
    def __init__(self, *args, **kwargs):
        self.args = args
        self.kwargs = kwargs


class FakeKerasModel:
    """โมเดล Keras ปลอม: จำว่าถูกเรียกอะไรบ้าง และทำนายค่าคงที่ 0.6"""

    def __init__(self, layers=None):
        self.layers = layers or []
        self.input_shape = (None, 7)
        self.output_shape = (None, 1)
        self.compiled = None
        self.fitted = None
        self.exported_to = None

    def compile(self, **kwargs):
        self.compiled = kwargs

    def summary(self):
        print("fake model summary")

    def fit(self, X, y, **kwargs):
        self.fitted = (X, y, kwargs)

    def evaluate(self, X, y, verbose=0):
        return 0.25, 0.9

    def predict(self, X, verbose=0):
        return np.full((len(X), 1), 0.6)

    def save(self, path):
        with open(path, "wb") as f:
            f.write(b"keras")

    def export(self, directory):
        self.exported_to = directory


class FakeConverter:
    def __init__(self):
        self.optimizations = None
        self.target_spec = SimpleNamespace(supported_ops=None)

    def convert(self):
        return b"TFLITE-BYTES"


class FakeInterpreter:
    def __init__(self, model_path):
        self.model_path = model_path

    def allocate_tensors(self):
        pass

    def get_input_details(self):
        return [{"shape": [1, 7], "dtype": "float32"}]

    def get_output_details(self):
        return [{"shape": [1, 1], "dtype": "float32"}]


def make_fake_tf(load_model=None):
    converters = []

    def from_saved_model(_directory):
        converter = FakeConverter()
        converters.append(converter)
        return converter

    tf = SimpleNamespace(
        keras=SimpleNamespace(
            Sequential=FakeKerasModel,
            Input=FakeLayer,
            layers=SimpleNamespace(Dense=FakeLayer, BatchNormalization=FakeLayer, Dropout=FakeLayer),
            optimizers=SimpleNamespace(Adam=FakeLayer),
            callbacks=SimpleNamespace(EarlyStopping=FakeLayer, ReduceLROnPlateau=FakeLayer),
            models=SimpleNamespace(load_model=load_model or (lambda path, compile=False: FakeKerasModel())),
        ),
        lite=SimpleNamespace(
            Optimize=SimpleNamespace(DEFAULT="DEFAULT"),
            OpsSet=SimpleNamespace(TFLITE_BUILTINS="TFLITE_BUILTINS", SELECT_TF_OPS="SELECT_TF_OPS"),
            TFLiteConverter=SimpleNamespace(from_saved_model=from_saved_model),
            Interpreter=FakeInterpreter,
        ),
    )
    tf.converters = converters
    return tf


@pytest.fixture
def fake_tf(monkeypatch):
    """ติดตั้ง tensorflow ปลอมใน sys.modules แล้วคืนตัวมันมาให้ test ตรวจ"""
    tf = make_fake_tf()
    monkeypatch.setitem(sys.modules, "tensorflow", tf)
    return tf


def fake_train_test_split(X, y, test_size=0.2, random_state=None, stratify=None):
    """แบ่งแบบกำหนดได้แน่นอน: ทุกแถวที่ 5 เป็น test"""
    idx = np.arange(len(X))
    test = idx % 5 == 0
    return X[~test], X[test], y[~test], y[test]


@pytest.fixture
def fake_sklearn(monkeypatch):
    model_selection = SimpleNamespace(train_test_split=fake_train_test_split)
    sklearn = SimpleNamespace(model_selection=model_selection)
    monkeypatch.setitem(sys.modules, "sklearn", sklearn)
    monkeypatch.setitem(sys.modules, "sklearn.model_selection", model_selection)
