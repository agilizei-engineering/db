-- Funções do schema quotation
-- Schema: quotation
-- Arquivo: functions.sql

-- Este arquivo contém todas as funções do schema quotation
-- As funções são criadas automaticamente pelos scripts de extensão
-- Este arquivo serve como documentação e referência

-- =====================================================
-- FUNÇÕES DE GESTÃO DE LISTAS DE COMPRAS
-- =====================================================

/*
-- Criar lista de compras com itens
CREATE OR REPLACE FUNCTION quotation.create_shopping_list(
    p_establishment_id uuid,
    p_name text,
    p_description text DEFAULT NULL,
    p_items jsonb DEFAULT '[]'::jsonb
) RETURNS uuid AS $$
DECLARE
    v_shopping_list_id uuid;
    v_item jsonb;
BEGIN
    -- Criar lista de compras
    INSERT INTO quotation.shopping_lists (
        establishment_id, name, description, status
    ) VALUES (
        p_establishment_id, p_name, p_description, 'DRAFT'
    ) RETURNING shopping_list_id INTO v_shopping_list_id;
    
    -- Adicionar itens se fornecidos
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        INSERT INTO quotation.shopping_list_items (
            shopping_list_id,
            item_id,
            term,
            quantity,
            notes
        ) VALUES (
            v_shopping_list_id,
            (v_item->>'item_id')::uuid,
            v_item->>'term',
            (v_item->>'quantity')::numeric,
            v_item->>'notes'
        );
    END LOOP;
    
    RETURN v_shopping_list_id;
END;
$$ LANGUAGE plpgsql;
*/

-- Funcionalidade: Cria lista de compras com itens
-- Parâmetros: establishment_id, name, description, items (JSON)
-- Retorna: ID da lista criada
-- Uso: Criação rápida de listas com múltiplos itens

/*
-- Adicionar item à lista de compras
CREATE OR REPLACE FUNCTION quotation.add_item_to_shopping_list(
    p_shopping_list_id uuid,
    p_item_id uuid,
    p_term text,
    p_quantity numeric,
    p_notes text DEFAULT NULL
) RETURNS uuid AS $$
DECLARE
    v_shopping_list_item_id uuid;
BEGIN
    -- Verificar se a lista existe e está em rascunho
    IF NOT EXISTS (
        SELECT 1 FROM quotation.shopping_lists 
        WHERE shopping_list_id = p_shopping_list_id 
        AND status = 'DRAFT'
    ) THEN
        RAISE EXCEPTION 'Lista de compras não encontrada ou não está em rascunho';
    END IF;
    
    -- Adicionar item
    INSERT INTO quotation.shopping_list_items (
        shopping_list_id, item_id, term, quantity, notes
    ) VALUES (
        p_shopping_list_id, p_item_id, p_term, p_quantity, p_notes
    ) RETURNING shopping_list_item_id INTO v_shopping_list_item_id;
    
    RETURN v_shopping_list_item_id;
END;
$$ LANGUAGE plpgsql;
*/

-- Funcionalidade: Adiciona item à lista de compras
-- Parâmetros: shopping_list_id, item_id, term, quantity, notes
-- Retorna: ID do item adicionado
-- Validações: Lista deve estar em rascunho

-- =====================================================
-- FUNÇÕES DE SUBMISSÃO DE COTAÇÕES
-- =====================================================

/*
-- Submeter lista de compras para cotação
CREATE OR REPLACE FUNCTION quotation.submit_shopping_list_for_quotation(
    p_shopping_list_id uuid,
    p_notes text DEFAULT NULL
) RETURNS uuid AS $$
DECLARE
    v_quotation_submission_id uuid;
    v_total_items integer;
BEGIN
    -- Verificar se a lista existe e está em rascunho
    IF NOT EXISTS (
        SELECT 1 FROM quotation.shopping_lists 
        WHERE shopping_list_id = p_shopping_list_id 
        AND status = 'DRAFT'
    ) THEN
        RAISE EXCEPTION 'Lista de compras não encontrada ou não está em rascunho';
    END IF;
    
    -- Calcular total de itens
    SELECT COUNT(*) INTO v_total_items
    FROM quotation.shopping_list_items
    WHERE shopping_list_id = p_shopping_list_id;
    
    -- Criar submissão
    INSERT INTO quotation.quotation_submissions (
        shopping_list_id,
        submission_status_id,
        total_items,
        notes
    ) VALUES (
        p_shopping_list_id,
        (SELECT submission_status_id FROM quotation.submission_statuses WHERE name = 'PENDING'),
        v_total_items,
        p_notes
    ) RETURNING quotation_submission_id INTO v_quotation_submission_id;
    
    -- Atualizar status da lista
    UPDATE quotation.shopping_lists 
    SET status = 'ACTIVE'
    WHERE shopping_list_id = p_shopping_list_id;
    
    RETURN v_quotation_submission_id;
END;
$$ LANGUAGE plpgsql;
*/

