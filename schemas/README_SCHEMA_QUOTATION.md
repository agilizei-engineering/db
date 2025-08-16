# 💰 SCHEMA: `quotation` - SISTEMA DE COTAÇÕES

## 🎯 VISÃO GERAL

O schema `quotation` implementa um sistema completo de cotações e listas de compras para estabelecimentos. Ele permite a criação de listas de compras, submissão de cotações para fornecedores e comparação de preços de forma eficiente e auditável.

---

## 📋 TABELAS PRINCIPAIS

### **🛒 Listas de Compras**

#### **`shopping_lists`** - Listas de Compras
- **Descrição**: Listas de compras dos estabelecimentos
- **Campos principais**: `shopping_list_id`, `establishment_id`, `name`, `description`, `status`, `created_at`, `updated_at`
- **Funcionalidades**: Criação e gestão de listas de compras
- **Relacionamentos**: Foreign key para `accounts.establishments.establishment_id`
- **Auditoria**: Automática via schema `audit`

#### **`shopping_list_items`** - Itens das Listas
- **Descrição**: Itens específicos das listas de compras com decomposição
- **Campos principais**: `item_id`, `shopping_list_id`, `product_id`, `variant_id`, `quantity`, `unit_price`, `notes`
- **Funcionalidades**: Controle de itens, preços e quantidades
- **Relacionamentos**: Foreign keys para `catalogs.products` e `catalogs.variants`
- **Auditoria**: Automática via schema `audit`

---

### **📝 Submissões de Cotações**

#### **`quotation_submissions`** - Submissões de Cotação
- **Descrição**: Submissões de cotações para fornecedores
- **Campos principais**: `submission_id`, `shopping_list_id`, `supplier_id`, `status`, `submitted_at`, `valid_until`
- **Funcionalidades**: Controle de submissões, prazos de validade
- **Relacionamentos**: Foreign keys para `shopping_lists` e `accounts.establishments` (fornecedor)
- **Auditoria**: Automática via schema `audit`

#### **`submission_statuses`** - Status das Submissões
- **Descrição**: Estados possíveis para submissões de cotação
- **Campos principais**: `status_id`, `name`, `description`, `is_active`
- **Funcionalidades**: Controle de fluxo de trabalho
- **Valores típicos**: 'DRAFT', 'SUBMITTED', 'IN_REVIEW', 'APPROVED', 'REJECTED'
- **Auditoria**: Automática via schema `audit`

---

### **💼 Cotações dos Fornecedores**

#### **`supplier_quotations`** - Cotações dos Fornecedores
- **Descrição**: Cotações recebidas dos fornecedores
- **Campos principais**: `quotation_id`, `submission_id`, `supplier_id`, `status`, `quoted_at`, `valid_until`, `total_amount`
- **Funcionalidades**: Controle de cotações, prazos, valores totais
- **Relacionamentos**: Foreign keys para `quotation_submissions` e `accounts.establishments`
- **Auditoria**: Automática via schema `audit`

#### **`supplier_quotation_statuses`** - Status das Cotações
- **Descrição**: Estados possíveis para cotações dos fornecedores
- **Campos principais**: `status_id`, `name`, `description`, `is_active`
- **Funcionalidades**: Controle de fluxo de trabalho das cotações
- **Valores típicos**: 'RECEIVED', 'UNDER_REVIEW', 'APPROVED', 'REJECTED', 'EXPIRED'
- **Auditoria**: Automática via schema `audit`

---

### **💰 Preços Cotados**

#### **`quoted_prices`** - Preços Cotados
- **Descrição**: Preços específicos cotados para itens
- **Campos principais**: `price_id`, `quotation_id`, `item_id`, `unit_price`, `quantity`, `discount_percentage`, `delivery_time`, `payment_terms`
- **Funcionalidades**: Controle de preços, descontos, condições comerciais
- **Relacionamentos**: Foreign keys para `supplier_quotations` e `shopping_list_items`
- **Auditoria**: Automática via schema `audit`

---

## 🔍 FUNCIONALIDADES PRINCIPAIS

### **Gestão de Listas de Compras**
- Criação de listas organizadas por estabelecimento
- Controle de itens com quantidades e preços estimados
- Rastreamento de status e mudanças

### **Submissão de Cotações**
- Envio de listas para múltiplos fornecedores
- Controle de prazos de submissão
- Rastreamento de status de cada submissão

### **Recebimento de Cotações**
- Captura de cotações dos fornecedores
- Controle de prazos de validade
- Comparação de preços e condições

### **Análise e Comparação**
- Comparação de preços entre fornecedores
- Análise de condições comerciais
- Relatórios de competitividade

---

## 📊 VIEWS ÚTEIS

### **`v_shopping_lists_complete`**
Listas de compras com informações completas.

