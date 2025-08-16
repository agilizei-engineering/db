# 📊 SCHEMA: `audit` - SISTEMA AUTOMÁTICO DE AUDITORIA

## 🎯 VISÃO GERAL

O schema `audit` implementa um sistema completo e automático de auditoria para todas as tabelas do banco de dados. Ele captura automaticamente todas as operações INSERT, UPDATE e DELETE, mantendo um histórico completo de mudanças com particionamento eficiente por data.

---

## 🚀 FUNCIONALIDADES PRINCIPAIS

### **✅ Auditoria Automática**
- Captura todas as operações INSERT/UPDATE/DELETE automaticamente
- Não requer modificação no código da aplicação
- Funciona com qualquer tabela existente ou nova

### **📅 Particionamento por Data**
- Organização eficiente por ano/mês/dia
- Performance otimizada para consultas históricas
- Limpeza automática de dados antigos

### **🔄 Sincronização Automática**
- Detecta mudanças estruturais nas tabelas fonte
- Adiciona/modifica colunas automaticamente na auditoria
- Recria triggers e funções quando necessário

### **📊 Histórico Completo**
- Mantém todos os dados anteriores
- Rastreia quem fez o que e quando
- Informações de sessão e conexão

---

## 🔧 COMO USAR

### **1. Criar Auditoria para uma Tabela**

#### **Auditoria Básica**
```sql
-- Criar auditoria para uma tabela específica
SELECT audit.create_audit_table('accounts', 'users');

-- Resultado: Tabela audit.accounts__users criada com particionamento
```

#### **Verificar Auditoria Criada**
```sql
-- Verificar se a tabela de auditoria foi criada
SELECT 
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_schema = 'audit' 
AND table_name LIKE 'accounts__%';

-- Verificar estrutura da tabela de auditoria
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'audit' 
AND table_name = 'accounts__users'
ORDER BY ordinal_position;
```

### **2. Auditoria de Schemas Inteiros**

#### **Auditoria de Múltiplos Schemas**
```sql
-- Auditoria de múltiplos schemas de uma vez
SELECT audit.audit_schemas(ARRAY['accounts', 'catalogs', 'quotation']);

-- Resultado: Todas as tabelas dos schemas especificados serão auditadas
```

#### **Auditoria de um Schema Específico**
```sql
-- Auditoria de um schema específico
SELECT audit.audit_schema('accounts');

-- Resultado: Todas as tabelas do schema accounts serão auditadas
```

### **3. Sincronização Automática**

#### **Sincronizar Após Mudanças Estruturais**
```sql
-- Sincronizar auditoria após adicionar/modificar colunas
SELECT audit.sync_audit_table('accounts', 'users');

-- Resultado: Tabela de auditoria atualizada automaticamente
```

#### **Exemplo de Fluxo Completo**
```sql
-- 1. Adicionar nova coluna na tabela fonte
ALTER TABLE accounts.users ADD COLUMN phone_number text;

-- 2. Sincronizar auditoria automaticamente
SELECT audit.sync_audit_table('accounts', 'users');

-- 3. Verificar se a coluna foi adicionada na auditoria
SELECT column_name 
FROM information_schema.columns 
WHERE table_schema = 'audit' 
AND table_name = 'accounts__users' 
AND column_name = 'phone_number';
```

---

## 📊 CONSULTAS DE AUDITORIA

### **1. Histórico Básico**

#### **Todas as Operações de uma Tabela**
```sql
-- Histórico completo de uma tabela
SELECT 
    audit_timestamp,
    audit_operation,
    audit_user,
    audit_session_id,
    user_id,
    email,
    full_name
FROM audit.accounts__users 
ORDER BY audit_timestamp DESC;
```

#### **Operações de uma Data Específica**
```sql
-- Operações de hoje
SELECT 
    audit_timestamp,
    audit_operation,
    audit_user,
    user_id,
    email
FROM audit.accounts__users 
WHERE DATE(audit_timestamp) = CURRENT_DATE
ORDER BY audit_timestamp DESC;

-- Operações da última semana
SELECT 
    audit_timestamp,
    audit_operation,
    audit_user,
    user_id,
    email
FROM audit.accounts__users 
WHERE audit_timestamp >= CURRENT_DATE - INTERVAL '7 days'
ORDER BY audit_timestamp DESC;
```

### **2. Consultas por Tipo de Operação**

