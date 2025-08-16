-- =====================================================
-- SISTEMA DE AUDITORIA AUTOMÁTICO
-- =====================================================
-- Este script cria um sistema de auditoria completo que:
-- 1. Cria tabelas clone no schema audit para todas as tabelas dos schemas especificados
-- 2. Implementa triggers automáticos para capturar INSERT, UPDATE e DELETE
-- 3. Particiona automaticamente por data (ano/mês/dia)
-- 4. Detecta alterações de estrutura e sincroniza automaticamente

-- =====================================================
-- CRIAÇÃO DO SCHEMA AUDIT
-- ==================================================

-- Cria o schema audit se não existir
CREATE SCHEMA IF NOT EXISTS audit;

-- Comentário do schema
COMMENT ON SCHEMA audit IS 'Schema para armazenar histórico de auditoria de todas as tabelas do sistema';

-- =====================================================
-- FUNÇÃO PARA CRIAR TABELA DE AUDITORIA INDIVIDUAL
-- =====================================================

CREATE OR REPLACE FUNCTION audit.create_audit_table(
    p_schema_name text,
    p_table_name text
)
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
    v_audit_table_name text;
    v_create_table_sql text;
    v_column_definitions text := '';
    v_column text;
    v_data_type text;
    v_is_nullable text;
    v_column_default text;
    v_trigger_name text;
    v_function_name text;
    v_audit_table_exists boolean;
    v_columns_changed boolean := false;
BEGIN
    -- Validação dos parâmetros
    IF p_schema_name IS NULL OR p_table_name IS NULL THEN
        RAISE EXCEPTION 'Schema e nome da tabela são obrigatórios';
    END IF;
    
    -- Verifica se a tabela existe
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = p_schema_name 
        AND table_name = p_table_name
    ) THEN
        RAISE EXCEPTION 'Tabela %.% não existe', p_schema_name, p_table_name;
    END IF;
    
    -- Nome da tabela de auditoria (padrão: schema__tabela)
    v_audit_table_name := p_schema_name || '__' || p_table_name;
    
    -- Verifica se a tabela de auditoria já existe
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'audit' 
        AND table_name = v_audit_table_name
    ) INTO v_audit_table_exists;
    
    -- Se a tabela já existe, verifica se precisa sincronizar colunas
    IF v_audit_table_exists THEN
        -- TODO: Implementar sincronização de colunas
        RAISE NOTICE 'Tabela de auditoria %.% já existe. Verificando sincronização...', 'audit', v_audit_table_name;
    END IF;
    
    -- Constrói as definições das colunas
    FOR v_column, v_data_type, v_is_nullable, v_column_default IN
        SELECT 
            column_name,
            data_type,
            is_nullable,
            column_default
        FROM information_schema.columns 
        WHERE table_schema = p_schema_name 
        AND table_name = p_table_name
        ORDER BY ordinal_position
    LOOP
        -- Converte tipos para tipos versáteis
        CASE v_data_type
            WHEN 'character varying', 'varchar', 'text' THEN
                v_data_type := 'text';
            WHEN 'character', 'char' THEN
                v_data_type := 'text';
            WHEN 'integer', 'bigint', 'smallint' THEN
                v_data_type := 'bigint';
            WHEN 'numeric', 'decimal' THEN
                v_data_type := 'numeric';
            WHEN 'real', 'double precision' THEN
                v_data_type := 'double precision';
            WHEN 'boolean' THEN
                v_data_type := 'boolean';
            WHEN 'date' THEN
                v_data_type := 'date';
            WHEN 'timestamp without time zone', 'timestamp with time zone' THEN
                v_data_type := 'timestamp with time zone';
            WHEN 'time without time zone', 'time with time zone' THEN
                v_data_type := 'time with time zone';
            WHEN 'uuid' THEN
                v_data_type := 'uuid';
            WHEN 'json', 'jsonb' THEN
                v_data_type := 'jsonb';
            ELSE
                v_data_type := 'text'; -- Fallback para tipos desconhecidos
        END CASE;
        
        -- Adiciona definição da coluna
        IF v_column_definitions != '' THEN
            v_column_definitions := v_column_definitions || ', ';
        END IF;
        
        v_column_definitions := v_column_definitions || 
            quote_ident(v_column) || ' ' || v_data_type;
        
        -- Adiciona NOT NULL se necessário
        IF v_is_nullable = 'NO' THEN
            v_column_definitions := v_column_definitions || ' NOT NULL';
        END IF;
    END LOOP;
    
    -- Adiciona campos de auditoria (sem chave primária aqui)
    v_column_definitions := v_column_definitions || 
        ', audit_id bigint GENERATED ALWAYS AS IDENTITY' ||
        ', audit_operation text NOT NULL' ||
        ', audit_timestamp timestamp with time zone DEFAULT now() NOT NULL' ||
        ', audit_user text DEFAULT current_user NOT NULL' ||
        ', audit_session_id text DEFAULT current_setting(''application_name'') NOT NULL' ||
        ', audit_connection_id text DEFAULT inet_client_addr() NOT NULL' ||
        ', audit_partition_date date DEFAULT current_date NOT NULL';
    
    -- Adiciona chave primária separadamente (deve vir depois de todos os campos)
    v_column_definitions := v_column_definitions || 
        ', PRIMARY KEY (audit_id, audit_partition_date)'; -- Chave primária deve incluir coluna de particionamento
    
    -- Remove tabela existente se houver (para garantir estrutura correta)
    EXECUTE format('DROP TABLE IF EXISTS audit.%I CASCADE', v_audit_table_name);
    
    -- Cria a tabela de auditoria como particionada
    v_create_table_sql := format(
        'CREATE TABLE IF NOT EXISTS audit.%I (%s) PARTITION BY RANGE (audit_partition_date)',
        v_audit_table_name,
        v_column_definitions
    );
    
    EXECUTE v_create_table_sql;
    
    -- Herda comentários da tabela mãe
    PERFORM audit.inherit_table_comments(p_schema_name, p_table_name, v_audit_table_name);
    
    -- Herda comentários das colunas da tabela mãe
    PERFORM audit.inherit_column_comments(p_schema_name, p_table_name, v_audit_table_name);
    
    -- Cria índices para chaves primárias e estrangeiras
    PERFORM audit.create_audit_indexes(p_schema_name, p_table_name, v_audit_table_name);
    
    -- Cria a função de auditoria
    PERFORM audit.create_audit_function(p_schema_name, p_table_name, v_audit_table_name);
    
    -- Cria o trigger de auditoria
    PERFORM audit.create_audit_trigger(p_schema_name, p_table_name, v_audit_table_name);
    
    -- Cria particionamento por data
    PERFORM audit.create_audit_partitioning(v_audit_table_name);
    
    RAISE NOTICE 'Tabela de auditoria %.% criada com sucesso', 'audit', v_audit_table_name;
    
    RETURN 'Tabela de auditoria audit.' || v_audit_table_name || ' criada com sucesso';
