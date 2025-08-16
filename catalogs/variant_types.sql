-- Tabela de tipos de variação
-- Schema: catalogs
-- Tabela: variant_types

-- Esta tabela é criada automaticamente pelo dump principal
-- Este arquivo serve como documentação e referência

/*
CREATE TABLE catalogs.variant_types (
    variant_type_id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    name text NOT NULL,
    description text,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone
);
*/

-- Campos principais:
-- variant_type_id: Identificador único do tipo de variação (UUID)
-- name: Nome do tipo de variação
-- description: Descrição detalhada do tipo de variação
-- is_active: Status ativo/inativo do tipo de variação
-- created_at: Data de criação
-- updated_at: Data da última atualização

-- Constraints:
-- PRIMARY KEY: variant_type_id
-- NOT NULL: name, is_active, created_at

-- Triggers:
-- updated_at: Atualiza automaticamente o campo updated_at

-- Auditoria:
-- Automática via schema audit (audit.catalogs__variant_types)

-- Relacionamentos:
-- catalogs.products.variant_type_id -> catalogs.variant_types.variant_type_id
-- quotation.shopping_list_items.variant_type_id -> catalogs.variant_types.variant_type_id

-- Comentários da tabela:
-- COMMENT ON TABLE catalogs.variant_types IS 'Tipo ou variação específica do item (ex: Espaguete nº 08)';
-- COMMENT ON COLUMN catalogs.variant_types.variant_type_id IS 'Identificador único do tipo';
-- COMMENT ON COLUMN catalogs.variant_types.name IS 'Nome do tipo de variação';
-- COMMENT ON COLUMN catalogs.variant_types.description IS 'Descrição do tipo de variação';
-- COMMENT ON COLUMN catalogs.variant_types.is_active IS 'Status ativo/inativo';
-- COMMENT ON COLUMN catalogs.variant_types.created_at IS 'Data de criação do registro';
-- COMMENT ON COLUMN catalogs.variant_types.updated_at IS 'Data da última atualização';

-- Funcionalidades:
-- Definição de tipos de variação
-- Controle de especificidades por tipo
-- Base para produtos específicos
-- Organização de variações detalhadas

-- Exemplos de tipos de variação:
-- - Espaguete nº 08 (Massas)
-- - Espaguete nº 12 (Massas)
-- - Penne Rigate (Massas)
-- - Lasanha Verde (Massas)
-- - Arroz Branco Tipo 1 (Grãos)

-- Índices:
-- CREATE INDEX idx_variant_types_name ON catalogs.variant_types USING btree (name);
-- CREATE INDEX idx_variant_types_active ON catalogs.variant_types USING btree (is_active);

-- Índices de texto para busca:
-- CREATE INDEX idx_variant_types_name_gin ON catalogs.variant_types USING gin(to_tsvector('portuguese', name));
-- CREATE INDEX idx_variant_types_description_gin ON catalogs.variant_types USING gin(to_tsvector('portuguese', description));

-- Índices trigram para busca fuzzy (se pg_trgm disponível):
-- CREATE INDEX idx_variant_types_name_trgm ON catalogs.variant_types USING gin(name gin_trgm_ops);
-- CREATE INDEX idx_variant_types_description_trgm ON catalogs.variant_types USING gin(description gin_trgm_ops);
