# 🛍️ SCHEMA: `catalogs` - CATÁLOGO DE PRODUTOS

## 🎯 VISÃO GERAL

O schema `catalogs` gerencia todo o catálogo de produtos do sistema, incluindo categorias, marcas, variações e composições. Ele implementa uma estrutura hierárquica flexível para organizar produtos de forma eficiente e permitir buscas avançadas.

---

## 📋 TABELAS PRINCIPAIS

### **🏷️ Estrutura Hierárquica**

#### **`categories`** - Categorias Principais
- **Descrição**: Categorias principais de produtos
- **Campos principais**: `category_id`, `name`, `description`, `is_active`
- **Funcionalidades**: Organização principal do catálogo
- **Auditoria**: Automática via schema `audit`

#### **`subcategories`** - Subcategorias
- **Descrição**: Subcategorias dentro das categorias principais
- **Campos principais**: `subcategory_id`, `category_id`, `name`, `description`, `is_active`
- **Funcionalidades**: Organização hierárquica de produtos
- **Relacionamentos**: Foreign key para `categories.category_id`
- **Auditoria**: Automática via schema `audit`

---

### **🏭 Marcas e Identificação**

#### **`brands`** - Marcas dos Produtos
- **Descrição**: Marcas e fabricantes dos produtos
- **Campos principais**: `brand_id`, `name`, `description`, `logo_url`, `is_active`
- **Funcionalidades**: Identificação de marcas, controle de qualidade
- **Validações**: URL do logo via `aux.validate_url()`
- **Auditoria**: Automática via schema `audit`

---

### **📦 Produtos e Variações**

#### **`products`** - Produtos Base
- **Descrição**: Produtos principais do catálogo
- **Campos principais**: `product_id`, `name`, `description`, `category_id`, `subcategory_id`, `brand_id`, `is_active`
- **Funcionalidades**: Produto base com informações gerais
- **Relacionamentos**: Foreign keys para categorias, subcategorias e marcas
- **Auditoria**: Automática via schema `audit`

#### **`variants`** - Variações de Produtos
- **Descrição**: Variações específicas de um produto (cor, tamanho, etc.)
- **Campos principais**: `variant_id`, `product_id`, `name`, `description`, `sku`, `is_active`
- **Funcionalidades**: Controle de variações, SKU único
- **Relacionamentos**: Foreign key para `products.product_id`
- **Auditoria**: Automática via schema `audit`

---

### **🧩 Composição e Características**

#### **`compositions`** - Composições dos Produtos
- **Descrição**: Materiais e composições dos produtos
- **Campos principais**: `composition_id`, `name`, `description`, `is_active`
- **Funcionalidades**: Controle de materiais, busca por composição
- **Auditoria**: Automática via schema `audit`

#### **`fillings`** - Recheios
- **Descrição**: Tipos de recheio disponíveis
- **Campos principais**: `filling_id`, `name`, `description`, `is_active`
- **Funcionalidades**: Controle de recheios, busca por tipo
- **Auditoria**: Automática via schema `audit`

#### **`flavors`** - Sabores
- **Descrição**: Sabores disponíveis para produtos
- **Campos principais**: `flavor_id`, `name`, `description`, `is_active`
- **Funcionalidades**: Controle de sabores, busca por sabor
- **Auditoria**: Automática via schema `audit`

#### **`formats`** - Formatos
- **Descrição**: Formatos disponíveis para produtos
- **Campos principais**: `format_id`, `name`, `description`, `is_active`
- **Funcionalidades**: Controle de formatos, busca por formato
- **Auditoria**: Automática via schema `audit`

#### **`packagings`** - Embalagens
- **Descrição**: Tipos de embalagem disponíveis
- **Campos principais**: `packaging_id`, `name`, `description`, `is_active`
- **Funcionalidades**: Controle de embalagens, busca por tipo
- **Auditoria**: Automática via schema `audit`

---

### **📊 Controle de Estoque e Preços**

#### **`quantities`** - Quantidades Disponíveis
- **Descrição**: Controle de estoque por variação de produto
- **Campos principais**: `quantity_id`, `variant_id`, `available_quantity`, `reserved_quantity`, `minimum_stock`, `is_active`
- **Funcionalidades**: Controle de estoque, alertas de estoque baixo
- **Relacionamentos**: Foreign key para `variants.variant_id`
- **Auditoria**: Automática via schema `audit`

