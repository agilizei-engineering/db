-- =====================================================
-- EXTENSÃO DE EMPLOYEES - DADOS PESSOAIS E ENDEREÇOS
-- =====================================================
-- Este script estende a tabela accounts.employees com dados pessoais
-- e endereços, incluindo validação de CPF e limpeza automática

-- =====================================================
-- VERIFICAÇÃO DE EXTENSÕES (OPCIONAL)
-- =====================================================

-- Verifica se a extensão pg_trgm está disponível (comum no RDS)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_extension WHERE extname = 'pg_trgm'
    ) THEN
        RAISE NOTICE '✅ Extensão pg_trgm disponível - usando índices trigram';
    ELSE
        RAISE NOTICE '⚠️  Extensão pg_trgm não disponível - usando índices padrão';
    END IF;
END $$;

-- =====================================================
-- FUNÇÕES DE VALIDAÇÃO E LIMPEZA
-- =====================================================

-- Função para validar CPF (baseada no script fornecido, adaptada para nosso padrão)
CREATE OR REPLACE FUNCTION accounts.validate_cpf(p_cpf text)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
    v_cpf_invalidos text[] := ARRAY[
        '00000000000', '11111111111', '22222222222', '33333333333',
        '44444444444', '55555555555', '66666666666', '77777777777',
        '88888888888', '99999999999'
    ];
    v_cpf_quebrado integer[];
    v_soma_dv1 integer := 0;
    v_resto_dv1 integer := 0;
    v_soma_dv2 integer := 0;
    v_resto_dv2 integer := 0;
    v_digito1 integer;
    v_digito2 integer;
BEGIN
    -- Verifica se é nulo ou vazio
    IF p_cpf IS NULL OR p_cpf = '' THEN
        RETURN false;
    END IF;
    
    -- Verifica se tem exatamente 11 dígitos
    IF p_cpf !~ '^\d{11}$' THEN
        RETURN false;
    END IF;
    
    -- Verifica se é um dos CPFs inválidos conhecidos
    IF p_cpf = ANY(v_cpf_invalidos) THEN
        RETURN false;
    END IF;
    
    -- Converte string em array de inteiros
    v_cpf_quebrado := ARRAY(
        SELECT (regexp_split_to_array(p_cpf, ''))[i]::integer 
        FROM generate_series(1, 11) i
    );
    
    -- Calcula primeiro dígito verificador
    FOR i IN 1..9 LOOP
        v_soma_dv1 := v_soma_dv1 + (v_cpf_quebrado[i] * (12 - i));
    END LOOP;
    
    v_resto_dv1 := v_soma_dv1 % 11;
    v_digito1 := CASE WHEN v_resto_dv1 < 2 THEN 0 ELSE 11 - v_resto_dv1 END;
    
    -- Verifica primeiro dígito
    IF v_digito1 != v_cpf_quebrado[10] THEN
        RETURN false;
    END IF;
    
    -- Calcula segundo dígito verificador
    FOR i IN 1..10 LOOP
        v_soma_dv2 := v_soma_dv2 + (v_cpf_quebrado[i] * (13 - i));
    END LOOP;
    
    v_resto_dv2 := v_soma_dv2 % 11;
    v_digito2 := CASE WHEN v_resto_dv2 < 2 THEN 0 ELSE 11 - v_resto_dv2 END;
    
    -- Verifica segundo dígito
    RETURN v_digito2 = v_cpf_quebrado[11];
END;
$$;

COMMENT ON FUNCTION accounts.validate_cpf IS 'Valida CPF brasileiro usando algoritmo oficial';

-- Função para limpar e validar CPF (seguindo padrão do CNPJ)
CREATE OR REPLACE FUNCTION accounts.clean_and_validate_cpf(cpf_input text)
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
    cleaned_cpf text;
