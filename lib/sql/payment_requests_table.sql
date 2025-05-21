CREATE TABLE payment_requests (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    amount DECIMAL(10, 2) NOT NULL,
    payment_method VARCHAR(100) NOT NULL,
    source_phone VARCHAR(100) NOT NULL,
    payment_proof_url TEXT,
    rejection_reason TEXT,
    approved_at TIMESTAMP WITH TIME ZONE,
    user_name VARCHAR(255),
    university_id VARCHAR(100),
    
    -- تفاصيل إضافية اختيارية
    faculty VARCHAR(255),
    branch VARCHAR(255),
    current_balance DECIMAL(10, 2),
    
    -- فهارس لتحسين الأداء
    CONSTRAINT fk_status CHECK (status IN ('pending', 'approved', 'rejected'))
);

-- إنشاء فهارس للبحث السريع
CREATE INDEX idx_payment_requests_user_id ON payment_requests(user_id);
CREATE INDEX idx_payment_requests_status ON payment_requests(status);
CREATE INDEX idx_payment_requests_created_at ON payment_requests(created_at);

-- إنشاء سياسة لسهولة الوصول في Supabase
ALTER TABLE payment_requests ENABLE ROW LEVEL SECURITY;

-- السياسة للقراءة: المستخدمون يمكنهم فقط رؤية طلباتهم الخاصة
CREATE POLICY "Users can view their own payment requests"
    ON payment_requests FOR SELECT
    USING (auth.uid()::text = user_id);

-- السياسة للإضافة: المستخدمون يمكنهم إضافة طلبات جديدة
CREATE POLICY "Users can insert their own payment requests"
    ON payment_requests FOR INSERT
    WITH CHECK (auth.uid()::text = user_id);