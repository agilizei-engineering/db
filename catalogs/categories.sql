-- Tabela de categorias principais
-- Schema: catalogs
-- Tabela: categories

-- Esta tabela é criada automaticamente pelo dump principal
-- Este arquivo serve como documentação e referência

/*
CREATE TABLE catalogs.categories (
    category_id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    name text NOT NULL,
    description text,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone
);
*/

-- Campos principais:
-- category_id: Identificador único da categoria (UUID)
-- name: Nome da categoria
-- description: Descrição detalhada da categoria
-- is_active: Status ativo/inativo da categoria
-- created_at: Data de criação
-- updated_at: Data da última atualização

-- Constraints:
-- PRIMARY KEY: category_id
-- NOT NULL: name, is_active, created_at

-- Triggers:
-- updated_at: Atualiza automaticamente o campo updated_at

-- Auditoria:
-- Automática via schema audit (audit.catalogs__categories)

-- Relacionamentos:
-- catalogs.subcategories.category_id -> catalogs.categories.category_id

-- Comentários da tabela:
-- COMMENT ON TABLE catalogs.categories IS 'Categorias amplas para agrupamento dos produtos';
-- COMMENT ON COLUMN catalogs.categories.category_id IS 'Identificador único da categoria';
-- COMMENT ON COLUMN catalogs.categories.name IS 'Nome da categoria';
-- COMMENT ON COLUMN catalogs.categories.description IS 'Descrição da categoria';
-- COMMENT ON COLUMN catalogs.categories.is_active IS 'Status ativo/inativo';
-- COMMENT ON COLUMN catalogs.categories.created_at IS 'Data de criação do registro';
-- COMMENT ON COLUMN catalogs.categories.updated_at IS 'Data da última atualização';

-- Funcionalidades:
-- Organização hierárquica de produtos
-- Agrupamento lógico por tipo de produto
-- Base para subcategorias específicas
-- Controle de visibilidade por categoria

-- Exemplos de categorias:
-- - Massas
-- - Laticínios
-- - Carnes
-- - Bebidas
-- - Higiene
-- - Limpeza

-- Índices:
-- CREATE INDEX idx_categories_name ON catalogs.categories USING btree (name);
-- CREATE INDEX idx_categories_active ON catalogs.categories USING btree (is_active);

-- Índices de texto para busca:
-- CREATE INDEX idx_categories_name_gin ON catalogs.categories USING gin(to_tsvector('portuguese', name));
-- CREATE INDEX idx_categories_description_gin ON catalogs.categories USING gin(to_tsvector('portuguese', description));

-- Índices trigram para busca fuzzy (se pg_trgm disponível):
-- CREATE INDEX idx_categories_name_trgm ON catalogs.categories USING gin(name gin_trgm_ops);
-- CREATE INDEX idx_categories_description_trgm ON catalogs.categories USING gin(description gin_trgm_ops);
