-- =====================================================
-- TABELA: installments - Parcelas dos Pagamentos
-- =====================================================
-- Descrição: Parcelas/installments dos pagamentos esperados
-- Funcionalidades: Gestão de parcelas, controle de vencimentos, status

-- =====================================================
-- CRIAÇÃO DA TABELA
-- =====================================================

CREATE TABLE billing.installments (
    installment_id uuid DEFAULT gen_random_uuid() NOT NULL,
    expected_payment_id uuid NOT NULL,
    installment_number integer NOT NULL,
    amount numeric(10,2) NOT NULL,
    due_date date NOT NULL,
    status_id uuid NOT NULL,
    payment_attempt_id uuid,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);

-- =====================================================
-- COMENTÁRIOS
-- =====================================================

COMMENT ON TABLE billing.installments IS 'Parcelas/installments dos pagamentos esperados';

COMMENT ON COLUMN billing.installments.installment_id IS 'Identificador único da parcela';
COMMENT ON COLUMN billing.installments.expected_payment_id IS 'Referência ao pagamento esperado';
COMMENT ON COLUMN billing.installments.installment_number IS 'Número da parcela (1, 2, 3...)';
COMMENT ON COLUMN billing.installments.amount IS 'Valor da parcela';
COMMENT ON COLUMN billing.installments.due_date IS 'Data de vencimento da parcela';
COMMENT ON COLUMN billing.installments.status_id IS 'Status da parcela';
COMMENT ON COLUMN billing.installments.payment_attempt_id IS 'Referência à tentativa de pagamento (quando pago)';
COMMENT ON COLUMN billing.installments.created_at IS 'Data de criação do registro';
COMMENT ON COLUMN billing.installments.updated_at IS 'Data da última atualização do registro';

-- =====================================================
-- CONSTRAINTS
-- =====================================================

-- Chave primária
ALTER TABLE billing.installments ADD CONSTRAINT installments_pkey PRIMARY KEY (installment_id);

-- Validação de valor
ALTER TABLE billing.installments ADD CONSTRAINT installments_amount_check CHECK (amount > 0);

-- Validação de número da parcela
ALTER TABLE billing.installments ADD CONSTRAINT installments_number_check CHECK (installment_number > 0);

-- Número único por pagamento
ALTER TABLE billing.installments ADD CONSTRAINT installments_unique_number 
    UNIQUE (expected_payment_id, installment_number);

-- =====================================================
-- ÍNDICES
-- =====================================================

-- Índice para pagamento esperado
CREATE INDEX idx_installments_expected_payment ON billing.installments (expected_payment_id);

-- Índice para status
CREATE INDEX idx_installments_status ON billing.installments (status_id);

-- Índice para data de vencimento
CREATE INDEX idx_installments_due_date ON billing.installments (due_date);

-- Índice para tentativa de pagamento
CREATE INDEX idx_installments_payment_attempt ON billing.installments (payment_attempt_id);

-- =====================================================
-- TRIGGERS
-- =====================================================

-- Trigger para updated_at
SELECT aux.create_updated_at_trigger('billing', 'installments');

-- =====================================================
-- AUDITORIA
-- =====================================================

-- Criar tabela de auditoria
SELECT audit.create_audit_table('billing', 'installments');
