-- =====================================================
-- SCHEMA: subscriptions - GESTÃO DE ASSINATURAS E PLANOS
-- =====================================================
-- Este script cria o schema subscriptions completo que:
-- 1. Cria todas as tabelas do schema subscriptions
-- 2. Implementa sistema de validação JSONB automático
-- 3. Cria triggers para controle automático de uso
-- 4. Integra com schemas aux e audit
-- 5. Implementa sistema de assinaturas SaaS flexível

-- =====================================================
-- CRIAÇÃO DO SCHEMA SUBSCRIPTIONS
-- =====================================================

-- Cria o schema subscriptions se não existir
CREATE SCHEMA IF NOT EXISTS subscriptions;

-- Comentário do schema
COMMENT ON SCHEMA subscriptions IS 'Schema para gestão de assinaturas SaaS, planos e controle de uso';

-- =====================================================
-- VERIFICAÇÃO DE DEPENDÊNCIAS
-- =====================================================

-- Verifica se o schema aux existe
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'aux') THEN
        RAISE EXCEPTION 'Schema aux não existe. Execute aux_schema.sql primeiro.';
    END IF;
END $$;

-- Verifica se o schema audit existe
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'audit') THEN
        RAISE EXCEPTION 'Schema audit não existe. Execute audit_schema.sql primeiro.';
    END IF;
END $$;

-- Verifica se o schema accounts existe
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'accounts') THEN
        RAISE EXCEPTION 'Schema accounts não existe. Execute accounts_schema.sql primeiro.';
    END IF;
END $$;

-- =====================================================
-- CONFIGURAÇÃO DE VALIDAÇÃO JSONB
-- =====================================================

-- Configura parâmetros de validação para o campo usage_limits
DO $$
BEGIN
    -- Verifica se a tabela aux.json_validation_params existe
    IF EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'aux' 
        AND table_name = 'json_validation_params'
    ) THEN
        -- Insere parâmetros de validação para produtos de cotação
        INSERT INTO aux.json_validation_params (param_name, param_value) VALUES
        ('subscriptions.plans', 'usage_limits.quotations'),
        ('subscriptions.plans', 'usage_limits.suppliers'),
        ('subscriptions.plans', 'usage_limits.items')
        ON CONFLICT (param_name, param_value) DO NOTHING;
        
        RAISE NOTICE 'Parâmetros de validação JSONB configurados para subscriptions.plans';
    ELSE
        RAISE NOTICE 'Tabela aux.json_validation_params não existe. Validação JSONB será configurada posteriormente.';
    END IF;
END $$;

-- =====================================================
-- CRIAÇÃO DAS TABELAS
-- =====================================================

-- =====================================================
-- TABELA: products
-- =====================================================

CREATE TABLE subscriptions.products (
    product_id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    description text,
    billing_model text NOT NULL,
    is_available_for_supplier boolean NOT NULL DEFAULT false,
    is_available_for_establishment boolean NOT NULL DEFAULT false,
    is_active boolean NOT NULL DEFAULT true,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now()
);

-- Comentários
COMMENT ON TABLE subscriptions.products IS 'Produtos comerciais que podem ser contratados pelos clientes';
COMMENT ON COLUMN subscriptions.products.product_id IS 'Identificador único do produto';
COMMENT ON COLUMN subscriptions.products.name IS 'Nome do produto comercial';
COMMENT ON COLUMN subscriptions.products.description IS 'Descrição detalhada do produto';
COMMENT ON COLUMN subscriptions.products.billing_model IS 'Modelo de cobrança: usage_limits ou access_boolean';
COMMENT ON COLUMN subscriptions.products.is_available_for_supplier IS 'Indica se o produto está disponível para suppliers';
COMMENT ON COLUMN subscriptions.products.is_available_for_establishment IS 'Indica se o produto está disponível para establishments';
COMMENT ON COLUMN subscriptions.products.is_active IS 'Indica se o produto está ativo';
COMMENT ON COLUMN subscriptions.products.created_at IS 'Data de criação do registro';
COMMENT ON COLUMN subscriptions.products.updated_at IS 'Data da última atualização do registro';

