-- =====================================================
-- TABELA: payment_attempts - Tentativas de Pagamento
-- =====================================================
-- Descrição: Tentativas de pagamento para um expected_payment
-- Funcionalidades: Gestão de tentativas, controle de status, payloads de gateway

-- =====================================================
-- CRIAÇÃO DA TABELA
-- =====================================================

CREATE TABLE billing.payment_attempts (
    attempt_id uuid DEFAULT gen_random_uuid() NOT NULL,
    expected_payment_id uuid NOT NULL,
    payment_method text NOT NULL,
    gateway_name text NOT NULL,
    status text NOT NULL,
    gateway_payload jsonb NOT NULL,
    failure_reason text,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);

-- =====================================================
-- COMENTÁRIOS
-- =====================================================

COMMENT ON TABLE billing.payment_attempts IS 'Tentativas de pagamento para um expected_payment';

COMMENT ON COLUMN billing.payment_attempts.attempt_id IS 'Identificador único da tentativa';
COMMENT ON COLUMN billing.payment_attempts.expected_payment_id IS 'Referência ao pagamento esperado';
COMMENT ON COLUMN billing.payment_attempts.payment_method IS 'Método de pagamento usado na tentativa';
COMMENT ON COLUMN billing.payment_attempts.gateway_name IS 'Nome do gateway usado';
COMMENT ON COLUMN billing.payment_attempts.status IS 'Status da tentativa (success, failed, pending, cancelled)';
COMMENT ON COLUMN billing.payment_attempts.gateway_payload IS 'Payload completo retornado pelo gateway';
COMMENT ON COLUMN billing.payment_attempts.failure_reason IS 'Motivo da falha (se aplicável)';
COMMENT ON COLUMN billing.payment_attempts.created_at IS 'Data de criação do registro';
COMMENT ON COLUMN billing.payment_attempts.updated_at IS 'Data da última atualização do registro';

-- =====================================================
-- CONSTRAINTS
-- =====================================================

-- Chave primária
ALTER TABLE billing.payment_attempts ADD CONSTRAINT payment_attempts_pkey PRIMARY KEY (attempt_id);

-- Validação de status
ALTER TABLE billing.payment_attempts ADD CONSTRAINT payment_attempts_status_check 
    CHECK (status IN ('success', 'failed', 'pending', 'cancelled'));

-- Validação de método de pagamento
ALTER TABLE billing.payment_attempts ADD CONSTRAINT payment_attempts_payment_method_check 
    CHECK (payment_method IN ('credit_card', 'debit_card', 'pix', 'boleto', 'invoiced'));

-- =====================================================
-- ÍNDICES
-- =====================================================

-- Índice para pagamento esperado
CREATE INDEX idx_payment_attempts_expected_payment ON billing.payment_attempts (expected_payment_id);

-- Índice para status
CREATE INDEX idx_payment_attempts_status ON billing.payment_attempts (status);

-- Índice para método de pagamento
CREATE INDEX idx_payment_attempts_payment_method ON billing.payment_attempts (payment_method);

-- Índice para gateway
CREATE INDEX idx_payment_attempts_gateway ON billing.payment_attempts (gateway_name);

-- Índice para payload do gateway (GIN para JSONB)
CREATE INDEX idx_payment_attempts_gateway_payload ON billing.payment_attempts USING GIN (gateway_payload);

-- =====================================================
-- TRIGGERS
-- =====================================================

-- Trigger para updated_at
SELECT aux.create_updated_at_trigger('billing', 'payment_attempts');

-- =====================================================
-- AUDITORIA
-- =====================================================

-- Criar tabela de auditoria
SELECT audit.create_audit_table('billing', 'payment_attempts');
