-- Tabela de quantidades e medidas
-- Schema: catalogs
-- Tabela: quantities

-- Esta tabela é criada automaticamente pelo dump principal
-- Este arquivo serve como documentação e referência

/*
CREATE TABLE catalogs.quantities (
    quantity_id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    unit text NOT NULL,
    value numeric NOT NULL,
    display_name text NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone
);
*/

-- Campos principais:
-- quantity_id: Identificador único da quantidade (UUID)
-- unit: Unidade de medida (ex: g, ml, un)
-- value: Valor numérico da unidade
-- display_name: Nome formatado para exibição
-- is_active: Status ativo/inativo da quantidade
-- created_at: Data de criação
-- updated_at: Data da última atualização

-- Constraints:
-- PRIMARY KEY: quantity_id
-- NOT NULL: unit, value, display_name, is_active, created_at
-- CHECK: value > 0

-- Triggers:
-- updated_at: Atualiza automaticamente o campo updated_at

-- Auditoria:
-- Automática via schema audit (audit.catalogs__quantities)

-- Relacionamentos:
-- catalogs.products.quantity_id -> catalogs.quantities.quantity_id
-- quotation.shopping_list_items.quantity_id -> catalogs.quantities.quantity_id

-- Comentários da tabela:
-- COMMENT ON TABLE catalogs.quantities IS 'Quantidade ou medida do produto (ex: 500g, 12 unidades)';
-- COMMENT ON COLUMN catalogs.quantities.quantity_id IS 'Identificador único da quantidade';
-- COMMENT ON COLUMN catalogs.quantities.unit IS 'Unidade de medida (ex: g, ml, un)';
-- COMMENT ON COLUMN catalogs.quantities.value IS 'Valor numérico da unidade';
-- COMMENT ON COLUMN catalogs.quantities.display_name IS 'Nome formatado para exibição';
-- COMMENT ON COLUMN catalogs.quantities.is_active IS 'Status ativo/inativo';
-- COMMENT ON COLUMN catalogs.quantities.created_at IS 'Data de criação do registro';
-- COMMENT ON COLUMN catalogs.quantities.updated_at IS 'Data da última atualização';

-- Funcionalidades:
-- Definição de quantidades padronizadas
-- Controle de medidas por produto
-- Base para produtos específicos
-- Organização de variações de quantidade

-- Exemplos de quantidades:
-- - 500g (Massas)
-- - 1L (Bebidas)
-- - 12 un (Biscoitos)
-- - 250ml (Iogurtes)
-- - 1kg (Carnes)

-- Índices:
-- CREATE INDEX idx_quantities_unit ON catalogs.quantities USING btree (unit);
-- CREATE INDEX idx_quantities_value ON catalogs.quantities USING btree (value);
-- CREATE INDEX idx_quantities_active ON catalogs.quantities USING btree (is_active);

-- Índices de texto para busca:
-- CREATE INDEX idx_quantities_display_name_gin ON catalogs.quantities USING gin(to_tsvector('portuguese', display_name));

-- Índices trigram para busca fuzzy (se pg_trgm disponível):
-- CREATE INDEX idx_quantities_display_name_trgm ON catalogs.quantities USING gin(display_name gin_trgm_ops);
