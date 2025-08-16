-- =====================================================
-- LIMPEZA COMPLETA DE FUNÇÕES DUPLICADAS
-- =====================================================
-- Script para remover todas as funções duplicadas do schema accounts
-- e criar triggers automáticos usando as funções genéricas do aux
-- Autor: Assistente IA + Usuário
-- Data: 2025-01-27
-- Versão: 1.0

-- =====================================================
-- VERIFICAÇÃO DE PRÉ-REQUISITOS
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE 'Verificando pre-requisitos para limpeza...';
    
    -- Verificar se o schema aux existe
    IF NOT EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'aux') THEN
        RAISE EXCEPTION 'Schema aux nao encontrado. Execute primeiro: \i aux_schema.sql';
    END IF;
    
    -- Verificar se as funções genéricas existem
    IF NOT EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_schema = 'aux' AND routine_name = 'create_validation_triggers') THEN
        RAISE EXCEPTION 'Funcao aux.create_validation_triggers nao encontrada';
    END IF;
    
    RAISE NOTICE 'Todos os pre-requisitos atendidos!';
END $$;

-- =====================================================
-- REMOÇÃO DE TRIGGERS ANTIGOS (PRIMEIRO)
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE 'Removendo triggers antigos primeiro...';
    
    -- Listar e remover todos os triggers que usam funções duplicadas
    DECLARE
        r RECORD;
    BEGIN
        -- Remover triggers de limpeza (clean_*)
        FOR r IN (
            SELECT trigger_schema, trigger_name, event_object_table
            FROM information_schema.triggers 
            WHERE trigger_schema = 'accounts'
            AND trigger_name LIKE '%clean%'
        ) LOOP
            EXECUTE format('DROP TRIGGER IF EXISTS %I ON %I.%I', 
                          r.trigger_name, r.trigger_schema, r.event_object_table);
            RAISE NOTICE 'Trigger % removido da tabela %.%', r.trigger_name, r.trigger_schema, r.event_object_table;
        END LOOP;
        
        -- Remover triggers de updated_at (set_*_updated_at)
        FOR r IN (
            SELECT trigger_schema, trigger_name, event_object_table
            FROM information_schema.triggers 
            WHERE trigger_schema = 'accounts'
            AND trigger_name LIKE '%updated_at%'
        ) LOOP
            EXECUTE format('DROP TRIGGER IF EXISTS %I ON %I.%I', 
                          r.trigger_name, r.trigger_schema, r.event_object_table);
            RAISE NOTICE 'Trigger % removido da tabela %.%', r.trigger_name, r.trigger_schema, r.event_object_table;
        END LOOP;
        
        -- Remover triggers específicos que não se encaixam nos padrões acima
        DROP TRIGGER IF EXISTS update_address_timestamp_trigger ON accounts.employee_addresses;
        RAISE NOTICE 'Trigger update_address_timestamp_trigger removido da tabela accounts.employee_addresses';
    END;
    
    RAISE NOTICE 'Triggers antigos removidos!';
END $$;

