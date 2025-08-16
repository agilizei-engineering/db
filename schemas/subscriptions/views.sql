-- =====================================================
-- VIEWS DO SCHEMA: subscriptions
-- =====================================================
-- Este arquivo contém todas as views relacionadas ao schema subscriptions
-- Inclui views para consultas frequentes e relatórios

-- =====================================================
-- VIEW: v_active_subscriptions
-- =====================================================
-- Descrição: Assinaturas ativas com informações completas
-- Funcionalidade: Retorna dados combinados de todas as tabelas relacionadas
-- Uso: Ideal para dashboards e relatórios

CREATE OR REPLACE VIEW subscriptions.v_active_subscriptions AS
SELECT 
    s.subscription_id,
    s.establishment_id,
    s.supplier_id,
    s.employee_id,
    s.start_date,
    s.end_date,
    s.status,
    s.created_at,
    s.updated_at,
    
    -- Dados do plano
    pl.plan_id,
    pl.valid_from as plan_valid_from,
    pl.valid_to as plan_valid_to,
    pl.price,
    pl.usage_limits,
    
    -- Nome do plano
    pn.name as plan_name,
    pn.description as plan_description,
    
    -- Dados do produto
    p.product_id,
    p.name as product_name,
    p.description as product_description,
    p.billing_model,
    p.is_available_for_supplier,
    p.is_available_for_establishment,
    
    -- Dados do employee
    e.full_name as employee_name,
    e.email as employee_email,
    
    -- Dados do establishment (se aplicável)
    est.name as establishment_name,
    est.description as establishment_description,
    
    -- Dados do supplier (se aplicável)
    sup.name as supplier_name,
    sup.description as supplier_description,
    
    -- Cálculos
    CASE 
        WHEN s.establishment_id IS NOT NULL THEN 'establishment'
        ELSE 'supplier'
    END as client_type,
    
    (s.end_date - s.start_date) as subscription_duration_days,
    CASE 
        WHEN s.end_date < now() THEN 'expired'
        WHEN s.end_date < (now() + interval '30 days') THEN 'expiring_soon'
        ELSE 'active'
    END as subscription_status
    
FROM subscriptions.subscriptions s
JOIN subscriptions.plans pl ON s.plan_id = pl.plan_id
JOIN subscriptions.plan_names pn ON pl.plan_name_id = pn.plan_name_id
JOIN subscriptions.products p ON pl.product_id = p.product_id
JOIN accounts.employees e ON s.employee_id = e.employee_id
LEFT JOIN accounts.establishments est ON s.establishment_id = est.establishment_id
LEFT JOIN accounts.suppliers sup ON s.supplier_id = sup.supplier_id
WHERE s.status = 'active';

COMMENT ON VIEW subscriptions.v_active_subscriptions IS 'Assinaturas ativas com informações completas para dashboards e relatórios';

-- =====================================================
-- VIEW: v_usage_summary
-- =====================================================
-- Descrição: Resumo de uso por cliente e período
-- Funcionalidade: Retorna estatísticas de uso por cliente
-- Uso: Útil para análises e cobrança

CREATE OR REPLACE VIEW subscriptions.v_usage_summary AS
SELECT 
    ut.usage_id,
    ut.subscription_id,
    ut.period_start,
    ut.period_end,
    ut.quotations_used,
    ut.quotations_subscription,
    ut.quotations_bought,
    ut.quotations_limit,
    ut.is_over_limit,
    ut.created_at,
    ut.updated_at,
    
    -- Dados da assinatura
    s.establishment_id,
    s.supplier_id,
    s.start_date as subscription_start,
    s.end_date as subscription_end,
    s.status as subscription_status,
    
    -- Dados do plano
    pl.price as plan_price,
    pl.usage_limits,
    
    -- Nome do plano
    pn.name as plan_name,
    
    -- Dados do produto
    p.name as product_name,
    p.billing_model,
    
    -- Dados do cliente
    COALESCE(est.name, sup.name) as client_name,
    CASE 
        WHEN s.establishment_id IS NOT NULL THEN 'establishment'
        ELSE 'supplier'
    END as client_type,
    
    -- Cálculos
    GREATEST(0, ut.quotations_limit - ut.quotations_used) as quotations_remaining,
    ROUND((ut.quotations_used::numeric / ut.quotations_limit::numeric) * 100, 2) as usage_percentage,
    
    -- Período
    EXTRACT(DAY FROM (ut.period_end - ut.period_start)) as period_days,
    EXTRACT(DAY FROM (now() - ut.period_start)) as days_elapsed,
    EXTRACT(DAY FROM (ut.period_end - now())) as days_remaining
    
