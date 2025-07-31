# แผนการพัฒนาระบบ Rails Facebook API (แบบละเอียด)

## ภาพรวมโครงการ
แผนการพัฒนาระบบครบถ้วนตาม UPDATED_SYSTEM_REQUIREMENTS.md โดยเน้นการพัฒนาแบบ phased approach เพื่อให้แต่ละระบบทำงานได้อย่างมีประสิทธิภาพและเชื่อมโยงกันได้อย่างลงตัว ระบบนี้จะเป็นแพลตฟอร์มสำหรับผู้ขายสินค้าผ่าน Facebook Live พร้อมระบบจัดการครบวงจร

---

## 🎯 Phase 1: ระบบสมาชิกรายเดือน (สัปดาห์ที่ 1-2)
**เป้าหมาย**: สร้างระบบสมาชิกแบบจ่ายรายเดือนพร้อมการตรวจสอบการชำระเงินด้วยตนเอง

### สัปดาห์ที่ 1: ฐานข้อมูลและโมเดล

#### การสร้าง Database Migrations
- [ ] **สร้างตาราง `subscription_plans`** (แผนการสมัครสมาชิก)
  - `id` - รหัสแผน (Primary Key, Auto-increment)
  - `name` - ชื่อแผน (String, เช่น "แผนพื้นฐาน", "แผนพรีเมียม", "แผนองค์กร")
  - `description` - รายละเอียดแผน (Text, คำอธิบายคุณสมบัติของแผน)
  - `price_per_month` - ราคาต่อเดือน (Decimal, precision: 10, scale: 2)
  - `features` - คุณสมบัติของแผน (JSON format, เก็บรายการฟีเจอร์)
  - `active` - สถานะการเปิดใช้งาน (Boolean, default: true)
  - `plan_type` - ประเภทแผน (String, เช่น "basic", "premium", "enterprise")
  - `max_products` - จำนวนสินค้าสูงสุดที่อนุญาต (Integer)
  - `max_orders_per_month` - จำนวนออเดอร์สูงสุดต่อเดือน (Integer)
  - `created_at`, `updated_at` - เวลาสร้างและอัปเดต

- [ ] **สร้างตาราง `user_subscriptions`** (การสมัครสมาชิกของผู้ใช้)
  - `id` - รหัสการสมัครสมาชิก (Primary Key)
  - `user_id` - รหัสผู้ใช้ (Foreign Key → users.id)
  - `subscription_plan_id` - รหัสแผนสมาชิก (Foreign Key → subscription_plans.id)
  - `status` - สถานะ (Enum: "pending", "active", "expired", "cancelled", "suspended")
  - `activated_at` - เวลาที่เริ่มใช้งาน (DateTime)
  - `expires_at` - เวลาที่หมดอายุ (DateTime, สำคัญสำหรับระบบรายเดือน)
  - `paid_amount` - จำนวนเงินที่ชำระ (Decimal)
  - `payment_method` - วิธีการชำระเงิน (String, เช่น "bank_transfer", "credit_card")
  - `auto_renew` - การต่ออายุอัตโนมัติ (Boolean, default: false)
  - `renewal_date` - วันที่ต่ออายุถัดไป (Date)
  - `notes` - หมายเหตุเพิ่มเติม (Text)
  - `created_at`, `updated_at` - เวลาสร้างและอัปเดต
  - **Indexes**: user_id, status, expires_at, activated_at

- [ ] **สร้างตาราง `payment_slips`** (หลักฐานการชำระเงิน)
  - `id` - รหัสสลิป (Primary Key)
  - `user_id` - รหัสผู้ใช้ (Foreign Key → users.id)
  - `user_subscription_id` - รหัสการสมัครสมาชิก (Foreign Key → user_subscriptions.id)
  - `amount` - จำนวนเงิน (Decimal, precision: 10, scale: 2)
  - `status` - สถานะ (Enum: "pending", "verified", "rejected", "expired")
  - `slip_image` - รูปภาพสลิป (String, Active Storage key)
  - `bank_name` - ชื่อธนาคาร (String)
  - `account_number` - เลขที่บัญชี (String)
  - `transfer_date` - วันที่โอน (Date)
  - `transfer_time` - เวลาที่โอน (Time)
  - `notes` - หมายเหตุจากผู้ใช้ (Text)
  - `reference_number` - เลขอ้างอิงการโอน (String)
  - `payment_date` - วันที่ชำระเงิน (Date)
  - `verified_by_id` - รหัสแอดมินที่ตรวจสอบ (Integer, Foreign Key → users.id)
  - `verified_at` - เวลาที่ตรวจสอบ (DateTime)
  - `rejection_reason` - เหตุผลการปฏิเสธ (Text)
  - `admin_notes` - หมายเหตุจากแอดมิน (Text)
  - `created_at`, `updated_at` - เวลาสร้างและอัปเดต
  - **Indexes**: user_id, status, verified_by_id, created_at

#### การพัฒนา Models

- [ ] **โมเดล `SubscriptionPlan`**
  ```ruby
  # Validations ที่ต้องมี:
  # - name presence และ uniqueness
  # - price_per_month presence และ numericality > 0
  # - features format validation (valid JSON)
  # - plan_type inclusion in allowed values
  
  # Scopes ที่ต้องมี:
  # - active: แผนที่เปิดใช้งาน
  # - by_price: เรียงตามราคา
  # - popular: แผนยอดนิยม
  
  # Methods ที่ต้องมี:
  # - feature_list: แปลง JSON features เป็น array
  # - includes_feature?(feature): ตรวจสอบว่ามีฟีเจอร์นี้หรือไม่
  # - monthly_price_display: แสดงราคาในรูปแบบที่อ่านง่าย
  # - can_create_products?(count): ตรวจสอบว่าสามารถสร้างสินค้าได้อีกหรือไม่
  ```

- [ ] **โมเดล `UserSubscription`**
  ```ruby
  # Associations:
  # - belongs_to :user
  # - belongs_to :subscription_plan
  # - has_many :payment_slips
  
  # Validations:
  # - user_id presence และ uniqueness (scope: status active)
  # - expires_at presence และ future date
  # - paid_amount presence และ matches plan price
  
  # State Machine สำหรับ status:
  # pending → active (เมื่อได้รับการอนุมัติ)
  # active → expired (เมื่อหมดอายุ)
  # active → cancelled (เมื่อยกเลิก)
  # expired → active (เมื่อต่ออายุ)
  
  # Scopes:
  # - active: สมาชิกที่ใช้งานได้
  # - expired: สมาชิกที่หมดอายุ
  # - expiring_soon: สมาชิกที่จะหมดอายุใน 7 วัน
  
  # Methods:
  # - active?: ตรวจสอบว่าสมาชิกยังใช้งานได้หรือไม่
  # - days_until_expiry: จำนวนวันที่เหลือก่อนหมดอายุ
  # - can_access_feature?(feature): ตรวจสอบสิทธิ์การใช้ฟีเจอร์
  # - extend_subscription(months): ต่ออายุสมาชิก
  # - calculate_renewal_amount: คำนวณจำนวนเงินการต่ออายุ
  ```

- [ ] **โมเดล `PaymentSlip`**
  ```ruby
  # Active Storage:
  # - has_one_attached :slip_image
  # - Image validation: ประเภทไฟล์ (jpg, png, pdf), ขนาดไฟล์ < 5MB
  
  # Associations:
  # - belongs_to :user
  # - belongs_to :user_subscription
  # - belongs_to :verified_by, class_name: 'User', optional: true
  
  # Validations:
  # - amount presence และ positive number
  # - slip_image presence
  # - bank_name และ account_number presence
  # - transfer_date presence และ not future date
  
  # State Machine:
  # pending → verified (เมื่อแอดมินอนุมัติ)
  # pending → rejected (เมื่อแอดมินปฏิเสธ)
  # pending → expired (เมื่อเกิน 7 วันไม่มีการตรวจสอบ)
  
  # Methods:
  # - verify!(admin_user, notes = nil): อนุมัติการชำระเงิน
  # - reject!(admin_user, reason): ปฏิเสธการชำระเงิน
  # - formatted_amount: แสดงจำนวนเงินในรูปแบบที่อ่านง่าย
  # - days_since_submission: จำนวนวันที่ส่งมา
  ```

