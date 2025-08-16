-- Tabela de produtos do catálogo
-- Schema: catalogs
-- Tabela: products

-- Esta tabela é criada automaticamente pelo dump principal
-- Este arquivo serve como documentação e referência

/*
CREATE TABLE catalogs.products (
    product_id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    name text NOT NULL,
    description text,
    category_id uuid,
    subcategory_id uuid,
    brand_id uuid,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone,
    FOREIGN KEY (category_id) REFERENCES catalogs.categories(category_id),
    FOREIGN KEY (subcategory_id) REFERENCES catalogs.subcategories(subcategory_id),
    FOREIGN KEY (brand_id) REFERENCES catalogs.brands(brand_id)
);
*/

-- Campos principais:
-- product_id: Identificador único do produto (UUID)
-- name: Nome do produto
-- description: Descrição detalhada do produto
-- category_id: Categoria principal do produto
-- subcategory_id: Subcategoria do produto
-- brand_id: Marca do produto
-- is_active: Status ativo/inativo do produto
-- created_at: Data de criação
-- updated_at: Data da última atualização

-- Constraints:
-- PRIMARY KEY: product_id
-- FOREIGN KEY: category_id -> catalogs.categories.category_id
-- FOREIGN KEY: subcategory_id -> catalogs.subcategories.subcategory_id
-- FOREIGN KEY: brand_id -> catalogs.brands.brand_id

-- Triggers:
-- updated_at: Atualiza automaticamente o campo updated_at

-- Auditoria:
-- Automática via schema audit (audit.catalogs__products)

-- Relacionamentos:
-- catalogs.variants.product_id -> catalogs.products.product_id
-- quotation.shopping_list_items.product_id -> catalogs.products.product_id

-- Funcionalidades:
-- Produto base com informações gerais
-- Organização hierárquica por categoria e subcategoria
-- Vinculação com marca específica
-- Suporte a múltiplas variações por produto

-- Comentários da tabela:
-- COMMENT ON TABLE catalogs.products IS 'Produto padronizado resultante da combinação de um item com suas variações e atributos dimensionais';
-- COMMENT ON COLUMN catalogs.products.product_id IS 'Identificador único do produto';
-- COMMENT ON COLUMN catalogs.products.item_id IS 'FK para o item base deste produto';
-- COMMENT ON COLUMN catalogs.products.composition_id IS 'FK para a composição (matéria-prima)';
-- COMMENT ON COLUMN catalogs.products.variant_type_id IS 'FK para o tipo de variação';
-- COMMENT ON COLUMN catalogs.products.format_id IS 'FK para o formato físico';
-- COMMENT ON COLUMN catalogs.products.flavor_id IS 'FK para o sabor';
-- COMMENT ON COLUMN catalogs.products.filling_id IS 'FK para o recheio';
-- COMMENT ON COLUMN catalogs.products.nutritional_variant_id IS 'FK para a variação nutricional';
-- COMMENT ON COLUMN catalogs.products.brand_id IS 'FK para a marca';
-- COMMENT ON COLUMN catalogs.products.packaging_id IS 'FK para a embalagem';
-- COMMENT ON COLUMN catalogs.products.quantity_id IS 'FK para a quantidade';
-- COMMENT ON COLUMN catalogs.products.visibility IS 'Define se o produto é público ou privado';
-- COMMENT ON COLUMN catalogs.products.created_at IS 'Data de criação do registro';
-- COMMENT ON COLUMN catalogs.products.updated_at IS 'Data da última atualização';

-- Índices:
-- CREATE INDEX idx_products_item_id ON catalogs.products USING btree (item_id);
-- CREATE INDEX idx_products_brand_id ON catalogs.products USING btree (brand_id);
-- CREATE INDEX idx_products_visibility ON catalogs.products USING btree (visibility);
-- CREATE INDEX idx_products_active ON catalogs.products USING btree (is_active);

-- Índices compostos:
-- CREATE INDEX idx_products_item_brand ON catalogs.products USING btree (item_id, brand_id);
-- CREATE INDEX idx_products_composition_variant ON catalogs.products USING btree (composition_id, variant_type_id);

-- Índices de texto para busca:
-- CREATE INDEX idx_products_item_name_gin ON catalogs.products USING gin(to_tsvector('portuguese', (SELECT name FROM catalogs.items WHERE item_id = products.item_id)));

-- Índices para filtros comuns:
-- CREATE INDEX idx_products_visibility_active ON catalogs.products USING btree (visibility, is_active) WHERE visibility = 'PUBLIC' AND is_active = true;