FROM subscriptions.usage_tracking ut
JOIN subscriptions.subscriptions s ON ut.subscription_id = s.subscription_id
JOIN subscriptions.plans pl ON s.plan_id = pl.plan_id
JOIN subscriptions.plan_names pn ON pl.plan_name_id = pn.plan_name_id
JOIN subscriptions.products p ON pl.product_id = p.product_id
LEFT JOIN accounts.establishments est ON s.establishment_id = est.establishment_id
LEFT JOIN accounts.suppliers sup ON s.supplier_id = sup.supplier_id
ORDER BY ut.period_start DESC, ut.subscription_id;

COMMENT ON VIEW subscriptions.v_usage_summary IS 'Resumo de uso por cliente e período para análises e cobrança';

-- =====================================================
-- VIEW: v_plan_comparison
-- =====================================================
-- Descrição: Comparação entre diferentes planos
-- Funcionalidade: Retorna comparação de recursos e preços
-- Uso: Ideal para vendas e marketing

CREATE OR REPLACE VIEW subscriptions.v_plan_comparison AS
SELECT 
    p.product_id,
    p.name as product_name,
    p.description as product_description,
    p.billing_model,
    p.is_available_for_supplier,
    p.is_available_for_establishment,
    
    pn.plan_name_id,
    pn.name as plan_name,
    pn.description as plan_description,
    pn.is_active as plan_name_active,
    
    pl.plan_id,
    pl.valid_from,
    pl.valid_to,
    pl.price,
    pl.usage_limits,
    pl.is_active as plan_active,
    
    -- Extração de limites específicos para comparação
    COALESCE(pl.usage_limits->>'quotations', '0')::integer as quotations_limit,
    COALESCE(pl.usage_limits->>'suppliers', '0')::integer as suppliers_limit,
    COALESCE(pl.usage_limits->>'items', '0')::integer as items_limit,
    COALESCE(pl.usage_limits->>'messages', '0')::integer as messages_limit,
    COALESCE(pl.usage_limits->>'establishments', '0')::integer as establishments_limit,
    
    -- Cálculos
    CASE 
        WHEN pl.valid_to < now() THEN 'expired'
        WHEN pl.valid_to < (now() + interval '30 days') THEN 'expiring_soon'
        ELSE 'active'
    END as plan_validity_status,
    
    (pl.valid_to - pl.valid_from) as plan_duration_days,
    
    -- Preço por dia (para comparação)
    ROUND(pl.price / EXTRACT(DAY FROM (pl.valid_to - pl.valid_from))::numeric, 4) as price_per_day,
    
    -- Preço por cotação (se aplicável)
    CASE 
        WHEN COALESCE(pl.usage_limits->>'quotations', '0')::integer > 0 
        THEN ROUND(pl.price / COALESCE(pl.usage_limits->>'quotations', '1')::numeric, 4)
        ELSE NULL
    END as price_per_quotation
    
FROM subscriptions.products p
JOIN subscriptions.plan_names pn ON pn.is_active = true
JOIN subscriptions.plans pl ON pl.product_id = p.product_id AND pl.plan_name_id = pn.plan_name_id
WHERE p.is_active = true
ORDER BY p.name, pn.name, pl.price;