- [ ] **อัปเดตโมเดล `User`**
  ```ruby
  # เพิ่ม Associations:
  # - has_many :user_subscriptions
  # - has_one :current_subscription, -> { active }, class_name: 'UserSubscription'
  # - has_many :payment_slips
  
  # เพิ่ม Methods:
  # - subscribed?: ตรวจสอบว่ามีสมาชิกที่ใช้งานได้หรือไม่
  # - subscription_active?: ตรวจสอบสถานะสมาชิก
  # - current_plan: แผนสมาชิกปัจจุบัน
  # - can_access?(feature): ตรวจสอบสิทธิ์การเข้าถึงฟีเจอร์
  # - subscription_expires_at: วันที่สมาชิกหมดอายุ
  # - days_until_subscription_expires: จำนวนวันที่เหลือ
  # - subscription_expired?: ตรวจสอบว่าสมาชิกหมดอายุหรือไม่
  
  # เพิ่ม Roles:
  # - admin?: สำหรับตรวจสอบสิทธิ์แอดมิน
  # - subscriber?: สำหรับตรวจสอบว่าเป็นสมาชิกหรือไม่
  ```

### สัปดาห์ที่ 2: Services และ Logic หลัก

#### Service Layer Development

- [ ] **`SubscriptionService`**
  ```ruby
  class SubscriptionService
    # Methods ที่ต้องมี:
    
    # activate_subscription(user, plan, payment_slip)
    # - ตรวจสอบความถูกต้องของการชำระเงิน
    # - เปิดใช้งานสมาชิกใหม่
    # - ปิดการใช้งานสมาชิกเก่า (ถ้ามี)
    # - ส่งอีเมลยืนยัน
    # - สร้าง activity log
    
    # renew_subscription(subscription, months = 1)
    # - ต่ออายุสมาชิก
    # - คำนวณวันหมดอายุใหม่
    # - อัปเดตสถานะการชำระเงิน
    # - ส่งการแจ้งเตือน
    
    # expire_subscription(subscription)
    # - เปลี่ยนสถานะเป็น expired
    # - จำกัดการเข้าถึงฟีเจอร์
    # - ส่งการแจ้งเตือน
    # - สร้าง grace period (ถ้าต้องการ)
    
    # check_expiring_subscriptions
    # - ค้นหาสมาชิกที่จะหมดอายุใน 7, 3, 1 วัน
    # - ส่งการแจ้งเตือนแต่ละระดับ
    # - สร้างรายงานสำหรับแอดมิน
    
    # upgrade_subscription(user, new_plan)
    # - อัปเกรดแผนสมาชิก
    # - คำนวณค่าใช้จ่ายเพิ่มเติม (prorated)
    # - อัปเดตสิทธิ์การเข้าถึง
    
    # cancel_subscription(subscription, reason = nil)
    # - ยกเลิกสมาชิก
    # - จัดการ refund policy
    # - ส่งการแจ้งเตือน
    # - สร้าง cancellation log
  end
  ```

- [ ] **`PaymentProcessor`**
  ```ruby
  class PaymentProcessor
    # verify_payment_slip(payment_slip, admin_user, notes = nil)
    # - ตรวจสอบความถูกต้องของสลิป
    # - อัปเดตสถานะการชำระเงิน
    # - เปิดใช้งานสมาชิก (ถ้าถูกต้อง)
    # - ส่งการแจ้งเตือนให้ผู้ใช้
    # - สร้าง audit trail
    
    # reject_payment_slip(payment_slip, admin_user, reason)
    # - ปฏิเสธการชำระเงิน
    # - ส่งการแจ้งเตือนพร้อมเหตุผล
    # - อนุญาตให้อัปโหลดสลิปใหม่
    
    # process_pending_payments
    # - ประมวลผลการชำระเงินที่รอดำเนินการ
    # - ตรวจสอบสลิปที่เก่าเกินไป
    # - ส่งการแจ้งเตือนให้แอดมิน
    
    # validate_slip_image(image)
    # - ตรวจสอบประเภทไฟล์
    # - ตรวจสอบขนาดไฟล์
    # - ตรวจสอบความชัดเจนของภาพ (ถ้าเป็นไปได้)
    
    # generate_payment_reference(user, amount)
    # - สร้างเลขอ้างอิงการชำระเงิน
    # - ใช้สำหรับการติดตาม
  end
  ```

- [ ] **`NotificationService`**
  ```ruby
  class NotificationService
    # subscription_activated(user_subscription)
    # - ส่งอีเมลยืนยันการเปิดใช้งาน
    # - ส่ง in-app notification
    # - อัปเดต dashboard
    
    # subscription_expiring(user_subscription, days_left)
    # - ส่งการแจ้งเตือนการหมดอายุ
    # - แสดง renewal options
    # - สร้าง urgency ตามจำนวนวันที่เหลือ
    
    # payment_verified(payment_slip)
    # - แจ้งผลการตรวจสอบการชำระเงิน
    # - ส่งใบเสร็จรับเงิน
    
    # payment_rejected(payment_slip, reason)
    # - แจ้งการปฏิเสธการชำระเงิน
    # - อธิบายเหตุผลและขั้นตอนการแก้ไข
    
    # admin_payment_pending(payment_slip)
    # - แจ้งแอดมินมีการชำระเงินใหม่
    # - รวมข้อมูลสำคัญสำหรับการตรวจสอบ
    
    # bulk_expiry_report(subscriptions)
    # - รายงานสมาชิกที่จะหมดอายุ
    # - ส่งให้แอดมินเป็นรายวัน/รายสัปดาห์
  end
  ```

#### Access Control Implementation

- [ ] **Subscription Middleware (`SubscriptionRequired`)**
  ```ruby
  class SubscriptionRequired
    # before_action สำหรับ controllers ที่ต้องการสมาชิก
    
    # check_subscription
    # - ตรวจสอบว่าผู้ใช้มีสมาชิกที่ใช้งานได้
    # - ตรวจสอบว่าสมาชิกยังไม่หมดอายุ
    # - ตรวจสอบสิทธิ์การเข้าถึงฟีเจอร์เฉพาะ
    
    # handle_expired_subscription
    # - redirect ไปหน้าต่ออายุสมาชิก
    # - แสดงข้อความแจ้งเตือน
    # - เก็บ intended URL สำหรับ redirect กลับ
    
    # handle_insufficient_privileges
    # - แสดงหน้าอัปเกรดแผน
    # - อธิบายฟีเจอร์ที่ต้องการแผนที่สูงกว่า
    
    # grace_period_check
    # - ตรวจสอบ grace period (ถ้ามี)
    # - อนุญาตการใช้งานแบบจำกัด
  end
  ```

- [ ] **Admin Authorization (`AdminRequired`)**
  ```ruby
  class AdminRequired
    # verify_admin_access
    # - ตรวจสอบ role ของผู้ใช้
    # - ตรวจสอบสิทธิ์เฉพาะ (เช่น payment verification)
    
    # log_admin_action
    # - บันทึกการกระทำของแอดมิน
    # - เก็บ IP address และ timestamp
    # - สร้าง audit trail
    
    # require_two_factor_auth (ถ้าจำเป็น)
    # - ตรวจสอบ 2FA สำหรับการกระทำที่สำคัญ
  end
  ```

#### Background Jobs

- [ ] **`SubscriptionExpiryJob`**
  ```ruby
  # ทำงานทุกวันเวลา 09:00
  # - ตรวจสอบสมาชิกที่หมดอายุ
  # - ส่งการแจ้งเตือน
  # - อัปเดตสถานะ
  # - สร้างรายงาน
  ```

