import os
import numpy as np
import joblib
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional, Dict
import logging

# ตั้งค่า Logging สำหรับการแสดงผลสถานะการทำงานของเซิร์ฟเวอร์
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# เริ่มต้นระบบ FastAPI App พร้อมระบุหัวข้อ คำอธิบาย และเวอร์ชัน
app = FastAPI(
    title="Emotion Detection API",
    description="API สำหรับตรวจจับอารมณ์จากข้อมูล EEG brainwave ด้วย TSception model",
    version="1.0.0",
)

# ต้นทาง (Origin) ที่อนุญาตให้เรียก API จากเบราว์เซอร์ เช่น เว็บ Flutter
# กำหนดด้วย env CORS_ALLOW_ORIGINS คั่นด้วยจุลภาค เช่น "https://app.example.com,https://admin.example.com"
# ถ้าไม่กำหนด อนุญาตเฉพาะ localhost / 127.0.0.1 ทุกพอร์ต สำหรับ flutter run -d chrome ตอนพัฒนา
# แอปมือถือไม่ผ่าน CORS จึงไม่ได้รับผลกระทบ
CORS_ALLOW_ORIGINS = [o.strip() for o in os.environ.get("CORS_ALLOW_ORIGINS", "").split(",") if o.strip()]
LOCALHOST_ORIGIN_REGEX = r"^https?://(localhost|127\.0\.0\.1)(:\d+)?$"

# API นี้ไม่ใช้ cookie หรือ session จึงไม่ต้องเปิด allow_credentials
app.add_middleware(
    CORSMiddleware,
    allow_origins=CORS_ALLOW_ORIGINS,
    allow_origin_regex=None if CORS_ALLOW_ORIGINS else LOCALHOST_ORIGIN_REGEX,
    allow_credentials=False,
    allow_methods=["GET", "POST"],
    allow_headers=["Content-Type"],
)

# ประกาศตัวแปร Global เพื่อใช้เก็บโมเดล, ตัวแปลงสเกลข้อมูล และตัวถอดรหัส Label
model = None
scaler = None
label_encoder = None

# ตั้งค่าตำแหน่งที่อยู่ของโมเดล (ใช้ร่วมกับโปรเจกต์ Flutter)
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODELS_DIR = os.path.join(BASE_DIR, "..", "assets", "models")

MODEL_PATH = os.path.join(MODELS_DIR, "Emotion_TSception.h5")
SCALER_PATH = os.path.join(MODELS_DIR, "scaler_kmeans.pkl")
LABEL_ENCODER_PATH = os.path.join(MODELS_DIR, "label_encoder_kmeans.pkl")

# รายการอารมณ์ทั้งหมดที่แยกตามคลาส index (อารมณ์ภาษาอังกฤษ)
EMOTION_LABELS = {
    0: "neutral",
    1: "happy",
    2: "sad",
    3: "angry",
    4: "fearful",
    5: "calm",
    6: "stressed",
    7: "anxious",
    8: "surprised",
    9: "disgusted",
}

# พจนานุกรมแปลภาษาอารมณ์จากอังกฤษเป็นภาษาไทย
EMOTION_LABELS_TH: Dict[str, str] = {
    "neutral": "ปกติ",
    "happy": "มีความสุข",
    "sad": "เศร้า",
    "angry": "โกรธ",
    "fearful": "กลัว",
    "calm": "สงบ",
    "stressed": "เครียด",
    "anxious": "วิตกกังวล",
    "surprised": "ประหลาดใจ",
    "disgusted": "รังเกียจ",
}

# ไอคอน Emoji ที่สอดคล้องกับแต่ละอารมณ์
EMOTION_EMOJIS: Dict[str, str] = {
    "neutral": "😐",
    "happy": "😊",
    "sad": "😢",
    "angry": "😠",
    "fearful": "😨",
    "calm": "😌",
    "stressed": "😰",
    "anxious": "😟",
    "surprised": "😲",
    "disgusted": "🤢",
}

# โมเดลข้อมูลนำเข้าสำหรับคลื่นสมอง EEG แต่ละช่วงความถี่
class EEGData(BaseModel):
    alpha: float
    beta: float
    theta: float
    delta: float
    gamma: float
    attention: Optional[float] = 0.0
    meditation: Optional[float] = 0.0

