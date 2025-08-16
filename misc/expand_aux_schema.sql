-- =====================================================
-- EXPANSÃO DO SCHEMA AUX - FUNÇÕES GENÉRICAS DE TRIGGER
-- =====================================================
-- Script para expandir o schema aux com funções genéricas
-- que serão usadas pelos schemas específicos
-- Autor: Assistente IA + Usuário
-- Data: 2025-01-27
-- Versão: 1.0

-- =====================================================
-- VERIFICAÇÃO DE PRÉ-REQUISITOS
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '🔍 Verificando pré-requisitos para expansão do schema aux...';
    
    -- Verificar se o schema aux existe
    IF NOT EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'aux') THEN
        RAISE EXCEPTION 'Schema aux não encontrado. Execute primeiro: \i aux_schema.sql';
    END IF;
    
    -- Verificar se as funções de validação existem
    IF NOT EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_schema = 'aux' AND routine_name = 'clean_and_validate_cnpj') THEN
        RAISE EXCEPTION 'Função aux.clean_and_validate_cnpj não encontrada';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_schema = 'aux' AND routine_name = 'clean_and_validate_cpf') THEN
        RAISE EXCEPTION 'Função aux.clean_and_validate_cpf não encontrada';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_schema = 'aux' AND routine_name = 'clean_and_validate_postal_code') THEN
        RAISE EXCEPTION 'Função aux.clean_and_validate_postal_code não encontrada';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_schema = 'aux' AND routine_name = 'validate_email') THEN
        RAISE EXCEPTION 'Função aux.validate_email não encontrada';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_schema = 'aux' AND routine_name = 'validate_url') THEN
        RAISE EXCEPTION 'Função aux.validate_url não encontrada';
    END IF;
    
    RAISE NOTICE '✅ Todos os pré-requisitos atendidos!';
END $$;

-- =====================================================
-- FUNÇÕES GENÉRICAS DE TRIGGER PARA CNPJ
-- =====================================================

-- Função genérica para limpar e validar CNPJ
CREATE OR REPLACE FUNCTION aux.clean_cnpj_before_insert_update()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Usar função de validação do schema aux
    NEW.cnpj := aux.clean_and_validate_cnpj(NEW.cnpj);
    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION aux.clean_cnpj_before_insert_update() IS 'Função genérica de trigger para limpar e validar CNPJ automaticamente';

-- =====================================================
-- FUNÇÕES GENÉRICAS DE TRIGGER PARA CPF
-- =====================================================

-- Função genérica para limpar e validar CPF
CREATE OR REPLACE FUNCTION aux.clean_cpf_before_insert_update()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Usar função de validação do schema aux
    NEW.cpf := aux.clean_and_validate_cpf(NEW.cpf);
    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION aux.clean_cpf_before_insert_update() IS 'Função genérica de trigger para limpar e validar CPF automaticamente';

-- =====================================================
-- FUNÇÕES GENÉRICAS DE TRIGGER PARA CEP
-- =====================================================

-- Função genérica para limpar e validar CEP
CREATE OR REPLACE FUNCTION aux.clean_postal_code_before_insert_update()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Usar função de validação do schema aux
    NEW.postal_code := aux.clean_and_validate_postal_code(NEW.postal_code);
    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION aux.clean_postal_code_before_insert_update() IS 'Função genérica de trigger para limpar e validar CEP automaticamente';

-- =====================================================
-- FUNÇÕES GENÉRICAS DE TRIGGER PARA EMAIL
-- =====================================================

-- Função genérica para validar email
CREATE OR REPLACE FUNCTION aux.validate_email_before_insert_update()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Usar função de validação do schema aux
    IF NEW.email IS NOT NULL THEN
        IF NOT aux.validate_email(NEW.email) THEN
            RAISE EXCEPTION 'Email inválido: %', NEW.email;
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION aux.validate_email_before_insert_update() IS 'Função genérica de trigger para validar email automaticamente';

-- =====================================================
-- FUNÇÕES GENÉRICAS DE TRIGGER PARA URL
-- =====================================================

-- Função genérica para validar URL
CREATE OR REPLACE FUNCTION aux.validate_url_before_insert_update()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Usar função de validação do schema aux
    IF NEW.photo_url IS NOT NULL THEN
        IF NOT aux.validate_url(NEW.photo_url) THEN
            RAISE EXCEPTION 'URL inválida: %', NEW.photo_url;
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION aux.validate_url_before_insert_update() IS 'Função genérica de trigger para validar URL automaticamente';