- [ ] **`PaymentReminderJob`**
  ```ruby
  # ทำงานทุก 6 ชั่วโมง
  # - ตรวจสอบการชำระเงินที่รอดำเนินการ
  # - ส่งการแจ้งเตือนให้แอดมิน
  # - ตรวจสอบสลิปที่เก่าเกินไป
  ```

---

## 🚀 Phase 2: ระบบขนส่งแบบยืดหยุน (สัปดาห์ที่ 3-4)
**เป้าหมาย**: สร้างระบบจัดการขนส่งที่ยืดหยุน รองรับการตั้งค่าอัตราค่าขนส่งแบบต่างๆ

### สัปดาห์ที่ 3: โครงสร้างระบบขนส่ง

#### การออกแบบฐานข้อมูล

- [ ] **สร้างตาราง `shipping_providers`** (ผู้ให้บริการขนส่ง)
  - `id` - รหัสผู้ให้บริการ (Primary Key)
  - `name` - ชื่อบริษัทขนส่ง (String, เช่น "ไปรษณีย์ไทย", "Kerry Express")
  - `code` - รหัสย่อ (String, เช่น "TH_POST", "KERRY")
  - `description` - รายละเอียดบริการ (Text)
  - `config` - การตั้งค่าเฉพาะ (JSON, สำหรับการตั้งค่า API และพารามิเตอร์ต่างๆ)
  - `api_endpoint` - URL สำหรับเชื่อมต่อ API (String, optional)
  - `api_key` - API key (String, encrypted)
  - `active` - สถานะการใช้งาน (Boolean)
  - `supports_tracking` - รองรับการติดตาม (Boolean)
  - `supports_cod` - รองรับเก็บเงินปลายทาง (Boolean)
  - `min_weight` - น้ำหนักขั้นต่ำ (Decimal, grams)
  - `max_weight` - น้ำหนักสูงสุด (Decimal, grams)
  - `created_at`, `updated_at`
  - **Indexes**: code (unique), active

- [ ] **สร้างตาราง `user_shipping_settings`** (การตั้งค่าขนส่งของผู้ใช้)
  - `id` - รหัสการตั้งค่า (Primary Key)
  - `user_id` - รหัสผู้ใช้ (Foreign Key → users.id)
  - `default_provider_id` - ผู้ให้บริการหลัก (Foreign Key → shipping_providers.id)
  - `backup_provider_id` - ผู้ให้บริการสำรอง (Foreign Key, optional)
  - `settings` - การตั้งค่าเพิ่มเติม (JSON)
  - `sender_name` - ชื่อผู้ส่ง (String)
  - `sender_phone` - เบอร์โทรผู้ส่ง (String)
  - `sender_address` - ที่อยู่ผู้ส่ง (Text)
  - `sender_province` - จังหวัดผู้ส่ง (String)
  - `sender_postal_code` - รหัสไปรษณีย์ผู้ส่ง (String)
  - `auto_select_cheapest` - เลือกราคาถูกที่สุดอัตโนมัติ (Boolean)
  - `insurance_default` - ประกันภัยเริ่มต้น (Boolean)
  - `cod_available` - เปิดใช้เก็บเงินปลายทาง (Boolean)
  - `created_at`, `updated_at`
  - **Indexes**: user_id (unique)

- [ ] **สร้างตาราง `shipping_rates`** (อัตราค่าขนส่ง)
  - `id` - รหัสอัตราค่าขนส่ง (Primary Key)
  - `user_id` - รหัสผู้ใช้ (Foreign Key → users.id)
  - `shipping_provider_id` - ผู้ให้บริการ (Foreign Key → shipping_providers.id)
  - `zone_name` - ชื่อเขต (String, เช่น "กรุงเทพและปริมณฑล", "ต่างจังหวัด")
  - `zone_type` - ประเภทเขต (Enum: "domestic", "international")
  - `provinces` - รายชื่อจังหวัด (JSON array)
  - `base_rate` - ค่าขนส่งพื้นฐาน (Decimal)
  - `per_kg_rate` - ค่าขนส่งต่อกิโลกรัม (Decimal)
  - `per_item_rate` - ค่าขนส่งต่อชิ้น (Decimal, optional)
  - `min_weight` - น้ำหนักขั้นต่ำ (Decimal, grams)
  - `max_weight` - น้ำหนักสูงสุด (Decimal, grams)
  - `min_charge` - ค่าขนส่งขั้นต่ำ (Decimal)
  - `max_charge` - ค่าขนส่งสูงสุด (Decimal, optional)
  - `delivery_days` - จำนวนวันที่ส่ง (Integer)
  - `active` - สถานะการใช้งาน (Boolean)
  - `priority` - ลำดับความสำคัญ (Integer, สำหรับการเรียงลำดับ)
  - `effective_from` - วันที่เริ่มใช้อัตรานี้ (Date)
  - `effective_until` - วันที่สิ้นสุดอัตรานี้ (Date, optional)
  - `created_at`, `updated_at`
  - **Indexes**: user_id, shipping_provider_id, zone_name, active

#### Models และ Services

- [ ] **โมเดล `ShippingProvider`**
  ```ruby
  # Validations:
  # - name presence และ uniqueness
  # - code presence, uniqueness, format (uppercase + underscore)
  # - config valid JSON format
  # - weight ranges logical (min < max)
  
  # Scopes:
  # - active: ผู้ให้บริการที่เปิดใช้งาน
  # - supports_tracking: รองรับการติดตาม
  # - supports_cod: รองรับเก็บเงินปลายทาง
  # - for_weight(weight): กรองตามน้ำหนักที่รองรับ
  
  # Methods:
  # - api_configured?: ตรวจสอบว่าตั้งค่า API แล้วหรือไม่
  # - calculate_rate(weight, zone): คำนวณค่าขนส่งพื้นฐาน
  # - supports_weight?(weight): ตรวจสอบว่ารองรับน้ำหนักนี้หรือไม่
  # - get_tracking_info(tracking_number): ดึงข้อมูลการติดตาม
  # - estimate_delivery_date(zone): ประมาณวันที่ส่ง
  ```

- [ ] **โมเดล `UserShippingSettings`**
  ```ruby
  # Associations:
  # - belongs_to :user
  # - belongs_to :default_provider, class_name: 'ShippingProvider'
  # - belongs_to :backup_provider, class_name: 'ShippingProvider', optional: true
  # - has_many :shipping_rates
  
  # Validations:
  # - user_id uniqueness
  # - sender_name, sender_phone, sender_address presence
  # - sender_postal_code format
  # - settings valid JSON
  
  # Methods:
  # - complete_address: ที่อยู่ผู้ส่งแบบเต็ม
  # - available_providers: ผู้ให้บริการที่ใช้ได้
  # - get_setting(key, default = nil): ดึงค่าการตั้งค่า
  # - update_setting(key, value): อัปเดตการตั้งค่า
  # - validate_sender_info: ตรวจสอบข้อมูลผู้ส่ง
  ```

- [ ] **โมเดล `ShippingRate`**
  ```ruby
  # Associations:
  # - belongs_to :user
  # - belongs_to :shipping_provider
  
  # Validations:
  # - zone_name presence
  # - base_rate, per_kg_rate numericality >= 0
  # - min_weight < max_weight
  # - provinces valid JSON array
  # - effective_from <= effective_until
  
  # Scopes:
  # - active: อัตราที่ใช้งานได้
  # - current: อัตราที่มีผลในปัจจุบัน
  # - for_province(province): กรองตามจังหวัด
  # - by_priority: เรียงตามลำดับความสำคัญ
  
  # Methods:
  # - calculate_cost(weight, items = 1): คำนวณค่าขนส่ง
  # - covers_province?(province): ตรวจสอบว่าครอบคลุมจังหวัดนี้หรือไม่
  # - effective?: ตรวจสอบว่ายังใช้งานได้หรือไม่
  # - province_list: รายชื่อจังหวัดที่ครอบคลุม
  # - rate_summary: สรุปอัตราค่าขนส่ง
  ```

