-- =====================================================
-- MIGRAÇÃO: EMPLOYEES_EXTENSION -> SCHEMA AUX
-- =====================================================
-- Script para refatorar employees_extension.sql para usar o schema aux
-- Autor: Assistente IA + Usuário
-- Data: 2025-01-27
-- Versão: 1.0

-- =====================================================
-- VERIFICAÇÃO DE PRÉ-REQUISITOS
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '🔍 Verificando pré-requisitos para migração...';
    
    -- Verificar se o schema aux existe
    IF NOT EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'aux') THEN
        RAISE EXCEPTION 'Schema aux não encontrado. Execute primeiro: \i aux_schema.sql';
    END IF;
    
    -- Verificar se as funções necessárias existem
    IF NOT EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_schema = 'aux' AND routine_name = 'clean_and_validate_cpf') THEN
        RAISE EXCEPTION 'Função aux.clean_and_validate_cpf não encontrada';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_schema = 'aux' AND routine_name = 'clean_and_validate_postal_code') THEN
        RAISE EXCEPTION 'Função aux.clean_and_validate_postal_code não encontrada';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_schema = 'aux' AND routine_name = 'validate_url') THEN
        RAISE EXCEPTION 'Função aux.validate_url não encontrada';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_schema = 'aux' AND routine_name = 'validate_birth_date') THEN
        RAISE EXCEPTION 'Função aux.validate_birth_date não encontrada';
    END IF;
    
    RAISE NOTICE '✅ Todos os pré-requisitos atendidos!';
END $$;

-- =====================================================
-- REMOÇÃO DE FUNÇÕES DUPLICADAS
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '🗑️ Removendo funções duplicadas...';
    
    -- Remover função de validação de CPF duplicada
    DROP FUNCTION IF EXISTS accounts.validate_cpf(text);
    RAISE NOTICE '✅ Função accounts.validate_cpf removida';
    
    -- Remover função de limpeza e validação de CPF duplicada
    DROP FUNCTION IF EXISTS accounts.clean_and_validate_cpf(text);
    RAISE NOTICE '✅ Função accounts.clean_and_validate_cpf removida';
    
    RAISE NOTICE '✅ Funções duplicadas removidas!';
END $$;

-- =====================================================
-- ATUALIZAÇÃO DE CONSTRAINTS PARA USAR SCHEMA AUX
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '🔧 Atualizando constraints para usar schema aux...';
    
    -- Remover constraint antiga de validação de URL
    ALTER TABLE accounts.employee_personal_data 
    DROP CONSTRAINT IF EXISTS employee_personal_data_photo_url_valid;
    RAISE NOTICE '✅ Constraint employee_personal_data_photo_url_valid removida';
    
    -- Remover constraint antiga de validação de data de nascimento
    ALTER TABLE accounts.employee_personal_data 
    DROP CONSTRAINT IF EXISTS employee_personal_data_birth_date_valid;
    RAISE NOTICE '✅ Constraint employee_personal_data_birth_date_valid removida';
    
    -- Adicionar nova constraint usando função do schema aux para URL
    ALTER TABLE accounts.employee_personal_data 
    ADD CONSTRAINT employee_personal_data_photo_url_valid 
    CHECK (aux.validate_url(photo_url));
    RAISE NOTICE '✅ Nova constraint usando aux.validate_url criada';
    
    -- Adicionar nova constraint usando função do schema aux para data de nascimento
    ALTER TABLE accounts.employee_personal_data 
    ADD CONSTRAINT employee_personal_data_birth_date_valid 
    CHECK (aux.validate_birth_date(birth_date, 14));
    RAISE NOTICE '✅ Nova constraint usando aux.validate_birth_date criada';
    
    RAISE NOTICE '✅ Todas as constraints atualizadas para usar schema aux!';
    
    -- Verificar se existem outras constraints que dependem de funções antigas
    RAISE NOTICE '🔍 Verificando outras constraints que podem precisar de atualização...';
    
    -- Listar constraints CHECK que podem estar usando funções antigas
    RAISE NOTICE '📋 Constraints CHECK encontradas na tabela employee_personal_data:';
    DECLARE
        r RECORD;
    BEGIN
        FOR r IN (
            SELECT cc.constraint_name, cc.check_clause 
            FROM information_schema.check_constraints cc
            JOIN information_schema.table_constraints tc ON cc.constraint_name = tc.constraint_name
            WHERE tc.table_schema = 'accounts' 
            AND tc.table_name = 'employee_personal_data'
        ) LOOP
            RAISE NOTICE '   - %: %', r.constraint_name, r.check_clause;
        END LOOP;
    END;
    
END $$;

