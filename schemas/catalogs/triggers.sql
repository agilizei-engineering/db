-- Triggers do schema catalogs
-- Schema: catalogs
-- Arquivo: triggers.sql

-- Este arquivo contém todos os triggers do schema catalogs
-- Os triggers são criados automaticamente pelos scripts de extensão
-- Este arquivo serve como documentação e referência

-- =====================================================
-- TRIGGERS DE UPDATED_AT
-- =====================================================

/*
-- Trigger para atualizar campo updated_at automaticamente
CREATE OR REPLACE FUNCTION catalogs.set_updated_at()
RETURNS trigger AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
*/

-- Funcionalidade: Atualiza automaticamente o campo updated_at
-- Uso: Aplicado a todas as tabelas com campo updated_at
-- Evento: BEFORE UPDATE

/*
-- Exemplo de aplicação do trigger updated_at
CREATE TRIGGER update_categories_updated_at
    BEFORE UPDATE ON catalogs.categories
    FOR EACH ROW
    EXECUTE FUNCTION catalogs.set_updated_at();

CREATE TRIGGER update_products_updated_at
    BEFORE UPDATE ON catalogs.products
    FOR EACH ROW
    EXECUTE FUNCTION catalogs.set_updated_at();

CREATE TRIGGER update_offers_updated_at
    BEFORE UPDATE ON catalogs.offers
    FOR EACH ROW
    EXECUTE FUNCTION catalogs.set_updated_at();
*/

-- =====================================================
-- TRIGGERS DE VALIDAÇÃO DE URL
-- =====================================================

/*
-- Trigger para validar URL automaticamente
CREATE OR REPLACE FUNCTION catalogs.validate_url_before_insert_update()
RETURNS trigger AS $$
BEGIN
    -- Validar URL (se não for NULL)
    IF NEW.logo_url IS NOT NULL AND NOT aux.validate_url(NEW.logo_url) THEN
        RAISE EXCEPTION 'URL do logo inválida: %', NEW.logo_url;
    END IF;
    
    IF NEW.website_url IS NOT NULL AND NOT aux.validate_url(NEW.website_url) THEN
        RAISE EXCEPTION 'URL do site inválida: %', NEW.website_url;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
*/

-- Funcionalidade: Valida URL automaticamente
-- Uso: Aplicado às tabelas com campos URL
-- Evento: BEFORE INSERT, BEFORE UPDATE

/*
-- Exemplo de aplicação do trigger URL
CREATE TRIGGER validate_brands_url
    BEFORE INSERT OR UPDATE ON catalogs.brands
    FOR EACH ROW
    EXECUTE FUNCTION catalogs.validate_url_before_insert_update();
*/

-- =====================================================
-- TRIGGERS DE VALIDAÇÃO DE PREÇO
-- =====================================================

/*
-- Trigger para validar preço automaticamente
CREATE OR REPLACE FUNCTION catalogs.validate_price_before_insert_update()
RETURNS trigger AS $$
BEGIN
    -- Validar preço
    IF NEW.price <= 0 THEN
        RAISE EXCEPTION 'Preço deve ser maior que zero: %', NEW.price;
    END IF;
    
    -- Validar datas de disponibilidade
    IF NEW.available_until IS NOT NULL AND NEW.available_until <= NEW.available_from THEN
        RAISE EXCEPTION 'Data de término deve ser posterior à data de início';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
*/

-- Funcionalidade: Valida preço e datas automaticamente
-- Uso: Aplicado à tabela offers
-- Evento: BEFORE INSERT, BEFORE UPDATE

/*
-- Exemplo de aplicação do trigger preço
CREATE TRIGGER validate_offers_price
    BEFORE INSERT OR UPDATE ON catalogs.offers
    FOR EACH ROW
    EXECUTE FUNCTION catalogs.validate_price_before_insert_update();
*/

-- =====================================================
-- TRIGGERS DE VALIDAÇÃO DE QUANTIDADE
-- =====================================================