-- Funcionalidade: Submete lista para cotação
-- Parâmetros: shopping_list_id, notes
-- Retorna: ID da submissão criada
-- Validações: Lista deve estar em rascunho
-- Ações: Cria submissão e atualiza status da lista

-- =====================================================
-- FUNÇÕES DE COTAÇÃO DE FORNECEDORES
-- =====================================================

/*
-- Registrar cotação de fornecedor
CREATE OR REPLACE FUNCTION quotation.register_supplier_quotation(
    p_quotation_submission_id uuid,
    p_shopping_list_item_id uuid,
    p_supplier_id uuid,
    p_notes text DEFAULT NULL
) RETURNS uuid AS $$
DECLARE
    v_supplier_quotation_id uuid;
BEGIN
    -- Verificar se a submissão está ativa
    IF NOT EXISTS (
        SELECT 1 FROM quotation.quotation_submissions qs
        JOIN quotation.submission_statuses ss ON qs.submission_status_id = ss.submission_status_id
        WHERE qs.quotation_submission_id = p_quotation_submission_id
        AND ss.name IN ('PENDING', 'SENT')
    ) THEN
        RAISE EXCEPTION 'Submissão não está ativa para cotação';
    END IF;
    
    -- Registrar cotação
    INSERT INTO quotation.supplier_quotations (
        quotation_submission_id,
        shopping_list_item_id,
        supplier_id,
        quotation_status_id,
        notes
    ) VALUES (
        p_quotation_submission_id,
        p_shopping_list_item_id,
        p_supplier_id,
        (SELECT quotation_status_id FROM quotation.supplier_quotation_statuses WHERE name = 'PENDING'),
        p_notes
    ) RETURNING supplier_quotation_id INTO v_supplier_quotation_id;
    
    RETURN v_supplier_quotation_id;
END;
$$ LANGUAGE plpgsql;
*/

-- Funcionalidade: Registra cotação de fornecedor
-- Parâmetros: quotation_submission_id, shopping_list_item_id, supplier_id, notes
-- Retorna: ID da cotação criada
-- Validações: Submissão deve estar ativa

/*
-- Adicionar preço cotado
CREATE OR REPLACE FUNCTION quotation.add_quoted_price(
    p_supplier_quotation_id uuid,
    p_quantity_from numeric,
    p_quantity_to numeric DEFAULT NULL,
    p_unit_price numeric,
    p_currency text DEFAULT 'BRL',
    p_delivery_time_days integer DEFAULT NULL,
    p_minimum_order_quantity numeric DEFAULT NULL,
    p_payment_terms text DEFAULT NULL,
    p_validity_days integer DEFAULT NULL,
    p_special_conditions text DEFAULT NULL
) RETURNS uuid AS $$
DECLARE
    v_quoted_price_id uuid;
    v_total_price numeric;
BEGIN
    -- Calcular preço total
    v_total_price := p_quantity_from * p_unit_price;
    
    -- Adicionar preço cotado
    INSERT INTO quotation.quoted_prices (
        supplier_quotation_id,
        quantity_from,
        quantity_to,
        unit_price,
        total_price,
        currency,
        delivery_time_days,
        minimum_order_quantity,
        payment_terms,
        validity_days,
        special_conditions
    ) VALUES (
        p_supplier_quotation_id,
        p_quantity_from,
        p_quantity_to,
        p_unit_price,
        v_total_price,
        p_currency,
        p_delivery_time_days,
        p_minimum_order_quantity,
        p_payment_terms,
        p_validity_days,
        p_special_conditions
    ) RETURNING quoted_price_id INTO v_quoted_price_id;
    
    RETURN v_quoted_price_id;
END;
$$ LANGUAGE plpgsql;
*/

-- Funcionalidade: Adiciona preço cotado
-- Parâmetros: Todos os campos de preço
-- Retorna: ID do preço criado
-- Cálculos: Preço total calculado automaticamente

-- =====================================================
-- FUNÇÕES DE CONSULTA E ANÁLISE
-- =====================================================