```sql
-- Consultar listas completas
SELECT * FROM quotation.v_shopping_lists_complete;

-- Retorna listas com estabelecimento, status e contagem de itens
-- Ideal para dashboards e relatórios
```

### **`v_quotations_comparison`**
Comparação de cotações entre fornecedores.

```sql
-- Comparar cotações
SELECT * FROM quotation.v_quotations_comparison;

-- Retorna comparação de preços e condições
-- Útil para análise de competitividade
```

### **`v_submissions_status`**
Status de todas as submissões.

```sql
-- Verificar status das submissões
SELECT * FROM quotation.v_submissions_status;

-- Retorna status atual de todas as submissões
-- Ideal para acompanhamento de processos
```

---

## 🚀 EXEMPLOS PRÁTICOS

### **1. Criar Lista de Compras Completa**

```sql
-- 1. Criar lista de compras
INSERT INTO quotation.shopping_lists (establishment_id, name, description) 
VALUES ('uuid-estabelecimento', 'Lista de Compras Janeiro 2025', 'Produtos para o primeiro mês do ano')
RETURNING shopping_list_id;

-- 2. Adicionar itens à lista
INSERT INTO quotation.shopping_list_items (shopping_list_id, product_id, variant_id, quantity, unit_price) VALUES 
('uuid-lista', 'uuid-produto-1', 'uuid-variacao-1', 100, 2.50),
('uuid-lista', 'uuid-produto-2', 'uuid-variacao-2', 50, 5.00);
```

### **2. Submeter Cotação para Fornecedores**

```sql
-- 1. Criar submissão para fornecedor A
INSERT INTO quotation.quotation_submissions (shopping_list_id, supplier_id, status, valid_until) 
VALUES ('uuid-lista', 'uuid-fornecedor-a', 'SUBMITTED', '2025-02-15')
RETURNING submission_id;

-- 2. Criar submissão para fornecedor B
INSERT INTO quotation.quotation_submissions (shopping_list_id, supplier_id, status, valid_until) 
VALUES ('uuid-lista', 'uuid-fornecedor-b', 'SUBMITTED', '2025-02-15')
RETURNING submission_id;
```

### **3. Receber Cotação do Fornecedor**

```sql
-- 1. Criar cotação do fornecedor
INSERT INTO quotation.supplier_quotations (submission_id, supplier_id, status, quoted_at, valid_until, total_amount) 
VALUES ('uuid-submissao', 'uuid-fornecedor', 'RECEIVED', NOW(), '2025-02-20', 1250.00)
RETURNING quotation_id;

-- 2. Adicionar preços específicos
INSERT INTO quotation.quoted_prices (quotation_id, item_id, unit_price, quantity, discount_percentage, delivery_time) VALUES 
('uuid-cotacao', 'uuid-item-1', 2.30, 100, 8.00, '7 dias'),
('uuid-cotacao', 'uuid-item-2', 4.80, 50, 4.00, '5 dias');
```

### **4. Aprovar Cotação**

```sql
-- Atualizar status da cotação para aprovada
UPDATE quotation.supplier_quotations 
SET status = 'APPROVED' 
WHERE quotation_id = 'uuid-cotacao';

-- Atualizar status da submissão
UPDATE quotation.quotation_submissions 
SET status = 'APPROVED' 
WHERE submission_id = 'uuid-submissao';
```

---

## 🔍 CONSULTAS AVANÇADAS

### **Comparação de Preços**

```sql
-- Comparar preços entre fornecedores
SELECT 
    sl.name as lista_compras,
    p.name as produto,
    v.name as variacao,
    sli.quantity as quantidade_solicitada,
    sli.unit_price as preco_estimado,
    qp.unit_price as preco_cotado,
    qp.discount_percentage as desconto,
    e.name as fornecedor,
    qp.delivery_time as prazo_entrega
FROM quotation.shopping_lists sl
JOIN quotation.shopping_list_items sli ON sl.shopping_list_id = sli.shopping_list_id
JOIN catalogs.products p ON sli.product_id = p.product_id
JOIN catalogs.variants v ON sli.variant_id = v.variant_id
JOIN quotation.quotation_submissions qs ON sl.shopping_list_id = qs.shopping_list_id
JOIN quotation.supplier_quotations sq ON qs.submission_id = sq.submission_id
JOIN quotation.quoted_prices qp ON sq.quotation_id = qp.quotation_id
JOIN accounts.establishments e ON sq.supplier_id = e.establishment_id
WHERE sl.shopping_list_id = 'uuid-lista'
ORDER BY p.name, qp.unit_price;
```

### **Análise de Competitividade**

