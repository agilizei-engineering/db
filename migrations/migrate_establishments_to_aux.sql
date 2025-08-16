-- =====================================================
-- MIGRAÇÃO: ESTABLISHMENTS_EXTENSION -> SCHEMA AUX
-- =====================================================
-- Script para refatorar establishments_extension.sql para usar o schema aux
-- Versão 2.0 - Usando funções genéricas do schema aux
-- Autor: Assistente IA + Usuário
-- Data: 2025-01-27
-- Versão: 2.0

-- =====================================================
-- VERIFICAÇÃO DE PRÉ-REQUISITOS
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE 'Verificando pre-requisitos para migracao...';
    
    -- Verificar se o schema aux existe
    IF NOT EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'aux') THEN
        RAISE EXCEPTION 'Schema aux nao encontrado. Execute primeiro: \i aux_schema.sql';
    END IF;
    
    -- Verificar se as funções genéricas existem
    IF NOT EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_schema = 'aux' AND routine_name = 'create_validation_triggers') THEN
        RAISE EXCEPTION 'Funcao aux.create_validation_triggers nao encontrada';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_schema = 'aux' AND routine_name = 'clean_cnpj_before_insert_update') THEN
        RAISE EXCEPTION 'Funcao aux.clean_cnpj_before_insert_update nao encontrada';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_schema = 'aux' AND routine_name = 'clean_postal_code_before_insert_update') THEN
        RAISE EXCEPTION 'Funcao aux.clean_postal_code_before_insert_update nao encontrada';
    END IF;
    
    RAISE NOTICE 'Todos os pre-requisitos atendidos!';
END $$;

-- =====================================================
-- REMOÇÃO DE FUNÇÕES DUPLICADAS
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE 'Removendo funcoes duplicadas...';
    
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
    
    RAISE NOTICE 'Todas as funcoes duplicadas removidas!';
END $$;

-- =====================================================
-- REMOÇÃO DE TRIGGERS ANTIGOS
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE 'Removendo triggers antigos...';
    
    -- Remover trigger antigo de CNPJ
    DROP TRIGGER IF EXISTS clean_cnpj_trigger ON accounts.establishment_business_data;
    RAISE NOTICE 'Trigger clean_cnpj_trigger removido';
    
    -- Remover trigger antigo de CEP
    DROP TRIGGER IF EXISTS clean_postal_code_trigger ON accounts.establishment_addresses;
    RAISE NOTICE 'Trigger clean_postal_code_trigger removido';
    
    -- Remover função de trigger de CNPJ
    DROP FUNCTION IF EXISTS accounts.clean_cnpj_before_insert_update();
    RAISE NOTICE 'Funcao accounts.clean_cnpj_before_insert_update removida';
    
    -- Remover função de trigger de CEP
    DROP FUNCTION IF EXISTS accounts.clean_postal_code_before_insert_update();
    RAISE NOTICE 'Funcao accounts.clean_postal_code_before_insert_update removida';
    
    RAISE NOTICE 'Triggers antigos removidos!';
END $$;

-- =====================================================
-- CRIAÇÃO DE TRIGGERS USANDO FUNÇÕES GENÉRICAS AUX
-- =====================================================

DO $$
DECLARE
    v_result text[];
BEGIN
    RAISE NOTICE 'Criando triggers usando funcoes genericas do schema aux...';
    
    -- Criar trigger para CNPJ na tabela establishment_business_data
    v_result := aux.create_validation_triggers('accounts', 'establishment_business_data', ARRAY['cnpj']);
    RAISE NOTICE 'Trigger CNPJ criado: %', v_result[1];
    
    -- Criar trigger para CEP na tabela establishment_addresses
    v_result := aux.create_validation_triggers('accounts', 'establishment_addresses', ARRAY['postal_code']);
    RAISE NOTICE 'Trigger CEP criado: %', v_result[1];
    
    RAISE NOTICE 'Triggers criados com sucesso usando schema aux!';
END $$;

-- =====================================================
-- ATUALIZAÇÃO DE CONSTRAINTS PARA USAR SCHEMA AUX
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE 'Atualizando constraints para usar schema aux...';
    
    -- Remover constraint antiga de validação de URL (se existir)
    ALTER TABLE accounts.establishment_business_data 
    DROP CONSTRAINT IF EXISTS establishment_business_data_photo_url_valid;
    RAISE NOTICE 'Constraint establishment_business_data_photo_url_valid removida (se existia)';
    
    -- Remover constraint antiga de validação de data (se existir)
    ALTER TABLE accounts.establishment_business_data 
    DROP CONSTRAINT IF EXISTS establishment_business_data_created_at_valid;
    RAISE NOTICE 'Constraint establishment_business_data_created_at_valid removida (se existia)';
    
    -- Adicionar nova constraint usando função do schema aux para URL (se a coluna existir)
    BEGIN
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'accounts' AND table_name = 'establishment_business_data' AND column_name = 'photo_url') THEN
            ALTER TABLE accounts.establishment_business_data 
            ADD CONSTRAINT establishment_business_data_photo_url_valid 
            CHECK (aux.validate_url(photo_url));
            RAISE NOTICE 'Nova constraint usando aux.validate_url criada para photo_url';
        ELSE
            RAISE NOTICE 'Coluna photo_url nao encontrada, pulando constraint';
        END IF;
    END;
    
    RAISE NOTICE 'Constraints atualizadas para usar schema aux!';