- [ ] **Service `ShippingCalculator`**
  ```ruby
  class ShippingCalculator
    # calculate_shipping_cost(user, destination_province, weight, items = 1)
    # - ค้นหาอัตราค่าขนส่งที่เหมาะสม
    # - คำนวณค่าขนส่งตามน้ำหนักและจำนวน
    # - พิจารณาโปรโมชันและส่วนลด
    # - ส่งกลับตัวเลือกทั้งหมดพร้อมราคา
    
    # get_available_options(user, destination, weight, items = 1)
    # - รายการผู้ให้บริการที่ใช้ได้
    # - ประมาณเวลาการส่ง
    # - ค่าใช้จ่ายแต่ละตัวเลือก
    # - ฟีเจอร์พิเศษ (tracking, COD, insurance)
    
    # find_cheapest_option(options)
    # - หาตัวเลือกที่ถูกที่สุด
    # - พิจารณาทั้งราคาและคุณภาพ
    
    # find_fastest_option(options)
    # - หาตัวเลือกที่เร็วที่สุด
    # - พิจารณาเวลาการส่ง
    
    # validate_shipping_data(data)
    # - ตรวจสอบข้อมูลการขนส่ง
    # - ตรวจสอบที่อยู่ปลายทาง
    # - ตรวจสอบน้ำหนักและขนาด
    
    # estimate_delivery_date(provider, zone, order_date = Date.current)
    # - ประมาณวันที่จะส่งถึง
    # - พิจารณาวันหยุดและช่วงเทศกาล
  end
  ```

### สัปดาห์ที่ 4: UI การตั้งค่าขนส่ง

#### Controllers และ Views

- [ ] **`ShippingSettingsController`**
  ```ruby
  # Actions ที่ต้องมี:
  
  # index: แสดงการตั้งค่าปัจจุบัน
  # - ข้อมูลผู้ส่ง
  # - ผู้ให้บริการที่เลือก
  # - อัตราค่าขนส่งที่ตั้งไว้
  
  # edit: ฟอร์มแก้ไขการตั้งค่า
  # - ข้อมูลผู้ส่ง
  # - เลือกผู้ให้บริการ
  # - ตั้งค่าเพิ่มเติม
  
  # update: บันทึกการตั้งค่า
  # - validate ข้อมูล
  # - บันทึกลงฐานข้อมูล
  # - แสดงข้อความยืนยัน
  
  # test_calculation: ทดสอบการคำนวณ
  # - ป้อนข้อมูลจำลอง
  # - แสดงผลการคำนวณ
  # - เปรียบเทียบตัวเลือกต่างๆ
  ```

- [ ] **`ShippingRatesController`**
  ```ruby
  # index: รายการอัตราค่าขนส่งทั้งหมด
  # new: สร้างอัตราใหม่
  # create: บันทึกอัตราใหม่
  # edit: แก้ไขอัตรา
  # update: บันทึกการแก้ไข
  # destroy: ลบอัตรา
  # bulk_update: อัปเดตหลายอัตราพร้อมกัน
  # duplicate: ทำสำเนาอัตราไปยังเขตอื่น
  ```

- [ ] **Views สำหรับการจัดการขนส่ง**
  ```erb
  # shipping_settings/index.html.erb
  # - Dashboard แสดงสถานะการตั้งค่า
  # - Quick actions สำหรับการแก้ไข
  # - สรุปอัตราค่าขนส่งแต่ละเขต
  
  # shipping_settings/edit.html.erb
  # - ฟอร์มแก้ไขข้อมูลผู้ส่ง
  # - เลือกผู้ให้บริการหลักและสำรอง
  # - การตั้งค่าอื่นๆ
  
  # shipping_rates/index.html.erb
  # - ตารางแสดงอัตราค่าขนส่ง
  # - กรองและค้นหาข้อมูล
  # - การจัดการแบบ bulk
  
  # shipping_rates/_form.html.erb
  # - ฟอร์มสร้าง/แก้ไขอัตรา
  # - เลือกจังหวัดแบบ multiple select
  # - คำนวณตัวอย่างแบบ real-time
  
  # shared/_shipping_calculator.html.erb
  # - Component สำหรับคำนวณค่าขนส่ง
  # - ใช้ใน checkout และหน้าอื่นๆ
  # - แสดงตัวเลือกทั้งหมดพร้อมราคา
  ```

#### การผสมผสานกับ Calculator

- [ ] **Real-time Shipping Calculator**
  ```javascript
  // shipping_calculator.js
  
  // calculateShipping(weight, province, items)
  // - เรียก API คำนวณค่าขนส่ง
  // - แสดงผลแบบ real-time
  // - จัดการ loading states
  
  // updateShippingOptions(options)
  // - อัปเดต UI ตัวเลือกขนส่ง
  // - แสดงราคาและเวลาส่ง
  // - เปิดใช้การเลือก
  
  // validateShippingForm()
  // - ตรวจสอบข้อมูลก่อนส่ง
  # - แสดง error messages
  # - disable/enable ปุ่ม submit
  ```

- [ ] **Admin Shipping Management**
  ```ruby
  # Admin::ShippingProvidersController
  # - จัดการผู้ให้บริการขนส่ง
  # - ตั้งค่า API connections
  # - ติดตามสถิติการใช้งาน
  
  # Admin::ShippingRatesController  
  # - ดูอัตราค่าขนส่งของผู้ใช้ทั้งหมด
  # - สร้าง bulk updates
  # - รายงานและวิเคราะห์
  ```

---

## 💳 Phase 3: ระบบเครดิตขั้นสูง (สัปดาห์ที่ 5-6)
**เป้าหมาย**: สร้างระบบเครดิตสำหรับชำระค่าขนส่ง พร้อมการตรวจสอบและบล็อกออเดอร์

### สัปดาห์ที่ 5: โครงสร้างระบบเครดิต

#### ฐานข้อมูลและ Models

- [ ] **สร้างตาราง `user_credits`** (ยอดเครดิตของผู้ใช้)
  - `id` - รหัสเครดิต (Primary Key)
  - `user_id` - รหัสผู้ใช้ (Foreign Key → users.id, unique)
  - `balance` - ยอดคงเหลือ (Decimal, precision: 10, scale: 2)
  - `total_topped_up` - ยอดเติมสะสม (Decimal)
  - `total_used` - ยอดใช้สะสม (Decimal)
  - `total_refunded` - ยอดคืนสะสม (Decimal)
  - `last_transaction_at` - เวลาทำรายการล่าสุด (DateTime)
  - `low_balance_threshold` - เกณฑ์แจ้งเตือนยอดต่ำ (Decimal, default: 100)
  - `auto_topup_enabled` - เติมเงินอัตโนมัติ (Boolean, default: false)
  - `auto_topup_amount` - จำนวนเติมอัตโนมัติ (Decimal)
  - `auto_topup_threshold` - เกณฑ์เติมอัตโนมัติ (Decimal)
  - `status` - สถานะบัญชี (Enum: "active", "suspended", "closed")
  - `created_at`, `updated_at`
  - **Indexes**: user_id (unique), balance, status

- [ ] **สร้างตาราง `credit_transactions`** (ประวัติการทำรายการ)
  - `id` - รหัสทำรายการ (Primary Key)
  - `user_id` - รหัสผู้ใช้ (Foreign Key → users.id)
  - `transaction_type` - ประเภทรายการ (Enum: "topup", "deduction", "refund", "adjustment", "bonus")
  - `amount` - จำนวนเงิน (Decimal, signed: + for credit, - for debit)
  - `balance_before` - ยอดก่อนทำรายการ (Decimal)
  - `balance_after` - ยอดหลังทำรายการ (Decimal)
  - `description` - คำอธิบายรายการ (String)
  - `reference_type` - ประเภทอ้างอิง (String, polymorphic)
  - `reference_id` - รหัสอ้างอิง (Integer, polymorphic)
  - `payment_method` - วิธีการชำระ (String, เช่น "bank_transfer", "credit_card")
  - `payment_reference` - เลขอ้างอิงการชำระ (String)
  - `status` - สถานะรายการ (Enum: "pending", "completed", "failed", "cancelled", "reversed")
  - `processed_at` - เวลาที่ประมวลผล (DateTime)
  - `processed_by_id` - ผู้ประมวลผล (Integer, Foreign Key → users.id)
  - `notes` - หมายเหตุเพิ่มเติม (Text)
  - `external_transaction_id` - รหัสรายการภายนอก (String, สำหรับ API integration)
  - `created_at`, `updated_at`
  - **Indexes**: user_id, transaction_type, status, created_at, reference (polymorphic)