#### **Apenas Inserções**
```sql
-- Todas as inserções
SELECT 
    audit_timestamp,
    audit_user,
    user_id,
    email,
    full_name
FROM audit.accounts__users 
WHERE audit_operation = 'INSERT'
ORDER BY audit_timestamp DESC;
```

#### **Apenas Atualizações**
```sql
-- Todas as atualizações
SELECT 
    audit_timestamp,
    audit_user,
    user_id,
    email,
    full_name
FROM audit.accounts__users 
WHERE audit_operation = 'UPDATE'
ORDER BY audit_timestamp DESC;
```

#### **Apenas Exclusões**
```sql
-- Todas as exclusões
SELECT 
    audit_timestamp,
    audit_user,
    user_id,
    email,
    full_name
FROM audit.accounts__users 
WHERE audit_operation = 'DELETE'
ORDER BY audit_timestamp DESC;
```

### **3. Consultas por Usuário**

#### **Operações de um Usuário Específico**
```sql
-- Todas as operações de um usuário específico
SELECT 
    audit_timestamp,
    audit_operation,
    audit_user,
    audit_session_id,
    user_id,
    email,
    full_name
FROM audit.accounts__users 
WHERE user_id = 'uuid-do-usuario'
ORDER BY audit_timestamp DESC;
```

#### **Operações de um Usuário de Sistema**
```sql
-- Operações feitas por um usuário específico do sistema
SELECT 
    audit_timestamp,
    audit_operation,
    user_id,
    email,
    full_name
FROM audit.accounts__users 
WHERE audit_user = 'postgres'
ORDER BY audit_timestamp DESC;
```

### **4. Consultas por Sessão**

#### **Operações de uma Sessão**
```sql
-- Todas as operações de uma sessão específica
SELECT 
    audit_timestamp,
    audit_operation,
    audit_user,
    user_id,
    email,
    full_name
FROM audit.accounts__users 
WHERE audit_session_id = 'sessao-especifica'
ORDER BY audit_timestamp DESC;
```

#### **Operações por IP**
```sql
-- Operações de um endereço IP específico
SELECT 
    audit_timestamp,
    audit_operation,
    audit_user,
    user_id,
    email,
    full_name
FROM audit.accounts__users 
WHERE audit_connection_id = '192.168.1.100'
ORDER BY audit_timestamp DESC;
```

### **5. Relatórios e Estatísticas**

#### **Resumo de Operações por Usuário**
```sql
-- Resumo de operações por usuário do sistema
SELECT 
    audit_user,
    audit_operation,
    COUNT(*) as total_operacoes,
    MIN(audit_timestamp) as primeira_operacao,
    MAX(audit_timestamp) as ultima_operacao
FROM audit.accounts__users 
WHERE audit_timestamp >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY audit_user, audit_operation
ORDER BY audit_user, total_operacoes DESC;
```

#### **Resumo de Operações por Tabela**
```sql
-- Resumo de operações por tabela auditada
SELECT 
    'accounts__users' as tabela_auditoria,
    audit_operation,
    COUNT(*) as total_operacoes,
    COUNT(DISTINCT audit_user) as usuarios_diferentes,
    COUNT(DISTINCT DATE(audit_timestamp)) as dias_com_operacoes
FROM audit.accounts__users 
WHERE audit_timestamp >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY audit_operation
ORDER BY total_operacoes DESC;
```

#### **Atividade por Período**
```sql
-- Atividade por hora do dia
SELECT 
    EXTRACT(HOUR FROM audit_timestamp) as hora,
    COUNT(*) as total_operacoes,
    COUNT(DISTINCT audit_user) as usuarios_ativos
FROM audit.accounts__users 
WHERE audit_timestamp >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY EXTRACT(HOUR FROM audit_timestamp)
ORDER BY hora;
```

---

## 🔍 CONSULTAS AVANÇADAS

### **1. Comparação de Valores (Antes/Depois)**

#### **Mudanças em Campos Específicos**
```sql
-- Verificar mudanças no campo email
SELECT 
    audit_timestamp,
    audit_user,
    user_id,
    email,
    audit_operation
FROM audit.accounts__users 
WHERE audit_operation = 'UPDATE'
  AND email IS NOT NULL
ORDER BY audit_timestamp DESC;
```

