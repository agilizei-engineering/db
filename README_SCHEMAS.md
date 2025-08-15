# 📚 DOCUMENTAÇÃO COMPLETA DOS SCHEMAS

## 🎯 VISÃO GERAL

Este documento descreve todos os schemas do banco de dados, suas funções, tabelas e como utilizá-los corretamente.

---

## 📁 SCHEMA: `accounts`

### **Descrição**
Schema principal para autenticação, autorização e gestão de usuários do sistema.

### **Tabelas Principais**
- `users` - Usuários autenticáveis
- `employees` - Funcionários vinculados a estabelecimentos/fornecedores
- `establishments` - Estabelecimentos comerciais
- `roles` - Papéis/funções no sistema
- `features` - Funcionalidades disponíveis
- `modules` - Módulos do sistema
- `platforms` - Plataformas disponíveis

### **Extensões**
- `establishment_business_data` - Dados empresariais dos estabelecimentos
- `establishment_addresses` - Endereços dos estabelecimentos
- `employee_personal_data` - Dados pessoais dos funcionários
- `employee_addresses` - Endereços dos funcionários
- `user_google_oauth` - Dados de autenticação OAuth do Google

### **Funções Principais**

#### **🔍 Busca de Funcionários**
```sql
-- Buscar funcionário por CPF
SELECT * FROM accounts.find_employee_by_cpf('123.456.789-09');

-- Buscar funcionários por CEP
SELECT * FROM accounts.find_employees_by_postal_code('12345-678');

-- Buscar funcionários por nome (busca fuzzy)
SELECT * FROM accounts.search_employees_by_name('Vinicius');
```

#### **🔍 Busca de Estabelecimentos**
```sql
-- Buscar estabelecimentos por CEP
SELECT * FROM accounts.find_establishments_by_postal_code('12345-678');
```

#### **📊 Views Úteis**
```sql
-- Usuários com dados completos do Google OAuth
SELECT * FROM accounts.v_users_with_google;

-- Funcionários com dados completos
SELECT * FROM accounts.v_employees_complete;

-- Estabelecimentos com dados completos
SELECT * FROM accounts.v_establishments_complete;
```

---

## 📁 SCHEMA: `catalogs`

### **Descrição**
Schema para gestão de produtos, categorias, marcas e variações do catálogo.

### **Tabelas Principais**
- `products` - Produtos do catálogo
- `categories` - Categorias de produtos
- `subcategories` - Subcategorias
- `brands` - Marcas dos produtos
- `variants` - Variações de produtos
- `compositions` - Composições dos produtos
- `fillings` - Recheios
- `flavors` - Sabores
- `formats` - Formatos
- `packagings` - Embalagens
- `quantities` - Quantidades disponíveis
- `offers` - Ofertas especiais

### **Funcionalidades**
- Catálogo hierárquico de produtos
- Sistema de variações flexível
- Gestão de estoque e quantidades
- Sistema de ofertas e promoções

---

## 📁 SCHEMA: `quotation`

### **Descrição**
Sistema de cotações e listas de compras para estabelecimentos.

### **Tabelas Principais**
- `shopping_lists` - Listas de compras
- `shopping_list_items` - Itens das listas
- `quotation_submissions` - Submissões de cotações
- `supplier_quotations` - Cotações dos fornecedores
- `quoted_prices` - Preços cotados
- `submission_statuses` - Status das submissões
- `supplier_quotation_statuses` - Status das cotações

### **Funcionalidades**
- Criação de listas de compras
- Submissão de cotações para fornecedores
- Comparação de preços
- Acompanhamento de status

---

## 📁 SCHEMA: `audit`

### **Descrição**
Sistema automático de auditoria para todas as tabelas do banco.

### **Funcionalidades Principais**
- **Auditoria Automática**: Captura todas as operações INSERT/UPDATE/DELETE
- **Particionamento por Data**: Organização eficiente por ano/mês/dia
- **Sincronização Automática**: Detecta mudanças estruturais automaticamente
- **Histórico Completo**: Mantém todos os dados anteriores

### **Como Usar**

#### **🔧 Criar Auditoria para uma Tabela**
```sql
-- Auditoria de uma tabela específica
SELECT audit.create_audit_table('accounts', 'users');

-- Auditoria de uma tabela específica
SELECT audit.create_audit_table('catalogs', 'products');
```

