# 📋 SCHEMA: billing

## **📁 ESTRUTURA DE ARQUIVOS**

O schema `billing` é composto pelos seguintes arquivos:

### **🏗️ Arquivo Principal:**
- **`billing_schema.sql`** - Script principal de criação do schema completo

### **📋 Arquivos de Tabelas Individuais:**
- **`transaction_statuses.sql`** - Status das transações financeiras
- **`payment_types.sql`** - Tipos de pagamento disponíveis
- **`installment_statuses.sql`** - Status das parcelas/installments
- **`invoice_statuses.sql`** - Status dos invoices/documentos
- **`transactions.sql`** - Transações financeiras principais
- **`expected_payments.sql`** - Pagamentos esperados
- **`installments.sql`** - Parcelas dos pagamentos
- **`invoices.sql`** - Documentos de pagamento (boletos, recibos)
- **`payment_attempts.sql`** - Tentativas de pagamento
- **`transaction_timeline.sql`** - Timeline de eventos

### **⚙️ Arquivos de Funcionalidades:**
- **`functions.sql`** - Funções PL/pgSQL para gestão e consultas
- **`views.sql`** - Views para relatórios e análises
- **`triggers.sql`** - Triggers de validação e lógica de negócio

### **📚 Documentação:**
- **`README_SCHEMA_BILLING.md`** - Esta documentação completa

---

## **🎯 VISÃO GERAL**

O schema `billing` é responsável por **processamento financeiro e faturamento agnóstico ao negócio**. Ele gerencia transações financeiras de forma genérica, suportando múltiplos métodos de pagamento, parcelamentos e rastreamento completo de eventos.

### **🔑 CARACTERÍSTICAS PRINCIPAIS**

- **🔄 Agnóstico ao Negócio**: Processa qualquer tipo de transação (assinaturas, compras, serviços)
- **💳 Múltiplos Métodos**: Cartão, PIX, boleto, faturado
- **📅 Parcelamento**: Suporte completo a installments
- **📊 Timeline Completa**: Rastreamento de todos os eventos
- **🔒 Auditoria**: Integração com sistema de auditoria
- **✅ Validação JSONB**: Validação automática de campos JSONB

---

## **🏗️ ESTRUTURA DAS TABELAS**

### **📊 TABELAS DE DOMÍNIO**

#### **`transaction_statuses`**
Status possíveis para transações financeiras.

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `status_id` | `uuid` | Identificador único |
| `name` | `text` | Nome do status |
| `description` | `text` | Descrição clara |
| `is_active` | `boolean` | Status ativo |
| `created_at` | `timestamp` | Data de criação |
| `updated_at` | `timestamp` | Última atualização |

**Status disponíveis:**
- `pending` - Transação pendente de processamento
- `processing` - Transação sendo processada
- `completed` - Transação concluída com sucesso
- `failed` - Transação falhou
- `cancelled` - Transação cancelada
- `refunded` - Transação estornada

#### **`payment_types`**
Tipos de pagamento disponíveis.

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `payment_type_id` | `uuid` | Identificador único |
| `name` | `text` | Nome do tipo |
| `description` | `text` | Descrição |
| `supports_installments` | `boolean` | Suporta parcelamento |
| `is_active` | `boolean` | Tipo ativo |
| `created_at` | `timestamp` | Data de criação |
| `updated_at` | `timestamp` | Última atualização |

**Tipos disponíveis:**
- `credit_card` - Cartão de crédito (suporta parcelamento)
- `debit_card` - Cartão de débito
- `pix` - Transferência PIX
- `boleto` - Boleto bancário
- `invoiced` - Faturado (30/60/90 dias) (suporta parcelamento)

#### **`installment_statuses`**
Status possíveis para parcelas/installments.

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `status_id` | `uuid` | Identificador único |
| `name` | `text` | Nome do status |
| `description` | `text` | Descrição clara |
| `is_active` | `boolean` | Status ativo |
| `created_at` | `timestamp` | Data de criação |
| `updated_at` | `timestamp` | Última atualização |

**Status disponíveis:**
- `pending` - Parcela pendente de pagamento
- `due` - Parcela vencida (inclui em atraso)
- `paid` - Parcela paga
- `cancelled` - Parcela cancelada

#### **`invoice_statuses`**
Status possíveis para invoices/documentos de pagamento.

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `status_id` | `uuid` | Identificador único |
| `name` | `text` | Nome do status |
| `description` | `text` | Descrição clara |
| `is_active` | `boolean` | Status ativo |
| `created_at` | `timestamp` | Data de criação |
| `updated_at` | `timestamp` | Última atualização |

**Status disponíveis:**
- `generated` - Invoice gerado
- `sent` - Invoice enviado
- `overdue` - Invoice vencido
- `paid` - Invoice pago
- `cancelled` - Invoice cancelado

### **📊 TABELAS PRINCIPAIS**

