-- Funções do schema accounts
-- Schema: accounts
-- Arquivo: functions.sql

-- Este arquivo contém todas as funções do schema accounts
-- As funções são criadas automaticamente pelos scripts de extensão
-- Este arquivo serve como documentação e referência

-- =====================================================
-- FUNÇÕES DE BUSCA DE FUNCIONÁRIOS
-- =====================================================

/*
-- Buscar funcionário por CPF
CREATE OR REPLACE FUNCTION accounts.find_employee_by_cpf(p_cpf text)
RETURNS TABLE(
    employee_id uuid, 
    user_id uuid, 
    email text, 
    full_name text, 
    cpf text, 
    birth_date date, 
    gender text, 
    photo_url text
) AS $$
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
        epd.photo_url
    FROM accounts.employees e
    JOIN accounts.users u ON e.user_id = u.user_id
    JOIN accounts.employee_personal_data epd ON e.employee_id = epd.employee_id
    WHERE epd.cpf = aux.clean_and_validate_cpf(p_cpf)
      AND e.is_active = true;
END;
$$ LANGUAGE plpgsql;
*/

-- Funcionalidade: Busca funcionário por CPF com validação automática
-- Parâmetros: p_cpf (text) - CPF a ser buscado
-- Retorna: Dados completos do funcionário
-- Validação: CPF é limpo e validado automaticamente

/*
-- Buscar funcionários por CEP
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
) AS $$
BEGIN
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
    WHERE ea.postal_code = aux.clean_and_validate_postal_code(postal_code)
      AND e.is_active = true
      AND ea.is_primary = true;
END;
$$ LANGUAGE plpgsql;
*/

-- Funcionalidade: Busca funcionários por CEP com validação automática
-- Parâmetros: postal_code (text) - CEP a ser buscado
-- Retorna: Dados dos funcionários que moram no CEP especificado
-- Validação: CEP é limpo e validado automaticamente

/*
-- Busca fuzzy de funcionários por nome
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
    state text
) AS $$
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
    WHERE e.is_active = true
      AND (
          epd.full_name ILIKE '%' || search_term || '%'
          OR epd.full_name % search_term
      )
    ORDER BY 
        CASE WHEN epd.full_name ILIKE search_term || '%' THEN 1
             WHEN epd.full_name ILIKE '%' || search_term || '%' THEN 2
             ELSE 3
        END,
        epd.full_name;
END;
$$ LANGUAGE plpgsql;
*/

-- Funcionalidade: Busca fuzzy de funcionários por nome
-- Parâmetros: search_term (text) - Termo de busca
-- Retorna: Funcionários com nomes similares ao termo buscado
-- Busca: Suporta busca parcial e fuzzy (se pg_trgm disponível)

-- =====================================================
-- FUNÇÕES DE BUSCA DE ESTABELECIMENTOS
-- =====================================================

/*
-- Buscar estabelecimentos por CEP
CREATE OR REPLACE FUNCTION accounts.find_establishments_by_postal_code(p_postal_code text)
RETURNS TABLE(
    establishment_id uuid, 
    establishment_name text, 
    cnpj text, 
    trade_name text, 
    corporate_name text, 
    state_registration text, 
    street text, 
    number text, 
    neighborhood text, 
    city text, 
    state text
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        est.establishment_id,
        est.name as establishment_name,
        ebd.cnpj,
        ebd.trade_name,
        ebd.corporate_name,
        ebd.state_registration,
        ea.street,
        ea.number,
        ea.neighborhood,
        ea.city,
        ea.state
    FROM accounts.establishments est
    JOIN accounts.establishment_business_data ebd ON est.establishment_id = ebd.establishment_id
    JOIN accounts.establishment_addresses ea ON est.establishment_id = ea.establishment_id
    WHERE ea.postal_code = aux.clean_and_validate_postal_code(p_postal_code)
      AND est.is_active = true
      AND ea.is_primary = true;
END;
$$ LANGUAGE plpgsql;
*/

-- Funcionalidade: Busca estabelecimentos por CEP com validação automática
-- Parâmetros: p_postal_code (text) - CEP a ser buscado
-- Retorna: Dados completos dos estabelecimentos no CEP especificado
-- Validação: CEP é limpo e validado automaticamente

-- =====================================================
-- FUNÇÕES DE VALIDAÇÃO E LIMPEZA
-- =====================================================

/*
-- Função para atualizar timestamp de updated_at
CREATE OR REPLACE FUNCTION accounts.set_updated_at()
RETURNS trigger AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
*/

-- Funcionalidade: Atualiza automaticamente o campo updated_at
-- Uso: Trigger para manter timestamps atualizados
-- Aplicação: Todas as tabelas com campo updated_at

-- =====================================================
-- EXEMPLOS DE USO
-- =====================================================

/*
-- Exemplo 1: Buscar funcionário por CPF
SELECT * FROM accounts.find_employee_by_cpf('123.456.789-09');

-- Exemplo 2: Buscar funcionários por CEP
SELECT * FROM accounts.find_employees_by_postal_code('12345-678');

-- Exemplo 3: Busca fuzzy por nome
SELECT * FROM accounts.search_employees_by_name('Vinicius');

-- Exemplo 4: Buscar estabelecimentos por CEP
SELECT * FROM accounts.find_establishments_by_postal_code('12345-678');
*/

-- =====================================================
-- NOTAS IMPORTANTES
-- =====================================================

-- 1. Todas as funções usam validação automática via schema aux
-- 2. CPF e CEP são limpos automaticamente antes da busca
-- 3. Busca fuzzy requer extensão pg_trgm (opcional)
-- 4. Funções retornam apenas registros ativos
-- 5. Todas as operações são auditadas automaticamente
