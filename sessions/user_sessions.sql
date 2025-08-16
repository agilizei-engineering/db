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
