-- Funções do schema catalogs
-- Schema: catalogs
-- Arquivo: functions.sql

-- Este arquivo contém todas as funções do schema catalogs
-- As funções são criadas automaticamente pelos scripts de extensão
-- Este arquivo serve como documentação e referência

-- =====================================================
-- FUNÇÕES DE BUSCA DE PRODUTOS
-- =====================================================

/*
-- Buscar produtos por categoria
CREATE OR REPLACE FUNCTION catalogs.find_products_by_category(p_category_name text)
RETURNS TABLE(
    product_id uuid,
    product_name text,
    brand_name text,
    category_name text,
    subcategory_name text,
    price numeric,
    supplier_name text
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.product_id,
        i.name as product_name,
        b.name as brand_name,
        c.name as category_name,
        sc.name as subcategory_name,
        o.price,
        s.name as supplier_name
    FROM catalogs.products p
    JOIN catalogs.items i ON p.item_id = i.item_id
    JOIN catalogs.subcategories sc ON i.subcategory_id = sc.subcategory_id
    JOIN catalogs.categories c ON sc.category_id = c.category_id
    LEFT JOIN catalogs.brands b ON p.brand_id = b.brand_id
    LEFT JOIN catalogs.offers o ON p.product_id = o.product_id AND o.is_active = true
    LEFT JOIN accounts.suppliers s ON o.supplier_id = s.supplier_id
    WHERE c.name ILIKE '%' || p_category_name || '%'
      AND p.visibility = 'PUBLIC'
      AND p.is_active = true
      AND c.is_active = true
      AND sc.is_active = true
    ORDER BY i.name, b.name;
END;
$$ LANGUAGE plpgsql;
*/

-- Funcionalidade: Busca produtos por categoria
-- Parâmetros: p_category_name (text) - Nome da categoria
-- Retorna: Produtos da categoria com preços e fornecedores
-- Filtros: Apenas produtos públicos e ativos

/*
-- Buscar produtos por marca
CREATE OR REPLACE FUNCTION catalogs.find_products_by_brand(p_brand_name text)
RETURNS TABLE(
    product_id uuid,
    product_name text,
    brand_name text,
    category_name text,
    subcategory_name text,
    price numeric,
    supplier_name text
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.product_id,
        i.name as product_name,
        b.name as brand_name,
        c.name as category_name,
        sc.name as subcategory_name,
        o.price,
        s.name as supplier_name
    FROM catalogs.products p
    JOIN catalogs.items i ON p.item_id = i.item_id
    JOIN catalogs.subcategories sc ON i.subcategory_id = sc.subcategory_id
    JOIN catalogs.categories c ON sc.category_id = c.category_id
    JOIN catalogs.brands b ON p.brand_id = b.brand_id
    LEFT JOIN catalogs.offers o ON p.product_id = o.product_id AND o.is_active = true
    LEFT JOIN accounts.suppliers s ON o.supplier_id = s.supplier_id
    WHERE b.name ILIKE '%' || p_brand_name || '%'
      AND p.visibility = 'PUBLIC'
      AND p.is_active = true
      AND b.is_active = true
    ORDER BY i.name, c.name;
END;
$$ LANGUAGE plpgsql;
*/

-- Funcionalidade: Busca produtos por marca
-- Parâmetros: p_brand_name (text) - Nome da marca
-- Retorna: Produtos da marca com categorias e preços
-- Filtros: Apenas produtos públicos e ativos

/*
-- Busca fuzzy de produtos por nome
CREATE OR REPLACE FUNCTION catalogs.search_products_by_name(p_search_term text)
RETURNS TABLE(
    product_id uuid,
    product_name text,
    brand_name text,
    category_name text,
    subcategory_name text,
    price numeric,
    supplier_name text,
    relevance numeric
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.product_id,
        i.name as product_name,
        b.name as brand_name,
        c.name as category_name,
        sc.name as subcategory_name,
        o.price,
        s.name as supplier_name,
        CASE 
            WHEN i.name ILIKE p_search_term THEN 1.0
            WHEN i.name ILIKE p_search_term || '%' THEN 0.8
            WHEN i.name ILIKE '%' || p_search_term || '%' THEN 0.6
            WHEN i.name % p_search_term THEN 0.4
            ELSE 0.2
        END as relevance
    FROM catalogs.products p
    JOIN catalogs.items i ON p.item_id = i.item_id
    JOIN catalogs.subcategories sc ON i.subcategory_id = sc.subcategory_id
    JOIN catalogs.categories c ON sc.category_id = c.category_id
    LEFT JOIN catalogs.brands b ON p.brand_id = b.brand_id
    LEFT JOIN catalogs.offers o ON p.product_id = o.product_id AND o.is_active = true
    LEFT JOIN accounts.suppliers s ON o.supplier_id = s.supplier_id
    WHERE p.visibility = 'PUBLIC'
      AND p.is_active = true
      AND (
          i.name ILIKE '%' || p_search_term || '%'
          OR i.name % p_search_term
          OR b.name ILIKE '%' || p_search_term || '%'
      )
    ORDER BY relevance DESC, i.name;
END;
$$ LANGUAGE plpgsql;
*/

