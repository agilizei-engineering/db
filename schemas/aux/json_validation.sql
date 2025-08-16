-- =====================================================
-- VALIDAÇÃO JSONB AUTOMÁTICA - SCHEMA: aux
-- =====================================================
-- Este arquivo implementa o sistema de validação JSONB automático
-- Inclui tabela de parâmetros, funções de validação e triggers automáticos

-- =====================================================
-- TABELA: json_validation_params
-- =====================================================
-- Descrição: Armazena parâmetros de validação para campos JSONB
-- Funcionalidade: Define quais chaves são válidas para cada tabela/campo JSONB

CREATE TABLE IF NOT EXISTS aux.json_validation_params (
    param_id uuid DEFAULT gen_random_uuid() NOT NULL,
    param_name text NOT NULL,
    param_value text NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now()
);

-- Comentários
COMMENT ON TABLE aux.json_validation_params IS 'Parâmetros de validação para campos JSONB em todo o sistema';
COMMENT ON COLUMN aux.json_validation_params.param_id IS 'Identificador único do parâmetro';
COMMENT ON COLUMN aux.json_validation_params.param_name IS 'Nome do parâmetro (formato: schema.table)';
COMMENT ON COLUMN aux.json_validation_params.param_value IS 'Valor do parâmetro (formato: column.json_key)';
COMMENT ON COLUMN aux.json_validation_params.created_at IS 'Data de criação do registro';
COMMENT ON COLUMN aux.json_validation_params.updated_at IS 'Data da última atualização do registro';

-- Constraints
ALTER TABLE aux.json_validation_params ADD CONSTRAINT json_validation_params_pkey PRIMARY KEY (param_id);
ALTER TABLE aux.json_validation_params ADD CONSTRAINT json_validation_params_unique UNIQUE (param_name, param_value);

-- Índices
CREATE INDEX IF NOT EXISTS idx_json_validation_params_name ON aux.json_validation_params (param_name);
CREATE INDEX IF NOT EXISTS idx_json_validation_params_value ON aux.json_validation_params (param_value);

-- Trigger para updated_at
SELECT aux.create_updated_at_trigger('aux', 'json_validation_params');

-- =====================================================
-- FUNÇÃO: validate_json_field
-- =====================================================
-- Descrição: Valida se um campo JSONB contém as chaves corretas
-- Parâmetros: nome da tabela, nome da coluna, dados JSONB
-- Retorna: true se válido, exceção se inválido

CREATE OR REPLACE FUNCTION aux.validate_json_field(
    p_table_name text,
    p_column_name text,
    p_json_data jsonb
)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
    v_param_value text;
    v_required_keys text[];
    v_json_keys text[];
    v_missing_keys text[];
    v_extra_keys text[];
    v_full_table_name text;
BEGIN
    -- Constrói nome completo da tabela
    v_full_table_name := p_table_name;
    
    -- Buscar todas as chaves válidas para esta tabela/campo
    SELECT array_agg(param_value) INTO v_required_keys
    FROM aux.json_validation_params
    WHERE param_name = v_full_table_name;
    
    -- Se não há parâmetros definidos, aceita qualquer JSON
    IF v_required_keys IS NULL THEN
        RETURN true;
    END IF;
    
    -- Extrair chaves do JSONB fornecido
    SELECT array_agg(key) INTO v_json_keys
    FROM jsonb_object_keys(p_json_data) AS key;
    
    -- Se não há chaves no JSON, verifica se é obrigatório ter chaves
    IF v_json_keys IS NULL THEN
        -- Se há parâmetros definidos mas JSON está vazio, é inválido
        IF array_length(v_required_keys, 1) > 0 THEN
            RAISE EXCEPTION 'Campo JSONB não pode estar vazio para %.%', v_full_table_name, p_column_name;
        END IF;
        RETURN true;
    END IF;
    
    -- Verificar chaves faltantes
    SELECT array_agg(required.key) INTO v_missing_keys
    FROM unnest(v_required_keys) AS required(key)
    WHERE NOT (required.key = ANY(v_json_keys));
    
    -- Verificar chaves extras
    SELECT array_agg(json.key) INTO v_extra_keys
    FROM unnest(v_json_keys) AS json(key)
    WHERE NOT (json.key = ANY(v_required_keys));
    
    -- Se há chaves faltantes, retorna erro
    IF array_length(v_missing_keys, 1) > 0 THEN
        RAISE EXCEPTION 'Chaves obrigatórias faltando em %.%: %', v_full_table_name, p_column_name, array_to_string(v_missing_keys, ', ');
    END IF;
    
    -- Se há chaves extras, retorna erro
    IF array_length(v_extra_keys, 1) > 0 THEN
        RAISE EXCEPTION 'Chaves não permitidas em %.%: %', v_full_table_name, p_column_name, array_to_string(v_extra_keys, ', ');
    END IF;
    
    RETURN true;