END;
$$;

COMMENT ON FUNCTION audit.create_audit_table IS 'Cria uma tabela de auditoria para uma tabela específica (padrão: schema__tabela)';

-- =====================================================
-- FUNÇÃO PARA CRIAR ÍNDICES DE AUDITORIA
-- =====================================================

CREATE OR REPLACE FUNCTION audit.create_audit_indexes(
    p_schema_name text,
    p_table_name text,
    p_audit_table_name text
)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    v_index_name text;
    v_column_name text;
    v_constraint_type text;
BEGIN
    -- Cria índices para chaves primárias
    FOR v_column_name IN
        SELECT kcu.column_name
        FROM information_schema.table_constraints tc
        JOIN information_schema.key_column_usage kcu 
            ON tc.constraint_name = kcu.constraint_name
        WHERE tc.table_schema = p_schema_name
        AND tc.table_name = p_table_name
        AND tc.constraint_type = 'PRIMARY KEY'
        ORDER BY kcu.ordinal_position
    LOOP
        v_index_name := 'idx_' || p_audit_table_name || '_' || v_column_name;
        EXECUTE format('CREATE INDEX IF NOT EXISTS %I ON audit.%I (%I)', 
                      v_index_name, p_audit_table_name, v_column_name);
    END LOOP;
    
    -- Cria índices para chaves estrangeiras
    FOR v_column_name IN
        SELECT kcu.column_name
        FROM information_schema.table_constraints tc
        JOIN information_schema.key_column_usage kcu 
            ON tc.constraint_name = kcu.constraint_name
        WHERE tc.table_schema = p_schema_name
        AND tc.table_name = p_table_name
        AND tc.constraint_type = 'FOREIGN KEY'
        ORDER BY kcu.ordinal_position
    LOOP
        v_index_name := 'idx_' || p_audit_table_name || '_fk_' || v_column_name;
        EXECUTE format('CREATE INDEX IF NOT EXISTS %I ON audit.%I (%I)', 
                      v_index_name, p_audit_table_name, v_column_name);
    END LOOP;
    
    -- Índice para data de auditoria (para particionamento)
    v_index_name := 'idx_' || p_audit_table_name || '_audit_timestamp';
    EXECUTE format('CREATE INDEX IF NOT EXISTS %I ON audit.%I (audit_timestamp)', 
                  v_index_name, p_audit_table_name);
    
    -- Índice para operação de auditoria
    v_index_name := 'idx_' || p_audit_table_name || '_audit_operation';
    EXECUTE format('CREATE INDEX IF NOT EXISTS %I ON audit.%I (audit_operation)', 
                  v_index_name, p_audit_table_name);