#### **`transactions`**
Transações financeiras principais (agnósticas ao negócio).

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `transaction_id` | `uuid` | Identificador único |
| `business_reference` | `jsonb` | Referência ao negócio |
| `amount` | `numeric(10,2)` | Valor total |
| `currency` | `text` | Moeda (padrão: BRL) |
| `status_id` | `uuid` | Status da transação |
| `payment_type_id` | `uuid` | Tipo de pagamento |
| `total_installments` | `integer` | Número de parcelas |
| `created_at` | `timestamp` | Data de criação |
| `updated_at` | `timestamp` | Última atualização |

**Exemplo de `business_reference`:**
```json
{
  "schema": "subscriptions",
  "table": "subscriptions", 
  "id": "uuid-da-assinatura"
}
```

#### **`expected_payments`**
Pagamentos esperados baseados nas transações.

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `expected_payment_id` | `uuid` | Identificador único |
| `transaction_id` | `uuid` | Referência à transação |
| `payment_method` | `text` | Método de pagamento |
| `gateway_name` | `text` | Nome do gateway |
| `amount` | `numeric(10,2)` | Valor esperado |
| `created_at` | `timestamp` | Data de criação |
| `updated_at` | `timestamp` | Última atualização |

#### **`installments`**
Parcelas/installments dos pagamentos esperados.

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `installment_id` | `uuid` | Identificador único |
| `expected_payment_id` | `uuid` | Referência ao pagamento |
| `installment_number` | `integer` | Número da parcela |
| `amount` | `numeric(10,2)` | Valor da parcela |
| `due_date` | `date` | Data de vencimento |
| `status_id` | `uuid` | Status da parcela |
| `payment_attempt_id` | `uuid` | Tentativa de pagamento |
| `created_at` | `timestamp` | Data de criação |
| `updated_at` | `timestamp` | Última atualização |

#### **`invoices`**
Documentos de pagamento (boletos, recibos, etc.).

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `invoice_id` | `uuid` | Identificador único |
| `expected_payment_id` | `uuid` | Referência ao pagamento |
| `invoice_number` | `text` | Número do documento |
| `barcode` | `text` | Código de barras |
| `amount` | `numeric(10,2)` | Valor do invoice |
| `due_date` | `date` | Data de vencimento |
| `status_id` | `uuid` | Status do invoice |
| `payment_date` | `date` | Data do pagamento |
| `gateway_payload` | `jsonb` | Payload do gateway |
| `created_at` | `timestamp` | Data de criação |
| `updated_at` | `timestamp` | Última atualização |

#### **`payment_attempts`**
Tentativas de pagamento para um expected_payment.

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `attempt_id` | `uuid` | Identificador único |
| `expected_payment_id` | `uuid` | Referência ao pagamento |
| `payment_method` | `text` | Método usado |
| `gateway_name` | `text` | Gateway usado |
| `status` | `text` | Status da tentativa |
| `gateway_payload` | `jsonb` | Payload do gateway |
| `failure_reason` | `text` | Motivo da falha |
| `created_at` | `timestamp` | Data de criação |
| `updated_at` | `timestamp` | Última atualização |

**Status disponíveis:**
- `success` - Tentativa bem-sucedida
- `failed` - Tentativa falhou
- `pending` - Tentativa pendente
- `cancelled` - Tentativa cancelada

#### **`transaction_timeline`**
Timeline completa de eventos de uma transação.

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `event_id` | `uuid` | Identificador único |
| `transaction_id` | `uuid` | Referência à transação |
| `event_type` | `text` | Tipo do evento |
| `description` | `text` | Descrição do evento |
| `metadata` | `jsonb` | Dados específicos |
| `created_at` | `timestamp` | Data do evento |

**Tipos de evento:**
- `created` - Transação criada
- `payment_attempt` - Tentativa de pagamento
- `success` - Pagamento bem-sucedido
- `failure` - Falha no pagamento
- `installment_paid` - Parcela paga
- `invoice_generated` - Invoice gerado

---

## **🔗 RELACIONAMENTOS**

### **📊 DIAGRAMA DE RELACIONAMENTOS**

```
transactions (1) ←→ (N) expected_payments
expected_payments (1) ←→ (N) installments
expected_payments (1) ←→ (N) invoices
expected_payments (1) ←→ (N) payment_attempts
transactions (1) ←→ (N) transaction_timeline
```

### **🔑 CHAVES ESTRANGEIRAS**

- **`transactions.status_id`** → `transaction_statuses.status_id`
- **`transactions.payment_type_id`** → `payment_types.payment_type_id`
- **`expected_payments.transaction_id`** → `transactions.transaction_id`
- **`installments.expected_payment_id`** → `expected_payments.expected_payment_id`
- **`installments.status_id`** → `installment_statuses.status_id`
- **`installments.payment_attempt_id`** → `payment_attempts.attempt_id`
- **`invoices.expected_payment_id`** → `expected_payments.expected_payment_id`
- **`invoices.status_id`** → `invoice_statuses.status_id`
- **`payment_attempts.expected_payment_id`** → `expected_payments.expected_payment_id`
- **`transaction_timeline.transaction_id`** → `transactions.transaction_id`

---

## **🚀 FUNCIONALIDADES**

### **✅ VALIDAÇÃO JSONB AUTOMÁTICA**

O campo `business_reference` é validado automaticamente via `aux.json_validation_params`:

```sql
-- Configuração automática
SELECT aux.create_json_validation_trigger('billing', 'transactions', 'business_reference');
```

**Parâmetros de validação:**
- `business_reference.schema` - Schema de referência
- `business_reference.table` - Tabela de referência  
- `business_reference.id` - ID de referência

### **⏰ TRIGGERS AUTOMÁTICOS**

Todas as tabelas possuem trigger `updated_at` automático:

```sql
-- Aplicado automaticamente
SELECT aux.create_updated_at_trigger('billing', 'nome_tabela');
```

### **📊 AUDITORIA COMPLETA**

Todas as tabelas são auditadas automaticamente:

```sql
-- Criação automática de tabelas de auditoria
SELECT audit.create_audit_table('billing', 'nome_tabela');
```

---

## **💡 CENÁRIOS DE USO**

### **🔄 CENÁRIO 1: CARTÃO DE CRÉDITO SEM PARCELAMENTO**

1. **Criar transação** em `transactions`
2. **Criar expected_payment** com método `credit_card`
3. **Criar installment** único (número 1)
4. **Criar payment_attempt** para processar
5. **Atualizar status** para `completed` quando aprovado

### **📅 CENÁRIO 2: CARTÃO DE CRÉDITO PARCELADO (12x)**

1. **Criar transação** com `total_installments = 12`
2. **Criar expected_payment** com método `credit_card`
3. **Criar 12 installments** com datas de vencimento mensais
4. **Processar payment_attempt** para aprovação
5. **Status da transação** = `completed`, installments = `pending`

### **📄 CENÁRIO 3: FATURA DE 90 DIAS (3x)**

1. **Criar transação** com `total_installments = 3`
2. **Criar expected_payment** com método `invoiced`
3. **Criar 3 installments** (30, 60, 90 dias)
4. **Gerar invoices** para cada parcela
5. **Status da transação** = `completed`, installments = `due`

### **🔄 CENÁRIO 4: MÚLTIPLAS TENTATIVAS + TROCA DE MEIO**

1. **Criar transação** e `expected_payment`
2. **Primeira tentativa** com cartão (falha)
3. **Segunda tentativa** com outro cartão (falha)
4. **Terceira tentativa** com PIX (sucesso)
5. **Timeline** registra todas as tentativas

---

## **📋 ORDEM DE CRIAÇÃO**

### **🔧 DEPENDÊNCIAS EXTERNAS**

1. **Schema `aux`** - Funções utilitárias
2. **Schema `audit`** - Sistema de auditoria

### **📊 ORDEM INTERNA**

1. **Tabelas de domínio** (statuses, types)
2. **Tabela principal** (`transactions`)
3. **Tabelas de suporte** (`expected_payments`, `installments`)
4. **Tabelas de documentos** (`invoices`, `payment_attempts`)
5. **Timeline** (`transaction_timeline`)
6. **Chaves estrangeiras**
7. **Triggers e auditoria**

---

## **🛠️ MANUTENÇÃO**

### **🧹 LIMPEZA PERIÓDICA**

```sql
-- Limpar eventos antigos da timeline
DELETE FROM billing.transaction_timeline 
WHERE created_at < NOW() - INTERVAL '2 years';

-- Limpar tentativas de pagamento antigas
DELETE FROM billing.payment_attempts 
WHERE created_at < NOW() - INTERVAL '1 year';
```

### **📊 MONITORAMENTO**

```sql
-- Verificar transações pendentes
SELECT COUNT(*) FROM billing.transactions 
WHERE status_id = (SELECT status_id FROM billing.transaction_statuses WHERE name = 'pending');

-- Verificar parcelas vencidas
SELECT COUNT(*) FROM billing.installments 
WHERE status_id = (SELECT status_id FROM billing.installment_statuses WHERE name = 'due');
```

---

## **⚠️ IMPORTANTE**

### **🔒 SEGURANÇA**

- **Nenhum dado sensível** é armazenado (PII fica no gateway)
- **Apenas tokens** e referências são mantidos
- **Auditoria completa** de todas as operações

### **🔄 INTEGRAÇÃO**

- **Sem integração direta** com outros schemas via triggers
- **Toda lógica de negócio** deve ser implementada externamente
- **Billing é agnóstico** ao tipo de transação

### **📱 RESPONSABILIDADES**

- **Billing**: Processamento financeiro e rastreamento
- **Aplicação**: Lógica de negócio e orquestração
- **Gateway**: Armazenamento de dados sensíveis

---

## **📚 RECURSOS ADICIONAIS**

- **[billing_schema.sql](billing_schema.sql)** - Script principal de criação
- **[functions.sql](functions.sql)** - Funções específicas do schema
- **[views.sql](views.sql)** - Views úteis para consultas
- **[triggers.sql](triggers.sql)** - Triggers de negócio

---

## **🎯 PRÓXIMOS PASSOS**

1. **Implementar funções** específicas de billing
2. **Criar views** para relatórios e consultas
3. **Implementar triggers** de negócio
4. **Criar schema `wallet`** para créditos
5. **Testar** todos os cenários implementados

---

*Schema `billing` - Sistema de Faturamento e Processamento Financeiro*