END;
$$;

COMMENT ON FUNCTION aux.validate_json_field IS 'Valida se um campo JSONB contém as chaves corretas baseado nos parâmetros configurados';

-- =====================================================
-- FUNÇÃO: create_json_validation_trigger
-- =====================================================
-- Descrição: Cria trigger de validação JSONB para uma coluna específica
-- Parâmetros: schema, tabela, coluna
-- Retorna: void

CREATE OR REPLACE FUNCTION aux.create_json_validation_trigger(
    p_schema_name text,
    p_table_name text,
    p_column_name text
)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    v_full_table_name text;
    v_trigger_name text;
    v_function_name text;
    v_trigger_exists boolean;
BEGIN
    -- Validações
    IF p_schema_name IS NULL OR p_table_name IS NULL OR p_column_name IS NULL THEN
        RAISE EXCEPTION 'Schema, tabela e coluna são obrigatórios';
    END IF;
    
    -- Verifica se a tabela existe
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = p_schema_name 
        AND table_name = p_table_name
    ) THEN
        RAISE EXCEPTION 'Tabela %.% não existe', p_schema_name, p_table_name;
    END IF;
    
    -- Verifica se a coluna é JSONB
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = p_schema_name 
        AND table_name = p_table_name 
        AND column_name = p_column_name 
        AND data_type = 'jsonb'
    ) THEN
        RAISE EXCEPTION 'Coluna %.%.% não é do tipo JSONB', p_schema_name, p_table_name, p_column_name;
    END IF;
    
    v_full_table_name := p_schema_name || '.' || p_table_name;
    v_trigger_name := p_table_name || '_' || p_column_name || '_json_validation';
    v_function_name := 'aux.validate_json_field';
    
    -- Verifica se o trigger já existe
    SELECT EXISTS (
        SELECT 1 FROM information_schema.triggers 
        WHERE trigger_schema = p_schema_name 
        AND trigger_name = v_trigger_name
    ) INTO v_trigger_exists;
    
    -- Remove trigger existente se houver
    IF v_trigger_exists THEN
        EXECUTE format('DROP TRIGGER IF EXISTS %I ON %I.%I', 
                      v_trigger_name, p_schema_name, p_table_name);
    END IF;
    
    -- Cria função de validação específica para esta tabela/coluna
    EXECUTE format('
        CREATE OR REPLACE FUNCTION %I.%I_%I_json_validation()
        RETURNS TRIGGER AS $func$
        BEGIN
            -- Validar o campo JSONB
            IF NOT aux.validate_json_field(%L, %L, NEW.%I) THEN
                RAISE EXCEPTION ''Validação JSONB falhou para %.%.%'';
            END IF;
            RETURN NEW;
        END;
        $func$ LANGUAGE plpgsql
    ', 
    p_schema_name, p_table_name, p_column_name,
    p_schema_name, p_table_name, p_column_name,
    v_full_table_name, p_column_name, p_column_name,
    p_schema_name, p_table_name, p_column_name
    );
    
    -- Cria o trigger
    EXECUTE format('
        CREATE TRIGGER %I
        BEFORE INSERT OR UPDATE ON %I.%I
        FOR EACH ROW
        EXECUTE FUNCTION %I.%I_%I_json_validation()
    ', 
    v_trigger_name, 
    p_schema_name, 
    p_table_name, 
    p_schema_name, p_table_name, p_column_name
    );
    
    RAISE NOTICE 'Trigger de validação JSON criado: % em %.%', v_trigger_name, p_schema_name, p_table_name;
