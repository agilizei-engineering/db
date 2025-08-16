# 🔐 SCHEMA: `sessions` - CONTROLE DE SESSÕES

## 🎯 VISÃO GERAL

O schema `sessions` implementa um sistema robusto de controle de sessões ativas para autenticação multi-persona. Ele permite que um usuário tenha múltiplas sessões ativas simultaneamente, cada uma vinculada a um papel específico em um estabelecimento, proporcionando flexibilidade e segurança no controle de acesso.

---

## 📋 TABELAS PRINCIPAIS

### **🔑 Sessões de Usuário**

#### **`user_sessions`** - Sessões Ativas dos Usuários
- **Descrição**: Controle de todas as sessões ativas dos usuários
- **Campos principais**: 
  - `session_id` - ID único da sessão
  - `employee_id` - Funcionário vinculado à sessão
  - `current_session_id` - ID da sessão atual
  - `session_expires_at` - Data/hora de expiração
  - `refresh_token_hash` - Hash do token de refresh
  - `access_token_hash` - Hash do token de acesso
  - `ip_address` - Endereço IP da conexão
  - `user_agent` - User agent do navegador
  - `is_active` - Status ativo da sessão
  - `created_at` - Data/hora de criação
  - `updated_at` - Data/hora da última atualização

- **Funcionalidades**: 
  - Controle de múltiplas sessões por usuário
  - Expiração automática de sessões
  - Rastreamento de IP e user agent
  - Controle de status ativo/inativo

- **Relacionamentos**: Foreign key para `accounts.employees.employee_id`
- **Auditoria**: Automática via schema `audit`

---

## 🔍 FUNCIONALIDADES PRINCIPAIS

### **Sistema Multi-Persona**
- **Múltiplas Sessões**: Um usuário pode ter várias sessões ativas simultaneamente
- **Diferentes Papéis**: Cada sessão pode representar um papel diferente em estabelecimentos diferentes
- **Controle Granular**: Controle independente de cada sessão

### **Controle de Sessão**
- **Expiração Automática**: Sessões expiram automaticamente no tempo definido
- **Tokens Seguros**: Hash dos tokens de acesso e refresh para segurança
- **Rastreamento**: IP e user agent são registrados para auditoria

### **Segurança e Auditoria**
- **Hash de Tokens**: Tokens são armazenados como hash para segurança
- **Rastreamento de IP**: Monitoramento de endereços IP de acesso
- **User Agent**: Identificação do dispositivo/navegador
- **Auditoria Completa**: Todas as operações são auditadas

---

## 📊 VIEWS ÚTEIS

### **`v_active_sessions`**
Sessões ativas com informações completas.

```sql
-- Consultar sessões ativas
SELECT * FROM sessions.v_active_sessions;

-- Retorna sessões com dados do funcionário, estabelecimento e usuário
-- Ideal para dashboards de segurança e monitoramento
```

### **`v_session_activity`**
Atividade das sessões por período.

```sql
-- Consultar atividade das sessões
SELECT * FROM sessions.v_session_activity;

-- Retorna estatísticas de atividade por período
-- Útil para análise de uso e segurança
```

---

## 🚀 EXEMPLOS PRÁTICOS

### **1. Criar Nova Sessão**

```sql
-- Criar nova sessão para um funcionário
INSERT INTO sessions.user_sessions (
    employee_id,
    current_session_id,
    session_expires_at,
    refresh_token_hash,
    access_token_hash,
    ip_address,
    user_agent
) VALUES (
    'uuid-funcionario',
    'sessao-123-abc',
    NOW() + INTERVAL '24 hours',
    'hash-refresh-token-123',
    'hash-access-token-456',
    '192.168.1.100',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
);
```

### **2. Atualizar Sessão Ativa**

```sql
-- Atualizar sessão para manter ativa
UPDATE sessions.user_sessions 
SET 
    current_session_id = 'sessao-123-def',
    session_expires_at = NOW() + INTERVAL '24 hours',
    updated_at = NOW()
WHERE session_id = 'uuid-sessao';
```

### **3. Desativar Sessão**

```sql
-- Desativar sessão (logout)
UPDATE sessions.user_sessions 
SET 
    is_active = false,
    updated_at = NOW()
WHERE session_id = 'uuid-sessao';
```

### **4. Limpar Sessões Expiradas**

```sql
-- Desativar sessões expiradas
UPDATE sessions.user_sessions 
SET 
    is_active = false,
    updated_at = NOW()
WHERE session_expires_at < NOW()
  AND is_active = true;
```

---

## 🔍 CONSULTAS AVANÇADAS

### **Sessões por Funcionário**

```sql
-- Todas as sessões de um funcionário específico
SELECT 
    us.*,
    e.establishment_id,
    e.supplier_id,
    epd.full_name as nome_funcionario
FROM sessions.user_sessions us
JOIN accounts.employees e ON us.employee_id = e.employee_id
JOIN accounts.employee_personal_data epd ON e.employee_id = epd.employee_id
WHERE e.employee_id = 'uuid-funcionario'
ORDER BY us.created_at DESC;
```

### **Sessões por Estabelecimento**

```sql
-- Sessões ativas por estabelecimento
SELECT 
    est.name as nome_estabelecimento,
    epd.full_name as nome_funcionario,
    us.current_session_id,
    us.session_expires_at,
    us.ip_address,
    us.user_agent
FROM sessions.user_sessions us
JOIN accounts.employees e ON us.employee_id = e.employee_id
JOIN accounts.establishments est ON e.establishment_id = est.establishment_id
JOIN accounts.employee_personal_data epd ON e.employee_id = epd.employee_id
WHERE us.is_active = true
  AND e.establishment_id = 'uuid-estabelecimento'
ORDER BY us.session_expires_at;
```

