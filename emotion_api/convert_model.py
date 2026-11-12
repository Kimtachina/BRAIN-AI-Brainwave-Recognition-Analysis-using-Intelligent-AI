import os
import json

# กำหนดโฟลเดอร์สำหรับเก็บโมเดล โดยอิงตามโฟลเดอร์ assets/models ในฝั่ง Flutter
MODELS_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "models")

# เส้นทางไฟล์ข้อมูลนำเข้า (H5 Model และ PKL สำหรับ Scaler / Label Encoder)
MODEL_PATH = os.path.join(MODELS_DIR, "Emotion_TSception.h5")
SCALER_PATH = os.path.join(MODELS_DIR, "scaler_kmeans.pkl")
LABEL_ENCODER_PATH = os.path.join(MODELS_DIR, "label_encoder_kmeans.pkl")

# เส้นทางไฟล์ผลลัพธ์ที่จะได้จากการแปลงข้อมูล (สำหรับเรียกใช้บนแอปมือถือ Flutter)
OUTPUT_TFLITE = os.path.join(MODELS_DIR, "emotion_model.tflite")
OUTPUT_SCALER_JSON = os.path.join(MODELS_DIR, "scaler_params.json")
OUTPUT_LABELS_JSON = os.path.join(MODELS_DIR, "emotion_labels.json")

# ฟังก์ชันแปลงโมเดล Keras (.h5) ไปเป็น TensorFlow Lite (.tflite) สำหรับใช้งานบน Mobile
def convert_h5_to_tflite():
    print("=" * 50)
    print("📦 แปลง Emotion_TSception.h5 → TFLite")
    print("=" * 50)

    import tensorflow as tf

    # ตรวจสอบว่ามีไฟล์ต้นฉบับหรือไม่
    if not os.path.exists(MODEL_PATH):
        print(f"❌ ไม่พบไฟล์ model: {MODEL_PATH}")
        return False

    try:
        # โหลดโมเดล Keras (.h5) แบบไม่ต้อง Compile เพื่อประหยัดเวลา
        model = tf.keras.models.load_model(MODEL_PATH, compile=False)
        print("✅ โหลด model สำเร็จ")
        print(f"   Input shape:  {model.input_shape}")
        print(f"   Output shape: {model.output_shape}")
        model.summary()

        # แปลงผ่าน SavedModel เพื่อให้ใช้กับ Keras 3 (TensorFlow 2.16+) ได้
        from tflite_utils import convert_keras_to_tflite

        def configure(converter):
            # ตั้งค่าให้เหมาะสมสำหรับการแปลงและบีบอัดโมเดล
            converter.optimizations = [tf.lite.Optimize.DEFAULT]
            # สนับสนุน Operations พื้นฐานและเรียกใช้ Select TF ops เพิ่มเติมกรณีมีมิติซับซ้อน
            converter.target_spec.supported_ops = [
                tf.lite.OpsSet.TFLITE_BUILTINS,
                tf.lite.OpsSet.SELECT_TF_OPS,
            ]
            converter._experimental_lower_tensor_list_ops = False

        tflite_model = convert_keras_to_tflite(tf, model, configure)

        # บันทึกผลลัพธ์ออกมาเป็นไฟล์ .tflite
        with open(OUTPUT_TFLITE, "wb") as f:
            f.write(tflite_model)

        # แสดงขนาดของไฟล์โมเดลสำเร็จรูป
        size_mb = os.path.getsize(OUTPUT_TFLITE) / (1024 * 1024)
        print(f"✅ บันทึก TFLite model: {OUTPUT_TFLITE}")
        print(f"   ขนาด: {size_mb:.2f} MB")

        # ทดสอบโหลดไฟล์โมเดล TFLite เพื่อยืนยันความถูกต้องของมิติข้อมูลขาเข้า/ขาออก
        interpreter = tf.lite.Interpreter(model_path=OUTPUT_TFLITE)
        interpreter.allocate_tensors()
        input_details = interpreter.get_input_details()
        output_details = interpreter.get_output_details()
        print("\n📋 TFLite Model Details:")
        print(f"   Input:  {input_details[0]['shape']} dtype={input_details[0]['dtype']}")
        print(f"   Output: {output_details[0]['shape']} dtype={output_details[0]['dtype']}")

        return True

    except Exception as e:
        print(f"❌ แปลง model ล้มเหลว: {e}")
        import traceback
        traceback.print_exc()
        return False

# แปลง numpy array / ค่า numpy เป็นชนิดข้อมูลที่ json.dump รองรับ
def _to_json_value(value):
    return value.tolist() if hasattr(value, "tolist") else value


# พารามิเตอร์ของ Scaler ที่ส่งออกเป็น JSON: (ชื่อ attribute, ชื่อ key ใน JSON, แสดงบนหน้าจอหรือไม่)
SCALER_ATTRIBUTES = [
    # StandardScaler
    ("mean_", "mean", True),
    ("scale_", "scale", True),
    ("var_", "var", False),
    ("n_features_in_", "n_features", True),
    ("feature_names_in_", "feature_names", True),
    # MinMaxScaler
    ("data_min_", "data_min", False),
    ("data_max_", "data_max", False),
    ("data_range_", "data_range", False),
    ("min_", "min", False),
]


# ดึงพารามิเตอร์ที่ Scaler มี ตามรายการ SCALER_ATTRIBUTES
def _scaler_params(scaler) -> dict:
    params = {}
    for attr, key, show in SCALER_ATTRIBUTES:
        if not hasattr(scaler, attr):
            continue
        value = getattr(scaler, attr)
        params[key] = _to_json_value(value)
        if show:
            print(f"   {key}: {value}")
    return params


