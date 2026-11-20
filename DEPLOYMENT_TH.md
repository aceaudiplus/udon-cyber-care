# คู่มือติดตั้ง Udon Cyber Care Professional V2

## A. สร้างฐานข้อมูลออนไลน์ (Supabase)
1. ไปที่ https://supabase.com/ แล้วสร้าง Project ใหม่
2. ตั้งรหัสผ่าน Database ที่คาดเดายากและเก็บไว้ใน password manager
3. เปิด Project > SQL Editor > New query
4. เปิดไฟล์ `supabase/schema.sql` คัดลอกทั้งหมด แล้ว Run
5. ไปที่ Project Settings > API คัดลอก Project URL และ anon/public key
6. เปิด `config.js` แล้วแทนค่า:
   - `https://YOUR-PROJECT.supabase.co`
   - `YOUR_SUPABASE_ANON_PUBLIC_KEY`
   ใช้ anon/public key เท่านั้น ห้ามใช้ service_role key

## B. สร้างบัญชีเจ้าของร้าน
1. ไปที่ Authentication > Users > Add user
2. สร้างอีเมลและรหัสผ่านของเจ้าของร้าน (ควรใช้รหัสผ่านเฉพาะ ไม่ซ้ำที่อื่น)
3. คัดลอก User UID/UUID ของบัญชีที่สร้าง
4. กลับไป SQL Editor แล้วรันคำสั่ง (แทน UUID และชื่อจริง):
   ```sql
   update public.profiles
   set role = 'owner', full_name = 'เจ้าของร้าน'
   where id = 'ใส่-USER-UUID-ตรงนี้';
   ```
5. สร้างผู้ใช้ช่างจาก Authentication > Users > Add user
   ระบบจะสร้าง profile เป็น `technician` โดยอัตโนมัติ

## ตั้งค่าหน้า Landing Page และลิงก์ LINE
- `index.html` คือหน้า Landing Page สำหรับลูกค้าทั่วไป และ `staff.html` คือหน้า Login/ระบบจัดการงานซ่อมของช่าง
- ปุ่ม “เข้าสู่ระบบช่าง” มุมขวาบนจะเปิด `staff.html`
- แก้ `LINE_URL` ใน `config.js` ให้เป็นลิงก์ LINE Official Account ของร้าน เช่น `https://line.me/R/ti/p/@yourlineid` (เปลี่ยนเป็นลิงก์จริงของร้าน)
- ปุ่มสั่งซื้อของแต่ละหมวดจะส่งข้อความระบุสินค้าที่สนใจไปยัง LINE เมื่อใส่ลิงก์ LINE จริงแล้ว
- รายการสินค้าในหน้าแรกเป็นหมวดตัวอย่างและข้อความสอบถามราคา ยังไม่ได้เชื่อมกับสต็อก Supabase; แก้ชื่อ/รูป/รายละเอียดใน `index.html` ให้ตรงกับสินค้าจริงก่อนเผยแพร่

## C. Deploy ขึ้นออนไลน์ด้วย Vercel
1. สร้างบัญชี https://vercel.com/
2. อัปโหลดโฟลเดอร์นี้เข้า GitHub repository (อย่าอัปโหลดรหัสผ่านฐานข้อมูลหรือ service_role key)
3. ใน Vercel เลือก Add New > Project แล้ว Import repository
4. Framework Preset เลือก Other; Build Command และ Output Directory เว้นว่าง (หรือ Output Directory เป็น `.`)
5. Deploy
6. เปิด URL ที่ Vercel ให้มา แล้วทดลอง Login

สามารถใช้ Netlify หรือ static hosting ที่รองรับ HTTPS แทนได้เช่นกัน

## D. ตรวจสอบก่อนใช้งานจริง
- ลอง Login ด้วยบัญชี owner และ technician
- ตรวจว่าช่างไม่เห็นเมนูการเงิน/สต็อก/จัดการผู้ใช้
- เพิ่มลูกค้า เปิดงานซ่อม เปลี่ยนสถานะ และบันทึกยอดรับชำระ
- ทดสอบใบรับซ่อมและใบเสร็จ เลือก Print > Save as PDF
- ทดสอบเปิด URL เดียวกันจากมือถือ/คอมพิวเตอร์อีกเครื่อง ข้อมูลควรตรงกัน
- เปิด MFA สำหรับ owner และตั้งค่า backup ของ Supabase
- จำกัดการสร้างผู้ใช้ให้เฉพาะผู้ดูแล (อย่าเปิด public sign-up โดยไม่จำเป็น)

## E. ข้อควรทราบ
- บทบาท owner/technician ถูกควบคุมที่ฐานข้อมูลด้วย RLS; การซ่อนเมนูในหน้าเว็บเป็นเพียง UX ไม่ใช่มาตรการรักษาความปลอดภัยหลัก
- การสร้างผู้ใช้ใหม่และเลื่อนสิทธิ์ owner ทำผ่าน Supabase Dashboard เท่านั้นในชุดนี้
- ช่างสามารถแก้ไขงานซ่อมและข้อมูลลูกค้าได้ตาม policy; การลบและข้อมูลการเงิน/สต็อกเป็นของ owner
- PDF ออกโดยใช้ระบบ Print ของเบราว์เซอร์ ไม่ต้องใช้บริการ PDF ภายนอก
- ระบบยังไม่รองรับการบันทึกประวัติการรับชำระหลายงวดแยก transaction; ฟิลด์ paid เป็นยอดรวมสะสมของใบซ่อม
- อย่าใช้กับข้อมูลจริงจนกว่าจะตั้งค่า Supabase, ตรวจ policy, ตั้ง backup และทดสอบตามรายการด้านบน