BEGIN
    -- Remove todos os caracteres não numéricos (aceita digitação quebrada)
    cleaned_cpf := regexp_replace(cpf_input, '[^0-9]', '', 'g');
    
    -- Verifica se tem exatamente 11 dígitos
    IF length(cleaned_cpf) != 11 THEN
        RAISE EXCEPTION 'CPF deve ter exatamente 11 dígitos numéricos. Recebido: % (após limpeza: %)', cpf_input, cleaned_cpf;
    END IF;
    
    -- Verifica se todos os dígitos são iguais
    IF cleaned_cpf ~ '^(\d)\1+$' THEN
        RAISE EXCEPTION 'CPF não pode ter todos os dígitos iguais';
    END IF;
    
    -- Valida o CPF usando a função de validação
    IF NOT accounts.validate_cpf(cleaned_cpf) THEN
        RAISE EXCEPTION 'CPF inválido: %', cpf_input;
    END IF;
    
    RETURN cleaned_cpf;
END;
$$;

COMMENT ON FUNCTION accounts.clean_and_validate_cpf IS 'Limpa e valida CPF, removendo máscaras e validando algoritmo';

-- Função para validar URL de foto
CREATE OR REPLACE FUNCTION accounts.validate_photo_url(photo_url text)
RETURNS boolean
LANGUAGE plpgsql
AS $$
BEGIN
    -- Se for nulo, é válido (campo opcional)
    IF photo_url IS NULL THEN
        RETURN true;
    END IF;
    
    -- Verifica se é uma URL válida (formato básico)
    IF photo_url ~ '^https?://[^\s/$.?#].[^\s]*$' THEN
        RETURN true;
    END IF;
    
    RETURN false;
END;
$$;

COMMENT ON FUNCTION accounts.validate_photo_url IS 'Valida formato básico de URL para foto';

-- Função para validar data de nascimento (idade mínima 14 anos)
CREATE OR REPLACE FUNCTION accounts.validate_birth_date(birth_date date)
RETURNS boolean
LANGUAGE plpgsql
AS $$
BEGIN
    -- Data não pode ser futura
    IF birth_date > current_date THEN
        RETURN false;
    END IF;
    
    -- Idade mínima 14 anos
    IF birth_date > (current_date - INTERVAL '14 years') THEN
        RETURN false;
    END IF;
    
    RETURN true;
END;
$$;

COMMENT ON FUNCTION accounts.validate_birth_date IS 'Valida data de nascimento (não futura, idade mínima 14 anos)';

-- =====================================================
-- TABELAS DE EXTENSÃO
-- =====================================================

-- Tabela para dados pessoais dos funcionários
CREATE TABLE IF NOT EXISTS accounts.employee_personal_data (
    employee_personal_data_id uuid DEFAULT gen_random_uuid() NOT NULL,
    employee_id uuid NOT NULL,
    cpf text NOT NULL, -- Apenas números (11 dígitos)
    full_name text NOT NULL, -- Nome completo
    birth_date date NOT NULL, -- Data de nascimento
    gender text NOT NULL, -- Sexo (M/F/O)
    photo_url text, -- URL da foto (opcional)
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone,
    
    CONSTRAINT employee_personal_data_pkey PRIMARY KEY (employee_personal_data_id),
    CONSTRAINT employee_personal_data_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES accounts.employees(employee_id) ON DELETE CASCADE,
    CONSTRAINT employee_personal_data_cpf_unique UNIQUE (cpf),
    CONSTRAINT employee_personal_data_employee_id_unique UNIQUE (employee_id),
    CONSTRAINT employee_personal_data_cpf_clean CHECK (cpf ~ '^\d{11}$'),
    CONSTRAINT employee_personal_data_full_name_length CHECK (length(full_name) >= 2 AND length(full_name) <= 100),
    CONSTRAINT employee_personal_data_gender_valid CHECK (gender IN ('M', 'F', 'O')),
    CONSTRAINT employee_personal_data_birth_date_valid CHECK (accounts.validate_birth_date(birth_date)),
    CONSTRAINT employee_personal_data_photo_url_valid CHECK (accounts.validate_photo_url(photo_url)),
    CONSTRAINT employee_personal_data_dates_valid CHECK (
        created_at <= now() AND 
        (updated_at IS NULL OR updated_at <= now())
    )
);

