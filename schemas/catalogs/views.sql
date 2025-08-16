-- Views do schema catalogs
-- Schema: catalogs
-- Arquivo: views.sql

-- Este arquivo contém todas as views do schema catalogs
-- As views são criadas automaticamente pelos scripts de extensão
-- Este arquivo serve como documentação e referência

-- =====================================================
-- VIEWS DE PRODUTOS COMPLETOS
-- =====================================================

/*
-- View de produtos com dados completos
CREATE OR REPLACE VIEW catalogs.v_products_complete AS
SELECT 
    p.product_id,
    p.visibility,
    p.is_active,
    p.created_at,
    p.updated_at,
    i.name as item_name,
    i.description as item_description,
    c.name as category_name,
    c.description as category_description,
    sc.name as subcategory_name,
    sc.description as subcategory_description,
    b.name as brand_name,
    b.description as brand_description,
    b.logo_url as brand_logo,
    b.website_url as brand_website,
    comp.name as composition_name,
    comp.description as composition_description,
    vt.name as variant_type_name,
    vt.description as variant_type_description,
    f.name as format_name,
    f.description as format_description,
    fl.name as flavor_name,
    fl.description as flavor_description,
    fill.name as filling_name,
    fill.description as filling_description,
    nv.name as nutritional_variant_name,
    nv.description as nutritional_variant_description,
    pack.name as packaging_name,
    pack.description as packaging_description,
    q.unit as quantity_unit,
    q.value as quantity_value,
    q.display_name as quantity_display
FROM catalogs.products p
JOIN catalogs.items i ON p.item_id = i.item_id
JOIN catalogs.subcategories sc ON i.subcategory_id = sc.subcategory_id
JOIN catalogs.categories c ON sc.category_id = c.category_id
LEFT JOIN catalogs.brands b ON p.brand_id = b.brand_id
LEFT JOIN catalogs.compositions comp ON p.composition_id = comp.composition_id
LEFT JOIN catalogs.variant_types vt ON p.variant_type_id = vt.variant_type_id
LEFT JOIN catalogs.formats f ON p.format_id = f.format_id
LEFT JOIN catalogs.flavors fl ON p.flavor_id = fl.flavor_id
LEFT JOIN catalogs.fillings fill ON p.filling_id = fill.filling_id
LEFT JOIN catalogs.nutritional_variants nv ON p.nutritional_variant_id = nv.nutritional_variant_id
LEFT JOIN catalogs.packagings pack ON p.packaging_id = pack.packaging_id
LEFT JOIN catalogs.quantities q ON p.quantity_id = q.quantity_id
WHERE p.visibility = 'PUBLIC'
  AND p.is_active = true
  AND i.is_active = true
  AND sc.is_active = true
  AND c.is_active = true;
*/

-- Funcionalidade: View completa de produtos
-- Retorna: Dados combinados de todas as tabelas relacionadas
-- Uso: Ideal para relatórios e dashboards
-- Filtros: Apenas produtos públicos e ativos

/*
-- View de produtos com preços ativos
CREATE OR REPLACE VIEW catalogs.v_products_with_prices AS
SELECT 
    p.product_id,
    i.name as item_name,
    c.name as category_name,
    sc.name as subcategory_name,
    b.name as brand_name,
    q.display_name as quantity_display,
    o.price,
    o.available_from,
    o.available_until,
    s.name as supplier_name,
    s.description as supplier_description
FROM catalogs.products p
JOIN catalogs.items i ON p.item_id = i.item_id
JOIN catalogs.subcategories sc ON i.subcategory_id = sc.subcategory_id
JOIN catalogs.categories c ON sc.category_id = c.category_id
LEFT JOIN catalogs.brands b ON p.brand_id = b.brand_id
LEFT JOIN catalogs.quantities q ON p.quantity_id = q.quantity_id
JOIN catalogs.offers o ON p.product_id = o.product_id
JOIN accounts.suppliers s ON o.supplier_id = s.supplier_id
WHERE p.visibility = 'PUBLIC'
  AND p.is_active = true
  AND o.is_active = true
  AND s.is_active = true
  AND (o.available_until IS NULL OR o.available_until > now());
*/

