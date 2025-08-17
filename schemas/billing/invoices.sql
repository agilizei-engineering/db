-- =====================================================
-- TABELA: invoices - Documentos de Pagamento
-- =====================================================
-- Descrição: Documentos de pagamento (boletos, recibos, etc.)
-- Funcionalidades: Gestão de documentos, controle de vencimentos, payloads de gateway

-- =====================================================
-- CRIAÇÃO DA TABELA
-- =====================================================

CREATE TABLE billing.invoices (
    invoice_id uuid DEFAULT gen_random_uuid() NOT NULL,
    expected_payment_id uuid NOT NULL,
    invoice_number text NOT NULL,
    barcode text,
    amount numeric(10,2) NOT NULL,
    due_date date NOT NULL,
    status_id uuid NOT NULL,
    payment_date date,
    gateway_payload jsonb,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);

-- =====================================================
-- COMENTÁRIOS
-- =====================================================

COMMENT ON TABLE billing.invoices IS 'Documentos de pagamento (boletos, recibos, etc.)';

COMMENT ON COLUMN billing.invoices.invoice_id IS 'Identificador único do invoice';
COMMENT ON COLUMN billing.invoices.expected_payment_id IS 'Referência ao pagamento esperado';
COMMENT ON COLUMN billing.invoices.invoice_number IS 'Número do invoice/documento';
COMMENT ON COLUMN billing.invoices.barcode IS 'Código de barras (para boletos)';
COMMENT ON COLUMN billing.invoices.amount IS 'Valor do invoice';
COMMENT ON COLUMN billing.invoices.due_date IS 'Data de vencimento';
COMMENT ON COLUMN billing.invoices.status_id IS 'Status do invoice';
COMMENT ON COLUMN billing.invoices.payment_date IS 'Data do pagamento (NULL até ser pago)';
COMMENT ON COLUMN billing.invoices.gateway_payload IS 'Payload completo do gateway';
COMMENT ON COLUMN billing.invoices.created_at IS 'Data de criação do registro';
COMMENT ON COLUMN billing.invoices.updated_at IS 'Data da última atualização do registro';

-- =====================================================
-- CONSTRAINTS
-- =====================================================

-- Chave primária
ALTER TABLE billing.invoices ADD CONSTRAINT invoices_pkey PRIMARY KEY (invoice_id);

-- Validação de valor
ALTER TABLE billing.invoices ADD CONSTRAINT invoices_amount_check CHECK (amount > 0);

-- Número único do invoice
ALTER TABLE billing.invoices ADD CONSTRAINT invoices_invoice_number_unique UNIQUE (invoice_number);

-- =====================================================
-- ÍNDICES
-- =====================================================

-- Índice para pagamento esperado
CREATE INDEX idx_invoices_expected_payment ON billing.invoices (expected_payment_id);

-- Índice para status
CREATE INDEX idx_invoices_status ON billing.invoices (status_id);

-- Índice para data de vencimento
CREATE INDEX idx_invoices_due_date ON billing.invoices (due_date);

-- Índice para data de pagamento
CREATE INDEX idx_invoices_payment_date ON billing.invoices (payment_date);

-- Índice para payload do gateway (GIN para JSONB)
CREATE INDEX idx_invoices_gateway_payload ON billing.invoices USING GIN (gateway_payload);

-- =====================================================
-- TRIGGERS
-- =====================================================

-- Trigger para updated_at
SELECT aux.create_updated_at_trigger('billing', 'invoices');

-- =====================================================
-- AUDITORIA
-- =====================================================

-- Criar tabela de auditoria
SELECT audit.create_audit_table('billing', 'invoices');
