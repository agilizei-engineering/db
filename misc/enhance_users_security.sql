-- =====================================================
-- ENHANCEMENT: USERS SECURITY & GOOGLE OAUTH INTEGRATION
-- =====================================================
-- Script para implementar melhorias de segurança e autenticação
-- Autor: Assistente IA + Usuário
-- Data: 2025-01-27
-- Versão: 1.0

-- =====================================================
-- VERIFICAÇÃO DE PRÉ-REQUISITOS
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE 'Verificando pre-requisitos para implementacao...';
    
    -- Verificar se o schema aux existe
    IF NOT EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'aux') THEN
        RAISE EXCEPTION 'Schema aux nao encontrado. Execute primeiro: \i aux_schema.sql';
    END IF;
    
    -- Verificar se a tabela accounts.users existe
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'accounts' AND table_name = 'users') THEN
        RAISE EXCEPTION 'Tabela accounts.users nao encontrada';
    END IF;
    
    RAISE NOTICE 'Todos os pre-requisitos atendidos!';
END $$;

-- =====================================================
-- 1. ADIÇÃO DE CAMPOS DE SEGURANÇA EM ACCOUNTS.USERS
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE 'Adicionando campos de seguranca na tabela accounts.users...';
    
    -- Adicionar campo de verificação de email
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'accounts' AND table_name = 'users' AND column_name = 'email_verified') THEN
        ALTER TABLE accounts.users ADD COLUMN email_verified boolean DEFAULT false NOT NULL;
        RAISE NOTICE 'Campo email_verified adicionado';
    ELSE
        RAISE NOTICE 'Campo email_verified ja existe';
    END IF;
    
    -- Adicionar campo de telefone
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'accounts' AND table_name = 'users' AND column_name = 'phone_number') THEN
        ALTER TABLE accounts.users ADD COLUMN phone_number text;
        RAISE NOTICE 'Campo phone_number adicionado';
    ELSE
        RAISE NOTICE 'Campo phone_number ja existe';
    END IF;
    
    -- Adicionar campo de verificação de telefone
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'accounts' AND table_name = 'users' AND column_name = 'phone_number_verified') THEN
        ALTER TABLE accounts.users ADD COLUMN phone_number_verified boolean DEFAULT false NOT NULL;
        RAISE NOTICE 'Campo phone_number_verified adicionado';
    ELSE
        RAISE NOTICE 'Campo phone_number_verified ja existe';
    END IF;
    
    -- Adicionar campo de aceite de termos
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'accounts' AND table_name = 'users' AND column_name = 'terms_accepted_at') THEN
        ALTER TABLE accounts.users ADD COLUMN terms_accepted_at timestamp with time zone;
        RAISE NOTICE 'Campo terms_accepted_at adicionado';
    ELSE
        RAISE NOTICE 'Campo terms_accepted_at ja existe';
    END IF;
    
    -- Adicionar campo de aceite de política de privacidade
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'accounts' AND table_name = 'users' AND column_name = 'privacy_policy_accepted_at') THEN
        ALTER TABLE accounts.users ADD COLUMN privacy_policy_accepted_at timestamp with time zone;
        RAISE NOTICE 'Campo privacy_policy_accepted_at adicionado';
    ELSE
        RAISE NOTICE 'Campo privacy_policy_accepted_at ja existe';
    END IF;
    
    -- Adicionar campo de aceite de cookies
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'accounts' AND table_name = 'users' AND column_name = 'cookies_accepted_at') THEN
        ALTER TABLE accounts.users ADD COLUMN cookies_accepted_at timestamp with time zone;
        RAISE NOTICE 'Campo cookies_accepted_at adicionado';
    ELSE
        RAISE NOTICE 'Campo cookies_accepted_at ja existe';
    END IF;
    
    RAISE NOTICE 'Campos de seguranca adicionados com sucesso!';
END $$;

-- =====================================================
-- 2. CRIAÇÃO DO SCHEMA SESSIONS
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE 'Criando schema sessions...';
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'sessions') THEN
        CREATE SCHEMA sessions;
        RAISE NOTICE 'Schema sessions criado';
    ELSE
        RAISE NOTICE 'Schema sessions ja existe';
    END IF;
    
    COMMENT ON SCHEMA sessions IS 'Schema para controle de sessões e autenticação';
END $$;

-- =====================================================
-- 3. CRIAÇÃO DA TABELA DE SESSÕES
-- =====================================================

