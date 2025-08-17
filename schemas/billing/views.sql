-- =====================================================
-- VIEWS DO SCHEMA: billing
-- =====================================================
-- Este arquivo contém todas as views relacionadas ao schema billing
-- Inclui views para relatórios, consultas e análises

-- =====================================================
-- VIEWS DE RESUMO E ESTATÍSTICAS
-- =====================================================

-- =====================================================
-- v_transactions_summary
-- =====================================================
-- Resumo geral de todas as transações com status e tipo de pagamento

CREATE OR REPLACE VIEW billing.v_transactions_summary AS
SELECT 
    t.transaction_id,
    t.amount,
    t.currency,
    t.total_installments,
    t.created_at,
    ts.name AS status,
    pt.name AS payment_type,
    pt.supports_installments,
    t.business_reference
FROM billing.transactions t
JOIN billing.transaction_statuses ts ON t.status_id = ts.status_id
JOIN billing.payment_types pt ON t.payment_type_id = pt.payment_type_id
WHERE ts.is_active = true AND pt.is_active = true;

COMMENT ON VIEW billing.v_transactions_summary IS 'Resumo geral de todas as transações com status e tipo de pagamento';

-- =====================================================
-- v_expected_payments_summary
-- =====================================================
-- Resumo de pagamentos esperados com informações de transação

CREATE OR REPLACE VIEW billing.v_expected_payments_summary AS
SELECT 
    ep.expected_payment_id,
    ep.payment_method,
    ep.gateway_name,
    ep.amount,
    ep.created_at,
    t.transaction_id,
    t.amount AS transaction_amount,
    t.currency,
    t.total_installments,
    ts.name AS transaction_status,
    pt.name AS payment_type
FROM billing.expected_payments ep
JOIN billing.transactions t ON ep.transaction_id = t.transaction_id
JOIN billing.transaction_statuses ts ON t.status_id = ts.status_id
JOIN billing.payment_types pt ON t.payment_type_id = pt.payment_type_id
WHERE ts.is_active = true AND pt.is_active = true;

COMMENT ON VIEW billing.v_expected_payments_summary IS 'Resumo de pagamentos esperados com informações de transação';

-- =====================================================
-- v_installments_summary
-- =====================================================
-- Resumo de parcelas com informações de pagamento e transação

CREATE OR REPLACE VIEW billing.v_installments_summary AS
SELECT 
    i.installment_id,
    i.installment_number,
    i.amount,
    i.due_date,
    i.created_at,
    is2.name AS status,
    ep.expected_payment_id,
    ep.payment_method,
    ep.gateway_name,
    t.transaction_id,
    t.amount AS transaction_amount,
    t.currency,
    t.total_installments,
    ts.name AS transaction_status
FROM billing.installments i
JOIN billing.installment_statuses is2 ON i.status_id = is2.status_id
JOIN billing.expected_payments ep ON i.expected_payment_id = ep.expected_payment_id
JOIN billing.transactions t ON ep.transaction_id = t.transaction_id
JOIN billing.transaction_statuses ts ON t.status_id = ts.status_id
WHERE is2.is_active = true AND ts.is_active = true;

COMMENT ON VIEW billing.v_installments_summary IS 'Resumo de parcelas com informações de pagamento e transação';

-- =====================================================
-- v_payment_attempts_summary
-- =====================================================
-- Resumo de tentativas de pagamento com informações completas

CREATE OR REPLACE VIEW billing.v_payment_attempts_summary AS
SELECT 
    pa.attempt_id,
    pa.payment_method,
    pa.gateway_name,
    pa.status AS attempt_status,
    pa.failure_reason,
    pa.created_at,
    ep.expected_payment_id,
    ep.amount AS expected_amount,
    t.transaction_id,
    t.amount AS transaction_amount,
    t.currency,
    ts.name AS transaction_status
