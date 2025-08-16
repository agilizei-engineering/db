-- Tabela de itens das listas de compras
-- Schema: quotation
-- Tabela: shopping_list_items

-- Esta tabela é criada automaticamente pelo dump principal
-- Este arquivo serve como documentação e referência

/*
CREATE TABLE quotation.shopping_list_items (
    shopping_list_item_id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    shopping_list_id uuid NOT NULL,
    item_id uuid NOT NULL,
    product_id uuid,
    composition_id uuid,
    variant_type_id uuid,
    format_id uuid,
    flavor_id uuid,
    filling_id uuid,
    nutritional_variant_id uuid,
    brand_id uuid,
    packaging_id uuid,
    quantity_id uuid,
    term text NOT NULL,
    quantity numeric NOT NULL,
    notes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone,
    FOREIGN KEY (shopping_list_id) REFERENCES quotation.shopping_lists(shopping_list_id),
    FOREIGN KEY (item_id) REFERENCES catalogs.items(item_id),
    FOREIGN KEY (product_id) REFERENCES catalogs.products(product_id),
    FOREIGN KEY (composition_id) REFERENCES catalogs.compositions(composition_id),
    FOREIGN KEY (variant_type_id) REFERENCES catalogs.variant_types(variant_type_id),
    FOREIGN KEY (format_id) REFERENCES catalogs.formats(format_id),
    FOREIGN KEY (flavor_id) REFERENCES catalogs.flavors(flavor_id),
    FOREIGN KEY (filling_id) REFERENCES catalogs.fillings(filling_id),
    FOREIGN KEY (nutritional_variant_id) REFERENCES catalogs.nutritional_variants(nutritional_variant_id),
    FOREIGN KEY (brand_id) REFERENCES catalogs.brands(brand_id),
    FOREIGN KEY (packaging_id) REFERENCES catalogs.packagings(packaging_id),
    FOREIGN KEY (quantity_id) REFERENCES catalogs.quantities(quantity_id)
);
*/

-- Campos principais:
-- shopping_list_item_id: Identificador único do item da lista de compras (UUID)
-- shopping_list_id: Referência para a lista de compras
-- item_id: Referência para catalogs.items (item genérico - OBRIGATÓRIO)
-- product_id: Referência para catalogs.products (produto específico se encontrado)
-- composition_id: Referência para catalogs.compositions (composição do produto)
-- variant_type_id: Referência para catalogs.variant_types (tipo de variante)
-- format_id: Referência para catalogs.formats (formato do produto)
-- flavor_id: Referência para catalogs.flavors (sabor do produto)
-- filling_id: Referência para catalogs.fillings (recheio do produto)
-- nutritional_variant_id: Referência para catalogs.nutritional_variants (variante nutricional)
-- brand_id: Referência para catalogs.brands (marca do produto)
-- packaging_id: Referência para catalogs.packagings (embalagem do produto)
-- quantity_id: Referência para catalogs.quantities (quantidade/medida)
-- term: Termo original digitado pelo usuário para busca
-- quantity: Quantidade solicitada
-- notes: Observações sobre o item
-- created_at: Data de criação
-- updated_at: Data da última atualização

-- Constraints:
-- PRIMARY KEY: shopping_list_item_id
-- NOT NULL: shopping_list_id, item_id, term, quantity, created_at
-- FOREIGN KEY: shopping_list_id -> quotation.shopping_lists(shopping_list_id)
-- FOREIGN KEY: item_id -> catalogs.items(item_id)
-- FOREIGN KEY: product_id -> catalogs.products(product_id) (se não for NULL)
-- FOREIGN KEY: composition_id -> catalogs.compositions(composition_id) (se não for NULL)
-- FOREIGN KEY: variant_type_id -> catalogs.variant_types(variant_type_id) (se não for NULL)
-- FOREIGN KEY: format_id -> catalogs.formats(format_id) (se não for NULL)
-- FOREIGN KEY: flavor_id -> catalogs.flavors(flavor_id) (se não for NULL)
-- FOREIGN KEY: filling_id -> catalogs.fillings(filling_id) (se não for NULL)
-- FOREIGN KEY: nutritional_variant_id -> catalogs.nutritional_variants(nutritional_variant_id) (se não for NULL)
-- FOREIGN KEY: brand_id -> catalogs.brands(brand_id) (se não for NULL)
-- FOREIGN KEY: packaging_id -> catalogs.packagings(packaging_id) (se não for NULL)
-- FOREIGN KEY: quantity_id -> catalogs.quantities(quantity_id) (se não for NULL)
-- CHECK: quantity > 0

-- Triggers:
-- updated_at: Atualiza automaticamente o campo updated_at

-- Auditoria:
-- Automática via schema audit (audit.quotation__shopping_list_items)

-- Relacionamentos:
-- quotation.shopping_list_items.shopping_list_id -> quotation.shopping_lists(shopping_list_id)
-- quotation.shopping_list_items.item_id -> catalogs.items(item_id)
-- quotation.shopping_list_items.product_id -> catalogs.products(product_id)
-- quotation.shopping_list_items.composition_id -> catalogs.compositions(composition_id)
-- quotation.shopping_list_items.variant_type_id -> catalogs.variant_types(variant_type_id)
-- quotation.shopping_list_items.format_id -> catalogs.formats(format_id)
-- quotation.shopping_list_items.flavor_id -> catalogs.flavors(flavor_id)
-- quotation.shopping_list_items.filling_id -> catalogs.fillings(filling_id)
-- quotation.shopping_list_items.nutritional_variant_id -> catalogs.nutritional_variants(nutritional_variant_id)
-- quotation.shopping_list_items.brand_id -> catalogs.brands(brand_id)
-- quotation.shopping_list_items.packaging_id -> catalogs.packagings(packaging_id)
-- quotation.shopping_list_items.quantity_id -> catalogs.quantities(quantity_id)
-- quotation.supplier_quotations.shopping_list_item_id -> quotation.shopping_list_items(shopping_list_item_id)