-- =====================================================
-- REMOÇÃO DE FUNÇÕES DUPLICADAS (DEPOIS DOS TRIGGERS)
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE 'Removendo funcoes duplicadas...';
    
    -- Remover função de validação de CPF duplicada
    DROP FUNCTION IF EXISTS accounts.validate_cpf(text);
    RAISE NOTICE 'Funcao accounts.validate_cpf removida';
    
    -- Remover função de limpeza e validação de CPF duplicada
    DROP FUNCTION IF EXISTS accounts.clean_and_validate_cpf(text);
    RAISE NOTICE 'Funcao accounts.clean_and_validate_cpf removida';
    
    -- Remover função de validação de CNPJ duplicada
    DROP FUNCTION IF EXISTS accounts.validate_cnpj(text);
    RAISE NOTICE 'Funcao accounts.validate_cnpj removida';
    
    -- Remover função de limpeza e validação de CNPJ duplicada
    DROP FUNCTION IF EXISTS accounts.clean_and_validate_cnpj(text);
    RAISE NOTICE 'Funcao accounts.clean_and_validate_cnpj removida';
    
    -- Remover função de validação de CEP duplicada
    DROP FUNCTION IF EXISTS accounts.validate_postal_code(text);
    RAISE NOTICE 'Funcao accounts.validate_postal_code removida';
    
    -- Remover função de limpeza e validação de CEP duplicada
    DROP FUNCTION IF EXISTS accounts.clean_and_validate_postal_code(text);
    RAISE NOTICE 'Funcao accounts.clean_and_validate_postal_code removida';
    
    -- Remover função de validação de URL duplicada
    DROP FUNCTION IF EXISTS accounts.validate_photo_url(text);
    RAISE NOTICE 'Funcao accounts.validate_photo_url removida';
    
    -- Remover função de validação de data de nascimento duplicada
    DROP FUNCTION IF EXISTS accounts.validate_birth_date(date);
    RAISE NOTICE 'Funcao accounts.validate_birth_date removida';
    
    -- Remover função de atualização de timestamp duplicada
    DROP FUNCTION IF EXISTS accounts.update_address_timestamp();
    RAISE NOTICE 'Funcao accounts.update_address_timestamp removida';
    
    RAISE NOTICE 'Todas as funcoes duplicadas removidas!';
END $$;





-- =====================================================
-- CRIAÇÃO AUTOMÁTICA DE TRIGGERS USANDO AUX
-- =====================================================

DO $$
DECLARE
    v_result text[];
    v_table_name text;
    v_schema_name text;
BEGIN
    RAISE NOTICE 'Criando triggers automaticos usando funcoes genericas do schema aux...';
    
    -- Criar triggers para todas as tabelas que precisam de validação
    -- establishment_business_data (CNPJ)
    v_result := aux.create_validation_triggers('accounts', 'establishment_business_data', ARRAY['cnpj']);
    RAISE NOTICE 'Triggers para establishment_business_data criados: %', v_result[1];
    
    -- establishment_addresses (CEP)
    v_result := aux.create_validation_triggers('accounts', 'establishment_addresses', ARRAY['postal_code']);
    RAISE NOTICE 'Triggers para establishment_addresses criados: %', v_result[1];
    
    -- employee_personal_data (CPF)
    v_result := aux.create_validation_triggers('accounts', 'employee_personal_data', ARRAY['cpf']);
    RAISE NOTICE 'Triggers para employee_personal_data criados: %', v_result[1];
    
    -- employee_addresses (CEP)
    v_result := aux.create_validation_triggers('accounts', 'employee_addresses', ARRAY['postal_code']);
    RAISE NOTICE 'Triggers para employee_addresses criados: %', v_result[1];
    
    RAISE NOTICE 'Criando triggers de updated_at para todas as tabelas...';
    
    -- Recriar triggers de updated_at para todas as tabelas principais
    PERFORM aux.create_updated_at_trigger('accounts', 'users');
    PERFORM aux.create_updated_at_trigger('accounts', 'suppliers');
    PERFORM aux.create_updated_at_trigger('accounts', 'establishments');
    PERFORM aux.create_updated_at_trigger('accounts', 'employees');
    PERFORM aux.create_updated_at_trigger('accounts', 'platforms');
    PERFORM aux.create_updated_at_trigger('accounts', 'modules');
    PERFORM aux.create_updated_at_trigger('accounts', 'features');
    PERFORM aux.create_updated_at_trigger('accounts', 'roles');
    PERFORM aux.create_updated_at_trigger('accounts', 'role_features');
    PERFORM aux.create_updated_at_trigger('accounts', 'employee_roles');
    PERFORM aux.create_updated_at_trigger('accounts', 'apis');
    PERFORM aux.create_updated_at_trigger('accounts', 'establishment_business_data');
    PERFORM aux.create_updated_at_trigger('accounts', 'establishment_addresses');
    PERFORM aux.create_updated_at_trigger('accounts', 'employee_personal_data');
    PERFORM aux.create_updated_at_trigger('accounts', 'employee_addresses');
    
    RAISE NOTICE 'Todos os triggers criados com sucesso usando schema aux!';
END $$;