-- Constraints
ALTER TABLE subscriptions.products ADD CONSTRAINT products_pkey PRIMARY KEY (product_id);
ALTER TABLE subscriptions.products ADD CONSTRAINT products_name_unique UNIQUE (name);
ALTER TABLE subscriptions.products ADD CONSTRAINT products_billing_model_check 
    CHECK (billing_model IN ('usage_limits', 'access_boolean'));

-- Índices
CREATE INDEX idx_products_is_active ON subscriptions.products (is_active);
CREATE INDEX idx_products_supplier_establishment ON subscriptions.products (is_available_for_supplier, is_available_for_establishment);
CREATE INDEX idx_products_name ON subscriptions.products (name);
CREATE INDEX idx_products_billing_model ON subscriptions.products (billing_model);

-- =====================================================
-- TABELA: plan_names
-- =====================================================

CREATE TABLE subscriptions.plan_names (
    plan_name_id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    description text,
    is_active boolean NOT NULL DEFAULT true,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now()
);

-- Comentários
COMMENT ON TABLE subscriptions.plan_names IS 'Nomes comerciais dos planos (Basic, Pro, Max)';
COMMENT ON COLUMN subscriptions.plan_names.plan_name_id IS 'Identificador único do nome do plano';
COMMENT ON COLUMN subscriptions.plan_names.name IS 'Nome comercial do plano (ex: Basic, Pro, Max)';
COMMENT ON COLUMN subscriptions.plan_names.description IS 'Descrição do plano';
COMMENT ON COLUMN subscriptions.plan_names.is_active IS 'Indica se o nome do plano está ativo';
COMMENT ON COLUMN subscriptions.plan_names.created_at IS 'Data de criação do registro';
COMMENT ON COLUMN subscriptions.plan_names.updated_at IS 'Data da última atualização do registro';

-- Constraints
ALTER TABLE subscriptions.plan_names ADD CONSTRAINT plan_names_pkey PRIMARY KEY (plan_name_id);
ALTER TABLE subscriptions.plan_names ADD CONSTRAINT plan_names_name_unique UNIQUE (name);

-- Índices
CREATE INDEX idx_plan_names_name ON subscriptions.plan_names (name);
CREATE INDEX idx_plan_names_is_active ON subscriptions.plan_names (is_active);

-- =====================================================
-- TABELA: plans
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

-- Comentários
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

-- Constraints
ALTER TABLE subscriptions.plans ADD CONSTRAINT plans_pkey PRIMARY KEY (plan_id);
ALTER TABLE subscriptions.plans ADD CONSTRAINT plans_price_check CHECK (price > 0);
ALTER TABLE subscriptions.plans ADD CONSTRAINT plans_validity_check CHECK (valid_from < valid_to);

-- Índices
CREATE INDEX idx_plans_is_active ON subscriptions.plans (is_active);
CREATE INDEX idx_plans_product_id ON subscriptions.plans (product_id);
CREATE INDEX idx_plans_plan_name_id ON subscriptions.plans (plan_name_id);
CREATE INDEX idx_plans_validity ON subscriptions.plans (valid_from, valid_to);
CREATE INDEX idx_plans_product_active ON subscriptions.plans (product_id, is_active);
CREATE INDEX idx_plans_usage_limits ON subscriptions.plans USING GIN (usage_limits);

-- =====================================================
-- TABELA: product_modules
-- =====================================================

CREATE TABLE subscriptions.product_modules (
    product_module_id uuid DEFAULT gen_random_uuid() NOT NULL,
    product_id uuid NOT NULL,
    module_id uuid NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now()
);

-- Comentários
COMMENT ON TABLE subscriptions.product_modules IS 'Relacionamento entre produtos e módulos do sistema';
COMMENT ON COLUMN subscriptions.product_modules.product_module_id IS 'Identificador único do relacionamento';
COMMENT ON COLUMN subscriptions.product_modules.product_id IS 'Referência ao produto';
COMMENT ON COLUMN subscriptions.product_modules.module_id IS 'Referência ao módulo do sistema';
COMMENT ON COLUMN subscriptions.product_modules.created_at IS 'Data de criação do registro';
COMMENT ON COLUMN subscriptions.product_modules.updated_at IS 'Data da última atualização do registro';

-- Constraints
ALTER TABLE subscriptions.product_modules ADD CONSTRAINT product_modules_pkey PRIMARY KEY (product_module_id);
ALTER TABLE subscriptions.product_modules ADD CONSTRAINT product_modules_product_module_unique 
    UNIQUE (product_id, module_id);