#### **Histórico de Mudanças de Status**
```sql
-- Histórico de mudanças no campo is_active
SELECT 
    audit_timestamp,
    audit_user,
    user_id,
    email,
    is_active,
    audit_operation
FROM audit.accounts__users 
WHERE audit_operation = 'UPDATE'
  AND is_active IS NOT NULL
ORDER BY user_id, audit_timestamp DESC;
```

### **2. Análise de Padrões**

#### **Usuários Mais Ativos**
```sql
-- Top 10 usuários que mais alteraram dados
SELECT 
    audit_user,
    COUNT(*) as total_alteracoes,
    COUNT(DISTINCT DATE(audit_timestamp)) as dias_ativos,
    MIN(audit_timestamp) as primeira_operacao,
    MAX(audit_timestamp) as ultima_operacao
FROM audit.accounts__users 
WHERE audit_timestamp >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY audit_user
ORDER BY total_alteracoes DESC
LIMIT 10;
```

#### **Horários de Pico de Atividade**
```sql
-- Horários com mais atividade
SELECT 
    EXTRACT(HOUR FROM audit_timestamp) as hora,
    audit_operation,
    COUNT(*) as total_operacoes
FROM audit.accounts__users 
WHERE audit_timestamp >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY EXTRACT(HOUR FROM audit_timestamp), audit_operation
ORDER BY total_operacoes DESC;
```

### **3. Auditoria de Segurança**

#### **Operações Suspeitas**
```sql
-- Múltiplas operações em um curto período
SELECT 
    audit_user,
    user_id,
    COUNT(*) as operacoes_rapidas,
    MIN(audit_timestamp) as inicio,
    MAX(audit_timestamp) as fim,
    EXTRACT(EPOCH FROM (MAX(audit_timestamp) - MIN(audit_timestamp))) as segundos
FROM audit.accounts__users 
WHERE audit_timestamp >= CURRENT_DATE - INTERVAL '1 day'
GROUP BY audit_user, user_id
HAVING COUNT(*) > 10 
   AND EXTRACT(EPOCH FROM (MAX(audit_timestamp) - MIN(audit_timestamp))) < 60
ORDER BY operacoes_rapidas DESC;
```

#### **Acesso de IPs Diferentes**
```sql
-- Usuários acessando de IPs diferentes
SELECT 
    audit_user,
    COUNT(DISTINCT audit_connection_id) as ips_diferentes,
    array_agg(DISTINCT audit_connection_id) as lista_ips
FROM audit.accounts__users 
WHERE audit_timestamp >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY audit_user
HAVING COUNT(DISTINCT audit_connection_id) > 1
ORDER BY ips_diferentes DESC;
```

---

## 📅 PARTICIONAMENTO E PERFORMANCE

### **1. Estrutura de Partições**

#### **Verificar Partições Existentes**
```sql
-- Listar todas as partições de uma tabela de auditoria
SELECT 
    schemaname,
    tablename,
    partitionname,
    partitionrangestart,
    partitionrangeend
FROM pg_partitions 
WHERE tablename = 'accounts__users'
ORDER BY partitionrangestart;
```

#### **Consultar Partição Específica**
```sql
-- Consultar dados de uma partição específica (mais rápido)
SELECT 
    audit_timestamp,
    audit_operation,
    audit_user,
    user_id,
    email
FROM audit.accounts__users_2025_08  -- Partição de agosto/2025
WHERE audit_timestamp >= '2025-08-15'
ORDER BY audit_timestamp DESC;
```

### **2. Otimização de Consultas**

#### **Consultas por Período**
```sql
-- Consulta otimizada para um período específico
SELECT 
    audit_timestamp,
    audit_operation,
    audit_user,
    user_id,
    email
FROM audit.accounts__users 
WHERE audit_partition_date >= CURRENT_DATE - INTERVAL '30 days'
  AND audit_timestamp >= CURRENT_DATE - INTERVAL '30 days'
ORDER BY audit_timestamp DESC;
```

#### **Índices Recomendados**
```sql
-- Verificar índices existentes
SELECT 
    indexname,
    indexdef
FROM pg_indexes 
WHERE tablename = 'accounts__users'
ORDER BY indexname;

-- Criar índices adicionais se necessário
CREATE INDEX CONCURRENTLY idx_audit_users_operation_date 
ON audit.accounts__users(audit_operation, audit_partition_date);

CREATE INDEX CONCURRENTLY idx_audit_users_user_timestamp 
ON audit.accounts__users(user_id, audit_timestamp);
```

