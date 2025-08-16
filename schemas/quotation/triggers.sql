-- Triggers do schema quotation
-- Schema: quotation
-- Arquivo: triggers.sql

-- Este arquivo contém todos os triggers do schema quotation
-- Os triggers são criados automaticamente pelos scripts de extensão
-- Este arquivo serve como documentação e referência

-- =====================================================
-- TRIGGERS DE TIMESTAMP
-- =====================================================

/*
-- Trigger para atualizar automaticamente o campo updated_at
CREATE OR REPLACE FUNCTION quotation.set_updated_at()
RETURNS trigger AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar trigger em todas as tabelas com campo updated_at
CREATE TRIGGER trigger_shopping_lists_updated_at
    BEFORE UPDATE ON quotation.shopping_lists
    FOR EACH ROW EXECUTE FUNCTION quotation.set_updated_at();

CREATE TRIGGER trigger_shopping_list_items_updated_at
    BEFORE UPDATE ON quotation.shopping_list_items
    FOR EACH ROW EXECUTE FUNCTION quotation.set_updated_at();

CREATE TRIGGER trigger_quotation_submissions_updated_at
    BEFORE UPDATE ON quotation.quotation_submissions
    FOR EACH ROW EXECUTE FUNCTION quotation.set_updated_at();

CREATE TRIGGER trigger_supplier_quotations_updated_at
    BEFORE UPDATE ON quotation.supplier_quotations
    FOR EACH ROW EXECUTE FUNCTION quotation.set_updated_at();

CREATE TRIGGER trigger_quoted_prices_updated_at
    BEFORE UPDATE ON quotation.quoted_prices
    FOR EACH ROW EXECUTE FUNCTION quotation.set_updated_at();

CREATE TRIGGER trigger_submission_statuses_updated_at
    BEFORE UPDATE ON quotation.submission_statuses
    FOR EACH ROW EXECUTE FUNCTION quotation.set_updated_at();

CREATE TRIGGER trigger_supplier_quotation_statuses_updated_at
    BEFORE UPDATE ON quotation.supplier_quotation_statuses
    FOR EACH ROW EXECUTE FUNCTION quotation.set_updated_at();
*/

-- Funcionalidade: Atualiza automaticamente o campo updated_at
-- Uso: Manter timestamps de modificação sempre atualizados
-- Aplicação: Todas as tabelas com campo updated_at

-- =====================================================
-- TRIGGERS DE VALIDAÇÃO
-- =====================================================

/*
-- Trigger para validar cor hexadecimal antes de inserir/atualizar
CREATE OR REPLACE FUNCTION quotation.validate_color_before_insert_update()
RETURNS trigger AS $$
BEGIN
    -- Validar formato de cor hexadecimal se não for NULL
    IF NEW.color IS NOT NULL THEN
        IF NEW.color !~ '^#[0-9A-Fa-f]{6}$' THEN
            RAISE EXCEPTION 'Formato de cor inválido. Use formato hexadecimal (#RRGGBB)';
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar trigger de validação de cor
CREATE TRIGGER trigger_submission_statuses_color_validation
    BEFORE INSERT OR UPDATE ON quotation.submission_statuses
    FOR EACH ROW EXECUTE FUNCTION quotation.validate_color_before_insert_update();

CREATE TRIGGER trigger_supplier_quotation_statuses_color_validation
    BEFORE INSERT OR UPDATE ON quotation.supplier_quotation_statuses
    FOR EACH ROW EXECUTE FUNCTION quotation.validate_color_before_insert_update();
*/

-- Funcionalidade: Valida formato de cor hexadecimal
-- Uso: Garantir que cores sejam válidas para interface
-- Validação: Formato #RRGGBB obrigatório

