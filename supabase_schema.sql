-- ==============================================================================
-- สคริปต์สร้างฐานข้อมูล Supabase สำหรับระบบคลังจุลินทรีย์และบัญชีสรุป
-- ศูนย์ผลิตจุลินทรีย์ โรงพยาบาล ๕๐ พรรษา มหาวชิรลงกรณ
-- ==============================================================================

-- 1. ลบตารางเดิมหากมีอยู่ (CASCADE เพื่อความปลอดภัยในการ Init ใหม่)
DROP TABLE IF EXISTS public.financials CASCADE;
DROP TABLE IF EXISTS public.transactions CASCADE;
DROP TABLE IF EXISTS public.stock CASCADE;
DROP TABLE IF EXISTS public.master_items CASCADE;
DROP TABLE IF EXISTS public.categories CASCADE;
DROP TABLE IF EXISTS public.customers CASCADE;
DROP TABLE IF EXISTS public.products CASCADE;
DROP TABLE IF EXISTS public.app_users CASCADE;

-- 2. สร้างตาราง: app_users (จัดการผู้ใช้งานระบบ)
CREATE TABLE public.app_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(50) DEFAULT 'Viewer' CHECK (role IN ('Admin', 'User', 'Viewer')),
    full_name VARCHAR(255) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 3. สร้างตาราง: products (รายชื่อสินค้าหลัก - Master Products)
CREATE TABLE public.products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_code VARCHAR(50) UNIQUE NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    product_type VARCHAR(100) DEFAULT 'ผลิตภัณฑ์',
    unit VARCHAR(50) DEFAULT 'แกลลอน',
    selling_price NUMERIC(12, 2) DEFAULT 0.00,
    cost_price NUMERIC(12, 2) DEFAULT 0.00,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 4. สร้างตาราง: customers (รายชื่อหน่วยงาน / ลูกค้า)
CREATE TABLE public.customers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_code VARCHAR(50) UNIQUE NOT NULL,
    customer_name VARCHAR(255) NOT NULL,
    customer_type VARCHAR(100) DEFAULT 'หน่วยงานภายใน',
    contact_info VARCHAR(255),
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 5. สร้างตาราง: categories (แยกประเภท / หมวดหมู่หลัก)
CREATE TABLE public.categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_code VARCHAR(50) UNIQUE NOT NULL,
    category_name VARCHAR(255) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 6. สร้างตาราง: master_items (แยกรายการบัญชี)
CREATE TABLE public.master_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    item_code VARCHAR(50) UNIQUE NOT NULL,
    item_name VARCHAR(255) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 7. สร้างตาราง: stock (คลังสินค้าปัจจุบัน)