---

## 🔧 MANUTENÇÃO E LIMPEZA

### **1. Verificar Status das Tabelas de Auditoria**

#### **Listar Todas as Tabelas Auditadas**
```sql
-- Listar todas as tabelas de auditoria
SELECT 
    table_schema,
    table_name,
    REPLACE(table_name, '__', '.') as tabela_original
FROM information_schema.tables 
WHERE table_schema = 'audit' 
  AND table_name LIKE '%__%'
ORDER BY table_name;
```

#### **Verificar Triggers de Auditoria**
```sql
-- Verificar se os triggers de auditoria estão ativos
SELECT 
    trigger_schema,
    trigger_name,
    event_object_table,
    action_statement,
    event_manipulation,
    action_timing
FROM information_schema.triggers 
WHERE trigger_name LIKE '%audit%'
ORDER BY event_object_table, trigger_name;
```

### **2. Limpeza de Dados Antigos**

#### **Identificar Dados Antigos**
```sql
-- Identificar partições com dados muito antigos
SELECT 
    schemaname,
    tablename,
    partitionname,
    partitionrangestart,
    partitionrangeend,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||partitionname)) as tamanho
FROM pg_partitions 
WHERE tablename LIKE '%__%'
  AND partitionrangestart < CURRENT_DATE - INTERVAL '2 years'
ORDER BY partitionrangestart;
```

#### **Remover Partições Antigas**
```sql
-- Remover partição antiga (apenas se necessário)
-- ATENÇÃO: Esta operação remove dados permanentemente
DROP TABLE IF EXISTS audit.accounts__users_2020_01;
```

### **3. Monitoramento de Performance**

#### **Verificar Tamanho das Tabelas**
```sql
-- Verificar tamanho das tabelas de auditoria
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as tamanho_total,
    pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) as tamanho_tabela,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename) - pg_relation_size(schemaname||'.'||tablename)) as tamanho_indices
FROM pg_tables 
WHERE schemaname = 'audit'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

#### **Verificar Estatísticas**
```sql
-- Verificar estatísticas das tabelas de auditoria
SELECT 
    schemaname,
    tablename,
    n_tup_ins as total_inserts,
    n_tup_upd as total_updates,
    n_tup_del as total_deletes,
    last_vacuum,
    last_analyze
FROM pg_stat_user_tables 
WHERE schemaname = 'audit'
ORDER BY n_tup_ins + n_tup_upd + n_tup_del DESC;
```

---

## 🚀 EXEMPLOS PRÁTICOS COMPLETOS

### **Exemplo 1: Auditoria Completa de uma Nova Tabela**

```sql
-- 1. Criar nova tabela
CREATE TABLE minha_tabela (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    nome text NOT NULL,
    email text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone
);

-- 2. Criar auditoria automaticamente
SELECT audit.create_audit_table('public', 'minha_tabela');

-- 3. Verificar se foi criada
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'audit' AND table_name = 'public__minha_tabela';

-- 4. Inserir dados de teste
INSERT INTO minha_tabela (nome, email) VALUES 
('João Silva', 'joao@exemplo.com'),
('Maria Santos', 'maria@exemplo.com');

-- 5. Atualizar dados
UPDATE minha_tabela SET nome = 'João da Silva' WHERE email = 'joao@exemplo.com';

-- 6. Verificar auditoria
SELECT 
    audit_timestamp,
    audit_operation,
    audit_user,
    nome,
    email
FROM audit.public__minha_tabela 
ORDER BY audit_timestamp DESC;
```

### **Exemplo 2: Relatório de Atividade Diária**

```sql
-- Relatório de atividade do dia
WITH atividade_diaria AS (
    SELECT 
        audit_operation,
        audit_user,
        COUNT(*) as total_operacoes,
        MIN(audit_timestamp) as primeira_operacao,
        MAX(audit_timestamp) as ultima_operacao
    FROM audit.accounts__users 
    WHERE DATE(audit_timestamp) = CURRENT_DATE
    GROUP BY audit_operation, audit_user
)
SELECT 
    audit_operation,
    audit_user,
    total_operacoes,
    primeira_operacao,
    ultima_operacao,
    EXTRACT(EPOCH FROM (ultima_operacao - primeira_operacao)) / 3600 as horas_ativo
