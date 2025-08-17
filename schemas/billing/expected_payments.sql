-- =====================================================
-- TABELA: expected_payments - Pagamentos Esperados
-- =====================================================
-- Descrição: Pagamentos esperados baseados nas transações
-- Funcionalidades: Gestão de pagamentos, métodos de pagamento, gateways

-- =====================================================
-- CRIAÇÃO DA TABELA
-- =====================================================

CREATE TABLE billing.expected_payments (
    expected_payment_id uuid DEFAULT gen_random_uuid() NOT NULL,
    transaction_id uuid NOT NULL,
    payment_method text NOT NULL,
    gateway_name text,
    amount numeric(10,2) NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);

-- =====================================================
-- COMENTÁRIOS
-- =====================================================

COMMENT ON TABLE billing.expected_payments IS 'Pagamentos esperados baseados nas transações';

COMMENT ON COLUMN billing.expected_payments.expected_payment_id IS 'Identificador único do pagamento esperado';
COMMENT ON COLUMN billing.expected_payments.transaction_id IS 'Referência à transação';
COMMENT ON COLUMN billing.expected_payments.payment_method IS 'Método de pagamento (ex: credit_card, pix, boleto, invoiced)';
COMMENT ON COLUMN billing.expected_payments.gateway_name IS 'Nome do gateway de pagamento (ex: stripe, pagseguro)';
COMMENT ON COLUMN billing.expected_payments.amount IS 'Valor esperado para este pagamento';
COMMENT ON COLUMN billing.expected_payments.created_at IS 'Data de criação do registro';
COMMENT ON COLUMN billing.expected_payments.updated_at IS 'Data da última atualização do registro';

-- =====================================================
-- CONSTRAINTS
-- =====================================================

-- Chave primária
ALTER TABLE billing.expected_payments ADD CONSTRAINT expected_payments_pkey PRIMARY KEY (expected_payment_id);

-- Validação de valor
ALTER TABLE billing.expected_payments ADD CONSTRAINT expected_payments_amount_check CHECK (amount > 0);

-- Validação de método de pagamento
ALTER TABLE billing.expected_payments ADD CONSTRAINT expected_payments_payment_method_check 
    CHECK (payment_method IN ('credit_card', 'debit_card', 'pix', 'boleto', 'invoiced'));

-- =====================================================
-- ÍNDICES
-- =====================================================

-- Índice para transação
CREATE INDEX idx_expected_payments_transaction ON billing.expected_payments (transaction_id);

-- Índice para método de pagamento
CREATE INDEX idx_expected_payments_payment_method ON billing.expected_payments (payment_method);

-- Índice para gateway
CREATE INDEX idx_expected_payments_gateway ON billing.expected_payments (gateway_name);

-- =====================================================
-- TRIGGERS
-- =====================================================

-- Trigger para updated_at
SELECT aux.create_updated_at_trigger('billing', 'expected_payments');

-- =====================================================
-- AUDITORIA
-- =====================================================

-- Criar tabela de auditoria
SELECT audit.create_audit_table('billing', 'expected_payments');
