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

-- Auditoria:
-- Automática via schema audit (audit.accounts__users)

-- Relacionamentos:
-- accounts.employees.user_id -> accounts.users.user_id
-- accounts.user_google_oauth.user_id -> accounts.users.user_id
