-- =====================================================
-- SCHEMA QUOTATION - SISTEMA DE COTAÇÕES AGILIZEI
-- =====================================================
-- Schema para gerenciamento de listas de compras e cotações
-- Autor: Assistente IA + Usuário
-- Data: 2025-01-27
-- Versão: 2.0 (Corrigida)

-- =====================================================
-- VERIFICAÇÃO DE EXTENSÕES
-- =====================================================

-- Verifica se a extensão uuid-ossp está disponível
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_extension WHERE extname = 'uuid-ossp'
    ) THEN
        CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
        RAISE NOTICE '✅ Extensão uuid-ossp criada';
    ELSE
        RAISE NOTICE '✅ Extensão uuid-ossp já disponível';
    END IF;
END $$;

-- =====================================================
-- CRIAÇÃO DO SCHEMA
-- =====================================================

CREATE SCHEMA IF NOT EXISTS quotation;

-- =====================================================
-- TABELAS DE DOMÍNIO (STATUS)
-- =====================================================

-- Status das submissões de cotação (controle interno)
CREATE TABLE quotation.submission_statuses (
    submission_status_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    color VARCHAR(7),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Status das cotações dos fornecedores
CREATE TABLE quotation.supplier_quotation_statuses (
    quotation_status_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    color VARCHAR(7),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- TABELAS PRINCIPAIS
-- =====================================================

-- Listas de compras criadas pelos estabelecimentos
CREATE TABLE quotation.shopping_lists (
    shopping_list_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    establishment_id UUID NOT NULL,
    employee_id UUID NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Itens dentro das listas de compras com decomposição completa
CREATE TABLE quotation.shopping_list_items (
    shopping_list_item_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    shopping_list_id UUID NOT NULL,
    
    -- Campo obrigatório: item base (ex: "Macarrão")
    item_id UUID NOT NULL,
    
    -- Campos opcionais para refinamento da busca
    product_id UUID,                    -- Produto específico se encontrado
    composition_id UUID,                -- Composição (ex: "Integral")
    variant_type_id UUID,               -- Tipo de variante (ex: "Spaghetti")
    format_id UUID,                     -- Formato (ex: "Fino")
    flavor_id UUID,                     -- Sabor (ex: "Natural")
    filling_id UUID,                    -- Recheio (ex: "Sem recheio")
    nutritional_variant_id UUID,        -- Variante nutricional (ex: "Light")
    brand_id UUID,                      -- Marca (ex: "Barilla")
    packaging_id UUID,                  -- Embalagem (ex: "Caixa")
    quantity_id UUID,                   -- Quantidade (ex: "500g")
    
    -- Campos do item
    term VARCHAR(255) NOT NULL,         -- Termo original digitado pelo usuário
    quantity DECIMAL(10,3) NOT NULL,    -- Quantidade solicitada
    notes TEXT,                         -- Observações sobre o item
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Submissões de cotação (quando as listas são enviadas)
CREATE TABLE quotation.quotation_submissions (
    quotation_submission_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    shopping_list_id UUID NOT NULL,
    submission_status_id UUID NOT NULL,  -- Referência para tabela de domínio
    submission_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    total_items INTEGER DEFAULT 0,       -- Calculado automaticamente
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Cotações recebidas dos fornecedores
CREATE TABLE quotation.supplier_quotations (
    supplier_quotation_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    quotation_submission_id UUID NOT NULL,
    shopping_list_item_id UUID NOT NULL,
    supplier_id UUID NOT NULL,
    quotation_status_id UUID NOT NULL,   -- Referência para tabela de domínio
    quotation_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Preços cotados individuais com condições
CREATE TABLE quotation.quoted_prices (
    quoted_price_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    supplier_quotation_id UUID NOT NULL,
    quantity_from DECIMAL(10,3) NOT NULL,
    quantity_to DECIMAL(10,3),          -- NULL = ilimitado
    unit_price DECIMAL(10,2) NOT NULL,
    total_price DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'BRL',
    delivery_time_days INTEGER,
    minimum_order_quantity DECIMAL(10,3),
    payment_terms VARCHAR(100),
    validity_days INTEGER DEFAULT 30,
    special_conditions TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- FOREIGN KEYS
-- =====================================================

-- Estabelecimentos e Funcionários
ALTER TABLE quotation.shopping_lists 
ADD CONSTRAINT fk_shopping_lists_establishment 
FOREIGN KEY (establishment_id) REFERENCES accounts.establishments(establishment_id);

ALTER TABLE quotation.shopping_lists 
ADD CONSTRAINT fk_shopping_lists_employee 
FOREIGN KEY (employee_id) REFERENCES accounts.employees(employee_id);

-- Itens da lista de compras
ALTER TABLE quotation.shopping_list_items 
ADD CONSTRAINT fk_shopping_list_items_shopping_list 
FOREIGN KEY (shopping_list_id) REFERENCES quotation.shopping_lists(shopping_list_id) ON DELETE CASCADE;

ALTER TABLE quotation.shopping_list_items 
ADD CONSTRAINT fk_shopping_list_items_item 
FOREIGN KEY (item_id) REFERENCES catalogs.items(item_id);

-- Campos de decomposição opcionais
ALTER TABLE quotation.shopping_list_items 
ADD CONSTRAINT fk_shopping_list_items_product 
FOREIGN KEY (product_id) REFERENCES catalogs.products(product_id);

ALTER TABLE quotation.shopping_list_items 
ADD CONSTRAINT fk_shopping_list_items_composition 
FOREIGN KEY (composition_id) REFERENCES catalogs.compositions(composition_id);

ALTER TABLE quotation.shopping_list_items 
ADD CONSTRAINT fk_shopping_list_items_variant_type 
FOREIGN KEY (variant_type_id) REFERENCES catalogs.variant_types(variant_type_id);

ALTER TABLE quotation.shopping_list_items 
ADD CONSTRAINT fk_shopping_list_items_format 
FOREIGN KEY (format_id) REFERENCES catalogs.formats(format_id);

ALTER TABLE quotation.shopping_list_items 
ADD CONSTRAINT fk_shopping_list_items_flavor 
FOREIGN KEY (flavor_id) REFERENCES catalogs.flavors(flavor_id);

ALTER TABLE quotation.shopping_list_items 
ADD CONSTRAINT fk_shopping_list_items_filling 
FOREIGN KEY (filling_id) REFERENCES catalogs.fillings(filling_id);

ALTER TABLE quotation.shopping_list_items 
ADD CONSTRAINT fk_shopping_list_items_nutritional_variant 
FOREIGN KEY (nutritional_variant_id) REFERENCES catalogs.nutritional_variants(nutritional_variant_id);

ALTER TABLE quotation.shopping_list_items 
ADD CONSTRAINT fk_shopping_list_items_brand 
FOREIGN KEY (brand_id) REFERENCES catalogs.brands(brand_id);

ALTER TABLE quotation.shopping_list_items 
ADD CONSTRAINT fk_shopping_list_items_packaging 
FOREIGN KEY (packaging_id) REFERENCES catalogs.packagings(packaging_id);

ALTER TABLE quotation.shopping_list_items 
ADD CONSTRAINT fk_shopping_list_items_quantity 
FOREIGN KEY (quantity_id) REFERENCES catalogs.quantities(quantity_id);

-- Submissões de cotação
ALTER TABLE quotation.quotation_submissions 
ADD CONSTRAINT fk_quotation_submissions_shopping_list 
FOREIGN KEY (shopping_list_id) REFERENCES quotation.shopping_lists(shopping_list_id) ON DELETE CASCADE;

ALTER TABLE quotation.quotation_submissions 
ADD CONSTRAINT fk_quotation_submissions_status 
FOREIGN KEY (submission_status_id) REFERENCES quotation.submission_statuses(submission_status_id);

-- Cotações dos fornecedores
ALTER TABLE quotation.supplier_quotations 
ADD CONSTRAINT fk_supplier_quotations_submission 
FOREIGN KEY (quotation_submission_id) REFERENCES quotation.quotation_submissions(quotation_submission_id) ON DELETE CASCADE;

ALTER TABLE quotation.supplier_quotations 
ADD CONSTRAINT fk_supplier_quotations_shopping_list_item 
FOREIGN KEY (shopping_list_item_id) REFERENCES quotation.shopping_list_items(shopping_list_item_id) ON DELETE CASCADE;

ALTER TABLE quotation.supplier_quotations 
ADD CONSTRAINT fk_supplier_quotations_supplier 
FOREIGN KEY (supplier_id) REFERENCES accounts.suppliers(supplier_id);

ALTER TABLE quotation.supplier_quotations 
ADD CONSTRAINT fk_supplier_quotations_status 
FOREIGN KEY (quotation_status_id) REFERENCES quotation.supplier_quotation_statuses(quotation_status_id);

-- Preços cotados
ALTER TABLE quotation.quoted_prices 
ADD CONSTRAINT fk_quoted_prices_supplier_quotation 
FOREIGN KEY (supplier_quotation_id) REFERENCES quotation.supplier_quotations(supplier_quotation_id) ON DELETE CASCADE;

-- =====================================================
-- DADOS INICIAIS
-- =====================================================

-- Status das submissões de cotação
INSERT INTO quotation.submission_statuses (name, description, color) VALUES
('pending', 'Submissão pendente de envio', '#FFA500'),
('sent', 'Submissão enviada para cotação', '#008000'),
('in_progress', 'Cotação em andamento', '#0066CC'),
('completed', 'Cotação finalizada', '#006600'),
('cancelled', 'Submissão cancelada', '#CC0000');

-- Status das cotações dos fornecedores
INSERT INTO quotation.supplier_quotation_statuses (name, description, color) VALUES
('pending', 'Cotação pendente de resposta do fornecedor', '#FFA500'),
('received', 'Cotação recebida do fornecedor', '#008000'),
('accepted', 'Cotação aceita pelo estabelecimento', '#0066CC'),
('rejected', 'Cotação rejeitada pelo estabelecimento', '#CC0000'),
('expired', 'Cotação expirada', '#808080'),
('cancelled', 'Cotação cancelada', '#FF0000');

-- =====================================================
-- ÍNDICES PARA PERFORMANCE
-- =====================================================

-- Índices para shopping_lists
CREATE INDEX idx_quotation_shopping_lists_establishment_id ON quotation.shopping_lists(establishment_id);
CREATE INDEX idx_quotation_shopping_lists_employee_id ON quotation.shopping_lists(employee_id);
CREATE INDEX idx_quotation_shopping_lists_created_at ON quotation.shopping_lists(created_at);

-- Índices para shopping_list_items
CREATE INDEX idx_quotation_shopping_list_items_shopping_list_id ON quotation.shopping_list_items(shopping_list_id);
CREATE INDEX idx_quotation_shopping_list_items_item_id ON quotation.shopping_list_items(item_id);
CREATE INDEX idx_quotation_shopping_list_items_product_id ON quotation.shopping_list_items(product_id);
CREATE INDEX idx_quotation_shopping_list_items_term ON quotation.shopping_list_items(term);

-- Índices para quotation_submissions
CREATE INDEX idx_quotation_submissions_shopping_list_id ON quotation.quotation_submissions(shopping_list_id);
CREATE INDEX idx_quotation_submissions_status_id ON quotation.quotation_submissions(submission_status_id);
CREATE INDEX idx_quotation_submissions_submission_date ON quotation.quotation_submissions(submission_date);

-- Índices para supplier_quotations
CREATE INDEX idx_supplier_quotations_submission_id ON quotation.supplier_quotations(quotation_submission_id);
CREATE INDEX idx_supplier_quotations_shopping_list_item_id ON quotation.supplier_quotations(shopping_list_item_id);
CREATE INDEX idx_supplier_quotations_supplier_id ON quotation.supplier_quotations(supplier_id);
CREATE INDEX idx_supplier_quotations_status_id ON quotation.supplier_quotations(quotation_status_id);

-- Índices para quoted_prices
CREATE INDEX idx_quoted_prices_supplier_quotation_id ON quotation.quoted_prices(supplier_quotation_id);
CREATE INDEX idx_quoted_prices_unit_price ON quotation.quoted_prices(unit_price);
CREATE INDEX idx_quoted_prices_validity_days ON quotation.quoted_prices(validity_days);

-- =====================================================
-- FUNÇÕES E TRIGGERS
-- =====================================================

-- Função para atualizar updated_at
CREATE OR REPLACE FUNCTION quotation.set_updated_at()
RETURNS TRIGGER 
LANGUAGE plpgsql 
AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION quotation.set_updated_at() IS 'Função para atualizar automaticamente o campo updated_at das tabelas';

-- Função para calcular total_items automaticamente
CREATE OR REPLACE FUNCTION quotation.calculate_total_items()
RETURNS TRIGGER 
LANGUAGE plpgsql 
AS $$
BEGIN
    -- Atualiza o total_items na tabela quotation_submissions
    UPDATE quotation.quotation_submissions 
    SET total_items = (
        SELECT COUNT(*) 
        FROM quotation.shopping_list_items 
        WHERE shopping_list_id = NEW.shopping_list_id
    )
    WHERE shopping_list_id = NEW.shopping_list_id;
    
    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION quotation.calculate_total_items() IS 'Função para calcular automaticamente o total de itens em quotation_submissions baseado na quantidade de itens em shopping_list_items';

-- Triggers para updated_at
CREATE TRIGGER trg_set_updated_at_shopping_lists 
    BEFORE UPDATE ON quotation.shopping_lists 
    FOR EACH ROW EXECUTE FUNCTION quotation.set_updated_at();

CREATE TRIGGER trg_set_updated_at_shopping_list_items 
    BEFORE UPDATE ON quotation.shopping_list_items 
    FOR EACH ROW EXECUTE FUNCTION quotation.set_updated_at();

CREATE TRIGGER trg_set_updated_at_quotation_submissions 
    BEFORE UPDATE ON quotation.quotation_submissions 
    FOR EACH ROW EXECUTE FUNCTION quotation.set_updated_at();

CREATE TRIGGER trg_set_updated_at_submission_statuses 
    BEFORE UPDATE ON quotation.submission_statuses 
    FOR EACH ROW EXECUTE FUNCTION quotation.set_updated_at();

CREATE TRIGGER trg_set_updated_at_supplier_quotation_statuses 
    BEFORE UPDATE ON quotation.supplier_quotation_statuses 
    FOR EACH ROW EXECUTE FUNCTION quotation.set_updated_at();

CREATE TRIGGER trg_set_updated_at_supplier_quotations 
    BEFORE UPDATE ON quotation.supplier_quotations 
    FOR EACH ROW EXECUTE FUNCTION quotation.set_updated_at();

CREATE TRIGGER trg_set_updated_at_quoted_prices 
    BEFORE UPDATE ON quotation.quoted_prices 
    FOR EACH ROW EXECUTE FUNCTION quotation.set_updated_at();

-- Trigger para calcular total_items automaticamente
CREATE TRIGGER trg_calculate_total_items_shopping_list_items 
    AFTER INSERT OR DELETE OR UPDATE ON quotation.shopping_list_items 
    FOR EACH ROW EXECUTE FUNCTION quotation.calculate_total_items();

-- =====================================================
-- COMENTÁRIOS DAS TABELAS
-- =====================================================

COMMENT ON TABLE quotation.submission_statuses IS 'Status das submissões de cotação (controle interno do sistema)';
COMMENT ON TABLE quotation.supplier_quotation_statuses IS 'Status das cotações recebidas dos fornecedores';
COMMENT ON TABLE quotation.shopping_lists IS 'Listas de compras criadas pelos estabelecimentos';
COMMENT ON TABLE quotation.shopping_list_items IS 'Itens dentro das listas de compras com decomposição completa para busca refinada';
COMMENT ON TABLE quotation.quotation_submissions IS 'Submissões de cotação quando as listas de compras são enviadas';
COMMENT ON TABLE quotation.supplier_quotations IS 'Cotações recebidas dos fornecedores para itens específicos';
COMMENT ON TABLE quotation.quoted_prices IS 'Preços cotados pelos fornecedores com condições comerciais';

-- =====================================================
-- COMENTÁRIOS DOS CAMPOS
-- =====================================================

-- submission_statuses
COMMENT ON COLUMN quotation.submission_statuses.submission_status_id IS 'Identificador único do status de submissão';
COMMENT ON COLUMN quotation.submission_statuses.name IS 'Nome do status (ex: pending, sent, completed)';
COMMENT ON COLUMN quotation.submission_statuses.description IS 'Descrição detalhada do status';
COMMENT ON COLUMN quotation.submission_statuses.color IS 'Código de cor hexadecimal para interface';
COMMENT ON COLUMN quotation.submission_statuses.is_active IS 'Indica se o status está ativo para uso';

-- supplier_quotation_statuses
COMMENT ON COLUMN quotation.supplier_quotation_statuses.quotation_status_id IS 'Identificador único do status de cotação';
COMMENT ON COLUMN quotation.supplier_quotation_statuses.name IS 'Nome do status (ex: pending, received, accepted)';
COMMENT ON COLUMN quotation.supplier_quotation_statuses.description IS 'Descrição detalhada do status';
COMMENT ON COLUMN quotation.supplier_quotation_statuses.color IS 'Código de cor hexadecimal para interface';
COMMENT ON COLUMN quotation.supplier_quotation_statuses.is_active IS 'Indica se o status está ativo para uso';

-- shopping_lists
COMMENT ON COLUMN quotation.shopping_lists.shopping_list_id IS 'Identificador único da lista de compras';
COMMENT ON COLUMN quotation.shopping_lists.establishment_id IS 'Referência para accounts.establishments';
COMMENT ON COLUMN quotation.shopping_lists.employee_id IS 'Referência para accounts.employees (usuário que criou a lista)';
COMMENT ON COLUMN quotation.shopping_lists.name IS 'Nome da lista de compras';
COMMENT ON COLUMN quotation.shopping_lists.description IS 'Descrição da lista de compras';
COMMENT ON COLUMN quotation.shopping_lists.created_at IS 'Data de criação do registro';
COMMENT ON COLUMN quotation.shopping_lists.updated_at IS 'Data da última atualização do registro';

-- shopping_list_items
COMMENT ON COLUMN quotation.shopping_list_items.shopping_list_item_id IS 'Identificador único do item da lista de compras';
COMMENT ON COLUMN quotation.shopping_list_items.shopping_list_id IS 'Referência para a lista de compras';
COMMENT ON COLUMN quotation.shopping_list_items.item_id IS 'Referência para catalog.items (item genérico - OBRIGATÓRIO)';
COMMENT ON COLUMN quotation.shopping_list_items.product_id IS 'Referência para catalog.products (produto específico se encontrado)';
COMMENT ON COLUMN quotation.shopping_list_items.composition_id IS 'Referência para catalog.compositions (composição do produto)';
COMMENT ON COLUMN quotation.shopping_list_items.variant_type_id IS 'Referência para catalog.variant_types (tipo de variante)';
COMMENT ON COLUMN quotation.shopping_list_items.format_id IS 'Referência para catalog.formats (formato do produto)';
COMMENT ON COLUMN quotation.shopping_list_items.flavor_id IS 'Referência para catalog.flavors (sabor do produto)';
COMMENT ON COLUMN quotation.shopping_list_items.filling_id IS 'Referência para catalog.fillings (recheio do produto)';
COMMENT ON COLUMN quotation.shopping_list_items.nutritional_variant_id IS 'Referência para catalog.nutritional_variants (variante nutricional)';
COMMENT ON COLUMN quotation.shopping_list_items.brand_id IS 'Referência para catalog.brands (marca do produto)';
COMMENT ON COLUMN quotation.shopping_list_items.packaging_id IS 'Referência para catalog.packagings (embalagem do produto)';
COMMENT ON COLUMN quotation.shopping_list_items.quantity_id IS 'Referência para catalog.quantities (quantidade/medida)';
COMMENT ON COLUMN quotation.shopping_list_items.term IS 'Termo original digitado pelo usuário para busca';
COMMENT ON COLUMN quotation.shopping_list_items.quantity IS 'Quantidade solicitada';
COMMENT ON COLUMN quotation.shopping_list_items.notes IS 'Observações sobre o item';

-- quotation_submissions
COMMENT ON COLUMN quotation.quotation_submissions.quotation_submission_id IS 'Identificador único da submissão de cotação';
COMMENT ON COLUMN quotation.quotation_submissions.shopping_list_id IS 'Referência para a lista de compras';
COMMENT ON COLUMN quotation.quotation_submissions.submission_status_id IS 'Referência para o status da submissão';
COMMENT ON COLUMN quotation.quotation_submissions.submission_date IS 'Data de submissão da cotação';
COMMENT ON COLUMN quotation.quotation_submissions.total_items IS 'Total de itens na submissão (calculado automaticamente)';
COMMENT ON COLUMN quotation.quotation_submissions.notes IS 'Observações sobre a submissão';

-- supplier_quotations
COMMENT ON COLUMN quotation.supplier_quotations.supplier_quotation_id IS 'Identificador único da cotação do fornecedor';
COMMENT ON COLUMN quotation.supplier_quotations.quotation_submission_id IS 'Referência para a submissão de cotação';
COMMENT ON COLUMN quotation.supplier_quotations.shopping_list_item_id IS 'Referência para o item da lista de compras';
COMMENT ON COLUMN quotation.supplier_quotations.supplier_id IS 'Referência para accounts.suppliers';
COMMENT ON COLUMN quotation.supplier_quotations.quotation_status_id IS 'Referência para o status da cotação';
COMMENT ON COLUMN quotation.supplier_quotations.quotation_date IS 'Data da cotação do fornecedor';
COMMENT ON COLUMN quotation.supplier_quotations.notes IS 'Observações sobre a cotação do fornecedor';

-- quoted_prices
COMMENT ON COLUMN quotation.quoted_prices.quoted_price_id IS 'Identificador único do preço cotado';
COMMENT ON COLUMN quotation.quoted_prices.supplier_quotation_id IS 'Referência para a cotação do fornecedor';
COMMENT ON COLUMN quotation.quoted_prices.quantity_from IS 'Quantidade mínima para este preço';
COMMENT ON COLUMN quotation.quoted_prices.quantity_to IS 'Quantidade máxima para este preço (NULL = ilimitado)';
COMMENT ON COLUMN quotation.quoted_prices.unit_price IS 'Preço unitário';
COMMENT ON COLUMN quotation.quoted_prices.total_price IS 'Preço total para a quantidade';
COMMENT ON COLUMN quotation.quoted_prices.currency IS 'Moeda da cotação';
COMMENT ON COLUMN quotation.quoted_prices.delivery_time_days IS 'Prazo de entrega em dias';
COMMENT ON COLUMN quotation.quoted_prices.minimum_order_quantity IS 'Quantidade mínima para pedido';
COMMENT ON COLUMN quotation.quoted_prices.payment_terms IS 'Condições de pagamento';
COMMENT ON COLUMN quotation.quoted_prices.validity_days IS 'Validade da cotação em dias';
COMMENT ON COLUMN quotation.quoted_prices.special_conditions IS 'Condições especiais';

-- =====================================================
-- INTEGRAÇÃO COM SISTEMA DE AUDITORIA
-- =====================================================

-- Cria automaticamente as tabelas de auditoria para todas as tabelas do schema quotation
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'audit') THEN
        -- Criar auditoria para todas as tabelas do schema quotation
        PERFORM audit.create_audit_table('quotation', 'submission_statuses');
        PERFORM audit.create_audit_table('quotation', 'supplier_quotation_statuses');
        PERFORM audit.create_audit_table('quotation', 'shopping_lists');
        PERFORM audit.create_audit_table('quotation', 'shopping_list_items');
        PERFORM audit.create_audit_table('quotation', 'quotation_submissions');
        PERFORM audit.create_audit_table('quotation', 'supplier_quotations');
        PERFORM audit.create_audit_table('quotation', 'quoted_prices');
        
        RAISE NOTICE '✅ Auditoria criada para todas as tabelas do schema quotation';
        RAISE NOTICE '🎯 Schema quotation criado com sucesso e integrado ao sistema de auditoria!';
    ELSE
        RAISE NOTICE '⚠️  Schema audit não encontrado. Execute primeiro: \i audit_system.sql';
        RAISE NOTICE '⚠️  Depois execute manualmente:';
        RAISE NOTICE '   SELECT audit.create_audit_table(''quotation'', ''submission_statuses'');';
        RAISE NOTICE '   SELECT audit.create_audit_table(''quotation'', ''supplier_quotation_statuses'');';
        RAISE NOTICE '   SELECT audit.create_audit_table(''quotation'', ''shopping_lists'');';
        RAISE NOTICE '   SELECT audit.create_audit_table(''quotation'', ''shopping_list_items'');';
        RAISE NOTICE '   SELECT audit.create_audit_table(''quotation'', ''quotation_submissions'');';
        RAISE NOTICE '   SELECT audit.create_audit_table(''quotation'', ''supplier_quotations'');';
        RAISE NOTICE '   SELECT audit.create_audit_table(''quotation'', ''quoted_prices'');';
    END IF;
END $$;
