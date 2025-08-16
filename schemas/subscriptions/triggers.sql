-- =====================================================
-- TRIGGERS DO SCHEMA: subscriptions
-- =====================================================
-- Este arquivo contém todos os triggers relacionados ao schema subscriptions
-- Inclui triggers para validação, cálculo automático e integração com outros schemas

-- =====================================================
-- TRIGGER: Validação JSONB para plans.usage_limits
-- =====================================================
-- Descrição: Valida se o campo usage_limits contém as chaves corretas
-- Funcionalidade: Integração com aux.json_validation_params
-- Uso: Automático em INSERT/UPDATE

-- Este trigger será criado automaticamente via aux.create_json_validation_trigger()
-- quando a tabela plans for criada

-- =====================================================
-- TRIGGER: Cálculo automático de campos em usage_tracking
-- =====================================================
-- Descrição: Calcula quotations_limit e is_over_limit automaticamente
-- Funcionalidade: Trigger BEFORE INSERT/UPDATE
-- Uso: Automático em todas as operações

-- Função já criada em usage_tracking.sql
-- Trigger já criado em usage_tracking.sql

-- =====================================================
-- TRIGGER: Integração com quotation.quotation_submissions
-- =====================================================
-- Descrição: Atualiza usage_tracking quando uma cotação é submetida
-- Funcionalidade: Trigger AFTER INSERT em quotation.quotation_submissions
-- Uso: Tracking automático de uso

CREATE OR REPLACE FUNCTION subscriptions.track_quotation_usage()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_subscription_id uuid;
    v_establishment_id uuid;
    v_supplier_id uuid;
    v_quotations_used integer;
    v_usage_id uuid;
BEGIN
    -- Obtém establishment_id da shopping_list
    SELECT establishment_id INTO v_establishment_id
    FROM quotation.shopping_lists
    WHERE shopping_list_id = NEW.shopping_list_id;
    
    -- Se não encontrou establishment, tenta supplier
    IF v_establishment_id IS NULL THEN
        SELECT supplier_id INTO v_supplier_id
        FROM quotation.shopping_lists
        WHERE shopping_list_id = NEW.shopping_list_id;
    END IF;
    
    -- Se encontrou cliente, busca assinatura ativa
    IF v_establishment_id IS NOT NULL OR v_supplier_id IS NOT NULL THEN
        SELECT subscription_id INTO v_subscription_id
        FROM subscriptions.subscriptions
        WHERE status = 'active'
        AND (
            (v_establishment_id IS NOT NULL AND establishment_id = v_establishment_id) OR
            (v_supplier_id IS NOT NULL AND supplier_id = v_supplier_id)
        );
        
        -- Se encontrou assinatura ativa, atualiza tracking
        IF v_subscription_id IS NOT NULL THEN
            -- Obtém uso atual do período
            SELECT 
                usage_id,
                quotations_used
            INTO 
                v_usage_id,
                v_quotations_used
            FROM subscriptions.usage_tracking
            WHERE subscription_id = v_subscription_id
            AND period_start <= now()
            AND period_end > now();
            
            -- Se encontrou registro de uso, incrementa
            IF v_usage_id IS NOT NULL THEN
                UPDATE subscriptions.usage_tracking
                SET 
                    quotations_used = v_quotations_used + 1,
                    updated_at = now()
                WHERE usage_id = v_usage_id;
                
                RAISE NOTICE 'Uso atualizado para assinatura %. Cotações: %', v_subscription_id, v_quotations_used + 1;
            ELSE
                -- Cria novo registro de uso se não existir
                PERFORM subscriptions.track_usage(v_subscription_id, 1);
                RAISE NOTICE 'Novo registro de uso criado para assinatura %', v_subscription_id;
            END IF;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION subscriptions.track_quotation_usage IS 'Atualiza usage_tracking quando uma cotação é submetida';

