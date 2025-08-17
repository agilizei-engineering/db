-- =====================================================
-- TABELA: transaction_timeline - Timeline de Transações
-- =====================================================
-- Descrição: Timeline completa de eventos de uma transação
-- Funcionalidades: Rastreamento de eventos, histórico completo, metadados

-- =====================================================
-- CRIAÇÃO DA TABELA
-- =====================================================

CREATE TABLE billing.transaction_timeline (
    event_id uuid DEFAULT gen_random_uuid() NOT NULL,
    transaction_id uuid NOT NULL,
    event_type text NOT NULL,
    description text NOT NULL,
    metadata jsonb,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);

-- =====================================================
-- COMENTÁRIOS
-- =====================================================

COMMENT ON TABLE billing.transaction_timeline IS 'Timeline completa de eventos de uma transação';

COMMENT ON COLUMN billing.transaction_timeline.event_id IS 'Identificador único do evento';
COMMENT ON COLUMN billing.transaction_timeline.transaction_id IS 'Referência à transação';
COMMENT ON COLUMN billing.transaction_timeline.event_type IS 'Tipo do evento (ex: created, payment_attempt, success, failure)';
COMMENT ON COLUMN billing.transaction_timeline.description IS 'Descrição clara do evento';
COMMENT ON COLUMN billing.transaction_timeline.metadata IS 'Dados específicos do evento em formato JSONB';
COMMENT ON COLUMN billing.transaction_timeline.created_at IS 'Data de criação do evento';

-- =====================================================
-- CONSTRAINTS
-- =====================================================

-- Chave primária
ALTER TABLE billing.transaction_timeline ADD CONSTRAINT transaction_timeline_pkey PRIMARY KEY (event_id);

-- Validação de tipo de evento
ALTER TABLE billing.transaction_timeline ADD CONSTRAINT transaction_timeline_event_type_check 
    CHECK (event_type IN ('created', 'payment_attempt', 'success', 'failure', 'installment_paid', 'invoice_generated'));

-- =====================================================
-- ÍNDICES
-- =====================================================

-- Índice para transação
CREATE INDEX idx_transaction_timeline_transaction ON billing.transaction_timeline (transaction_id);

-- Índice para tipo de evento
CREATE INDEX idx_transaction_timeline_event_type ON billing.transaction_timeline (event_type);

-- Índice para data de criação
CREATE INDEX idx_transaction_timeline_created_at ON billing.transaction_timeline (created_at);

-- Índice para metadados (GIN para JSONB)
CREATE INDEX idx_transaction_timeline_metadata ON billing.transaction_timeline USING GIN (metadata);

-- =====================================================
-- AUDITORIA
-- =====================================================

-- Criar tabela de auditoria
SELECT audit.create_audit_table('billing', 'transaction_timeline');
