-- Tabela de formatos físicos
-- Schema: catalogs
-- Tabela: formats

-- Esta tabela é criada automaticamente pelo dump principal
-- Este arquivo serve como documentação e referência

/*
CREATE TABLE catalogs.formats (
    format_id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    name text NOT NULL,
    description text,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone
);
*/

-- Campos principais:
-- format_id: Identificador único do formato (UUID)
-- name: Nome do formato
-- description: Descrição detalhada do formato
-- is_active: Status ativo/inativo do formato
-- created_at: Data de criação
-- updated_at: Data da última atualização

-- Constraints:
-- PRIMARY KEY: format_id
-- NOT NULL: name, is_active, created_at

-- Triggers:
-- updated_at: Atualiza automaticamente o campo updated_at

-- Auditoria:
-- Automática via schema audit (audit.catalogs__formats)

-- Relacionamentos:
-- catalogs.products.format_id -> catalogs.formats.format_id
-- quotation.shopping_list_items.format_id -> catalogs.formats.format_id

-- Comentários da tabela:
-- COMMENT ON TABLE catalogs.formats IS 'Formato físico de apresentação (ex: Fatiada, Bolinha)';
-- COMMENT ON COLUMN catalogs.formats.format_id IS 'Identificador único do formato';
-- COMMENT ON COLUMN catalogs.formats.name IS 'Nome do formato';
-- COMMENT ON COLUMN catalogs.formats.description IS 'Descrição do formato';
-- COMMENT ON COLUMN catalogs.formats.is_active IS 'Status ativo/inativo';
-- COMMENT ON COLUMN catalogs.formats.created_at IS 'Data de criação do registro';
-- COMMENT ON COLUMN catalogs.formats.updated_at IS 'Data da última atualização';

-- Funcionalidades:
-- Definição de formatos físicos
-- Controle de apresentação por formato
-- Base para produtos específicos
-- Organização de variações físicas

-- Exemplos de formatos:
-- - Fatiada (Queijos)
-- - Bolinha (Queijos)
-- - Ralado (Queijos)
-- - Inteira (Frutas)
-- - Picada (Carnes)

-- Índices:
-- CREATE INDEX idx_formats_name ON catalogs.formats USING btree (name);
-- CREATE INDEX idx_formats_active ON catalogs.formats USING btree (is_active);

-- Índices de texto para busca:
-- CREATE INDEX idx_formats_name_gin ON catalogs.formats USING gin(to_tsvector('portuguese', name));
-- CREATE INDEX idx_formats_description_gin ON catalogs.formats USING gin(to_tsvector('portuguese', description));

-- Índices trigram para busca fuzzy (se pg_trgm disponível):
-- CREATE INDEX idx_formats_name_trgm ON catalogs.formats USING gin(name gin_trgm_ops);
-- CREATE INDEX idx_formats_description_trgm ON catalogs.formats USING gin(description gin_trgm_ops);
