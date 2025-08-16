-- Tabela de vínculos entre papéis e funcionalidades
-- Schema: accounts
-- Tabela: role_features

-- Esta tabela é criada automaticamente pelo dump principal
-- Este arquivo serve como documentação e referência

/*
CREATE TABLE accounts.role_features (
    role_feature_id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    role_id uuid NOT NULL,
    feature_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    FOREIGN KEY (role_id) REFERENCES accounts.roles(role_id),
    FOREIGN KEY (feature_id) REFERENCES accounts.features(feature_id)
);
*/

-- Campos principais:
-- role_feature_id: Identificador único do vínculo (UUID)
-- role_id: Papel que recebe a funcionalidade
-- feature_id: Funcionalidade atribuída ao papel
-- created_at: Data de criação do vínculo

-- Constraints:
-- PRIMARY KEY: role_feature_id
-- NOT NULL: role_id, feature_id, created_at
-- FOREIGN KEY: role_id -> accounts.roles.role_id
-- FOREIGN KEY: feature_id -> accounts.features(feature_id)

-- Auditoria:
-- Automática via schema audit (audit.accounts__role_features)

-- Relacionamentos:
-- accounts.role_features.role_id -> accounts.roles.role_id
-- accounts.role_features.feature_id -> accounts.features.feature_id

-- Comentários da tabela:
-- COMMENT ON TABLE accounts.role_features IS 'Vínculos entre papéis e funcionalidades';
-- COMMENT ON COLUMN accounts.role_features.role_feature_id IS 'Identificador único do vínculo';
-- COMMENT ON COLUMN accounts.role_features.role_id IS 'Papel que recebe a funcionalidade';
-- COMMENT ON COLUMN accounts.role_features.feature_id IS 'Funcionalidade atribuída ao papel';
-- COMMENT ON COLUMN accounts.role_features.created_at IS 'Data de criação do vínculo';

-- Funcionalidades:
-- Controle granular de permissões por funcionalidade
-- Atribuição de funcionalidades específicas a papéis
-- Base para verificação de acesso a recursos
-- Sistema de permissões flexível e granular

-- Índices:
-- CREATE INDEX idx_role_features_role_feature ON accounts.role_features USING btree (role_id, feature_id);
-- CREATE INDEX idx_role_features_role ON accounts.role_features USING btree (role_id);
-- CREATE INDEX idx_role_features_feature ON accounts.role_features USING btree (feature_id);
