-- Tabela de recheios principais
-- Schema: catalogs
-- Tabela: fillings

-- Esta tabela é criada automaticamente pelo dump principal
-- Este arquivo serve como documentação e referência

/*
CREATE TABLE catalogs.fillings (
    filling_id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    name text NOT NULL,
    description text,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone
);
*/

-- Campos principais:
-- filling_id: Identificador único do recheio (UUID)
-- name: Nome do recheio
-- description: Descrição detalhada do recheio
-- is_active: Status ativo/inativo do recheio
-- created_at: Data de criação
-- updated_at: Data da última atualização

-- Constraints:
-- PRIMARY KEY: filling_id
-- NOT NULL: name, is_active, created_at

-- Triggers:
-- updated_at: Atualiza automaticamente o campo updated_at

-- Auditoria:
-- Automática via schema audit (audit.catalogs__fillings)

-- Relacionamentos:
-- catalogs.products.filling_id -> catalogs.fillings.filling_id
-- quotation.shopping_list_items.filling_id -> catalogs.fillings.filling_id

-- Comentários da tabela:
-- COMMENT ON TABLE catalogs.fillings IS 'Recheio principal do produto (ex: Morango, Baunilha)';
-- COMMENT ON COLUMN catalogs.fillings.filling_id IS 'Identificador único do recheio';
-- COMMENT ON COLUMN catalogs.fillings.name IS 'Nome do recheio';
-- COMMENT ON COLUMN catalogs.fillings.description IS 'Descrição do recheio';
-- COMMENT ON COLUMN catalogs.fillings.is_active IS 'Status ativo/inativo';
-- COMMENT ON COLUMN catalogs.fillings.created_at IS 'Data de criação do registro';
-- COMMENT ON COLUMN catalogs.fillings.updated_at IS 'Data da última atualização';

-- Funcionalidades:
-- Definição de recheios de produtos
-- Controle de variedades por recheio
-- Base para produtos específicos
-- Organização de sabores

-- Exemplos de recheios:
-- - Morango (Doces)
-- - Baunilha (Sorvetes)
-- - Chocolate (Bolos)
-- - Carne (Empadas)
-- - Queijo (Pizzas)

-- Índices:
-- CREATE INDEX idx_fillings_name ON catalogs.fillings USING btree (name);
-- CREATE INDEX idx_fillings_active ON catalogs.fillings USING btree (is_active);

-- Índices de texto para busca:
-- CREATE INDEX idx_fillings_name_gin ON catalogs.fillings USING gin(to_tsvector('portuguese', name));
-- CREATE INDEX idx_fillings_description_gin ON catalogs.fillings USING gin(to_tsvector('portuguese', description));

-- Índices trigram para busca fuzzy (se pg_trgm disponível):
-- CREATE INDEX idx_fillings_name_trgm ON catalogs.fillings USING gin(name gin_trgm_ops);
-- CREATE INDEX idx_fillings_description_trgm ON catalogs.fillings USING gin(description gin_trgm_ops);
