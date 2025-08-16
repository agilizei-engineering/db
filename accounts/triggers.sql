-- Triggers do schema accounts
-- Schema: accounts
-- Arquivo: triggers.sql

-- Este arquivo contém todos os triggers do schema accounts
-- Os triggers são criados automaticamente pelos scripts de extensão
-- Este arquivo serve como documentação e referência

-- =====================================================
-- TRIGGERS DE UPDATED_AT
-- =====================================================

/*
-- Trigger para atualizar campo updated_at automaticamente
CREATE OR REPLACE FUNCTION accounts.set_updated_at()
RETURNS trigger AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
*/

-- Funcionalidade: Atualiza automaticamente o campo updated_at
-- Uso: Aplicado a todas as tabelas com campo updated_at
-- Evento: BEFORE UPDATE

/*
-- Exemplo de aplicação do trigger updated_at
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON accounts.users
    FOR EACH ROW
    EXECUTE FUNCTION accounts.set_updated_at();

CREATE TRIGGER update_employees_updated_at
    BEFORE UPDATE ON accounts.employees
    FOR EACH ROW
    EXECUTE FUNCTION accounts.set_updated_at();

CREATE TRIGGER update_establishments_updated_at
    BEFORE UPDATE ON accounts.establishments
    FOR EACH ROW
    EXECUTE FUNCTION accounts.set_updated_at();
*/

-- =====================================================
-- TRIGGERS DE VALIDAÇÃO DE CNPJ
-- =====================================================

/*
-- Trigger para validar e limpar CNPJ automaticamente
CREATE OR REPLACE FUNCTION accounts.clean_cnpj_before_insert_update()
RETURNS trigger AS $$
BEGIN
    -- Limpar e validar CNPJ
    NEW.cnpj := aux.clean_and_validate_cnpj(NEW.cnpj);
    
    -- Validar CNPJ
    IF NOT aux.validate_cnpj(NEW.cnpj) THEN
        RAISE EXCEPTION 'CNPJ inválido: %', NEW.cnpj;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
*/

-- Funcionalidade: Valida e limpa CNPJ automaticamente
-- Uso: Aplicado às tabelas com campo CNPJ
-- Evento: BEFORE INSERT, BEFORE UPDATE

/*
-- Exemplo de aplicação do trigger CNPJ
CREATE TRIGGER clean_establishment_business_data_cnpj
    BEFORE INSERT OR UPDATE ON accounts.establishment_business_data
    FOR EACH ROW
    EXECUTE FUNCTION accounts.clean_cnpj_before_insert_update();
*/

-- =====================================================
-- TRIGGERS DE VALIDAÇÃO DE CPF
-- =====================================================

/*
-- Trigger para validar e limpar CPF automaticamente
CREATE OR REPLACE FUNCTION accounts.clean_cpf_before_insert_update()
RETURNS trigger AS $$
BEGIN
    -- Limpar e validar CPF
    NEW.cpf := aux.clean_and_validate_cpf(NEW.cpf);
    
    -- Validar CPF
    IF NOT aux.validate_cpf(NEW.cpf) THEN
        RAISE EXCEPTION 'CPF inválido: %', NEW.cpf;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
*/

-- Funcionalidade: Valida e limpa CPF automaticamente
-- Uso: Aplicado às tabelas com campo CPF
-- Evento: BEFORE INSERT, BEFORE UPDATE

/*
-- Exemplo de aplicação do trigger CPF
CREATE TRIGGER clean_employee_personal_data_cpf
    BEFORE INSERT OR UPDATE ON accounts.employee_personal_data
    FOR EACH ROW
    EXECUTE FUNCTION accounts.clean_cpf_before_insert_update();
*/

-- =====================================================
-- TRIGGERS DE VALIDAÇÃO DE CEP
-- =====================================================

