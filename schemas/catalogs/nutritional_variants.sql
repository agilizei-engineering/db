-- Tabela de variações nutricionais
-- Schema: catalogs
-- Tabela: nutritional_variants

-- Esta tabela é criada automaticamente pelo dump principal
-- Este arquivo serve como documentação e referência

/*
CREATE TABLE catalogs.nutritional_variants (
    nutritional_variant_id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    name text NOT NULL,
    description text,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone
);
*/

-- Campos principais:
-- nutritional_variant_id: Identificador único da variação nutricional (UUID)
-- name: Nome da variação nutricional
-- description: Descrição detalhada da variação nutricional
-- is_active: Status ativo/inativo da variação nutricional
-- created_at: Data de criação
-- updated_at: Data da última atualização

-- Constraints:
-- PRIMARY KEY: nutritional_variant_id
-- NOT NULL: name, is_active, created_at

-- Triggers:
-- updated_at: Atualiza automaticamente o campo updated_at

-- Auditoria:
-- Automática via schema audit (audit.catalogs__nutritional_variants)

-- Relacionamentos:
-- catalogs.products.nutritional_variant_id -> catalogs.nutritional_variants.nutritional_variant_id
-- quotation.shopping_list_items.nutritional_variant_id -> catalogs.nutritional_variants.nutritional_variant_id

-- Comentários da tabela:
-- COMMENT ON TABLE catalogs.nutritional_variants IS 'Variações nutricionais (ex: Light, Zero, Sem Lactose)';
-- COMMENT ON COLUMN catalogs.nutritional_variants.nutritional_variant_id IS 'Identificador único da variação';
-- COMMENT ON COLUMN catalogs.nutritional_variants.name IS 'Nome da variação nutricional';
-- COMMENT ON COLUMN catalogs.nutritional_variants.description IS 'Descrição da variação nutricional';
-- COMMENT ON COLUMN catalogs.nutritional_variants.is_active IS 'Status ativo/inativo';
-- COMMENT ON COLUMN catalogs.nutritional_variants.created_at IS 'Data de criação do registro';
-- COMMENT ON COLUMN catalogs.nutritional_variants.updated_at IS 'Data da última atualização';

-- Funcionalidades:
-- Definição de variações nutricionais
-- Controle de opções dietéticas
-- Base para produtos específicos
-- Organização de alternativas saudáveis

-- Exemplos de variações nutricionais:
-- - Light (Reduzido em calorias)
-- - Zero (Sem açúcar)
-- - Sem Lactose (Para intolerantes)
-- - Integral (Rico em fibras)
-- - Orgânico (Sem agrotóxicos)

-- Índices:
-- CREATE INDEX idx_nutritional_variants_name ON catalogs.nutritional_variants USING btree (name);
-- CREATE INDEX idx_nutritional_variants_active ON catalogs.nutritional_variants USING btree (is_active);

-- Índices de texto para busca:
-- CREATE INDEX idx_nutritional_variants_name_gin ON catalogs.nutritional_variants USING gin(to_tsvector('portuguese', name));
-- CREATE INDEX idx_nutritional_variants_description_gin ON catalogs.nutritional_variants USING gin(to_tsvector('portuguese', description));

-- Índices trigram para busca fuzzy (se pg_trgm disponível):
-- CREATE INDEX idx_nutritional_variants_name_trgm ON catalogs.nutritional_variants USING gin(name gin_trgm_ops);
-- CREATE INDEX idx_nutritional_variants_description_trgm ON catalogs.nutritional_variants USING gin(description gin_trgm_ops);
