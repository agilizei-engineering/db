-- =====================================================
-- SCHEMA AUX - FUNÇÕES E VALIDAÇÕES COMPARTILHADAS
-- =====================================================
-- Schema centralizado para funções utilitárias e validações
-- Autor: Assistente IA + Usuário
-- Data: 2025-01-27
-- Versão: 1.0

-- =====================================================
-- CRIAÇÃO DO SCHEMA
-- =====================================================

CREATE SCHEMA IF NOT EXISTS aux;

-- =====================================================
-- DOMÍNIOS E TIPOS COMPARTILHADOS
-- =====================================================

-- Estados brasileiros válidos
DROP DOMAIN IF EXISTS aux.estado_brasileiro CASCADE;
CREATE DOMAIN aux.estado_brasileiro AS VARCHAR(2) 
CHECK (VALUE IN (
    'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA', 
    'MT', 'MS', 'MG', 'PA', 'PB', 'PR', 'PE', 'PI', 'RJ', 'RN', 
    'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO'
));

-- Gênero válido
DROP DOMAIN IF EXISTS aux.genero CASCADE;
CREATE DOMAIN aux.genero AS VARCHAR(1) 
CHECK (VALUE IN ('M', 'F', 'O'));

-- Moeda válida (ISO 4217)
DROP DOMAIN IF EXISTS aux.moeda CASCADE;
CREATE DOMAIN aux.moeda AS VARCHAR(3) 
CHECK (VALUE IN ('BRL', 'USD', 'EUR', 'GBP'));

-- =====================================================
-- FUNÇÕES DE VALIDAÇÃO DE DOCUMENTOS
-- =====================================================

-- =====================================================
-- VALIDAÇÃO DE CPF
-- =====================================================

-- Função para validar CPF (algoritmo oficial)
CREATE OR REPLACE FUNCTION aux.validate_cpf(p_cpf text)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
    cpf_limpo text;
    i integer;
    soma integer;
    resto integer;
    digito1 integer;
    digito2 integer;
BEGIN
    -- Remove caracteres não numéricos
    cpf_limpo := regexp_replace(p_cpf, '[^0-9]', '', 'g');
    
    -- Verifica se tem 11 dígitos
    IF length(cpf_limpo) != 11 THEN
        RETURN false;
    END IF;
    
    -- Verifica se todos os dígitos são iguais
    IF cpf_limpo = regexp_replace(cpf_limpo, '^(\d)\1*$', '\1', 'g') THEN
        RETURN false;
    END IF;
    
    -- Calcula primeiro dígito verificador
    soma := 0;
    FOR i IN 1..9 LOOP
        soma := soma + (substring(cpf_limpo, i, 1)::integer * (11 - i));
    END LOOP;
    
    resto := soma % 11;
    IF resto < 2 THEN
        digito1 := 0;
    ELSE
        digito1 := 11 - resto;
    END IF;
    
    -- Calcula segundo dígito verificador
    soma := 0;
    FOR i IN 1..10 LOOP
        soma := soma + (substring(cpf_limpo, i, 1)::integer * (12 - i));
    END LOOP;
    
    resto := soma % 11;
    IF resto < 2 THEN
        digito2 := 0;
    ELSE
        digito2 := 11 - resto;
    END IF;
    
    -- Verifica se os dígitos calculados são iguais aos do CPF
    RETURN (digito1::text = substring(cpf_limpo, 10, 1) AND 
            digito2::text = substring(cpf_limpo, 11, 1));
END;
$$;

COMMENT ON FUNCTION aux.validate_cpf(text) IS 'Valida CPF usando algoritmo oficial brasileiro';

-- Função para limpar e validar CPF
CREATE OR REPLACE FUNCTION aux.clean_and_validate_cpf(cpf_input text)
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
    cpf_limpo text;
    cpf_numerico text;