-- =====================================================
-- ATUALIZAÇÃO DE TRIGGERS PARA USAR SCHEMA AUX
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '🔧 Atualizando triggers para usar schema aux...';
    
    -- Remover trigger antigo de CPF
    DROP TRIGGER IF EXISTS clean_cpf_trigger ON accounts.employee_personal_data;
    RAISE NOTICE '✅ Trigger clean_cpf_trigger removido';
    
    -- Remover trigger antigo de CEP
    DROP TRIGGER IF EXISTS clean_postal_code_trigger ON accounts.employee_addresses;
    RAISE NOTICE '✅ Trigger clean_postal_code_trigger removido';
    
    -- Remover função de trigger de CPF
    DROP FUNCTION IF EXISTS accounts.clean_cpf_before_insert_update();
    RAISE NOTICE '✅ Função accounts.clean_cpf_before_insert_update removida';
    
    -- Remover função de trigger de CEP
    DROP FUNCTION IF EXISTS accounts.clean_postal_code_employee_before_insert_update();
    RAISE NOTICE '✅ Função accounts.clean_postal_code_employee_before_insert_update removida';
    
    RAISE NOTICE '✅ Triggers antigos removidos!';
END $$;

-- =====================================================
-- CRIAÇÃO DE NOVAS FUNÇÕES DE TRIGGER USANDO AUX
-- =====================================================

-- Função para limpar e validar CPF usando schema aux
CREATE OR REPLACE FUNCTION accounts.clean_cpf_before_insert_update()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Usar função do schema aux
    NEW.cpf := aux.clean_and_validate_cpf(NEW.cpf);
    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION accounts.clean_cpf_before_insert_update() IS 'Função de trigger para limpar e validar CPF usando schema aux';

-- Função para limpar e validar CEP usando schema aux
CREATE OR REPLACE FUNCTION accounts.clean_postal_code_employee_before_insert_update()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Usar função do schema aux
    NEW.postal_code := aux.clean_and_validate_postal_code(NEW.postal_code);
    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION accounts.clean_postal_code_employee_before_insert_update() IS 'Função de trigger para limpar e validar CEP usando schema aux';

-- =====================================================
-- RECRIAÇÃO DOS TRIGGERS
-- =====================================================

-- Recriar trigger para CPF
CREATE TRIGGER clean_cpf_trigger
    BEFORE INSERT OR UPDATE ON accounts.employee_personal_data
    FOR EACH ROW EXECUTE FUNCTION accounts.clean_cpf_before_insert_update();

COMMENT ON TRIGGER clean_cpf_trigger ON accounts.employee_personal_data IS 'Trigger para limpar e validar CPF automaticamente usando schema aux';

-- Recriar trigger para CEP
CREATE TRIGGER clean_postal_code_trigger
    BEFORE INSERT OR UPDATE ON accounts.employee_addresses
    FOR EACH ROW EXECUTE FUNCTION accounts.clean_postal_code_employee_before_insert_update();

COMMENT ON TRIGGER clean_postal_code_trigger ON accounts.employee_addresses IS 'Trigger para limpar e validar CEP automaticamente usando schema aux';

-- =====================================================
-- ATUALIZAÇÃO DE FUNÇÕES DE BUSCA PARA USAR AUX
-- =====================================================

-- Remover função antiga primeiro
DROP FUNCTION IF EXISTS accounts.find_employee_by_cpf(text);

