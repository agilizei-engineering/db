-- Tabela de estabelecimentos comerciais
-- Schema: accounts
-- Tabela: establishments

-- Esta tabela é criada automaticamente pelo dump principal
-- Este arquivo serve como documentação e referência

/*
CREATE TABLE accounts.establishments (
    establishment_id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
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
-- establishment_id: Identificador único do estabelecimento (UUID)
-- name: Nome do estabelecimento
-- description: Descrição detalhada do estabelecimento
-- is_active: Status ativo/inativo do estabelecimento
-- activated_at: Data de ativação
-- deactivated_at: Data de desativação
-- created_at: Data de criação
-- updated_at: Data da última atualização

-- Constraints:
-- PRIMARY KEY: establishment_id
-- NOT NULL: name, is_active, created_at

-- Triggers:
-- updated_at: Atualiza automaticamente o campo updated_at

-- Auditoria:
-- Automática via schema audit (audit.accounts__establishments)

-- Relacionamentos:
-- accounts.employees.establishment_id -> accounts.establishments.establishment_id
-- accounts.establishment_business_data.establishment_id -> accounts.establishments.establishment_id
-- accounts.establishment_addresses.establishment_id -> accounts.establishments.establishment_id
-- quotation.shopping_lists.establishment_id -> accounts.establishments.establishment_id

-- Comentários da tabela:
-- COMMENT ON TABLE accounts.establishments IS 'Estabelecimentos que utilizam o sistema e possuem funcionários';
-- COMMENT ON COLUMN accounts.establishments.establishment_id IS 'Identificador único do estabelecimento';
-- COMMENT ON COLUMN accounts.establishments.name IS 'Nome do estabelecimento';
-- COMMENT ON COLUMN accounts.establishments.is_active IS 'Indica se o estabelecimento está ativo';
-- COMMENT ON COLUMN accounts.establishments.activated_at IS 'Data de ativação';
-- COMMENT ON COLUMN accounts.establishments.deactivated_at IS 'Data de desativação';
-- COMMENT ON COLUMN accounts.establishments.created_at IS 'Data de criação do registro';
-- COMMENT ON COLUMN accounts.establishments.updated_at IS 'Data da última atualização do registro';

-- Funcionalidades:
-- Gestão de estabelecimentos comerciais
-- Controle de status ativo/inativo
-- Rastreamento de datas de ativação/desativação
-- Base para funcionários e dados empresariais
