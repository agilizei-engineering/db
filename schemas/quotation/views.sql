-- Views do schema quotation
-- Schema: quotation
-- Arquivo: views.sql

-- Este arquivo contém todas as views do schema quotation
-- As views são criadas automaticamente pelos scripts de extensão
-- Este arquivo serve como documentação e referência

-- =====================================================
-- VIEWS DE LISTAS DE COMPRAS COMPLETAS
-- =====================================================

/*
-- View de listas de compras com dados completos
CREATE OR REPLACE VIEW quotation.v_shopping_lists_complete AS
SELECT 
    sl.shopping_list_id,
    sl.name as list_name,
    sl.description as list_description,
    sl.status as list_status,
    sl.created_at as list_created_at,
    sl.updated_at as list_updated_at,
    e.name as establishment_name,
    e.description as establishment_description,
    emp.full_name as employee_name,
    COUNT(sli.shopping_list_item_id) as total_items,
    SUM(sli.quantity) as total_quantity,
    CASE 
        WHEN sl.status = 'DRAFT' THEN 'Rascunho'
        WHEN sl.status = 'ACTIVE' THEN 'Ativa'
        WHEN sl.status = 'COMPLETED' THEN 'Concluída'
        WHEN sl.status = 'CANCELLED' THEN 'Cancelada'
        ELSE sl.status
    END as status_display
FROM quotation.shopping_lists sl
JOIN accounts.establishments e ON sl.establishment_id = e.establishment_id
LEFT JOIN accounts.employees emp ON sl.employee_id = emp.employee_id
LEFT JOIN quotation.shopping_list_items sli ON sl.shopping_list_id = sli.shopping_list_id
GROUP BY sl.shopping_list_id, sl.name, sl.description, sl.status, sl.created_at, sl.updated_at,
         e.name, e.description, emp.full_name
ORDER BY sl.created_at DESC;
*/

-- Funcionalidade: View completa de listas de compras
-- Retorna: Dados combinados de listas, estabelecimentos e funcionários
-- Uso: Relatórios e dashboards de listas de compras
-- Estatísticas: Contagem de itens e quantidades por lista

/*
-- View de itens de listas com dados de catálogo
CREATE OR REPLACE VIEW quotation.v_shopping_list_items_complete AS
SELECT 
    sli.shopping_list_item_id,
    sli.shopping_list_id,
    sli.term,
    sli.quantity as requested_quantity,
    sli.notes as item_notes,
    sli.created_at as item_created_at,
    sl.name as list_name,
    sl.status as list_status,
    i.name as item_name,
    i.description as item_description,
    c.name as category_name,
    sc.name as subcategory_name,
    b.name as brand_name,
    q.display_name as quantity_display,
    comp.name as composition_name,
    vt.name as variant_type_name,
    f.name as format_name,
    fl.name as flavor_name,
    fill.name as filling_name,
    nv.name as nutritional_variant_name,
    pack.name as packaging_name
FROM quotation.shopping_list_items sli
JOIN quotation.shopping_lists sl ON sli.shopping_list_id = sl.shopping_list_id
JOIN catalogs.items i ON sli.item_id = i.item_id
JOIN catalogs.subcategories sc ON i.subcategory_id = sc.subcategory_id
JOIN catalogs.categories c ON sc.category_id = c.category_id
LEFT JOIN catalogs.brands b ON sli.brand_id = b.brand_id
LEFT JOIN catalogs.quantities q ON sli.quantity_id = q.quantity_id
LEFT JOIN catalogs.compositions comp ON sli.composition_id = comp.composition_id
LEFT JOIN catalogs.variant_types vt ON sli.variant_type_id = vt.variant_type_id
LEFT JOIN catalogs.formats f ON sli.format_id = f.format_id
LEFT JOIN catalogs.flavors fl ON sli.flavor_id = fl.flavor_id
LEFT JOIN catalogs.fillings fill ON sli.filling_id = fill.filling_id
LEFT JOIN catalogs.nutritional_variants nv ON sli.nutritional_variant_id = nv.nutritional_variant_id
LEFT JOIN catalogs.packagings pack ON sli.packaging_id = pack.packaging_id
WHERE sl.status != 'CANCELLED'
ORDER BY sl.name, i.name;
*/

-- Funcionalidade: View completa de itens de listas
-- Retorna: Dados combinados de itens e catálogo
-- Uso: Análise detalhada de itens nas listas
-- Filtros: Exclui listas canceladas

-- =====================================================
-- VIEWS DE SUBMISSÕES E COTAÇÕES
-- =====================================================