COMMENT ON VIEW subscriptions.v_plan_comparison IS 'Comparação entre diferentes planos para vendas e marketing';

-- =====================================================
-- VIEW: v_quota_purchases_summary
-- =====================================================
-- Descrição: Resumo de compras de cotas extras
-- Funcionalidade: Retorna estatísticas de microtransações
-- Uso: Útil para análises financeiras

CREATE OR REPLACE VIEW subscriptions.v_quota_purchases_summary AS
SELECT 
    qp.purchase_id,
    qp.purchase_date,
    qp.quotations_bought,
    qp.unit_price,
    qp.total_price,
    qp.created_at,
    qp.updated_at,
    
    -- Dados do cliente
    qp.establishment_id,
    qp.supplier_id,
    COALESCE(est.name, sup.name) as client_name,
    CASE 
        WHEN qp.establishment_id IS NOT NULL THEN 'establishment'
        ELSE 'supplier'
    END as client_type,
    
    -- Dados da assinatura (se existir)
    s.subscription_id,
    s.status as subscription_status,
    
    -- Dados do plano
    pl.price as plan_price,
    pn.name as plan_name,
    p.name as product_name,
    
    -- Cálculos
    EXTRACT(DAY FROM (now() - qp.purchase_date)) as days_since_purchase,
    EXTRACT(MONTH FROM qp.purchase_date) as purchase_month,
    EXTRACT(YEAR FROM qp.purchase_date) as purchase_year,
    
    -- Comparação com preço do plano
    CASE 
        WHEN s.subscription_id IS NOT NULL AND pl.price > 0 
        THEN ROUND((qp.total_price / pl.price) * 100, 2)
        ELSE NULL
    END as purchase_vs_plan_percentage
    
FROM subscriptions.quota_purchases qp
LEFT JOIN accounts.establishments est ON qp.establishment_id = est.establishment_id
LEFT JOIN accounts.suppliers sup ON qp.supplier_id = sup.supplier_id
LEFT JOIN subscriptions.subscriptions s ON (
    (qp.establishment_id IS NOT NULL AND s.establishment_id = qp.establishment_id) OR
    (qp.supplier_id IS NOT NULL AND s.supplier_id = qp.supplier_id)
) AND s.status = 'active'
LEFT JOIN subscriptions.plans pl ON s.plan_id = pl.plan_id
LEFT JOIN subscriptions.plan_names pn ON pl.plan_name_id = pn.plan_name_id
LEFT JOIN subscriptions.products p ON pl.product_id = p.product_id
ORDER BY qp.purchase_date DESC;

COMMENT ON VIEW subscriptions.v_quota_purchases_summary IS 'Resumo de compras de cotas extras para análises financeiras';

-- =====================================================
-- VIEW: v_plan_changes_summary
-- =====================================================
-- Descrição: Resumo de mudanças de planos
-- Funcionalidade: Retorna histórico de upgrades, downgrades e renovações
-- Uso: Útil para análises de comportamento do cliente

CREATE OR REPLACE VIEW subscriptions.v_plan_changes_summary AS
SELECT 
    pc.change_id,
    pc.change_type,
    pc.change_date,
    pc.change_reason,
    pc.credits_given,
    pc.created_at,
    pc.updated_at,
    
    -- Dados da assinatura
    pc.subscription_id,
    s.establishment_id,
    s.supplier_id,
    s.start_date as subscription_start,
    s.end_date as subscription_end,
    s.status as subscription_status,
    
    -- Dados do plano anterior
    old_pl.price as old_plan_price,
    old_pn.name as old_plan_name,
    old_p.name as old_product_name,
    
    -- Dados do novo plano
    new_pl.price as new_plan_price,
    new_pn.name as new_plan_name,
    new_p.name as new_product_name,
    
    -- Dados do cliente
    COALESCE(est.name, sup.name) as client_name,
    CASE 
        WHEN s.establishment_id IS NOT NULL THEN 'establishment'
        ELSE 'supplier'
    END as client_type,
    
    -- Cálculos
    CASE 
        WHEN pc.change_type = 'upgrade' THEN new_pl.price - old_pl.price
        WHEN pc.change_type = 'downgrade' THEN old_pl.price - new_pl.price
        ELSE 0
    END as price_difference,
    
    CASE 
        WHEN pc.change_type = 'upgrade' THEN 'positive'
        WHEN pc.change_type = 'downgrade' THEN 'negative'
        ELSE 'neutral'
    END as change_impact,
    
    EXTRACT(DAY FROM (now() - pc.change_date)) as days_since_change
    
