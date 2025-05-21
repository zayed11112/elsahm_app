-- Create owners table
CREATE TABLE IF NOT EXISTS owners (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  email TEXT,
  phone TEXT NOT NULL,
  address TEXT,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create apartments table
CREATE TABLE IF NOT EXISTS apartments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  address TEXT NOT NULL,
  rooms INTEGER NOT NULL CHECK (rooms > 0),
  monthly_rent DECIMAL(10, 2) NOT NULL CHECK (monthly_rent > 0),
  status TEXT NOT NULL CHECK (status IN ('available', 'rented')),
  image_url TEXT,
  notes TEXT,
  videos TEXT[] DEFAULT '{}',
  owner_id UUID REFERENCES owners(id) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create users table
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  password TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('user', 'admin')) DEFAULT 'user',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create reservations table
CREATE TABLE IF NOT EXISTS reservations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  apartment_id UUID NOT NULL REFERENCES apartments(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  total_price DECIMAL(10, 2) NOT NULL CHECK (total_price >= 0),
  status TEXT NOT NULL CHECK (status IN ('pending', 'confirmed', 'cancelled')) DEFAULT 'pending',
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  CONSTRAINT valid_date_range CHECK (end_date > start_date)
);

-- Create banners table
CREATE TABLE IF NOT EXISTS banners (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT,
  image_url TEXT NOT NULL,
  link_url TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  "order" INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_apartments_owner_id ON apartments(owner_id);
CREATE INDEX IF NOT EXISTS idx_apartments_status ON apartments(status);
CREATE INDEX IF NOT EXISTS idx_reservations_apartment_id ON reservations(apartment_id);
CREATE INDEX IF NOT EXISTS idx_reservations_user_id ON reservations(user_id);
CREATE INDEX IF NOT EXISTS idx_reservations_status ON reservations(status);
CREATE INDEX IF NOT EXISTS idx_banners_is_active ON banners(is_active);
CREATE INDEX IF NOT EXISTS idx_banners_order ON banners("order");

-- Create RLS (Row Level Security) policies
-- Enable RLS on all tables
ALTER TABLE owners ENABLE ROW LEVEL SECURITY;
ALTER TABLE apartments ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE reservations ENABLE ROW LEVEL SECURITY;
ALTER TABLE banners ENABLE ROW LEVEL SECURITY;

-- Owners policies
CREATE POLICY owners_select_policy ON owners
  FOR SELECT USING (true); -- Anyone can view owners

CREATE POLICY owners_insert_policy ON owners
  FOR INSERT WITH CHECK (auth.role() = 'authenticated' AND auth.jwt() ->> 'role' = 'admin');

CREATE POLICY owners_update_policy ON owners
  FOR UPDATE USING (auth.role() = 'authenticated' AND auth.jwt() ->> 'role' = 'admin');

CREATE POLICY owners_delete_policy ON owners
  FOR DELETE USING (auth.role() = 'authenticated' AND auth.jwt() ->> 'role' = 'admin');

-- Apartments policies
CREATE POLICY apartments_select_policy ON apartments
  FOR SELECT USING (true); -- Anyone can view apartments

CREATE POLICY apartments_insert_policy ON apartments
  FOR INSERT WITH CHECK (auth.role() = 'authenticated' AND auth.jwt() ->> 'role' = 'admin');

CREATE POLICY apartments_update_policy ON apartments
  FOR UPDATE USING (auth.role() = 'authenticated' AND auth.jwt() ->> 'role' = 'admin');

CREATE POLICY apartments_delete_policy ON apartments
  FOR DELETE USING (auth.role() = 'authenticated' AND auth.jwt() ->> 'role' = 'admin');

-- Users policies
CREATE POLICY users_select_self_policy ON users
  FOR SELECT USING (auth.uid() = id OR auth.jwt() ->> 'role' = 'admin');

CREATE POLICY users_insert_admin_policy ON users
  FOR INSERT WITH CHECK (auth.role() = 'authenticated' AND auth.jwt() ->> 'role' = 'admin');

CREATE POLICY users_update_self_policy ON users
  FOR UPDATE USING (auth.uid() = id OR auth.jwt() ->> 'role' = 'admin');

CREATE POLICY users_delete_admin_policy ON users
  FOR DELETE USING (auth.role() = 'authenticated' AND auth.jwt() ->> 'role' = 'admin');

-- Reservations policies
CREATE POLICY reservations_select_self_policy ON reservations
  FOR SELECT USING (auth.uid() = user_id OR auth.jwt() ->> 'role' = 'admin');

CREATE POLICY reservations_insert_self_policy ON reservations
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY reservations_update_admin_policy ON reservations
  FOR UPDATE USING (auth.role() = 'authenticated' AND auth.jwt() ->> 'role' = 'admin');

CREATE POLICY reservations_delete_admin_policy ON reservations
  FOR DELETE USING (auth.role() = 'authenticated' AND auth.jwt() ->> 'role' = 'admin');

-- Banners policies
CREATE POLICY banners_select_policy ON banners
  FOR SELECT USING (true); -- Anyone can view banners

CREATE POLICY banners_insert_policy ON banners
  FOR INSERT WITH CHECK (auth.role() = 'authenticated' AND auth.jwt() ->> 'role' = 'admin');

CREATE POLICY banners_update_policy ON banners
  FOR UPDATE USING (auth.role() = 'authenticated' AND auth.jwt() ->> 'role' = 'admin');

CREATE POLICY banners_delete_policy ON banners
  FOR DELETE USING (auth.role() = 'authenticated' AND auth.jwt() ->> 'role' = 'admin');