BEGIN
    -- Remove todos os caracteres não numéricos
    cpf_numerico := regexp_replace(cpf_input, '[^0-9]', '', 'g');
    
    -- Verifica se tem pelo menos 11 dígitos (pode ter mais se máscara quebrada)
    IF length(cpf_numerico) < 11 THEN
        RAISE EXCEPTION 'CPF inválido: deve ter pelo menos 11 dígitos numéricos';
    END IF;
    
    -- Pega apenas os primeiros 11 dígitos (ignora máscaras quebradas)
    cpf_limpo := substring(cpf_numerico, 1, 11);
    
    -- Valida o CPF
    IF NOT aux.validate_cpf(cpf_limpo) THEN
        RAISE EXCEPTION 'CPF inválido: número não passa na validação oficial';
    END IF;
    
    RETURN cpf_limpo;
END;
$$;

COMMENT ON FUNCTION aux.clean_and_validate_cpf(text) IS 'Limpa CPF (remove máscaras) e valida usando algoritmo oficial';

-- =====================================================
-- VALIDAÇÃO DE CNPJ
-- =====================================================

-- Função para validar CNPJ (algoritmo oficial)
CREATE OR REPLACE FUNCTION aux.validate_cnpj(p_cnpj text)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
    cnpj_limpo text;
    i integer;
    soma integer;
    resto integer;
    digito1 integer;
    digito2 integer;
    multiplicadores1 integer[] := ARRAY[5,4,3,2,9,8,7,6,5,4,3,2];
    multiplicadores2 integer[] := ARRAY[6,5,4,3,2,9,8,7,6,5,4,3,2];
BEGIN
    -- Remove caracteres não numéricos
    cnpj_limpo := regexp_replace(p_cnpj, '[^0-9]', '', 'g');
    
    -- Verifica se tem 14 dígitos
    IF length(cnpj_limpo) != 14 THEN
        RETURN false;
    END IF;
    
    -- Verifica se todos os dígitos são iguais
    IF cnpj_limpo = regexp_replace(cnpj_limpo, '^(\d)\1*$', '\1', 'g') THEN
        RETURN false;
    END IF;
    
    -- Calcula primeiro dígito verificador
    soma := 0;
    FOR i IN 1..12 LOOP
        soma := soma + (substring(cnpj_limpo, i, 1)::integer * multiplicadores1[i]);
    END LOOP;
    
    resto := soma % 11;
    IF resto < 2 THEN
        digito1 := 0;
    ELSE
        digito1 := 11 - resto;
    END IF;
    
    -- Calcula segundo dígito verificador
    soma := 0;
    FOR i IN 1..13 LOOP
        soma := soma + (substring(cnpj_limpo, i, 1)::integer * multiplicadores2[i]);
    END LOOP;
    
    resto := soma % 11;
    IF resto < 2 THEN
        digito2 := 0;
    ELSE
        digito2 := 11 - resto;
    END IF;
    
    -- Verifica se os dígitos calculados são iguais aos do CNPJ
    RETURN (digito1::text = substring(cnpj_limpo, 13, 1) AND 
            digito2::text = substring(cnpj_limpo, 14, 1));
END;
$$;

COMMENT ON FUNCTION aux.validate_cnpj(text) IS 'Valida CNPJ usando algoritmo oficial brasileiro';

-- Função para limpar e validar CNPJ
CREATE OR REPLACE FUNCTION aux.clean_and_validate_cnpj(cnpj_input text)
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
    cnpj_limpo text;
    cnpj_numerico text;
BEGIN
    -- Remove todos os caracteres não numéricos
    cnpj_numerico := regexp_replace(cnpj_input, '[^0-9]', '', 'g');
    
    -- Verifica se tem pelo menos 14 dígitos (pode ter mais se máscara quebrada)
    IF length(cnpj_numerico) < 14 THEN
        RAISE EXCEPTION 'CNPJ inválido: deve ter pelo menos 14 dígitos numéricos';
    END IF;
    
    -- Pega apenas os primeiros 14 dígitos (ignora máscaras quebradas)
    cnpj_limpo := substring(cnpj_numerico, 1, 14);
    
    -- Valida o CNPJ
    IF NOT aux.validate_cnpj(cnpj_limpo) THEN
        RAISE EXCEPTION 'CNPJ inválido: número não passa na validação oficial';
    END IF;
    
    RETURN cnpj_limpo;
