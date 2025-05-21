-- طلبات تسجيل الخروج لحجز العقارات
CREATE TABLE checkout_requests (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  property_id TEXT NOT NULL,
  property_name TEXT NOT NULL,
  customer_name TEXT NOT NULL,
  customer_phone TEXT NOT NULL,
  university_id TEXT NOT NULL,
  college TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'جاري المعالجة', -- جاري المعالجة، مؤكد، ملغي
  commission DECIMAL(10, 2) DEFAULT 0,
  deposit DECIMAL(10, 2) DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- مؤشر على معرّف المستخدم لتحسين استعلامات البحث
CREATE INDEX checkout_requests_user_id_idx ON checkout_requests (user_id);

-- مؤشر على معرّف العقار لتحسين استعلامات البحث
CREATE INDEX checkout_requests_property_id_idx ON checkout_requests (property_id);

-- مؤشر على حالة الطلب
CREATE INDEX checkout_requests_status_idx ON checkout_requests (status);

-- وظيفة لتحديث وقت التعديل تلقائياً
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = NOW();
   RETURN NEW;
END;
$$ language 'plpgsql';

-- محفز لتحديث وقت التعديل تلقائياً عند تحديث البيانات
CREATE TRIGGER update_checkout_requests_updated_at
BEFORE UPDATE ON checkout_requests
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column(); 