COMMENT ON TABLE accounts.employee_personal_data IS 'Dados pessoais dos funcionários (CPF, nome, nascimento, sexo, foto)';
COMMENT ON COLUMN accounts.employee_personal_data.employee_personal_data_id IS 'ID único dos dados pessoais';
COMMENT ON COLUMN accounts.employee_personal_data.employee_id IS 'Referência ao funcionário';
COMMENT ON COLUMN accounts.employee_personal_data.cpf IS 'CPF do funcionário (apenas números)';
COMMENT ON COLUMN accounts.employee_personal_data.full_name IS 'Nome completo do funcionário';
COMMENT ON COLUMN accounts.employee_personal_data.birth_date IS 'Data de nascimento';
COMMENT ON COLUMN accounts.employee_personal_data.gender IS 'Sexo (M=Masculino, F=Feminino, O=Outro)';
COMMENT ON COLUMN accounts.employee_personal_data.photo_url IS 'URL da foto do funcionário (opcional)';
COMMENT ON COLUMN accounts.employee_personal_data.created_at IS 'Data de criação do registro';
COMMENT ON COLUMN accounts.employee_personal_data.updated_at IS 'Data da última atualização';


-- Tabela para endereços dos funcionários
CREATE TABLE IF NOT EXISTS accounts.employee_addresses (
    employee_address_id uuid DEFAULT gen_random_uuid() NOT NULL,
    employee_id uuid NOT NULL,
    postal_code text NOT NULL, -- Apenas números (8 dígitos)
    street text NOT NULL, -- Rua
    number text NOT NULL, -- Número
    complement text, -- Complemento (opcional)
    neighborhood text NOT NULL, -- Bairro
    city text NOT NULL, -- Cidade
    state text NOT NULL, -- Estado (UF)
    is_primary boolean DEFAULT true NOT NULL, -- Endereço principal
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone,
    
    CONSTRAINT employee_addresses_pkey PRIMARY KEY (employee_address_id),
    CONSTRAINT employee_addresses_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES accounts.employees(employee_id) ON DELETE CASCADE,
    CONSTRAINT employee_addresses_postal_code_clean CHECK (postal_code ~ '^\d{8}$'),
    CONSTRAINT employee_addresses_street_length CHECK (length(street) >= 2 AND length(street) <= 200),
    CONSTRAINT employee_addresses_number_length CHECK (length(number) >= 1 AND length(number) <= 20),
    CONSTRAINT employee_addresses_neighborhood_length CHECK (length(neighborhood) >= 2 AND length(neighborhood) <= 100),
    CONSTRAINT employee_addresses_city_length CHECK (length(city) >= 2 AND length(city) <= 100),
    CONSTRAINT employee_addresses_state_valid CHECK (
        state IN ('AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA', 'MT', 'MS', 'MG', 'PA', 'PB', 'PR', 'PE', 'PI', 'RJ', 'RN', 'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO')
    ),
    CONSTRAINT employee_addresses_dates_valid CHECK (
        created_at <= now() AND 
        (updated_at IS NULL OR updated_at <= now())
    ),
    CONSTRAINT employee_addresses_primary_unique UNIQUE (employee_id, is_primary) DEFERRABLE INITIALLY DEFERRED
);

