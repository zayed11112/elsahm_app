-- إنشاء جدول الأقسام
CREATE TABLE categories (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  icon_url VARCHAR(255),
  order_index INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- إنشاء جدول العلاقة بين الأقسام والشقق
CREATE TABLE category_properties (
  id SERIAL PRIMARY KEY,
  category_id INTEGER REFERENCES categories(id) ON DELETE CASCADE,
  property_id UUID REFERENCES properties(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(category_id, property_id)
);

-- إضافة بعض الأقسام الافتراضية
INSERT INTO categories (name, icon_url, order_index, is_active) VALUES
  ('سكن الطلاب', 'https://i.ibb.co/YQnkf7S/meeting-room.png', 1, TRUE),
  ('سكن الطالبات', 'https://i.ibb.co/YQnkf7S/meeting-room.png', 2, TRUE),
  ('شقق عائلية', 'https://i.ibb.co/YQnkf7S/apartment.png', 3, TRUE),
  ('استوديو', 'https://i.ibb.co/YQnkf7S/single-bed.png', 4, TRUE),
  ('فيلا', 'https://i.ibb.co/YQnkf7S/home.png', 5, TRUE),
  ('شقة مفروشة', 'https://i.ibb.co/YQnkf7S/chair.png', 6, TRUE),
  ('شقة غير مفروشة', 'https://i.ibb.co/YQnkf7S/apartment.png', 7, TRUE),
  ('أخرى', 'https://i.ibb.co/YQnkf7S/category.png', 8, TRUE);

-- إضافة دالة لتحديث حقل updated_at تلقائيًا
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = NOW();
   RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- إضافة trigger لتحديث حقل updated_at تلقائيًا عند تحديث السجل
CREATE TRIGGER update_categories_updated_at
BEFORE UPDATE ON categories
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();
