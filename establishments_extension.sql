-- =====================================================
-- EXTENSÃO DO SCHEMA ACCOUNTS - ESTABLISHMENTS
-- =====================================================
-- Este script estende a entidade establishments com informações
-- adicionais de cadastro empresarial e endereço

-- Tabela para dados empresariais (CNPJ, Razão Social, etc.)
CREATE TABLE accounts.establishment_business_data (
    establishment_business_data_id uuid DEFAULT gen_random_uuid() NOT NULL,
    establishment_id uuid NOT NULL,
    cnpj text NOT NULL, -- Apenas números (14 dígitos)
    trade_name text NOT NULL, -- Nome Fantasia
    corporate_name text NOT NULL, -- Razão Social
    state_registration text, -- Inscrição Estadual
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone, -- Soft delete
    
    CONSTRAINT establishment_business_data_pkey PRIMARY KEY (establishment_business_data_id),
    CONSTRAINT establishment_business_data_establishment_id_fkey 
        FOREIGN KEY (establishment_id) REFERENCES accounts.establishments(establishment_id) ON DELETE CASCADE,
    CONSTRAINT establishment_business_data_cnpj_unique UNIQUE (cnpj),
    CONSTRAINT establishment_business_data_establishment_id_unique UNIQUE (establishment_id)
);

-- Comentários para a tabela de dados empresariais
COMMENT ON TABLE accounts.establishment_business_data IS 'Dados empresariais específicos dos estabelecimentos (CNPJ, Razão Social, etc.)';
COMMENT ON COLUMN accounts.establishment_business_data.establishment_business_data_id IS 'Identificador único dos dados empresariais';
COMMENT ON COLUMN accounts.establishment_business_data.establishment_id IS 'Referência ao estabelecimento';
COMMENT ON COLUMN accounts.establishment_business_data.cnpj IS 'CNPJ da empresa (apenas números, 14 dígitos)';
COMMENT ON COLUMN accounts.establishment_business_data.trade_name IS 'Nome Fantasia da empresa';
COMMENT ON COLUMN accounts.establishment_business_data.corporate_name IS 'Razão Social da empresa';
COMMENT ON COLUMN accounts.establishment_business_data.state_registration IS 'Número da Inscrição Estadual';
COMMENT ON COLUMN accounts.establishment_business_data.created_at IS 'Data de criação do registro';
COMMENT ON COLUMN accounts.establishment_business_data.updated_at IS 'Data da última atualização';
COMMENT ON COLUMN accounts.establishment_business_data.deleted_at IS 'Data de exclusão lógica (soft delete) - NULL se ativo';

-- Tabela para endereços dos estabelecimentos
CREATE TABLE accounts.establishment_addresses (
    establishment_address_id uuid DEFAULT gen_random_uuid() NOT NULL,
    establishment_id uuid NOT NULL,
    postal_code text NOT NULL, -- CEP (apenas números, 8 dígitos)
    street text NOT NULL, -- Logradouro
    number text NOT NULL, -- Número
    complement text, -- Complemento (opcional)
    neighborhood text NOT NULL, -- Bairro
    city text NOT NULL, -- Cidade
    state text NOT NULL, -- Estado
    is_primary boolean DEFAULT true NOT NULL, -- Endereço principal
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone, -- Soft delete
    
    CONSTRAINT establishment_addresses_pkey PRIMARY KEY (establishment_address_id),
    CONSTRAINT establishment_addresses_establishment_id_fkey 
        FOREIGN KEY (establishment_id) REFERENCES accounts.establishments(establishment_id) ON DELETE CASCADE,
    CONSTRAINT establishment_addresses_postal_code_check 
        CHECK (postal_code ~ '^\d{8}$'),
    CONSTRAINT establishment_addresses_state_check 
        CHECK (state ~ '^[A-Z]{2}$')
);

