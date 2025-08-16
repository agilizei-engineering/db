-- =====================================================
-- TABELA: plan_changes - Histórico de Mudanças de Planos
-- =====================================================
-- Descrição: Histórico de upgrades, downgrades e renovações
-- Funcionalidades: Rastreamento de mudanças, controle de créditos para downgrades

-- =====================================================
-- CRIAÇÃO DA TABELA
-- =====================================================

CREATE TABLE subscriptions.plan_changes (
    change_id uuid DEFAULT gen_random_uuid() NOT NULL,
    subscription_id uuid NOT NULL REFERENCES subscriptions.subscriptions(subscription_id) ON DELETE CASCADE,
    change_type text NOT NULL,
    old_plan_id uuid REFERENCES subscriptions.plans(plan_id) ON DELETE SET NULL,
    new_plan_id uuid NOT NULL REFERENCES subscriptions.plans(plan_id) ON DELETE CASCADE,
    change_date timestamp without time zone DEFAULT now() NOT NULL,
    change_reason text,
    credits_given numeric(10,2) DEFAULT 0,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now()
);

-- =====================================================
-- COMENTÁRIOS
-- =====================================================

COMMENT ON TABLE subscriptions.plan_changes IS 'Histórico de upgrades, downgrades e renovações';

COMMENT ON COLUMN subscriptions.plan_changes.change_id IS 'Identificador único da mudança';
COMMENT ON COLUMN subscriptions.plan_changes.subscription_id IS 'Referência à assinatura';
COMMENT ON COLUMN subscriptions.plan_changes.change_type IS 'Tipo de mudança (upgrade, downgrade, renewal)';
COMMENT ON COLUMN subscriptions.plan_changes.old_plan_id IS 'Referência ao plano anterior (NULL para novas assinaturas)';
COMMENT ON COLUMN subscriptions.plan_changes.new_plan_id IS 'Referência ao novo plano';
COMMENT ON COLUMN subscriptions.plan_changes.change_date IS 'Data da mudança';
COMMENT ON COLUMN subscriptions.plan_changes.change_reason IS 'Motivo da mudança';
COMMENT ON COLUMN subscriptions.plan_changes.credits_given IS 'Créditos dados para downgrades';
COMMENT ON COLUMN subscriptions.plan_changes.created_at IS 'Data de criação do registro';
COMMENT ON COLUMN subscriptions.plan_changes.updated_at IS 'Data da última atualização do registro';

-- =====================================================
-- CONSTRAINTS
-- =====================================================

-- Chave primária
ALTER TABLE subscriptions.plan_changes ADD CONSTRAINT plan_changes_pkey PRIMARY KEY (change_id);

-- Chave estrangeira para assinaturas
ALTER TABLE subscriptions.plan_changes ADD CONSTRAINT plan_changes_subscription_id_fkey 
    FOREIGN KEY (subscription_id) REFERENCES subscriptions.subscriptions(subscription_id) ON DELETE CASCADE;

-- Chave estrangeira para plano anterior
ALTER TABLE subscriptions.plan_changes ADD CONSTRAINT plan_changes_old_plan_id_fkey 
    FOREIGN KEY (old_plan_id) REFERENCES subscriptions.plans(plan_id) ON DELETE SET NULL;

-- Chave estrangeira para novo plano
ALTER TABLE subscriptions.plan_changes ADD CONSTRAINT plan_changes_new_plan_id_fkey 
    FOREIGN KEY (new_plan_id) REFERENCES subscriptions.plans(plan_id) ON DELETE CASCADE;

-- Validação de tipo de mudança
ALTER TABLE subscriptions.plan_changes ADD CONSTRAINT plan_changes_change_type_check 
    CHECK (change_type IN ('upgrade', 'downgrade', 'renewal'));

-- Validação de planos diferentes
ALTER TABLE subscriptions.plan_changes ADD CONSTRAINT plan_changes_different_plans_check 
    CHECK (old_plan_id != new_plan_id);

-- Validação de créditos não negativos
ALTER TABLE subscriptions.plan_changes ADD CONSTRAINT plan_changes_credits_given_check 
    CHECK (credits_given >= 0);

-- =====================================================
-- ÍNDICES
-- =====================================================

-- Índice para busca por assinatura
CREATE INDEX idx_plan_changes_subscription ON subscriptions.plan_changes (subscription_id);

-- Índice para busca por data
CREATE INDEX idx_plan_changes_date ON subscriptions.plan_changes (change_date);

-- Índice para tipo de mudança
CREATE INDEX idx_plan_changes_type ON subscriptions.plan_changes (change_type);

-- =====================================================
-- TRIGGERS
-- =====================================================

-- Trigger para updated_at
SELECT aux.create_updated_at_trigger('subscriptions', 'plan_changes');

-- =====================================================
-- AUDITORIA
-- =====================================================

-- Criar tabela de auditoria
SELECT audit.create_audit_table('subscriptions', 'plan_changes');