-- =====================================================
-- FUNÇÃO GENÉRICA PARA CRIAR TRIGGER DE CNPJ
-- =====================================================

CREATE OR REPLACE FUNCTION aux.create_cnpj_trigger(
    p_schema_name text,
    p_table_name text,
    p_column_name text DEFAULT 'cnpj'
)
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
    v_trigger_name text;
    v_full_table_name text;
    v_sql text;
BEGIN
    -- Nome do trigger
    v_trigger_name := 'clean_cnpj_trigger';
    v_full_table_name := p_schema_name || '.' || p_table_name;
    
    -- Criar trigger
    v_sql := format('
        DROP TRIGGER IF EXISTS %I ON %I;
        CREATE TRIGGER %I
            BEFORE INSERT OR UPDATE ON %I
            FOR EACH ROW EXECUTE FUNCTION aux.clean_cnpj_before_insert_update();
    ', v_trigger_name, v_full_table_name, v_trigger_name, v_full_table_name);
    
    EXECUTE v_sql;
    
    RETURN 'Trigger ' || v_trigger_name || ' criado com sucesso para ' || v_full_table_name;
END;
$$;

COMMENT ON FUNCTION aux.create_cnpj_trigger(text, text, text) IS 'Função genérica para criar trigger de limpeza de CNPJ';

-- =====================================================
-- FUNÇÃO GENÉRICA PARA CRIAR TRIGGER DE CPF
-- =====================================================

CREATE OR REPLACE FUNCTION aux.create_cpf_trigger(
    p_schema_name text,
    p_table_name text,
    p_column_name text DEFAULT 'cpf'
)
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
    v_trigger_name text;
    v_full_table_name text;
    v_sql text;
BEGIN
    -- Nome do trigger
    v_trigger_name := 'clean_cpf_trigger';
    v_full_table_name := p_schema_name || '.' || p_table_name;
    
    -- Criar trigger
    v_sql := format('
        DROP TRIGGER IF EXISTS %I ON %I;
        CREATE TRIGGER %I
            BEFORE INSERT OR UPDATE ON %I
            FOR EACH ROW EXECUTE FUNCTION aux.clean_cpf_before_insert_update();
    ', v_trigger_name, v_full_table_name, v_trigger_name, v_full_table_name);
    
    EXECUTE v_sql;
    
    RETURN 'Trigger ' || v_trigger_name || ' criado com sucesso para ' || v_full_table_name;
END;
$$;

COMMENT ON FUNCTION aux.create_cpf_trigger(text, text, text) IS 'Função genérica para criar trigger de limpeza de CPF';

-- =====================================================
-- FUNÇÃO GENÉRICA PARA CRIAR TRIGGER DE CEP
-- =====================================================

CREATE OR REPLACE FUNCTION aux.create_postal_code_trigger(
    p_schema_name text,
    p_table_name text,
    p_column_name text DEFAULT 'postal_code'
)
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
    v_trigger_name text;
    v_full_table_name text;
    v_sql text;
BEGIN
    -- Nome do trigger
    v_trigger_name := 'clean_postal_code_trigger';
    v_full_table_name := p_schema_name || '.' || p_table_name;
    
    -- Criar trigger
    v_sql := format('
        DROP TRIGGER IF EXISTS %I ON %I;
        CREATE TRIGGER %I
            BEFORE INSERT OR UPDATE ON %I
            FOR EACH ROW EXECUTE FUNCTION aux.clean_postal_code_before_insert_update();
    ', v_trigger_name, v_full_table_name, v_trigger_name, v_full_table_name);
    
    EXECUTE v_sql;
    
    RETURN 'Trigger ' || v_trigger_name || ' criado com sucesso para ' || v_full_table_name;
END;
$$;

COMMENT ON FUNCTION aux.create_postal_code_trigger(text, text, text) IS 'Função genérica para criar trigger de limpeza de CEP';

-- =====================================================
-- FUNÇÃO GENÉRICA PARA CRIAR TRIGGER DE EMAIL
-- =====================================================

CREATE OR REPLACE FUNCTION aux.create_email_trigger(
    p_schema_name text,
    p_table_name text,
    p_column_name text DEFAULT 'email'
)
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
    v_trigger_name text;
    v_full_table_name text;
    v_sql text;
BEGIN
    -- Nome do trigger
    v_trigger_name := 'validate_email_trigger';
    v_full_table_name := p_schema_name || '.' || p_table_name;
    
    -- Criar trigger
    v_sql := format('
        DROP TRIGGER IF EXISTS %I ON %I;
        CREATE TRIGGER %I
            BEFORE INSERT OR UPDATE ON %I
            FOR EACH ROW EXECUTE FUNCTION aux.validate_email_before_insert_update();
    ', v_trigger_name, v_full_table_name, v_trigger_name, v_full_table_name);
    
    EXECUTE v_sql;
    
    RETURN 'Trigger ' || v_trigger_name || ' criado com sucesso para ' || v_full_table_name;
END;
$$;

COMMENT ON FUNCTION aux.create_email_trigger(text, text, text) IS 'Função genérica para criar trigger de validação de email';

-- =====================================================
-- FUNÇÃO GENÉRICA PARA CRIAR TRIGGER DE URL
-- =====================================================

CREATE OR REPLACE FUNCTION aux.create_url_trigger(
    p_schema_name text,
    p_table_name text,
    p_column_name text DEFAULT 'photo_url'
)
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
    v_trigger_name text;
    v_full_table_name text;
    v_sql text;
BEGIN
    -- Nome do trigger
    v_trigger_name := 'validate_url_trigger';
    v_full_table_name := p_schema_name || '.' || p_table_name;
    
    -- Criar trigger
    v_sql := format('
        DROP TRIGGER IF EXISTS %I ON %I;
        CREATE TRIGGER %I
            BEFORE INSERT OR UPDATE ON %I
            FOR EACH ROW EXECUTE FUNCTION aux.validate_url_before_insert_update();
    ', v_trigger_name, v_full_table_name, v_trigger_name, v_full_table_name);
    
    EXECUTE v_sql;
    
    RETURN 'Trigger ' || v_trigger_name || ' criado com sucesso para ' || v_full_table_name;
END;
$$;

COMMENT ON FUNCTION aux.create_url_trigger(text, text, text) IS 'Função genérica para criar trigger de validação de URL';

-- =====================================================
-- FUNÇÃO GENÉRICA PARA CRIAR TODOS OS TRIGGERS DE UMA TABELA
-- =====================================================

CREATE OR REPLACE FUNCTION aux.create_validation_triggers(
    p_schema_name text,
    p_table_name text,
    p_columns text[] DEFAULT ARRAY[]::text[]
)
RETURNS text[]
LANGUAGE plpgsql
AS $$
DECLARE
    v_result text[];
    v_column text;
    v_message text;
BEGIN
    v_result := ARRAY[]::text[];
    
    -- Se não especificou colunas, usar padrões baseados no nome da tabela
    IF array_length(p_columns, 1) IS NULL THEN
        -- Detectar automaticamente colunas baseado no nome da tabela
        IF p_table_name LIKE '%business%' OR p_table_name LIKE '%establishment%' THEN
            p_columns := ARRAY['cnpj'];
        ELSIF p_table_name LIKE '%employee%' OR p_table_name LIKE '%person%' THEN
            p_columns := ARRAY['cpf'];
        ELSIF p_table_name LIKE '%address%' THEN
            p_columns := ARRAY['postal_code'];
        END IF;
    END IF;
    
    -- Criar triggers para cada coluna
    FOREACH v_column IN ARRAY p_columns
    LOOP
        BEGIN
            CASE v_column
                WHEN 'cnpj' THEN
                    v_message := aux.create_cnpj_trigger(p_schema_name, p_table_name, v_column);
                WHEN 'cpf' THEN
                    v_message := aux.create_cpf_trigger(p_schema_name, p_table_name, v_column);
                WHEN 'postal_code' THEN
                    v_message := aux.create_postal_code_trigger(p_schema_name, p_table_name, v_column);
                WHEN 'email' THEN
                    v_message := aux.create_email_trigger(p_schema_name, p_table_name, v_column);
                WHEN 'photo_url' THEN
                    v_message := aux.create_url_trigger(p_schema_name, p_table_name, v_column);
                ELSE
                    v_message := 'Coluna ' || v_column || ' não suportada para validação automática';
            END CASE;
            
            v_result := array_append(v_result, v_message);
        EXCEPTION
            WHEN OTHERS THEN
                v_result := array_append(v_result, 'Erro ao criar trigger para ' || v_column || ': ' || SQLERRM);
        END;
    END LOOP;
    
    RETURN v_result;
END;
$$;

COMMENT ON FUNCTION aux.create_validation_triggers(text, text, text[]) IS 'Função genérica para criar todos os triggers de validação de uma tabela';

-- =====================================================
-- VERIFICAÇÃO DE FUNÇÕES CRIADAS
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '🔍 Verificando funções criadas no schema aux...';
    
    -- Verificar funções de trigger
    IF EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_schema = 'aux' AND routine_name = 'clean_cnpj_before_insert_update') THEN
        RAISE NOTICE '✅ Função aux.clean_cnpj_before_insert_update criada';
    ELSE
        RAISE NOTICE '❌ Função aux.clean_cnpj_before_insert_update não foi criada';
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_schema = 'aux' AND routine_name = 'clean_cpf_before_insert_update') THEN
        RAISE NOTICE '✅ Função aux.clean_cpf_before_insert_update criada';
    ELSE
        RAISE NOTICE '❌ Função aux.clean_cpf_before_insert_update não foi criada';
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_schema = 'aux' AND routine_name = 'clean_postal_code_before_insert_update') THEN
        RAISE NOTICE '✅ Função aux.clean_postal_code_before_insert_update criada';
    ELSE
        RAISE NOTICE '❌ Função aux.clean_postal_code_before_insert_update não foi criada';
    END IF;
    
    -- Verificar funções de criação de triggers
    IF EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_schema = 'aux' AND routine_name = 'create_cnpj_trigger') THEN
        RAISE NOTICE '✅ Função aux.create_cnpj_trigger criada';
    ELSE
        RAISE NOTICE '❌ Função aux.create_cnpj_trigger não foi criada';
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_schema = 'aux' AND routine_name = 'create_validation_triggers') THEN
        RAISE NOTICE '✅ Função aux.create_validation_triggers criada';
    ELSE
        RAISE NOTICE '❌ Função aux.create_validation_triggers não foi criada';
    END IF;
    
    RAISE NOTICE '🎯 Expansão do schema aux concluída com sucesso!';