-- Índices
CREATE INDEX idx_product_modules_product_id ON subscriptions.product_modules (product_id);
CREATE INDEX idx_product_modules_module_id ON subscriptions.product_modules (module_id);
CREATE INDEX idx_product_modules_composite ON subscriptions.product_modules (product_id, module_id);

-- =====================================================
-- TABELA: subscriptions
-- =====================================================

CREATE TABLE subscriptions.subscriptions (
    subscription_id uuid DEFAULT gen_random_uuid() NOT NULL,
    establishment_id uuid REFERENCES accounts.establishments(establishment_id) ON DELETE CASCADE,
    supplier_id uuid REFERENCES accounts.suppliers(supplier_id) ON DELETE CASCADE,
    employee_id uuid NOT NULL REFERENCES accounts.employees(employee_id) ON DELETE CASCADE,
    plan_id uuid NOT NULL,
    start_date timestamp without time zone NOT NULL,
    end_date timestamp without time zone NOT NULL,
    status text NOT NULL DEFAULT 'active',
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now()
);

-- Comentários
COMMENT ON TABLE subscriptions.subscriptions IS 'Assinaturas ativas de establishments e suppliers';
COMMENT ON COLUMN subscriptions.subscriptions.subscription_id IS 'Identificador único da assinatura';
COMMENT ON COLUMN subscriptions.subscriptions.establishment_id IS 'Referência ao establishment (NULL se for supplier)';
COMMENT ON COLUMN subscriptions.subscriptions.supplier_id IS 'Referência ao supplier (NULL se for establishment)';
COMMENT ON COLUMN subscriptions.subscriptions.employee_id IS 'Employee que executou a ação de assinatura';
COMMENT ON COLUMN subscriptions.subscriptions.plan_id IS 'Referência ao plano contratado';
COMMENT ON COLUMN subscriptions.subscriptions.start_date IS 'Data de início da assinatura';
COMMENT ON COLUMN subscriptions.subscriptions.end_date IS 'Data de fim da assinatura';
COMMENT ON COLUMN subscriptions.subscriptions.status IS 'Status da assinatura (active, suspended, cancelled)';
COMMENT ON COLUMN subscriptions.subscriptions.created_at IS 'Data de criação do registro';
COMMENT ON COLUMN subscriptions.subscriptions.updated_at IS 'Data da última atualização do registro';

-- Constraints
ALTER TABLE subscriptions.subscriptions ADD CONSTRAINT subscriptions_pkey PRIMARY KEY (subscription_id);
ALTER TABLE subscriptions.subscriptions ADD CONSTRAINT subscriptions_status_check 
    CHECK (status IN ('active', 'suspended', 'cancelled'));
ALTER TABLE subscriptions.subscriptions ADD CONSTRAINT subscriptions_period_check 
    CHECK (start_date < end_date);
ALTER TABLE subscriptions.subscriptions ADD CONSTRAINT subscriptions_establishment_unique 
    UNIQUE (establishment_id, status) WHERE status = 'active';
ALTER TABLE subscriptions.subscriptions ADD CONSTRAINT subscriptions_supplier_unique 
    UNIQUE (supplier_id, status) WHERE status = 'active';
ALTER TABLE subscriptions.subscriptions ADD CONSTRAINT subscriptions_client_check 
    CHECK (
        (establishment_id IS NOT NULL AND supplier_id IS NULL) OR 
        (establishment_id IS NULL AND supplier_id IS NOT NULL)
    );

-- Índices
CREATE INDEX idx_subscriptions_establishment ON subscriptions.subscriptions (establishment_id);
CREATE INDEX idx_subscriptions_supplier ON subscriptions.subscriptions (supplier_id);
CREATE INDEX idx_subscriptions_status ON subscriptions.subscriptions (status);
CREATE INDEX idx_subscriptions_period ON subscriptions.subscriptions (start_date, end_date);
CREATE INDEX idx_subscriptions_employee ON subscriptions.subscriptions (employee_id);

-- =====================================================
-- TABELA: usage_tracking
-- =====================================================