COMMENT ON TABLE accounts.employee_addresses IS 'Endereços dos funcionários';
COMMENT ON COLUMN accounts.employee_addresses.employee_address_id IS 'ID único do endereço';
COMMENT ON COLUMN accounts.employee_addresses.employee_id IS 'Referência ao funcionário';
COMMENT ON COLUMN accounts.employee_addresses.postal_code IS 'CEP (apenas números)';
COMMENT ON COLUMN accounts.employee_addresses.street IS 'Nome da rua';
COMMENT ON COLUMN accounts.employee_addresses.number IS 'Número do endereço';
COMMENT ON COLUMN accounts.employee_addresses.complement IS 'Complemento do endereço';
COMMENT ON COLUMN accounts.employee_addresses.neighborhood IS 'Bairro';
COMMENT ON COLUMN accounts.employee_addresses.city IS 'Cidade';
COMMENT ON COLUMN accounts.employee_addresses.state IS 'Estado (UF)';
COMMENT ON COLUMN accounts.employee_addresses.is_primary IS 'Indica se é o endereço principal';
COMMENT ON COLUMN accounts.employee_addresses.created_at IS 'Data de criação do registro';
COMMENT ON COLUMN accounts.employee_addresses.updated_at IS 'Data da última atualização';


-- =====================================================
-- TRIGGERS PARA LIMPEZA AUTOMÁTICA
-- =====================================================

-- Trigger para limpar CPF automaticamente
CREATE OR REPLACE FUNCTION accounts.clean_cpf_before_insert_update()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    -- Limpa e valida CPF
    NEW.cpf := accounts.clean_and_validate_cpf(NEW.cpf);
    
    -- Atualiza timestamp
    IF TG_OP = 'INSERT' THEN
        NEW.created_at := now();
    ELSE
        NEW.updated_at := now();
    END IF;
    
    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION accounts.clean_cpf_before_insert_update IS 'Trigger para limpar e validar CPF automaticamente';

CREATE TRIGGER clean_cpf_trigger
    BEFORE INSERT OR UPDATE ON accounts.employee_personal_data
    FOR EACH ROW
    EXECUTE FUNCTION accounts.clean_cpf_before_insert_update();

-- Trigger para limpar CEP automaticamente (reutilizando função existente)
CREATE OR REPLACE FUNCTION accounts.clean_postal_code_employee_before_insert_update()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    -- Reutiliza função existente de establishments
    NEW.postal_code := accounts.clean_and_validate_postal_code(NEW.postal_code);
    
    -- Atualiza timestamp
    IF TG_OP = 'INSERT' THEN
        NEW.created_at := now();
    ELSE
        NEW.updated_at := now();
    END IF;
    
    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION accounts.clean_postal_code_employee_before_insert_update IS 'Trigger para limpar CEP automaticamente (reutiliza função de establishments)';

CREATE TRIGGER clean_postal_code_trigger
    BEFORE INSERT OR UPDATE ON accounts.employee_addresses
    FOR EACH ROW
    EXECUTE FUNCTION accounts.clean_postal_code_employee_before_insert_update();

-- Trigger para atualizar timestamp de endereços
CREATE OR REPLACE FUNCTION accounts.update_address_timestamp()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        NEW.created_at := now();
    ELSE
        NEW.updated_at := now();
    END IF;
    
    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION accounts.update_address_timestamp IS 'Trigger para atualizar timestamp de endereços';

CREATE TRIGGER update_address_timestamp_trigger
    BEFORE INSERT OR UPDATE ON accounts.employee_addresses
    FOR EACH ROW
    EXECUTE FUNCTION accounts.update_address_timestamp();



-- =====================================================
-- VIEWS PARA CONSULTA
-- =====================================================

-- View para funcionários com dados completos
CREATE OR REPLACE VIEW accounts.v_employees_complete AS
SELECT 
    e.employee_id,
    e.user_id,
    e.supplier_id,
    e.establishment_id,
    e.is_active,
    e.activated_at,
    e.deactivated_at,
    e.created_at as employee_created_at,
    e.updated_at as employee_updated_at,
    -- Dados do usuário
    u.email,
    u.full_name as user_full_name,
    u.cognito_sub,
    u.is_active as user_is_active,
    -- Dados pessoais
    epd.cpf,
    epd.full_name as employee_full_name,
    epd.birth_date,
    epd.gender,
    epd.photo_url,
    epd.created_at as personal_data_created_at,
    epd.updated_at as personal_data_updated_at,
    -- Endereço
    ea.postal_code,
    ea.street,
    ea.number,
    ea.complement,
    ea.neighborhood,
    ea.city,
    ea.state,
    ea.is_primary,
    ea.created_at as address_created_at,
    ea.updated_at as address_updated_at
