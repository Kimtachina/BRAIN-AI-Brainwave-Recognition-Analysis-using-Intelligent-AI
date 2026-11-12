part of '../test_screen.dart';

// ข้อมูลแบบประเมิน PHQ-9: คำชี้แจง ตัวเลือกคำตอบ (0–3 คะแนน) และคำถาม 9 ข้อ

const String _phq9Instruction =
  'ในช่วง 2 สัปดาห์ที่ผ่านมา คุณได้รับความเดือดร้อนจากปัญหาต่อไปนี้ มากน้อยเพียงใด';

const List<String> _answerOptions = [
  'ไม่เลย',
  'หลายวัน',
  'มากกว่าครึ่งหนึ่งของวัน',
  'เกือบทุกวัน',
];

const List<Map<String, String>> _phq9Questions = [
  {
    'question': 'รู้สึกเบื่อ ไม่สนใจอยากทำอะไร',
    'en': 'Little interest or pleasure in doing things',
  },
  {
    'question': 'รู้สึกหดหู่ ท้อแท้ หรือสิ้นหวัง',
    'en': 'Feeling down, depressed, or hopeless',
  },
  {
    'question': 'นอนไม่หลับ หรือหลับมากเกินไป',
    'en': 'Trouble falling or staying asleep, or sleeping too much',
  },
  {
    'question': 'รู้สึกเหนื่อย ไม่มีแรง หรืออ่อนเพลีย',
    'en': 'Feeling tired or having little energy',
  },
  {
    'question': 'เบื่ออาหาร หรือกินมากเกินไป',
    'en': 'Poor appetite or overeating',
  },
  {
    'question': 'รู้สึกไม่ดีกับตัวเอง คิดว่าตัวเองล้มเหลว\nหรือทำให้ตัวเองหรือครอบครัวผิดหวัง',
    'en': 'Feeling bad about yourself — or that you are a failure\nor have let yourself or your family down',
  },
  {
    'question': 'ไม่มีสมาธิในการทำสิ่งต่างๆ เช่น อ่านหนังสือ\nหรือดูโทรทัศน์',
    'en': 'Trouble concentrating on things, such as reading\nthe newspaper or watching television',
  },
  {
    'question': 'พูดหรือเคลื่อนไหวช้าจนคนอื่นสังเกตเห็น\nหรือกระสับกระส่ายจนอยู่ไม่นิ่งมากกว่าปกติ',
    'en': 'Moving or speaking so slowly that other people could\nhave noticed? Or the opposite — being fidgety or restless',
  },
  {
    'question': 'คิดว่าตัวเองตายไปจะดีกว่า หรือคิดจะ\nทำร้ายตัวเอง',
    'en': 'Thoughts that you would be better off dead\nor of hurting yourself in some way',
  },
];
