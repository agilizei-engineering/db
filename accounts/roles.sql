-- Tabela de papéis e permissões
-- Schema: accounts
-- Tabela: roles

-- Esta tabela é criada automaticamente pelo dump principal
-- Este arquivo serve como documentação e referência

/*
CREATE TABLE accounts.roles (
    role_id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    name text NOT NULL,
    description text,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone
);
*/

-- Campos principais:
-- role_id: Identificador único do papel (UUID)
-- name: Nome do papel
-- description: Descrição detalhada do papel
-- is_active: Status ativo/inativo do papel
-- created_at: Data de criação
-- updated_at: Data da última atualização

-- Constraints:
-- PRIMARY KEY: role_id
-- NOT NULL: name, is_active, created_at

-- Triggers:
-- updated_at: Atualiza automaticamente o campo updated_at

-- Auditoria:
-- Automática via schema audit (audit.accounts__roles)

-- Relacionamentos:
-- accounts.employee_roles.role_id -> accounts.roles.role_id
-- accounts.role_features.role_id -> accounts.roles.role_id

-- Comentários da tabela:
-- COMMENT ON TABLE accounts.roles IS 'Papéis/funções no sistema';
-- COMMENT ON COLUMN accounts.roles.role_id IS 'Identificador único do papel';
-- COMMENT ON COLUMN accounts.roles.name IS 'Nome do papel';
-- COMMENT ON COLUMN accounts.roles.description IS 'Descrição do papel';
-- COMMENT ON COLUMN accounts.roles.is_active IS 'Status ativo/inativo';
-- COMMENT ON COLUMN accounts.roles.created_at IS 'Data de criação';
-- COMMENT ON COLUMN accounts.roles.updated_at IS 'Data da última atualização';

-- Funcionalidades:
-- Definição de papéis e funções no sistema
-- Controle de acesso baseado em papéis (RBAC)
-- Vinculação com funcionalidades específicas
-- Gestão de permissões por usuário