FROM subscriptions.plan_changes pc
JOIN subscriptions.subscriptions s ON pc.subscription_id = s.subscription_id
LEFT JOIN subscriptions.plans old_pl ON pc.old_plan_id = old_pl.plan_id
LEFT JOIN subscriptions.plan_names old_pn ON old_pl.plan_name_id = old_pn.plan_name_id
LEFT JOIN subscriptions.products old_p ON old_pl.product_id = old_p.product_id
JOIN subscriptions.plans new_pl ON pc.new_plan_id = new_pl.plan_id
JOIN subscriptions.plan_names new_pn ON new_pl.plan_name_id = new_pn.plan_name_id
JOIN subscriptions.products new_p ON new_pl.product_id = new_p.product_id
LEFT JOIN accounts.establishments est ON s.establishment_id = est.establishment_id
LEFT JOIN accounts.suppliers sup ON s.supplier_id = sup.supplier_id
ORDER BY pc.change_date DESC;

COMMENT ON VIEW subscriptions.v_plan_changes_summary IS 'Resumo de mudanças de planos para análises de comportamento do cliente';

-- =====================================================
-- VIEW: v_product_modules_summary
-- =====================================================
-- Descrição: Resumo de produtos e seus módulos
-- Funcionalidade: Retorna mapeamento completo de produtos para módulos
-- Uso: Útil para vendas e suporte técnico

CREATE OR REPLACE VIEW subscriptions.v_product_modules_summary AS
SELECT 
    p.product_id,
    p.name as product_name,
    p.description as product_description,
    p.billing_model,
    p.is_available_for_supplier,
    p.is_available_for_establishment,
    p.is_active as product_active,
    
    pm.product_module_id,
    
    m.module_id,
    m.name as module_name,
    m.description as module_description,
    m.is_active as module_active,
    
    -- Contagem de planos por produto
    (SELECT COUNT(*) FROM subscriptions.plans pl WHERE pl.product_id = p.product_id AND pl.is_active = true) as active_plans_count,
    
    -- Contagem de assinaturas ativas por produto
    (SELECT COUNT(*) FROM subscriptions.subscriptions s 
     JOIN subscriptions.plans pl ON s.plan_id = pl.plan_id 
     WHERE pl.product_id = p.product_id AND s.status = 'active') as active_subscriptions_count,
    
    -- Preço médio dos planos
    (SELECT ROUND(AVG(pl.price), 2) FROM subscriptions.plans pl 
     WHERE pl.product_id = p.product_id AND pl.is_active = true) as average_plan_price,
    
    -- Preço mínimo dos planos
    (SELECT MIN(pl.price) FROM subscriptions.plans pl 
     WHERE pl.product_id = p.product_id AND pl.is_active = true) as min_plan_price,
    
    -- Preço máximo dos planos
    (SELECT MAX(pl.price) FROM subscriptions.plans pl 
     WHERE pl.product_id = p.product_id AND pl.is_active = true) as max_plan_price
    
FROM subscriptions.products p
LEFT JOIN subscriptions.product_modules pm ON p.product_id = pm.product_id
LEFT JOIN accounts.modules m ON pm.module_id = m.module_id
WHERE p.is_active = true
ORDER BY p.name, m.name;

COMMENT ON VIEW subscriptions.v_product_modules_summary IS 'Resumo de produtos e seus módulos para vendas e suporte técnico';
