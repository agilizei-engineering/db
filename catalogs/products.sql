-- Tabela de produtos do catálogo
-- Schema: catalogs
-- Tabela: products

-- Esta tabela é criada automaticamente pelo dump principal
-- Este arquivo serve como documentação e referência

/*
CREATE TABLE catalogs.products (
    product_id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    name text NOT NULL,
    description text,
    category_id uuid,
    subcategory_id uuid,
    brand_id uuid,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone,
    FOREIGN KEY (category_id) REFERENCES catalogs.categories(category_id),
    FOREIGN KEY (subcategory_id) REFERENCES catalogs.subcategories(subcategory_id),
    FOREIGN KEY (brand_id) REFERENCES catalogs.brands(brand_id)
);
*/

-- Campos principais:
-- product_id: Identificador único do produto (UUID)
-- name: Nome do produto
-- description: Descrição detalhada do produto
-- category_id: Categoria principal do produto
-- subcategory_id: Subcategoria do produto
-- brand_id: Marca do produto
-- is_active: Status ativo/inativo do produto
-- created_at: Data de criação
-- updated_at: Data da última atualização

-- Constraints:
-- PRIMARY KEY: product_id
-- FOREIGN KEY: category_id -> catalogs.categories.category_id
-- FOREIGN KEY: subcategory_id -> catalogs.subcategories.subcategory_id
-- FOREIGN KEY: brand_id -> catalogs.brands.brand_id

-- Triggers:
-- updated_at: Atualiza automaticamente o campo updated_at

-- Auditoria:
-- Automática via schema audit (audit.catalogs__products)

-- Relacionamentos:
-- catalogs.variants.product_id -> catalogs.products.product_id
-- quotation.shopping_list_items.product_id -> catalogs.products.product_id

-- Funcionalidades:
-- Produto base com informações gerais
-- Organização hierárquica por categoria e subcategoria
-- Vinculação com marca específica
-- Suporte a múltiplas variações por produto
