-- Tabela de usuários autenticáveis
-- Schema: accounts
-- Tabela: users

-- Esta tabela é criada automaticamente pelo dump principal
-- Este arquivo serve como documentação e referência

/*
CREATE TABLE accounts.users (
    user_id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    email text NOT NULL,
    full_name text NOT NULL,
    cognito_sub text,
    is_active boolean DEFAULT true NOT NULL,
    email_verified boolean DEFAULT false,
    phone_number text,
    phone_number_verified boolean DEFAULT false,
    terms_accepted_at timestamp with time zone,
    privacy_policy_accepted_at timestamp with time zone,
    cookies_accepted_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone
);
*/

-- Campos principais:
-- user_id: Identificador único do usuário (UUID)
-- email: Email do usuário (validado via aux.validate_email)
-- full_name: Nome completo do usuário
-- cognito_sub: ID do usuário no AWS Cognito
-- is_active: Status ativo/inativo do usuário
-- email_verified: Email verificado
-- phone_number: Número de telefone
-- phone_number_verified: Telefone verificado
-- terms_accepted_at: Data de aceitação dos termos
-- privacy_policy_accepted_at: Data de aceitação da política de privacidade
-- cookies_accepted_at: Data de aceitação dos cookies
-- created_at: Data de criação
-- updated_at: Data da última atualização

-- Constraints:
-- PRIMARY KEY: user_id
-- UNIQUE: email
-- CHECK: email válido via aux.validate_email

-- Triggers:
-- updated_at: Atualiza automaticamente o campo updated_at
-- email_validation: Valida formato do email

-- Comentários da tabela:
-- COMMENT ON TABLE accounts.users IS 'Usuários autenticáveis do sistema';
-- COMMENT ON COLUMN accounts.users.user_id IS 'Identificador único do usuário (UUID)';
-- COMMENT ON COLUMN accounts.users.email IS 'Email do usuário (validado via aux.validate_email)';
-- COMMENT ON COLUMN accounts.users.full_name IS 'Nome completo do usuário';
-- COMMENT ON COLUMN accounts.users.cognito_sub IS 'ID do usuário no AWS Cognito';
-- COMMENT ON COLUMN accounts.users.is_active IS 'Status ativo/inativo do usuário';
-- COMMENT ON COLUMN accounts.users.email_verified IS 'Email verificado';
-- COMMENT ON COLUMN accounts.users.phone_number IS 'Número de telefone';
-- COMMENT ON COLUMN accounts.users.phone_number_verified IS 'Telefone verificado';
-- COMMENT ON COLUMN accounts.users.terms_accepted_at IS 'Data de aceitação dos termos';
-- COMMENT ON COLUMN accounts.users.privacy_policy_accepted_at IS 'Data de aceitação da política de privacidade';
-- COMMENT ON COLUMN accounts.users.cookies_accepted_at IS 'Data de aceitação dos cookies';
-- COMMENT ON COLUMN accounts.users.created_at IS 'Data de criação';
-- COMMENT ON COLUMN accounts.users.updated_at IS 'Data da última atualização';

-- Funcionalidades:
-- Autenticação via AWS Cognito
-- Controle de status ativo/inativo
-- Verificação de email e telefone
-- Aceitação de termos e políticas
-- Base para funcionários e sessões

-- Índices:
-- CREATE INDEX idx_users_email ON accounts.users USING btree (email);
-- CREATE INDEX idx_users_cognito_sub ON accounts.users USING btree (cognito_sub);
-- CREATE INDEX idx_users_active ON accounts.users USING btree (is_active);
-- CREATE INDEX idx_users_email_verified ON accounts.users USING btree (email_verified);

-- Auditoria:
-- Automática via schema audit (audit.accounts__users)

-- Relacionamentos:
-- accounts.employees.user_id -> accounts.users.user_id
-- accounts.user_google_oauth.user_id -> accounts.users.user_id