/*
-- Trigger para validar preços antes de inserir/atualizar
CREATE OR REPLACE FUNCTION quotation.validate_price_before_insert_update()
RETURNS trigger AS $$
BEGIN
    -- Validar preços positivos
    IF NEW.unit_price <= 0 THEN
        RAISE EXCEPTION 'Preço unitário deve ser maior que zero';
    END IF;
    
    IF NEW.total_price <= 0 THEN
        RAISE EXCEPTION 'Preço total deve ser maior que zero';
    END IF;
    
    -- Validar quantidade mínima
    IF NEW.quantity_from <= 0 THEN
        RAISE EXCEPTION 'Quantidade mínima deve ser maior que zero';
    END IF;
    
    -- Validar range de quantidade
    IF NEW.quantity_to IS NOT NULL AND NEW.quantity_to <= NEW.quantity_from THEN
        RAISE EXCEPTION 'Quantidade máxima deve ser maior que quantidade mínima';
    END IF;
    
    -- Validar prazos positivos
    IF NEW.delivery_time_days IS NOT NULL AND NEW.delivery_time_days < 0 THEN
        RAISE EXCEPTION 'Prazo de entrega deve ser maior ou igual a zero';
    END IF;
    
    IF NEW.validity_days IS NOT NULL AND NEW.validity_days <= 0 THEN
        RAISE EXCEPTION 'Validade deve ser maior que zero';
    END IF;
    
    -- Validar quantidade mínima de pedido
    IF NEW.minimum_order_quantity IS NOT NULL AND NEW.minimum_order_quantity <= 0 THEN
        RAISE EXCEPTION 'Quantidade mínima de pedido deve ser maior que zero';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar trigger de validação de preços
CREATE TRIGGER trigger_quoted_prices_validation
    BEFORE INSERT OR UPDATE ON quotation.quoted_prices
    FOR EACH ROW EXECUTE FUNCTION quotation.validate_price_before_insert_update();
*/

-- Funcionalidade: Valida preços e condições comerciais
-- Uso: Garantir consistência de dados de preços
-- Validações: Preços positivos, quantidades válidas, prazos corretos

/*
-- Trigger para validar quantidade antes de inserir/atualizar
CREATE OR REPLACE FUNCTION quotation.validate_quantity_before_insert_update()
RETURNS trigger AS $$
BEGIN
    -- Validar quantidade positiva
    IF NEW.quantity <= 0 THEN
        RAISE EXCEPTION 'Quantidade deve ser maior que zero';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar trigger de validação de quantidade
CREATE TRIGGER trigger_shopping_list_items_quantity_validation
    BEFORE INSERT OR UPDATE ON quotation.shopping_list_items
    FOR EACH ROW EXECUTE FUNCTION quotation.validate_quantity_before_insert_update();
*/

-- Funcionalidade: Valida quantidade de itens
-- Uso: Garantir que quantidades sejam sempre positivas
-- Validação: Quantidade > 0

-- =====================================================
-- TRIGGERS DE INTEGRIDADE HIERÁRQUICA
-- =====================================================

/*
-- Trigger para validar hierarquia de listas de compras
CREATE OR REPLACE FUNCTION quotation.validate_shopping_list_hierarchy()
RETURNS trigger AS $$
BEGIN
    -- Verificar se o estabelecimento existe
    IF NOT EXISTS (
        SELECT 1 FROM accounts.establishments 
        WHERE establishment_id = NEW.establishment_id
    ) THEN
        RAISE EXCEPTION 'Estabelecimento não encontrado';
    END IF;
    
    -- Verificar se o funcionário existe (se fornecido)
    IF NEW.employee_id IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM accounts.employees 
        WHERE employee_id = NEW.employee_id
    ) THEN
        RAISE EXCEPTION 'Funcionário não encontrado';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar trigger de validação hierárquica
CREATE TRIGGER trigger_shopping_lists_hierarchy_validation
    BEFORE INSERT OR UPDATE ON quotation.shopping_lists
    FOR EACH ROW EXECUTE FUNCTION quotation.validate_shopping_list_hierarchy();
*/

-- Funcionalidade: Valida hierarquia de listas de compras
-- Uso: Garantir que estabelecimentos e funcionários existam
-- Validações: Estabelecimento obrigatório, funcionário opcional