FROM billing.payment_attempts pa
JOIN billing.expected_payments ep ON pa.expected_payment_id = ep.expected_payment_id
JOIN billing.transactions t ON ep.transaction_id = t.transaction_id
JOIN billing.transaction_statuses ts ON t.status_id = ts.status_id
WHERE ts.is_active = true;

COMMENT ON VIEW billing.v_payment_attempts_summary IS 'Resumo de tentativas de pagamento com informações completas';

-- =====================================================
-- VIEWS DE ANÁLISE E MONITORAMENTO
-- =====================================================

-- =====================================================
-- v_transactions_by_status
-- =====================================================
-- Contagem de transações por status

CREATE OR REPLACE VIEW billing.v_transactions_by_status AS
SELECT 
    ts.name AS status,
    ts.description,
    COUNT(*) AS total_transactions,
    SUM(t.amount) AS total_amount,
    AVG(t.amount) AS average_amount,
    MIN(t.created_at) AS first_transaction,
    MAX(t.created_at) AS last_transaction
FROM billing.transactions t
JOIN billing.transaction_statuses ts ON t.status_id = ts.status_id
WHERE ts.is_active = true
GROUP BY ts.status_id, ts.name, ts.description
ORDER BY total_transactions DESC;

COMMENT ON VIEW billing.v_transactions_by_status IS 'Contagem de transações por status';

-- =====================================================
-- v_transactions_by_payment_type
-- =====================================================
-- Contagem de transações por tipo de pagamento

CREATE OR REPLACE VIEW billing.v_transactions_by_payment_type AS
SELECT 
    pt.name AS payment_type,
    pt.description,
    pt.supports_installments,
    COUNT(*) AS total_transactions,
    SUM(t.amount) AS total_amount,
    AVG(t.amount) AS average_amount,
    AVG(t.total_installments) AS average_installments,
    MIN(t.created_at) AS first_transaction,
    MAX(t.created_at) AS last_transaction
FROM billing.transactions t
JOIN billing.payment_types pt ON t.payment_type_id = pt.payment_type_id
WHERE pt.is_active = true
GROUP BY pt.payment_type_id, pt.name, pt.description, pt.supports_installments
ORDER BY total_transactions DESC;

COMMENT ON VIEW billing.v_transactions_by_payment_type IS 'Contagem de transações por tipo de pagamento';

-- =====================================================
-- v_installments_by_status
-- =====================================================
-- Contagem de parcelas por status

CREATE OR REPLACE VIEW billing.v_installments_by_status AS
SELECT 
    is2.name AS status,
    is2.description,
    COUNT(*) AS total_installments,
    SUM(i.amount) AS total_amount,
    AVG(i.amount) AS average_amount,
    MIN(i.due_date) AS earliest_due_date,
    MAX(i.due_date) AS latest_due_date,
    COUNT(CASE WHEN i.due_date < CURRENT_DATE THEN 1 END) AS overdue_count,
    COUNT(CASE WHEN i.due_date BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '7 days' THEN 1 END) AS due_this_week
FROM billing.installments i
JOIN billing.installment_statuses is2 ON i.status_id = is2.status_id
WHERE is2.is_active = true
GROUP BY is2.status_id, is2.name, is2.description
ORDER BY total_installments DESC;

COMMENT ON VIEW billing.v_installments_by_status IS 'Contagem de parcelas por status';

-- =====================================================
-- v_payment_attempts_by_status
-- =====================================================
-- Contagem de tentativas de pagamento por status

CREATE OR REPLACE VIEW billing.v_payment_attempts_by_status AS
SELECT 
    pa.status,
    COUNT(*) AS total_attempts,
    COUNT(CASE WHEN pa.failure_reason IS NOT NULL THEN 1 END) AS failed_with_reason,
    COUNT(CASE WHEN pa.failure_reason IS NULL THEN 1 END) AS failed_without_reason,
    MIN(pa.created_at) AS first_attempt,
    MAX(pa.created_at) AS last_attempt
FROM billing.payment_attempts pa
GROUP BY pa.status
ORDER BY total_attempts DESC;