CREATE TABLE public.stock (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_code VARCHAR(50) UNIQUE NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    unit VARCHAR(50) DEFAULT 'แกลลอน',
    qty NUMERIC(12, 2) DEFAULT 0,
    avg_cost NUMERIC(12, 2) DEFAULT 0.00,
    total_value NUMERIC(14, 2) DEFAULT 0.00,
    reorder_point NUMERIC(12, 2) DEFAULT 10,
    status VARCHAR(50) DEFAULT 'ปกติ',
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- 8. สร้างตาราง: transactions (ประวัติธุรกรรม รับเข้า / จ่ายออก)
CREATE TABLE public.transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_date DATE DEFAULT CURRENT_DATE,
    doc_number VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL, -- 'รับเข้า' หรือ 'จ่ายออก'
    transaction_type VARCHAR(255) NOT NULL,
    product_code VARCHAR(50) NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    qty NUMERIC(12, 2) NOT NULL DEFAULT 1,
    unit_price NUMERIC(12, 2) DEFAULT 0.00,
    total_value NUMERIC(14, 2) DEFAULT 0.00,
    customer_name VARCHAR(255) DEFAULT 'ไม่ระบุ',
    recorded_by VARCHAR(255) DEFAULT 'System',
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 9. สร้างตาราง: financials (บันทึกบัญชีรายรับ-รายจ่าย)
CREATE TABLE public.financials (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_date DATE DEFAULT CURRENT_DATE,
    doc_number VARCHAR(100) NOT NULL,
    main_category VARCHAR(50) NOT NULL, -- 'รายรับ' หรือ 'รายจ่าย'
    category_name VARCHAR(255) NOT NULL,
    item_name VARCHAR(255) NOT NULL,
    income NUMERIC(14, 2) DEFAULT 0.00,
    expense NUMERIC(14, 2) DEFAULT 0.00,
    balance NUMERIC(14, 2) DEFAULT 0.00,
    details TEXT,
    recorded_by VARCHAR(255) DEFAULT 'System',
    created_at TIMESTAMPTZ DEFAULT now()
);

-- ==============================================================================
-- 10. สร้าง INDEX เพื่อเพิ่มประสิทธิภาพการค้นหาและ Query
-- ==============================================================================
CREATE INDEX IF NOT EXISTS idx_products_code ON public.products(product_code);
CREATE INDEX IF NOT EXISTS idx_customers_code ON public.customers(customer_code);
CREATE INDEX IF NOT EXISTS idx_stock_code ON public.stock(product_code);
CREATE INDEX IF NOT EXISTS idx_stock_status ON public.stock(status);
CREATE INDEX IF NOT EXISTS idx_transactions_date ON public.transactions(transaction_date);
CREATE INDEX IF NOT EXISTS idx_transactions_cat ON public.transactions(category);
CREATE INDEX IF NOT EXISTS idx_transactions_cust ON public.transactions(customer_name);
CREATE INDEX IF NOT EXISTS idx_financials_date ON public.financials(transaction_date);
CREATE INDEX IF NOT EXISTS idx_financials_maincat ON public.financials(main_category);

-- ==============================================================================
-- 11. เปิดใช้งาน Row Level Security (RLS) และกำหนดสิทธิ์ Public Anon Access
-- ==============================================================================
ALTER TABLE public.app_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.master_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stock ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.financials ENABLE ROW LEVEL SECURITY;

-- นโยบายเปิดให้สามารถ SELECT, INSERT, UPDATE, DELETE ได้ผ่าน Anon Key
CREATE POLICY "Allow anon all on app_users" ON public.app_users FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "Allow anon all on products" ON public.products FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "Allow anon all on customers" ON public.customers FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "Allow anon all on categories" ON public.categories FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "Allow anon all on master_items" ON public.master_items FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "Allow anon all on stock" ON public.stock FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "Allow anon all on transactions" ON public.transactions FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "Allow anon all on financials" ON public.financials FOR ALL TO anon USING (true) WITH CHECK (true);

-- เปิดให้ authenticated user เข้าถึงได้เช่นเดียวกัน
CREATE POLICY "Allow auth all on app_users" ON public.app_users FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Allow auth all on products" ON public.products FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Allow auth all on customers" ON public.customers FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Allow auth all on categories" ON public.categories FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Allow auth all on master_items" ON public.master_items FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Allow auth all on stock" ON public.stock FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Allow auth all on transactions" ON public.transactions FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Allow auth all on financials" ON public.financials FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- ==============================================================================
-- 12. ข้อมูลตั้งต้น (SEED DATA)
-- ==============================================================================

-- ผู้ใช้งานเริ่มต้น (Admin & Staff)
INSERT INTO public.app_users (username, password, role, full_name) VALUES
('Sangtawan', 'Sangtawan123456789', 'Admin', 'นายแสงตะวัน ชาวเขา'),
('Officer', 'Officer123456', 'User', 'เจ้าหน้าที่คลังจุลินทรีย์');

-- รายการสินค้าเริ่มต้น
INSERT INTO public.products (product_code, product_name, product_type, unit, selling_price, cost_price) VALUES
('BIO-001', 'น้ำยาจุลินทรีย์ EM สูตรเข้มข้น (แกลลอน)', 'ผลิตภัณฑ์', 'แกลลอน', 150.00, 80.00),
('BIO-002', 'กากน้ำตาลแท้เกรด A', 'วัตถุดิบ', 'กิโลกรัม', 20.00, 15.00),
('BIO-003', 'หัวเชื้อจุลินทรีย์บริสุทธิ์', 'วัตถุดิบ', 'ขวด', 300.00, 180.00),
('BIO-004', 'ถังหมักพลาสติกขนาด 200 ลิตร', 'อุปกรณ์', 'ใบ', 850.00, 650.00),
('BIO-005', 'น้ำยาจุลินทรีย์ EM ชนิดเติม 1 ลิตร', 'ผลิตภัณฑ์', 'ขวด', 45.00, 25.00);

-- รายการหน่วยงาน / ลูกค้าเริ่มต้น
INSERT INTO public.customers (customer_code, customer_name, customer_type, contact_info) VALUES
('CUS-001', 'กลุ่มงานสิ่งแวดล้อมและสุขาภิบาล รพ.๕๐ พรรษา', 'หน่วยงานภายใน', 'เบอร์ภายใน 104'),
('CUS-002', 'แผนกโภชนาการ (โรงครัว)', 'หน่วยงานภายใน', 'เบอร์ภายใน 108'),
('CUS-003', 'เทศบาลนครอุบลราชธานี', 'หน่วยงานภายนอก', '045-244800'),
('CUS-004', 'โรงพยาบาลส่งเสริมสุขภาพตำบล (รพ.สต.) เครือข่าย', 'หน่วยงานภายนอก', '045-312111'),
('CUS-005', 'กลุ่มงานอาคารสถานที่และยานพาหนะ', 'หน่วยงานภายใน', 'เบอร์ภายใน 112');

-- หมวดหมู่รายการหลัก
INSERT INTO public.categories (category_code, category_name) VALUES
('CAT-001', 'รายรับจากการจำหน่าย'),
('CAT-002', 'รายจ่ายซื้อวัตถุดิบผลิต'),
('CAT-003', 'รายจ่ายวัสดุอุปกรณ์ห้องแล็บ'),
('CAT-004', 'รายจ่ายค่าบำรุงรักษาและสาธารณูปโภค');

-- รายการย่อยทางบัญชี
INSERT INTO public.master_items (item_code, item_name) VALUES
('ITM-001', 'ส่งเงินรายได้เข้ากองทุนสวัสดิการศูนย์ EM'),
('ITM-002', 'เบิกจ่ายเงินซื้อกากน้ำตาลและหัวเชื้อ'),
('ITM-003', 'จัดซื้อแกลลอนและบรรจุภัณฑ์'),
('ITM-004', 'จัดซื้อชุดตรวจวัดค่า pH และอุปกรณ์แล็บ'),
('ITM-005', 'รายได้จำหน่ายน้ำยาจุลินทรีย์ให้หน่วยงานภายนอก');

-- ข้อมูลสต๊อกเริ่มต้น
INSERT INTO public.stock (product_code, product_name, unit, qty, avg_cost, total_value, reorder_point, status) VALUES
('BIO-001', 'น้ำยาจุลินทรีย์ EM สูตรเข้มข้น (แกลลอน)', 'แกลลอน', 120.00, 80.00, 9600.00, 20.00, 'ปกติ'),
('BIO-002', 'กากน้ำตาลแท้เกรด A', 'กิโลกรัม', 35.00, 15.00, 525.00, 15.00, 'ปกติ'),
('BIO-003', 'หัวเชื้อจุลินทรีย์บริสุทธิ์', 'ขวด', 5.00, 180.00, 900.00, 10.00, 'ต่ำ'),
('BIO-004', 'ถังหมักพลาสติกขนาด 200 ลิตร', 'ใบ', 8.00, 650.00, 5200.00, 3.00, 'ปกติ'),
('BIO-005', 'น้ำยาจุลินทรีย์ EM ชนิดเติม 1 ลิตร', 'ขวด', 0.00, 25.00, 0.00, 15.00, 'หมด');

-- ธุรกรรมตัวอย่าง
INSERT INTO public.transactions (transaction_date, doc_number, category, transaction_type, product_code, product_name, qty, unit_price, total_value, customer_name, recorded_by) VALUES
(CURRENT_DATE - INTERVAL '5 days', 'DOC-20260801', 'จ่ายออก', 'จ่ายออก-เพื่อเบิกใช้ในสิ่งแวดล้อมใน โรงพยาบาล (ตัดสต๊อก)', 'BIO-001', 'น้ำยาจุลินทรีย์ EM สูตรเข้มข้น (แกลลอน)', 25.00, 150.00, 3750.00, 'กลุ่มงานสิ่งแวดล้อมและสุขาภิบาล รพ.๕๐ พรรษา', 'นายแสงตะวัน ชาวเขา'),
(CURRENT_DATE - INTERVAL '3 days', 'DOC-20260802', 'จ่ายออก', 'จ่ายออก-เพื่อเบิกใช้ใน โรงพยาบาล (ตัดสต๊อก)', 'BIO-001', 'น้ำยาจุลินทรีย์ EM สูตรเข้มข้น (แกลลอน)', 15.00, 150.00, 2250.00, 'แผนกโภชนาการ (โรงครัว)', 'เจ้าหน้าที่คลังจุลินทรีย์'),
(CURRENT_DATE - INTERVAL '2 days', 'DOC-20260803', 'จ่ายออก', 'จ่ายออก-เพื่อจำหน่าย (ตัดสต๊อก)', 'BIO-001', 'น้ำยาจุลินทรีย์ EM สูตรเข้มข้น (แกลลอน)', 40.00, 150.00, 6000.00, 'เทศบาลนครอุบลราชธานี', 'นายแสงตะวัน ชาวเขา'),
(CURRENT_DATE - INTERVAL '1 days', 'DOC-20260804', 'รับเข้า', 'รับเข้า-จากการผลิต (เพิ่มสต๊อก)', 'BIO-001', 'น้ำยาจุลินทรีย์ EM สูตรเข้มข้น (แกลลอน)', 50.00, 80.00, 4000.00, 'ศูนย์ผลิตจุลินทรีย์', 'นายแสงตะวัน ชาวเขา');

-- บันทึกบัญชีการเงินตัวอย่าง
INSERT INTO public.financials (transaction_date, doc_number, main_category, category_name, item_name, income, expense, balance, details, recorded_by) VALUES
(CURRENT_DATE - INTERVAL '5 days', 'FIN-20260801', 'รายรับ', 'รายรับจากการจำหน่าย', 'ส่งเงินรายได้เข้ากองทุนสวัสดิการศูนย์ EM', 3750.00, 0.00, 3750.00, 'จำหน่ายให้กลุ่มงานสิ่งแวดล้อม รพ.๕๐ พรรษา', 'นายแสงตะวัน ชาวเขา'),
(CURRENT_DATE - INTERVAL '4 days', 'FIN-20260802', 'รายจ่าย', 'รายจ่ายซื้อวัตถุดิบผลิต', 'เบิกจ่ายเงินซื้อกากน้ำตาลและหัวเชื้อ', 0.00, 1500.00, 2250.00, 'จัดซื้อกากน้ำตาลและหัวเชื้อจุลินทรีย์รอบใหม่', 'นายแสงตะวัน ชาวเขา'),
(CURRENT_DATE - INTERVAL '2 days', 'FIN-20260803', 'รายรับ', 'รายรับจากการจำหน่าย', 'รายได้จำหน่ายน้ำยาจุลินทรีย์ให้หน่วยงานภายนอก', 6000.00, 0.00, 8250.00, 'จำหน่ายน้ำยา EM ให้เทศบาลนครอุบลราชธานี', 'นายแสงตะวัน ชาวเขา');

-- ==============================================================================
-- 13. รีเฟรช Schema Cache ใน Supabase PostgREST
-- ==============================================================================
NOTIFY pgrst, 'reload schema';
