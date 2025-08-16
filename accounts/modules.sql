-- Tabela de módulos do sistema
-- Schema: accounts
-- Tabela: modules

-- Esta tabela é criada automaticamente pelo dump principal
-- Este arquivo serve como documentação e referência

/*
CREATE TABLE accounts.modules (
    module_id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    name text NOT NULL,
    description text,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone
);
*/

-- Campos principais:
-- module_id: Identificador único do módulo (UUID)
-- name: Nome do módulo
-- description: Descrição detalhada do módulo
-- is_active: Status ativo/inativo do módulo
-- created_at: Data de criação
-- updated_at: Data da última atualização

-- Constraints:
-- PRIMARY KEY: module_id
-- NOT NULL: name, is_active, created_at

-- Triggers:
-- updated_at: Atualiza automaticamente o campo updated_at

-- Auditoria:
-- Automática via schema audit (audit.accounts__modules)

-- Relacionamentos:
-- accounts.features.module_id -> accounts.modules.module_id
-- accounts.apis.module_id -> accounts.modules.module_id

-- Comentários da tabela:
-- COMMENT ON TABLE accounts.modules IS 'Módulos funcionais do sistema (ex: Lista de Compras)';
-- COMMENT ON COLUMN accounts.modules.module_id IS 'Identificador único do módulo';
-- COMMENT ON COLUMN accounts.modules.name IS 'Nome do módulo';
-- COMMENT ON COLUMN accounts.modules.description IS 'Descrição do módulo';
-- COMMENT ON COLUMN accounts.modules.is_active IS 'Status ativo/inativo';
-- COMMENT ON COLUMN accounts.modules.created_at IS 'Data de criação';
-- COMMENT ON COLUMN accounts.modules.updated_at IS 'Data da última atualização';

-- Funcionalidades:
-- Organização hierárquica de funcionalidades
-- Agrupamento lógico de recursos do sistema
-- Base para controle de acesso por módulo
-- Estrutura organizacional do sistema

-- Exemplos de módulos:
-- - Lista de Compras
-- - Catálogo de Produtos
-- - Gestão de Usuários
-- - Relatórios
-- - Configurações