-- Comentários para a tabela de endereços
COMMENT ON TABLE accounts.establishment_addresses IS 'Endereços dos estabelecimentos';
COMMENT ON COLUMN accounts.establishment_addresses.establishment_address_id IS 'Identificador único do endereço';
COMMENT ON COLUMN accounts.establishment_addresses.establishment_id IS 'Referência ao estabelecimento';
COMMENT ON COLUMN accounts.establishment_addresses.postal_code IS 'CEP (apenas números, 8 dígitos)';
COMMENT ON COLUMN accounts.establishment_addresses.street IS 'Logradouro (Rua, Avenida, etc.)';
COMMENT ON COLUMN accounts.establishment_addresses.number IS 'Número do endereço';
COMMENT ON COLUMN accounts.establishment_addresses.complement IS 'Complemento do endereço (opcional)';
COMMENT ON COLUMN accounts.establishment_addresses.neighborhood IS 'Bairro';
COMMENT ON COLUMN accounts.establishment_addresses.city IS 'Cidade';
COMMENT ON COLUMN accounts.establishment_addresses.state IS 'Estado (sigla de 2 letras)';
COMMENT ON COLUMN accounts.establishment_addresses.is_primary IS 'Indica se é o endereço principal';
COMMENT ON COLUMN accounts.establishment_addresses.created_at IS 'Data de criação do registro';
COMMENT ON COLUMN accounts.establishment_addresses.updated_at IS 'Data da última atualização';
COMMENT ON COLUMN accounts.establishment_addresses.deleted_at IS 'Data de exclusão lógica (soft delete) - NULL se ativo';

-- =====================================================
-- ÍNDICES PARA PERFORMANCE
-- =====================================================

-- Índices para dados empresariais
CREATE INDEX idx_establishment_business_data_cnpj ON accounts.establishment_business_data(cnpj);
CREATE INDEX idx_establishment_business_data_trade_name ON accounts.establishment_business_data(trade_name);
CREATE INDEX idx_establishment_business_data_corporate_name ON accounts.establishment_business_data(corporate_name);

-- Índices para endereços
CREATE INDEX idx_establishment_addresses_postal_code ON accounts.establishment_addresses(postal_code);
CREATE INDEX idx_establishment_addresses_city ON accounts.establishment_addresses(city);
CREATE INDEX idx_establishment_addresses_state ON accounts.establishment_addresses(state);
CREATE INDEX idx_establishment_addresses_establishment_id ON accounts.establishment_addresses(establishment_id);

-- =====================================================
-- ÍNDICES DE TEXTO PARA BUSCA AVANÇADA
-- =====================================================

-- Índices GIN para busca full-text em nomes
CREATE INDEX idx_establishment_business_data_trade_name_gin ON accounts.establishment_business_data USING gin(to_tsvector('portuguese', trade_name));
CREATE INDEX idx_establishment_business_data_corporate_name_gin ON accounts.establishment_business_data USING gin(to_tsvector('portuguese', corporate_name));

-- Índices trigram para busca fuzzy (similaridade)
CREATE INDEX idx_establishment_business_data_trade_name_trgm ON accounts.establishment_business_data USING gin(trade_name gin_trgm_ops);
CREATE INDEX idx_establishment_business_data_corporate_name_trgm ON accounts.establishment_business_data USING gin(corporate_name gin_trgm_ops);

-- Índices para endereços com busca de texto
CREATE INDEX idx_establishment_addresses_street_gin ON accounts.establishment_addresses USING gin(to_tsvector('portuguese', street));
CREATE INDEX idx_establishment_addresses_neighborhood_gin ON accounts.establishment_addresses USING gin(to_tsvector('portuguese', neighborhood));
CREATE INDEX idx_establishment_addresses_city_gin ON accounts.establishment_addresses USING gin(to_tsvector('portuguese', city));