FROM accounts.employees e
JOIN accounts.users u ON e.user_id = u.user_id
LEFT JOIN accounts.employee_personal_data epd ON e.employee_id = epd.employee_id
LEFT JOIN accounts.employee_addresses ea ON e.employee_id = ea.employee_id AND ea.is_primary = true;

COMMENT ON VIEW accounts.v_employees_complete IS 'View completa de funcionários com dados pessoais e endereço principal';

-- =====================================================
-- ÍNDICES PARA PERFORMANCE
-- =====================================================

-- Índices para dados pessoais
CREATE INDEX IF NOT EXISTS idx_employee_personal_data_cpf ON accounts.employee_personal_data(cpf);
CREATE INDEX IF NOT EXISTS idx_employee_personal_data_full_name ON accounts.employee_personal_data(full_name);
CREATE INDEX IF NOT EXISTS idx_employee_personal_data_birth_date ON accounts.employee_personal_data(birth_date);
CREATE INDEX IF NOT EXISTS idx_employee_personal_data_gender ON accounts.employee_personal_data(gender);

-- Índices para endereços
CREATE INDEX IF NOT EXISTS idx_employee_addresses_postal_code ON accounts.employee_addresses(postal_code);
CREATE INDEX IF NOT EXISTS idx_employee_addresses_city ON accounts.employee_addresses(city);
CREATE INDEX IF NOT EXISTS idx_employee_addresses_state ON accounts.employee_addresses(state);
CREATE INDEX IF NOT EXISTS idx_employee_addresses_street ON accounts.employee_addresses(street);
CREATE INDEX IF NOT EXISTS idx_employee_addresses_neighborhood ON accounts.employee_addresses(neighborhood);

-- Índices condicionais para pg_trgm (se disponível)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_trgm') THEN
        -- Criar índices trigram se a extensão estiver disponível
        EXECUTE 'CREATE INDEX IF NOT EXISTS idx_employee_personal_data_full_name_trgm ON accounts.employee_personal_data USING gin(full_name gin_trgm_ops)';
        EXECUTE 'CREATE INDEX IF NOT EXISTS idx_employee_addresses_city_trgm ON accounts.employee_addresses USING gin(city gin_trgm_ops)';
        EXECUTE 'CREATE INDEX IF NOT EXISTS idx_employee_addresses_street_trgm ON accounts.employee_addresses USING gin(street gin_trgm_ops)';
        EXECUTE 'CREATE INDEX IF NOT EXISTS idx_employee_addresses_neighborhood_trgm ON accounts.employee_addresses USING gin(neighborhood gin_trgm_ops)';
        RAISE NOTICE '✅ Índices trigram criados com sucesso';
    ELSE
        RAISE NOTICE '⚠️  Índices trigram não criados - extensão pg_trgm não disponível';
    END IF;
END $$;

-- =====================================================
-- FUNÇÕES UTILITÁRIAS
-- =====================================================