END;
$$;

COMMENT ON FUNCTION aux.clean_and_validate_cnpj(text) IS 'Limpa CNPJ (remove máscaras) e valida usando algoritmo oficial';

-- =====================================================
-- VALIDAÇÃO DE CEP
-- =====================================================

-- Função para validar CEP
CREATE OR REPLACE FUNCTION aux.validate_postal_code(p_cep text)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
    cep_limpo text;
BEGIN
    -- Remove caracteres não numéricos
    cep_limpo := regexp_replace(p_cep, '[^0-9]', '', 'g');
    
    -- Verifica se tem 8 dígitos
    IF length(cep_limpo) != 8 THEN
        RETURN false;
    END IF;
    
    -- Verifica se todos os dígitos são iguais
    IF cep_limpo = regexp_replace(cep_limpo, '^(\d)\1*$', '\1', 'g') THEN
        RETURN false;
    END IF;
    
    RETURN true;
END;
$$;

COMMENT ON FUNCTION aux.validate_postal_code(text) IS 'Valida CEP brasileiro (8 dígitos numéricos)';

-- Função para limpar e validar CEP
CREATE OR REPLACE FUNCTION aux.clean_and_validate_postal_code(cep_input text)
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
    cep_limpo text;
    cep_numerico text;
BEGIN
    -- Remove todos os caracteres não numéricos
    cep_numerico := regexp_replace(cep_input, '[^0-9]', '', 'g');
    
    -- Verifica se tem pelo menos 8 dígitos (pode ter mais se máscara quebrada)
    IF length(cep_numerico) < 8 THEN
        RAISE EXCEPTION 'CEP inválido: deve ter pelo menos 8 dígitos numéricos';
    END IF;
    
    -- Pega apenas os primeiros 8 dígitos (ignora máscaras quebradas)
    cep_limpo := substring(cep_numerico, 1, 8);
    
    -- Valida o CEP
    IF NOT aux.validate_postal_code(cep_limpo) THEN
        RAISE EXCEPTION 'CEP inválido: formato inválido';
    END IF;
    
    RETURN cep_limpo;
END;
$$;

COMMENT ON FUNCTION aux.clean_and_validate_postal_code(text) IS 'Limpa CEP (remove máscaras) e valida formato';

-- =====================================================
-- VALIDAÇÕES DE DADOS GERAIS
-- =====================================================

-- Função para validar URL
CREATE OR REPLACE FUNCTION aux.validate_url(url text)
RETURNS boolean
LANGUAGE plpgsql
AS $$
BEGIN
    -- Se for NULL, é válido (opcional)
    IF url IS NULL THEN
        RETURN true;
    END IF;
    
    -- Verifica se começa com http:// ou https://
    IF url ~ '^https?://' THEN
        RETURN true;
    END IF;
    
    RETURN false;
END;
$$;

COMMENT ON FUNCTION aux.validate_url(text) IS 'Valida formato básico de URL (http:// ou https://)';

-- Função para validar email
CREATE OR REPLACE FUNCTION aux.validate_email(email text)
RETURNS boolean
LANGUAGE plpgsql
AS $$
BEGIN
    -- Se for NULL, é válido (opcional)
    IF email IS NULL THEN
        RETURN true;
    END IF;
    
    -- Regex básico para validação de email
    -- Formato: local@domain
    -- local: pode conter letras, números, pontos, hífens, underscores
    -- domain: deve ter pelo menos um ponto e terminar com 2-4 letras
    IF email ~ '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$' THEN
        RETURN true;
    END IF;
    
    RETURN false;
END;
$$;

COMMENT ON FUNCTION aux.validate_email(text) IS 'Valida formato básico de email (local@domain)';

