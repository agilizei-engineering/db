-- =====================================================
-- TABELA: plan_names - Nomes dos Planos
-- =====================================================
-- Descrição: Nomes comerciais dos planos (Basic, Pro, Max)
-- Funcionalidades: Identificação comercial dos planos

-- =====================================================
-- CRIAÇÃO DA TABELA
-- =====================================================

CREATE TABLE subscriptions.plan_names (
    plan_name_id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    description text,
    is_active boolean NOT NULL DEFAULT true,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now()
);

-- =====================================================
-- COMENTÁRIOS
-- =====================================================

COMMENT ON TABLE subscriptions.plan_names IS 'Nomes comerciais dos planos (Basic, Pro, Max)';

COMMENT ON COLUMN subscriptions.plan_names.plan_name_id IS 'Identificador único do nome do plano';
COMMENT ON COLUMN subscriptions.plan_names.name IS 'Nome comercial do plano (ex: Basic, Pro, Max)';
COMMENT ON COLUMN subscriptions.plan_names.description IS 'Descrição do plano';
COMMENT ON COLUMN subscriptions.plan_names.is_active IS 'Indica se o nome do plano está ativo';
COMMENT ON COLUMN subscriptions.plan_names.created_at IS 'Data de criação do registro';
COMMENT ON COLUMN subscriptions.plan_names.updated_at IS 'Data da última atualização do registro';

-- =====================================================
-- CONSTRAINTS
-- =====================================================

-- Chave primária
ALTER TABLE subscriptions.plan_names ADD CONSTRAINT plan_names_pkey PRIMARY KEY (plan_name_id);

-- Nome único
ALTER TABLE subscriptions.plan_names ADD CONSTRAINT plan_names_name_unique UNIQUE (name);

-- =====================================================
-- ÍNDICES
-- =====================================================

-- Índice para busca por nome
CREATE INDEX idx_plan_names_name ON subscriptions.plan_names (name);

-- Índice para planos ativos
CREATE INDEX idx_plan_names_is_active ON subscriptions.plan_names (is_active);

-- =====================================================
-- TRIGGERS
-- =====================================================

-- Trigger para updated_at
SELECT aux.create_updated_at_trigger('subscriptions', 'plan_names');

-- =====================================================
-- AUDITORIA
-- =====================================================

-- Criar tabela de auditoria
SELECT audit.create_audit_table('subscriptions', 'plan_names');