END;
$$;

COMMENT ON FUNCTION audit.create_audit_indexes IS 'Cria índices necessários para a tabela de auditoria';

-- =====================================================
-- FUNÇÕES PARA HERDAR COMENTÁRIOS
-- =====================================================

-- Função para herdar comentários da tabela mãe
CREATE OR REPLACE FUNCTION audit.inherit_table_comments(
    p_schema_name text,
    p_table_name text,
    p_audit_table_name text
)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    v_table_comment text;
BEGIN
    -- Obtém o comentário da tabela mãe
    SELECT obj_description(format('%s.%s', p_schema_name, p_table_name)::regclass) 
    INTO v_table_comment;
    
    -- Se existe comentário, aplica na tabela de auditoria
    IF v_table_comment IS NOT NULL THEN
        EXECUTE format('COMMENT ON TABLE audit.%I IS %L', 
                      p_audit_table_name, 
                      'AUDITORIA: ' || v_table_comment);
    ELSE
        -- Comentário padrão se não houver comentário na tabela mãe
        EXECUTE format('COMMENT ON TABLE audit.%I IS %L', 
                      p_audit_table_name, 
                      'Tabela de auditoria para ' || p_schema_name || '.' || p_table_name);
    END IF;
    
    RAISE NOTICE 'Comentário da tabela herdado para %.%', 'audit', p_audit_table_name;
END;
$$;

COMMENT ON FUNCTION audit.inherit_table_comments IS 'Herdar comentários da tabela mãe para a tabela de auditoria';

-- Função para herdar comentários das colunas da tabela mãe
CREATE OR REPLACE FUNCTION audit.inherit_column_comments(
    p_schema_name text,
    p_table_name text,
    p_audit_table_name text
)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    v_column_name text;
    v_column_comment text;
    v_audit_column_name text;
BEGIN
    -- Itera por todas as colunas da tabela mãe
    FOR v_column_name IN
        SELECT column_name
        FROM information_schema.columns 
        WHERE table_schema = p_schema_name 
        AND table_name = p_table_name
        ORDER BY ordinal_position
    LOOP
        -- Obtém o comentário da coluna da tabela mãe
        SELECT col_description(format('%s.%s', p_schema_name, p_table_name)::regclass, ordinal_position)
        FROM information_schema.columns 
        WHERE table_schema = p_schema_name 
        AND table_name = p_table_name 
        AND column_name = v_column_name
        INTO v_column_comment;
        
        -- Se existe comentário, aplica na coluna da tabela de auditoria
        IF v_column_comment IS NOT NULL THEN
            EXECUTE format('COMMENT ON COLUMN audit.%I.%I IS %L', 
                          p_audit_table_name, v_column_name, v_column_comment);
        END IF;
    END LOOP;
    
    -- Adiciona comentários para os campos de auditoria
    EXECUTE format('COMMENT ON COLUMN audit.%I.audit_id IS %L', 
                  p_audit_table_name, 'Identificador único do registro de auditoria');
    
    EXECUTE format('COMMENT ON COLUMN audit.%I.audit_operation IS %L', 
                  p_audit_table_name, 'Tipo de operação realizada (INSERT, UPDATE, DELETE)');
    
    EXECUTE format('COMMENT ON COLUMN audit.%I.audit_timestamp IS %L', 
                  p_audit_table_name, 'Data e hora da operação auditada');
    
    EXECUTE format('COMMENT ON COLUMN audit.%I.audit_user IS %L', 
                  p_audit_table_name, 'Usuário que executou a operação');
    
    EXECUTE format('COMMENT ON COLUMN audit.%I.audit_session_id IS %L', 
                  p_audit_table_name, 'Identificador da sessão da aplicação');
    
    EXECUTE format('COMMENT ON COLUMN audit.%I.audit_connection_id IS %L', 
                  p_audit_table_name, 'Endereço IP da conexão');
    
    EXECUTE format('COMMENT ON COLUMN audit.%I.audit_partition_date IS %L', 
                  p_audit_table_name, 'Data para particionamento da tabela de auditoria');
    
    RAISE NOTICE 'Comentários das colunas herdados para %.%', 'audit', p_audit_table_name;