# ดึงคลาสการจัดประเภท/ชื่อประเภทอารมณ์ พร้อมชุดเชื่อมโยง Index <-> Label
def _encoder_classes_data(encoder) -> dict:
    if not hasattr(encoder, "classes_"):
        return {}
    classes = _to_json_value(encoder.classes_)
    data = {
        "classes": [str(c) for c in classes],
        "index_to_label": {str(i): str(c) for i, c in enumerate(classes)},
        "label_to_index": {str(c): i for i, c in enumerate(classes)},
    }
    print(f"   classes: {data['classes']}")
    return data


# ข้อมูลเพิ่มเติมกรณีใช้งานร่วมกับโมเดลตระกูล Clustering (KMeans)
def _clustering_data(encoder) -> dict:
    data = {}
    if hasattr(encoder, "cluster_centers_"):
        data["cluster_centers"] = encoder.cluster_centers_.tolist()
        print(f"   cluster_centers shape: {encoder.cluster_centers_.shape}")
    if hasattr(encoder, "n_clusters"):
        data["n_clusters"] = int(encoder.n_clusters)
    if hasattr(encoder, "labels_"):
        data["labels"] = encoder.labels_.tolist()
    return data


# ฟังก์ชันดึงพารามิเตอร์การสเกลข้อมูล (MinMaxScaler/StandardScaler) จาก pkl ไปเป็น JSON
def convert_scaler_to_json():
    print("\n" + "=" * 50)
    print("📦 แปลง scaler_kmeans.pkl → JSON")
    print("=" * 50)

    import joblib

    # ตรวจสอบว่ามีไฟล์ต้นฉบับพิกเกิลของ Scaler หรือไม่
    if not os.path.exists(SCALER_PATH):
        print(f"⚠️ ไม่พบไฟล์ scaler: {SCALER_PATH}")
        return False

    try:
        # โหลดตัวแปลงสเกล (Scaler) จาก pkl
        scaler = joblib.load(SCALER_PATH)
        print(f"✅ โหลด scaler สำเร็จ: {type(scaler).__name__}")

        scaler_data = _scaler_params(scaler)

        # บันทึกประเภทของ Scaler ไว้ด้วย
        scaler_data["type"] = type(scaler).__name__

        # เขียนพารามิเตอร์เก็บลงในรูปแบบไฟล์ JSON
        with open(OUTPUT_SCALER_JSON, "w") as f:
            json.dump(scaler_data, f, indent=2)

        print(f"✅ บันทึก scaler params: {OUTPUT_SCALER_JSON}")
        return True

    except Exception as e:
        print(f"❌ แปลง scaler ล้มเหลว: {e}")
        import traceback
        traceback.print_exc()
        return False

# ฟังก์ชันดึงประเภทการจัดกลุ่มและ Label การทำนายจาก Encoder ไปเป็น JSON
def convert_label_encoder_to_json():
    print("\n" + "=" * 50)
    print("📦 แปลง label_encoder_kmeans.pkl → JSON")
    print("=" * 50)

    import joblib

    # ตรวจสอบว่ามีไฟล์ต้นฉบับพิกเกิลของ Label Encoder หรือไม่
    if not os.path.exists(LABEL_ENCODER_PATH):
        print(f"⚠️ ไม่พบไฟล์ label encoder: {LABEL_ENCODER_PATH}")
        return False

    try:
        # โหลด Label Encoder หรือ KMeans จาก pkl
        encoder = joblib.load(LABEL_ENCODER_PATH)
        print(f"✅ โหลด label encoder สำเร็จ: {type(encoder).__name__}")

        labels_data = {**_encoder_classes_data(encoder), **_clustering_data(encoder)}

        # บันทึกชนิดโมเดลวิเคราะห์ตัวแปรลง JSON
        labels_data["type"] = type(encoder).__name__

        # บันทึกข้อมูลออกมาเป็นไฟล์ JSON
        with open(OUTPUT_LABELS_JSON, "w") as f:
            json.dump(labels_data, f, indent=2, ensure_ascii=False)

        print(f"✅ บันทึก labels: {OUTPUT_LABELS_JSON}")
        return True

    except Exception as e:
        print(f"❌ แปลง label encoder ล้มเหลว: {e}")
        import traceback
        traceback.print_exc()
        return False

# ฟังก์ชันหลักสำหรับการเริ่มกระบวนการแปลงไฟล์ทั้งหมด คืน True ถ้าแปลงสำเร็จครบทุกไฟล์
def main():
    print("🚀 เริ่มแปลง model สำหรับ Flutter TFLite\n")

    results = {}
    results["tflite"] = convert_h5_to_tflite()
    results["scaler"] = convert_scaler_to_json()
    results["labels"] = convert_label_encoder_to_json()

    print("\n" + "=" * 50)
    print("📋 สรุปผล:")
    print("=" * 50)
    for name, ok in results.items():
        print(f"  {'✅' if ok else '❌'} {name}")

    # แสดงสรุปที่ตั้งไฟล์โมเดลที่แปลงสำเร็จแล้ว
    if all(results.values()):
        print("\n🎉 แปลงทั้งหมดสำเร็จ! ไฟล์อยู่ใน assets/models/")
        print("   - emotion_model.tflite")
        print("   - scaler_params.json")
        print("   - emotion_labels.json")
    else:
        print("\n⚠️ บางส่วนล้มเหลว ดูข้อผิดพลาดด้านบน")

    return all(results.values())


if __name__ == "__main__":
    main()
