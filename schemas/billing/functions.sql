-- =====================================================
-- FUNÇÕES DO SCHEMA: billing
-- =====================================================
-- Este arquivo contém todas as funções PL/pgSQL relacionadas ao schema billing
-- Inclui funções para gestão de transações, pagamentos, parcelas e timeline

-- =====================================================
-- FUNÇÕES DE GESTÃO DE TRANSAÇÕES
-- =====================================================

-- =====================================================
-- create_transaction
-- =====================================================
-- Cria uma nova transação financeira
-- Parâmetros: referência de negócio, valor, moeda, tipo de pagamento, parcelas
-- Retorna: transaction_id da transação criada

CREATE OR REPLACE FUNCTION billing.create_transaction(
    p_business_reference jsonb,
    p_amount numeric(10,2),
    p_currency text DEFAULT 'BRL',
    p_payment_type_name text DEFAULT 'credit_card',
    p_total_installments integer DEFAULT 1
)
RETURNS uuid
LANGUAGE plpgsql
AS $$
DECLARE
    v_transaction_id uuid;
    v_status_id uuid;
    v_payment_type_id uuid;
BEGIN
    -- Validações
    IF p_business_reference IS NULL THEN
        RAISE EXCEPTION 'Referência de negócio é obrigatória';
    END IF;
    
    IF p_amount IS NULL OR p_amount <= 0 THEN
        RAISE EXCEPTION 'Valor deve ser maior que zero';
    END IF;
    
    IF p_total_installments < 1 THEN
        RAISE EXCEPTION 'Número de parcelas deve ser pelo menos 1';
    END IF;
    
    -- Buscar status 'pending'
    SELECT status_id INTO v_status_id 
    FROM billing.transaction_statuses 
    WHERE name = 'pending';
    
    IF v_status_id IS NULL THEN
        RAISE EXCEPTION 'Status "pending" não encontrado';
    END IF;
    
    -- Buscar tipo de pagamento
    SELECT payment_type_id INTO v_payment_type_id 
    FROM billing.payment_types 
    WHERE name = p_payment_type_name;
    
    IF v_payment_type_id IS NULL THEN
        RAISE EXCEPTION 'Tipo de pagamento "%" não encontrado', p_payment_type_name;
    END IF;
    
    -- Criar a transação
    INSERT INTO billing.transactions (
        business_reference,
        amount,
        currency,
        status_id,
        payment_type_id,
        total_installments
    ) VALUES (
        p_business_reference,
        p_amount,
        p_currency,
        v_status_id,
        v_payment_type_id,
        p_total_installments
    ) RETURNING transaction_id INTO v_transaction_id;
    
    -- Registrar evento na timeline
    INSERT INTO billing.transaction_timeline (
        transaction_id,
        event_type,
        description,
        metadata
    ) VALUES (
        v_transaction_id,
        'created',
        'Transação criada',
        jsonb_build_object(
            'amount', p_amount,
            'currency', p_currency,
            'installments', p_total_installments
        )
    );
    
    RAISE NOTICE 'Transação criada com ID: %', v_transaction_id;
    
    RETURN v_transaction_id;
END;
$$;

COMMENT ON FUNCTION billing.create_transaction IS 'Cria uma nova transação financeira';

-- =====================================================
-- create_expected_payment
-- =====================================================
-- Cria um pagamento esperado para uma transação
-- Parâmetros: transaction_id, método de pagamento, gateway, valor
-- Retorna: expected_payment_id do pagamento criado