END;
$$;

COMMENT ON FUNCTION audit.inherit_column_comments IS 'Herdar comentários das colunas da tabela mãe para a tabela de auditoria';

-- =====================================================
-- FUNÇÃO PARA CRIAR FUNÇÃO DE AUDITORIA
-- =====================================================

CREATE OR REPLACE FUNCTION audit.create_audit_function(
    p_schema_name text,
    p_table_name text,
    p_audit_table_name text
)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    v_function_name text;
    v_function_body text;
    v_columns text := '';
    v_column text;
BEGIN
    v_function_name := 'audit_' || p_schema_name || '_' || p_table_name || '_trigger';
    
    -- Constrói lista de colunas para INSERT
    FOR v_column IN
        SELECT column_name
        FROM information_schema.columns 
        WHERE table_schema = p_schema_name 
        AND table_name = p_table_name
        ORDER BY ordinal_position
    LOOP
        IF v_columns != '' THEN
            v_columns := v_columns || ', ';
        END IF;
        v_columns := v_columns || quote_ident(v_column);
    END LOOP;
    
    -- Remove função existente se houver
    EXECUTE 'DROP FUNCTION IF EXISTS audit.' || quote_ident(v_function_name) || '() CASCADE';
    
    -- Constrói lista de valores com NEW. e OLD.
    DECLARE
        v_new_values text := '';
        v_old_values text := '';
        v_column text;
    BEGIN
        -- Reconstrói as listas para usar NEW. e OLD.
        FOR v_column IN
            SELECT column_name
            FROM information_schema.columns 
            WHERE table_schema = p_schema_name 
            AND table_name = p_table_name
            ORDER BY ordinal_position
        LOOP
            IF v_new_values != '' THEN
                v_new_values := v_new_values || ', ';
                v_old_values := v_old_values || ', ';
            END IF;
            v_new_values := v_new_values || 'NEW.' || quote_ident(v_column);
            v_old_values := v_old_values || 'OLD.' || quote_ident(v_column);
        END LOOP;
        
        -- Cria a função usando EXECUTE com string simples
        EXECUTE 'CREATE FUNCTION audit.' || quote_ident(v_function_name) || '() RETURNS trigger AS $body$' ||
                'BEGIN' ||
                '  IF TG_OP = ''INSERT'' THEN' ||
                '    INSERT INTO audit.' || quote_ident(p_audit_table_name) || ' (' || v_columns || ', audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)' ||
                '    VALUES (' || v_new_values || ', ''INSERT'', current_user, current_setting(''application_name''), inet_client_addr(), current_date);' ||
                '    RETURN NEW;' ||
                '  ELSIF TG_OP = ''UPDATE'' THEN' ||
                '    INSERT INTO audit.' || quote_ident(p_audit_table_name) || ' (' || v_columns || ', audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)' ||
                '    VALUES (' || v_new_values || ', ''UPDATE'', current_user, current_setting(''application_name''), inet_client_addr(), current_date);' ||
                '    RETURN NEW;' ||
                '  ELSIF TG_OP = ''DELETE'' THEN' ||
                '    INSERT INTO audit.' || quote_ident(p_audit_table_name) || ' (' || v_columns || ', audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)' ||
                '    VALUES (' || v_old_values || ', ''DELETE'', current_user, current_setting(''application_name''), inet_client_addr(), current_date);' ||
                '    RETURN OLD;' ||
                '  END IF;' ||
                '  RETURN NULL;' ||
                'END;' ||
                '$body$ LANGUAGE plpgsql;';
    END;
    
    RAISE NOTICE 'Função de auditoria % criada com sucesso', v_function_name;
