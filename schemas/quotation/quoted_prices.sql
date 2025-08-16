-- Tabela de preços cotados pelos fornecedores
-- Schema: quotation
-- Tabela: quoted_prices

-- Esta tabela é criada automaticamente pelo dump principal
-- Este arquivo serve como documentação e referência

/*
CREATE TABLE quotation.quoted_prices (
    quoted_price_id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    supplier_quotation_id uuid NOT NULL,
    quantity_from numeric NOT NULL,
    quantity_to numeric,
    unit_price numeric NOT NULL,
    total_price numeric NOT NULL,
    currency text NOT NULL,
    delivery_time_days integer,
    minimum_order_quantity numeric,
    payment_terms text,
    validity_days integer,
    special_conditions text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone,
    FOREIGN KEY (supplier_quotation_id) REFERENCES quotation.supplier_quotations(supplier_quotation_id)
);
*/

-- Campos principais:
-- quoted_price_id: Identificador único do preço cotado (UUID)
-- supplier_quotation_id: Referência para a cotação do fornecedor
-- quantity_from: Quantidade mínima para este preço
-- quantity_to: Quantidade máxima para este preço (NULL = ilimitado)
-- unit_price: Preço unitário
-- total_price: Preço total para a quantidade
-- currency: Moeda da cotação
-- delivery_time_days: Prazo de entrega em dias
-- minimum_order_quantity: Quantidade mínima para pedido
-- payment_terms: Condições de pagamento
-- validity_days: Validade da cotação em dias
-- special_conditions: Condições especiais
-- created_at: Data de criação
-- updated_at: Data da última atualização

-- Constraints:
-- PRIMARY KEY: quoted_price_id
-- NOT NULL: supplier_quotation_id, quantity_from, unit_price, total_price, currency, created_at
-- FOREIGN KEY: supplier_quotation_id -> quotation.supplier_quotations(supplier_quotation_id)
-- CHECK: quantity_from > 0
-- CHECK: quantity_to IS NULL OR quantity_to > quantity_from
-- CHECK: unit_price > 0
-- CHECK: total_price > 0
-- CHECK: currency válido via aux.validate_moeda
-- CHECK: delivery_time_days IS NULL OR delivery_time_days >= 0
-- CHECK: minimum_order_quantity IS NULL OR minimum_order_quantity > 0
-- CHECK: validity_days IS NULL OR validity_days > 0

-- Triggers:
-- updated_at: Atualiza automaticamente o campo updated_at
-- validate_currency: Valida moeda automaticamente
-- calculate_total_price: Calcula preço total automaticamente

-- Auditoria:
-- Automática via schema audit (audit.quotation__quoted_prices)

-- Relacionamentos:
-- quotation.quoted_prices.supplier_quotation_id -> quotation.supplier_quotations(supplier_quotation_id)

-- Comentários da tabela:
-- COMMENT ON TABLE quotation.quoted_prices IS 'Preços cotados pelos fornecedores com condições comerciais';
-- COMMENT ON COLUMN quotation.quoted_prices.quoted_price_id IS 'Identificador único do preço cotado';
-- COMMENT ON COLUMN quotation.quoted_prices.supplier_quotation_id IS 'Referência para a cotação do fornecedor';
-- COMMENT ON COLUMN quotation.quoted_prices.quantity_from IS 'Quantidade mínima para este preço';
-- COMMENT ON COLUMN quotation.quoted_prices.quantity_to IS 'Quantidade máxima para este preço (NULL = ilimitado)';
-- COMMENT ON COLUMN quotation.quoted_prices.unit_price IS 'Preço unitário';
-- COMMENT ON COLUMN quotation.quoted_prices.total_price IS 'Preço total para a quantidade';
-- COMMENT ON COLUMN quotation.quoted_prices.currency IS 'Moeda da cotação';
-- COMMENT ON COLUMN quotation.quoted_prices.delivery_time_days IS 'Prazo de entrega em dias';
-- COMMENT ON COLUMN quotation.quoted_prices.minimum_order_quantity IS 'Quantidade mínima para pedido';
-- COMMENT ON COLUMN quotation.quoted_prices.payment_terms IS 'Condições de pagamento';
-- COMMENT ON COLUMN quotation.quoted_prices.validity_days IS 'Validade da cotação em dias';
-- COMMENT ON COLUMN quotation.quoted_prices.special_conditions IS 'Condições especiais';
-- COMMENT ON COLUMN quotation.quoted_prices.created_at IS 'Data de criação do registro';
-- COMMENT ON COLUMN quotation.quoted_prices.updated_at IS 'Data da última atualização';

-- Funcionalidades:
-- Gestão de preços cotados pelos fornecedores
-- Controle de quantidades e preços
-- Validação de moedas
-- Cálculo automático de preços totais
-- Controle de condições comerciais
-- Base para análise de preços

-- Exemplos de uso:
-- - Cotação de preços por quantidade
-- - Análise de preços entre fornecedores
-- - Controle de condições comerciais
-- - Relatórios de preços cotados

-- Índices:
-- CREATE INDEX idx_quoted_prices_supplier_quotation_id ON quotation.quoted_prices USING btree (supplier_quotation_id);
-- CREATE INDEX idx_quoted_prices_quantity_from ON quotation.quoted_prices USING btree (quantity_from);
-- CREATE INDEX idx_quoted_prices_unit_price ON quotation.quoted_prices USING btree (unit_price);
-- CREATE INDEX idx_quoted_prices_currency ON quotation.quoted_prices USING btree (currency);
-- CREATE INDEX idx_quoted_prices_delivery_time ON quotation.quoted_prices USING btree (delivery_time_days);
-- CREATE INDEX idx_quoted_prices_validity ON quotation.quoted_prices USING btree (validity_days);

-- Índices compostos:
-- CREATE INDEX idx_quoted_prices_quantity_range ON quotation.quoted_prices USING btree (quantity_from, quantity_to);
-- CREATE INDEX idx_quoted_prices_price_currency ON quotation.quoted_prices USING btree (unit_price, currency);

-- Índices de texto para busca:
-- CREATE INDEX idx_quoted_prices_payment_terms_gin ON quotation.quoted_prices USING gin(to_tsvector('portuguese', payment_terms));
-- CREATE INDEX idx_quoted_prices_special_conditions_gin ON quotation.quoted_prices USING gin(to_tsvector('portuguese', special_conditions));

-- Índices trigram para busca fuzzy (se pg_trgm disponível):
-- CREATE INDEX idx_quoted_prices_payment_terms_trgm ON quotation.quoted_prices USING gin(payment_terms gin_trgm_ops);
-- CREATE INDEX idx_quoted_prices_special_conditions_trgm ON quotation.quoted_prices USING gin(special_conditions gin_trgm_ops);
