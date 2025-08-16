-- Tabela de dados pessoais dos funcionários
-- Schema: accounts
-- Tabela: employee_personal_data

-- Esta tabela é criada automaticamente pelo employees_extension.sql
-- Este arquivo serve como documentação e referência

/*
CREATE TABLE accounts.employee_personal_data (
    employee_personal_data_id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    employee_id uuid NOT NULL,
    cpf text NOT NULL,
    full_name text NOT NULL,
    birth_date date NOT NULL,
    gender text NOT NULL,
    photo_url text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone,
    FOREIGN KEY (employee_id) REFERENCES accounts.employees(employee_id) ON DELETE CASCADE
);
*/

-- Campos principais:
-- employee_personal_data_id: Identificador único dos dados pessoais (UUID)
-- employee_id: Referência ao funcionário
-- cpf: CPF do funcionário (apenas números, 11 dígitos)
-- full_name: Nome completo do funcionário
-- birth_date: Data de nascimento
-- gender: Sexo (M=Masculino, F=Feminino, O=Outro)
-- photo_url: URL da foto do funcionário (opcional)
-- created_at: Data de criação
-- updated_at: Data da última atualização

-- Constraints:
-- PRIMARY KEY: employee_personal_data_id
-- NOT NULL: employee_id, cpf, full_name, birth_date, gender, created_at
-- FOREIGN KEY: employee_id -> accounts.employees.employee_id ON DELETE CASCADE
-- CHECK: cpf válido via aux.validate_cpf()
-- CHECK: birth_date válido via aux.validate_birth_date() (idade mínima: 14 anos)
-- CHECK: gender válido via aux.genero (M/F/O)
-- CHECK: photo_url válido via aux.validate_url() (se não for NULL)

-- Triggers:
-- updated_at: Atualiza automaticamente o campo updated_at
-- cpf_validation: Valida e limpa CPF automaticamente
-- birth_date_validation: Valida data de nascimento automaticamente
-- photo_url_validation: Valida URL da foto automaticamente

-- Auditoria:
-- Automática via schema audit (audit.accounts__employee_personal_data)

-- Relacionamentos:
-- accounts.employee_personal_data.employee_id -> accounts.employees.employee_id

-- Comentários da tabela:
-- COMMENT ON TABLE accounts.employee_personal_data IS 'Dados pessoais dos funcionários (CPF, nome, nascimento, sexo, foto)';
-- COMMENT ON COLUMN accounts.employee_personal_data.employee_personal_data_id IS 'ID único dos dados pessoais';
-- COMMENT ON COLUMN accounts.employee_personal_data.employee_id IS 'Referência ao funcionário';
-- COMMENT ON COLUMN accounts.employee_personal_data.cpf IS 'CPF do funcionário (apenas números)';
-- COMMENT ON COLUMN accounts.employee_personal_data.full_name IS 'Nome completo do funcionário';
-- COMMENT ON COLUMN accounts.employee_personal_data.birth_date IS 'Data de nascimento';
-- COMMENT ON COLUMN accounts.employee_personal_data.gender IS 'Sexo (M=Masculino, F=Feminino, O=Outro)';
-- COMMENT ON COLUMN accounts.employee_personal_data.photo_url IS 'URL da foto do funcionário (opcional)';
-- COMMENT ON COLUMN accounts.employee_personal_data.created_at IS 'Data de criação do registro';
-- COMMENT ON COLUMN accounts.employee_personal_data.updated_at IS 'Data da última atualização';

-- Funcionalidades:
-- Armazenamento de dados pessoais dos funcionários
-- Validação automática de CPF
-- Limpeza automática de máscaras de CPF
-- Validação de data de nascimento com idade mínima
-- Validação de gênero
-- Validação de URL da foto (opcional)

-- Índices:
-- CREATE INDEX idx_employee_personal_data_employee_id ON accounts.employee_personal_data(employee_id);
-- CREATE INDEX idx_employee_personal_data_cpf ON accounts.employee_personal_data(cpf);
-- CREATE INDEX idx_employee_personal_data_full_name ON accounts.employee_personal_data(full_name);
-- CREATE INDEX idx_employee_personal_data_birth_date ON accounts.employee_personal_data(birth_date);
-- CREATE INDEX idx_employee_personal_data_gender ON accounts.employee_personal_data(gender);

-- Índices de texto para busca:
-- CREATE INDEX idx_employee_personal_data_full_name_gin ON accounts.employee_personal_data USING gin(to_tsvector('portuguese', full_name));

-- Índices trigram para busca fuzzy (se pg_trgm disponível):
-- CREATE INDEX idx_employee_personal_data_full_name_trgm ON accounts.employee_personal_data USING gin(full_name gin_trgm_ops);