CREATE TABLE IF NOT EXISTS sessions.user_sessions (
    session_id uuid DEFAULT gen_random_uuid() NOT NULL,
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
    CONSTRAINT user_sessions_pkey PRIMARY KEY (session_id),
    CONSTRAINT user_sessions_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES accounts.employees(employee_id),
    CONSTRAINT user_sessions_current_session_id_key UNIQUE (current_session_id)
);

COMMENT ON TABLE sessions.user_sessions IS 'Sessoes ativas dos usuarios no sistema';
COMMENT ON COLUMN sessions.user_sessions.session_id IS 'Identificador unico da sessao';
COMMENT ON COLUMN sessions.user_sessions.employee_id IS 'Funcionario ativo na sessao (contem referencia ao user_id via accounts.employees)';
COMMENT ON COLUMN sessions.user_sessions.current_session_id IS 'ID da sessao atual (Cognito/JWT)';
COMMENT ON COLUMN sessions.user_sessions.session_expires_at IS 'Data de expiracao da sessao';
COMMENT ON COLUMN sessions.user_sessions.refresh_token_hash IS 'Hash do refresh token';
COMMENT ON COLUMN sessions.user_sessions.access_token_hash IS 'Hash do access token';
COMMENT ON COLUMN sessions.user_sessions.ip_address IS 'Endereco IP da conexao';
COMMENT ON COLUMN sessions.user_sessions.user_agent IS 'User agent do navegador';
COMMENT ON COLUMN sessions.user_sessions.is_active IS 'Indica se a sessao esta ativa';
COMMENT ON COLUMN sessions.user_sessions.created_at IS 'Data de criacao da sessao';
COMMENT ON COLUMN sessions.user_sessions.updated_at IS 'Data da ultima atualizacao';

-- =====================================================
-- 4. CRIAÇÃO DA TABELA DE DADOS DO GOOGLE OAUTH
-- =====================================================

CREATE TABLE IF NOT EXISTS accounts.user_google_oauth (
    google_oauth_id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    google_id text NOT NULL,
    google_picture_url text,
    google_locale text,
    google_given_name text,
    google_family_name text,
    google_hd text,
    google_email text NOT NULL,
    google_email_verified boolean DEFAULT false,
    google_profile_data jsonb,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone,
    CONSTRAINT user_google_oauth_pkey PRIMARY KEY (google_oauth_id),
    CONSTRAINT user_google_oauth_user_id_fkey FOREIGN KEY (user_id) REFERENCES accounts.users(user_id),
    CONSTRAINT user_google_oauth_google_id_key UNIQUE (google_id),
    CONSTRAINT user_google_oauth_user_id_key UNIQUE (user_id)
);

COMMENT ON TABLE accounts.user_google_oauth IS 'Dados de autenticacao OAuth do Google para usuarios';
COMMENT ON COLUMN accounts.user_google_oauth.google_oauth_id IS 'Identificador unico do registro OAuth';
COMMENT ON COLUMN accounts.user_google_oauth.user_id IS 'Usuario associado';
COMMENT ON COLUMN accounts.user_google_oauth.google_id IS 'ID unico do Google';
COMMENT ON COLUMN accounts.user_google_oauth.google_picture_url IS 'URL da foto do perfil Google';
COMMENT ON COLUMN accounts.user_google_oauth.google_locale IS 'Idioma/regiao do Google';
COMMENT ON COLUMN accounts.user_google_oauth.google_given_name IS 'Primeiro nome do Google';
COMMENT ON COLUMN accounts.user_google_oauth.google_family_name IS 'Sobrenome do Google';
COMMENT ON COLUMN accounts.user_google_oauth.google_hd IS 'Hosted domain (para GSuite)';
COMMENT ON COLUMN accounts.user_google_oauth.google_email IS 'Email do Google (pode ser diferente do email principal)';
COMMENT ON COLUMN accounts.user_google_oauth.google_email_verified IS 'Email do Google verificado';
COMMENT ON COLUMN accounts.user_google_oauth.google_profile_data IS 'Dados completos do perfil Google em JSON';
COMMENT ON COLUMN accounts.user_google_oauth.is_active IS 'Indica se o registro OAuth esta ativo';
COMMENT ON COLUMN accounts.user_google_oauth.created_at IS 'Data de criacao do registro OAuth';
COMMENT ON COLUMN accounts.user_google_oauth.updated_at IS 'Data da ultima atualizacao';

