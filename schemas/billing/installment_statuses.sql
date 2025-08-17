-- =====================================================
-- TABELA: installment_statuses - Status das Parcelas
-- =====================================================
-- Descrição: Status possíveis para parcelas/installments
-- Funcionalidades: Definição de status, controle de fluxo de parcelas

-- =====================================================
-- CRIAÇÃO DA TABELA
-- =====================================================

CREATE TABLE billing.installment_statuses (
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

COMMENT ON TABLE billing.installment_statuses IS 'Status possíveis para parcelas/installments';

COMMENT ON COLUMN billing.installment_statuses.status_id IS 'Identificador único do status';
COMMENT ON COLUMN billing.installment_statuses.name IS 'Nome do status (ex: pending, due, paid, cancelled)';
COMMENT ON COLUMN billing.installment_statuses.description IS 'Descrição clara do que significa o status';
COMMENT ON COLUMN billing.installment_statuses.is_active IS 'Indica se o status está ativo';
COMMENT ON COLUMN billing.installment_statuses.created_at IS 'Data de criação do registro';
COMMENT ON COLUMN billing.installment_statuses.updated_at IS 'Data da última atualização do registro';

-- =====================================================
-- CONSTRAINTS
-- =====================================================

-- Chave primária
ALTER TABLE billing.installment_statuses ADD CONSTRAINT installment_statuses_pkey PRIMARY KEY (status_id);

-- Nome único
ALTER TABLE billing.installment_statuses ADD CONSTRAINT installment_statuses_name_unique UNIQUE (name);

-- =====================================================
-- ÍNDICES
-- =====================================================

-- Índice para busca por nome
CREATE INDEX idx_installment_statuses_name ON billing.installment_statuses (name);

-- Índice para status ativos
CREATE INDEX idx_installment_statuses_is_active ON billing.installment_statuses (is_active);

-- =====================================================
-- TRIGGERS
-- =====================================================

-- Trigger para updated_at
SELECT aux.create_updated_at_trigger('billing', 'installment_statuses');

-- =====================================================
-- AUDITORIA
-- =====================================================

-- Criar tabela de auditoria
SELECT audit.create_audit_table('billing', 'installment_statuses');