-- Funcionalidade: View de produtos com preços ativos
-- Retorna: Produtos com ofertas válidas
-- Uso: Catálogo de produtos com preços
-- Filtros: Apenas ofertas ativas e válidas

-- =====================================================
-- VIEWS DE HIERARQUIA
-- =====================================================

/*
-- View de hierarquia de categorias
CREATE OR REPLACE VIEW catalogs.v_categories_hierarchy AS
SELECT 
    c.category_id,
    c.name as category_name,
    c.description as category_description,
    c.is_active as category_active,
    c.created_at as category_created_at,
    sc.subcategory_id,
    sc.name as subcategory_name,
    sc.description as subcategory_description,
    sc.is_active as subcategory_active,
    sc.created_at as subcategory_created_at,
    COUNT(DISTINCT i.item_id) as total_items,
    COUNT(DISTINCT p.product_id) as total_products
FROM catalogs.categories c
JOIN catalogs.subcategories sc ON c.category_id = sc.category_id
LEFT JOIN catalogs.items i ON sc.subcategory_id = i.subcategory_id AND i.is_active = true
LEFT JOIN catalogs.products p ON i.item_id = p.item_id AND p.visibility = 'PUBLIC' AND p.is_active = true
WHERE c.is_active = true
  AND sc.is_active = true
GROUP BY c.category_id, c.name, c.description, c.is_active, c.created_at,
         sc.subcategory_id, sc.name, sc.description, sc.is_active, sc.created_at
ORDER BY c.name, sc.name;
*/

-- Funcionalidade: View de hierarquia de categorias
-- Retorna: Estrutura hierárquica com estatísticas
-- Uso: Navegação e relatórios organizacionais
-- Estatísticas: Contagem de itens e produtos por nível

-- =====================================================
-- VIEWS DE ESTATÍSTICAS
-- =====================================================

/*
-- View de estatísticas de marcas
CREATE OR REPLACE VIEW catalogs.v_brand_statistics AS
SELECT 
    b.brand_id,
    b.name as brand_name,
    b.description as brand_description,
    COUNT(DISTINCT p.product_id) as total_products,
    COUNT(DISTINCT c.category_id) as total_categories,
    AVG(o.price) as avg_price,
    MIN(o.price) as min_price,
    MAX(o.price) as max_price,
    COUNT(DISTINCT o.supplier_id) as total_suppliers
FROM catalogs.brands b
LEFT JOIN catalogs.products p ON b.brand_id = p.brand_id AND p.visibility = 'PUBLIC' AND p.is_active = true
LEFT JOIN catalogs.items i ON p.item_id = i.item_id AND i.is_active = true
LEFT JOIN catalogs.subcategories sc ON i.subcategory_id = sc.subcategory_id AND sc.is_active = true
LEFT JOIN catalogs.categories c ON sc.category_id = c.category_id AND c.is_active = true
LEFT JOIN catalogs.offers o ON p.product_id = o.product_id AND o.is_active = true
WHERE b.is_active = true
GROUP BY b.brand_id, b.name, b.description
ORDER BY total_products DESC;
*/

-- Funcionalidade: View de estatísticas de marcas
-- Retorna: Métricas agregadas por marca
-- Uso: Relatórios de performance de marcas
-- Estatísticas: Produtos, categorias, preços e fornecedores