/*
-- Trigger para validar quantidade automaticamente
CREATE OR REPLACE FUNCTION catalogs.validate_quantity_before_insert_update()
RETURNS trigger AS $$
BEGIN
    -- Validar valor da quantidade
    IF NEW.value <= 0 THEN
        RAISE EXCEPTION 'Valor da quantidade deve ser maior que zero: %', NEW.value;
    END IF;
    
    -- Validar unidade
    IF NEW.unit IS NULL OR length(trim(NEW.unit)) = 0 THEN
        RAISE EXCEPTION 'Unidade da quantidade é obrigatória';
    END IF;
    
    -- Validar nome de exibição
    IF NEW.display_name IS NULL OR length(trim(NEW.display_name)) = 0 THEN
        RAISE EXCEPTION 'Nome de exibição da quantidade é obrigatório';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
*/

-- Funcionalidade: Valida quantidade automaticamente
-- Uso: Aplicado à tabela quantities
-- Evento: BEFORE INSERT, BEFORE UPDATE

/*
-- Exemplo de aplicação do trigger quantidade
CREATE TRIGGER validate_quantities_quantity
    BEFORE INSERT OR UPDATE ON catalogs.quantities
    FOR EACH ROW
    EXECUTE FUNCTION catalogs.validate_quantity_before_insert_update();
*/

-- =====================================================
-- TRIGGERS DE INTEGRIDADE HIERÁRQUICA
-- =====================================================

/*
-- Trigger para validar integridade hierárquica
CREATE OR REPLACE FUNCTION catalogs.validate_hierarchy_before_insert_update()
RETURNS trigger AS $$
BEGIN
    -- Validar se a subcategoria pertence à categoria
    IF NEW.category_id IS NOT NULL THEN
        IF NOT EXISTS (
            SELECT 1 FROM catalogs.subcategories 
            WHERE subcategory_id = NEW.subcategory_id 
            AND category_id = NEW.category_id
        ) THEN
            RAISE EXCEPTION 'Subcategoria % não pertence à categoria %', NEW.subcategory_id, NEW.category_id;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
*/

-- Funcionalidade: Valida integridade hierárquica
-- Uso: Aplicado às tabelas com relacionamentos hierárquicos
-- Evento: BEFORE INSERT, BEFORE UPDATE

/*
-- Exemplo de aplicação do trigger hierarquia
CREATE TRIGGER validate_items_hierarchy
    BEFORE INSERT OR UPDATE ON catalogs.items
    FOR EACH ROW
    EXECUTE FUNCTION catalogs.validate_hierarchy_before_insert_update();
*/

-- =====================================================
-- TRIGGERS DE AUDITORIA DE PREÇOS
-- =====================================================

/*
-- Trigger para auditoria de mudanças de preço
CREATE OR REPLACE FUNCTION catalogs.audit_price_changes()
RETURNS trigger AS $$
BEGIN
    -- Registrar mudança de preço se houve alteração
    IF OLD.price IS DISTINCT FROM NEW.price THEN
        INSERT INTO catalogs.price_change_log (
            offer_id,
            old_price,
            new_price,
            change_date,
            change_reason
        ) VALUES (
            NEW.offer_id,
            OLD.price,
            NEW.price,
            now(),
            'Alteração automática via trigger'
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
*/

-- Funcionalidade: Auditoria de mudanças de preço
-- Uso: Aplicado à tabela offers
-- Evento: AFTER UPDATE
-- Nota: Requer tabela price_change_log (opcional)

/*
-- Exemplo de aplicação do trigger auditoria de preço
CREATE TRIGGER audit_offers_price_changes
    AFTER UPDATE ON catalogs.offers
    FOR EACH ROW
    EXECUTE FUNCTION catalogs.audit_price_changes();
*/

-- =====================================================
-- TRIGGERS DE VALIDAÇÃO DE VISIBILIDADE
-- =====================================================

/*
-- Trigger para validar visibilidade do produto
CREATE OR REPLACE FUNCTION catalogs.validate_product_visibility()
RETURNS trigger AS $$
BEGIN
    -- Validar valores de visibilidade
    IF NEW.visibility NOT IN ('PUBLIC', 'PRIVATE') THEN
        RAISE EXCEPTION 'Visibilidade deve ser PUBLIC ou PRIVATE: %', NEW.visibility;
    END IF;
    
    -- Produtos privados devem ter pelo menos uma oferta ativa
    IF NEW.visibility = 'PRIVATE' THEN
        IF NOT EXISTS (
            SELECT 1 FROM catalogs.offers 
            WHERE product_id = NEW.product_id 
            AND is_active = true
        ) THEN
            RAISE EXCEPTION 'Produtos privados devem ter pelo menos uma oferta ativa';
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
*/