END;
$$;

COMMENT ON FUNCTION aux.create_json_validation_trigger IS 'Cria trigger de validação JSONB para uma coluna específica';

-- =====================================================
-- FUNÇÃO: setup_json_validation_triggers
-- =====================================================
-- Descrição: Configura automaticamente triggers de validação para todas as colunas JSONB
-- Parâmetros: nenhum
-- Retorna: void

CREATE OR REPLACE FUNCTION aux.setup_json_validation_triggers()
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    r RECORD;
    v_count integer := 0;
BEGIN
    RAISE NOTICE 'Iniciando configuração automática de triggers de validação JSONB...';
    
    -- Buscar todas as colunas JSONB no banco (excluindo schemas do sistema)
    FOR r IN 
        SELECT 
            table_schema,
            table_name,
            column_name
        FROM information_schema.columns 
        WHERE data_type = 'jsonb'
        AND table_schema NOT IN ('information_schema', 'pg_catalog', 'pg_toast')
        AND table_schema NOT LIKE 'audit%'
        ORDER BY table_schema, table_name, column_name
    LOOP
        BEGIN
            -- Criar trigger para cada coluna JSONB
            PERFORM aux.create_json_validation_trigger(
                r.table_schema, 
                r.table_name, 
                r.column_name
            );
            v_count := v_count + 1;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Erro ao criar trigger para %.%.%: %', 
                        r.table_schema, r.table_name, r.column_name, SQLERRM;
        END;
    END LOOP;
    
    RAISE NOTICE 'Configuração concluída: % triggers de validação JSONB criados', v_count;
END;
$$;

COMMENT ON FUNCTION aux.setup_json_validation_triggers IS 'Configura automaticamente triggers de validação para todas as colunas JSONB';

-- =====================================================
-- FUNÇÃO: add_json_validation_param
-- =====================================================
-- Descrição: Adiciona um parâmetro de validação JSONB
-- Parâmetros: nome da tabela, valor do parâmetro
-- Retorna: param_id do parâmetro criado

CREATE OR REPLACE FUNCTION aux.add_json_validation_param(
    p_table_name text,
    p_param_value text
)
RETURNS uuid
LANGUAGE plpgsql
AS $$
DECLARE
    v_param_id uuid;
BEGIN
    -- Validações
    IF p_table_name IS NULL OR p_table_name = '' THEN
        RAISE EXCEPTION 'Nome da tabela é obrigatório';
    END IF;
    
    IF p_param_value IS NULL OR p_param_value = '' THEN
        RAISE EXCEPTION 'Valor do parâmetro é obrigatório';
    END IF;
    
    -- Insere o parâmetro
    INSERT INTO aux.json_validation_params (param_name, param_value) 
    VALUES (p_table_name, p_param_value)
    ON CONFLICT (param_name, param_value) DO NOTHING
    RETURNING param_id INTO v_param_id;
    
    -- Se não retornou ID, significa que já existia
    IF v_param_id IS NULL THEN
        SELECT param_id INTO v_param_id
        FROM aux.json_validation_params
        WHERE param_name = p_table_name AND param_value = p_param_value;
    END IF;
    
    RAISE NOTICE 'Parâmetro de validação adicionado: %.%', p_table_name, p_param_value;
    
    RETURN v_param_id;
END;
$$;

COMMENT ON FUNCTION aux.add_json_validation_param IS 'Adiciona um parâmetro de validação JSONB';

-- =====================================================
-- FUNÇÃO: remove_json_validation_param
-- =====================================================
-- Descrição: Remove um parâmetro de validação JSONB
-- Parâmetros: nome da tabela, valor do parâmetro
-- Retorna: void

