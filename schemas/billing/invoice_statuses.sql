-- =====================================================
-- TABELA: invoice_statuses - Status dos Invoices
-- =====================================================
-- Descrição: Status possíveis para invoices/documentos de pagamento
-- Funcionalidades: Definição de status, controle de fluxo de documentos

-- =====================================================
-- CRIAÇÃO DA TABELA
-- =====================================================

CREATE TABLE billing.invoice_statuses (
    status_id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    description text NOT NULL,
    is_active boolean NOT NULL DEFAULT true,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);

-- =====================================================
-- COMENTÁRIOS
-- =====================================================

COMMENT ON TABLE billing.invoice_statuses IS 'Status possíveis para invoices/documentos de pagamento';

COMMENT ON COLUMN billing.invoice_statuses.status_id IS 'Identificador único do status';
COMMENT ON COLUMN billing.invoice_statuses.name IS 'Nome do status (ex: generated, sent, overdue, paid, cancelled)';
COMMENT ON COLUMN billing.invoice_statuses.description IS 'Descrição clara do que significa o status';
COMMENT ON COLUMN billing.invoice_statuses.is_active IS 'Indica se o status está ativo';
COMMENT ON COLUMN billing.invoice_statuses.created_at IS 'Data de criação do registro';
COMMENT ON COLUMN billing.invoice_statuses.updated_at IS 'Data da última atualização do registro';

-- =====================================================
-- CONSTRAINTS
-- =====================================================

-- Chave primária
ALTER TABLE billing.invoice_statuses ADD CONSTRAINT invoice_statuses_pkey PRIMARY KEY (status_id);

-- Nome único
ALTER TABLE billing.invoice_statuses ADD CONSTRAINT invoice_statuses_name_unique UNIQUE (name);

-- =====================================================
-- ÍNDICES
-- =====================================================

-- Índice para busca por nome
CREATE INDEX idx_invoice_statuses_name ON billing.invoice_statuses (name);

-- Índice para status ativos
CREATE INDEX idx_invoice_statuses_is_active ON billing.invoice_statuses (is_active);

-- =====================================================
-- TRIGGERS
-- =====================================================

-- Trigger para updated_at
SELECT aux.create_updated_at_trigger('billing', 'invoice_statuses');

-- =====================================================
-- AUDITORIA
-- =====================================================

-- Criar tabela de auditoria
SELECT audit.create_audit_table('billing', 'invoice_statuses');
