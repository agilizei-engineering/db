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
