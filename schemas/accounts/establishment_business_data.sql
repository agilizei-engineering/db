-- Tabela de dados empresariais dos estabelecimentos
-- Schema: accounts
-- Tabela: establishment_business_data

-- Esta tabela é criada automaticamente pelo establishments_extension.sql
-- Este arquivo serve como documentação e referência

/*
CREATE TABLE accounts.establishment_business_data (
    establishment_business_data_id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    establishment_id uuid NOT NULL,
    cnpj text NOT NULL,
    trade_name text NOT NULL,
    corporate_name text NOT NULL,
    state_registration text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone,
    FOREIGN KEY (establishment_id) REFERENCES accounts.establishments(establishment_id) ON DELETE CASCADE
);
*/

-- Campos principais:
-- establishment_business_data_id: Identificador único dos dados empresariais (UUID)
-- establishment_id: Referência ao estabelecimento
-- cnpj: CNPJ da empresa (apenas números, 14 dígitos)
-- trade_name: Nome Fantasia da empresa
-- corporate_name: Razão Social da empresa
-- state_registration: Número da Inscrição Estadual
-- created_at: Data de criação
-- updated_at: Data da última atualização

-- Constraints:
-- PRIMARY KEY: establishment_business_data_id
-- NOT NULL: establishment_id, cnpj, trade_name, corporate_name, created_at
-- FOREIGN KEY: establishment_id -> accounts.establishments.establishment_id ON DELETE CASCADE
-- CHECK: cnpj válido via aux.validate_cnpj()

-- Triggers:
-- updated_at: Atualiza automaticamente o campo updated_at
-- cnpj_validation: Valida e limpa CNPJ automaticamente

-- Auditoria:
-- Automática via schema audit (audit.accounts__establishment_business_data)

-- Relacionamentos:
-- accounts.establishment_business_data.establishment_id -> accounts.establishments.establishment_id

-- Comentários da tabela:
-- COMMENT ON TABLE accounts.establishment_business_data IS 'Dados empresariais específicos dos estabelecimentos (CNPJ, Razão Social, etc.)';
-- COMMENT ON COLUMN accounts.establishment_business_data.establishment_business_data_id IS 'Identificador único dos dados empresariais';
-- COMMENT ON COLUMN accounts.establishment_business_data.establishment_id IS 'Referência ao estabelecimento';
-- COMMENT ON COLUMN accounts.establishment_business_data.cnpj IS 'CNPJ da empresa (apenas números, 14 dígitos)';
-- COMMENT ON COLUMN accounts.establishment_business_data.trade_name IS 'Nome Fantasia da empresa';
-- COMMENT ON COLUMN accounts.establishment_business_data.corporate_name IS 'Razão Social da empresa';
-- COMMENT ON COLUMN accounts.establishment_business_data.state_registration IS 'Número da Inscrição Estadual';
-- COMMENT ON COLUMN accounts.establishment_business_data.created_at IS 'Data de criação do registro';
-- COMMENT ON COLUMN accounts.establishment_business_data.updated_at IS 'Data da última atualização';

-- Funcionalidades:
-- Armazenamento de dados empresariais dos estabelecimentos
-- Validação automática de CNPJ
-- Limpeza automática de máscaras de CNPJ
-- Controle de dados fiscais e empresariais

-- Índices:
-- CREATE INDEX idx_establishment_business_data_cnpj ON accounts.establishment_business_data(cnpj);
-- CREATE INDEX idx_establishment_business_data_trade_name ON accounts.establishment_business_data(trade_name);
-- CREATE INDEX idx_establishment_business_data_corporate_name ON accounts.establishment_business_data(corporate_name);
-- CREATE INDEX idx_establishment_business_data_establishment_id ON accounts.establishment_business_data(establishment_id);

-- Índices de texto para busca:
-- CREATE INDEX idx_establishment_business_data_trade_name_gin ON accounts.establishment_business_data USING gin(to_tsvector('portuguese', trade_name));
-- CREATE INDEX idx_establishment_business_data_corporate_name_gin ON accounts.establishment_business_data USING gin(to_tsvector('portuguese', corporate_name));

-- Índices trigram para busca fuzzy (se pg_trgm disponível):
-- CREATE INDEX idx_establishment_business_data_trade_name_trgm ON accounts.establishment_business_data USING gin(trade_name gin_trgm_ops);
-- CREATE INDEX idx_establishment_business_data_corporate_name_trgm ON accounts.establishment_business_data USING gin(corporate_name gin_trgm_ops);