```sql
-- Análise de competitividade por fornecedor
SELECT 
    e.name as fornecedor,
    COUNT(DISTINCT sq.quotation_id) as total_cotacoes,
    AVG(qp.unit_price) as preco_medio,
    AVG(qp.discount_percentage) as desconto_medio,
    AVG(qp.delivery_time) as prazo_medio_entrega,
    SUM(qp.unit_price * qp.quantity) as valor_total_cotado
FROM quotation.supplier_quotations sq
JOIN accounts.establishments e ON sq.supplier_id = e.establishment_id
JOIN quotation.quoted_prices qp ON sq.quotation_id = qp.quotation_id
WHERE sq.status = 'RECEIVED'
GROUP BY e.establishment_id, e.name
ORDER BY valor_total_cotado DESC;
```

### **Relatório de Eficiência**

```sql
-- Relatório de eficiência das submissões
SELECT 
    sl.name as lista_compras,
    sl.created_at as data_criacao,
    COUNT(DISTINCT qs.submission_id) as total_submissoes,
    COUNT(DISTINCT CASE WHEN qs.status = 'APPROVED' THEN qs.submission_id END) as submissoes_aprovadas,
    COUNT(DISTINCT CASE WHEN qs.status = 'REJECTED' THEN qs.submission_id END) as submissoes_rejeitadas,
    ROUND(
        COUNT(DISTINCT CASE WHEN qs.status = 'APPROVED' THEN qs.submission_id END)::numeric / 
        COUNT(DISTINCT qs.submission_id)::numeric * 100, 2
    ) as taxa_aprovacao
FROM quotation.shopping_lists sl
LEFT JOIN quotation.quotation_submissions qs ON sl.shopping_list_id = qs.shopping_list_id
GROUP BY sl.shopping_list_id, sl.name, sl.created_at
ORDER BY sl.created_at DESC;
```

---

## 🔧 MANUTENÇÃO E MONITORAMENTO

### **Verificar Status das Submissões**

```sql
-- Status atual das submissões
SELECT 
    sl.name as lista_compras,
    e.name as fornecedor,
    qs.status as status_submissao,
    qs.submitted_at as data_submissao,
    qs.valid_until as valido_ate
FROM quotation.shopping_lists sl
JOIN quotation.quotation_submissions qs ON sl.shopping_list_id = qs.shopping_list_id
JOIN accounts.establishments e ON qs.supplier_id = e.establishment_id
WHERE qs.status NOT IN ('APPROVED', 'REJECTED')
ORDER BY qs.valid_until;
```

### **Verificar Cotações Expiradas**

```sql
-- Cotações com prazo expirado
SELECT 
    sq.quotation_id,
    e.name as fornecedor,
    sq.quoted_at as data_cotacao,
    sq.valid_until as valido_ate,
    sq.total_amount as valor_total
FROM quotation.supplier_quotations sq
JOIN accounts.establishments e ON sq.supplier_id = e.establishment_id
WHERE sq.valid_until < CURRENT_DATE
  AND sq.status = 'RECEIVED'
ORDER BY sq.valid_until;
```

### **Verificar Auditoria**

```sql
-- Listar tabelas auditadas
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'audit' 
  AND table_name LIKE 'quotation__%'
ORDER BY table_name;
```

---

## ⚠️ IMPORTANTE

### **Validações Automáticas**
- Datas de validade são validadas automaticamente
- Valores monetários são validados via `aux.moeda`
- Auditoria é aplicada automaticamente via schema `audit`

### **Ordem de Criação**
1. **shopping_lists** (lista de compras)
2. **shopping_list_items** (itens da lista)
3. **quotation_submissions** (submissões)
4. **supplier_quotations** (cotações recebidas)
5. **quoted_prices** (preços específicos)

### **Boas Práticas**
- Sempre defina prazos de validade realistas
- Monitore status das submissões regularmente
- Compare preços antes de aprovar cotações
- Use transações para operações complexas
- Mantenha histórico completo via auditoria

---

## 📚 RECURSOS ADICIONAIS

- **[README.md](README.md)** - Documentação geral do projeto
- **[README_SCHEMAS.md](README_SCHEMAS.md)** - Visão geral de todos os schemas
- **[README_SCHEMA_ACCOUNTS.md](README_SCHEMA_ACCOUNTS.md)** - Schema de autenticação
- **[README_SCHEMA_CATALOGS.md](README_SCHEMA_CATALOGS.md)** - Schema de catálogo
- **[README_SCHEMA_AUX.md](README_SCHEMA_AUX.md)** - Funções auxiliares e validações
- **[README_SCHEMA_AUDIT.md](README_SCHEMA_AUDIT.md)** - Sistema de auditoria

---

**🎯 Lembre-se: O schema `quotation` é essencial para o controle de compras. Mantenha os prazos atualizados e monitore o status das submissões regularmente!**