-- Funcionalidade: Busca fuzzy de produtos por nome
-- Parâmetros: p_search_term (text) - Termo de busca
-- Retorna: Produtos com relevância calculada
-- Busca: Suporta busca parcial e fuzzy (se pg_trgm disponível)

-- =====================================================
-- FUNÇÕES DE COMPARAÇÃO DE PREÇOS
-- =====================================================

/*
-- Comparar preços de um produto entre fornecedores
CREATE OR REPLACE FUNCTION catalogs.compare_product_prices(p_product_id uuid)
RETURNS TABLE(
    supplier_name text,
    price numeric,
    available_from timestamp with time zone,
    available_until timestamp with time zone,
    offer_age_days integer
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.name as supplier_name,
        o.price,
        o.available_from,
        o.available_until,
        EXTRACT(DAY FROM (now() - o.created_at))::integer as offer_age_days
    FROM catalogs.offers o
    JOIN accounts.suppliers s ON o.supplier_id = s.supplier_id
    WHERE o.product_id = p_product_id
      AND o.is_active = true
      AND s.is_active = true
    ORDER BY o.price ASC;
END;
$$ LANGUAGE plpgsql;
*/

-- Funcionalidade: Compara preços de um produto entre fornecedores
-- Parâmetros: p_product_id (uuid) - ID do produto
-- Retorna: Lista de preços ordenados por valor
-- Filtros: Apenas ofertas e fornecedores ativos

-- =====================================================
-- FUNÇÕES DE ESTATÍSTICAS
-- =====================================================

/*
-- Estatísticas de produtos por categoria
CREATE OR REPLACE FUNCTION catalogs.get_category_statistics()
RETURNS TABLE(
    category_name text,
    total_products integer,
    total_brands integer,
    avg_price numeric,
    min_price numeric,
    max_price numeric
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.name as category_name,
        COUNT(DISTINCT p.product_id)::integer as total_products,
        COUNT(DISTINCT p.brand_id)::integer as total_brands,
        AVG(o.price) as avg_price,
        MIN(o.price) as min_price,
        MAX(o.price) as max_price
    FROM catalogs.categories c
    JOIN catalogs.subcategories sc ON c.category_id = sc.category_id
    JOIN catalogs.items i ON sc.subcategory_id = i.subcategory_id
    JOIN catalogs.products p ON i.item_id = p.item_id
    LEFT JOIN catalogs.offers o ON p.product_id = o.product_id AND o.is_active = true
    WHERE c.is_active = true
      AND sc.is_active = true
      AND i.is_active = true
      AND p.visibility = 'PUBLIC'
      AND p.is_active = true
    GROUP BY c.category_id, c.name
    ORDER BY total_products DESC;
END;
$$ LANGUAGE plpgsql;
*/

-- Funcionalidade: Estatísticas de produtos por categoria
-- Retorna: Contagens e preços agregados por categoria
-- Uso: Relatórios e dashboards
-- Filtros: Apenas registros ativos e públicos

-- =====================================================
-- FUNÇÕES DE VALIDAÇÃO E LIMPEZA
-- =====================================================

/*
-- Função para atualizar timestamp de updated_at
CREATE OR REPLACE FUNCTION catalogs.set_updated_at()
RETURNS trigger AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
*/

-- Funcionalidade: Atualiza automaticamente o campo updated_at
-- Uso: Trigger para manter timestamps atualizados
-- Aplicação: Todas as tabelas com campo updated_at

-- =====================================================
-- EXEMPLOS DE USO
-- =====================================================

/*
-- Exemplo 1: Buscar produtos por categoria
SELECT * FROM catalogs.find_products_by_category('Massas');

-- Exemplo 2: Buscar produtos por marca
SELECT * FROM catalogs.find_products_by_brand('Barilla');

-- Exemplo 3: Busca fuzzy por nome
SELECT * FROM catalogs.search_products_by_name('espaguete');

-- Exemplo 4: Comparar preços
SELECT * FROM catalogs.compare_product_prices('uuid-do-produto');

-- Exemplo 5: Estatísticas por categoria
SELECT * FROM catalogs.get_category_statistics();
*/

-- =====================================================
-- NOTAS IMPORTANTES
-- =====================================================

-- 1. Todas as funções retornam apenas produtos públicos e ativos
-- 2. Busca fuzzy requer extensão pg_trgm (opcional)
-- 3. Funções de preço consideram apenas ofertas ativas
-- 4. Estatísticas são calculadas em tempo real
-- 5. Todas as operações são auditadas automaticamente
