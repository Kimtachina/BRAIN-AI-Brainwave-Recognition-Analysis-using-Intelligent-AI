"""Test ของ emotion_api/tflite_utils.py ด้วย tf และโมเดลปลอม (ไม่ต้องติดตั้ง TensorFlow)"""

import os
from types import SimpleNamespace

from tflite_utils import convert_keras_to_tflite


class FakeModel:
    def __init__(self):
        self.export_dir: str | None = None
        self.dir_existed = False

    def export(self, path):
        self.export_dir = path
        self.dir_existed = os.path.isdir(path)


class FakeConverter:
    def __init__(self, saved_model_dir):
        self.saved_model_dir = saved_model_dir
        self.optimizations = []

    def convert(self):
        # ไฟล์ SavedModel ต้องยังอยู่ตอนแปลง
        assert os.path.isdir(self.saved_model_dir)
        return b"tflite-bytes"


def fake_tf(created):
    def from_saved_model(path):
        converter = FakeConverter(path)
        created.append(converter)
        return converter

    return SimpleNamespace(lite=SimpleNamespace(
        TFLiteConverter=SimpleNamespace(from_saved_model=from_saved_model)))


def test_exports_saved_model_and_converts():
    created = []
    model = FakeModel()

    result = convert_keras_to_tflite(fake_tf(created), model)

    assert result == b"tflite-bytes"
    assert model.dir_existed
    assert model.export_dir is not None
    assert created[0].saved_model_dir == model.export_dir
    assert not os.path.exists(model.export_dir)  # ลบโฟลเดอร์ชั่วคราวหลังแปลงเสร็จ


def test_configure_runs_before_convert():
    created = []

    convert_keras_to_tflite(fake_tf(created), FakeModel(),
                            lambda c: c.optimizations.append("DEFAULT"))

    assert created[0].optimizations == ["DEFAULT"]
