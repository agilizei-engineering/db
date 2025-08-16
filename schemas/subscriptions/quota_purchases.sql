-- =====================================================
-- TABELA: quota_purchases - Compras de Cotas Extras
-- =====================================================
-- Descrição: Microtransações independentes para cotas excedentes
-- Funcionalidades: Compra de cotas extras, controle de preços unitários
-- Campos calculados: total_price (unit_price * quotations_bought)

-- =====================================================
-- CRIAÇÃO DA TABELA
-- =====================================================

CREATE TABLE subscriptions.quota_purchases (
    purchase_id uuid DEFAULT gen_random_uuid() NOT NULL,
    establishment_id uuid REFERENCES accounts.establishments(establishment_id) ON DELETE CASCADE,
    supplier_id uuid REFERENCES accounts.suppliers(supplier_id) ON DELETE CASCADE,
    purchase_date timestamp without time zone DEFAULT now() NOT NULL,
    quotations_bought integer NOT NULL,
    unit_price numeric(10,2) NOT NULL,
    total_price numeric(10,2) NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now()
);

-- =====================================================
-- COMENTÁRIOS
-- =====================================================

COMMENT ON TABLE subscriptions.quota_purchases IS 'Microtransações independentes para cotas excedentes';

COMMENT ON COLUMN subscriptions.quota_purchases.purchase_id IS 'Identificador único da compra';
COMMENT ON COLUMN subscriptions.quota_purchases.establishment_id IS 'Referência ao establishment (NULL se for supplier)';
COMMENT ON COLUMN subscriptions.quota_purchases.supplier_id IS 'Referência ao supplier (NULL se for establishment)';
COMMENT ON COLUMN subscriptions.quota_purchases.purchase_date IS 'Data da compra';
COMMENT ON COLUMN subscriptions.quota_purchases.quotations_bought IS 'Quantidade de cotações compradas';
COMMENT ON COLUMN subscriptions.quota_purchases.unit_price IS 'Preço unitário por cotação';
COMMENT ON COLUMN subscriptions.quota_purchases.total_price IS 'Preço total da compra';
COMMENT ON COLUMN subscriptions.quota_purchases.created_at IS 'Data de criação do registro';
COMMENT ON COLUMN subscriptions.quota_purchases.updated_at IS 'Data da última atualização do registro';

-- =====================================================
-- CONSTRAINTS
-- =====================================================

-- Chave primária
ALTER TABLE subscriptions.quota_purchases ADD CONSTRAINT quota_purchases_pkey PRIMARY KEY (purchase_id);

-- Chave estrangeira para establishments
ALTER TABLE subscriptions.quota_purchases ADD CONSTRAINT quota_purchases_establishment_id_fkey 
    FOREIGN KEY (establishment_id) REFERENCES accounts.establishments(establishment_id) ON DELETE CASCADE;

-- Chave estrangeira para suppliers
ALTER TABLE subscriptions.quota_purchases ADD CONSTRAINT quota_purchases_supplier_id_fkey 
    FOREIGN KEY (supplier_id) REFERENCES accounts.suppliers(supplier_id) ON DELETE CASCADE;

-- Validação de preço unitário
ALTER TABLE subscriptions.quota_purchases ADD CONSTRAINT quota_purchases_unit_price_check 
    CHECK (unit_price > 0);

-- Validação de quantidade
ALTER TABLE subscriptions.quota_purchases ADD CONSTRAINT quota_purchases_quotations_bought_check 
    CHECK (quotations_bought > 0);

-- Validação de preço total
ALTER TABLE subscriptions.quota_purchases ADD CONSTRAINT quota_purchases_total_price_check 
    CHECK (total_price = unit_price * quotations_bought);

-- Garantir que establishment_id ou supplier_id seja preenchido, mas não ambos
ALTER TABLE subscriptions.quota_purchases ADD CONSTRAINT quota_purchases_client_check 
    CHECK (
        (establishment_id IS NOT NULL AND supplier_id IS NULL) OR 
        (establishment_id IS NULL AND supplier_id IS NOT NULL)
    );

-- =====================================================
-- ÍNDICES
-- =====================================================

-- Índice para establishment
CREATE INDEX idx_quota_purchases_establishment ON subscriptions.quota_purchases (establishment_id);

-- Índice para supplier
CREATE INDEX idx_quota_purchases_supplier ON subscriptions.quota_purchases (supplier_id);

-- Índice para data de compra
CREATE INDEX idx_quota_purchases_date ON subscriptions.quota_purchases (purchase_date);

-- =====================================================
-- TRIGGERS
-- =====================================================

-- Trigger para updated_at
SELECT aux.create_updated_at_trigger('subscriptions', 'quota_purchases');

-- =====================================================
-- AUDITORIA
-- =====================================================

-- Criar tabela de auditoria
SELECT audit.create_audit_table('subscriptions', 'quota_purchases');