# โมเดลข้อมูลนำเข้าในรูปแบบกลุ่ม (Batch) เพื่อใช้วิเคราะห์ข้อมูลพร้อมๆ กันหลายวินาที
class EEGBatchData(BaseModel):
    data: List[EEGData]

# โครงสร้างผลลัพธ์ข้อมูลส่งกลับของการทำนายอารมณ์
class EmotionResponse(BaseModel):
    success: bool
    emotion_type: str
    emotion_label_th: str
    emoji: str
    confidence: float
    all_scores: Dict[str, float]
    method: str

# โครงสร้างผลลัพธ์การตรวจสอบสถานะระบบ (Health Check)
class HealthResponse(BaseModel):
    status: str
    model_loaded: bool
    scaler_loaded: bool
    label_encoder_loaded: bool

# ฟังก์ชันโหลดไฟล์โมเดล, Scaler และ Label Encoder เข้ามาในหน่วยความจำตอนเริ่มต้นระบบ
def load_models():
    global model, scaler, label_encoder

    # 1. พยายามโหลดโมเดลปัญญาประดิษฐ์ TSception (Deep Learning - TensorFlow)
    try:
        import tensorflow as tf
        if os.path.exists(MODEL_PATH):
            model = tf.keras.models.load_model(MODEL_PATH, compile=False)
            logger.info(f"✅ Loaded TSception model from {MODEL_PATH}")
            logger.info(f"   Model input shape: {model.input_shape}")
            logger.info(f"   Model output shape: {model.output_shape}")
        else:
            logger.warning(f"⚠️ Model file not found: {MODEL_PATH}")
    except Exception as e:
        logger.error(f"❌ Failed to load model: {e}")

    # 2. โหลด MinMaxScaler เพื่อแปลงขนาดข้อมูลฟีเจอร์คลื่นสมองให้เข้าคู่กับชุดที่โมเดลใช้เรียนรู้
    try:
        if os.path.exists(SCALER_PATH):
            scaler = joblib.load(SCALER_PATH)
            logger.info(f"✅ Loaded scaler from {SCALER_PATH}")
        else:
            logger.warning(f"⚠️ Scaler file not found: {SCALER_PATH}")
    except Exception as e:
        logger.error(f"❌ Failed to load scaler: {e}")

    # 3. โหลด Label Encoder เพื่อใช้แปลงชื่อประเภทอารมณ์ (เช่น happy, calm) จากตัวเลขทำนาย
    try:
        if os.path.exists(LABEL_ENCODER_PATH):
            label_encoder = joblib.load(LABEL_ENCODER_PATH)
            logger.info(f"✅ Loaded label encoder from {LABEL_ENCODER_PATH}")
            if hasattr(label_encoder, 'classes_'):
                logger.info(f"   Classes: {label_encoder.classes_}")
        else:
            logger.warning(f"⚠️ Label encoder file not found: {LABEL_ENCODER_PATH}")
    except Exception as e:
        logger.error(f"❌ Failed to load label encoder: {e}")

# ดักจับอีเวนต์เมื่อระบบ API เริ่มสตาร์ทขึ้นมาเพื่อเริ่มโหลดโมเดลทันที
@app.on_event("startup")
async def startup_event():
    logger.info("🚀 Starting Emotion Detection API...")
    load_models()
    logger.info("✅ API ready!")

# Endpoint ตรวจสอบสถานะการเชื่อมต่อและการทำงานของเซิร์ฟเวอร์
@app.get("/", response_model=HealthResponse)
async def health_check():
    return HealthResponse(
        status="running",
        model_loaded=model is not None,
        scaler_loaded=scaler is not None,
        label_encoder_loaded=label_encoder is not None,
    )

# Alias ของหน้าหลัก เพื่อตรวจสอบสถานะความพร้อมของเซิร์ฟเวอร์
@app.get("/health", response_model=HealthResponse)
async def health():
    return await health_check()