-- Funcionalidade: Valida visibilidade do produto
-- Uso: Aplicado à tabela products
-- Evento: BEFORE INSERT, BEFORE UPDATE

/*
-- Exemplo de aplicação do trigger visibilidade
CREATE TRIGGER validate_products_visibility
    BEFORE INSERT OR UPDATE ON catalogs.products
    FOR EACH ROW
    EXECUTE FUNCTION catalogs.validate_product_visibility();
*/

-- =====================================================
-- FUNÇÃO PARA CRIAR TRIGGERS DE VALIDAÇÃO
-- =====================================================

/*
-- Função para criar triggers de validação automaticamente
CREATE OR REPLACE FUNCTION catalogs.create_validation_triggers(
    p_schema_name text,
    p_table_name text,
    p_columns text[]
) RETURNS text AS $$
DECLARE
    v_column text;
    v_trigger_name text;
    v_function_name text;
    v_result text := '';
BEGIN
    FOREACH v_column IN ARRAY p_columns
    LOOP
        v_trigger_name := 'validate_' || p_table_name || '_' || v_column;
        
        -- Determinar função baseada no tipo de coluna
        CASE v_column
            WHEN 'logo_url', 'website_url' THEN
                v_function_name := 'catalogs.validate_url_before_insert_update';
            WHEN 'price' THEN
                v_function_name := 'catalogs.validate_price_before_insert_update';
            WHEN 'value', 'unit', 'display_name' THEN
                v_function_name := 'catalogs.validate_quantity_before_insert_update';
            WHEN 'visibility' THEN
                v_function_name := 'catalogs.validate_product_visibility';
            ELSE
                RAISE NOTICE 'Tipo de coluna não suportado: %', v_column;
                CONTINUE;
        END CASE;
        
        -- Criar trigger
        EXECUTE format('
            DROP TRIGGER IF EXISTS %I ON %I.%I;
            CREATE TRIGGER %I
                BEFORE INSERT OR UPDATE ON %I.%I
                FOR EACH ROW
                EXECUTE FUNCTION %s;
        ', v_trigger_name, p_schema_name, p_table_name,
           v_trigger_name, p_schema_name, p_table_name, v_function_name);
        
        v_result := v_result || 'Trigger ' || v_trigger_name || ' criado. ';
    END LOOP;
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql;
*/

-- Funcionalidade: Cria triggers de validação automaticamente
-- Uso: Simplifica a criação de múltiplos triggers
-- Parâmetros: schema, tabela e array de colunas para validar

-- =====================================================
-- EXEMPLOS DE USO
-- =====================================================

/*
-- Exemplo 1: Criar triggers de validação para uma tabela
SELECT catalogs.create_validation_triggers('catalogs', 'brands', ARRAY['logo_url', 'website_url']);

-- Exemplo 2: Criar múltiplos triggers de validação
SELECT catalogs.create_validation_triggers('catalogs', 'offers', ARRAY['price']);

-- Exemplo 3: Criar triggers para quantidades
SELECT catalogs.create_validation_triggers('catalogs', 'quantities', ARRAY['value', 'unit', 'display_name']);

-- Exemplo 4: Criar triggers para produtos
SELECT catalogs.create_validation_triggers('catalogs', 'products', ARRAY['visibility']);
*/

-- =====================================================
-- NOTAS IMPORTANTES
-- =====================================================

-- 1. Todos os triggers usam funções de validação do schema aux quando aplicável
-- 2. Triggers são aplicados BEFORE INSERT/UPDATE para validação
-- 3. Validações incluem regras de negócio específicas do catálogo
-- 4. Triggers de updated_at são aplicados a todas as tabelas relevantes
-- 5. Função create_validation_triggers simplifica a criação de triggers
-- 6. Todos os triggers são auditados automaticamente
-- 7. Triggers de auditoria de preço são opcionais e requerem tabela adicional
