-- Tabela de funcionários e colaboradores
-- Schema: accounts
-- Tabela: employees

-- Esta tabela é criada automaticamente pelo dump principal
-- Este arquivo serve como documentação e referência

/*
CREATE TABLE accounts.employees (
    employee_id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id uuid NOT NULL,
    establishment_id uuid,
    supplier_id uuid,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone,
    FOREIGN KEY (user_id) REFERENCES accounts.users(user_id),
    FOREIGN KEY (establishment_id) REFERENCES accounts.establishments(establishment_id),
    FOREIGN KEY (supplier_id) REFERENCES accounts.establishments(establishment_id)
);
*/

-- Campos principais:
-- employee_id: Identificador único do funcionário (UUID)
-- user_id: Referência ao usuário (obrigatório)
-- establishment_id: Estabelecimento onde trabalha (opcional)
-- supplier_id: Fornecedor (opcional)
-- is_active: Status ativo/inativo do funcionário
-- created_at: Data de criação
-- updated_at: Data da última atualização

-- Constraints:
-- PRIMARY KEY: employee_id
-- FOREIGN KEY: user_id -> accounts.users.user_id
-- FOREIGN KEY: establishment_id -> accounts.establishments.establishment_id
-- FOREIGN KEY: supplier_id -> accounts.establishments.establishment_id

-- Triggers:
-- updated_at: Atualiza automaticamente o campo updated_at

-- Auditoria:
-- Automática via schema audit (audit.accounts__employees)

-- Relacionamentos:
-- accounts.employee_personal_data.employee_id -> accounts.employees.employee_id
-- accounts.employee_addresses.employee_id -> accounts.employees.employee_id
-- sessions.user_sessions.employee_id -> accounts.employees.employee_id

-- Funcionalidades:
-- Um usuário pode ter múltiplos papéis em diferentes estabelecimentos
-- Suporte a funcionários que também são fornecedores
-- Sistema multi-persona para controle de acesso

-- Comentários da tabela:
-- COMMENT ON TABLE accounts.employees IS 'Funcionários vinculados a fornecedores ou estabelecimentos';
-- COMMENT ON COLUMN accounts.employees.employee_id IS 'Identificador do vínculo funcional';
-- COMMENT ON COLUMN accounts.employees.user_id IS 'Usuário associado ao funcionário';
-- COMMENT ON COLUMN accounts.employees.supplier_id IS 'Fornecedor ao qual o funcionário pertence';
-- COMMENT ON COLUMN accounts.employees.establishment_id IS 'Estabelecimento ao qual o funcionário pertence';
-- COMMENT ON COLUMN accounts.employees.is_active IS 'Se o vínculo está ativo';
-- COMMENT ON COLUMN accounts.employees.activated_at IS 'Data de ativação do vínculo';
-- COMMENT ON COLUMN accounts.employees.deactivated_at IS 'Data de desativação do vínculo';
-- COMMENT ON COLUMN accounts.employees.created_at IS 'Data de criação';
-- COMMENT ON COLUMN accounts.employees.updated_at IS 'Data da última atualização';

-- Índices:
-- CREATE INDEX idx_employees_user_id ON accounts.employees USING btree (user_id);
-- CREATE INDEX idx_employees_establishment_id ON accounts.employees USING btree (establishment_id);
-- CREATE INDEX idx_employees_supplier_id ON accounts.employees USING btree (supplier_id);
-- CREATE INDEX idx_employees_active ON accounts.employees USING btree (is_active);
-- CREATE INDEX idx_employees_supplier_active ON accounts.employees USING btree (supplier_id, is_active);