COMMENT ON VIEW billing.v_payment_attempts_by_status IS 'Contagem de tentativas de pagamento por status';

-- =====================================================
-- VIEWS DE RELATÓRIOS TEMPORAIS
-- =====================================================

-- =====================================================
-- v_transactions_by_month
-- =====================================================
-- Transações agrupadas por mês

CREATE OR REPLACE VIEW billing.v_transactions_by_month AS
SELECT 
    DATE_TRUNC('month', t.created_at) AS month,
    COUNT(*) AS total_transactions,
    SUM(t.amount) AS total_amount,
    AVG(t.amount) AS average_amount,
    COUNT(DISTINCT t.payment_type_id) AS unique_payment_types,
    COUNT(CASE WHEN t.total_installments > 1 THEN 1 END) AS installment_transactions,
    COUNT(CASE WHEN t.total_installments = 1 THEN 1 END) AS single_payment_transactions
FROM billing.transactions t
GROUP BY DATE_TRUNC('month', t.created_at)
ORDER BY month DESC;

COMMENT ON VIEW billing.v_transactions_by_month IS 'Transações agrupadas por mês';

-- =====================================================
-- v_installments_by_month
-- =====================================================
-- Parcelas agrupadas por mês de vencimento

CREATE OR REPLACE VIEW billing.v_installments_by_month AS
SELECT 
    DATE_TRUNC('month', i.due_date) AS month,
    COUNT(*) AS total_installments,
    SUM(i.amount) AS total_amount,
    AVG(i.amount) AS average_amount,
    COUNT(CASE WHEN is2.name = 'pending' THEN 1 END) AS pending_count,
    COUNT(CASE WHEN is2.name = 'due' THEN 1 END) AS due_count,
    COUNT(CASE WHEN is2.name = 'paid' THEN 1 END) AS paid_count,
    COUNT(CASE WHEN is2.name = 'cancelled' THEN 1 END) AS cancelled_count
FROM billing.installments i
JOIN billing.installment_statuses is2 ON i.status_id = is2.status_id
WHERE is2.is_active = true
GROUP BY DATE_TRUNC('month', i.due_date)
ORDER BY month DESC;

COMMENT ON VIEW billing.v_installments_by_month IS 'Parcelas agrupadas por mês de vencimento';

-- =====================================================
-- VIEWS DE ALERTAS E MONITORAMENTO
-- =====================================================

-- =====================================================
-- v_overdue_installments
-- =====================================================
-- Parcelas em atraso

CREATE OR REPLACE VIEW billing.v_overdue_installments AS
SELECT 
    i.installment_id,
    i.installment_number,
    i.amount,
    i.due_date,
    CURRENT_DATE - i.due_date AS days_overdue,
    ep.payment_method,
    ep.gateway_name,
    t.transaction_id,
    t.amount AS transaction_amount,
    t.currency,
    t.business_reference
FROM billing.installments i
JOIN billing.installment_statuses is2 ON i.status_id = is2.status_id
JOIN billing.expected_payments ep ON i.expected_payment_id = ep.expected_payment_id
JOIN billing.transactions t ON ep.transaction_id = t.transaction_id
WHERE is2.name = 'due' 
  AND i.due_date < CURRENT_DATE
ORDER BY i.due_date ASC, i.amount DESC;

COMMENT ON VIEW billing.v_overdue_installments IS 'Parcelas em atraso';

-- =====================================================
-- v_installments_due_soon
-- =====================================================
-- Parcelas com vencimento próximo

CREATE OR REPLACE VIEW billing.v_installments_due_soon AS
SELECT 
    i.installment_id,
    i.installment_number,
    i.amount,
    i.due_date,
    i.due_date - CURRENT_DATE AS days_until_due,
    ep.payment_method,
    ep.gateway_name,
    t.transaction_id,
    t.amount AS transaction_amount,
    t.currency,
    t.business_reference