# ขนาดของมิติใน input_shape ของโมเดล (None = ไม่ได้กำหนดตายตัว ให้ใช้ค่า default แทน)
def _dim(value: int | None, default: int) -> int:
    return value if value is not None else default


# แปลงโครงสร้างข้อมูล (Reshape) ให้ตรงกับ input shape ของโมเดลเครือข่ายประสาท
def _reshape_for_model(scaled_features: np.ndarray, input_shape: tuple) -> np.ndarray:
    n_features = scaled_features.shape[1]

    # (batch, time_steps, features): ทำซ้ำเวกเตอร์ฟีเจอร์เดียวกันในทุก time step
    if len(input_shape) == 3:
        time_steps = _dim(input_shape[1], 1)
        features = _dim(input_shape[2], n_features)
        width = min(features, n_features)
        model_input = np.zeros((1, time_steps, features))
        model_input[0, :, :width] = scaled_features[0, :width]
        return model_input

    # (batch, channels, time_steps, features): วางฟีเจอร์ลงแกนเวลาของทุก channel
    if len(input_shape) == 4:
        channels = _dim(input_shape[1], 1)
        time_steps = _dim(input_shape[2], n_features)
        features = _dim(input_shape[3], 1)
        steps = min(time_steps, n_features)
        model_input = np.zeros((1, channels, time_steps, features))
        model_input[0, :, :steps, 0] = scaled_features[0, :steps]
        return model_input

    return scaled_features


# คืนรายชื่อคลาสจาก Label Encoder หรือ None ถ้าไม่มี
def _encoder_classes():
    if label_encoder is not None and hasattr(label_encoder, "classes_"):
        return label_encoder.classes_
    return None


# แปลงผลลัพธ์แบบหลายคลาส (Multi-class) เป็น (อารมณ์, ความมั่นใจ, คะแนนทุกอารมณ์)
def _decode_multiclass(probs: np.ndarray) -> tuple:
    predicted_class = int(np.argmax(probs))
    confidence = float(np.max(probs))
    classes = _encoder_classes()

    if classes is None:
        all_scores = {EMOTION_LABELS.get(i, f"class_{i}"): float(p) for i, p in enumerate(probs)}
        return EMOTION_LABELS.get(predicted_class, "neutral"), confidence, all_scores

    all_scores = {str(cls): float(probs[i]) for i, cls in enumerate(classes) if i < len(probs)}
    emotion_type = str(classes[predicted_class]) if predicted_class < len(classes) else "neutral"
    return emotion_type, confidence, all_scores


# แปลงผลลัพธ์แบบ Binary classification หรือสัญกรณ์มิติเดียว
def _decode_binary(predictions: np.ndarray) -> tuple:
    confidence = float(predictions[0][0])
    predicted_class = int(round(confidence))
    classes = _encoder_classes()

    if classes is None:
        emotion_type = EMOTION_LABELS.get(predicted_class, "neutral")
    else:
        emotion_type = str(classes[min(predicted_class, len(classes) - 1)])
    return emotion_type, confidence, {emotion_type: confidence}


# ฟังก์ชันทำนายอารมณ์โดยใช้ Deep Learning Model (TSception) ที่โหลดไว้
def predict_with_model(eeg_features: np.ndarray) -> dict:
    try:
        if model is None:
            raise Exception("Model not loaded")

        # ปรับสเกลข้อมูล EEG Feature ให้อยู่ในช่วงที่เหมาะสมกับโมเดล
        features_2d = eeg_features.reshape(1, -1)
        scaled_features = scaler.transform(features_2d) if scaler is not None else features_2d

        # ทำนายผลโดยใช้ TSception Model
        model_input = _reshape_for_model(scaled_features, model.input_shape)
        predictions = model.predict(model_input, verbose=0)

        if predictions.ndim > 1 and predictions.shape[1] > 1:
            emotion_type, confidence, all_scores = _decode_multiclass(predictions[0])
        else:
            emotion_type, confidence, all_scores = _decode_binary(predictions)

        return {
            "emotion_type": emotion_type,
            "confidence": confidence,
            "all_scores": all_scores,
            "method": "tsception_model",
        }

    except Exception as e:
        logger.error(f"Model prediction error: {e}")
        raise

