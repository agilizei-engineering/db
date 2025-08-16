-- Tabela de chaves de API
-- Schema: accounts
-- Tabela: api_keys

-- Esta tabela é criada automaticamente pelo dump principal
-- Este arquivo serve como documentação e referência

/*
CREATE TABLE accounts.api_keys (
    api_key_id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    employee_id uuid NOT NULL,
    name text NOT NULL,
    secret text NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone,
    FOREIGN KEY (employee_id) REFERENCES accounts.employees(employee_id)
);
*/

-- Campos principais:
-- api_key_id: Identificador único da chave de API (UUID)
-- employee_id: Funcionário que possui a chave
-- name: Nome de exibição da chave
-- secret: Chave secreta usada na autenticação
-- is_active: Status ativo/inativo da chave
-- created_at: Data de criação
-- updated_at: Data da última atualização

-- Constraints:
-- PRIMARY KEY: api_key_id
-- NOT NULL: employee_id, name, secret, is_active, created_at
-- FOREIGN KEY: employee_id -> accounts.employees.employee_id

-- Triggers:
-- updated_at: Atualiza automaticamente o campo updated_at

-- Auditoria:
-- Automática via schema audit (audit.accounts__api_keys)

-- Relacionamentos:
-- accounts.api_scopes.api_key_id -> accounts.api_keys.api_key_id

-- Comentários da tabela:
-- COMMENT ON TABLE accounts.api_keys IS 'Chaves de autenticação geradas para integração de APIs por employees';
-- COMMENT ON COLUMN accounts.api_keys.api_key_id IS 'Identificador único da chave de API';
-- COMMENT ON COLUMN accounts.api_keys.employee_id IS 'Employee que possui a chave';
-- COMMENT ON COLUMN accounts.api_keys.name IS 'Nome de exibição da chave';
-- COMMENT ON COLUMN accounts.api_keys.secret IS 'Chave secreta usada na autenticação';
-- COMMENT ON COLUMN accounts.api_keys.created_at IS 'Data de criação do registro';
-- COMMENT ON COLUMN accounts.api_keys.updated_at IS 'Data da última atualização do registro';

-- Funcionalidades:
-- Autenticação via chave de API para serviços externos
-- Controle de acesso por funcionário
-- Geração de chaves seguras para integrações
-- Base para controle de escopos de API

-- Índices:
-- CREATE INDEX idx_api_keys_employee ON accounts.api_keys USING btree (employee_id);
-- CREATE INDEX idx_api_keys_active ON accounts.api_keys USING btree (is_active);
