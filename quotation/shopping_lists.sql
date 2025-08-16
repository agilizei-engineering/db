-- Tabela de listas de compras
-- Schema: quotation
-- Tabela: shopping_lists

-- Esta tabela é criada automaticamente pelo quotation_schema.sql
-- Este arquivo serve como documentação e referência

/*
CREATE TABLE quotation.shopping_lists (
    shopping_list_id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    establishment_id uuid NOT NULL,
    name text NOT NULL,
    description text,
    status text DEFAULT 'DRAFT',
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone,
    FOREIGN KEY (establishment_id) REFERENCES accounts.establishments(establishment_id)
);
*/

-- Campos principais:
-- shopping_list_id: Identificador único da lista de compras (UUID)
-- establishment_id: Estabelecimento que criou a lista
-- name: Nome da lista de compras
-- description: Descrição detalhada da lista
-- status: Status atual da lista (DRAFT, ACTIVE, COMPLETED, CANCELLED)
-- created_at: Data de criação
-- updated_at: Data da última atualização

-- Constraints:
-- PRIMARY KEY: shopping_list_id
-- FOREIGN KEY: establishment_id -> accounts.establishments.establishment_id

-- Triggers:
-- updated_at: Atualiza automaticamente o campo updated_at

-- Auditoria:
-- Automática via schema audit (audit.quotation__shopping_lists)

-- Relacionamentos:
-- quotation.shopping_list_items.shopping_list_id -> quotation.shopping_lists.shopping_list_id
-- quotation.quotation_submissions.shopping_list_id -> quotation.shopping_lists.shopping_list_id

-- Funcionalidades:
-- Criação de listas organizadas por estabelecimento
-- Controle de status da lista
-- Rastreamento de mudanças via auditoria
-- Base para submissão de cotações

-- Comentários da tabela:
-- COMMENT ON TABLE quotation.shopping_lists IS 'Listas de compras criadas pelos estabelecimentos';
-- COMMENT ON COLUMN quotation.shopping_lists.shopping_list_id IS 'Identificador único da lista de compras';
-- COMMENT ON COLUMN quotation.shopping_lists.establishment_id IS 'Referência para accounts.establishments';
-- COMMENT ON COLUMN quotation.shopping_lists.name IS 'Nome da lista de compras';
-- COMMENT ON COLUMN quotation.shopping_lists.description IS 'Descrição da lista de compras';
-- COMMENT ON COLUMN quotation.shopping_lists.status IS 'Status atual da lista (DRAFT, ACTIVE, COMPLETED, CANCELLED)';
-- COMMENT ON COLUMN quotation.shopping_lists.created_at IS 'Data de criação do registro';
-- COMMENT ON COLUMN quotation.shopping_lists.updated_at IS 'Data da última atualização';

-- Índices:
-- CREATE INDEX idx_shopping_lists_establishment_id ON quotation.shopping_lists USING btree (establishment_id);
-- CREATE INDEX idx_shopping_lists_name ON quotation.shopping_lists USING btree (name);
-- CREATE INDEX idx_shopping_lists_status ON quotation.shopping_lists USING btree (status);
-- CREATE INDEX idx_shopping_lists_created_at ON quotation.shopping_lists USING btree (created_at);

-- Índices compostos:
-- CREATE INDEX idx_shopping_lists_establishment_status ON quotation.shopping_lists USING btree (establishment_id, status);
-- CREATE INDEX idx_shopping_lists_establishment_date ON quotation.shopping_lists USING btree (establishment_id, created_at);

-- Índices de texto para busca:
-- CREATE INDEX idx_shopping_lists_name_gin ON quotation.shopping_lists USING gin(to_tsvector('portuguese', name));
-- CREATE INDEX idx_shopping_lists_description_gin ON quotation.shopping_lists USING gin(to_tsvector('portuguese', description));

-- Índices trigram para busca fuzzy (se pg_trgm disponível):
-- CREATE INDEX idx_shopping_lists_name_trgm ON quotation.shopping_lists USING gin(name gin_trgm_ops);
-- CREATE INDEX idx_shopping_lists_description_trgm ON quotation.shopping_lists USING gin(description gin_trgm_ops);
