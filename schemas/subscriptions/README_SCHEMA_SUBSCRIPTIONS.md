# 💳 SCHEMA: `subscriptions` - GESTÃO DE ASSINATURAS E PLANOS

## 🎯 VISÃO GERAL

O schema `subscriptions` é o coração do sistema de gestão de assinaturas SaaS da Agilizei, controlando planos, produtos comerciais, assinaturas ativas e tracking de uso. Ele implementa um sistema flexível de cobrança que suporta tanto planos com limites de uso quanto planos de acesso total.

---

## 📋 TABELAS PRINCIPAIS

### **🏢 Produtos Comerciais**

#### **`products`** - Produtos Disponíveis para Venda
- **Descrição**: Produtos comerciais que podem ser contratados pelos clientes
- **Campos principais**: `product_id`, `name`, `description`, `billing_model`, `is_available_for_supplier`, `is_available_for_establishment`
- **Funcionalidades**: Definição de produtos, modelos de cobrança, disponibilidade por tipo de cliente
- **Auditoria**: Automática via schema `audit`

#### **`product_modules`** - Módulos de Cada Produto
- **Descrição**: Relacionamento entre produtos e módulos do sistema
- **Campos principais**: `product_module_id`, `product_id`, `module_id`
- **Funcionalidades**: Define quais módulos cada produto inclui
- **Auditoria**: Automática via schema `audit`

### **📊 Planos e Nomes**

#### **`plan_names`** - Nomes dos Planos
- **Descrição**: Nomes comerciais dos planos (Basic, Pro, Max)
- **Campos principais**: `plan_name_id`, `name`, `description`, `is_active`
- **Funcionalidades**: Identificação comercial dos planos
- **Auditoria**: Automática via schema `audit`

#### **`plans`** - Configuração dos Planos
- **Descrição**: Planos específicos com limites, preços e período de vigência
- **Campos principais**: `plan_id`, `product_id`, `plan_name_id`, `valid_from`, `valid_to`, `price`, `usage_limits`
- **Funcionalidades**: Definição de limites, preços e validade dos planos
- **Validações**: JSONB `usage_limits` validado via `aux.json_validation_params`
- **Auditoria**: Automática via schema `audit`

### **🔐 Assinaturas e Uso**

#### **`subscriptions`** - Assinaturas Ativas dos Clientes
- **Descrição**: Assinaturas ativas de establishments e suppliers
- **Campos principais**: `subscription_id`, `establishment_id`, `supplier_id`, `employee_id`, `plan_id`, `start_date`, `end_date`, `status`
- **Funcionalidades**: Controle de assinaturas ativas, uma por cliente
- **Constraints**: UNIQUE (establishment_id + status = 'active'), UNIQUE (supplier_id + status = 'active')
- **Auditoria**: Automática via schema `audit`

#### **`usage_tracking`** - Controle de Uso das Assinaturas
- **Descrição**: Tracking de uso das funcionalidades por período
- **Campos principais**: `subscription_id`, `period_start`, `period_end`, `quotations_used`, `quotations_subscription`, `quotations_bought`, `quotations_limit`, `is_over_limit`
- **Funcionalidades**: Controle de cotas, tracking de uso, identificação de limites excedidos
- **Campos calculados**: `quotations_limit` (quotations_subscription + quotations_bought), `is_over_limit` (quotations_used > quotations_limit)
- **Auditoria**: Automática via schema `audit`

### **💰 Microtransações e Mudanças**

#### **`quota_purchases`** - Compras de Cotas Extras
- **Descrição**: Microtransações independentes para cotas excedentes
- **Campos principais**: `purchase_id`, `establishment_id`, `supplier_id`, `purchase_date`, `quotations_bought`, `unit_price`, `total_price`
- **Funcionalidades**: Compra de cotas extras, controle de preços unitários
- **Campos calculados**: `total_price` (unit_price * quotations_bought)
- **Auditoria**: Automática via schema `audit`

#### **`plan_changes`** - Histórico de Mudanças de Planos
- **Descrição**: Histórico de upgrades, downgrades e renovações
- **Campos principais**: `change_id`, `subscription_id`, `change_type`, `old_plan_id`, `new_plan_id`, `change_date`, `change_reason`, `credits_given`
- **Funcionalidades**: Rastreamento de mudanças, controle de créditos para downgrades
- **Auditoria**: Automática via schema `audit`

