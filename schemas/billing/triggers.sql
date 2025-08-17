-- =====================================================
-- TRIGGERS DO SCHEMA: billing
-- =====================================================
-- Este arquivo contém todos os triggers relacionados ao schema billing
-- Inclui triggers para validação, auditoria e lógica de negócio

-- =====================================================
-- TRIGGERS DE VALIDAÇÃO E INTEGRIDADE
-- =====================================================

-- =====================================================
-- validate_transaction_business_reference
-- =====================================================
-- Valida se a referência de negócio está no formato correto
-- Trigger: BEFORE INSERT OR UPDATE ON billing.transactions

CREATE OR REPLACE FUNCTION billing.validate_transaction_business_reference()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Verificar se business_reference tem os campos obrigatórios
    IF NEW.business_reference IS NULL THEN
        RAISE EXCEPTION 'business_reference não pode ser NULL';
    END IF;
    
    IF NEW.business_reference->>'schema' IS NULL THEN
        RAISE EXCEPTION 'business_reference deve conter campo "schema"';
    END IF;
    
    IF NEW.business_reference->>'table' IS NULL THEN
        RAISE EXCEPTION 'business_reference deve conter campo "table"';
    END IF;
    
    IF NEW.business_reference->>'id' IS NULL THEN
        RAISE EXCEPTION 'business_reference deve conter campo "id"';
    END IF;
    
    -- Verificar se o schema existe
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.schemata 
        WHERE schema_name = NEW.business_reference->>'schema'
    ) THEN
        RAISE EXCEPTION 'Schema "%" não existe', NEW.business_reference->>'schema';
    END IF;
    
    -- Verificar se a tabela existe
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = NEW.business_reference->>'schema'
          AND table_name = NEW.business_reference->>'table'
    ) THEN
        RAISE EXCEPTION 'Tabela "%"."%" não existe', 
            NEW.business_reference->>'schema', 
            NEW.business_reference->>'table';
    END IF;
    
    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION billing.validate_transaction_business_reference IS 'Valida se a referência de negócio está no formato correto';

-- Criar o trigger
CREATE TRIGGER tr_validate_transaction_business_reference
    BEFORE INSERT OR UPDATE ON billing.transactions
    FOR EACH ROW
    EXECUTE FUNCTION billing.validate_transaction_business_reference();

-- =====================================================
-- validate_installment_amounts
-- =====================================================
-- Valida se a soma das parcelas é igual ao valor da transação
-- Trigger: AFTER INSERT OR UPDATE OR DELETE ON billing.installments

CREATE OR REPLACE FUNCTION billing.validate_installment_amounts()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_transaction_amount numeric(10,2);
    v_total_installments numeric(10,2);
    v_expected_payment_id uuid;
BEGIN
    -- Determinar o expected_payment_id
    IF TG_OP = 'DELETE' THEN
        v_expected_payment_id := OLD.expected_payment_id;
    ELSE
        v_expected_payment_id := NEW.expected_payment_id;
    END IF;
    
    -- Buscar valor da transação
    SELECT t.amount INTO v_transaction_amount
    FROM billing.transactions t
    JOIN billing.expected_payments ep ON t.transaction_id = ep.transaction_id
    WHERE ep.expected_payment_id = v_expected_payment_id;
    
    -- Calcular soma das parcelas
    SELECT COALESCE(SUM(amount), 0) INTO v_total_installments
    FROM billing.installments
    WHERE expected_payment_id = v_expected_payment_id;
    
    -- Validar se a soma é igual ao valor da transação
    IF v_total_installments != v_transaction_amount THEN
        RAISE EXCEPTION 'Soma das parcelas (%) deve ser igual ao valor da transação (%)', 
            v_total_installments, v_transaction_amount;
    END IF;
    
    RETURN COALESCE(NEW, OLD);
END;
$$;

COMMENT ON FUNCTION billing.validate_installment_amounts IS 'Valida se a soma das parcelas é igual ao valor da transação';