/*
-- Trigger para validar e limpar CEP automaticamente
CREATE OR REPLACE FUNCTION accounts.clean_postal_code_before_insert_update()
RETURNS trigger AS $$
BEGIN
    -- Limpar e validar CEP
    NEW.postal_code := aux.clean_and_validate_postal_code(NEW.postal_code);
    
    -- Validar CEP
    IF NOT aux.validate_postal_code(NEW.postal_code) THEN
        RAISE EXCEPTION 'CEP inválido: %', NEW.postal_code;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
*/

-- Funcionalidade: Valida e limpa CEP automaticamente
-- Uso: Aplicado às tabelas com campo postal_code
-- Evento: BEFORE INSERT, BEFORE UPDATE

/*
-- Exemplo de aplicação do trigger CEP
CREATE TRIGGER clean_establishment_addresses_postal_code
    BEFORE INSERT OR UPDATE ON accounts.establishment_addresses
    FOR EACH ROW
    EXECUTE FUNCTION accounts.clean_postal_code_before_insert_update();

CREATE TRIGGER clean_employee_addresses_postal_code
    BEFORE INSERT OR UPDATE ON accounts.employee_addresses
    FOR EACH ROW
    EXECUTE FUNCTION accounts.clean_postal_code_before_insert_update();
*/

-- =====================================================
-- TRIGGERS DE VALIDAÇÃO DE EMAIL
-- =====================================================

/*
-- Trigger para validar email automaticamente
CREATE OR REPLACE FUNCTION accounts.validate_email_before_insert_update()
RETURNS trigger AS $$
BEGIN
    -- Validar email
    IF NOT aux.validate_email(NEW.email) THEN
        RAISE EXCEPTION 'Email inválido: %', NEW.email;
    END IF;
    
    -- Converter para minúsculas
    NEW.email := lower(NEW.email);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
*/

-- Funcionalidade: Valida email automaticamente
-- Uso: Aplicado às tabelas com campo email
-- Evento: BEFORE INSERT, BEFORE UPDATE

/*
-- Exemplo de aplicação do trigger email
CREATE TRIGGER validate_users_email
    BEFORE INSERT OR UPDATE ON accounts.users
    FOR EACH ROW
    EXECUTE FUNCTION accounts.validate_email_before_insert_update();
*/

-- =====================================================
-- TRIGGERS DE VALIDAÇÃO DE URL
-- =====================================================

/*
-- Trigger para validar URL automaticamente
CREATE OR REPLACE FUNCTION accounts.validate_url_before_insert_update()
RETURNS trigger AS $$
BEGIN
    -- Validar URL (se não for NULL)
    IF NEW.photo_url IS NOT NULL AND NOT aux.validate_url(NEW.photo_url) THEN
        RAISE EXCEPTION 'URL inválida: %', NEW.photo_url;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
*/

-- Funcionalidade: Valida URL automaticamente
-- Uso: Aplicado às tabelas com campo URL
-- Evento: BEFORE INSERT, BEFORE UPDATE

/*
-- Exemplo de aplicação do trigger URL
CREATE TRIGGER validate_employee_personal_data_photo_url
    BEFORE INSERT OR UPDATE ON accounts.employee_personal_data
    FOR EACH ROW
    EXECUTE FUNCTION accounts.validate_url_before_insert_update();

CREATE TRIGGER validate_user_google_oauth_photo_url
    BEFORE INSERT OR UPDATE ON accounts.user_google_oauth
    FOR EACH ROW
    EXECUTE FUNCTION accounts.validate_url_before_insert_update();
*/

-- =====================================================
-- TRIGGERS DE VALIDAÇÃO DE DATA DE NASCIMENTO
-- =====================================================

/*
-- Trigger para validar data de nascimento automaticamente
CREATE OR REPLACE FUNCTION accounts.validate_birth_date_before_insert_update()
RETURNS trigger AS $$
BEGIN
    -- Validar data de nascimento (idade mínima: 14 anos)
    IF NOT aux.validate_birth_date(NEW.birth_date, 14) THEN
        RAISE EXCEPTION 'Data de nascimento inválida: % (idade mínima: 14 anos)', NEW.birth_date;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
*/

