-- =====================================================
-- TABELA: usage_tracking - Controle de Uso das Assinaturas
-- =====================================================
-- Descrição: Tracking de uso das funcionalidades por período
-- Funcionalidades: Controle de cotas, tracking de uso, identificação de limites excedidos
-- Campos calculados: quotations_limit (quotations_subscription + quotations_bought), is_over_limit (quotations_used > quotations_limit)

-- =====================================================
-- CRIAÇÃO DA TABELA
-- =====================================================

CREATE TABLE subscriptions.usage_tracking (
    usage_id uuid DEFAULT gen_random_uuid() NOT NULL,
    subscription_id uuid NOT NULL REFERENCES subscriptions.subscriptions(subscription_id) ON DELETE CASCADE,
    period_start timestamp without time zone NOT NULL,
    period_end timestamp without time zone NOT NULL,
    quotations_used integer NOT NULL DEFAULT 0,
    quotations_subscription integer NOT NULL,
    quotations_bought integer NOT NULL DEFAULT 0,
    quotations_limit integer NOT NULL,
    is_over_limit boolean NOT NULL DEFAULT false,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now()
);

-- =====================================================
-- COMENTÁRIOS
-- =====================================================

COMMENT ON TABLE subscriptions.usage_tracking IS 'Tracking de uso das funcionalidades por período';

COMMENT ON COLUMN subscriptions.usage_tracking.usage_id IS 'Identificador único do registro de uso';
COMMENT ON COLUMN subscriptions.usage_tracking.subscription_id IS 'Referência à assinatura';
COMMENT ON COLUMN subscriptions.usage_tracking.period_start IS 'Início do período de controle';
COMMENT ON COLUMN subscriptions.usage_tracking.period_end IS 'Fim do período de controle';
COMMENT ON COLUMN subscriptions.usage_tracking.quotations_used IS 'Quantidade de cotações utilizadas no período';
COMMENT ON COLUMN subscriptions.usage_tracking.quotations_subscription IS 'Limite de cotações da assinatura';
COMMENT ON COLUMN subscriptions.usage_tracking.quotations_bought IS 'Quantidade de cotações compradas via microtransações';
COMMENT ON COLUMN subscriptions.usage_tracking.quotations_limit IS 'Limite total (assinatura + compradas)';
COMMENT ON COLUMN subscriptions.usage_tracking.is_over_limit IS 'Indica se o uso excedeu o limite';
COMMENT ON COLUMN subscriptions.usage_tracking.created_at IS 'Data de criação do registro';
COMMENT ON COLUMN subscriptions.usage_tracking.updated_at IS 'Data da última atualização do registro';

-- =====================================================
-- CONSTRAINTS
-- =====================================================

-- Chave primária
ALTER TABLE subscriptions.usage_tracking ADD CONSTRAINT usage_tracking_pkey PRIMARY KEY (usage_id);

-- Chave estrangeira para assinaturas
ALTER TABLE subscriptions.usage_tracking ADD CONSTRAINT usage_tracking_subscription_id_fkey 
    FOREIGN KEY (subscription_id) REFERENCES subscriptions.subscriptions(subscription_id) ON DELETE CASCADE;

-- Validação de período
ALTER TABLE subscriptions.usage_tracking ADD CONSTRAINT usage_tracking_period_check 
    CHECK (period_start < period_end);

-- Validação de valores não negativos
ALTER TABLE subscriptions.usage_tracking ADD CONSTRAINT usage_tracking_quotations_used_check 
    CHECK (quotations_used >= 0);

ALTER TABLE subscriptions.usage_tracking ADD CONSTRAINT usage_tracking_quotations_subscription_check 
    CHECK (quotations_subscription >= 0);

ALTER TABLE subscriptions.usage_tracking ADD CONSTRAINT usage_tracking_quotations_bought_check 
    CHECK (quotations_bought >= 0);

ALTER TABLE subscriptions.usage_tracking ADD CONSTRAINT usage_tracking_quotations_limit_check 
    CHECK (quotations_limit >= 0);

-- =====================================================
-- ÍNDICES
-- =====================================================

-- Índice para busca por assinatura
CREATE INDEX idx_usage_tracking_subscription ON subscriptions.usage_tracking (subscription_id);

-- Índice para busca por período
CREATE INDEX idx_usage_tracking_period ON subscriptions.usage_tracking (period_start, period_end);

-- Índice para uso excedido
CREATE INDEX idx_usage_tracking_over_limit ON subscriptions.usage_tracking (is_over_limit);

-- =====================================================
-- TRIGGERS
-- =====================================================

-- Trigger para updated_at
SELECT aux.create_updated_at_trigger('subscriptions', 'usage_tracking');

-- Trigger para calcular campos automáticos
CREATE OR REPLACE FUNCTION subscriptions.calculate_usage_fields()
RETURNS TRIGGER AS $$
BEGIN
    -- Calcular quotations_limit
    NEW.quotations_limit := NEW.quotations_subscription + NEW.quotations_bought;
    
    -- Calcular is_over_limit
    NEW.is_over_limit := NEW.quotations_used > NEW.quotations_limit;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_calculate_usage_fields
    BEFORE INSERT OR UPDATE ON subscriptions.usage_tracking
    FOR EACH ROW
    EXECUTE FUNCTION subscriptions.calculate_usage_fields();

-- =====================================================
-- AUDITORIA
-- =====================================================

-- Criar tabela de auditoria
SELECT audit.create_audit_table('subscriptions', 'usage_tracking');