-- Criar o trigger
CREATE TRIGGER tr_validate_installment_amounts
    AFTER INSERT OR UPDATE OR DELETE ON billing.installments
    FOR EACH ROW
    EXECUTE FUNCTION billing.validate_installment_amounts();

-- =====================================================
-- TRIGGERS DE LÓGICA DE NEGÓCIO
-- =====================================================

-- =====================================================
-- update_transaction_status_on_payment
-- =====================================================
-- Atualiza o status da transação quando um pagamento é bem-sucedido
-- Trigger: AFTER UPDATE ON billing.payment_attempts

CREATE OR REPLACE FUNCTION billing.update_transaction_status_on_payment()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_transaction_id uuid;
    v_completed_status_id uuid;
    v_failed_status_id uuid;
BEGIN
    -- Buscar transaction_id
    SELECT ep.transaction_id INTO v_transaction_id
    FROM billing.expected_payments ep
    WHERE ep.expected_payment_id = NEW.expected_payment_id;
    
    -- Se o status mudou para success, atualizar transação para completed
    IF NEW.status = 'success' AND (OLD.status IS NULL OR OLD.status != 'success') THEN
        -- Buscar status 'completed'
        SELECT status_id INTO v_completed_status_id
        FROM billing.transaction_statuses
        WHERE name = 'completed';
        
        IF v_completed_status_id IS NOT NULL THEN
            UPDATE billing.transactions
            SET status_id = v_completed_status_id, updated_at = now()
            WHERE transaction_id = v_transaction_id;
            
            RAISE NOTICE 'Transação % marcada como completed', v_transaction_id;
        END IF;
    END IF;
    
    -- Se o status mudou para failed, atualizar transação para failed
    IF NEW.status = 'failed' AND (OLD.status IS NULL OR OLD.status != 'failed') THEN
        -- Buscar status 'failed'
        SELECT status_id INTO v_failed_status_id
        FROM billing.transaction_statuses
        WHERE name = 'failed';
        
        IF v_failed_status_id IS NOT NULL THEN
            UPDATE billing.transactions
            SET status_id = v_failed_status_id, updated_at = now()
            WHERE transaction_id = v_transaction_id;
            
            RAISE NOTICE 'Transação % marcada como failed', v_transaction_id;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION billing.update_transaction_status_on_payment IS 'Atualiza o status da transação quando um pagamento é bem-sucedido';

-- Criar o trigger
CREATE TRIGGER tr_update_transaction_status_on_payment
    AFTER UPDATE ON billing.payment_attempts
    FOR EACH ROW
    EXECUTE FUNCTION billing.update_transaction_status_on_payment();

-- =====================================================
-- update_installment_status_on_payment
-- =====================================================
-- Atualiza o status da parcela quando um pagamento é bem-sucedido
-- Trigger: AFTER UPDATE ON billing.payment_attempts

CREATE OR REPLACE FUNCTION billing.update_installment_status_on_payment()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_paid_status_id uuid;
    v_installment_id uuid;
BEGIN
    -- Se o status mudou para success, marcar parcelas como paid
    IF NEW.status = 'success' AND (OLD.status IS NULL OR OLD.status != 'success') THEN
        -- Buscar status 'paid'
        SELECT status_id INTO v_paid_status_id
        FROM billing.installment_statuses
        WHERE name = 'paid';
        
        IF v_paid_status_id IS NOT NULL THEN
            -- Atualizar parcelas relacionadas ao expected_payment
            UPDATE billing.installments
            SET 
                status_id = v_paid_status_id,
                payment_attempt_id = NEW.attempt_id,
                updated_at = now()
            WHERE expected_payment_id = NEW.expected_payment_id;
            
            -- Buscar installment_id para a timeline
            SELECT installment_id INTO v_installment_id
            FROM billing.installments
            WHERE expected_payment_id = NEW.expected_payment_id
            LIMIT 1;
            
            IF v_installment_id IS NOT NULL THEN
                -- Registrar evento na timeline
                INSERT INTO billing.transaction_timeline (
                    transaction_id,
                    event_type,
                    description,
                    metadata
                )
                SELECT 
                    ep.transaction_id,
                    'installment_paid',
                    'Parcela marcada como paga',
                    jsonb_build_object(
                        'installment_id', v_installment_id,
                        'payment_attempt_id', NEW.attempt_id,
                        'payment_method', NEW.payment_method,
                        'gateway', NEW.gateway_name
                    )
                FROM billing.expected_payments ep
                WHERE ep.expected_payment_id = NEW.expected_payment_id;
            END IF;
            
            RAISE NOTICE 'Parcelas do expected_payment % marcadas como paid', NEW.expected_payment_id;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION billing.update_installment_status_on_payment IS 'Atualiza o status da parcela quando um pagamento é bem-sucedido';

