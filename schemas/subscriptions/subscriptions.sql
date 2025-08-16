-- =====================================================
-- TABELA: subscriptions - Assinaturas Ativas dos Clientes
-- =====================================================
-- Descrição: Assinaturas ativas de establishments e suppliers
-- Funcionalidades: Controle de assinaturas ativas, uma por cliente
-- Constraints: UNIQUE (establishment_id + status = 'active'), UNIQUE (supplier_id + status = 'active')

-- =====================================================
-- CRIAÇÃO DA TABELA
-- =====================================================

CREATE TABLE subscriptions.subscriptions (
    subscription_id uuid DEFAULT gen_random_uuid() NOT NULL,
    establishment_id uuid REFERENCES accounts.establishments(establishment_id) ON DELETE CASCADE,
    supplier_id uuid REFERENCES accounts.suppliers(supplier_id) ON DELETE CASCADE,
    employee_id uuid NOT NULL REFERENCES accounts.employees(employee_id) ON DELETE CASCADE,
    plan_id uuid NOT NULL REFERENCES subscriptions.plans(plan_id) ON DELETE CASCADE,
    start_date timestamp without time zone NOT NULL,
    end_date timestamp without time zone NOT NULL,
    status text NOT NULL DEFAULT 'active',
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now()
);

-- =====================================================
-- COMENTÁRIOS
-- =====================================================

COMMENT ON TABLE subscriptions.subscriptions IS 'Assinaturas ativas de establishments e suppliers';

COMMENT ON COLUMN subscriptions.subscriptions.subscription_id IS 'Identificador único da assinatura';
COMMENT ON COLUMN subscriptions.subscriptions.establishment_id IS 'Referência ao establishment (NULL se for supplier)';
COMMENT ON COLUMN subscriptions.subscriptions.supplier_id IS 'Referência ao supplier (NULL se for establishment)';
COMMENT ON COLUMN subscriptions.subscriptions.employee_id IS 'Employee que executou a ação de assinatura';
COMMENT ON COLUMN subscriptions.subscriptions.plan_id IS 'Referência ao plano contratado';
COMMENT ON COLUMN subscriptions.subscriptions.start_date IS 'Data de início da assinatura';
COMMENT ON COLUMN subscriptions.subscriptions.end_date IS 'Data de fim da assinatura';
COMMENT ON COLUMN subscriptions.subscriptions.status IS 'Status da assinatura (active, suspended, cancelled)';
COMMENT ON COLUMN subscriptions.subscriptions.created_at IS 'Data de criação do registro';
COMMENT ON COLUMN subscriptions.subscriptions.updated_at IS 'Data da última atualização do registro';

-- =====================================================
-- CONSTRAINTS
-- =====================================================

-- Chave primária
ALTER TABLE subscriptions.subscriptions ADD CONSTRAINT subscriptions_pkey PRIMARY KEY (subscription_id);

-- Chave estrangeira para establishments
ALTER TABLE subscriptions.subscriptions ADD CONSTRAINT subscriptions_establishment_id_fkey 
    FOREIGN KEY (establishment_id) REFERENCES accounts.establishments(establishment_id) ON DELETE CASCADE;

-- Chave estrangeira para suppliers
ALTER TABLE subscriptions.subscriptions ADD CONSTRAINT subscriptions_supplier_id_fkey 
    FOREIGN KEY (supplier_id) REFERENCES accounts.suppliers(supplier_id) ON DELETE CASCADE;

-- Chave estrangeira para employees
ALTER TABLE subscriptions.subscriptions ADD CONSTRAINT subscriptions_employee_id_fkey 
    FOREIGN KEY (employee_id) REFERENCES accounts.employees(employee_id) ON DELETE CASCADE;

-- Chave estrangeira para planos
ALTER TABLE subscriptions.subscriptions ADD CONSTRAINT subscriptions_plan_id_fkey 
    FOREIGN KEY (plan_id) REFERENCES subscriptions.plans(plan_id) ON DELETE CASCADE;

-- Validação de status
ALTER TABLE subscriptions.subscriptions ADD CONSTRAINT subscriptions_status_check 
    CHECK (status IN ('active', 'suspended', 'cancelled'));

-- Validação de período
ALTER TABLE subscriptions.subscriptions ADD CONSTRAINT subscriptions_period_check 
    CHECK (start_date < end_date);

-- Uma assinatura ativa por establishment
ALTER TABLE subscriptions.subscriptions ADD CONSTRAINT subscriptions_establishment_unique 
    UNIQUE (establishment_id, status) WHERE status = 'active';

-- Uma assinatura ativa por supplier
ALTER TABLE subscriptions.subscriptions ADD CONSTRAINT subscriptions_supplier_unique 
    UNIQUE (supplier_id, status) WHERE status = 'active';

-- Garantir que establishment_id ou supplier_id seja preenchido, mas não ambos
ALTER TABLE subscriptions.subscriptions ADD CONSTRAINT subscriptions_client_check 
    CHECK (
        (establishment_id IS NOT NULL AND supplier_id IS NULL) OR 
        (establishment_id IS NULL AND supplier_id IS NOT NULL)
    );

-- =====================================================
-- ÍNDICES
-- =====================================================

-- Índice para establishment
CREATE INDEX idx_subscriptions_establishment ON subscriptions.subscriptions (establishment_id);

-- Índice para supplier
CREATE INDEX idx_subscriptions_supplier ON subscriptions.subscriptions (supplier_id);

-- Índice para status
CREATE INDEX idx_subscriptions_status ON subscriptions.subscriptions (status);

-- Índice para período
CREATE INDEX idx_subscriptions_period ON subscriptions.subscriptions (start_date, end_date);

-- Índice para employee
CREATE INDEX idx_subscriptions_employee ON subscriptions.subscriptions (employee_id);

-- =====================================================
-- TRIGGERS
-- =====================================================

-- Trigger para updated_at
SELECT aux.create_updated_at_trigger('subscriptions', 'subscriptions');

-- =====================================================
-- AUDITORIA
-- =====================================================

-- Criar tabela de auditoria
SELECT audit.create_audit_table('subscriptions', 'subscriptions');
