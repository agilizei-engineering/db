-- Tabela de itens genéricos
-- Schema: catalogs
-- Tabela: items

-- Esta tabela é criada automaticamente pelo dump principal
-- Este arquivo serve como documentação e referência

/*
CREATE TABLE catalogs.items (
    item_id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    subcategory_id uuid NOT NULL,
    name text NOT NULL,
    description text,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone,
    FOREIGN KEY (subcategory_id) REFERENCES catalogs.subcategories(subcategory_id)
);
*/

-- Campos principais:
-- item_id: Identificador único do item (UUID)
-- subcategory_id: Subcategoria à qual este item pertence
-- name: Nome genérico do item
-- description: Descrição detalhada do item
-- is_active: Status ativo/inativo do item
-- created_at: Data de criação
-- updated_at: Data da última atualização

-- Constraints:
-- PRIMARY KEY: item_id
-- NOT NULL: subcategory_id, name, is_active, created_at
-- FOREIGN KEY: subcategory_id -> catalogs.subcategories(subcategory_id)

-- Triggers:
-- updated_at: Atualiza automaticamente o campo updated_at

-- Auditoria:
-- Automática via schema audit (audit.catalogs__items)

-- Relacionamentos:
-- catalogs.items.subcategory_id -> catalogs.subcategories.subcategory_id
-- catalogs.products.item_id -> catalogs.items.item_id
-- quotation.shopping_list_items.item_id -> catalogs.items.item_id

-- Comentários da tabela:
-- COMMENT ON TABLE catalogs.items IS 'Itens genéricos que representam o núcleo de um produto';
-- COMMENT ON COLUMN catalogs.items.item_id IS 'Identificador único do item';
-- COMMENT ON COLUMN catalogs.items.subcategory_id IS 'Subcategoria à qual este item pertence';
-- COMMENT ON COLUMN catalogs.items.name IS 'Nome genérico do item';
-- COMMENT ON COLUMN catalogs.items.description IS 'Descrição do item';
-- COMMENT ON COLUMN catalogs.items.is_active IS 'Status ativo/inativo';
-- COMMENT ON COLUMN catalogs.items.created_at IS 'Data de criação do registro';
-- COMMENT ON COLUMN catalogs.items.updated_at IS 'Data da última atualização';

-- Funcionalidades:
-- Representação genérica de produtos
-- Base para variações específicas
-- Organização hierárquica de produtos
-- Controle de visibilidade por item

-- Exemplos de itens:
-- - Massas: Espaguete, Penne, Lasanha
-- - Laticínios: Queijo, Leite, Iogurte
-- - Carnes: Carne Bovina, Frango, Porco
-- - Bebidas: Refrigerante, Suco, Água

-- Índices:
-- CREATE INDEX idx_items_subcategory_id ON catalogs.items USING btree (subcategory_id);
-- CREATE INDEX idx_items_name ON catalogs.items USING btree (name);
-- CREATE INDEX idx_items_active ON catalogs.items USING btree (is_active);

-- Índices de texto para busca:
-- CREATE INDEX idx_items_name_gin ON catalogs.items USING gin(to_tsvector('portuguese', name));
-- CREATE INDEX idx_items_description_gin ON catalogs.items USING gin(to_tsvector('portuguese', description));

-- Índices trigram para busca fuzzy (se pg_trgm disponível):
-- CREATE INDEX idx_items_name_trgm ON catalogs.items USING gin(name gin_trgm_ops);
-- CREATE INDEX idx_items_description_trgm ON catalogs.items USING gin(description gin_trgm_ops);