-- =====================================================
-- 5. CRIAÇÃO DE ÍNDICES PARA PERFORMANCE
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE 'Criando indices para performance...';
    
    -- Índices para sessions
    CREATE INDEX IF NOT EXISTS idx_user_sessions_employee_id ON sessions.user_sessions(employee_id);
    CREATE INDEX IF NOT EXISTS idx_user_sessions_current_session_id ON sessions.user_sessions(current_session_id);
    CREATE INDEX IF NOT EXISTS idx_user_sessions_expires_at ON sessions.user_sessions(session_expires_at);
    CREATE INDEX IF NOT EXISTS idx_user_sessions_is_active ON sessions.user_sessions(is_active);
    
    -- Índices para Google OAuth
    CREATE INDEX IF NOT EXISTS idx_user_google_oauth_user_id ON accounts.user_google_oauth(user_id);
    CREATE INDEX IF NOT EXISTS idx_user_google_oauth_google_id ON accounts.user_google_oauth(google_id);
    CREATE INDEX IF NOT EXISTS idx_user_google_oauth_google_email ON accounts.user_google_oauth(google_email);
    
    RAISE NOTICE 'Indices criados com sucesso!';
END $$;

-- =====================================================
-- 6. CRIAÇÃO DE TRIGGERS DE UPDATED_AT
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE 'Criando triggers de updated_at...';
    
    -- Trigger para sessions.user_sessions
    PERFORM aux.create_updated_at_trigger('sessions', 'user_sessions');
    
    -- Trigger para accounts.user_google_oauth
    PERFORM aux.create_updated_at_trigger('accounts', 'user_google_oauth');
    
    RAISE NOTICE 'Triggers de updated_at criados com sucesso!';
END $$;

-- =====================================================
-- 7. VERIFICAÇÃO DE FUNÇÕES DE VALIDAÇÃO DE EMAIL
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE 'Verificando funcoes de validacao de email no schema aux...';
    
    -- Verificar se a função de validação de email existe
    IF NOT EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_schema = 'aux' AND routine_name = 'validate_email') THEN
        RAISE EXCEPTION 'Funcao aux.validate_email nao encontrada. Execute primeiro: \i aux_schema.sql';
    END IF;
    
    RAISE NOTICE 'Funcao aux.validate_email encontrada e sera utilizada';
END $$;

-- =====================================================
-- 8. APLICAÇÃO DE VALIDAÇÕES NAS TABELAS
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE 'Aplicando validacoes de email...';
    
    -- Adicionar constraint de validação de email na tabela users
    ALTER TABLE accounts.users 
    ADD CONSTRAINT users_email_format_valid 
    CHECK (aux.validate_email(email));
    
    -- Adicionar constraint de validação de email na tabela user_google_oauth
    ALTER TABLE accounts.user_google_oauth 
    ADD CONSTRAINT user_google_oauth_google_email_format_valid 
    CHECK (aux.validate_email(google_email));
    
    RAISE NOTICE 'Validacoes de email aplicadas com sucesso!';
END $$;

-- =====================================================
-- 9. CRIAÇÃO DE VIEWS ÚTEIS
-- =====================================================

-- View para usuários com dados do Google OAuth
CREATE OR REPLACE VIEW accounts.v_users_with_google AS
SELECT 
    u.user_id,
    u.email,
    u.full_name,
    u.cognito_sub,
    u.email_verified,
    u.phone_number,
    u.phone_number_verified,
    u.terms_accepted_at,
    u.privacy_policy_accepted_at,
    u.cookies_accepted_at,
    u.is_active,
    u.created_at,
    u.updated_at,
    g.google_id,
    g.google_picture_url,
    g.google_locale,
    g.google_given_name,
    g.google_family_name,
    g.google_hd,
    g.google_email,
    g.google_email_verified,
    g.google_profile_data
FROM accounts.users u
LEFT JOIN accounts.user_google_oauth g ON u.user_id = g.user_id AND g.is_active = true;

COMMENT ON VIEW accounts.v_users_with_google IS 'View consolidada de usuarios com dados do Google OAuth';

-- View para sessões ativas
CREATE OR REPLACE VIEW sessions.v_active_sessions AS
SELECT 
    us.session_id,
    us.employee_id,
    e.user_id,
    u.email,
    u.full_name,
    us.current_session_id,
    us.session_expires_at,
    us.ip_address,
    us.user_agent,
    us.created_at,
    us.updated_at,
    CASE 
        WHEN us.session_expires_at < now() THEN 'EXPIRED'
        ELSE 'ACTIVE'
    END as session_status
FROM sessions.user_sessions us
JOIN accounts.employees e ON us.employee_id = e.employee_id
JOIN accounts.users u ON e.user_id = u.user_id
WHERE us.is_active = true;

