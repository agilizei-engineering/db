-- Tabela de subcategorias específicas
-- Schema: catalogs
-- Tabela: subcategories

-- Esta tabela é criada automaticamente pelo dump principal
-- Este arquivo serve como documentação e referência

/*
CREATE TABLE catalogs.subcategories (
    subcategory_id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    category_id uuid NOT NULL,
    name text NOT NULL,
    description text,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone,
    FOREIGN KEY (category_id) REFERENCES catalogs.categories(category_id)
);
*/

-- Campos principais:
-- subcategory_id: Identificador único da subcategoria (UUID)
-- category_id: Categoria à qual esta subcategoria pertence
-- name: Nome da subcategoria
-- description: Descrição detalhada da subcategoria
-- is_active: Status ativo/inativo da subcategoria
-- created_at: Data de criação
-- updated_at: Data da última atualização

-- Constraints:
-- PRIMARY KEY: subcategory_id
-- NOT NULL: category_id, name, is_active, created_at
-- FOREIGN KEY: category_id -> catalogs.categories(category_id)

-- Triggers:
-- updated_at: Atualiza automaticamente o campo updated_at

-- Auditoria:
-- Automática via schema audit (audit.catalogs__subcategories)

-- Relacionamentos:
-- catalogs.subcategories.category_id -> catalogs.categories.category_id
-- catalogs.items.subcategory_id -> catalogs.subcategories.subcategory_id

-- Comentários da tabela:
-- COMMENT ON TABLE catalogs.subcategories IS 'Subcategorias específicas dentro de uma categoria principal';
-- COMMENT ON COLUMN catalogs.subcategories.subcategory_id IS 'Identificador único da subcategoria';
-- COMMENT ON COLUMN catalogs.subcategories.category_id IS 'Categoria à qual esta subcategoria pertence';
-- COMMENT ON COLUMN catalogs.subcategories.name IS 'Nome da subcategoria';
-- COMMENT ON COLUMN catalogs.subcategories.description IS 'Descrição da subcategoria';
-- COMMENT ON COLUMN catalogs.subcategories.is_active IS 'Status ativo/inativo';
-- COMMENT ON COLUMN catalogs.subcategories.created_at IS 'Data de criação do registro';
-- COMMENT ON COLUMN catalogs.subcategories.updated_at IS 'Data da última atualização';

-- Funcionalidades:
-- Organização hierárquica detalhada
-- Agrupamento específico por tipo de produto
-- Base para itens genéricos
-- Controle de visibilidade por subcategoria

-- Exemplos de subcategorias:
-- - Massas: Espaguete, Penne, Lasanha
-- - Laticínios: Queijos, Leites, Iogurtes
-- - Carnes: Bovinas, Suínas, Aves
-- - Bebidas: Refrigerantes, Sucos, Águas

-- Índices:
-- CREATE INDEX idx_subcategories_category_id ON catalogs.subcategories USING btree (category_id);
-- CREATE INDEX idx_subcategories_name ON catalogs.subcategories USING btree (name);
-- CREATE INDEX idx_subcategories_active ON catalogs.subcategories USING btree (is_active);

-- Índices de texto para busca:
-- CREATE INDEX idx_subcategories_name_gin ON catalogs.subcategories USING gin(to_tsvector('portuguese', name));
-- CREATE INDEX idx_subcategories_description_gin ON catalogs.subcategories USING gin(to_tsvector('portuguese', description));

-- Índices trigram para busca fuzzy (se pg_trgm disponível):
-- CREATE INDEX idx_subcategories_name_trgm ON catalogs.subcategories USING gin(name gin_trgm_ops);
-- CREATE INDEX idx_subcategories_description_trgm ON catalogs.subcategories USING gin(description gin_trgm_ops);