#### **`offers`** - Ofertas e Promoções
- **Descrição**: Ofertas especiais e promoções
- **Campos principais**: `offer_id`, `name`, `description`, `discount_percentage`, `start_date`, `end_date`, `is_active`
- **Funcionalidades**: Controle de promoções, datas de validade
- **Validações**: Datas válidas, percentual de desconto
- **Auditoria**: Automática via schema `audit`

---

## 🔍 FUNCIONALIDADES PRINCIPAIS

### **Sistema Hierárquico**
- **Categorias** → **Subcategorias** → **Produtos** → **Variações**
- Organização lógica e flexível
- Suporte a múltiplos níveis de categorização

### **Controle de Variações**
- Um produto pode ter múltiplas variações
- Cada variação tem SKU único
- Controle independente de estoque por variação

### **Características Flexíveis**
- Composições, recheios, sabores, formatos e embalagens
- Aplicáveis a qualquer produto
- Sistema de tags para busca avançada

### **Gestão de Estoque**
- Controle de quantidade disponível
- Quantidade reservada
- Alertas de estoque mínimo
- Rastreamento de movimentações

---

## 📊 VIEWS ÚTEIS

### **`v_products_complete`**
Produtos com todas as informações relacionadas.

```sql
-- Consultar produtos completos
SELECT * FROM catalogs.v_products_complete;

-- Retorna produtos com categoria, subcategoria, marca e variações
-- Ideal para listagens e catálogos
```

### **`v_variants_with_stock`**
Variações com informações de estoque.

```sql
-- Consultar variações com estoque
SELECT * FROM catalogs.v_variants_with_stock;

-- Retorna variações com quantidade disponível e reservada
-- Útil para controle de estoque
```

### **`v_categories_hierarchy`**
Hierarquia completa de categorias.

```sql
-- Consultar hierarquia de categorias
SELECT * FROM catalogs.v_categories_hierarchy;

-- Retorna estrutura hierárquica de categorias e subcategorias
-- Ideal para navegação e menus
```

---

## 🚀 EXEMPLOS PRÁTICOS

### **1. Criar Categoria Completa**

```sql
-- 1. Criar categoria principal
INSERT INTO catalogs.categories (name, description) 
VALUES ('Alimentos', 'Produtos alimentícios em geral')
RETURNING category_id;

-- 2. Criar subcategoria
INSERT INTO catalogs.subcategories (category_id, name, description) 
VALUES ('uuid-da-categoria', 'Doces', 'Produtos doces e sobremesas')
RETURNING subcategory_id;
```

### **2. Criar Produto com Variações**

```sql
-- 1. Criar produto base
INSERT INTO catalogs.products (name, description, category_id, subcategory_id, brand_id) 
VALUES ('Chocolate Premium', 'Chocolate artesanal de alta qualidade', 'uuid-categoria', 'uuid-subcategoria', 'uuid-marca')
RETURNING product_id;

-- 2. Criar variações
INSERT INTO catalogs.variants (product_id, name, description, sku) VALUES 
('uuid-produto', 'Chocolate 70%', 'Chocolate amargo 70% cacau', 'CHOC-70-001'),
('uuid-produto', 'Chocolate 85%', 'Chocolate extra amargo 85% cacau', 'CHOC-85-001');

-- 3. Adicionar estoque para cada variação
INSERT INTO catalogs.quantities (variant_id, available_quantity, minimum_stock) VALUES 
('uuid-variacao-70', 100, 20),
('uuid-variacao-85', 50, 10);
```

### **3. Criar Marca com Logo**

```sql
-- Criar marca
INSERT INTO catalogs.brands (name, description, logo_url) 
VALUES ('Chocolate Artesanal', 'Marca especializada em chocolates artesanais', 'https://example.com/logos/chocolate-artesanal.png')
RETURNING brand_id;
```

### **4. Criar Oferta Especial**

```sql
-- Criar oferta
INSERT INTO catalogs.offers (name, description, discount_percentage, start_date, end_date) 
VALUES ('Black Friday', 'Ofertas especiais de Black Friday', 25.00, '2025-11-29', '2025-11-30')
RETURNING offer_id;
```

---

## 🔍 BUSCAS AVANÇADAS

### **Busca por Categoria**

```sql
-- Produtos de uma categoria específica
SELECT 
    p.name as produto,
    s.name as subcategoria,
    b.name as marca
FROM catalogs.products p
JOIN catalogs.subcategories s ON p.subcategory_id = s.subcategory_id
JOIN catalogs.brands b ON p.brand_id = b.brand_id
WHERE s.category_id = 'uuid-categoria'
ORDER BY p.name;
```