-- Comentários da tabela:
-- COMMENT ON TABLE quotation.shopping_list_items IS 'Itens dentro das listas de compras com decomposição completa para busca refinada';
-- COMMENT ON COLUMN quotation.shopping_list_items.shopping_list_item_id IS 'Identificador único do item da lista de compras';
-- COMMENT ON COLUMN quotation.shopping_list_items.shopping_list_id IS 'Referência para a lista de compras';
-- COMMENT ON COLUMN quotation.shopping_list_items.item_id IS 'Referência para catalog.items (item genérico - OBRIGATÓRIO)';
-- COMMENT ON COLUMN quotation.shopping_list_items.product_id IS 'Referência para catalog.products (produto específico se encontrado)';
-- COMMENT ON COLUMN quotation.shopping_list_items.composition_id IS 'Referência para catalog.compositions (composição do produto)';
-- COMMENT ON COLUMN quotation.shopping_list_items.variant_type_id IS 'Referência para catalog.variant_types (tipo de variante)';
-- COMMENT ON COLUMN quotation.shopping_list_items.format_id IS 'Referência para catalog.formats (formato do produto)';
-- COMMENT ON COLUMN quotation.shopping_list_items.flavor_id IS 'Referência para catalog.flavors (sabor do produto)';
-- COMMENT ON COLUMN quotation.shopping_list_items.filling_id IS 'Referência para catalog.fillings (recheio do produto)';
-- COMMENT ON COLUMN quotation.shopping_list_items.nutritional_variant_id IS 'Referência para catalog.nutritional_variants (variante nutricional)';
-- COMMENT ON COLUMN quotation.shopping_list_items.brand_id IS 'Referência para catalog.brands (marca do produto)';
-- COMMENT ON COLUMN quotation.shopping_list_items.packaging_id IS 'Referência para catalog.packagings (embalagem do produto)';
-- COMMENT ON COLUMN quotation.shopping_list_items.quantity_id IS 'Referência para catalog.quantities (quantidade/medida)';
-- COMMENT ON COLUMN quotation.shopping_list_items.term IS 'Termo original digitado pelo usuário para busca';
-- COMMENT ON COLUMN quotation.shopping_list_items.quantity IS 'Quantidade solicitada';
-- COMMENT ON COLUMN quotation.shopping_list_items.notes IS 'Observações sobre o item';
-- COMMENT ON COLUMN quotation.shopping_list_items.created_at IS 'Data de criação do registro';
-- COMMENT ON COLUMN quotation.shopping_list_items.updated_at IS 'Data da última atualização';

-- Funcionalidades:
-- Gestão de itens nas listas de compras
-- Decomposição completa para busca refinada
-- Suporte a produtos específicos e genéricos
-- Controle de quantidades solicitadas
-- Base para cotações de fornecedores
-- Rastreamento de termos de busca originais

-- Exemplos de uso:
-- - Adição de itens genéricos (ex: "arroz")
-- - Adição de produtos específicos (ex: "arroz branco tipo 1 marca X")
-- - Controle de quantidades por item
-- - Observações e notas por item
-- - Busca refinada por atributos

-- Índices:
-- CREATE INDEX idx_shopping_list_items_shopping_list_id ON quotation.shopping_list_items USING btree (shopping_list_id);
-- CREATE INDEX idx_shopping_list_items_item_id ON quotation.shopping_list_items USING btree (item_id);
-- CREATE INDEX idx_shopping_list_items_product_id ON quotation.shopping_list_items USING btree (product_id);
-- CREATE INDEX idx_shopping_list_items_brand_id ON quotation.shopping_list_items USING btree (brand_id);
-- CREATE INDEX idx_shopping_list_items_quantity ON quotation.shopping_list_items USING btree (quantity);
-- CREATE INDEX idx_shopping_list_items_created_at ON quotation.shopping_list_items USING btree (created_at);

-- Índices compostos:
-- CREATE INDEX idx_shopping_list_items_list_item ON quotation.shopping_list_items USING btree (shopping_list_id, item_id);
-- CREATE INDEX idx_shopping_list_items_list_product ON quotation.shopping_list_items USING btree (shopping_list_id, product_id);
-- CREATE INDEX idx_shopping_list_items_item_brand ON quotation.shopping_list_items USING btree (item_id, brand_id);

-- Índices de texto para busca:
-- CREATE INDEX idx_shopping_list_items_term_gin ON quotation.shopping_list_items USING gin(to_tsvector('portuguese', term));
-- CREATE INDEX idx_shopping_list_items_notes_gin ON quotation.shopping_list_items USING gin(to_tsvector('portuguese', notes));

-- Índices trigram para busca fuzzy (se pg_trgm disponível):
-- CREATE INDEX idx_shopping_list_items_term_trgm ON quotation.shopping_list_items USING gin(term gin_trgm_ops);
-- CREATE INDEX idx_shopping_list_items_notes_trgm ON quotation.shopping_list_items USING gin(notes gin_trgm_ops);
