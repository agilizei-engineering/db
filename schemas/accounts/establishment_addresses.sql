-- Tabela de endereços dos estabelecimentos
-- Schema: accounts
-- Tabela: establishment_addresses

-- Esta tabela é criada automaticamente pelo establishments_extension.sql
-- Este arquivo serve como documentação e referência

/*
CREATE TABLE accounts.establishment_addresses (
    establishment_address_id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    establishment_id uuid NOT NULL,
    postal_code text NOT NULL,
    street text NOT NULL,
    number text NOT NULL,
    complement text,
    neighborhood text NOT NULL,
    city text NOT NULL,
    state text NOT NULL,
    is_primary boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone,
    FOREIGN KEY (establishment_id) REFERENCES accounts.establishments(establishment_id) ON DELETE CASCADE
);
*/

-- Campos principais:
-- establishment_address_id: Identificador único do endereço (UUID)
-- establishment_id: Referência ao estabelecimento
-- postal_code: CEP (apenas números, 8 dígitos)
-- street: Logradouro (Rua, Avenida, etc.)
-- number: Número do endereço
-- complement: Complemento do endereço (opcional)
-- neighborhood: Bairro
-- city: Cidade
-- state: Estado (sigla de 2 letras)
-- is_primary: Indica se é o endereço principal
-- created_at: Data de criação
-- updated_at: Data da última atualização

-- Constraints:
-- PRIMARY KEY: establishment_address_id
-- NOT NULL: establishment_id, postal_code, street, number, neighborhood, city, state, is_primary, created_at
-- FOREIGN KEY: establishment_id -> accounts.establishments.establishment_id ON DELETE CASCADE
-- CHECK: postal_code válido via aux.validate_postal_code()
-- CHECK: state válido via aux.estado_brasileiro

-- Triggers:
-- updated_at: Atualiza automaticamente o campo updated_at
-- postal_code_validation: Valida e limpa CEP automaticamente

-- Auditoria:
-- Automática via schema audit (audit.accounts__establishment_addresses)

-- Relacionamentos:
-- accounts.establishment_addresses.establishment_id -> accounts.establishments.establishment_id

-- Comentários da tabela:
-- COMMENT ON TABLE accounts.establishment_addresses IS 'Endereços dos estabelecimentos';
-- COMMENT ON COLUMN accounts.establishment_addresses.establishment_address_id IS 'Identificador único do endereço';
-- COMMENT ON COLUMN accounts.establishment_addresses.establishment_id IS 'Referência ao estabelecimento';
-- COMMENT ON COLUMN accounts.establishment_addresses.postal_code IS 'CEP (apenas números, 8 dígitos)';
-- COMMENT ON COLUMN accounts.establishment_addresses.street IS 'Logradouro (Rua, Avenida, etc.)';
-- COMMENT ON COLUMN accounts.establishment_addresses.number IS 'Número do endereço';
-- COMMENT ON COLUMN accounts.establishment_addresses.complement IS 'Complemento do endereço (opcional)';
-- COMMENT ON COLUMN accounts.establishment_addresses.neighborhood IS 'Bairro';
-- COMMENT ON COLUMN accounts.establishment_addresses.city IS 'Cidade';
-- COMMENT ON COLUMN accounts.establishment_addresses.state IS 'Estado (sigla de 2 letras)';
-- COMMENT ON COLUMN accounts.establishment_addresses.is_primary IS 'Indica se é o endereço principal';
-- COMMENT ON COLUMN accounts.establishment_addresses.created_at IS 'Data de criação do registro';
-- COMMENT ON COLUMN accounts.establishment_addresses.updated_at IS 'Data da última atualização';

-- Funcionalidades:
-- Armazenamento de endereços dos estabelecimentos
-- Validação automática de CEP
-- Limpeza automática de máscaras de CEP
-- Controle de endereço principal
-- Suporte a múltiplos endereços por estabelecimento

-- Índices:
-- CREATE INDEX idx_establishment_addresses_establishment_id ON accounts.establishment_addresses(establishment_id);
-- CREATE INDEX idx_establishment_addresses_postal_code ON accounts.establishment_addresses(postal_code);
-- CREATE INDEX idx_establishment_addresses_city ON accounts.establishment_addresses(city);
-- CREATE INDEX idx_establishment_addresses_state ON accounts.establishment_addresses(state);
-- CREATE INDEX idx_establishment_addresses_street ON accounts.establishment_addresses(street);
-- CREATE INDEX idx_establishment_addresses_neighborhood ON accounts.establishment_addresses(neighborhood);

-- Índices de texto para busca:
-- CREATE INDEX idx_establishment_addresses_street_gin ON accounts.establishment_addresses USING gin(to_tsvector('portuguese', street));
-- CREATE INDEX idx_establishment_addresses_neighborhood_gin ON accounts.establishment_addresses USING gin(to_tsvector('portuguese', neighborhood));
-- CREATE INDEX idx_establishment_addresses_city_gin ON accounts.establishment_addresses USING gin(to_tsvector('portuguese', city));

-- Índices trigram para busca fuzzy (se pg_trgm disponível):
-- CREATE INDEX idx_establishment_addresses_street_trgm ON accounts.establishment_addresses USING gin(street gin_trgm_ops);
-- CREATE INDEX idx_establishment_addresses_neighborhood_trgm ON accounts.establishment_addresses USING gin(neighborhood gin_trgm_ops);
-- CREATE INDEX idx_establishment_addresses_city_trgm ON accounts.establishment_addresses USING gin(city gin_trgm_ops);