#### Core Logic Implementation

- [ ] **โมเดล `UserCredit`**
  ```ruby
  # Associations:
  # - belongs_to :user
  # - has_many :credit_transactions, dependent: :destroy
  
  # Validations:
  # - user_id uniqueness
  # - balance numericality >= 0
  # - threshold values numericality >= 0
  # - auto_topup_amount > 0 if auto_topup_enabled
  
  # Callbacks:
  # - after_update :check_low_balance, if: :saved_change_to_balance?
  # - after_update :trigger_auto_topup, if: :should_auto_topup?
  
  # Methods:
  # - sufficient_balance?(amount): ตรวจสอบยอดเพียงพอ
  # - deduct(amount, reference, description): หักเครดิต
  # - add(amount, reference, description): เพิ่มเครดิต
  # - calculate_available_balance: คำนวณยอดที่ใช้ได้ (ไม่รวมยอดที่จอง)
  # - reserve_amount(amount, reference): จองเครดิต
  # - release_reservation(amount, reference): ปลดล็อกเครดิต
  # - transaction_history(limit = 50): ประวัติรายการ
  # - low_balance?: ตรวจสอบยอดต่ำ
  # - monthly_usage: การใช้งานรายเดือน
  # - format_balance: แสดงยอดในรูปแบบที่อ่านง่าย
  ```

- [ ] **โมเดล `CreditTransaction`**
  ```ruby
  # Associations:
  # - belongs_to :user
  # - belongs_to :reference, polymorphic: true, optional: true
  # - belongs_to :processed_by, class_name: 'User', optional: true
  
  # Validations:
  # - amount presence และ not zero
  # - balance_before, balance_after numericality >= 0
  # - transaction_type inclusion
  # - description presence
  
  # Scopes:
  # - completed: รายการที่เสร็จสิ้น
  # - pending: รายการที่รอดำเนินการ
  # - by_type(type): กรองตามประเภท
  # - in_date_range(start_date, end_date): กรองตามช่วงวันที่
  # - for_reference(reference): รายการที่เกี่ยวข้องกับ reference
  
  # Methods:
  # - credit?: รายการเพิ่มเครดิต
  # - debit?: รายการหักเครดิต  
  # - complete!: ทำรายการให้เสร็จสิ้น
  # - cancel!(reason): ยกเลิกรายการ
  # - reverse!(reason): ย้อนกลับรายการ
  # - formatted_amount: แสดงจำนวนในรูปแบบที่อ่านง่าย
  # - summary: สรุปรายการ
  ```

- [ ] **Service `CreditService`**
  ```ruby
  class CreditService
    # topup(user, amount, payment_reference, method = 'bank_transfer')
    # - เติมเครดิตให้ผู้ใช้
    # - สร้าง transaction record
    # - ตรวจสอบการชำระเงิน
    # - ส่งการแจ้งเตือน
    # - อัปเดตสถิติ
    
    # deduct(user, amount, reference, description)
    # - หักเครดิตจากผู้ใช้
    # - ตรวจสอบยอดเพียงพอ
    # - สร้าง transaction record
    # - จัดการกรณี insufficient funds
    # - ส่งการแจ้งเตือน
    
    # reserve_for_order(user, order)
    # - จองเครดิตสำหรับออเดอร์
    # - คำนวณค่าขนส่งโดยประมาณ
    # - สร้าง pending transaction
    # - ป้องกันการใช้เครดิตซ้ำ
    
    # charge_shipping_cost(order)
    # - หักค่าขนส่งจริงเมื่อส่งสินค้า
    # - ปลดล็อกเครดิตที่จองไว้
    # - คืนเครดิตส่วนเกิน (ถ้ามี)
    # - อัปเดต order status
    
    # refund(user, amount, reference, reason)
    # - คืนเครดิตให้ผู้ใช้
    # - สร้าง refund transaction
    # - ส่งการแจ้งเตือน
    # - อัปเดตสถิติ
    
    # process_auto_topup(user_credit)
    # - ประมวลผลการเติมเงินอัตโนมัติ
    # - ตรวจสอบเงื่อนไข
    # - สร้างคำสั่งเติมเงิน
    # - ส่งการแจ้งเตือน
    
    # validate_transaction(user, amount, type)
    # - ตรวจสอบความถูกต้องของรายการ
    # - ตรวจสอบ daily/monthly limits
    # - ตรวจสอบสถานะบัญชี
    # - ป้องกัน fraud
    
    # generate_statement(user, start_date, end_date)
    # - สร้างใบแสดงรายการ
    # - สรุปรายรับ-จ่าย
    # - ยอดคงเหลือ
    # - รายการแต่ละวัน
  end
  ```

#### การผสมผสานกับ Order System

- [ ] **Order Integration Logic**
  ```ruby
  # การอัปเดต Order model
  
  # before_create :validate_user_credit
  # - ตรวจสอบเครดิตเพียงพอก่อนสร้างออเดอร์
  # - คำนวณค่าขนส่งโดยประมาณ
  # - จองเครดิต
  # - บล็อกการสร้างถ้าเครดิตไม่พอ
  
  # after_create :reserve_shipping_credit
  # - จองเครดิตสำหรับค่าขนส่ง
  # - สร้าง pending transaction
  # - ส่งการแจ้งเตือนให้ผู้ขาย
  
  # after_update :charge_actual_shipping, if: :shipping_confirmed?
  # - หักค่าขนส่งจริงเมื่อยืนยันการส่ง
  # - ปลดล็อกเครดิตที่จองไว้
  # - คืนเครดิตส่วนเกิน
  # - อัปเดตสถานะออเดอร์
  
  # after_update :refund_shipping_credit, if: :cancelled?
  # - คืนเครดิตเมื่อยกเลิกออเดอร์
  # - ปลดล็อกเครดิตที่จองไว้
  # - สร้าง refund transaction
  
  # Methods เพิ่มเติม:
  # - estimated_shipping_cost: ประมาณค่าขนส่ง
  # - actual_shipping_cost: ค่าขนส่งจริง
  # - credit_reserved?: ตรวจสอบว่าจองเครดิตแล้วหรือไม่
  # - can_be_created_with_current_credit?: ตรวจสอบเครดิตเพียงพอ
  ```

### สัปดาห์ที่ 6: การจัดการเครดิตและการผสมผสานกับออเดอร์

#### Enhanced Order Flow

- [ ] **อัปเดต Order Model**
  ```ruby
  # เพิ่ม fields ใหม่ในตาราง orders:
  # - estimated_shipping_cost (Decimal)
  # - actual_shipping_cost (Decimal)
  # - credit_reserved (Decimal)
  # - credit_charged (Decimal)
  # - shipping_credit_status (Enum: "pending", "reserved", "charged", "refunded")
  
  # เพิ่ม associations:
  # - has_many :credit_transactions, as: :reference
  # - has_one :shipping_credit_reservation, -> { where(transaction_type: 'reserve') }, 
  #           class_name: 'CreditTransaction', as: :reference
  
  # เพิ่ม callbacks:
  # - before_create :validate_seller_credit
  # - after_create :reserve_shipping_credit
  # - before_update :handle_shipping_cost_changes
  # - after_update :process_shipping_credit_changes
  
  # เพิ่ม validations:
  # - validate :sufficient_credit_for_shipping, on: :create
  # - validate :shipping_cost_within_limits
  ```

