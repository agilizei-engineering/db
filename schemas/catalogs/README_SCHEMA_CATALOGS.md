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

#### **`variant_types`** - Tipos de Variações
- **Descrição**: Tipo ou variação específica do item (ex: Espaguete nº 08)
- **Campos principais**: `variant_type_id`, `name`, `description`, `created_at`, `updated_at`
- **Funcionalidades**: Definição de tipos de variações, controle de categorias
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

#### **`items`** - Itens Genéricos
- **Descrição**: Itens genéricos que representam o núcleo de um produto
- **Campos principais**: `item_id`, `subcategory_id`, `name`, `description`, `created_at`, `updated_at`
- **Funcionalidades**: Base para produtos específicos, busca genérica
- **Relacionamentos**: Foreign key para `subcategories.subcategory_id`
- **Auditoria**: Automática via schema `audit`

#### **`nutritional_variants`** - Variantes Nutricionais
- **Descrição**: Variações nutricionais (ex: Light, Zero, Sem Lactose)
- **Campos principais**: `nutritional_variant_id`, `name`, `description`, `created_at`, `updated_at`
- **Funcionalidades**: Controle de variantes nutricionais, busca por restrições
- **Auditoria**: Automática via schema `audit`

---

### **📊 Controle de Estoque e Preços**

#### **`quantities`** - Quantidades e Medidas
- **Descrição**: Tipos de quantidade e medida disponíveis para produtos
- **Campos principais**: `quantity_id`, `name`, `description`, `unit`, `is_active`
- **Funcionalidades**: Controle de unidades de medida, padronização de quantidades
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
- **Categorias** → **Subcategorias** → **Itens** → **Produtos**
- Organização lógica e flexível
- Suporte a múltiplos níveis de categorização

### **Controle de Características**
- Produtos podem ter múltiplas características
- Sistema flexível de composições, recheios, sabores, formatos
- Variantes nutricionais para controle de restrições alimentares

### **Características Flexíveis**
- Composições, recheios, sabores, formatos e embalagens
- Aplicáveis a qualquer produto
- Sistema de tags para busca avançada

### **Gestão de Características**
- Controle de composições e materiais
- Tipos de recheios e sabores
- Formatos e embalagens disponíveis
- Variantes nutricionais e restrições

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

### **`v_items_with_characteristics`**
Itens com todas as características aplicáveis.

```sql
-- Consultar itens com características
SELECT * FROM catalogs.v_items_with_characteristics;

-- Retorna itens com composições, recheios, sabores e formatos
-- Útil para busca avançada e filtros
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

### **2. Criar Item com Características**

```sql
-- 1. Criar item genérico
INSERT INTO catalogs.items (name, description, category_id) 
VALUES ('Chocolate Premium', 'Chocolate artesanal de alta qualidade', 'uuid-categoria')
RETURNING item_id;

-- 2. Criar produto específico
INSERT INTO catalogs.products (name, description, category_id, subcategory_id, brand_id) 
VALUES ('Chocolate Premium', 'Chocolate artesanal de alta qualidade', 'uuid-categoria', 'uuid-subcategoria', 'uuid-marca')
RETURNING product_id;

-- 3. Adicionar características
INSERT INTO catalogs.product_compositions (product_id, composition_id) VALUES 
('uuid-produto', 'uuid-chocolate-70'),
('uuid-produto', 'uuid-chocolate-85');

INSERT INTO catalogs.product_flavors (product_id, flavor_id) VALUES 
('uuid-produto', 'uuid-amargo'),
('uuid-produto', 'uuid-doce');
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

### **Busca por Características Nutricionais**

```sql
-- Produtos com variantes nutricionais específicas
SELECT 
    p.name as produto,
    nv.name as variante_nutricional,
    nv.description as descricao
FROM catalogs.products p
JOIN catalogs.product_nutritional_variants pnv ON p.product_id = pnv.product_id
JOIN catalogs.nutritional_variants nv ON pnv.nutritional_variant_id = nv.nutritional_variant_id
WHERE nv.name IN ('Sem Glúten', 'Sem Lactose', 'Vegano')
ORDER BY p.name, nv.name;
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

### **Verificar Características dos Produtos**

```sql
-- Resumo de características por produto
SELECT 
    p.name as produto,
    STRING_AGG(DISTINCT c.name, ', ') as composicoes,
    STRING_AGG(DISTINCT f.name, ', ') as recheios,
    STRING_AGG(DISTINCT fl.name, ', ') as sabores,
    STRING_AGG(DISTINCT nv.name, ', ') as variantes_nutricionais
FROM catalogs.products p
LEFT JOIN catalogs.product_compositions pc ON p.product_id = pc.product_id
LEFT JOIN catalogs.compositions c ON pc.composition_id = c.composition_id
LEFT JOIN catalogs.product_fillings pf ON p.product_id = pf.product_id
LEFT JOIN catalogs.fillings f ON pf.filling_id = f.filling_id
LEFT JOIN catalogs.product_flavors pfl ON p.product_id = pfl.product_id
LEFT JOIN catalogs.flavors fl ON pfl.flavor_id = fl.flavor_id
LEFT JOIN catalogs.product_nutritional_variants pnv ON p.product_id = pnv.product_id
LEFT JOIN catalogs.nutritional_variants nv ON pnv.nutritional_variant_id = nv.nutritional_variant_id
WHERE p.is_active = true
GROUP BY p.product_id, p.name
ORDER BY p.name;
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
4. **items** (itens genéricos)
5. **products** (produtos específicos)
6. **Características** (composições, recheios, sabores, formatos, embalagens)
7. **variant_types** (tipos de variações)
8. **nutritional_variants** (variantes nutricionais)
9. **quantities** (tipos de quantidade/medida)
10. **offers** (ofertas e promoções)

### **Boas Práticas**
- Mantenha hierarquia de categorias consistente
- Use itens genéricos como base para produtos específicos
- Organize características de forma lógica e reutilizável
- Monitore variantes nutricionais para controle de restrições
- Use transações para operações complexas
- Crie auditoria para todas as tabelas

---

## 📚 RECURSOS ADICIONAIS

- **[README.md](README.md)** - Documentação geral do projeto
- **[schemas/README_SCHEMA_ACCOUNTS.md](schemas/accounts/README_SCHEMA_ACCOUNTS.md)** - Schema de autenticação
- **[schemas/README_SCHEMA_AUX.md](schemas/aux/README_SCHEMA_AUX.md)** - Funções auxiliares e validações
- **[schemas/README_SCHEMA_AUDIT.md](schemas/audit/README_SCHEMA_AUDIT.md)** - Sistema de auditoria

---

**🎯 Lembre-se: O schema `catalogs` é fundamental para a organização dos produtos. Mantenha a hierarquia consistente e use as validações automáticas!**