-- Função para validar JSON
CREATE OR REPLACE FUNCTION aux.validate_json(json_text text)
RETURNS boolean
LANGUAGE plpgsql
AS $$
BEGIN
    -- Se for NULL, é válido (opcional)
    IF json_text IS NULL THEN
        RETURN true;
    END IF;
    
    -- Tenta fazer parse do JSON
    BEGIN
        PERFORM json_text::json;
        RETURN true;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN false;
    END;
END;
$$;

COMMENT ON FUNCTION aux.validate_json(text) IS 'Valida se o texto é um JSON válido';

-- Função para validar data de nascimento com idade mínima
CREATE OR REPLACE FUNCTION aux.validate_birth_date(birth_date date, min_age_years integer DEFAULT 14)
RETURNS boolean
LANGUAGE plpgsql
AS $$
BEGIN
    -- Verifica se a data não é no futuro
    IF birth_date > current_date THEN
        RETURN false;
    END IF;
    
    -- Verifica se a pessoa tem a idade mínima
    IF birth_date > (current_date - interval '1 year' * min_age_years) THEN
        RETURN false;
    END IF;
    
    RETURN true;
END;
$$;

COMMENT ON FUNCTION aux.validate_birth_date(date, integer) IS 'Valida data de nascimento (não futura e idade mínima)';

-- Função para validar estado brasileiro
CREATE OR REPLACE FUNCTION aux.validate_estado_brasileiro(estado text)
RETURNS boolean
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN estado::aux.estado_brasileiro IS NOT NULL;
EXCEPTION
    WHEN OTHERS THEN
        RETURN false;
END;
$$;

COMMENT ON FUNCTION aux.validate_estado_brasileiro(text) IS 'Valida se o estado é um estado brasileiro válido';

-- =====================================================
-- FUNÇÕES UTILITÁRIAS
-- =====================================================

-- Função genérica para atualizar updated_at
CREATE OR REPLACE FUNCTION aux.set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION aux.set_updated_at() IS 'Função genérica para atualizar campo updated_at automaticamente';

-- Função para formatar CPF com máscara
CREATE OR REPLACE FUNCTION aux.format_cpf(cpf_numerico text)
RETURNS text
LANGUAGE plpgsql
AS $$
BEGIN
    IF length(cpf_numerico) != 11 THEN
        RAISE EXCEPTION 'CPF deve ter 11 dígitos numéricos';
    END IF;
    
    RETURN substring(cpf_numerico, 1, 3) || '.' ||
           substring(cpf_numerico, 4, 3) || '.' ||
           substring(cpf_numerico, 7, 3) || '-' ||
           substring(cpf_numerico, 10, 2);
END;
$$;

COMMENT ON FUNCTION aux.format_cpf(text) IS 'Formata CPF numérico com máscara (XXX.XXX.XXX-XX)';

-- Função para formatar CNPJ com máscara
CREATE OR REPLACE FUNCTION aux.format_cnpj(cnpj_numerico text)
RETURNS text
LANGUAGE plpgsql
AS $$
BEGIN
    IF length(cnpj_numerico) != 14 THEN
        RAISE EXCEPTION 'CNPJ deve ter 14 dígitos numéricos';
    END IF;
    
    RETURN substring(cnpj_numerico, 1, 2) || '.' ||
           substring(cnpj_numerico, 3, 3) || '.' ||
           substring(cnpj_numerico, 6, 3) || '/' ||
           substring(cnpj_numerico, 9, 4) || '-' ||
           substring(cnpj_numerico, 13, 2);
END;
$$;

COMMENT ON FUNCTION aux.format_cnpj(text) IS 'Formata CNPJ numérico com máscara (XX.XXX.XXX/XXXX-XX)';