-- Índices parciais para registros ativos (soft delete)
CREATE INDEX idx_establishment_business_data_active ON accounts.establishment_business_data(establishment_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_establishment_addresses_active ON accounts.establishment_addresses(establishment_id) WHERE deleted_at IS NULL;

-- =====================================================
-- TRIGGERS PARA AUDITORIA
-- =====================================================

-- Trigger para atualizar updated_at em establishment_business_data
CREATE TRIGGER set_establishment_business_data_updated_at
    BEFORE UPDATE ON accounts.establishment_business_data
    FOR EACH ROW
    EXECUTE FUNCTION accounts.set_updated_at();

-- Trigger para atualizar updated_at em establishment_addresses
CREATE TRIGGER set_establishment_addresses_updated_at
    BEFORE UPDATE ON accounts.establishment_addresses
    FOR EACH ROW
    EXECUTE FUNCTION accounts.set_updated_at();

-- =====================================================
-- TRIGGERS PARA LIMPEZA AUTOMÁTICA DE DADOS
-- =====================================================

-- Trigger para limpar e validar CNPJ automaticamente
CREATE OR REPLACE FUNCTION accounts.clean_cnpj_before_insert_update()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    -- Limpa e valida o CNPJ antes de inserir/atualizar
    NEW.cnpj := accounts.clean_and_validate_cnpj(NEW.cnpj);
    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION accounts.clean_cnpj_before_insert_update() IS 'Função trigger que limpa e valida CNPJ automaticamente antes de inserir/atualizar';

CREATE TRIGGER clean_cnpj_trigger
    BEFORE INSERT OR UPDATE ON accounts.establishment_business_data
    FOR EACH ROW
    EXECUTE FUNCTION accounts.clean_cnpj_before_insert_update();

COMMENT ON TRIGGER clean_cnpj_trigger ON accounts.establishment_business_data IS 'Trigger que executa automaticamente antes de inserir/atualizar CNPJ para limpeza e validação';

-- Trigger para limpar e validar CEP automaticamente
CREATE OR REPLACE FUNCTION accounts.clean_postal_code_before_insert_update()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    -- Limpa e valida o CEP antes de inserir/atualizar
    NEW.postal_code := accounts.clean_and_validate_postal_code(NEW.postal_code);
    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION accounts.clean_postal_code_before_insert_update() IS 'Função trigger que limpa e valida CEP automaticamente antes de inserir/atualizar';

CREATE TRIGGER clean_postal_code_trigger
    BEFORE INSERT OR UPDATE ON accounts.establishment_addresses
    FOR EACH ROW
    EXECUTE FUNCTION accounts.clean_postal_code_before_insert_update();

COMMENT ON TRIGGER clean_postal_code_trigger ON accounts.establishment_addresses IS 'Trigger que executa automaticamente antes de inserir/atualizar CEP para limpeza e validação';

-- =====================================================
-- VIEWS PARA CONSULTAS
-- =====================================================

-- View para estabelecimentos com dados completos (apenas ativos)
CREATE VIEW accounts.v_establishments_complete AS
SELECT 
    e.establishment_id,
    e.name,
    e.is_active,
    e.activated_at,
    e.deactivated_at,
    e.created_at,
    e.updated_at,
    -- Dados empresariais
    ebd.cnpj,
    ebd.trade_name,
    ebd.corporate_name,
    ebd.state_registration,
    -- Endereço principal
    ea.postal_code,
    ea.street,
    ea.number,
    ea.complement,
    ea.neighborhood,
    ea.city,
    ea.state
FROM accounts.establishments e
LEFT JOIN accounts.establishment_business_data ebd ON e.establishment_id = ebd.establishment_id AND ebd.deleted_at IS NULL
LEFT JOIN accounts.establishment_addresses ea ON e.establishment_id = ea.establishment_id AND ea.is_primary = true AND ea.deleted_at IS NULL
WHERE e.is_active = true;

COMMENT ON VIEW accounts.v_establishments_complete IS 'View que retorna estabelecimentos ativos com dados empresariais e endereço principal (filtra automaticamente registros deletados)';

-- =====================================================
-- FUNÇÕES AUXILIARES
-- =====================================================

-- Função para limpar e validar CNPJ com algoritmo real de validação
CREATE OR REPLACE FUNCTION accounts.clean_and_validate_cnpj(cnpj_input text)
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
    cleaned_cnpj text;
    cnpj_array integer[];
    i integer;
    sum integer;
    remainder integer;
    digit1 integer;
    digit2 integer;
BEGIN
    -- Remove todos os caracteres não numéricos
    cleaned_cnpj := regexp_replace(cnpj_input, '[^0-9]', '', 'g');
    
    -- Verifica se tem exatamente 14 dígitos
    IF length(cleaned_cnpj) != 14 THEN
        RAISE EXCEPTION 'CNPJ deve ter exatamente 14 dígitos numéricos. Recebido: % (após limpeza: %)', cnpj_input, cleaned_cnpj;
    END IF;
    
    -- Verifica se todos os dígitos são iguais
    IF cleaned_cnpj ~ '^(\d)\1+$' THEN
        RAISE EXCEPTION 'CNPJ não pode ter todos os dígitos iguais';
    END IF;
    
    -- Converte string em array de inteiros
    cnpj_array := array(
        SELECT (regexp_split_to_table(cleaned_cnpj, ''))::integer
    );
    
    -- Validação do primeiro dígito verificador
    sum := 0;
    FOR i IN 1..12 LOOP
        IF i <= 4 THEN
            sum := sum + cnpj_array[i] * (6 - i);
        ELSE
            sum := sum + cnpj_array[i] * (14 - i);
        END IF;
    END LOOP;
    
    remainder := sum % 11;
    IF remainder < 2 THEN
        digit1 := 0;
    ELSE
        digit1 := 11 - remainder;
    END IF;
    
    -- Validação do segundo dígito verificador
    sum := 0;
    FOR i IN 1..13 LOOP
        IF i <= 5 THEN
            sum := sum + cnpj_array[i] * (7 - i);
        ELSE
            sum := sum + cnpj_array[i] * (15 - i);
        END IF;
    END LOOP;
    
    remainder := sum % 11;
    IF remainder < 2 THEN
        digit2 := 0;
    ELSE
        digit2 := 11 - remainder;
    END IF;
    
    -- Verifica se os dígitos verificadores estão corretos
    IF cnpj_array[13] != digit1 OR cnpj_array[14] != digit2 THEN
        RAISE EXCEPTION 'CNPJ inválido: dígitos verificadores incorretos';
    END IF;
    
    RETURN cleaned_cnpj;
END;
$$;

-- Função para limpar e validar CEP
CREATE OR REPLACE FUNCTION accounts.clean_and_validate_postal_code(postal_code_input text)
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
    cleaned_postal_code text;
BEGIN
    -- Remove todos os caracteres não numéricos
    cleaned_postal_code := regexp_replace(postal_code_input, '[^0-9]', '', 'g');
    
    -- Verifica se tem exatamente 8 dígitos
    IF length(cleaned_postal_code) != 8 THEN
        RAISE EXCEPTION 'CEP deve ter exatamente 8 dígitos numéricos. Recebido: % (após limpeza: %)', postal_code_input, cleaned_postal_code;
    END IF;
    
    RETURN cleaned_postal_code;
END;
$$;

COMMENT ON FUNCTION accounts.clean_and_validate_cnpj IS 'Função para limpar máscaras e validar CNPJ brasileiro';
COMMENT ON FUNCTION accounts.clean_and_validate_postal_code IS 'Função para limpar máscaras e validar CEP brasileiro';

-- Função para formatar CNPJ (de números para formato exibição)
CREATE OR REPLACE FUNCTION accounts.format_cnpj(cnpj_input text)
RETURNS text
LANGUAGE plpgsql
AS $$
BEGIN
    -- Verifica se tem exatamente 14 dígitos
    IF cnpj_input ~ '^\d{14}$' THEN
        RETURN substring(cnpj_input from 1 for 2) || '.' ||
               substring(cnpj_input from 3 for 3) || '.' ||
               substring(cnpj_input from 6 for 3) || '/' ||
               substring(cnpj_input from 9 for 4) || '-' ||
               substring(cnpj_input from 13 for 2);
    END IF;
    
    RETURN cnpj_input;
END;
$$;

COMMENT ON FUNCTION accounts.format_cnpj IS 'Função para formatar CNPJ de números para formato de exibição XX.XXX.XXX/XXXX-XX';

-- Função para formatar CEP (de números para formato de exibição)
CREATE OR REPLACE FUNCTION accounts.format_postal_code(postal_code_input text)
RETURNS text
LANGUAGE plpgsql
AS $$
BEGIN
    -- Verifica se tem exatamente 8 dígitos
    IF postal_code_input ~ '^\d{8}$' THEN
        RETURN substring(postal_code_input from 1 for 5) || '-' ||
               substring(postal_code_input from 6 for 3);
    END IF;
    
    RETURN postal_code_input;
END;
$$;

COMMENT ON FUNCTION accounts.format_postal_code IS 'Função para formatar CEP de números para formato de exibição XXXXX-XXX';

-- =====================================================
-- FUNÇÕES DE UTILIDADE
-- =====================================================

-- Função para buscar estabelecimentos por CEP
CREATE OR REPLACE FUNCTION accounts.find_establishments_by_postal_code(postal_code_input text)
RETURNS TABLE(
    establishment_id uuid,
    establishment_name text,
    trade_name text,
    corporate_name text,
    cnpj text,
    full_address text,
    distance_km numeric
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        e.establishment_id,
        e.name as establishment_name,
        ebd.trade_name,
        ebd.corporate_name,
        accounts.format_cnpj(ebd.cnpj) as cnpj,
        ea.street || ', ' || ea.number || ' - ' || ea.neighborhood || ', ' || ea.city || '/' || ea.state as full_address,
        0 as distance_km -- Aqui você pode implementar cálculo de distância real
    FROM accounts.establishments e
    JOIN accounts.establishment_business_data ebd ON e.establishment_id = ebd.establishment_id AND ebd.deleted_at IS NULL
    JOIN accounts.establishment_addresses ea ON e.establishment_id = ea.establishment_id AND ea.deleted_at IS NULL
    WHERE ea.postal_code = accounts.clean_and_validate_postal_code(postal_code_input)
    AND e.is_active = true
    ORDER BY e.name;
END;
$$;

COMMENT ON FUNCTION accounts.find_establishments_by_postal_code IS 'Busca estabelecimentos por CEP, retornando informações completas formatadas';

-- Função para buscar estabelecimentos por nome (busca fuzzy)
CREATE OR REPLACE FUNCTION accounts.search_establishments_by_name(search_term text, similarity_threshold numeric DEFAULT 0.3)
RETURNS TABLE(
    establishment_id uuid,
    establishment_name text,
    trade_name text,
    corporate_name text,
    similarity numeric
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        e.establishment_id,
        e.name as establishment_name,
        ebd.trade_name,
        ebd.corporate_name,
        GREATEST(
            similarity(e.name, search_term),
            similarity(ebd.trade_name, search_term),
            similarity(ebd.corporate_name, search_term)
        ) as similarity
    FROM accounts.establishments e
    JOIN accounts.establishment_business_data ebd ON e.establishment_id = ebd.establishment_id AND ebd.deleted_at IS NULL
    WHERE e.is_active = true
    AND (
        e.name ILIKE '%' || search_term || '%'
        OR ebd.trade_name ILIKE '%' || search_term || '%'
        OR ebd.corporate_name ILIKE '%' || search_term || '%'
        OR similarity(e.name, search_term) > similarity_threshold
        OR similarity(ebd.trade_name, search_term) > similarity_threshold
        OR similarity(ebd.corporate_name, search_term) > similarity_threshold
    )
    ORDER BY similarity DESC, e.name;
END;
$$;

COMMENT ON FUNCTION accounts.search_establishments_by_name IS 'Busca estabelecimentos por nome usando busca fuzzy e similaridade';

-- Função para gerar relatório de auditoria
CREATE OR REPLACE FUNCTION accounts.generate_audit_report(
    start_date timestamp DEFAULT (now() - interval '30 days'),
    end_date timestamp DEFAULT now()
)
RETURNS TABLE(
    table_name text,
    operation text,
    record_count bigint,
    last_operation timestamp
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        'establishment_business_data'::text as table_name,
        'INSERT'::text as operation,
        COUNT(*) as record_count,
        MAX(created_at) as last_operation
    FROM accounts.establishment_business_data 
    WHERE created_at BETWEEN start_date AND end_date
    
    UNION ALL
    
    SELECT 
        'establishment_addresses'::text as table_name,
        'INSERT'::text as operation,
        COUNT(*) as record_count,
        MAX(created_at) as last_operation
    FROM accounts.establishment_addresses 
    WHERE created_at BETWEEN start_date AND end_date
    
    UNION ALL
    
    SELECT 
        'establishment_business_data'::text as table_name,
        'UPDATE'::text as operation,
        COUNT(*) as record_count,
        MAX(updated_at) as last_operation
    FROM accounts.establishment_business_data 
    WHERE updated_at BETWEEN start_date AND end_date AND updated_at IS NOT NULL
    
    UNION ALL
    
    SELECT 
        'establishment_addresses'::text as table_name,
        'UPDATE'::text as operation,
        COUNT(*) as record_count,
        MAX(updated_at) as last_operation
    FROM accounts.establishment_addresses 
    WHERE updated_at BETWEEN start_date AND end_date AND updated_at IS NOT NULL
    
    UNION ALL
    
    SELECT 
        'establishment_business_data'::text as table_name,
        'DELETE'::text as operation,
        COUNT(*) as record_count,
        MAX(deleted_at) as last_operation
    FROM accounts.establishment_business_data 
    WHERE deleted_at BETWEEN start_date AND end_date AND deleted_at IS NOT NULL
    
    UNION ALL
    
    SELECT 
        'establishment_addresses'::text as table_name,
        'DELETE'::text as operation,
        COUNT(*) as record_count,
        MAX(deleted_at) as last_operation
    FROM accounts.establishment_addresses 
    WHERE deleted_at BETWEEN start_date AND end_date AND deleted_at IS NOT NULL;
END;
$$;

COMMENT ON FUNCTION accounts.generate_audit_report IS 'Gera relatório de auditoria com contagem de operações por período';

-- =====================================================
-- CONSTRAINTS ADICIONAIS
-- =====================================================

-- Constraints para garantir que os dados estejam limpos após processamento
ALTER TABLE accounts.establishment_business_data 
ADD CONSTRAINT establishment_business_data_cnpj_clean 
CHECK (cnpj ~ '^\d{14}$');

ALTER TABLE accounts.establishment_addresses 
ADD CONSTRAINT establishment_addresses_postal_code_clean 
CHECK (postal_code ~ '^\d{8}$');

-- =====================================================
-- CONSTRAINTS DE NEGÓCIO
-- =====================================================

-- Validação de tamanhos de campos
ALTER TABLE accounts.establishment_business_data 
ADD CONSTRAINT establishment_business_data_trade_name_length 
CHECK (length(trade_name) >= 2 AND length(trade_name) <= 100);

ALTER TABLE accounts.establishment_business_data 
ADD CONSTRAINT establishment_business_data_corporate_name_length 
CHECK (length(corporate_name) >= 5 AND length(corporate_name) <= 200);

ALTER TABLE accounts.establishment_addresses 
ADD CONSTRAINT establishment_addresses_street_length 
CHECK (length(street) >= 3 AND length(street) <= 150);

ALTER TABLE accounts.establishment_addresses 
ADD CONSTRAINT establishment_addresses_city_length 
CHECK (length(city) >= 2 AND length(city) <= 100);

-- Validação de estados brasileiros válidos
ALTER TABLE accounts.establishment_addresses 
ADD CONSTRAINT establishment_addresses_state_valid 
CHECK (state IN ('AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA', 'MT', 'MS', 'MG', 'PA', 'PB', 'PR', 'PE', 'PI', 'RJ', 'RN', 'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO'));

-- Validação de datas (não permitir datas futuras)
ALTER TABLE accounts.establishment_business_data 
ADD CONSTRAINT establishment_business_data_dates_valid 
CHECK (created_at <= now() AND (updated_at IS NULL OR updated_at <= now()) AND (deleted_at IS NULL OR deleted_at <= now()));

ALTER TABLE accounts.establishment_addresses 
ADD CONSTRAINT establishment_addresses_dates_valid 
CHECK (created_at <= now() AND (updated_at IS NULL OR updated_at <= now()) AND (deleted_at IS NULL OR deleted_at <= now()));

-- Validação de endereço único por estabelecimento (considerando soft delete)
ALTER TABLE accounts.establishment_addresses 
ADD CONSTRAINT establishment_addresses_unique_establishment_primary 
UNIQUE (establishment_id, is_primary) 
WHERE is_primary = true AND deleted_at IS NULL;

-- =====================================================
-- DADOS DE EXEMPLO (OPCIONAL)
-- =====================================================

-- Inserir dados de exemplo para teste
-- INSERT INTO accounts.establishment_business_data (establishment_id, cnpj, trade_name, corporate_name, state_registration)
-- VALUES 
--     ('uuid-exemplo-1', '12345678000190', 'Empresa Exemplo LTDA', 'Empresa Exemplo Comercio e Servicos LTDA', '123456789');

-- INSERT INTO accounts.establishment_addresses (establishment_id, postal_code, street, number, neighborhood, city, state)
-- VALUES 
--     ('uuid-exemplo-1', '01234567', 'Rua das Flores', '123', 'Centro', 'São Paulo', 'SP');

-- =====================================================
-- COMO USAR NA APLICAÇÃO
-- =====================================================
-- 
-- 1. AO SALVAR DADOS:
--    - CNPJ: Pode enviar com ou sem máscara, o banco limpa automaticamente
--      Ex: '12.345.678/0001-90' -> salva como '12345678000190'
--          '12.345.678/000190' -> salva como '12345678000190'
--          '12345678000190' -> salva como '12345678000190'
--    
--    - CEP: Pode enviar com ou sem máscara, o banco limpa automaticamente
--      Ex: '01234-567' -> salva como '01234567'
--          '01234567' -> salva como '01234567'
--
-- 2. AO EXIBIR DADOS:
--    - CNPJ: SELECT accounts.format_cnpj(cnpj) FROM accounts.establishment_business_data
--    - CEP: SELECT accounts.format_postal_code(postal_code) FROM accounts.establishment_addresses
--
-- 3. EXEMPLO DE CONSULTA COMPLETA:
--    SELECT 
--        e.name,
--        accounts.format_cnpj(ebd.cnpj) as cnpj_formatado,
--        accounts.format_postal_code(ea.postal_code) as cep_formatado
--    FROM accounts.establishments e
--    JOIN accounts.establishment_business_data ebd ON e.establishment_id = ebd.establishment_id
--    JOIN accounts.establishment_addresses ea ON e.establishment_id = ea.establishment_id
--    WHERE ea.is_primary = true;
--
-- 4. EXEMPLOS DE INSERÇÃO (o banco limpa automaticamente):
--    INSERT INTO establishment_business_data (cnpj) VALUES ('12.345.678/0001-90');
--    INSERT INTO establishment_addresses (postal_code) VALUES ('01234-567');
--    
--    Resultado: CNPJ salvo como '12345678000190', CEP salvo como '01234567'
--
-- 5. EXEMPLOS DE USO DAS FUNÇÕES DE UTILIDADE:
--    
--    -- Buscar estabelecimentos por CEP
--    SELECT * FROM accounts.find_establishments_by_postal_code('01234-567');
--    
--    -- Busca fuzzy por nome
--    SELECT * FROM accounts.search_establishments_by_name('Empresa', 0.5);
--    
--    -- Relatório de auditoria dos últimos 7 dias
--    SELECT * FROM accounts.generate_audit_report(now() - interval '7 days');
--    
--    -- Soft delete (marca como deletado ao invés de remover)
--    UPDATE accounts.establishment_business_data 
--    SET deleted_at = now() 
--    WHERE establishment_id = 'uuid-do-establishment';
--    
--    -- Restaurar registro deletado
--    UPDATE accounts.establishment_business_data 
--    SET deleted_at = NULL 
--    WHERE establishment_id = 'uuid-do-establishment';