COMMENT ON VIEW sessions.v_active_sessions IS 'View de sessoes ativas dos usuarios';

-- =====================================================
-- 10. FUNÇÃO GENÉRICA PARA SINCRONIZAR AUDITORIA
-- =====================================================

-- Função para sincronizar automaticamente tabelas de auditoria
CREATE OR REPLACE FUNCTION audit.sync_audit_table(p_schema_name text, p_table_name text)
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
    v_audit_table_name text;
    v_audit_schema text := 'audit';
    v_audit_table_full text;
    v_source_columns record;
    v_audit_columns record;
    v_missing_columns text[] := ARRAY[]::text[];
    v_modified_columns text[] := ARRAY[]::text[];
    v_sql text;
    v_result text;
    v_audit_fields text[] := ARRAY['audit_id', 'audit_operation', 'audit_timestamp', 'audit_user', 'audit_session_id', 'audit_connection_id', 'audit_partition_date'];
BEGIN
    -- Construir nome da tabela de auditoria
    v_audit_table_name := p_schema_name || '__' || p_table_name;
    v_audit_table_full := v_audit_schema || '.' || v_audit_table_name;
    
    -- Verificar se a tabela de auditoria existe
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = v_audit_schema AND table_name = v_audit_table_name) THEN
        -- Criar tabela de auditoria se não existir
        PERFORM audit.create_audit_table(p_schema_name, p_table_name);
        RETURN 'Tabela de auditoria ' || v_audit_table_full || ' criada com sucesso';
    END IF;
    
    -- Verificar colunas da tabela fonte
    FOR v_source_columns IN 
        SELECT column_name, data_type, character_maximum_length, numeric_precision, numeric_scale
        FROM information_schema.columns 
        WHERE table_schema = p_schema_name AND table_name = p_table_name
        ORDER BY ordinal_position
    LOOP
        -- Verificar se a coluna existe na tabela de auditoria
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = v_audit_schema 
            AND table_name = v_audit_table_name 
            AND column_name = v_source_columns.column_name
        ) THEN
            -- Coluna não existe na auditoria - adicionar
            v_missing_columns := array_append(v_missing_columns, v_source_columns.column_name);
            
            -- Adicionar coluna na tabela de auditoria
            v_sql := format('ALTER TABLE %I.%I ADD COLUMN %I %s', 
                           v_audit_schema, v_audit_table_name, 
                           v_source_columns.column_name, 
                           v_source_columns.data_type);
            
            -- Adicionar precisão para tipos numéricos
            IF v_source_columns.numeric_precision IS NOT NULL THEN
                v_sql := v_sql || format('(%s', v_source_columns.numeric_precision);
                IF v_source_columns.numeric_scale IS NOT NULL THEN
                    v_sql := v_sql || format(',%s', v_source_columns.numeric_scale);
                END IF;
                v_sql := v_sql || ')';
            END IF;
            
            -- Adicionar tamanho para tipos de caractere
            IF v_source_columns.character_maximum_length IS NOT NULL THEN
                v_sql := v_sql || format('(%s)', v_source_columns.character_maximum_length);
            END IF;
            
            EXECUTE v_sql;
            RAISE NOTICE 'Coluna % adicionada na tabela de auditoria', v_source_columns.column_name;
        ELSE
            -- Verificar se o tipo de dados mudou
            SELECT column_name, data_type, character_maximum_length, numeric_precision, numeric_scale
            INTO v_audit_columns
            FROM information_schema.columns 
            WHERE table_schema = v_audit_schema 
            AND table_name = v_audit_table_name 
            AND column_name = v_source_columns.column_name;
            
            -- Se o tipo mudou, alterar para text para preservar dados
            IF v_audit_columns.data_type != v_source_columns.data_type THEN
                v_modified_columns := array_append(v_modified_columns, v_source_columns.column_name);
                
                v_sql := format('ALTER TABLE %I.%I ALTER COLUMN %I TYPE text', 
                               v_audit_schema, v_audit_table_name, v_source_columns.column_name);
                EXECUTE v_sql;
                RAISE NOTICE 'Tipo da coluna % alterado para text na tabela de auditoria', v_source_columns.column_name;
            END IF;
        END IF;
    END LOOP;
    
    -- Recriar trigger de auditoria se houver mudanças
    IF array_length(v_missing_columns, 1) > 0 OR array_length(v_modified_columns, 1) > 0 THEN
        -- Recriar função de trigger
        PERFORM audit.create_audit_function(p_schema_name, p_table_name, v_audit_table_name);
        
        -- Recriar trigger
        PERFORM audit.create_audit_trigger(p_schema_name, p_table_name, v_audit_table_name);
        
        RAISE NOTICE 'Trigger de auditoria recriado para %', v_audit_table_full;
    END IF;
    
    -- Construir mensagem de resultado
    v_result := 'Sincronizacao concluida para ' || v_audit_table_full;
    
    IF array_length(v_missing_columns, 1) > 0 THEN
        v_result := v_result || '. Colunas adicionadas: ' || array_to_string(v_missing_columns, ', ');
    END IF;
    
    IF array_length(v_modified_columns, 1) > 0 THEN
        v_result := v_result || '. Colunas modificadas: ' || array_to_string(v_modified_columns, ', ');
    END IF;
    
    IF array_length(v_missing_columns, 1) = 0 AND array_length(v_modified_columns, 1) = 0 THEN
        v_result := v_result || '. Nenhuma alteracao necessaria';
    END IF;
    
    RETURN v_result;