CREATE OR REPLACE FUNCTION aux.remove_json_validation_param(
    p_table_name text,
    p_param_value text
)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    v_deleted_count integer;
BEGIN
    -- Validações
    IF p_table_name IS NULL OR p_table_name = '' THEN
        RAISE EXCEPTION 'Nome da tabela é obrigatório';
    END IF;
    
    IF p_param_value IS NULL OR p_param_value = '' THEN
        RAISE EXCEPTION 'Valor do parâmetro é obrigatório';
    END IF;
    
    -- Remove o parâmetro
    DELETE FROM aux.json_validation_params 
    WHERE param_name = p_table_name AND param_value = p_param_value;
    
    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
    
    IF v_deleted_count > 0 THEN
        RAISE NOTICE 'Parâmetro de validação removido: %.%', p_table_name, p_param_value;
    ELSE
        RAISE NOTICE 'Parâmetro de validação não encontrado: %.%', p_table_name, p_param_value;
    END IF;
END;
$$;

COMMENT ON FUNCTION aux.remove_json_validation_param IS 'Remove um parâmetro de validação JSONB';

-- =====================================================
-- FUNÇÃO: list_json_validation_params
-- =====================================================
-- Descrição: Lista todos os parâmetros de validação JSONB
-- Parâmetros: filtro opcional por nome da tabela
-- Retorna: tabela com parâmetros

CREATE OR REPLACE FUNCTION aux.list_json_validation_params(
    p_table_name text DEFAULT NULL
)
RETURNS TABLE(
    param_id uuid,
    param_name text,
    param_value text,
    created_at timestamp without time zone
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_table_name IS NULL THEN
        -- Retorna todos os parâmetros
        RETURN QUERY
        SELECT 
            jvp.param_id,
            jvp.param_name,
            jvp.param_value,
            jvp.created_at
        FROM aux.json_validation_params jvp
        ORDER BY jvp.param_name, jvp.param_value;
    ELSE
        -- Retorna parâmetros filtrados por tabela
        RETURN QUERY
        SELECT 
            jvp.param_id,
            jvp.param_name,
            jvp.param_value,
            jvp.created_at
        FROM aux.json_validation_params jvp
        WHERE jvp.param_name = p_table_name
        ORDER BY jvp.param_value;
    END IF;
END;
$$;

COMMENT ON FUNCTION aux.list_json_validation_params IS 'Lista parâmetros de validação JSONB';

-- =====================================================
-- DADOS INICIAIS
-- =====================================================

-- Inserir parâmetros padrão para o schema subscriptions
INSERT INTO aux.json_validation_params (param_name, param_value) VALUES
('subscriptions.plans', 'usage_limits.quotations'),
('subscriptions.plans', 'usage_limits.suppliers'),
('subscriptions.plans', 'usage_limits.items')
ON CONFLICT (param_name, param_value) DO NOTHING;

-- =====================================================
-- MENSAGEM DE CONCLUSÃO
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '=====================================================';
    RAISE NOTICE 'SISTEMA DE VALIDAÇÃO JSONB IMPLEMENTADO!';
    RAISE NOTICE '=====================================================';
    RAISE NOTICE '';
    RAISE NOTICE 'Funcionalidades criadas:';
    RAISE NOTICE '- Tabela aux.json_validation_params';
    RAISE NOTICE '- Função aux.validate_json_field()';
    RAISE NOTICE '- Função aux.create_json_validation_trigger()';
    RAISE NOTICE '- Função aux.setup_json_validation_triggers()';
    RAISE NOTICE '- Função aux.add_json_validation_param()';
    RAISE NOTICE '- Função aux.remove_json_validation_param()';
    RAISE NOTICE '- Função aux.list_json_validation_params()';
    RAISE NOTICE '';
    RAISE NOTICE 'Parâmetros padrão configurados para subscriptions.plans';
    RAISE NOTICE 'Sistema pronto para validação automática de campos JSONB!';
    RAISE NOTICE '=====================================================';
END $$;