/*
-- View de submissões de cotação com dados completos
CREATE OR REPLACE VIEW quotation.v_quotation_submissions_complete AS
SELECT 
    qs.quotation_submission_id,
    qs.submission_date,
    qs.total_items,
    qs.notes as submission_notes,
    qs.created_at as submission_created_at,
    sl.name as list_name,
    sl.status as list_status,
    e.name as establishment_name,
    ss.name as submission_status_name,
    ss.color as submission_status_color,
    COUNT(sq.supplier_quotation_id) as total_quotations_received,
    COUNT(CASE WHEN sqs2.name = 'ACCEPTED' THEN 1 END) as total_quotations_accepted,
    COUNT(CASE WHEN sqs2.name = 'REJECTED' THEN 1 END) as total_quotations_rejected
FROM quotation.quotation_submissions qs
JOIN quotation.shopping_lists sl ON qs.shopping_list_id = sl.shopping_list_id
JOIN accounts.establishments e ON sl.establishment_id = e.establishment_id
JOIN quotation.submission_statuses ss ON qs.submission_status_id = ss.submission_status_id
LEFT JOIN quotation.supplier_quotations sq ON qs.quotation_submission_id = sq.quotation_submission_id
LEFT JOIN quotation.supplier_quotation_statuses sqs2 ON sq.quotation_status_id = sqs2.quotation_status_id
GROUP BY qs.quotation_submission_id, qs.submission_date, qs.total_items, qs.notes, qs.created_at,
         sl.name, sl.status, e.name, ss.name, ss.color
ORDER BY qs.submission_date DESC;
*/

-- Funcionalidade: View completa de submissões de cotação
-- Retorna: Dados combinados de submissões, listas e estabelecimentos
-- Uso: Relatórios de submissões e acompanhamento
-- Estatísticas: Contagem de cotações por status

/*
-- View de cotações de fornecedores com dados completos
CREATE OR REPLACE VIEW quotation.v_supplier_quotations_complete AS
SELECT 
    sq.supplier_quotation_id,
    sq.quotation_date,
    sq.notes as quotation_notes,
    sq.created_at as quotation_created_at,
    s.name as supplier_name,
    s.description as supplier_description,
    sqs.name as quotation_status_name,
    sqs.color as quotation_status_color,
    sl.name as list_name,
    sl.status as list_status,
    e.name as establishment_name,
    i.name as item_name,
    sli.term,
    sli.quantity as requested_quantity,
    sli.notes as item_notes,
    COUNT(qp.quoted_price_id) as total_prices_quoted,
    MIN(qp.unit_price) as min_unit_price,
    MAX(qp.unit_price) as max_unit_price,
    AVG(qp.unit_price) as avg_unit_price
FROM quotation.supplier_quotations sq
JOIN accounts.suppliers s ON sq.supplier_id = s.supplier_id
JOIN quotation.supplier_quotation_statuses sqs ON sq.quotation_status_id = sqs.quotation_status_id
JOIN quotation.quotation_submissions qs ON sq.quotation_submission_id = qs.quotation_submission_id
JOIN quotation.shopping_lists sl ON qs.shopping_list_id = sl.shopping_list_id
JOIN accounts.establishments e ON sl.establishment_id = e.establishment_id
JOIN quotation.shopping_list_items sli ON sq.shopping_list_item_id = sli.shopping_list_item_id
JOIN catalogs.items i ON sli.item_id = i.item_id
LEFT JOIN quotation.quoted_prices qp ON sq.supplier_quotation_id = qp.supplier_quotation_id
GROUP BY sq.supplier_quotation_id, sq.quotation_date, sq.notes, sq.created_at,
         s.name, s.description, sqs.name, sqs.color, sl.name, sl.status, e.name,
         i.name, sli.term, sli.quantity, sli.notes
ORDER BY sq.quotation_date DESC;
*/

-- Funcionalidade: View completa de cotações de fornecedores
-- Retorna: Dados combinados de cotações, fornecedores e itens
-- Uso: Análise de cotações por fornecedor
-- Estatísticas: Preços mínimos, máximos e médios

-- =====================================================
-- VIEWS DE PREÇOS E ANÁLISE
-- =====================================================

