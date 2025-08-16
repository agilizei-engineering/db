-- Tabela de dados do Google OAuth
-- Schema: accounts
-- Tabela: user_google_oauth

-- Esta tabela é criada automaticamente pelo enhance_users_security.sql
-- Este arquivo serve como documentação e referência

/*
CREATE TABLE accounts.user_google_oauth (
    google_oauth_id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id uuid NOT NULL,
    google_id text NOT NULL,
    google_picture_url text,
    google_locale text,
    google_given_name text,
    google_family_name text,
    google_hd text,
    google_email text,
    google_email_verified boolean DEFAULT false,
    google_profile_data jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone,
    FOREIGN KEY (user_id) REFERENCES accounts.users(user_id) ON DELETE CASCADE
);
*/

-- Campos principais:
-- google_oauth_id: Identificador único do registro OAuth (UUID)
-- user_id: Referência ao usuário
-- google_id: ID único do usuário no Google
-- google_picture_url: URL da foto do perfil Google
-- google_locale: Localização/configuração de idioma
-- google_given_name: Primeiro nome do usuário
-- google_family_name: Sobrenome do usuário
-- google_hd: Hosted domain (domínio da organização)
-- google_email: Email do usuário no Google
-- google_email_verified: Email verificado pelo Google
-- google_profile_data: Dados completos do perfil em JSON
-- created_at: Data de criação
-- updated_at: Data da última atualização

-- Constraints:
-- PRIMARY KEY: google_oauth_id
-- NOT NULL: user_id, google_id, created_at
-- FOREIGN KEY: user_id -> accounts.users(user_id) ON DELETE CASCADE
-- CHECK: google_picture_url válido via aux.validate_url() (se não for NULL)
-- CHECK: google_email válido via aux.validate_email() (se não for NULL)

-- Triggers:
-- updated_at: Atualiza automaticamente o campo updated_at
-- photo_url_validation: Valida URL da foto automaticamente
-- email_validation: Valida email automaticamente

-- Auditoria:
-- Automática via schema audit (audit.accounts__user_google_oauth)

-- Relacionamentos:
-- accounts.user_google_oauth.user_id -> accounts.users.user_id

-- Comentários da tabela:
-- COMMENT ON TABLE accounts.user_google_oauth IS 'Dados de autenticação OAuth do Google';
-- COMMENT ON COLUMN accounts.user_google_oauth.google_oauth_id IS 'Identificador único do registro OAuth';
-- COMMENT ON COLUMN accounts.user_google_oauth.user_id IS 'Referência ao usuário';
-- COMMENT ON COLUMN accounts.user_google_oauth.google_id IS 'ID único do usuário no Google';
-- COMMENT ON COLUMN accounts.user_google_oauth.google_picture_url IS 'URL da foto do perfil Google';
-- COMMENT ON COLUMN accounts.user_google_oauth.google_locale IS 'Localização/configuração de idioma';
-- COMMENT ON COLUMN accounts.user_google_oauth.google_given_name IS 'Primeiro nome do usuário';
-- COMMENT ON COLUMN accounts.user_google_oauth.google_family_name IS 'Sobrenome do usuário';
-- COMMENT ON COLUMN accounts.user_google_oauth.google_hd IS 'Hosted domain (domínio da organização)';
-- COMMENT ON COLUMN accounts.user_google_oauth.google_email IS 'Email do usuário no Google';
-- COMMENT ON COLUMN accounts.user_google_oauth.google_email_verified IS 'Email verificado pelo Google';
-- COMMENT ON COLUMN accounts.user_google_oauth.google_profile_data IS 'Dados completos do perfil em JSON';
-- COMMENT ON COLUMN accounts.user_google_oauth.created_at IS 'Data de criação';
-- COMMENT ON COLUMN accounts.user_google_oauth.updated_at IS 'Data da última atualização';

-- Funcionalidades:
-- Integração com Google OAuth
-- Armazenamento de dados do perfil Google
-- Validação automática de URLs e emails
-- Controle de dados de autenticação externa
-- Suporte a múltiplos provedores OAuth

-- Índices:
-- CREATE INDEX idx_user_google_oauth_user_id ON accounts.user_google_oauth(user_id);
-- CREATE INDEX idx_user_google_oauth_google_id ON accounts.user_google_oauth(google_id);
-- CREATE INDEX idx_user_google_oauth_google_email ON accounts.user_google_oauth(google_email);

-- Índices para dados JSON:
-- CREATE INDEX idx_user_google_oauth_profile_data_gin ON accounts.user_google_oauth USING gin(google_profile_data);