---

## 🔍 FUNÇÕES PRINCIPAIS

### **Gestão de Produtos e Planos**

#### **`create_product(name, description, billing_model, is_available_for_supplier, is_available_for_establishment)`**
Cria um novo produto comercial.

```sql
-- Exemplo de uso
SELECT subscriptions.create_product(
    'Cotação e Comparação de Preços',
    'Sistema completo de cotações e comparações',
    'usage_limits',
    false,
    true
);
```

#### **`create_plan(product_id, plan_name_id, valid_from, valid_to, price, usage_limits)`**
Cria um novo plano para um produto.

```sql
-- Exemplo de uso
SELECT subscriptions.create_plan(
    'uuid-do-produto',
    'uuid-do-nome-plano',
    '2025-01-01',
    '2025-12-31',
    199.90,
    '{"quotations": 100, "suppliers": 10, "items": 50}'
);
```

### **Gestão de Assinaturas**

#### **`create_subscription(establishment_id, supplier_id, plan_id, employee_id, start_date, end_date)`**
Cria uma nova assinatura para um cliente.

```sql
-- Exemplo de uso
SELECT subscriptions.create_subscription(
    'uuid-do-establishment',
    NULL,
    'uuid-do-plano',
    'uuid-do-employee',
    '2025-01-01',
    '2025-12-31'
);
```

#### **`upgrade_subscription(subscription_id, new_plan_id, change_reason)`**
Faz upgrade de uma assinatura para um plano superior.

```sql
-- Exemplo de uso
SELECT subscriptions.upgrade_subscription(
    'uuid-da-assinatura',
    'uuid-do-novo-plano',
    'Necessidade de mais cotações'
);
```

### **Controle de Uso**

#### **`track_usage(subscription_id, quotations_used)`**
Atualiza o tracking de uso de uma assinatura.

```sql
-- Exemplo de uso
SELECT subscriptions.track_usage(
    'uuid-da-assinatura',
    5
);
```

#### **`purchase_quotas(establishment_id, supplier_id, quotations_bought, unit_price)`**
Registra compra de cotas extras.

```sql
-- Exemplo de uso
SELECT subscriptions.purchase_quotas(
    'uuid-do-establishment',
    NULL,
    10,
    29.90
);
```

---

## 📊 VIEWS ÚTEIS

### **`v_active_subscriptions`**
Assinaturas ativas com informações completas.

```sql
-- Consultar assinaturas ativas
SELECT * FROM subscriptions.v_active_subscriptions;

-- Retorna dados combinados de todas as tabelas relacionadas
-- Ideal para dashboards e relatórios
```

### **`v_usage_summary`**
Resumo de uso por cliente e período.

```sql
-- Consultar resumo de uso
SELECT * FROM subscriptions.v_usage_summary;

-- Retorna estatísticas de uso por cliente
-- Útil para análises e cobrança
```

### **`v_plan_comparison`**
Comparação entre diferentes planos.

```sql
-- Comparar planos
SELECT * FROM subscriptions.v_plan_comparison;

-- Retorna comparação de recursos e preços
-- Ideal para vendas e marketing
```

---

## 🔧 SISTEMA DE VALIDAÇÃO

### **Validação JSONB Automática**
- **`aux.json_validation_params`**: Define parâmetros válidos para cada tabela/campo JSONB
- **Trigger automático**: Valida `usage_limits` em `plans` baseado nos parâmetros configurados
- **Flexibilidade**: Suporta qualquer estrutura de limites por produto

### **Exemplo de Configuração:**
```sql
-- Configurar parâmetros válidos para produtos
INSERT INTO aux.json_validation_params (param_name, param_value) VALUES
('subscriptions.plans', 'usage_limits.quotations'),
('subscriptions.plans', 'usage_limits.suppliers'),
('subscriptions.plans', 'usage_limits.items');
```

---

## 🚀 EXEMPLOS PRÁTICOS

### **1. Criar Produto Completo com Planos**

```sql
-- 1. Criar produto
INSERT INTO subscriptions.products (name, description, billing_model, is_available_for_establishment) 
VALUES ('Cotação e Comparação de Preços', 'Sistema de cotações', 'usage_limits', true)
RETURNING product_id;

-- 2. Criar nome do plano
INSERT INTO subscriptions.plan_names (name, description) 
VALUES ('Basic', 'Plano básico para pequenas empresas')
RETURNING plan_name_id;

-- 3. Criar plano
INSERT INTO subscriptions.plans (product_id, plan_name_id, valid_from, valid_to, price, usage_limits) 
VALUES (
    'uuid-do-produto',
    'uuid-do-nome-plano',
    '2025-01-01',
    '2025-12-31',
    199.90,
    '{"quotations": 100, "suppliers": 10, "items": 50}'
);
```

