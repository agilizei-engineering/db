# 🔐 SCHEMA: `accounts` - AUTENTICAÇÃO E AUTORIZAÇÃO

## 🎯 VISÃO GERAL

O schema `accounts` é o coração do sistema de autenticação e autorização, gerenciando usuários, funcionários, estabelecimentos e suas permissões. Ele implementa um sistema robusto de controle de acesso com suporte a múltiplos papéis e estabelecimentos.

---

## 📋 TABELAS PRINCIPAIS

### **👥 Usuários e Autenticação**

#### **`users`** - Usuários Autenticáveis
- **Descrição**: Tabela principal de usuários do sistema
- **Campos principais**: `user_id`, `email`, `full_name`, `cognito_sub`, `is_active`
- **Funcionalidades**: Autenticação via AWS Cognito, controle de status ativo/inativo
- **Auditoria**: Automática via schema `audit`

#### **`employees`** - Funcionários e Colaboradores
- **Descrição**: Funcionários vinculados a estabelecimentos ou fornecedores
- **Campos principais**: `employee_id`, `user_id`, `establishment_id`, `supplier_id`, `is_active`
- **Funcionalidades**: Relacionamento usuário-estabelecimento, controle de acesso
- **Auditoria**: Automática via schema `audit`

#### **`roles`** - Perfis de Acesso
- **Descrição**: Definição de papéis e permissões no sistema
- **Campos principais**: `role_id`, `name`, `description`, `is_active`
- **Funcionalidades**: Controle de acesso baseado em papéis (RBAC)
- **Auditoria**: Automática via schema `audit`

#### **`features`** - Funcionalidades Disponíveis
- **Descrição**: Lista de funcionalidades que podem ser controladas por permissão
- **Campos principais**: `feature_id`, `name`, `description`, `module_id`
- **Funcionalidades**: Controle granular de funcionalidades por usuário/papel
- **Auditoria**: Automática via schema `audit`

#### **`modules`** - Módulos do Sistema
- **Descrição**: Módulos organizacionais do sistema
- **Campos principais**: `module_id`, `name`, `description`, `is_active`
- **Funcionalidades**: Organização hierárquica de funcionalidades
- **Auditoria**: Automática via schema `audit`

#### **`platforms`** - Plataformas Disponíveis
- **Descrição**: Plataformas onde o sistema pode ser acessado
- **Campos principais**: `platform_id`, `name`, `description`, `is_active`
- **Funcionalidades**: Controle de acesso por plataforma
- **Auditoria**: Automática via schema `audit`

#### **`api_keys`** - Chaves de API
- **Descrição**: Chaves de autenticação para APIs externas
- **Campos principais**: `api_key_id`, `name`, `key_hash`, `user_id`, `is_active`
- **Funcionalidades**: Autenticação via chave de API, controle de acesso
- **Auditoria**: Automática via schema `audit`

---

### **🏢 Estabelecimentos e Dados Empresariais**

#### **`establishments`** - Estabelecimentos Comerciais
- **Descrição**: Estabelecimentos, empresas ou fornecedores do sistema
- **Campos principais**: `establishment_id`, `name`, `description`, `is_active`
- **Funcionalidades**: Gestão de estabelecimentos, controle de status
- **Auditoria**: Automática via schema `audit`

#### **`establishment_business_data`** - Dados Empresariais
- **Descrição**: Informações empresariais dos estabelecimentos
- **Campos principais**: `establishment_id`, `cnpj`, `trade_name`, `corporate_name`, `state_registration`
- **Funcionalidades**: Validação automática de CNPJ, limpeza de máscaras
- **Validações**: CNPJ válido via `aux.validate_cnpj()`
- **Auditoria**: Automática via schema `audit`

#### **`establishment_addresses`** - Endereços dos Estabelecimentos
- **Descrição**: Endereços físicos dos estabelecimentos
- **Campos principais**: `establishment_id`, `postal_code`, `street`, `number`, `neighborhood`, `city`, `state`
- **Funcionalidades**: Validação automática de CEP, limpeza de máscaras
- **Validações**: CEP válido via `aux.validate_postal_code()`, estado via `aux.estado_brasileiro`
- **Auditoria**: Automática via schema `audit`

---

### **👤 Dados Pessoais dos Funcionários**

#### **`employee_personal_data`** - Dados Pessoais
- **Descrição**: Informações pessoais dos funcionários
- **Campos principais**: `employee_id`, `cpf`, `full_name`, `birth_date`, `gender`, `photo_url`
- **Funcionalidades**: Validação automática de CPF, data de nascimento, gênero
- **Validações**: 
  - CPF válido via `aux.validate_cpf()`
  - Data de nascimento via `aux.validate_birth_date()` (idade mínima: 14 anos)
  - Gênero via `aux.genero` (M/F/O)
  - URL de foto via `aux.validate_url()`
- **Auditoria**: Automática via schema `audit`

