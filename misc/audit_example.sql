-- =====================================================
-- EXEMPLO DE USO DO SISTEMA DE AUDITORIA
-- =====================================================
-- Este script demonstra como usar o sistema de auditoria criado

-- =====================================================
-- 1. INSTALAÇÃO DO SISTEMA DE AUDITORIA
-- =====================================================

-- Primeiro, execute o script audit_system.sql para criar o sistema
-- \i audit_system.sql

-- =====================================================
-- 2. AUDITORIA DE SCHEMAS COMPLETOS
-- =====================================================

-- Para auditar os schemas accounts e catalogs de uma vez:
SELECT audit.audit_schemas(ARRAY['accounts', 'catalogs']);

-- Para auditar apenas um schema:
-- SELECT audit.audit_schema('accounts');

-- =====================================================
-- 3. AUDITORIA DE TABELA ESPECÍFICA
-- =====================================================

-- Para auditar uma tabela específica:
-- SELECT audit.create_audit_table('accounts', 'users');

-- =====================================================
-- 4. VERIFICAÇÃO DO QUE FOI CRIADO
-- =====================================================

-- Lista todas as tabelas de auditoria criadas:
SELECT 
    table_name,
    table_type,
    is_insertable_into,
    is_typed
FROM information_schema.tables 
WHERE table_schema = 'audit' 
ORDER BY table_name;

-- Lista as colunas de uma tabela de auditoria específica:
-- SELECT 
--     column_name,
--     data_type,
--     is_nullable,
--     column_default
-- FROM information_schema.columns 
-- WHERE table_schema = 'audit' 
-- AND table_name = 'accounts__users'
-- ORDER BY ordinal_position;

-- =====================================================
-- 5. TESTE DO SISTEMA DE AUDITORIA
-- =====================================================

-- Exemplo: Inserir um registro na tabela original
-- INSERT INTO accounts.establishment_business_data (establishment_id, cnpj, trade_name, corporate_name)
-- VALUES (gen_random_uuid(), '12345678000190', 'Empresa Teste', 'Empresa Teste LTDA');

-- Verificar se foi auditado:
-- SELECT 
--     audit_operation,
--     audit_timestamp,
--     audit_user,
--     trade_name,
--     cnpj
-- FROM audit.accounts__establishment_business_data
-- ORDER BY audit_timestamp DESC
-- LIMIT 5;

-- =====================================================
-- 6. CONSULTAS DE AUDITORIA ÚTEIS
-- =====================================================

-- Histórico de operações por usuário:
-- SELECT 
--     audit_user,
--     audit_operation,
--     COUNT(*) as total_operations
-- FROM audit.accounts__establishment_business_data
-- GROUP BY audit_user, audit_operation
-- ORDER BY audit_user, audit_operation;

-- Histórico de operações por período:
-- SELECT 
--     DATE(audit_timestamp) as data,
--     audit_operation,
--     COUNT(*) as total_operations
-- FROM audit.accounts__establishment_business_data
-- WHERE audit_timestamp >= current_date - interval '7 days'
-- GROUP BY DATE(audit_timestamp), audit_operation
-- ORDER BY data DESC, audit_operation;

-- Últimas alterações em um registro específico:
-- SELECT 
--     audit_timestamp,
--     audit_operation,
--     audit_user,
--     trade_name,
--     cnpj
-- FROM audit.accounts__establishment_business_data
-- WHERE cnpj = '12345678000190'
-- ORDER BY audit_timestamp DESC;

-- =====================================================
-- 7. MANUTENÇÃO DO SISTEMA
-- =====================================================

-- Para adicionar auditoria a um novo schema:
-- SELECT audit.audit_schema('novo_schema');

-- Para adicionar auditoria a uma nova tabela:
-- SELECT audit.create_audit_table('accounts', 'nova_tabela');

-- =====================================================
-- 8. REMOÇÃO DE AUDITORIA (SE NECESSÁRIO)
-- =====================================================

-- Para remover auditoria de uma tabela específica:
-- DROP TRIGGER IF EXISTS trg_audit_accounts_users ON accounts.users;
-- DROP FUNCTION IF EXISTS audit.audit_accounts_users_trigger();
-- DROP TABLE IF EXISTS audit.accounts__users;

-- Para remover todo o sistema de auditoria:
-- DROP SCHEMA IF EXISTS audit CASCADE;

-- =====================================================
-- 9. CONFIGURAÇÕES AVANÇADAS
-- =====================================================

-- Para configurar particionamento manual:
-- CREATE TABLE audit.accounts__users_2024_01 PARTITION OF audit.accounts__users
-- FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');

-- Para configurar retenção de dados (exemplo: manter apenas 2 anos):
-- DELETE FROM audit.accounts__users 
-- WHERE audit_timestamp < current_date - interval '2 years';

-- =====================================================
-- 10. MONITORAMENTO DE PERFORMANCE
-- =====================================================

-- Verificar tamanho das tabelas de auditoria:
-- SELECT 
--     schemaname,
--     tablename,
--     pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
-- FROM pg_tables 
-- WHERE schemaname = 'audit'
-- ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Verificar estatísticas de uso:
-- SELECT 
--     schemaname,
--     tablename,
--     n_tup_ins as inserts,
--     n_tup_upd as updates,
--     n_tup_del as deletes
-- FROM pg_stat_user_tables 
-- WHERE schemaname = 'audit'
-- ORDER BY n_tup_ins + n_tup_upd + n_tup_del DESC;

-- =====================================================
-- RESUMO DE COMANDOS PRINCIPAIS
-- =====================================================

/*
1. INSTALAR: Execute audit_system.sql
2. AUDITAR SCHEMAS: SELECT audit.audit_schemas(ARRAY['accounts', 'catalogs']);
3. AUDITAR TABELA: SELECT audit.create_audit_table('schema', 'tabela');
4. VERIFICAR: SELECT * FROM information_schema.tables WHERE table_schema = 'audit';
5. TESTAR: Faça operações nas tabelas originais e verifique as tabelas de auditoria
6. MANTER: Execute periodicamente para novas tabelas/schemas

NOTA: As tabelas de auditoria seguem o padrão schema__tabela (ex: accounts__users, catalogs__products)
*/
