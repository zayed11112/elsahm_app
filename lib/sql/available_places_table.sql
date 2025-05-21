-- إنشاء جدول الأماكن المتاحة
CREATE TABLE available_places (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  icon_url VARCHAR(255),
  order_index INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- إنشاء جدول العلاقة بين الأماكن المتاحة والعقارات
CREATE TABLE place_properties (
  id SERIAL PRIMARY KEY,
  place_id INTEGER REFERENCES available_places(id) ON DELETE CASCADE,
  property_id UUID REFERENCES properties(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(place_id, property_id)
);

-- إضافة بعض الأماكن المتاحة الافتراضية
INSERT INTO available_places (name, icon_url, order_index, is_active) VALUES
  ('شقة طلابية مميزة', 'https://i.ibb.co/YQnkf7S/apartment.png', 1, TRUE),
  ('غرفة مشتركة للطالبات', 'https://i.ibb.co/YQnkf7S/meeting-room.png', 2, TRUE),
  ('استوديو فاخر', 'https://i.ibb.co/YQnkf7S/single-bed.png', 3, TRUE);

-- إضافة دالة لتحديث حقل updated_at تلقائيًا
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = NOW();
   RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- إضافة trigger لتحديث حقل updated_at تلقائيًا عند تحديث السجل
CREATE TRIGGER update_available_places_updated_at
BEFORE UPDATE ON available_places
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column(); 