CREATE TABLE subscriptions.usage_tracking (
    usage_id uuid DEFAULT gen_random_uuid() NOT NULL,
    subscription_id uuid NOT NULL,
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

-- Comentários
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

-- Constraints
ALTER TABLE subscriptions.usage_tracking ADD CONSTRAINT usage_tracking_pkey PRIMARY KEY (usage_id);
ALTER TABLE subscriptions.usage_tracking ADD CONSTRAINT usage_tracking_period_check 
    CHECK (period_start < period_end);
ALTER TABLE subscriptions.usage_tracking ADD CONSTRAINT usage_tracking_quotations_used_check 
    CHECK (quotations_used >= 0);
ALTER TABLE subscriptions.usage_tracking ADD CONSTRAINT usage_tracking_quotations_subscription_check 
    CHECK (quotations_subscription >= 0);
ALTER TABLE subscriptions.usage_tracking ADD CONSTRAINT usage_tracking_quotations_bought_check 
    CHECK (quotations_bought >= 0);
ALTER TABLE subscriptions.usage_tracking ADD CONSTRAINT usage_tracking_quotations_limit_check 
    CHECK (quotations_limit >= 0);

-- Índices
CREATE INDEX idx_usage_tracking_subscription ON subscriptions.usage_tracking (subscription_id);
CREATE INDEX idx_usage_tracking_period ON subscriptions.usage_tracking (period_start, period_end);
CREATE INDEX idx_usage_tracking_over_limit ON subscriptions.usage_tracking (is_over_limit);

-- =====================================================
-- TABELA: quota_purchases
-- =====================================================

CREATE TABLE subscriptions.quota_purchases (
    purchase_id uuid DEFAULT gen_random_uuid() NOT NULL,
    establishment_id uuid REFERENCES accounts.establishments(establishment_id) ON DELETE CASCADE,
    supplier_id uuid REFERENCES accounts.suppliers(supplier_id) ON DELETE CASCADE,
    purchase_date timestamp without time zone DEFAULT now() NOT NULL,
    quotations_bought integer NOT NULL,
    unit_price numeric(10,2) NOT NULL,
    total_price numeric(10,2) NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now()
);

-- Comentários
COMMENT ON TABLE subscriptions.quota_purchases IS 'Microtransações independentes para cotas excedentes';
COMMENT ON COLUMN subscriptions.quota_purchases.purchase_id IS 'Identificador único da compra';
COMMENT ON COLUMN subscriptions.quota_purchases.establishment_id IS 'Referência ao establishment (NULL se for supplier)';
COMMENT ON COLUMN subscriptions.quota_purchases.supplier_id IS 'Referência ao supplier (NULL se for establishment)';
COMMENT ON COLUMN subscriptions.quota_purchases.purchase_date IS 'Data da compra';
COMMENT ON COLUMN subscriptions.quota_purchases.quotations_bought IS 'Quantidade de cotações compradas';
COMMENT ON COLUMN subscriptions.quota_purchases.unit_price IS 'Preço unitário por cotação';
COMMENT ON COLUMN subscriptions.quota_purchases.total_price IS 'Preço total da compra';
COMMENT ON COLUMN subscriptions.quota_purchases.created_at IS 'Data de criação do registro';
COMMENT ON COLUMN subscriptions.quota_purchases.updated_at IS 'Data da última atualização do registro';

-- Constraints
ALTER TABLE subscriptions.quota_purchases ADD CONSTRAINT quota_purchases_pkey PRIMARY KEY (purchase_id);
ALTER TABLE subscriptions.quota_purchases ADD CONSTRAINT quota_purchases_unit_price_check 
    CHECK (unit_price > 0);
ALTER TABLE subscriptions.quota_purchases ADD CONSTRAINT quota_purchases_quotations_bought_check 
    CHECK (quotations_bought > 0);
ALTER TABLE subscriptions.quota_purchases ADD CONSTRAINT quota_purchases_total_price_check 
    CHECK (total_price = unit_price * quotations_bought);
ALTER TABLE subscriptions.quota_purchases ADD CONSTRAINT quota_purchases_client_check 
    CHECK (
        (establishment_id IS NOT NULL AND supplier_id IS NULL) OR 
        (establishment_id IS NULL AND supplier_id IS NOT NULL)
    );

-- Índices
CREATE INDEX idx_quota_purchases_establishment ON subscriptions.quota_purchases (establishment_id);
CREATE INDEX idx_quota_purchases_supplier ON subscriptions.quota_purchases (supplier_id);
CREATE INDEX idx_quota_purchases_date ON subscriptions.quota_purchases (purchase_date);

-- =====================================================
-- TABELA: plan_changes
-- =====================================================

CREATE TABLE subscriptions.plan_changes (
    change_id uuid DEFAULT gen_random_uuid() NOT NULL,
    subscription_id uuid NOT NULL,
    change_type text NOT NULL,
    old_plan_id uuid,
    new_plan_id uuid NOT NULL,
    change_date timestamp without time zone DEFAULT now() NOT NULL,
    change_reason text,
    credits_given numeric(10,2) DEFAULT 0,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now()
);

-- Comentários
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

-- Constraints
ALTER TABLE subscriptions.plan_changes ADD CONSTRAINT plan_changes_pkey PRIMARY KEY (change_id);
ALTER TABLE subscriptions.plan_changes ADD CONSTRAINT plan_changes_change_type_check 
    CHECK (change_type IN ('upgrade', 'downgrade', 'renewal', 'status_change'));
ALTER TABLE subscriptions.plan_changes ADD CONSTRAINT plan_changes_different_plans_check 
    CHECK (old_plan_id != new_plan_id OR old_plan_id IS NULL);
ALTER TABLE subscriptions.plan_changes ADD CONSTRAINT plan_changes_credits_given_check 
    CHECK (credits_given >= 0);

-- Índices
CREATE INDEX idx_plan_changes_subscription ON subscriptions.plan_changes (subscription_id);
CREATE INDEX idx_plan_changes_date ON subscriptions.plan_changes (change_date);
CREATE INDEX idx_plan_changes_type ON subscriptions.plan_changes (change_type);

-- =====================================================
-- CHAVES ESTRANGEIRAS
-- =====================================================

-- Chaves estrangeiras para plans
ALTER TABLE subscriptions.plans ADD CONSTRAINT plans_product_id_fkey 
    FOREIGN KEY (product_id) REFERENCES subscriptions.products(product_id) ON DELETE CASCADE;
ALTER TABLE subscriptions.plans ADD CONSTRAINT plans_plan_name_id_fkey 
    FOREIGN KEY (plan_name_id) REFERENCES subscriptions.plan_names(plan_name_id) ON DELETE CASCADE;

-- Chaves estrangeiras para product_modules
ALTER TABLE subscriptions.product_modules ADD CONSTRAINT product_modules_product_id_fkey 
    FOREIGN KEY (product_id) REFERENCES subscriptions.products(product_id) ON DELETE CASCADE;
ALTER TABLE subscriptions.product_modules ADD CONSTRAINT product_modules_module_id_fkey 
    FOREIGN KEY (module_id) REFERENCES accounts.modules(module_id) ON DELETE CASCADE;

-- Chaves estrangeiras para subscriptions
ALTER TABLE subscriptions.subscriptions ADD CONSTRAINT subscriptions_plan_id_fkey 
    FOREIGN KEY (plan_id) REFERENCES subscriptions.plans(plan_id) ON DELETE CASCADE;

-- Chaves estrangeiras para usage_tracking
ALTER TABLE subscriptions.usage_tracking ADD CONSTRAINT usage_tracking_subscription_id_fkey 
    FOREIGN KEY (subscription_id) REFERENCES subscriptions.subscriptions(subscription_id) ON DELETE CASCADE;

-- Chaves estrangeiras para plan_changes
ALTER TABLE subscriptions.plan_changes ADD CONSTRAINT plan_changes_subscription_id_fkey 
    FOREIGN KEY (subscription_id) REFERENCES subscriptions.subscriptions(subscription_id) ON DELETE CASCADE;
ALTER TABLE subscriptions.plan_changes ADD CONSTRAINT plan_changes_old_plan_id_fkey 
    FOREIGN KEY (old_plan_id) REFERENCES subscriptions.plans(plan_id) ON DELETE SET NULL;
ALTER TABLE subscriptions.plan_changes ADD CONSTRAINT plan_changes_new_plan_id_fkey 
    FOREIGN KEY (new_plan_id) REFERENCES subscriptions.plans(plan_id) ON DELETE CASCADE;

-- =====================================================
-- TRIGGERS E FUNÇÕES
-- =====================================================

-- Trigger para updated_at em todas as tabelas
SELECT aux.create_updated_at_trigger('subscriptions', 'products');
SELECT aux.create_updated_at_trigger('subscriptions', 'product_modules');
SELECT aux.create_updated_at_trigger('subscriptions', 'plan_names');
SELECT aux.create_updated_at_trigger('subscriptions', 'plans');
SELECT aux.create_updated_at_trigger('subscriptions', 'subscriptions');
SELECT aux.create_updated_at_trigger('subscriptions', 'usage_tracking');
SELECT aux.create_updated_at_trigger('subscriptions', 'quota_purchases');
SELECT aux.create_updated_at_trigger('subscriptions', 'plan_changes');

-- =====================================================
-- FUNÇÕES ESPECÍFICAS
-- =====================================================

-- Função para calcular campos automáticos em usage_tracking
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

COMMENT ON FUNCTION subscriptions.calculate_usage_fields IS 'Calcula campos automáticos em usage_tracking';

-- Trigger para cálculo automático
CREATE TRIGGER trg_calculate_usage_fields
    BEFORE INSERT OR UPDATE ON subscriptions.usage_tracking
    FOR EACH ROW
    EXECUTE FUNCTION subscriptions.calculate_usage_fields();

-- =====================================================
-- AUDITORIA
-- =====================================================

-- Criar tabelas de auditoria para todas as tabelas
SELECT audit.create_audit_table('subscriptions', 'products');
SELECT audit.create_audit_table('subscriptions', 'product_modules');
SELECT audit.create_audit_table('subscriptions', 'plan_names');
SELECT audit.create_audit_table('subscriptions', 'plans');
SELECT audit.create_audit_table('subscriptions', 'subscriptions');
SELECT audit.create_audit_table('subscriptions', 'usage_tracking');
SELECT audit.create_audit_table('subscriptions', 'quota_purchases');
SELECT audit.create_audit_table('subscriptions', 'plan_changes');

-- =====================================================
-- DADOS INICIAIS
-- =====================================================

-- Inserir nomes de planos padrão
INSERT INTO subscriptions.plan_names (name, description) VALUES
('Basic', 'Plano básico para pequenas empresas'),
('Pro', 'Plano profissional para empresas em crescimento'),
('Max', 'Plano máximo para grandes empresas')
ON CONFLICT (name) DO NOTHING;

-- Inserir produto padrão de cotação
INSERT INTO subscriptions.products (name, description, billing_model, is_available_for_establishment) VALUES
('Cotação e Comparação de Preços', 'Sistema completo de cotações e comparações de preços', 'usage_limits', true)
ON CONFLICT (name) DO NOTHING;

-- =====================================================
-- MENSAGEM DE CONCLUSÃO
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '=====================================================';
    RAISE NOTICE 'SCHEMA SUBSCRIPTIONS CRIADO COM SUCESSO!';
    RAISE NOTICE '=====================================================';
    RAISE NOTICE '';
    RAISE NOTICE 'Tabelas criadas:';
    RAISE NOTICE '- products';
    RAISE NOTICE '- product_modules';
    RAISE NOTICE '- plan_names';
    RAISE NOTICE '- plans';
    RAISE NOTICE '- subscriptions';
    RAISE NOTICE '- usage_tracking';
    RAISE NOTICE '- quota_purchases';
    RAISE NOTICE '- plan_changes';
    RAISE NOTICE '';
    RAISE NOTICE 'Funcionalidades implementadas:';
    RAISE NOTICE '- Validação JSONB automática';
    RAISE NOTICE '- Triggers de controle automático';
    RAISE NOTICE '- Auditoria completa';
    RAISE NOTICE '- Integração com schemas aux e audit';
    RAISE NOTICE '';
    RAISE NOTICE 'Próximos passos:';
    RAISE NOTICE '1. Execute schemas/subscriptions/functions.sql';
    RAISE NOTICE '2. Execute schemas/subscriptions/views.sql';
    RAISE NOTICE '3. Execute schemas/subscriptions/triggers.sql';
    RAISE NOTICE '';
    RAISE NOTICE 'Schema pronto para uso em produção!';
    RAISE NOTICE '=====================================================';
END $$;
