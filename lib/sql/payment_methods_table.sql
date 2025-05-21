-- إنشاء جدول طرق الدفع المتاحة
CREATE TABLE payment_methods (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,                -- اسم طريقة الدفع (مثل: فودافون كاش، إنستا باي)
  payment_identifier TEXT NOT NULL,  -- رقم أو معرف الدفع (رقم هاتف أو بريد إلكتروني أو أي معرف آخر)
  image_url TEXT,                    -- رابط صورة طريقة الدفع
  is_active BOOLEAN DEFAULT TRUE,    -- هل طريقة الدفع نشطة أم لا
  display_order INTEGER DEFAULT 0,   -- ترتيب العرض
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- إضافة تعليقات توضيحية للجدول والأعمدة
COMMENT ON TABLE payment_methods IS 'طرق الدفع المتاحة لشحن المحفظة';
COMMENT ON COLUMN payment_methods.name IS 'اسم طريقة الدفع';
COMMENT ON COLUMN payment_methods.payment_identifier IS 'رقم أو معرف الدفع (رقم هاتف أو بريد إلكتروني)';
COMMENT ON COLUMN payment_methods.image_url IS 'رابط صورة طريقة الدفع';
COMMENT ON COLUMN payment_methods.is_active IS 'حالة طريقة الدفع (نشطة أو غير نشطة)';
COMMENT ON COLUMN payment_methods.display_order IS 'ترتيب عرض طريقة الدفع في الواجهة';

-- إنشاء دالة لتحديث وقت التعديل تلقائياً
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = NOW();
   RETURN NEW;
END;
$$ language 'plpgsql';

-- إنشاء محفز (trigger) لتحديث وقت التعديل تلقائياً
CREATE TRIGGER update_payment_methods_updated_at
BEFORE UPDATE ON payment_methods
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- إدخال بيانات طرق الدفع المتاحة حالياً
INSERT INTO payment_methods (name, payment_identifier, image_url, display_order) 
VALUES 
  ('فودافون كاش', '01093130120', 'https://i.ibb.co/Qp8mxWL/vodafone-cash.png', 1),
  ('إنستا باي', 'eslamz11@instapay', 'https://i.ibb.co/YQnhzjY/instapay.png', 2);