#### **🔧 Auditoria de Schemas Inteiros**
```sql
-- Auditoria de múltiplos schemas
SELECT audit.audit_schemas(ARRAY['accounts', 'catalogs']);

-- Auditoria de um schema específico
SELECT audit.audit_schema('quotation');
```

#### **🔧 Sincronização Automática**
```sql
-- Sincronizar auditoria após mudanças estruturais
SELECT audit.sync_audit_table('accounts', 'users');

-- Sincronizar auditoria de uma tabela
SELECT audit.sync_audit_table('catalogs', 'products');
```

#### **📊 Consultar Histórico de Auditoria**
```sql
-- Histórico de uma tabela específica
SELECT * FROM audit.accounts__users ORDER BY audit_timestamp DESC;

-- Histórico de uma data específica
SELECT * FROM audit.accounts__users_2025_08 ORDER BY audit_timestamp DESC;

-- Histórico de operações específicas
SELECT * FROM audit.accounts__users 
WHERE audit_operation = 'UPDATE' 
ORDER BY audit_timestamp DESC;

-- Histórico de um usuário específico
SELECT * FROM audit.accounts__users 
WHERE user_id = 'uuid-do-usuario' 
ORDER BY audit_timestamp DESC;
```

#### **🔍 Exemplos de Consultas Úteis**
```sql
-- Últimas 10 alterações em qualquer tabela
SELECT 
    audit_timestamp,
    audit_operation,
    audit_user,
    audit_session_id
FROM audit.accounts__users 
ORDER BY audit_timestamp DESC 
LIMIT 10;

-- Alterações de hoje
SELECT 
    audit_timestamp,
    audit_operation,
    audit_user
FROM audit.accounts__users 
WHERE DATE(audit_timestamp) = CURRENT_DATE
ORDER BY audit_timestamp DESC;

-- Usuários que mais alteraram dados
SELECT 
    audit_user,
    COUNT(*) as total_alteracoes
FROM audit.accounts__users 
GROUP BY audit_user 
ORDER BY total_alteracoes DESC;
```

---

## 📁 SCHEMA: `aux`

### **Descrição**
Schema auxiliar com funções compartilhadas, validações e utilitários para todo o sistema.

### **Funções de Validação**

#### **📧 Validação de Email**
```sql
-- Validar formato de email
SELECT aux.validate_email('usuario@exemplo.com'); -- true
SELECT aux.validate_email('email-invalido'); -- false

-- Limpar e validar email
SELECT aux.clean_and_validate_email('  USUARIO@EXEMPLO.COM  '); -- 'usuario@exemplo.com'
```

#### **🆔 Validação de CPF**
```sql
-- Validar CPF
SELECT aux.validate_cpf('123.456.789-09'); -- true
SELECT aux.validate_cpf('111.111.111-11'); -- false

-- Limpar e validar CPF
SELECT aux.clean_and_validate_cpf('123.456.789-09'); -- '12345678909'

-- Formatar CPF
SELECT aux.format_cpf('12345678909'); -- '123.456.789-09'
```

#### **🏢 Validação de CNPJ**
```sql
-- Validar CNPJ
SELECT aux.validate_cnpj('11.222.333/0001-81'); -- true
SELECT aux.validate_cnpj('11.111.111/1111-11'); -- false

-- Limpar e validar CNPJ
SELECT aux.clean_and_validate_cnpj('11.222.333/0001-81'); -- '11222333000181'

-- Formatar CNPJ
SELECT aux.format_cnpj('11222333000181'); -- '11.222.333/0001-81'
```

#### **📍 Validação de CEP**
```sql
-- Validar CEP
SELECT aux.validate_postal_code('12345-678'); -- true
SELECT aux.validate_postal_code('12345'); -- false

-- Limpar e validar CEP
SELECT aux.clean_and_validate_postal_code('12345-678'); -- '12345678'

-- Formatar CEP
SELECT aux.format_postal_code('12345678'); -- '12345-678'
```

#### **🌐 Validação de URL**
```sql
-- Validar URL
SELECT aux.validate_url('https://exemplo.com'); -- true
SELECT aux.validate_url('url-invalida'); -- false
```

#### **📅 Validação de Data de Nascimento**
```sql
-- Validar data de nascimento (idade mínima padrão: 14 anos)
SELECT aux.validate_birth_date('2000-01-01'); -- true
SELECT aux.validate_birth_date('2015-01-01'); -- false (muito jovem)

-- Validar com idade mínima personalizada
SELECT aux.validate_birth_date('2005-01-01', 18); -- false (menor de 18)
```

