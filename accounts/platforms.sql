-- Tabela de plataformas do sistema
-- Schema: accounts
-- Tabela: platforms

-- Esta tabela é criada automaticamente pelo dump principal
-- Este arquivo serve como documentação e referência

/*
CREATE TABLE accounts.platforms (
    platform_id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    name text NOT NULL,
    description text,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone
);
*/

-- Campos principais:
-- platform_id: Identificador único da plataforma (UUID)
-- name: Nome da plataforma
-- description: Descrição detalhada da plataforma
-- is_active: Status ativo/inativo da plataforma
-- created_at: Data de criação
-- updated_at: Data da última atualização

-- Constraints:
-- PRIMARY KEY: platform_id
-- NOT NULL: name, is_active, created_at

-- Triggers:
-- updated_at: Atualiza automaticamente o campo updated_at

-- Auditoria:
-- Automática via schema audit (audit.accounts__platforms)

-- Relacionamentos:
-- accounts.features.platform_id -> accounts.platforms.platform_id

-- Comentários da tabela:
-- COMMENT ON TABLE accounts.platforms IS 'Plataformas onde o sistema pode ser acessado';
-- COMMENT ON COLUMN accounts.platforms.platform_id IS 'Identificador único da plataforma';
-- COMMENT ON COLUMN accounts.platforms.name IS 'Nome da plataforma';
-- COMMENT ON COLUMN accounts.platforms.description IS 'Descrição da plataforma';
-- COMMENT ON COLUMN accounts.platforms.is_active IS 'Status ativo/inativo';
-- COMMENT ON COLUMN accounts.platforms.created_at IS 'Data de criação';
-- COMMENT ON COLUMN accounts.platforms.updated_at IS 'Data da última atualização';

-- Funcionalidades:
-- Controle de acesso por plataforma
-- Diferentes funcionalidades por plataforma
-- Base para controle de recursos específicos
-- Organização de funcionalidades por ambiente

-- Exemplos de plataformas:
-- - Web (Navegador)
-- - Mobile (App Android/iOS)
-- - API (Integrações externas)
-- - Desktop (Aplicação desktop)
-- - Admin (Painel administrativo)