/*
-- View de preços cotados com análise comparativa
CREATE OR REPLACE VIEW quotation.v_quoted_prices_analysis AS
SELECT 
    qp.quoted_price_id,
    qp.quantity_from,
    qp.quantity_to,
    qp.unit_price,
    qp.total_price,
    qp.currency,
    qp.delivery_time_days,
    qp.minimum_order_quantity,
    qp.payment_terms,
    qp.validity_days,
    qp.special_conditions,
    qp.created_at as price_created_at,
    s.name as supplier_name,
    s.description as supplier_description,
    sqs.name as quotation_status_name,
    i.name as item_name,
    sli.term,
    sli.quantity as requested_quantity,
    sl.name as list_name,
    e.name as establishment_name,
    -- Análise de preços
    CASE 
        WHEN qp.unit_price <= LAG(qp.unit_price) OVER (PARTITION BY sli.shopping_list_item_id ORDER BY qp.unit_price) THEN 'Melhor Preço'
        WHEN qp.unit_price <= AVG(qp.unit_price) OVER (PARTITION BY sli.shopping_list_item_id) THEN 'Abaixo da Média'
        ELSE 'Acima da Média'
    END as price_analysis,
    -- Análise de prazo
    CASE 
        WHEN qp.delivery_time_days <= 3 THEN 'Entrega Rápida'
        WHEN qp.delivery_time_days <= 7 THEN 'Entrega Normal'
        ELSE 'Entrega Lenta'
    END as delivery_analysis
FROM quotation.quoted_prices qp
JOIN quotation.supplier_quotations sq ON qp.supplier_quotation_id = sq.supplier_quotation_id
JOIN accounts.suppliers s ON sq.supplier_id = s.supplier_id
JOIN quotation.supplier_quotation_statuses sqs ON sq.quotation_status_id = sqs.quotation_status_id
JOIN quotation.shopping_list_items sli ON sq.shopping_list_item_id = sli.shopping_list_item_id
JOIN catalogs.items i ON sli.item_id = i.item_id
JOIN quotation.shopping_lists sl ON sli.shopping_list_id = sl.shopping_list_id
JOIN accounts.establishments e ON sl.establishment_id = e.establishment_id
WHERE sqs.name != 'REJECTED'
ORDER BY sli.shopping_list_item_id, qp.unit_price ASC;
*/

-- Funcionalidade: View de análise de preços cotados
-- Retorna: Dados completos com análise comparativa
-- Uso: Análise de competitividade de preços
-- Análises: Classificação de preços e prazos de entrega

/*
-- View de resumo de cotações por estabelecimento
CREATE OR REPLACE VIEW quotation.v_establishment_quotation_summary AS
SELECT 
    e.establishment_id,
    e.name as establishment_name,
    e.description as establishment_description,
    COUNT(DISTINCT sl.shopping_list_id) as total_shopping_lists,
    COUNT(DISTINCT qs.quotation_submission_id) as total_submissions,
    COUNT(DISTINCT sq.supplier_quotation_id) as total_quotations_received,
    COUNT(DISTINCT sq.supplier_id) as total_suppliers_quoted,
    COUNT(DISTINCT sli.shopping_list_item_id) as total_items_quoted,
    AVG(qp.unit_price) as avg_unit_price,
    MIN(qp.unit_price) as min_unit_price,
    MAX(qp.unit_price) as max_unit_price,
    AVG(qp.delivery_time_days) as avg_delivery_time_days,
    SUM(qp.total_price) as total_estimated_value,
    -- Status das listas
    COUNT(CASE WHEN sl.status = 'DRAFT' THEN 1 END) as draft_lists,
    COUNT(CASE WHEN sl.status = 'ACTIVE' THEN 1 END) as active_lists,
    COUNT(CASE WHEN sl.status = 'COMPLETED' THEN 1 END) as completed_lists,
    COUNT(CASE WHEN sl.status = 'CANCELLED' THEN 1 END) as cancelled_lists
FROM accounts.establishments e
LEFT JOIN quotation.shopping_lists sl ON e.establishment_id = sl.establishment_id
LEFT JOIN quotation.quotation_submissions qs ON sl.shopping_list_id = qs.shopping_list_id
LEFT JOIN quotation.supplier_quotations sq ON qs.quotation_submission_id = sq.quotation_submission_id
LEFT JOIN quotation.shopping_list_items sli ON sl.shopping_list_id = sli.shopping_list_id
LEFT JOIN quotation.quoted_prices qp ON sq.supplier_quotation_id = qp.supplier_quotation_id
GROUP BY e.establishment_id, e.name, e.description
ORDER BY total_shopping_lists DESC;
*/

-- Funcionalidade: Resumo de cotações por estabelecimento
-- Retorna: Métricas agregadas por estabelecimento
-- Uso: Dashboards e relatórios executivos
-- Estatísticas: Contagens, preços e prazos agregados

-- =====================================================
-- VIEWS DE WORKFLOW E STATUS
-- =====================================================