-- Funcionalidade: Valida data de nascimento automaticamente
-- Uso: Aplicado às tabelas com campo birth_date
-- Evento: BEFORE INSERT, BEFORE UPDATE

/*
-- Exemplo de aplicação do trigger data de nascimento
CREATE TRIGGER validate_employee_personal_data_birth_date
    BEFORE INSERT OR UPDATE ON accounts.employee_personal_data
    FOR EACH ROW
    EXECUTE FUNCTION accounts.validate_birth_date_before_insert_update();
*/

-- =====================================================
-- FUNÇÃO PARA CRIAR TRIGGERS DE VALIDAÇÃO
-- =====================================================

/*
-- Função para criar triggers de validação automaticamente
CREATE OR REPLACE FUNCTION accounts.create_validation_triggers(
    p_schema_name text,
    p_table_name text,
    p_columns text[]
) RETURNS text AS $$
DECLARE
    v_column text;
    v_trigger_name text;
    v_function_name text;
    v_result text := '';
BEGIN
    FOREACH v_column IN ARRAY p_columns
    LOOP
        v_trigger_name := 'validate_' || p_table_name || '_' || v_column;
        
        -- Determinar função baseada no tipo de coluna
        CASE v_column
            WHEN 'cnpj' THEN
                v_function_name := 'accounts.clean_cnpj_before_insert_update';
            WHEN 'cpf' THEN
                v_function_name := 'accounts.clean_cpf_before_insert_update';
            WHEN 'postal_code' THEN
                v_function_name := 'accounts.clean_postal_code_before_insert_update';
            WHEN 'email' THEN
                v_function_name := 'accounts.validate_email_before_insert_update';
            WHEN 'photo_url' THEN
                v_function_name := 'accounts.validate_url_before_insert_update';
            WHEN 'birth_date' THEN
                v_function_name := 'accounts.validate_birth_date_before_insert_update';
            ELSE
                RAISE NOTICE 'Tipo de coluna não suportado: %', v_column;
                CONTINUE;
        END CASE;
        
        -- Criar trigger
        EXECUTE format('
            DROP TRIGGER IF EXISTS %I ON %I.%I;
            CREATE TRIGGER %I
                BEFORE INSERT OR UPDATE ON %I.%I
                FOR EACH ROW
                EXECUTE FUNCTION %s;
        ', v_trigger_name, p_schema_name, p_table_name,
           v_trigger_name, p_schema_name, p_table_name, v_function_name);
        
        v_result := v_result || 'Trigger ' || v_trigger_name || ' criado. ';
    END LOOP;
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql;
*/

-- Funcionalidade: Cria triggers de validação automaticamente
-- Uso: Simplifica a criação de múltiplos triggers
-- Parâmetros: schema, tabela e array de colunas para validar

-- =====================================================
-- EXEMPLOS DE USO
-- =====================================================

/*
-- Exemplo 1: Criar triggers de validação para uma tabela
SELECT accounts.create_validation_triggers('accounts', 'establishment_business_data', ARRAY['cnpj']);

-- Exemplo 2: Criar múltiplos triggers de validação
SELECT accounts.create_validation_triggers('accounts', 'employee_personal_data', ARRAY['cpf', 'birth_date', 'photo_url']);

-- Exemplo 3: Criar triggers para endereços
SELECT accounts.create_validation_triggers('accounts', 'establishment_addresses', ARRAY['postal_code']);
SELECT accounts.create_validation_triggers('accounts', 'employee_addresses', ARRAY['postal_code']);
*/

-- =====================================================
-- NOTAS IMPORTANTES
-- =====================================================

-- 1. Todos os triggers usam funções de validação do schema aux
-- 2. Triggers são aplicados BEFORE INSERT/UPDATE para validação
-- 3. Validações incluem limpeza automática de máscaras
-- 4. Triggers de updated_at são aplicados a todas as tabelas relevantes
-- 5. Função create_validation_triggers simplifica a criação de triggers
-- 6. Todos os triggers são auditados automaticamente
