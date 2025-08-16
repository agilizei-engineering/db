-- =====================================================
-- TABELA: products - Produtos Comerciais
-- =====================================================
-- Descrição: Produtos comerciais que podem ser contratados pelos clientes
-- Funcionalidades: Definição de produtos, modelos de cobrança, disponibilidade por tipo de cliente

-- =====================================================
-- CRIAÇÃO DA TABELA
-- =====================================================

CREATE TABLE subscriptions.products (
    product_id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    description text,
    billing_model text NOT NULL,
    is_available_for_supplier boolean NOT NULL DEFAULT false,
    is_available_for_establishment boolean NOT NULL DEFAULT false,
    is_active boolean NOT NULL DEFAULT true,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now()
);

-- =====================================================
-- COMENTÁRIOS
-- =====================================================

COMMENT ON TABLE subscriptions.products IS 'Produtos comerciais que podem ser contratados pelos clientes';

COMMENT ON COLUMN subscriptions.products.product_id IS 'Identificador único do produto';
COMMENT ON COLUMN subscriptions.products.name IS 'Nome do produto comercial';
COMMENT ON COLUMN subscriptions.products.description IS 'Descrição detalhada do produto';
COMMENT ON COLUMN subscriptions.products.billing_model IS 'Modelo de cobrança: usage_limits ou access_boolean';
COMMENT ON COLUMN subscriptions.products.is_available_for_supplier IS 'Indica se o produto está disponível para suppliers';
COMMENT ON COLUMN subscriptions.products.is_available_for_establishment IS 'Indica se o produto está disponível para establishments';
COMMENT ON COLUMN subscriptions.products.is_active IS 'Indica se o produto está ativo';
COMMENT ON COLUMN subscriptions.products.created_at IS 'Data de criação do registro';
COMMENT ON COLUMN subscriptions.products.updated_at IS 'Data da última atualização do registro';

-- =====================================================
-- CONSTRAINTS
-- =====================================================

-- Chave primária
ALTER TABLE subscriptions.products ADD CONSTRAINT products_pkey PRIMARY KEY (product_id);

-- Nome único
ALTER TABLE subscriptions.products ADD CONSTRAINT products_name_unique UNIQUE (name);

-- Validação do modelo de cobrança
ALTER TABLE subscriptions.products ADD CONSTRAINT products_billing_model_check 
    CHECK (billing_model IN ('usage_limits', 'access_boolean'));

-- =====================================================
-- ÍNDICES
-- =====================================================

-- Índice para produtos ativos
CREATE INDEX idx_products_is_active ON subscriptions.products (is_active);

-- Índice para disponibilidade por tipo de cliente
CREATE INDEX idx_products_supplier_establishment ON subscriptions.products (is_available_for_supplier, is_available_for_establishment);

-- Índice para busca por nome
CREATE INDEX idx_products_name ON subscriptions.products (name);

-- Índice para modelo de cobrança
CREATE INDEX idx_products_billing_model ON subscriptions.products (billing_model);

-- =====================================================
-- TRIGGERS
-- =====================================================

-- Trigger para updated_at
SELECT aux.create_updated_at_trigger('subscriptions', 'products');

-- =====================================================
-- AUDITORIA
-- =====================================================

-- Criar tabela de auditoria
SELECT audit.create_audit_table('subscriptions', 'products');
