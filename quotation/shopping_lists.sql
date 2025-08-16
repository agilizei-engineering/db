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
