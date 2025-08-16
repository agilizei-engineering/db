-- Tabela de ofertas de produtos
-- Schema: catalogs
-- Tabela: offers

-- Esta tabela é criada automaticamente pelo dump principal
-- Este arquivo serve como documentação e referência

/*
CREATE TABLE catalogs.offers (
    offer_id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    product_id uuid NOT NULL,
    supplier_id uuid NOT NULL,
    price numeric NOT NULL,
    available_from timestamp with time zone NOT NULL,
    available_until timestamp with time zone,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone,
    FOREIGN KEY (product_id) REFERENCES catalogs.products(product_id),
    FOREIGN KEY (supplier_id) REFERENCES accounts.suppliers(supplier_id)
);
*/

-- Campos principais:
-- offer_id: Identificador único da oferta (UUID)
-- product_id: Produto ofertado
-- supplier_id: Fornecedor que oferta o produto
-- price: Preço da oferta
-- available_from: Data de início da disponibilidade da oferta
-- available_until: Data de término da disponibilidade da oferta (opcional)
-- is_active: Indica se a oferta está ativa
-- created_at: Data de criação
-- updated_at: Data da última atualização

-- Constraints:
-- PRIMARY KEY: offer_id
-- NOT NULL: product_id, supplier_id, price, available_from, is_active, created_at
-- FOREIGN KEY: product_id -> catalogs.products(product_id)
-- FOREIGN KEY: supplier_id -> accounts.suppliers(supplier_id)
-- CHECK: price > 0
-- CHECK: available_until IS NULL OR available_until > available_from

-- Triggers:
-- updated_at: Atualiza automaticamente o campo updated_at

-- Auditoria:
-- Automática via schema audit (audit.catalogs__offers)

-- Relacionamentos:
-- catalogs.offers.product_id -> catalogs.products(product_id)
-- catalogs.offers.supplier_id -> accounts.suppliers(supplier_id)

-- Comentários da tabela:
-- COMMENT ON TABLE catalogs.offers IS 'Oferta de um produto específico por um fornecedor com condições comerciais';
-- COMMENT ON COLUMN catalogs.offers.offer_id IS 'Identificador único da oferta';
-- COMMENT ON COLUMN catalogs.offers.product_id IS 'Produto ofertado';
-- COMMENT ON COLUMN catalogs.offers.supplier_id IS 'Fornecedor que oferta o produto';
-- COMMENT ON COLUMN catalogs.offers.price IS 'Preço da oferta';
-- COMMENT ON COLUMN catalogs.offers.available_from IS 'Data de início da disponibilidade da oferta';
-- COMMENT ON COLUMN catalogs.offers.available_until IS 'Data de término da disponibilidade da oferta (opcional)';
-- COMMENT ON COLUMN catalogs.offers.is_active IS 'Indica se a oferta está ativa';
-- COMMENT ON COLUMN catalogs.offers.created_at IS 'Data de criação do registro';
-- COMMENT ON COLUMN catalogs.offers.updated_at IS 'Data da última atualização';

-- Funcionalidades:
-- Gestão de ofertas por fornecedor
-- Controle de preços e disponibilidade
-- Base para comparação de preços
-- Rastreamento de ofertas ativas

-- Exemplos de ofertas:
-- - Produto: Espaguete Barilla 500g
-- - Fornecedor: Distribuidora ABC
-- - Preço: R$ 8,50
-- - Período: 01/01/2024 a 31/12/2024

-- Índices:
-- CREATE INDEX idx_offers_product_id ON catalogs.offers USING btree (product_id);
-- CREATE INDEX idx_offers_supplier_id ON catalogs.offers USING btree (supplier_id);
-- CREATE INDEX idx_offers_price ON catalogs.offers USING btree (price);
-- CREATE INDEX idx_offers_active ON catalogs.offers USING btree (is_active);
-- CREATE INDEX idx_offers_available_from ON catalogs.offers USING btree (available_from);
-- CREATE INDEX idx_offers_available_until ON catalogs.offers USING btree (available_until);

-- Índices compostos:
-- CREATE INDEX idx_offers_product_supplier ON catalogs.offers USING btree (product_id, supplier_id);
-- CREATE INDEX idx_offers_supplier_active ON catalogs.offers USING btree (supplier_id, is_active);