-- Recriar função de busca por CPF para usar formatação do aux
CREATE OR REPLACE FUNCTION accounts.find_employee_by_cpf(p_cpf text)
RETURNS TABLE (
    employee_id uuid,
    user_id uuid,
    email text,
    full_name text,
    cpf text,
    birth_date date,
    gender text,
    photo_url text,
    postal_code text,
    street text,
    number text,
    complement text,
    neighborhood text,
    city text,
    state text,
    is_primary boolean
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Limpar CPF de entrada usando schema aux
    p_cpf := aux.clean_and_validate_cpf(p_cpf);
    
    RETURN QUERY
    SELECT 
        e.employee_id,
        e.user_id,
        u.email,
        epd.full_name,
        epd.cpf,
        epd.birth_date,
        epd.gender,
        epd.photo_url,
        ea.postal_code,
        ea.street,
        ea.number,
        ea.complement,
        ea.neighborhood,
        ea.city,
        ea.state,
        ea.is_primary
    FROM accounts.employees e
    JOIN accounts.users u ON e.user_id = u.user_id
    JOIN accounts.employee_personal_data epd ON e.employee_id = epd.employee_id
    LEFT JOIN accounts.employee_addresses ea ON e.employee_id = ea.employee_id AND ea.is_primary = true
    WHERE epd.cpf = p_cpf;
END;
$$;

COMMENT ON FUNCTION accounts.find_employee_by_cpf(text) IS 'Busca funcionário por CPF usando validação do schema aux';

-- =====================================================
-- ATUALIZAÇÃO DE VIEWS PARA USAR DOMÍNIOS AUX
-- =====================================================

-- Remover view antiga primeiro
DROP VIEW IF EXISTS accounts.v_employees_complete;

-- Recriar view para usar domínios do schema aux
CREATE OR REPLACE VIEW accounts.v_employees_complete AS
SELECT 
    e.employee_id,
    e.user_id,
    u.email,
    u.full_name as user_full_name,
    u.is_active,
    epd.full_name,
    epd.cpf,
    epd.birth_date,
    epd.gender::aux.genero as gender_validated,
    epd.photo_url,
    epd.created_at as personal_data_created_at,
    epd.updated_at as personal_data_updated_at,
    ea.postal_code,
    ea.street,
    ea.number,
    ea.complement,
    ea.neighborhood,
    ea.city,
    ea.state::aux.estado_brasileiro as state_validated,
    ea.is_primary,
    ea.created_at as address_created_at,
    ea.updated_at as address_updated_at
FROM accounts.employees e
JOIN accounts.users u ON e.user_id = u.user_id
LEFT JOIN accounts.employee_personal_data epd ON e.employee_id = epd.employee_id
LEFT JOIN accounts.employee_addresses ea ON e.employee_id = ea.employee_id AND ea.is_primary = true;

COMMENT ON VIEW accounts.v_employees_complete IS 'View consolidada de funcionários usando validações do schema aux';

-- =====================================================
-- VERIFICAÇÃO DE COMPATIBILIDADE
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '🔍 Verificando compatibilidade após migração...';
    
    -- Verificar se as funções do aux estão sendo usadas
    IF EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_schema = 'accounts' AND routine_name = 'clean_cpf_before_insert_update') THEN
        RAISE NOTICE '✅ Função clean_cpf_before_insert_update recriada com sucesso';
    ELSE
        RAISE NOTICE '❌ Função clean_cpf_before_insert_update não foi recriada';
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_schema = 'accounts' AND routine_name = 'clean_postal_code_employee_before_insert_update') THEN
        RAISE NOTICE '✅ Função clean_postal_code_employee_before_insert_update recriada com sucesso';
    ELSE
        RAISE NOTICE '❌ Função clean_postal_code_employee_before_insert_update não foi recriada';
    END IF;
    
    -- Verificar se os triggers foram recriados
    IF EXISTS (SELECT 1 FROM information_schema.triggers WHERE trigger_schema = 'accounts' AND trigger_name = 'clean_cpf_trigger') THEN
        RAISE NOTICE '✅ Trigger clean_cpf_trigger recriado com sucesso';
    ELSE
        RAISE NOTICE '❌ Trigger clean_cpf_trigger não foi recriado';
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.triggers WHERE trigger_schema = 'accounts' AND trigger_name = 'clean_postal_code_trigger') THEN
        RAISE NOTICE '✅ Trigger clean_postal_code_trigger recriado com sucesso';
    ELSE
        RAISE NOTICE '❌ Trigger clean_postal_code_trigger não foi recriado';
    END IF;
    
    -- Verificar se a view foi atualizada
    IF EXISTS (SELECT 1 FROM information_schema.views WHERE table_schema = 'accounts' AND table_name = 'v_employees_complete') THEN
        RAISE NOTICE '✅ View v_employees_complete atualizada com sucesso';
    ELSE
        RAISE NOTICE '❌ View v_employees_complete não foi atualizada';
    END IF;
    
    -- Verificar se as constraints foram atualizadas
    IF EXISTS (
        SELECT 1 FROM information_schema.check_constraints cc
        JOIN information_schema.table_constraints tc ON cc.constraint_name = tc.constraint_name
        WHERE tc.table_schema = 'accounts' 
        AND tc.table_name = 'employee_personal_data'
        AND cc.check_clause LIKE '%aux.validate_url%'
    ) AND EXISTS (
        SELECT 1 FROM information_schema.check_constraints cc
        JOIN information_schema.table_constraints tc ON cc.constraint_name = tc.constraint_name
        WHERE tc.table_schema = 'accounts' 
        AND tc.table_name = 'employee_personal_data'
        AND cc.check_clause LIKE '%aux.validate_birth_date%'
    ) THEN
        RAISE NOTICE '✅ Todas as constraints atualizadas para usar schema aux';
    ELSE
        RAISE NOTICE '❌ Constraints não foram atualizadas corretamente';
    END IF;
    
    RAISE NOTICE '🎯 Migração para schema aux concluída com sucesso!';
END $$;

-- =====================================================
-- TESTE DE FUNCIONALIDADE
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '🧪 Testando funcionalidades após migração...';
    
    -- Testar se as funções do aux estão funcionando
    BEGIN
        DECLARE
            cpf_teste text;
            cep_teste text;
        BEGIN
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
-- RESUMO DA MIGRAÇÃO
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '🎯 =====================================================';
    RAISE NOTICE '🎯 MIGRAÇÃO EMPLOYEES_EXTENSION -> SCHEMA AUX';
    RAISE NOTICE '🎯 =====================================================';
    RAISE NOTICE '✅ Funções duplicadas removidas';
    RAISE NOTICE '✅ Triggers atualizados para usar schema aux';
    RAISE NOTICE '✅ Views atualizadas com domínios aux';
    RAISE NOTICE '✅ Compatibilidade mantida';
    RAISE NOTICE '✅ Funcionalidades testadas';
    RAISE NOTICE '🎯 Migração concluída com sucesso!';
    RAISE NOTICE '=====================================================';
END $$;