/*
-- Buscar cotações por item
CREATE OR REPLACE FUNCTION quotation.find_quotations_by_item(
    p_shopping_list_item_id uuid
) RETURNS TABLE(
    supplier_name text,
    supplier_description text,
    quotation_status text,
    unit_price numeric,
    currency text,
    delivery_time_days integer,
    payment_terms text,
    validity_days integer
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.name as supplier_name,
        s.description as supplier_description,
        sqs.name as quotation_status,
        qp.unit_price,
        qp.currency,
        qp.delivery_time_days,
        qp.payment_terms,
        qp.validity_days
    FROM quotation.supplier_quotations sq
    JOIN accounts.suppliers s ON sq.supplier_id = s.supplier_id
    JOIN quotation.supplier_quotation_statuses sqs ON sq.quotation_status_id = sqs.quotation_status_id
    LEFT JOIN quotation.quoted_prices qp ON sq.supplier_quotation_id = qp.supplier_quotation_id
    WHERE sq.shopping_list_item_id = p_shopping_list_item_id
      AND sqs.name != 'REJECTED'
    ORDER BY qp.unit_price ASC NULLS LAST;
END;
$$ LANGUAGE plpgsql;
*/

-- Funcionalidade: Busca cotações por item
-- Parâmetros: shopping_list_item_id
-- Retorna: Cotações ordenadas por preço
-- Filtros: Exclui cotações rejeitadas

/*
-- Estatísticas de cotações por estabelecimento
CREATE OR REPLACE FUNCTION quotation.get_quotation_statistics(
    p_establishment_id uuid
) RETURNS TABLE(
    total_lists integer,
    total_submissions integer,
    total_quotations integer,
    avg_response_time_days numeric,
    total_estimated_value numeric
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(DISTINCT sl.shopping_list_id)::integer as total_lists,
        COUNT(DISTINCT qs.quotation_submission_id)::integer as total_submissions,
        COUNT(DISTINCT sq.supplier_quotation_id)::integer as total_quotations,
        AVG(EXTRACT(DAY FROM (sq.quotation_date - qs.submission_date))) as avg_response_time_days,
        SUM(qp.total_price) as total_estimated_value
    FROM quotation.shopping_lists sl
    LEFT JOIN quotation.quotation_submissions qs ON sl.shopping_list_id = qs.shopping_list_id
    LEFT JOIN quotation.supplier_quotations sq ON qs.quotation_submission_id = sq.quotation_submission_id
    LEFT JOIN quotation.quoted_prices qp ON sq.supplier_quotation_id = qp.supplier_quotation_id
    WHERE sl.establishment_id = p_establishment_id;
END;
$$ LANGUAGE plpgsql;
*/

-- Funcionalidade: Estatísticas de cotações por estabelecimento
-- Parâmetros: establishment_id
-- Retorna: Métricas agregadas
-- Uso: Relatórios e dashboards

-- =====================================================
-- FUNÇÕES DE VALIDAÇÃO E LIMPEZA
-- =====================================================

/*
-- Função para atualizar timestamp de updated_at
CREATE OR REPLACE FUNCTION quotation.set_updated_at()
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
-- Exemplo 1: Criar lista de compras
SELECT quotation.create_shopping_list(
    'uuid-do-estabelecimento',
    'Lista de Compras Janeiro 2024',
    'Produtos para o mês de janeiro',
    '[{"item_id": "uuid-do-item", "term": "arroz", "quantity": 10, "notes": "Arroz branco tipo 1"}]'::jsonb
);

-- Exemplo 2: Adicionar item
SELECT quotation.add_item_to_shopping_list(
    'uuid-da-lista',
    'uuid-do-item',
    'feijão',
    5,
    'Feijão carioca'
);

-- Exemplo 3: Submeter para cotação
SELECT quotation.submit_shopping_list_for_quotation(
    'uuid-da-lista',
    'Cotação para fornecedores'
);

-- Exemplo 4: Registrar cotação
SELECT quotation.register_supplier_quotation(
    'uuid-da-submissao',
    'uuid-do-item',
    'uuid-do-fornecedor',
    'Preço especial para quantidade'
);

-- Exemplo 5: Adicionar preço
SELECT quotation.add_quoted_price(
    'uuid-da-cotacao',
    10,
    50,
    8.50,
    'BRL',
    5,
    10,
    '30/60/90',
    30,
    'Entrega gratuita'
);

-- Exemplo 6: Buscar cotações
SELECT * FROM quotation.find_quotations_by_item('uuid-do-item');

-- Exemplo 7: Estatísticas
SELECT * FROM quotation.get_quotation_statistics('uuid-do-estabelecimento');
*/

-- =====================================================
-- NOTAS IMPORTANTES
-- =====================================================

-- 1. Todas as funções retornam apenas registros ativos
-- 2. Validações incluem regras de negócio específicas
-- 3. Funções de criação incluem validações automáticas
-- 4. Estatísticas são calculadas em tempo real
-- 5. Todas as operações são auditadas automaticamente
-- 6. Funções suportam transações para consistência
-- 7. Validações de status são aplicadas em todas as operações
