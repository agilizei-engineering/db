-- Tabela de funcionalidades do sistema
-- Schema: accounts
-- Tabela: features

-- Esta tabela é criada automaticamente pelo dump principal
-- Este arquivo serve como documentação e referência

/*
CREATE TABLE accounts.features (
    feature_id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    module_id uuid,
    platform_id uuid,
    name text NOT NULL,
    code text NOT NULL,
    description text,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone,
    FOREIGN KEY (module_id) REFERENCES accounts.modules(module_id),
    FOREIGN KEY (platform_id) REFERENCES accounts.platforms(platform_id)
);
*/

-- Campos principais:
-- feature_id: Identificador único da funcionalidade (UUID)
-- module_id: Módulo ao qual a funcionalidade pertence
-- platform_id: Plataforma onde a funcionalidade está disponível
-- name: Nome da funcionalidade
-- code: Código único da funcionalidade (para verificação de permissão)
-- description: Descrição detalhada da funcionalidade
-- is_active: Status ativo/inativo da funcionalidade
-- created_at: Data de criação
-- updated_at: Data da última atualização

-- Constraints:
-- PRIMARY KEY: feature_id
-- NOT NULL: name, code, is_active, created_at
-- FOREIGN KEY: module_id -> accounts.modules.module_id
-- FOREIGN KEY: platform_id -> accounts.platforms.platform_id

-- Triggers:
-- updated_at: Atualiza automaticamente o campo updated_at

-- Auditoria:
-- Automática via schema audit (audit.accounts__features)

-- Relacionamentos:
-- accounts.role_features.feature_id -> accounts.features.feature_id
-- accounts.api_scopes.feature_id -> accounts.features.feature_id

-- Comentários da tabela:
-- COMMENT ON TABLE accounts.features IS 'Funcionalidades específicas associadas a módulos';
-- COMMENT ON COLUMN accounts.features.feature_id IS 'Identificador da feature';
-- COMMENT ON COLUMN accounts.features.module_id IS 'Módulo ao qual a feature pertence';
-- COMMENT ON COLUMN accounts.features.name IS 'Nome da feature';
-- COMMENT ON COLUMN accounts.features.code IS 'Código único da feature (para verificação de permissão)';
-- COMMENT ON COLUMN accounts.features.description IS 'Descrição da feature';
-- COMMENT ON COLUMN accounts.features.created_at IS 'Data de criação';
-- COMMENT ON COLUMN accounts.features.updated_at IS 'Data da última atualização';

-- Funcionalidades:
-- Definição de funcionalidades específicas do sistema
-- Controle granular de permissões por funcionalidade
-- Vinculação com módulos e plataformas
-- Base para controle de acesso RBAC

-- Índices:
-- CREATE INDEX idx_features_code ON accounts.features USING btree (code);
-- CREATE INDEX idx_features_module ON accounts.features USING btree (module_id);