#### **`employee_addresses`** - Endereços dos Funcionários
- **Descrição**: Endereços residenciais dos funcionários
- **Campos principais**: `employee_id`, `postal_code`, `street`, `number`, `neighborhood`, `city`, `state`
- **Funcionalidades**: Validação automática de CEP, limpeza de máscaras
- **Validações**: CEP válido via `aux.validate_postal_code()`, estado via `aux.estado_brasileiro`
- **Auditoria**: Automática via schema `audit`

---

### **🔐 Autenticação OAuth e Integração**

#### **`user_google_oauth`** - Dados do Google OAuth
- **Descrição**: Informações de autenticação OAuth do Google
- **Campos principais**: `google_oauth_id`, `user_id`, `google_id`, `google_picture_url`, `google_locale`, `google_given_name`, `google_family_name`, `google_hd`, `google_email`, `google_email_verified`, `google_profile_data`
- **Funcionalidades**: Integração com Google OAuth, armazenamento de dados do perfil
- **Validações**: URL da foto via `aux.validate_url()`, email via `aux.validate_email()`
- **Auditoria**: Automática via schema `audit`

---

## 🔍 FUNÇÕES PRINCIPAIS

### **Busca de Funcionários**

#### **`find_employee_by_cpf(cpf text)`**
Busca funcionário por CPF (com validação automática).

```sql
-- Exemplo de uso
SELECT * FROM accounts.find_employee_by_cpf('123.456.789-09');

-- Retorna dados completos do funcionário
-- Inclui dados pessoais, endereço e estabelecimento
```

#### **`find_employees_by_postal_code(postal_code text)`**
Busca funcionários por CEP (com validação automática).

```sql
-- Exemplo de uso
SELECT * FROM accounts.find_employees_by_postal_code('12345-678');

-- Retorna todos os funcionários de um CEP específico
-- Útil para análises geográficas
```

#### **`search_employees_by_name(name_pattern text)`**
Busca fuzzy de funcionários por nome.

```sql
-- Exemplo de uso
SELECT * FROM accounts.search_employees_by_name('Vinicius');

-- Retorna funcionários com nomes similares
-- Suporta busca parcial e fuzzy
```

### **Busca de Estabelecimentos**

#### **`find_establishments_by_postal_code(postal_code text)`**
Busca estabelecimentos por CEP (com validação automática).

```sql
-- Exemplo de uso
SELECT * FROM accounts.find_establishments_by_postal_code('12345-678');

-- Retorna todos os estabelecimentos de um CEP específico
-- Inclui dados empresariais e endereços
```

---

## 📊 VIEWS ÚTEIS

### **`v_users_with_google`**
Usuários com dados completos do Google OAuth.

```sql
-- Consultar usuários com integração Google
SELECT * FROM accounts.v_users_with_google;

-- Retorna dados combinados de users e user_google_oauth
-- Útil para autenticação e perfil do usuário
```

### **`v_employees_complete`**
Funcionários com dados completos (pessoais, endereço, estabelecimento).

```sql
-- Consultar funcionários completos
SELECT * FROM accounts.v_employees_complete;

-- Retorna dados combinados de todas as tabelas relacionadas
-- Ideal para relatórios e dashboards
```

### **`v_establishments_complete`**
Estabelecimentos com dados completos (empresariais e endereços).

```sql
-- Consultar estabelecimentos completos
SELECT * FROM accounts.v_establishments_complete;

-- Retorna dados combinados de todas as tabelas relacionadas
-- Ideal para relatórios e dashboards
```

---

## 🔐 SISTEMA DE AUTENTICAÇÃO

### **Multi-Persona**
- Um usuário pode ter múltiplos papéis em diferentes estabelecimentos
- Sistema de sessões independentes por papel/estabelecimento
- Controle granular de permissões por funcionalidade

### **Integração OAuth**
- **Google OAuth**: Login via Google com dados do perfil
- **AWS Cognito**: Autenticação via AWS (campo `cognito_sub`)
- **API Keys**: Autenticação via chave de API para serviços externos

### **Controle de Acesso**
- **RBAC (Role-Based Access Control)**: Controle baseado em papéis
- **Funcionalidades granulares**: Controle por funcionalidade específica
- **Módulos organizacionais**: Agrupamento lógico de funcionalidades

---

## 🚀 EXEMPLOS PRÁTICOS

### **1. Criar Usuário Completo com Funcionário**

