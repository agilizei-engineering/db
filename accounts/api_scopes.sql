-- Tabela de escopos de acesso das chaves de API
-- Schema: accounts
-- Tabela: api_scopes

-- Esta tabela é criada automaticamente pelo dump principal
-- Este arquivo serve como documentação e referência

/*
CREATE TABLE accounts.api_scopes (
    api_scope_id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    api_key_id uuid NOT NULL,
    feature_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    FOREIGN KEY (api_key_id) REFERENCES accounts.api_keys(api_key_id) ON DELETE CASCADE,
    FOREIGN KEY (feature_id) REFERENCES accounts.features(feature_id) ON DELETE CASCADE
);
*/

-- Campos principais:
-- api_scope_id: Identificador único do escopo (UUID)
-- api_key_id: Chave de API à qual o escopo pertence
-- feature_id: Funcionalidade autorizada para acesso via API
-- created_at: Data de criação do escopo

-- Constraints:
-- PRIMARY KEY: api_scope_id
-- NOT NULL: api_key_id, feature_id, created_at
-- FOREIGN KEY: api_key_id -> accounts.api_keys(api_key_id) ON DELETE CASCADE
-- FOREIGN KEY: feature_id -> accounts.features(feature_id) ON DELETE CASCADE

-- Auditoria:
-- Automática via schema audit (audit.accounts__api_scopes)

-- Relacionamentos:
-- accounts.api_scopes.api_key_id -> accounts.api_keys(api_key_id)
-- accounts.api_scopes.feature_id -> accounts.features(feature_id)

-- Comentários da tabela:
-- COMMENT ON TABLE accounts.api_scopes IS 'Define os escopos de acesso das chaves de API às features do sistema';
-- COMMENT ON COLUMN accounts.api_scopes.api_scope_id IS 'Identificador único do escopo';
-- COMMENT ON COLUMN accounts.api_scopes.api_key_id IS 'Chave de API à qual o escopo pertence';
-- COMMENT ON COLUMN accounts.api_scopes.feature_id IS 'Feature autorizada para acesso via API';
-- COMMENT ON COLUMN accounts.api_scopes.created_at IS 'Data de criação do escopo';

-- Funcionalidades:
-- Controle de acesso granular para APIs
-- Definição de escopos específicos por chave de API
-- Base para autenticação e autorização via API
-- Sistema de permissões para integrações externas

-- Índices:
-- CREATE INDEX idx_api_scopes_api_key ON accounts.api_scopes USING btree (api_key_id);
-- CREATE INDEX idx_api_scopes_feature ON accounts.api_scopes USING btree (feature_id);
-- CREATE INDEX idx_api_scopes_api_key_feature ON accounts.api_scopes USING btree (api_key_id, feature_id);
