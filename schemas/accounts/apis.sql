-- Tabela de endpoints da API
-- Schema: accounts
-- Tabela: apis

-- Esta tabela é criada automaticamente pelo dump principal
-- Este arquivo serve como documentação e referência

/*
CREATE TABLE accounts.apis (
    api_id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    module_id uuid,
    path text NOT NULL,
    method text NOT NULL,
    description text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone,
    FOREIGN KEY (module_id) REFERENCES accounts.modules(module_id)
);
*/

-- Campos principais:
-- api_id: Identificador único da API (UUID)
-- module_id: Módulo ao qual a API pertence
-- path: Caminho do endpoint (ex: /purchases)
-- method: Método HTTP (ex: GET, POST, PUT, DELETE)
-- description: Descrição do funcionamento do endpoint
-- created_at: Data de criação do endpoint
-- updated_at: Data da última atualização

-- Constraints:
-- PRIMARY KEY: api_id
-- NOT NULL: path, method, created_at
-- FOREIGN KEY: module_id -> accounts.modules.module_id

-- Triggers:
-- updated_at: Atualiza automaticamente o campo updated_at

-- Auditoria:
-- Automática via schema audit (audit.accounts__apis)

-- Relacionamentos:
-- accounts.apis.module_id -> accounts.modules.module_id

-- Comentários da tabela:
-- COMMENT ON TABLE accounts.apis IS 'Endpoints expostos da API vinculados a features do sistema';
-- COMMENT ON COLUMN accounts.apis.api_id IS 'Identificador único da API';
-- COMMENT ON COLUMN accounts.apis.module_id IS 'Módulo ao qual a API pertence';
-- COMMENT ON COLUMN accounts.apis.path IS 'Caminho do endpoint (ex: /purchases)';
-- COMMENT ON COLUMN accounts.apis.method IS 'Método HTTP (ex: GET, POST, PUT)';
-- COMMENT ON COLUMN accounts.apis.description IS 'Descrição do funcionamento do endpoint';
-- COMMENT ON COLUMN accounts.apis.created_at IS 'Data de criação do endpoint';
-- COMMENT ON COLUMN accounts.apis.updated_at IS 'Data de última atualização do endpoint';

-- Funcionalidades:
-- Mapeamento de endpoints da API
-- Organização por módulos funcionais
-- Documentação de funcionalidades da API
-- Base para controle de acesso e auditoria

-- Índices:
-- CREATE INDEX idx_apis_path_method ON accounts.apis USING btree (path, method);
-- CREATE INDEX idx_apis_module ON accounts.apis USING btree (module_id);
-- CREATE INDEX idx_apis_path ON accounts.apis USING btree (path);
-- CREATE INDEX idx_apis_method ON accounts.apis USING btree (method);

-- Exemplos de endpoints:
-- /users (GET, POST, PUT, DELETE)
-- /employees (GET, POST, PUT, DELETE)
-- /establishments (GET, POST, PUT, DELETE)
-- /products (GET, POST, PUT, DELETE)
-- /quotations (GET, POST, PUT, DELETE)