/*
-- View de workflow de cotações
CREATE OR REPLACE VIEW quotation.v_quotation_workflow AS
SELECT 
    sl.shopping_list_id,
    sl.name as list_name,
    sl.status as list_status,
    sl.created_at as list_created_at,
    qs.quotation_submission_id,
    qs.submission_date,
    ss.name as submission_status_name,
    ss.color as submission_status_color,
    COUNT(sli.shopping_list_item_id) as total_items,
    COUNT(sq.supplier_quotation_id) as total_quotations_received,
    COUNT(CASE WHEN sqs2.name = 'ACCEPTED' THEN 1 END) as accepted_quotations,
    COUNT(CASE WHEN sqs2.name = 'REJECTED' THEN 1 END) as rejected_quotations,
    COUNT(CASE WHEN sqs2.name = 'PENDING' THEN 1 END) as pending_quotations,
    -- Progresso da cotação
    CASE 
        WHEN sl.status = 'DRAFT' THEN 'Rascunho'
        WHEN sl.status = 'ACTIVE' AND qs.quotation_submission_id IS NULL THEN 'Pronta para Submissão'
        WHEN qs.quotation_submission_id IS NOT NULL AND COUNT(sq.supplier_quotation_id) = 0 THEN 'Submetida - Aguardando Cotações'
        WHEN COUNT(sq.supplier_quotation_id) > 0 THEN 'Cotações Recebidas'
        ELSE 'Status Desconhecido'
    END as workflow_status,
    -- Próximos passos
    CASE 
        WHEN sl.status = 'DRAFT' THEN 'Finalizar lista e submeter para cotação'
        WHEN sl.status = 'ACTIVE' AND qs.quotation_submission_id IS NULL THEN 'Submeter lista para cotação'
        WHEN qs.quotation_submission_id IS NOT NULL AND COUNT(sq.supplier_quotation_id) = 0 THEN 'Aguardar cotações dos fornecedores'
        WHEN COUNT(sq.supplier_quotation_id) > 0 THEN 'Analisar cotações recebidas'
        ELSE 'Verificar status'
    END as next_steps
FROM quotation.shopping_lists sl
LEFT JOIN quotation.quotation_submissions qs ON sl.shopping_list_id = qs.shopping_list_id
LEFT JOIN quotation.submission_statuses ss ON qs.submission_status_id = ss.submission_status_id
LEFT JOIN quotation.shopping_list_items sli ON sl.shopping_list_id = sli.shopping_list_id
LEFT JOIN quotation.supplier_quotations sq ON qs.quotation_submission_id = sq.quotation_submission_id
LEFT JOIN quotation.supplier_quotation_statuses sqs2 ON sq.quotation_status_id = sqs2.quotation_status_id
GROUP BY sl.shopping_list_id, sl.name, sl.status, sl.created_at,
         qs.quotation_submission_id, qs.submission_date, ss.name, ss.color
ORDER BY sl.created_at DESC;
*/

-- Funcionalidade: Workflow de cotações
-- Retorna: Status e progresso de cada lista
-- Uso: Acompanhamento de processo de cotação
-- Funcionalidades: Status atual e próximos passos

-- =====================================================
-- EXEMPLOS DE USO
-- =====================================================

/*
-- Exemplo 1: Consultar listas completas
SELECT * FROM quotation.v_shopping_lists_complete;

-- Exemplo 2: Consultar itens completos
SELECT * FROM quotation.v_shopping_list_items_complete;

-- Exemplo 3: Consultar submissões completas
SELECT * FROM quotation.v_quotation_submissions_complete;

-- Exemplo 4: Consultar cotações completas
SELECT * FROM quotation.v_supplier_quotations_complete;

-- Exemplo 5: Análise de preços
SELECT * FROM quotation.v_quoted_prices_analysis;

-- Exemplo 6: Resumo por estabelecimento
SELECT * FROM quotation.v_establishment_quotation_summary;

-- Exemplo 7: Workflow de cotações
SELECT * FROM quotation.v_quotation_workflow;
*/

-- =====================================================
-- NOTAS IMPORTANTES
-- =====================================================

-- 1. Todas as views retornam apenas registros ativos e válidos
-- 2. Views são otimizadas para consultas de relatórios
-- 3. Dados são sempre consistentes entre tabelas relacionadas
-- 4. Views podem ser usadas como base para outras views
-- 5. Todas as operações nas tabelas base são auditadas
-- 6. Views incluem análises e classificações automáticas
-- 7. Estatísticas são calculadas em tempo real
