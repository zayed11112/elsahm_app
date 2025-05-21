-- تعديل جدول checkout_requests ليتناسب مع البيانات المرسلة من التطبيق

-- إضافة عمود property_price إذا لم يكن موجوداً
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'checkout_requests' AND column_name = 'property_price'
  ) THEN
    ALTER TABLE checkout_requests ADD COLUMN property_price DECIMAL(10, 2) DEFAULT 0;
  END IF;
END $$;

-- التأكد من أن قيود المفتاح الخارجي لـ user_id لا تتسبب في مشاكل عند ربط المستخدمين
-- إذا كان يوجد مشكلة، حذف القيد وإضافته بخيار CASCADE

-- التحقق مما إذا كان user_id مرتبط بمفتاح خارجي
DO $$
DECLARE
  constraint_name text;
BEGIN
  SELECT conname INTO constraint_name
  FROM pg_constraint 
  WHERE conrelid = 'checkout_requests'::regclass AND contype = 'f' AND array_position(conkey, (
    SELECT attnum 
    FROM pg_attribute 
    WHERE attrelid = 'checkout_requests'::regclass AND attname = 'user_id'
  )) IS NOT NULL;
  
  -- إذا وجد قيد، حذفه وإعادة إنشائه بخيار CASCADE
  IF constraint_name IS NOT NULL THEN
    EXECUTE 'ALTER TABLE checkout_requests DROP CONSTRAINT ' || constraint_name;
    -- إعادة إنشاء القيد بخيار CASCADE
    ALTER TABLE checkout_requests 
    ADD CONSTRAINT checkout_requests_user_id_fkey 
    FOREIGN KEY (user_id) 
    REFERENCES auth.users(id) 
    ON DELETE CASCADE;
  END IF;
END $$;

-- جعل الحقول غير المطلوبة اختيارية
DO $$
BEGIN
  -- التحقق من أن user_id قابل للقيم NULL
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'checkout_requests' AND column_name = 'user_id' AND is_nullable = 'NO'
  ) THEN
    ALTER TABLE checkout_requests ALTER COLUMN user_id DROP NOT NULL;
  END IF;
END $$; 