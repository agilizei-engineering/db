-- Tabela de fornecedores
-- Schema: accounts
-- Tabela: suppliers

-- Esta tabela é criada automaticamente pelo dump principal
-- Este arquivo serve como documentação e referência

/*
CREATE TABLE accounts.suppliers (
    supplier_id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    name text NOT NULL,
    description text,
    is_active boolean DEFAULT true NOT NULL,
    activated_at timestamp with time zone,
    deactivated_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone
);
*/

-- Campos principais:
-- supplier_id: Identificador único do fornecedor (UUID)
-- name: Nome do fornecedor
-- description: Descrição detalhada do fornecedor
-- is_active: Status ativo/inativo do fornecedor
-- activated_at: Data de ativação
-- deactivated_at: Data de desativação
-- created_at: Data de criação
-- updated_at: Data da última atualização

-- Constraints:
-- PRIMARY KEY: supplier_id
-- NOT NULL: name, is_active, created_at

-- Triggers:
-- updated_at: Atualiza automaticamente o campo updated_at

-- Auditoria:
-- Automática via schema audit (audit.accounts__suppliers)

-- Relacionamentos:
-- accounts.employees.supplier_id -> accounts.suppliers.supplier_id
-- quotation.supplier_quotations.supplier_id -> accounts.suppliers.supplier_id

-- Comentários da tabela:
-- COMMENT ON TABLE accounts.suppliers IS 'Fornecedores que podem fornecer produtos para estabelecimentos';
-- COMMENT ON COLUMN accounts.suppliers.supplier_id IS 'Identificador único do fornecedor';
-- COMMENT ON COLUMN accounts.suppliers.name IS 'Nome do fornecedor';
-- COMMENT ON COLUMN accounts.suppliers.description IS 'Descrição do fornecedor';
-- COMMENT ON COLUMN accounts.suppliers.is_active IS 'Status ativo/inativo';
-- COMMENT ON COLUMN accounts.suppliers.activated_at IS 'Data de ativação';
-- COMMENT ON COLUMN accounts.suppliers.deactivated_at IS 'Data de desativação';
-- COMMENT ON COLUMN accounts.suppliers.created_at IS 'Data de criação';
-- COMMENT ON COLUMN accounts.suppliers.updated_at IS 'Data da última atualização';

-- Funcionalidades:
-- Gestão de fornecedores do sistema
-- Controle de status ativo/inativo
-- Rastreamento de datas de ativação/desativação
-- Base para funcionários fornecedores e cotações

-- Índices:
-- CREATE INDEX idx_suppliers_name ON accounts.suppliers USING btree (name);
-- CREATE INDEX idx_suppliers_active ON accounts.suppliers USING btree (is_active);