### **Análise de Segurança**

```sql
-- Múltiplas sessões do mesmo IP
SELECT 
    us.ip_address,
    COUNT(*) as total_sessoes,
    COUNT(DISTINCT us.employee_id) as funcionarios_diferentes,
    array_agg(DISTINCT epd.full_name) as nomes_funcionarios
FROM sessions.user_sessions us
JOIN accounts.employees e ON us.employee_id = e.employee_id
JOIN accounts.employee_personal_data epd ON e.employee_id = epd.employee_id
WHERE us.is_active = true
  AND us.created_at >= CURRENT_DATE - INTERVAL '1 day'
GROUP BY us.ip_address
HAVING COUNT(*) > 1
ORDER BY total_sessoes DESC;
```

### **Sessões por Período**

```sql
-- Sessões criadas por período
SELECT 
    DATE(us.created_at) as data,
    COUNT(*) as total_sessoes,
    COUNT(DISTINCT us.employee_id) as funcionarios_unicos,
    COUNT(DISTINCT us.ip_address) as ips_unicos
FROM sessions.user_sessions us
WHERE us.created_at >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY DATE(us.created_at)
ORDER BY data DESC;
```

---

## 🔧 MANUTENÇÃO E MONITORAMENTO

### **Verificar Sessões Ativas**

```sql
-- Total de sessões ativas
SELECT 
    COUNT(*) as total_sessoes_ativas,
    COUNT(DISTINCT employee_id) as funcionarios_com_sessao,
    COUNT(DISTINCT ip_address) as ips_unicos
FROM sessions.user_sessions 
WHERE is_active = true;

-- Sessões por funcionário
SELECT 
    epd.full_name,
    COUNT(*) as total_sessoes
FROM sessions.user_sessions us
JOIN accounts.employees e ON us.employee_id = e.employee_id
JOIN accounts.employee_personal_data epd ON e.employee_id = epd.employee_id
WHERE us.is_active = true
GROUP BY e.employee_id, epd.full_name
ORDER BY total_sessoes DESC;
```

### **Verificar Sessões Expiradas**

```sql
-- Sessões expiradas ainda ativas
SELECT 
    us.session_id,
    epd.full_name as funcionario,
    us.session_expires_at,
    us.ip_address,
    us.user_agent
FROM sessions.user_sessions us
JOIN accounts.employees e ON us.employee_id = e.employee_id
JOIN accounts.employee_personal_data epd ON e.employee_id = epd.employee_id
WHERE us.session_expires_at < NOW()
  AND us.is_active = true
ORDER BY us.session_expires_at;
```

### **Verificar Auditoria**

```sql
-- Listar tabelas auditadas
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'audit' 
  AND table_name LIKE 'sessions__%'
ORDER BY table_name;
```

---

## ⚠️ IMPORTANTE

### **Segurança**
- **Tokens Hash**: Tokens são sempre armazenados como hash
- **Expiração**: Sessões devem ter tempo de expiração realista
- **IP Tracking**: Monitore IPs suspeitos ou múltiplas sessões do mesmo IP
- **User Agent**: Rastreie dispositivos e navegadores

### **Performance**
- **Índices**: Sessões são indexadas por `employee_id` e `session_expires_at`
- **Limpeza**: Sessões expiradas devem ser limpas regularmente
- **Particionamento**: Tabelas de auditoria são particionadas por data

### **Boas Práticas**
- Sempre defina tempo de expiração realista
- Monitore sessões ativas regularmente
- Limpe sessões expiradas automaticamente
- Use transações para operações complexas
- Mantenha auditoria ativa para todas as operações

---

## 🔐 INTEGRAÇÃO COM AUTENTICAÇÃO

### **AWS Cognito**
- **cognito_sub**: Campo em `accounts.users` para integração
- **Tokens**: Hash dos tokens de acesso e refresh
- **Expiração**: Controle de tempo de vida das sessões

### **Google OAuth**
- **Google ID**: Integração via `accounts.user_google_oauth`
- **Sessões**: Múltiplas sessões podem usar diferentes provedores
- **Controle**: Cada sessão é independente

### **Multi-Persona**
- **Estabelecimentos**: Usuário pode ter sessões em diferentes estabelecimentos
- **Papéis**: Cada sessão representa um papel específico
- **Controle**: Acesso granular por estabelecimento e papel

---

## 📚 RECURSOS ADICIONAIS

- **[README.md](README.md)** - Documentação geral do projeto
- **[README_SCHEMAS.md](README_SCHEMAS.md)** - Visão geral de todos os schemas
- **[README_SCHEMA_ACCOUNTS.md](README_SCHEMA_ACCOUNTS.md)** - Schema de autenticação
- **[README_SCHEMA_CATALOGS.md](README_SCHEMA_CATALOGS.md)** - Schema de catálogo
- **[README_SCHEMA_QUOTATION.md](README_SCHEMA_QUOTATION.md)** - Schema de cotações
- **[README_SCHEMA_AUX.md](README_SCHEMA_AUX.md)** - Funções auxiliares e validações
- **[README_SCHEMA_AUDIT.md](README_SCHEMA_AUDIT.md)** - Sistema de auditoria

---

**🎯 Lembre-se: O schema `sessions` é crucial para a segurança do sistema. Monitore as sessões ativas e mantenha a limpeza automática de sessões expiradas!**
