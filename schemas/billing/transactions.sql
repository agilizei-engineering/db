-- =====================================================
-- TABELA: transactions - Transações Financeiras
-- =====================================================
-- Descrição: Transações financeiras principais (agnósticas ao negócio)
-- Funcionalidades: Gestão de transações, referências de negócio, controle de parcelamento

-- =====================================================
-- CRIAÇÃO DA TABELA
-- =====================================================

CREATE TABLE billing.transactions (
    transaction_id uuid DEFAULT gen_random_uuid() NOT NULL,
    business_reference jsonb NOT NULL,
    amount numeric(10,2) NOT NULL,
    currency text NOT NULL DEFAULT 'BRL',
    status_id uuid NOT NULL,
    payment_type_id uuid NOT NULL,
    total_installments integer NOT NULL DEFAULT 1,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);

-- =====================================================
-- COMENTÁRIOS
-- =====================================================

COMMENT ON TABLE billing.transactions IS 'Transações financeiras principais (agnósticas ao negócio)';

COMMENT ON COLUMN billing.transactions.transaction_id IS 'Identificador único da transação';
COMMENT ON COLUMN billing.transactions.business_reference IS 'Referência ao negócio em formato JSONB (ex: {"schema": "subscriptions", "table": "subscriptions", "id": "uuid"})';
COMMENT ON COLUMN billing.transactions.amount IS 'Valor total da transação';
COMMENT ON COLUMN billing.transactions.currency IS 'Moeda da transação (padrão: BRL)';
COMMENT ON COLUMN billing.transactions.status_id IS 'Status atual da transação';
COMMENT ON COLUMN billing.transactions.payment_type_id IS 'Tipo de pagamento';
COMMENT ON COLUMN billing.transactions.total_installments IS 'Número total de parcelas (sempre >= 1)';
COMMENT ON COLUMN billing.transactions.created_at IS 'Data de criação do registro';
COMMENT ON COLUMN billing.transactions.updated_at IS 'Data da última atualização do registro';

-- =====================================================
-- CONSTRAINTS
-- =====================================================

-- Chave primária
ALTER TABLE billing.transactions ADD CONSTRAINT transactions_pkey PRIMARY KEY (transaction_id);

-- Validação de valor
ALTER TABLE billing.transactions ADD CONSTRAINT transactions_amount_check CHECK (amount > 0);

-- Validação de parcelas
ALTER TABLE billing.transactions ADD CONSTRAINT transactions_total_installments_check CHECK (total_installments >= 1);

-- Validação de moeda
ALTER TABLE billing.transactions ADD CONSTRAINT transactions_currency_check CHECK (currency IN ('BRL', 'USD', 'EUR'));

-- =====================================================
-- ÍNDICES
-- =====================================================

-- Índice para status
CREATE INDEX idx_transactions_status ON billing.transactions (status_id);

-- Índice para tipo de pagamento
CREATE INDEX idx_transactions_payment_type ON billing.transactions (payment_type_id);

-- Índice para referência de negócio (GIN para JSONB)
CREATE INDEX idx_transactions_business_reference ON billing.transactions USING GIN (business_reference);

-- Índice para data de criação
CREATE INDEX idx_transactions_created_at ON billing.transactions (created_at);

-- Índice para valor
CREATE INDEX idx_transactions_amount ON billing.transactions (amount);

-- =====================================================
-- TRIGGERS
-- =====================================================

-- Trigger para updated_at
SELECT aux.create_updated_at_trigger('billing', 'transactions');

-- =====================================================
-- AUDITORIA
-- =====================================================

-- Criar tabela de auditoria
SELECT audit.create_audit_table('billing', 'transactions');
