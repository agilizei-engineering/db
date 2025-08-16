-- Tabela de tipos de embalagem
-- Schema: catalogs
-- Tabela: packagings

-- Esta tabela é criada automaticamente pelo dump principal
-- Este arquivo serve como documentação e referência

/*
CREATE TABLE catalogs.packagings (
    packaging_id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    name text NOT NULL,
    description text,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone
);
*/

-- Campos principais:
-- packaging_id: Identificador único da embalagem (UUID)
-- name: Nome do tipo de embalagem
-- description: Descrição detalhada da embalagem
-- is_active: Status ativo/inativo da embalagem
-- created_at: Data de criação
-- updated_at: Data da última atualização

-- Constraints:
-- PRIMARY KEY: packaging_id
-- NOT NULL: name, is_active, created_at

-- Triggers:
-- updated_at: Atualiza automaticamente o campo updated_at

-- Auditoria:
-- Automática via schema audit (audit.catalogs__packagings)

-- Relacionamentos:
-- catalogs.products.packaging_id -> catalogs.packagings.packaging_id
-- quotation.shopping_list_items.packaging_id -> catalogs.packagings.packaging_id

-- Comentários da tabela:
-- COMMENT ON TABLE catalogs.packagings IS 'Tipo de embalagem do produto (ex: Caixa, Lata, Pacote)';
-- COMMENT ON COLUMN catalogs.packagings.packaging_id IS 'Identificador único da embalagem';
-- COMMENT ON COLUMN catalogs.packagings.name IS 'Nome do tipo de embalagem';
-- COMMENT ON COLUMN catalogs.packagings.description IS 'Descrição da embalagem';
-- COMMENT ON COLUMN catalogs.packagings.is_active IS 'Status ativo/inativo';
-- COMMENT ON COLUMN catalogs.packagings.created_at IS 'Data de criação do registro';
-- COMMENT ON COLUMN catalogs.packagings.updated_at IS 'Data da última atualização';

-- Funcionalidades:
-- Definição de tipos de embalagem
-- Controle de apresentação por embalagem
-- Base para produtos específicos
-- Organização de variações de embalagem

-- Exemplos de embalagens:
-- - Caixa (Cereais)
-- - Lata (Atum)
-- - Pacote (Biscoitos)
-- - Garrafa (Bebidas)
-- - Sache (Temperos)

-- Índices:
-- CREATE INDEX idx_packagings_name ON catalogs.packagings USING btree (name);
-- CREATE INDEX idx_packagings_active ON catalogs.packagings USING btree (is_active);

-- Índices de texto para busca:
-- CREATE INDEX idx_packagings_name_gin ON catalogs.packagings USING gin(to_tsvector('portuguese', name));
-- CREATE INDEX idx_packagings_description_gin ON catalogs.packagings USING gin(to_tsvector('portuguese', description));

-- Índices trigram para busca fuzzy (se pg_trgm disponível):
-- CREATE INDEX idx_packagings_name_trgm ON catalogs.packagings USING gin(name gin_trgm_ops);
-- CREATE INDEX idx_packagings_description_trgm ON catalogs.packagings USING gin(description gin_trgm_ops);