-- Criar o trigger
CREATE TRIGGER tr_update_installment_status_on_payment
    AFTER UPDATE ON billing.payment_attempts
    FOR EACH ROW
    EXECUTE FUNCTION billing.update_installment_status_on_payment();

-- =====================================================
-- update_installment_status_on_due_date
-- =====================================================
-- Atualiza o status da parcela para 'due' quando vence
-- Trigger: Evento baseado em função de agendamento

CREATE OR REPLACE FUNCTION billing.update_installment_status_on_due_date()
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    v_due_status_id uuid;
    v_transaction_id uuid;
BEGIN
    -- Buscar status 'due'
    SELECT status_id INTO v_due_status_id
    FROM billing.installment_statuses
    WHERE name = 'due';
    
    IF v_due_status_id IS NOT NULL THEN
        -- Atualizar parcelas vencidas
        UPDATE billing.installments
        SET 
            status_id = v_due_status_id,
            updated_at = now()
        WHERE status_id = (
            SELECT status_id FROM billing.installment_statuses WHERE name = 'pending'
        )
        AND due_date <= CURRENT_DATE;
        
        -- Registrar eventos na timeline para parcelas vencidas
        INSERT INTO billing.transaction_timeline (
            transaction_id,
            event_type,
            description,
            metadata
        )
        SELECT DISTINCT
            ep.transaction_id,
            'payment_attempt',
            'Parcela vencida',
            jsonb_build_object(
                'installment_id', i.installment_id,
                'due_date', i.due_date,
                'amount', i.amount
            )
        FROM billing.installments i
        JOIN billing.expected_payments ep ON i.expected_payment_id = ep.expected_payment_id
        WHERE i.status_id = v_due_status_id
          AND i.due_date = CURRENT_DATE;
        
        RAISE NOTICE 'Parcelas vencidas atualizadas para status "due"';
    END IF;
END;
$$;

COMMENT ON FUNCTION billing.update_installment_status_on_due_date IS 'Atualiza o status da parcela para due quando vence';

-- =====================================================
-- TRIGGERS DE AUDITORIA E LOG
-- =====================================================

-- =====================================================
-- log_transaction_changes
-- =====================================================
-- Registra mudanças importantes na timeline
-- Trigger: AFTER UPDATE ON billing.transactions

CREATE OR REPLACE FUNCTION billing.log_transaction_changes()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_old_status_name text;
    v_new_status_name text;
    v_old_payment_type_name text;
    v_new_payment_type_name text;