-- Cria o trigger na tabela quotation.quotation_submissions
-- (Será executado quando a tabela quotation.quotation_submissions existir)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'quotation' 
        AND table_name = 'quotation_submissions'
    ) THEN
        -- Remove trigger existente se houver
        DROP TRIGGER IF EXISTS trg_track_quotation_usage ON quotation.quotation_submissions;
        
        -- Cria o trigger
        CREATE TRIGGER trg_track_quotation_usage
        AFTER INSERT ON quotation.quotation_submissions
        FOR EACH ROW
        EXECUTE FUNCTION subscriptions.track_quotation_usage();
        
        RAISE NOTICE 'Trigger de tracking de cotações criado em quotation.quotation_submissions';
    ELSE
        RAISE NOTICE 'Tabela quotation.quotation_submissions não existe. Trigger será criado quando a tabela for criada.';
    END IF;
END $$;

-- =====================================================
-- TRIGGER: Validação de planos ativos
-- =====================================================
-- Descrição: Garante que apenas planos ativos sejam usados em assinaturas
-- Funcionalidade: Trigger BEFORE INSERT/UPDATE em subscriptions
-- Uso: Validação de integridade

CREATE OR REPLACE FUNCTION subscriptions.validate_active_plan()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Verifica se o plano está ativo
    IF NOT EXISTS (
        SELECT 1 FROM subscriptions.plans 
        WHERE plan_id = NEW.plan_id 
        AND is_active = true
    ) THEN
        RAISE EXCEPTION 'Plano com ID % não está ativo', NEW.plan_id;
    END IF;
    
    -- Verifica se o plano está dentro do período de vigência
    IF NOT EXISTS (
        SELECT 1 FROM subscriptions.plans 
        WHERE plan_id = NEW.plan_id 
        AND valid_from <= NEW.start_date 
        AND valid_to >= NEW.end_date
    ) THEN
        RAISE EXCEPTION 'Período da assinatura está fora da vigência do plano';
    END IF;
    
    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION subscriptions.validate_active_plan IS 'Valida se o plano usado na assinatura está ativo e vigente';

-- Cria o trigger
CREATE TRIGGER trg_validate_active_plan
    BEFORE INSERT OR UPDATE ON subscriptions.subscriptions
    FOR EACH ROW
    EXECUTE FUNCTION subscriptions.validate_active_plan();

-- =====================================================
-- TRIGGER: Validação de produtos disponíveis
-- =====================================================
-- Descrição: Garante que apenas produtos disponíveis para o tipo de cliente sejam usados
-- Funcionalidade: Trigger BEFORE INSERT/UPDATE em subscriptions
-- Uso: Validação de negócio

CREATE OR REPLACE FUNCTION subscriptions.validate_product_availability()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_product_id uuid;
    v_is_available_for_establishment boolean;
    v_is_available_for_supplier boolean;
BEGIN
    -- Obtém o produto do plano
    SELECT product_id INTO v_product_id
    FROM subscriptions.plans
    WHERE plan_id = NEW.plan_id;
    
    -- Obtém disponibilidade do produto
    SELECT 
        is_available_for_establishment,
        is_available_for_supplier
    INTO 
        v_is_available_for_establishment,
        v_is_available_for_supplier
    FROM subscriptions.products
    WHERE product_id = v_product_id;
    
    -- Valida disponibilidade para establishment
    IF NEW.establishment_id IS NOT NULL AND NOT v_is_available_for_establishment THEN
        RAISE EXCEPTION 'Produto não está disponível para establishments';
    END IF;
    
    -- Valida disponibilidade para supplier
    IF NEW.supplier_id IS NOT NULL AND NOT v_is_available_for_supplier THEN
        RAISE EXCEPTION 'Produto não está disponível para suppliers';
    END IF;
    
    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION subscriptions.validate_product_availability IS 'Valida se o produto está disponível para o tipo de cliente';

