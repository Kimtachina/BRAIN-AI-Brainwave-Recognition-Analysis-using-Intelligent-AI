# Smart Brain

แอป Flutter สำหรับวัดคลื่นสมองด้วย Muse (Muse 2 / Muse S) ประเมินสุขภาพจิต (PHQ-9) และให้คำแนะนำด้วย AI
ใช้ Supabase เป็นฐานข้อมูลและระบบล็อกอิน

## รันในเครื่อง

```bash
flutter pub get
cp env/supabase.example.json env/supabase.json   # ครั้งแรกครั้งเดียว แล้วใส่ URL และ anon key ของโปรเจกต์
flutter run --dart-define-from-file=env/supabase.json              # มือถือที่ต่ออยู่
flutter run -d chrome --dart-define-from-file=env/supabase.json    # เว็บ
```

`env/supabase.json` อยู่ใน `.gitignore` ห้าม commit ใน VS Code กด F5 ได้เลย เพราะ `.vscode/launch.json` ส่งไฟล์นี้ให้แล้ว
ถ้าลืมส่งไฟล์ แอปจะขึ้นข้อความ `ไม่พบ SUPABASE_URL / SUPABASE_ANON_KEY` ใน debug console

OpenAI key อยู่ฝั่ง server (ดูหัวข้อถัดไป)

## OpenAI ผ่าน Supabase Edge Function

แชต, RAG embeddings และถอดเสียง เรียก OpenAI ผ่าน `supabase/functions/openai-proxy`
ตัว function ตรวจว่าผู้ใช้ล็อกอินแล้ว และกำหนดโมเดลกับขนาดคำขอสูงสุดไว้ฝั่ง server

```bash
supabase login
supabase link --project-ref ifsvthnxydchqnigvmuw
supabase secrets set OPENAI_API_KEY=sk-...
supabase functions deploy openai-proxy
```

ถ้า key เดิมเคยอยู่ใน `.env` ที่ build เป็นแอปหรือเว็บไปแล้ว ให้ยกเลิก key นั้นที่ OpenAI แล้วสร้างใหม่

## Deploy เว็บ

```bash
flutter build web --release --dart-define-from-file=env/supabase.json
# อัปโหลดโฟลเดอร์ build/web ขึ้น static hosting ที่มี HTTPS เช่น
npx vercel deploy build/web --prod
```

หลัง deploy:
- เพิ่ม URL ของเว็บใน Supabase → Authentication → URL Configuration (Site URL และ Redirect URLs) เพื่อให้ล็อกอินด้วย Google บนเว็บได้
- ต้องเปิด RLS ครบทุกตาราง เพราะ anon key อยู่ในตัวเว็บ

## การเชื่อมต่อ Muse บนเว็บ

เว็บใช้ Web Bluetooth ผ่าน `flutter_blue_plus`:

| เบราว์เซอร์ | ต่อ Muse ได้ |
|---|---|
| Chrome / Edge บน Windows, macOS, Android | ได้ |
| Safari, ทุกเบราว์เซอร์บน iPhone/iPad, Firefox | ไม่ได้ (ใช้แอปมือถือ) |

- ต้องเปิดผ่าน HTTPS หรือ `localhost`
- กดปุ่มเชื่อมต่อแล้วเลือกอุปกรณ์ในหน้าต่างของเบราว์เซอร์
- การตรวจอารมณ์บนเว็บใช้สูตรจากสัดส่วนคลื่นสมอง (`emotion_heuristics.dart`) เพราะ TFLite ใช้บนเว็บไม่ได้
- โหมดจำลองให้ดูหน้าจอได้ แต่ไม่บันทึกผลลงประวัติ