END;
$$;

COMMENT ON FUNCTION audit.sync_audit_table(text, text) IS 'Sincroniza automaticamente tabela de auditoria com tabela fonte, adicionando/modificando colunas conforme necessario';

-- =====================================================
-- 11. SINCRONIZAÇÃO AUTOMÁTICA DAS TABELAS DE AUDITORIA
-- =====================================================

DO $$
DECLARE
    v_result text;
BEGIN
    RAISE NOTICE 'Sincronizando tabelas de auditoria...';
    
    -- Sincronizar tabela de auditoria de users
    v_result := audit.sync_audit_table('accounts', 'users');
    RAISE NOTICE 'Users: %', v_result;
    
    -- Criar tabela de auditoria para user_google_oauth
    PERFORM audit.create_audit_table('accounts', 'user_google_oauth');
    RAISE NOTICE 'Tabela de auditoria para user_google_oauth criada';
    
    -- Criar tabela de auditoria para user_sessions
    PERFORM audit.create_audit_table('sessions', 'user_sessions');
    RAISE NOTICE 'Tabela de auditoria para user_sessions criada';
    
    RAISE NOTICE 'Tabelas de auditoria sincronizadas com sucesso!';
END $$;

-- =====================================================
-- 12. VERIFICAÇÃO FINAL
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=====================================================';
    RAISE NOTICE 'VERIFICACAO FINAL DA IMPLEMENTACAO';
    RAISE NOTICE '=====================================================';
    
    -- Verificar campos adicionados em users
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'accounts' AND table_name = 'users' AND column_name = 'email_verified') THEN
        RAISE NOTICE '✅ Campo email_verified adicionado em accounts.users';
    ELSE
        RAISE NOTICE '❌ Campo email_verified nao foi adicionado';
    END IF;
    
    -- Verificar schema sessions
    IF EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'sessions') THEN
        RAISE NOTICE '✅ Schema sessions criado';
    ELSE
        RAISE NOTICE '❌ Schema sessions nao foi criado';
    END IF;
    
    -- Verificar tabela user_sessions
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'sessions' AND table_name = 'user_sessions') THEN
        RAISE NOTICE '✅ Tabela sessions.user_sessions criada';
    ELSE
        RAISE NOTICE '❌ Tabela sessions.user_sessions nao foi criada';
    END IF;
    
    -- Verificar tabela user_google_oauth
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'accounts' AND table_name = 'user_google_oauth') THEN
        RAISE NOTICE '✅ Tabela accounts.user_google_oauth criada';
    ELSE
        RAISE NOTICE '❌ Tabela accounts.user_google_oauth nao foi criada';
    END IF;
    
    -- Verificar função de sincronização de auditoria
    IF EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_schema = 'audit' AND routine_name = 'sync_audit_table') THEN
        RAISE NOTICE '✅ Funcao audit.sync_audit_table criada';
    ELSE
        RAISE NOTICE '❌ Funcao audit.sync_audit_table nao foi criada';
    END IF;
    
    -- Verificar função de validação de email no aux
    IF EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_schema = 'aux' AND routine_name = 'validate_email') THEN
        RAISE NOTICE '✅ Funcao aux.validate_email encontrada e sendo utilizada';
    ELSE
        RAISE NOTICE '❌ Funcao aux.validate_email nao foi encontrada';
    END IF;
    
    RAISE NOTICE '=====================================================';
    RAISE NOTICE 'Implementacao concluida!';
    RAISE NOTICE '=====================================================';
END $$;