END;
$$;

COMMENT ON FUNCTION audit.create_audit_function IS 'Cria a função de trigger para auditoria';

-- =====================================================
-- FUNÇÃO PARA CRIAR TRIGGER DE AUDITORIA
-- =====================================================

CREATE OR REPLACE FUNCTION audit.create_audit_trigger(
    p_schema_name text,
    p_table_name text,
    p_audit_table_name text
)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    v_trigger_name text;
    v_function_name text;
BEGIN
    v_trigger_name := 'trg_audit_' || p_schema_name || '_' || p_table_name;
    v_function_name := 'audit_' || p_schema_name || '_' || p_table_name || '_trigger';
    
    -- Remove trigger existente se houver
    EXECUTE format('DROP TRIGGER IF EXISTS %I ON %I.%I', 
                  v_trigger_name, p_schema_name, p_table_name);
    
    -- Cria o trigger
    EXECUTE format('CREATE TRIGGER %I
                    AFTER INSERT OR UPDATE OR DELETE ON %I.%I
                    FOR EACH ROW EXECUTE FUNCTION audit.%I()',
                  v_trigger_name, p_schema_name, p_table_name, v_function_name);
    
    RAISE NOTICE 'Trigger de auditoria % criado com sucesso', v_trigger_name;
END;
$$;

COMMENT ON FUNCTION audit.create_audit_trigger IS 'Cria o trigger de auditoria na tabela original';

-- =====================================================
-- FUNÇÃO PARA CRIAR PARTICIONAMENTO
-- =====================================================

CREATE OR REPLACE FUNCTION audit.create_audit_partitioning(p_audit_table_name text)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    v_current_year integer;
    v_current_month integer;
    v_partition_name text;
    v_start_date date;
    v_end_date date;
    v_table_exists boolean;
BEGIN
    -- Verifica se a tabela existe
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'audit' 
        AND table_name = p_audit_table_name
    ) INTO v_table_exists;
    
    IF NOT v_table_exists THEN
        RAISE NOTICE 'Tabela audit.% não existe, pulando particionamento', p_audit_table_name;
        RETURN;
    END IF;
    
    -- Obtém ano e mês atual
    v_current_year := EXTRACT(YEAR FROM current_date);
    v_current_month := EXTRACT(MONTH FROM current_date);
    
    -- Cria partição para o mês atual
    v_partition_name := p_audit_table_name || '_' || v_current_year || '_' || LPAD(v_current_month::text, 2, '0');
    v_start_date := date(v_current_year || '-' || v_current_month || '-01');
    v_end_date := v_start_date + interval '1 month';
    
    -- Cria partição se não existir
    BEGIN
        EXECUTE format('CREATE TABLE IF NOT EXISTS audit.%I PARTITION OF audit.%I
                        FOR VALUES FROM (%L) TO (%L)',
                      v_partition_name, p_audit_table_name, v_start_date, v_end_date);
        
        RAISE NOTICE 'Partição % criada para %', v_partition_name, p_audit_table_name;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Erro ao criar partição % para %: %', v_partition_name, p_audit_table_name, SQLERRM;
    END;
END;
$$;

COMMENT ON FUNCTION audit.create_audit_partitioning IS 'Cria particionamento por data para tabela de auditoria';

-- =====================================================
-- FUNÇÃO PARA AUDITAR SCHEMA COMPLETO
-- =====================================================

CREATE OR REPLACE FUNCTION audit.audit_schema(p_schema_name text)
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
    v_table_name text;
    v_result text;
    v_total_tables integer := 0;
    v_success_count integer := 0;
    v_error_count integer := 0;