BEGIN
    -- Buscar nomes dos status
    IF OLD.status_id != NEW.status_id THEN
        SELECT name INTO v_old_status_name
        FROM billing.transaction_statuses
        WHERE status_id = OLD.status_id;
        
        SELECT name INTO v_new_status_name
        FROM billing.transaction_statuses
        WHERE status_id = NEW.status_id;
        
        -- Registrar mudança de status
        INSERT INTO billing.transaction_timeline (
            transaction_id,
            event_type,
            description,
            metadata
        ) VALUES (
            NEW.transaction_id,
            'payment_attempt',
            'Status da transação alterado',
            jsonb_build_object(
                'old_status', v_old_status_name,
                'new_status', v_new_status_name,
                'changed_at', now()
            )
        );
    END IF;
    
    -- Buscar nomes dos tipos de pagamento
    IF OLD.payment_type_id != NEW.payment_type_id THEN
        SELECT name INTO v_old_payment_type_name
        FROM billing.payment_types
        WHERE payment_type_id = OLD.payment_type_id;
        
        SELECT name INTO v_new_payment_type_name
        FROM billing.payment_types
        WHERE payment_type_id = NEW.payment_type_id;
        
        -- Registrar mudança de tipo de pagamento
        INSERT INTO billing.transaction_timeline (
            transaction_id,
            event_type,
            description,
            metadata
        ) VALUES (
            NEW.transaction_id,
            'payment_attempt',
            'Tipo de pagamento alterado',
            jsonb_build_object(
                'old_payment_type', v_old_payment_type_name,
                'new_payment_type', v_new_payment_type_name,
                'changed_at', now()
            )
        );
    END IF;
    
    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION billing.log_transaction_changes IS 'Registra mudanças importantes na timeline';

-- Criar o trigger
CREATE TRIGGER tr_log_transaction_changes
    AFTER UPDATE ON billing.transactions
    FOR EACH ROW
    EXECUTE FUNCTION billing.log_transaction_changes();

-- =====================================================
-- log_installment_changes
-- =====================================================
-- Registra mudanças importantes nas parcelas
-- Trigger: AFTER UPDATE ON billing.installments

CREATE OR REPLACE FUNCTION billing.log_installment_changes()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_old_status_name text;
    v_new_status_name text;
    v_transaction_id uuid;
BEGIN
    -- Se o status mudou
    IF OLD.status_id != NEW.status_id THEN
        -- Buscar nomes dos status
        SELECT name INTO v_old_status_name
        FROM billing.installment_statuses
        WHERE status_id = OLD.status_id;
        
        SELECT name INTO v_new_status_name
        FROM billing.installment_statuses
        WHERE status_id = NEW.status_id;
        
        -- Buscar transaction_id
        SELECT ep.transaction_id INTO v_transaction_id
        FROM billing.expected_payments ep
        WHERE ep.expected_payment_id = NEW.expected_payment_id;
        
        -- Registrar mudança de status
        INSERT INTO billing.transaction_timeline (
            transaction_id,
            event_type,
            description,
            metadata
        ) VALUES (
            v_transaction_id,
            'installment_paid',
            'Status da parcela alterado',
            jsonb_build_object(
                'installment_id', NEW.installment_id,
                'installment_number', NEW.installment_number,
                'old_status', v_old_status_name,
                'new_status', v_new_status_name,
                'changed_at', now()
            )
        );
    END IF;
    
    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION billing.log_installment_changes IS 'Registra mudanças importantes nas parcelas';

-- Criar o trigger
CREATE TRIGGER tr_log_installment_changes
    AFTER UPDATE ON billing.installments
    FOR EACH ROW
    EXECUTE FUNCTION billing.log_installment_changes();

-- =====================================================
-- FUNÇÃO PARA CRIAR TODOS OS TRIGGERS
-- =====================================================

-- =====================================================
-- create_billing_triggers
-- =====================================================
-- Cria todos os triggers do schema billing
-- Parâmetros: nenhum
-- Retorna: void

CREATE OR REPLACE FUNCTION billing.create_billing_triggers()
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE NOTICE 'Criando triggers do schema billing...';
    
    -- Triggers já são criados automaticamente pelo script
    -- Esta função serve apenas para documentação e verificação
    
    RAISE NOTICE 'Triggers criados com sucesso!';
    RAISE NOTICE 'Triggers disponíveis:';
    RAISE NOTICE '- tr_validate_transaction_business_reference';
    RAISE NOTICE '- tr_validate_installment_amounts';
    RAISE NOTICE '- tr_update_transaction_status_on_payment';
    RAISE NOTICE '- tr_update_installment_status_on_payment';
    RAISE NOTICE '- tr_log_transaction_changes';
    RAISE NOTICE '- tr_log_installment_changes';
    
END;
$$;

COMMENT ON FUNCTION billing.create_billing_triggers IS 'Cria todos os triggers do schema billing';
