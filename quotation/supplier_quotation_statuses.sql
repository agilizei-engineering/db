-- Tabela de status das cotações dos fornecedores
-- Schema: quotation
-- Tabela: supplier_quotation_statuses

-- Esta tabela é criada automaticamente pelo dump principal
-- Este arquivo serve como documentação e referência

/*
CREATE TABLE quotation.supplier_quotation_statuses (
    quotation_status_id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    name text NOT NULL,
    description text,
    color text,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone
);
*/

-- Campos principais:
-- quotation_status_id: Identificador único do status de cotação (UUID)
-- name: Nome do status (ex: pending, received, accepted)
-- description: Descrição detalhada do status
-- color: Código de cor hexadecimal para interface
-- is_active: Indica se o status está ativo para uso
-- created_at: Data de criação
-- updated_at: Data da última atualização

-- Constraints:
-- PRIMARY KEY: quotation_status_id
-- NOT NULL: name, is_active, created_at
-- CHECK: color válido via aux.validate_color() (se não for NULL)

-- Triggers:
-- updated_at: Atualiza automaticamente o campo updated_at
-- color_validation: Valida cor hexadecimal automaticamente

-- Auditoria:
-- Automática via schema audit (audit.quotation__supplier_quotation_statuses)

-- Relacionamentos:
-- quotation.supplier_quotations.quotation_status_id -> quotation.supplier_quotation_statuses.quotation_status_id

-- Comentários da tabela:
-- COMMENT ON TABLE quotation.supplier_quotation_statuses IS 'Status das cotações recebidas dos fornecedores';
-- COMMENT ON COLUMN quotation.supplier_quotation_statuses.quotation_status_id IS 'Identificador único do status de cotação';
-- COMMENT ON COLUMN quotation.supplier_quotation_statuses.name IS 'Nome do status (ex: pending, received, accepted)';
-- COMMENT ON COLUMN quotation.supplier_quotation_statuses.description IS 'Descrição detalhada do status';
-- COMMENT ON COLUMN quotation.supplier_quotation_statuses.color IS 'Código de cor hexadecimal para interface';
-- COMMENT ON COLUMN quotation.supplier_quotation_statuses.is_active IS 'Indica se o status está ativo para uso';
-- COMMENT ON COLUMN quotation.supplier_quotation_statuses.created_at IS 'Data de criação do registro';
-- COMMENT ON COLUMN quotation.supplier_quotation_statuses.updated_at IS 'Data da última atualização';

-- Funcionalidades:
-- Controle de status das cotações dos fornecedores
-- Personalização visual por status
-- Base para workflow de cotações
-- Controle de fluxo de trabalho

-- Exemplos de status:
-- - Pending (Pendente) - #FFA500
-- - Received (Recebida) - #0066CC
-- - Accepted (Aceita) - #00CC00
-- - Rejected (Rejeitada) - #CC0000
-- - Expired (Expirada) - #999999
-- - Under Review (Em Análise) - #FF6600

-- Índices:
-- CREATE INDEX idx_supplier_quotation_statuses_name ON quotation.supplier_quotation_statuses USING btree (name);
-- CREATE INDEX idx_supplier_quotation_statuses_active ON quotation.supplier_quotation_statuses USING btree (is_active);

-- Índices de texto para busca:
-- CREATE INDEX idx_supplier_quotation_statuses_name_gin ON quotation.supplier_quotation_statuses USING gin(to_tsvector('portuguese', name));
-- CREATE INDEX idx_supplier_quotation_statuses_description_gin ON quotation.supplier_quotation_statuses USING gin(to_tsvector('portuguese', description));

-- Índices trigram para busca fuzzy (se pg_trgm disponível):
-- CREATE INDEX idx_supplier_quotation_statuses_name_trgm ON quotation.supplier_quotation_statuses USING gin(name gin_trgm_ops);
-- CREATE INDEX idx_supplier_quotation_statuses_description_trgm ON quotation.supplier_quotation_statuses USING gin(description gin_trgm_ops);
