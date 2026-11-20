# Udon Cyber Care Professional V2

ชุดไฟล์สำหรับนำขึ้นใช้งานจริง โดยใช้:
- Frontend: HTML/CSS/JavaScript
- Authentication + Online PostgreSQL: Supabase
- Hosting: Vercel / Netlify / Static hosting
- เอกสาร PDF: ใช้หน้าต่างพิมพ์ของเบราว์เซอร์ เลือก “Save as PDF”

## ไฟล์ในแพ็กเกจ
- `index.html` — หน้าเว็บและหน้าล็อกอิน
- `style.css` — Responsive UI
- `app.js` — ระบบ Login, role, CRUD, งานซ่อม, พิมพ์เอกสาร
- `config.js` — ใส่ Supabase Project URL และ anon key
- `supabase/schema.sql` — สร้างตาราง, trigger, RLS policies
- `vercel.json` — ตั้งค่า static deployment
- `.env.example` — ตัวอย่างค่าตั้งค่า (หน้าเว็บ static ใช้ config.js)
- `DEPLOYMENT_TH.md` — คู่มือติดตั้งทีละขั้น

## ก่อนเปิดใช้
1. สร้าง Supabase project
2. รัน `supabase/schema.sql` ใน SQL Editor
3. สร้างบัญชีเจ้าของร้านใน Authentication > Users
4. คัดลอก UUID ของเจ้าของร้าน แล้วรัน SQL UPDATE ตามคู่มือเพื่อกำหนด role owner
5. สร้างบัญชีช่างใน Authentication > Users (role เริ่มต้น technician)
6. ใส่ Project URL และ anon public key ใน config.js
7. Deploy โฟลเดอร์นี้ขึ้น Vercel/Netlify ผ่าน Git หรือ CLI

## ข้อจำกัด / ความปลอดภัย
- ห้ามนำ `service_role` key ไปใส่ใน frontend/config.js หรือ commit ลง Git
- RLS ป้องกันการอ่าน/เขียนข้อมูลโดยผู้ที่ไม่ได้ล็อกอิน และจำกัดตารางสต็อก/การเงินให้เจ้าของร้าน
- ในรุ่นนี้ช่างอ่าน/แก้ไขข้อมูลลูกค้าและงานซ่อมได้; การลบงาน/ลูกค้าเป็นสิทธิ์เจ้าของ
- การออกเอกสารเป็นการพิมพ์จาก browser; เลือก Save as PDF ไม่ใช่ไฟล์ PDF ที่สร้างฝั่ง server
- ควรเปิด MFA สำหรับบัญชีเจ้าของ, ตั้งค่า SMTP, เปิด backup/PITR ตามแผน Supabase และทดสอบ RLS ก่อนใช้ข้อมูลจริง
- ไม่ได้มีการเชื่อมระบบแจ้งเตือน LINE/SMS หรือระบบภาษี e-Tax
- ก่อนเปิดใช้จริงให้ตรวจสอบแบบฟอร์มใบเสร็จและข้อกำหนดทางบัญชี/ภาษีของกิจการ
