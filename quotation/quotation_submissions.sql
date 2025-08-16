-- Tabela de submissões de cotação
-- Schema: quotation
-- Tabela: quotation_submissions

-- Esta tabela é criada automaticamente pelo dump principal
-- Este arquivo serve como documentação e referência

/*
CREATE TABLE quotation.quotation_submissions (
    quotation_submission_id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    shopping_list_id uuid NOT NULL,
    submission_status_id uuid NOT NULL,
    submission_date timestamp with time zone DEFAULT now() NOT NULL,
    total_items integer DEFAULT 0 NOT NULL,
    notes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone,
    FOREIGN KEY (shopping_list_id) REFERENCES quotation.shopping_lists(shopping_list_id),
    FOREIGN KEY (submission_status_id) REFERENCES quotation.submission_statuses(submission_status_id)
);
*/

-- Campos principais:
-- quotation_submission_id: Identificador único da submissão de cotação (UUID)
-- shopping_list_id: Referência para a lista de compras
-- submission_status_id: Referência para o status da submissão
-- submission_date: Data de submissão da cotação
-- total_items: Total de itens na submissão (calculado automaticamente)
-- notes: Observações sobre a submissão
-- created_at: Data de criação
-- updated_at: Data da última atualização

-- Constraints:
-- PRIMARY KEY: quotation_submission_id
-- NOT NULL: shopping_list_id, submission_status_id, submission_date, total_items, created_at
-- FOREIGN KEY: shopping_list_id -> quotation.shopping_lists(shopping_list_id)
-- FOREIGN KEY: submission_status_id -> quotation.submission_statuses(submission_status_id)
-- CHECK: total_items >= 0

-- Triggers:
-- updated_at: Atualiza automaticamente o campo updated_at
-- calculate_total_items: Calcula total de itens automaticamente

-- Auditoria:
-- Automática via schema audit (audit.quotation__quotation_submissions)

-- Relacionamentos:
-- quotation.quotation_submissions.shopping_list_id -> quotation.shopping_lists(shopping_list_id)
-- quotation.quotation_submissions.submission_status_id -> quotation.submission_statuses(submission_status_id)
-- quotation.supplier_quotations.quotation_submission_id -> quotation.quotation_submissions(quotation_submission_id)

-- Comentários da tabela:
-- COMMENT ON TABLE quotation.quotation_submissions IS 'Submissões de cotação quando as listas de compras são enviadas';
-- COMMENT ON COLUMN quotation.quotation_submissions.quotation_submission_id IS 'Identificador único da submissão de cotação';
-- COMMENT ON COLUMN quotation.quotation_submissions.shopping_list_id IS 'Referência para a lista de compras';
-- COMMENT ON COLUMN quotation.quotation_submissions.submission_status_id IS 'Referência para o status da submissão';
-- COMMENT ON COLUMN quotation.quotation_submissions.submission_date IS 'Data de submissão da cotação';
-- COMMENT ON COLUMN quotation.quotation_submissions.total_items IS 'Total de itens na submissão (calculado automaticamente)';
-- COMMENT ON COLUMN quotation.quotation_submissions.notes IS 'Observações sobre a submissão';
-- COMMENT ON COLUMN quotation.quotation_submissions.created_at IS 'Data de criação do registro';
-- COMMENT ON COLUMN quotation.quotation_submissions.updated_at IS 'Data da última atualização';

-- Funcionalidades:
-- Gestão de submissões de cotação
-- Controle de status de submissão
-- Cálculo automático de total de itens
-- Rastreamento de datas de submissão
-- Base para workflow de cotações

-- Exemplos de uso:
-- - Submissão de lista de compras para cotação
-- - Acompanhamento de status de submissão
-- - Controle de fluxo de trabalho
-- - Relatórios de submissões

-- Índices:
-- CREATE INDEX idx_quotation_submissions_shopping_list_id ON quotation.quotation_submissions USING btree (shopping_list_id);
-- CREATE INDEX idx_quotation_submissions_status_id ON quotation.quotation_submissions USING btree (submission_status_id);
-- CREATE INDEX idx_quotation_submissions_submission_date ON quotation.quotation_submissions USING btree (submission_date);
-- CREATE INDEX idx_quotation_submissions_total_items ON quotation.quotation_submissions USING btree (total_items);

-- Índices compostos:
-- CREATE INDEX idx_quotation_submissions_status_date ON quotation.quotation_submissions USING btree (submission_status_id, submission_date);
-- CREATE INDEX idx_quotation_submissions_list_status ON quotation.quotation_submissions USING btree (shopping_list_id, submission_status_id);

-- Índices de texto para busca:
-- CREATE INDEX idx_quotation_submissions_notes_gin ON quotation.quotation_submissions USING gin(to_tsvector('portuguese', notes));

-- Índices trigram para busca fuzzy (se pg_trgm disponível):
-- CREATE INDEX idx_quotation_submissions_notes_trgm ON quotation.quotation_submissions USING gin(notes gin_trgm_ops);
