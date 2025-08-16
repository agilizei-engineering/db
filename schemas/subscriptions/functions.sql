-- =====================================================
-- FUNÇÕES DO SCHEMA: subscriptions
-- =====================================================
-- Este arquivo contém todas as funções PL/pgSQL relacionadas ao schema subscriptions
-- Inclui funções para gestão de produtos, planos, assinaturas e controle de uso

-- =====================================================
-- FUNÇÕES DE GESTÃO DE PRODUTOS E PLANOS
-- =====================================================

-- =====================================================
-- create_product
-- =====================================================
-- Cria um novo produto comercial
-- Parâmetros: nome, descrição, modelo de cobrança, disponibilidade para supplier/establishment
-- Retorna: product_id do produto criado

CREATE OR REPLACE FUNCTION subscriptions.create_product(
    p_name text,
    p_description text DEFAULT NULL,
    p_billing_model text DEFAULT 'usage_limits',
    p_is_available_for_supplier boolean DEFAULT false,
    p_is_available_for_establishment boolean DEFAULT false
)
RETURNS uuid
LANGUAGE plpgsql
AS $$
DECLARE
    v_product_id uuid;
BEGIN
    -- Validações
    IF p_name IS NULL OR p_name = '' THEN
        RAISE EXCEPTION 'Nome do produto é obrigatório';
    END IF;
    
    IF p_billing_model NOT IN ('usage_limits', 'access_boolean') THEN
        RAISE EXCEPTION 'Modelo de cobrança deve ser usage_limits ou access_boolean';
    END IF;
    
    -- Verifica se já existe produto com o mesmo nome
    IF EXISTS (SELECT 1 FROM subscriptions.products WHERE name = p_name) THEN
        RAISE EXCEPTION 'Produto com nome % já existe', p_name;
    END IF;
    
    -- Cria o produto
    INSERT INTO subscriptions.products (
        name, 
        description, 
        billing_model, 
        is_available_for_supplier, 
        is_available_for_establishment
    ) VALUES (
        p_name, 
        p_description, 
        p_billing_model, 
        p_is_available_for_supplier, 
        p_is_available_for_establishment
    ) RETURNING product_id INTO v_product_id;
    
    RAISE NOTICE 'Produto % criado com ID: %', p_name, v_product_id;
    
    RETURN v_product_id;
END;
$$;

COMMENT ON FUNCTION subscriptions.create_product IS 'Cria um novo produto comercial';

-- =====================================================
-- create_plan
-- =====================================================
-- Cria um novo plano para um produto
-- Parâmetros: product_id, plan_name_id, período de vigência, preço, limites de uso
-- Retorna: plan_id do plano criado