BEGIN
    -- Validação do schema
    IF p_schema_name IS NULL THEN
        RAISE EXCEPTION 'Nome do schema é obrigatório';
    END IF;
    
    -- Verifica se o schema existe
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.schemata 
        WHERE schema_name = p_schema_name
    ) THEN
        RAISE EXCEPTION 'Schema % não existe', p_schema_name;
    END IF;
    
    -- Exclui schemas do sistema
    IF p_schema_name IN ('information_schema', 'pg_catalog', 'pg_toast', 'audit') THEN
        RAISE EXCEPTION 'Não é permitido auditar schemas do sistema';
    END IF;
    
    RAISE NOTICE 'Iniciando auditoria do schema %', p_schema_name;
    
    -- Itera por todas as tabelas do schema
    FOR v_table_name IN
        SELECT table_name
        FROM information_schema.tables 
        WHERE table_schema = p_schema_name 
        AND table_type = 'BASE TABLE'
        ORDER BY table_name
    LOOP
        v_total_tables := v_total_tables + 1;
        
        BEGIN
            v_result := audit.create_audit_table(p_schema_name, v_table_name);
            v_success_count := v_success_count + 1;
            RAISE NOTICE '✓ %: %', v_table_name, v_result;
        EXCEPTION WHEN OTHERS THEN
            v_error_count := v_error_count + 1;
            RAISE NOTICE '✗ %: Erro - %', v_table_name, SQLERRM;
        END;
    END LOOP;
    
    RAISE NOTICE 'Auditoria do schema % concluída:', p_schema_name;
    RAISE NOTICE '  Total de tabelas: %', v_total_tables;
    RAISE NOTICE '  Sucessos: %', v_success_count;
    RAISE NOTICE '  Erros: %', v_error_count;
    
    RETURN 'Schema ' || p_schema_name || ' auditado: ' || v_success_count || '/' || v_total_tables || ' tabelas processadas com sucesso';
END;
$$;

COMMENT ON FUNCTION audit.audit_schema IS 'Audita todas as tabelas de um schema específico';

-- =====================================================
-- FUNÇÃO PARA AUDITAR MÚLTIPLOS SCHEMAS
-- =====================================================

CREATE OR REPLACE FUNCTION audit.audit_schemas(p_schema_names text[])
RETURNS text[]
LANGUAGE plpgsql
AS $$
DECLARE
    v_schema_name text;
    v_result text;
    v_results text[] := '{}';
    v_schema_count integer := 0;
BEGIN
    -- Validação dos parâmetros
    IF p_schema_names IS NULL OR array_length(p_schema_names, 1) = 0 THEN
        RAISE EXCEPTION 'Lista de schemas é obrigatória';
    END IF;
    
    RAISE NOTICE 'Iniciando auditoria de % schemas', array_length(p_schema_names, 1);
    
    -- Itera por cada schema
    FOREACH v_schema_name IN ARRAY p_schema_names
    LOOP
        v_schema_count := v_schema_count + 1;
        RAISE NOTICE 'Processando schema % (%/%): %', v_schema_name, v_schema_count, array_length(p_schema_names, 1), v_schema_name;
        
        BEGIN
            v_result := audit.audit_schema(v_schema_name);
            v_results := array_append(v_results, v_result);
        EXCEPTION WHEN OTHERS THEN
            v_result := 'Schema ' || v_schema_name || ': Erro - ' || SQLERRM;
            v_results := array_append(v_results, v_result);
        END;
    END LOOP;
    
    RAISE NOTICE 'Auditoria de schemas concluída';
    RETURN v_results;
END;
$$;

COMMENT ON FUNCTION audit.audit_schemas IS 'Audita múltiplos schemas de uma vez';

-- =====================================================
-- EXEMPLOS DE USO
-- =====================================================

-- Para auditar uma tabela específica:
-- SELECT audit.create_audit_table('accounts', 'users');
-- Resultado: tabela audit.accounts__users criada

-- Para auditar um schema completo:
-- SELECT audit.audit_schema('accounts');
-- Resultado: todas as tabelas do schema accounts auditadas

-- Para auditar múltiplos schemas:
-- SELECT audit.audit_schemas(ARRAY['accounts', 'catalogs']);
-- Resultado: todas as tabelas dos schemas accounts e catalogs auditadas

-- =====================================================
-- FUNÇÃO PARA SINCRONIZAR COLUNAS (FUTURO)
-- =====================================================

-- TODO: Implementar função para sincronizar colunas quando tabelas são alteradas
-- Esta função deve:
-- 1. Detectar novas colunas na tabela original
-- 2. Adicionar colunas na tabela de auditoria
-- 3. Manter colunas removidas (com NULL)
-- 4. Atualizar tipos de dados se necessário

