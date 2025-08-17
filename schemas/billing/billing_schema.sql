-- =====================================================
-- SCHEMA: billing - SISTEMA DE FATURAMENTO E PROCESSAMENTO FINANCEIRO
-- =====================================================
-- Este script cria o schema billing completo que:
-- 1. Gerencia transações financeiras de forma agnóstica ao negócio
-- 2. Suporta múltiplos métodos de pagamento (cartão, pix, boleto, faturado)
-- 3. Gerencia parcelamentos e installments
-- 4. Rastreia timeline completa de eventos
-- 5. Integra com schemas aux, audit e outros schemas de negócio

-- =====================================================
-- CRIAÇÃO DO SCHEMA BILLING
-- =====================================================

-- Cria o schema billing se não existir
CREATE SCHEMA IF NOT EXISTS billing;

-- Comentário do schema
COMMENT ON SCHEMA billing IS 'Schema para processamento financeiro e faturamento agnóstico ao negócio';

-- =====================================================
-- VERIFICAÇÃO DE DEPENDÊNCIAS
-- =====================================================

-- Verifica se o schema aux existe
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'aux') THEN
        RAISE EXCEPTION 'Schema aux não existe. Execute aux_schema.sql primeiro.';
    END IF;
END $$;

-- Verifica se o schema audit existe
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'audit') THEN
        RAISE EXCEPTION 'Schema audit não existe. Execute audit_schema.sql primeiro.';
    END IF;
END $$;

-- =====================================================
-- CONFIGURAÇÃO DE VALIDAÇÃO JSONB
-- =====================================================

-- Configura parâmetros de validação para campos JSONB
DO $$
BEGIN
    -- Verifica se a tabela aux.json_validation_params existe
    IF EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'aux' 
        AND table_name = 'json_validation_params'
    ) THEN
        -- Insere parâmetros de validação para business_reference
        INSERT INTO aux.json_validation_params (param_name, param_value) VALUES
        ('billing.transactions', 'business_reference.schema'),
        ('billing.transactions', 'business_reference.table'),
        ('billing.transactions', 'business_reference.id')
        ON CONFLICT (param_name, param_value) DO NOTHING;
        
        RAISE NOTICE 'Parâmetros de validação JSONB configurados para billing.transactions';
    ELSE
        RAISE NOTICE 'Tabela aux.json_validation_params não existe. Validação JSONB será configurada posteriormente.';
    END IF;
END $$;

-- =====================================================
-- INCLUSÃO DOS ARQUIVOS INDIVIDUAIS
-- =====================================================

-- Incluir arquivos de tabelas individuais
\i schemas/billing/transaction_statuses.sql
\i schemas/billing/payment_types.sql
\i schemas/billing/installment_statuses.sql
\i schemas/billing/invoice_statuses.sql
\i schemas/billing/transactions.sql
\i schemas/billing/expected_payments.sql
\i schemas/billing/installments.sql
\i schemas/billing/invoices.sql
\i schemas/billing/payment_attempts.sql
\i schemas/billing/transaction_timeline.sql

-- =====================================================
-- INCLUSÃO DOS ARQUIVOS GENÉRICOS
-- =====================================================

-- Incluir arquivo de funções
\i schemas/billing/functions.sql

-- Incluir arquivo de views
\i schemas/billing/views.sql

-- Incluir arquivo de triggers
\i schemas/billing/triggers.sql

-- =====================================================
-- CHAVES ESTRANGEIRAS
-- =====================================================

-- Chaves estrangeiras para transactions
ALTER TABLE billing.transactions ADD CONSTRAINT transactions_status_id_fkey 
    FOREIGN KEY (status_id) REFERENCES billing.transaction_statuses(status_id) ON DELETE RESTRICT;
ALTER TABLE billing.transactions ADD CONSTRAINT transactions_payment_type_id_fkey 
    FOREIGN KEY (payment_type_id) REFERENCES billing.payment_types(payment_type_id) ON DELETE RESTRICT;

-- Chaves estrangeiras para expected_payments
ALTER TABLE billing.expected_payments ADD CONSTRAINT expected_payments_transaction_id_fkey 
    FOREIGN KEY (transaction_id) REFERENCES billing.transactions(transaction_id) ON DELETE CASCADE;