CREATE OR REPLACE FUNCTION subscriptions.create_plan(
    p_product_id uuid,
    p_plan_name_id uuid,
    p_valid_from timestamp without time zone,
    p_valid_to timestamp without time zone,
    p_price numeric(10,2),
    p_usage_limits jsonb DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
AS $$
DECLARE
    v_plan_id uuid;
    v_billing_model text;
BEGIN
    -- Validações
    IF p_product_id IS NULL THEN
        RAISE EXCEPTION 'ID do produto é obrigatório';
    END IF;
    
    IF p_plan_name_id IS NULL THEN
        RAISE EXCEPTION 'ID do nome do plano é obrigatório';
    END IF;
    
    IF p_valid_from IS NULL OR p_valid_to IS NULL THEN
        RAISE EXCEPTION 'Período de vigência é obrigatório';
    END IF;
    
    IF p_valid_from >= p_valid_to THEN
        RAISE EXCEPTION 'Data de início deve ser anterior à data de fim';
    END IF;
    
    IF p_price IS NULL OR p_price <= 0 THEN
        RAISE EXCEPTION 'Preço deve ser maior que zero';
    END IF;
    
    -- Verifica se o produto existe
    IF NOT EXISTS (SELECT 1 FROM subscriptions.products WHERE product_id = p_product_id) THEN
        RAISE EXCEPTION 'Produto com ID % não existe', p_product_id;
    END IF;
    
    -- Verifica se o nome do plano existe
    IF NOT EXISTS (SELECT 1 FROM subscriptions.plan_names WHERE plan_name_id = p_plan_name_id) THEN
        RAISE EXCEPTION 'Nome do plano com ID % não existe', p_plan_name_id;
    END IF;
    
    -- Obtém o modelo de cobrança do produto
    SELECT billing_model INTO v_billing_model FROM subscriptions.products WHERE product_id = p_product_id;
    
    -- Valida usage_limits para produtos com modelo usage_limits
    IF v_billing_model = 'usage_limits' AND p_usage_limits IS NULL THEN
        RAISE EXCEPTION 'Limites de uso são obrigatórios para produtos com modelo usage_limits';
    END IF;
    
    -- Cria o plano
    INSERT INTO subscriptions.plans (
        product_id, 
        plan_name_id, 
        valid_from, 
        valid_to, 
        price, 
        usage_limits
    ) VALUES (
        p_product_id, 
        p_plan_name_id, 
        p_valid_from, 
        p_valid_to, 
        p_price, 
        p_usage_limits
    ) RETURNING plan_id INTO v_plan_id;
    
    RAISE NOTICE 'Plano criado com ID: %', v_plan_id;
    
    RETURN v_plan_id;
END;
$$;

COMMENT ON FUNCTION subscriptions.create_plan IS 'Cria um novo plano para um produto';

-- =====================================================
-- FUNÇÕES DE GESTÃO DE ASSINATURAS
-- =====================================================

-- =====================================================
-- create_subscription
-- =====================================================
-- Cria uma nova assinatura para um cliente
-- Parâmetros: establishment_id ou supplier_id, plan_id, employee_id, período
-- Retorna: subscription_id da assinatura criada

CREATE OR REPLACE FUNCTION subscriptions.create_subscription(
    p_establishment_id uuid DEFAULT NULL,
    p_supplier_id uuid DEFAULT NULL,
    p_plan_id uuid,
    p_employee_id uuid,
    p_start_date timestamp without time zone DEFAULT now(),
    p_end_date timestamp without time zone DEFAULT (now() + interval '1 year')
)
RETURNS uuid
LANGUAGE plpgsql
AS $$
DECLARE
    v_subscription_id uuid;
    v_plan_valid_from timestamp without time zone;
    v_plan_valid_to timestamp without time zone;
BEGIN
    -- Validações
    IF p_establishment_id IS NULL AND p_supplier_id IS NULL THEN
        RAISE EXCEPTION 'Deve especificar establishment_id ou supplier_id';
    END IF;
    
    IF p_establishment_id IS NOT NULL AND p_supplier_id IS NOT NULL THEN
        RAISE EXCEPTION 'Não pode especificar establishment_id e supplier_id simultaneamente';
    END IF;
    
    IF p_plan_id IS NULL THEN
        RAISE EXCEPTION 'ID do plano é obrigatório';
    END IF;
    
    IF p_employee_id IS NULL THEN
        RAISE EXCEPTION 'ID do employee é obrigatório';
    END IF;
    
    -- Verifica se o plano existe e está ativo
    IF NOT EXISTS (SELECT 1 FROM subscriptions.plans WHERE plan_id = p_plan_id AND is_active = true) THEN
        RAISE EXCEPTION 'Plano com ID % não existe ou não está ativo', p_plan_id;
    END IF;
    
    -- Verifica se o employee existe
    IF NOT EXISTS (SELECT 1 FROM accounts.employees WHERE employee_id = p_employee_id) THEN
        RAISE EXCEPTION 'Employee com ID % não existe', p_employee_id;
    END IF;
    
    -- Verifica se já existe assinatura ativa para o cliente
    IF p_establishment_id IS NOT NULL THEN
        IF EXISTS (SELECT 1 FROM subscriptions.subscriptions WHERE establishment_id = p_establishment_id AND status = 'active') THEN
            RAISE EXCEPTION 'Já existe assinatura ativa para o establishment %', p_establishment_id;
        END IF;
        
        -- Verifica se o establishment existe
        IF NOT EXISTS (SELECT 1 FROM accounts.establishments WHERE establishment_id = p_establishment_id) THEN
            RAISE EXCEPTION 'Establishment com ID % não existe', p_establishment_id;
        END IF;
    END IF;
    
    IF p_supplier_id IS NOT NULL THEN
        IF EXISTS (SELECT 1 FROM subscriptions.subscriptions WHERE supplier_id = p_supplier_id AND status = 'active') THEN
            RAISE EXCEPTION 'Já existe assinatura ativa para o supplier %', p_supplier_id;
        END IF;
        
        -- Verifica se o supplier existe
        IF NOT EXISTS (SELECT 1 FROM accounts.suppliers WHERE supplier_id = p_supplier_id) THEN
            RAISE EXCEPTION 'Supplier com ID % não existe', p_supplier_id;
        END IF;
    END IF;
    
    -- Obtém período de vigência do plano
    SELECT valid_from, valid_to INTO v_plan_valid_from, v_plan_valid_to 
    FROM subscriptions.plans WHERE plan_id = p_plan_id;
    
    -- Ajusta período da assinatura se necessário
    IF p_start_date < v_plan_valid_from THEN
        p_start_date := v_plan_valid_from;
    END IF;
    
    IF p_end_date > v_plan_valid_to THEN
        p_end_date := v_plan_valid_to;
    END IF;
    
    -- Cria a assinatura
    INSERT INTO subscriptions.subscriptions (
        establishment_id, 
        supplier_id, 
        plan_id, 
        employee_id, 
        start_date, 
        end_date, 
        status
    ) VALUES (
        p_establishment_id, 
        p_supplier_id, 
        p_plan_id, 
        p_employee_id, 
        p_start_date, 
        p_end_date, 
        'active'
    ) RETURNING subscription_id INTO v_subscription_id;
    
    RAISE NOTICE 'Assinatura criada com ID: %', v_subscription_id;
    
    RETURN v_subscription_id;
END;
$$;

COMMENT ON FUNCTION subscriptions.create_subscription IS 'Cria uma nova assinatura para um cliente';

-- =====================================================
-- upgrade_subscription
-- =====================================================
-- Faz upgrade de uma assinatura para um plano superior
-- Parâmetros: subscription_id, new_plan_id, change_reason
-- Retorna: change_id da mudança registrada

CREATE OR REPLACE FUNCTION subscriptions.upgrade_subscription(
    p_subscription_id uuid,
    p_new_plan_id uuid,
    p_change_reason text DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
AS $$
DECLARE
    v_change_id uuid;
    v_old_plan_id uuid;
    v_subscription_exists boolean;
BEGIN
    -- Validações
    IF p_subscription_id IS NULL THEN
        RAISE EXCEPTION 'ID da assinatura é obrigatório';
    END IF;
    
    IF p_new_plan_id IS NULL THEN
        RAISE EXCEPTION 'ID do novo plano é obrigatório';
    END IF;
    
    -- Verifica se a assinatura existe e está ativa
    SELECT 
        plan_id,
        true
    INTO 
        v_old_plan_id,
        v_subscription_exists
    FROM subscriptions.subscriptions 
    WHERE subscription_id = p_subscription_id AND status = 'active';
    
    IF NOT v_subscription_exists THEN
        RAISE EXCEPTION 'Assinatura com ID % não existe ou não está ativa', p_subscription_id;
    END IF;
    
    -- Verifica se o novo plano existe e está ativo
    IF NOT EXISTS (SELECT 1 FROM subscriptions.plans WHERE plan_id = p_new_plan_id AND is_active = true) THEN
        RAISE EXCEPTION 'Novo plano com ID % não existe ou não está ativo', p_new_plan_id;
    END IF;
    
    -- Verifica se não é o mesmo plano
    IF v_old_plan_id = p_new_plan_id THEN
        RAISE EXCEPTION 'Novo plano deve ser diferente do plano atual';
    END IF;
    
    -- Registra a mudança
    INSERT INTO subscriptions.plan_changes (
        subscription_id, 
        change_type, 
        old_plan_id, 
        new_plan_id, 
        change_reason
    ) VALUES (
        p_subscription_id, 
        'upgrade', 
        v_old_plan_id, 
        p_new_plan_id, 
        p_change_reason
    ) RETURNING change_id INTO v_change_id;
    
    -- Atualiza a assinatura
    UPDATE subscriptions.subscriptions 
    SET plan_id = p_new_plan_id, updated_at = now()
    WHERE subscription_id = p_subscription_id;
    
    RAISE NOTICE 'Upgrade realizado com sucesso. Change ID: %', v_change_id;
    
    RETURN v_change_id;
END;
$$;

COMMENT ON FUNCTION subscriptions.upgrade_subscription IS 'Faz upgrade de uma assinatura para um plano superior';

-- =====================================================
-- FUNÇÕES DE CONTROLE DE USO
-- =====================================================

-- =====================================================
-- track_usage
-- =====================================================
-- Atualiza o tracking de uso de uma assinatura
-- Parâmetros: subscription_id, quotations_used
-- Retorna: usage_id do registro atualizado

CREATE OR REPLACE FUNCTION subscriptions.track_usage(
    p_subscription_id uuid,
    p_quotations_used integer
)
RETURNS uuid
LANGUAGE plpgsql
AS $$
DECLARE
    v_usage_id uuid;
    v_current_period_start timestamp without time zone;
    v_current_period_end timestamp without time zone;
    v_usage_exists boolean;
BEGIN
    -- Validações
    IF p_subscription_id IS NULL THEN
        RAISE EXCEPTION 'ID da assinatura é obrigatório';
    END IF;
    
    IF p_quotations_used IS NULL OR p_quotations_used < 0 THEN
        RAISE EXCEPTION 'Quantidade de cotações deve ser não negativa';
    END IF;
    
    -- Verifica se a assinatura existe e está ativa
    IF NOT EXISTS (SELECT 1 FROM subscriptions.subscriptions WHERE subscription_id = p_subscription_id AND status = 'active') THEN
        RAISE EXCEPTION 'Assinatura com ID % não existe ou não está ativa', p_subscription_id;
    END IF;
    
    -- Calcula período atual (30 dias a partir da data de início da assinatura)
    SELECT 
        start_date + (EXTRACT(EPOCH FROM (now() - start_date)) / (30 * 24 * 3600))::integer * interval '30 days',
        start_date + (EXTRACT(EPOCH FROM (now() - start_date)) / (30 * 24 * 3600))::integer * interval '30 days' + interval '30 days'
    INTO v_current_period_start, v_current_period_end
    FROM subscriptions.subscriptions 
    WHERE subscription_id = p_subscription_id;
    
    -- Verifica se já existe registro para o período atual
    SELECT usage_id INTO v_usage_id
    FROM subscriptions.usage_tracking 
    WHERE subscription_id = p_subscription_id 
    AND period_start = v_current_period_start;
    
    IF v_usage_id IS NOT NULL THEN
        -- Atualiza registro existente
        UPDATE subscriptions.usage_tracking 
        SET quotations_used = p_quotations_used, updated_at = now()
        WHERE usage_id = v_usage_id;
        
        v_usage_exists := true;
    ELSE
        -- Cria novo registro
        INSERT INTO subscriptions.usage_tracking (
            subscription_id, 
            period_start, 
            period_end, 
            quotations_used, 
            quotations_subscription, 
            quotations_bought
        ) VALUES (
            p_subscription_id, 
            v_current_period_start, 
            v_current_period_end, 
            p_quotations_used, 
            0, -- Será calculado pelo trigger
            0  -- Será calculado pelo trigger
        ) RETURNING usage_id INTO v_usage_id;
        
        v_usage_exists := false;
    END IF;
    
    IF v_usage_exists THEN
        RAISE NOTICE 'Uso atualizado para assinatura %. Usage ID: %', p_subscription_id, v_usage_id;
    ELSE
        RAISE NOTICE 'Novo registro de uso criado para assinatura %. Usage ID: %', p_subscription_id, v_usage_id;
    END IF;
    
    RETURN v_usage_id;
END;
$$;

COMMENT ON FUNCTION subscriptions.track_usage IS 'Atualiza o tracking de uso de uma assinatura';

-- =====================================================
-- purchase_quotas
-- =====================================================
-- Registra compra de cotas extras
-- Parâmetros: establishment_id ou supplier_id, quotations_bought, unit_price
-- Retorna: purchase_id da compra registrada

CREATE OR REPLACE FUNCTION subscriptions.purchase_quotas(
    p_establishment_id uuid DEFAULT NULL,
    p_supplier_id uuid DEFAULT NULL,
    p_quotations_bought integer,
    p_unit_price numeric(10,2)
)
RETURNS uuid
LANGUAGE plpgsql
AS $$
DECLARE
    v_purchase_id uuid;
    v_total_price numeric(10,2);
BEGIN
    -- Validações
    IF p_establishment_id IS NULL AND p_supplier_id IS NULL THEN
        RAISE EXCEPTION 'Deve especificar establishment_id ou supplier_id';
    END IF;
    
    IF p_establishment_id IS NOT NULL AND p_supplier_id IS NOT NULL THEN
        RAISE EXCEPTION 'Não pode especificar establishment_id e supplier_id simultaneamente';
    END IF;
    
    IF p_quotations_bought IS NULL OR p_quotations_bought <= 0 THEN
        RAISE EXCEPTION 'Quantidade de cotações deve ser maior que zero';
    END IF;
    
    IF p_unit_price IS NULL OR p_unit_price <= 0 THEN
        RAISE EXCEPTION 'Preço unitário deve ser maior que zero';
    END IF;
    
    -- Verifica se o cliente existe
    IF p_establishment_id IS NOT NULL THEN
        IF NOT EXISTS (SELECT 1 FROM accounts.establishments WHERE establishment_id = p_establishment_id) THEN
            RAISE EXCEPTION 'Establishment com ID % não existe', p_establishment_id;
        END IF;
    END IF;
    
    IF p_supplier_id IS NOT NULL THEN
        IF NOT EXISTS (SELECT 1 FROM accounts.suppliers WHERE supplier_id = p_supplier_id) THEN
            RAISE EXCEPTION 'Supplier com ID % não existe', p_supplier_id;
        END IF;
    END IF;
    
    -- Calcula preço total
    v_total_price := p_quotations_bought * p_unit_price;
    
    -- Registra a compra
    INSERT INTO subscriptions.quota_purchases (
        establishment_id, 
        supplier_id, 
        quotations_bought, 
        unit_price, 
        total_price
    ) VALUES (
        p_establishment_id, 
        p_supplier_id, 
        p_quotations_bought, 
        p_unit_price, 
        v_total_price
    ) RETURNING purchase_id INTO v_purchase_id;
    
    RAISE NOTICE 'Compra de cotas registrada com ID: %. Total: R$ %', v_purchase_id, v_total_price;
    
    RETURN v_purchase_id;
END;
$$;

COMMENT ON FUNCTION subscriptions.purchase_quotas IS 'Registra compra de cotas extras';

-- =====================================================
-- FUNÇÕES DE CONSULTA
-- =====================================================

-- =====================================================
-- get_active_subscription
-- =====================================================
-- Obtém a assinatura ativa de um cliente
-- Parâmetros: establishment_id ou supplier_id
-- Retorna: Dados da assinatura ativa

CREATE OR REPLACE FUNCTION subscriptions.get_active_subscription(
    p_establishment_id uuid DEFAULT NULL,
    p_supplier_id uuid DEFAULT NULL
)
RETURNS TABLE(
    subscription_id uuid,
    plan_name text,
    product_name text,
    start_date timestamp without time zone,
    end_date timestamp without time zone,
    status text,
    price numeric(10,2),
    usage_limits jsonb
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Validações
    IF p_establishment_id IS NULL AND p_supplier_id IS NULL THEN
        RAISE EXCEPTION 'Deve especificar establishment_id ou supplier_id';
    END IF;
    
    IF p_establishment_id IS NOT NULL AND p_supplier_id IS NOT NULL THEN
        RAISE EXCEPTION 'Não pode especificar establishment_id e supplier_id simultaneamente';
    END IF;
    
    -- Retorna dados da assinatura ativa
    RETURN QUERY
    SELECT 
        s.subscription_id,
        pn.name as plan_name,
        p.name as product_name,
        s.start_date,
        s.end_date,
        s.status,
        pl.price,
        pl.usage_limits
    FROM subscriptions.subscriptions s
    JOIN subscriptions.plans pl ON s.plan_id = pl.plan_id
    JOIN subscriptions.plan_names pn ON pl.plan_name_id = pn.plan_name_id
    JOIN subscriptions.products p ON pl.product_id = p.product_id
    WHERE s.status = 'active'
    AND (
        (p_establishment_id IS NOT NULL AND s.establishment_id = p_establishment_id) OR
        (p_supplier_id IS NOT NULL AND s.supplier_id = p_supplier_id)
    );
END;
$$;

COMMENT ON FUNCTION subscriptions.get_active_subscription IS 'Obtém a assinatura ativa de um cliente';

-- =====================================================
-- get_usage_summary
-- =====================================================
-- Obtém resumo de uso de uma assinatura
-- Parâmetros: subscription_id
-- Retorna: Resumo de uso com limites e utilização

CREATE OR REPLACE FUNCTION subscriptions.get_usage_summary(
    p_subscription_id uuid
)
RETURNS TABLE(
    period_start timestamp without time zone,
    period_end timestamp without time zone,
    quotations_used integer,
    quotations_limit integer,
    quotations_remaining integer,
    is_over_limit boolean
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Validações
    IF p_subscription_id IS NULL THEN
        RAISE EXCEPTION 'ID da assinatura é obrigatório';
    END IF;
    
    -- Verifica se a assinatura existe
    IF NOT EXISTS (SELECT 1 FROM subscriptions.subscriptions WHERE subscription_id = p_subscription_id) THEN
        RAISE EXCEPTION 'Assinatura com ID % não existe', p_subscription_id;
    END IF;
    
    -- Retorna resumo de uso
    RETURN QUERY
    SELECT 
        ut.period_start,
        ut.period_end,
        ut.quotations_used,
        ut.quotations_limit,
        GREATEST(0, ut.quotations_limit - ut.quotations_used) as quotations_remaining,
        ut.is_over_limit
    FROM subscriptions.usage_tracking ut
    WHERE ut.subscription_id = p_subscription_id
    ORDER BY ut.period_start DESC
    LIMIT 1;
END;
$$;

COMMENT ON FUNCTION subscriptions.get_usage_summary IS 'Obtém resumo de uso de uma assinatura';
