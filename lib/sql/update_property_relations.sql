-- إنشاء جدول العلاقة بين العقارات والأقسام
CREATE TABLE IF NOT EXISTS property_categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
  category_id INTEGER NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(property_id, category_id)
);

-- إنشاء جدول العلاقة بين العقارات والأماكن المتاحة
CREATE TABLE IF NOT EXISTS property_available_places (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
  place_id INTEGER NOT NULL REFERENCES available_places(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(property_id, place_id)
);

-- إنشاء فهارس للبحث السريع
CREATE INDEX IF NOT EXISTS idx_property_categories_property_id ON property_categories(property_id);
CREATE INDEX IF NOT EXISTS idx_property_categories_category_id ON property_categories(category_id);
CREATE INDEX IF NOT EXISTS idx_property_available_places_property_id ON property_available_places(property_id);
CREATE INDEX IF NOT EXISTS idx_property_available_places_place_id ON property_available_places(place_id); 