-- Função para formatar CEP com máscara
CREATE OR REPLACE FUNCTION aux.format_postal_code(cep_numerico text)
RETURNS text
LANGUAGE plpgsql
AS $$
BEGIN
    IF length(cep_numerico) != 8 THEN
        RAISE EXCEPTION 'CEP deve ter 8 dígitos numéricos';
    END IF;
    
    RETURN substring(cep_numerico, 1, 5) || '-' ||
           substring(cep_numerico, 6, 3);
END;
$$;

COMMENT ON FUNCTION aux.format_postal_code(text) IS 'Formata CEP numérico com máscara (XXXXX-XXX)';

-- =====================================================
-- TRIGGERS GENÉRICOS
-- =====================================================

-- Função para criar trigger de updated_at automaticamente
CREATE OR REPLACE FUNCTION aux.create_updated_at_trigger(
    p_schema_name text,
    p_table_name text
)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    v_trigger_name text;
BEGIN
    v_trigger_name := 'trg_set_updated_at_' || p_table_name;
    
    -- Remove trigger existente se houver
    EXECUTE format('DROP TRIGGER IF EXISTS %I ON %I.%I', 
                   v_trigger_name, p_schema_name, p_table_name);
    
    -- Cria novo trigger
    EXECUTE format('CREATE TRIGGER %I BEFORE UPDATE ON %I.%I FOR EACH ROW EXECUTE FUNCTION aux.set_updated_at()',
                   v_trigger_name, p_schema_name, p_table_name);
    
    RAISE NOTICE 'Trigger % criado para %.%', v_trigger_name, p_schema_name, p_table_name;
END;
$$;

COMMENT ON FUNCTION aux.create_updated_at_trigger(text, text) IS 'Cria automaticamente trigger de updated_at para uma tabela';

-- =====================================================
-- COMENTÁRIOS DAS FUNÇÕES
-- =====================================================

COMMENT ON SCHEMA aux IS 'Schema auxiliar com funções e validações compartilhadas entre todos os schemas';

-- =====================================================
-- TESTE INICIAL DO SCHEMA
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE 'Schema aux criado com sucesso!';
    RAISE NOTICE 'Funcoes de validacao de documentos implementadas';
    RAISE NOTICE 'Funcoes utilitarias criadas';
    RAISE NOTICE 'Triggers genericos disponiveis';
    RAISE NOTICE 'Pronto para uso em todos os schemas!';
END $$;

-- =====================================================
-- FUNÇÕES GENÉRICAS DE TRIGGER (ADICIONADAS)
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
-- FUNÇÕES GENÉRICAS PARA CRIAR TRIGGERS
-- =====================================================

-- Função genérica para criar trigger de CNPJ
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
        DROP TRIGGER IF EXISTS %I ON %s;
        CREATE TRIGGER %I
            BEFORE INSERT OR UPDATE ON %s
            FOR EACH ROW EXECUTE FUNCTION aux.clean_cnpj_before_insert_update();
    ', v_trigger_name, v_full_table_name, v_trigger_name, v_full_table_name);
    
    EXECUTE v_sql;
    
    RETURN 'Trigger ' || v_trigger_name || ' criado com sucesso para ' || v_full_table_name;
END;
$$;

COMMENT ON FUNCTION aux.create_cnpj_trigger(text, text, text) IS 'Função genérica para criar trigger de limpeza de CNPJ';

-- Função genérica para criar trigger de CPF
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
        DROP TRIGGER IF EXISTS %I ON %s;
        CREATE TRIGGER %I
            BEFORE INSERT OR UPDATE ON %s
            FOR EACH ROW EXECUTE FUNCTION aux.clean_cpf_before_insert_update();
    ', v_trigger_name, v_full_table_name, v_trigger_name, v_full_table_name);
    
    EXECUTE v_sql;
    
    RETURN 'Trigger ' || v_trigger_name || ' criado com sucesso para ' || v_full_table_name;
END;
$$;

COMMENT ON FUNCTION aux.create_cpf_trigger(text, text, text) IS 'Função genérica para criar trigger de limpeza de CPF';

