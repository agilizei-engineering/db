-- =====================================================
-- TABELA: product_modules - Módulos de Cada Produto
-- =====================================================
-- Descrição: Relacionamento entre produtos e módulos do sistema
-- Funcionalidades: Define quais módulos cada produto inclui

-- =====================================================
-- CRIAÇÃO DA TABELA
-- =====================================================

CREATE TABLE subscriptions.product_modules (
    product_module_id uuid DEFAULT gen_random_uuid() NOT NULL,
    product_id uuid NOT NULL,
    module_id uuid NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now()
);

-- =====================================================
-- COMENTÁRIOS
-- =====================================================

COMMENT ON TABLE subscriptions.product_modules IS 'Relacionamento entre produtos e módulos do sistema';

COMMENT ON COLUMN subscriptions.product_modules.product_module_id IS 'Identificador único do relacionamento';
COMMENT ON COLUMN subscriptions.product_modules.product_id IS 'Referência ao produto';
COMMENT ON COLUMN subscriptions.product_modules.module_id IS 'Referência ao módulo do sistema';
COMMENT ON COLUMN subscriptions.product_modules.created_at IS 'Data de criação do registro';
COMMENT ON COLUMN subscriptions.product_modules.updated_at IS 'Data da última atualização do registro';

-- =====================================================
-- CONSTRAINTS
-- =====================================================

-- Chave primária
ALTER TABLE subscriptions.product_modules ADD CONSTRAINT product_modules_pkey PRIMARY KEY (product_module_id);

-- Relacionamento único (produto + módulo)
ALTER TABLE subscriptions.product_modules ADD CONSTRAINT product_modules_product_module_unique 
    UNIQUE (product_id, module_id);

-- Chave estrangeira para produtos
ALTER TABLE subscriptions.product_modules ADD CONSTRAINT product_modules_product_id_fkey 
    FOREIGN KEY (product_id) REFERENCES subscriptions.products(product_id) ON DELETE CASCADE;

-- Chave estrangeira para módulos
ALTER TABLE subscriptions.product_modules ADD CONSTRAINT product_modules_module_id_fkey 
    FOREIGN KEY (module_id) REFERENCES accounts.modules(module_id) ON DELETE CASCADE;

-- =====================================================
-- ÍNDICES
-- =====================================================

-- Índice para busca por produto
CREATE INDEX idx_product_modules_product_id ON subscriptions.product_modules (product_id);

-- Índice para busca por módulo
CREATE INDEX idx_product_modules_module_id ON subscriptions.product_modules (module_id);

-- Índice composto para verificação única
CREATE INDEX idx_product_modules_composite ON subscriptions.product_modules (product_id, module_id);

-- =====================================================
-- TRIGGERS
-- =====================================================

-- Trigger para updated_at
SELECT aux.create_updated_at_trigger('subscriptions', 'product_modules');

-- =====================================================
-- AUDITORIA
-- =====================================================

-- Criar tabela de auditoria
SELECT audit.create_audit_table('subscriptions', 'product_modules');