```sql
-- 1. Criar usuário
INSERT INTO accounts.users (email, full_name, cognito_sub, is_active) 
VALUES ('joao@empresa.com', 'João Silva Santos', 'cognito-joao-123', true)
RETURNING user_id;

-- 2. Criar estabelecimento
INSERT INTO accounts.establishments (name, description) 
VALUES ('Empresa ABC', 'Empresa de tecnologia')
RETURNING establishment_id;

-- 3. Criar funcionário
INSERT INTO accounts.employees (user_id, establishment_id, is_active) 
VALUES ('uuid-do-usuario', 'uuid-do-estabelecimento', true)
RETURNING employee_id;

-- 4. Adicionar dados pessoais
INSERT INTO accounts.employee_personal_data (
    employee_id, cpf, full_name, birth_date, gender, photo_url
) VALUES (
    'uuid-do-funcionario',
    '123.456.789-01',
    'João Silva Santos',
    '1990-05-15',
    'M',
    'https://example.com/photos/joao.jpg'
);

-- 5. Adicionar endereço
INSERT INTO accounts.employee_addresses (
    employee_id, postal_code, street, number, neighborhood, city, state
) VALUES (
    'uuid-do-funcionario',
    '01234-567',
    'Rua das Flores',
    '123',
    'Centro',
    'São Paulo',
    'SP'
);
```

### **2. Criar Estabelecimento com Dados Empresariais**

```sql
-- 1. Criar estabelecimento
INSERT INTO accounts.establishments (name, description) 
VALUES ('Minha Empresa LTDA', 'Empresa de consultoria')
RETURNING establishment_id;

-- 2. Adicionar dados empresariais
INSERT INTO accounts.establishment_business_data (
    establishment_id, cnpj, trade_name, corporate_name, state_registration
) VALUES (
    'uuid-do-estabelecimento',
    '12.345.678/0001-90',
    'Minha Empresa',
    'Minha Empresa Consultoria LTDA',
    '123456789'
);

-- 3. Adicionar endereço
INSERT INTO accounts.establishment_addresses (
    establishment_id, postal_code, street, number, neighborhood, city, state
) VALUES (
    'uuid-do-estabelecimento',
    '01234-567',
    'Avenida Paulista',
    '1000',
    'Bela Vista',
    'São Paulo',
    'SP'
);
```

### **3. Integração com Google OAuth**

```sql
-- 1. Usuário já deve existir em accounts.users
-- 2. Adicionar dados do Google OAuth
INSERT INTO accounts.user_google_oauth (
    user_id, google_id, google_picture_url, google_locale, 
    google_given_name, google_family_name, google_email, 
    google_email_verified, google_profile_data
) VALUES (
    'uuid-do-usuario',
    'google-user-id-123',
    'https://lh3.googleusercontent.com/photo.jpg',
    'pt_BR',
    'João',
    'Silva',
    'joao.silva@gmail.com',
    true,
    '{"hd": "empresa.com", "sub": "google-sub-123"}'
);
```

---

## 🔧 MANUTENÇÃO E MONITORAMENTO

### **Verificar Status das Tabelas**

```sql
-- Listar todas as tabelas do schema accounts
SELECT table_name, table_type 
FROM information_schema.tables 
WHERE table_schema = 'accounts'
ORDER BY table_name;

-- Verificar constraints ativas
SELECT 
    constraint_name,
    table_name,
    constraint_type
FROM information_schema.table_constraints 
WHERE table_schema = 'accounts'
ORDER BY table_name, constraint_name;
```

### **Verificar Triggers de Validação**

```sql
-- Listar triggers de validação
SELECT 
    trigger_name,
    event_object_table,
    action_statement
FROM information_schema.triggers 
WHERE trigger_schema = 'accounts'
  AND trigger_name LIKE '%validation%'
ORDER BY event_object_table;
```

### **Verificar Auditoria**

```sql
-- Listar tabelas auditadas
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'audit' 
  AND table_name LIKE 'accounts__%'
ORDER BY table_name;
```

---

## ⚠️ IMPORTANTE

### **Validações Automáticas**
- Todas as tabelas com campos sensíveis têm validação automática
- Triggers são criados automaticamente via schema `aux`
- Auditoria é aplicada automaticamente via schema `audit`

### **Ordem de Criação**
1. **users** (usuário base)
2. **establishments** (estabelecimento)
3. **employees** (vinculação usuário-estabelecimento)
4. **Dados complementares** (pessoais, empresariais, endereços)
5. **Integrações OAuth** (se necessário)

### **Boas Práticas**
- Sempre use as funções de validação do schema `aux`
- Crie auditoria para todas as tabelas novas
- Mantenha relacionamentos consistentes
- Use transações para operações complexas

---

## 📚 RECURSOS ADICIONAIS

- **[README.md](README.md)** - Documentação geral do projeto
- **[README_SCHEMAS.md](README_SCHEMAS.md)** - Visão geral de todos os schemas
- **[README_SCHEMA_AUX.md](README_SCHEMA_AUX.md)** - Funções auxiliares e validações
- **[README_SCHEMA_AUDIT.md](README_SCHEMA_AUDIT.md)** - Sistema de auditoria

---

**🎯 Lembre-se: O schema `accounts` é fundamental para todo o sistema. Mantenha a integridade dos dados e use sempre as validações automáticas!**