/*
-- Trigger para validar hierarquia de itens de lista
CREATE OR REPLACE FUNCTION quotation.validate_shopping_list_item_hierarchy()
RETURNS trigger AS $$
BEGIN
    -- Verificar se a lista de compras existe
    IF NOT EXISTS (
        SELECT 1 FROM quotation.shopping_lists 
        WHERE shopping_list_id = NEW.shopping_list_id
    ) THEN
        RAISE EXCEPTION 'Lista de compras não encontrada';
    END IF;
    
    -- Verificar se o item existe
    IF NOT EXISTS (
        SELECT 1 FROM catalogs.items 
        WHERE item_id = NEW.item_id
    ) THEN
        RAISE EXCEPTION 'Item não encontrado no catálogo';
    END IF;
    
    -- Verificar se o produto existe (se fornecido)
    IF NEW.product_id IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM catalogs.products 
        WHERE product_id = NEW.product_id
    ) THEN
        RAISE EXCEPTION 'Produto não encontrado no catálogo';
    END IF;
    
    -- Verificar se a marca existe (se fornecida)
    IF NEW.brand_id IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM catalogs.brands 
        WHERE brand_id = NEW.brand_id
    ) THEN
        RAISE EXCEPTION 'Marca não encontrada no catálogo';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar trigger de validação hierárquica de itens
CREATE TRIGGER trigger_shopping_list_items_hierarchy_validation
    BEFORE INSERT OR UPDATE ON quotation.shopping_list_items
    FOR EACH ROW EXECUTE FUNCTION quotation.validate_shopping_list_item_hierarchy();
*/

-- Funcionalidade: Valida hierarquia de itens de lista
-- Uso: Garantir que itens e produtos existam no catálogo
-- Validações: Item obrigatório, produto e marca opcionais

-- =====================================================
-- TRIGGERS DE AUDITORIA DE PREÇOS
-- =====================================================

/*
-- Trigger para auditar mudanças de preços
CREATE OR REPLACE FUNCTION quotation.audit_price_changes()
RETURNS trigger AS $$
BEGIN
    -- Registrar mudança de preço se houver alteração
    IF TG_OP = 'UPDATE' AND (
        OLD.unit_price != NEW.unit_price OR
        OLD.total_price != NEW.total_price OR
        OLD.currency != NEW.currency OR
        OLD.delivery_time_days != NEW.delivery_time_days OR
        OLD.validity_days != NEW.validity_days
    ) THEN
        -- Aqui você pode inserir em uma tabela de auditoria específica
        -- ou usar o sistema de auditoria automático
        RAISE NOTICE 'Preço alterado para cotação %: unit_price % -> %, total_price % -> %',
            NEW.supplier_quotation_id,
            OLD.unit_price, NEW.unit_price,
            OLD.total_price, NEW.total_price;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar trigger de auditoria de preços
CREATE TRIGGER trigger_quoted_prices_audit
    AFTER UPDATE ON quotation.quoted_prices
    FOR EACH ROW EXECUTE FUNCTION quotation.audit_price_changes();
*/

-- Funcionalidade: Audita mudanças de preços
-- Uso: Rastrear alterações de preços para análise
-- Ações: Notifica mudanças e pode registrar em tabela de auditoria

-- =====================================================
-- TRIGGERS DE VALIDAÇÃO DE STATUS
-- =====================================================

/*
-- Trigger para validar mudanças de status de lista
CREATE OR REPLACE FUNCTION quotation.validate_shopping_list_status_change()
RETURNS trigger AS $$
BEGIN
    -- Validar transições de status permitidas
    IF OLD.status = 'DRAFT' AND NEW.status NOT IN ('ACTIVE', 'CANCELLED') THEN
        RAISE EXCEPTION 'Lista em rascunho só pode ser ativada ou cancelada';
    END IF;
    
    IF OLD.status = 'ACTIVE' AND NEW.status NOT IN ('COMPLETED', 'CANCELLED') THEN
        RAISE EXCEPTION 'Lista ativa só pode ser concluída ou cancelada';
    END IF;
    
    IF OLD.status = 'COMPLETED' AND NEW.status != 'COMPLETED' THEN
        RAISE EXCEPTION 'Lista concluída não pode ter status alterado';
    END IF;
    
    IF OLD.status = 'CANCELLED' AND NEW.status != 'CANCELLED' THEN
        RAISE EXCEPTION 'Lista cancelada não pode ter status alterado';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar trigger de validação de status
CREATE TRIGGER trigger_shopping_lists_status_validation
    BEFORE UPDATE ON quotation.shopping_lists
    FOR EACH ROW EXECUTE FUNCTION quotation.validate_shopping_list_status_change();
*/

-- Funcionalidade: Valida transições de status de listas
-- Uso: Garantir fluxo correto de status
-- Validações: Transições permitidas entre status

-- =====================================================
-- TRIGGERS DE CÁLCULO AUTOMÁTICO
-- =====================================================