END $$;

-- =====================================================
-- TESTE DE FUNCIONALIDADE
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '🧪 Testando funcionalidades criadas...';
    
    -- Testar se as funções estão funcionando
    BEGIN
        DECLARE
            cnpj_teste text;
            cpf_teste text;
            cep_teste text;
        BEGIN
            -- Testar validação de CNPJ
            cnpj_teste := aux.clean_and_validate_cnpj('11.222.333/0001-81');
            RAISE NOTICE '✅ Validação de CNPJ funcionando: %', cnpj_teste;
            
            -- Testar validação de CPF
            cpf_teste := aux.clean_and_validate_cpf('123.456.789-09');
            RAISE NOTICE '✅ Validação de CPF funcionando: %', cpf_teste;
            
            -- Testar validação de CEP
            cep_teste := aux.clean_and_validate_postal_code('12345-678');
            RAISE NOTICE '✅ Validação de CEP funcionando: %', cep_teste;
            
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE '❌ Erro ao testar validações: %', SQLERRM;
        END;
    END;
    
    RAISE NOTICE '🎯 Testes de funcionalidade concluídos!';
END $$;

-- =====================================================
-- RESUMO DA EXPANSÃO
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '🎯 =====================================================';
    RAISE NOTICE '🎯 EXPANSÃO DO SCHEMA AUX - FUNÇÕES GENÉRICAS';
    RAISE NOTICE '🎯 =====================================================';
    RAISE NOTICE '✅ Funções de trigger genéricas criadas';
    RAISE NOTICE '✅ Funções de criação de triggers criadas';
    RAISE NOTICE '✅ Função de criação automática de triggers criada';
    RAISE NOTICE '✅ Nomenclatura existente mantida';
    RAISE NOTICE '✅ Compatibilidade preservada';
    RAISE NOTICE '🎯 Schema aux expandido com sucesso!';
    RAISE NOTICE '=====================================================';
    RAISE NOTICE '';
    RAISE NOTICE '📋 PRÓXIMOS PASSOS:';
    RAISE NOTICE '1. Migrar establishments_extension para usar aux.*';
    RAISE NOTICE '2. Verificar employees_extension está 100% limpo';
    RAISE NOTICE '3. Migrar quotation_schema se necessário';
    RAISE NOTICE '4. Limpeza final de funções duplicadas';
    RAISE NOTICE '=====================================================';
END $$;