- [ ] **Credit Management UI**
  ```erb
  # credits/index.html.erb - หน้าหลักเครดิต
  # - แสดงยอดคงเหลือปัจจุบัน
  # - กราฟการใช้งานรายเดือน
  # - รายการทำรายการล่าสุด
  # - ปุ่มเติมเครดิต
  # - การตั้งค่า auto top-up
  
  # credits/topup.html.erb - หน้าเติมเครดิต
  # - เลือกจำนวนเงินที่เติม
  # - แพ็กเกจโบนัส (ถ้ามี)
  # - วิธีการชำระเงิน
  # - อัปโหลดสลิป
  
  # credits/transactions.html.erb - ประวัติรายการ
  # - ตารางรายการทั้งหมด
  # - กรองตามประเภทและวันที่
  # - ดาวน์โหลดใบแสดงรายการ
  # - ค้นหารายการ
  
  # credits/settings.html.erb - การตั้งค่าเครดิต
  # - เกณฑ์แจ้งเตือนยอดต่ำ
  # - การเติมเงินอัตโนมัติ
  # - การแจ้งเตือน
  # - ข้อมูลการชำระเงิน
  ```

- [ ] **Seller Notifications System**
  ```ruby
  # NotificationService เพิ่มเติม:
  
  # low_credit_warning(user, current_balance)
  # - แจ้งเตือนเครดิตต่ำ
  # - แสดงลิงก์เติมเครดิต
  # - ประมาณจำนวนออเดอร์ที่ทำได้อีก
  
  # order_blocked_insufficient_credit(user, order, required_amount)
  # - แจ้งเตือนออเดอร์ถูกบล็อก
  # - แสดงจำนวนเครดิตที่ต้องการ
  # - ลิงก์ไปเติมเครดิต
  
  # credit_topup_confirmed(user, amount, new_balance)
  # - ยืนยันการเติมเครดิต
  # - แสดงยอดใหม่
  # - สรุปรายการ
  
  # shipping_cost_charged(user, order, amount)
  # - แจ้งเตือนการหักค่าขนส่ง
  # - แสดงรายละเอียดออเดอร์
  # - ยอดคงเหลือใหม่
  
  # auto_topup_processed(user, amount)
  # - แจ้งเติมเงินอัตโนมัติ
  # - แสดงการตั้งค่า
  # - ยอดใหม่หลังเติม
  ```

#### Background Jobs สำหรับเครดิต

- [ ] **`CreditMonitoringJob`**
  ```ruby
  # ทำงานทุก 1 ชั่วโมง
  # - ตรวจสอบผู้ใช้ที่มีเครดิตต่ำ
  # - ส่งการแจ้งเตือน
  # - ประมวลผล auto top-up
  # - สร้างรายงานสำหรับแอดมิน
  ```

- [ ] **`CreditTransactionProcessorJob`**
  ```ruby
  # ทำงานทุก 15 นาที
  # - ประมวลผล pending transactions
  # - ตรวจสอบการชำระเงิน
  # - อัปเดตยอดเครดิต
  # - ส่งการแจ้งเตือน
  ```

- [ ] **`CreditStatementGeneratorJob`**
  ```ruby
  # ทำงานทุกวันที่ 1 ของเดือน
  # - สร้างใบแสดงรายการรายเดือน
  # - ส่งอีเมลให้ผู้ใช้
  # - สร้างรายงานสรุป
  # - บันทึกข้อมูลสถิติ
  ```

---

## 📝 Phase 4: ระบบการชำระเงินขั้นสูง (สัปดาห์ที่ 7-8)
**เป้าหมาย**: สร้างระบบการชำระเงินที่รองรับทั้ง subscription และ credit top-up

### สัปดาห์ที่ 7: ระบบการชำระเงินแบบ Multi-purpose

#### การเพิ่มประสิทธิภาพฐานข้อมูล

- [ ] **สร้างตาราง `payments`** (รายการชำระเงินทั่วไป)
  - `id` - รหัสการชำระเงิน (Primary Key)
  - `user_id` - รหัสผู้ใช้ (Foreign Key → users.id)
  - `payable_type` - ประเภทการชำระ (String, polymorphic: "UserSubscription", "UserCredit")
  - `payable_id` - รหัสการชำระ (Integer, polymorphic)
  - `amount` - จำนวนเงิน (Decimal, precision: 10, scale: 2)
  - `currency` - สกุลเงิน (String, default: "THB")
  - `payment_type` - ประเภทการชำระ (Enum: "subscription", "credit_topup", "order_payment")
  - `payment_method` - วิธีการชำระ (Enum: "bank_transfer", "credit_card", "e_wallet", "cash")
  - `status` - สถานะ (Enum: "pending", "processing", "completed", "failed", "cancelled", "refunded")
  - `external_transaction_id` - รหัสรายการภายนอก (String, สำหรับ payment gateway)
  - `gateway_response` - ข้อมูลตอบกลับจาก gateway (JSON)
  - `fee_amount` - ค่าธรรมเนียม (Decimal)
  - `net_amount` - จำนวนสุทธิ (Decimal)
  - `reference_number` - เลขอ้างอิง (String, unique)
  - `description` - คำอธิบาย (Text)
  - `metadata` - ข้อมูลเพิ่มเติม (JSON)
  - `processed_at` - เวลาประมวลผล (DateTime)
  - `expires_at` - เวลาหมดอายุ (DateTime)
  - `created_at`, `updated_at`
  - **Indexes**: user_id, payable (polymorphic), status, reference_number (unique), created_at

- [ ] **สร้างตาราง `payment_verifications`** (การตรวจสอบการชำระเงิน)
  - `id` - รหัสการตรวจสอบ (Primary Key)
  - `payment_id` - รหัสการชำระเงิน (Foreign Key → payments.id)
  - `verification_method` - วิธีการตรวจสอบ (Enum: "manual", "automatic", "webhook")
  - `slip_image` - รูปภาพสลิป (String, Active Storage)
  - `additional_documents` - เอกสารเพิ่มเติม (JSON, Active Storage keys)
  - `bank_name` - ชื่อธนาคาร (String)
  - `account_number` - เลขที่บัญชี (String)
  - `transaction_date` - วันที่ทำรายการ (Date)
  - `transaction_time` - เวลาที่ทำรายการ (Time)
  - `status` - สถานะการตรวจสอบ (Enum: "pending", "in_review", "verified", "rejected", "expired")
  - `verified_by_id` - ผู้ตรวจสอบ (Integer, Foreign Key → users.id)
  - `verified_at` - เวลาที่ตรวจสอบ (DateTime)
  - `verification_notes` - หมายเหตุการตรวจสอบ (Text)
  - `rejection_reason` - เหตุผลการปฏิเสธ (Text)
  - `auto_verification_score` - คะแนนตรวจสอบอัตโนมัติ (Float, 0-100)
  - `risk_flags` - ธงเตือนความเสี่ยง (JSON array)
  - `ip_address` - IP address ของผู้ส่ง (String)
  - `user_agent` - User agent ของผู้ส่ง (String)
  - `created_at`, `updated_at`
  - **Indexes**: payment_id, status, verified_by_id, created_at

#### Enhanced Features Implementation

- [ ] **Polymorphic Payment System**
  ```ruby
  # โมเดล Payment
  class Payment < ApplicationRecord
    # Polymorphic association
    belongs_to :payable, polymorphic: true
    belongs_to :user
    has_many :payment_verifications, dependent: :destroy
    has_one :current_verification, -> { order(created_at: :desc) }, 
            class_name: 'PaymentVerification'
  
    # State machine
    state_machine :status, initial: :pending do
      event :process do
        transition pending: :processing
      end
      
      event :complete do
        transition processing: :completed
      end
      
      event :fail do
        transition [:pending, :processing] => :failed
      end
      
      event :cancel do
        transition [:pending, :processing] => :cancelled
      end
      
      event :refund do
        transition completed: :refunded
      end
      
      # Callbacks
      after_transition to: :completed do |payment|
        payment.payable.process_payment_completion(payment)
      end
      
      after_transition to: :failed do |payment|
        payment.payable.handle_payment_failure(payment)
      end
    end
  
    # Methods
    def generate_reference_number
      "PAY#{Time.current.strftime('%Y%m%d')}#{SecureRandom.hex(4).upcase}"
    end
  
    def calculate_fee
      # คำนวณค่าธรรมเนียมตาม payment method
      case payment_method
      when 'credit_card'
        (amount * 0.025).round(2) # 2.5%
      when 'bank_transfer'
        15.0 # ค่าธรรมเนียมคงที่
      else
        0.0
      end
    end
  
    def net_amount
      amount - (fee_amount || 0)
    end
  
    def can_be_refunded?
      completed? && created_at > 30.days.ago
    end
  
    def formatted_amount(include_currency: true)
      formatted = "#{amount.to_i.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
      include_currency ? "฿#{formatted}" : formatted
    end
  end
  ```