/*
-- Trigger para calcular total de itens automaticamente
CREATE OR REPLACE FUNCTION quotation.calculate_total_items()
RETURNS trigger AS $$
BEGIN
    -- Atualizar total de itens na submissão
    UPDATE quotation.quotation_submissions 
    SET total_items = (
        SELECT COUNT(*) 
        FROM quotation.shopping_list_items 
        WHERE shopping_list_id = NEW.shopping_list_id
    )
    WHERE shopping_list_id = NEW.shopping_list_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar trigger de cálculo automático
CREATE TRIGGER trigger_shopping_list_items_calculate_total
    AFTER INSERT OR DELETE OR UPDATE ON quotation.shopping_list_items
    FOR EACH ROW EXECUTE FUNCTION quotation.calculate_total_items();
*/

-- Funcionalidade: Calcula total de itens automaticamente
-- Uso: Manter contadores sempre atualizados
-- Ações: Atualiza total_items na submissão

-- =====================================================
-- FUNÇÃO PARA CRIAR TODOS OS TRIGGERS
-- =====================================================

/*
-- Função para criar todos os triggers de validação
CREATE OR REPLACE FUNCTION quotation.create_validation_triggers()
RETURNS text AS $$
DECLARE
    v_result text := '';
BEGIN
    -- Criar triggers de updated_at
    EXECUTE 'CREATE TRIGGER IF NOT EXISTS trigger_shopping_lists_updated_at
        BEFORE UPDATE ON quotation.shopping_lists
        FOR EACH ROW EXECUTE FUNCTION quotation.set_updated_at()';
    v_result := v_result || 'Trigger updated_at para shopping_lists criado. ';
    
    EXECUTE 'CREATE TRIGGER IF NOT EXISTS trigger_shopping_list_items_updated_at
        BEFORE UPDATE ON quotation.shopping_list_items
        FOR EACH ROW EXECUTE FUNCTION quotation.set_updated_at()';
    v_result := v_result || 'Trigger updated_at para shopping_list_items criado. ';
    
    EXECUTE 'CREATE TRIGGER IF NOT EXISTS trigger_quotation_submissions_updated_at
        BEFORE UPDATE ON quotation.quotation_submissions
        FOR EACH ROW EXECUTE FUNCTION quotation.set_updated_at()';
    v_result := v_result || 'Trigger updated_at para quotation_submissions criado. ';
    
    EXECUTE 'CREATE TRIGGER IF NOT EXISTS trigger_supplier_quotations_updated_at
        BEFORE UPDATE ON quotation.supplier_quotations
        FOR EACH ROW EXECUTE FUNCTION quotation.set_updated_at()';
    v_result := v_result || 'Trigger updated_at para supplier_quotations criado. ';
    
    EXECUTE 'CREATE TRIGGER IF NOT EXISTS trigger_quoted_prices_updated_at
        BEFORE UPDATE ON quotation.quoted_prices
        FOR EACH ROW EXECUTE FUNCTION quotation.set_updated_at()';
    v_result := v_result || 'Trigger updated_at para quoted_prices criado. ';
    
    -- Criar triggers de validação
    EXECUTE 'CREATE TRIGGER IF NOT EXISTS trigger_submission_statuses_color_validation
        BEFORE INSERT OR UPDATE ON quotation.submission_statuses
        FOR EACH ROW EXECUTE FUNCTION quotation.validate_color_before_insert_update()';
    v_result := v_result || 'Trigger de validação de cor para submission_statuses criado. ';
    
    EXECUTE 'CREATE TRIGGER IF NOT EXISTS trigger_supplier_quotation_statuses_color_validation
        BEFORE INSERT OR UPDATE ON quotation.supplier_quotation_statuses
        FOR EACH ROW EXECUTE FUNCTION quotation.validate_color_before_insert_update()';
    v_result := v_result || 'Trigger de validação de cor para supplier_quotation_statuses criado. ';
    
    EXECUTE 'CREATE TRIGGER IF NOT EXISTS trigger_quoted_prices_validation
        BEFORE INSERT OR UPDATE ON quotation.quoted_prices
        FOR EACH ROW EXECUTE FUNCTION quotation.validate_price_before_insert_update()';
    v_result := v_result || 'Trigger de validação de preços para quoted_prices criado. ';
    
    EXECUTE 'CREATE TRIGGER IF NOT EXISTS trigger_shopping_list_items_quantity_validation
        BEFORE INSERT OR UPDATE ON quotation.shopping_list_items
        FOR EACH ROW EXECUTE FUNCTION quotation.validate_quantity_before_insert_update()';
    v_result := v_result || 'Trigger de validação de quantidade para shopping_list_items criado. ';
    
    -- Criar triggers de hierarquia
    EXECUTE 'CREATE TRIGGER IF NOT EXISTS trigger_shopping_lists_hierarchy_validation
        BEFORE INSERT OR UPDATE ON quotation.shopping_lists
        FOR EACH ROW EXECUTE FUNCTION quotation.validate_shopping_list_hierarchy()';
    v_result := v_result || 'Trigger de validação hierárquica para shopping_lists criado. ';
    
    EXECUTE 'CREATE TRIGGER IF NOT EXISTS trigger_shopping_list_items_hierarchy_validation
        BEFORE INSERT OR UPDATE ON quotation.shopping_list_items
        FOR EACH ROW EXECUTE FUNCTION quotation.validate_shopping_list_item_hierarchy()';
    v_result := v_result || 'Trigger de validação hierárquica para shopping_list_items criado. ';
    
    -- Criar triggers de auditoria
    EXECUTE 'CREATE TRIGGER IF NOT EXISTS trigger_quoted_prices_audit
        AFTER UPDATE ON quotation.quoted_prices
        FOR EACH ROW EXECUTE FUNCTION quotation.audit_price_changes()';
    v_result := v_result || 'Trigger de auditoria para quoted_prices criado. ';
    
    -- Criar triggers de status
    EXECUTE 'CREATE TRIGGER IF NOT EXISTS trigger_shopping_lists_status_validation
        BEFORE UPDATE ON quotation.shopping_lists
        FOR EACH ROW EXECUTE FUNCTION quotation.validate_shopping_list_status_change()';
    v_result := v_result || 'Trigger de validação de status para shopping_lists criado. ';
    
    -- Criar triggers de cálculo
    EXECUTE 'CREATE TRIGGER IF NOT EXISTS trigger_shopping_list_items_calculate_total
        AFTER INSERT OR DELETE OR UPDATE ON quotation.shopping_list_items
        FOR EACH ROW EXECUTE FUNCTION quotation.calculate_total_items()';
    v_result := v_result || 'Trigger de cálculo para shopping_list_items criado. ';
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql;
*/