FROM billing.installments i
JOIN billing.installment_statuses is2 ON i.status_id = is2.status_id
JOIN billing.expected_payments ep ON i.expected_payment_id = ep.expected_payment_id
JOIN billing.transactions t ON ep.transaction_id = t.transaction_id
WHERE is2.name = 'pending' 
  AND i.due_date BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '7 days'
ORDER BY i.due_date ASC, i.amount DESC;

COMMENT ON VIEW billing.v_installments_due_soon IS 'Parcelas com vencimento próximo';

-- =====================================================
-- v_failed_payment_attempts_recent
-- =====================================================
-- Tentativas de pagamento que falharam recentemente

CREATE OR REPLACE VIEW billing.v_failed_payment_attempts_recent AS
SELECT 
    pa.attempt_id,
    pa.payment_method,
    pa.gateway_name,
    pa.failure_reason,
    pa.created_at,
    CURRENT_TIMESTAMP - pa.created_at AS time_since_failure,
    ep.expected_payment_id,
    ep.amount AS expected_amount,
    t.transaction_id,
    t.amount AS transaction_amount,
    t.currency,
    t.business_reference
FROM billing.payment_attempts pa
JOIN billing.expected_payments ep ON pa.expected_payment_id = ep.expected_payment_id
JOIN billing.transactions t ON ep.transaction_id = t.transaction_id
WHERE pa.status = 'failed'
  AND pa.created_at >= CURRENT_DATE - INTERVAL '7 days'
ORDER BY pa.created_at DESC;

COMMENT ON VIEW billing.v_failed_payment_attempts_recent IS 'Tentativas de pagamento que falharam recentemente';

-- =====================================================
-- VIEWS DE INTEGRAÇÃO COM NEGÓCIO
-- =====================================================

-- =====================================================
-- v_business_reference_summary
-- =====================================================
-- Resumo de transações por referência de negócio

CREATE OR REPLACE VIEW billing.v_business_reference_summary AS
SELECT 
    t.business_reference->>'schema' AS business_schema,
    t.business_reference->>'table' AS business_table,
    COUNT(*) AS total_transactions,
    SUM(t.amount) AS total_amount,
    AVG(t.amount) AS average_amount,
    COUNT(CASE WHEN ts.name = 'completed' THEN 1 END) AS completed_transactions,
    COUNT(CASE WHEN ts.name = 'pending' THEN 1 END) AS pending_transactions,
    COUNT(CASE WHEN ts.name = 'failed' THEN 1 END) AS failed_transactions,
    MIN(t.created_at) AS first_transaction,
    MAX(t.created_at) AS last_transaction
FROM billing.transactions t
JOIN billing.transaction_statuses ts ON t.status_id = ts.status_id
WHERE ts.is_active = true
GROUP BY t.business_reference->>'schema', t.business_reference->>'table'
ORDER BY total_transactions DESC;

COMMENT ON VIEW billing.v_business_reference_summary IS 'Resumo de transações por referência de negócio';

-- =====================================================
-- v_gateway_performance
-- =====================================================
-- Performance dos gateways de pagamento

CREATE OR REPLACE VIEW billing.v_gateway_performance AS
SELECT 
    pa.gateway_name,
    COUNT(*) AS total_attempts,
    COUNT(CASE WHEN pa.status = 'success' THEN 1 END) AS successful_attempts,
    COUNT(CASE WHEN pa.status = 'failed' THEN 1 END) AS failed_attempts,
    COUNT(CASE WHEN pa.status = 'pending' THEN 1 END) AS pending_attempts,
    ROUND(
        (COUNT(CASE WHEN pa.status = 'success' THEN 1 END)::numeric / COUNT(*)) * 100, 2
    ) AS success_rate_percentage,
    MIN(pa.created_at) AS first_attempt,
    MAX(pa.created_at) AS last_attempt
FROM billing.payment_attempts pa
GROUP BY pa.gateway_name
ORDER BY success_rate_percentage DESC, total_attempts DESC;

COMMENT ON VIEW billing.v_gateway_performance IS 'Performance dos gateways de pagamento';