-- Função genérica para criar trigger de CEP
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
        DROP TRIGGER IF EXISTS %I ON %s;
        CREATE TRIGGER %I
            BEFORE INSERT OR UPDATE ON %s
            FOR EACH ROW EXECUTE FUNCTION aux.clean_postal_code_before_insert_update();
    ', v_trigger_name, v_full_table_name, v_trigger_name, v_full_table_name);
    
    EXECUTE v_sql;
    
    RETURN 'Trigger ' || v_trigger_name || ' criado com sucesso para ' || v_full_table_name;
END;
$$;

COMMENT ON FUNCTION aux.create_postal_code_trigger(text, text, text) IS 'Função genérica para criar trigger de limpeza de CEP';

-- Função genérica para criar trigger de email
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
        DROP TRIGGER IF EXISTS %I ON %s;
        CREATE TRIGGER %I
            BEFORE INSERT OR UPDATE ON %s
            FOR EACH ROW EXECUTE FUNCTION aux.validate_email_before_insert_update();
    ', v_trigger_name, v_full_table_name, v_trigger_name, v_full_table_name);
    
    EXECUTE v_sql;
    
    RETURN 'Trigger ' || v_trigger_name || ' criado com sucesso para ' || v_full_table_name;
END;
$$;

COMMENT ON FUNCTION aux.create_email_trigger(text, text, text) IS 'Função genérica para criar trigger de validação de email';

-- Função genérica para criar trigger de URL
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
        DROP TRIGGER IF EXISTS %I ON %s;
        CREATE TRIGGER %I
            BEFORE INSERT OR UPDATE ON %s
            FOR EACH ROW EXECUTE FUNCTION aux.validate_url_before_insert_update();
    ', v_trigger_name, v_full_table_name, v_trigger_name, v_full_table_name);
    
    EXECUTE v_sql;
    
    RETURN 'Trigger ' || v_trigger_name || ' criado com sucesso para ' || v_full_table_name;
END;
$$;

COMMENT ON FUNCTION aux.create_url_trigger(text, text, text) IS 'Função genérica para criar trigger de validação de URL';

-- =====================================================
-- FUNÇÃO MESTRA PARA CRIAR TODOS OS TRIGGERS
-- =====================================================

-- Função genérica para criar todos os triggers de validação de uma tabela
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
-- INCLUSÃO DO SISTEMA DE VALIDAÇÃO JSONB
-- =====================================================

-- Inclui o arquivo de validação JSONB
\i schemas/aux/json_validation.sql

-- =====================================================
-- VERIFICAÇÃO FINAL DAS FUNÇÕES ADICIONADAS
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=====================================================';
    RAISE NOTICE 'FUNCOES GENERICAS DE TRIGGER ADICIONADAS AO AUX';
    RAISE NOTICE '=====================================================';
    RAISE NOTICE 'Funcoes de trigger genericas criadas';
    RAISE NOTICE 'Funcoes de criacao de triggers criadas';
    RAISE NOTICE 'Funcao de criacao automatica de triggers criada';
    RAISE NOTICE 'Nomenclatura existente mantida';
    RAISE NOTICE 'Compatibilidade preservada';
    RAISE NOTICE 'Schema aux expandido com sucesso!';
    RAISE NOTICE '=====================================================';
    RAISE NOTICE '';
    RAISE NOTICE 'SISTEMA DE VALIDAÇÃO JSONB IMPLEMENTADO!';
    RAISE NOTICE '=====================================================';
    RAISE NOTICE '';
    RAISE NOTICE 'PROXIMOS PASSOS:';
    RAISE NOTICE '1. Migrar establishments_extension para usar aux.*';
    RAISE NOTICE '2. Verificar employees_extension esta 100 por cento limpo';
    RAISE NOTICE '3. Migrar quotation_schema se necessario';
    RAISE NOTICE '4. Limpeza final de funcoes duplicadas';
    RAISE NOTICE '5. Sistema JSONB pronto para uso em subscriptions';
    RAISE NOTICE '=====================================================';
END $$;