# ระบบตรรกะแบบ Rule-Based (สำรองกรณีไม่ได้โหลดไฟล์โมเดลปัญญาประดิษฐ์ไว้)
# ประเมินสถิติสัดส่วนความหนาแน่นของคลื่นสมองแต่ละช่วงความถี่ เพื่อคาดการณ์ความรู้สึกเบื้องต้น
def predict_with_rules(eeg_data: EEGData) -> dict:
    alpha = eeg_data.alpha
    beta = eeg_data.beta
    theta = eeg_data.theta
    delta = eeg_data.delta
    gamma = eeg_data.gamma

    # หาผลรวมของคลื่นสมองเพื่อนำมาคิดอัตราส่วนเปอร์เซ็นต์
    total = alpha + beta + theta + delta + gamma
    if total == 0:
        total = 1

    a_pct = alpha / total
    b_pct = beta / total
    t_pct = theta / total
    d_pct = delta / total
    g_pct = gamma / total

    scores = {}

    # Calm (สงบ): คลื่น Alpha สูง และ คลื่น Beta ต่ำ
    scores["calm"] = min(1.0, a_pct * 1.5 + (1 - b_pct) * 0.5)

    # Stressed (เครียด): คลื่น Beta และ Gamma ตอบสนองในปริมาณที่สูง
    scores["stressed"] = min(1.0, b_pct * 1.2 + g_pct * 0.8)

    # Happy (มีความสุข): คลื่น Alpha เด่นร่วมกับ Theta ปานกลาง
    scores["happy"] = min(1.0, a_pct * 1.2 + t_pct * 0.5 + (1 - b_pct) * 0.3)

    # Sad (เศร้า): คลื่น Theta และ Delta ทำงานเด่นในสภาวะซึมเศร้ากระตุ้นน้อย
    scores["sad"] = min(1.0, t_pct * 1.0 + d_pct * 0.8 + (1 - a_pct) * 0.2)

    # Angry (โกรธ): คลื่น Beta และ Gamma สูงมากร่วมกับ Alpha ที่ลดลงอย่างเห็นได้ชัด
    scores["angry"] = min(1.0, b_pct * 1.0 + g_pct * 1.0 + (1 - a_pct) * 0.5)

    # Fearful (กลัว): คลื่นความถี่สูงอย่าง Gamma ถูกกระตุ้นอย่างฉับพลัน
    scores["fearful"] = min(1.0, g_pct * 1.3 + b_pct * 0.5 + (1 - a_pct) * 0.3)

    # Neutral (ปกติ): สภาวะสมดุลของคลื่นสมองหลักทั้งสาม
    balance = 1 - abs(a_pct - 0.2) - abs(b_pct - 0.2) - abs(t_pct - 0.2)
    scores["neutral"] = max(0, min(1.0, balance))

    # Anxious (วิตกกังวล): คลื่น Theta และ Beta มีการเปลี่ยนแปลง
    scores["anxious"] = min(1.0, t_pct * 0.8 + b_pct * 0.7 + g_pct * 0.3)

    # ทำการแปลงคะแนนสัมพัทธ์ (Normalization) ให้สูงสุดเป็น 1.0
    max_score = max(scores.values()) if scores else 1
    if max_score > 0:
        scores = {k: round(v / max_score, 4) for k, v in scores.items()}

    emotion_type = max(scores, key=lambda k: scores[k])
    confidence = scores[emotion_type]

    return {
        "emotion_type": emotion_type,
        "confidence": confidence,
        "all_scores": scores,
        "method": "rule_based",
    }

# เรียงค่าคลื่นสมองเป็นเวกเตอร์ฟีเจอร์ตามลำดับที่โมเดลต้องการ
def _eeg_to_features(eeg: EEGData) -> np.ndarray:
    return np.array([
        eeg.alpha,
        eeg.beta,
        eeg.theta,
        eeg.delta,
        eeg.gamma,
        eeg.attention or 0,
        eeg.meditation or 0,
    ])

