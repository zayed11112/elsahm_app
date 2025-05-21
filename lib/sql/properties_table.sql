# جداول قاعدة البيانات Supabase المستخدمة في لوحة التحكم

## 1. جدول العقارات (properties)
```sql
CREATE TABLE IF NOT EXISTS properties (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  description TEXT,
  address TEXT NOT NULL,
  type TEXT NOT NULL, 
  price NUMERIC NOT NULL DEFAULT 0,
  commission NUMERIC NOT NULL DEFAULT 0,
  bedrooms INTEGER NOT NULL DEFAULT 0,
  beds INTEGER NOT NULL DEFAULT 0,
  floor TEXT NOT NULL DEFAULT '', 
  is_available BOOLEAN NOT NULL DEFAULT true,
  features TEXT[] DEFAULT '{}',
  images TEXT[] DEFAULT '{}',
  videos TEXT[] DEFAULT '{}',
  drive_images TEXT[] DEFAULT '{}',
  owner_id UUID REFERENCES owners(id),
  owner_name TEXT,
  owner_phone TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- مؤشرات للبحث السريع
CREATE INDEX idx_properties_name ON properties (name);
CREATE INDEX idx_properties_address ON properties (address);
CREATE INDEX idx_properties_type ON properties (type);
CREATE INDEX idx_properties_is_available ON properties (is_available);
CREATE INDEX idx_properties_price ON properties (price);
CREATE INDEX idx_properties_owner_id ON properties (owner_id);
```

## 2. جدول المُلاك (owners)
```sql
CREATE TABLE IF NOT EXISTS owners (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  phone TEXT NOT NULL,
  email TEXT,
  address TEXT,
  notes TEXT,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- مؤشرات للبحث السريع
CREATE INDEX idx_owners_name ON owners (name);
CREATE INDEX idx_owners_phone ON owners (phone);
```

## 3. جدول الحجوزات (reservations)
```sql
CREATE TABLE IF NOT EXISTS reservations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  property_id UUID NOT NULL REFERENCES properties(id),
  user_id TEXT NOT NULL,
  start_date TIMESTAMP WITH TIME ZONE NOT NULL,
  end_date TIMESTAMP WITH TIME ZONE NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending', -- 'pending', 'confirmed', 'cancelled', 'completed'
  total_price NUMERIC NOT NULL DEFAULT 0,
  payment_status TEXT NOT NULL DEFAULT 'unpaid', -- 'unpaid', 'partial', 'paid'
  payment_amount NUMERIC NOT NULL DEFAULT 0,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- مؤشرات للبحث السريع
CREATE INDEX idx_reservations_property_id ON reservations (property_id);
CREATE INDEX idx_reservations_user_id ON reservations (user_id);
CREATE INDEX idx_reservations_status ON reservations (status);
CREATE INDEX idx_reservations_dates ON reservations (start_date, end_date);
```

## 4. جدول الإشعارات (notifications)
```sql
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id TEXT NOT NULL,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type TEXT NOT NULL DEFAULT 'info', -- 'info', 'success', 'warning', 'error'
  is_read BOOLEAN NOT NULL DEFAULT false,
  related_id UUID, -- يمكن أن يكون معرف عقار أو حجز أو مستخدم
  related_type TEXT, -- 'property', 'reservation', 'user'
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- مؤشرات للبحث السريع
CREATE INDEX idx_notifications_user_id ON notifications (user_id);
CREATE INDEX idx_notifications_is_read ON notifications (is_read);
```



## ملاحظات هامة

1. **الأمان**: تأكد من إعداد قواعد الأمان المناسبة في Supabase لكل جدول.
2. **ترتيب الإنشاء**: يجب إنشاء الجداول بالترتيب التالي لتجنب مشاكل المراجع الخارجية:
   - أولاً: جدول المُلاك (owners)
   - ثانياً: جدول العقارات (properties)
   - ثالثاً: جدول الحجوزات (reservations)
   - رابعاً: جدول الإشعارات (notifications)
3. **تحديث حقل الطابق**: إذا كان جدول العقارات موجوداً بالفعل وكان حقل الطابق من نوع INTEGER، يمكنك تحديثه باستخدام الأمر التالي:
```sql
ALTER TABLE properties ALTER COLUMN floor TYPE TEXT;
```
4. **المستخدمين**: يتم استخدام نظام مستخدمين خارجي، لذلك تم استخدام حقل user_id من نوع TEXT في الجداول التي تحتاج إلى ربط بالمستخدمين.
5. **النسخ الاحتياطي**: قم بإعداد نظام للنسخ الاحتياطي المنتظم لقاعدة البيانات.

## تنفيذ الجداول

يمكن تنفيذ هذه الجداول في Supabase باستخدام واجهة SQL Editor المتوفرة في لوحة تحكم Supabase.

1. قم بتسجيل الدخول إلى لوحة تحكم Supabase الخاصة بك.
2. انتقل إلى قسم "SQL Editor".
3. انسخ والصق أوامر SQL الخاصة بكل جدول بالترتيب المذكور أعلاه.
4. اضغط على زر "Run" لتنفيذ الأوامر.



## تحديث الجداول الموجودة

إذا كنت تريد تحديث جدول موجود بالفعل، يمكنك استخدام أوامر ALTER TABLE. على سبيل المثال:

```sql
-- تحديث جدول العقارات لتغيير نوع حقل الطابق من INTEGER إلى TEXT
ALTER TABLE properties ALTER COLUMN floor TYPE TEXT;
```