-- Chaves estrangeiras para installments
ALTER TABLE billing.installments ADD CONSTRAINT installments_expected_payment_id_fkey 
    FOREIGN KEY (expected_payment_id) REFERENCES billing.expected_payments(expected_payment_id) ON DELETE CASCADE;
ALTER TABLE billing.installments ADD CONSTRAINT installments_status_id_fkey 
    FOREIGN KEY (status_id) REFERENCES billing.installment_statuses(status_id) ON DELETE RESTRICT;
ALTER TABLE billing.installments ADD CONSTRAINT installments_payment_attempt_id_fkey 
    FOREIGN KEY (payment_attempt_id) REFERENCES billing.payment_attempts(attempt_id) ON DELETE SET NULL;

-- Chaves estrangeiras para invoices
ALTER TABLE billing.invoices ADD CONSTRAINT invoices_expected_payment_id_fkey 
    FOREIGN KEY (expected_payment_id) REFERENCES billing.expected_payments(expected_payment_id) ON DELETE CASCADE;
ALTER TABLE billing.invoices ADD CONSTRAINT invoices_status_id_fkey 
    FOREIGN KEY (status_id) REFERENCES billing.invoice_statuses(status_id) ON DELETE RESTRICT;

-- Chaves estrangeiras para payment_attempts
ALTER TABLE billing.payment_attempts ADD CONSTRAINT payment_attempts_expected_payment_id_fkey 
    FOREIGN KEY (expected_payment_id) REFERENCES billing.expected_payments(expected_payment_id) ON DELETE CASCADE;

-- Chaves estrangeiras para transaction_timeline
ALTER TABLE billing.transaction_timeline ADD CONSTRAINT transaction_timeline_transaction_id_fkey 
    FOREIGN KEY (transaction_id) REFERENCES billing.transactions(transaction_id) ON DELETE CASCADE;

-- =====================================================
-- DADOS INICIAIS
-- =====================================================

-- Inserir status de transações padrão
INSERT INTO billing.transaction_statuses (name, description) VALUES
('pending', 'Transação pendente de processamento'),
('processing', 'Transação sendo processada'),
('completed', 'Transação concluída com sucesso'),
('failed', 'Transação falhou'),
('cancelled', 'Transação cancelada'),
('refunded', 'Transação estornada')
ON CONFLICT (name) DO NOTHING;

-- Inserir tipos de pagamento padrão
INSERT INTO billing.payment_types (name, description, supports_installments) VALUES
('credit_card', 'Cartão de crédito', true),
('debit_card', 'Cartão de débito', false),
('pix', 'Transferência PIX', false),
('boleto', 'Boleto bancário', false),
('invoiced', 'Faturado (30/60/90 dias)', true)
ON CONFLICT (name) DO NOTHING;

-- Inserir status de parcelas padrão
INSERT INTO billing.installment_statuses (name, description) VALUES
('pending', 'Parcela pendente de pagamento'),
('due', 'Parcela vencida (inclui em atraso)'),
('paid', 'Parcela paga'),
('cancelled', 'Parcela cancelada')
ON CONFLICT (name) DO NOTHING;

-- Inserir status de invoices padrão
INSERT INTO billing.invoice_statuses (name, description) VALUES
('generated', 'Invoice gerado'),
('sent', 'Invoice enviado'),
('overdue', 'Invoice vencido'),
('paid', 'Invoice pago'),
('cancelled', 'Invoice cancelado')
ON CONFLICT (name) DO NOTHING;

-- =====================================================
-- MENSAGEM DE CONCLUSÃO
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '=====================================================';
    RAISE NOTICE 'SCHEMA BILLING CRIADO COM SUCESSO!';
    RAISE NOTICE '=====================================================';
    RAISE NOTICE 'Tabelas criadas: 10';
    RAISE NOTICE 'Funções criadas: 8';
    RAISE NOTICE 'Views criadas: 15';
    RAISE NOTICE 'Triggers criados: 6';
    RAISE NOTICE '=====================================================';
    RAISE NOTICE 'Próximo passo: Testar as funcionalidades';
    RAISE NOTICE '=====================================================';
END $$;