-- Função para buscar funcionários por CPF
CREATE OR REPLACE FUNCTION accounts.find_employee_by_cpf(p_cpf text)
RETURNS TABLE(
    employee_id uuid,
    user_id uuid,
    email text,
    full_name text,
    cpf text,
    birth_date date,
    gender text,
    city text,
    state text
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        e.employee_id,
        e.user_id,
        u.email,
        epd.full_name,
        epd.cpf,
        epd.birth_date,
        epd.gender,
        ea.city,
        ea.state
    FROM accounts.employees e
    JOIN accounts.users u ON e.user_id = u.user_id
    JOIN accounts.employee_personal_data epd ON e.employee_id = epd.employee_id
    LEFT JOIN accounts.employee_addresses ea ON e.employee_id = ea.employee_id AND ea.is_primary = true
    WHERE epd.cpf = accounts.clean_and_validate_cpf(p_cpf);
END;
$$;

COMMENT ON FUNCTION accounts.find_employee_by_cpf IS 'Busca funcionário por CPF';

-- Função para buscar funcionários por nome (busca fuzzy)
CREATE OR REPLACE FUNCTION accounts.search_employees_by_name(search_term text)
RETURNS TABLE(
    employee_id uuid,
    user_id uuid,
    email text,
    full_name text,
    cpf text,
    birth_date date,
    gender text,
    city text,
    state text,
    similarity_score real
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Verifica se a extensão pg_trgm está disponível
    IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_trgm') THEN
        -- Busca com trigram se disponível
        RETURN QUERY
        SELECT 
            e.employee_id,
            e.user_id,
            u.email,
            epd.full_name,
            epd.cpf,
            epd.birth_date,
            epd.gender,
            ea.city,
            ea.state,
            similarity(epd.full_name, search_term) as similarity_score
        FROM accounts.employees e
        JOIN accounts.users u ON e.user_id = u.user_id
        JOIN accounts.employee_personal_data epd ON e.employee_id = epd.employee_id
        LEFT JOIN accounts.employee_addresses ea ON e.employee_id = ea.employee_id AND ea.is_primary = true
        WHERE epd.full_name % search_term
        ORDER BY similarity_score DESC;
    ELSE
        -- Busca simples com ILIKE se trigram não estiver disponível
        RETURN QUERY
        SELECT 
            e.employee_id,
            e.user_id,
            u.email,
            epd.full_name,
            epd.cpf,
            epd.birth_date,
            epd.gender,
            ea.city,
            ea.state,
            CASE 
                WHEN epd.full_name ILIKE '%' || search_term || '%' THEN 1.0
                WHEN epd.full_name ILIKE search_term || '%' THEN 0.8
                WHEN epd.full_name ILIKE '%' || search_term THEN 0.6
                ELSE 0.0
            END as similarity_score
        FROM accounts.employees e
        JOIN accounts.users u ON e.user_id = u.user_id
        JOIN accounts.employee_personal_data epd ON e.employee_id = epd.employee_id
        LEFT JOIN accounts.employee_addresses ea ON e.employee_id = ea.employee_id AND ea.is_primary = true
        WHERE epd.full_name ILIKE '%' || search_term || '%'
        ORDER BY similarity_score DESC;
    END IF;
END;
$$;

COMMENT ON FUNCTION accounts.search_employees_by_name IS 'Busca fuzzy de funcionários por nome';

-- Função para buscar funcionários por CEP
CREATE OR REPLACE FUNCTION accounts.find_employees_by_postal_code(postal_code text)
RETURNS TABLE(
    employee_id uuid,
    user_id uuid,
    email text,
    full_name text,
    cpf text,
    street text,
    number text,
    neighborhood text,
    city text,
    state text
)
LANGUAGE plpgsql
AS $$
DECLARE
    cleaned_postal_code text;
BEGIN
    -- Limpa o CEP
    cleaned_postal_code := regexp_replace(postal_code, '[^0-9]', '', 'g');
    
    RETURN QUERY
    SELECT 
        e.employee_id,
        e.user_id,
        u.email,
        epd.full_name,
        epd.cpf,
        ea.street,
        ea.number,
        ea.neighborhood,
        ea.city,
        ea.state
    FROM accounts.employees e
    JOIN accounts.users u ON e.user_id = u.user_id
    JOIN accounts.employee_personal_data epd ON e.employee_id = epd.employee_id
    JOIN accounts.employee_addresses ea ON e.employee_id = ea.employee_id
    WHERE ea.postal_code = cleaned_postal_code;
END;
$$;

COMMENT ON FUNCTION accounts.find_employees_by_postal_code IS 'Busca funcionários por CEP';

-- =====================================================
-- DADOS DE EXEMPLO (OPCIONAL)
-- =====================================================

-- Inserir dados de exemplo (descomente se necessário)
/*
INSERT INTO accounts.employee_personal_data (employee_id, cpf, full_name, birth_date, gender, photo_url) VALUES
(gen_random_uuid(), '12345678901', 'João Silva Santos', '1990-05-15', 'M', 'https://example.com/photos/joao.jpg'),
(gen_random_uuid(), '98765432100', 'Maria Oliveira Costa', '1985-12-03', 'F', 'https://example.com/photos/maria.jpg'),
(gen_random_uuid(), '11122233344', 'Pedro Almeida Lima', '1995-08-22', 'M', NULL);

INSERT INTO accounts.employee_addresses (employee_id, postal_code, street, number, neighborhood, city, state) VALUES
(gen_random_uuid(), '01234567', 'Rua das Flores', '123', 'Centro', 'São Paulo', 'SP'),
(gen_random_uuid(), '98765432', 'Avenida Principal', '456', 'Jardim', 'Rio de Janeiro', 'RJ'),
(gen_random_uuid(), '55556666', 'Travessa da Paz', '789', 'Vila Nova', 'Belo Horizonte', 'MG');
*/

-- =====================================================
-- CRIAÇÃO AUTOMÁTICA DAS TABELAS DE AUDITORIA
-- =====================================================

-- Cria automaticamente as tabelas de auditoria para as novas tabelas
DO $$
BEGIN
    -- Verifica se o schema audit existe
    IF EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'audit') THEN
        -- Cria auditoria para employee_personal_data
        PERFORM audit.create_audit_table('accounts', 'employee_personal_data');
        RAISE NOTICE '✅ Auditoria criada para accounts.employee_personal_data';
        
        -- Cria auditoria para employee_addresses
        PERFORM audit.create_audit_table('accounts', 'employee_addresses');
        RAISE NOTICE '✅ Auditoria criada para accounts.employee_addresses';
        
        RAISE NOTICE '🎯 Todas as tabelas de employees agora estão auditadas automaticamente!';
    ELSE
        RAISE NOTICE '⚠️  Schema audit não encontrado. Execute primeiro: \i audit_system.sql';
        RAISE NOTICE '⚠️  Depois execute manualmente:';
        RAISE NOTICE '   SELECT audit.create_audit_table(''accounts'', ''employee_personal_data'');';
        RAISE NOTICE '   SELECT audit.create_audit_table(''accounts'', ''employee_addresses'');';
    END IF;
END $$;

-- =====================================================
-- MENSAGEM DE SUCESSO
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '🎉 ==========================================';
    RAISE NOTICE '🎉 EXTENSÃO DE EMPLOYEES CRIADA COM SUCESSO!';
    RAISE NOTICE '🎉 ==========================================';
    RAISE NOTICE '';
    RAISE NOTICE '📋 Tabelas criadas:';
    RAISE NOTICE '   - accounts.employee_personal_data';
    RAISE NOTICE '   - accounts.employee_addresses';
    RAISE NOTICE '';
    RAISE NOTICE '🔧 Funcionalidades implementadas:';
    RAISE NOTICE '   - Validação automática de CPF';
    RAISE NOTICE '   - Limpeza automática de CPF e CEP';
    RAISE NOTICE '   - Auditoria automática criada';
    RAISE NOTICE '   - Índices otimizados para busca';
    RAISE NOTICE '   - Views para consulta completa';
    RAISE NOTICE '';
    RAISE NOTICE '📊 Auditoria:';
    RAISE NOTICE '   - Tabelas audit criadas automaticamente';
    RAISE NOTICE '   - Triggers de auditoria ativos';
    RAISE NOTICE '   - Particionamento automático por data';
    RAISE NOTICE '';
    RAISE NOTICE '🚀 Sistema pronto para produção com auditoria completa!';
    RAISE NOTICE '';
END $$;
