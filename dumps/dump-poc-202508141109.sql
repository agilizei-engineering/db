--
-- PostgreSQL database dump
--

-- Dumped from database version 17.4
-- Dumped by pg_dump version 17.5 (Homebrew)

-- Started on 2025-08-14 11:09:30 -03

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 7 (class 2615 OID 17223)
-- Name: accounts; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA accounts;


ALTER SCHEMA accounts OWNER TO postgres;

--
-- TOC entry 9 (class 2615 OID 17915)
-- Name: catalogs; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA catalogs;


ALTER SCHEMA catalogs OWNER TO postgres;

--
-- TOC entry 268 (class 1255 OID 17225)
-- Name: set_updated_at(); Type: FUNCTION; Schema: accounts; Owner: postgres
--

CREATE FUNCTION accounts.set_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END;
$$;


ALTER FUNCTION accounts.set_updated_at() OWNER TO postgres;

--
-- TOC entry 4671 (class 0 OID 0)
-- Dependencies: 268
-- Name: FUNCTION set_updated_at(); Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON FUNCTION accounts.set_updated_at() IS 'Função que atualiza o campo updated_at automaticamente em alterações de registros.';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 250 (class 1259 OID 17697)
-- Name: api_keys; Type: TABLE; Schema: accounts; Owner: postgres
--

CREATE TABLE accounts.api_keys (
    api_key_id uuid DEFAULT gen_random_uuid() NOT NULL,
    employee_id uuid NOT NULL,
    name text NOT NULL,
    secret text NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone
);


ALTER TABLE accounts.api_keys OWNER TO postgres;

--
-- TOC entry 4672 (class 0 OID 0)
-- Dependencies: 250
-- Name: TABLE api_keys; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON TABLE accounts.api_keys IS 'Chaves de autenticação geradas para integração de APIs por employees';


--
-- TOC entry 4673 (class 0 OID 0)
-- Dependencies: 250
-- Name: COLUMN api_keys.api_key_id; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.api_keys.api_key_id IS 'Identificador único da chave de API';


--
-- TOC entry 4674 (class 0 OID 0)
-- Dependencies: 250
-- Name: COLUMN api_keys.employee_id; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.api_keys.employee_id IS 'Employee que possui a chave';


--
-- TOC entry 4675 (class 0 OID 0)
-- Dependencies: 250
-- Name: COLUMN api_keys.name; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.api_keys.name IS 'Nome de exibição da chave';


--
-- TOC entry 4676 (class 0 OID 0)
-- Dependencies: 250
-- Name: COLUMN api_keys.secret; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.api_keys.secret IS 'Chave secreta usada na autenticação';


--
-- TOC entry 4677 (class 0 OID 0)
-- Dependencies: 250
-- Name: COLUMN api_keys.created_at; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.api_keys.created_at IS 'Data de criação do registro';


--
-- TOC entry 4678 (class 0 OID 0)
-- Dependencies: 250
-- Name: COLUMN api_keys.updated_at; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.api_keys.updated_at IS 'Data da última atualização do registro';


--
-- TOC entry 251 (class 1259 OID 17711)
-- Name: api_scopes; Type: TABLE; Schema: accounts; Owner: postgres
--

