-- Tabela de endereços dos funcionários
-- Schema: accounts
-- Tabela: employee_addresses

-- Esta tabela é criada automaticamente pelo employees_extension.sql
-- Este arquivo serve como documentação e referência

/*
CREATE TABLE accounts.employee_addresses (
    employee_address_id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    employee_id uuid NOT NULL,
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
    FOREIGN KEY (employee_id) REFERENCES accounts.employees(employee_id) ON DELETE CASCADE
);
*/

-- Campos principais:
-- employee_address_id: Identificador único do endereço (UUID)
-- employee_id: Referência ao funcionário
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
-- PRIMARY KEY: employee_address_id
-- NOT NULL: employee_id, postal_code, street, number, neighborhood, city, state, is_primary, created_at
-- FOREIGN KEY: employee_id -> accounts.employees.employee_id ON DELETE CASCADE
-- CHECK: postal_code válido via aux.validate_postal_code()
-- CHECK: state válido via aux.estado_brasileiro

-- Triggers:
-- updated_at: Atualiza automaticamente o campo updated_at
-- postal_code_validation: Valida e limpa CEP automaticamente

-- Auditoria:
-- Automática via schema audit (audit.accounts__employee_addresses)

-- Relacionamentos:
-- accounts.employee_addresses.employee_id -> accounts.employees.employee_id

-- Comentários da tabela:
-- COMMENT ON TABLE accounts.employee_addresses IS 'Endereços dos funcionários';
-- COMMENT ON COLUMN accounts.employee_addresses.employee_address_id IS 'ID único do endereço';
-- COMMENT ON COLUMN accounts.employee_addresses.employee_id IS 'Referência ao funcionário';
-- COMMENT ON COLUMN accounts.employee_addresses.postal_code IS 'CEP (apenas números)';
-- COMMENT ON COLUMN accounts.employee_addresses.street IS 'Nome da rua';
-- COMMENT ON COLUMN accounts.employee_addresses.number IS 'Número do endereço';
-- COMMENT ON COLUMN accounts.employee_addresses.complement IS 'Complemento do endereço';
-- COMMENT ON COLUMN accounts.employee_addresses.neighborhood IS 'Bairro';
-- COMMENT ON COLUMN accounts.employee_addresses.city IS 'Cidade';
-- COMMENT ON COLUMN accounts.employee_addresses.state IS 'Estado (UF)';
-- COMMENT ON COLUMN accounts.employee_addresses.is_primary IS 'Indica se é o endereço principal';
-- COMMENT ON COLUMN accounts.employee_addresses.created_at IS 'Data de criação do registro';
-- COMMENT ON COLUMN accounts.employee_addresses.updated_at IS 'Data da última atualização';

-- Funcionalidades:
-- Armazenamento de endereços dos funcionários
-- Validação automática de CEP
-- Limpeza automática de máscaras de CEP
-- Controle de endereço principal
-- Suporte a múltiplos endereços por funcionário

-- Índices:
-- CREATE INDEX idx_employee_addresses_employee_id ON accounts.employee_addresses(employee_id);
-- CREATE INDEX idx_employee_addresses_postal_code ON accounts.employee_addresses(postal_code);
-- CREATE INDEX idx_employee_addresses_city ON accounts.employee_addresses(city);
-- CREATE INDEX idx_employee_addresses_state ON accounts.employee_addresses(state);
-- CREATE INDEX idx_employee_addresses_street ON accounts.employee_addresses(street);
-- CREATE INDEX idx_employee_addresses_neighborhood ON accounts.employee_addresses(neighborhood);

-- Índices de texto para busca:
-- CREATE INDEX idx_employee_addresses_city_gin ON accounts.employee_addresses USING gin(to_tsvector('portuguese', city));
-- CREATE INDEX idx_employee_addresses_street_gin ON accounts.employee_addresses USING gin(to_tsvector('portuguese', street));
-- CREATE INDEX idx_employee_addresses_neighborhood_gin ON accounts.employee_addresses USING gin(to_tsvector('portuguese', neighborhood));

-- Índices trigram para busca fuzzy (se pg_trgm disponível):
-- CREATE INDEX idx_employee_addresses_city_trgm ON accounts.employee_addresses USING gin(city gin_trgm_ops);
-- CREATE INDEX idx_employee_addresses_street_trgm ON accounts.employee_addresses USING gin(street gin_trgm_ops);
-- CREATE INDEX idx_employee_addresses_neighborhood_trgm ON accounts.employee_addresses USING gin(neighborhood gin_trgm_ops);