- [ ] **Image Processing Enhancement**
  ```ruby
  # PaymentVerification model
  class PaymentVerification < ApplicationRecord
    belongs_to :payment
    belongs_to :verified_by, class_name: 'User', optional: true
    
    has_one_attached :slip_image
    has_many_attached :additional_documents
    
    # Image validations
    validates :slip_image, presence: true
    validate :slip_image_format
    validate :slip_image_size
    
    # Auto-verification logic
    after_create :analyze_slip_image
    
    private
    
    def slip_image_format
      return unless slip_image.attached?
      
      acceptable_types = ['image/jpeg', 'image/png', 'application/pdf']
      unless acceptable_types.include?(slip_image.content_type)
        errors.add(:slip_image, 'must be JPEG, PNG, or PDF')
      end
    end
    
    def slip_image_size
      return unless slip_image.attached?
      
      if slip_image.byte_size > 5.megabytes
        errors.add(:slip_image, 'must be less than 5MB')
      end
    end
    
    def analyze_slip_image
      # OCR และ image analysis สำหรับ auto-verification
      SlipAnalysisJob.perform_later(self)
    end
  end
  ```

- [ ] **Admin Verification Dashboard**
  ```ruby
  # Admin::PaymentVerificationsController
  class Admin::PaymentVerificationsController < AdminController
    before_action :require_payment_admin
    
    def index
      @verifications = PaymentVerification.includes(:payment, :verified_by)
                                         .pending_review
                                         .order(created_at: :desc)
                                         .page(params[:page])
      
      @stats = {
        pending: PaymentVerification.pending.count,
        verified_today: PaymentVerification.verified.where(verified_at: Date.current.all_day).count,
        total_amount_pending: Payment.joins(:payment_verifications)
                                    .where(payment_verifications: { status: 'pending' })
                                    .sum(:amount)
      }
    end
    
    def show
      @verification = PaymentVerification.find(params[:id])
      @payment = @verification.payment
      @user = @payment.user
      @history = @user.payments.includes(:payment_verifications)
                               .order(created_at: :desc)
                               .limit(10)
    end
    
    def verify
      @verification = PaymentVerification.find(params[:id])
      
      if @verification.verify!(current_user, verification_params[:notes])
        redirect_to admin_payment_verification_path(@verification),
                    notice: 'Payment verified successfully'
      else
        redirect_to admin_payment_verification_path(@verification),
                    alert: 'Failed to verify payment'
      end
    end
    
    def reject
      @verification = PaymentVerification.find(params[:id])
      
      if @verification.reject!(current_user, rejection_params[:reason])
        redirect_to admin_payment_verification_path(@verification),
                    notice: 'Payment rejected'
      else
        redirect_to admin_payment_verification_path(@verification),
                    alert: 'Failed to reject payment'
      end
    end
    
    def bulk_action
      verification_ids = params[:verification_ids]
      action = params[:bulk_action]
      
      case action
      when 'verify'
        process_bulk_verification(verification_ids)
      when 'reject'
        process_bulk_rejection(verification_ids)
      end
      
      redirect_to admin_payment_verifications_path
    end
    
    private
    
    def verification_params
      params.require(:payment_verification).permit(:notes)
    end
    
    def rejection_params
      params.require(:payment_verification).permit(:reason)
    end
  end
  ```

### สัปดาห์ที่ 8: การผสมผสานและการทดสอบ

#### System Integration

- [ ] **เชื่อมต่อระบบการชำระเงินกับ Subscriptions และ Credits**
  ```ruby
  # UserSubscription เพิ่ม payment interface
  class UserSubscription < ApplicationRecord
    has_many :payments, as: :payable
    
    def process_payment_completion(payment)
      # เมื่อการชำระเงินสำเร็จ
      activate! if pending?
      extend_subscription_period
      send_activation_notification
    end
    
    def handle_payment_failure(payment)
      # เมื่อการชำระเงินล้มเหลว
      mark_payment_failed
      send_failure_notification
      schedule_retry if auto_retry_enabled?
    end
  end
  
  # UserCredit เพิ่ม payment interface
  class UserCredit < ApplicationRecord
    has_many :payments, as: :payable
    
    def process_payment_completion(payment)
      # เมื่อการเติมเครดิตสำเร็จ
      add_credit(payment.net_amount)
      create_transaction_record(payment)
      send_topup_confirmation
    end
    
    def handle_payment_failure(payment)
      # เมื่อการเติมเครดิตล้มเหลว
      send_failure_notification
      suggest_alternative_methods
    end
  end
  ```

- [ ] **Third-party Payment Gateway Preparation**
  ```ruby
  # PaymentGateway abstraction
  class PaymentGateway
    def self.for(method)
      case method
      when 'credit_card'
        OmiseGateway.new
      when 'promptpay'
        PromptPayGateway.new
      when 'bank_transfer'
        BankTransferGateway.new
      else
        ManualGateway.new
      end
    end
  end
  
  # Example gateway implementation
  class OmiseGateway < PaymentGateway
    def create_charge(payment)
      # สร้าง charge ผ่าน Omise API
      # return { success: true/false, transaction_id: '', message: '' }
    end
    
    def verify_charge(transaction_id)
      # ตรวจสอบสถานะ charge
    end
    
    def refund_charge(transaction_id, amount)
      # คืนเงิน
    end
  end
  ```

- [ ] **Comprehensive Testing Suite**
  ```ruby
  # Test scenarios ที่ต้องครอบคลุม:
  
  # Unit Tests:
  # - Model validations และ associations
  # - Service methods และ calculations
  # - State machine transitions
  # - Payment processing logic
  
  # Integration Tests:
  # - Complete subscription flow
  # - Credit top-up process
  # - Order creation with credit validation
  # - Payment verification workflow
  # - Admin management interfaces
  
  # System Tests:
  # - End-to-end user journeys
  # - Payment failure scenarios
  # - Admin verification process
  # - Notification delivery
  # - Background job processing
  
  # Performance Tests:
  # - Database query optimization
  # - Image processing performance
  # - Concurrent payment processing
  # - Large dataset handling
  ```

#### Final Integration Testing

- [ ] **User Journey Testing**
  ```ruby
  # Test Case 1: New User Subscription
  # 1. User สมัครสมาชิก
  # 2. เลือกแผนและอัปโหลดสลิป
  # 3. Admin ตรวจสอบและอนุมัติ
  # 4. User ได้รับการแจ้งเตือน
  # 5. ระบบเปิดใช้งานสมาชิก
  
  # Test Case 2: Credit Top-up and Order Creation
  # 1. User เติมเครดิต
  # 2. Admin อนุมัติการเติม
  # 3. User สร้างออเดอร์
  # 4. ระบบตรวจสอบและจองเครดิต
  # 5. เมื่อส่งสินค้า ระบบหักค่าขนส่งจริง
  
  # Test Case 3: Subscription Renewal
  # 1. ระบบแจ้งเตือนการหมดอายุ
  # 2. User ต่ออายุสมาชิก
  # 3. อัปโหลดสลิปการชำระเงิน
  # 4. Admin ตรวจสอบ
  # 5. ระบบต่ออายุสมาชิก
  ```

---

## 🔧 รายละเอียดการใช้งานเทคนิค

