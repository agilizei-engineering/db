-- Tabela de sessões ativas dos usuários
-- Schema: sessions
-- Tabela: user_sessions

-- Esta tabela é criada automaticamente pelo enhance_users_security.sql
-- Este arquivo serve como documentação e referência

/*
CREATE TABLE sessions.user_sessions (
    session_id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    employee_id uuid NOT NULL,
    current_session_id text NOT NULL,
    session_expires_at timestamp with time zone NOT NULL,
    refresh_token_hash text,
    access_token_hash text,
    ip_address inet,
    user_agent text,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone,
    FOREIGN KEY (employee_id) REFERENCES accounts.employees(employee_id)
);
*/

-- Campos principais:
-- session_id: Identificador único da sessão (UUID)
-- employee_id: Funcionário vinculado à sessão
-- current_session_id: ID da sessão atual
-- session_expires_at: Data/hora de expiração da sessão
-- refresh_token_hash: Hash do token de refresh
-- access_token_hash: Hash do token de acesso
-- ip_address: Endereço IP da conexão
-- user_agent: User agent do navegador/dispositivo
-- is_active: Status ativo da sessão
-- created_at: Data de criação
-- updated_at: Data da última atualização

-- Constraints:
-- PRIMARY KEY: session_id
-- FOREIGN KEY: employee_id -> accounts.employees.employee_id

-- Triggers:
-- updated_at: Atualiza automaticamente o campo updated_at

-- Auditoria:
-- Automática via schema audit (audit.sessions__user_sessions)

-- Relacionamentos:
-- sessions.user_sessions.employee_id -> accounts.employees.employee_id

-- Funcionalidades:
-- Controle de múltiplas sessões por usuário
-- Expiração automática de sessões
-- Rastreamento de IP e user agent
-- Sistema multi-persona para controle de acesso
-- Hash seguro dos tokens de autenticação

-- Comentários da tabela:
-- COMMENT ON TABLE sessions.user_sessions IS 'Sessões ativas dos usuários no sistema';
-- COMMENT ON COLUMN sessions.user_sessions.session_id IS 'Identificador único da sessão';
-- COMMENT ON COLUMN sessions.user_sessions.employee_id IS 'Funcionário ativo na sessão (contém referência ao user_id via accounts.employees)';
-- COMMENT ON COLUMN sessions.user_sessions.current_session_id IS 'ID da sessão atual (Cognito/JWT)';
-- COMMENT ON COLUMN sessions.user_sessions.session_expires_at IS 'Data de expiração da sessão';
-- COMMENT ON COLUMN sessions.user_sessions.refresh_token_hash IS 'Hash do refresh token';
-- COMMENT ON COLUMN sessions.user_sessions.access_token_hash IS 'Hash do access token';
-- COMMENT ON COLUMN sessions.user_sessions.ip_address IS 'Endereço IP da conexão';
-- COMMENT ON COLUMN sessions.user_sessions.user_agent IS 'User agent do navegador';
-- COMMENT ON COLUMN sessions.user_sessions.is_active IS 'Indica se a sessão está ativa';
-- COMMENT ON COLUMN sessions.user_sessions.created_at IS 'Data de criação da sessão';
-- COMMENT ON COLUMN sessions.user_sessions.updated_at IS 'Data da última atualização';

-- Índices:
-- CREATE INDEX idx_user_sessions_employee_id ON sessions.user_sessions USING btree (employee_id);
-- CREATE INDEX idx_user_sessions_current_session_id ON sessions.user_sessions USING btree (current_session_id);
-- CREATE INDEX idx_user_sessions_expires_at ON sessions.user_sessions USING btree (session_expires_at);
-- CREATE INDEX idx_user_sessions_is_active ON sessions.user_sessions USING btree (is_active);
-- CREATE INDEX idx_user_sessions_ip_address ON sessions.user_sessions USING btree (ip_address);
-- CREATE INDEX idx_user_sessions_created_at ON sessions.user_sessions USING btree (created_at);

-- Índices compostos:
-- CREATE INDEX idx_user_sessions_employee_active ON sessions.user_sessions USING btree (employee_id, is_active);
-- CREATE INDEX idx_user_sessions_employee_expires ON sessions.user_sessions USING btree (employee_id, session_expires_at);
-- CREATE INDEX idx_user_sessions_active_expires ON sessions.user_sessions USING btree (is_active, session_expires_at);

-- Índices de texto para busca:
-- CREATE INDEX idx_user_sessions_current_session_id_gin ON sessions.user_sessions USING gin(to_tsvector('portuguese', current_session_id));
-- CREATE INDEX idx_user_sessions_user_agent_gin ON sessions.user_sessions USING gin(to_tsvector('portuguese', user_agent));

-- Índices trigram para busca fuzzy (se pg_trgm disponível):
-- CREATE INDEX idx_user_sessions_current_session_id_trgm ON sessions.user_sessions USING gin(current_session_id gin_trgm_ops);
-- CREATE INDEX idx_user_sessions_user_agent_trgm ON sessions.user_sessions USING gin(user_agent gin_trgm_ops);
