-- Tabela de composições e matérias-primas
-- Schema: catalogs
-- Tabela: compositions

-- Esta tabela é criada automaticamente pelo dump principal
-- Este arquivo serve como documentação e referência

/*
CREATE TABLE catalogs.compositions (
    composition_id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    name text NOT NULL,
    description text,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone
);
*/

-- Campos principais:
-- composition_id: Identificador único da composição (UUID)
-- name: Nome da composição
-- description: Descrição detalhada da composição
-- is_active: Status ativo/inativo da composição
-- created_at: Data de criação
-- updated_at: Data da última atualização

-- Constraints:
-- PRIMARY KEY: composition_id
-- NOT NULL: name, is_active, created_at

-- Triggers:
-- updated_at: Atualiza automaticamente o campo updated_at

-- Auditoria:
-- Automática via schema audit (audit.catalogs__compositions)

-- Relacionamentos:
-- catalogs.products.composition_id -> catalogs.compositions.composition_id
-- quotation.shopping_list_items.composition_id -> catalogs.compositions.composition_id

-- Comentários da tabela:
-- COMMENT ON TABLE catalogs.compositions IS 'Composição ou matéria-prima do produto (ex: Grano Duro)';
-- COMMENT ON COLUMN catalogs.compositions.composition_id IS 'Identificador único da composição';
-- COMMENT ON COLUMN catalogs.compositions.name IS 'Nome da composição';
-- COMMENT ON COLUMN catalogs.compositions.description IS 'Descrição da composição';
-- COMMENT ON COLUMN catalogs.compositions.is_active IS 'Status ativo/inativo';
-- COMMENT ON COLUMN catalogs.compositions.created_at IS 'Data de criação do registro';
-- COMMENT ON COLUMN catalogs.compositions.updated_at IS 'Data da última atualização';

-- Funcionalidades:
-- Definição de matérias-primas
-- Controle de qualidade por composição
-- Base para produtos específicos
-- Rastreabilidade de ingredientes

-- Exemplos de composições:
-- - Grano Duro (Massas)
-- - Grano Mole (Pães)
-- - Sêmola (Cuscuz)
-- - Farinha de Trigo (Bolos)
-- - Milho (Polenta)

-- Índices:
-- CREATE INDEX idx_compositions_name ON catalogs.compositions USING btree (name);
-- CREATE INDEX idx_compositions_active ON catalogs.compositions USING btree (is_active);

-- Índices de texto para busca:
-- CREATE INDEX idx_compositions_name_gin ON catalogs.compositions USING gin(to_tsvector('portuguese', name));
-- CREATE INDEX idx_compositions_description_gin ON catalogs.compositions USING gin(to_tsvector('portuguese', description));

-- Índices trigram para busca fuzzy (se pg_trgm disponível):
-- CREATE INDEX idx_compositions_name_trgm ON catalogs.compositions USING gin(name gin_trgm_ops);
-- CREATE INDEX idx_compositions_description_trgm ON catalogs.compositions USING gin(description gin_trgm_ops);