-- Cria o trigger
CREATE TRIGGER trg_validate_product_availability
    BEFORE INSERT OR UPDATE ON subscriptions.subscriptions
    FOR EACH ROW
    EXECUTE FUNCTION subscriptions.validate_product_availability();

-- =====================================================
-- TRIGGER: Atualização automática de usage_tracking
-- =====================================================
-- Descrição: Atualiza quotations_subscription quando uma assinatura é criada/atualizada
-- Funcionalidade: Trigger AFTER INSERT/UPDATE em subscriptions
-- Uso: Sincronização automática de dados

CREATE OR REPLACE FUNCTION subscriptions.update_usage_tracking()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_quotations_limit integer;
    v_usage_id uuid;
BEGIN
    -- Se é uma nova assinatura ou mudança de plano
    IF TG_OP = 'INSERT' OR (TG_OP = 'UPDATE' AND OLD.plan_id != NEW.plan_id) THEN
        -- Obtém limite de cotações do plano
        SELECT COALESCE((usage_limits->>'quotations')::integer, 0) INTO v_quotations_limit
        FROM subscriptions.plans
        WHERE plan_id = NEW.plan_id;
        
        -- Atualiza registros de usage_tracking existentes
        UPDATE subscriptions.usage_tracking
        SET 
            quotations_subscription = v_quotations_limit,
            updated_at = now()
        WHERE subscription_id = NEW.subscription_id;
        
        RAISE NOTICE 'Limite de cotações atualizado para assinatura %. Valor: %', NEW.subscription_id, v_quotations_limit;
    END IF;
    
    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION subscriptions.update_usage_tracking IS 'Atualiza quotations_subscription quando uma assinatura é criada/atualizada';

-- Cria o trigger
CREATE TRIGGER trg_update_usage_tracking
    AFTER INSERT OR UPDATE ON subscriptions.subscriptions
    FOR EACH ROW
    EXECUTE FUNCTION subscriptions.update_usage_tracking();

-- =====================================================
-- TRIGGER: Validação de período de assinatura
-- =====================================================
-- Descrição: Garante que o período da assinatura esteja dentro da vigência do plano
-- Funcionalidade: Trigger BEFORE INSERT/UPDATE em subscriptions
-- Uso: Validação de integridade

CREATE OR REPLACE FUNCTION subscriptions.validate_subscription_period()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_plan_valid_from timestamp without time zone;
    v_plan_valid_to timestamp without time zone;
BEGIN
    -- Obtém período de vigência do plano
    SELECT valid_from, valid_to INTO v_plan_valid_from, v_plan_valid_to
    FROM subscriptions.plans
    WHERE plan_id = NEW.plan_id;
    
    -- Valida início da assinatura
    IF NEW.start_date < v_plan_valid_from THEN
        RAISE EXCEPTION 'Data de início da assinatura não pode ser anterior à vigência do plano';
    END IF;
    
    -- Valida fim da assinatura
    IF NEW.end_date > v_plan_valid_to THEN
        RAISE EXCEPTION 'Data de fim da assinatura não pode ser posterior à vigência do plano';
    END IF;
    
    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION subscriptions.validate_subscription_period IS 'Valida se o período da assinatura está dentro da vigência do plano';

-- Cria o trigger
CREATE TRIGGER trg_validate_subscription_period
    BEFORE INSERT OR UPDATE ON subscriptions.subscriptions
    FOR EACH ROW
    EXECUTE FUNCTION subscriptions.validate_subscription_period();

-- =====================================================
-- TRIGGER: Histórico de mudanças de status
-- =====================================================
-- Descrição: Registra mudanças de status em plan_changes
-- Funcionalidade: Trigger AFTER UPDATE em subscriptions
-- Uso: Auditoria de mudanças de status

