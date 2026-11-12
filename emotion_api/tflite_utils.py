"""แปลงโมเดล Keras เป็น TFLite ให้ใช้ได้ทั้ง Keras 2 และ Keras 3 (TensorFlow 2.16+)

Keras 3 ใช้ TFLiteConverter.from_keras_model ไม่ได้ จึง export เป็น SavedModel ชั่วคราวก่อน
แล้วแปลงด้วย from_saved_model แทน
"""

import tempfile
from collections.abc import Callable
from typing import Any


def convert_keras_to_tflite(
    tf: Any,
    model: Any,
    configure: Callable[[Any], None] | None = None,
) -> bytes:
    """คืนค่าไบต์ของไฟล์ .tflite

    configure: ฟังก์ชันที่รับ converter ไปตั้งค่าเพิ่ม เช่น optimizations ก่อนแปลง
    """
    with tempfile.TemporaryDirectory() as saved_model_dir:
        model.export(saved_model_dir)
        converter = tf.lite.TFLiteConverter.from_saved_model(saved_model_dir)
        if configure is not None:
            configure(converter)
        return converter.convert()