CREATE TABLE accounts.api_scopes (
    api_scope_id uuid DEFAULT gen_random_uuid() NOT NULL,
    api_key_id uuid NOT NULL,
    feature_id uuid NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE accounts.api_scopes OWNER TO postgres;

--
-- TOC entry 4679 (class 0 OID 0)
-- Dependencies: 251
-- Name: TABLE api_scopes; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON TABLE accounts.api_scopes IS 'Define os escopos de acesso das chaves de API às features do sistema';


--
-- TOC entry 4680 (class 0 OID 0)
-- Dependencies: 251
-- Name: COLUMN api_scopes.api_scope_id; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.api_scopes.api_scope_id IS 'Identificador único do escopo';


--
-- TOC entry 4681 (class 0 OID 0)
-- Dependencies: 251
-- Name: COLUMN api_scopes.api_key_id; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.api_scopes.api_key_id IS 'Chave de API à qual o escopo pertence';


--
-- TOC entry 4682 (class 0 OID 0)
-- Dependencies: 251
-- Name: COLUMN api_scopes.feature_id; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.api_scopes.feature_id IS 'Feature autorizada para acesso via API';


--
-- TOC entry 4683 (class 0 OID 0)
-- Dependencies: 251
-- Name: COLUMN api_scopes.created_at; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.api_scopes.created_at IS 'Data de criação do registro';


--
-- TOC entry 249 (class 1259 OID 17420)
-- Name: apis; Type: TABLE; Schema: accounts; Owner: postgres
--

CREATE TABLE accounts.apis (
    api_id uuid DEFAULT gen_random_uuid() NOT NULL,
    path text NOT NULL,
    method text NOT NULL,
    description text,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone,
    module_id uuid
);


ALTER TABLE accounts.apis OWNER TO postgres;

--
-- TOC entry 4684 (class 0 OID 0)
-- Dependencies: 249
-- Name: TABLE apis; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON TABLE accounts.apis IS 'Endpoints expostos da API vinculados a features do sistema';


--
-- TOC entry 4685 (class 0 OID 0)
-- Dependencies: 249
-- Name: COLUMN apis.api_id; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.apis.api_id IS 'Identificador único da API';


--
-- TOC entry 4686 (class 0 OID 0)
-- Dependencies: 249
-- Name: COLUMN apis.path; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.apis.path IS 'Caminho do endpoint (ex: /purchases)';


--
-- TOC entry 4687 (class 0 OID 0)
-- Dependencies: 249
-- Name: COLUMN apis.method; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.apis.method IS 'Método HTTP (ex: GET, POST, PUT)';


--
-- TOC entry 4688 (class 0 OID 0)
-- Dependencies: 249
-- Name: COLUMN apis.description; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.apis.description IS 'Descrição do funcionamento do endpoint';


--
-- TOC entry 4689 (class 0 OID 0)
-- Dependencies: 249
-- Name: COLUMN apis.created_at; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.apis.created_at IS 'Data de criação do endpoint';


--
-- TOC entry 4690 (class 0 OID 0)
-- Dependencies: 249
-- Name: COLUMN apis.updated_at; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.apis.updated_at IS 'Data de última atualização do endpoint';


--
-- TOC entry 248 (class 1259 OID 17398)
-- Name: employee_roles; Type: TABLE; Schema: accounts; Owner: postgres
--

CREATE TABLE accounts.employee_roles (
    employee_role_id uuid DEFAULT gen_random_uuid() NOT NULL,
    employee_id uuid NOT NULL,
    role_id uuid NOT NULL,
    granted_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone
);


ALTER TABLE accounts.employee_roles OWNER TO postgres;

--
-- TOC entry 4691 (class 0 OID 0)
-- Dependencies: 248
-- Name: TABLE employee_roles; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON TABLE accounts.employee_roles IS 'Vínculos entre funcionários e papéis nomeados (roles)';


--
-- TOC entry 4692 (class 0 OID 0)
-- Dependencies: 248
-- Name: COLUMN employee_roles.employee_role_id; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.employee_roles.employee_role_id IS 'Identificador do vínculo entre employee e role';


--
-- TOC entry 4693 (class 0 OID 0)
-- Dependencies: 248
-- Name: COLUMN employee_roles.employee_id; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.employee_roles.employee_id IS 'Funcionário que recebe o papel';


--
-- TOC entry 4694 (class 0 OID 0)
-- Dependencies: 248
-- Name: COLUMN employee_roles.role_id; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.employee_roles.role_id IS 'Papel atribuído ao funcionário';


--
-- TOC entry 4695 (class 0 OID 0)
-- Dependencies: 248
-- Name: COLUMN employee_roles.granted_at; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.employee_roles.granted_at IS 'Data de concessão do papel';


--
-- TOC entry 4696 (class 0 OID 0)
-- Dependencies: 248
-- Name: COLUMN employee_roles.updated_at; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.employee_roles.updated_at IS 'Data da última modificação do vínculo';


--
-- TOC entry 242 (class 1259 OID 17272)
-- Name: employees; Type: TABLE; Schema: accounts; Owner: postgres
--

CREATE TABLE accounts.employees (
    employee_id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    supplier_id uuid,
    establishment_id uuid,
    is_active boolean DEFAULT true NOT NULL,
    activated_at timestamp without time zone DEFAULT now(),
    deactivated_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone,
    CONSTRAINT employees_check CHECK ((((supplier_id IS NOT NULL) AND (establishment_id IS NULL)) OR ((supplier_id IS NULL) AND (establishment_id IS NOT NULL))))
);


ALTER TABLE accounts.employees OWNER TO postgres;

--
-- TOC entry 4697 (class 0 OID 0)
-- Dependencies: 242
-- Name: TABLE employees; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON TABLE accounts.employees IS 'Funcionários vinculados a fornecedores ou estabelecimentos';


--
-- TOC entry 4698 (class 0 OID 0)
-- Dependencies: 242
-- Name: COLUMN employees.employee_id; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.employees.employee_id IS 'Identificador do vínculo funcional';


--
-- TOC entry 4699 (class 0 OID 0)
-- Dependencies: 242
-- Name: COLUMN employees.user_id; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.employees.user_id IS 'Usuário associado ao funcionário';


--
-- TOC entry 4700 (class 0 OID 0)
-- Dependencies: 242
-- Name: COLUMN employees.supplier_id; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.employees.supplier_id IS 'Fornecedor ao qual o funcionário pertence';


--
-- TOC entry 4701 (class 0 OID 0)
-- Dependencies: 242
-- Name: COLUMN employees.establishment_id; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.employees.establishment_id IS 'Estabelecimento ao qual o funcionário pertence';


--
-- TOC entry 4702 (class 0 OID 0)
-- Dependencies: 242
-- Name: COLUMN employees.is_active; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.employees.is_active IS 'Se o vínculo está ativo';


--
-- TOC entry 4703 (class 0 OID 0)
-- Dependencies: 242
-- Name: COLUMN employees.activated_at; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.employees.activated_at IS 'Data de ativação do vínculo';


--
-- TOC entry 4704 (class 0 OID 0)
-- Dependencies: 242
-- Name: COLUMN employees.deactivated_at; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.employees.deactivated_at IS 'Data de desativação do vínculo';


--
-- TOC entry 4705 (class 0 OID 0)
-- Dependencies: 242
-- Name: COLUMN employees.created_at; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.employees.created_at IS 'Data de criação';


--
-- TOC entry 4706 (class 0 OID 0)
-- Dependencies: 242
-- Name: COLUMN employees.updated_at; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.employees.updated_at IS 'Data da última atualização';


--
-- TOC entry 241 (class 1259 OID 17256)
-- Name: establishments; Type: TABLE; Schema: accounts; Owner: postgres
--

CREATE TABLE accounts.establishments (
    establishment_id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    activated_at timestamp without time zone DEFAULT now(),
    deactivated_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone
);


ALTER TABLE accounts.establishments OWNER TO postgres;

--
-- TOC entry 4707 (class 0 OID 0)
-- Dependencies: 241
-- Name: TABLE establishments; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON TABLE accounts.establishments IS 'Estabelecimentos que utilizam o sistema e possuem funcionários';


--
-- TOC entry 4708 (class 0 OID 0)
-- Dependencies: 241
-- Name: COLUMN establishments.establishment_id; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.establishments.establishment_id IS 'Identificador único do estabelecimento';


--
-- TOC entry 4709 (class 0 OID 0)
-- Dependencies: 241
-- Name: COLUMN establishments.name; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.establishments.name IS 'Nome do estabelecimento';


--
-- TOC entry 4710 (class 0 OID 0)
-- Dependencies: 241
-- Name: COLUMN establishments.is_active; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.establishments.is_active IS 'Indica se o estabelecimento está ativo';


--
-- TOC entry 4711 (class 0 OID 0)
-- Dependencies: 241
-- Name: COLUMN establishments.activated_at; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.establishments.activated_at IS 'Data de ativação';


--
-- TOC entry 4712 (class 0 OID 0)
-- Dependencies: 241
-- Name: COLUMN establishments.deactivated_at; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.establishments.deactivated_at IS 'Data de desativação';


--
-- TOC entry 4713 (class 0 OID 0)
-- Dependencies: 241
-- Name: COLUMN establishments.created_at; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.establishments.created_at IS 'Data de criação do registro';


--
-- TOC entry 4714 (class 0 OID 0)
-- Dependencies: 241
-- Name: COLUMN establishments.updated_at; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.establishments.updated_at IS 'Data da última atualização do registro';


--
-- TOC entry 245 (class 1259 OID 17339)
-- Name: features; Type: TABLE; Schema: accounts; Owner: postgres
--

CREATE TABLE accounts.features (
    feature_id uuid DEFAULT gen_random_uuid() NOT NULL,
    module_id uuid,
    name text NOT NULL,
    code text NOT NULL,
    description text,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone,
    platform_id uuid
);


ALTER TABLE accounts.features OWNER TO postgres;

--
-- TOC entry 4715 (class 0 OID 0)
-- Dependencies: 245
-- Name: TABLE features; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON TABLE accounts.features IS 'Funcionalidades específicas associadas a módulos';


--
-- TOC entry 4716 (class 0 OID 0)
-- Dependencies: 245
-- Name: COLUMN features.feature_id; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.features.feature_id IS 'Identificador da feature';


--
-- TOC entry 4717 (class 0 OID 0)
-- Dependencies: 245
-- Name: COLUMN features.module_id; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.features.module_id IS 'Módulo ao qual a feature pertence';


--
-- TOC entry 4718 (class 0 OID 0)
-- Dependencies: 245
-- Name: COLUMN features.name; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.features.name IS 'Nome da feature';


--
-- TOC entry 4719 (class 0 OID 0)
-- Dependencies: 245
-- Name: COLUMN features.code; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.features.code IS 'Código único da feature (para verificação de permissão)';


--
-- TOC entry 4720 (class 0 OID 0)
-- Dependencies: 245
-- Name: COLUMN features.description; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.features.description IS 'Descrição da feature';


--
-- TOC entry 4721 (class 0 OID 0)
-- Dependencies: 245
-- Name: COLUMN features.created_at; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.features.created_at IS 'Data de criação';


--
-- TOC entry 4722 (class 0 OID 0)
-- Dependencies: 245
-- Name: COLUMN features.updated_at; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.features.updated_at IS 'Data da última atualização';


--
-- TOC entry 244 (class 1259 OID 17318)
-- Name: modules; Type: TABLE; Schema: accounts; Owner: postgres
--

CREATE TABLE accounts.modules (
    module_id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    description text,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone
);


ALTER TABLE accounts.modules OWNER TO postgres;

--
-- TOC entry 4723 (class 0 OID 0)
-- Dependencies: 244
-- Name: TABLE modules; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON TABLE accounts.modules IS 'Módulos funcionais do sistema (ex: Lista de Compras)';


--
-- TOC entry 4724 (class 0 OID 0)
-- Dependencies: 244
-- Name: COLUMN modules.module_id; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.modules.module_id IS 'Identificador único do módulo';


--
-- TOC entry 4725 (class 0 OID 0)
-- Dependencies: 244
-- Name: COLUMN modules.name; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.modules.name IS 'Nome do módulo';


--
-- TOC entry 4726 (class 0 OID 0)
-- Dependencies: 244
-- Name: COLUMN modules.description; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.modules.description IS 'Descrição do módulo';


--
-- TOC entry 4727 (class 0 OID 0)
-- Dependencies: 244
-- Name: COLUMN modules.created_at; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.modules.created_at IS 'Data de criação';


--
-- TOC entry 4728 (class 0 OID 0)
-- Dependencies: 244
-- Name: COLUMN modules.updated_at; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.modules.updated_at IS 'Data da última atualização';


--
-- TOC entry 243 (class 1259 OID 17302)
-- Name: platforms; Type: TABLE; Schema: accounts; Owner: postgres
--

CREATE TABLE accounts.platforms (
    platform_id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    description text,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone
);


ALTER TABLE accounts.platforms OWNER TO postgres;

--
-- TOC entry 4729 (class 0 OID 0)
-- Dependencies: 243
-- Name: TABLE platforms; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON TABLE accounts.platforms IS 'Plataformas do sistema, como Área do Fornecedor, Aplicativo do Estabelecimento, etc.';


--
-- TOC entry 4730 (class 0 OID 0)
-- Dependencies: 243
-- Name: COLUMN platforms.platform_id; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.platforms.platform_id IS 'Identificador único da plataforma';


--
-- TOC entry 4731 (class 0 OID 0)
-- Dependencies: 243
-- Name: COLUMN platforms.name; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.platforms.name IS 'Nome da plataforma (ex: Área do Fornecedor)';


--
-- TOC entry 4732 (class 0 OID 0)
-- Dependencies: 243
-- Name: COLUMN platforms.description; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.platforms.description IS 'Descrição da plataforma';


--
-- TOC entry 4733 (class 0 OID 0)
-- Dependencies: 243
-- Name: COLUMN platforms.created_at; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.platforms.created_at IS 'Data de criação da plataforma';


--
-- TOC entry 4734 (class 0 OID 0)
-- Dependencies: 243
-- Name: COLUMN platforms.updated_at; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.platforms.updated_at IS 'Data da última atualização da plataforma';


--
-- TOC entry 247 (class 1259 OID 17376)
-- Name: role_features; Type: TABLE; Schema: accounts; Owner: postgres
--

CREATE TABLE accounts.role_features (
    role_feature_id uuid DEFAULT gen_random_uuid() NOT NULL,
    role_id uuid NOT NULL,
    feature_id uuid NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone
);


ALTER TABLE accounts.role_features OWNER TO postgres;

--
-- TOC entry 4735 (class 0 OID 0)
-- Dependencies: 247
-- Name: TABLE role_features; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON TABLE accounts.role_features IS 'Relaciona os papéis do sistema com suas permissões (features)';


--
-- TOC entry 4736 (class 0 OID 0)
-- Dependencies: 247
-- Name: COLUMN role_features.role_feature_id; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.role_features.role_feature_id IS 'Identificador único do vínculo role-feature';


--
-- TOC entry 4737 (class 0 OID 0)
-- Dependencies: 247
-- Name: COLUMN role_features.role_id; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.role_features.role_id IS 'Papel que receberá as permissões';


--
-- TOC entry 4738 (class 0 OID 0)
-- Dependencies: 247
-- Name: COLUMN role_features.feature_id; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.role_features.feature_id IS 'Permissão (feature) associada ao papel';


--
-- TOC entry 4739 (class 0 OID 0)
-- Dependencies: 247
-- Name: COLUMN role_features.created_at; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.role_features.created_at IS 'Data de criação';


--
-- TOC entry 4740 (class 0 OID 0)
-- Dependencies: 247
-- Name: COLUMN role_features.updated_at; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.role_features.updated_at IS 'Data da última modificação';


--
-- TOC entry 246 (class 1259 OID 17360)
-- Name: roles; Type: TABLE; Schema: accounts; Owner: postgres
--

CREATE TABLE accounts.roles (
    role_id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    description text,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone
);


ALTER TABLE accounts.roles OWNER TO postgres;

--
-- TOC entry 4741 (class 0 OID 0)
-- Dependencies: 246
-- Name: TABLE roles; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON TABLE accounts.roles IS 'Papéis nomeados do sistema que agrupam permissões';


--
-- TOC entry 4742 (class 0 OID 0)
-- Dependencies: 246
-- Name: COLUMN roles.role_id; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.roles.role_id IS 'Identificador único do papel';


--
-- TOC entry 4743 (class 0 OID 0)
-- Dependencies: 246
-- Name: COLUMN roles.name; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.roles.name IS 'Nome do papel (ex: comprador, gestor)';


--
-- TOC entry 4744 (class 0 OID 0)
-- Dependencies: 246
-- Name: COLUMN roles.description; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.roles.description IS 'Descrição funcional do papel';


--
-- TOC entry 4745 (class 0 OID 0)
-- Dependencies: 246
-- Name: COLUMN roles.created_at; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.roles.created_at IS 'Data de criação';


--
-- TOC entry 4746 (class 0 OID 0)
-- Dependencies: 246
-- Name: COLUMN roles.updated_at; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.roles.updated_at IS 'Data da última atualização';


--
-- TOC entry 240 (class 1259 OID 17240)
-- Name: suppliers; Type: TABLE; Schema: accounts; Owner: postgres
--

CREATE TABLE accounts.suppliers (
    supplier_id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    activated_at timestamp without time zone DEFAULT now(),
    deactivated_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone
);


ALTER TABLE accounts.suppliers OWNER TO postgres;

--
-- TOC entry 4747 (class 0 OID 0)
-- Dependencies: 240
-- Name: TABLE suppliers; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON TABLE accounts.suppliers IS 'Fornecedores do sistema, que possuem funcionários e filiais';


--
-- TOC entry 4748 (class 0 OID 0)
-- Dependencies: 240
-- Name: COLUMN suppliers.supplier_id; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.suppliers.supplier_id IS 'Identificador único do fornecedor';


--
-- TOC entry 4749 (class 0 OID 0)
-- Dependencies: 240
-- Name: COLUMN suppliers.name; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.suppliers.name IS 'Nome do fornecedor';


--
-- TOC entry 4750 (class 0 OID 0)
-- Dependencies: 240
-- Name: COLUMN suppliers.is_active; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.suppliers.is_active IS 'Indica se o fornecedor está ativo';


--
-- TOC entry 4751 (class 0 OID 0)
-- Dependencies: 240
-- Name: COLUMN suppliers.activated_at; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.suppliers.activated_at IS 'Data de ativação';


--
-- TOC entry 4752 (class 0 OID 0)
-- Dependencies: 240
-- Name: COLUMN suppliers.deactivated_at; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.suppliers.deactivated_at IS 'Data de desativação';


--
-- TOC entry 4753 (class 0 OID 0)
-- Dependencies: 240
-- Name: COLUMN suppliers.created_at; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.suppliers.created_at IS 'Data de criação do registro';


--
-- TOC entry 4754 (class 0 OID 0)
-- Dependencies: 240
-- Name: COLUMN suppliers.updated_at; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.suppliers.updated_at IS 'Data da última atualização do registro';


--
-- TOC entry 239 (class 1259 OID 17226)
-- Name: users; Type: TABLE; Schema: accounts; Owner: postgres
--

CREATE TABLE accounts.users (
    user_id uuid DEFAULT gen_random_uuid() NOT NULL,
    email text NOT NULL,
    full_name text NOT NULL,
    cognito_sub text NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone
);


ALTER TABLE accounts.users OWNER TO postgres;

--
-- TOC entry 4755 (class 0 OID 0)
-- Dependencies: 239
-- Name: TABLE users; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON TABLE accounts.users IS 'Usuários autenticáveis no sistema (funcionários)';


--
-- TOC entry 4756 (class 0 OID 0)
-- Dependencies: 239
-- Name: COLUMN users.user_id; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.users.user_id IS 'Identificador único do usuário';


--
-- TOC entry 4757 (class 0 OID 0)
-- Dependencies: 239
-- Name: COLUMN users.email; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.users.email IS 'Endereço de e-mail usado para login';


--
-- TOC entry 4758 (class 0 OID 0)
-- Dependencies: 239
-- Name: COLUMN users.full_name; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.users.full_name IS 'Nome completo do usuário';


--
-- TOC entry 4759 (class 0 OID 0)
-- Dependencies: 239
-- Name: COLUMN users.cognito_sub; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.users.cognito_sub IS 'Identificador único do Cognito (OAuth/Auth)';


--
-- TOC entry 4760 (class 0 OID 0)
-- Dependencies: 239
-- Name: COLUMN users.is_active; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.users.is_active IS 'Indica se o usuário está ativo no sistema';


--
-- TOC entry 4761 (class 0 OID 0)
-- Dependencies: 239
-- Name: COLUMN users.created_at; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.users.created_at IS 'Data de criação do registro';


--
-- TOC entry 4762 (class 0 OID 0)
-- Dependencies: 239
-- Name: COLUMN users.updated_at; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.users.updated_at IS 'Data da última atualização do registro';


--
-- TOC entry 253 (class 1259 OID 17743)
-- Name: v_api_key_feature_scope; Type: VIEW; Schema: accounts; Owner: postgres
--

CREATE VIEW accounts.v_api_key_feature_scope AS
 SELECT ak.api_key_id,
    ak.employee_id,
    u.email,
    f.feature_id,
    f.code AS feature_code,
    f.name AS feature_name,
    m.name AS module_name,
    p.name AS platform_name
   FROM ((((((accounts.api_keys ak
     JOIN accounts.api_scopes aps ON ((aps.api_key_id = ak.api_key_id)))
     JOIN accounts.features f ON ((f.feature_id = aps.feature_id)))
     JOIN accounts.modules m ON ((m.module_id = f.module_id)))
     JOIN accounts.platforms p ON ((p.platform_id = f.platform_id)))
     JOIN accounts.employees e ON ((e.employee_id = ak.employee_id)))
     JOIN accounts.users u ON ((u.user_id = e.user_id)));


ALTER VIEW accounts.v_api_key_feature_scope OWNER TO postgres;

--
-- TOC entry 4763 (class 0 OID 0)
-- Dependencies: 253
-- Name: VIEW v_api_key_feature_scope; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON VIEW accounts.v_api_key_feature_scope IS 'View que mostra quais features uma chave de API tem acesso, incluindo escopo completo de plataforma e módulo.';


--
-- TOC entry 252 (class 1259 OID 17738)
-- Name: v_employee_feature_access; Type: VIEW; Schema: accounts; Owner: postgres
--

CREATE VIEW accounts.v_employee_feature_access AS
 SELECT u.user_id,
    e.employee_id,
    r.role_id,
    f.feature_id,
    f.code AS feature_code,
    f.name AS feature_name,
    m.name AS module_name,
    p.name AS platform_name
   FROM (((((((accounts.employees e
     JOIN accounts.users u ON ((u.user_id = e.user_id)))
     JOIN accounts.employee_roles er ON ((er.employee_id = e.employee_id)))
     JOIN accounts.roles r ON ((r.role_id = er.role_id)))
     JOIN accounts.role_features rf ON ((rf.role_id = r.role_id)))
     JOIN accounts.features f ON ((f.feature_id = rf.feature_id)))
     JOIN accounts.modules m ON ((m.module_id = f.module_id)))
     JOIN accounts.platforms p ON ((p.platform_id = f.platform_id)));


ALTER VIEW accounts.v_employee_feature_access OWNER TO postgres;

--
-- TOC entry 4764 (class 0 OID 0)
-- Dependencies: 252
-- Name: VIEW v_employee_feature_access; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON VIEW accounts.v_employee_feature_access IS 'View consolidada com as features acessíveis por cada employee e seu contexto organizacional';


--
-- TOC entry 263 (class 1259 OID 18022)
-- Name: brands; Type: TABLE; Schema: catalogs; Owner: postgres
--

CREATE TABLE catalogs.brands (
    brand_id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone
);


ALTER TABLE catalogs.brands OWNER TO postgres;

--
-- TOC entry 4765 (class 0 OID 0)
-- Dependencies: 263
-- Name: TABLE brands; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON TABLE catalogs.brands IS 'Marca ou fabricante do produto';


--
-- TOC entry 4766 (class 0 OID 0)
-- Dependencies: 263
-- Name: COLUMN brands.brand_id; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.brands.brand_id IS 'Identificador único da marca';


--
-- TOC entry 4767 (class 0 OID 0)
-- Dependencies: 263
-- Name: COLUMN brands.name; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.brands.name IS 'Nome da marca';


--
-- TOC entry 4768 (class 0 OID 0)
-- Dependencies: 263
-- Name: COLUMN brands.created_at; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.brands.created_at IS 'Data de criação do registro';


--
-- TOC entry 4769 (class 0 OID 0)
-- Dependencies: 263
-- Name: COLUMN brands.updated_at; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.brands.updated_at IS 'Data da última atualização do registro';


--
-- TOC entry 254 (class 1259 OID 17916)
-- Name: categories; Type: TABLE; Schema: catalogs; Owner: postgres
--

CREATE TABLE catalogs.categories (
    category_id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    description text,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone
);


ALTER TABLE catalogs.categories OWNER TO postgres;

--
-- TOC entry 4770 (class 0 OID 0)
-- Dependencies: 254
-- Name: TABLE categories; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON TABLE catalogs.categories IS 'Categorias amplas para agrupamento dos produtos';


--
-- TOC entry 4771 (class 0 OID 0)
-- Dependencies: 254
-- Name: COLUMN categories.category_id; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.categories.category_id IS 'Identificador único da categoria';


--
-- TOC entry 4772 (class 0 OID 0)
-- Dependencies: 254
-- Name: COLUMN categories.name; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.categories.name IS 'Nome da categoria';


--
-- TOC entry 4773 (class 0 OID 0)
-- Dependencies: 254
-- Name: COLUMN categories.description; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.categories.description IS 'Descrição da categoria';


--
-- TOC entry 4774 (class 0 OID 0)
-- Dependencies: 254
-- Name: COLUMN categories.created_at; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.categories.created_at IS 'Data de criação do registro';


--
-- TOC entry 4775 (class 0 OID 0)
-- Dependencies: 254
-- Name: COLUMN categories.updated_at; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.categories.updated_at IS 'Data da última atualização do registro';


--
-- TOC entry 257 (class 1259 OID 17956)
-- Name: compositions; Type: TABLE; Schema: catalogs; Owner: postgres
--

CREATE TABLE catalogs.compositions (
    composition_id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    description text,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone
);


ALTER TABLE catalogs.compositions OWNER TO postgres;

--
-- TOC entry 4776 (class 0 OID 0)
-- Dependencies: 257
-- Name: TABLE compositions; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON TABLE catalogs.compositions IS 'Composição ou matéria-prima do produto (ex: Grano Duro)';


--
-- TOC entry 4777 (class 0 OID 0)
-- Dependencies: 257
-- Name: COLUMN compositions.composition_id; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.compositions.composition_id IS 'Identificador único da composição';


--
-- TOC entry 4778 (class 0 OID 0)
-- Dependencies: 257
-- Name: COLUMN compositions.name; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.compositions.name IS 'Nome da composição';


--
-- TOC entry 4779 (class 0 OID 0)
-- Dependencies: 257
-- Name: COLUMN compositions.description; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.compositions.description IS 'Descrição da composição';


--
-- TOC entry 4780 (class 0 OID 0)
-- Dependencies: 257
-- Name: COLUMN compositions.created_at; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.compositions.created_at IS 'Data de criação do registro';


--
-- TOC entry 4781 (class 0 OID 0)
-- Dependencies: 257
-- Name: COLUMN compositions.updated_at; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.compositions.updated_at IS 'Data da última atualização do registro';


--
-- TOC entry 261 (class 1259 OID 18000)
-- Name: fillings; Type: TABLE; Schema: catalogs; Owner: postgres
--

CREATE TABLE catalogs.fillings (
    filling_id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    description text,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone
);


ALTER TABLE catalogs.fillings OWNER TO postgres;

--
-- TOC entry 4782 (class 0 OID 0)
-- Dependencies: 261
-- Name: TABLE fillings; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON TABLE catalogs.fillings IS 'Recheio principal do produto (ex: Morango, Baunilha)';


--
-- TOC entry 4783 (class 0 OID 0)
-- Dependencies: 261
-- Name: COLUMN fillings.filling_id; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.fillings.filling_id IS 'Identificador único do recheio';


--
-- TOC entry 4784 (class 0 OID 0)
-- Dependencies: 261
-- Name: COLUMN fillings.name; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.fillings.name IS 'Nome do recheio';


--
-- TOC entry 4785 (class 0 OID 0)
-- Dependencies: 261
-- Name: COLUMN fillings.description; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.fillings.description IS 'Descrição do recheio';


--
-- TOC entry 4786 (class 0 OID 0)
-- Dependencies: 261
-- Name: COLUMN fillings.created_at; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.fillings.created_at IS 'Data de criação do registro';


--
-- TOC entry 4787 (class 0 OID 0)
-- Dependencies: 261
-- Name: COLUMN fillings.updated_at; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.fillings.updated_at IS 'Data da última atualização do registro';


--
-- TOC entry 260 (class 1259 OID 17989)
-- Name: flavors; Type: TABLE; Schema: catalogs; Owner: postgres
--

CREATE TABLE catalogs.flavors (
    flavor_id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    description text,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone
);


ALTER TABLE catalogs.flavors OWNER TO postgres;

--
-- TOC entry 4788 (class 0 OID 0)
-- Dependencies: 260
-- Name: TABLE flavors; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON TABLE catalogs.flavors IS 'Perfil de sabor ou tempero (ex: Picante, Galinha Caipira)';


--
-- TOC entry 4789 (class 0 OID 0)
-- Dependencies: 260
-- Name: COLUMN flavors.flavor_id; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.flavors.flavor_id IS 'Identificador único do sabor';


--
-- TOC entry 4790 (class 0 OID 0)
-- Dependencies: 260
-- Name: COLUMN flavors.name; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.flavors.name IS 'Nome do sabor';


--
-- TOC entry 4791 (class 0 OID 0)
-- Dependencies: 260
-- Name: COLUMN flavors.description; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.flavors.description IS 'Descrição do sabor';


--
-- TOC entry 4792 (class 0 OID 0)
-- Dependencies: 260
-- Name: COLUMN flavors.created_at; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.flavors.created_at IS 'Data de criação do registro';


--
-- TOC entry 4793 (class 0 OID 0)
-- Dependencies: 260
-- Name: COLUMN flavors.updated_at; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.flavors.updated_at IS 'Data da última atualização do registro';


--
-- TOC entry 259 (class 1259 OID 17978)
-- Name: formats; Type: TABLE; Schema: catalogs; Owner: postgres
--

CREATE TABLE catalogs.formats (
    format_id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    description text,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone
);


ALTER TABLE catalogs.formats OWNER TO postgres;

--
-- TOC entry 4794 (class 0 OID 0)
-- Dependencies: 259
-- Name: TABLE formats; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON TABLE catalogs.formats IS 'Formato físico de apresentação (ex: Fatiada, Bolinha)';


--
-- TOC entry 4795 (class 0 OID 0)
-- Dependencies: 259
-- Name: COLUMN formats.format_id; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.formats.format_id IS 'Identificador único do formato';


--
-- TOC entry 4796 (class 0 OID 0)
-- Dependencies: 259
-- Name: COLUMN formats.name; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.formats.name IS 'Nome do formato';


--
-- TOC entry 4797 (class 0 OID 0)
-- Dependencies: 259
-- Name: COLUMN formats.description; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.formats.description IS 'Descrição do formato';


--
-- TOC entry 4798 (class 0 OID 0)
-- Dependencies: 259
-- Name: COLUMN formats.created_at; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.formats.created_at IS 'Data de criação do registro';


--
-- TOC entry 4799 (class 0 OID 0)
-- Dependencies: 259
-- Name: COLUMN formats.updated_at; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.formats.updated_at IS 'Data da última atualização do registro';


--
-- TOC entry 256 (class 1259 OID 17941)
-- Name: items; Type: TABLE; Schema: catalogs; Owner: postgres
--

CREATE TABLE catalogs.items (
    item_id uuid DEFAULT gen_random_uuid() NOT NULL,
    subcategory_id uuid NOT NULL,
    name text NOT NULL,
    description text,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone
);


ALTER TABLE catalogs.items OWNER TO postgres;

--
-- TOC entry 4800 (class 0 OID 0)
-- Dependencies: 256
-- Name: TABLE items; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON TABLE catalogs.items IS 'Itens genéricos que representam o núcleo de um produto';


--
-- TOC entry 4801 (class 0 OID 0)
-- Dependencies: 256
-- Name: COLUMN items.item_id; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.items.item_id IS 'Identificador único do item';


--
-- TOC entry 4802 (class 0 OID 0)
-- Dependencies: 256
-- Name: COLUMN items.subcategory_id; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.items.subcategory_id IS 'Subcategoria à qual este item pertence';


--
-- TOC entry 4803 (class 0 OID 0)
-- Dependencies: 256
-- Name: COLUMN items.name; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.items.name IS 'Nome genérico do item';


--
-- TOC entry 4804 (class 0 OID 0)
-- Dependencies: 256
-- Name: COLUMN items.description; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.items.description IS 'Descrição do item';


--
-- TOC entry 4805 (class 0 OID 0)
-- Dependencies: 256
-- Name: COLUMN items.created_at; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.items.created_at IS 'Data de criação do registro';


--
-- TOC entry 4806 (class 0 OID 0)
-- Dependencies: 256
-- Name: COLUMN items.updated_at; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.items.updated_at IS 'Data da última atualização do registro';


--
-- TOC entry 262 (class 1259 OID 18011)
-- Name: nutritional_variants; Type: TABLE; Schema: catalogs; Owner: postgres
--

CREATE TABLE catalogs.nutritional_variants (
    nutritional_variant_id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    description text,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone
);


ALTER TABLE catalogs.nutritional_variants OWNER TO postgres;

--
-- TOC entry 4807 (class 0 OID 0)
-- Dependencies: 262
-- Name: TABLE nutritional_variants; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON TABLE catalogs.nutritional_variants IS 'Variações nutricionais (ex: Light, Zero, Sem Lactose)';


--
-- TOC entry 4808 (class 0 OID 0)
-- Dependencies: 262
-- Name: COLUMN nutritional_variants.nutritional_variant_id; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.nutritional_variants.nutritional_variant_id IS 'Identificador único da variação';


--
-- TOC entry 4809 (class 0 OID 0)
-- Dependencies: 262
-- Name: COLUMN nutritional_variants.name; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.nutritional_variants.name IS 'Nome da variação nutricional';


--
-- TOC entry 4810 (class 0 OID 0)
-- Dependencies: 262
-- Name: COLUMN nutritional_variants.description; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.nutritional_variants.description IS 'Descrição da variação nutricional';


--
-- TOC entry 4811 (class 0 OID 0)
-- Dependencies: 262
-- Name: COLUMN nutritional_variants.created_at; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.nutritional_variants.created_at IS 'Data de criação do registro';


--
-- TOC entry 4812 (class 0 OID 0)
-- Dependencies: 262
-- Name: COLUMN nutritional_variants.updated_at; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.nutritional_variants.updated_at IS 'Data da última atualização do registro';


--
-- TOC entry 267 (class 1259 OID 18113)
-- Name: offers; Type: TABLE; Schema: catalogs; Owner: postgres
--

CREATE TABLE catalogs.offers (
    offer_id uuid DEFAULT gen_random_uuid() NOT NULL,
    product_id uuid NOT NULL,
    supplier_id uuid NOT NULL,
    price numeric(12,2) NOT NULL,
    available_from date NOT NULL,
    available_until date,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone
);


ALTER TABLE catalogs.offers OWNER TO postgres;

--
-- TOC entry 4813 (class 0 OID 0)
-- Dependencies: 267
-- Name: TABLE offers; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON TABLE catalogs.offers IS 'Oferta de um produto específico por um fornecedor com condições comerciais';


--
-- TOC entry 4814 (class 0 OID 0)
-- Dependencies: 267
-- Name: COLUMN offers.offer_id; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.offers.offer_id IS 'Identificador único da oferta';


--
-- TOC entry 4815 (class 0 OID 0)
-- Dependencies: 267
-- Name: COLUMN offers.product_id; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.offers.product_id IS 'Produto ofertado';


--
-- TOC entry 4816 (class 0 OID 0)
-- Dependencies: 267
-- Name: COLUMN offers.supplier_id; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.offers.supplier_id IS 'Fornecedor que oferta o produto';


--
-- TOC entry 4817 (class 0 OID 0)
-- Dependencies: 267
-- Name: COLUMN offers.price; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.offers.price IS 'Preço da oferta';


--
-- TOC entry 4818 (class 0 OID 0)
-- Dependencies: 267
-- Name: COLUMN offers.available_from; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.offers.available_from IS 'Data de início da disponibilidade da oferta';


--
-- TOC entry 4819 (class 0 OID 0)
-- Dependencies: 267
-- Name: COLUMN offers.available_until; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.offers.available_until IS 'Data de término da disponibilidade da oferta (opcional)';


--
-- TOC entry 4820 (class 0 OID 0)
-- Dependencies: 267
-- Name: COLUMN offers.is_active; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.offers.is_active IS 'Indica se a oferta está ativa';


--
-- TOC entry 4821 (class 0 OID 0)
-- Dependencies: 267
-- Name: COLUMN offers.created_at; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.offers.created_at IS 'Data de criação do registro';


--
-- TOC entry 4822 (class 0 OID 0)
-- Dependencies: 267
-- Name: COLUMN offers.updated_at; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.offers.updated_at IS 'Data da última atualização do registro';


--
-- TOC entry 264 (class 1259 OID 18033)
-- Name: packagings; Type: TABLE; Schema: catalogs; Owner: postgres
--

CREATE TABLE catalogs.packagings (
    packaging_id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    description text,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone
);


ALTER TABLE catalogs.packagings OWNER TO postgres;

--
-- TOC entry 4823 (class 0 OID 0)
-- Dependencies: 264
-- Name: TABLE packagings; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON TABLE catalogs.packagings IS 'Tipo de embalagem do produto (ex: Caixa, Lata, Pacote)';


--
-- TOC entry 4824 (class 0 OID 0)
-- Dependencies: 264
-- Name: COLUMN packagings.packaging_id; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.packagings.packaging_id IS 'Identificador único da embalagem';


--
-- TOC entry 4825 (class 0 OID 0)
-- Dependencies: 264
-- Name: COLUMN packagings.name; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.packagings.name IS 'Nome do tipo de embalagem';


--
-- TOC entry 4826 (class 0 OID 0)
-- Dependencies: 264
-- Name: COLUMN packagings.description; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.packagings.description IS 'Descrição da embalagem';


--
-- TOC entry 4827 (class 0 OID 0)
-- Dependencies: 264
-- Name: COLUMN packagings.created_at; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.packagings.created_at IS 'Data de criação do registro';


--
-- TOC entry 4828 (class 0 OID 0)
-- Dependencies: 264
-- Name: COLUMN packagings.updated_at; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.packagings.updated_at IS 'Data da última atualização do registro';


--
-- TOC entry 266 (class 1259 OID 18053)
-- Name: products; Type: TABLE; Schema: catalogs; Owner: postgres
--

CREATE TABLE catalogs.products (
    product_id uuid DEFAULT gen_random_uuid() NOT NULL,
    item_id uuid NOT NULL,
    composition_id uuid,
    variant_type_id uuid,
    format_id uuid,
    flavor_id uuid,
    filling_id uuid,
    nutritional_variant_id uuid,
    brand_id uuid,
    packaging_id uuid,
    quantity_id uuid,
    visibility text DEFAULT 'public'::text NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone
);


ALTER TABLE catalogs.products OWNER TO postgres;

--
-- TOC entry 4829 (class 0 OID 0)
-- Dependencies: 266
-- Name: TABLE products; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON TABLE catalogs.products IS 'Produto padronizado resultante da combinação de um item com suas variações e atributos dimensionais';


--
-- TOC entry 4830 (class 0 OID 0)
-- Dependencies: 266
-- Name: COLUMN products.product_id; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.products.product_id IS 'Identificador único do produto';


--
-- TOC entry 4831 (class 0 OID 0)
-- Dependencies: 266
-- Name: COLUMN products.item_id; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.products.item_id IS 'FK para o item base deste produto';


--
-- TOC entry 4832 (class 0 OID 0)
-- Dependencies: 266
-- Name: COLUMN products.composition_id; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.products.composition_id IS 'FK para a composição (matéria-prima)';


--
-- TOC entry 4833 (class 0 OID 0)
-- Dependencies: 266
-- Name: COLUMN products.variant_type_id; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.products.variant_type_id IS 'FK para o tipo de variação';


--
-- TOC entry 4834 (class 0 OID 0)
-- Dependencies: 266
-- Name: COLUMN products.format_id; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.products.format_id IS 'FK para o formato físico';


--
-- TOC entry 4835 (class 0 OID 0)
-- Dependencies: 266
-- Name: COLUMN products.flavor_id; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.products.flavor_id IS 'FK para o sabor';


--
-- TOC entry 4836 (class 0 OID 0)
-- Dependencies: 266
-- Name: COLUMN products.filling_id; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.products.filling_id IS 'FK para o recheio';


--
-- TOC entry 4837 (class 0 OID 0)
-- Dependencies: 266
-- Name: COLUMN products.nutritional_variant_id; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.products.nutritional_variant_id IS 'FK para a variação nutricional';


--
-- TOC entry 4838 (class 0 OID 0)
-- Dependencies: 266
-- Name: COLUMN products.brand_id; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.products.brand_id IS 'FK para a marca';


--
-- TOC entry 4839 (class 0 OID 0)
-- Dependencies: 266
-- Name: COLUMN products.packaging_id; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.products.packaging_id IS 'FK para a embalagem';


--
-- TOC entry 4840 (class 0 OID 0)
-- Dependencies: 266
-- Name: COLUMN products.quantity_id; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.products.quantity_id IS 'FK para a quantidade';


--
-- TOC entry 4841 (class 0 OID 0)
-- Dependencies: 266
-- Name: COLUMN products.visibility; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.products.visibility IS 'Define se o produto é público ou privado';


--
-- TOC entry 4842 (class 0 OID 0)
-- Dependencies: 266
-- Name: COLUMN products.created_at; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.products.created_at IS 'Data de criação do registro';


--
-- TOC entry 4843 (class 0 OID 0)
-- Dependencies: 266
-- Name: COLUMN products.updated_at; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.products.updated_at IS 'Data da última atualização do registro';


--
-- TOC entry 265 (class 1259 OID 18044)
-- Name: quantities; Type: TABLE; Schema: catalogs; Owner: postgres
--

CREATE TABLE catalogs.quantities (
    quantity_id uuid DEFAULT gen_random_uuid() NOT NULL,
    unit text NOT NULL,
    value numeric(10,3) NOT NULL,
    display_name text NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone
);


ALTER TABLE catalogs.quantities OWNER TO postgres;

--
-- TOC entry 4844 (class 0 OID 0)
-- Dependencies: 265
-- Name: TABLE quantities; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON TABLE catalogs.quantities IS 'Quantidade ou medida do produto (ex: 500g, 12 unidades)';


--
-- TOC entry 4845 (class 0 OID 0)
-- Dependencies: 265
-- Name: COLUMN quantities.quantity_id; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.quantities.quantity_id IS 'Identificador único da quantidade';


--
-- TOC entry 4846 (class 0 OID 0)
-- Dependencies: 265
-- Name: COLUMN quantities.unit; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.quantities.unit IS 'Unidade de medida (ex: g, ml, un)';


--
-- TOC entry 4847 (class 0 OID 0)
-- Dependencies: 265
-- Name: COLUMN quantities.value; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.quantities.value IS 'Valor numérico da unidade';


--
-- TOC entry 4848 (class 0 OID 0)
-- Dependencies: 265
-- Name: COLUMN quantities.display_name; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.quantities.display_name IS 'Nome formatado para exibição';


--
-- TOC entry 4849 (class 0 OID 0)
-- Dependencies: 265
-- Name: COLUMN quantities.created_at; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.quantities.created_at IS 'Data de criação do registro';


--
-- TOC entry 4850 (class 0 OID 0)
-- Dependencies: 265
-- Name: COLUMN quantities.updated_at; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.quantities.updated_at IS 'Data da última atualização do registro';


--
-- TOC entry 255 (class 1259 OID 17927)
-- Name: subcategories; Type: TABLE; Schema: catalogs; Owner: postgres
--

CREATE TABLE catalogs.subcategories (
    subcategory_id uuid DEFAULT gen_random_uuid() NOT NULL,
    category_id uuid NOT NULL,
    name text NOT NULL,
    description text,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone
);


ALTER TABLE catalogs.subcategories OWNER TO postgres;

--
-- TOC entry 4851 (class 0 OID 0)
-- Dependencies: 255
-- Name: TABLE subcategories; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON TABLE catalogs.subcategories IS 'Subcategorias específicas dentro de uma categoria principal';


--
-- TOC entry 4852 (class 0 OID 0)
-- Dependencies: 255
-- Name: COLUMN subcategories.subcategory_id; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.subcategories.subcategory_id IS 'Identificador único da subcategoria';


--
-- TOC entry 4853 (class 0 OID 0)
-- Dependencies: 255
-- Name: COLUMN subcategories.category_id; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.subcategories.category_id IS 'Categoria à qual esta subcategoria pertence';


--
-- TOC entry 4854 (class 0 OID 0)
-- Dependencies: 255
-- Name: COLUMN subcategories.name; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.subcategories.name IS 'Nome da subcategoria';


--
-- TOC entry 4855 (class 0 OID 0)
-- Dependencies: 255
-- Name: COLUMN subcategories.description; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.subcategories.description IS 'Descrição da subcategoria';


--
-- TOC entry 4856 (class 0 OID 0)
-- Dependencies: 255
-- Name: COLUMN subcategories.created_at; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.subcategories.created_at IS 'Data de criação do registro';


--
-- TOC entry 4857 (class 0 OID 0)
-- Dependencies: 255
-- Name: COLUMN subcategories.updated_at; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.subcategories.updated_at IS 'Data da última atualização do registro';


--
-- TOC entry 258 (class 1259 OID 17967)
-- Name: variant_types; Type: TABLE; Schema: catalogs; Owner: postgres
--

CREATE TABLE catalogs.variant_types (
    variant_type_id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    description text,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone
);


ALTER TABLE catalogs.variant_types OWNER TO postgres;

--
-- TOC entry 4858 (class 0 OID 0)
-- Dependencies: 258
-- Name: TABLE variant_types; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON TABLE catalogs.variant_types IS 'Tipo ou variação específica do item (ex: Espaguete nº 08)';


--
-- TOC entry 4859 (class 0 OID 0)
-- Dependencies: 258
-- Name: COLUMN variant_types.variant_type_id; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.variant_types.variant_type_id IS 'Identificador único do tipo';


--
-- TOC entry 4860 (class 0 OID 0)
-- Dependencies: 258
-- Name: COLUMN variant_types.name; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.variant_types.name IS 'Nome do tipo de variação';


--
-- TOC entry 4861 (class 0 OID 0)
-- Dependencies: 258
-- Name: COLUMN variant_types.description; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.variant_types.description IS 'Descrição do tipo de variação';


--
-- TOC entry 4862 (class 0 OID 0)
-- Dependencies: 258
-- Name: COLUMN variant_types.created_at; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.variant_types.created_at IS 'Data de criação do registro';


--
-- TOC entry 4863 (class 0 OID 0)
-- Dependencies: 258
-- Name: COLUMN variant_types.updated_at; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.variant_types.updated_at IS 'Data da última atualização do registro';


--
-- TOC entry 4650 (class 0 OID 17697)
-- Dependencies: 250
-- Data for Name: api_keys; Type: TABLE DATA; Schema: accounts; Owner: postgres
--

INSERT INTO accounts.api_keys VALUES ('f55b2638-ac83-4584-a8d8-8f83084a6789', '3a63d392-60fe-4d9c-82a9-e5848a4d3665', 'Chave Pública Jonathan', 'secret-teste-jonathan', '2025-05-27 02:31:06.489197', NULL);


--
-- TOC entry 4651 (class 0 OID 17711)
-- Dependencies: 251
-- Data for Name: api_scopes; Type: TABLE DATA; Schema: accounts; Owner: postgres
--

INSERT INTO accounts.api_scopes VALUES ('9b87fc07-f647-484b-882b-0bb8a73f1240', 'f55b2638-ac83-4584-a8d8-8f83084a6789', '3225eae1-60f6-4dab-8b5b-3290312fad3f', '2025-05-27 10:44:37.208236');
INSERT INTO accounts.api_scopes VALUES ('0bca55ff-4156-4996-8760-9de48de8936e', 'f55b2638-ac83-4584-a8d8-8f83084a6789', 'b562e3df-78a3-43af-aa3d-46cfd7c90f9c', '2025-05-27 10:44:37.208236');


--
-- TOC entry 4649 (class 0 OID 17420)
-- Dependencies: 249
-- Data for Name: apis; Type: TABLE DATA; Schema: accounts; Owner: postgres
--

INSERT INTO accounts.apis VALUES ('029af1c1-cf12-436a-afb7-844f405f09f1', '/shopping-lists', 'POST', 'Criar nova lista de compras', '2025-05-17 01:20:42.114603', NULL, NULL);
INSERT INTO accounts.apis VALUES ('95fd97bf-360e-4fce-a790-36ccd427e3ea', '/quotations', 'POST', 'Solicitar cotação de produtos', '2025-05-17 01:20:42.114603', NULL, NULL);
INSERT INTO accounts.apis VALUES ('58eedfe0-8f6d-401c-8a93-f9c4da54ada0', '/shopping-lists/{id}/send', 'POST', 'Enviar lista de compras para cotação', '2025-05-17 01:20:42.114603', NULL, NULL);
INSERT INTO accounts.apis VALUES ('f4e8e8f1-db95-497d-ba49-b14c3b1713f0', '/shopping-lists/{id}/quotes', 'GET', 'Consultar cotações recebidas', '2025-05-17 01:20:42.114603', NULL, NULL);
INSERT INTO accounts.apis VALUES ('723608c1-4dc0-47a6-8c1c-0087ef68191f', '/catalog/products', 'POST', 'Cadastrar produtos no catálogo', '2025-05-17 01:20:42.114603', NULL, NULL);
INSERT INTO accounts.apis VALUES ('484394aa-be37-49a3-81c1-2539a2a32946', '/quotations/response', 'POST', 'Responder cotações recebidas', '2025-05-17 01:20:42.114603', NULL, NULL);


--
-- TOC entry 4648 (class 0 OID 17398)
-- Dependencies: 248
-- Data for Name: employee_roles; Type: TABLE DATA; Schema: accounts; Owner: postgres
--

INSERT INTO accounts.employee_roles VALUES ('0bc59b18-088d-4986-8283-bcaf4e7ba33a', '3a63d392-60fe-4d9c-82a9-e5848a4d3665', '9b43bd06-9b89-42bb-b105-d5ef057657ea', '2025-05-17 01:31:11.106129', NULL);
INSERT INTO accounts.employee_roles VALUES ('40c1fd77-5bdb-4014-81b1-bbd54c032cd4', '199ecc7b-d75d-4913-bc7a-e44940fd3ff2', '1dae8888-f954-4f17-9f58-a9b99ff12ede', '2025-05-17 01:31:11.106129', NULL);
INSERT INTO accounts.employee_roles VALUES ('391c35b3-a5cc-417f-b1f5-d280d1809401', '60688fde-6798-46eb-9a35-4902b35cbe75', '1362ebf0-191f-41a1-9f98-da7657f38263', '2025-05-17 01:31:11.106129', NULL);


--
-- TOC entry 4642 (class 0 OID 17272)
-- Dependencies: 242
-- Data for Name: employees; Type: TABLE DATA; Schema: accounts; Owner: postgres
--

INSERT INTO accounts.employees VALUES ('3a63d392-60fe-4d9c-82a9-e5848a4d3665', '270e14d4-04c8-4319-8e49-0f1b38e54c07', '9416b02a-bc71-4441-a6cc-535b3d497c75', NULL, true, '2025-05-17 01:24:04.420438', NULL, '2025-05-17 01:24:04.420438', NULL);
INSERT INTO accounts.employees VALUES ('199ecc7b-d75d-4913-bc7a-e44940fd3ff2', '29263b69-5212-4dc8-9207-19ad696e538d', NULL, '0b53ccb4-f36c-4b0e-bc0e-570a6cb800af', true, '2025-05-17 01:24:04.420438', NULL, '2025-05-17 01:24:04.420438', NULL);
INSERT INTO accounts.employees VALUES ('60688fde-6798-46eb-9a35-4902b35cbe75', '58920904-0ad1-4f3d-a907-333bb38bfe41', NULL, '0b53ccb4-f36c-4b0e-bc0e-570a6cb800af', true, '2025-05-17 01:24:04.420438', NULL, '2025-05-17 01:24:04.420438', NULL);


--
-- TOC entry 4641 (class 0 OID 17256)
-- Dependencies: 241
-- Data for Name: establishments; Type: TABLE DATA; Schema: accounts; Owner: postgres
--

INSERT INTO accounts.establishments VALUES ('0b53ccb4-f36c-4b0e-bc0e-570a6cb800af', 'Burgeria do Vini', true, '2025-05-17 01:22:28.598373', NULL, '2025-05-17 01:22:28.598373', NULL);


--
-- TOC entry 4645 (class 0 OID 17339)
-- Dependencies: 245
-- Data for Name: features; Type: TABLE DATA; Schema: accounts; Owner: postgres
--

INSERT INTO accounts.features VALUES ('e764c452-77d9-4e45-815e-d6918e1f5196', '40a09388-1d79-4f8a-a83d-1e5710c209aa', 'Criar lista de compras', 'criar_lista_compras', 'Permite criar uma nova lista de compras', '2025-05-27 02:49:44.792881', NULL, '1595b7e8-7828-4733-bf45-912023627234');
INSERT INTO accounts.features VALUES ('4e8fb761-f302-4cc9-b9bd-e3e28cb53f79', '40a09388-1d79-4f8a-a83d-1e5710c209aa', 'Cotar produtos', 'cotar_produtos', 'Permite selecionar produtos para cotação', '2025-05-27 02:49:44.792881', NULL, '1595b7e8-7828-4733-bf45-912023627234');
INSERT INTO accounts.features VALUES ('5991f57e-e241-44a3-b62c-5513b1b36f66', 'bbdf7f53-bd82-4725-b7fd-4c443c26b584', 'Enviar lista para cotação', 'enviar_lista_cotacao', 'Permite enviar a lista para fornecedores', '2025-05-27 02:49:44.792881', NULL, '1595b7e8-7828-4733-bf45-912023627234');
INSERT INTO accounts.features VALUES ('4452dd21-fe5a-4d41-9532-54e8a00e4a82', 'bbdf7f53-bd82-4725-b7fd-4c443c26b584', 'Ver cotações recebidas', 'ver_cotacoes_recebidas', 'Visualiza as cotações retornadas', '2025-05-27 02:49:44.792881', NULL, '1595b7e8-7828-4733-bf45-912023627234');
INSERT INTO accounts.features VALUES ('3225eae1-60f6-4dab-8b5b-3290312fad3f', '74f2c3c3-11e5-40b5-af53-448abedb4510', 'Cadastrar catálogo de produtos', 'cadastrar_catalogo', 'Permite cadastrar produtos no catálogo', '2025-05-27 02:49:44.792881', NULL, '5950a0ea-68fa-49bc-8386-52f78e0ccadb');
INSERT INTO accounts.features VALUES ('b562e3df-78a3-43af-aa3d-46cfd7c90f9c', '84713bfb-452c-4c74-adac-6377d4c80082', 'Responder cotações recebidas', 'responder_cotacoes', 'Permite responder cotações enviadas', '2025-05-27 02:49:44.792881', NULL, '5950a0ea-68fa-49bc-8386-52f78e0ccadb');


--
-- TOC entry 4644 (class 0 OID 17318)
-- Dependencies: 244
-- Data for Name: modules; Type: TABLE DATA; Schema: accounts; Owner: postgres
--

INSERT INTO accounts.modules VALUES ('40a09388-1d79-4f8a-a83d-1e5710c209aa', 'Lista de Compras', 'Criação e gerenciamento de listas de compras', '2025-05-17 01:19:51.512309', NULL);
INSERT INTO accounts.modules VALUES ('bbdf7f53-bd82-4725-b7fd-4c443c26b584', 'Envio de Cotações', 'Envio de listas para cotação pelos fornecedores', '2025-05-17 01:19:51.512309', NULL);
INSERT INTO accounts.modules VALUES ('74f2c3c3-11e5-40b5-af53-448abedb4510', 'Catálogo de Produtos', 'Gerenciamento do catálogo do fornecedor', '2025-05-17 01:19:51.512309', NULL);
INSERT INTO accounts.modules VALUES ('84713bfb-452c-4c74-adac-6377d4c80082', 'Gestão de Cotações', 'Recebimento e resposta de cotações', '2025-05-17 01:19:51.512309', NULL);


--
-- TOC entry 4643 (class 0 OID 17302)
-- Dependencies: 243
-- Data for Name: platforms; Type: TABLE DATA; Schema: accounts; Owner: postgres
--

INSERT INTO accounts.platforms VALUES ('5950a0ea-68fa-49bc-8386-52f78e0ccadb', 'Área do Fornecedor', 'Ambiente exclusivo para fornecedores', '2025-05-17 01:18:06.913173', NULL);
INSERT INTO accounts.platforms VALUES ('1595b7e8-7828-4733-bf45-912023627234', 'Área do Estabelecimento', 'Ambiente exclusivo para estabelecimentos', '2025-05-17 01:18:06.913173', NULL);


--
-- TOC entry 4647 (class 0 OID 17376)
-- Dependencies: 247
-- Data for Name: role_features; Type: TABLE DATA; Schema: accounts; Owner: postgres
--

INSERT INTO accounts.role_features VALUES ('99bc5501-e509-4a74-bd94-5290d399df96', '1dae8888-f954-4f17-9f58-a9b99ff12ede', 'e764c452-77d9-4e45-815e-d6918e1f5196', '2025-05-27 10:42:03.515545', NULL);
INSERT INTO accounts.role_features VALUES ('d26c9244-d522-46d5-a2ad-095d1b258228', '1dae8888-f954-4f17-9f58-a9b99ff12ede', '4e8fb761-f302-4cc9-b9bd-e3e28cb53f79', '2025-05-27 10:42:03.515545', NULL);
INSERT INTO accounts.role_features VALUES ('fa738695-ec67-4866-aef3-421e66efd699', '1dae8888-f954-4f17-9f58-a9b99ff12ede', '5991f57e-e241-44a3-b62c-5513b1b36f66', '2025-05-27 10:42:03.515545', NULL);
INSERT INTO accounts.role_features VALUES ('25c17c6c-355b-421f-83ea-2cf76351da71', '1dae8888-f954-4f17-9f58-a9b99ff12ede', '4452dd21-fe5a-4d41-9532-54e8a00e4a82', '2025-05-27 10:42:03.515545', NULL);
INSERT INTO accounts.role_features VALUES ('2d13e0b2-cd7e-458a-9fad-a6a896cb4f8d', '1dae8888-f954-4f17-9f58-a9b99ff12ede', 'e764c452-77d9-4e45-815e-d6918e1f5196', '2025-05-27 10:42:41.447383', NULL);
INSERT INTO accounts.role_features VALUES ('7c4ebc97-a731-4c6a-9782-432a3a4a703a', '1dae8888-f954-4f17-9f58-a9b99ff12ede', '4e8fb761-f302-4cc9-b9bd-e3e28cb53f79', '2025-05-27 10:42:41.447383', NULL);
INSERT INTO accounts.role_features VALUES ('e5dc2ff1-1391-4f9d-a9e8-041974f23804', '1dae8888-f954-4f17-9f58-a9b99ff12ede', '5991f57e-e241-44a3-b62c-5513b1b36f66', '2025-05-27 10:42:41.447383', NULL);
INSERT INTO accounts.role_features VALUES ('94a9918a-7e6d-4a44-a9fb-9dfa6cb30c94', '1dae8888-f954-4f17-9f58-a9b99ff12ede', '4452dd21-fe5a-4d41-9532-54e8a00e4a82', '2025-05-27 10:42:41.447383', NULL);
INSERT INTO accounts.role_features VALUES ('19acecdb-7b2d-4be6-84b2-ee2b85444eb9', '9b43bd06-9b89-42bb-b105-d5ef057657ea', '3225eae1-60f6-4dab-8b5b-3290312fad3f', '2025-05-27 10:42:45.752223', NULL);
INSERT INTO accounts.role_features VALUES ('afc1ebc8-2db4-4bcd-95bb-124354ebfeb7', '9b43bd06-9b89-42bb-b105-d5ef057657ea', 'b562e3df-78a3-43af-aa3d-46cfd7c90f9c', '2025-05-27 10:42:45.752223', NULL);
INSERT INTO accounts.role_features VALUES ('9e1fc497-97b8-4848-be40-2482cabce83e', '1362ebf0-191f-41a1-9f98-da7657f38263', '4452dd21-fe5a-4d41-9532-54e8a00e4a82', '2025-05-27 10:43:06.039046', NULL);


--
-- TOC entry 4646 (class 0 OID 17360)
-- Dependencies: 246
-- Data for Name: roles; Type: TABLE DATA; Schema: accounts; Owner: postgres
--

INSERT INTO accounts.roles VALUES ('1dae8888-f954-4f17-9f58-a9b99ff12ede', 'admin_estabelecimento', 'Acesso total à plataforma do estabelecimento', '2025-05-17 01:30:16.304337', NULL);
INSERT INTO accounts.roles VALUES ('9b43bd06-9b89-42bb-b105-d5ef057657ea', 'admin_fornecedor', 'Acesso total à plataforma do fornecedor', '2025-05-17 01:30:16.304337', NULL);
INSERT INTO accounts.roles VALUES ('1362ebf0-191f-41a1-9f98-da7657f38263', 'consulta_estabelecimento', 'Visualiza apenas as cotações enviadas', '2025-05-17 01:30:16.304337', NULL);


--
-- TOC entry 4640 (class 0 OID 17240)
-- Dependencies: 240
-- Data for Name: suppliers; Type: TABLE DATA; Schema: accounts; Owner: postgres
--

INSERT INTO accounts.suppliers VALUES ('9416b02a-bc71-4441-a6cc-535b3d497c75', 'Atacadão do Tião', true, '2025-05-17 01:22:28.598373', NULL, '2025-05-17 01:22:28.598373', NULL);
INSERT INTO accounts.suppliers VALUES ('de93c8b5-52d3-4352-b18b-f9fddd6f92a4', 'Distribuidora São Paulo', true, '2025-08-12 13:58:31.229754', NULL, '2025-08-12 13:58:31.229754', NULL);
INSERT INTO accounts.suppliers VALUES ('40ebea12-e124-4f0b-9177-303981c8793a', 'Mega Atacadão', true, '2025-08-12 13:58:31.393915', NULL, '2025-08-12 13:58:31.393915', NULL);
INSERT INTO accounts.suppliers VALUES ('69fa9957-82c8-4a18-9e06-5ec9e61f5fab', 'Vini Atacado', true, '2025-08-12 13:58:31.551486', NULL, '2025-08-12 13:58:31.551486', NULL);


--
-- TOC entry 4639 (class 0 OID 17226)
-- Dependencies: 239
-- Data for Name: users; Type: TABLE DATA; Schema: accounts; Owner: postgres
--

INSERT INTO accounts.users VALUES ('270e14d4-04c8-4319-8e49-0f1b38e54c07', 'jonathan@tiao.com', 'Jonathan Silva', 'sub-jonathan', true, '2025-05-17 01:22:17.357785', NULL);
INSERT INTO accounts.users VALUES ('29263b69-5212-4dc8-9207-19ad696e538d', 'laura@burgeria.com', 'Laura Almeida', 'sub-laura', true, '2025-05-17 01:22:17.357785', NULL);
INSERT INTO accounts.users VALUES ('58920904-0ad1-4f3d-a907-333bb38bfe41', 'julia@burgeria.com', 'Julia Costa', 'sub-julia', true, '2025-05-17 01:22:17.357785', NULL);


--
-- TOC entry 4661 (class 0 OID 18022)
-- Dependencies: 263
-- Data for Name: brands; Type: TABLE DATA; Schema: catalogs; Owner: postgres
--



--
-- TOC entry 4652 (class 0 OID 17916)
-- Dependencies: 254
-- Data for Name: categories; Type: TABLE DATA; Schema: catalogs; Owner: postgres
--

INSERT INTO catalogs.categories VALUES ('0f21080d-bbac-4e3e-bc5a-a0c90dbdde43', 'Açougue', 'Produtos cárneos e derivados', '2025-05-27 18:38:20.520764', NULL);
INSERT INTO catalogs.categories VALUES ('faa27e7c-cec6-4c1d-8f5b-b1c4ac4d6b88', 'Bebidas Alcoólicas', 'Cervejas, vinhos e destilados', '2025-05-27 18:38:20.520764', NULL);
INSERT INTO catalogs.categories VALUES ('be39720f-4c61-4a4c-a379-7a55c9b6a8b6', 'Bebidas não Alcoólicas', 'Águas, sucos, chás e energéticos', '2025-05-27 18:38:20.520764', NULL);
INSERT INTO catalogs.categories VALUES ('28f93ab7-7062-436e-bcf5-b7eb861fb873', 'Congelados e Resfriados', 'Produtos mantidos sob refrigeração', '2025-05-27 18:38:20.520764', NULL);
INSERT INTO catalogs.categories VALUES ('4d3db62d-2a27-41d1-bfa9-6ca6766c7f51', 'Frios e Laticínios', 'Queijos, iogurtes e similares', '2025-05-27 18:38:20.520764', NULL);
INSERT INTO catalogs.categories VALUES ('593a63dc-2de2-4e5e-b492-c9c66e7af479', 'Higiene e Beleza', 'Produtos de cuidados pessoais e higiene', '2025-05-27 18:38:20.520764', NULL);
INSERT INTO catalogs.categories VALUES ('3eb166b5-75ac-4ac6-8cc7-07e173fea410', 'Hortifrúti', 'Frutas, verduras, legumes e ovos', '2025-05-27 18:38:20.520764', NULL);
INSERT INTO catalogs.categories VALUES ('bb4dc285-b90f-44c4-873d-019f7a29cf72', 'Mercearia', 'Alimentos secos e embalados para consumo geral', '2025-05-27 18:38:20.520764', NULL);
INSERT INTO catalogs.categories VALUES ('cdfee9be-d5d6-4696-8281-b30f0a105000', 'Padaria e Rotisseria', 'Pães, salgados e itens de padaria', '2025-05-27 18:38:20.520764', NULL);
INSERT INTO catalogs.categories VALUES ('79568054-d01e-4844-b43b-c69c407db1bb', 'Pet Shop', 'Produtos e alimentos para animais', '2025-05-27 18:38:20.520764', NULL);
INSERT INTO catalogs.categories VALUES ('d6355fc0-0a7f-415d-9e2e-cbc65f4e528c', 'Produtos de Limpeza', 'Artigos para limpeza doméstica e lavanderia', '2025-05-27 18:38:20.520764', NULL);
INSERT INTO catalogs.categories VALUES ('9ab68158-ca3d-4fb2-b8c9-32d83fb6e511', 'Utilidades e Bazar', 'Itens para o lar, festas e uso cotidiano', '2025-05-27 18:38:20.520764', NULL);
INSERT INTO catalogs.categories VALUES ('9a435ae1-9cbe-4dfb-a703-c5666b7e7830', 'Viver Bem', 'Produtos saudáveis, integrais e funcionais', '2025-05-27 18:38:20.520764', NULL);


--
-- TOC entry 4655 (class 0 OID 17956)
-- Dependencies: 257
-- Data for Name: compositions; Type: TABLE DATA; Schema: catalogs; Owner: postgres
--



--
-- TOC entry 4659 (class 0 OID 18000)
-- Dependencies: 261
-- Data for Name: fillings; Type: TABLE DATA; Schema: catalogs; Owner: postgres
--



--
-- TOC entry 4658 (class 0 OID 17989)
-- Dependencies: 260
-- Data for Name: flavors; Type: TABLE DATA; Schema: catalogs; Owner: postgres
--



--
-- TOC entry 4657 (class 0 OID 17978)
-- Dependencies: 259
-- Data for Name: formats; Type: TABLE DATA; Schema: catalogs; Owner: postgres
--



--
-- TOC entry 4654 (class 0 OID 17941)
-- Dependencies: 256
-- Data for Name: items; Type: TABLE DATA; Schema: catalogs; Owner: postgres
--



--
-- TOC entry 4660 (class 0 OID 18011)
-- Dependencies: 262
-- Data for Name: nutritional_variants; Type: TABLE DATA; Schema: catalogs; Owner: postgres
--



--
-- TOC entry 4665 (class 0 OID 18113)
-- Dependencies: 267
-- Data for Name: offers; Type: TABLE DATA; Schema: catalogs; Owner: postgres
--



--
-- TOC entry 4662 (class 0 OID 18033)
-- Dependencies: 264
-- Data for Name: packagings; Type: TABLE DATA; Schema: catalogs; Owner: postgres
--



--
-- TOC entry 4664 (class 0 OID 18053)
-- Dependencies: 266
-- Data for Name: products; Type: TABLE DATA; Schema: catalogs; Owner: postgres
--



--
-- TOC entry 4663 (class 0 OID 18044)
-- Dependencies: 265
-- Data for Name: quantities; Type: TABLE DATA; Schema: catalogs; Owner: postgres
--



--
-- TOC entry 4653 (class 0 OID 17927)
-- Dependencies: 255
-- Data for Name: subcategories; Type: TABLE DATA; Schema: catalogs; Owner: postgres
--

INSERT INTO catalogs.subcategories VALUES ('9063063b-f40b-4c58-b0c2-6d32636c092d', '0f21080d-bbac-4e3e-bc5a-a0c90dbdde43', 'Carne Bovina', NULL, '2025-05-27 19:40:28.813689', NULL);
INSERT INTO catalogs.subcategories VALUES ('4d0d9605-dd29-4ebb-ac0f-af3d09f2c379', '0f21080d-bbac-4e3e-bc5a-a0c90dbdde43', 'Carne Suína', NULL, '2025-05-27 19:40:28.813689', NULL);
INSERT INTO catalogs.subcategories VALUES ('b2cdfa5d-3b28-4abc-92c6-f8a58b946265', '0f21080d-bbac-4e3e-bc5a-a0c90dbdde43', 'Carnes Semiprontas', NULL, '2025-05-27 19:40:28.813689', NULL);
INSERT INTO catalogs.subcategories VALUES ('28997086-a394-4a07-91b1-1890a9c926ec', '0f21080d-bbac-4e3e-bc5a-a0c90dbdde43', 'Embutidos Defumados e Exóticas', NULL, '2025-05-27 19:40:28.813689', NULL);
INSERT INTO catalogs.subcategories VALUES ('d4a2e12b-752c-4d75-981f-f15f13ae913c', '0f21080d-bbac-4e3e-bc5a-a0c90dbdde43', 'Frango e Aves Exóticas', NULL, '2025-05-27 19:40:28.813689', NULL);
INSERT INTO catalogs.subcategories VALUES ('6f38a5d8-1274-4f2c-8281-8bed4c225f6e', '0f21080d-bbac-4e3e-bc5a-a0c90dbdde43', 'Peixes', NULL, '2025-05-27 19:40:28.813689', NULL);
INSERT INTO catalogs.subcategories VALUES ('b94789ea-c894-4af2-abc6-8617279a0940', '0f21080d-bbac-4e3e-bc5a-a0c90dbdde43', 'Salsichas e Linguiças', NULL, '2025-05-27 19:40:28.813689', NULL);
INSERT INTO catalogs.subcategories VALUES ('82b50228-19a6-4834-aed8-b44e864cef1e', 'faa27e7c-cec6-4c1d-8f5b-b1c4ac4d6b88', 'Aperitivos e Drinks', NULL, '2025-05-27 19:52:38.213052', NULL);
INSERT INTO catalogs.subcategories VALUES ('eba4a96b-966e-4fd2-a827-514c7e375354', 'faa27e7c-cec6-4c1d-8f5b-b1c4ac4d6b88', 'Cervejas', NULL, '2025-05-27 19:52:38.213052', NULL);
INSERT INTO catalogs.subcategories VALUES ('c3832db3-daed-42cd-b74a-cbed7c678b9e', 'faa27e7c-cec6-4c1d-8f5b-b1c4ac4d6b88', 'Destilados', NULL, '2025-05-27 19:52:38.213052', NULL);
INSERT INTO catalogs.subcategories VALUES ('04a36407-915b-4a8f-9a55-646623cee422', 'faa27e7c-cec6-4c1d-8f5b-b1c4ac4d6b88', 'Vinhos e Espumantes', NULL, '2025-05-27 19:52:38.213052', NULL);
INSERT INTO catalogs.subcategories VALUES ('9bdb4740-70b5-4956-bb80-05270eb4b134', 'be39720f-4c61-4a4c-a379-7a55c9b6a8b6', 'Águas de Coco', NULL, '2025-05-27 19:58:18.735952', NULL);
INSERT INTO catalogs.subcategories VALUES ('bf058745-c36a-4693-b4ce-5ef79c95ebb1', 'be39720f-4c61-4a4c-a379-7a55c9b6a8b6', 'Águas Minerais', NULL, '2025-05-27 19:58:18.735952', NULL);
INSERT INTO catalogs.subcategories VALUES ('b10afcfa-05a2-442b-8711-5393934b7604', 'be39720f-4c61-4a4c-a379-7a55c9b6a8b6', 'Energéticos e Isotônicos', NULL, '2025-05-27 19:58:18.735952', NULL);
INSERT INTO catalogs.subcategories VALUES ('73d764c4-379e-41db-9b3d-90d644e21cdb', 'be39720f-4c61-4a4c-a379-7a55c9b6a8b6', 'Sucos e Chás', NULL, '2025-05-27 19:58:18.735952', NULL);
INSERT INTO catalogs.subcategories VALUES ('1a75b44b-73ad-48e7-ad57-ea152cc5a925', '28f93ab7-7062-436e-bcf5-b7eb861fb873', 'Lanches e Massas Congelados', NULL, '2025-05-27 20:01:54.070518', NULL);
INSERT INTO catalogs.subcategories VALUES ('ee087c67-5841-4ba8-a026-087df5e22c21', '28f93ab7-7062-436e-bcf5-b7eb861fb873', 'Polpas e Frutas', NULL, '2025-05-27 20:01:54.070518', NULL);
INSERT INTO catalogs.subcategories VALUES ('70846c48-643c-4332-a355-8ae336544ec7', '28f93ab7-7062-436e-bcf5-b7eb861fb873', 'Sorvetes, Açaís e Sobremesas', NULL, '2025-05-27 20:01:54.070518', NULL);
INSERT INTO catalogs.subcategories VALUES ('d2c4c607-7045-4ffd-b1db-7cbc241dcedf', '28f93ab7-7062-436e-bcf5-b7eb861fb873', 'Vegetais', NULL, '2025-05-27 20:01:54.070518', NULL);
INSERT INTO catalogs.subcategories VALUES ('ff67b526-7ea8-4cca-9c59-ae742819bd85', '4d3db62d-2a27-41d1-bfa9-6ca6766c7f51', 'Frios e Defumados', NULL, '2025-05-27 20:05:19.892585', NULL);
INSERT INTO catalogs.subcategories VALUES ('9e7ac743-517e-4057-9998-c7f2308581eb', '4d3db62d-2a27-41d1-bfa9-6ca6766c7f51', 'Iogurtes', NULL, '2025-05-27 20:05:19.892585', NULL);
INSERT INTO catalogs.subcategories VALUES ('c088ea1d-ceb7-4941-ac32-f5be0f9d9cf3', '4d3db62d-2a27-41d1-bfa9-6ca6766c7f51', 'Leite e Bebidas Lácteas', NULL, '2025-05-27 20:05:19.892585', NULL);
INSERT INTO catalogs.subcategories VALUES ('ebcf3391-5af1-4817-a656-ba24833a40b7', '4d3db62d-2a27-41d1-bfa9-6ca6766c7f51', 'Manteiga e Margarina', NULL, '2025-05-27 20:05:19.892585', NULL);
INSERT INTO catalogs.subcategories VALUES ('09405537-b8cb-47f8-853d-95da4e9f3a8f', '4d3db62d-2a27-41d1-bfa9-6ca6766c7f51', 'Queijos', NULL, '2025-05-27 20:05:19.892585', NULL);
INSERT INTO catalogs.subcategories VALUES ('38552cd3-3157-4801-801f-5e14c60d5ced', '593a63dc-2de2-4e5e-b492-c9c66e7af479', 'Acessórios Banho', NULL, '2025-05-27 20:07:29.667458', NULL);
INSERT INTO catalogs.subcategories VALUES ('8b99d4c7-2749-437b-93be-af7ee7ea57b2', '593a63dc-2de2-4e5e-b492-c9c66e7af479', 'Barbearia', NULL, '2025-05-27 20:07:29.667458', NULL);
INSERT INTO catalogs.subcategories VALUES ('8d0bdc9d-af27-4b81-a456-b93c9b6d4c4d', '593a63dc-2de2-4e5e-b492-c9c66e7af479', 'Cuidado com o Corpo', NULL, '2025-05-27 20:07:29.667458', NULL);
INSERT INTO catalogs.subcategories VALUES ('e05118fc-af91-48cb-a359-358dea79c8cf', '593a63dc-2de2-4e5e-b492-c9c66e7af479', 'Cuidado com o Rosto', NULL, '2025-05-27 20:07:29.667458', NULL);
INSERT INTO catalogs.subcategories VALUES ('c1f6abb5-b095-456c-8cc9-a39049578a4b', '593a63dc-2de2-4e5e-b492-c9c66e7af479', 'Cuidado com os Cabelos', NULL, '2025-05-27 20:07:29.667458', NULL);
INSERT INTO catalogs.subcategories VALUES ('0f05cc82-ea4a-4feb-a07a-9a1a53e78c43', '593a63dc-2de2-4e5e-b492-c9c66e7af479', 'Cuidados com Mãos e Pés', NULL, '2025-05-27 20:07:29.667458', NULL);
INSERT INTO catalogs.subcategories VALUES ('d8289b53-63db-49fd-b3e7-8d406381f25b', '593a63dc-2de2-4e5e-b492-c9c66e7af479', 'Desodorante', NULL, '2025-05-27 20:07:29.667458', NULL);
INSERT INTO catalogs.subcategories VALUES ('1e4351a2-a7cb-4bf8-bb90-2d57fd8e9e65', '593a63dc-2de2-4e5e-b492-c9c66e7af479', 'Higiene Íntima', NULL, '2025-05-27 20:07:29.667458', NULL);
INSERT INTO catalogs.subcategories VALUES ('0c1c8e4c-1188-44d5-89c3-c3eee4b12d67', '593a63dc-2de2-4e5e-b492-c9c66e7af479', 'Infantil', NULL, '2025-05-27 20:07:29.667458', NULL);
INSERT INTO catalogs.subcategories VALUES ('236681ba-467d-4d19-b0c1-40664cb0ad52', '593a63dc-2de2-4e5e-b492-c9c66e7af479', 'Papel Higiênico e Lenços', NULL, '2025-05-27 20:07:29.667458', NULL);
INSERT INTO catalogs.subcategories VALUES ('11239553-1839-4edc-ba52-a210c43aa438', '593a63dc-2de2-4e5e-b492-c9c66e7af479', 'Sabonetes', NULL, '2025-05-27 20:07:29.667458', NULL);
INSERT INTO catalogs.subcategories VALUES ('6a0d03e8-d306-4bb0-8aa4-9b497f8d12dd', '593a63dc-2de2-4e5e-b492-c9c66e7af479', 'Saúde', NULL, '2025-05-27 20:07:29.667458', NULL);
INSERT INTO catalogs.subcategories VALUES ('13e1bc25-a959-4984-8f3b-2044f66337c9', '3eb166b5-75ac-4ac6-8cc7-07e173fea410', 'Empório', NULL, '2025-05-27 20:09:12.429485', NULL);
INSERT INTO catalogs.subcategories VALUES ('4d3eab65-6d43-47fb-8e61-fc919ec4207a', '3eb166b5-75ac-4ac6-8cc7-07e173fea410', 'Frutas', NULL, '2025-05-27 20:09:12.429485', NULL);
INSERT INTO catalogs.subcategories VALUES ('0001e734-d010-44f2-9909-dc398ee2cd77', '3eb166b5-75ac-4ac6-8cc7-07e173fea410', 'Legumes', NULL, '2025-05-27 20:09:12.429485', NULL);
INSERT INTO catalogs.subcategories VALUES ('f463cef8-962f-4269-b571-bf7c9d13e87a', '3eb166b5-75ac-4ac6-8cc7-07e173fea410', 'Molhos Frescos', NULL, '2025-05-27 20:09:12.429485', NULL);
INSERT INTO catalogs.subcategories VALUES ('598b3b42-188e-488c-98b9-53e2f929ab24', '3eb166b5-75ac-4ac6-8cc7-07e173fea410', 'Orgânicos', NULL, '2025-05-27 20:09:12.429485', NULL);
INSERT INTO catalogs.subcategories VALUES ('151c470e-a0ea-417b-b227-f80f582b015f', '3eb166b5-75ac-4ac6-8cc7-07e173fea410', 'Ovos', NULL, '2025-05-27 20:09:12.429485', NULL);
INSERT INTO catalogs.subcategories VALUES ('86e2efb3-023f-4ce3-b0d6-36e4581f189e', '3eb166b5-75ac-4ac6-8cc7-07e173fea410', 'Verduras', NULL, '2025-05-27 20:09:12.429485', NULL);
INSERT INTO catalogs.subcategories VALUES ('8fa81de0-07e4-47cb-b706-4b620dc97a8c', 'bb4dc285-b90f-44c4-873d-019f7a29cf72', 'Achocolatados e Cacau em Pó', NULL, '2025-05-27 20:12:01.309503', NULL);
INSERT INTO catalogs.subcategories VALUES ('7fb99608-d306-4301-9550-f3eadca2eac7', 'bb4dc285-b90f-44c4-873d-019f7a29cf72', 'Açucares e adoçantes', NULL, '2025-05-27 20:12:01.309503', NULL);
INSERT INTO catalogs.subcategories VALUES ('2f879099-4d62-4b06-9f98-416281275ecc', 'bb4dc285-b90f-44c4-873d-019f7a29cf72', 'Alimentos Infantis', NULL, '2025-05-27 20:12:01.309503', NULL);
INSERT INTO catalogs.subcategories VALUES ('170b8f6f-07ed-46ab-a9a2-ca6c5f2c41f7', 'bb4dc285-b90f-44c4-873d-019f7a29cf72', 'Arroz e Feijão', NULL, '2025-05-27 20:12:01.309503', NULL);
INSERT INTO catalogs.subcategories VALUES ('5be3bfcb-2d3c-4162-bc27-eb243afce071', 'bb4dc285-b90f-44c4-873d-019f7a29cf72', 'Aveias, Cereais e Matinais', NULL, '2025-05-27 20:12:01.309503', NULL);
INSERT INTO catalogs.subcategories VALUES ('d9c801ae-585c-447b-ba80-441d9cc1a60c', 'bb4dc285-b90f-44c4-873d-019f7a29cf72', 'Biscoitos e Snacks', NULL, '2025-05-27 20:12:01.309503', NULL);
INSERT INTO catalogs.subcategories VALUES ('a03489b3-072f-4bce-9875-c5109b647d66', 'bb4dc285-b90f-44c4-873d-019f7a29cf72', 'Bomboniere', NULL, '2025-05-27 20:12:01.309503', NULL);
INSERT INTO catalogs.subcategories VALUES ('419a8f6e-d7f4-45f5-8b45-b717c1a37754', 'bb4dc285-b90f-44c4-873d-019f7a29cf72', 'Cafés e Chás', NULL, '2025-05-27 20:12:01.309503', NULL);
INSERT INTO catalogs.subcategories VALUES ('4707f7ab-377b-416f-935d-fa96ff3491c8', 'bb4dc285-b90f-44c4-873d-019f7a29cf72', 'Cestas Básicas', NULL, '2025-05-27 20:12:01.309503', NULL);
INSERT INTO catalogs.subcategories VALUES ('0b9122d7-23b6-47b7-b826-a8eb247d585b', 'bb4dc285-b90f-44c4-873d-019f7a29cf72', 'Chips e Batatas Palha', NULL, '2025-05-27 20:12:01.309503', NULL);
INSERT INTO catalogs.subcategories VALUES ('534c6710-d76a-4397-9c38-23e927ef3210', 'bb4dc285-b90f-44c4-873d-019f7a29cf72', 'Doces e Geléias', NULL, '2025-05-27 20:12:01.309503', NULL);
INSERT INTO catalogs.subcategories VALUES ('d9484bbd-dcec-4151-9b50-ca0cf0ba7f1c', 'bb4dc285-b90f-44c4-873d-019f7a29cf72', 'Enlatados e Conservas', NULL, '2025-05-27 20:12:01.309503', NULL);
INSERT INTO catalogs.subcategories VALUES ('78b8577f-92ed-4aa5-a89c-e297856eb645', 'bb4dc285-b90f-44c4-873d-019f7a29cf72', 'Farinhas e Fermentos', NULL, '2025-05-27 20:12:01.309503', NULL);
INSERT INTO catalogs.subcategories VALUES ('adf0fcf1-01f7-4158-9f51-f7eeb76aabd9', 'bb4dc285-b90f-44c4-873d-019f7a29cf72', 'Leites e Bebidas Lácteas', NULL, '2025-05-27 20:12:01.309503', NULL);
INSERT INTO catalogs.subcategories VALUES ('24cc3e97-aad8-4602-b938-4ac4d547a9f5', 'bb4dc285-b90f-44c4-873d-019f7a29cf72', 'Massas', NULL, '2025-05-27 20:12:01.309503', NULL);
INSERT INTO catalogs.subcategories VALUES ('03e2c558-0d6d-49d1-a870-5e83fcca9f83', 'bb4dc285-b90f-44c4-873d-019f7a29cf72', 'Mercearia Importados', NULL, '2025-05-27 20:12:01.309503', NULL);
INSERT INTO catalogs.subcategories VALUES ('d0ef6e0f-8afd-4183-bb87-2ed3b47611f3', 'bb4dc285-b90f-44c4-873d-019f7a29cf72', 'Molhos e Condimentos', NULL, '2025-05-27 20:12:01.309503', NULL);
INSERT INTO catalogs.subcategories VALUES ('7d180b6e-98e9-4eb5-bf0c-6f70d55486d2', 'bb4dc285-b90f-44c4-873d-019f7a29cf72', 'Pipocas e Grãos', NULL, '2025-05-27 20:12:01.309503', NULL);
INSERT INTO catalogs.subcategories VALUES ('44af3572-9446-4338-a941-e2a020424d72', 'bb4dc285-b90f-44c4-873d-019f7a29cf72', 'Sopas e Cremes', NULL, '2025-05-27 20:12:01.309503', NULL);
INSERT INTO catalogs.subcategories VALUES ('634b7d42-ead8-42a4-8d42-458c2c490ed2', 'bb4dc285-b90f-44c4-873d-019f7a29cf72', 'Temperos e Especiarias', NULL, '2025-05-27 20:12:01.309503', NULL);
INSERT INTO catalogs.subcategories VALUES ('14087e7e-64a0-422d-8e68-8cfb1e1f1e6e', 'bb4dc285-b90f-44c4-873d-019f7a29cf72', 'Vinagres, Óleos e Azeites', NULL, '2025-05-27 20:12:01.309503', NULL);
INSERT INTO catalogs.subcategories VALUES ('bc88dd02-fbfc-4132-bbfd-5f38f2e2975f', 'cdfee9be-d5d6-4696-8281-b30f0a105000', 'Biscoitos e Pães de Queijo', NULL, '2025-05-27 20:14:57.314998', NULL);
INSERT INTO catalogs.subcategories VALUES ('02a45af3-8313-405d-9fcf-ef15e7f364de', 'cdfee9be-d5d6-4696-8281-b30f0a105000', 'Confeitaria', NULL, '2025-05-27 20:14:57.314998', NULL);
INSERT INTO catalogs.subcategories VALUES ('590faf89-af59-4b91-8a0d-f71f12e54843', 'cdfee9be-d5d6-4696-8281-b30f0a105000', 'Pães e Bolos Industrializados', NULL, '2025-05-27 20:14:57.314998', NULL);
INSERT INTO catalogs.subcategories VALUES ('073dd3f1-95e8-4db0-ba9a-8c92db4d6399', 'cdfee9be-d5d6-4696-8281-b30f0a105000', 'Pães Fabricação Própria', NULL, '2025-05-27 20:14:57.314998', NULL);
INSERT INTO catalogs.subcategories VALUES ('02804d35-d737-4ecf-9966-19a5cbead05c', 'cdfee9be-d5d6-4696-8281-b30f0a105000', 'Rotisseria', NULL, '2025-05-27 20:14:57.314998', NULL);
INSERT INTO catalogs.subcategories VALUES ('ddd2ca36-5d7e-452c-b3ff-9f8a54c676c2', 'cdfee9be-d5d6-4696-8281-b30f0a105000', 'Salgados', NULL, '2025-05-27 20:14:57.314998', NULL);
INSERT INTO catalogs.subcategories VALUES ('b5a26bdb-a855-49aa-961c-905e5aea1a14', '79568054-d01e-4844-b43b-c69c407db1bb', 'Acessórios Pet', NULL, '2025-05-27 20:20:37.98758', NULL);
INSERT INTO catalogs.subcategories VALUES ('787a2941-ebf8-47ca-b5be-34b3a799fab1', '79568054-d01e-4844-b43b-c69c407db1bb', 'Cães', NULL, '2025-05-27 20:20:37.98758', NULL);
INSERT INTO catalogs.subcategories VALUES ('832f09bb-7a47-485f-97d6-f6f20baeb9b5', '79568054-d01e-4844-b43b-c69c407db1bb', 'Gatos', NULL, '2025-05-27 20:20:37.98758', NULL);
INSERT INTO catalogs.subcategories VALUES ('f162bf27-eca3-4054-9bf3-86ace863ab99', '79568054-d01e-4844-b43b-c69c407db1bb', 'Higiene e Limpeza', NULL, '2025-05-27 20:20:37.98758', NULL);
INSERT INTO catalogs.subcategories VALUES ('8d63358c-538c-49c1-ac65-78a90fe0f761', '79568054-d01e-4844-b43b-c69c407db1bb', 'Outros Animais', NULL, '2025-05-27 20:20:37.98758', NULL);
INSERT INTO catalogs.subcategories VALUES ('4a5f9580-1829-47ce-8e4d-cdead5dfc5ad', 'd6355fc0-0a7f-415d-9e2e-cbc65f4e528c', 'Para Banheiro', NULL, '2025-05-27 20:22:33.810808', NULL);
INSERT INTO catalogs.subcategories VALUES ('09a3b7fd-3fd0-4896-a0fb-614246f98e30', 'd6355fc0-0a7f-415d-9e2e-cbc65f4e528c', 'Para Casa Toda', NULL, '2025-05-27 20:22:33.810808', NULL);
INSERT INTO catalogs.subcategories VALUES ('f5cb78a4-cf63-407f-9652-c98d8d6b0b62', 'd6355fc0-0a7f-415d-9e2e-cbc65f4e528c', 'Para Cozinha', NULL, '2025-05-27 20:22:33.810808', NULL);
INSERT INTO catalogs.subcategories VALUES ('317e7ba5-b9f0-4fdb-9c6d-ce8e249f874d', 'd6355fc0-0a7f-415d-9e2e-cbc65f4e528c', 'Para Roupas', NULL, '2025-05-27 20:22:33.810808', NULL);
INSERT INTO catalogs.subcategories VALUES ('3eb2e255-2d98-4eff-b5f6-8f12b54bc217', '9ab68158-ca3d-4fb2-b8c9-32d83fb6e511', 'Artigos para Festa', NULL, '2025-05-27 20:25:26.222003', NULL);
INSERT INTO catalogs.subcategories VALUES ('2810f596-4ce6-47fb-990a-9ef336ec6cc5', '9ab68158-ca3d-4fb2-b8c9-32d83fb6e511', 'Brinquedos', NULL, '2025-05-27 20:25:26.222003', NULL);
INSERT INTO catalogs.subcategories VALUES ('3e7b394d-4184-479f-86b7-7e7e57240002', '9ab68158-ca3d-4fb2-b8c9-32d83fb6e511', 'Cama, Mesa e Banho', NULL, '2025-05-27 20:25:26.222003', NULL);
INSERT INTO catalogs.subcategories VALUES ('f14d4d82-f990-4f59-8c99-ef4d25344d24', '9ab68158-ca3d-4fb2-b8c9-32d83fb6e511', 'Churrasco', NULL, '2025-05-27 20:25:26.222003', NULL);
INSERT INTO catalogs.subcategories VALUES ('a5155da5-7da5-47ab-a6b8-9845d8db2edc', '9ab68158-ca3d-4fb2-b8c9-32d83fb6e511', 'Eletro', NULL, '2025-05-27 20:25:26.222003', NULL);
INSERT INTO catalogs.subcategories VALUES ('0c5b3e9a-3df6-475d-ab27-d4e5acd627ef', '9ab68158-ca3d-4fb2-b8c9-32d83fb6e511', 'Embalagens e Descartáveis', NULL, '2025-05-27 20:25:26.222003', NULL);
INSERT INTO catalogs.subcategories VALUES ('bebd28e4-cf0d-42a5-9bfa-9ef5951f3a12', '9ab68158-ca3d-4fb2-b8c9-32d83fb6e511', 'Esportes e Camping', NULL, '2025-05-27 20:25:26.222003', NULL);
INSERT INTO catalogs.subcategories VALUES ('0e570349-1366-4e7a-a8e3-d8a13d83f64b', '9ab68158-ca3d-4fb2-b8c9-32d83fb6e511', 'Jardinagem', NULL, '2025-05-27 20:25:26.222003', NULL);
INSERT INTO catalogs.subcategories VALUES ('3efa0b6a-4c17-4b0c-bef8-1919407305ef', '9ab68158-ca3d-4fb2-b8c9-32d83fb6e511', 'Material Escolar e de Escritório', NULL, '2025-05-27 20:25:26.222003', NULL);
INSERT INTO catalogs.subcategories VALUES ('ac689f3b-e28f-4370-a042-7cb4293854e8', '9ab68158-ca3d-4fb2-b8c9-32d83fb6e511', 'Mesas e Cadeiras', NULL, '2025-05-27 20:25:26.222003', NULL);
INSERT INTO catalogs.subcategories VALUES ('020650c1-d2c2-469f-924b-457238d7bf01', '9ab68158-ca3d-4fb2-b8c9-32d83fb6e511', 'Produtos Automotivos', NULL, '2025-05-27 20:25:26.222003', NULL);
INSERT INTO catalogs.subcategories VALUES ('56810e63-b7a1-45d9-b03c-55492504b343', '9ab68158-ca3d-4fb2-b8c9-32d83fb6e511', 'Utensílios Domésticos', NULL, '2025-05-27 20:25:26.222003', NULL);
INSERT INTO catalogs.subcategories VALUES ('f246ed4d-d23c-46bc-8052-8f6b5d934e47', '9ab68158-ca3d-4fb2-b8c9-32d83fb6e511', 'Vestuário e Calçados', NULL, '2025-05-27 20:25:26.222003', NULL);
INSERT INTO catalogs.subcategories VALUES ('829b03b2-c117-4acc-8e71-448f0f9504db', '9a435ae1-9cbe-4dfb-a703-c5666b7e7830', 'Adoçantes', NULL, '2025-05-27 20:25:42.303244', NULL);
INSERT INTO catalogs.subcategories VALUES ('f37bcd4c-13f4-4b5a-a8ef-723fc88e0f6f', '9a435ae1-9cbe-4dfb-a703-c5666b7e7830', 'Aveias, Cereais e Matinais', NULL, '2025-05-27 20:25:42.303244', NULL);
INSERT INTO catalogs.subcategories VALUES ('c49642b0-bb5b-4cd0-97a6-75fa7a64e1b2', '9a435ae1-9cbe-4dfb-a703-c5666b7e7830', 'Bebidas Vegetais', NULL, '2025-05-27 20:25:42.303244', NULL);
INSERT INTO catalogs.subcategories VALUES ('d2c7881b-fb79-4c6b-99c5-cd00988a5128', '9a435ae1-9cbe-4dfb-a703-c5666b7e7830', 'Biscoitos e Snacks', NULL, '2025-05-27 20:25:42.303244', NULL);
INSERT INTO catalogs.subcategories VALUES ('82bf9ce2-f0ad-4882-8f85-0c0856cb4e3b', '9a435ae1-9cbe-4dfb-a703-c5666b7e7830', 'Bombons e Chocolates', NULL, '2025-05-27 20:25:42.303244', NULL);
INSERT INTO catalogs.subcategories VALUES ('a0546e44-c136-4229-bf57-c7f1b2268790', '9a435ae1-9cbe-4dfb-a703-c5666b7e7830', 'Complementos e Suplementos', NULL, '2025-05-27 20:25:42.303244', NULL);
INSERT INTO catalogs.subcategories VALUES ('dec544c8-2556-4a85-9311-984ef18feb80', '9a435ae1-9cbe-4dfb-a703-c5666b7e7830', 'Doces', NULL, '2025-05-27 20:25:42.303244', NULL);
INSERT INTO catalogs.subcategories VALUES ('aa38037a-b65f-4e73-931c-cb6cda28a35b', '9a435ae1-9cbe-4dfb-a703-c5666b7e7830', 'Farinhas e Grãos', NULL, '2025-05-27 20:25:42.303244', NULL);
INSERT INTO catalogs.subcategories VALUES ('42daf2ea-f578-4f40-a2fd-45ec72f9b31d', '9a435ae1-9cbe-4dfb-a703-c5666b7e7830', 'Óleos e Azeites', NULL, '2025-05-27 20:25:42.303244', NULL);
INSERT INTO catalogs.subcategories VALUES ('10e940d4-064a-4475-a86c-ec1279dac8c8', '9a435ae1-9cbe-4dfb-a703-c5666b7e7830', 'Orgânicos', NULL, '2025-05-27 20:25:42.303244', NULL);
INSERT INTO catalogs.subcategories VALUES ('dd1d3d47-265c-4910-81ca-539704e0a11b', '9a435ae1-9cbe-4dfb-a703-c5666b7e7830', 'Outros Saudáveis', NULL, '2025-05-27 20:25:42.303244', NULL);
INSERT INTO catalogs.subcategories VALUES ('7a77bd7a-a1c0-40dc-98d7-89ac585d6b41', '9a435ae1-9cbe-4dfb-a703-c5666b7e7830', 'Padaria', NULL, '2025-05-27 20:25:42.303244', NULL);
INSERT INTO catalogs.subcategories VALUES ('5a8b55e1-80c2-4542-994f-b997ffd43d0f', '9a435ae1-9cbe-4dfb-a703-c5666b7e7830', 'Proteínas Vegetais', NULL, '2025-05-27 20:25:42.303244', NULL);


--
-- TOC entry 4656 (class 0 OID 17967)
-- Dependencies: 258
-- Data for Name: variant_types; Type: TABLE DATA; Schema: catalogs; Owner: postgres
--



--
-- TOC entry 4405 (class 2606 OID 17705)
-- Name: api_keys api_keys_pkey; Type: CONSTRAINT; Schema: accounts; Owner: postgres
--

ALTER TABLE ONLY accounts.api_keys
    ADD CONSTRAINT api_keys_pkey PRIMARY KEY (api_key_id);


--
-- TOC entry 4407 (class 2606 OID 17717)
-- Name: api_scopes api_scopes_pkey; Type: CONSTRAINT; Schema: accounts; Owner: postgres
--

ALTER TABLE ONLY accounts.api_scopes
    ADD CONSTRAINT api_scopes_pkey PRIMARY KEY (api_scope_id);


--
-- TOC entry 4402 (class 2606 OID 17428)
-- Name: apis apis_pkey; Type: CONSTRAINT; Schema: accounts; Owner: postgres
--

ALTER TABLE ONLY accounts.apis
    ADD CONSTRAINT apis_pkey PRIMARY KEY (api_id);


--
-- TOC entry 4398 (class 2606 OID 17404)
-- Name: employee_roles employee_roles_pkey; Type: CONSTRAINT; Schema: accounts; Owner: postgres
--

ALTER TABLE ONLY accounts.employee_roles
    ADD CONSTRAINT employee_roles_pkey PRIMARY KEY (employee_role_id);


--
-- TOC entry 4374 (class 2606 OID 17281)
-- Name: employees employees_pkey; Type: CONSTRAINT; Schema: accounts; Owner: postgres
--

ALTER TABLE ONLY accounts.employees
    ADD CONSTRAINT employees_pkey PRIMARY KEY (employee_id);


--
-- TOC entry 4372 (class 2606 OID 17266)
-- Name: establishments establishments_pkey; Type: CONSTRAINT; Schema: accounts; Owner: postgres
--

ALTER TABLE ONLY accounts.establishments
    ADD CONSTRAINT establishments_pkey PRIMARY KEY (establishment_id);


--
-- TOC entry 4385 (class 2606 OID 17349)
-- Name: features features_code_key; Type: CONSTRAINT; Schema: accounts; Owner: postgres
--

ALTER TABLE ONLY accounts.features
    ADD CONSTRAINT features_code_key UNIQUE (code);


--
-- TOC entry 4387 (class 2606 OID 17347)
-- Name: features features_pkey; Type: CONSTRAINT; Schema: accounts; Owner: postgres
--

ALTER TABLE ONLY accounts.features
    ADD CONSTRAINT features_pkey PRIMARY KEY (feature_id);


--
-- TOC entry 4381 (class 2606 OID 17328)
-- Name: modules modules_name_key; Type: CONSTRAINT; Schema: accounts; Owner: postgres
--

ALTER TABLE ONLY accounts.modules
    ADD CONSTRAINT modules_name_key UNIQUE (name);


--
-- TOC entry 4383 (class 2606 OID 17326)
-- Name: modules modules_pkey; Type: CONSTRAINT; Schema: accounts; Owner: postgres
--

ALTER TABLE ONLY accounts.modules
    ADD CONSTRAINT modules_pkey PRIMARY KEY (module_id);


--
-- TOC entry 4377 (class 2606 OID 17312)
-- Name: platforms platforms_name_key; Type: CONSTRAINT; Schema: accounts; Owner: postgres
--

ALTER TABLE ONLY accounts.platforms
    ADD CONSTRAINT platforms_name_key UNIQUE (name);


--
-- TOC entry 4379 (class 2606 OID 17310)
-- Name: platforms platforms_pkey; Type: CONSTRAINT; Schema: accounts; Owner: postgres
--

ALTER TABLE ONLY accounts.platforms
    ADD CONSTRAINT platforms_pkey PRIMARY KEY (platform_id);


--
-- TOC entry 4396 (class 2606 OID 17382)
-- Name: role_features role_features_pkey; Type: CONSTRAINT; Schema: accounts; Owner: postgres
--

ALTER TABLE ONLY accounts.role_features
    ADD CONSTRAINT role_features_pkey PRIMARY KEY (role_feature_id);


--
-- TOC entry 4391 (class 2606 OID 17370)
-- Name: roles roles_name_key; Type: CONSTRAINT; Schema: accounts; Owner: postgres
--

ALTER TABLE ONLY accounts.roles
    ADD CONSTRAINT roles_name_key UNIQUE (name);


--
-- TOC entry 4393 (class 2606 OID 17368)
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: accounts; Owner: postgres
--

ALTER TABLE ONLY accounts.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (role_id);


--
-- TOC entry 4370 (class 2606 OID 17250)
-- Name: suppliers suppliers_pkey; Type: CONSTRAINT; Schema: accounts; Owner: postgres
--

ALTER TABLE ONLY accounts.suppliers
    ADD CONSTRAINT suppliers_pkey PRIMARY KEY (supplier_id);


--
-- TOC entry 4364 (class 2606 OID 17239)
-- Name: users users_cognito_sub_key; Type: CONSTRAINT; Schema: accounts; Owner: postgres
--

ALTER TABLE ONLY accounts.users
    ADD CONSTRAINT users_cognito_sub_key UNIQUE (cognito_sub);


--
-- TOC entry 4366 (class 2606 OID 17237)
-- Name: users users_email_key; Type: CONSTRAINT; Schema: accounts; Owner: postgres
--

ALTER TABLE ONLY accounts.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- TOC entry 4368 (class 2606 OID 17235)
-- Name: users users_pkey; Type: CONSTRAINT; Schema: accounts; Owner: postgres
--

ALTER TABLE ONLY accounts.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (user_id);


--
-- TOC entry 4441 (class 2606 OID 18032)
-- Name: brands brands_name_key; Type: CONSTRAINT; Schema: catalogs; Owner: postgres
--

ALTER TABLE ONLY catalogs.brands
    ADD CONSTRAINT brands_name_key UNIQUE (name);


--
-- TOC entry 4443 (class 2606 OID 18030)
-- Name: brands brands_pkey; Type: CONSTRAINT; Schema: catalogs; Owner: postgres
--

ALTER TABLE ONLY catalogs.brands
    ADD CONSTRAINT brands_pkey PRIMARY KEY (brand_id);


--
-- TOC entry 4409 (class 2606 OID 17926)
-- Name: categories categories_name_key; Type: CONSTRAINT; Schema: catalogs; Owner: postgres
--

ALTER TABLE ONLY catalogs.categories
    ADD CONSTRAINT categories_name_key UNIQUE (name);


--
-- TOC entry 4411 (class 2606 OID 17924)
-- Name: categories categories_pkey; Type: CONSTRAINT; Schema: catalogs; Owner: postgres
--

ALTER TABLE ONLY catalogs.categories
    ADD CONSTRAINT categories_pkey PRIMARY KEY (category_id);


--
-- TOC entry 4417 (class 2606 OID 17966)
-- Name: compositions compositions_name_key; Type: CONSTRAINT; Schema: catalogs; Owner: postgres
--

ALTER TABLE ONLY catalogs.compositions
    ADD CONSTRAINT compositions_name_key UNIQUE (name);


--
-- TOC entry 4419 (class 2606 OID 17964)
-- Name: compositions compositions_pkey; Type: CONSTRAINT; Schema: catalogs; Owner: postgres
--

ALTER TABLE ONLY catalogs.compositions
    ADD CONSTRAINT compositions_pkey PRIMARY KEY (composition_id);


--
-- TOC entry 4433 (class 2606 OID 18010)
-- Name: fillings fillings_name_key; Type: CONSTRAINT; Schema: catalogs; Owner: postgres
--

ALTER TABLE ONLY catalogs.fillings
    ADD CONSTRAINT fillings_name_key UNIQUE (name);


--
-- TOC entry 4435 (class 2606 OID 18008)
-- Name: fillings fillings_pkey; Type: CONSTRAINT; Schema: catalogs; Owner: postgres
--

ALTER TABLE ONLY catalogs.fillings
    ADD CONSTRAINT fillings_pkey PRIMARY KEY (filling_id);


--
-- TOC entry 4429 (class 2606 OID 17999)
-- Name: flavors flavors_name_key; Type: CONSTRAINT; Schema: catalogs; Owner: postgres
--

ALTER TABLE ONLY catalogs.flavors
    ADD CONSTRAINT flavors_name_key UNIQUE (name);


--
-- TOC entry 4431 (class 2606 OID 17997)
-- Name: flavors flavors_pkey; Type: CONSTRAINT; Schema: catalogs; Owner: postgres
--

ALTER TABLE ONLY catalogs.flavors
    ADD CONSTRAINT flavors_pkey PRIMARY KEY (flavor_id);


--
-- TOC entry 4425 (class 2606 OID 17988)
-- Name: formats formats_name_key; Type: CONSTRAINT; Schema: catalogs; Owner: postgres
--

ALTER TABLE ONLY catalogs.formats
    ADD CONSTRAINT formats_name_key UNIQUE (name);


--
-- TOC entry 4427 (class 2606 OID 17986)
-- Name: formats formats_pkey; Type: CONSTRAINT; Schema: catalogs; Owner: postgres
--

ALTER TABLE ONLY catalogs.formats
    ADD CONSTRAINT formats_pkey PRIMARY KEY (format_id);


--
-- TOC entry 4415 (class 2606 OID 17949)
-- Name: items items_pkey; Type: CONSTRAINT; Schema: catalogs; Owner: postgres
--

ALTER TABLE ONLY catalogs.items
    ADD CONSTRAINT items_pkey PRIMARY KEY (item_id);


--
-- TOC entry 4437 (class 2606 OID 18021)
-- Name: nutritional_variants nutritional_variants_name_key; Type: CONSTRAINT; Schema: catalogs; Owner: postgres
--

ALTER TABLE ONLY catalogs.nutritional_variants
    ADD CONSTRAINT nutritional_variants_name_key UNIQUE (name);


--
-- TOC entry 4439 (class 2606 OID 18019)
-- Name: nutritional_variants nutritional_variants_pkey; Type: CONSTRAINT; Schema: catalogs; Owner: postgres
--

ALTER TABLE ONLY catalogs.nutritional_variants
    ADD CONSTRAINT nutritional_variants_pkey PRIMARY KEY (nutritional_variant_id);


--
-- TOC entry 4453 (class 2606 OID 18120)
-- Name: offers offers_pkey; Type: CONSTRAINT; Schema: catalogs; Owner: postgres
--

ALTER TABLE ONLY catalogs.offers
    ADD CONSTRAINT offers_pkey PRIMARY KEY (offer_id);


--
-- TOC entry 4445 (class 2606 OID 18043)
-- Name: packagings packagings_name_key; Type: CONSTRAINT; Schema: catalogs; Owner: postgres
--

ALTER TABLE ONLY catalogs.packagings
    ADD CONSTRAINT packagings_name_key UNIQUE (name);


--
-- TOC entry 4447 (class 2606 OID 18041)
-- Name: packagings packagings_pkey; Type: CONSTRAINT; Schema: catalogs; Owner: postgres
--

ALTER TABLE ONLY catalogs.packagings
    ADD CONSTRAINT packagings_pkey PRIMARY KEY (packaging_id);


--
-- TOC entry 4451 (class 2606 OID 18062)
-- Name: products products_pkey; Type: CONSTRAINT; Schema: catalogs; Owner: postgres
--

ALTER TABLE ONLY catalogs.products
    ADD CONSTRAINT products_pkey PRIMARY KEY (product_id);


--
-- TOC entry 4449 (class 2606 OID 18052)
-- Name: quantities quantities_pkey; Type: CONSTRAINT; Schema: catalogs; Owner: postgres
--

ALTER TABLE ONLY catalogs.quantities
    ADD CONSTRAINT quantities_pkey PRIMARY KEY (quantity_id);


--
-- TOC entry 4413 (class 2606 OID 17935)
-- Name: subcategories subcategories_pkey; Type: CONSTRAINT; Schema: catalogs; Owner: postgres
--

ALTER TABLE ONLY catalogs.subcategories
    ADD CONSTRAINT subcategories_pkey PRIMARY KEY (subcategory_id);


--
-- TOC entry 4421 (class 2606 OID 17977)
-- Name: variant_types variant_types_name_key; Type: CONSTRAINT; Schema: catalogs; Owner: postgres
--

ALTER TABLE ONLY catalogs.variant_types
    ADD CONSTRAINT variant_types_name_key UNIQUE (name);


--
-- TOC entry 4423 (class 2606 OID 17975)
-- Name: variant_types variant_types_pkey; Type: CONSTRAINT; Schema: catalogs; Owner: postgres
--

ALTER TABLE ONLY catalogs.variant_types
    ADD CONSTRAINT variant_types_pkey PRIMARY KEY (variant_type_id);


--
-- TOC entry 4403 (class 1259 OID 17595)
-- Name: idx_apis_path_method; Type: INDEX; Schema: accounts; Owner: postgres
--

CREATE INDEX idx_apis_path_method ON accounts.apis USING btree (path, method);


--
-- TOC entry 4399 (class 1259 OID 17597)
-- Name: idx_employee_roles_employee; Type: INDEX; Schema: accounts; Owner: postgres
--

CREATE INDEX idx_employee_roles_employee ON accounts.employee_roles USING btree (employee_id);


--
-- TOC entry 4400 (class 1259 OID 17591)
-- Name: idx_employee_roles_user; Type: INDEX; Schema: accounts; Owner: postgres
--

CREATE INDEX idx_employee_roles_user ON accounts.employee_roles USING btree (employee_id);


--
-- TOC entry 4375 (class 1259 OID 17596)
-- Name: idx_employees_supplier_active; Type: INDEX; Schema: accounts; Owner: postgres
--

CREATE INDEX idx_employees_supplier_active ON accounts.employees USING btree (supplier_id, is_active);


--
-- TOC entry 4388 (class 1259 OID 17593)
-- Name: idx_features_code; Type: INDEX; Schema: accounts; Owner: postgres
--

CREATE INDEX idx_features_code ON accounts.features USING btree (code);


--
-- TOC entry 4389 (class 1259 OID 17598)
-- Name: idx_features_module; Type: INDEX; Schema: accounts; Owner: postgres
--

CREATE INDEX idx_features_module ON accounts.features USING btree (module_id);


--
-- TOC entry 4394 (class 1259 OID 17592)
-- Name: idx_role_features_role_feature; Type: INDEX; Schema: accounts; Owner: postgres
--

CREATE INDEX idx_role_features_role_feature ON accounts.role_features USING btree (role_id, feature_id);


--
-- TOC entry 4491 (class 2620 OID 17524)
-- Name: apis trg_set_updated_at_apis; Type: TRIGGER; Schema: accounts; Owner: postgres
--

CREATE TRIGGER trg_set_updated_at_apis BEFORE UPDATE ON accounts.apis FOR EACH ROW EXECUTE FUNCTION accounts.set_updated_at();


--
-- TOC entry 4864 (class 0 OID 0)
-- Dependencies: 4491
-- Name: TRIGGER trg_set_updated_at_apis ON apis; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON TRIGGER trg_set_updated_at_apis ON accounts.apis IS 'Atualiza automaticamente o campo updated_at da tabela apis em updates.';


--
-- TOC entry 4490 (class 2620 OID 17523)
-- Name: employee_roles trg_set_updated_at_employee_roles; Type: TRIGGER; Schema: accounts; Owner: postgres
--

CREATE TRIGGER trg_set_updated_at_employee_roles BEFORE UPDATE ON accounts.employee_roles FOR EACH ROW EXECUTE FUNCTION accounts.set_updated_at();


--
-- TOC entry 4865 (class 0 OID 0)
-- Dependencies: 4490
-- Name: TRIGGER trg_set_updated_at_employee_roles ON employee_roles; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON TRIGGER trg_set_updated_at_employee_roles ON accounts.employee_roles IS 'Atualiza automaticamente o campo updated_at da tabela employee_roles em updates.';


--
-- TOC entry 4484 (class 2620 OID 17517)
-- Name: employees trg_set_updated_at_employees; Type: TRIGGER; Schema: accounts; Owner: postgres
--

CREATE TRIGGER trg_set_updated_at_employees BEFORE UPDATE ON accounts.employees FOR EACH ROW EXECUTE FUNCTION accounts.set_updated_at();


--
-- TOC entry 4866 (class 0 OID 0)
-- Dependencies: 4484
-- Name: TRIGGER trg_set_updated_at_employees ON employees; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON TRIGGER trg_set_updated_at_employees ON accounts.employees IS 'Atualiza automaticamente o campo updated_at da tabela employees em updates.';


--
-- TOC entry 4483 (class 2620 OID 17516)
-- Name: establishments trg_set_updated_at_establishments; Type: TRIGGER; Schema: accounts; Owner: postgres
--

CREATE TRIGGER trg_set_updated_at_establishments BEFORE UPDATE ON accounts.establishments FOR EACH ROW EXECUTE FUNCTION accounts.set_updated_at();


--
-- TOC entry 4867 (class 0 OID 0)
-- Dependencies: 4483
-- Name: TRIGGER trg_set_updated_at_establishments ON establishments; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON TRIGGER trg_set_updated_at_establishments ON accounts.establishments IS 'Atualiza automaticamente o campo updated_at da tabela establishments em updates.';


--
-- TOC entry 4487 (class 2620 OID 17520)
-- Name: features trg_set_updated_at_features; Type: TRIGGER; Schema: accounts; Owner: postgres
--

CREATE TRIGGER trg_set_updated_at_features BEFORE UPDATE ON accounts.features FOR EACH ROW EXECUTE FUNCTION accounts.set_updated_at();


--
-- TOC entry 4868 (class 0 OID 0)
-- Dependencies: 4487
-- Name: TRIGGER trg_set_updated_at_features ON features; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON TRIGGER trg_set_updated_at_features ON accounts.features IS 'Atualiza automaticamente o campo updated_at da tabela features em updates.';


--
-- TOC entry 4486 (class 2620 OID 17519)
-- Name: modules trg_set_updated_at_modules; Type: TRIGGER; Schema: accounts; Owner: postgres
--

CREATE TRIGGER trg_set_updated_at_modules BEFORE UPDATE ON accounts.modules FOR EACH ROW EXECUTE FUNCTION accounts.set_updated_at();


--
-- TOC entry 4869 (class 0 OID 0)
-- Dependencies: 4486
-- Name: TRIGGER trg_set_updated_at_modules ON modules; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON TRIGGER trg_set_updated_at_modules ON accounts.modules IS 'Atualiza automaticamente o campo updated_at da tabela modules em updates.';


--
-- TOC entry 4485 (class 2620 OID 17518)
-- Name: platforms trg_set_updated_at_platforms; Type: TRIGGER; Schema: accounts; Owner: postgres
--

CREATE TRIGGER trg_set_updated_at_platforms BEFORE UPDATE ON accounts.platforms FOR EACH ROW EXECUTE FUNCTION accounts.set_updated_at();


--
-- TOC entry 4870 (class 0 OID 0)
-- Dependencies: 4485
-- Name: TRIGGER trg_set_updated_at_platforms ON platforms; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON TRIGGER trg_set_updated_at_platforms ON accounts.platforms IS 'Atualiza automaticamente o campo updated_at da tabela platforms em updates.';


--
-- TOC entry 4489 (class 2620 OID 17522)
-- Name: role_features trg_set_updated_at_role_features; Type: TRIGGER; Schema: accounts; Owner: postgres
--

CREATE TRIGGER trg_set_updated_at_role_features BEFORE UPDATE ON accounts.role_features FOR EACH ROW EXECUTE FUNCTION accounts.set_updated_at();


--
-- TOC entry 4871 (class 0 OID 0)
-- Dependencies: 4489
-- Name: TRIGGER trg_set_updated_at_role_features ON role_features; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON TRIGGER trg_set_updated_at_role_features ON accounts.role_features IS 'Atualiza automaticamente o campo updated_at da tabela role_features em updates.';


--
-- TOC entry 4488 (class 2620 OID 17521)
-- Name: roles trg_set_updated_at_roles; Type: TRIGGER; Schema: accounts; Owner: postgres
--

CREATE TRIGGER trg_set_updated_at_roles BEFORE UPDATE ON accounts.roles FOR EACH ROW EXECUTE FUNCTION accounts.set_updated_at();


--
-- TOC entry 4872 (class 0 OID 0)
-- Dependencies: 4488
-- Name: TRIGGER trg_set_updated_at_roles ON roles; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON TRIGGER trg_set_updated_at_roles ON accounts.roles IS 'Atualiza automaticamente o campo updated_at da tabela roles em updates.';


--
-- TOC entry 4482 (class 2620 OID 17515)
-- Name: suppliers trg_set_updated_at_suppliers; Type: TRIGGER; Schema: accounts; Owner: postgres
--

CREATE TRIGGER trg_set_updated_at_suppliers BEFORE UPDATE ON accounts.suppliers FOR EACH ROW EXECUTE FUNCTION accounts.set_updated_at();


--
-- TOC entry 4873 (class 0 OID 0)
-- Dependencies: 4482
-- Name: TRIGGER trg_set_updated_at_suppliers ON suppliers; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON TRIGGER trg_set_updated_at_suppliers ON accounts.suppliers IS 'Atualiza automaticamente o campo updated_at da tabela suppliers em updates.';


--
-- TOC entry 4481 (class 2620 OID 17514)
-- Name: users trg_set_updated_at_users; Type: TRIGGER; Schema: accounts; Owner: postgres
--

CREATE TRIGGER trg_set_updated_at_users BEFORE UPDATE ON accounts.users FOR EACH ROW EXECUTE FUNCTION accounts.set_updated_at();


--
-- TOC entry 4874 (class 0 OID 0)
-- Dependencies: 4481
-- Name: TRIGGER trg_set_updated_at_users ON users; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON TRIGGER trg_set_updated_at_users ON accounts.users IS 'Atualiza automaticamente o campo updated_at da tabela users em updates.';


--
-- TOC entry 4464 (class 2606 OID 17706)
-- Name: api_keys api_keys_employee_id_fkey; Type: FK CONSTRAINT; Schema: accounts; Owner: postgres
--

ALTER TABLE ONLY accounts.api_keys
    ADD CONSTRAINT api_keys_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES accounts.employees(employee_id);


--
-- TOC entry 4465 (class 2606 OID 17718)
-- Name: api_scopes api_scopes_api_key_id_fkey; Type: FK CONSTRAINT; Schema: accounts; Owner: postgres
--

ALTER TABLE ONLY accounts.api_scopes
    ADD CONSTRAINT api_scopes_api_key_id_fkey FOREIGN KEY (api_key_id) REFERENCES accounts.api_keys(api_key_id) ON DELETE CASCADE;


--
-- TOC entry 4466 (class 2606 OID 17723)
-- Name: api_scopes api_scopes_feature_id_fkey; Type: FK CONSTRAINT; Schema: accounts; Owner: postgres
--

ALTER TABLE ONLY accounts.api_scopes
    ADD CONSTRAINT api_scopes_feature_id_fkey FOREIGN KEY (feature_id) REFERENCES accounts.features(feature_id) ON DELETE CASCADE;


--
-- TOC entry 4463 (class 2606 OID 17733)
-- Name: apis apis_module_id_fkey; Type: FK CONSTRAINT; Schema: accounts; Owner: postgres
--

ALTER TABLE ONLY accounts.apis
    ADD CONSTRAINT apis_module_id_fkey FOREIGN KEY (module_id) REFERENCES accounts.modules(module_id);


--
-- TOC entry 4461 (class 2606 OID 17405)
-- Name: employee_roles employee_roles_employee_id_fkey; Type: FK CONSTRAINT; Schema: accounts; Owner: postgres
--

ALTER TABLE ONLY accounts.employee_roles
    ADD CONSTRAINT employee_roles_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES accounts.employees(employee_id);


--
-- TOC entry 4462 (class 2606 OID 17410)
-- Name: employee_roles employee_roles_role_id_fkey; Type: FK CONSTRAINT; Schema: accounts; Owner: postgres
--

ALTER TABLE ONLY accounts.employee_roles
    ADD CONSTRAINT employee_roles_role_id_fkey FOREIGN KEY (role_id) REFERENCES accounts.roles(role_id);


--
-- TOC entry 4454 (class 2606 OID 17292)
-- Name: employees employees_establishment_id_fkey; Type: FK CONSTRAINT; Schema: accounts; Owner: postgres
--

ALTER TABLE ONLY accounts.employees
    ADD CONSTRAINT employees_establishment_id_fkey FOREIGN KEY (establishment_id) REFERENCES accounts.establishments(establishment_id);


--
-- TOC entry 4455 (class 2606 OID 17287)
-- Name: employees employees_supplier_id_fkey; Type: FK CONSTRAINT; Schema: accounts; Owner: postgres
--

ALTER TABLE ONLY accounts.employees
    ADD CONSTRAINT employees_supplier_id_fkey FOREIGN KEY (supplier_id) REFERENCES accounts.suppliers(supplier_id);


--
-- TOC entry 4456 (class 2606 OID 17282)
-- Name: employees employees_user_id_fkey; Type: FK CONSTRAINT; Schema: accounts; Owner: postgres
--

ALTER TABLE ONLY accounts.employees
    ADD CONSTRAINT employees_user_id_fkey FOREIGN KEY (user_id) REFERENCES accounts.users(user_id);


--
-- TOC entry 4457 (class 2606 OID 17350)
-- Name: features features_module_id_fkey; Type: FK CONSTRAINT; Schema: accounts; Owner: postgres
--

ALTER TABLE ONLY accounts.features
    ADD CONSTRAINT features_module_id_fkey FOREIGN KEY (module_id) REFERENCES accounts.modules(module_id);


--
-- TOC entry 4458 (class 2606 OID 17728)
-- Name: features features_platform_id_fkey; Type: FK CONSTRAINT; Schema: accounts; Owner: postgres
--

ALTER TABLE ONLY accounts.features
    ADD CONSTRAINT features_platform_id_fkey FOREIGN KEY (platform_id) REFERENCES accounts.platforms(platform_id);


--
-- TOC entry 4459 (class 2606 OID 17388)
-- Name: role_features role_features_feature_id_fkey; Type: FK CONSTRAINT; Schema: accounts; Owner: postgres
--

ALTER TABLE ONLY accounts.role_features
    ADD CONSTRAINT role_features_feature_id_fkey FOREIGN KEY (feature_id) REFERENCES accounts.features(feature_id);


--
-- TOC entry 4460 (class 2606 OID 17383)
-- Name: role_features role_features_role_id_fkey; Type: FK CONSTRAINT; Schema: accounts; Owner: postgres
--

ALTER TABLE ONLY accounts.role_features
    ADD CONSTRAINT role_features_role_id_fkey FOREIGN KEY (role_id) REFERENCES accounts.roles(role_id);


--
-- TOC entry 4468 (class 2606 OID 17950)
-- Name: items items_subcategory_id_fkey; Type: FK CONSTRAINT; Schema: catalogs; Owner: postgres
--

ALTER TABLE ONLY catalogs.items
    ADD CONSTRAINT items_subcategory_id_fkey FOREIGN KEY (subcategory_id) REFERENCES catalogs.subcategories(subcategory_id);


--
-- TOC entry 4479 (class 2606 OID 18121)
-- Name: offers offers_product_id_fkey; Type: FK CONSTRAINT; Schema: catalogs; Owner: postgres
--

ALTER TABLE ONLY catalogs.offers
    ADD CONSTRAINT offers_product_id_fkey FOREIGN KEY (product_id) REFERENCES catalogs.products(product_id);


--
-- TOC entry 4480 (class 2606 OID 18126)
-- Name: offers offers_supplier_id_fkey; Type: FK CONSTRAINT; Schema: catalogs; Owner: postgres
--

ALTER TABLE ONLY catalogs.offers
    ADD CONSTRAINT offers_supplier_id_fkey FOREIGN KEY (supplier_id) REFERENCES accounts.suppliers(supplier_id);


--
-- TOC entry 4469 (class 2606 OID 18098)
-- Name: products products_brand_id_fkey; Type: FK CONSTRAINT; Schema: catalogs; Owner: postgres
--

ALTER TABLE ONLY catalogs.products
    ADD CONSTRAINT products_brand_id_fkey FOREIGN KEY (brand_id) REFERENCES catalogs.brands(brand_id);


--
-- TOC entry 4470 (class 2606 OID 18068)
-- Name: products products_composition_id_fkey; Type: FK CONSTRAINT; Schema: catalogs; Owner: postgres
--

ALTER TABLE ONLY catalogs.products
    ADD CONSTRAINT products_composition_id_fkey FOREIGN KEY (composition_id) REFERENCES catalogs.compositions(composition_id);


--
-- TOC entry 4471 (class 2606 OID 18088)
-- Name: products products_filling_id_fkey; Type: FK CONSTRAINT; Schema: catalogs; Owner: postgres
--

ALTER TABLE ONLY catalogs.products
    ADD CONSTRAINT products_filling_id_fkey FOREIGN KEY (filling_id) REFERENCES catalogs.fillings(filling_id);


--
-- TOC entry 4472 (class 2606 OID 18083)
-- Name: products products_flavor_id_fkey; Type: FK CONSTRAINT; Schema: catalogs; Owner: postgres
--

ALTER TABLE ONLY catalogs.products
    ADD CONSTRAINT products_flavor_id_fkey FOREIGN KEY (flavor_id) REFERENCES catalogs.flavors(flavor_id);


--
-- TOC entry 4473 (class 2606 OID 18078)
-- Name: products products_format_id_fkey; Type: FK CONSTRAINT; Schema: catalogs; Owner: postgres
--

ALTER TABLE ONLY catalogs.products
    ADD CONSTRAINT products_format_id_fkey FOREIGN KEY (format_id) REFERENCES catalogs.formats(format_id);


--
-- TOC entry 4474 (class 2606 OID 18063)
-- Name: products products_item_id_fkey; Type: FK CONSTRAINT; Schema: catalogs; Owner: postgres
--

ALTER TABLE ONLY catalogs.products
    ADD CONSTRAINT products_item_id_fkey FOREIGN KEY (item_id) REFERENCES catalogs.items(item_id);


--
-- TOC entry 4475 (class 2606 OID 18093)
-- Name: products products_nutritional_variant_id_fkey; Type: FK CONSTRAINT; Schema: catalogs; Owner: postgres
--

ALTER TABLE ONLY catalogs.products
    ADD CONSTRAINT products_nutritional_variant_id_fkey FOREIGN KEY (nutritional_variant_id) REFERENCES catalogs.nutritional_variants(nutritional_variant_id);


--
-- TOC entry 4476 (class 2606 OID 18103)
-- Name: products products_packaging_id_fkey; Type: FK CONSTRAINT; Schema: catalogs; Owner: postgres
--

ALTER TABLE ONLY catalogs.products
    ADD CONSTRAINT products_packaging_id_fkey FOREIGN KEY (packaging_id) REFERENCES catalogs.packagings(packaging_id);


--
-- TOC entry 4477 (class 2606 OID 18108)
-- Name: products products_quantity_id_fkey; Type: FK CONSTRAINT; Schema: catalogs; Owner: postgres
--

ALTER TABLE ONLY catalogs.products
    ADD CONSTRAINT products_quantity_id_fkey FOREIGN KEY (quantity_id) REFERENCES catalogs.quantities(quantity_id);


--
-- TOC entry 4478 (class 2606 OID 18073)
-- Name: products products_variant_type_id_fkey; Type: FK CONSTRAINT; Schema: catalogs; Owner: postgres
--

ALTER TABLE ONLY catalogs.products
    ADD CONSTRAINT products_variant_type_id_fkey FOREIGN KEY (variant_type_id) REFERENCES catalogs.variant_types(variant_type_id);


--
-- TOC entry 4467 (class 2606 OID 17936)
-- Name: subcategories subcategories_category_id_fkey; Type: FK CONSTRAINT; Schema: catalogs; Owner: postgres
--

ALTER TABLE ONLY catalogs.subcategories
    ADD CONSTRAINT subcategories_category_id_fkey FOREIGN KEY (category_id) REFERENCES catalogs.categories(category_id);


-- Completed on 2025-08-14 11:09:58 -03

--
-- PostgreSQL database dump complete
--

