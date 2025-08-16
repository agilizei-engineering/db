-- Tabela de perfis de sabor
-- Schema: catalogs
-- Tabela: flavors

-- Esta tabela é criada automaticamente pelo dump principal
-- Este arquivo serve como documentação e referência

/*
CREATE TABLE catalogs.flavors (
    flavor_id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    name text NOT NULL,
    description text,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone
);
*/

-- Campos principais:
-- flavor_id: Identificador único do sabor (UUID)
-- name: Nome do sabor
-- description: Descrição detalhada do sabor
-- is_active: Status ativo/inativo do sabor
-- created_at: Data de criação
-- updated_at: Data da última atualização

-- Constraints:
-- PRIMARY KEY: flavor_id
-- NOT NULL: name, is_active, created_at

-- Triggers:
-- updated_at: Atualiza automaticamente o campo updated_at

-- Auditoria:
-- Automática via schema audit (audit.catalogs__flavors)

-- Relacionamentos:
-- catalogs.products.flavor_id -> catalogs.flavors.flavor_id
-- quotation.shopping_list_items.flavor_id -> catalogs.flavors.flavor_id

-- Comentários da tabela:
-- COMMENT ON TABLE catalogs.flavors IS 'Perfil de sabor ou tempero (ex: Picante, Galinha Caipira)';
-- COMMENT ON COLUMN catalogs.flavors.flavor_id IS 'Identificador único do sabor';
-- COMMENT ON COLUMN catalogs.flavors.name IS 'Nome do sabor';
-- COMMENT ON COLUMN catalogs.flavors.description IS 'Descrição do sabor';
-- COMMENT ON COLUMN catalogs.flavors.is_active IS 'Status ativo/inativo';
-- COMMENT ON COLUMN catalogs.flavors.created_at IS 'Data de criação do registro';
-- COMMENT ON COLUMN catalogs.flavors.updated_at IS 'Data da última atualização';

-- Funcionalidades:
-- Definição de perfis de sabor
-- Controle de variedades por sabor
-- Base para produtos específicos
-- Organização de temperos

-- Exemplos de sabores:
-- - Picante (Temperos)
-- - Galinha Caipira (Temperos)
-- - Alho e Óleo (Temperos)
-- - Ervas Finas (Temperos)
-- - Churrasco (Temperos)

-- Índices:
-- CREATE INDEX idx_flavors_name ON catalogs.flavors USING btree (name);
-- CREATE INDEX idx_flavors_active ON catalogs.flavors USING btree (is_active);

-- Índices de texto para busca:
-- CREATE INDEX idx_flavors_name_gin ON catalogs.flavors USING gin(to_tsvector('portuguese', name));
-- CREATE INDEX idx_flavors_description_gin ON catalogs.flavors USING gin(to_tsvector('portuguese', description));

-- Índices trigram para busca fuzzy (se pg_trgm disponível):
-- CREATE INDEX idx_flavors_name_trgm ON catalogs.flavors USING gin(name gin_trgm_ops);
-- CREATE INDEX idx_flavors_description_trgm ON catalogs.flavors USING gin(description gin_trgm_ops);
