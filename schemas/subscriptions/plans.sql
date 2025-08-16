-- =====================================================
-- TABELA: plans - Configuração dos Planos
-- =====================================================
-- Descrição: Planos específicos com limites, preços e período de vigência
-- Funcionalidades: Definição de limites, preços e validade dos planos
-- Validações: JSONB usage_limits validado via aux.json_validation_params

-- =====================================================
-- CRIAÇÃO DA TABELA
-- =====================================================

CREATE TABLE subscriptions.plans (
    plan_id uuid DEFAULT gen_random_uuid() NOT NULL,
    product_id uuid NOT NULL,
    plan_name_id uuid NOT NULL,
    valid_from timestamp without time zone NOT NULL,
    valid_to timestamp without time zone NOT NULL,
    price numeric(10,2) NOT NULL,
    usage_limits jsonb NOT NULL,
    is_active boolean NOT NULL DEFAULT true,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now()
);

-- =====================================================
-- COMENTÁRIOS
-- =====================================================

COMMENT ON TABLE subscriptions.plans IS 'Planos específicos com limites, preços e período de vigência';

COMMENT ON COLUMN subscriptions.plans.plan_id IS 'Identificador único do plano';
COMMENT ON COLUMN subscriptions.plans.product_id IS 'Referência ao produto';
COMMENT ON COLUMN subscriptions.plans.plan_name_id IS 'Referência ao nome do plano';
COMMENT ON COLUMN subscriptions.plans.valid_from IS 'Data de início da vigência do plano';
COMMENT ON COLUMN subscriptions.plans.valid_to IS 'Data de fim da vigência do plano';
COMMENT ON COLUMN subscriptions.plans.price IS 'Preço mensal do plano';
COMMENT ON COLUMN subscriptions.plans.usage_limits IS 'Limites de uso em formato JSONB (ex: {"quotations": 100, "suppliers": 10, "items": 50})';
COMMENT ON COLUMN subscriptions.plans.is_active IS 'Indica se o plano está ativo';
COMMENT ON COLUMN subscriptions.plans.created_at IS 'Data de criação do registro';
COMMENT ON COLUMN subscriptions.plans.updated_at IS 'Data da última atualização do registro';

-- =====================================================
-- CONSTRAINTS
-- =====================================================

-- Chave primária
ALTER TABLE subscriptions.plans ADD CONSTRAINT plans_pkey PRIMARY KEY (plan_id);

-- Chave estrangeira para produtos
ALTER TABLE subscriptions.plans ADD CONSTRAINT plans_product_id_fkey 
    FOREIGN KEY (product_id) REFERENCES subscriptions.products(product_id) ON DELETE CASCADE;

-- Chave estrangeira para nomes dos planos
ALTER TABLE subscriptions.plans ADD CONSTRAINT plans_plan_name_id_fkey 
    FOREIGN KEY (plan_name_id) REFERENCES subscriptions.plan_names(plan_name_id) ON DELETE CASCADE;

-- Validação de preço
ALTER TABLE subscriptions.plans ADD CONSTRAINT plans_price_check CHECK (price > 0);

-- Validação de período de vigência
ALTER TABLE subscriptions.plans ADD CONSTRAINT plans_validity_check CHECK (valid_from < valid_to);

-- =====================================================
-- ÍNDICES
-- =====================================================

-- Índice para planos ativos
CREATE INDEX idx_plans_is_active ON subscriptions.plans (is_active);

-- Índice para busca por produto
CREATE INDEX idx_plans_product_id ON subscriptions.plans (product_id);

-- Índice para busca por nome do plano
CREATE INDEX idx_plans_plan_name_id ON subscriptions.plans (plan_name_id);

-- Índice para período de validade
CREATE INDEX idx_plans_validity ON subscriptions.plans (valid_from, valid_to);

-- Índice composto para planos ativos de um produto
CREATE INDEX idx_plans_product_active ON subscriptions.plans (product_id, is_active);

-- Índice para campo JSONB usage_limits
CREATE INDEX idx_plans_usage_limits ON subscriptions.plans USING GIN (usage_limits);

-- =====================================================
-- TRIGGERS
-- =====================================================

-- Trigger para updated_at
SELECT aux.create_updated_at_trigger('subscriptions', 'plans');

-- =====================================================
-- AUDITORIA
-- =====================================================

-- Criar tabela de auditoria
SELECT audit.create_audit_table('subscriptions', 'plans');