-- Funcionalidade: Cria todos os triggers de validação
-- Uso: Configuração automática de todos os triggers
-- Retorna: Relatório de triggers criados

-- =====================================================
-- EXEMPLOS DE USO
-- =====================================================

/*
-- Exemplo 1: Criar todos os triggers
SELECT quotation.create_validation_triggers();

-- Exemplo 2: Verificar triggers existentes
SELECT 
    trigger_name,
    event_manipulation,
    event_object_table,
    action_statement
FROM information_schema.triggers
WHERE trigger_schema = 'quotation'
ORDER BY trigger_name;

-- Exemplo 3: Testar validação de cor
INSERT INTO quotation.submission_statuses (name, description, color) 
VALUES ('TEST', 'Teste', '#INVALID');

-- Exemplo 4: Testar validação de preço
INSERT INTO quotation.quoted_prices (supplier_quotation_id, quantity_from, unit_price, total_price, currency)
VALUES ('uuid-invalido', -10, 0, 0, 'BRL');

-- Exemplo 5: Testar validação de quantidade
INSERT INTO quotation.shopping_list_items (shopping_list_id, item_id, term, quantity)
VALUES ('uuid-invalido', 'uuid-invalido', 'teste', -5);
*/

-- =====================================================
-- NOTAS IMPORTANTES
-- =====================================================

-- 1. Todos os triggers são executados em ordem específica
-- 2. Triggers de validação são executados ANTES das operações
-- 3. Triggers de auditoria são executados DEPOIS das operações
-- 4. Triggers de cálculo são executados APÓS mudanças
-- 5. Todos os triggers são auditados automaticamente
-- 6. Triggers de auditoria de preço são opcionais e requerem tabela adicional
-- 7. Função create_validation_triggers() cria todos os triggers necessários