### **2. Criar Assinatura para Establishment**

```sql
-- 1. Assinatura já deve existir em subscriptions.products e subscriptions.plans
-- 2. Criar assinatura
INSERT INTO subscriptions.subscriptions (
    establishment_id, plan_id, employee_id, start_date, end_date, status
) VALUES (
    'uuid-do-establishment',
    'uuid-do-plano',
    'uuid-do-employee',
    '2025-01-01',
    '2025-12-31',
    'active'
);
```

### **3. Tracking de Uso Automático**

```sql
-- O sistema automaticamente:
-- 1. Cria registros em usage_tracking
-- 2. Atualiza quotations_used
-- 3. Calcula quotations_limit
-- 4. Define is_over_limit
```

---

## 🔧 MANUTENÇÃO E MONITORAMENTO

### **Verificar Status das Tabelas**

```sql
-- Listar todas as tabelas do schema subscriptions
SELECT table_name, table_type 
FROM information_schema.tables 
WHERE table_schema = 'subscriptions'
ORDER BY table_name;

-- Verificar constraints ativas
SELECT 
    constraint_name,
    table_name,
    constraint_type
FROM information_schema.table_constraints 
WHERE table_schema = 'subscriptions'
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
WHERE trigger_schema = 'subscriptions'
  AND trigger_name LIKE '%validation%'
ORDER BY event_object_table;
```

### **Verificar Auditoria**

```sql
-- Listar tabelas auditadas
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'audit' 
  AND table_name LIKE 'subscriptions__%'
ORDER BY table_name;
```

---

## ⚠️ IMPORTANTE

### **Validações Automáticas**
- Todas as tabelas têm validação automática via schema `aux`
- Triggers são criados automaticamente via schema `aux`
- Auditoria é aplicada automaticamente via schema `audit`
- Validação JSONB é automática via `aux.json_validation_params`

### **Ordem de Criação**
1. **products** (produto base)
2. **plan_names** (nomes dos planos)
3. **plans** (configuração dos planos)
4. **product_modules** (módulos do produto)
5. **subscriptions** (assinaturas dos clientes)
6. **usage_tracking** (controle de uso)
7. **quota_purchases** (microtransações)
8. **plan_changes** (histórico de mudanças)

### **Boas Práticas**
- Sempre use as funções de validação do schema `aux`
- Configure `aux.json_validation_params` antes de inserir dados
- Crie auditoria para todas as tabelas novas
- Mantenha relacionamentos consistentes
- Use transações para operações complexas

---

## 📚 RECURSOS ADICIONAIS

- **[README.md](README.md)** - Documentação geral do projeto
- **[schemas/aux/README_SCHEMA_AUX.md](schemas/aux/README_SCHEMA_AUX.md)** - Funções auxiliares e validações
- **[schemas/audit/README_SCHEMA_AUDIT.md](schemas/audit/README_SCHEMA_AUDIT.md)** - Sistema de auditoria

---

## **🔗 INTEGRAÇÃO COM BILLING**

O schema `subscriptions` integra-se com o schema `billing` para processamento financeiro:

### **📊 FLUXO DE INTEGRAÇÃO:**

1. **Criação de assinatura** → Gera transação em `billing.transactions`
2. **Renovação automática** → Cria nova transação em `billing.transactions`
3. **Compra de cotas** → Gera transação para microtransação
4. **Mudança de plano** → Pode gerar transações de upgrade/downgrade

### **🔗 REFERÊNCIAS:**

- **`business_reference`** em `billing.transactions` aponta para `subscriptions.subscriptions`
- **Validação JSONB** garante integridade das referências
- **Auditoria completa** rastreia todas as operações financeiras

**📚 Para mais detalhes, consulte: [README_SCHEMA_BILLING.md](../billing/README_SCHEMA_BILLING.md)**

---

**🎯 Lembre-se: O schema `subscriptions` é fundamental para o modelo de negócio SaaS. Mantenha a integridade dos dados e use sempre as validações automáticas!**