### **Busca por Características**

```sql
-- Produtos com características específicas
SELECT 
    p.name as produto,
    c.name as composicao,
    f.name as recheio,
    fl.name as sabor
FROM catalogs.products p
JOIN catalogs.product_compositions pc ON p.product_id = pc.product_id
JOIN catalogs.compositions c ON pc.composition_id = c.composition_id
JOIN catalogs.product_fillings pf ON p.product_id = pf.product_id
JOIN catalogs.fillings f ON pf.filling_id = f.filling_id
JOIN catalogs.product_flavors pfl ON p.product_id = pfl.product_id
JOIN catalogs.flavors fl ON pfl.flavor_id = fl.flavor_id
WHERE c.name = 'Chocolate' AND f.name = 'Caramelo';
```

### **Busca por Estoque**

```sql
-- Produtos com estoque baixo
SELECT 
    p.name as produto,
    v.name as variacao,
    q.available_quantity as estoque_atual,
    q.minimum_stock as estoque_minimo
FROM catalogs.products p
JOIN catalogs.variants v ON p.product_id = v.product_id
JOIN catalogs.quantities q ON v.variant_id = q.variant_id
WHERE q.available_quantity <= q.minimum_stock
ORDER BY q.available_quantity;
```

---

## 🔧 MANUTENÇÃO E MONITORAMENTO

### **Verificar Estrutura do Catálogo**

```sql
-- Listar categorias e subcategorias
SELECT 
    c.name as categoria,
    s.name as subcategoria,
    COUNT(p.product_id) as total_produtos
FROM catalogs.categories c
LEFT JOIN catalogs.subcategories s ON c.category_id = s.category_id
LEFT JOIN catalogs.products p ON s.subcategory_id = p.subcategory_id
GROUP BY c.category_id, s.subcategory_id
ORDER BY c.name, s.name;

-- Listar produtos por marca
SELECT 
    b.name as marca,
    COUNT(p.product_id) as total_produtos
FROM catalogs.brands b
LEFT JOIN catalogs.products p ON b.brand_id = p.brand_id
GROUP BY b.brand_id
ORDER BY total_produtos DESC;
```

### **Verificar Estoque**

```sql
-- Resumo de estoque
SELECT 
    p.name as produto,
    v.name as variacao,
    q.available_quantity as disponivel,
    q.reserved_quantity as reservado,
    (q.available_quantity - q.reserved_quantity) as estoque_livre
FROM catalogs.products p
JOIN catalogs.variants v ON p.product_id = v.product_id
JOIN catalogs.quantities q ON v.variant_id = q.variant_id
WHERE q.is_active = true
ORDER BY estoque_livre;
```

### **Verificar Auditoria**

```sql
-- Listar tabelas auditadas
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'audit' 
  AND table_name LIKE 'catalogs__%'
ORDER BY table_name;
```

---

## ⚠️ IMPORTANTE

### **Validações Automáticas**
- URLs de logos são validadas via `aux.validate_url()`
- Datas de ofertas são validadas automaticamente
- Auditoria é aplicada automaticamente via schema `audit`

### **Ordem de Criação**
1. **categories** (categorias principais)
2. **subcategories** (subcategorias)
3. **brands** (marcas)
4. **products** (produtos base)
5. **variants** (variações)
6. **quantities** (estoque)
7. **Características** (composições, recheios, etc.)

### **Boas Práticas**
- Use SKUs únicos para variações
- Mantenha hierarquia de categorias consistente
- Monitore estoque regularmente
- Use transações para operações complexas
- Crie auditoria para todas as tabelas

---

## 📚 RECURSOS ADICIONAIS

- **[README.md](README.md)** - Documentação geral do projeto
- **[README_SCHEMAS.md](README_SCHEMAS.md)** - Visão geral de todos os schemas
- **[README_SCHEMA_ACCOUNTS.md](README_SCHEMA_ACCOUNTS.md)** - Schema de autenticação
- **[README_SCHEMA_AUX.md](README_SCHEMA_AUX.md)** - Funções auxiliares e validações
- **[README_SCHEMA_AUDIT.md](README_SCHEMA_AUDIT.md)** - Sistema de auditoria

---

**🎯 Lembre-se: O schema `catalogs` é fundamental para a organização dos produtos. Mantenha a hierarquia consistente e use as validações automáticas!**