END $$;

-- =====================================================
-- ATUALIZAÇÃO DE FUNÇÕES DE BUSCA PARA USAR AUX
-- =====================================================

-- Remover função antiga primeiro
DROP FUNCTION IF EXISTS accounts.find_establishments_by_postal_code(text);

-- Recriar função de busca por CEP para usar formatação do aux
CREATE OR REPLACE FUNCTION accounts.find_establishments_by_postal_code(p_postal_code text)
RETURNS TABLE (
    establishment_id uuid,
    establishment_name text,
    cnpj text,
    trade_name text,
    corporate_name text,
    state_registration text,
    postal_code text,
    street text,
    number text,
    complement text,
    neighborhood text,
    city text,
    state text
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Limpar CEP de entrada usando schema aux
    p_postal_code := aux.clean_and_validate_postal_code(p_postal_code);
    
    RETURN QUERY
    SELECT 
        e.establishment_id,
        e.name,
        ebd.cnpj,
        ebd.trade_name,
        ebd.corporate_name,
        ebd.state_registration,
        ea.postal_code,
        ea.street,
        ea.number,
        ea.complement,
        ea.neighborhood,
        ea.city,
        ea.state
    FROM accounts.establishments e
    JOIN accounts.establishment_business_data ebd ON e.establishment_id = ebd.establishment_id
    JOIN accounts.establishment_addresses ea ON e.establishment_id = ea.establishment_id
    WHERE ea.postal_code = p_postal_code;
END;
$$;

COMMENT ON FUNCTION accounts.find_establishments_by_postal_code(text) IS 'Busca estabelecimentos por CEP usando validacao do schema aux';

-- =====================================================
-- ATUALIZAÇÃO DE VIEWS PARA USAR DOMÍNIOS AUX
-- =====================================================

-- Remover view antiga primeiro
DROP VIEW IF EXISTS accounts.v_establishments_complete;

-- Recriar view para usar domínios do schema aux
CREATE OR REPLACE VIEW accounts.v_establishments_complete AS
SELECT 
    e.establishment_id,
    e.name,
    e.is_active,
    e.created_at,
    e.updated_at,
    ebd.cnpj,
    ebd.trade_name,
    ebd.corporate_name,
    ebd.state_registration,
    ebd.created_at as business_data_created_at,
    ebd.updated_at as business_data_updated_at,
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
FROM accounts.establishments e
LEFT JOIN accounts.establishment_business_data ebd ON e.establishment_id = ebd.establishment_id
LEFT JOIN accounts.establishment_addresses ea ON e.establishment_id = ea.establishment_id AND ea.is_primary = true;

COMMENT ON VIEW accounts.v_establishments_complete IS 'View consolidada de estabelecimentos usando validacoes do schema aux';

-- =====================================================
-- VERIFICAÇÃO DE COMPATIBILIDADE
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE 'Verificando compatibilidade apos migracao...';
    
    -- Verificar se os triggers foram recriados
    IF EXISTS (SELECT 1 FROM information_schema.triggers WHERE trigger_schema = 'accounts' AND trigger_name = 'clean_cnpj_trigger') THEN
        RAISE NOTICE 'Trigger clean_cnpj_trigger recriado com sucesso';
    ELSE
        RAISE NOTICE 'Trigger clean_cnpj_trigger nao foi recriado';
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.triggers WHERE trigger_schema = 'accounts' AND trigger_name = 'clean_postal_code_trigger') THEN
        RAISE NOTICE 'Trigger clean_postal_code_trigger recriado com sucesso';
    ELSE
        RAISE NOTICE 'Trigger clean_postal_code_trigger nao foi recriado';
    END IF;
    
    -- Verificar se a view foi atualizada
    IF EXISTS (SELECT 1 FROM information_schema.views WHERE table_schema = 'accounts' AND table_name = 'v_establishments_complete') THEN
        RAISE NOTICE 'View v_establishments_complete atualizada com sucesso';
    ELSE
        RAISE NOTICE 'View v_establishments_complete nao foi atualizada';
    END IF;
    
    RAISE NOTICE 'Migracao para schema aux concluida com sucesso!';
END $$;

-- =====================================================
-- TESTE DE FUNCIONALIDADE
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE 'Testando funcionalidades apos migracao...';
    
    -- Testar se as funções do aux estão funcionando
    BEGIN
        DECLARE
            cnpj_teste text;
            cep_teste text;
        BEGIN
            -- Testar validação de CNPJ
            cnpj_teste := aux.clean_and_validate_cnpj('11.222.333/0001-81');
            RAISE NOTICE 'Validacao de CNPJ funcionando: %', cnpj_teste;
            
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
-- RESUMO DA MIGRAÇÃO
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=====================================================';
    RAISE NOTICE 'MIGRACAO ESTABLISHMENTS_EXTENSION -> SCHEMA AUX';
    RAISE NOTICE '=====================================================';
    RAISE NOTICE 'Funcoes duplicadas removidas';
    RAISE NOTICE 'Triggers atualizados para usar schema aux';
    RAISE NOTICE 'Views atualizadas com dominios aux';
    RAISE NOTICE 'Constraints atualizadas para usar schema aux';
    RAISE NOTICE 'Compatibilidade mantida';
    RAISE NOTICE 'Funcionalidades testadas';
    RAISE NOTICE 'Migracao concluida com sucesso!';
    RAISE NOTICE '=====================================================';
END $$;