# Endpoint หลักสำหรับการทำนายอารมณ์ด้วยข้อมูลคลื่นสมอง EEG แบบวินาทีเดียว
@app.post("/predict", response_model=EmotionResponse)
async def predict_emotion(eeg_data: EEGData):
    try:
        # หากโหลดโมเดลปัญญาประดิษฐ์สำเร็จ จะใช้วิธี Deep learning ในการทำนาย
        if model is not None:
            result = predict_with_model(_eeg_to_features(eeg_data))
        else:
            # หากไม่มีไฟล์โมเดล จะประเมินด้วยตรรกะแบบเงื่อนไขคลื่นสมองเบื้องต้นแทน
            result = predict_with_rules(eeg_data)

        emotion_type = str(result["emotion_type"])

        return EmotionResponse(
            success=True,
            emotion_type=emotion_type,
            emotion_label_th=EMOTION_LABELS_TH.get(emotion_type, emotion_type),
            emoji=EMOTION_EMOJIS.get(emotion_type, "😐"),
            confidence=result["confidence"],
            all_scores=result["all_scores"],
            method=result["method"],
        )

    except Exception as e:
        logger.error(f"Prediction error: {e}")
        # กรณีเกิดความผิดพลาดใดๆ ให้รันระบบ Rule-Based เป็นตัวสำรองฉุกเฉิน (Fallback)
        try:
            result = predict_with_rules(eeg_data)
            emotion_type = str(result["emotion_type"])
            return EmotionResponse(
                success=True,
                emotion_type=emotion_type,
                emotion_label_th=EMOTION_LABELS_TH.get(emotion_type, emotion_type),
                emoji=EMOTION_EMOJIS.get(emotion_type, "😐"),
                confidence=result["confidence"],
                all_scores=result["all_scores"],
                method="rule_based_fallback",
            )
        except Exception as e2:
            raise HTTPException(status_code=500, detail=str(e2)) from e2

# ทำนายอารมณ์ของข้อมูลหนึ่งวินาที: ใช้โมเดลถ้ามี ถ้าไม่มีหรือโมเดลล้มเหลวให้ใช้ rule-based
def _predict_single(eeg: EEGData) -> dict:
    try:
        if model is not None:
            return predict_with_model(_eeg_to_features(eeg))
        return predict_with_rules(eeg)
    except Exception:
        return predict_with_rules(eeg)


# เฉลี่ยคะแนนความน่าจะเป็นของแต่ละอารมณ์จากผลลัพธ์ทั้งหมด
def _average_scores(results: list[dict]) -> dict[str, float]:
    totals: dict[str, float] = {}
    for r in results:
        for k, v in r["all_scores"].items():
            totals[k] = totals.get(k, 0) + v
    n = len(results)
    return {k: round(v / n, 4) for k, v in totals.items()}


# Endpoint สำหรับวิเคราะห์ข้อมูลคลื่นสมองแบบกลุ่ม (Batch) เพื่อเฉลี่ยแนวโน้มอารมณ์จากช่วงเวลาที่กว้างขึ้น
@app.post("/predict/batch", response_model=EmotionResponse)
async def predict_emotion_batch(batch: EEGBatchData):
    if not batch.data:
        raise HTTPException(status_code=400, detail="No EEG data provided")

    # ประมวลผลและทำนายข้อมูลคลื่นสมองของแต่ละวินาทีในชุดข้อมูล
    all_results = [_predict_single(eeg) for eeg in batch.data]
    combined_scores = _average_scores(all_results)

    # หาอารมณ์ที่มีคะแนนเฉลี่ยสูงสุดในกลุ่มข้อมูลทั้งหมด
    emotion_type = max(combined_scores, key=lambda k: combined_scores[k])
    confidence = combined_scores[emotion_type]

    return EmotionResponse(
        success=True,
        emotion_type=emotion_type,
        emotion_label_th=EMOTION_LABELS_TH.get(emotion_type, emotion_type),
        emoji=EMOTION_EMOJIS.get(emotion_type, "😐"),
        confidence=confidence,
        all_scores=combined_scores,
        method=all_results[0]["method"] if all_results else "unknown",
    )

# สั่งให้รัน Uvicorn เซิร์ฟเวอร์เมื่อทำการสั่งรันไฟล์นี้โดยตรง (Port: 8000)
if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
