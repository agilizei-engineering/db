-- Tabela de cotações dos fornecedores
-- Schema: quotation
-- Tabela: supplier_quotations

-- Esta tabela é criada automaticamente pelo dump principal
-- Este arquivo serve como documentação e referência

/*
CREATE TABLE quotation.supplier_quotations (
    supplier_quotation_id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    quotation_submission_id uuid NOT NULL,
    shopping_list_item_id uuid NOT NULL,
    supplier_id uuid NOT NULL,
    quotation_status_id uuid NOT NULL,
    quotation_date timestamp with time zone DEFAULT now() NOT NULL,
    notes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone,
    FOREIGN KEY (quotation_submission_id) REFERENCES quotation.quotation_submissions(quotation_submission_id),
    FOREIGN KEY (shopping_list_item_id) REFERENCES quotation.shopping_list_items(shopping_list_item_id),
    FOREIGN KEY (supplier_id) REFERENCES accounts.suppliers(supplier_id),
    FOREIGN KEY (quotation_status_id) REFERENCES quotation.supplier_quotation_statuses(quotation_status_id)
);
*/

-- Campos principais:
-- supplier_quotation_id: Identificador único da cotação do fornecedor (UUID)
-- quotation_submission_id: Referência para a submissão de cotação
-- shopping_list_item_id: Referência para o item da lista de compras
-- supplier_id: Referência para accounts.suppliers
-- quotation_status_id: Referência para o status da cotação
-- quotation_date: Data da cotação do fornecedor
-- notes: Observações sobre a cotação do fornecedor
-- created_at: Data de criação
-- updated_at: Data da última atualização

-- Constraints:
-- PRIMARY KEY: supplier_quotation_id
-- NOT NULL: quotation_submission_id, shopping_list_item_id, supplier_id, quotation_status_id, quotation_date, created_at
-- FOREIGN KEY: quotation_submission_id -> quotation.quotation_submissions(quotation_submission_id)
-- FOREIGN KEY: shopping_list_item_id -> quotation.shopping_list_items(shopping_list_item_id)
-- FOREIGN KEY: supplier_id -> accounts.suppliers(supplier_id)
-- FOREIGN KEY: quotation_status_id -> quotation.supplier_quotation_statuses(quotation_status_id)

-- Triggers:
-- updated_at: Atualiza automaticamente o campo updated_at

-- Auditoria:
-- Automática via schema audit (audit.quotation__supplier_quotations)

-- Relacionamentos:
-- quotation.supplier_quotations.quotation_submission_id -> quotation.quotation_submissions(quotation_submission_id)
-- quotation.supplier_quotations.shopping_list_item_id -> quotation.shopping_list_items(shopping_list_item_id)
-- quotation.supplier_quotations.supplier_id -> accounts.suppliers(supplier_id)
-- quotation.supplier_quotations.quotation_status_id -> quotation.supplier_quotation_statuses(quotation_status_id)
-- quotation.quoted_prices.supplier_quotation_id -> quotation.supplier_quotations(supplier_quotation_id)

-- Comentários da tabela:
-- COMMENT ON TABLE quotation.supplier_quotations IS 'Cotações recebidas dos fornecedores para itens específicos';
-- COMMENT ON COLUMN quotation.supplier_quotations.supplier_quotation_id IS 'Identificador único da cotação do fornecedor';
-- COMMENT ON COLUMN quotation.supplier_quotations.quotation_submission_id IS 'Referência para a submissão de cotação';
-- COMMENT ON COLUMN quotation.supplier_quotations.shopping_list_item_id IS 'Referência para o item da lista de compras';
-- COMMENT ON COLUMN quotation.supplier_quotations.supplier_id IS 'Referência para accounts.suppliers';
-- COMMENT ON COLUMN quotation.supplier_quotations.quotation_status_id IS 'Referência para o status da cotação';
-- COMMENT ON COLUMN quotation.supplier_quotations.quotation_date IS 'Data da cotação do fornecedor';
-- COMMENT ON COLUMN quotation.supplier_quotations.notes IS 'Observações sobre a cotação do fornecedor';
-- COMMENT ON COLUMN quotation.supplier_quotations.created_at IS 'Data de criação do registro';
-- COMMENT ON COLUMN quotation.supplier_quotations.updated_at IS 'Data da última atualização';

-- Funcionalidades:
-- Gestão de cotações dos fornecedores
-- Controle de status de cotação
-- Rastreamento de datas de cotação
-- Base para preços cotados
-- Controle de workflow de cotações

-- Exemplos de uso:
-- - Recebimento de cotações de fornecedores
-- - Acompanhamento de status de cotação
-- - Controle de fluxo de trabalho
-- - Relatórios de cotações por fornecedor

-- Índices:
-- CREATE INDEX idx_supplier_quotations_submission_id ON quotation.supplier_quotations USING btree (quotation_submission_id);
-- CREATE INDEX idx_supplier_quotations_item_id ON quotation.supplier_quotations USING btree (shopping_list_item_id);
-- CREATE INDEX idx_supplier_quotations_supplier_id ON quotation.supplier_quotations USING btree (supplier_id);
-- CREATE INDEX idx_supplier_quotations_status_id ON quotation.supplier_quotations USING btree (quotation_status_id);
-- CREATE INDEX idx_supplier_quotations_date ON quotation.supplier_quotations USING btree (quotation_date);

-- Índices compostos:
-- CREATE INDEX idx_supplier_quotations_submission_item ON quotation.supplier_quotations USING btree (quotation_submission_id, shopping_list_item_id);
-- CREATE INDEX idx_supplier_quotations_supplier_status ON quotation.supplier_quotations USING btree (supplier_id, quotation_status_id);
-- CREATE INDEX idx_supplier_quotations_item_supplier ON quotation.supplier_quotations USING btree (shopping_list_item_id, supplier_id);

-- Índices de texto para busca:
-- CREATE INDEX idx_supplier_quotations_notes_gin ON quotation.supplier_quotations USING gin(to_tsvector('portuguese', notes));

-- Índices trigram para busca fuzzy (se pg_trgm disponível):
-- CREATE INDEX idx_supplier_quotations_notes_trgm ON quotation.supplier_quotations USING gin(notes gin_trgm_ops);