#### **🇧🇷 Validação de Estado Brasileiro**
```sql
-- Validar estado
SELECT aux.validate_estado_brasileiro('SP'); -- true
SELECT aux.validate_estado_brasileiro('XX'); -- false
```

### **Funções de Trigger**

#### **🔄 Triggers de Validação**
```sql
-- Criar triggers de validação para uma tabela
SELECT aux.create_validation_triggers('accounts', 'establishment_business_data', ARRAY['cnpj']);

-- Criar triggers de validação para múltiplas colunas
SELECT aux.create_validation_triggers('accounts', 'employee_personal_data', ARRAY['cpf', 'email']);

-- Criar trigger específico para CNPJ
SELECT aux.create_cnpj_trigger('accounts', 'establishment_business_data', 'cnpj');

-- Criar trigger específico para CPF
SELECT aux.create_cpf_trigger('accounts', 'employee_personal_data', 'cpf');

-- Criar trigger específico para CEP
SELECT aux.create_postal_code_trigger('accounts', 'establishment_addresses', 'postal_code');

-- Criar trigger específico para email
SELECT aux.create_email_trigger('accounts', 'users', 'email');

-- Criar trigger específico para URL
SELECT aux.create_url_trigger('accounts', 'user_google_oauth', 'google_picture_url');
```

#### **⏰ Triggers de Updated At**
```sql
-- Criar trigger de updated_at para uma tabela
SELECT aux.create_updated_at_trigger('accounts', 'users');

-- Criar trigger de updated_at para múltiplas tabelas
SELECT aux.create_updated_at_trigger('catalogs', 'products');
SELECT aux.create_updated_at_trigger('catalogs', 'categories');
```

### **Domínios de Validação**

#### **🏷️ Tipos de Dados Validados**
```sql
-- Estado brasileiro
CREATE TABLE exemplo (
    estado aux.estado_brasileiro NOT NULL
);

-- Gênero
CREATE TABLE exemplo (
    genero aux.genero NOT NULL
);

-- Moeda
CREATE TABLE exemplo (
    valor aux.moeda NOT NULL
);
```

---

## 📁 SCHEMA: `sessions`

### **Descrição**
Controle de sessões ativas e autenticação multi-persona dos usuários.

### **Tabelas**
- `user_sessions` - Sessões ativas dos usuários

### **Funcionalidades**
- **Multi-Persona**: Um usuário pode ter múltiplas sessões ativas
- **Controle de Sessão**: Expiração, tokens, IP, user agent
- **Auditoria**: Rastreamento completo de sessões

### **Como Usar**

#### **📊 Consultar Sessões Ativas**
```sql
-- Todas as sessões ativas
SELECT * FROM sessions.v_active_sessions;

-- Sessões de um funcionário específico
SELECT * FROM sessions.v_active_sessions 
WHERE employee_id = 'uuid-do-funcionario';

-- Sessões expiradas
SELECT * FROM sessions.v_active_sessions 
WHERE session_status = 'EXPIRED';
```

#### **🔍 Consultar Sessões por Usuário**
```sql
-- Sessões de um usuário específico
SELECT 
    us.*,
    e.establishment_id,
    e.supplier_id
FROM sessions.user_sessions us
JOIN accounts.employees e ON us.employee_id = e.employee_id
WHERE e.user_id = 'uuid-do-usuario';
```

---

## 🚀 EXEMPLOS PRÁTICOS DE USO

### **1. 🔐 Implementar Validação em Nova Tabela**

```sql
-- Criar tabela com validações
CREATE TABLE minha_tabela (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    email text NOT NULL,
    cpf text NOT NULL,
    cep text NOT NULL
);

-- Adicionar constraints de validação
ALTER TABLE minha_tabela 
ADD CONSTRAINT email_valido CHECK (aux.validate_email(email));

ALTER TABLE minha_tabela 
ADD CONSTRAINT cpf_valido CHECK (aux.validate_cpf(cpf));

ALTER TABLE minha_tabela 
ADD CONSTRAINT cep_valido CHECK (aux.validate_postal_code(cep));

-- Criar triggers de validação automática
SELECT aux.create_validation_triggers('meu_schema', 'minha_tabela', ARRAY['email', 'cpf', 'cep']);

-- Criar trigger de updated_at
SELECT aux.create_updated_at_trigger('meu_schema', 'minha_tabela');

-- Criar auditoria
SELECT audit.create_audit_table('meu_schema', 'minha_tabela');
```