CREATE OR REPLACE FUNCTION billing.create_expected_payment(
    p_transaction_id uuid,
    p_payment_method text,
    p_gateway_name text DEFAULT NULL,
    p_amount numeric(10,2) DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
AS $$
DECLARE
    v_expected_payment_id uuid;
    v_transaction_amount numeric(10,2);
BEGIN
    -- Validações
    IF p_transaction_id IS NULL THEN
        RAISE EXCEPTION 'ID da transação é obrigatório';
    END IF;
    
    IF p_payment_method IS NULL THEN
        RAISE EXCEPTION 'Método de pagamento é obrigatório';
    END IF;
    
    -- Verificar se a transação existe
    IF NOT EXISTS (SELECT 1 FROM billing.transactions WHERE transaction_id = p_transaction_id) THEN
        RAISE EXCEPTION 'Transação com ID % não encontrada', p_transaction_id;
    END IF;
    
    -- Buscar valor da transação se não fornecido
    IF p_amount IS NULL THEN
        SELECT amount INTO v_transaction_amount 
        FROM billing.transactions 
        WHERE transaction_id = p_transaction_id;
        p_amount := v_transaction_amount;
    END IF;
    
    -- Criar o pagamento esperado
    INSERT INTO billing.expected_payments (
        transaction_id,
        payment_method,
        gateway_name,
        amount
    ) VALUES (
        p_transaction_id,
        p_payment_method,
        p_gateway_name,
        p_amount
    ) RETURNING expected_payment_id INTO v_expected_payment_id;
    
    -- Registrar evento na timeline
    INSERT INTO billing.transaction_timeline (
        transaction_id,
        event_type,
        description,
        metadata
    ) VALUES (
        p_transaction_id,
        'payment_attempt',
        'Pagamento esperado criado',
        jsonb_build_object(
            'expected_payment_id', v_expected_payment_id,
            'payment_method', p_payment_method,
            'gateway', p_gateway_name
        )
    );
    
    RAISE NOTICE 'Pagamento esperado criado com ID: %', v_expected_payment_id;
    
    RETURN v_expected_payment_id;
END;
$$;

COMMENT ON FUNCTION billing.create_expected_payment IS 'Cria um pagamento esperado para uma transação';

-- =====================================================
-- create_installments
-- =====================================================
-- Cria parcelas para um pagamento esperado
-- Parâmetros: expected_payment_id, valor por parcela, datas de vencimento
-- Retorna: array com IDs das parcelas criadas

CREATE OR REPLACE FUNCTION billing.create_installments(
    p_expected_payment_id uuid,
    p_installment_amount numeric(10,2),
    p_due_dates date[]
)
RETURNS uuid[]
LANGUAGE plpgsql
AS $$
DECLARE
    v_installment_ids uuid[] := ARRAY[]::uuid[];
    v_installment_id uuid;
    v_status_id uuid;
    v_due_date date;
    v_installment_number integer := 1;
BEGIN
    -- Validações
    IF p_expected_payment_id IS NULL THEN
        RAISE EXCEPTION 'ID do pagamento esperado é obrigatório';
    END IF;
    
    IF p_installment_amount IS NULL OR p_installment_amount <= 0 THEN
        RAISE EXCEPTION 'Valor da parcela deve ser maior que zero';
    END IF;
    
    IF p_due_dates IS NULL OR array_length(p_due_dates, 1) = 0 THEN
        RAISE EXCEPTION 'Datas de vencimento são obrigatórias';
    END IF;
    
    -- Verificar se o pagamento esperado existe
    IF NOT EXISTS (SELECT 1 FROM billing.expected_payments WHERE expected_payment_id = p_expected_payment_id) THEN
        RAISE EXCEPTION 'Pagamento esperado com ID % não encontrado', p_expected_payment_id;
    END IF;
    
    -- Buscar status 'pending'
    SELECT status_id INTO v_status_id 
    FROM billing.installment_statuses 
    WHERE name = 'pending';
    
    IF v_status_id IS NULL THEN
        RAISE EXCEPTION 'Status "pending" não encontrado';
    END IF;
    
    -- Criar parcelas
    FOREACH v_due_date IN ARRAY p_due_dates
    LOOP
        INSERT INTO billing.installments (
            expected_payment_id,
            installment_number,
            amount,
            due_date,
            status_id
        ) VALUES (
            p_expected_payment_id,
            v_installment_number,
            p_installment_amount,
            v_due_date,
            v_status_id
        ) RETURNING installment_id INTO v_installment_id;
        
        v_installment_ids := array_append(v_installment_ids, v_installment_id);
        v_installment_number := v_installment_number + 1;
    END LOOP;
    
    RAISE NOTICE 'Criadas % parcelas para o pagamento esperado %', array_length(v_installment_ids, 1), p_expected_payment_id;
    
    RETURN v_installment_ids;
END;
$$;

COMMENT ON FUNCTION billing.create_installments IS 'Cria parcelas para um pagamento esperado';

-- =====================================================
-- create_payment_attempt
-- =====================================================
-- Cria uma tentativa de pagamento
-- Parâmetros: expected_payment_id, método, gateway, payload
-- Retorna: attempt_id da tentativa criada

CREATE OR REPLACE FUNCTION billing.create_payment_attempt(
    p_expected_payment_id uuid,
    p_payment_method text,
    p_gateway_name text,
    p_gateway_payload jsonb,
    p_status text DEFAULT 'pending'
)
RETURNS uuid
LANGUAGE plpgsql
AS $$
DECLARE
    v_attempt_id uuid;
    v_transaction_id uuid;
BEGIN
    -- Validações
    IF p_expected_payment_id IS NULL THEN
        RAISE EXCEPTION 'ID do pagamento esperado é obrigatório';
    END IF;
    
    IF p_payment_method IS NULL THEN
        RAISE EXCEPTION 'Método de pagamento é obrigatório';
    END IF;
    
    IF p_gateway_name IS NULL THEN
        RAISE EXCEPTION 'Nome do gateway é obrigatório';
    END IF;
    
    IF p_gateway_payload IS NULL THEN
        RAISE EXCEPTION 'Payload do gateway é obrigatório';
    END IF;
    
    -- Verificar se o pagamento esperado existe
    IF NOT EXISTS (SELECT 1 FROM billing.expected_payments WHERE expected_payment_id = p_expected_payment_id) THEN
        RAISE EXCEPTION 'Pagamento esperado com ID % não encontrado', p_expected_payment_id;
    END IF;
    
    -- Buscar transaction_id para a timeline
    SELECT transaction_id INTO v_transaction_id 
    FROM billing.expected_payments 
    WHERE expected_payment_id = p_expected_payment_id;
    
    -- Criar a tentativa de pagamento
    INSERT INTO billing.payment_attempts (
        expected_payment_id,
        payment_method,
        gateway_name,
        status,
        gateway_payload
    ) VALUES (
        p_expected_payment_id,
        p_payment_method,
        p_gateway_name,
        p_status,
        p_gateway_payload
    ) RETURNING attempt_id INTO v_attempt_id;
    
    -- Registrar evento na timeline
    INSERT INTO billing.transaction_timeline (
        transaction_id,
        event_type,
        description,
        metadata
    ) VALUES (
        v_transaction_id,
        'payment_attempt',
        'Tentativa de pagamento criada',
        jsonb_build_object(
            'attempt_id', v_attempt_id,
            'payment_method', p_payment_method,
            'gateway', p_gateway_name,
            'status', p_status
        )
    );
    
    RAISE NOTICE 'Tentativa de pagamento criada com ID: %', v_attempt_id;
    
    RETURN v_attempt_id;
END;
$$;

COMMENT ON FUNCTION billing.create_payment_attempt IS 'Cria uma tentativa de pagamento';

-- =====================================================
-- update_payment_attempt_status
-- =====================================================
-- Atualiza o status de uma tentativa de pagamento
-- Parâmetros: attempt_id, novo status, motivo da falha (opcional)
-- Retorna: void

CREATE OR REPLACE FUNCTION billing.update_payment_attempt_status(
    p_attempt_id uuid,
    p_status text,
    p_failure_reason text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    v_transaction_id uuid;
    v_payment_method text;
    v_gateway_name text;
BEGIN
    -- Validações
    IF p_attempt_id IS NULL THEN
        RAISE EXCEPTION 'ID da tentativa é obrigatório';
    END IF;
    
    IF p_status IS NULL THEN
        RAISE EXCEPTION 'Novo status é obrigatório';
    END IF;
    
    -- Verificar se a tentativa existe
    IF NOT EXISTS (SELECT 1 FROM billing.payment_attempts WHERE attempt_id = p_attempt_id) THEN
        RAISE EXCEPTION 'Tentativa com ID % não encontrada', p_attempt_id;
    END IF;
    
    -- Buscar informações para a timeline
    SELECT 
        ep.transaction_id,
        pa.payment_method,
        pa.gateway_name
    INTO v_transaction_id, v_payment_method, v_gateway_name
    FROM billing.payment_attempts pa
    JOIN billing.expected_payments ep ON pa.expected_payment_id = ep.expected_payment_id
    WHERE pa.attempt_id = p_attempt_id;
    
    -- Atualizar a tentativa
    UPDATE billing.payment_attempts 
    SET 
        status = p_status,
        failure_reason = p_failure_reason,
        updated_at = now()
    WHERE attempt_id = p_attempt_id;
    
    -- Registrar evento na timeline
    INSERT INTO billing.transaction_timeline (
        transaction_id,
        event_type,
        description,
        metadata
    ) VALUES (
        v_transaction_id,
        CASE 
            WHEN p_status = 'success' THEN 'success'
            WHEN p_status = 'failed' THEN 'failure'
            ELSE 'payment_attempt'
        END,
        CASE 
            WHEN p_status = 'success' THEN 'Pagamento realizado com sucesso'
            WHEN p_status = 'failed' THEN 'Falha no pagamento'
            ELSE 'Status da tentativa atualizado'
        END,
        jsonb_build_object(
            'attempt_id', p_attempt_id,
            'payment_method', v_payment_method,
            'gateway', v_gateway_name,
            'status', p_status,
            'failure_reason', p_failure_reason
        )
    );
    
    RAISE NOTICE 'Status da tentativa % atualizado para: %', p_attempt_id, p_status;
END;
$$;

COMMENT ON FUNCTION billing.update_payment_attempt_status IS 'Atualiza o status de uma tentativa de pagamento';

-- =====================================================
-- FUNÇÕES DE CONSULTA E RELATÓRIOS
-- =====================================================

-- =====================================================
-- get_transaction_summary
-- =====================================================
-- Retorna um resumo completo de uma transação
-- Parâmetros: transaction_id
-- Retorna: JSON com resumo da transação

CREATE OR REPLACE FUNCTION billing.get_transaction_summary(
    p_transaction_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
AS $$
DECLARE
    v_result jsonb;
BEGIN
    -- Validações
    IF p_transaction_id IS NULL THEN
        RAISE EXCEPTION 'ID da transação é obrigatório';
    END IF;
    
    -- Verificar se a transação existe
    IF NOT EXISTS (SELECT 1 FROM billing.transactions WHERE transaction_id = p_transaction_id) THEN
        RAISE EXCEPTION 'Transação com ID % não encontrada', p_transaction_id;
    END IF;
    
    -- Buscar resumo completo
    SELECT jsonb_build_object(
        'transaction', jsonb_build_object(
            'id', t.transaction_id,
            'amount', t.amount,
            'currency', t.currency,
            'total_installments', t.total_installments,
            'created_at', t.created_at,
            'status', ts.name,
            'payment_type', pt.name
        ),
        'expected_payments', (
            SELECT jsonb_agg(jsonb_build_object(
                'id', ep.expected_payment_id,
                'payment_method', ep.payment_method,
                'gateway', ep.gateway_name,
                'amount', ep.amount,
                'installments', (
                    SELECT jsonb_agg(jsonb_build_object(
                        'id', i.installment_id,
                        'number', i.installment_number,
                        'amount', i.amount,
                        'due_date', i.due_date,
                        'status', is2.name
                    ))
                    FROM billing.installments i
                    JOIN billing.installment_statuses is2 ON i.status_id = is2.status_id
                    WHERE i.expected_payment_id = ep.expected_payment_id
                ),
                'payment_attempts', (
                    SELECT jsonb_agg(jsonb_build_object(
                        'id', pa.attempt_id,
                        'status', pa.status,
                        'payment_method', pa.payment_method,
                        'gateway', pa.gateway_name,
                        'created_at', pa.created_at
                    ))
                    FROM billing.payment_attempts pa
                    WHERE pa.expected_payment_id = ep.expected_payment_id
                )
            ))
            FROM billing.expected_payments ep
            WHERE ep.transaction_id = t.transaction_id
        ),
        'timeline', (
            SELECT jsonb_agg(jsonb_build_object(
                'event_type', tt.event_type,
                'description', tt.description,
                'created_at', tt.created_at,
                'metadata', tt.metadata
            ) ORDER BY tt.created_at)
            FROM billing.transaction_timeline tt
            WHERE tt.transaction_id = t.transaction_id
        )
    ) INTO v_result
    FROM billing.transactions t
    JOIN billing.transaction_statuses ts ON t.status_id = ts.status_id
    JOIN billing.payment_types pt ON t.payment_type_id = pt.payment_type_id
    WHERE t.transaction_id = p_transaction_id;
    
    RETURN v_result;
END;
$$;

COMMENT ON FUNCTION billing.get_transaction_summary IS 'Retorna um resumo completo de uma transação';

-- =====================================================
-- get_pending_installments
-- =====================================================
-- Retorna parcelas pendentes de vencimento
-- Parâmetros: dias de antecedência (opcional)
-- Retorna: tabela com parcelas pendentes

CREATE OR REPLACE FUNCTION billing.get_pending_installments(
    p_days_ahead integer DEFAULT 7
)
RETURNS TABLE (
    installment_id uuid,
    transaction_id uuid,
    installment_number integer,
    amount numeric(10,2),
    due_date date,
    days_until_due integer,
    payment_method text,
    business_reference jsonb
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        i.installment_id,
        ep.transaction_id,
        i.installment_number,
        i.amount,
        i.due_date,
        i.due_date - CURRENT_DATE AS days_until_due,
        ep.payment_method,
        t.business_reference
    FROM billing.installments i
    JOIN billing.expected_payments ep ON i.expected_payment_id = ep.expected_payment_id
    JOIN billing.transactions t ON ep.transaction_id = t.transaction_id
    JOIN billing.installment_statuses is2 ON i.status_id = is2.status_id
    WHERE is2.name = 'pending'
      AND i.due_date BETWEEN CURRENT_DATE AND CURRENT_DATE + (p_days_ahead || ' days')::interval
    ORDER BY i.due_date, i.amount;
END;
$$;

COMMENT ON FUNCTION billing.get_pending_installments IS 'Retorna parcelas pendentes de vencimento';

-- =====================================================
-- get_failed_payment_attempts
-- =====================================================
-- Retorna tentativas de pagamento que falharam
-- Parâmetros: dias para trás (opcional)
-- Retorna: tabela com tentativas falhadas

CREATE OR REPLACE FUNCTION billing.get_failed_payment_attempts(
    p_days_back integer DEFAULT 30
)
RETURNS TABLE (
    attempt_id uuid,
    transaction_id uuid,
    payment_method text,
    gateway_name text,
    failure_reason text,
    created_at timestamp without time zone,
    business_reference jsonb
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        pa.attempt_id,
        ep.transaction_id,
        pa.payment_method,
        pa.gateway_name,
        pa.failure_reason,
        pa.created_at,
        t.business_reference
    FROM billing.payment_attempts pa
    JOIN billing.expected_payments ep ON pa.expected_payment_id = ep.expected_payment_id
    JOIN billing.transactions t ON ep.transaction_id = t.transaction_id
    WHERE pa.status = 'failed'
      AND pa.created_at >= CURRENT_DATE - (p_days_back || ' days')::interval
    ORDER BY pa.created_at DESC;
END;
$$;

COMMENT ON FUNCTION billing.get_failed_payment_attempts IS 'Retorna tentativas de pagamento que falharam';
