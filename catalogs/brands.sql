-- Tabela de marcas e fabricantes
-- Schema: catalogs
-- Tabela: brands

-- Esta tabela é criada automaticamente pelo dump principal
-- Este arquivo serve como documentação e referência

/*
CREATE TABLE catalogs.brands (
    brand_id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    name text NOT NULL,
    description text,
    logo_url text,
    website_url text,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone
);
*/

-- Campos principais:
-- brand_id: Identificador único da marca (UUID)
-- name: Nome da marca
-- description: Descrição detalhada da marca
-- logo_url: URL do logo da marca
-- website_url: URL do site oficial da marca
-- is_active: Status ativo/inativo da marca
-- created_at: Data de criação
-- updated_at: Data da última atualização

-- Constraints:
-- PRIMARY KEY: brand_id
-- NOT NULL: name, is_active, created_at
-- CHECK: logo_url válido via aux.validate_url() (se não for NULL)
-- CHECK: website_url válido via aux.validate_url() (se não for NULL)

-- Triggers:
-- updated_at: Atualiza automaticamente o campo updated_at
-- logo_url_validation: Valida URL do logo automaticamente
-- website_url_validation: Valida URL do site automaticamente

-- Auditoria:
-- Automática via schema audit (audit.catalogs__brands)

-- Relacionamentos:
-- catalogs.products.brand_id -> catalogs.brands.brand_id
-- quotation.shopping_list_items.brand_id -> catalogs.brands.brand_id

-- Comentários da tabela:
-- COMMENT ON TABLE catalogs.brands IS 'Marca ou fabricante do produto';
-- COMMENT ON COLUMN catalogs.brands.brand_id IS 'Identificador único da marca';
-- COMMENT ON COLUMN catalogs.brands.name IS 'Nome da marca';
-- COMMENT ON COLUMN catalogs.brands.description IS 'Descrição da marca';
-- COMMENT ON COLUMN catalogs.brands.logo_url IS 'URL do logo da marca';
-- COMMENT ON COLUMN catalogs.brands.website_url IS 'URL do site oficial da marca';
-- COMMENT ON COLUMN catalogs.brands.is_active IS 'Status ativo/inativo';
-- COMMENT ON COLUMN catalogs.brands.created_at IS 'Data de criação do registro';
-- COMMENT ON COLUMN catalogs.brands.updated_at IS 'Data da última atualização';

-- Funcionalidades:
-- Gestão de marcas e fabricantes
-- Controle de visibilidade por marca
-- Base para produtos específicos
-- Suporte a logos e sites oficiais

-- Exemplos de marcas:
-- - Barilla (Massas)
-- - Nestlé (Alimentos)
-- - Coca-Cola (Bebidas)
-- - Unilever (Higiene e Limpeza)

-- Índices:
-- CREATE INDEX idx_brands_name ON catalogs.brands USING btree (name);
-- CREATE INDEX idx_brands_active ON catalogs.brands USING btree (is_active);

-- Índices de texto para busca:
-- CREATE INDEX idx_brands_name_gin ON catalogs.brands USING gin(to_tsvector('portuguese', name));
-- CREATE INDEX idx_brands_description_gin ON catalogs.brands USING gin(to_tsvector('portuguese', description));

-- Índices trigram para busca fuzzy (se pg_trgm disponível):
-- CREATE INDEX idx_brands_name_trgm ON catalogs.brands USING gin(name gin_trgm_ops);
-- CREATE INDEX idx_brands_description_trgm ON catalogs.brands USING gin(description gin_trgm_ops);