/*
-- View de produtos mais ofertados
CREATE OR REPLACE VIEW catalogs.v_most_offered_products AS
SELECT 
    p.product_id,
    i.name as item_name,
    b.name as brand_name,
    c.name as category_name,
    COUNT(o.offer_id) as total_offers,
    AVG(o.price) as avg_price,
    MIN(o.price) as min_price,
    MAX(o.price) as max_price,
    COUNT(DISTINCT o.supplier_id) as total_suppliers
FROM catalogs.products p
JOIN catalogs.items i ON p.item_id = i.item_id
JOIN catalogs.subcategories sc ON i.subcategory_id = sc.subcategory_id
JOIN catalogs.categories c ON sc.category_id = c.category_id
LEFT JOIN catalogs.brands b ON p.brand_id = b.brand_id
JOIN catalogs.offers o ON p.product_id = o.product_id
WHERE p.visibility = 'PUBLIC'
  AND p.is_active = true
  AND o.is_active = true
  AND (o.available_until IS NULL OR o.available_until > now())
GROUP BY p.product_id, i.name, b.name, c.name
HAVING COUNT(o.offer_id) > 1
ORDER BY total_offers DESC, avg_price ASC;
*/

-- Funcionalidade: View de produtos mais ofertados
-- Retorna: Produtos com múltiplas ofertas
-- Uso: Análise de competitividade de preços
-- Filtros: Apenas produtos com mais de uma oferta

-- =====================================================
-- VIEWS DE BUSCA E FILTROS
-- =====================================================

/*
-- View de produtos por faixa de preço
CREATE OR REPLACE VIEW catalogs.v_products_by_price_range AS
SELECT 
    CASE 
        WHEN o.price < 10 THEN 'Até R$ 10,00'
        WHEN o.price < 25 THEN 'R$ 10,00 a R$ 25,00'
        WHEN o.price < 50 THEN 'R$ 25,00 a R$ 50,00'
        WHEN o.price < 100 THEN 'R$ 50,00 a R$ 100,00'
        ELSE 'Acima de R$ 100,00'
    END as price_range,
    COUNT(DISTINCT p.product_id) as total_products,
    COUNT(DISTINCT b.brand_id) as total_brands,
    COUNT(DISTINCT c.category_id) as total_categories,
    AVG(o.price) as avg_price
FROM catalogs.products p
JOIN catalogs.items i ON p.item_id = i.item_id
JOIN catalogs.subcategories sc ON i.subcategory_id = sc.subcategory_id
JOIN catalogs.categories c ON sc.category_id = c.category_id
LEFT JOIN catalogs.brands b ON p.brand_id = b.brand_id
JOIN catalogs.offers o ON p.product_id = o.product_id
WHERE p.visibility = 'PUBLIC'
  AND p.is_active = true
  AND o.is_active = true
  AND (o.available_until IS NULL OR o.available_until > now())
GROUP BY price_range
ORDER BY avg_price;
*/

-- Funcionalidade: View de produtos por faixa de preço
-- Retorna: Agrupamento por faixas de preço
-- Uso: Análise de distribuição de preços
-- Categorização: Faixas predefinidas de preço

-- =====================================================
-- EXEMPLOS DE USO
-- =====================================================

/*
-- Exemplo 1: Consultar produtos completos
SELECT * FROM catalogs.v_products_complete;

-- Exemplo 2: Consultar produtos com preços
SELECT * FROM catalogs.v_products_with_prices;

-- Exemplo 3: Consultar hierarquia de categorias
SELECT * FROM catalogs.v_categories_hierarchy;

-- Exemplo 4: Consultar estatísticas de marcas
SELECT * FROM catalogs.v_brand_statistics;

-- Exemplo 5: Consultar produtos mais ofertados
SELECT * FROM catalogs.v_most_offered_products;

-- Exemplo 6: Consultar produtos por faixa de preço
SELECT * FROM catalogs.v_products_by_price_range;
*/

-- =====================================================
-- NOTAS IMPORTANTES
-- =====================================================

-- 1. Todas as views retornam apenas registros ativos e públicos
-- 2. Views são otimizadas para consultas de relatórios
-- 3. Dados são sempre consistentes entre tabelas relacionadas
-- 4. Views podem ser usadas como base para outras views
-- 5. Todas as operações nas tabelas base são auditadas
