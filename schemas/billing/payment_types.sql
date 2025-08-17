-- =====================================================
-- TABELA: payment_types - Tipos de Pagamento
-- =====================================================
-- Descrição: Tipos de pagamento disponíveis no sistema
-- Funcionalidades: Definição de tipos, controle de suporte a parcelamento

-- =====================================================
-- CRIAÇÃO DA TABELA
-- =====================================================

CREATE TABLE billing.payment_types (
    payment_type_id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    description text NOT NULL,
    supports_installments boolean NOT NULL DEFAULT false,
    is_active boolean NOT NULL DEFAULT true,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);

-- =====================================================
-- COMENTÁRIOS
-- =====================================================

COMMENT ON TABLE billing.payment_types IS 'Tipos de pagamento disponíveis no sistema';

COMMENT ON COLUMN billing.payment_types.payment_type_id IS 'Identificador único do tipo de pagamento';
COMMENT ON COLUMN billing.payment_types.name IS 'Nome do tipo (ex: credit_card, pix, boleto, invoiced)';
COMMENT ON COLUMN billing.payment_types.description IS 'Descrição do tipo de pagamento';
COMMENT ON COLUMN billing.payment_types.supports_installments IS 'Indica se suporta parcelamento';
COMMENT ON COLUMN billing.payment_types.is_active IS 'Indica se o tipo está ativo';
COMMENT ON COLUMN billing.payment_types.created_at IS 'Data de criação do registro';
COMMENT ON COLUMN billing.payment_types.updated_at IS 'Data da última atualização do registro';

-- =====================================================
-- CONSTRAINTS
-- =====================================================

-- Chave primária
ALTER TABLE billing.payment_types ADD CONSTRAINT payment_types_pkey PRIMARY KEY (payment_type_id);

-- Nome único
ALTER TABLE billing.payment_types ADD CONSTRAINT payment_types_name_unique UNIQUE (name);

-- =====================================================
-- ÍNDICES
-- =====================================================

-- Índice para busca por nome
CREATE INDEX idx_payment_types_name ON billing.payment_types (name);

-- Índice para tipos que suportam parcelamento
CREATE INDEX idx_payment_types_supports_installments ON billing.payment_types (supports_installments);

-- Índice para tipos ativos
CREATE INDEX idx_payment_types_is_active ON billing.payment_types (is_active);

-- =====================================================
-- TRIGGERS
-- =====================================================

-- Trigger para updated_at
SELECT aux.create_updated_at_trigger('billing', 'payment_types');

-- =====================================================
-- AUDITORIA
-- =====================================================

-- Criar tabela de auditoria
SELECT audit.create_audit_table('billing', 'payment_types');