### **2. 📊 Consultar Histórico de Mudanças**

```sql
-- Histórico de mudanças de uma tabela
SELECT 
    audit_timestamp,
    audit_operation,
    audit_user,
    audit_session_id,
    -- campos específicos da tabela
    email,
    cpf,
    cep
FROM audit.meu_schema__minha_tabela 
WHERE audit_timestamp >= CURRENT_DATE - INTERVAL '7 days'
ORDER BY audit_timestamp DESC;
```

### **3. 🔍 Busca Avançada com Validações**

```sql
-- Buscar estabelecimentos por CEP com validação
SELECT 
    e.name,
    ebd.cnpj,
    ea.postal_code,
    ea.city,
    ea.state
FROM accounts.establishments e
JOIN accounts.establishment_business_data ebd ON e.establishment_id = ebd.establishment_id
JOIN accounts.establishment_addresses ea ON e.establishment_id = ea.establishment_id
WHERE aux.clean_and_validate_postal_code('12345-678') = ea.postal_code;
```

### **4. 📈 Relatório de Auditoria**

```sql
-- Relatório de atividades por usuário
SELECT 
    audit_user,
    audit_operation,
    COUNT(*) as total_operacoes,
    DATE(audit_timestamp) as data
FROM audit.accounts__users 
WHERE audit_timestamp >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY audit_user, audit_operation, DATE(audit_timestamp)
ORDER BY data DESC, total_operacoes DESC;
```

---

## ⚠️ IMPORTANTE: ORDEM DE EXECUÇÃO

### **1. Pré-requisitos**
```bash
# Executar primeiro
psql -d postgres -f aux_schema.sql
```

### **2. Sistema de Auditoria**
```bash
# Executar segundo
psql -d postgres -f audit_system.sql
```

### **3. Extensões**
```bash
# Executar terceiro
psql -d postgres -f establishments_extension.sql
psql -d postgres -f employees_extension.sql
psql -d postgres -f quotation_schema.sql
```

### **4. Refatoração**
```bash
# Executar quarto
psql -d postgres -f migrate_employees_to_aux.sql
psql -d postgres -f migrate_establishments_to_aux.sql
psql -d postgres -f cleanup_duplicated_functions.sql
```

### **5. Melhorias de Segurança**
```bash
# Executar por último
psql -d postgres -f enhance_users_security.sql
```

---

## 🔧 MANUTENÇÃO E MONITORAMENTO

### **Verificar Status das Tabelas de Auditoria**
```sql
-- Listar todas as tabelas auditadas
SELECT 
    table_schema,
    table_name,
    audit_table_name
FROM (
    SELECT 
        'audit' as table_schema,
        table_name,
        table_name as audit_table_name
    FROM information_schema.tables 
    WHERE table_schema = 'audit' 
    AND table_name LIKE '%__%'
) audit_tables
ORDER BY table_schema, table_name;
```

### **Verificar Triggers Ativos**
```sql
-- Listar todos os triggers de auditoria
SELECT 
    trigger_schema,
    trigger_name,
    event_object_table,
    action_statement
FROM information_schema.triggers 
WHERE trigger_name LIKE '%audit%'
ORDER BY trigger_schema, event_object_table;
```

### **Verificar Funções do Schema Aux**
```sql
-- Listar todas as funções auxiliares
SELECT 
    routine_name,
    routine_type,
    data_type
FROM information_schema.routines 
WHERE routine_schema = 'aux'
ORDER BY routine_name;
```

---

## 📚 RECURSOS ADICIONAIS

- **README.md** - Documentação geral do projeto
- **test_*.sql** - Scripts de teste para validação
- **migrate_*.sql** - Scripts de migração entre versões
- **cleanup_*.sql** - Scripts de limpeza e manutenção

---

## 🆘 SUPORTE

Para dúvidas ou problemas:
1. Verificar logs de execução dos scripts
2. Consultar tabelas de auditoria para rastrear mudanças
3. Verificar constraints e triggers ativos
4. Consultar documentação específica de cada schema

---

**🎯 Lembre-se: Sempre execute os scripts na ordem correta para evitar problemas de dependência!**