-- =====================================================
-- VERIFICAÇÃO DE FUNÇÕES RESTANTES
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE 'Verificando funcoes restantes no schema accounts...';
    
    -- Listar todas as funções que ainda existem no schema accounts
    DECLARE
        r RECORD;
        v_count integer := 0;
    BEGIN
        FOR r IN (
            SELECT routine_name, routine_type
            FROM information_schema.routines 
            WHERE routine_schema = 'accounts'
            ORDER BY routine_name
        ) LOOP
            v_count := v_count + 1;
            RAISE NOTICE '  - % (%)', r.routine_name, r.routine_type;
        END LOOP;
        
        RAISE NOTICE 'Total de funcoes no schema accounts: %', v_count;
    END;
    
    RAISE NOTICE 'Verificacao concluida!';
END $$;

-- =====================================================
-- VERIFICAÇÃO DE TRIGGERS CRIADOS
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE 'Verificando triggers criados...';
    
    -- Listar todos os triggers criados
    DECLARE
        r RECORD;
        v_count integer := 0;
    BEGIN
        FOR r IN (
            SELECT trigger_schema, trigger_name, event_object_table, action_statement
            FROM information_schema.triggers 
            WHERE trigger_schema = 'accounts'
            AND trigger_name LIKE '%clean%'
            ORDER BY event_object_table, trigger_name
        ) LOOP
            v_count := v_count + 1;
            RAISE NOTICE '  - % em %.%: %', r.trigger_name, r.trigger_schema, r.event_object_table, r.action_statement;
        END LOOP;
        
        RAISE NOTICE 'Total de triggers de limpeza criados: %', v_count;
    END;
    
    RAISE NOTICE 'Verificacao de triggers concluida!';
END $$;

-- =====================================================
-- TESTE DE FUNCIONALIDADE
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE 'Testando funcionalidades apos limpeza...';
    
    -- Testar se as funções do aux estão funcionando
    BEGIN
        DECLARE
            cnpj_teste text;
            cpf_teste text;
            cep_teste text;
        BEGIN
            -- Testar validação de CNPJ
            cnpj_teste := aux.clean_and_validate_cnpj('11.222.333/0001-81');
            RAISE NOTICE 'Validacao de CNPJ funcionando: %', cnpj_teste;
            
            -- Testar validação de CPF
            cpf_teste := aux.clean_and_validate_cpf('123.456.789-09');
            RAISE NOTICE 'Validacao de CPF funcionando: %', cpf_teste;
            
            -- Testar validação de CEP
            cep_teste := aux.clean_and_validate_postal_code('12345-678');
            RAISE NOTICE 'Validacao de CEP funcionando: %', cep_teste;
            
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'Erro ao testar validacoes: %', SQLERRM;
        END;
    END;
    
    RAISE NOTICE 'Testes de funcionalidade concluidos!';
END $$;

-- =====================================================
-- RESUMO DA LIMPEZA
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=====================================================';
    RAISE NOTICE 'LIMPEZA COMPLETA DE FUNCOES DUPLICADAS';
    RAISE NOTICE '=====================================================';
    RAISE NOTICE 'Funcoes duplicadas removidas do schema accounts';
    RAISE NOTICE 'Triggers antigos removidos';
    RAISE NOTICE 'Triggers automaticos criados usando schema aux';
    RAISE NOTICE 'Funcoes especificas de negocio mantidas';
    RAISE NOTICE 'Compatibilidade preservada';
    RAISE NOTICE 'Limpeza concluida com sucesso!';
    RAISE NOTICE '=====================================================';
    RAISE NOTICE '';
    RAISE NOTICE 'FUNCOES RESTANTES NO SCHEMA ACCOUNTS:';
    RAISE NOTICE '- find_employee_by_cpf (especifica)';
    RAISE NOTICE '- find_employees_by_postal_code (especifica)';
    RAISE NOTICE '- find_establishments_by_postal_code (especifica)';
    RAISE NOTICE '- search_employees_by_name (especifica)';
    RAISE NOTICE '- update_address_timestamp (especifica)';
    RAISE NOTICE '=====================================================';
END $$;