CREATE OR REPLACE FUNCTION subscriptions.track_status_changes()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Se o status mudou
    IF OLD.status != NEW.status THEN
        INSERT INTO subscriptions.plan_changes (
            subscription_id,
            change_type,
            old_plan_id,
            new_plan_id,
            change_reason
        ) VALUES (
            NEW.subscription_id,
            'status_change',
            OLD.plan_id,
            NEW.plan_id,
            'Mudança de status de ' || OLD.status || ' para ' || NEW.status
        );
        
        RAISE NOTICE 'Mudança de status registrada para assinatura %: % -> %', NEW.subscription_id, OLD.status, NEW.status;
    END IF;
    
    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION subscriptions.track_status_changes IS 'Registra mudanças de status em plan_changes';

-- Cria o trigger
CREATE TRIGGER trg_track_status_changes
    AFTER UPDATE ON subscriptions.subscriptions
    FOR EACH ROW
    EXECUTE FUNCTION subscriptions.track_status_changes();

-- =====================================================
-- TRIGGER: Validação de preços em quota_purchases
-- =====================================================
-- Descrição: Garante que o preço total seja calculado corretamente
-- Funcionalidade: Trigger BEFORE INSERT/UPDATE em quota_purchases
-- Uso: Validação de integridade

CREATE OR REPLACE FUNCTION subscriptions.validate_quota_purchase_prices()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Valida se o preço total está correto
    IF NEW.total_price != (NEW.unit_price * NEW.quotations_bought) THEN
        RAISE EXCEPTION 'Preço total deve ser igual a unit_price * quotations_bought';
    END IF;
    
    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION subscriptions.validate_quota_purchase_prices IS 'Valida se o preço total em quota_purchases está correto';

-- Cria o trigger
CREATE TRIGGER trg_validate_quota_purchase_prices
    BEFORE INSERT OR UPDATE ON subscriptions.quota_purchases
    FOR EACH ROW
    EXECUTE FUNCTION subscriptions.validate_quota_purchase_prices();

-- =====================================================
-- TRIGGER: Atualização automática de usage_tracking para cotas compradas
-- =====================================================
-- Descrição: Atualiza quotations_bought quando cotas são compradas
-- Funcionalidade: Trigger AFTER INSERT em quota_purchases
-- Uso: Sincronização automática de dados

CREATE OR REPLACE FUNCTION subscriptions.update_quota_purchases_usage()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_subscription_id uuid;
    v_usage_id uuid;
    v_current_quotations_bought integer;
BEGIN
    -- Busca assinatura ativa do cliente
    SELECT subscription_id INTO v_subscription_id
    FROM subscriptions.subscriptions
    WHERE status = 'active'
    AND (
        (NEW.establishment_id IS NOT NULL AND establishment_id = NEW.establishment_id) OR
        (NEW.supplier_id IS NOT NULL AND supplier_id = NEW.supplier_id)
    );
    
    -- Se encontrou assinatura ativa, atualiza usage_tracking
    IF v_subscription_id IS NOT NULL THEN
        -- Busca registro de uso atual
        SELECT usage_id, quotations_bought INTO v_usage_id, v_current_quotations_bought
        FROM subscriptions.usage_tracking
        WHERE subscription_id = v_subscription_id
        AND period_start <= now()
        AND period_end > now();
        
        -- Se encontrou registro, atualiza
        IF v_usage_id IS NOT NULL THEN
            UPDATE subscriptions.usage_tracking
            SET 
                quotations_bought = v_current_quotations_bought + NEW.quotations_bought,
                updated_at = now()
            WHERE usage_id = v_usage_id;
            
            RAISE NOTICE 'Cotas compradas atualizadas para assinatura %. Total: %', v_subscription_id, v_current_quotations_bought + NEW.quotations_bought;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION subscriptions.update_quota_purchases_usage IS 'Atualiza quotations_bought quando cotas são compradas';

-- Cria o trigger
CREATE TRIGGER trg_update_quota_purchases_usage
    AFTER INSERT ON subscriptions.quota_purchases
    FOR EACH ROW
    EXECUTE FUNCTION subscriptions.update_quota_purchases_usage();
