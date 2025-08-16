-- Tabela de vínculos entre funcionários e papéis
-- Schema: accounts
-- Tabela: employee_roles

-- Esta tabela é criada automaticamente pelo dump principal
-- Este arquivo serve como documentação e referência

/*
CREATE TABLE accounts.employee_roles (
    employee_role_id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    employee_id uuid NOT NULL,
    role_id uuid NOT NULL,
    granted_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone,
    FOREIGN KEY (employee_id) REFERENCES accounts.employees(employee_id),
    FOREIGN KEY (role_id) REFERENCES accounts.roles(role_id)
);
*/

-- Campos principais:
-- employee_role_id: Identificador único do vínculo (UUID)
-- employee_id: Funcionário que recebe o papel
-- role_id: Papel atribuído ao funcionário
-- granted_at: Data de concessão do papel
-- updated_at: Data da última modificação do vínculo

-- Constraints:
-- PRIMARY KEY: employee_role_id
-- NOT NULL: employee_id, role_id, granted_at
-- FOREIGN KEY: employee_id -> accounts.employees.employee_id
-- FOREIGN KEY: role_id -> accounts.roles.role_id

-- Triggers:
-- updated_at: Atualiza automaticamente o campo updated_at

-- Auditoria:
-- Automática via schema audit (audit.accounts__employee_roles)

-- Relacionamentos:
-- accounts.employee_roles.employee_id -> accounts.employees.employee_id
-- accounts.employee_roles.role_id -> accounts.roles.role_id

-- Comentários da tabela:
-- COMMENT ON TABLE accounts.employee_roles IS 'Vínculos entre funcionários e papéis nomeados (roles)';
-- COMMENT ON COLUMN accounts.employee_roles.employee_role_id IS 'Identificador do vínculo entre employee e role';
-- COMMENT ON COLUMN accounts.employee_roles.employee_id IS 'Funcionário que recebe o papel';
-- COMMENT ON COLUMN accounts.employee_roles.role_id IS 'Papel atribuído ao funcionário';
-- COMMENT ON COLUMN accounts.employee_roles.granted_at IS 'Data de concessão do papel';
-- COMMENT ON COLUMN accounts.employee_roles.updated_at IS 'Data da última modificação do vínculo';

-- Funcionalidades:
-- Controle de acesso baseado em papéis (RBAC)
-- Atribuição de múltiplos papéis por funcionário
-- Rastreamento de concessão de papéis
-- Base para controle de permissões granulares

-- Índices:
-- CREATE INDEX idx_employee_roles_employee ON accounts.employee_roles USING btree (employee_id);
-- CREATE INDEX idx_employee_roles_role ON accounts.employee_roles USING btree (role_id);
-- CREATE INDEX idx_employee_roles_granted_at ON accounts.employee_roles USING btree (granted_at);