### Service Layer Architecture
```ruby
# โครงสร้าง Services หลัก
app/services/
├── subscription_service.rb      # จัดการ subscription lifecycle
├── credit_service.rb           # จัดการ credit transactions
├── payment_processor.rb        # ประมวลผลการชำระเงิน
├── shipping_calculator.rb      # คำนวณค่าขนส่ง
├── notification_service.rb     # ส่งการแจ้งเตือน
├── order_validator.rb          # ตรวจสอบ order ก่อนสร้าง
├── slip_analyzer.rb            # วิเคราะห์สลิปการชำระเงิน
└── report_generator.rb         # สร้างรายงานต่างๆ
```

### Middleware และ Concerns
```ruby
# Access Control Middleware
app/controllers/concerns/
├── subscription_required.rb    # ตรวจสอบสมาชิก
├── credit_validation.rb        # ตรวจสอบเครดิต
├── admin_required.rb           # สิทธิ์แอดมิน
└── rate_limiting.rb            # จำกัดอัตราการเข้าถึง

# Model Concerns
app/models/concerns/
├── payable.rb                  # Interface การชำระเงิน
├── notifiable.rb               # Interface การแจ้งเตือน
├── trackable.rb                # การติดตามกิจกรรม
└── auditable.rb                # Audit trail
```

### Background Jobs
```ruby
# Jobs สำหรับงานที่ทำงานในพื้นหลัง
app/jobs/
├── subscription_expiry_job.rb          # ตรวจสอบการหมดอายุ
├── payment_reminder_job.rb             # เตือนการชำระเงิน
├── credit_monitoring_job.rb            # ติดตามเครดิต
├── slip_analysis_job.rb                # วิเคราะห์สลิป
├── notification_delivery_job.rb        # ส่งการแจ้งเตือน
├── report_generation_job.rb            # สร้างรายงาน
└── cleanup_expired_payments_job.rb     # ทำความสะอาดข้อมูล
```

---

## 🛡️ การรักษาความปลอดภัยและประสิทธิภาพ

### มาตรการความปลอดภัย

- [ ] **การตรวจสอบและป้องกัน**
  - Input validation และ sanitization ทุกจุด
  - File upload security (ประเภท, ขนาด, content validation)
  - SQL injection prevention
  - XSS protection
  - CSRF protection
  - Rate limiting สำหรับ sensitive actions

- [ ] **การจัดการข้อมูลการชำระเงิน**
  - เข้ารหัสข้อมูลสำคัญ (API keys, payment details)
  - Secure file storage สำหรับสลิป
  - PCI DSS compliance (สำหรับ credit card)
  - Audit trail สำหรับการกระทำของแอดมิน

- [ ] **การควบคุมการเข้าถึง**
  - Role-based access control
  - Two-factor authentication สำหรับแอดมิน
  - Session management
  - IP whitelisting สำหรับ admin functions

### การเพิ่มประสิทธิภาพ

- [ ] **Database Optimization**
  - Index strategy สำหรับ queries ที่ใช้บ่อย
  - Query optimization และ N+1 prevention
  - Database partitioning สำหรับข้อมูลขนาดใหญ่
  - Connection pooling

- [ ] **Caching Strategy**
  - Redis caching สำหรับ frequent queries
  - Fragment caching สำหรับ expensive views
  - CDN สำหรับ static assets
  - Browser caching optimization

- [ ] **Background Processing**
  - Sidekiq หรือ similar สำหรับ heavy operations
  - Job queues และ priority management
  - Error handling และ retry logic
  - Monitoring และ alerting

---

## 📊 กลยุทธ์การทดสอบ

### Unit Testing
- [ ] **Model Testing**
  - Validations และ associations
  - Custom methods และ calculations
  - State machine transitions
  - Callbacks และ hooks

- [ ] **Service Testing**
  - Business logic correctness
  - Error handling
  - Edge cases
  - Integration points

### Integration Testing
- [ ] **API Testing**
  - Controller actions
  - Authentication และ authorization
  - Parameter validation
  - Response format

- [ ] **Workflow Testing**
  - Complete user journeys
  - Cross-system interactions
  - Error scenarios
  - Recovery mechanisms

### System Testing
- [ ] **End-to-End Testing**
  - Browser automation
  - User interface testing
  - Performance testing
  - Load testing

### Security Testing
- [ ] **Penetration Testing**
  - Input validation bypass
  - Authentication bypass
  - Authorization flaws
  - File upload vulnerabilities

---

## 🚀 การ Deploy และ Monitoring

### Deployment Checklist
- [ ] **Database Setup**
  - Run migrations
  - Seed initial data
  - Set up indexes
  - Configure backups

- [ ] **Environment Configuration**
  - Environment variables
  - SSL certificates
  - Domain configuration
  - CDN setup

- [ ] **Service Configuration**
  - Background job queues
  - Caching servers
  - Log management
  - Monitoring tools

### Monitoring และ Alerts
- [ ] **Application Monitoring**
  - Error tracking (Sentry, Bugsnag)
  - Performance monitoring (New Relic, Datadog)
  - Uptime monitoring
  - Log aggregation

- [ ] **Business Metrics**
  - Subscription conversion rates
  - Payment success rates
  - Credit usage patterns
  - System performance metrics

- [ ] **Automated Alerts**
  - System errors
  - Payment failures
  - High resource usage
  - Security incidents

---

## 📈 การปรับปรุงในอนาคต (Post-Launch)

### Phase 5+: คุณสมบัติขั้นสูง
- [ ] **API Integration**
  - เชื่อมต่อกับ shipping providers จริง
  - Real-time tracking
  - Automated rate updates
  - Bulk shipping operations

- [ ] **Payment Gateway Integration**
  - Credit card processing
  - E-wallet integration
  - Cryptocurrency support
  - Automated recurring payments

- [ ] **Mobile Application**
  - Native iOS/Android apps
  - Push notifications
  - Offline functionality
  - Mobile-specific features

- [ ] **Advanced Analytics**
  - Business intelligence dashboard
  - Predictive analytics
  - Customer behavior analysis
  - Revenue optimization

### Scalability Considerations
- [ ] **Architecture Evolution**
  - Microservices migration
  - Event-driven architecture
  - API-first design
  - Cloud-native deployment

- [ ] **Performance Optimization**
  - Database sharding
  - Load balancing
  - Auto-scaling
  - Global CDN

- [ ] **Multi-tenant Support**
  - White-label solutions
  - Custom branding
  - Isolated data
  - Flexible pricing models

---

## 📋 สรุปไทม์ไลน์โครงการ

| Phase | ระยะเวลา | ส่วนประกอบหลัก | เป้าหมายสำคัญ |
|-------|----------|-----------------|----------------|
| **Phase 1** | สัปดาห์ที่ 1-2 | ระบบสมาชิกรายเดือน | สร้างฐานรายได้แบบ recurring |
| **Phase 2** | สัปดาห์ที่ 3-4 | ระบบขนส่งแบบยืดหยุน | รองรับการขนส่งที่หลากหลาย |
| **Phase 3** | สัปดาห์ที่ 5-6 | ระบบเครดิตขั้นสูง | ควบคุมค่าใช้จ่ายการขนส่ง |
| **Phase 4** | สัปดาห์ที่ 7-8 | ระบบการชำระเงินรวม | รองรับการชำระเงินครบวงจร |
| **รวมทั้งหมด** | **8 สัปดาห์** | **ระบบครบถ้วน** | **พร้อมใช้งานจริง** |

### จุดสำคัญในแต่ละ Phase
1. **Phase 1**: สร้างรายได้จากการสมัครสมาชิก
2. **Phase 2**: เพิ่มความยืดหยุนในการจัดส่ง
3. **Phase 3**: ควบคุมต้นทุนและป้องกันการใช้เกิน
4. **Phase 4**: รองรับการเติบโตและ scalability

---

*อัปเดตล่าสุด: <%= Time.current.strftime("%d/%m/%Y %H:%M") %>*
*เวอร์ชัน: 1.0 - แผนการพัฒนาแบบละเอียด*