FROM atividade_diaria
ORDER BY total_operacoes DESC;
```

### **Exemplo 3: Detecção de Anomalias**

```sql
-- Detectar usuários com atividade anormal
SELECT 
    audit_user,
    COUNT(*) as total_operacoes,
    COUNT(DISTINCT DATE(audit_timestamp)) as dias_ativos,
    COUNT(*) / COUNT(DISTINCT DATE(audit_timestamp)) as operacoes_por_dia,
    CASE 
        WHEN COUNT(*) / COUNT(DISTINCT DATE(audit_timestamp)) > 100 THEN 'ATIVIDADE ALTA'
        WHEN COUNT(*) / COUNT(DISTINCT DATE(audit_timestamp)) > 50 THEN 'ATIVIDADE MODERADA'
        ELSE 'ATIVIDADE NORMAL'
    END as nivel_atividade
FROM audit.accounts__users 
WHERE audit_timestamp >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY audit_user
HAVING COUNT(DISTINCT DATE(audit_timestamp)) > 0
ORDER BY operacoes_por_dia DESC;
```

---

## ⚠️ IMPORTANTE: BOAS PRÁTICAS

### **1. Sempre Crie Auditoria para Novas Tabelas**
```sql
-- ✅ CORRETO: Criar auditoria automaticamente
SELECT audit.create_audit_table('meu_schema', 'minha_tabela');

-- ❌ INCORRETO: Não criar auditoria
-- Perde histórico de mudanças
```

### **2. Sincronize Auditoria Após Mudanças Estruturais**
```sql
-- ✅ CORRETO: Sincronizar após alterações
ALTER TABLE minha_tabela ADD COLUMN nova_coluna text;
SELECT audit.sync_audit_table('meu_schema', 'minha_tabela');

-- ❌ INCORRETO: Não sincronizar
-- Auditoria pode ficar desatualizada
```

### **3. Use Partições para Consultas Históricas**
```sql
-- ✅ CORRETO: Consultar partição específica
SELECT * FROM audit.accounts__users_2025_08 WHERE audit_timestamp >= '2025-08-15';

-- ❌ INCORRETO: Consultar tabela principal para dados antigos
SELECT * FROM audit.accounts__users WHERE audit_timestamp >= '2025-08-15';
```

### **4. Monitore Regularmente o Tamanho**
```sql
-- ✅ CORRETO: Verificar tamanho regularmente
SELECT pg_size_pretty(pg_total_relation_size('audit.accounts__users'));

-- ❌ INCORRETO: Ignorar crescimento da auditoria
-- Pode impactar performance
```

---

## 🆘 SOLUÇÃO DE PROBLEMAS

### **Problema: Auditoria não está funcionando**
```sql
-- 1. Verificar se a tabela de auditoria existe
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'audit' AND table_name = 'schema__tabela';

-- 2. Verificar se o trigger existe
SELECT trigger_name FROM information_schema.triggers 
WHERE event_object_table = 'tabela';

-- 3. Recriar auditoria se necessário
SELECT audit.create_audit_table('schema', 'tabela');
```

### **Problema: Colunas não sincronizadas**
```sql
-- 1. Verificar colunas da tabela fonte
SELECT column_name FROM information_schema.columns 
WHERE table_schema = 'schema' AND table_name = 'tabela';

-- 2. Verificar colunas da auditoria
SELECT column_name FROM information_schema.columns 
WHERE table_schema = 'audit' AND table_name = 'schema__tabela';

-- 3. Sincronizar automaticamente
SELECT audit.sync_audit_table('schema', 'tabela');
```

### **Problema: Performance lenta**
```sql
-- 1. Verificar índices
SELECT indexname FROM pg_indexes WHERE tablename = 'schema__tabela';

-- 2. Verificar tamanho
SELECT pg_size_pretty(pg_total_relation_size('audit.schema__tabela'));

-- 3. Verificar partições
SELECT partitionname FROM pg_partitions WHERE tablename = 'schema__tabela';
```

---

## 📚 RECURSOS ADICIONAIS

- **README_SCHEMAS.md** - Documentação geral de todos os schemas
- **audit_system.sql** - Script de criação do sistema de auditoria
- **test_*.sql** - Scripts de teste para validação

---

**🎯 Lembre-se: O sistema de auditoria é automático, mas requer monitoramento regular para garantir performance e funcionalidade!**
