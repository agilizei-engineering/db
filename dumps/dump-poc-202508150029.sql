--
-- PostgreSQL database dump
--

-- Dumped from database version 17.4
-- Dumped by pg_dump version 17.5 (Homebrew)

-- Started on 2025-08-15 00:29:14 -03

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
-- TOC entry 8 (class 2615 OID 17223)
-- Name: accounts; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA accounts;


ALTER SCHEMA accounts OWNER TO postgres;

--
-- TOC entry 11 (class 2615 OID 18382)
-- Name: audit; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA audit;


ALTER SCHEMA audit OWNER TO postgres;

--
-- TOC entry 6563 (class 0 OID 0)
-- Dependencies: 11
-- Name: SCHEMA audit; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON SCHEMA audit IS 'Schema para armazenar histórico de auditoria de todas as tabelas do sistema';


--
-- TOC entry 13 (class 2615 OID 21829)
-- Name: aux; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA aux;


ALTER SCHEMA aux OWNER TO postgres;

--
-- TOC entry 6564 (class 0 OID 0)
-- Dependencies: 13
-- Name: SCHEMA aux; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON SCHEMA aux IS 'Schema auxiliar com funções e validações compartilhadas entre todos os schemas';


--
-- TOC entry 10 (class 2615 OID 17915)
-- Name: catalogs; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA catalogs;


ALTER SCHEMA catalogs OWNER TO postgres;

--
-- TOC entry 12 (class 2615 OID 21329)
-- Name: quotation; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA quotation;


ALTER SCHEMA quotation OWNER TO postgres;

--
-- TOC entry 1482 (class 1247 OID 21981)
-- Name: estado_brasileiro; Type: DOMAIN; Schema: aux; Owner: postgres
--

CREATE DOMAIN aux.estado_brasileiro AS character varying(2)
	CONSTRAINT estado_brasileiro_check CHECK (((VALUE)::text = ANY ((ARRAY['AC'::character varying, 'AL'::character varying, 'AP'::character varying, 'AM'::character varying, 'BA'::character varying, 'CE'::character varying, 'DF'::character varying, 'ES'::character varying, 'GO'::character varying, 'MA'::character varying, 'MT'::character varying, 'MS'::character varying, 'MG'::character varying, 'PA'::character varying, 'PB'::character varying, 'PR'::character varying, 'PE'::character varying, 'PI'::character varying, 'RJ'::character varying, 'RN'::character varying, 'RS'::character varying, 'RO'::character varying, 'RR'::character varying, 'SC'::character varying, 'SP'::character varying, 'SE'::character varying, 'TO'::character varying])::text[])));


ALTER DOMAIN aux.estado_brasileiro OWNER TO postgres;

--
-- TOC entry 1486 (class 1247 OID 21984)
-- Name: genero; Type: DOMAIN; Schema: aux; Owner: postgres
--

CREATE DOMAIN aux.genero AS character varying(1)
	CONSTRAINT genero_check CHECK (((VALUE)::text = ANY ((ARRAY['M'::character varying, 'F'::character varying, 'O'::character varying])::text[])));


ALTER DOMAIN aux.genero OWNER TO postgres;

--
-- TOC entry 1490 (class 1247 OID 21987)
-- Name: moeda; Type: DOMAIN; Schema: aux; Owner: postgres
--

CREATE DOMAIN aux.moeda AS character varying(3)
	CONSTRAINT moeda_check CHECK (((VALUE)::text = ANY ((ARRAY['BRL'::character varying, 'USD'::character varying, 'EUR'::character varying, 'GBP'::character varying])::text[])));


ALTER DOMAIN aux.moeda OWNER TO postgres;

--
-- TOC entry 463 (class 1255 OID 21876)
-- Name: find_employee_by_cpf(text); Type: FUNCTION; Schema: accounts; Owner: postgres
--

CREATE FUNCTION accounts.find_employee_by_cpf(p_cpf text) RETURNS TABLE(employee_id uuid, user_id uuid, email text, full_name text, cpf text, birth_date date, gender text, photo_url text, postal_code text, street text, number text, complement text, neighborhood text, city text, state text, is_primary boolean)
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Limpar CPF de entrada usando schema aux
    p_cpf := aux.clean_and_validate_cpf(p_cpf);
    
    RETURN QUERY
    SELECT 
        e.employee_id,
        e.user_id,
        u.email,
        epd.full_name,
        epd.cpf,
        epd.birth_date,
        epd.gender,
        epd.photo_url,
        ea.postal_code,
        ea.street,
        ea.number,
        ea.complement,
        ea.neighborhood,
        ea.city,
        ea.state,
        ea.is_primary
    FROM accounts.employees e
    JOIN accounts.users u ON e.user_id = u.user_id
    JOIN accounts.employee_personal_data epd ON e.employee_id = epd.employee_id
    LEFT JOIN accounts.employee_addresses ea ON e.employee_id = ea.employee_id AND ea.is_primary = true
    WHERE epd.cpf = p_cpf;
END;
$$;


ALTER FUNCTION accounts.find_employee_by_cpf(p_cpf text) OWNER TO postgres;

--
-- TOC entry 6565 (class 0 OID 0)
-- Dependencies: 463
-- Name: FUNCTION find_employee_by_cpf(p_cpf text); Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON FUNCTION accounts.find_employee_by_cpf(p_cpf text) IS 'Busca funcionário por CPF usando validação do schema aux';


--
-- TOC entry 407 (class 1255 OID 21251)
-- Name: find_employees_by_postal_code(text); Type: FUNCTION; Schema: accounts; Owner: postgres
--

CREATE FUNCTION accounts.find_employees_by_postal_code(postal_code text) RETURNS TABLE(employee_id uuid, user_id uuid, email text, full_name text, cpf text, street text, number text, neighborhood text, city text, state text)
    LANGUAGE plpgsql
    AS $$
DECLARE
    cleaned_postal_code text;
BEGIN
    -- Limpa o CEP
    cleaned_postal_code := regexp_replace(postal_code, '[^0-9]', '', 'g');
    
    RETURN QUERY
    SELECT 
        e.employee_id,
        e.user_id,
        u.email,
        epd.full_name,
        epd.cpf,
        ea.street,
        ea.number,
        ea.neighborhood,
        ea.city,
        ea.state
    FROM accounts.employees e
    JOIN accounts.users u ON e.user_id = u.user_id
    JOIN accounts.employee_personal_data epd ON e.employee_id = epd.employee_id
    JOIN accounts.employee_addresses ea ON e.employee_id = ea.employee_id
    WHERE ea.postal_code = cleaned_postal_code;
END;
$$;


ALTER FUNCTION accounts.find_employees_by_postal_code(postal_code text) OWNER TO postgres;

--
-- TOC entry 6566 (class 0 OID 0)
-- Dependencies: 407
-- Name: FUNCTION find_employees_by_postal_code(postal_code text); Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON FUNCTION accounts.find_employees_by_postal_code(postal_code text) IS 'Busca funcionários por CEP';


--
-- TOC entry 448 (class 1255 OID 21992)
-- Name: find_establishments_by_postal_code(text); Type: FUNCTION; Schema: accounts; Owner: postgres
--

CREATE FUNCTION accounts.find_establishments_by_postal_code(p_postal_code text) RETURNS TABLE(establishment_id uuid, establishment_name text, cnpj text, trade_name text, corporate_name text, state_registration text, postal_code text, street text, number text, complement text, neighborhood text, city text, state text)
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Limpar CEP de entrada usando schema aux
    p_postal_code := aux.clean_and_validate_postal_code(p_postal_code);
    
    RETURN QUERY
    SELECT 
        e.establishment_id,
        e.name,
        ebd.cnpj,
        ebd.trade_name,
        ebd.corporate_name,
        ebd.state_registration,
        ea.postal_code,
        ea.street,
        ea.number,
        ea.complement,
        ea.neighborhood,
        ea.city,
        ea.state
    FROM accounts.establishments e
    JOIN accounts.establishment_business_data ebd ON e.establishment_id = ebd.establishment_id
    JOIN accounts.establishment_addresses ea ON e.establishment_id = ea.establishment_id
    WHERE ea.postal_code = p_postal_code;
END;
$$;


ALTER FUNCTION accounts.find_establishments_by_postal_code(p_postal_code text) OWNER TO postgres;

--
-- TOC entry 6567 (class 0 OID 0)
-- Dependencies: 448
-- Name: FUNCTION find_establishments_by_postal_code(p_postal_code text); Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON FUNCTION accounts.find_establishments_by_postal_code(p_postal_code text) IS 'Busca estabelecimentos por CEP usando validacao do schema aux';


--
-- TOC entry 432 (class 1255 OID 21250)
-- Name: search_employees_by_name(text); Type: FUNCTION; Schema: accounts; Owner: postgres
--

CREATE FUNCTION accounts.search_employees_by_name(search_term text) RETURNS TABLE(employee_id uuid, user_id uuid, email text, full_name text, cpf text, birth_date date, gender text, city text, state text, similarity_score real)
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Verifica se a extensão pg_trgm está disponível
    IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_trgm') THEN
        -- Busca com trigram se disponível
        RETURN QUERY
        SELECT 
            e.employee_id,
            e.user_id,
            u.email,
            epd.full_name,
            epd.cpf,
            epd.birth_date,
            epd.gender,
            ea.city,
            ea.state,
            similarity(epd.full_name, search_term) as similarity_score
        FROM accounts.employees e
        JOIN accounts.users u ON e.user_id = u.user_id
        JOIN accounts.employee_personal_data epd ON e.employee_id = epd.employee_id
        LEFT JOIN accounts.employee_addresses ea ON e.employee_id = ea.employee_id AND ea.is_primary = true
        WHERE epd.full_name % search_term
        ORDER BY similarity_score DESC;
    ELSE
        -- Busca simples com ILIKE se trigram não estiver disponível
        RETURN QUERY
        SELECT 
            e.employee_id,
            e.user_id,
            u.email,
            epd.full_name,
            epd.cpf,
            epd.birth_date,
            epd.gender,
            ea.city,
            ea.state,
            CASE 
                WHEN epd.full_name ILIKE '%' || search_term || '%' THEN 1.0
                WHEN epd.full_name ILIKE search_term || '%' THEN 0.8
                WHEN epd.full_name ILIKE '%' || search_term THEN 0.6
                ELSE 0.0
            END as similarity_score
        FROM accounts.employees e
        JOIN accounts.users u ON e.user_id = u.user_id
        JOIN accounts.employee_personal_data epd ON e.employee_id = epd.employee_id
        LEFT JOIN accounts.employee_addresses ea ON e.employee_id = ea.employee_id AND ea.is_primary = true
        WHERE epd.full_name ILIKE '%' || search_term || '%'
        ORDER BY similarity_score DESC;
    END IF;
END;
$$;


ALTER FUNCTION accounts.search_employees_by_name(search_term text) OWNER TO postgres;

--
-- TOC entry 6568 (class 0 OID 0)
-- Dependencies: 432
-- Name: FUNCTION search_employees_by_name(search_term text); Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON FUNCTION accounts.search_employees_by_name(search_term text) IS 'Busca fuzzy de funcionários por nome';


--
-- TOC entry 469 (class 1255 OID 20098)
-- Name: audit_accounts_api_keys_trigger(); Type: FUNCTION; Schema: audit; Owner: postgres
--

CREATE FUNCTION audit.audit_accounts_api_keys_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN  IF TG_OP = 'INSERT' THEN    INSERT INTO audit.accounts__api_keys (api_key_id, employee_id, name, secret, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (NEW.api_key_id, NEW.employee_id, NEW.name, NEW.secret, NEW.created_at, NEW.updated_at, 'INSERT', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN NEW;  ELSIF TG_OP = 'UPDATE' THEN    INSERT INTO audit.accounts__api_keys (api_key_id, employee_id, name, secret, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (NEW.api_key_id, NEW.employee_id, NEW.name, NEW.secret, NEW.created_at, NEW.updated_at, 'UPDATE', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN NEW;  ELSIF TG_OP = 'DELETE' THEN    INSERT INTO audit.accounts__api_keys (api_key_id, employee_id, name, secret, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (OLD.api_key_id, OLD.employee_id, OLD.name, OLD.secret, OLD.created_at, OLD.updated_at, 'DELETE', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN OLD;  END IF;  RETURN NULL;END;$$;


ALTER FUNCTION audit.audit_accounts_api_keys_trigger() OWNER TO postgres;

--
-- TOC entry 440 (class 1255 OID 20132)
-- Name: audit_accounts_api_scopes_trigger(); Type: FUNCTION; Schema: audit; Owner: postgres
--

CREATE FUNCTION audit.audit_accounts_api_scopes_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN  IF TG_OP = 'INSERT' THEN    INSERT INTO audit.accounts__api_scopes (api_scope_id, api_key_id, feature_id, created_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (NEW.api_scope_id, NEW.api_key_id, NEW.feature_id, NEW.created_at, 'INSERT', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN NEW;  ELSIF TG_OP = 'UPDATE' THEN    INSERT INTO audit.accounts__api_scopes (api_scope_id, api_key_id, feature_id, created_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (NEW.api_scope_id, NEW.api_key_id, NEW.feature_id, NEW.created_at, 'UPDATE', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN NEW;  ELSIF TG_OP = 'DELETE' THEN    INSERT INTO audit.accounts__api_scopes (api_scope_id, api_key_id, feature_id, created_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (OLD.api_scope_id, OLD.api_key_id, OLD.feature_id, OLD.created_at, 'DELETE', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN OLD;  END IF;  RETURN NULL;END;$$;


ALTER FUNCTION audit.audit_accounts_api_scopes_trigger() OWNER TO postgres;

--
-- TOC entry 484 (class 1255 OID 20166)
-- Name: audit_accounts_apis_trigger(); Type: FUNCTION; Schema: audit; Owner: postgres
--

CREATE FUNCTION audit.audit_accounts_apis_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN  IF TG_OP = 'INSERT' THEN    INSERT INTO audit.accounts__apis (api_id, path, method, description, created_at, updated_at, module_id, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (NEW.api_id, NEW.path, NEW.method, NEW.description, NEW.created_at, NEW.updated_at, NEW.module_id, 'INSERT', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN NEW;  ELSIF TG_OP = 'UPDATE' THEN    INSERT INTO audit.accounts__apis (api_id, path, method, description, created_at, updated_at, module_id, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (NEW.api_id, NEW.path, NEW.method, NEW.description, NEW.created_at, NEW.updated_at, NEW.module_id, 'UPDATE', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN NEW;  ELSIF TG_OP = 'DELETE' THEN    INSERT INTO audit.accounts__apis (api_id, path, method, description, created_at, updated_at, module_id, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (OLD.api_id, OLD.path, OLD.method, OLD.description, OLD.created_at, OLD.updated_at, OLD.module_id, 'DELETE', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN OLD;  END IF;  RETURN NULL;END;$$;


ALTER FUNCTION audit.audit_accounts_apis_trigger() OWNER TO postgres;

--
-- TOC entry 404 (class 1255 OID 21300)
-- Name: audit_accounts_employee_addresses_trigger(); Type: FUNCTION; Schema: audit; Owner: postgres
--

CREATE FUNCTION audit.audit_accounts_employee_addresses_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN  IF TG_OP = 'INSERT' THEN    INSERT INTO audit.accounts__employee_addresses (employee_address_id, employee_id, postal_code, street, number, complement, neighborhood, city, state, is_primary, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (NEW.employee_address_id, NEW.employee_id, NEW.postal_code, NEW.street, NEW.number, NEW.complement, NEW.neighborhood, NEW.city, NEW.state, NEW.is_primary, NEW.created_at, NEW.updated_at, 'INSERT', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN NEW;  ELSIF TG_OP = 'UPDATE' THEN    INSERT INTO audit.accounts__employee_addresses (employee_address_id, employee_id, postal_code, street, number, complement, neighborhood, city, state, is_primary, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (NEW.employee_address_id, NEW.employee_id, NEW.postal_code, NEW.street, NEW.number, NEW.complement, NEW.neighborhood, NEW.city, NEW.state, NEW.is_primary, NEW.created_at, NEW.updated_at, 'UPDATE', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN NEW;  ELSIF TG_OP = 'DELETE' THEN    INSERT INTO audit.accounts__employee_addresses (employee_address_id, employee_id, postal_code, street, number, complement, neighborhood, city, state, is_primary, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (OLD.employee_address_id, OLD.employee_id, OLD.postal_code, OLD.street, OLD.number, OLD.complement, OLD.neighborhood, OLD.city, OLD.state, OLD.is_primary, OLD.created_at, OLD.updated_at, 'DELETE', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN OLD;  END IF;  RETURN NULL;END;$$;


ALTER FUNCTION audit.audit_accounts_employee_addresses_trigger() OWNER TO postgres;

--
-- TOC entry 471 (class 1255 OID 21267)
-- Name: audit_accounts_employee_personal_data_trigger(); Type: FUNCTION; Schema: audit; Owner: postgres
--

CREATE FUNCTION audit.audit_accounts_employee_personal_data_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN  IF TG_OP = 'INSERT' THEN    INSERT INTO audit.accounts__employee_personal_data (employee_personal_data_id, employee_id, cpf, full_name, birth_date, gender, photo_url, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (NEW.employee_personal_data_id, NEW.employee_id, NEW.cpf, NEW.full_name, NEW.birth_date, NEW.gender, NEW.photo_url, NEW.created_at, NEW.updated_at, 'INSERT', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN NEW;  ELSIF TG_OP = 'UPDATE' THEN    INSERT INTO audit.accounts__employee_personal_data (employee_personal_data_id, employee_id, cpf, full_name, birth_date, gender, photo_url, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (NEW.employee_personal_data_id, NEW.employee_id, NEW.cpf, NEW.full_name, NEW.birth_date, NEW.gender, NEW.photo_url, NEW.created_at, NEW.updated_at, 'UPDATE', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN NEW;  ELSIF TG_OP = 'DELETE' THEN    INSERT INTO audit.accounts__employee_personal_data (employee_personal_data_id, employee_id, cpf, full_name, birth_date, gender, photo_url, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (OLD.employee_personal_data_id, OLD.employee_id, OLD.cpf, OLD.full_name, OLD.birth_date, OLD.gender, OLD.photo_url, OLD.created_at, OLD.updated_at, 'DELETE', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN OLD;  END IF;  RETURN NULL;END;$$;


ALTER FUNCTION audit.audit_accounts_employee_personal_data_trigger() OWNER TO postgres;

--
-- TOC entry 496 (class 1255 OID 20200)
-- Name: audit_accounts_employee_roles_trigger(); Type: FUNCTION; Schema: audit; Owner: postgres
--

CREATE FUNCTION audit.audit_accounts_employee_roles_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN  IF TG_OP = 'INSERT' THEN    INSERT INTO audit.accounts__employee_roles (employee_role_id, employee_id, role_id, granted_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (NEW.employee_role_id, NEW.employee_id, NEW.role_id, NEW.granted_at, NEW.updated_at, 'INSERT', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN NEW;  ELSIF TG_OP = 'UPDATE' THEN    INSERT INTO audit.accounts__employee_roles (employee_role_id, employee_id, role_id, granted_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (NEW.employee_role_id, NEW.employee_id, NEW.role_id, NEW.granted_at, NEW.updated_at, 'UPDATE', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN NEW;  ELSIF TG_OP = 'DELETE' THEN    INSERT INTO audit.accounts__employee_roles (employee_role_id, employee_id, role_id, granted_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (OLD.employee_role_id, OLD.employee_id, OLD.role_id, OLD.granted_at, OLD.updated_at, 'DELETE', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN OLD;  END IF;  RETURN NULL;END;$$;


ALTER FUNCTION audit.audit_accounts_employee_roles_trigger() OWNER TO postgres;

--
-- TOC entry 493 (class 1255 OID 20236)
-- Name: audit_accounts_employees_trigger(); Type: FUNCTION; Schema: audit; Owner: postgres
--

CREATE FUNCTION audit.audit_accounts_employees_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN  IF TG_OP = 'INSERT' THEN    INSERT INTO audit.accounts__employees (employee_id, user_id, supplier_id, establishment_id, is_active, activated_at, deactivated_at, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (NEW.employee_id, NEW.user_id, NEW.supplier_id, NEW.establishment_id, NEW.is_active, NEW.activated_at, NEW.deactivated_at, NEW.created_at, NEW.updated_at, 'INSERT', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN NEW;  ELSIF TG_OP = 'UPDATE' THEN    INSERT INTO audit.accounts__employees (employee_id, user_id, supplier_id, establishment_id, is_active, activated_at, deactivated_at, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (NEW.employee_id, NEW.user_id, NEW.supplier_id, NEW.establishment_id, NEW.is_active, NEW.activated_at, NEW.deactivated_at, NEW.created_at, NEW.updated_at, 'UPDATE', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN NEW;  ELSIF TG_OP = 'DELETE' THEN    INSERT INTO audit.accounts__employees (employee_id, user_id, supplier_id, establishment_id, is_active, activated_at, deactivated_at, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (OLD.employee_id, OLD.user_id, OLD.supplier_id, OLD.establishment_id, OLD.is_active, OLD.activated_at, OLD.deactivated_at, OLD.created_at, OLD.updated_at, 'DELETE', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN OLD;  END IF;  RETURN NULL;END;$$;


ALTER FUNCTION audit.audit_accounts_employees_trigger() OWNER TO postgres;

--
-- TOC entry 428 (class 1255 OID 20271)
-- Name: audit_accounts_establishment_addresses_trigger(); Type: FUNCTION; Schema: audit; Owner: postgres
--

CREATE FUNCTION audit.audit_accounts_establishment_addresses_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN  IF TG_OP = 'INSERT' THEN    INSERT INTO audit.accounts__establishment_addresses (establishment_address_id, establishment_id, postal_code, street, number, complement, neighborhood, city, state, is_primary, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (NEW.establishment_address_id, NEW.establishment_id, NEW.postal_code, NEW.street, NEW.number, NEW.complement, NEW.neighborhood, NEW.city, NEW.state, NEW.is_primary, NEW.created_at, NEW.updated_at, 'INSERT', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN NEW;  ELSIF TG_OP = 'UPDATE' THEN    INSERT INTO audit.accounts__establishment_addresses (establishment_address_id, establishment_id, postal_code, street, number, complement, neighborhood, city, state, is_primary, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (NEW.establishment_address_id, NEW.establishment_id, NEW.postal_code, NEW.street, NEW.number, NEW.complement, NEW.neighborhood, NEW.city, NEW.state, NEW.is_primary, NEW.created_at, NEW.updated_at, 'UPDATE', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN NEW;  ELSIF TG_OP = 'DELETE' THEN    INSERT INTO audit.accounts__establishment_addresses (establishment_address_id, establishment_id, postal_code, street, number, complement, neighborhood, city, state, is_primary, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (OLD.establishment_address_id, OLD.establishment_id, OLD.postal_code, OLD.street, OLD.number, OLD.complement, OLD.neighborhood, OLD.city, OLD.state, OLD.is_primary, OLD.created_at, OLD.updated_at, 'DELETE', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN OLD;  END IF;  RETURN NULL;END;$$;


ALTER FUNCTION audit.audit_accounts_establishment_addresses_trigger() OWNER TO postgres;

--
-- TOC entry 455 (class 1255 OID 20304)
-- Name: audit_accounts_establishment_business_data_trigger(); Type: FUNCTION; Schema: audit; Owner: postgres
--

CREATE FUNCTION audit.audit_accounts_establishment_business_data_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN  IF TG_OP = 'INSERT' THEN    INSERT INTO audit.accounts__establishment_business_data (establishment_business_data_id, establishment_id, cnpj, trade_name, corporate_name, state_registration, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (NEW.establishment_business_data_id, NEW.establishment_id, NEW.cnpj, NEW.trade_name, NEW.corporate_name, NEW.state_registration, NEW.created_at, NEW.updated_at, 'INSERT', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN NEW;  ELSIF TG_OP = 'UPDATE' THEN    INSERT INTO audit.accounts__establishment_business_data (establishment_business_data_id, establishment_id, cnpj, trade_name, corporate_name, state_registration, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (NEW.establishment_business_data_id, NEW.establishment_id, NEW.cnpj, NEW.trade_name, NEW.corporate_name, NEW.state_registration, NEW.created_at, NEW.updated_at, 'UPDATE', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN NEW;  ELSIF TG_OP = 'DELETE' THEN    INSERT INTO audit.accounts__establishment_business_data (establishment_business_data_id, establishment_id, cnpj, trade_name, corporate_name, state_registration, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (OLD.establishment_business_data_id, OLD.establishment_id, OLD.cnpj, OLD.trade_name, OLD.corporate_name, OLD.state_registration, OLD.created_at, OLD.updated_at, 'DELETE', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN OLD;  END IF;  RETURN NULL;END;$$;


ALTER FUNCTION audit.audit_accounts_establishment_business_data_trigger() OWNER TO postgres;

--
-- TOC entry 497 (class 1255 OID 20336)
-- Name: audit_accounts_establishments_trigger(); Type: FUNCTION; Schema: audit; Owner: postgres
--

CREATE FUNCTION audit.audit_accounts_establishments_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN  IF TG_OP = 'INSERT' THEN    INSERT INTO audit.accounts__establishments (establishment_id, name, is_active, activated_at, deactivated_at, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (NEW.establishment_id, NEW.name, NEW.is_active, NEW.activated_at, NEW.deactivated_at, NEW.created_at, NEW.updated_at, 'INSERT', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN NEW;  ELSIF TG_OP = 'UPDATE' THEN    INSERT INTO audit.accounts__establishments (establishment_id, name, is_active, activated_at, deactivated_at, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (NEW.establishment_id, NEW.name, NEW.is_active, NEW.activated_at, NEW.deactivated_at, NEW.created_at, NEW.updated_at, 'UPDATE', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN NEW;  ELSIF TG_OP = 'DELETE' THEN    INSERT INTO audit.accounts__establishments (establishment_id, name, is_active, activated_at, deactivated_at, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (OLD.establishment_id, OLD.name, OLD.is_active, OLD.activated_at, OLD.deactivated_at, OLD.created_at, OLD.updated_at, 'DELETE', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN OLD;  END IF;  RETURN NULL;END;$$;


ALTER FUNCTION audit.audit_accounts_establishments_trigger() OWNER TO postgres;

--
-- TOC entry 437 (class 1255 OID 20369)
-- Name: audit_accounts_features_trigger(); Type: FUNCTION; Schema: audit; Owner: postgres
--

CREATE FUNCTION audit.audit_accounts_features_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN  IF TG_OP = 'INSERT' THEN    INSERT INTO audit.accounts__features (feature_id, module_id, name, code, description, created_at, updated_at, platform_id, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (NEW.feature_id, NEW.module_id, NEW.name, NEW.code, NEW.description, NEW.created_at, NEW.updated_at, NEW.platform_id, 'INSERT', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN NEW;  ELSIF TG_OP = 'UPDATE' THEN    INSERT INTO audit.accounts__features (feature_id, module_id, name, code, description, created_at, updated_at, platform_id, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (NEW.feature_id, NEW.module_id, NEW.name, NEW.code, NEW.description, NEW.created_at, NEW.updated_at, NEW.platform_id, 'UPDATE', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN NEW;  ELSIF TG_OP = 'DELETE' THEN    INSERT INTO audit.accounts__features (feature_id, module_id, name, code, description, created_at, updated_at, platform_id, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (OLD.feature_id, OLD.module_id, OLD.name, OLD.code, OLD.description, OLD.created_at, OLD.updated_at, OLD.platform_id, 'DELETE', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN OLD;  END IF;  RETURN NULL;END;$$;


ALTER FUNCTION audit.audit_accounts_features_trigger() OWNER TO postgres;

--
-- TOC entry 475 (class 1255 OID 20402)
-- Name: audit_accounts_modules_trigger(); Type: FUNCTION; Schema: audit; Owner: postgres
--

CREATE FUNCTION audit.audit_accounts_modules_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN  IF TG_OP = 'INSERT' THEN    INSERT INTO audit.accounts__modules (module_id, name, description, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (NEW.module_id, NEW.name, NEW.description, NEW.created_at, NEW.updated_at, 'INSERT', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN NEW;  ELSIF TG_OP = 'UPDATE' THEN    INSERT INTO audit.accounts__modules (module_id, name, description, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (NEW.module_id, NEW.name, NEW.description, NEW.created_at, NEW.updated_at, 'UPDATE', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN NEW;  ELSIF TG_OP = 'DELETE' THEN    INSERT INTO audit.accounts__modules (module_id, name, description, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (OLD.module_id, OLD.name, OLD.description, OLD.created_at, OLD.updated_at, 'DELETE', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN OLD;  END IF;  RETURN NULL;END;$$;


ALTER FUNCTION audit.audit_accounts_modules_trigger() OWNER TO postgres;

--
-- TOC entry 458 (class 1255 OID 20433)
-- Name: audit_accounts_platforms_trigger(); Type: FUNCTION; Schema: audit; Owner: postgres
--

CREATE FUNCTION audit.audit_accounts_platforms_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN  IF TG_OP = 'INSERT' THEN    INSERT INTO audit.accounts__platforms (platform_id, name, description, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (NEW.platform_id, NEW.name, NEW.description, NEW.created_at, NEW.updated_at, 'INSERT', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN NEW;  ELSIF TG_OP = 'UPDATE' THEN    INSERT INTO audit.accounts__platforms (platform_id, name, description, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (NEW.platform_id, NEW.name, NEW.description, NEW.created_at, NEW.updated_at, 'UPDATE', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN NEW;  ELSIF TG_OP = 'DELETE' THEN    INSERT INTO audit.accounts__platforms (platform_id, name, description, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (OLD.platform_id, OLD.name, OLD.description, OLD.created_at, OLD.updated_at, 'DELETE', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN OLD;  END IF;  RETURN NULL;END;$$;


ALTER FUNCTION audit.audit_accounts_platforms_trigger() OWNER TO postgres;

--
-- TOC entry 498 (class 1255 OID 20466)
-- Name: audit_accounts_role_features_trigger(); Type: FUNCTION; Schema: audit; Owner: postgres
--

CREATE FUNCTION audit.audit_accounts_role_features_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN  IF TG_OP = 'INSERT' THEN    INSERT INTO audit.accounts__role_features (role_feature_id, role_id, feature_id, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (NEW.role_feature_id, NEW.role_id, NEW.feature_id, NEW.created_at, NEW.updated_at, 'INSERT', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN NEW;  ELSIF TG_OP = 'UPDATE' THEN    INSERT INTO audit.accounts__role_features (role_feature_id, role_id, feature_id, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (NEW.role_feature_id, NEW.role_id, NEW.feature_id, NEW.created_at, NEW.updated_at, 'UPDATE', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN NEW;  ELSIF TG_OP = 'DELETE' THEN    INSERT INTO audit.accounts__role_features (role_feature_id, role_id, feature_id, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (OLD.role_feature_id, OLD.role_id, OLD.feature_id, OLD.created_at, OLD.updated_at, 'DELETE', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN OLD;  END IF;  RETURN NULL;END;$$;


ALTER FUNCTION audit.audit_accounts_role_features_trigger() OWNER TO postgres;

--
-- TOC entry 477 (class 1255 OID 20499)
-- Name: audit_accounts_roles_trigger(); Type: FUNCTION; Schema: audit; Owner: postgres
--

CREATE FUNCTION audit.audit_accounts_roles_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN  IF TG_OP = 'INSERT' THEN    INSERT INTO audit.accounts__roles (role_id, name, description, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (NEW.role_id, NEW.name, NEW.description, NEW.created_at, NEW.updated_at, 'INSERT', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN NEW;  ELSIF TG_OP = 'UPDATE' THEN    INSERT INTO audit.accounts__roles (role_id, name, description, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (NEW.role_id, NEW.name, NEW.description, NEW.created_at, NEW.updated_at, 'UPDATE', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN NEW;  ELSIF TG_OP = 'DELETE' THEN    INSERT INTO audit.accounts__roles (role_id, name, description, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (OLD.role_id, OLD.name, OLD.description, OLD.created_at, OLD.updated_at, 'DELETE', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN OLD;  END IF;  RETURN NULL;END;$$;


ALTER FUNCTION audit.audit_accounts_roles_trigger() OWNER TO postgres;

--
-- TOC entry 464 (class 1255 OID 20530)
-- Name: audit_accounts_suppliers_trigger(); Type: FUNCTION; Schema: audit; Owner: postgres
--

CREATE FUNCTION audit.audit_accounts_suppliers_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN  IF TG_OP = 'INSERT' THEN    INSERT INTO audit.accounts__suppliers (supplier_id, name, is_active, activated_at, deactivated_at, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (NEW.supplier_id, NEW.name, NEW.is_active, NEW.activated_at, NEW.deactivated_at, NEW.created_at, NEW.updated_at, 'INSERT', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN NEW;  ELSIF TG_OP = 'UPDATE' THEN    INSERT INTO audit.accounts__suppliers (supplier_id, name, is_active, activated_at, deactivated_at, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (NEW.supplier_id, NEW.name, NEW.is_active, NEW.activated_at, NEW.deactivated_at, NEW.created_at, NEW.updated_at, 'UPDATE', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN NEW;  ELSIF TG_OP = 'DELETE' THEN    INSERT INTO audit.accounts__suppliers (supplier_id, name, is_active, activated_at, deactivated_at, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (OLD.supplier_id, OLD.name, OLD.is_active, OLD.activated_at, OLD.deactivated_at, OLD.created_at, OLD.updated_at, 'DELETE', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN OLD;  END IF;  RETURN NULL;END;$$;


ALTER FUNCTION audit.audit_accounts_suppliers_trigger() OWNER TO postgres;

--
-- TOC entry 468 (class 1255 OID 20561)
-- Name: audit_accounts_users_trigger(); Type: FUNCTION; Schema: audit; Owner: postgres
--

CREATE FUNCTION audit.audit_accounts_users_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN  IF TG_OP = 'INSERT' THEN    INSERT INTO audit.accounts__users (user_id, email, full_name, cognito_sub, is_active, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (NEW.user_id, NEW.email, NEW.full_name, NEW.cognito_sub, NEW.is_active, NEW.created_at, NEW.updated_at, 'INSERT', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN NEW;  ELSIF TG_OP = 'UPDATE' THEN    INSERT INTO audit.accounts__users (user_id, email, full_name, cognito_sub, is_active, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (NEW.user_id, NEW.email, NEW.full_name, NEW.cognito_sub, NEW.is_active, NEW.created_at, NEW.updated_at, 'UPDATE', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN NEW;  ELSIF TG_OP = 'DELETE' THEN    INSERT INTO audit.accounts__users (user_id, email, full_name, cognito_sub, is_active, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (OLD.user_id, OLD.email, OLD.full_name, OLD.cognito_sub, OLD.is_active, OLD.created_at, OLD.updated_at, 'DELETE', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN OLD;  END IF;  RETURN NULL;END;$$;


ALTER FUNCTION audit.audit_accounts_users_trigger() OWNER TO postgres;

--
-- TOC entry 436 (class 1255 OID 20592)
-- Name: audit_catalogs_brands_trigger(); Type: FUNCTION; Schema: audit; Owner: postgres
--

CREATE FUNCTION audit.audit_catalogs_brands_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN  IF TG_OP = 'INSERT' THEN    INSERT INTO audit.catalogs__brands (brand_id, name, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (NEW.brand_id, NEW.name, NEW.created_at, NEW.updated_at, 'INSERT', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN NEW;  ELSIF TG_OP = 'UPDATE' THEN    INSERT INTO audit.catalogs__brands (brand_id, name, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (NEW.brand_id, NEW.name, NEW.created_at, NEW.updated_at, 'UPDATE', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN NEW;  ELSIF TG_OP = 'DELETE' THEN    INSERT INTO audit.catalogs__brands (brand_id, name, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (OLD.brand_id, OLD.name, OLD.created_at, OLD.updated_at, 'DELETE', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN OLD;  END IF;  RETURN NULL;END;$$;


ALTER FUNCTION audit.audit_catalogs_brands_trigger() OWNER TO postgres;

--
-- TOC entry 408 (class 1255 OID 20623)
-- Name: audit_catalogs_categories_trigger(); Type: FUNCTION; Schema: audit; Owner: postgres
--

CREATE FUNCTION audit.audit_catalogs_categories_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN  IF TG_OP = 'INSERT' THEN    INSERT INTO audit.catalogs__categories (category_id, name, description, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (NEW.category_id, NEW.name, NEW.description, NEW.created_at, NEW.updated_at, 'INSERT', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN NEW;  ELSIF TG_OP = 'UPDATE' THEN    INSERT INTO audit.catalogs__categories (category_id, name, description, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (NEW.category_id, NEW.name, NEW.description, NEW.created_at, NEW.updated_at, 'UPDATE', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN NEW;  ELSIF TG_OP = 'DELETE' THEN    INSERT INTO audit.catalogs__categories (category_id, name, description, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (OLD.category_id, OLD.name, OLD.description, OLD.created_at, OLD.updated_at, 'DELETE', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN OLD;  END IF;  RETURN NULL;END;$$;


ALTER FUNCTION audit.audit_catalogs_categories_trigger() OWNER TO postgres;

--
-- TOC entry 441 (class 1255 OID 20654)
-- Name: audit_catalogs_compositions_trigger(); Type: FUNCTION; Schema: audit; Owner: postgres
--

CREATE FUNCTION audit.audit_catalogs_compositions_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN  IF TG_OP = 'INSERT' THEN    INSERT INTO audit.catalogs__compositions (composition_id, name, description, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (NEW.composition_id, NEW.name, NEW.description, NEW.created_at, NEW.updated_at, 'INSERT', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN NEW;  ELSIF TG_OP = 'UPDATE' THEN    INSERT INTO audit.catalogs__compositions (composition_id, name, description, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (NEW.composition_id, NEW.name, NEW.description, NEW.created_at, NEW.updated_at, 'UPDATE', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN NEW;  ELSIF TG_OP = 'DELETE' THEN    INSERT INTO audit.catalogs__compositions (composition_id, name, description, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (OLD.composition_id, OLD.name, OLD.description, OLD.created_at, OLD.updated_at, 'DELETE', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN OLD;  END IF;  RETURN NULL;END;$$;


ALTER FUNCTION audit.audit_catalogs_compositions_trigger() OWNER TO postgres;

--
-- TOC entry 423 (class 1255 OID 20685)
-- Name: audit_catalogs_fillings_trigger(); Type: FUNCTION; Schema: audit; Owner: postgres
--

CREATE FUNCTION audit.audit_catalogs_fillings_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN  IF TG_OP = 'INSERT' THEN    INSERT INTO audit.catalogs__fillings (filling_id, name, description, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (NEW.filling_id, NEW.name, NEW.description, NEW.created_at, NEW.updated_at, 'INSERT', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN NEW;  ELSIF TG_OP = 'UPDATE' THEN    INSERT INTO audit.catalogs__fillings (filling_id, name, description, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (NEW.filling_id, NEW.name, NEW.description, NEW.created_at, NEW.updated_at, 'UPDATE', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN NEW;  ELSIF TG_OP = 'DELETE' THEN    INSERT INTO audit.catalogs__fillings (filling_id, name, description, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (OLD.filling_id, OLD.name, OLD.description, OLD.created_at, OLD.updated_at, 'DELETE', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN OLD;  END IF;  RETURN NULL;END;$$;


ALTER FUNCTION audit.audit_catalogs_fillings_trigger() OWNER TO postgres;

--
-- TOC entry 480 (class 1255 OID 20716)
-- Name: audit_catalogs_flavors_trigger(); Type: FUNCTION; Schema: audit; Owner: postgres
--

CREATE FUNCTION audit.audit_catalogs_flavors_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN  IF TG_OP = 'INSERT' THEN    INSERT INTO audit.catalogs__flavors (flavor_id, name, description, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (NEW.flavor_id, NEW.name, NEW.description, NEW.created_at, NEW.updated_at, 'INSERT', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN NEW;  ELSIF TG_OP = 'UPDATE' THEN    INSERT INTO audit.catalogs__flavors (flavor_id, name, description, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (NEW.flavor_id, NEW.name, NEW.description, NEW.created_at, NEW.updated_at, 'UPDATE', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN NEW;  ELSIF TG_OP = 'DELETE' THEN    INSERT INTO audit.catalogs__flavors (flavor_id, name, description, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (OLD.flavor_id, OLD.name, OLD.description, OLD.created_at, OLD.updated_at, 'DELETE', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN OLD;  END IF;  RETURN NULL;END;$$;


ALTER FUNCTION audit.audit_catalogs_flavors_trigger() OWNER TO postgres;

--
-- TOC entry 431 (class 1255 OID 20747)
-- Name: audit_catalogs_formats_trigger(); Type: FUNCTION; Schema: audit; Owner: postgres
--

CREATE FUNCTION audit.audit_catalogs_formats_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN  IF TG_OP = 'INSERT' THEN    INSERT INTO audit.catalogs__formats (format_id, name, description, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (NEW.format_id, NEW.name, NEW.description, NEW.created_at, NEW.updated_at, 'INSERT', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN NEW;  ELSIF TG_OP = 'UPDATE' THEN    INSERT INTO audit.catalogs__formats (format_id, name, description, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (NEW.format_id, NEW.name, NEW.description, NEW.created_at, NEW.updated_at, 'UPDATE', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN NEW;  ELSIF TG_OP = 'DELETE' THEN    INSERT INTO audit.catalogs__formats (format_id, name, description, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (OLD.format_id, OLD.name, OLD.description, OLD.created_at, OLD.updated_at, 'DELETE', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN OLD;  END IF;  RETURN NULL;END;$$;


ALTER FUNCTION audit.audit_catalogs_formats_trigger() OWNER TO postgres;

--
-- TOC entry 411 (class 1255 OID 20779)
-- Name: audit_catalogs_items_trigger(); Type: FUNCTION; Schema: audit; Owner: postgres
--

CREATE FUNCTION audit.audit_catalogs_items_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN  IF TG_OP = 'INSERT' THEN    INSERT INTO audit.catalogs__items (item_id, subcategory_id, name, description, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (NEW.item_id, NEW.subcategory_id, NEW.name, NEW.description, NEW.created_at, NEW.updated_at, 'INSERT', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN NEW;  ELSIF TG_OP = 'UPDATE' THEN    INSERT INTO audit.catalogs__items (item_id, subcategory_id, name, description, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (NEW.item_id, NEW.subcategory_id, NEW.name, NEW.description, NEW.created_at, NEW.updated_at, 'UPDATE', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN NEW;  ELSIF TG_OP = 'DELETE' THEN    INSERT INTO audit.catalogs__items (item_id, subcategory_id, name, description, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (OLD.item_id, OLD.subcategory_id, OLD.name, OLD.description, OLD.created_at, OLD.updated_at, 'DELETE', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN OLD;  END IF;  RETURN NULL;END;$$;


ALTER FUNCTION audit.audit_catalogs_items_trigger() OWNER TO postgres;

--
-- TOC entry 410 (class 1255 OID 20811)
-- Name: audit_catalogs_nutritional_variants_trigger(); Type: FUNCTION; Schema: audit; Owner: postgres
--

CREATE FUNCTION audit.audit_catalogs_nutritional_variants_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN  IF TG_OP = 'INSERT' THEN    INSERT INTO audit.catalogs__nutritional_variants (nutritional_variant_id, name, description, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (NEW.nutritional_variant_id, NEW.name, NEW.description, NEW.created_at, NEW.updated_at, 'INSERT', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN NEW;  ELSIF TG_OP = 'UPDATE' THEN    INSERT INTO audit.catalogs__nutritional_variants (nutritional_variant_id, name, description, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (NEW.nutritional_variant_id, NEW.name, NEW.description, NEW.created_at, NEW.updated_at, 'UPDATE', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN NEW;  ELSIF TG_OP = 'DELETE' THEN    INSERT INTO audit.catalogs__nutritional_variants (nutritional_variant_id, name, description, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (OLD.nutritional_variant_id, OLD.name, OLD.description, OLD.created_at, OLD.updated_at, 'DELETE', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN OLD;  END IF;  RETURN NULL;END;$$;


ALTER FUNCTION audit.audit_catalogs_nutritional_variants_trigger() OWNER TO postgres;

--
-- TOC entry 492 (class 1255 OID 20844)
-- Name: audit_catalogs_offers_trigger(); Type: FUNCTION; Schema: audit; Owner: postgres
--

CREATE FUNCTION audit.audit_catalogs_offers_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN  IF TG_OP = 'INSERT' THEN    INSERT INTO audit.catalogs__offers (offer_id, product_id, supplier_id, price, available_from, available_until, is_active, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (NEW.offer_id, NEW.product_id, NEW.supplier_id, NEW.price, NEW.available_from, NEW.available_until, NEW.is_active, NEW.created_at, NEW.updated_at, 'INSERT', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN NEW;  ELSIF TG_OP = 'UPDATE' THEN    INSERT INTO audit.catalogs__offers (offer_id, product_id, supplier_id, price, available_from, available_until, is_active, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (NEW.offer_id, NEW.product_id, NEW.supplier_id, NEW.price, NEW.available_from, NEW.available_until, NEW.is_active, NEW.created_at, NEW.updated_at, 'UPDATE', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN NEW;  ELSIF TG_OP = 'DELETE' THEN    INSERT INTO audit.catalogs__offers (offer_id, product_id, supplier_id, price, available_from, available_until, is_active, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (OLD.offer_id, OLD.product_id, OLD.supplier_id, OLD.price, OLD.available_from, OLD.available_until, OLD.is_active, OLD.created_at, OLD.updated_at, 'DELETE', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN OLD;  END IF;  RETURN NULL;END;$$;


ALTER FUNCTION audit.audit_catalogs_offers_trigger() OWNER TO postgres;

--
-- TOC entry 472 (class 1255 OID 20877)
-- Name: audit_catalogs_packagings_trigger(); Type: FUNCTION; Schema: audit; Owner: postgres
--

CREATE FUNCTION audit.audit_catalogs_packagings_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN  IF TG_OP = 'INSERT' THEN    INSERT INTO audit.catalogs__packagings (packaging_id, name, description, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (NEW.packaging_id, NEW.name, NEW.description, NEW.created_at, NEW.updated_at, 'INSERT', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN NEW;  ELSIF TG_OP = 'UPDATE' THEN    INSERT INTO audit.catalogs__packagings (packaging_id, name, description, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (NEW.packaging_id, NEW.name, NEW.description, NEW.created_at, NEW.updated_at, 'UPDATE', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN NEW;  ELSIF TG_OP = 'DELETE' THEN    INSERT INTO audit.catalogs__packagings (packaging_id, name, description, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (OLD.packaging_id, OLD.name, OLD.description, OLD.created_at, OLD.updated_at, 'DELETE', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN OLD;  END IF;  RETURN NULL;END;$$;


ALTER FUNCTION audit.audit_catalogs_packagings_trigger() OWNER TO postgres;

--
-- TOC entry 412 (class 1255 OID 20918)
-- Name: audit_catalogs_products_trigger(); Type: FUNCTION; Schema: audit; Owner: postgres
--

CREATE FUNCTION audit.audit_catalogs_products_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN  IF TG_OP = 'INSERT' THEN    INSERT INTO audit.catalogs__products (product_id, item_id, composition_id, variant_type_id, format_id, flavor_id, filling_id, nutritional_variant_id, brand_id, packaging_id, quantity_id, visibility, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (NEW.product_id, NEW.item_id, NEW.composition_id, NEW.variant_type_id, NEW.format_id, NEW.flavor_id, NEW.filling_id, NEW.nutritional_variant_id, NEW.brand_id, NEW.packaging_id, NEW.quantity_id, NEW.visibility, NEW.created_at, NEW.updated_at, 'INSERT', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN NEW;  ELSIF TG_OP = 'UPDATE' THEN    INSERT INTO audit.catalogs__products (product_id, item_id, composition_id, variant_type_id, format_id, flavor_id, filling_id, nutritional_variant_id, brand_id, packaging_id, quantity_id, visibility, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (NEW.product_id, NEW.item_id, NEW.composition_id, NEW.variant_type_id, NEW.format_id, NEW.flavor_id, NEW.filling_id, NEW.nutritional_variant_id, NEW.brand_id, NEW.packaging_id, NEW.quantity_id, NEW.visibility, NEW.created_at, NEW.updated_at, 'UPDATE', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN NEW;  ELSIF TG_OP = 'DELETE' THEN    INSERT INTO audit.catalogs__products (product_id, item_id, composition_id, variant_type_id, format_id, flavor_id, filling_id, nutritional_variant_id, brand_id, packaging_id, quantity_id, visibility, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (OLD.product_id, OLD.item_id, OLD.composition_id, OLD.variant_type_id, OLD.format_id, OLD.flavor_id, OLD.filling_id, OLD.nutritional_variant_id, OLD.brand_id, OLD.packaging_id, OLD.quantity_id, OLD.visibility, OLD.created_at, OLD.updated_at, 'DELETE', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN OLD;  END IF;  RETURN NULL;END;$$;


ALTER FUNCTION audit.audit_catalogs_products_trigger() OWNER TO postgres;

--
-- TOC entry 449 (class 1255 OID 20959)
-- Name: audit_catalogs_quantities_trigger(); Type: FUNCTION; Schema: audit; Owner: postgres
--

CREATE FUNCTION audit.audit_catalogs_quantities_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN  IF TG_OP = 'INSERT' THEN    INSERT INTO audit.catalogs__quantities (quantity_id, unit, value, display_name, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (NEW.quantity_id, NEW.unit, NEW.value, NEW.display_name, NEW.created_at, NEW.updated_at, 'INSERT', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN NEW;  ELSIF TG_OP = 'UPDATE' THEN    INSERT INTO audit.catalogs__quantities (quantity_id, unit, value, display_name, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (NEW.quantity_id, NEW.unit, NEW.value, NEW.display_name, NEW.created_at, NEW.updated_at, 'UPDATE', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN NEW;  ELSIF TG_OP = 'DELETE' THEN    INSERT INTO audit.catalogs__quantities (quantity_id, unit, value, display_name, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (OLD.quantity_id, OLD.unit, OLD.value, OLD.display_name, OLD.created_at, OLD.updated_at, 'DELETE', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN OLD;  END IF;  RETURN NULL;END;$$;


ALTER FUNCTION audit.audit_catalogs_quantities_trigger() OWNER TO postgres;

--
-- TOC entry 405 (class 1255 OID 20991)
-- Name: audit_catalogs_subcategories_trigger(); Type: FUNCTION; Schema: audit; Owner: postgres
--

CREATE FUNCTION audit.audit_catalogs_subcategories_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN  IF TG_OP = 'INSERT' THEN    INSERT INTO audit.catalogs__subcategories (subcategory_id, category_id, name, description, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (NEW.subcategory_id, NEW.category_id, NEW.name, NEW.description, NEW.created_at, NEW.updated_at, 'INSERT', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN NEW;  ELSIF TG_OP = 'UPDATE' THEN    INSERT INTO audit.catalogs__subcategories (subcategory_id, category_id, name, description, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (NEW.subcategory_id, NEW.category_id, NEW.name, NEW.description, NEW.created_at, NEW.updated_at, 'UPDATE', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN NEW;  ELSIF TG_OP = 'DELETE' THEN    INSERT INTO audit.catalogs__subcategories (subcategory_id, category_id, name, description, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (OLD.subcategory_id, OLD.category_id, OLD.name, OLD.description, OLD.created_at, OLD.updated_at, 'DELETE', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN OLD;  END IF;  RETURN NULL;END;$$;


ALTER FUNCTION audit.audit_catalogs_subcategories_trigger() OWNER TO postgres;

--
-- TOC entry 417 (class 1255 OID 21023)
-- Name: audit_catalogs_variant_types_trigger(); Type: FUNCTION; Schema: audit; Owner: postgres
--

CREATE FUNCTION audit.audit_catalogs_variant_types_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN  IF TG_OP = 'INSERT' THEN    INSERT INTO audit.catalogs__variant_types (variant_type_id, name, description, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (NEW.variant_type_id, NEW.name, NEW.description, NEW.created_at, NEW.updated_at, 'INSERT', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN NEW;  ELSIF TG_OP = 'UPDATE' THEN    INSERT INTO audit.catalogs__variant_types (variant_type_id, name, description, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (NEW.variant_type_id, NEW.name, NEW.description, NEW.created_at, NEW.updated_at, 'UPDATE', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN NEW;  ELSIF TG_OP = 'DELETE' THEN    INSERT INTO audit.catalogs__variant_types (variant_type_id, name, description, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (OLD.variant_type_id, OLD.name, OLD.description, OLD.created_at, OLD.updated_at, 'DELETE', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN OLD;  END IF;  RETURN NULL;END;$$;


ALTER FUNCTION audit.audit_catalogs_variant_types_trigger() OWNER TO postgres;

--
-- TOC entry 489 (class 1255 OID 21711)
-- Name: audit_quotation_quotation_submissions_trigger(); Type: FUNCTION; Schema: audit; Owner: postgres
--

CREATE FUNCTION audit.audit_quotation_quotation_submissions_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN  IF TG_OP = 'INSERT' THEN    INSERT INTO audit.quotation__quotation_submissions (quotation_submission_id, shopping_list_id, submission_status_id, submission_date, total_items, notes, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (NEW.quotation_submission_id, NEW.shopping_list_id, NEW.submission_status_id, NEW.submission_date, NEW.total_items, NEW.notes, NEW.created_at, NEW.updated_at, 'INSERT', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN NEW;  ELSIF TG_OP = 'UPDATE' THEN    INSERT INTO audit.quotation__quotation_submissions (quotation_submission_id, shopping_list_id, submission_status_id, submission_date, total_items, notes, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (NEW.quotation_submission_id, NEW.shopping_list_id, NEW.submission_status_id, NEW.submission_date, NEW.total_items, NEW.notes, NEW.created_at, NEW.updated_at, 'UPDATE', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN NEW;  ELSIF TG_OP = 'DELETE' THEN    INSERT INTO audit.quotation__quotation_submissions (quotation_submission_id, shopping_list_id, submission_status_id, submission_date, total_items, notes, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (OLD.quotation_submission_id, OLD.shopping_list_id, OLD.submission_status_id, OLD.submission_date, OLD.total_items, OLD.notes, OLD.created_at, OLD.updated_at, 'DELETE', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN OLD;  END IF;  RETURN NULL;END;$$;


ALTER FUNCTION audit.audit_quotation_quotation_submissions_trigger() OWNER TO postgres;

--
-- TOC entry 465 (class 1255 OID 21784)
-- Name: audit_quotation_quoted_prices_trigger(); Type: FUNCTION; Schema: audit; Owner: postgres
--

CREATE FUNCTION audit.audit_quotation_quoted_prices_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN  IF TG_OP = 'INSERT' THEN    INSERT INTO audit.quotation__quoted_prices (quoted_price_id, supplier_quotation_id, quantity_from, quantity_to, unit_price, total_price, currency, delivery_time_days, minimum_order_quantity, payment_terms, validity_days, special_conditions, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (NEW.quoted_price_id, NEW.supplier_quotation_id, NEW.quantity_from, NEW.quantity_to, NEW.unit_price, NEW.total_price, NEW.currency, NEW.delivery_time_days, NEW.minimum_order_quantity, NEW.payment_terms, NEW.validity_days, NEW.special_conditions, NEW.created_at, NEW.updated_at, 'INSERT', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN NEW;  ELSIF TG_OP = 'UPDATE' THEN    INSERT INTO audit.quotation__quoted_prices (quoted_price_id, supplier_quotation_id, quantity_from, quantity_to, unit_price, total_price, currency, delivery_time_days, minimum_order_quantity, payment_terms, validity_days, special_conditions, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (NEW.quoted_price_id, NEW.supplier_quotation_id, NEW.quantity_from, NEW.quantity_to, NEW.unit_price, NEW.total_price, NEW.currency, NEW.delivery_time_days, NEW.minimum_order_quantity, NEW.payment_terms, NEW.validity_days, NEW.special_conditions, NEW.created_at, NEW.updated_at, 'UPDATE', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN NEW;  ELSIF TG_OP = 'DELETE' THEN    INSERT INTO audit.quotation__quoted_prices (quoted_price_id, supplier_quotation_id, quantity_from, quantity_to, unit_price, total_price, currency, delivery_time_days, minimum_order_quantity, payment_terms, validity_days, special_conditions, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (OLD.quoted_price_id, OLD.supplier_quotation_id, OLD.quantity_from, OLD.quantity_to, OLD.unit_price, OLD.total_price, OLD.currency, OLD.delivery_time_days, OLD.minimum_order_quantity, OLD.payment_terms, OLD.validity_days, OLD.special_conditions, OLD.created_at, OLD.updated_at, 'DELETE', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN OLD;  END IF;  RETURN NULL;END;$$;


ALTER FUNCTION audit.audit_quotation_quoted_prices_trigger() OWNER TO postgres;

--
-- TOC entry 494 (class 1255 OID 21666)
-- Name: audit_quotation_shopping_list_items_trigger(); Type: FUNCTION; Schema: audit; Owner: postgres
--

CREATE FUNCTION audit.audit_quotation_shopping_list_items_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN  IF TG_OP = 'INSERT' THEN    INSERT INTO audit.quotation__shopping_list_items (shopping_list_item_id, shopping_list_id, item_id, product_id, composition_id, variant_type_id, format_id, flavor_id, filling_id, nutritional_variant_id, brand_id, packaging_id, quantity_id, term, quantity, notes, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (NEW.shopping_list_item_id, NEW.shopping_list_id, NEW.item_id, NEW.product_id, NEW.composition_id, NEW.variant_type_id, NEW.format_id, NEW.flavor_id, NEW.filling_id, NEW.nutritional_variant_id, NEW.brand_id, NEW.packaging_id, NEW.quantity_id, NEW.term, NEW.quantity, NEW.notes, NEW.created_at, NEW.updated_at, 'INSERT', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN NEW;  ELSIF TG_OP = 'UPDATE' THEN    INSERT INTO audit.quotation__shopping_list_items (shopping_list_item_id, shopping_list_id, item_id, product_id, composition_id, variant_type_id, format_id, flavor_id, filling_id, nutritional_variant_id, brand_id, packaging_id, quantity_id, term, quantity, notes, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (NEW.shopping_list_item_id, NEW.shopping_list_id, NEW.item_id, NEW.product_id, NEW.composition_id, NEW.variant_type_id, NEW.format_id, NEW.flavor_id, NEW.filling_id, NEW.nutritional_variant_id, NEW.brand_id, NEW.packaging_id, NEW.quantity_id, NEW.term, NEW.quantity, NEW.notes, NEW.created_at, NEW.updated_at, 'UPDATE', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN NEW;  ELSIF TG_OP = 'DELETE' THEN    INSERT INTO audit.quotation__shopping_list_items (shopping_list_item_id, shopping_list_id, item_id, product_id, composition_id, variant_type_id, format_id, flavor_id, filling_id, nutritional_variant_id, brand_id, packaging_id, quantity_id, term, quantity, notes, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (OLD.shopping_list_item_id, OLD.shopping_list_id, OLD.item_id, OLD.product_id, OLD.composition_id, OLD.variant_type_id, OLD.format_id, OLD.flavor_id, OLD.filling_id, OLD.nutritional_variant_id, OLD.brand_id, OLD.packaging_id, OLD.quantity_id, OLD.term, OLD.quantity, OLD.notes, OLD.created_at, OLD.updated_at, 'DELETE', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN OLD;  END IF;  RETURN NULL;END;$$;


ALTER FUNCTION audit.audit_quotation_shopping_list_items_trigger() OWNER TO postgres;

--
-- TOC entry 426 (class 1255 OID 21621)
-- Name: audit_quotation_shopping_lists_trigger(); Type: FUNCTION; Schema: audit; Owner: postgres
--

CREATE FUNCTION audit.audit_quotation_shopping_lists_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN  IF TG_OP = 'INSERT' THEN    INSERT INTO audit.quotation__shopping_lists (shopping_list_id, establishment_id, employee_id, name, description, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (NEW.shopping_list_id, NEW.establishment_id, NEW.employee_id, NEW.name, NEW.description, NEW.created_at, NEW.updated_at, 'INSERT', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN NEW;  ELSIF TG_OP = 'UPDATE' THEN    INSERT INTO audit.quotation__shopping_lists (shopping_list_id, establishment_id, employee_id, name, description, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (NEW.shopping_list_id, NEW.establishment_id, NEW.employee_id, NEW.name, NEW.description, NEW.created_at, NEW.updated_at, 'UPDATE', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN NEW;  ELSIF TG_OP = 'DELETE' THEN    INSERT INTO audit.quotation__shopping_lists (shopping_list_id, establishment_id, employee_id, name, description, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (OLD.shopping_list_id, OLD.establishment_id, OLD.employee_id, OLD.name, OLD.description, OLD.created_at, OLD.updated_at, 'DELETE', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN OLD;  END IF;  RETURN NULL;END;$$;


ALTER FUNCTION audit.audit_quotation_shopping_lists_trigger() OWNER TO postgres;

--
-- TOC entry 491 (class 1255 OID 21557)
-- Name: audit_quotation_submission_statuses_trigger(); Type: FUNCTION; Schema: audit; Owner: postgres
--

CREATE FUNCTION audit.audit_quotation_submission_statuses_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN  IF TG_OP = 'INSERT' THEN    INSERT INTO audit.quotation__submission_statuses (submission_status_id, name, description, color, is_active, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (NEW.submission_status_id, NEW.name, NEW.description, NEW.color, NEW.is_active, NEW.created_at, NEW.updated_at, 'INSERT', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN NEW;  ELSIF TG_OP = 'UPDATE' THEN    INSERT INTO audit.quotation__submission_statuses (submission_status_id, name, description, color, is_active, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (NEW.submission_status_id, NEW.name, NEW.description, NEW.color, NEW.is_active, NEW.created_at, NEW.updated_at, 'UPDATE', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN NEW;  ELSIF TG_OP = 'DELETE' THEN    INSERT INTO audit.quotation__submission_statuses (submission_status_id, name, description, color, is_active, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (OLD.submission_status_id, OLD.name, OLD.description, OLD.color, OLD.is_active, OLD.created_at, OLD.updated_at, 'DELETE', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN OLD;  END IF;  RETURN NULL;END;$$;


ALTER FUNCTION audit.audit_quotation_submission_statuses_trigger() OWNER TO postgres;

--
-- TOC entry 443 (class 1255 OID 21588)
-- Name: audit_quotation_supplier_quotation_statuses_trigger(); Type: FUNCTION; Schema: audit; Owner: postgres
--

CREATE FUNCTION audit.audit_quotation_supplier_quotation_statuses_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN  IF TG_OP = 'INSERT' THEN    INSERT INTO audit.quotation__supplier_quotation_statuses (quotation_status_id, name, description, color, is_active, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (NEW.quotation_status_id, NEW.name, NEW.description, NEW.color, NEW.is_active, NEW.created_at, NEW.updated_at, 'INSERT', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN NEW;  ELSIF TG_OP = 'UPDATE' THEN    INSERT INTO audit.quotation__supplier_quotation_statuses (quotation_status_id, name, description, color, is_active, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (NEW.quotation_status_id, NEW.name, NEW.description, NEW.color, NEW.is_active, NEW.created_at, NEW.updated_at, 'UPDATE', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN NEW;  ELSIF TG_OP = 'DELETE' THEN    INSERT INTO audit.quotation__supplier_quotation_statuses (quotation_status_id, name, description, color, is_active, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (OLD.quotation_status_id, OLD.name, OLD.description, OLD.color, OLD.is_active, OLD.created_at, OLD.updated_at, 'DELETE', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN OLD;  END IF;  RETURN NULL;END;$$;


ALTER FUNCTION audit.audit_quotation_supplier_quotation_statuses_trigger() OWNER TO postgres;

--
-- TOC entry 479 (class 1255 OID 21748)
-- Name: audit_quotation_supplier_quotations_trigger(); Type: FUNCTION; Schema: audit; Owner: postgres
--

CREATE FUNCTION audit.audit_quotation_supplier_quotations_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN  IF TG_OP = 'INSERT' THEN    INSERT INTO audit.quotation__supplier_quotations (supplier_quotation_id, quotation_submission_id, shopping_list_item_id, supplier_id, quotation_status_id, quotation_date, notes, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (NEW.supplier_quotation_id, NEW.quotation_submission_id, NEW.shopping_list_item_id, NEW.supplier_id, NEW.quotation_status_id, NEW.quotation_date, NEW.notes, NEW.created_at, NEW.updated_at, 'INSERT', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN NEW;  ELSIF TG_OP = 'UPDATE' THEN    INSERT INTO audit.quotation__supplier_quotations (supplier_quotation_id, quotation_submission_id, shopping_list_item_id, supplier_id, quotation_status_id, quotation_date, notes, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (NEW.supplier_quotation_id, NEW.quotation_submission_id, NEW.shopping_list_item_id, NEW.supplier_id, NEW.quotation_status_id, NEW.quotation_date, NEW.notes, NEW.created_at, NEW.updated_at, 'UPDATE', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN NEW;  ELSIF TG_OP = 'DELETE' THEN    INSERT INTO audit.quotation__supplier_quotations (supplier_quotation_id, quotation_submission_id, shopping_list_item_id, supplier_id, quotation_status_id, quotation_date, notes, created_at, updated_at, audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)    VALUES (OLD.supplier_quotation_id, OLD.quotation_submission_id, OLD.shopping_list_item_id, OLD.supplier_id, OLD.quotation_status_id, OLD.quotation_date, OLD.notes, OLD.created_at, OLD.updated_at, 'DELETE', current_user, current_setting('application_name'), inet_client_addr(), current_date);    RETURN OLD;  END IF;  RETURN NULL;END;$$;


ALTER FUNCTION audit.audit_quotation_supplier_quotations_trigger() OWNER TO postgres;

--
-- TOC entry 401 (class 1255 OID 18475)
-- Name: audit_schema(text); Type: FUNCTION; Schema: audit; Owner: postgres
--

CREATE FUNCTION audit.audit_schema(p_schema_name text) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_table_name text;
    v_result text;
    v_total_tables integer := 0;
    v_success_count integer := 0;
    v_error_count integer := 0;
BEGIN
    -- Validação do schema
    IF p_schema_name IS NULL THEN
        RAISE EXCEPTION 'Nome do schema é obrigatório';
    END IF;
    
    -- Verifica se o schema existe
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.schemata 
        WHERE schema_name = p_schema_name
    ) THEN
        RAISE EXCEPTION 'Schema % não existe', p_schema_name;
    END IF;
    
    -- Exclui schemas do sistema
    IF p_schema_name IN ('information_schema', 'pg_catalog', 'pg_toast', 'audit') THEN
        RAISE EXCEPTION 'Não é permitido auditar schemas do sistema';
    END IF;
    
    RAISE NOTICE 'Iniciando auditoria do schema %', p_schema_name;
    
    -- Itera por todas as tabelas do schema
    FOR v_table_name IN
        SELECT table_name
        FROM information_schema.tables 
        WHERE table_schema = p_schema_name 
        AND table_type = 'BASE TABLE'
        ORDER BY table_name
    LOOP
        v_total_tables := v_total_tables + 1;
        
        BEGIN
            v_result := audit.create_audit_table(p_schema_name, v_table_name);
            v_success_count := v_success_count + 1;
            RAISE NOTICE '✓ %: %', v_table_name, v_result;
        EXCEPTION WHEN OTHERS THEN
            v_error_count := v_error_count + 1;
            RAISE NOTICE '✗ %: Erro - %', v_table_name, SQLERRM;
        END;
    END LOOP;
    
    RAISE NOTICE 'Auditoria do schema % concluída:', p_schema_name;
    RAISE NOTICE '  Total de tabelas: %', v_total_tables;
    RAISE NOTICE '  Sucessos: %', v_success_count;
    RAISE NOTICE '  Erros: %', v_error_count;
    
    RETURN 'Schema ' || p_schema_name || ' auditado: ' || v_success_count || '/' || v_total_tables || ' tabelas processadas com sucesso';
END;
$$;


ALTER FUNCTION audit.audit_schema(p_schema_name text) OWNER TO postgres;

--
-- TOC entry 6569 (class 0 OID 0)
-- Dependencies: 401
-- Name: FUNCTION audit_schema(p_schema_name text); Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON FUNCTION audit.audit_schema(p_schema_name text) IS 'Audita todas as tabelas de um schema específico';


--
-- TOC entry 454 (class 1255 OID 18476)
-- Name: audit_schemas(text[]); Type: FUNCTION; Schema: audit; Owner: postgres
--

CREATE FUNCTION audit.audit_schemas(p_schema_names text[]) RETURNS text[]
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_schema_name text;
    v_result text;
    v_results text[] := '{}';
    v_schema_count integer := 0;
BEGIN
    -- Validação dos parâmetros
    IF p_schema_names IS NULL OR array_length(p_schema_names, 1) = 0 THEN
        RAISE EXCEPTION 'Lista de schemas é obrigatória';
    END IF;
    
    RAISE NOTICE 'Iniciando auditoria de % schemas', array_length(p_schema_names, 1);
    
    -- Itera por cada schema
    FOREACH v_schema_name IN ARRAY p_schema_names
    LOOP
        v_schema_count := v_schema_count + 1;
        RAISE NOTICE 'Processando schema % (%/%): %', v_schema_name, v_schema_count, array_length(p_schema_names, 1), v_schema_name;
        
        BEGIN
            v_result := audit.audit_schema(v_schema_name);
            v_results := array_append(v_results, v_result);
        EXCEPTION WHEN OTHERS THEN
            v_result := 'Schema ' || v_schema_name || ': Erro - ' || SQLERRM;
            v_results := array_append(v_results, v_result);
        END;
    END LOOP;
    
    RAISE NOTICE 'Auditoria de schemas concluída';
    RETURN v_results;
END;
$$;


ALTER FUNCTION audit.audit_schemas(p_schema_names text[]) OWNER TO postgres;

--
-- TOC entry 6570 (class 0 OID 0)
-- Dependencies: 454
-- Name: FUNCTION audit_schemas(p_schema_names text[]); Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON FUNCTION audit.audit_schemas(p_schema_names text[]) IS 'Audita múltiplos schemas de uma vez';


--
-- TOC entry 474 (class 1255 OID 18472)
-- Name: create_audit_function(text, text, text); Type: FUNCTION; Schema: audit; Owner: postgres
--

CREATE FUNCTION audit.create_audit_function(p_schema_name text, p_table_name text, p_audit_table_name text) RETURNS void
    LANGUAGE plpgsql
    AS $_$
DECLARE
    v_function_name text;
    v_function_body text;
    v_columns text := '';
    v_column text;
BEGIN
    v_function_name := 'audit_' || p_schema_name || '_' || p_table_name || '_trigger';
    
    -- Constrói lista de colunas para INSERT
    FOR v_column IN
        SELECT column_name
        FROM information_schema.columns 
        WHERE table_schema = p_schema_name 
        AND table_name = p_table_name
        ORDER BY ordinal_position
    LOOP
        IF v_columns != '' THEN
            v_columns := v_columns || ', ';
        END IF;
        v_columns := v_columns || quote_ident(v_column);
    END LOOP;
    
    -- Remove função existente se houver
    EXECUTE 'DROP FUNCTION IF EXISTS audit.' || quote_ident(v_function_name) || '() CASCADE';
    
    -- Constrói lista de valores com NEW. e OLD.
    DECLARE
        v_new_values text := '';
        v_old_values text := '';
        v_column text;
    BEGIN
        -- Reconstrói as listas para usar NEW. e OLD.
        FOR v_column IN
            SELECT column_name
            FROM information_schema.columns 
            WHERE table_schema = p_schema_name 
            AND table_name = p_table_name
            ORDER BY ordinal_position
        LOOP
            IF v_new_values != '' THEN
                v_new_values := v_new_values || ', ';
                v_old_values := v_old_values || ', ';
            END IF;
            v_new_values := v_new_values || 'NEW.' || quote_ident(v_column);
            v_old_values := v_old_values || 'OLD.' || quote_ident(v_column);
        END LOOP;
        
        -- Cria a função usando EXECUTE com string simples
        EXECUTE 'CREATE FUNCTION audit.' || quote_ident(v_function_name) || '() RETURNS trigger AS $body$' ||
                'BEGIN' ||
                '  IF TG_OP = ''INSERT'' THEN' ||
                '    INSERT INTO audit.' || quote_ident(p_audit_table_name) || ' (' || v_columns || ', audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)' ||
                '    VALUES (' || v_new_values || ', ''INSERT'', current_user, current_setting(''application_name''), inet_client_addr(), current_date);' ||
                '    RETURN NEW;' ||
                '  ELSIF TG_OP = ''UPDATE'' THEN' ||
                '    INSERT INTO audit.' || quote_ident(p_audit_table_name) || ' (' || v_columns || ', audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)' ||
                '    VALUES (' || v_new_values || ', ''UPDATE'', current_user, current_setting(''application_name''), inet_client_addr(), current_date);' ||
                '    RETURN NEW;' ||
                '  ELSIF TG_OP = ''DELETE'' THEN' ||
                '    INSERT INTO audit.' || quote_ident(p_audit_table_name) || ' (' || v_columns || ', audit_operation, audit_user, audit_session_id, audit_connection_id, audit_partition_date)' ||
                '    VALUES (' || v_old_values || ', ''DELETE'', current_user, current_setting(''application_name''), inet_client_addr(), current_date);' ||
                '    RETURN OLD;' ||
                '  END IF;' ||
                '  RETURN NULL;' ||
                'END;' ||
                '$body$ LANGUAGE plpgsql;';
    END;
    
    RAISE NOTICE 'Função de auditoria % criada com sucesso', v_function_name;
END;
$_$;


ALTER FUNCTION audit.create_audit_function(p_schema_name text, p_table_name text, p_audit_table_name text) OWNER TO postgres;

--
-- TOC entry 6571 (class 0 OID 0)
-- Dependencies: 474
-- Name: FUNCTION create_audit_function(p_schema_name text, p_table_name text, p_audit_table_name text); Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON FUNCTION audit.create_audit_function(p_schema_name text, p_table_name text, p_audit_table_name text) IS 'Cria a função de trigger para auditoria';


--
-- TOC entry 445 (class 1255 OID 18469)
-- Name: create_audit_indexes(text, text, text); Type: FUNCTION; Schema: audit; Owner: postgres
--

CREATE FUNCTION audit.create_audit_indexes(p_schema_name text, p_table_name text, p_audit_table_name text) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_index_name text;
    v_column_name text;
    v_constraint_type text;
BEGIN
    -- Cria índices para chaves primárias
    FOR v_column_name IN
        SELECT kcu.column_name
        FROM information_schema.table_constraints tc
        JOIN information_schema.key_column_usage kcu 
            ON tc.constraint_name = kcu.constraint_name
        WHERE tc.table_schema = p_schema_name
        AND tc.table_name = p_table_name
        AND tc.constraint_type = 'PRIMARY KEY'
        ORDER BY kcu.ordinal_position
    LOOP
        v_index_name := 'idx_' || p_audit_table_name || '_' || v_column_name;
        EXECUTE format('CREATE INDEX IF NOT EXISTS %I ON audit.%I (%I)', 
                      v_index_name, p_audit_table_name, v_column_name);
    END LOOP;
    
    -- Cria índices para chaves estrangeiras
    FOR v_column_name IN
        SELECT kcu.column_name
        FROM information_schema.table_constraints tc
        JOIN information_schema.key_column_usage kcu 
            ON tc.constraint_name = kcu.constraint_name
        WHERE tc.table_schema = p_schema_name
        AND tc.table_name = p_table_name
        AND tc.constraint_type = 'FOREIGN KEY'
        ORDER BY kcu.ordinal_position
    LOOP
        v_index_name := 'idx_' || p_audit_table_name || '_fk_' || v_column_name;
        EXECUTE format('CREATE INDEX IF NOT EXISTS %I ON audit.%I (%I)', 
                      v_index_name, p_audit_table_name, v_column_name);
    END LOOP;
    
    -- Índice para data de auditoria (para particionamento)
    v_index_name := 'idx_' || p_audit_table_name || '_audit_timestamp';
    EXECUTE format('CREATE INDEX IF NOT EXISTS %I ON audit.%I (audit_timestamp)', 
                  v_index_name, p_audit_table_name);
    
    -- Índice para operação de auditoria
    v_index_name := 'idx_' || p_audit_table_name || '_audit_operation';
    EXECUTE format('CREATE INDEX IF NOT EXISTS %I ON audit.%I (audit_operation)', 
                  v_index_name, p_audit_table_name);
END;
$$;


ALTER FUNCTION audit.create_audit_indexes(p_schema_name text, p_table_name text, p_audit_table_name text) OWNER TO postgres;

--
-- TOC entry 6572 (class 0 OID 0)
-- Dependencies: 445
-- Name: FUNCTION create_audit_indexes(p_schema_name text, p_table_name text, p_audit_table_name text); Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON FUNCTION audit.create_audit_indexes(p_schema_name text, p_table_name text, p_audit_table_name text) IS 'Cria índices necessários para a tabela de auditoria';


--
-- TOC entry 460 (class 1255 OID 18474)
-- Name: create_audit_partitioning(text); Type: FUNCTION; Schema: audit; Owner: postgres
--

CREATE FUNCTION audit.create_audit_partitioning(p_audit_table_name text) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_current_year integer;
    v_current_month integer;
    v_partition_name text;
    v_start_date date;
    v_end_date date;
    v_table_exists boolean;
BEGIN
    -- Verifica se a tabela existe
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'audit' 
        AND table_name = p_audit_table_name
    ) INTO v_table_exists;
    
    IF NOT v_table_exists THEN
        RAISE NOTICE 'Tabela audit.% não existe, pulando particionamento', p_audit_table_name;
        RETURN;
    END IF;
    
    -- Obtém ano e mês atual
    v_current_year := EXTRACT(YEAR FROM current_date);
    v_current_month := EXTRACT(MONTH FROM current_date);
    
    -- Cria partição para o mês atual
    v_partition_name := p_audit_table_name || '_' || v_current_year || '_' || LPAD(v_current_month::text, 2, '0');
    v_start_date := date(v_current_year || '-' || v_current_month || '-01');
    v_end_date := v_start_date + interval '1 month';
    
    -- Cria partição se não existir
    BEGIN
        EXECUTE format('CREATE TABLE IF NOT EXISTS audit.%I PARTITION OF audit.%I
                        FOR VALUES FROM (%L) TO (%L)',
                      v_partition_name, p_audit_table_name, v_start_date, v_end_date);
        
        RAISE NOTICE 'Partição % criada para %', v_partition_name, p_audit_table_name;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Erro ao criar partição % para %: %', v_partition_name, p_audit_table_name, SQLERRM;
    END;
END;
$$;


ALTER FUNCTION audit.create_audit_partitioning(p_audit_table_name text) OWNER TO postgres;

--
-- TOC entry 6573 (class 0 OID 0)
-- Dependencies: 460
-- Name: FUNCTION create_audit_partitioning(p_audit_table_name text); Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON FUNCTION audit.create_audit_partitioning(p_audit_table_name text) IS 'Cria particionamento por data para tabela de auditoria';


--
-- TOC entry 414 (class 1255 OID 18467)
-- Name: create_audit_table(text, text); Type: FUNCTION; Schema: audit; Owner: postgres
--

CREATE FUNCTION audit.create_audit_table(p_schema_name text, p_table_name text) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_audit_table_name text;
    v_create_table_sql text;
    v_column_definitions text := '';
    v_column text;
    v_data_type text;
    v_is_nullable text;
    v_column_default text;
    v_trigger_name text;
    v_function_name text;
    v_audit_table_exists boolean;
    v_columns_changed boolean := false;
BEGIN
    -- Validação dos parâmetros
    IF p_schema_name IS NULL OR p_table_name IS NULL THEN
        RAISE EXCEPTION 'Schema e nome da tabela são obrigatórios';
    END IF;
    
    -- Verifica se a tabela existe
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = p_schema_name 
        AND table_name = p_table_name
    ) THEN
        RAISE EXCEPTION 'Tabela %.% não existe', p_schema_name, p_table_name;
    END IF;
    
    -- Nome da tabela de auditoria (padrão: schema__tabela)
    v_audit_table_name := p_schema_name || '__' || p_table_name;
    
    -- Verifica se a tabela de auditoria já existe
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'audit' 
        AND table_name = v_audit_table_name
    ) INTO v_audit_table_exists;
    
    -- Se a tabela já existe, verifica se precisa sincronizar colunas
    IF v_audit_table_exists THEN
        -- TODO: Implementar sincronização de colunas
        RAISE NOTICE 'Tabela de auditoria %.% já existe. Verificando sincronização...', 'audit', v_audit_table_name;
    END IF;
    
    -- Constrói as definições das colunas
    FOR v_column, v_data_type, v_is_nullable, v_column_default IN
        SELECT 
            column_name,
            data_type,
            is_nullable,
            column_default
        FROM information_schema.columns 
        WHERE table_schema = p_schema_name 
        AND table_name = p_table_name
        ORDER BY ordinal_position
    LOOP
        -- Converte tipos para tipos versáteis
        CASE v_data_type
            WHEN 'character varying', 'varchar', 'text' THEN
                v_data_type := 'text';
            WHEN 'character', 'char' THEN
                v_data_type := 'text';
            WHEN 'integer', 'bigint', 'smallint' THEN
                v_data_type := 'bigint';
            WHEN 'numeric', 'decimal' THEN
                v_data_type := 'numeric';
            WHEN 'real', 'double precision' THEN
                v_data_type := 'double precision';
            WHEN 'boolean' THEN
                v_data_type := 'boolean';
            WHEN 'date' THEN
                v_data_type := 'date';
            WHEN 'timestamp without time zone', 'timestamp with time zone' THEN
                v_data_type := 'timestamp with time zone';
            WHEN 'time without time zone', 'time with time zone' THEN
                v_data_type := 'time with time zone';
            WHEN 'uuid' THEN
                v_data_type := 'uuid';
            WHEN 'json', 'jsonb' THEN
                v_data_type := 'jsonb';
            ELSE
                v_data_type := 'text'; -- Fallback para tipos desconhecidos
        END CASE;
        
        -- Adiciona definição da coluna
        IF v_column_definitions != '' THEN
            v_column_definitions := v_column_definitions || ', ';
        END IF;
        
        v_column_definitions := v_column_definitions || 
            quote_ident(v_column) || ' ' || v_data_type;
        
        -- Adiciona NOT NULL se necessário
        IF v_is_nullable = 'NO' THEN
            v_column_definitions := v_column_definitions || ' NOT NULL';
        END IF;
    END LOOP;
    
    -- Adiciona campos de auditoria (sem chave primária aqui)
    v_column_definitions := v_column_definitions || 
        ', audit_id bigint GENERATED ALWAYS AS IDENTITY' ||
        ', audit_operation text NOT NULL' ||
        ', audit_timestamp timestamp with time zone DEFAULT now() NOT NULL' ||
        ', audit_user text DEFAULT current_user NOT NULL' ||
        ', audit_session_id text DEFAULT current_setting(''application_name'') NOT NULL' ||
        ', audit_connection_id text DEFAULT inet_client_addr() NOT NULL' ||
        ', audit_partition_date date DEFAULT current_date NOT NULL';
    
    -- Adiciona chave primária separadamente (deve vir depois de todos os campos)
    v_column_definitions := v_column_definitions || 
        ', PRIMARY KEY (audit_id, audit_partition_date)'; -- Chave primária deve incluir coluna de particionamento
    
    -- Remove tabela existente se houver (para garantir estrutura correta)
    EXECUTE format('DROP TABLE IF EXISTS audit.%I CASCADE', v_audit_table_name);
    
    -- Cria a tabela de auditoria como particionada
    v_create_table_sql := format(
        'CREATE TABLE IF NOT EXISTS audit.%I (%s) PARTITION BY RANGE (audit_partition_date)',
        v_audit_table_name,
        v_column_definitions
    );
    
    EXECUTE v_create_table_sql;
    
    -- Herda comentários da tabela mãe
    PERFORM audit.inherit_table_comments(p_schema_name, p_table_name, v_audit_table_name);
    
    -- Herda comentários das colunas da tabela mãe
    PERFORM audit.inherit_column_comments(p_schema_name, p_table_name, v_audit_table_name);
    
    -- Cria índices para chaves primárias e estrangeiras
    PERFORM audit.create_audit_indexes(p_schema_name, p_table_name, v_audit_table_name);
    
    -- Cria a função de auditoria
    PERFORM audit.create_audit_function(p_schema_name, p_table_name, v_audit_table_name);
    
    -- Cria o trigger de auditoria
    PERFORM audit.create_audit_trigger(p_schema_name, p_table_name, v_audit_table_name);
    
    -- Cria particionamento por data
    PERFORM audit.create_audit_partitioning(v_audit_table_name);
    
    RAISE NOTICE 'Tabela de auditoria %.% criada com sucesso', 'audit', v_audit_table_name;
    
    RETURN 'Tabela de auditoria audit.' || v_audit_table_name || ' criada com sucesso';
END;
$$;


ALTER FUNCTION audit.create_audit_table(p_schema_name text, p_table_name text) OWNER TO postgres;

--
-- TOC entry 6574 (class 0 OID 0)
-- Dependencies: 414
-- Name: FUNCTION create_audit_table(p_schema_name text, p_table_name text); Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON FUNCTION audit.create_audit_table(p_schema_name text, p_table_name text) IS 'Cria uma tabela de auditoria para uma tabela específica (padrão: schema__tabela)';


--
-- TOC entry 488 (class 1255 OID 18473)
-- Name: create_audit_trigger(text, text, text); Type: FUNCTION; Schema: audit; Owner: postgres
--

CREATE FUNCTION audit.create_audit_trigger(p_schema_name text, p_table_name text, p_audit_table_name text) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_trigger_name text;
    v_function_name text;
BEGIN
    v_trigger_name := 'trg_audit_' || p_schema_name || '_' || p_table_name;
    v_function_name := 'audit_' || p_schema_name || '_' || p_table_name || '_trigger';
    
    -- Remove trigger existente se houver
    EXECUTE format('DROP TRIGGER IF EXISTS %I ON %I.%I', 
                  v_trigger_name, p_schema_name, p_table_name);
    
    -- Cria o trigger
    EXECUTE format('CREATE TRIGGER %I
                    AFTER INSERT OR UPDATE OR DELETE ON %I.%I
                    FOR EACH ROW EXECUTE FUNCTION audit.%I()',
                  v_trigger_name, p_schema_name, p_table_name, v_function_name);
    
    RAISE NOTICE 'Trigger de auditoria % criado com sucesso', v_trigger_name;
END;
$$;


ALTER FUNCTION audit.create_audit_trigger(p_schema_name text, p_table_name text, p_audit_table_name text) OWNER TO postgres;

--
-- TOC entry 6575 (class 0 OID 0)
-- Dependencies: 488
-- Name: FUNCTION create_audit_trigger(p_schema_name text, p_table_name text, p_audit_table_name text); Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON FUNCTION audit.create_audit_trigger(p_schema_name text, p_table_name text, p_audit_table_name text) IS 'Cria o trigger de auditoria na tabela original';


--
-- TOC entry 462 (class 1255 OID 18471)
-- Name: inherit_column_comments(text, text, text); Type: FUNCTION; Schema: audit; Owner: postgres
--

CREATE FUNCTION audit.inherit_column_comments(p_schema_name text, p_table_name text, p_audit_table_name text) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_column_name text;
    v_column_comment text;
    v_audit_column_name text;
BEGIN
    -- Itera por todas as colunas da tabela mãe
    FOR v_column_name IN
        SELECT column_name
        FROM information_schema.columns 
        WHERE table_schema = p_schema_name 
        AND table_name = p_table_name
        ORDER BY ordinal_position
    LOOP
        -- Obtém o comentário da coluna da tabela mãe
        SELECT col_description(format('%s.%s', p_schema_name, p_table_name)::regclass, ordinal_position)
        FROM information_schema.columns 
        WHERE table_schema = p_schema_name 
        AND table_name = p_table_name 
        AND column_name = v_column_name
        INTO v_column_comment;
        
        -- Se existe comentário, aplica na coluna da tabela de auditoria
        IF v_column_comment IS NOT NULL THEN
            EXECUTE format('COMMENT ON COLUMN audit.%I.%I IS %L', 
                          p_audit_table_name, v_column_name, v_column_comment);
        END IF;
    END LOOP;
    
    -- Adiciona comentários para os campos de auditoria
    EXECUTE format('COMMENT ON COLUMN audit.%I.audit_id IS %L', 
                  p_audit_table_name, 'Identificador único do registro de auditoria');
    
    EXECUTE format('COMMENT ON COLUMN audit.%I.audit_operation IS %L', 
                  p_audit_table_name, 'Tipo de operação realizada (INSERT, UPDATE, DELETE)');
    
    EXECUTE format('COMMENT ON COLUMN audit.%I.audit_timestamp IS %L', 
                  p_audit_table_name, 'Data e hora da operação auditada');
    
    EXECUTE format('COMMENT ON COLUMN audit.%I.audit_user IS %L', 
                  p_audit_table_name, 'Usuário que executou a operação');
    
    EXECUTE format('COMMENT ON COLUMN audit.%I.audit_session_id IS %L', 
                  p_audit_table_name, 'Identificador da sessão da aplicação');
    
    EXECUTE format('COMMENT ON COLUMN audit.%I.audit_connection_id IS %L', 
                  p_audit_table_name, 'Endereço IP da conexão');
    
    EXECUTE format('COMMENT ON COLUMN audit.%I.audit_partition_date IS %L', 
                  p_audit_table_name, 'Data para particionamento da tabela de auditoria');
    
    RAISE NOTICE 'Comentários das colunas herdados para %.%', 'audit', p_audit_table_name;
END;
$$;


ALTER FUNCTION audit.inherit_column_comments(p_schema_name text, p_table_name text, p_audit_table_name text) OWNER TO postgres;

--
-- TOC entry 6576 (class 0 OID 0)
-- Dependencies: 462
-- Name: FUNCTION inherit_column_comments(p_schema_name text, p_table_name text, p_audit_table_name text); Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON FUNCTION audit.inherit_column_comments(p_schema_name text, p_table_name text, p_audit_table_name text) IS 'Herdar comentários das colunas da tabela mãe para a tabela de auditoria';


--
-- TOC entry 466 (class 1255 OID 18470)
-- Name: inherit_table_comments(text, text, text); Type: FUNCTION; Schema: audit; Owner: postgres
--

CREATE FUNCTION audit.inherit_table_comments(p_schema_name text, p_table_name text, p_audit_table_name text) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_table_comment text;
BEGIN
    -- Obtém o comentário da tabela mãe
    SELECT obj_description(format('%s.%s', p_schema_name, p_table_name)::regclass) 
    INTO v_table_comment;
    
    -- Se existe comentário, aplica na tabela de auditoria
    IF v_table_comment IS NOT NULL THEN
        EXECUTE format('COMMENT ON TABLE audit.%I IS %L', 
                      p_audit_table_name, 
                      'AUDITORIA: ' || v_table_comment);
    ELSE
        -- Comentário padrão se não houver comentário na tabela mãe
        EXECUTE format('COMMENT ON TABLE audit.%I IS %L', 
                      p_audit_table_name, 
                      'Tabela de auditoria para ' || p_schema_name || '.' || p_table_name);
    END IF;
    
    RAISE NOTICE 'Comentário da tabela herdado para %.%', 'audit', p_audit_table_name;
END;
$$;


ALTER FUNCTION audit.inherit_table_comments(p_schema_name text, p_table_name text, p_audit_table_name text) OWNER TO postgres;

--
-- TOC entry 6577 (class 0 OID 0)
-- Dependencies: 466
-- Name: FUNCTION inherit_table_comments(p_schema_name text, p_table_name text, p_audit_table_name text); Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON FUNCTION audit.inherit_table_comments(p_schema_name text, p_table_name text, p_audit_table_name text) IS 'Herdar comentários da tabela mãe para a tabela de auditoria';


--
-- TOC entry 416 (class 1255 OID 21842)
-- Name: clean_and_validate_cnpj(text); Type: FUNCTION; Schema: aux; Owner: postgres
--

CREATE FUNCTION aux.clean_and_validate_cnpj(cnpj_input text) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    cnpj_limpo text;
    cnpj_numerico text;
BEGIN
    -- Remove todos os caracteres não numéricos
    cnpj_numerico := regexp_replace(cnpj_input, '[^0-9]', '', 'g');
    
    -- Verifica se tem pelo menos 14 dígitos (pode ter mais se máscara quebrada)
    IF length(cnpj_numerico) < 14 THEN
        RAISE EXCEPTION 'CNPJ inválido: deve ter pelo menos 14 dígitos numéricos';
    END IF;
    
    -- Pega apenas os primeiros 14 dígitos (ignora máscaras quebradas)
    cnpj_limpo := substring(cnpj_numerico, 1, 14);
    
    -- Valida o CNPJ
    IF NOT aux.validate_cnpj(cnpj_limpo) THEN
        RAISE EXCEPTION 'CNPJ inválido: número não passa na validação oficial';
    END IF;
    
    RETURN cnpj_limpo;
END;
$$;


ALTER FUNCTION aux.clean_and_validate_cnpj(cnpj_input text) OWNER TO postgres;

--
-- TOC entry 6578 (class 0 OID 0)
-- Dependencies: 416
-- Name: FUNCTION clean_and_validate_cnpj(cnpj_input text); Type: COMMENT; Schema: aux; Owner: postgres
--

COMMENT ON FUNCTION aux.clean_and_validate_cnpj(cnpj_input text) IS 'Limpa CNPJ (remove máscaras) e valida usando algoritmo oficial';


--
-- TOC entry 433 (class 1255 OID 21840)
-- Name: clean_and_validate_cpf(text); Type: FUNCTION; Schema: aux; Owner: postgres
--

CREATE FUNCTION aux.clean_and_validate_cpf(cpf_input text) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    cpf_limpo text;
    cpf_numerico text;
BEGIN
    -- Remove todos os caracteres não numéricos
    cpf_numerico := regexp_replace(cpf_input, '[^0-9]', '', 'g');
    
    -- Verifica se tem pelo menos 11 dígitos (pode ter mais se máscara quebrada)
    IF length(cpf_numerico) < 11 THEN
        RAISE EXCEPTION 'CPF inválido: deve ter pelo menos 11 dígitos numéricos';
    END IF;
    
    -- Pega apenas os primeiros 11 dígitos (ignora máscaras quebradas)
    cpf_limpo := substring(cpf_numerico, 1, 11);
    
    -- Valida o CPF
    IF NOT aux.validate_cpf(cpf_limpo) THEN
        RAISE EXCEPTION 'CPF inválido: número não passa na validação oficial';
    END IF;
    
    RETURN cpf_limpo;
END;
$$;


ALTER FUNCTION aux.clean_and_validate_cpf(cpf_input text) OWNER TO postgres;

--
-- TOC entry 6579 (class 0 OID 0)
-- Dependencies: 433
-- Name: FUNCTION clean_and_validate_cpf(cpf_input text); Type: COMMENT; Schema: aux; Owner: postgres
--

COMMENT ON FUNCTION aux.clean_and_validate_cpf(cpf_input text) IS 'Limpa CPF (remove máscaras) e valida usando algoritmo oficial';


--
-- TOC entry 424 (class 1255 OID 21844)
-- Name: clean_and_validate_postal_code(text); Type: FUNCTION; Schema: aux; Owner: postgres
--

CREATE FUNCTION aux.clean_and_validate_postal_code(cep_input text) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    cep_limpo text;
    cep_numerico text;
BEGIN
    -- Remove todos os caracteres não numéricos
    cep_numerico := regexp_replace(cep_input, '[^0-9]', '', 'g');
    
    -- Verifica se tem pelo menos 8 dígitos (pode ter mais se máscara quebrada)
    IF length(cep_numerico) < 8 THEN
        RAISE EXCEPTION 'CEP inválido: deve ter pelo menos 8 dígitos numéricos';
    END IF;
    
    -- Pega apenas os primeiros 8 dígitos (ignora máscaras quebradas)
    cep_limpo := substring(cep_numerico, 1, 8);
    
    -- Valida o CEP
    IF NOT aux.validate_postal_code(cep_limpo) THEN
        RAISE EXCEPTION 'CEP inválido: formato inválido';
    END IF;
    
    RETURN cep_limpo;
END;
$$;


ALTER FUNCTION aux.clean_and_validate_postal_code(cep_input text) OWNER TO postgres;

--
-- TOC entry 6580 (class 0 OID 0)
-- Dependencies: 424
-- Name: FUNCTION clean_and_validate_postal_code(cep_input text); Type: COMMENT; Schema: aux; Owner: postgres
--

COMMENT ON FUNCTION aux.clean_and_validate_postal_code(cep_input text) IS 'Limpa CEP (remove máscaras) e valida formato';


--
-- TOC entry 459 (class 1255 OID 21927)
-- Name: clean_cnpj_before_insert_update(); Type: FUNCTION; Schema: aux; Owner: postgres
--

CREATE FUNCTION aux.clean_cnpj_before_insert_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Usar função de validação do schema aux
    NEW.cnpj := aux.clean_and_validate_cnpj(NEW.cnpj);
    RETURN NEW;
END;
$$;


ALTER FUNCTION aux.clean_cnpj_before_insert_update() OWNER TO postgres;

--
-- TOC entry 6581 (class 0 OID 0)
-- Dependencies: 459
-- Name: FUNCTION clean_cnpj_before_insert_update(); Type: COMMENT; Schema: aux; Owner: postgres
--

COMMENT ON FUNCTION aux.clean_cnpj_before_insert_update() IS 'Função genérica de trigger para limpar e validar CNPJ automaticamente';


--
-- TOC entry 461 (class 1255 OID 21928)
-- Name: clean_cpf_before_insert_update(); Type: FUNCTION; Schema: aux; Owner: postgres
--

CREATE FUNCTION aux.clean_cpf_before_insert_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Usar função de validação do schema aux
    NEW.cpf := aux.clean_and_validate_cpf(NEW.cpf);
    RETURN NEW;
END;
$$;


ALTER FUNCTION aux.clean_cpf_before_insert_update() OWNER TO postgres;

--
-- TOC entry 6582 (class 0 OID 0)
-- Dependencies: 461
-- Name: FUNCTION clean_cpf_before_insert_update(); Type: COMMENT; Schema: aux; Owner: postgres
--

COMMENT ON FUNCTION aux.clean_cpf_before_insert_update() IS 'Função genérica de trigger para limpar e validar CPF automaticamente';


--
-- TOC entry 473 (class 1255 OID 21929)
-- Name: clean_postal_code_before_insert_update(); Type: FUNCTION; Schema: aux; Owner: postgres
--

CREATE FUNCTION aux.clean_postal_code_before_insert_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Usar função de validação do schema aux
    NEW.postal_code := aux.clean_and_validate_postal_code(NEW.postal_code);
    RETURN NEW;
END;
$$;


ALTER FUNCTION aux.clean_postal_code_before_insert_update() OWNER TO postgres;

--
-- TOC entry 6583 (class 0 OID 0)
-- Dependencies: 473
-- Name: FUNCTION clean_postal_code_before_insert_update(); Type: COMMENT; Schema: aux; Owner: postgres
--

COMMENT ON FUNCTION aux.clean_postal_code_before_insert_update() IS 'Função genérica de trigger para limpar e validar CEP automaticamente';


--
-- TOC entry 434 (class 1255 OID 21932)
-- Name: create_cnpj_trigger(text, text, text); Type: FUNCTION; Schema: aux; Owner: postgres
--

CREATE FUNCTION aux.create_cnpj_trigger(p_schema_name text, p_table_name text, p_column_name text DEFAULT 'cnpj'::text) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_trigger_name text;
    v_full_table_name text;
    v_sql text;
BEGIN
    -- Nome do trigger
    v_trigger_name := 'clean_cnpj_trigger';
    v_full_table_name := p_schema_name || '.' || p_table_name;
    
    -- Criar trigger
    v_sql := format('
        DROP TRIGGER IF EXISTS %I ON %s;
        CREATE TRIGGER %I
            BEFORE INSERT OR UPDATE ON %s
            FOR EACH ROW EXECUTE FUNCTION aux.clean_cnpj_before_insert_update();
    ', v_trigger_name, v_full_table_name, v_trigger_name, v_full_table_name);
    
    EXECUTE v_sql;
    
    RETURN 'Trigger ' || v_trigger_name || ' criado com sucesso para ' || v_full_table_name;
END;
$$;


ALTER FUNCTION aux.create_cnpj_trigger(p_schema_name text, p_table_name text, p_column_name text) OWNER TO postgres;

--
-- TOC entry 6584 (class 0 OID 0)
-- Dependencies: 434
-- Name: FUNCTION create_cnpj_trigger(p_schema_name text, p_table_name text, p_column_name text); Type: COMMENT; Schema: aux; Owner: postgres
--

COMMENT ON FUNCTION aux.create_cnpj_trigger(p_schema_name text, p_table_name text, p_column_name text) IS 'Função genérica para criar trigger de limpeza de CNPJ';


--
-- TOC entry 418 (class 1255 OID 21933)
-- Name: create_cpf_trigger(text, text, text); Type: FUNCTION; Schema: aux; Owner: postgres
--

CREATE FUNCTION aux.create_cpf_trigger(p_schema_name text, p_table_name text, p_column_name text DEFAULT 'cpf'::text) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_trigger_name text;
    v_full_table_name text;
    v_sql text;
BEGIN
    -- Nome do trigger
    v_trigger_name := 'clean_cpf_trigger';
    v_full_table_name := p_schema_name || '.' || p_table_name;
    
    -- Criar trigger
    v_sql := format('
        DROP TRIGGER IF EXISTS %I ON %s;
        CREATE TRIGGER %I
            BEFORE INSERT OR UPDATE ON %s
            FOR EACH ROW EXECUTE FUNCTION aux.clean_cpf_before_insert_update();
    ', v_trigger_name, v_full_table_name, v_trigger_name, v_full_table_name);
    
    EXECUTE v_sql;
    
    RETURN 'Trigger ' || v_trigger_name || ' criado com sucesso para ' || v_full_table_name;
END;
$$;


ALTER FUNCTION aux.create_cpf_trigger(p_schema_name text, p_table_name text, p_column_name text) OWNER TO postgres;

--
-- TOC entry 6585 (class 0 OID 0)
-- Dependencies: 418
-- Name: FUNCTION create_cpf_trigger(p_schema_name text, p_table_name text, p_column_name text); Type: COMMENT; Schema: aux; Owner: postgres
--

COMMENT ON FUNCTION aux.create_cpf_trigger(p_schema_name text, p_table_name text, p_column_name text) IS 'Função genérica para criar trigger de limpeza de CPF';


--
-- TOC entry 451 (class 1255 OID 21935)
-- Name: create_email_trigger(text, text, text); Type: FUNCTION; Schema: aux; Owner: postgres
--

CREATE FUNCTION aux.create_email_trigger(p_schema_name text, p_table_name text, p_column_name text DEFAULT 'email'::text) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_trigger_name text;
    v_full_table_name text;
    v_sql text;
BEGIN
    -- Nome do trigger
    v_trigger_name := 'validate_email_trigger';
    v_full_table_name := p_schema_name || '.' || p_table_name;
    
    -- Criar trigger
    v_sql := format('
        DROP TRIGGER IF EXISTS %I ON %s;
        CREATE TRIGGER %I
            BEFORE INSERT OR UPDATE ON %s
            FOR EACH ROW EXECUTE FUNCTION aux.validate_email_before_insert_update();
    ', v_trigger_name, v_full_table_name, v_trigger_name, v_full_table_name);
    
    EXECUTE v_sql;
    
    RETURN 'Trigger ' || v_trigger_name || ' criado com sucesso para ' || v_full_table_name;
END;
$$;


ALTER FUNCTION aux.create_email_trigger(p_schema_name text, p_table_name text, p_column_name text) OWNER TO postgres;

--
-- TOC entry 6586 (class 0 OID 0)
-- Dependencies: 451
-- Name: FUNCTION create_email_trigger(p_schema_name text, p_table_name text, p_column_name text); Type: COMMENT; Schema: aux; Owner: postgres
--

COMMENT ON FUNCTION aux.create_email_trigger(p_schema_name text, p_table_name text, p_column_name text) IS 'Função genérica para criar trigger de validação de email';


--
-- TOC entry 495 (class 1255 OID 21934)
-- Name: create_postal_code_trigger(text, text, text); Type: FUNCTION; Schema: aux; Owner: postgres
--

CREATE FUNCTION aux.create_postal_code_trigger(p_schema_name text, p_table_name text, p_column_name text DEFAULT 'postal_code'::text) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_trigger_name text;
    v_full_table_name text;
    v_sql text;
BEGIN
    -- Nome do trigger
    v_trigger_name := 'clean_postal_code_trigger';
    v_full_table_name := p_schema_name || '.' || p_table_name;
    
    -- Criar trigger
    v_sql := format('
        DROP TRIGGER IF EXISTS %I ON %s;
        CREATE TRIGGER %I
            BEFORE INSERT OR UPDATE ON %s
            FOR EACH ROW EXECUTE FUNCTION aux.clean_postal_code_before_insert_update();
    ', v_trigger_name, v_full_table_name, v_trigger_name, v_full_table_name);
    
    EXECUTE v_sql;
    
    RETURN 'Trigger ' || v_trigger_name || ' criado com sucesso para ' || v_full_table_name;
END;
$$;


ALTER FUNCTION aux.create_postal_code_trigger(p_schema_name text, p_table_name text, p_column_name text) OWNER TO postgres;

--
-- TOC entry 6587 (class 0 OID 0)
-- Dependencies: 495
-- Name: FUNCTION create_postal_code_trigger(p_schema_name text, p_table_name text, p_column_name text); Type: COMMENT; Schema: aux; Owner: postgres
--

COMMENT ON FUNCTION aux.create_postal_code_trigger(p_schema_name text, p_table_name text, p_column_name text) IS 'Função genérica para criar trigger de limpeza de CEP';


--
-- TOC entry 398 (class 1255 OID 21854)
-- Name: create_updated_at_trigger(text, text); Type: FUNCTION; Schema: aux; Owner: postgres
--

CREATE FUNCTION aux.create_updated_at_trigger(p_schema_name text, p_table_name text) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_trigger_name text;
BEGIN
    v_trigger_name := 'trg_set_updated_at_' || p_table_name;
    
    -- Remove trigger existente se houver
    EXECUTE format('DROP TRIGGER IF EXISTS %I ON %I.%I', 
                   v_trigger_name, p_schema_name, p_table_name);
    
    -- Cria novo trigger
    EXECUTE format('CREATE TRIGGER %I BEFORE UPDATE ON %I.%I FOR EACH ROW EXECUTE FUNCTION aux.set_updated_at()',
                   v_trigger_name, p_schema_name, p_table_name);
    
    RAISE NOTICE 'Trigger % criado para %.%', v_trigger_name, p_schema_name, p_table_name;
END;
$$;


ALTER FUNCTION aux.create_updated_at_trigger(p_schema_name text, p_table_name text) OWNER TO postgres;

--
-- TOC entry 6588 (class 0 OID 0)
-- Dependencies: 398
-- Name: FUNCTION create_updated_at_trigger(p_schema_name text, p_table_name text); Type: COMMENT; Schema: aux; Owner: postgres
--

COMMENT ON FUNCTION aux.create_updated_at_trigger(p_schema_name text, p_table_name text) IS 'Cria automaticamente trigger de updated_at para uma tabela';


--
-- TOC entry 444 (class 1255 OID 21936)
-- Name: create_url_trigger(text, text, text); Type: FUNCTION; Schema: aux; Owner: postgres
--

CREATE FUNCTION aux.create_url_trigger(p_schema_name text, p_table_name text, p_column_name text DEFAULT 'photo_url'::text) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_trigger_name text;
    v_full_table_name text;
    v_sql text;
BEGIN
    -- Nome do trigger
    v_trigger_name := 'validate_url_trigger';
    v_full_table_name := p_schema_name || '.' || p_table_name;
    
    -- Criar trigger
    v_sql := format('
        DROP TRIGGER IF EXISTS %I ON %s;
        CREATE TRIGGER %I
            BEFORE INSERT OR UPDATE ON %s
            FOR EACH ROW EXECUTE FUNCTION aux.validate_url_before_insert_update();
    ', v_trigger_name, v_full_table_name, v_trigger_name, v_full_table_name);
    
    EXECUTE v_sql;
    
    RETURN 'Trigger ' || v_trigger_name || ' criado com sucesso para ' || v_full_table_name;
END;
$$;


ALTER FUNCTION aux.create_url_trigger(p_schema_name text, p_table_name text, p_column_name text) OWNER TO postgres;

--
-- TOC entry 6589 (class 0 OID 0)
-- Dependencies: 444
-- Name: FUNCTION create_url_trigger(p_schema_name text, p_table_name text, p_column_name text); Type: COMMENT; Schema: aux; Owner: postgres
--

COMMENT ON FUNCTION aux.create_url_trigger(p_schema_name text, p_table_name text, p_column_name text) IS 'Função genérica para criar trigger de validação de URL';


--
-- TOC entry 409 (class 1255 OID 21937)
-- Name: create_validation_triggers(text, text, text[]); Type: FUNCTION; Schema: aux; Owner: postgres
--

CREATE FUNCTION aux.create_validation_triggers(p_schema_name text, p_table_name text, p_columns text[] DEFAULT ARRAY[]::text[]) RETURNS text[]
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_result text[];
    v_column text;
    v_message text;
BEGIN
    v_result := ARRAY[]::text[];
    
    -- Se não especificou colunas, usar padrões baseados no nome da tabela
    IF array_length(p_columns, 1) IS NULL THEN
        -- Detectar automaticamente colunas baseado no nome da tabela
        IF p_table_name LIKE '%business%' OR p_table_name LIKE '%establishment%' THEN
            p_columns := ARRAY['cnpj'];
        ELSIF p_table_name LIKE '%employee%' OR p_table_name LIKE '%person%' THEN
            p_columns := ARRAY['cpf'];
        ELSIF p_table_name LIKE '%address%' THEN
            p_columns := ARRAY['postal_code'];
        END IF;
    END IF;
    
    -- Criar triggers para cada coluna
    FOREACH v_column IN ARRAY p_columns
    LOOP
        BEGIN
            CASE v_column
                WHEN 'cnpj' THEN
                    v_message := aux.create_cnpj_trigger(p_schema_name, p_table_name, v_column);
                WHEN 'cpf' THEN
                    v_message := aux.create_cpf_trigger(p_schema_name, p_table_name, v_column);
                WHEN 'postal_code' THEN
                    v_message := aux.create_postal_code_trigger(p_schema_name, p_table_name, v_column);
                WHEN 'email' THEN
                    v_message := aux.create_email_trigger(p_schema_name, p_table_name, v_column);
                WHEN 'photo_url' THEN
                    v_message := aux.create_url_trigger(p_schema_name, p_table_name, v_column);
                ELSE
                    v_message := 'Coluna ' || v_column || ' não suportada para validação automática';
            END CASE;
            
            v_result := array_append(v_result, v_message);
        EXCEPTION
            WHEN OTHERS THEN
                v_result := array_append(v_result, 'Erro ao criar trigger para ' || v_column || ': ' || SQLERRM);
        END;
    END LOOP;
    
    RETURN v_result;
END;
$$;


ALTER FUNCTION aux.create_validation_triggers(p_schema_name text, p_table_name text, p_columns text[]) OWNER TO postgres;

--
-- TOC entry 6590 (class 0 OID 0)
-- Dependencies: 409
-- Name: FUNCTION create_validation_triggers(p_schema_name text, p_table_name text, p_columns text[]); Type: COMMENT; Schema: aux; Owner: postgres
--

COMMENT ON FUNCTION aux.create_validation_triggers(p_schema_name text, p_table_name text, p_columns text[]) IS 'Função genérica para criar todos os triggers de validação de uma tabela';


--
-- TOC entry 481 (class 1255 OID 21852)
-- Name: format_cnpj(text); Type: FUNCTION; Schema: aux; Owner: postgres
--

CREATE FUNCTION aux.format_cnpj(cnpj_numerico text) RETURNS text
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF length(cnpj_numerico) != 14 THEN
        RAISE EXCEPTION 'CNPJ deve ter 14 dígitos numéricos';
    END IF;
    
    RETURN substring(cnpj_numerico, 1, 2) || '.' ||
           substring(cnpj_numerico, 3, 3) || '.' ||
           substring(cnpj_numerico, 6, 3) || '/' ||
           substring(cnpj_numerico, 9, 4) || '-' ||
           substring(cnpj_numerico, 13, 2);
END;
$$;


ALTER FUNCTION aux.format_cnpj(cnpj_numerico text) OWNER TO postgres;

--
-- TOC entry 6591 (class 0 OID 0)
-- Dependencies: 481
-- Name: FUNCTION format_cnpj(cnpj_numerico text); Type: COMMENT; Schema: aux; Owner: postgres
--

COMMENT ON FUNCTION aux.format_cnpj(cnpj_numerico text) IS 'Formata CNPJ numérico com máscara (XX.XXX.XXX/XXXX-XX)';


--
-- TOC entry 439 (class 1255 OID 21851)
-- Name: format_cpf(text); Type: FUNCTION; Schema: aux; Owner: postgres
--

CREATE FUNCTION aux.format_cpf(cpf_numerico text) RETURNS text
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF length(cpf_numerico) != 11 THEN
        RAISE EXCEPTION 'CPF deve ter 11 dígitos numéricos';
    END IF;
    
    RETURN substring(cpf_numerico, 1, 3) || '.' ||
           substring(cpf_numerico, 4, 3) || '.' ||
           substring(cpf_numerico, 7, 3) || '-' ||
           substring(cpf_numerico, 10, 2);
END;
$$;


ALTER FUNCTION aux.format_cpf(cpf_numerico text) OWNER TO postgres;

--
-- TOC entry 6592 (class 0 OID 0)
-- Dependencies: 439
-- Name: FUNCTION format_cpf(cpf_numerico text); Type: COMMENT; Schema: aux; Owner: postgres
--

COMMENT ON FUNCTION aux.format_cpf(cpf_numerico text) IS 'Formata CPF numérico com máscara (XXX.XXX.XXX-XX)';


--
-- TOC entry 467 (class 1255 OID 21853)
-- Name: format_postal_code(text); Type: FUNCTION; Schema: aux; Owner: postgres
--

CREATE FUNCTION aux.format_postal_code(cep_numerico text) RETURNS text
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF length(cep_numerico) != 8 THEN
        RAISE EXCEPTION 'CEP deve ter 8 dígitos numéricos';
    END IF;
    
    RETURN substring(cep_numerico, 1, 5) || '-' ||
           substring(cep_numerico, 6, 3);
END;
$$;


ALTER FUNCTION aux.format_postal_code(cep_numerico text) OWNER TO postgres;

--
-- TOC entry 6593 (class 0 OID 0)
-- Dependencies: 467
-- Name: FUNCTION format_postal_code(cep_numerico text); Type: COMMENT; Schema: aux; Owner: postgres
--

COMMENT ON FUNCTION aux.format_postal_code(cep_numerico text) IS 'Formata CEP numérico com máscara (XXXXX-XXX)';


--
-- TOC entry 452 (class 1255 OID 21850)
-- Name: set_updated_at(); Type: FUNCTION; Schema: aux; Owner: postgres
--

CREATE FUNCTION aux.set_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END;
$$;


ALTER FUNCTION aux.set_updated_at() OWNER TO postgres;

--
-- TOC entry 6594 (class 0 OID 0)
-- Dependencies: 452
-- Name: FUNCTION set_updated_at(); Type: COMMENT; Schema: aux; Owner: postgres
--

COMMENT ON FUNCTION aux.set_updated_at() IS 'Função genérica para atualizar campo updated_at automaticamente';


--
-- TOC entry 420 (class 1255 OID 21848)
-- Name: validate_birth_date(date, integer); Type: FUNCTION; Schema: aux; Owner: postgres
--

CREATE FUNCTION aux.validate_birth_date(birth_date date, min_age_years integer DEFAULT 14) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Verifica se a data não é no futuro
    IF birth_date > current_date THEN
        RETURN false;
    END IF;
    
    -- Verifica se a pessoa tem a idade mínima
    IF birth_date > (current_date - interval '1 year' * min_age_years) THEN
        RETURN false;
    END IF;
    
    RETURN true;
END;
$$;


ALTER FUNCTION aux.validate_birth_date(birth_date date, min_age_years integer) OWNER TO postgres;

--
-- TOC entry 6595 (class 0 OID 0)
-- Dependencies: 420
-- Name: FUNCTION validate_birth_date(birth_date date, min_age_years integer); Type: COMMENT; Schema: aux; Owner: postgres
--

COMMENT ON FUNCTION aux.validate_birth_date(birth_date date, min_age_years integer) IS 'Valida data de nascimento (não futura e idade mínima)';


--
-- TOC entry 487 (class 1255 OID 21841)
-- Name: validate_cnpj(text); Type: FUNCTION; Schema: aux; Owner: postgres
--

CREATE FUNCTION aux.validate_cnpj(p_cnpj text) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
    cnpj_limpo text;
    i integer;
    soma integer;
    resto integer;
    digito1 integer;
    digito2 integer;
    multiplicadores1 integer[] := ARRAY[5,4,3,2,9,8,7,6,5,4,3,2];
    multiplicadores2 integer[] := ARRAY[6,5,4,3,2,9,8,7,6,5,4,3,2];
BEGIN
    -- Remove caracteres não numéricos
    cnpj_limpo := regexp_replace(p_cnpj, '[^0-9]', '', 'g');
    
    -- Verifica se tem 14 dígitos
    IF length(cnpj_limpo) != 14 THEN
        RETURN false;
    END IF;
    
    -- Verifica se todos os dígitos são iguais
    IF cnpj_limpo = regexp_replace(cnpj_limpo, '^(\d)\1*$', '\1', 'g') THEN
        RETURN false;
    END IF;
    
    -- Calcula primeiro dígito verificador
    soma := 0;
    FOR i IN 1..12 LOOP
        soma := soma + (substring(cnpj_limpo, i, 1)::integer * multiplicadores1[i]);
    END LOOP;
    
    resto := soma % 11;
    IF resto < 2 THEN
        digito1 := 0;
    ELSE
        digito1 := 11 - resto;
    END IF;
    
    -- Calcula segundo dígito verificador
    soma := 0;
    FOR i IN 1..13 LOOP
        soma := soma + (substring(cnpj_limpo, i, 1)::integer * multiplicadores2[i]);
    END LOOP;
    
    resto := soma % 11;
    IF resto < 2 THEN
        digito2 := 0;
    ELSE
        digito2 := 11 - resto;
    END IF;
    
    -- Verifica se os dígitos calculados são iguais aos do CNPJ
    RETURN (digito1::text = substring(cnpj_limpo, 13, 1) AND 
            digito2::text = substring(cnpj_limpo, 14, 1));
END;
$_$;


ALTER FUNCTION aux.validate_cnpj(p_cnpj text) OWNER TO postgres;

--
-- TOC entry 6596 (class 0 OID 0)
-- Dependencies: 487
-- Name: FUNCTION validate_cnpj(p_cnpj text); Type: COMMENT; Schema: aux; Owner: postgres
--

COMMENT ON FUNCTION aux.validate_cnpj(p_cnpj text) IS 'Valida CNPJ usando algoritmo oficial brasileiro';


--
-- TOC entry 419 (class 1255 OID 21839)
-- Name: validate_cpf(text); Type: FUNCTION; Schema: aux; Owner: postgres
--

CREATE FUNCTION aux.validate_cpf(p_cpf text) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
    cpf_limpo text;
    i integer;
    soma integer;
    resto integer;
    digito1 integer;
    digito2 integer;
BEGIN
    -- Remove caracteres não numéricos
    cpf_limpo := regexp_replace(p_cpf, '[^0-9]', '', 'g');
    
    -- Verifica se tem 11 dígitos
    IF length(cpf_limpo) != 11 THEN
        RETURN false;
    END IF;
    
    -- Verifica se todos os dígitos são iguais
    IF cpf_limpo = regexp_replace(cpf_limpo, '^(\d)\1*$', '\1', 'g') THEN
        RETURN false;
    END IF;
    
    -- Calcula primeiro dígito verificador
    soma := 0;
    FOR i IN 1..9 LOOP
        soma := soma + (substring(cpf_limpo, i, 1)::integer * (11 - i));
    END LOOP;
    
    resto := soma % 11;
    IF resto < 2 THEN
        digito1 := 0;
    ELSE
        digito1 := 11 - resto;
    END IF;
    
    -- Calcula segundo dígito verificador
    soma := 0;
    FOR i IN 1..10 LOOP
        soma := soma + (substring(cpf_limpo, i, 1)::integer * (12 - i));
    END LOOP;
    
    resto := soma % 11;
    IF resto < 2 THEN
        digito2 := 0;
    ELSE
        digito2 := 11 - resto;
    END IF;
    
    -- Verifica se os dígitos calculados são iguais aos do CPF
    RETURN (digito1::text = substring(cpf_limpo, 10, 1) AND 
            digito2::text = substring(cpf_limpo, 11, 1));
END;
$_$;


ALTER FUNCTION aux.validate_cpf(p_cpf text) OWNER TO postgres;

--
-- TOC entry 6597 (class 0 OID 0)
-- Dependencies: 419
-- Name: FUNCTION validate_cpf(p_cpf text); Type: COMMENT; Schema: aux; Owner: postgres
--

COMMENT ON FUNCTION aux.validate_cpf(p_cpf text) IS 'Valida CPF usando algoritmo oficial brasileiro';


--
-- TOC entry 486 (class 1255 OID 21846)
-- Name: validate_email(text); Type: FUNCTION; Schema: aux; Owner: postgres
--

CREATE FUNCTION aux.validate_email(email text) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
BEGIN
    -- Se for NULL, é válido (opcional)
    IF email IS NULL THEN
        RETURN true;
    END IF;
    
    -- Regex básico para validação de email
    -- Formato: local@domain
    -- local: pode conter letras, números, pontos, hífens, underscores
    -- domain: deve ter pelo menos um ponto e terminar com 2-4 letras
    IF email ~ '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$' THEN
        RETURN true;
    END IF;
    
    RETURN false;
END;
$_$;


ALTER FUNCTION aux.validate_email(email text) OWNER TO postgres;

--
-- TOC entry 6598 (class 0 OID 0)
-- Dependencies: 486
-- Name: FUNCTION validate_email(email text); Type: COMMENT; Schema: aux; Owner: postgres
--

COMMENT ON FUNCTION aux.validate_email(email text) IS 'Valida formato básico de email (local@domain)';


--
-- TOC entry 482 (class 1255 OID 21930)
-- Name: validate_email_before_insert_update(); Type: FUNCTION; Schema: aux; Owner: postgres
--

CREATE FUNCTION aux.validate_email_before_insert_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Usar função de validação do schema aux
    IF NEW.email IS NOT NULL THEN
        IF NOT aux.validate_email(NEW.email) THEN
            RAISE EXCEPTION 'Email inválido: %', NEW.email;
        END IF;
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION aux.validate_email_before_insert_update() OWNER TO postgres;

--
-- TOC entry 6599 (class 0 OID 0)
-- Dependencies: 482
-- Name: FUNCTION validate_email_before_insert_update(); Type: COMMENT; Schema: aux; Owner: postgres
--

COMMENT ON FUNCTION aux.validate_email_before_insert_update() IS 'Função genérica de trigger para validar email automaticamente';


--
-- TOC entry 483 (class 1255 OID 21849)
-- Name: validate_estado_brasileiro(text); Type: FUNCTION; Schema: aux; Owner: postgres
--

CREATE FUNCTION aux.validate_estado_brasileiro(estado text) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN estado::aux.estado_brasileiro IS NOT NULL;
EXCEPTION
    WHEN OTHERS THEN
        RETURN false;
END;
$$;


ALTER FUNCTION aux.validate_estado_brasileiro(estado text) OWNER TO postgres;

--
-- TOC entry 6600 (class 0 OID 0)
-- Dependencies: 483
-- Name: FUNCTION validate_estado_brasileiro(estado text); Type: COMMENT; Schema: aux; Owner: postgres
--

COMMENT ON FUNCTION aux.validate_estado_brasileiro(estado text) IS 'Valida se o estado é um estado brasileiro válido';


--
-- TOC entry 490 (class 1255 OID 21847)
-- Name: validate_json(text); Type: FUNCTION; Schema: aux; Owner: postgres
--

CREATE FUNCTION aux.validate_json(json_text text) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Se for NULL, é válido (opcional)
    IF json_text IS NULL THEN
        RETURN true;
    END IF;
    
    -- Tenta fazer parse do JSON
    BEGIN
        PERFORM json_text::json;
        RETURN true;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN false;
    END;
END;
$$;


ALTER FUNCTION aux.validate_json(json_text text) OWNER TO postgres;

--
-- TOC entry 6601 (class 0 OID 0)
-- Dependencies: 490
-- Name: FUNCTION validate_json(json_text text); Type: COMMENT; Schema: aux; Owner: postgres
--

COMMENT ON FUNCTION aux.validate_json(json_text text) IS 'Valida se o texto é um JSON válido';


--
-- TOC entry 485 (class 1255 OID 21843)
-- Name: validate_postal_code(text); Type: FUNCTION; Schema: aux; Owner: postgres
--

CREATE FUNCTION aux.validate_postal_code(p_cep text) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
    cep_limpo text;
BEGIN
    -- Remove caracteres não numéricos
    cep_limpo := regexp_replace(p_cep, '[^0-9]', '', 'g');
    
    -- Verifica se tem 8 dígitos
    IF length(cep_limpo) != 8 THEN
        RETURN false;
    END IF;
    
    -- Verifica se todos os dígitos são iguais
    IF cep_limpo = regexp_replace(cep_limpo, '^(\d)\1*$', '\1', 'g') THEN
        RETURN false;
    END IF;
    
    RETURN true;
END;
$_$;


ALTER FUNCTION aux.validate_postal_code(p_cep text) OWNER TO postgres;

--
-- TOC entry 6602 (class 0 OID 0)
-- Dependencies: 485
-- Name: FUNCTION validate_postal_code(p_cep text); Type: COMMENT; Schema: aux; Owner: postgres
--

COMMENT ON FUNCTION aux.validate_postal_code(p_cep text) IS 'Valida CEP brasileiro (8 dígitos numéricos)';


--
-- TOC entry 446 (class 1255 OID 21845)
-- Name: validate_url(text); Type: FUNCTION; Schema: aux; Owner: postgres
--

CREATE FUNCTION aux.validate_url(url text) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Se for NULL, é válido (opcional)
    IF url IS NULL THEN
        RETURN true;
    END IF;
    
    -- Verifica se começa com http:// ou https://
    IF url ~ '^https?://' THEN
        RETURN true;
    END IF;
    
    RETURN false;
END;
$$;


ALTER FUNCTION aux.validate_url(url text) OWNER TO postgres;

--
-- TOC entry 6603 (class 0 OID 0)
-- Dependencies: 446
-- Name: FUNCTION validate_url(url text); Type: COMMENT; Schema: aux; Owner: postgres
--

COMMENT ON FUNCTION aux.validate_url(url text) IS 'Valida formato básico de URL (http:// ou https://)';


--
-- TOC entry 422 (class 1255 OID 21931)
-- Name: validate_url_before_insert_update(); Type: FUNCTION; Schema: aux; Owner: postgres
--

CREATE FUNCTION aux.validate_url_before_insert_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Usar função de validação do schema aux
    IF NEW.photo_url IS NOT NULL THEN
        IF NOT aux.validate_url(NEW.photo_url) THEN
            RAISE EXCEPTION 'URL inválida: %', NEW.photo_url;
        END IF;
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION aux.validate_url_before_insert_update() OWNER TO postgres;

--
-- TOC entry 6604 (class 0 OID 0)
-- Dependencies: 422
-- Name: FUNCTION validate_url_before_insert_update(); Type: COMMENT; Schema: aux; Owner: postgres
--

COMMENT ON FUNCTION aux.validate_url_before_insert_update() IS 'Função genérica de trigger para validar URL automaticamente';


--
-- TOC entry 403 (class 1255 OID 21534)
-- Name: calculate_total_items(); Type: FUNCTION; Schema: quotation; Owner: postgres
--

CREATE FUNCTION quotation.calculate_total_items() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Atualiza o total_items na tabela quotation_submissions
    UPDATE quotation.quotation_submissions 
    SET total_items = (
        SELECT COUNT(*) 
        FROM quotation.shopping_list_items 
        WHERE shopping_list_id = NEW.shopping_list_id
    )
    WHERE shopping_list_id = NEW.shopping_list_id;
    
    RETURN NEW;
END;
$$;


ALTER FUNCTION quotation.calculate_total_items() OWNER TO postgres;

--
-- TOC entry 6605 (class 0 OID 0)
-- Dependencies: 403
-- Name: FUNCTION calculate_total_items(); Type: COMMENT; Schema: quotation; Owner: postgres
--

COMMENT ON FUNCTION quotation.calculate_total_items() IS 'Função para calcular automaticamente o total de itens em quotation_submissions baseado na quantidade de itens em shopping_list_items';


--
-- TOC entry 478 (class 1255 OID 21533)
-- Name: set_updated_at(); Type: FUNCTION; Schema: quotation; Owner: postgres
--

CREATE FUNCTION quotation.set_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END;
$$;


ALTER FUNCTION quotation.set_updated_at() OWNER TO postgres;

--
-- TOC entry 6606 (class 0 OID 0)
-- Dependencies: 478
-- Name: FUNCTION set_updated_at(); Type: COMMENT; Schema: quotation; Owner: postgres
--

COMMENT ON FUNCTION quotation.set_updated_at() IS 'Função para atualizar automaticamente o campo updated_at das tabelas';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 254 (class 1259 OID 17697)
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
-- TOC entry 6607 (class 0 OID 0)
-- Dependencies: 254
-- Name: TABLE api_keys; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON TABLE accounts.api_keys IS 'Chaves de autenticação geradas para integração de APIs por employees';


--
-- TOC entry 6608 (class 0 OID 0)
-- Dependencies: 254
-- Name: COLUMN api_keys.api_key_id; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.api_keys.api_key_id IS 'Identificador único da chave de API';


--
-- TOC entry 6609 (class 0 OID 0)
-- Dependencies: 254
-- Name: COLUMN api_keys.employee_id; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.api_keys.employee_id IS 'Employee que possui a chave';


--
-- TOC entry 6610 (class 0 OID 0)
-- Dependencies: 254
-- Name: COLUMN api_keys.name; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.api_keys.name IS 'Nome de exibição da chave';


--
-- TOC entry 6611 (class 0 OID 0)
-- Dependencies: 254
-- Name: COLUMN api_keys.secret; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.api_keys.secret IS 'Chave secreta usada na autenticação';


--
-- TOC entry 6612 (class 0 OID 0)
-- Dependencies: 254
-- Name: COLUMN api_keys.created_at; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.api_keys.created_at IS 'Data de criação do registro';


--
-- TOC entry 6613 (class 0 OID 0)
-- Dependencies: 254
-- Name: COLUMN api_keys.updated_at; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.api_keys.updated_at IS 'Data da última atualização do registro';


--
-- TOC entry 255 (class 1259 OID 17711)
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
-- TOC entry 6614 (class 0 OID 0)
-- Dependencies: 255
-- Name: TABLE api_scopes; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON TABLE accounts.api_scopes IS 'Define os escopos de acesso das chaves de API às features do sistema';


--
-- TOC entry 6615 (class 0 OID 0)
-- Dependencies: 255
-- Name: COLUMN api_scopes.api_scope_id; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.api_scopes.api_scope_id IS 'Identificador único do escopo';


--
-- TOC entry 6616 (class 0 OID 0)
-- Dependencies: 255
-- Name: COLUMN api_scopes.api_key_id; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.api_scopes.api_key_id IS 'Chave de API à qual o escopo pertence';


--
-- TOC entry 6617 (class 0 OID 0)
-- Dependencies: 255
-- Name: COLUMN api_scopes.feature_id; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.api_scopes.feature_id IS 'Feature autorizada para acesso via API';


--
-- TOC entry 6618 (class 0 OID 0)
-- Dependencies: 255
-- Name: COLUMN api_scopes.created_at; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.api_scopes.created_at IS 'Data de criação do registro';


--
-- TOC entry 253 (class 1259 OID 17420)
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
-- TOC entry 6619 (class 0 OID 0)
-- Dependencies: 253
-- Name: TABLE apis; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON TABLE accounts.apis IS 'Endpoints expostos da API vinculados a features do sistema';


--
-- TOC entry 6620 (class 0 OID 0)
-- Dependencies: 253
-- Name: COLUMN apis.api_id; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.apis.api_id IS 'Identificador único da API';


--
-- TOC entry 6621 (class 0 OID 0)
-- Dependencies: 253
-- Name: COLUMN apis.path; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.apis.path IS 'Caminho do endpoint (ex: /purchases)';


--
-- TOC entry 6622 (class 0 OID 0)
-- Dependencies: 253
-- Name: COLUMN apis.method; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.apis.method IS 'Método HTTP (ex: GET, POST, PUT)';


--
-- TOC entry 6623 (class 0 OID 0)
-- Dependencies: 253
-- Name: COLUMN apis.description; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.apis.description IS 'Descrição do funcionamento do endpoint';


--
-- TOC entry 6624 (class 0 OID 0)
-- Dependencies: 253
-- Name: COLUMN apis.created_at; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.apis.created_at IS 'Data de criação do endpoint';


--
-- TOC entry 6625 (class 0 OID 0)
-- Dependencies: 253
-- Name: COLUMN apis.updated_at; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.apis.updated_at IS 'Data de última atualização do endpoint';


--
-- TOC entry 362 (class 1259 OID 21204)
-- Name: employee_addresses; Type: TABLE; Schema: accounts; Owner: postgres
--

CREATE TABLE accounts.employee_addresses (
    employee_address_id uuid DEFAULT gen_random_uuid() NOT NULL,
    employee_id uuid NOT NULL,
    postal_code text NOT NULL,
    street text NOT NULL,
    number text NOT NULL,
    complement text,
    neighborhood text NOT NULL,
    city text NOT NULL,
    state text NOT NULL,
    is_primary boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone,
    CONSTRAINT employee_addresses_city_length CHECK (((length(city) >= 2) AND (length(city) <= 100))),
    CONSTRAINT employee_addresses_dates_valid CHECK (((created_at <= now()) AND ((updated_at IS NULL) OR (updated_at <= now())))),
    CONSTRAINT employee_addresses_neighborhood_length CHECK (((length(neighborhood) >= 2) AND (length(neighborhood) <= 100))),
    CONSTRAINT employee_addresses_number_length CHECK (((length(number) >= 1) AND (length(number) <= 20))),
    CONSTRAINT employee_addresses_postal_code_clean CHECK ((postal_code ~ '^\d{8}$'::text)),
    CONSTRAINT employee_addresses_state_valid CHECK ((state = ANY (ARRAY['AC'::text, 'AL'::text, 'AP'::text, 'AM'::text, 'BA'::text, 'CE'::text, 'DF'::text, 'ES'::text, 'GO'::text, 'MA'::text, 'MT'::text, 'MS'::text, 'MG'::text, 'PA'::text, 'PB'::text, 'PR'::text, 'PE'::text, 'PI'::text, 'RJ'::text, 'RN'::text, 'RS'::text, 'RO'::text, 'RR'::text, 'SC'::text, 'SP'::text, 'SE'::text, 'TO'::text]))),
    CONSTRAINT employee_addresses_street_length CHECK (((length(street) >= 2) AND (length(street) <= 200)))
);


ALTER TABLE accounts.employee_addresses OWNER TO postgres;

--
-- TOC entry 6626 (class 0 OID 0)
-- Dependencies: 362
-- Name: TABLE employee_addresses; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON TABLE accounts.employee_addresses IS 'Endereços dos funcionários';


--
-- TOC entry 6627 (class 0 OID 0)
-- Dependencies: 362
-- Name: COLUMN employee_addresses.employee_address_id; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.employee_addresses.employee_address_id IS 'ID único do endereço';


--
-- TOC entry 6628 (class 0 OID 0)
-- Dependencies: 362
-- Name: COLUMN employee_addresses.employee_id; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.employee_addresses.employee_id IS 'Referência ao funcionário';


--
-- TOC entry 6629 (class 0 OID 0)
-- Dependencies: 362
-- Name: COLUMN employee_addresses.postal_code; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.employee_addresses.postal_code IS 'CEP (apenas números)';


--
-- TOC entry 6630 (class 0 OID 0)
-- Dependencies: 362
-- Name: COLUMN employee_addresses.street; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.employee_addresses.street IS 'Nome da rua';


--
-- TOC entry 6631 (class 0 OID 0)
-- Dependencies: 362
-- Name: COLUMN employee_addresses.number; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.employee_addresses.number IS 'Número do endereço';


--
-- TOC entry 6632 (class 0 OID 0)
-- Dependencies: 362
-- Name: COLUMN employee_addresses.complement; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.employee_addresses.complement IS 'Complemento do endereço';


--
-- TOC entry 6633 (class 0 OID 0)
-- Dependencies: 362
-- Name: COLUMN employee_addresses.neighborhood; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.employee_addresses.neighborhood IS 'Bairro';


--
-- TOC entry 6634 (class 0 OID 0)
-- Dependencies: 362
-- Name: COLUMN employee_addresses.city; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.employee_addresses.city IS 'Cidade';


--
-- TOC entry 6635 (class 0 OID 0)
-- Dependencies: 362
-- Name: COLUMN employee_addresses.state; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.employee_addresses.state IS 'Estado (UF)';


--
-- TOC entry 6636 (class 0 OID 0)
-- Dependencies: 362
-- Name: COLUMN employee_addresses.is_primary; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.employee_addresses.is_primary IS 'Indica se é o endereço principal';


--
-- TOC entry 6637 (class 0 OID 0)
-- Dependencies: 362
-- Name: COLUMN employee_addresses.created_at; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.employee_addresses.created_at IS 'Data de criação do registro';


--
-- TOC entry 6638 (class 0 OID 0)
-- Dependencies: 362
-- Name: COLUMN employee_addresses.updated_at; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.employee_addresses.updated_at IS 'Data da última atualização';


--
-- TOC entry 361 (class 1259 OID 21180)
-- Name: employee_personal_data; Type: TABLE; Schema: accounts; Owner: postgres
--

CREATE TABLE accounts.employee_personal_data (
    employee_personal_data_id uuid DEFAULT gen_random_uuid() NOT NULL,
    employee_id uuid NOT NULL,
    cpf text NOT NULL,
    full_name text NOT NULL,
    birth_date date NOT NULL,
    gender text NOT NULL,
    photo_url text,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone,
    CONSTRAINT employee_personal_data_birth_date_valid CHECK (aux.validate_birth_date(birth_date, 14)),
    CONSTRAINT employee_personal_data_cpf_clean CHECK ((cpf ~ '^\d{11}$'::text)),
    CONSTRAINT employee_personal_data_dates_valid CHECK (((created_at <= now()) AND ((updated_at IS NULL) OR (updated_at <= now())))),
    CONSTRAINT employee_personal_data_full_name_length CHECK (((length(full_name) >= 2) AND (length(full_name) <= 100))),
    CONSTRAINT employee_personal_data_gender_valid CHECK ((gender = ANY (ARRAY['M'::text, 'F'::text, 'O'::text]))),
    CONSTRAINT employee_personal_data_photo_url_valid CHECK (aux.validate_url(photo_url))
);


ALTER TABLE accounts.employee_personal_data OWNER TO postgres;

--
-- TOC entry 6639 (class 0 OID 0)
-- Dependencies: 361
-- Name: TABLE employee_personal_data; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON TABLE accounts.employee_personal_data IS 'Dados pessoais dos funcionários (CPF, nome, nascimento, sexo, foto)';


--
-- TOC entry 6640 (class 0 OID 0)
-- Dependencies: 361
-- Name: COLUMN employee_personal_data.employee_personal_data_id; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.employee_personal_data.employee_personal_data_id IS 'ID único dos dados pessoais';


--
-- TOC entry 6641 (class 0 OID 0)
-- Dependencies: 361
-- Name: COLUMN employee_personal_data.employee_id; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.employee_personal_data.employee_id IS 'Referência ao funcionário';


--
-- TOC entry 6642 (class 0 OID 0)
-- Dependencies: 361
-- Name: COLUMN employee_personal_data.cpf; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.employee_personal_data.cpf IS 'CPF do funcionário (apenas números)';


--
-- TOC entry 6643 (class 0 OID 0)
-- Dependencies: 361
-- Name: COLUMN employee_personal_data.full_name; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.employee_personal_data.full_name IS 'Nome completo do funcionário';


--
-- TOC entry 6644 (class 0 OID 0)
-- Dependencies: 361
-- Name: COLUMN employee_personal_data.birth_date; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.employee_personal_data.birth_date IS 'Data de nascimento';


--
-- TOC entry 6645 (class 0 OID 0)
-- Dependencies: 361
-- Name: COLUMN employee_personal_data.gender; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.employee_personal_data.gender IS 'Sexo (M=Masculino, F=Feminino, O=Outro)';


--
-- TOC entry 6646 (class 0 OID 0)
-- Dependencies: 361
-- Name: COLUMN employee_personal_data.photo_url; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.employee_personal_data.photo_url IS 'URL da foto do funcionário (opcional)';


--
-- TOC entry 6647 (class 0 OID 0)
-- Dependencies: 361
-- Name: COLUMN employee_personal_data.created_at; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.employee_personal_data.created_at IS 'Data de criação do registro';


--
-- TOC entry 6648 (class 0 OID 0)
-- Dependencies: 361
-- Name: COLUMN employee_personal_data.updated_at; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.employee_personal_data.updated_at IS 'Data da última atualização';


--
-- TOC entry 252 (class 1259 OID 17398)
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
-- TOC entry 6649 (class 0 OID 0)
-- Dependencies: 252
-- Name: TABLE employee_roles; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON TABLE accounts.employee_roles IS 'Vínculos entre funcionários e papéis nomeados (roles)';


--
-- TOC entry 6650 (class 0 OID 0)
-- Dependencies: 252
-- Name: COLUMN employee_roles.employee_role_id; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.employee_roles.employee_role_id IS 'Identificador do vínculo entre employee e role';


--
-- TOC entry 6651 (class 0 OID 0)
-- Dependencies: 252
-- Name: COLUMN employee_roles.employee_id; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.employee_roles.employee_id IS 'Funcionário que recebe o papel';


--
-- TOC entry 6652 (class 0 OID 0)
-- Dependencies: 252
-- Name: COLUMN employee_roles.role_id; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.employee_roles.role_id IS 'Papel atribuído ao funcionário';


--
-- TOC entry 6653 (class 0 OID 0)
-- Dependencies: 252
-- Name: COLUMN employee_roles.granted_at; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.employee_roles.granted_at IS 'Data de concessão do papel';


--
-- TOC entry 6654 (class 0 OID 0)
-- Dependencies: 252
-- Name: COLUMN employee_roles.updated_at; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.employee_roles.updated_at IS 'Data da última modificação do vínculo';


--
-- TOC entry 246 (class 1259 OID 17272)
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
-- TOC entry 6655 (class 0 OID 0)
-- Dependencies: 246
-- Name: TABLE employees; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON TABLE accounts.employees IS 'Funcionários vinculados a fornecedores ou estabelecimentos';


--
-- TOC entry 6656 (class 0 OID 0)
-- Dependencies: 246
-- Name: COLUMN employees.employee_id; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.employees.employee_id IS 'Identificador do vínculo funcional';


--
-- TOC entry 6657 (class 0 OID 0)
-- Dependencies: 246
-- Name: COLUMN employees.user_id; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.employees.user_id IS 'Usuário associado ao funcionário';


--
-- TOC entry 6658 (class 0 OID 0)
-- Dependencies: 246
-- Name: COLUMN employees.supplier_id; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.employees.supplier_id IS 'Fornecedor ao qual o funcionário pertence';


--
-- TOC entry 6659 (class 0 OID 0)
-- Dependencies: 246
-- Name: COLUMN employees.establishment_id; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.employees.establishment_id IS 'Estabelecimento ao qual o funcionário pertence';


--
-- TOC entry 6660 (class 0 OID 0)
-- Dependencies: 246
-- Name: COLUMN employees.is_active; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.employees.is_active IS 'Se o vínculo está ativo';


--
-- TOC entry 6661 (class 0 OID 0)
-- Dependencies: 246
-- Name: COLUMN employees.activated_at; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.employees.activated_at IS 'Data de ativação do vínculo';


--
-- TOC entry 6662 (class 0 OID 0)
-- Dependencies: 246
-- Name: COLUMN employees.deactivated_at; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.employees.deactivated_at IS 'Data de desativação do vínculo';


--
-- TOC entry 6663 (class 0 OID 0)
-- Dependencies: 246
-- Name: COLUMN employees.created_at; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.employees.created_at IS 'Data de criação';


--
-- TOC entry 6664 (class 0 OID 0)
-- Dependencies: 246
-- Name: COLUMN employees.updated_at; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.employees.updated_at IS 'Data da última atualização';


--
-- TOC entry 273 (class 1259 OID 18335)
-- Name: establishment_addresses; Type: TABLE; Schema: accounts; Owner: postgres
--

CREATE TABLE accounts.establishment_addresses (
    establishment_address_id uuid DEFAULT gen_random_uuid() NOT NULL,
    establishment_id uuid NOT NULL,
    postal_code text NOT NULL,
    street text NOT NULL,
    number text NOT NULL,
    complement text,
    neighborhood text NOT NULL,
    city text NOT NULL,
    state text NOT NULL,
    is_primary boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone,
    CONSTRAINT establishment_addresses_postal_code_check CHECK ((postal_code ~ '^\d{8}$'::text)),
    CONSTRAINT establishment_addresses_postal_code_clean CHECK ((postal_code ~ '^\d{8}$'::text)),
    CONSTRAINT establishment_addresses_state_check CHECK ((state ~ '^[A-Z]{2}$'::text))
);


ALTER TABLE accounts.establishment_addresses OWNER TO postgres;

--
-- TOC entry 6665 (class 0 OID 0)
-- Dependencies: 273
-- Name: TABLE establishment_addresses; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON TABLE accounts.establishment_addresses IS 'Endereços dos estabelecimentos';


--
-- TOC entry 6666 (class 0 OID 0)
-- Dependencies: 273
-- Name: COLUMN establishment_addresses.establishment_address_id; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.establishment_addresses.establishment_address_id IS 'Identificador único do endereço';


--
-- TOC entry 6667 (class 0 OID 0)
-- Dependencies: 273
-- Name: COLUMN establishment_addresses.establishment_id; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.establishment_addresses.establishment_id IS 'Referência ao estabelecimento';


--
-- TOC entry 6668 (class 0 OID 0)
-- Dependencies: 273
-- Name: COLUMN establishment_addresses.postal_code; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.establishment_addresses.postal_code IS 'CEP (apenas números, 8 dígitos)';


--
-- TOC entry 6669 (class 0 OID 0)
-- Dependencies: 273
-- Name: COLUMN establishment_addresses.street; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.establishment_addresses.street IS 'Logradouro (Rua, Avenida, etc.)';


--
-- TOC entry 6670 (class 0 OID 0)
-- Dependencies: 273
-- Name: COLUMN establishment_addresses.number; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.establishment_addresses.number IS 'Número do endereço';


--
-- TOC entry 6671 (class 0 OID 0)
-- Dependencies: 273
-- Name: COLUMN establishment_addresses.complement; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.establishment_addresses.complement IS 'Complemento do endereço (opcional)';


--
-- TOC entry 6672 (class 0 OID 0)
-- Dependencies: 273
-- Name: COLUMN establishment_addresses.neighborhood; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.establishment_addresses.neighborhood IS 'Bairro';


--
-- TOC entry 6673 (class 0 OID 0)
-- Dependencies: 273
-- Name: COLUMN establishment_addresses.city; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.establishment_addresses.city IS 'Cidade';


--
-- TOC entry 6674 (class 0 OID 0)
-- Dependencies: 273
-- Name: COLUMN establishment_addresses.state; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.establishment_addresses.state IS 'Estado (sigla de 2 letras)';


--
-- TOC entry 6675 (class 0 OID 0)
-- Dependencies: 273
-- Name: COLUMN establishment_addresses.is_primary; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.establishment_addresses.is_primary IS 'Indica se é o endereço principal';


--
-- TOC entry 6676 (class 0 OID 0)
-- Dependencies: 273
-- Name: COLUMN establishment_addresses.created_at; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.establishment_addresses.created_at IS 'Data de criação do registro';


--
-- TOC entry 6677 (class 0 OID 0)
-- Dependencies: 273
-- Name: COLUMN establishment_addresses.updated_at; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.establishment_addresses.updated_at IS 'Data da última atualização';


--
-- TOC entry 272 (class 1259 OID 18317)
-- Name: establishment_business_data; Type: TABLE; Schema: accounts; Owner: postgres
--

CREATE TABLE accounts.establishment_business_data (
    establishment_business_data_id uuid DEFAULT gen_random_uuid() NOT NULL,
    establishment_id uuid NOT NULL,
    cnpj text NOT NULL,
    trade_name text NOT NULL,
    corporate_name text NOT NULL,
    state_registration text,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone,
    CONSTRAINT establishment_business_data_cnpj_clean CHECK ((cnpj ~ '^\d{14}$'::text))
);


ALTER TABLE accounts.establishment_business_data OWNER TO postgres;

--
-- TOC entry 6678 (class 0 OID 0)
-- Dependencies: 272
-- Name: TABLE establishment_business_data; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON TABLE accounts.establishment_business_data IS 'Dados empresariais específicos dos estabelecimentos (CNPJ, Razão Social, etc.)';


--
-- TOC entry 6679 (class 0 OID 0)
-- Dependencies: 272
-- Name: COLUMN establishment_business_data.establishment_business_data_id; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.establishment_business_data.establishment_business_data_id IS 'Identificador único dos dados empresariais';


--
-- TOC entry 6680 (class 0 OID 0)
-- Dependencies: 272
-- Name: COLUMN establishment_business_data.establishment_id; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.establishment_business_data.establishment_id IS 'Referência ao estabelecimento';


--
-- TOC entry 6681 (class 0 OID 0)
-- Dependencies: 272
-- Name: COLUMN establishment_business_data.cnpj; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.establishment_business_data.cnpj IS 'CNPJ da empresa (apenas números, 14 dígitos)';


--
-- TOC entry 6682 (class 0 OID 0)
-- Dependencies: 272
-- Name: COLUMN establishment_business_data.trade_name; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.establishment_business_data.trade_name IS 'Nome Fantasia da empresa';


--
-- TOC entry 6683 (class 0 OID 0)
-- Dependencies: 272
-- Name: COLUMN establishment_business_data.corporate_name; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.establishment_business_data.corporate_name IS 'Razão Social da empresa';


--
-- TOC entry 6684 (class 0 OID 0)
-- Dependencies: 272
-- Name: COLUMN establishment_business_data.state_registration; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.establishment_business_data.state_registration IS 'Número da Inscrição Estadual';


--
-- TOC entry 6685 (class 0 OID 0)
-- Dependencies: 272
-- Name: COLUMN establishment_business_data.created_at; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.establishment_business_data.created_at IS 'Data de criação do registro';


--
-- TOC entry 6686 (class 0 OID 0)
-- Dependencies: 272
-- Name: COLUMN establishment_business_data.updated_at; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.establishment_business_data.updated_at IS 'Data da última atualização';


--
-- TOC entry 245 (class 1259 OID 17256)
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
-- TOC entry 6687 (class 0 OID 0)
-- Dependencies: 245
-- Name: TABLE establishments; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON TABLE accounts.establishments IS 'Estabelecimentos que utilizam o sistema e possuem funcionários';


--
-- TOC entry 6688 (class 0 OID 0)
-- Dependencies: 245
-- Name: COLUMN establishments.establishment_id; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.establishments.establishment_id IS 'Identificador único do estabelecimento';


--
-- TOC entry 6689 (class 0 OID 0)
-- Dependencies: 245
-- Name: COLUMN establishments.name; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.establishments.name IS 'Nome do estabelecimento';


--
-- TOC entry 6690 (class 0 OID 0)
-- Dependencies: 245
-- Name: COLUMN establishments.is_active; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.establishments.is_active IS 'Indica se o estabelecimento está ativo';


--
-- TOC entry 6691 (class 0 OID 0)
-- Dependencies: 245
-- Name: COLUMN establishments.activated_at; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.establishments.activated_at IS 'Data de ativação';


--
-- TOC entry 6692 (class 0 OID 0)
-- Dependencies: 245
-- Name: COLUMN establishments.deactivated_at; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.establishments.deactivated_at IS 'Data de desativação';


--
-- TOC entry 6693 (class 0 OID 0)
-- Dependencies: 245
-- Name: COLUMN establishments.created_at; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.establishments.created_at IS 'Data de criação do registro';


--
-- TOC entry 6694 (class 0 OID 0)
-- Dependencies: 245
-- Name: COLUMN establishments.updated_at; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.establishments.updated_at IS 'Data da última atualização do registro';


--
-- TOC entry 249 (class 1259 OID 17339)
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
-- TOC entry 6695 (class 0 OID 0)
-- Dependencies: 249
-- Name: TABLE features; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON TABLE accounts.features IS 'Funcionalidades específicas associadas a módulos';


--
-- TOC entry 6696 (class 0 OID 0)
-- Dependencies: 249
-- Name: COLUMN features.feature_id; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.features.feature_id IS 'Identificador da feature';


--
-- TOC entry 6697 (class 0 OID 0)
-- Dependencies: 249
-- Name: COLUMN features.module_id; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.features.module_id IS 'Módulo ao qual a feature pertence';


--
-- TOC entry 6698 (class 0 OID 0)
-- Dependencies: 249
-- Name: COLUMN features.name; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.features.name IS 'Nome da feature';


--
-- TOC entry 6699 (class 0 OID 0)
-- Dependencies: 249
-- Name: COLUMN features.code; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.features.code IS 'Código único da feature (para verificação de permissão)';


--
-- TOC entry 6700 (class 0 OID 0)
-- Dependencies: 249
-- Name: COLUMN features.description; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.features.description IS 'Descrição da feature';


--
-- TOC entry 6701 (class 0 OID 0)
-- Dependencies: 249
-- Name: COLUMN features.created_at; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.features.created_at IS 'Data de criação';


--
-- TOC entry 6702 (class 0 OID 0)
-- Dependencies: 249
-- Name: COLUMN features.updated_at; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.features.updated_at IS 'Data da última atualização';


--
-- TOC entry 248 (class 1259 OID 17318)
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
-- TOC entry 6703 (class 0 OID 0)
-- Dependencies: 248
-- Name: TABLE modules; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON TABLE accounts.modules IS 'Módulos funcionais do sistema (ex: Lista de Compras)';


--
-- TOC entry 6704 (class 0 OID 0)
-- Dependencies: 248
-- Name: COLUMN modules.module_id; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.modules.module_id IS 'Identificador único do módulo';


--
-- TOC entry 6705 (class 0 OID 0)
-- Dependencies: 248
-- Name: COLUMN modules.name; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.modules.name IS 'Nome do módulo';


--
-- TOC entry 6706 (class 0 OID 0)
-- Dependencies: 248
-- Name: COLUMN modules.description; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.modules.description IS 'Descrição do módulo';


--
-- TOC entry 6707 (class 0 OID 0)
-- Dependencies: 248
-- Name: COLUMN modules.created_at; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.modules.created_at IS 'Data de criação';


--
-- TOC entry 6708 (class 0 OID 0)
-- Dependencies: 248
-- Name: COLUMN modules.updated_at; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.modules.updated_at IS 'Data da última atualização';


--
-- TOC entry 247 (class 1259 OID 17302)
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
-- TOC entry 6709 (class 0 OID 0)
-- Dependencies: 247
-- Name: TABLE platforms; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON TABLE accounts.platforms IS 'Plataformas do sistema, como Área do Fornecedor, Aplicativo do Estabelecimento, etc.';


--
-- TOC entry 6710 (class 0 OID 0)
-- Dependencies: 247
-- Name: COLUMN platforms.platform_id; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.platforms.platform_id IS 'Identificador único da plataforma';


--
-- TOC entry 6711 (class 0 OID 0)
-- Dependencies: 247
-- Name: COLUMN platforms.name; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.platforms.name IS 'Nome da plataforma (ex: Área do Fornecedor)';


--
-- TOC entry 6712 (class 0 OID 0)
-- Dependencies: 247
-- Name: COLUMN platforms.description; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.platforms.description IS 'Descrição da plataforma';


--
-- TOC entry 6713 (class 0 OID 0)
-- Dependencies: 247
-- Name: COLUMN platforms.created_at; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.platforms.created_at IS 'Data de criação da plataforma';


--
-- TOC entry 6714 (class 0 OID 0)
-- Dependencies: 247
-- Name: COLUMN platforms.updated_at; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.platforms.updated_at IS 'Data da última atualização da plataforma';


--
-- TOC entry 251 (class 1259 OID 17376)
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
-- TOC entry 6715 (class 0 OID 0)
-- Dependencies: 251
-- Name: TABLE role_features; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON TABLE accounts.role_features IS 'Relaciona os papéis do sistema com suas permissões (features)';


--
-- TOC entry 6716 (class 0 OID 0)
-- Dependencies: 251
-- Name: COLUMN role_features.role_feature_id; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.role_features.role_feature_id IS 'Identificador único do vínculo role-feature';


--
-- TOC entry 6717 (class 0 OID 0)
-- Dependencies: 251
-- Name: COLUMN role_features.role_id; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.role_features.role_id IS 'Papel que receberá as permissões';


--
-- TOC entry 6718 (class 0 OID 0)
-- Dependencies: 251
-- Name: COLUMN role_features.feature_id; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.role_features.feature_id IS 'Permissão (feature) associada ao papel';


--
-- TOC entry 6719 (class 0 OID 0)
-- Dependencies: 251
-- Name: COLUMN role_features.created_at; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.role_features.created_at IS 'Data de criação';


--
-- TOC entry 6720 (class 0 OID 0)
-- Dependencies: 251
-- Name: COLUMN role_features.updated_at; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.role_features.updated_at IS 'Data da última modificação';


--
-- TOC entry 250 (class 1259 OID 17360)
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
-- TOC entry 6721 (class 0 OID 0)
-- Dependencies: 250
-- Name: TABLE roles; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON TABLE accounts.roles IS 'Papéis nomeados do sistema que agrupam permissões';


--
-- TOC entry 6722 (class 0 OID 0)
-- Dependencies: 250
-- Name: COLUMN roles.role_id; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.roles.role_id IS 'Identificador único do papel';


--
-- TOC entry 6723 (class 0 OID 0)
-- Dependencies: 250
-- Name: COLUMN roles.name; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.roles.name IS 'Nome do papel (ex: comprador, gestor)';


--
-- TOC entry 6724 (class 0 OID 0)
-- Dependencies: 250
-- Name: COLUMN roles.description; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.roles.description IS 'Descrição funcional do papel';


--
-- TOC entry 6725 (class 0 OID 0)
-- Dependencies: 250
-- Name: COLUMN roles.created_at; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.roles.created_at IS 'Data de criação';


--
-- TOC entry 6726 (class 0 OID 0)
-- Dependencies: 250
-- Name: COLUMN roles.updated_at; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.roles.updated_at IS 'Data da última atualização';


--
-- TOC entry 244 (class 1259 OID 17240)
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
-- TOC entry 6727 (class 0 OID 0)
-- Dependencies: 244
-- Name: TABLE suppliers; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON TABLE accounts.suppliers IS 'Fornecedores do sistema, que possuem funcionários e filiais';


--
-- TOC entry 6728 (class 0 OID 0)
-- Dependencies: 244
-- Name: COLUMN suppliers.supplier_id; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.suppliers.supplier_id IS 'Identificador único do fornecedor';


--
-- TOC entry 6729 (class 0 OID 0)
-- Dependencies: 244
-- Name: COLUMN suppliers.name; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.suppliers.name IS 'Nome do fornecedor';


--
-- TOC entry 6730 (class 0 OID 0)
-- Dependencies: 244
-- Name: COLUMN suppliers.is_active; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.suppliers.is_active IS 'Indica se o fornecedor está ativo';


--
-- TOC entry 6731 (class 0 OID 0)
-- Dependencies: 244
-- Name: COLUMN suppliers.activated_at; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.suppliers.activated_at IS 'Data de ativação';


--
-- TOC entry 6732 (class 0 OID 0)
-- Dependencies: 244
-- Name: COLUMN suppliers.deactivated_at; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.suppliers.deactivated_at IS 'Data de desativação';


--
-- TOC entry 6733 (class 0 OID 0)
-- Dependencies: 244
-- Name: COLUMN suppliers.created_at; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.suppliers.created_at IS 'Data de criação do registro';


--
-- TOC entry 6734 (class 0 OID 0)
-- Dependencies: 244
-- Name: COLUMN suppliers.updated_at; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.suppliers.updated_at IS 'Data da última atualização do registro';


--
-- TOC entry 243 (class 1259 OID 17226)
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
-- TOC entry 6735 (class 0 OID 0)
-- Dependencies: 243
-- Name: TABLE users; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON TABLE accounts.users IS 'Usuários autenticáveis no sistema (funcionários)';


--
-- TOC entry 6736 (class 0 OID 0)
-- Dependencies: 243
-- Name: COLUMN users.user_id; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.users.user_id IS 'Identificador único do usuário';


--
-- TOC entry 6737 (class 0 OID 0)
-- Dependencies: 243
-- Name: COLUMN users.email; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.users.email IS 'Endereço de e-mail usado para login';


--
-- TOC entry 6738 (class 0 OID 0)
-- Dependencies: 243
-- Name: COLUMN users.full_name; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.users.full_name IS 'Nome completo do usuário';


--
-- TOC entry 6739 (class 0 OID 0)
-- Dependencies: 243
-- Name: COLUMN users.cognito_sub; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.users.cognito_sub IS 'Identificador único do Cognito (OAuth/Auth)';


--
-- TOC entry 6740 (class 0 OID 0)
-- Dependencies: 243
-- Name: COLUMN users.is_active; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.users.is_active IS 'Indica se o usuário está ativo no sistema';


--
-- TOC entry 6741 (class 0 OID 0)
-- Dependencies: 243
-- Name: COLUMN users.created_at; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.users.created_at IS 'Data de criação do registro';


--
-- TOC entry 6742 (class 0 OID 0)
-- Dependencies: 243
-- Name: COLUMN users.updated_at; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON COLUMN accounts.users.updated_at IS 'Data da última atualização do registro';


--
-- TOC entry 257 (class 1259 OID 17743)
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
-- TOC entry 6743 (class 0 OID 0)
-- Dependencies: 257
-- Name: VIEW v_api_key_feature_scope; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON VIEW accounts.v_api_key_feature_scope IS 'View que mostra quais features uma chave de API tem acesso, incluindo escopo completo de plataforma e módulo.';


--
-- TOC entry 256 (class 1259 OID 17738)
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
-- TOC entry 6744 (class 0 OID 0)
-- Dependencies: 256
-- Name: VIEW v_employee_feature_access; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON VIEW accounts.v_employee_feature_access IS 'View consolidada com as features acessíveis por cada employee e seu contexto organizacional';


--
-- TOC entry 397 (class 1259 OID 21993)
-- Name: v_establishments_complete; Type: VIEW; Schema: accounts; Owner: postgres
--

CREATE VIEW accounts.v_establishments_complete AS
 SELECT e.establishment_id,
    e.name,
    e.is_active,
    e.created_at,
    e.updated_at,
    ebd.cnpj,
    ebd.trade_name,
    ebd.corporate_name,
    ebd.state_registration,
    ebd.created_at AS business_data_created_at,
    ebd.updated_at AS business_data_updated_at,
    ea.postal_code,
    ea.street,
    ea.number,
    ea.complement,
    ea.neighborhood,
    ea.city,
    (ea.state)::aux.estado_brasileiro AS state_validated,
    ea.is_primary,
    ea.created_at AS address_created_at,
    ea.updated_at AS address_updated_at
   FROM ((accounts.establishments e
     LEFT JOIN accounts.establishment_business_data ebd ON ((e.establishment_id = ebd.establishment_id)))
     LEFT JOIN accounts.establishment_addresses ea ON (((e.establishment_id = ea.establishment_id) AND (ea.is_primary = true))));


ALTER VIEW accounts.v_establishments_complete OWNER TO postgres;

--
-- TOC entry 6745 (class 0 OID 0)
-- Dependencies: 397
-- Name: VIEW v_establishments_complete; Type: COMMENT; Schema: accounts; Owner: postgres
--

COMMENT ON VIEW accounts.v_establishments_complete IS 'View consolidada de estabelecimentos usando validacoes do schema aux';


--
-- TOC entry 275 (class 1259 OID 20084)
-- Name: accounts__api_keys; Type: TABLE; Schema: audit; Owner: postgres
--

CREATE TABLE audit.accounts__api_keys (
    api_key_id uuid NOT NULL,
    employee_id uuid NOT NULL,
    name text NOT NULL,
    secret text NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone,
    audit_id bigint NOT NULL,
    audit_operation text NOT NULL,
    audit_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    audit_user text DEFAULT CURRENT_USER NOT NULL,
    audit_session_id text DEFAULT current_setting('application_name'::text) NOT NULL,
    audit_connection_id text DEFAULT inet_client_addr() NOT NULL,
    audit_partition_date date DEFAULT CURRENT_DATE NOT NULL
)
PARTITION BY RANGE (audit_partition_date);


ALTER TABLE audit.accounts__api_keys OWNER TO postgres;

--
-- TOC entry 6746 (class 0 OID 0)
-- Dependencies: 275
-- Name: TABLE accounts__api_keys; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON TABLE audit.accounts__api_keys IS 'AUDITORIA: Chaves de autenticação geradas para integração de APIs por employees';


--
-- TOC entry 6747 (class 0 OID 0)
-- Dependencies: 275
-- Name: COLUMN accounts__api_keys.api_key_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__api_keys.api_key_id IS 'Identificador único da chave de API';


--
-- TOC entry 6748 (class 0 OID 0)
-- Dependencies: 275
-- Name: COLUMN accounts__api_keys.employee_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__api_keys.employee_id IS 'Employee que possui a chave';


--
-- TOC entry 6749 (class 0 OID 0)
-- Dependencies: 275
-- Name: COLUMN accounts__api_keys.name; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__api_keys.name IS 'Nome de exibição da chave';


--
-- TOC entry 6750 (class 0 OID 0)
-- Dependencies: 275
-- Name: COLUMN accounts__api_keys.secret; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__api_keys.secret IS 'Chave secreta usada na autenticação';


--
-- TOC entry 6751 (class 0 OID 0)
-- Dependencies: 275
-- Name: COLUMN accounts__api_keys.created_at; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__api_keys.created_at IS 'Data de criação do registro';


--
-- TOC entry 6752 (class 0 OID 0)
-- Dependencies: 275
-- Name: COLUMN accounts__api_keys.updated_at; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__api_keys.updated_at IS 'Data da última atualização do registro';


--
-- TOC entry 6753 (class 0 OID 0)
-- Dependencies: 275
-- Name: COLUMN accounts__api_keys.audit_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__api_keys.audit_id IS 'Identificador único do registro de auditoria';


--
-- TOC entry 6754 (class 0 OID 0)
-- Dependencies: 275
-- Name: COLUMN accounts__api_keys.audit_operation; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__api_keys.audit_operation IS 'Tipo de operação realizada (INSERT, UPDATE, DELETE)';


--
-- TOC entry 6755 (class 0 OID 0)
-- Dependencies: 275
-- Name: COLUMN accounts__api_keys.audit_timestamp; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__api_keys.audit_timestamp IS 'Data e hora da operação auditada';


--
-- TOC entry 6756 (class 0 OID 0)
-- Dependencies: 275
-- Name: COLUMN accounts__api_keys.audit_user; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__api_keys.audit_user IS 'Usuário que executou a operação';


--
-- TOC entry 6757 (class 0 OID 0)
-- Dependencies: 275
-- Name: COLUMN accounts__api_keys.audit_session_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__api_keys.audit_session_id IS 'Identificador da sessão da aplicação';


--
-- TOC entry 6758 (class 0 OID 0)
-- Dependencies: 275
-- Name: COLUMN accounts__api_keys.audit_connection_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__api_keys.audit_connection_id IS 'Endereço IP da conexão';


--
-- TOC entry 6759 (class 0 OID 0)
-- Dependencies: 275
-- Name: COLUMN accounts__api_keys.audit_partition_date; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__api_keys.audit_partition_date IS 'Data para particionamento da tabela de auditoria';


--
-- TOC entry 276 (class 1259 OID 20100)
-- Name: accounts__api_keys_2025_08; Type: TABLE; Schema: audit; Owner: postgres
--

CREATE TABLE audit.accounts__api_keys_2025_08 (
    api_key_id uuid NOT NULL,
    employee_id uuid NOT NULL,
    name text NOT NULL,
    secret text NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone,
    audit_id bigint NOT NULL,
    audit_operation text NOT NULL,
    audit_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    audit_user text DEFAULT CURRENT_USER NOT NULL,
    audit_session_id text DEFAULT current_setting('application_name'::text) NOT NULL,
    audit_connection_id text DEFAULT inet_client_addr() NOT NULL,
    audit_partition_date date DEFAULT CURRENT_DATE NOT NULL
);


ALTER TABLE audit.accounts__api_keys_2025_08 OWNER TO postgres;

--
-- TOC entry 274 (class 1259 OID 20083)
-- Name: accounts__api_keys_audit_id_seq; Type: SEQUENCE; Schema: audit; Owner: postgres
--

ALTER TABLE audit.accounts__api_keys ALTER COLUMN audit_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME audit.accounts__api_keys_audit_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 278 (class 1259 OID 20117)
-- Name: accounts__api_scopes; Type: TABLE; Schema: audit; Owner: postgres
--

CREATE TABLE audit.accounts__api_scopes (
    api_scope_id uuid NOT NULL,
    api_key_id uuid NOT NULL,
    feature_id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    audit_id bigint NOT NULL,
    audit_operation text NOT NULL,
    audit_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    audit_user text DEFAULT CURRENT_USER NOT NULL,
    audit_session_id text DEFAULT current_setting('application_name'::text) NOT NULL,
    audit_connection_id text DEFAULT inet_client_addr() NOT NULL,
    audit_partition_date date DEFAULT CURRENT_DATE NOT NULL
)
PARTITION BY RANGE (audit_partition_date);


ALTER TABLE audit.accounts__api_scopes OWNER TO postgres;

--
-- TOC entry 6760 (class 0 OID 0)
-- Dependencies: 278
-- Name: TABLE accounts__api_scopes; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON TABLE audit.accounts__api_scopes IS 'AUDITORIA: Define os escopos de acesso das chaves de API às features do sistema';


--
-- TOC entry 6761 (class 0 OID 0)
-- Dependencies: 278
-- Name: COLUMN accounts__api_scopes.api_scope_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__api_scopes.api_scope_id IS 'Identificador único do escopo';


--
-- TOC entry 6762 (class 0 OID 0)
-- Dependencies: 278
-- Name: COLUMN accounts__api_scopes.api_key_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__api_scopes.api_key_id IS 'Chave de API à qual o escopo pertence';


--
-- TOC entry 6763 (class 0 OID 0)
-- Dependencies: 278
-- Name: COLUMN accounts__api_scopes.feature_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__api_scopes.feature_id IS 'Feature autorizada para acesso via API';


--
-- TOC entry 6764 (class 0 OID 0)
-- Dependencies: 278
-- Name: COLUMN accounts__api_scopes.created_at; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__api_scopes.created_at IS 'Data de criação do registro';


--
-- TOC entry 6765 (class 0 OID 0)
-- Dependencies: 278
-- Name: COLUMN accounts__api_scopes.audit_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__api_scopes.audit_id IS 'Identificador único do registro de auditoria';


--
-- TOC entry 6766 (class 0 OID 0)
-- Dependencies: 278
-- Name: COLUMN accounts__api_scopes.audit_operation; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__api_scopes.audit_operation IS 'Tipo de operação realizada (INSERT, UPDATE, DELETE)';


--
-- TOC entry 6767 (class 0 OID 0)
-- Dependencies: 278
-- Name: COLUMN accounts__api_scopes.audit_timestamp; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__api_scopes.audit_timestamp IS 'Data e hora da operação auditada';


--
-- TOC entry 6768 (class 0 OID 0)
-- Dependencies: 278
-- Name: COLUMN accounts__api_scopes.audit_user; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__api_scopes.audit_user IS 'Usuário que executou a operação';


--
-- TOC entry 6769 (class 0 OID 0)
-- Dependencies: 278
-- Name: COLUMN accounts__api_scopes.audit_session_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__api_scopes.audit_session_id IS 'Identificador da sessão da aplicação';


--
-- TOC entry 6770 (class 0 OID 0)
-- Dependencies: 278
-- Name: COLUMN accounts__api_scopes.audit_connection_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__api_scopes.audit_connection_id IS 'Endereço IP da conexão';


--
-- TOC entry 6771 (class 0 OID 0)
-- Dependencies: 278
-- Name: COLUMN accounts__api_scopes.audit_partition_date; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__api_scopes.audit_partition_date IS 'Data para particionamento da tabela de auditoria';


--
-- TOC entry 279 (class 1259 OID 20134)
-- Name: accounts__api_scopes_2025_08; Type: TABLE; Schema: audit; Owner: postgres
--

CREATE TABLE audit.accounts__api_scopes_2025_08 (
    api_scope_id uuid NOT NULL,
    api_key_id uuid NOT NULL,
    feature_id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    audit_id bigint NOT NULL,
    audit_operation text NOT NULL,
    audit_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    audit_user text DEFAULT CURRENT_USER NOT NULL,
    audit_session_id text DEFAULT current_setting('application_name'::text) NOT NULL,
    audit_connection_id text DEFAULT inet_client_addr() NOT NULL,
    audit_partition_date date DEFAULT CURRENT_DATE NOT NULL
);


ALTER TABLE audit.accounts__api_scopes_2025_08 OWNER TO postgres;

--
-- TOC entry 277 (class 1259 OID 20116)
-- Name: accounts__api_scopes_audit_id_seq; Type: SEQUENCE; Schema: audit; Owner: postgres
--

ALTER TABLE audit.accounts__api_scopes ALTER COLUMN audit_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME audit.accounts__api_scopes_audit_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 281 (class 1259 OID 20152)
-- Name: accounts__apis; Type: TABLE; Schema: audit; Owner: postgres
--

CREATE TABLE audit.accounts__apis (
    api_id uuid NOT NULL,
    path text NOT NULL,
    method text NOT NULL,
    description text,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone,
    module_id uuid,
    audit_id bigint NOT NULL,
    audit_operation text NOT NULL,
    audit_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    audit_user text DEFAULT CURRENT_USER NOT NULL,
    audit_session_id text DEFAULT current_setting('application_name'::text) NOT NULL,
    audit_connection_id text DEFAULT inet_client_addr() NOT NULL,
    audit_partition_date date DEFAULT CURRENT_DATE NOT NULL
)
PARTITION BY RANGE (audit_partition_date);


ALTER TABLE audit.accounts__apis OWNER TO postgres;

--
-- TOC entry 6772 (class 0 OID 0)
-- Dependencies: 281
-- Name: TABLE accounts__apis; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON TABLE audit.accounts__apis IS 'AUDITORIA: Endpoints expostos da API vinculados a features do sistema';


--
-- TOC entry 6773 (class 0 OID 0)
-- Dependencies: 281
-- Name: COLUMN accounts__apis.api_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__apis.api_id IS 'Identificador único da API';


--
-- TOC entry 6774 (class 0 OID 0)
-- Dependencies: 281
-- Name: COLUMN accounts__apis.path; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__apis.path IS 'Caminho do endpoint (ex: /purchases)';


--
-- TOC entry 6775 (class 0 OID 0)
-- Dependencies: 281
-- Name: COLUMN accounts__apis.method; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__apis.method IS 'Método HTTP (ex: GET, POST, PUT)';


--
-- TOC entry 6776 (class 0 OID 0)
-- Dependencies: 281
-- Name: COLUMN accounts__apis.description; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__apis.description IS 'Descrição do funcionamento do endpoint';


--
-- TOC entry 6777 (class 0 OID 0)
-- Dependencies: 281
-- Name: COLUMN accounts__apis.created_at; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__apis.created_at IS 'Data de criação do endpoint';


--
-- TOC entry 6778 (class 0 OID 0)
-- Dependencies: 281
-- Name: COLUMN accounts__apis.updated_at; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__apis.updated_at IS 'Data de última atualização do endpoint';


--
-- TOC entry 6779 (class 0 OID 0)
-- Dependencies: 281
-- Name: COLUMN accounts__apis.audit_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__apis.audit_id IS 'Identificador único do registro de auditoria';


--
-- TOC entry 6780 (class 0 OID 0)
-- Dependencies: 281
-- Name: COLUMN accounts__apis.audit_operation; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__apis.audit_operation IS 'Tipo de operação realizada (INSERT, UPDATE, DELETE)';


--
-- TOC entry 6781 (class 0 OID 0)
-- Dependencies: 281
-- Name: COLUMN accounts__apis.audit_timestamp; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__apis.audit_timestamp IS 'Data e hora da operação auditada';


--
-- TOC entry 6782 (class 0 OID 0)
-- Dependencies: 281
-- Name: COLUMN accounts__apis.audit_user; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__apis.audit_user IS 'Usuário que executou a operação';


--
-- TOC entry 6783 (class 0 OID 0)
-- Dependencies: 281
-- Name: COLUMN accounts__apis.audit_session_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__apis.audit_session_id IS 'Identificador da sessão da aplicação';


--
-- TOC entry 6784 (class 0 OID 0)
-- Dependencies: 281
-- Name: COLUMN accounts__apis.audit_connection_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__apis.audit_connection_id IS 'Endereço IP da conexão';


--
-- TOC entry 6785 (class 0 OID 0)
-- Dependencies: 281
-- Name: COLUMN accounts__apis.audit_partition_date; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__apis.audit_partition_date IS 'Data para particionamento da tabela de auditoria';


--
-- TOC entry 282 (class 1259 OID 20168)
-- Name: accounts__apis_2025_08; Type: TABLE; Schema: audit; Owner: postgres
--

CREATE TABLE audit.accounts__apis_2025_08 (
    api_id uuid NOT NULL,
    path text NOT NULL,
    method text NOT NULL,
    description text,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone,
    module_id uuid,
    audit_id bigint NOT NULL,
    audit_operation text NOT NULL,
    audit_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    audit_user text DEFAULT CURRENT_USER NOT NULL,
    audit_session_id text DEFAULT current_setting('application_name'::text) NOT NULL,
    audit_connection_id text DEFAULT inet_client_addr() NOT NULL,
    audit_partition_date date DEFAULT CURRENT_DATE NOT NULL
);


ALTER TABLE audit.accounts__apis_2025_08 OWNER TO postgres;

--
-- TOC entry 280 (class 1259 OID 20151)
-- Name: accounts__apis_audit_id_seq; Type: SEQUENCE; Schema: audit; Owner: postgres
--

ALTER TABLE audit.accounts__apis ALTER COLUMN audit_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME audit.accounts__apis_audit_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 367 (class 1259 OID 21286)
-- Name: accounts__employee_addresses; Type: TABLE; Schema: audit; Owner: postgres
--

CREATE TABLE audit.accounts__employee_addresses (
    employee_address_id uuid NOT NULL,
    employee_id uuid NOT NULL,
    postal_code text NOT NULL,
    street text NOT NULL,
    number text NOT NULL,
    complement text,
    neighborhood text NOT NULL,
    city text NOT NULL,
    state text NOT NULL,
    is_primary boolean NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone,
    audit_id bigint NOT NULL,
    audit_operation text NOT NULL,
    audit_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    audit_user text DEFAULT CURRENT_USER NOT NULL,
    audit_session_id text DEFAULT current_setting('application_name'::text) NOT NULL,
    audit_connection_id text DEFAULT inet_client_addr() NOT NULL,
    audit_partition_date date DEFAULT CURRENT_DATE NOT NULL
)
PARTITION BY RANGE (audit_partition_date);


ALTER TABLE audit.accounts__employee_addresses OWNER TO postgres;

--
-- TOC entry 6786 (class 0 OID 0)
-- Dependencies: 367
-- Name: TABLE accounts__employee_addresses; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON TABLE audit.accounts__employee_addresses IS 'AUDITORIA: Endereços dos funcionários';


--
-- TOC entry 6787 (class 0 OID 0)
-- Dependencies: 367
-- Name: COLUMN accounts__employee_addresses.employee_address_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__employee_addresses.employee_address_id IS 'ID único do endereço';


--
-- TOC entry 6788 (class 0 OID 0)
-- Dependencies: 367
-- Name: COLUMN accounts__employee_addresses.employee_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__employee_addresses.employee_id IS 'Referência ao funcionário';


--
-- TOC entry 6789 (class 0 OID 0)
-- Dependencies: 367
-- Name: COLUMN accounts__employee_addresses.postal_code; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__employee_addresses.postal_code IS 'CEP (apenas números)';


--
-- TOC entry 6790 (class 0 OID 0)
-- Dependencies: 367
-- Name: COLUMN accounts__employee_addresses.street; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__employee_addresses.street IS 'Nome da rua';


--
-- TOC entry 6791 (class 0 OID 0)
-- Dependencies: 367
-- Name: COLUMN accounts__employee_addresses.number; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__employee_addresses.number IS 'Número do endereço';


--
-- TOC entry 6792 (class 0 OID 0)
-- Dependencies: 367
-- Name: COLUMN accounts__employee_addresses.complement; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__employee_addresses.complement IS 'Complemento do endereço';


--
-- TOC entry 6793 (class 0 OID 0)
-- Dependencies: 367
-- Name: COLUMN accounts__employee_addresses.neighborhood; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__employee_addresses.neighborhood IS 'Bairro';


--
-- TOC entry 6794 (class 0 OID 0)
-- Dependencies: 367
-- Name: COLUMN accounts__employee_addresses.city; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__employee_addresses.city IS 'Cidade';


--
-- TOC entry 6795 (class 0 OID 0)
-- Dependencies: 367
-- Name: COLUMN accounts__employee_addresses.state; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__employee_addresses.state IS 'Estado (UF)';


--
-- TOC entry 6796 (class 0 OID 0)
-- Dependencies: 367
-- Name: COLUMN accounts__employee_addresses.is_primary; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__employee_addresses.is_primary IS 'Indica se é o endereço principal';


--
-- TOC entry 6797 (class 0 OID 0)
-- Dependencies: 367
-- Name: COLUMN accounts__employee_addresses.created_at; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__employee_addresses.created_at IS 'Data de criação do registro';


--
-- TOC entry 6798 (class 0 OID 0)
-- Dependencies: 367
-- Name: COLUMN accounts__employee_addresses.updated_at; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__employee_addresses.updated_at IS 'Data da última atualização';


--
-- TOC entry 6799 (class 0 OID 0)
-- Dependencies: 367
-- Name: COLUMN accounts__employee_addresses.audit_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__employee_addresses.audit_id IS 'Identificador único do registro de auditoria';


--
-- TOC entry 6800 (class 0 OID 0)
-- Dependencies: 367
-- Name: COLUMN accounts__employee_addresses.audit_operation; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__employee_addresses.audit_operation IS 'Tipo de operação realizada (INSERT, UPDATE, DELETE)';


--
-- TOC entry 6801 (class 0 OID 0)
-- Dependencies: 367
-- Name: COLUMN accounts__employee_addresses.audit_timestamp; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__employee_addresses.audit_timestamp IS 'Data e hora da operação auditada';


--
-- TOC entry 6802 (class 0 OID 0)
-- Dependencies: 367
-- Name: COLUMN accounts__employee_addresses.audit_user; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__employee_addresses.audit_user IS 'Usuário que executou a operação';


--
-- TOC entry 6803 (class 0 OID 0)
-- Dependencies: 367
-- Name: COLUMN accounts__employee_addresses.audit_session_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__employee_addresses.audit_session_id IS 'Identificador da sessão da aplicação';


--
-- TOC entry 6804 (class 0 OID 0)
-- Dependencies: 367
-- Name: COLUMN accounts__employee_addresses.audit_connection_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__employee_addresses.audit_connection_id IS 'Endereço IP da conexão';


--
-- TOC entry 6805 (class 0 OID 0)
-- Dependencies: 367
-- Name: COLUMN accounts__employee_addresses.audit_partition_date; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__employee_addresses.audit_partition_date IS 'Data para particionamento da tabela de auditoria';


--
-- TOC entry 368 (class 1259 OID 21302)
-- Name: accounts__employee_addresses_2025_08; Type: TABLE; Schema: audit; Owner: postgres
--

CREATE TABLE audit.accounts__employee_addresses_2025_08 (
    employee_address_id uuid NOT NULL,
    employee_id uuid NOT NULL,
    postal_code text NOT NULL,
    street text NOT NULL,
    number text NOT NULL,
    complement text,
    neighborhood text NOT NULL,
    city text NOT NULL,
    state text NOT NULL,
    is_primary boolean NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone,
    audit_id bigint NOT NULL,
    audit_operation text NOT NULL,
    audit_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    audit_user text DEFAULT CURRENT_USER NOT NULL,
    audit_session_id text DEFAULT current_setting('application_name'::text) NOT NULL,
    audit_connection_id text DEFAULT inet_client_addr() NOT NULL,
    audit_partition_date date DEFAULT CURRENT_DATE NOT NULL
);


ALTER TABLE audit.accounts__employee_addresses_2025_08 OWNER TO postgres;

--
-- TOC entry 366 (class 1259 OID 21285)
-- Name: accounts__employee_addresses_audit_id_seq; Type: SEQUENCE; Schema: audit; Owner: postgres
--

ALTER TABLE audit.accounts__employee_addresses ALTER COLUMN audit_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME audit.accounts__employee_addresses_audit_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 364 (class 1259 OID 21253)
-- Name: accounts__employee_personal_data; Type: TABLE; Schema: audit; Owner: postgres
--

CREATE TABLE audit.accounts__employee_personal_data (
    employee_personal_data_id uuid NOT NULL,
    employee_id uuid NOT NULL,
    cpf text NOT NULL,
    full_name text NOT NULL,
    birth_date date NOT NULL,
    gender text NOT NULL,
    photo_url text,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone,
    audit_id bigint NOT NULL,
    audit_operation text NOT NULL,
    audit_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    audit_user text DEFAULT CURRENT_USER NOT NULL,
    audit_session_id text DEFAULT current_setting('application_name'::text) NOT NULL,
    audit_connection_id text DEFAULT inet_client_addr() NOT NULL,
    audit_partition_date date DEFAULT CURRENT_DATE NOT NULL
)
PARTITION BY RANGE (audit_partition_date);


ALTER TABLE audit.accounts__employee_personal_data OWNER TO postgres;

--
-- TOC entry 6806 (class 0 OID 0)
-- Dependencies: 364
-- Name: TABLE accounts__employee_personal_data; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON TABLE audit.accounts__employee_personal_data IS 'AUDITORIA: Dados pessoais dos funcionários (CPF, nome, nascimento, sexo, foto)';


--
-- TOC entry 6807 (class 0 OID 0)
-- Dependencies: 364
-- Name: COLUMN accounts__employee_personal_data.employee_personal_data_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__employee_personal_data.employee_personal_data_id IS 'ID único dos dados pessoais';


--
-- TOC entry 6808 (class 0 OID 0)
-- Dependencies: 364
-- Name: COLUMN accounts__employee_personal_data.employee_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__employee_personal_data.employee_id IS 'Referência ao funcionário';


--
-- TOC entry 6809 (class 0 OID 0)
-- Dependencies: 364
-- Name: COLUMN accounts__employee_personal_data.cpf; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__employee_personal_data.cpf IS 'CPF do funcionário (apenas números)';


--
-- TOC entry 6810 (class 0 OID 0)
-- Dependencies: 364
-- Name: COLUMN accounts__employee_personal_data.full_name; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__employee_personal_data.full_name IS 'Nome completo do funcionário';


--
-- TOC entry 6811 (class 0 OID 0)
-- Dependencies: 364
-- Name: COLUMN accounts__employee_personal_data.birth_date; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__employee_personal_data.birth_date IS 'Data de nascimento';


--
-- TOC entry 6812 (class 0 OID 0)
-- Dependencies: 364
-- Name: COLUMN accounts__employee_personal_data.gender; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__employee_personal_data.gender IS 'Sexo (M=Masculino, F=Feminino, O=Outro)';


--
-- TOC entry 6813 (class 0 OID 0)
-- Dependencies: 364
-- Name: COLUMN accounts__employee_personal_data.photo_url; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__employee_personal_data.photo_url IS 'URL da foto do funcionário (opcional)';


--
-- TOC entry 6814 (class 0 OID 0)
-- Dependencies: 364
-- Name: COLUMN accounts__employee_personal_data.created_at; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__employee_personal_data.created_at IS 'Data de criação do registro';


--
-- TOC entry 6815 (class 0 OID 0)
-- Dependencies: 364
-- Name: COLUMN accounts__employee_personal_data.updated_at; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__employee_personal_data.updated_at IS 'Data da última atualização';


--
-- TOC entry 6816 (class 0 OID 0)
-- Dependencies: 364
-- Name: COLUMN accounts__employee_personal_data.audit_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__employee_personal_data.audit_id IS 'Identificador único do registro de auditoria';


--
-- TOC entry 6817 (class 0 OID 0)
-- Dependencies: 364
-- Name: COLUMN accounts__employee_personal_data.audit_operation; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__employee_personal_data.audit_operation IS 'Tipo de operação realizada (INSERT, UPDATE, DELETE)';


--
-- TOC entry 6818 (class 0 OID 0)
-- Dependencies: 364
-- Name: COLUMN accounts__employee_personal_data.audit_timestamp; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__employee_personal_data.audit_timestamp IS 'Data e hora da operação auditada';


--
-- TOC entry 6819 (class 0 OID 0)
-- Dependencies: 364
-- Name: COLUMN accounts__employee_personal_data.audit_user; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__employee_personal_data.audit_user IS 'Usuário que executou a operação';


--
-- TOC entry 6820 (class 0 OID 0)
-- Dependencies: 364
-- Name: COLUMN accounts__employee_personal_data.audit_session_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__employee_personal_data.audit_session_id IS 'Identificador da sessão da aplicação';


--
-- TOC entry 6821 (class 0 OID 0)
-- Dependencies: 364
-- Name: COLUMN accounts__employee_personal_data.audit_connection_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__employee_personal_data.audit_connection_id IS 'Endereço IP da conexão';


--
-- TOC entry 6822 (class 0 OID 0)
-- Dependencies: 364
-- Name: COLUMN accounts__employee_personal_data.audit_partition_date; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__employee_personal_data.audit_partition_date IS 'Data para particionamento da tabela de auditoria';


--
-- TOC entry 365 (class 1259 OID 21269)
-- Name: accounts__employee_personal_data_2025_08; Type: TABLE; Schema: audit; Owner: postgres
--

CREATE TABLE audit.accounts__employee_personal_data_2025_08 (
    employee_personal_data_id uuid NOT NULL,
    employee_id uuid NOT NULL,
    cpf text NOT NULL,
    full_name text NOT NULL,
    birth_date date NOT NULL,
    gender text NOT NULL,
    photo_url text,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone,
    audit_id bigint NOT NULL,
    audit_operation text NOT NULL,
    audit_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    audit_user text DEFAULT CURRENT_USER NOT NULL,
    audit_session_id text DEFAULT current_setting('application_name'::text) NOT NULL,
    audit_connection_id text DEFAULT inet_client_addr() NOT NULL,
    audit_partition_date date DEFAULT CURRENT_DATE NOT NULL
);


ALTER TABLE audit.accounts__employee_personal_data_2025_08 OWNER TO postgres;

--
-- TOC entry 363 (class 1259 OID 21252)
-- Name: accounts__employee_personal_data_audit_id_seq; Type: SEQUENCE; Schema: audit; Owner: postgres
--

ALTER TABLE audit.accounts__employee_personal_data ALTER COLUMN audit_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME audit.accounts__employee_personal_data_audit_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 284 (class 1259 OID 20185)
-- Name: accounts__employee_roles; Type: TABLE; Schema: audit; Owner: postgres
--

CREATE TABLE audit.accounts__employee_roles (
    employee_role_id uuid NOT NULL,
    employee_id uuid NOT NULL,
    role_id uuid NOT NULL,
    granted_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone,
    audit_id bigint NOT NULL,
    audit_operation text NOT NULL,
    audit_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    audit_user text DEFAULT CURRENT_USER NOT NULL,
    audit_session_id text DEFAULT current_setting('application_name'::text) NOT NULL,
    audit_connection_id text DEFAULT inet_client_addr() NOT NULL,
    audit_partition_date date DEFAULT CURRENT_DATE NOT NULL
)
PARTITION BY RANGE (audit_partition_date);


ALTER TABLE audit.accounts__employee_roles OWNER TO postgres;

--
-- TOC entry 6823 (class 0 OID 0)
-- Dependencies: 284
-- Name: TABLE accounts__employee_roles; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON TABLE audit.accounts__employee_roles IS 'AUDITORIA: Vínculos entre funcionários e papéis nomeados (roles)';


--
-- TOC entry 6824 (class 0 OID 0)
-- Dependencies: 284
-- Name: COLUMN accounts__employee_roles.employee_role_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__employee_roles.employee_role_id IS 'Identificador do vínculo entre employee e role';


--
-- TOC entry 6825 (class 0 OID 0)
-- Dependencies: 284
-- Name: COLUMN accounts__employee_roles.employee_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__employee_roles.employee_id IS 'Funcionário que recebe o papel';


--
-- TOC entry 6826 (class 0 OID 0)
-- Dependencies: 284
-- Name: COLUMN accounts__employee_roles.role_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__employee_roles.role_id IS 'Papel atribuído ao funcionário';


--
-- TOC entry 6827 (class 0 OID 0)
-- Dependencies: 284
-- Name: COLUMN accounts__employee_roles.granted_at; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__employee_roles.granted_at IS 'Data de concessão do papel';


--
-- TOC entry 6828 (class 0 OID 0)
-- Dependencies: 284
-- Name: COLUMN accounts__employee_roles.updated_at; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__employee_roles.updated_at IS 'Data da última modificação do vínculo';


--
-- TOC entry 6829 (class 0 OID 0)
-- Dependencies: 284
-- Name: COLUMN accounts__employee_roles.audit_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__employee_roles.audit_id IS 'Identificador único do registro de auditoria';


--
-- TOC entry 6830 (class 0 OID 0)
-- Dependencies: 284
-- Name: COLUMN accounts__employee_roles.audit_operation; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__employee_roles.audit_operation IS 'Tipo de operação realizada (INSERT, UPDATE, DELETE)';


--
-- TOC entry 6831 (class 0 OID 0)
-- Dependencies: 284
-- Name: COLUMN accounts__employee_roles.audit_timestamp; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__employee_roles.audit_timestamp IS 'Data e hora da operação auditada';


--
-- TOC entry 6832 (class 0 OID 0)
-- Dependencies: 284
-- Name: COLUMN accounts__employee_roles.audit_user; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__employee_roles.audit_user IS 'Usuário que executou a operação';


--
-- TOC entry 6833 (class 0 OID 0)
-- Dependencies: 284
-- Name: COLUMN accounts__employee_roles.audit_session_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__employee_roles.audit_session_id IS 'Identificador da sessão da aplicação';


--
-- TOC entry 6834 (class 0 OID 0)
-- Dependencies: 284
-- Name: COLUMN accounts__employee_roles.audit_connection_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__employee_roles.audit_connection_id IS 'Endereço IP da conexão';


--
-- TOC entry 6835 (class 0 OID 0)
-- Dependencies: 284
-- Name: COLUMN accounts__employee_roles.audit_partition_date; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__employee_roles.audit_partition_date IS 'Data para particionamento da tabela de auditoria';


--
-- TOC entry 285 (class 1259 OID 20202)
-- Name: accounts__employee_roles_2025_08; Type: TABLE; Schema: audit; Owner: postgres
--

CREATE TABLE audit.accounts__employee_roles_2025_08 (
    employee_role_id uuid NOT NULL,
    employee_id uuid NOT NULL,
    role_id uuid NOT NULL,
    granted_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone,
    audit_id bigint NOT NULL,
    audit_operation text NOT NULL,
    audit_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    audit_user text DEFAULT CURRENT_USER NOT NULL,
    audit_session_id text DEFAULT current_setting('application_name'::text) NOT NULL,
    audit_connection_id text DEFAULT inet_client_addr() NOT NULL,
    audit_partition_date date DEFAULT CURRENT_DATE NOT NULL
);


ALTER TABLE audit.accounts__employee_roles_2025_08 OWNER TO postgres;

--
-- TOC entry 283 (class 1259 OID 20184)
-- Name: accounts__employee_roles_audit_id_seq; Type: SEQUENCE; Schema: audit; Owner: postgres
--

ALTER TABLE audit.accounts__employee_roles ALTER COLUMN audit_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME audit.accounts__employee_roles_audit_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 287 (class 1259 OID 20220)
-- Name: accounts__employees; Type: TABLE; Schema: audit; Owner: postgres
--

CREATE TABLE audit.accounts__employees (
    employee_id uuid NOT NULL,
    user_id uuid NOT NULL,
    supplier_id uuid,
    establishment_id uuid,
    is_active boolean NOT NULL,
    activated_at timestamp with time zone,
    deactivated_at timestamp with time zone,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    audit_id bigint NOT NULL,
    audit_operation text NOT NULL,
    audit_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    audit_user text DEFAULT CURRENT_USER NOT NULL,
    audit_session_id text DEFAULT current_setting('application_name'::text) NOT NULL,
    audit_connection_id text DEFAULT inet_client_addr() NOT NULL,
    audit_partition_date date DEFAULT CURRENT_DATE NOT NULL
)
PARTITION BY RANGE (audit_partition_date);


ALTER TABLE audit.accounts__employees OWNER TO postgres;

--
-- TOC entry 6836 (class 0 OID 0)
-- Dependencies: 287
-- Name: TABLE accounts__employees; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON TABLE audit.accounts__employees IS 'AUDITORIA: Funcionários vinculados a fornecedores ou estabelecimentos';


--
-- TOC entry 6837 (class 0 OID 0)
-- Dependencies: 287
-- Name: COLUMN accounts__employees.employee_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__employees.employee_id IS 'Identificador do vínculo funcional';


--
-- TOC entry 6838 (class 0 OID 0)
-- Dependencies: 287
-- Name: COLUMN accounts__employees.user_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__employees.user_id IS 'Usuário associado ao funcionário';


--
-- TOC entry 6839 (class 0 OID 0)
-- Dependencies: 287
-- Name: COLUMN accounts__employees.supplier_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__employees.supplier_id IS 'Fornecedor ao qual o funcionário pertence';


--
-- TOC entry 6840 (class 0 OID 0)
-- Dependencies: 287
-- Name: COLUMN accounts__employees.establishment_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__employees.establishment_id IS 'Estabelecimento ao qual o funcionário pertence';


--
-- TOC entry 6841 (class 0 OID 0)
-- Dependencies: 287
-- Name: COLUMN accounts__employees.is_active; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__employees.is_active IS 'Se o vínculo está ativo';


--
-- TOC entry 6842 (class 0 OID 0)
-- Dependencies: 287
-- Name: COLUMN accounts__employees.activated_at; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__employees.activated_at IS 'Data de ativação do vínculo';


--
-- TOC entry 6843 (class 0 OID 0)
-- Dependencies: 287
-- Name: COLUMN accounts__employees.deactivated_at; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__employees.deactivated_at IS 'Data de desativação do vínculo';


--
-- TOC entry 6844 (class 0 OID 0)
-- Dependencies: 287
-- Name: COLUMN accounts__employees.created_at; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__employees.created_at IS 'Data de criação';


--
-- TOC entry 6845 (class 0 OID 0)
-- Dependencies: 287
-- Name: COLUMN accounts__employees.updated_at; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__employees.updated_at IS 'Data da última atualização';


--
-- TOC entry 6846 (class 0 OID 0)
-- Dependencies: 287
-- Name: COLUMN accounts__employees.audit_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__employees.audit_id IS 'Identificador único do registro de auditoria';


--
-- TOC entry 6847 (class 0 OID 0)
-- Dependencies: 287
-- Name: COLUMN accounts__employees.audit_operation; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__employees.audit_operation IS 'Tipo de operação realizada (INSERT, UPDATE, DELETE)';


--
-- TOC entry 6848 (class 0 OID 0)
-- Dependencies: 287
-- Name: COLUMN accounts__employees.audit_timestamp; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__employees.audit_timestamp IS 'Data e hora da operação auditada';


--
-- TOC entry 6849 (class 0 OID 0)
-- Dependencies: 287
-- Name: COLUMN accounts__employees.audit_user; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__employees.audit_user IS 'Usuário que executou a operação';


--
-- TOC entry 6850 (class 0 OID 0)
-- Dependencies: 287
-- Name: COLUMN accounts__employees.audit_session_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__employees.audit_session_id IS 'Identificador da sessão da aplicação';


--
-- TOC entry 6851 (class 0 OID 0)
-- Dependencies: 287
-- Name: COLUMN accounts__employees.audit_connection_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__employees.audit_connection_id IS 'Endereço IP da conexão';


--
-- TOC entry 6852 (class 0 OID 0)
-- Dependencies: 287
-- Name: COLUMN accounts__employees.audit_partition_date; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__employees.audit_partition_date IS 'Data para particionamento da tabela de auditoria';


--
-- TOC entry 288 (class 1259 OID 20238)
-- Name: accounts__employees_2025_08; Type: TABLE; Schema: audit; Owner: postgres
--

CREATE TABLE audit.accounts__employees_2025_08 (
    employee_id uuid NOT NULL,
    user_id uuid NOT NULL,
    supplier_id uuid,
    establishment_id uuid,
    is_active boolean NOT NULL,
    activated_at timestamp with time zone,
    deactivated_at timestamp with time zone,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    audit_id bigint NOT NULL,
    audit_operation text NOT NULL,
    audit_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    audit_user text DEFAULT CURRENT_USER NOT NULL,
    audit_session_id text DEFAULT current_setting('application_name'::text) NOT NULL,
    audit_connection_id text DEFAULT inet_client_addr() NOT NULL,
    audit_partition_date date DEFAULT CURRENT_DATE NOT NULL
);


ALTER TABLE audit.accounts__employees_2025_08 OWNER TO postgres;

--
-- TOC entry 286 (class 1259 OID 20219)
-- Name: accounts__employees_audit_id_seq; Type: SEQUENCE; Schema: audit; Owner: postgres
--

ALTER TABLE audit.accounts__employees ALTER COLUMN audit_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME audit.accounts__employees_audit_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 290 (class 1259 OID 20257)
-- Name: accounts__establishment_addresses; Type: TABLE; Schema: audit; Owner: postgres
--

CREATE TABLE audit.accounts__establishment_addresses (
    establishment_address_id uuid NOT NULL,
    establishment_id uuid NOT NULL,
    postal_code text NOT NULL,
    street text NOT NULL,
    number text NOT NULL,
    complement text,
    neighborhood text NOT NULL,
    city text NOT NULL,
    state text NOT NULL,
    is_primary boolean NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone,
    audit_id bigint NOT NULL,
    audit_operation text NOT NULL,
    audit_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    audit_user text DEFAULT CURRENT_USER NOT NULL,
    audit_session_id text DEFAULT current_setting('application_name'::text) NOT NULL,
    audit_connection_id text DEFAULT inet_client_addr() NOT NULL,
    audit_partition_date date DEFAULT CURRENT_DATE NOT NULL
)
PARTITION BY RANGE (audit_partition_date);


ALTER TABLE audit.accounts__establishment_addresses OWNER TO postgres;

--
-- TOC entry 6853 (class 0 OID 0)
-- Dependencies: 290
-- Name: TABLE accounts__establishment_addresses; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON TABLE audit.accounts__establishment_addresses IS 'AUDITORIA: Endereços dos estabelecimentos';


--
-- TOC entry 6854 (class 0 OID 0)
-- Dependencies: 290
-- Name: COLUMN accounts__establishment_addresses.establishment_address_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__establishment_addresses.establishment_address_id IS 'Identificador único do endereço';


--
-- TOC entry 6855 (class 0 OID 0)
-- Dependencies: 290
-- Name: COLUMN accounts__establishment_addresses.establishment_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__establishment_addresses.establishment_id IS 'Referência ao estabelecimento';


--
-- TOC entry 6856 (class 0 OID 0)
-- Dependencies: 290
-- Name: COLUMN accounts__establishment_addresses.postal_code; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__establishment_addresses.postal_code IS 'CEP (apenas números, 8 dígitos)';


--
-- TOC entry 6857 (class 0 OID 0)
-- Dependencies: 290
-- Name: COLUMN accounts__establishment_addresses.street; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__establishment_addresses.street IS 'Logradouro (Rua, Avenida, etc.)';


--
-- TOC entry 6858 (class 0 OID 0)
-- Dependencies: 290
-- Name: COLUMN accounts__establishment_addresses.number; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__establishment_addresses.number IS 'Número do endereço';


--
-- TOC entry 6859 (class 0 OID 0)
-- Dependencies: 290
-- Name: COLUMN accounts__establishment_addresses.complement; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__establishment_addresses.complement IS 'Complemento do endereço (opcional)';


--
-- TOC entry 6860 (class 0 OID 0)
-- Dependencies: 290
-- Name: COLUMN accounts__establishment_addresses.neighborhood; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__establishment_addresses.neighborhood IS 'Bairro';


--
-- TOC entry 6861 (class 0 OID 0)
-- Dependencies: 290
-- Name: COLUMN accounts__establishment_addresses.city; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__establishment_addresses.city IS 'Cidade';


--
-- TOC entry 6862 (class 0 OID 0)
-- Dependencies: 290
-- Name: COLUMN accounts__establishment_addresses.state; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__establishment_addresses.state IS 'Estado (sigla de 2 letras)';


--
-- TOC entry 6863 (class 0 OID 0)
-- Dependencies: 290
-- Name: COLUMN accounts__establishment_addresses.is_primary; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__establishment_addresses.is_primary IS 'Indica se é o endereço principal';


--
-- TOC entry 6864 (class 0 OID 0)
-- Dependencies: 290
-- Name: COLUMN accounts__establishment_addresses.created_at; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__establishment_addresses.created_at IS 'Data de criação do registro';


--
-- TOC entry 6865 (class 0 OID 0)
-- Dependencies: 290
-- Name: COLUMN accounts__establishment_addresses.updated_at; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__establishment_addresses.updated_at IS 'Data da última atualização';


--
-- TOC entry 6866 (class 0 OID 0)
-- Dependencies: 290
-- Name: COLUMN accounts__establishment_addresses.audit_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__establishment_addresses.audit_id IS 'Identificador único do registro de auditoria';


--
-- TOC entry 6867 (class 0 OID 0)
-- Dependencies: 290
-- Name: COLUMN accounts__establishment_addresses.audit_operation; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__establishment_addresses.audit_operation IS 'Tipo de operação realizada (INSERT, UPDATE, DELETE)';


--
-- TOC entry 6868 (class 0 OID 0)
-- Dependencies: 290
-- Name: COLUMN accounts__establishment_addresses.audit_timestamp; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__establishment_addresses.audit_timestamp IS 'Data e hora da operação auditada';


--
-- TOC entry 6869 (class 0 OID 0)
-- Dependencies: 290
-- Name: COLUMN accounts__establishment_addresses.audit_user; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__establishment_addresses.audit_user IS 'Usuário que executou a operação';


--
-- TOC entry 6870 (class 0 OID 0)
-- Dependencies: 290
-- Name: COLUMN accounts__establishment_addresses.audit_session_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__establishment_addresses.audit_session_id IS 'Identificador da sessão da aplicação';


--
-- TOC entry 6871 (class 0 OID 0)
-- Dependencies: 290
-- Name: COLUMN accounts__establishment_addresses.audit_connection_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__establishment_addresses.audit_connection_id IS 'Endereço IP da conexão';


--
-- TOC entry 6872 (class 0 OID 0)
-- Dependencies: 290
-- Name: COLUMN accounts__establishment_addresses.audit_partition_date; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__establishment_addresses.audit_partition_date IS 'Data para particionamento da tabela de auditoria';


--
-- TOC entry 291 (class 1259 OID 20273)
-- Name: accounts__establishment_addresses_2025_08; Type: TABLE; Schema: audit; Owner: postgres
--

CREATE TABLE audit.accounts__establishment_addresses_2025_08 (
    establishment_address_id uuid NOT NULL,
    establishment_id uuid NOT NULL,
    postal_code text NOT NULL,
    street text NOT NULL,
    number text NOT NULL,
    complement text,
    neighborhood text NOT NULL,
    city text NOT NULL,
    state text NOT NULL,
    is_primary boolean NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone,
    audit_id bigint NOT NULL,
    audit_operation text NOT NULL,
    audit_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    audit_user text DEFAULT CURRENT_USER NOT NULL,
    audit_session_id text DEFAULT current_setting('application_name'::text) NOT NULL,
    audit_connection_id text DEFAULT inet_client_addr() NOT NULL,
    audit_partition_date date DEFAULT CURRENT_DATE NOT NULL
);


ALTER TABLE audit.accounts__establishment_addresses_2025_08 OWNER TO postgres;

--
-- TOC entry 289 (class 1259 OID 20256)
-- Name: accounts__establishment_addresses_audit_id_seq; Type: SEQUENCE; Schema: audit; Owner: postgres
--

ALTER TABLE audit.accounts__establishment_addresses ALTER COLUMN audit_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME audit.accounts__establishment_addresses_audit_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 293 (class 1259 OID 20290)
-- Name: accounts__establishment_business_data; Type: TABLE; Schema: audit; Owner: postgres
--

CREATE TABLE audit.accounts__establishment_business_data (
    establishment_business_data_id uuid NOT NULL,
    establishment_id uuid NOT NULL,
    cnpj text NOT NULL,
    trade_name text NOT NULL,
    corporate_name text NOT NULL,
    state_registration text,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone,
    audit_id bigint NOT NULL,
    audit_operation text NOT NULL,
    audit_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    audit_user text DEFAULT CURRENT_USER NOT NULL,
    audit_session_id text DEFAULT current_setting('application_name'::text) NOT NULL,
    audit_connection_id text DEFAULT inet_client_addr() NOT NULL,
    audit_partition_date date DEFAULT CURRENT_DATE NOT NULL
)
PARTITION BY RANGE (audit_partition_date);


ALTER TABLE audit.accounts__establishment_business_data OWNER TO postgres;

--
-- TOC entry 6873 (class 0 OID 0)
-- Dependencies: 293
-- Name: TABLE accounts__establishment_business_data; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON TABLE audit.accounts__establishment_business_data IS 'AUDITORIA: Dados empresariais específicos dos estabelecimentos (CNPJ, Razão Social, etc.)';


--
-- TOC entry 6874 (class 0 OID 0)
-- Dependencies: 293
-- Name: COLUMN accounts__establishment_business_data.establishment_business_data_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__establishment_business_data.establishment_business_data_id IS 'Identificador único dos dados empresariais';


--
-- TOC entry 6875 (class 0 OID 0)
-- Dependencies: 293
-- Name: COLUMN accounts__establishment_business_data.establishment_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__establishment_business_data.establishment_id IS 'Referência ao estabelecimento';


--
-- TOC entry 6876 (class 0 OID 0)
-- Dependencies: 293
-- Name: COLUMN accounts__establishment_business_data.cnpj; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__establishment_business_data.cnpj IS 'CNPJ da empresa (apenas números, 14 dígitos)';


--
-- TOC entry 6877 (class 0 OID 0)
-- Dependencies: 293
-- Name: COLUMN accounts__establishment_business_data.trade_name; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__establishment_business_data.trade_name IS 'Nome Fantasia da empresa';


--
-- TOC entry 6878 (class 0 OID 0)
-- Dependencies: 293
-- Name: COLUMN accounts__establishment_business_data.corporate_name; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__establishment_business_data.corporate_name IS 'Razão Social da empresa';


--
-- TOC entry 6879 (class 0 OID 0)
-- Dependencies: 293
-- Name: COLUMN accounts__establishment_business_data.state_registration; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__establishment_business_data.state_registration IS 'Número da Inscrição Estadual';


--
-- TOC entry 6880 (class 0 OID 0)
-- Dependencies: 293
-- Name: COLUMN accounts__establishment_business_data.created_at; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__establishment_business_data.created_at IS 'Data de criação do registro';


--
-- TOC entry 6881 (class 0 OID 0)
-- Dependencies: 293
-- Name: COLUMN accounts__establishment_business_data.updated_at; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__establishment_business_data.updated_at IS 'Data da última atualização';


--
-- TOC entry 6882 (class 0 OID 0)
-- Dependencies: 293
-- Name: COLUMN accounts__establishment_business_data.audit_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__establishment_business_data.audit_id IS 'Identificador único do registro de auditoria';


--
-- TOC entry 6883 (class 0 OID 0)
-- Dependencies: 293
-- Name: COLUMN accounts__establishment_business_data.audit_operation; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__establishment_business_data.audit_operation IS 'Tipo de operação realizada (INSERT, UPDATE, DELETE)';


--
-- TOC entry 6884 (class 0 OID 0)
-- Dependencies: 293
-- Name: COLUMN accounts__establishment_business_data.audit_timestamp; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__establishment_business_data.audit_timestamp IS 'Data e hora da operação auditada';


--
-- TOC entry 6885 (class 0 OID 0)
-- Dependencies: 293
-- Name: COLUMN accounts__establishment_business_data.audit_user; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__establishment_business_data.audit_user IS 'Usuário que executou a operação';


--
-- TOC entry 6886 (class 0 OID 0)
-- Dependencies: 293
-- Name: COLUMN accounts__establishment_business_data.audit_session_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__establishment_business_data.audit_session_id IS 'Identificador da sessão da aplicação';


--
-- TOC entry 6887 (class 0 OID 0)
-- Dependencies: 293
-- Name: COLUMN accounts__establishment_business_data.audit_connection_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__establishment_business_data.audit_connection_id IS 'Endereço IP da conexão';


--
-- TOC entry 6888 (class 0 OID 0)
-- Dependencies: 293
-- Name: COLUMN accounts__establishment_business_data.audit_partition_date; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__establishment_business_data.audit_partition_date IS 'Data para particionamento da tabela de auditoria';


--
-- TOC entry 294 (class 1259 OID 20306)
-- Name: accounts__establishment_business_data_2025_08; Type: TABLE; Schema: audit; Owner: postgres
--

CREATE TABLE audit.accounts__establishment_business_data_2025_08 (
    establishment_business_data_id uuid NOT NULL,
    establishment_id uuid NOT NULL,
    cnpj text NOT NULL,
    trade_name text NOT NULL,
    corporate_name text NOT NULL,
    state_registration text,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone,
    audit_id bigint NOT NULL,
    audit_operation text NOT NULL,
    audit_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    audit_user text DEFAULT CURRENT_USER NOT NULL,
    audit_session_id text DEFAULT current_setting('application_name'::text) NOT NULL,
    audit_connection_id text DEFAULT inet_client_addr() NOT NULL,
    audit_partition_date date DEFAULT CURRENT_DATE NOT NULL
);


ALTER TABLE audit.accounts__establishment_business_data_2025_08 OWNER TO postgres;

--
-- TOC entry 292 (class 1259 OID 20289)
-- Name: accounts__establishment_business_data_audit_id_seq; Type: SEQUENCE; Schema: audit; Owner: postgres
--

ALTER TABLE audit.accounts__establishment_business_data ALTER COLUMN audit_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME audit.accounts__establishment_business_data_audit_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 296 (class 1259 OID 20323)
-- Name: accounts__establishments; Type: TABLE; Schema: audit; Owner: postgres
--

CREATE TABLE audit.accounts__establishments (
    establishment_id uuid NOT NULL,
    name text NOT NULL,
    is_active boolean NOT NULL,
    activated_at timestamp with time zone,
    deactivated_at timestamp with time zone,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    audit_id bigint NOT NULL,
    audit_operation text NOT NULL,
    audit_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    audit_user text DEFAULT CURRENT_USER NOT NULL,
    audit_session_id text DEFAULT current_setting('application_name'::text) NOT NULL,
    audit_connection_id text DEFAULT inet_client_addr() NOT NULL,
    audit_partition_date date DEFAULT CURRENT_DATE NOT NULL
)
PARTITION BY RANGE (audit_partition_date);


ALTER TABLE audit.accounts__establishments OWNER TO postgres;

--
-- TOC entry 6889 (class 0 OID 0)
-- Dependencies: 296
-- Name: TABLE accounts__establishments; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON TABLE audit.accounts__establishments IS 'AUDITORIA: Estabelecimentos que utilizam o sistema e possuem funcionários';


--
-- TOC entry 6890 (class 0 OID 0)
-- Dependencies: 296
-- Name: COLUMN accounts__establishments.establishment_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__establishments.establishment_id IS 'Identificador único do estabelecimento';


--
-- TOC entry 6891 (class 0 OID 0)
-- Dependencies: 296
-- Name: COLUMN accounts__establishments.name; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__establishments.name IS 'Nome do estabelecimento';


--
-- TOC entry 6892 (class 0 OID 0)
-- Dependencies: 296
-- Name: COLUMN accounts__establishments.is_active; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__establishments.is_active IS 'Indica se o estabelecimento está ativo';


--
-- TOC entry 6893 (class 0 OID 0)
-- Dependencies: 296
-- Name: COLUMN accounts__establishments.activated_at; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__establishments.activated_at IS 'Data de ativação';


--
-- TOC entry 6894 (class 0 OID 0)
-- Dependencies: 296
-- Name: COLUMN accounts__establishments.deactivated_at; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__establishments.deactivated_at IS 'Data de desativação';


--
-- TOC entry 6895 (class 0 OID 0)
-- Dependencies: 296
-- Name: COLUMN accounts__establishments.created_at; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__establishments.created_at IS 'Data de criação do registro';


--
-- TOC entry 6896 (class 0 OID 0)
-- Dependencies: 296
-- Name: COLUMN accounts__establishments.updated_at; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__establishments.updated_at IS 'Data da última atualização do registro';


--
-- TOC entry 6897 (class 0 OID 0)
-- Dependencies: 296
-- Name: COLUMN accounts__establishments.audit_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__establishments.audit_id IS 'Identificador único do registro de auditoria';


--
-- TOC entry 6898 (class 0 OID 0)
-- Dependencies: 296
-- Name: COLUMN accounts__establishments.audit_operation; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__establishments.audit_operation IS 'Tipo de operação realizada (INSERT, UPDATE, DELETE)';


--
-- TOC entry 6899 (class 0 OID 0)
-- Dependencies: 296
-- Name: COLUMN accounts__establishments.audit_timestamp; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__establishments.audit_timestamp IS 'Data e hora da operação auditada';


--
-- TOC entry 6900 (class 0 OID 0)
-- Dependencies: 296
-- Name: COLUMN accounts__establishments.audit_user; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__establishments.audit_user IS 'Usuário que executou a operação';


--
-- TOC entry 6901 (class 0 OID 0)
-- Dependencies: 296
-- Name: COLUMN accounts__establishments.audit_session_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__establishments.audit_session_id IS 'Identificador da sessão da aplicação';


--
-- TOC entry 6902 (class 0 OID 0)
-- Dependencies: 296
-- Name: COLUMN accounts__establishments.audit_connection_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__establishments.audit_connection_id IS 'Endereço IP da conexão';


--
-- TOC entry 6903 (class 0 OID 0)
-- Dependencies: 296
-- Name: COLUMN accounts__establishments.audit_partition_date; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__establishments.audit_partition_date IS 'Data para particionamento da tabela de auditoria';


--
-- TOC entry 297 (class 1259 OID 20338)
-- Name: accounts__establishments_2025_08; Type: TABLE; Schema: audit; Owner: postgres
--

CREATE TABLE audit.accounts__establishments_2025_08 (
    establishment_id uuid NOT NULL,
    name text NOT NULL,
    is_active boolean NOT NULL,
    activated_at timestamp with time zone,
    deactivated_at timestamp with time zone,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    audit_id bigint NOT NULL,
    audit_operation text NOT NULL,
    audit_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    audit_user text DEFAULT CURRENT_USER NOT NULL,
    audit_session_id text DEFAULT current_setting('application_name'::text) NOT NULL,
    audit_connection_id text DEFAULT inet_client_addr() NOT NULL,
    audit_partition_date date DEFAULT CURRENT_DATE NOT NULL
);


ALTER TABLE audit.accounts__establishments_2025_08 OWNER TO postgres;

--
-- TOC entry 295 (class 1259 OID 20322)
-- Name: accounts__establishments_audit_id_seq; Type: SEQUENCE; Schema: audit; Owner: postgres
--

ALTER TABLE audit.accounts__establishments ALTER COLUMN audit_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME audit.accounts__establishments_audit_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 299 (class 1259 OID 20354)
-- Name: accounts__features; Type: TABLE; Schema: audit; Owner: postgres
--

CREATE TABLE audit.accounts__features (
    feature_id uuid NOT NULL,
    module_id uuid,
    name text NOT NULL,
    code text NOT NULL,
    description text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    platform_id uuid,
    audit_id bigint NOT NULL,
    audit_operation text NOT NULL,
    audit_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    audit_user text DEFAULT CURRENT_USER NOT NULL,
    audit_session_id text DEFAULT current_setting('application_name'::text) NOT NULL,
    audit_connection_id text DEFAULT inet_client_addr() NOT NULL,
    audit_partition_date date DEFAULT CURRENT_DATE NOT NULL
)
PARTITION BY RANGE (audit_partition_date);


ALTER TABLE audit.accounts__features OWNER TO postgres;

--
-- TOC entry 6904 (class 0 OID 0)
-- Dependencies: 299
-- Name: TABLE accounts__features; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON TABLE audit.accounts__features IS 'AUDITORIA: Funcionalidades específicas associadas a módulos';


--
-- TOC entry 6905 (class 0 OID 0)
-- Dependencies: 299
-- Name: COLUMN accounts__features.feature_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__features.feature_id IS 'Identificador da feature';


--
-- TOC entry 6906 (class 0 OID 0)
-- Dependencies: 299
-- Name: COLUMN accounts__features.module_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__features.module_id IS 'Módulo ao qual a feature pertence';


--
-- TOC entry 6907 (class 0 OID 0)
-- Dependencies: 299
-- Name: COLUMN accounts__features.name; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__features.name IS 'Nome da feature';


--
-- TOC entry 6908 (class 0 OID 0)
-- Dependencies: 299
-- Name: COLUMN accounts__features.code; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__features.code IS 'Código único da feature (para verificação de permissão)';


--
-- TOC entry 6909 (class 0 OID 0)
-- Dependencies: 299
-- Name: COLUMN accounts__features.description; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__features.description IS 'Descrição da feature';


--
-- TOC entry 6910 (class 0 OID 0)
-- Dependencies: 299
-- Name: COLUMN accounts__features.created_at; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__features.created_at IS 'Data de criação';


--
-- TOC entry 6911 (class 0 OID 0)
-- Dependencies: 299
-- Name: COLUMN accounts__features.updated_at; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__features.updated_at IS 'Data da última atualização';


--
-- TOC entry 6912 (class 0 OID 0)
-- Dependencies: 299
-- Name: COLUMN accounts__features.audit_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__features.audit_id IS 'Identificador único do registro de auditoria';


--
-- TOC entry 6913 (class 0 OID 0)
-- Dependencies: 299
-- Name: COLUMN accounts__features.audit_operation; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__features.audit_operation IS 'Tipo de operação realizada (INSERT, UPDATE, DELETE)';


--
-- TOC entry 6914 (class 0 OID 0)
-- Dependencies: 299
-- Name: COLUMN accounts__features.audit_timestamp; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__features.audit_timestamp IS 'Data e hora da operação auditada';


--
-- TOC entry 6915 (class 0 OID 0)
-- Dependencies: 299
-- Name: COLUMN accounts__features.audit_user; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__features.audit_user IS 'Usuário que executou a operação';


--
-- TOC entry 6916 (class 0 OID 0)
-- Dependencies: 299
-- Name: COLUMN accounts__features.audit_session_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__features.audit_session_id IS 'Identificador da sessão da aplicação';


--
-- TOC entry 6917 (class 0 OID 0)
-- Dependencies: 299
-- Name: COLUMN accounts__features.audit_connection_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__features.audit_connection_id IS 'Endereço IP da conexão';


--
-- TOC entry 6918 (class 0 OID 0)
-- Dependencies: 299
-- Name: COLUMN accounts__features.audit_partition_date; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__features.audit_partition_date IS 'Data para particionamento da tabela de auditoria';


--
-- TOC entry 300 (class 1259 OID 20371)
-- Name: accounts__features_2025_08; Type: TABLE; Schema: audit; Owner: postgres
--

CREATE TABLE audit.accounts__features_2025_08 (
    feature_id uuid NOT NULL,
    module_id uuid,
    name text NOT NULL,
    code text NOT NULL,
    description text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    platform_id uuid,
    audit_id bigint NOT NULL,
    audit_operation text NOT NULL,
    audit_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    audit_user text DEFAULT CURRENT_USER NOT NULL,
    audit_session_id text DEFAULT current_setting('application_name'::text) NOT NULL,
    audit_connection_id text DEFAULT inet_client_addr() NOT NULL,
    audit_partition_date date DEFAULT CURRENT_DATE NOT NULL
);


ALTER TABLE audit.accounts__features_2025_08 OWNER TO postgres;

--
-- TOC entry 298 (class 1259 OID 20353)
-- Name: accounts__features_audit_id_seq; Type: SEQUENCE; Schema: audit; Owner: postgres
--

ALTER TABLE audit.accounts__features ALTER COLUMN audit_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME audit.accounts__features_audit_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 302 (class 1259 OID 20389)
-- Name: accounts__modules; Type: TABLE; Schema: audit; Owner: postgres
--

CREATE TABLE audit.accounts__modules (
    module_id uuid NOT NULL,
    name text NOT NULL,
    description text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    audit_id bigint NOT NULL,
    audit_operation text NOT NULL,
    audit_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    audit_user text DEFAULT CURRENT_USER NOT NULL,
    audit_session_id text DEFAULT current_setting('application_name'::text) NOT NULL,
    audit_connection_id text DEFAULT inet_client_addr() NOT NULL,
    audit_partition_date date DEFAULT CURRENT_DATE NOT NULL
)
PARTITION BY RANGE (audit_partition_date);


ALTER TABLE audit.accounts__modules OWNER TO postgres;

--
-- TOC entry 6919 (class 0 OID 0)
-- Dependencies: 302
-- Name: TABLE accounts__modules; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON TABLE audit.accounts__modules IS 'AUDITORIA: Módulos funcionais do sistema (ex: Lista de Compras)';


--
-- TOC entry 6920 (class 0 OID 0)
-- Dependencies: 302
-- Name: COLUMN accounts__modules.module_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__modules.module_id IS 'Identificador único do módulo';


--
-- TOC entry 6921 (class 0 OID 0)
-- Dependencies: 302
-- Name: COLUMN accounts__modules.name; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__modules.name IS 'Nome do módulo';


--
-- TOC entry 6922 (class 0 OID 0)
-- Dependencies: 302
-- Name: COLUMN accounts__modules.description; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__modules.description IS 'Descrição do módulo';


--
-- TOC entry 6923 (class 0 OID 0)
-- Dependencies: 302
-- Name: COLUMN accounts__modules.created_at; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__modules.created_at IS 'Data de criação';


--
-- TOC entry 6924 (class 0 OID 0)
-- Dependencies: 302
-- Name: COLUMN accounts__modules.updated_at; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__modules.updated_at IS 'Data da última atualização';


--
-- TOC entry 6925 (class 0 OID 0)
-- Dependencies: 302
-- Name: COLUMN accounts__modules.audit_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__modules.audit_id IS 'Identificador único do registro de auditoria';


--
-- TOC entry 6926 (class 0 OID 0)
-- Dependencies: 302
-- Name: COLUMN accounts__modules.audit_operation; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__modules.audit_operation IS 'Tipo de operação realizada (INSERT, UPDATE, DELETE)';


--
-- TOC entry 6927 (class 0 OID 0)
-- Dependencies: 302
-- Name: COLUMN accounts__modules.audit_timestamp; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__modules.audit_timestamp IS 'Data e hora da operação auditada';


--
-- TOC entry 6928 (class 0 OID 0)
-- Dependencies: 302
-- Name: COLUMN accounts__modules.audit_user; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__modules.audit_user IS 'Usuário que executou a operação';


--
-- TOC entry 6929 (class 0 OID 0)
-- Dependencies: 302
-- Name: COLUMN accounts__modules.audit_session_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__modules.audit_session_id IS 'Identificador da sessão da aplicação';


--
-- TOC entry 6930 (class 0 OID 0)
-- Dependencies: 302
-- Name: COLUMN accounts__modules.audit_connection_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__modules.audit_connection_id IS 'Endereço IP da conexão';


--
-- TOC entry 6931 (class 0 OID 0)
-- Dependencies: 302
-- Name: COLUMN accounts__modules.audit_partition_date; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__modules.audit_partition_date IS 'Data para particionamento da tabela de auditoria';


--
-- TOC entry 303 (class 1259 OID 20404)
-- Name: accounts__modules_2025_08; Type: TABLE; Schema: audit; Owner: postgres
--

CREATE TABLE audit.accounts__modules_2025_08 (
    module_id uuid NOT NULL,
    name text NOT NULL,
    description text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    audit_id bigint NOT NULL,
    audit_operation text NOT NULL,
    audit_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    audit_user text DEFAULT CURRENT_USER NOT NULL,
    audit_session_id text DEFAULT current_setting('application_name'::text) NOT NULL,
    audit_connection_id text DEFAULT inet_client_addr() NOT NULL,
    audit_partition_date date DEFAULT CURRENT_DATE NOT NULL
);


ALTER TABLE audit.accounts__modules_2025_08 OWNER TO postgres;

--
-- TOC entry 301 (class 1259 OID 20388)
-- Name: accounts__modules_audit_id_seq; Type: SEQUENCE; Schema: audit; Owner: postgres
--

ALTER TABLE audit.accounts__modules ALTER COLUMN audit_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME audit.accounts__modules_audit_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 305 (class 1259 OID 20420)
-- Name: accounts__platforms; Type: TABLE; Schema: audit; Owner: postgres
--

CREATE TABLE audit.accounts__platforms (
    platform_id uuid NOT NULL,
    name text NOT NULL,
    description text,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone,
    audit_id bigint NOT NULL,
    audit_operation text NOT NULL,
    audit_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    audit_user text DEFAULT CURRENT_USER NOT NULL,
    audit_session_id text DEFAULT current_setting('application_name'::text) NOT NULL,
    audit_connection_id text DEFAULT inet_client_addr() NOT NULL,
    audit_partition_date date DEFAULT CURRENT_DATE NOT NULL
)
PARTITION BY RANGE (audit_partition_date);


ALTER TABLE audit.accounts__platforms OWNER TO postgres;

--
-- TOC entry 6932 (class 0 OID 0)
-- Dependencies: 305
-- Name: TABLE accounts__platforms; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON TABLE audit.accounts__platforms IS 'AUDITORIA: Plataformas do sistema, como Área do Fornecedor, Aplicativo do Estabelecimento, etc.';


--
-- TOC entry 6933 (class 0 OID 0)
-- Dependencies: 305
-- Name: COLUMN accounts__platforms.platform_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__platforms.platform_id IS 'Identificador único da plataforma';


--
-- TOC entry 6934 (class 0 OID 0)
-- Dependencies: 305
-- Name: COLUMN accounts__platforms.name; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__platforms.name IS 'Nome da plataforma (ex: Área do Fornecedor)';


--
-- TOC entry 6935 (class 0 OID 0)
-- Dependencies: 305
-- Name: COLUMN accounts__platforms.description; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__platforms.description IS 'Descrição da plataforma';


--
-- TOC entry 6936 (class 0 OID 0)
-- Dependencies: 305
-- Name: COLUMN accounts__platforms.created_at; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__platforms.created_at IS 'Data de criação da plataforma';


--
-- TOC entry 6937 (class 0 OID 0)
-- Dependencies: 305
-- Name: COLUMN accounts__platforms.updated_at; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__platforms.updated_at IS 'Data da última atualização da plataforma';


--
-- TOC entry 6938 (class 0 OID 0)
-- Dependencies: 305
-- Name: COLUMN accounts__platforms.audit_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__platforms.audit_id IS 'Identificador único do registro de auditoria';


--
-- TOC entry 6939 (class 0 OID 0)
-- Dependencies: 305
-- Name: COLUMN accounts__platforms.audit_operation; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__platforms.audit_operation IS 'Tipo de operação realizada (INSERT, UPDATE, DELETE)';


--
-- TOC entry 6940 (class 0 OID 0)
-- Dependencies: 305
-- Name: COLUMN accounts__platforms.audit_timestamp; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__platforms.audit_timestamp IS 'Data e hora da operação auditada';


--
-- TOC entry 6941 (class 0 OID 0)
-- Dependencies: 305
-- Name: COLUMN accounts__platforms.audit_user; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__platforms.audit_user IS 'Usuário que executou a operação';


--
-- TOC entry 6942 (class 0 OID 0)
-- Dependencies: 305
-- Name: COLUMN accounts__platforms.audit_session_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__platforms.audit_session_id IS 'Identificador da sessão da aplicação';


--
-- TOC entry 6943 (class 0 OID 0)
-- Dependencies: 305
-- Name: COLUMN accounts__platforms.audit_connection_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__platforms.audit_connection_id IS 'Endereço IP da conexão';


--
-- TOC entry 6944 (class 0 OID 0)
-- Dependencies: 305
-- Name: COLUMN accounts__platforms.audit_partition_date; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__platforms.audit_partition_date IS 'Data para particionamento da tabela de auditoria';


--
-- TOC entry 306 (class 1259 OID 20435)
-- Name: accounts__platforms_2025_08; Type: TABLE; Schema: audit; Owner: postgres
--

CREATE TABLE audit.accounts__platforms_2025_08 (
    platform_id uuid NOT NULL,
    name text NOT NULL,
    description text,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone,
    audit_id bigint NOT NULL,
    audit_operation text NOT NULL,
    audit_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    audit_user text DEFAULT CURRENT_USER NOT NULL,
    audit_session_id text DEFAULT current_setting('application_name'::text) NOT NULL,
    audit_connection_id text DEFAULT inet_client_addr() NOT NULL,
    audit_partition_date date DEFAULT CURRENT_DATE NOT NULL
);


ALTER TABLE audit.accounts__platforms_2025_08 OWNER TO postgres;

--
-- TOC entry 304 (class 1259 OID 20419)
-- Name: accounts__platforms_audit_id_seq; Type: SEQUENCE; Schema: audit; Owner: postgres
--

ALTER TABLE audit.accounts__platforms ALTER COLUMN audit_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME audit.accounts__platforms_audit_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 308 (class 1259 OID 20451)
-- Name: accounts__role_features; Type: TABLE; Schema: audit; Owner: postgres
--

CREATE TABLE audit.accounts__role_features (
    role_feature_id uuid NOT NULL,
    role_id uuid NOT NULL,
    feature_id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone,
    audit_id bigint NOT NULL,
    audit_operation text NOT NULL,
    audit_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    audit_user text DEFAULT CURRENT_USER NOT NULL,
    audit_session_id text DEFAULT current_setting('application_name'::text) NOT NULL,
    audit_connection_id text DEFAULT inet_client_addr() NOT NULL,
    audit_partition_date date DEFAULT CURRENT_DATE NOT NULL
)
PARTITION BY RANGE (audit_partition_date);


ALTER TABLE audit.accounts__role_features OWNER TO postgres;

--
-- TOC entry 6945 (class 0 OID 0)
-- Dependencies: 308
-- Name: TABLE accounts__role_features; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON TABLE audit.accounts__role_features IS 'AUDITORIA: Relaciona os papéis do sistema com suas permissões (features)';


--
-- TOC entry 6946 (class 0 OID 0)
-- Dependencies: 308
-- Name: COLUMN accounts__role_features.role_feature_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__role_features.role_feature_id IS 'Identificador único do vínculo role-feature';


--
-- TOC entry 6947 (class 0 OID 0)
-- Dependencies: 308
-- Name: COLUMN accounts__role_features.role_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__role_features.role_id IS 'Papel que receberá as permissões';


--
-- TOC entry 6948 (class 0 OID 0)
-- Dependencies: 308
-- Name: COLUMN accounts__role_features.feature_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__role_features.feature_id IS 'Permissão (feature) associada ao papel';


--
-- TOC entry 6949 (class 0 OID 0)
-- Dependencies: 308
-- Name: COLUMN accounts__role_features.created_at; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__role_features.created_at IS 'Data de criação';


--
-- TOC entry 6950 (class 0 OID 0)
-- Dependencies: 308
-- Name: COLUMN accounts__role_features.updated_at; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__role_features.updated_at IS 'Data da última modificação';


--
-- TOC entry 6951 (class 0 OID 0)
-- Dependencies: 308
-- Name: COLUMN accounts__role_features.audit_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__role_features.audit_id IS 'Identificador único do registro de auditoria';


--
-- TOC entry 6952 (class 0 OID 0)
-- Dependencies: 308
-- Name: COLUMN accounts__role_features.audit_operation; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__role_features.audit_operation IS 'Tipo de operação realizada (INSERT, UPDATE, DELETE)';


--
-- TOC entry 6953 (class 0 OID 0)
-- Dependencies: 308
-- Name: COLUMN accounts__role_features.audit_timestamp; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__role_features.audit_timestamp IS 'Data e hora da operação auditada';


--
-- TOC entry 6954 (class 0 OID 0)
-- Dependencies: 308
-- Name: COLUMN accounts__role_features.audit_user; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__role_features.audit_user IS 'Usuário que executou a operação';


--
-- TOC entry 6955 (class 0 OID 0)
-- Dependencies: 308
-- Name: COLUMN accounts__role_features.audit_session_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__role_features.audit_session_id IS 'Identificador da sessão da aplicação';


--
-- TOC entry 6956 (class 0 OID 0)
-- Dependencies: 308
-- Name: COLUMN accounts__role_features.audit_connection_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__role_features.audit_connection_id IS 'Endereço IP da conexão';


--
-- TOC entry 6957 (class 0 OID 0)
-- Dependencies: 308
-- Name: COLUMN accounts__role_features.audit_partition_date; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__role_features.audit_partition_date IS 'Data para particionamento da tabela de auditoria';


--
-- TOC entry 309 (class 1259 OID 20468)
-- Name: accounts__role_features_2025_08; Type: TABLE; Schema: audit; Owner: postgres
--

CREATE TABLE audit.accounts__role_features_2025_08 (
    role_feature_id uuid NOT NULL,
    role_id uuid NOT NULL,
    feature_id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone,
    audit_id bigint NOT NULL,
    audit_operation text NOT NULL,
    audit_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    audit_user text DEFAULT CURRENT_USER NOT NULL,
    audit_session_id text DEFAULT current_setting('application_name'::text) NOT NULL,
    audit_connection_id text DEFAULT inet_client_addr() NOT NULL,
    audit_partition_date date DEFAULT CURRENT_DATE NOT NULL
);


ALTER TABLE audit.accounts__role_features_2025_08 OWNER TO postgres;

--
-- TOC entry 307 (class 1259 OID 20450)
-- Name: accounts__role_features_audit_id_seq; Type: SEQUENCE; Schema: audit; Owner: postgres
--

ALTER TABLE audit.accounts__role_features ALTER COLUMN audit_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME audit.accounts__role_features_audit_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 311 (class 1259 OID 20486)
-- Name: accounts__roles; Type: TABLE; Schema: audit; Owner: postgres
--

CREATE TABLE audit.accounts__roles (
    role_id uuid NOT NULL,
    name text NOT NULL,
    description text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    audit_id bigint NOT NULL,
    audit_operation text NOT NULL,
    audit_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    audit_user text DEFAULT CURRENT_USER NOT NULL,
    audit_session_id text DEFAULT current_setting('application_name'::text) NOT NULL,
    audit_connection_id text DEFAULT inet_client_addr() NOT NULL,
    audit_partition_date date DEFAULT CURRENT_DATE NOT NULL
)
PARTITION BY RANGE (audit_partition_date);


ALTER TABLE audit.accounts__roles OWNER TO postgres;

--
-- TOC entry 6958 (class 0 OID 0)
-- Dependencies: 311
-- Name: TABLE accounts__roles; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON TABLE audit.accounts__roles IS 'AUDITORIA: Papéis nomeados do sistema que agrupam permissões';


--
-- TOC entry 6959 (class 0 OID 0)
-- Dependencies: 311
-- Name: COLUMN accounts__roles.role_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__roles.role_id IS 'Identificador único do papel';


--
-- TOC entry 6960 (class 0 OID 0)
-- Dependencies: 311
-- Name: COLUMN accounts__roles.name; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__roles.name IS 'Nome do papel (ex: comprador, gestor)';


--
-- TOC entry 6961 (class 0 OID 0)
-- Dependencies: 311
-- Name: COLUMN accounts__roles.description; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__roles.description IS 'Descrição funcional do papel';


--
-- TOC entry 6962 (class 0 OID 0)
-- Dependencies: 311
-- Name: COLUMN accounts__roles.created_at; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__roles.created_at IS 'Data de criação';


--
-- TOC entry 6963 (class 0 OID 0)
-- Dependencies: 311
-- Name: COLUMN accounts__roles.updated_at; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__roles.updated_at IS 'Data da última atualização';


--
-- TOC entry 6964 (class 0 OID 0)
-- Dependencies: 311
-- Name: COLUMN accounts__roles.audit_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__roles.audit_id IS 'Identificador único do registro de auditoria';


--
-- TOC entry 6965 (class 0 OID 0)
-- Dependencies: 311
-- Name: COLUMN accounts__roles.audit_operation; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__roles.audit_operation IS 'Tipo de operação realizada (INSERT, UPDATE, DELETE)';


--
-- TOC entry 6966 (class 0 OID 0)
-- Dependencies: 311
-- Name: COLUMN accounts__roles.audit_timestamp; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__roles.audit_timestamp IS 'Data e hora da operação auditada';


--
-- TOC entry 6967 (class 0 OID 0)
-- Dependencies: 311
-- Name: COLUMN accounts__roles.audit_user; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__roles.audit_user IS 'Usuário que executou a operação';


--
-- TOC entry 6968 (class 0 OID 0)
-- Dependencies: 311
-- Name: COLUMN accounts__roles.audit_session_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__roles.audit_session_id IS 'Identificador da sessão da aplicação';


--
-- TOC entry 6969 (class 0 OID 0)
-- Dependencies: 311
-- Name: COLUMN accounts__roles.audit_connection_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__roles.audit_connection_id IS 'Endereço IP da conexão';


--
-- TOC entry 6970 (class 0 OID 0)
-- Dependencies: 311
-- Name: COLUMN accounts__roles.audit_partition_date; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__roles.audit_partition_date IS 'Data para particionamento da tabela de auditoria';


--
-- TOC entry 312 (class 1259 OID 20501)
-- Name: accounts__roles_2025_08; Type: TABLE; Schema: audit; Owner: postgres
--

CREATE TABLE audit.accounts__roles_2025_08 (
    role_id uuid NOT NULL,
    name text NOT NULL,
    description text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    audit_id bigint NOT NULL,
    audit_operation text NOT NULL,
    audit_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    audit_user text DEFAULT CURRENT_USER NOT NULL,
    audit_session_id text DEFAULT current_setting('application_name'::text) NOT NULL,
    audit_connection_id text DEFAULT inet_client_addr() NOT NULL,
    audit_partition_date date DEFAULT CURRENT_DATE NOT NULL
);


ALTER TABLE audit.accounts__roles_2025_08 OWNER TO postgres;

--
-- TOC entry 310 (class 1259 OID 20485)
-- Name: accounts__roles_audit_id_seq; Type: SEQUENCE; Schema: audit; Owner: postgres
--

ALTER TABLE audit.accounts__roles ALTER COLUMN audit_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME audit.accounts__roles_audit_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 314 (class 1259 OID 20517)
-- Name: accounts__suppliers; Type: TABLE; Schema: audit; Owner: postgres
--

CREATE TABLE audit.accounts__suppliers (
    supplier_id uuid NOT NULL,
    name text NOT NULL,
    is_active boolean NOT NULL,
    activated_at timestamp with time zone,
    deactivated_at timestamp with time zone,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    audit_id bigint NOT NULL,
    audit_operation text NOT NULL,
    audit_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    audit_user text DEFAULT CURRENT_USER NOT NULL,
    audit_session_id text DEFAULT current_setting('application_name'::text) NOT NULL,
    audit_connection_id text DEFAULT inet_client_addr() NOT NULL,
    audit_partition_date date DEFAULT CURRENT_DATE NOT NULL
)
PARTITION BY RANGE (audit_partition_date);


ALTER TABLE audit.accounts__suppliers OWNER TO postgres;

--
-- TOC entry 6971 (class 0 OID 0)
-- Dependencies: 314
-- Name: TABLE accounts__suppliers; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON TABLE audit.accounts__suppliers IS 'AUDITORIA: Fornecedores do sistema, que possuem funcionários e filiais';


--
-- TOC entry 6972 (class 0 OID 0)
-- Dependencies: 314
-- Name: COLUMN accounts__suppliers.supplier_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__suppliers.supplier_id IS 'Identificador único do fornecedor';


--
-- TOC entry 6973 (class 0 OID 0)
-- Dependencies: 314
-- Name: COLUMN accounts__suppliers.name; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__suppliers.name IS 'Nome do fornecedor';


--
-- TOC entry 6974 (class 0 OID 0)
-- Dependencies: 314
-- Name: COLUMN accounts__suppliers.is_active; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__suppliers.is_active IS 'Indica se o fornecedor está ativo';


--
-- TOC entry 6975 (class 0 OID 0)
-- Dependencies: 314
-- Name: COLUMN accounts__suppliers.activated_at; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__suppliers.activated_at IS 'Data de ativação';


--
-- TOC entry 6976 (class 0 OID 0)
-- Dependencies: 314
-- Name: COLUMN accounts__suppliers.deactivated_at; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__suppliers.deactivated_at IS 'Data de desativação';


--
-- TOC entry 6977 (class 0 OID 0)
-- Dependencies: 314
-- Name: COLUMN accounts__suppliers.created_at; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__suppliers.created_at IS 'Data de criação do registro';


--
-- TOC entry 6978 (class 0 OID 0)
-- Dependencies: 314
-- Name: COLUMN accounts__suppliers.updated_at; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__suppliers.updated_at IS 'Data da última atualização do registro';


--
-- TOC entry 6979 (class 0 OID 0)
-- Dependencies: 314
-- Name: COLUMN accounts__suppliers.audit_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__suppliers.audit_id IS 'Identificador único do registro de auditoria';


--
-- TOC entry 6980 (class 0 OID 0)
-- Dependencies: 314
-- Name: COLUMN accounts__suppliers.audit_operation; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__suppliers.audit_operation IS 'Tipo de operação realizada (INSERT, UPDATE, DELETE)';


--
-- TOC entry 6981 (class 0 OID 0)
-- Dependencies: 314
-- Name: COLUMN accounts__suppliers.audit_timestamp; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__suppliers.audit_timestamp IS 'Data e hora da operação auditada';


--
-- TOC entry 6982 (class 0 OID 0)
-- Dependencies: 314
-- Name: COLUMN accounts__suppliers.audit_user; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__suppliers.audit_user IS 'Usuário que executou a operação';


--
-- TOC entry 6983 (class 0 OID 0)
-- Dependencies: 314
-- Name: COLUMN accounts__suppliers.audit_session_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__suppliers.audit_session_id IS 'Identificador da sessão da aplicação';


--
-- TOC entry 6984 (class 0 OID 0)
-- Dependencies: 314
-- Name: COLUMN accounts__suppliers.audit_connection_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__suppliers.audit_connection_id IS 'Endereço IP da conexão';


--
-- TOC entry 6985 (class 0 OID 0)
-- Dependencies: 314
-- Name: COLUMN accounts__suppliers.audit_partition_date; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__suppliers.audit_partition_date IS 'Data para particionamento da tabela de auditoria';


--
-- TOC entry 315 (class 1259 OID 20532)
-- Name: accounts__suppliers_2025_08; Type: TABLE; Schema: audit; Owner: postgres
--

CREATE TABLE audit.accounts__suppliers_2025_08 (
    supplier_id uuid NOT NULL,
    name text NOT NULL,
    is_active boolean NOT NULL,
    activated_at timestamp with time zone,
    deactivated_at timestamp with time zone,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    audit_id bigint NOT NULL,
    audit_operation text NOT NULL,
    audit_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    audit_user text DEFAULT CURRENT_USER NOT NULL,
    audit_session_id text DEFAULT current_setting('application_name'::text) NOT NULL,
    audit_connection_id text DEFAULT inet_client_addr() NOT NULL,
    audit_partition_date date DEFAULT CURRENT_DATE NOT NULL
);


ALTER TABLE audit.accounts__suppliers_2025_08 OWNER TO postgres;

--
-- TOC entry 313 (class 1259 OID 20516)
-- Name: accounts__suppliers_audit_id_seq; Type: SEQUENCE; Schema: audit; Owner: postgres
--

ALTER TABLE audit.accounts__suppliers ALTER COLUMN audit_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME audit.accounts__suppliers_audit_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 317 (class 1259 OID 20548)
-- Name: accounts__users; Type: TABLE; Schema: audit; Owner: postgres
--

CREATE TABLE audit.accounts__users (
    user_id uuid NOT NULL,
    email text NOT NULL,
    full_name text NOT NULL,
    cognito_sub text NOT NULL,
    is_active boolean NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone,
    audit_id bigint NOT NULL,
    audit_operation text NOT NULL,
    audit_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    audit_user text DEFAULT CURRENT_USER NOT NULL,
    audit_session_id text DEFAULT current_setting('application_name'::text) NOT NULL,
    audit_connection_id text DEFAULT inet_client_addr() NOT NULL,
    audit_partition_date date DEFAULT CURRENT_DATE NOT NULL
)
PARTITION BY RANGE (audit_partition_date);


ALTER TABLE audit.accounts__users OWNER TO postgres;

--
-- TOC entry 6986 (class 0 OID 0)
-- Dependencies: 317
-- Name: TABLE accounts__users; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON TABLE audit.accounts__users IS 'AUDITORIA: Usuários autenticáveis no sistema (funcionários)';


--
-- TOC entry 6987 (class 0 OID 0)
-- Dependencies: 317
-- Name: COLUMN accounts__users.user_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__users.user_id IS 'Identificador único do usuário';


--
-- TOC entry 6988 (class 0 OID 0)
-- Dependencies: 317
-- Name: COLUMN accounts__users.email; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__users.email IS 'Endereço de e-mail usado para login';


--
-- TOC entry 6989 (class 0 OID 0)
-- Dependencies: 317
-- Name: COLUMN accounts__users.full_name; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__users.full_name IS 'Nome completo do usuário';


--
-- TOC entry 6990 (class 0 OID 0)
-- Dependencies: 317
-- Name: COLUMN accounts__users.cognito_sub; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__users.cognito_sub IS 'Identificador único do Cognito (OAuth/Auth)';


--
-- TOC entry 6991 (class 0 OID 0)
-- Dependencies: 317
-- Name: COLUMN accounts__users.is_active; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__users.is_active IS 'Indica se o usuário está ativo no sistema';


--
-- TOC entry 6992 (class 0 OID 0)
-- Dependencies: 317
-- Name: COLUMN accounts__users.created_at; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__users.created_at IS 'Data de criação do registro';


--
-- TOC entry 6993 (class 0 OID 0)
-- Dependencies: 317
-- Name: COLUMN accounts__users.updated_at; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__users.updated_at IS 'Data da última atualização do registro';


--
-- TOC entry 6994 (class 0 OID 0)
-- Dependencies: 317
-- Name: COLUMN accounts__users.audit_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__users.audit_id IS 'Identificador único do registro de auditoria';


--
-- TOC entry 6995 (class 0 OID 0)
-- Dependencies: 317
-- Name: COLUMN accounts__users.audit_operation; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__users.audit_operation IS 'Tipo de operação realizada (INSERT, UPDATE, DELETE)';


--
-- TOC entry 6996 (class 0 OID 0)
-- Dependencies: 317
-- Name: COLUMN accounts__users.audit_timestamp; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__users.audit_timestamp IS 'Data e hora da operação auditada';


--
-- TOC entry 6997 (class 0 OID 0)
-- Dependencies: 317
-- Name: COLUMN accounts__users.audit_user; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__users.audit_user IS 'Usuário que executou a operação';


--
-- TOC entry 6998 (class 0 OID 0)
-- Dependencies: 317
-- Name: COLUMN accounts__users.audit_session_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__users.audit_session_id IS 'Identificador da sessão da aplicação';


--
-- TOC entry 6999 (class 0 OID 0)
-- Dependencies: 317
-- Name: COLUMN accounts__users.audit_connection_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__users.audit_connection_id IS 'Endereço IP da conexão';


--
-- TOC entry 7000 (class 0 OID 0)
-- Dependencies: 317
-- Name: COLUMN accounts__users.audit_partition_date; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.accounts__users.audit_partition_date IS 'Data para particionamento da tabela de auditoria';


--
-- TOC entry 318 (class 1259 OID 20563)
-- Name: accounts__users_2025_08; Type: TABLE; Schema: audit; Owner: postgres
--

CREATE TABLE audit.accounts__users_2025_08 (
    user_id uuid NOT NULL,
    email text NOT NULL,
    full_name text NOT NULL,
    cognito_sub text NOT NULL,
    is_active boolean NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone,
    audit_id bigint NOT NULL,
    audit_operation text NOT NULL,
    audit_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    audit_user text DEFAULT CURRENT_USER NOT NULL,
    audit_session_id text DEFAULT current_setting('application_name'::text) NOT NULL,
    audit_connection_id text DEFAULT inet_client_addr() NOT NULL,
    audit_partition_date date DEFAULT CURRENT_DATE NOT NULL
);


ALTER TABLE audit.accounts__users_2025_08 OWNER TO postgres;

--
-- TOC entry 316 (class 1259 OID 20547)
-- Name: accounts__users_audit_id_seq; Type: SEQUENCE; Schema: audit; Owner: postgres
--

ALTER TABLE audit.accounts__users ALTER COLUMN audit_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME audit.accounts__users_audit_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 320 (class 1259 OID 20579)
-- Name: catalogs__brands; Type: TABLE; Schema: audit; Owner: postgres
--

CREATE TABLE audit.catalogs__brands (
    brand_id uuid NOT NULL,
    name text NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone,
    audit_id bigint NOT NULL,
    audit_operation text NOT NULL,
    audit_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    audit_user text DEFAULT CURRENT_USER NOT NULL,
    audit_session_id text DEFAULT current_setting('application_name'::text) NOT NULL,
    audit_connection_id text DEFAULT inet_client_addr() NOT NULL,
    audit_partition_date date DEFAULT CURRENT_DATE NOT NULL
)
PARTITION BY RANGE (audit_partition_date);


ALTER TABLE audit.catalogs__brands OWNER TO postgres;

--
-- TOC entry 7001 (class 0 OID 0)
-- Dependencies: 320
-- Name: TABLE catalogs__brands; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON TABLE audit.catalogs__brands IS 'AUDITORIA: Marca ou fabricante do produto';


--
-- TOC entry 7002 (class 0 OID 0)
-- Dependencies: 320
-- Name: COLUMN catalogs__brands.brand_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__brands.brand_id IS 'Identificador único da marca';


--
-- TOC entry 7003 (class 0 OID 0)
-- Dependencies: 320
-- Name: COLUMN catalogs__brands.name; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__brands.name IS 'Nome da marca';


--
-- TOC entry 7004 (class 0 OID 0)
-- Dependencies: 320
-- Name: COLUMN catalogs__brands.created_at; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__brands.created_at IS 'Data de criação do registro';


--
-- TOC entry 7005 (class 0 OID 0)
-- Dependencies: 320
-- Name: COLUMN catalogs__brands.updated_at; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__brands.updated_at IS 'Data da última atualização do registro';


--
-- TOC entry 7006 (class 0 OID 0)
-- Dependencies: 320
-- Name: COLUMN catalogs__brands.audit_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__brands.audit_id IS 'Identificador único do registro de auditoria';


--
-- TOC entry 7007 (class 0 OID 0)
-- Dependencies: 320
-- Name: COLUMN catalogs__brands.audit_operation; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__brands.audit_operation IS 'Tipo de operação realizada (INSERT, UPDATE, DELETE)';


--
-- TOC entry 7008 (class 0 OID 0)
-- Dependencies: 320
-- Name: COLUMN catalogs__brands.audit_timestamp; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__brands.audit_timestamp IS 'Data e hora da operação auditada';


--
-- TOC entry 7009 (class 0 OID 0)
-- Dependencies: 320
-- Name: COLUMN catalogs__brands.audit_user; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__brands.audit_user IS 'Usuário que executou a operação';


--
-- TOC entry 7010 (class 0 OID 0)
-- Dependencies: 320
-- Name: COLUMN catalogs__brands.audit_session_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__brands.audit_session_id IS 'Identificador da sessão da aplicação';


--
-- TOC entry 7011 (class 0 OID 0)
-- Dependencies: 320
-- Name: COLUMN catalogs__brands.audit_connection_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__brands.audit_connection_id IS 'Endereço IP da conexão';


--
-- TOC entry 7012 (class 0 OID 0)
-- Dependencies: 320
-- Name: COLUMN catalogs__brands.audit_partition_date; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__brands.audit_partition_date IS 'Data para particionamento da tabela de auditoria';


--
-- TOC entry 321 (class 1259 OID 20594)
-- Name: catalogs__brands_2025_08; Type: TABLE; Schema: audit; Owner: postgres
--

CREATE TABLE audit.catalogs__brands_2025_08 (
    brand_id uuid NOT NULL,
    name text NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone,
    audit_id bigint NOT NULL,
    audit_operation text NOT NULL,
    audit_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    audit_user text DEFAULT CURRENT_USER NOT NULL,
    audit_session_id text DEFAULT current_setting('application_name'::text) NOT NULL,
    audit_connection_id text DEFAULT inet_client_addr() NOT NULL,
    audit_partition_date date DEFAULT CURRENT_DATE NOT NULL
);


ALTER TABLE audit.catalogs__brands_2025_08 OWNER TO postgres;

--
-- TOC entry 319 (class 1259 OID 20578)
-- Name: catalogs__brands_audit_id_seq; Type: SEQUENCE; Schema: audit; Owner: postgres
--

ALTER TABLE audit.catalogs__brands ALTER COLUMN audit_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME audit.catalogs__brands_audit_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 323 (class 1259 OID 20610)
-- Name: catalogs__categories; Type: TABLE; Schema: audit; Owner: postgres
--

CREATE TABLE audit.catalogs__categories (
    category_id uuid NOT NULL,
    name text NOT NULL,
    description text,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone,
    audit_id bigint NOT NULL,
    audit_operation text NOT NULL,
    audit_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    audit_user text DEFAULT CURRENT_USER NOT NULL,
    audit_session_id text DEFAULT current_setting('application_name'::text) NOT NULL,
    audit_connection_id text DEFAULT inet_client_addr() NOT NULL,
    audit_partition_date date DEFAULT CURRENT_DATE NOT NULL
)
PARTITION BY RANGE (audit_partition_date);


ALTER TABLE audit.catalogs__categories OWNER TO postgres;

--
-- TOC entry 7013 (class 0 OID 0)
-- Dependencies: 323
-- Name: TABLE catalogs__categories; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON TABLE audit.catalogs__categories IS 'AUDITORIA: Categorias amplas para agrupamento dos produtos';


--
-- TOC entry 7014 (class 0 OID 0)
-- Dependencies: 323
-- Name: COLUMN catalogs__categories.category_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__categories.category_id IS 'Identificador único da categoria';


--
-- TOC entry 7015 (class 0 OID 0)
-- Dependencies: 323
-- Name: COLUMN catalogs__categories.name; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__categories.name IS 'Nome da categoria';


--
-- TOC entry 7016 (class 0 OID 0)
-- Dependencies: 323
-- Name: COLUMN catalogs__categories.description; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__categories.description IS 'Descrição da categoria';


--
-- TOC entry 7017 (class 0 OID 0)
-- Dependencies: 323
-- Name: COLUMN catalogs__categories.created_at; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__categories.created_at IS 'Data de criação do registro';


--
-- TOC entry 7018 (class 0 OID 0)
-- Dependencies: 323
-- Name: COLUMN catalogs__categories.updated_at; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__categories.updated_at IS 'Data da última atualização do registro';


--
-- TOC entry 7019 (class 0 OID 0)
-- Dependencies: 323
-- Name: COLUMN catalogs__categories.audit_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__categories.audit_id IS 'Identificador único do registro de auditoria';


--
-- TOC entry 7020 (class 0 OID 0)
-- Dependencies: 323
-- Name: COLUMN catalogs__categories.audit_operation; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__categories.audit_operation IS 'Tipo de operação realizada (INSERT, UPDATE, DELETE)';


--
-- TOC entry 7021 (class 0 OID 0)
-- Dependencies: 323
-- Name: COLUMN catalogs__categories.audit_timestamp; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__categories.audit_timestamp IS 'Data e hora da operação auditada';


--
-- TOC entry 7022 (class 0 OID 0)
-- Dependencies: 323
-- Name: COLUMN catalogs__categories.audit_user; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__categories.audit_user IS 'Usuário que executou a operação';


--
-- TOC entry 7023 (class 0 OID 0)
-- Dependencies: 323
-- Name: COLUMN catalogs__categories.audit_session_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__categories.audit_session_id IS 'Identificador da sessão da aplicação';


--
-- TOC entry 7024 (class 0 OID 0)
-- Dependencies: 323
-- Name: COLUMN catalogs__categories.audit_connection_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__categories.audit_connection_id IS 'Endereço IP da conexão';


--
-- TOC entry 7025 (class 0 OID 0)
-- Dependencies: 323
-- Name: COLUMN catalogs__categories.audit_partition_date; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__categories.audit_partition_date IS 'Data para particionamento da tabela de auditoria';


--
-- TOC entry 324 (class 1259 OID 20625)
-- Name: catalogs__categories_2025_08; Type: TABLE; Schema: audit; Owner: postgres
--

CREATE TABLE audit.catalogs__categories_2025_08 (
    category_id uuid NOT NULL,
    name text NOT NULL,
    description text,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone,
    audit_id bigint NOT NULL,
    audit_operation text NOT NULL,
    audit_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    audit_user text DEFAULT CURRENT_USER NOT NULL,
    audit_session_id text DEFAULT current_setting('application_name'::text) NOT NULL,
    audit_connection_id text DEFAULT inet_client_addr() NOT NULL,
    audit_partition_date date DEFAULT CURRENT_DATE NOT NULL
);


ALTER TABLE audit.catalogs__categories_2025_08 OWNER TO postgres;

--
-- TOC entry 322 (class 1259 OID 20609)
-- Name: catalogs__categories_audit_id_seq; Type: SEQUENCE; Schema: audit; Owner: postgres
--

ALTER TABLE audit.catalogs__categories ALTER COLUMN audit_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME audit.catalogs__categories_audit_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 326 (class 1259 OID 20641)
-- Name: catalogs__compositions; Type: TABLE; Schema: audit; Owner: postgres
--

CREATE TABLE audit.catalogs__compositions (
    composition_id uuid NOT NULL,
    name text NOT NULL,
    description text,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone,
    audit_id bigint NOT NULL,
    audit_operation text NOT NULL,
    audit_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    audit_user text DEFAULT CURRENT_USER NOT NULL,
    audit_session_id text DEFAULT current_setting('application_name'::text) NOT NULL,
    audit_connection_id text DEFAULT inet_client_addr() NOT NULL,
    audit_partition_date date DEFAULT CURRENT_DATE NOT NULL
)
PARTITION BY RANGE (audit_partition_date);


ALTER TABLE audit.catalogs__compositions OWNER TO postgres;

--
-- TOC entry 7026 (class 0 OID 0)
-- Dependencies: 326
-- Name: TABLE catalogs__compositions; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON TABLE audit.catalogs__compositions IS 'AUDITORIA: Composição ou matéria-prima do produto (ex: Grano Duro)';


--
-- TOC entry 7027 (class 0 OID 0)
-- Dependencies: 326
-- Name: COLUMN catalogs__compositions.composition_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__compositions.composition_id IS 'Identificador único da composição';


--
-- TOC entry 7028 (class 0 OID 0)
-- Dependencies: 326
-- Name: COLUMN catalogs__compositions.name; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__compositions.name IS 'Nome da composição';


--
-- TOC entry 7029 (class 0 OID 0)
-- Dependencies: 326
-- Name: COLUMN catalogs__compositions.description; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__compositions.description IS 'Descrição da composição';


--
-- TOC entry 7030 (class 0 OID 0)
-- Dependencies: 326
-- Name: COLUMN catalogs__compositions.created_at; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__compositions.created_at IS 'Data de criação do registro';


--
-- TOC entry 7031 (class 0 OID 0)
-- Dependencies: 326
-- Name: COLUMN catalogs__compositions.updated_at; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__compositions.updated_at IS 'Data da última atualização do registro';


--
-- TOC entry 7032 (class 0 OID 0)
-- Dependencies: 326
-- Name: COLUMN catalogs__compositions.audit_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__compositions.audit_id IS 'Identificador único do registro de auditoria';


--
-- TOC entry 7033 (class 0 OID 0)
-- Dependencies: 326
-- Name: COLUMN catalogs__compositions.audit_operation; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__compositions.audit_operation IS 'Tipo de operação realizada (INSERT, UPDATE, DELETE)';


--
-- TOC entry 7034 (class 0 OID 0)
-- Dependencies: 326
-- Name: COLUMN catalogs__compositions.audit_timestamp; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__compositions.audit_timestamp IS 'Data e hora da operação auditada';


--
-- TOC entry 7035 (class 0 OID 0)
-- Dependencies: 326
-- Name: COLUMN catalogs__compositions.audit_user; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__compositions.audit_user IS 'Usuário que executou a operação';


--
-- TOC entry 7036 (class 0 OID 0)
-- Dependencies: 326
-- Name: COLUMN catalogs__compositions.audit_session_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__compositions.audit_session_id IS 'Identificador da sessão da aplicação';


--
-- TOC entry 7037 (class 0 OID 0)
-- Dependencies: 326
-- Name: COLUMN catalogs__compositions.audit_connection_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__compositions.audit_connection_id IS 'Endereço IP da conexão';


--
-- TOC entry 7038 (class 0 OID 0)
-- Dependencies: 326
-- Name: COLUMN catalogs__compositions.audit_partition_date; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__compositions.audit_partition_date IS 'Data para particionamento da tabela de auditoria';


--
-- TOC entry 327 (class 1259 OID 20656)
-- Name: catalogs__compositions_2025_08; Type: TABLE; Schema: audit; Owner: postgres
--

CREATE TABLE audit.catalogs__compositions_2025_08 (
    composition_id uuid NOT NULL,
    name text NOT NULL,
    description text,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone,
    audit_id bigint NOT NULL,
    audit_operation text NOT NULL,
    audit_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    audit_user text DEFAULT CURRENT_USER NOT NULL,
    audit_session_id text DEFAULT current_setting('application_name'::text) NOT NULL,
    audit_connection_id text DEFAULT inet_client_addr() NOT NULL,
    audit_partition_date date DEFAULT CURRENT_DATE NOT NULL
);


ALTER TABLE audit.catalogs__compositions_2025_08 OWNER TO postgres;

--
-- TOC entry 325 (class 1259 OID 20640)
-- Name: catalogs__compositions_audit_id_seq; Type: SEQUENCE; Schema: audit; Owner: postgres
--

ALTER TABLE audit.catalogs__compositions ALTER COLUMN audit_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME audit.catalogs__compositions_audit_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 329 (class 1259 OID 20672)
-- Name: catalogs__fillings; Type: TABLE; Schema: audit; Owner: postgres
--

CREATE TABLE audit.catalogs__fillings (
    filling_id uuid NOT NULL,
    name text NOT NULL,
    description text,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone,
    audit_id bigint NOT NULL,
    audit_operation text NOT NULL,
    audit_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    audit_user text DEFAULT CURRENT_USER NOT NULL,
    audit_session_id text DEFAULT current_setting('application_name'::text) NOT NULL,
    audit_connection_id text DEFAULT inet_client_addr() NOT NULL,
    audit_partition_date date DEFAULT CURRENT_DATE NOT NULL
)
PARTITION BY RANGE (audit_partition_date);


ALTER TABLE audit.catalogs__fillings OWNER TO postgres;

--
-- TOC entry 7039 (class 0 OID 0)
-- Dependencies: 329
-- Name: TABLE catalogs__fillings; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON TABLE audit.catalogs__fillings IS 'AUDITORIA: Recheio principal do produto (ex: Morango, Baunilha)';


--
-- TOC entry 7040 (class 0 OID 0)
-- Dependencies: 329
-- Name: COLUMN catalogs__fillings.filling_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__fillings.filling_id IS 'Identificador único do recheio';


--
-- TOC entry 7041 (class 0 OID 0)
-- Dependencies: 329
-- Name: COLUMN catalogs__fillings.name; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__fillings.name IS 'Nome do recheio';


--
-- TOC entry 7042 (class 0 OID 0)
-- Dependencies: 329
-- Name: COLUMN catalogs__fillings.description; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__fillings.description IS 'Descrição do recheio';


--
-- TOC entry 7043 (class 0 OID 0)
-- Dependencies: 329
-- Name: COLUMN catalogs__fillings.created_at; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__fillings.created_at IS 'Data de criação do registro';


--
-- TOC entry 7044 (class 0 OID 0)
-- Dependencies: 329
-- Name: COLUMN catalogs__fillings.updated_at; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__fillings.updated_at IS 'Data da última atualização do registro';


--
-- TOC entry 7045 (class 0 OID 0)
-- Dependencies: 329
-- Name: COLUMN catalogs__fillings.audit_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__fillings.audit_id IS 'Identificador único do registro de auditoria';


--
-- TOC entry 7046 (class 0 OID 0)
-- Dependencies: 329
-- Name: COLUMN catalogs__fillings.audit_operation; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__fillings.audit_operation IS 'Tipo de operação realizada (INSERT, UPDATE, DELETE)';


--
-- TOC entry 7047 (class 0 OID 0)
-- Dependencies: 329
-- Name: COLUMN catalogs__fillings.audit_timestamp; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__fillings.audit_timestamp IS 'Data e hora da operação auditada';


--
-- TOC entry 7048 (class 0 OID 0)
-- Dependencies: 329
-- Name: COLUMN catalogs__fillings.audit_user; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__fillings.audit_user IS 'Usuário que executou a operação';


--
-- TOC entry 7049 (class 0 OID 0)
-- Dependencies: 329
-- Name: COLUMN catalogs__fillings.audit_session_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__fillings.audit_session_id IS 'Identificador da sessão da aplicação';


--
-- TOC entry 7050 (class 0 OID 0)
-- Dependencies: 329
-- Name: COLUMN catalogs__fillings.audit_connection_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__fillings.audit_connection_id IS 'Endereço IP da conexão';


--
-- TOC entry 7051 (class 0 OID 0)
-- Dependencies: 329
-- Name: COLUMN catalogs__fillings.audit_partition_date; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__fillings.audit_partition_date IS 'Data para particionamento da tabela de auditoria';


--
-- TOC entry 330 (class 1259 OID 20687)
-- Name: catalogs__fillings_2025_08; Type: TABLE; Schema: audit; Owner: postgres
--

CREATE TABLE audit.catalogs__fillings_2025_08 (
    filling_id uuid NOT NULL,
    name text NOT NULL,
    description text,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone,
    audit_id bigint NOT NULL,
    audit_operation text NOT NULL,
    audit_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    audit_user text DEFAULT CURRENT_USER NOT NULL,
    audit_session_id text DEFAULT current_setting('application_name'::text) NOT NULL,
    audit_connection_id text DEFAULT inet_client_addr() NOT NULL,
    audit_partition_date date DEFAULT CURRENT_DATE NOT NULL
);


ALTER TABLE audit.catalogs__fillings_2025_08 OWNER TO postgres;

--
-- TOC entry 328 (class 1259 OID 20671)
-- Name: catalogs__fillings_audit_id_seq; Type: SEQUENCE; Schema: audit; Owner: postgres
--

ALTER TABLE audit.catalogs__fillings ALTER COLUMN audit_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME audit.catalogs__fillings_audit_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 332 (class 1259 OID 20703)
-- Name: catalogs__flavors; Type: TABLE; Schema: audit; Owner: postgres
--

CREATE TABLE audit.catalogs__flavors (
    flavor_id uuid NOT NULL,
    name text NOT NULL,
    description text,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone,
    audit_id bigint NOT NULL,
    audit_operation text NOT NULL,
    audit_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    audit_user text DEFAULT CURRENT_USER NOT NULL,
    audit_session_id text DEFAULT current_setting('application_name'::text) NOT NULL,
    audit_connection_id text DEFAULT inet_client_addr() NOT NULL,
    audit_partition_date date DEFAULT CURRENT_DATE NOT NULL
)
PARTITION BY RANGE (audit_partition_date);


ALTER TABLE audit.catalogs__flavors OWNER TO postgres;

--
-- TOC entry 7052 (class 0 OID 0)
-- Dependencies: 332
-- Name: TABLE catalogs__flavors; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON TABLE audit.catalogs__flavors IS 'AUDITORIA: Perfil de sabor ou tempero (ex: Picante, Galinha Caipira)';


--
-- TOC entry 7053 (class 0 OID 0)
-- Dependencies: 332
-- Name: COLUMN catalogs__flavors.flavor_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__flavors.flavor_id IS 'Identificador único do sabor';


--
-- TOC entry 7054 (class 0 OID 0)
-- Dependencies: 332
-- Name: COLUMN catalogs__flavors.name; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__flavors.name IS 'Nome do sabor';


--
-- TOC entry 7055 (class 0 OID 0)
-- Dependencies: 332
-- Name: COLUMN catalogs__flavors.description; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__flavors.description IS 'Descrição do sabor';


--
-- TOC entry 7056 (class 0 OID 0)
-- Dependencies: 332
-- Name: COLUMN catalogs__flavors.created_at; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__flavors.created_at IS 'Data de criação do registro';


--
-- TOC entry 7057 (class 0 OID 0)
-- Dependencies: 332
-- Name: COLUMN catalogs__flavors.updated_at; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__flavors.updated_at IS 'Data da última atualização do registro';


--
-- TOC entry 7058 (class 0 OID 0)
-- Dependencies: 332
-- Name: COLUMN catalogs__flavors.audit_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__flavors.audit_id IS 'Identificador único do registro de auditoria';


--
-- TOC entry 7059 (class 0 OID 0)
-- Dependencies: 332
-- Name: COLUMN catalogs__flavors.audit_operation; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__flavors.audit_operation IS 'Tipo de operação realizada (INSERT, UPDATE, DELETE)';


--
-- TOC entry 7060 (class 0 OID 0)
-- Dependencies: 332
-- Name: COLUMN catalogs__flavors.audit_timestamp; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__flavors.audit_timestamp IS 'Data e hora da operação auditada';


--
-- TOC entry 7061 (class 0 OID 0)
-- Dependencies: 332
-- Name: COLUMN catalogs__flavors.audit_user; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__flavors.audit_user IS 'Usuário que executou a operação';


--
-- TOC entry 7062 (class 0 OID 0)
-- Dependencies: 332
-- Name: COLUMN catalogs__flavors.audit_session_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__flavors.audit_session_id IS 'Identificador da sessão da aplicação';


--
-- TOC entry 7063 (class 0 OID 0)
-- Dependencies: 332
-- Name: COLUMN catalogs__flavors.audit_connection_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__flavors.audit_connection_id IS 'Endereço IP da conexão';


--
-- TOC entry 7064 (class 0 OID 0)
-- Dependencies: 332
-- Name: COLUMN catalogs__flavors.audit_partition_date; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__flavors.audit_partition_date IS 'Data para particionamento da tabela de auditoria';


--
-- TOC entry 333 (class 1259 OID 20718)
-- Name: catalogs__flavors_2025_08; Type: TABLE; Schema: audit; Owner: postgres
--

CREATE TABLE audit.catalogs__flavors_2025_08 (
    flavor_id uuid NOT NULL,
    name text NOT NULL,
    description text,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone,
    audit_id bigint NOT NULL,
    audit_operation text NOT NULL,
    audit_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    audit_user text DEFAULT CURRENT_USER NOT NULL,
    audit_session_id text DEFAULT current_setting('application_name'::text) NOT NULL,
    audit_connection_id text DEFAULT inet_client_addr() NOT NULL,
    audit_partition_date date DEFAULT CURRENT_DATE NOT NULL
);


ALTER TABLE audit.catalogs__flavors_2025_08 OWNER TO postgres;

--
-- TOC entry 331 (class 1259 OID 20702)
-- Name: catalogs__flavors_audit_id_seq; Type: SEQUENCE; Schema: audit; Owner: postgres
--

ALTER TABLE audit.catalogs__flavors ALTER COLUMN audit_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME audit.catalogs__flavors_audit_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 335 (class 1259 OID 20734)
-- Name: catalogs__formats; Type: TABLE; Schema: audit; Owner: postgres
--

CREATE TABLE audit.catalogs__formats (
    format_id uuid NOT NULL,
    name text NOT NULL,
    description text,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone,
    audit_id bigint NOT NULL,
    audit_operation text NOT NULL,
    audit_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    audit_user text DEFAULT CURRENT_USER NOT NULL,
    audit_session_id text DEFAULT current_setting('application_name'::text) NOT NULL,
    audit_connection_id text DEFAULT inet_client_addr() NOT NULL,
    audit_partition_date date DEFAULT CURRENT_DATE NOT NULL
)
PARTITION BY RANGE (audit_partition_date);


ALTER TABLE audit.catalogs__formats OWNER TO postgres;

--
-- TOC entry 7065 (class 0 OID 0)
-- Dependencies: 335
-- Name: TABLE catalogs__formats; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON TABLE audit.catalogs__formats IS 'AUDITORIA: Formato físico de apresentação (ex: Fatiada, Bolinha)';


--
-- TOC entry 7066 (class 0 OID 0)
-- Dependencies: 335
-- Name: COLUMN catalogs__formats.format_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__formats.format_id IS 'Identificador único do formato';


--
-- TOC entry 7067 (class 0 OID 0)
-- Dependencies: 335
-- Name: COLUMN catalogs__formats.name; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__formats.name IS 'Nome do formato';


--
-- TOC entry 7068 (class 0 OID 0)
-- Dependencies: 335
-- Name: COLUMN catalogs__formats.description; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__formats.description IS 'Descrição do formato';


--
-- TOC entry 7069 (class 0 OID 0)
-- Dependencies: 335
-- Name: COLUMN catalogs__formats.created_at; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__formats.created_at IS 'Data de criação do registro';


--
-- TOC entry 7070 (class 0 OID 0)
-- Dependencies: 335
-- Name: COLUMN catalogs__formats.updated_at; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__formats.updated_at IS 'Data da última atualização do registro';


--
-- TOC entry 7071 (class 0 OID 0)
-- Dependencies: 335
-- Name: COLUMN catalogs__formats.audit_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__formats.audit_id IS 'Identificador único do registro de auditoria';


--
-- TOC entry 7072 (class 0 OID 0)
-- Dependencies: 335
-- Name: COLUMN catalogs__formats.audit_operation; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__formats.audit_operation IS 'Tipo de operação realizada (INSERT, UPDATE, DELETE)';


--
-- TOC entry 7073 (class 0 OID 0)
-- Dependencies: 335
-- Name: COLUMN catalogs__formats.audit_timestamp; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__formats.audit_timestamp IS 'Data e hora da operação auditada';


--
-- TOC entry 7074 (class 0 OID 0)
-- Dependencies: 335
-- Name: COLUMN catalogs__formats.audit_user; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__formats.audit_user IS 'Usuário que executou a operação';


--
-- TOC entry 7075 (class 0 OID 0)
-- Dependencies: 335
-- Name: COLUMN catalogs__formats.audit_session_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__formats.audit_session_id IS 'Identificador da sessão da aplicação';


--
-- TOC entry 7076 (class 0 OID 0)
-- Dependencies: 335
-- Name: COLUMN catalogs__formats.audit_connection_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__formats.audit_connection_id IS 'Endereço IP da conexão';


--
-- TOC entry 7077 (class 0 OID 0)
-- Dependencies: 335
-- Name: COLUMN catalogs__formats.audit_partition_date; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__formats.audit_partition_date IS 'Data para particionamento da tabela de auditoria';


--
-- TOC entry 336 (class 1259 OID 20749)
-- Name: catalogs__formats_2025_08; Type: TABLE; Schema: audit; Owner: postgres
--

CREATE TABLE audit.catalogs__formats_2025_08 (
    format_id uuid NOT NULL,
    name text NOT NULL,
    description text,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone,
    audit_id bigint NOT NULL,
    audit_operation text NOT NULL,
    audit_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    audit_user text DEFAULT CURRENT_USER NOT NULL,
    audit_session_id text DEFAULT current_setting('application_name'::text) NOT NULL,
    audit_connection_id text DEFAULT inet_client_addr() NOT NULL,
    audit_partition_date date DEFAULT CURRENT_DATE NOT NULL
);


ALTER TABLE audit.catalogs__formats_2025_08 OWNER TO postgres;

--
-- TOC entry 334 (class 1259 OID 20733)
-- Name: catalogs__formats_audit_id_seq; Type: SEQUENCE; Schema: audit; Owner: postgres
--

ALTER TABLE audit.catalogs__formats ALTER COLUMN audit_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME audit.catalogs__formats_audit_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 338 (class 1259 OID 20765)
-- Name: catalogs__items; Type: TABLE; Schema: audit; Owner: postgres
--

CREATE TABLE audit.catalogs__items (
    item_id uuid NOT NULL,
    subcategory_id uuid NOT NULL,
    name text NOT NULL,
    description text,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone,
    audit_id bigint NOT NULL,
    audit_operation text NOT NULL,
    audit_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    audit_user text DEFAULT CURRENT_USER NOT NULL,
    audit_session_id text DEFAULT current_setting('application_name'::text) NOT NULL,
    audit_connection_id text DEFAULT inet_client_addr() NOT NULL,
    audit_partition_date date DEFAULT CURRENT_DATE NOT NULL
)
PARTITION BY RANGE (audit_partition_date);


ALTER TABLE audit.catalogs__items OWNER TO postgres;

--
-- TOC entry 7078 (class 0 OID 0)
-- Dependencies: 338
-- Name: TABLE catalogs__items; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON TABLE audit.catalogs__items IS 'AUDITORIA: Itens genéricos que representam o núcleo de um produto';


--
-- TOC entry 7079 (class 0 OID 0)
-- Dependencies: 338
-- Name: COLUMN catalogs__items.item_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__items.item_id IS 'Identificador único do item';


--
-- TOC entry 7080 (class 0 OID 0)
-- Dependencies: 338
-- Name: COLUMN catalogs__items.subcategory_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__items.subcategory_id IS 'Subcategoria à qual este item pertence';


--
-- TOC entry 7081 (class 0 OID 0)
-- Dependencies: 338
-- Name: COLUMN catalogs__items.name; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__items.name IS 'Nome genérico do item';


--
-- TOC entry 7082 (class 0 OID 0)
-- Dependencies: 338
-- Name: COLUMN catalogs__items.description; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__items.description IS 'Descrição do item';


--
-- TOC entry 7083 (class 0 OID 0)
-- Dependencies: 338
-- Name: COLUMN catalogs__items.created_at; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__items.created_at IS 'Data de criação do registro';


--
-- TOC entry 7084 (class 0 OID 0)
-- Dependencies: 338
-- Name: COLUMN catalogs__items.updated_at; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__items.updated_at IS 'Data da última atualização do registro';


--
-- TOC entry 7085 (class 0 OID 0)
-- Dependencies: 338
-- Name: COLUMN catalogs__items.audit_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__items.audit_id IS 'Identificador único do registro de auditoria';


--
-- TOC entry 7086 (class 0 OID 0)
-- Dependencies: 338
-- Name: COLUMN catalogs__items.audit_operation; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__items.audit_operation IS 'Tipo de operação realizada (INSERT, UPDATE, DELETE)';


--
-- TOC entry 7087 (class 0 OID 0)
-- Dependencies: 338
-- Name: COLUMN catalogs__items.audit_timestamp; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__items.audit_timestamp IS 'Data e hora da operação auditada';


--
-- TOC entry 7088 (class 0 OID 0)
-- Dependencies: 338
-- Name: COLUMN catalogs__items.audit_user; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__items.audit_user IS 'Usuário que executou a operação';


--
-- TOC entry 7089 (class 0 OID 0)
-- Dependencies: 338
-- Name: COLUMN catalogs__items.audit_session_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__items.audit_session_id IS 'Identificador da sessão da aplicação';


--
-- TOC entry 7090 (class 0 OID 0)
-- Dependencies: 338
-- Name: COLUMN catalogs__items.audit_connection_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__items.audit_connection_id IS 'Endereço IP da conexão';


--
-- TOC entry 7091 (class 0 OID 0)
-- Dependencies: 338
-- Name: COLUMN catalogs__items.audit_partition_date; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__items.audit_partition_date IS 'Data para particionamento da tabela de auditoria';


--
-- TOC entry 339 (class 1259 OID 20781)
-- Name: catalogs__items_2025_08; Type: TABLE; Schema: audit; Owner: postgres
--

CREATE TABLE audit.catalogs__items_2025_08 (
    item_id uuid NOT NULL,
    subcategory_id uuid NOT NULL,
    name text NOT NULL,
    description text,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone,
    audit_id bigint NOT NULL,
    audit_operation text NOT NULL,
    audit_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    audit_user text DEFAULT CURRENT_USER NOT NULL,
    audit_session_id text DEFAULT current_setting('application_name'::text) NOT NULL,
    audit_connection_id text DEFAULT inet_client_addr() NOT NULL,
    audit_partition_date date DEFAULT CURRENT_DATE NOT NULL
);


ALTER TABLE audit.catalogs__items_2025_08 OWNER TO postgres;

--
-- TOC entry 337 (class 1259 OID 20764)
-- Name: catalogs__items_audit_id_seq; Type: SEQUENCE; Schema: audit; Owner: postgres
--

ALTER TABLE audit.catalogs__items ALTER COLUMN audit_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME audit.catalogs__items_audit_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 341 (class 1259 OID 20798)
-- Name: catalogs__nutritional_variants; Type: TABLE; Schema: audit; Owner: postgres
--

CREATE TABLE audit.catalogs__nutritional_variants (
    nutritional_variant_id uuid NOT NULL,
    name text NOT NULL,
    description text,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone,
    audit_id bigint NOT NULL,
    audit_operation text NOT NULL,
    audit_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    audit_user text DEFAULT CURRENT_USER NOT NULL,
    audit_session_id text DEFAULT current_setting('application_name'::text) NOT NULL,
    audit_connection_id text DEFAULT inet_client_addr() NOT NULL,
    audit_partition_date date DEFAULT CURRENT_DATE NOT NULL
)
PARTITION BY RANGE (audit_partition_date);


ALTER TABLE audit.catalogs__nutritional_variants OWNER TO postgres;

--
-- TOC entry 7092 (class 0 OID 0)
-- Dependencies: 341
-- Name: TABLE catalogs__nutritional_variants; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON TABLE audit.catalogs__nutritional_variants IS 'AUDITORIA: Variações nutricionais (ex: Light, Zero, Sem Lactose)';


--
-- TOC entry 7093 (class 0 OID 0)
-- Dependencies: 341
-- Name: COLUMN catalogs__nutritional_variants.nutritional_variant_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__nutritional_variants.nutritional_variant_id IS 'Identificador único da variação';


--
-- TOC entry 7094 (class 0 OID 0)
-- Dependencies: 341
-- Name: COLUMN catalogs__nutritional_variants.name; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__nutritional_variants.name IS 'Nome da variação nutricional';


--
-- TOC entry 7095 (class 0 OID 0)
-- Dependencies: 341
-- Name: COLUMN catalogs__nutritional_variants.description; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__nutritional_variants.description IS 'Descrição da variação nutricional';


--
-- TOC entry 7096 (class 0 OID 0)
-- Dependencies: 341
-- Name: COLUMN catalogs__nutritional_variants.created_at; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__nutritional_variants.created_at IS 'Data de criação do registro';


--
-- TOC entry 7097 (class 0 OID 0)
-- Dependencies: 341
-- Name: COLUMN catalogs__nutritional_variants.updated_at; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__nutritional_variants.updated_at IS 'Data da última atualização do registro';


--
-- TOC entry 7098 (class 0 OID 0)
-- Dependencies: 341
-- Name: COLUMN catalogs__nutritional_variants.audit_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__nutritional_variants.audit_id IS 'Identificador único do registro de auditoria';


--
-- TOC entry 7099 (class 0 OID 0)
-- Dependencies: 341
-- Name: COLUMN catalogs__nutritional_variants.audit_operation; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__nutritional_variants.audit_operation IS 'Tipo de operação realizada (INSERT, UPDATE, DELETE)';


--
-- TOC entry 7100 (class 0 OID 0)
-- Dependencies: 341
-- Name: COLUMN catalogs__nutritional_variants.audit_timestamp; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__nutritional_variants.audit_timestamp IS 'Data e hora da operação auditada';


--
-- TOC entry 7101 (class 0 OID 0)
-- Dependencies: 341
-- Name: COLUMN catalogs__nutritional_variants.audit_user; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__nutritional_variants.audit_user IS 'Usuário que executou a operação';


--
-- TOC entry 7102 (class 0 OID 0)
-- Dependencies: 341
-- Name: COLUMN catalogs__nutritional_variants.audit_session_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__nutritional_variants.audit_session_id IS 'Identificador da sessão da aplicação';


--
-- TOC entry 7103 (class 0 OID 0)
-- Dependencies: 341
-- Name: COLUMN catalogs__nutritional_variants.audit_connection_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__nutritional_variants.audit_connection_id IS 'Endereço IP da conexão';


--
-- TOC entry 7104 (class 0 OID 0)
-- Dependencies: 341
-- Name: COLUMN catalogs__nutritional_variants.audit_partition_date; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__nutritional_variants.audit_partition_date IS 'Data para particionamento da tabela de auditoria';


--
-- TOC entry 342 (class 1259 OID 20813)
-- Name: catalogs__nutritional_variants_2025_08; Type: TABLE; Schema: audit; Owner: postgres
--

CREATE TABLE audit.catalogs__nutritional_variants_2025_08 (
    nutritional_variant_id uuid NOT NULL,
    name text NOT NULL,
    description text,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone,
    audit_id bigint NOT NULL,
    audit_operation text NOT NULL,
    audit_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    audit_user text DEFAULT CURRENT_USER NOT NULL,
    audit_session_id text DEFAULT current_setting('application_name'::text) NOT NULL,
    audit_connection_id text DEFAULT inet_client_addr() NOT NULL,
    audit_partition_date date DEFAULT CURRENT_DATE NOT NULL
);


ALTER TABLE audit.catalogs__nutritional_variants_2025_08 OWNER TO postgres;

--
-- TOC entry 340 (class 1259 OID 20797)
-- Name: catalogs__nutritional_variants_audit_id_seq; Type: SEQUENCE; Schema: audit; Owner: postgres
--

ALTER TABLE audit.catalogs__nutritional_variants ALTER COLUMN audit_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME audit.catalogs__nutritional_variants_audit_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 344 (class 1259 OID 20829)
-- Name: catalogs__offers; Type: TABLE; Schema: audit; Owner: postgres
--

CREATE TABLE audit.catalogs__offers (
    offer_id uuid NOT NULL,
    product_id uuid NOT NULL,
    supplier_id uuid NOT NULL,
    price numeric NOT NULL,
    available_from date NOT NULL,
    available_until date,
    is_active boolean NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone,
    audit_id bigint NOT NULL,
    audit_operation text NOT NULL,
    audit_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    audit_user text DEFAULT CURRENT_USER NOT NULL,
    audit_session_id text DEFAULT current_setting('application_name'::text) NOT NULL,
    audit_connection_id text DEFAULT inet_client_addr() NOT NULL,
    audit_partition_date date DEFAULT CURRENT_DATE NOT NULL
)
PARTITION BY RANGE (audit_partition_date);


ALTER TABLE audit.catalogs__offers OWNER TO postgres;

--
-- TOC entry 7105 (class 0 OID 0)
-- Dependencies: 344
-- Name: TABLE catalogs__offers; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON TABLE audit.catalogs__offers IS 'AUDITORIA: Oferta de um produto específico por um fornecedor com condições comerciais';


--
-- TOC entry 7106 (class 0 OID 0)
-- Dependencies: 344
-- Name: COLUMN catalogs__offers.offer_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__offers.offer_id IS 'Identificador único da oferta';


--
-- TOC entry 7107 (class 0 OID 0)
-- Dependencies: 344
-- Name: COLUMN catalogs__offers.product_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__offers.product_id IS 'Produto ofertado';


--
-- TOC entry 7108 (class 0 OID 0)
-- Dependencies: 344
-- Name: COLUMN catalogs__offers.supplier_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__offers.supplier_id IS 'Fornecedor que oferta o produto';


--
-- TOC entry 7109 (class 0 OID 0)
-- Dependencies: 344
-- Name: COLUMN catalogs__offers.price; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__offers.price IS 'Preço da oferta';


--
-- TOC entry 7110 (class 0 OID 0)
-- Dependencies: 344
-- Name: COLUMN catalogs__offers.available_from; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__offers.available_from IS 'Data de início da disponibilidade da oferta';


--
-- TOC entry 7111 (class 0 OID 0)
-- Dependencies: 344
-- Name: COLUMN catalogs__offers.available_until; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__offers.available_until IS 'Data de término da disponibilidade da oferta (opcional)';


--
-- TOC entry 7112 (class 0 OID 0)
-- Dependencies: 344
-- Name: COLUMN catalogs__offers.is_active; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__offers.is_active IS 'Indica se a oferta está ativa';


--
-- TOC entry 7113 (class 0 OID 0)
-- Dependencies: 344
-- Name: COLUMN catalogs__offers.created_at; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__offers.created_at IS 'Data de criação do registro';


--
-- TOC entry 7114 (class 0 OID 0)
-- Dependencies: 344
-- Name: COLUMN catalogs__offers.updated_at; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__offers.updated_at IS 'Data da última atualização do registro';


--
-- TOC entry 7115 (class 0 OID 0)
-- Dependencies: 344
-- Name: COLUMN catalogs__offers.audit_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__offers.audit_id IS 'Identificador único do registro de auditoria';


--
-- TOC entry 7116 (class 0 OID 0)
-- Dependencies: 344
-- Name: COLUMN catalogs__offers.audit_operation; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__offers.audit_operation IS 'Tipo de operação realizada (INSERT, UPDATE, DELETE)';


--
-- TOC entry 7117 (class 0 OID 0)
-- Dependencies: 344
-- Name: COLUMN catalogs__offers.audit_timestamp; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__offers.audit_timestamp IS 'Data e hora da operação auditada';


--
-- TOC entry 7118 (class 0 OID 0)
-- Dependencies: 344
-- Name: COLUMN catalogs__offers.audit_user; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__offers.audit_user IS 'Usuário que executou a operação';


--
-- TOC entry 7119 (class 0 OID 0)
-- Dependencies: 344
-- Name: COLUMN catalogs__offers.audit_session_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__offers.audit_session_id IS 'Identificador da sessão da aplicação';


--
-- TOC entry 7120 (class 0 OID 0)
-- Dependencies: 344
-- Name: COLUMN catalogs__offers.audit_connection_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__offers.audit_connection_id IS 'Endereço IP da conexão';


--
-- TOC entry 7121 (class 0 OID 0)
-- Dependencies: 344
-- Name: COLUMN catalogs__offers.audit_partition_date; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__offers.audit_partition_date IS 'Data para particionamento da tabela de auditoria';


--
-- TOC entry 345 (class 1259 OID 20846)
-- Name: catalogs__offers_2025_08; Type: TABLE; Schema: audit; Owner: postgres
--

CREATE TABLE audit.catalogs__offers_2025_08 (
    offer_id uuid NOT NULL,
    product_id uuid NOT NULL,
    supplier_id uuid NOT NULL,
    price numeric NOT NULL,
    available_from date NOT NULL,
    available_until date,
    is_active boolean NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone,
    audit_id bigint NOT NULL,
    audit_operation text NOT NULL,
    audit_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    audit_user text DEFAULT CURRENT_USER NOT NULL,
    audit_session_id text DEFAULT current_setting('application_name'::text) NOT NULL,
    audit_connection_id text DEFAULT inet_client_addr() NOT NULL,
    audit_partition_date date DEFAULT CURRENT_DATE NOT NULL
);


ALTER TABLE audit.catalogs__offers_2025_08 OWNER TO postgres;

--
-- TOC entry 343 (class 1259 OID 20828)
-- Name: catalogs__offers_audit_id_seq; Type: SEQUENCE; Schema: audit; Owner: postgres
--

ALTER TABLE audit.catalogs__offers ALTER COLUMN audit_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME audit.catalogs__offers_audit_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 347 (class 1259 OID 20864)
-- Name: catalogs__packagings; Type: TABLE; Schema: audit; Owner: postgres
--

CREATE TABLE audit.catalogs__packagings (
    packaging_id uuid NOT NULL,
    name text NOT NULL,
    description text,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone,
    audit_id bigint NOT NULL,
    audit_operation text NOT NULL,
    audit_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    audit_user text DEFAULT CURRENT_USER NOT NULL,
    audit_session_id text DEFAULT current_setting('application_name'::text) NOT NULL,
    audit_connection_id text DEFAULT inet_client_addr() NOT NULL,
    audit_partition_date date DEFAULT CURRENT_DATE NOT NULL
)
PARTITION BY RANGE (audit_partition_date);


ALTER TABLE audit.catalogs__packagings OWNER TO postgres;

--
-- TOC entry 7122 (class 0 OID 0)
-- Dependencies: 347
-- Name: TABLE catalogs__packagings; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON TABLE audit.catalogs__packagings IS 'AUDITORIA: Tipo de embalagem do produto (ex: Caixa, Lata, Pacote)';


--
-- TOC entry 7123 (class 0 OID 0)
-- Dependencies: 347
-- Name: COLUMN catalogs__packagings.packaging_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__packagings.packaging_id IS 'Identificador único da embalagem';


--
-- TOC entry 7124 (class 0 OID 0)
-- Dependencies: 347
-- Name: COLUMN catalogs__packagings.name; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__packagings.name IS 'Nome do tipo de embalagem';


--
-- TOC entry 7125 (class 0 OID 0)
-- Dependencies: 347
-- Name: COLUMN catalogs__packagings.description; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__packagings.description IS 'Descrição da embalagem';


--
-- TOC entry 7126 (class 0 OID 0)
-- Dependencies: 347
-- Name: COLUMN catalogs__packagings.created_at; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__packagings.created_at IS 'Data de criação do registro';


--
-- TOC entry 7127 (class 0 OID 0)
-- Dependencies: 347
-- Name: COLUMN catalogs__packagings.updated_at; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__packagings.updated_at IS 'Data da última atualização do registro';


--
-- TOC entry 7128 (class 0 OID 0)
-- Dependencies: 347
-- Name: COLUMN catalogs__packagings.audit_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__packagings.audit_id IS 'Identificador único do registro de auditoria';


--
-- TOC entry 7129 (class 0 OID 0)
-- Dependencies: 347
-- Name: COLUMN catalogs__packagings.audit_operation; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__packagings.audit_operation IS 'Tipo de operação realizada (INSERT, UPDATE, DELETE)';


--
-- TOC entry 7130 (class 0 OID 0)
-- Dependencies: 347
-- Name: COLUMN catalogs__packagings.audit_timestamp; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__packagings.audit_timestamp IS 'Data e hora da operação auditada';


--
-- TOC entry 7131 (class 0 OID 0)
-- Dependencies: 347
-- Name: COLUMN catalogs__packagings.audit_user; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__packagings.audit_user IS 'Usuário que executou a operação';


--
-- TOC entry 7132 (class 0 OID 0)
-- Dependencies: 347
-- Name: COLUMN catalogs__packagings.audit_session_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__packagings.audit_session_id IS 'Identificador da sessão da aplicação';


--
-- TOC entry 7133 (class 0 OID 0)
-- Dependencies: 347
-- Name: COLUMN catalogs__packagings.audit_connection_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__packagings.audit_connection_id IS 'Endereço IP da conexão';


--
-- TOC entry 7134 (class 0 OID 0)
-- Dependencies: 347
-- Name: COLUMN catalogs__packagings.audit_partition_date; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__packagings.audit_partition_date IS 'Data para particionamento da tabela de auditoria';


--
-- TOC entry 348 (class 1259 OID 20879)
-- Name: catalogs__packagings_2025_08; Type: TABLE; Schema: audit; Owner: postgres
--

CREATE TABLE audit.catalogs__packagings_2025_08 (
    packaging_id uuid NOT NULL,
    name text NOT NULL,
    description text,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone,
    audit_id bigint NOT NULL,
    audit_operation text NOT NULL,
    audit_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    audit_user text DEFAULT CURRENT_USER NOT NULL,
    audit_session_id text DEFAULT current_setting('application_name'::text) NOT NULL,
    audit_connection_id text DEFAULT inet_client_addr() NOT NULL,
    audit_partition_date date DEFAULT CURRENT_DATE NOT NULL
);


ALTER TABLE audit.catalogs__packagings_2025_08 OWNER TO postgres;

--
-- TOC entry 346 (class 1259 OID 20863)
-- Name: catalogs__packagings_audit_id_seq; Type: SEQUENCE; Schema: audit; Owner: postgres
--

ALTER TABLE audit.catalogs__packagings ALTER COLUMN audit_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME audit.catalogs__packagings_audit_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 350 (class 1259 OID 20895)
-- Name: catalogs__products; Type: TABLE; Schema: audit; Owner: postgres
--

CREATE TABLE audit.catalogs__products (
    product_id uuid NOT NULL,
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
    visibility text NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone,
    audit_id bigint NOT NULL,
    audit_operation text NOT NULL,
    audit_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    audit_user text DEFAULT CURRENT_USER NOT NULL,
    audit_session_id text DEFAULT current_setting('application_name'::text) NOT NULL,
    audit_connection_id text DEFAULT inet_client_addr() NOT NULL,
    audit_partition_date date DEFAULT CURRENT_DATE NOT NULL
)
PARTITION BY RANGE (audit_partition_date);


ALTER TABLE audit.catalogs__products OWNER TO postgres;

--
-- TOC entry 7135 (class 0 OID 0)
-- Dependencies: 350
-- Name: TABLE catalogs__products; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON TABLE audit.catalogs__products IS 'AUDITORIA: Produto padronizado resultante da combinação de um item com suas variações e atributos dimensionais';


--
-- TOC entry 7136 (class 0 OID 0)
-- Dependencies: 350
-- Name: COLUMN catalogs__products.product_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__products.product_id IS 'Identificador único do produto';


--
-- TOC entry 7137 (class 0 OID 0)
-- Dependencies: 350
-- Name: COLUMN catalogs__products.item_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__products.item_id IS 'FK para o item base deste produto';


--
-- TOC entry 7138 (class 0 OID 0)
-- Dependencies: 350
-- Name: COLUMN catalogs__products.composition_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__products.composition_id IS 'FK para a composição (matéria-prima)';


--
-- TOC entry 7139 (class 0 OID 0)
-- Dependencies: 350
-- Name: COLUMN catalogs__products.variant_type_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__products.variant_type_id IS 'FK para o tipo de variação';


--
-- TOC entry 7140 (class 0 OID 0)
-- Dependencies: 350
-- Name: COLUMN catalogs__products.format_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__products.format_id IS 'FK para o formato físico';


--
-- TOC entry 7141 (class 0 OID 0)
-- Dependencies: 350
-- Name: COLUMN catalogs__products.flavor_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__products.flavor_id IS 'FK para o sabor';


--
-- TOC entry 7142 (class 0 OID 0)
-- Dependencies: 350
-- Name: COLUMN catalogs__products.filling_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__products.filling_id IS 'FK para o recheio';


--
-- TOC entry 7143 (class 0 OID 0)
-- Dependencies: 350
-- Name: COLUMN catalogs__products.nutritional_variant_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__products.nutritional_variant_id IS 'FK para a variação nutricional';


--
-- TOC entry 7144 (class 0 OID 0)
-- Dependencies: 350
-- Name: COLUMN catalogs__products.brand_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__products.brand_id IS 'FK para a marca';


--
-- TOC entry 7145 (class 0 OID 0)
-- Dependencies: 350
-- Name: COLUMN catalogs__products.packaging_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__products.packaging_id IS 'FK para a embalagem';


--
-- TOC entry 7146 (class 0 OID 0)
-- Dependencies: 350
-- Name: COLUMN catalogs__products.quantity_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__products.quantity_id IS 'FK para a quantidade';


--
-- TOC entry 7147 (class 0 OID 0)
-- Dependencies: 350
-- Name: COLUMN catalogs__products.visibility; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__products.visibility IS 'Define se o produto é público ou privado';


--
-- TOC entry 7148 (class 0 OID 0)
-- Dependencies: 350
-- Name: COLUMN catalogs__products.created_at; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__products.created_at IS 'Data de criação do registro';


--
-- TOC entry 7149 (class 0 OID 0)
-- Dependencies: 350
-- Name: COLUMN catalogs__products.updated_at; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__products.updated_at IS 'Data da última atualização do registro';


--
-- TOC entry 7150 (class 0 OID 0)
-- Dependencies: 350
-- Name: COLUMN catalogs__products.audit_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__products.audit_id IS 'Identificador único do registro de auditoria';


--
-- TOC entry 7151 (class 0 OID 0)
-- Dependencies: 350
-- Name: COLUMN catalogs__products.audit_operation; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__products.audit_operation IS 'Tipo de operação realizada (INSERT, UPDATE, DELETE)';


--
-- TOC entry 7152 (class 0 OID 0)
-- Dependencies: 350
-- Name: COLUMN catalogs__products.audit_timestamp; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__products.audit_timestamp IS 'Data e hora da operação auditada';


--
-- TOC entry 7153 (class 0 OID 0)
-- Dependencies: 350
-- Name: COLUMN catalogs__products.audit_user; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__products.audit_user IS 'Usuário que executou a operação';


--
-- TOC entry 7154 (class 0 OID 0)
-- Dependencies: 350
-- Name: COLUMN catalogs__products.audit_session_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__products.audit_session_id IS 'Identificador da sessão da aplicação';


--
-- TOC entry 7155 (class 0 OID 0)
-- Dependencies: 350
-- Name: COLUMN catalogs__products.audit_connection_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__products.audit_connection_id IS 'Endereço IP da conexão';


--
-- TOC entry 7156 (class 0 OID 0)
-- Dependencies: 350
-- Name: COLUMN catalogs__products.audit_partition_date; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__products.audit_partition_date IS 'Data para particionamento da tabela de auditoria';


--
-- TOC entry 351 (class 1259 OID 20920)
-- Name: catalogs__products_2025_08; Type: TABLE; Schema: audit; Owner: postgres
--

CREATE TABLE audit.catalogs__products_2025_08 (
    product_id uuid NOT NULL,
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
    visibility text NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone,
    audit_id bigint NOT NULL,
    audit_operation text NOT NULL,
    audit_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    audit_user text DEFAULT CURRENT_USER NOT NULL,
    audit_session_id text DEFAULT current_setting('application_name'::text) NOT NULL,
    audit_connection_id text DEFAULT inet_client_addr() NOT NULL,
    audit_partition_date date DEFAULT CURRENT_DATE NOT NULL
);


ALTER TABLE audit.catalogs__products_2025_08 OWNER TO postgres;

--
-- TOC entry 349 (class 1259 OID 20894)
-- Name: catalogs__products_audit_id_seq; Type: SEQUENCE; Schema: audit; Owner: postgres
--

ALTER TABLE audit.catalogs__products ALTER COLUMN audit_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME audit.catalogs__products_audit_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 353 (class 1259 OID 20946)
-- Name: catalogs__quantities; Type: TABLE; Schema: audit; Owner: postgres
--

CREATE TABLE audit.catalogs__quantities (
    quantity_id uuid NOT NULL,
    unit text NOT NULL,
    value numeric NOT NULL,
    display_name text NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone,
    audit_id bigint NOT NULL,
    audit_operation text NOT NULL,
    audit_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    audit_user text DEFAULT CURRENT_USER NOT NULL,
    audit_session_id text DEFAULT current_setting('application_name'::text) NOT NULL,
    audit_connection_id text DEFAULT inet_client_addr() NOT NULL,
    audit_partition_date date DEFAULT CURRENT_DATE NOT NULL
)
PARTITION BY RANGE (audit_partition_date);


ALTER TABLE audit.catalogs__quantities OWNER TO postgres;

--
-- TOC entry 7157 (class 0 OID 0)
-- Dependencies: 353
-- Name: TABLE catalogs__quantities; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON TABLE audit.catalogs__quantities IS 'AUDITORIA: Quantidade ou medida do produto (ex: 500g, 12 unidades)';


--
-- TOC entry 7158 (class 0 OID 0)
-- Dependencies: 353
-- Name: COLUMN catalogs__quantities.quantity_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__quantities.quantity_id IS 'Identificador único da quantidade';


--
-- TOC entry 7159 (class 0 OID 0)
-- Dependencies: 353
-- Name: COLUMN catalogs__quantities.unit; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__quantities.unit IS 'Unidade de medida (ex: g, ml, un)';


--
-- TOC entry 7160 (class 0 OID 0)
-- Dependencies: 353
-- Name: COLUMN catalogs__quantities.value; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__quantities.value IS 'Valor numérico da unidade';


--
-- TOC entry 7161 (class 0 OID 0)
-- Dependencies: 353
-- Name: COLUMN catalogs__quantities.display_name; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__quantities.display_name IS 'Nome formatado para exibição';


--
-- TOC entry 7162 (class 0 OID 0)
-- Dependencies: 353
-- Name: COLUMN catalogs__quantities.created_at; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__quantities.created_at IS 'Data de criação do registro';


--
-- TOC entry 7163 (class 0 OID 0)
-- Dependencies: 353
-- Name: COLUMN catalogs__quantities.updated_at; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__quantities.updated_at IS 'Data da última atualização do registro';


--
-- TOC entry 7164 (class 0 OID 0)
-- Dependencies: 353
-- Name: COLUMN catalogs__quantities.audit_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__quantities.audit_id IS 'Identificador único do registro de auditoria';


--
-- TOC entry 7165 (class 0 OID 0)
-- Dependencies: 353
-- Name: COLUMN catalogs__quantities.audit_operation; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__quantities.audit_operation IS 'Tipo de operação realizada (INSERT, UPDATE, DELETE)';


--
-- TOC entry 7166 (class 0 OID 0)
-- Dependencies: 353
-- Name: COLUMN catalogs__quantities.audit_timestamp; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__quantities.audit_timestamp IS 'Data e hora da operação auditada';


--
-- TOC entry 7167 (class 0 OID 0)
-- Dependencies: 353
-- Name: COLUMN catalogs__quantities.audit_user; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__quantities.audit_user IS 'Usuário que executou a operação';


--
-- TOC entry 7168 (class 0 OID 0)
-- Dependencies: 353
-- Name: COLUMN catalogs__quantities.audit_session_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__quantities.audit_session_id IS 'Identificador da sessão da aplicação';


--
-- TOC entry 7169 (class 0 OID 0)
-- Dependencies: 353
-- Name: COLUMN catalogs__quantities.audit_connection_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__quantities.audit_connection_id IS 'Endereço IP da conexão';


--
-- TOC entry 7170 (class 0 OID 0)
-- Dependencies: 353
-- Name: COLUMN catalogs__quantities.audit_partition_date; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__quantities.audit_partition_date IS 'Data para particionamento da tabela de auditoria';


--
-- TOC entry 354 (class 1259 OID 20961)
-- Name: catalogs__quantities_2025_08; Type: TABLE; Schema: audit; Owner: postgres
--

CREATE TABLE audit.catalogs__quantities_2025_08 (
    quantity_id uuid NOT NULL,
    unit text NOT NULL,
    value numeric NOT NULL,
    display_name text NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone,
    audit_id bigint NOT NULL,
    audit_operation text NOT NULL,
    audit_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    audit_user text DEFAULT CURRENT_USER NOT NULL,
    audit_session_id text DEFAULT current_setting('application_name'::text) NOT NULL,
    audit_connection_id text DEFAULT inet_client_addr() NOT NULL,
    audit_partition_date date DEFAULT CURRENT_DATE NOT NULL
);


ALTER TABLE audit.catalogs__quantities_2025_08 OWNER TO postgres;

--
-- TOC entry 352 (class 1259 OID 20945)
-- Name: catalogs__quantities_audit_id_seq; Type: SEQUENCE; Schema: audit; Owner: postgres
--

ALTER TABLE audit.catalogs__quantities ALTER COLUMN audit_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME audit.catalogs__quantities_audit_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 356 (class 1259 OID 20977)
-- Name: catalogs__subcategories; Type: TABLE; Schema: audit; Owner: postgres
--

CREATE TABLE audit.catalogs__subcategories (
    subcategory_id uuid NOT NULL,
    category_id uuid NOT NULL,
    name text NOT NULL,
    description text,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone,
    audit_id bigint NOT NULL,
    audit_operation text NOT NULL,
    audit_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    audit_user text DEFAULT CURRENT_USER NOT NULL,
    audit_session_id text DEFAULT current_setting('application_name'::text) NOT NULL,
    audit_connection_id text DEFAULT inet_client_addr() NOT NULL,
    audit_partition_date date DEFAULT CURRENT_DATE NOT NULL
)
PARTITION BY RANGE (audit_partition_date);


ALTER TABLE audit.catalogs__subcategories OWNER TO postgres;

--
-- TOC entry 7171 (class 0 OID 0)
-- Dependencies: 356
-- Name: TABLE catalogs__subcategories; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON TABLE audit.catalogs__subcategories IS 'AUDITORIA: Subcategorias específicas dentro de uma categoria principal';


--
-- TOC entry 7172 (class 0 OID 0)
-- Dependencies: 356
-- Name: COLUMN catalogs__subcategories.subcategory_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__subcategories.subcategory_id IS 'Identificador único da subcategoria';


--
-- TOC entry 7173 (class 0 OID 0)
-- Dependencies: 356
-- Name: COLUMN catalogs__subcategories.category_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__subcategories.category_id IS 'Categoria à qual esta subcategoria pertence';


--
-- TOC entry 7174 (class 0 OID 0)
-- Dependencies: 356
-- Name: COLUMN catalogs__subcategories.name; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__subcategories.name IS 'Nome da subcategoria';


--
-- TOC entry 7175 (class 0 OID 0)
-- Dependencies: 356
-- Name: COLUMN catalogs__subcategories.description; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__subcategories.description IS 'Descrição da subcategoria';


--
-- TOC entry 7176 (class 0 OID 0)
-- Dependencies: 356
-- Name: COLUMN catalogs__subcategories.created_at; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__subcategories.created_at IS 'Data de criação do registro';


--
-- TOC entry 7177 (class 0 OID 0)
-- Dependencies: 356
-- Name: COLUMN catalogs__subcategories.updated_at; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__subcategories.updated_at IS 'Data da última atualização do registro';


--
-- TOC entry 7178 (class 0 OID 0)
-- Dependencies: 356
-- Name: COLUMN catalogs__subcategories.audit_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__subcategories.audit_id IS 'Identificador único do registro de auditoria';


--
-- TOC entry 7179 (class 0 OID 0)
-- Dependencies: 356
-- Name: COLUMN catalogs__subcategories.audit_operation; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__subcategories.audit_operation IS 'Tipo de operação realizada (INSERT, UPDATE, DELETE)';


--
-- TOC entry 7180 (class 0 OID 0)
-- Dependencies: 356
-- Name: COLUMN catalogs__subcategories.audit_timestamp; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__subcategories.audit_timestamp IS 'Data e hora da operação auditada';


--
-- TOC entry 7181 (class 0 OID 0)
-- Dependencies: 356
-- Name: COLUMN catalogs__subcategories.audit_user; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__subcategories.audit_user IS 'Usuário que executou a operação';


--
-- TOC entry 7182 (class 0 OID 0)
-- Dependencies: 356
-- Name: COLUMN catalogs__subcategories.audit_session_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__subcategories.audit_session_id IS 'Identificador da sessão da aplicação';


--
-- TOC entry 7183 (class 0 OID 0)
-- Dependencies: 356
-- Name: COLUMN catalogs__subcategories.audit_connection_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__subcategories.audit_connection_id IS 'Endereço IP da conexão';


--
-- TOC entry 7184 (class 0 OID 0)
-- Dependencies: 356
-- Name: COLUMN catalogs__subcategories.audit_partition_date; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__subcategories.audit_partition_date IS 'Data para particionamento da tabela de auditoria';


--
-- TOC entry 357 (class 1259 OID 20993)
-- Name: catalogs__subcategories_2025_08; Type: TABLE; Schema: audit; Owner: postgres
--

CREATE TABLE audit.catalogs__subcategories_2025_08 (
    subcategory_id uuid NOT NULL,
    category_id uuid NOT NULL,
    name text NOT NULL,
    description text,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone,
    audit_id bigint NOT NULL,
    audit_operation text NOT NULL,
    audit_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    audit_user text DEFAULT CURRENT_USER NOT NULL,
    audit_session_id text DEFAULT current_setting('application_name'::text) NOT NULL,
    audit_connection_id text DEFAULT inet_client_addr() NOT NULL,
    audit_partition_date date DEFAULT CURRENT_DATE NOT NULL
);


ALTER TABLE audit.catalogs__subcategories_2025_08 OWNER TO postgres;

--
-- TOC entry 355 (class 1259 OID 20976)
-- Name: catalogs__subcategories_audit_id_seq; Type: SEQUENCE; Schema: audit; Owner: postgres
--

ALTER TABLE audit.catalogs__subcategories ALTER COLUMN audit_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME audit.catalogs__subcategories_audit_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 359 (class 1259 OID 21010)
-- Name: catalogs__variant_types; Type: TABLE; Schema: audit; Owner: postgres
--

CREATE TABLE audit.catalogs__variant_types (
    variant_type_id uuid NOT NULL,
    name text NOT NULL,
    description text,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone,
    audit_id bigint NOT NULL,
    audit_operation text NOT NULL,
    audit_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    audit_user text DEFAULT CURRENT_USER NOT NULL,
    audit_session_id text DEFAULT current_setting('application_name'::text) NOT NULL,
    audit_connection_id text DEFAULT inet_client_addr() NOT NULL,
    audit_partition_date date DEFAULT CURRENT_DATE NOT NULL
)
PARTITION BY RANGE (audit_partition_date);


ALTER TABLE audit.catalogs__variant_types OWNER TO postgres;

--
-- TOC entry 7185 (class 0 OID 0)
-- Dependencies: 359
-- Name: TABLE catalogs__variant_types; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON TABLE audit.catalogs__variant_types IS 'AUDITORIA: Tipo ou variação específica do item (ex: Espaguete nº 08)';


--
-- TOC entry 7186 (class 0 OID 0)
-- Dependencies: 359
-- Name: COLUMN catalogs__variant_types.variant_type_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__variant_types.variant_type_id IS 'Identificador único do tipo';


--
-- TOC entry 7187 (class 0 OID 0)
-- Dependencies: 359
-- Name: COLUMN catalogs__variant_types.name; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__variant_types.name IS 'Nome do tipo de variação';


--
-- TOC entry 7188 (class 0 OID 0)
-- Dependencies: 359
-- Name: COLUMN catalogs__variant_types.description; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__variant_types.description IS 'Descrição do tipo de variação';


--
-- TOC entry 7189 (class 0 OID 0)
-- Dependencies: 359
-- Name: COLUMN catalogs__variant_types.created_at; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__variant_types.created_at IS 'Data de criação do registro';


--
-- TOC entry 7190 (class 0 OID 0)
-- Dependencies: 359
-- Name: COLUMN catalogs__variant_types.updated_at; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__variant_types.updated_at IS 'Data da última atualização do registro';


--
-- TOC entry 7191 (class 0 OID 0)
-- Dependencies: 359
-- Name: COLUMN catalogs__variant_types.audit_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__variant_types.audit_id IS 'Identificador único do registro de auditoria';


--
-- TOC entry 7192 (class 0 OID 0)
-- Dependencies: 359
-- Name: COLUMN catalogs__variant_types.audit_operation; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__variant_types.audit_operation IS 'Tipo de operação realizada (INSERT, UPDATE, DELETE)';


--
-- TOC entry 7193 (class 0 OID 0)
-- Dependencies: 359
-- Name: COLUMN catalogs__variant_types.audit_timestamp; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__variant_types.audit_timestamp IS 'Data e hora da operação auditada';


--
-- TOC entry 7194 (class 0 OID 0)
-- Dependencies: 359
-- Name: COLUMN catalogs__variant_types.audit_user; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__variant_types.audit_user IS 'Usuário que executou a operação';


--
-- TOC entry 7195 (class 0 OID 0)
-- Dependencies: 359
-- Name: COLUMN catalogs__variant_types.audit_session_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__variant_types.audit_session_id IS 'Identificador da sessão da aplicação';


--
-- TOC entry 7196 (class 0 OID 0)
-- Dependencies: 359
-- Name: COLUMN catalogs__variant_types.audit_connection_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__variant_types.audit_connection_id IS 'Endereço IP da conexão';


--
-- TOC entry 7197 (class 0 OID 0)
-- Dependencies: 359
-- Name: COLUMN catalogs__variant_types.audit_partition_date; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.catalogs__variant_types.audit_partition_date IS 'Data para particionamento da tabela de auditoria';


--
-- TOC entry 360 (class 1259 OID 21025)
-- Name: catalogs__variant_types_2025_08; Type: TABLE; Schema: audit; Owner: postgres
--

CREATE TABLE audit.catalogs__variant_types_2025_08 (
    variant_type_id uuid NOT NULL,
    name text NOT NULL,
    description text,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone,
    audit_id bigint NOT NULL,
    audit_operation text NOT NULL,
    audit_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    audit_user text DEFAULT CURRENT_USER NOT NULL,
    audit_session_id text DEFAULT current_setting('application_name'::text) NOT NULL,
    audit_connection_id text DEFAULT inet_client_addr() NOT NULL,
    audit_partition_date date DEFAULT CURRENT_DATE NOT NULL
);


ALTER TABLE audit.catalogs__variant_types_2025_08 OWNER TO postgres;

--
-- TOC entry 358 (class 1259 OID 21009)
-- Name: catalogs__variant_types_audit_id_seq; Type: SEQUENCE; Schema: audit; Owner: postgres
--

ALTER TABLE audit.catalogs__variant_types ALTER COLUMN audit_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME audit.catalogs__variant_types_audit_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 389 (class 1259 OID 21696)
-- Name: quotation__quotation_submissions; Type: TABLE; Schema: audit; Owner: postgres
--

CREATE TABLE audit.quotation__quotation_submissions (
    quotation_submission_id uuid NOT NULL,
    shopping_list_id uuid NOT NULL,
    submission_status_id uuid NOT NULL,
    submission_date timestamp with time zone,
    total_items bigint,
    notes text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    audit_id bigint NOT NULL,
    audit_operation text NOT NULL,
    audit_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    audit_user text DEFAULT CURRENT_USER NOT NULL,
    audit_session_id text DEFAULT current_setting('application_name'::text) NOT NULL,
    audit_connection_id text DEFAULT inet_client_addr() NOT NULL,
    audit_partition_date date DEFAULT CURRENT_DATE NOT NULL
)
PARTITION BY RANGE (audit_partition_date);


ALTER TABLE audit.quotation__quotation_submissions OWNER TO postgres;

--
-- TOC entry 7198 (class 0 OID 0)
-- Dependencies: 389
-- Name: TABLE quotation__quotation_submissions; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON TABLE audit.quotation__quotation_submissions IS 'AUDITORIA: Submissões de cotação quando as listas de compras são enviadas';


--
-- TOC entry 7199 (class 0 OID 0)
-- Dependencies: 389
-- Name: COLUMN quotation__quotation_submissions.quotation_submission_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__quotation_submissions.quotation_submission_id IS 'Identificador único da submissão de cotação';


--
-- TOC entry 7200 (class 0 OID 0)
-- Dependencies: 389
-- Name: COLUMN quotation__quotation_submissions.shopping_list_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__quotation_submissions.shopping_list_id IS 'Referência para a lista de compras';


--
-- TOC entry 7201 (class 0 OID 0)
-- Dependencies: 389
-- Name: COLUMN quotation__quotation_submissions.submission_status_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__quotation_submissions.submission_status_id IS 'Referência para o status da submissão';


--
-- TOC entry 7202 (class 0 OID 0)
-- Dependencies: 389
-- Name: COLUMN quotation__quotation_submissions.submission_date; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__quotation_submissions.submission_date IS 'Data de submissão da cotação';


--
-- TOC entry 7203 (class 0 OID 0)
-- Dependencies: 389
-- Name: COLUMN quotation__quotation_submissions.total_items; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__quotation_submissions.total_items IS 'Total de itens na submissão (calculado automaticamente)';


--
-- TOC entry 7204 (class 0 OID 0)
-- Dependencies: 389
-- Name: COLUMN quotation__quotation_submissions.notes; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__quotation_submissions.notes IS 'Observações sobre a submissão';


--
-- TOC entry 7205 (class 0 OID 0)
-- Dependencies: 389
-- Name: COLUMN quotation__quotation_submissions.audit_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__quotation_submissions.audit_id IS 'Identificador único do registro de auditoria';


--
-- TOC entry 7206 (class 0 OID 0)
-- Dependencies: 389
-- Name: COLUMN quotation__quotation_submissions.audit_operation; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__quotation_submissions.audit_operation IS 'Tipo de operação realizada (INSERT, UPDATE, DELETE)';


--
-- TOC entry 7207 (class 0 OID 0)
-- Dependencies: 389
-- Name: COLUMN quotation__quotation_submissions.audit_timestamp; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__quotation_submissions.audit_timestamp IS 'Data e hora da operação auditada';


--
-- TOC entry 7208 (class 0 OID 0)
-- Dependencies: 389
-- Name: COLUMN quotation__quotation_submissions.audit_user; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__quotation_submissions.audit_user IS 'Usuário que executou a operação';


--
-- TOC entry 7209 (class 0 OID 0)
-- Dependencies: 389
-- Name: COLUMN quotation__quotation_submissions.audit_session_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__quotation_submissions.audit_session_id IS 'Identificador da sessão da aplicação';


--
-- TOC entry 7210 (class 0 OID 0)
-- Dependencies: 389
-- Name: COLUMN quotation__quotation_submissions.audit_connection_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__quotation_submissions.audit_connection_id IS 'Endereço IP da conexão';


--
-- TOC entry 7211 (class 0 OID 0)
-- Dependencies: 389
-- Name: COLUMN quotation__quotation_submissions.audit_partition_date; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__quotation_submissions.audit_partition_date IS 'Data para particionamento da tabela de auditoria';


--
-- TOC entry 390 (class 1259 OID 21713)
-- Name: quotation__quotation_submissions_2025_08; Type: TABLE; Schema: audit; Owner: postgres
--

CREATE TABLE audit.quotation__quotation_submissions_2025_08 (
    quotation_submission_id uuid NOT NULL,
    shopping_list_id uuid NOT NULL,
    submission_status_id uuid NOT NULL,
    submission_date timestamp with time zone,
    total_items bigint,
    notes text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    audit_id bigint NOT NULL,
    audit_operation text NOT NULL,
    audit_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    audit_user text DEFAULT CURRENT_USER NOT NULL,
    audit_session_id text DEFAULT current_setting('application_name'::text) NOT NULL,
    audit_connection_id text DEFAULT inet_client_addr() NOT NULL,
    audit_partition_date date DEFAULT CURRENT_DATE NOT NULL
);


ALTER TABLE audit.quotation__quotation_submissions_2025_08 OWNER TO postgres;

--
-- TOC entry 388 (class 1259 OID 21695)
-- Name: quotation__quotation_submissions_audit_id_seq; Type: SEQUENCE; Schema: audit; Owner: postgres
--

ALTER TABLE audit.quotation__quotation_submissions ALTER COLUMN audit_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME audit.quotation__quotation_submissions_audit_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 395 (class 1259 OID 21770)
-- Name: quotation__quoted_prices; Type: TABLE; Schema: audit; Owner: postgres
--

CREATE TABLE audit.quotation__quoted_prices (
    quoted_price_id uuid NOT NULL,
    supplier_quotation_id uuid NOT NULL,
    quantity_from numeric NOT NULL,
    quantity_to numeric,
    unit_price numeric NOT NULL,
    total_price numeric NOT NULL,
    currency text,
    delivery_time_days bigint,
    minimum_order_quantity numeric,
    payment_terms text,
    validity_days bigint,
    special_conditions text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    audit_id bigint NOT NULL,
    audit_operation text NOT NULL,
    audit_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    audit_user text DEFAULT CURRENT_USER NOT NULL,
    audit_session_id text DEFAULT current_setting('application_name'::text) NOT NULL,
    audit_connection_id text DEFAULT inet_client_addr() NOT NULL,
    audit_partition_date date DEFAULT CURRENT_DATE NOT NULL
)
PARTITION BY RANGE (audit_partition_date);


ALTER TABLE audit.quotation__quoted_prices OWNER TO postgres;

--
-- TOC entry 7212 (class 0 OID 0)
-- Dependencies: 395
-- Name: TABLE quotation__quoted_prices; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON TABLE audit.quotation__quoted_prices IS 'AUDITORIA: Preços cotados pelos fornecedores com condições comerciais';


--
-- TOC entry 7213 (class 0 OID 0)
-- Dependencies: 395
-- Name: COLUMN quotation__quoted_prices.quoted_price_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__quoted_prices.quoted_price_id IS 'Identificador único do preço cotado';


--
-- TOC entry 7214 (class 0 OID 0)
-- Dependencies: 395
-- Name: COLUMN quotation__quoted_prices.supplier_quotation_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__quoted_prices.supplier_quotation_id IS 'Referência para a cotação do fornecedor';


--
-- TOC entry 7215 (class 0 OID 0)
-- Dependencies: 395
-- Name: COLUMN quotation__quoted_prices.quantity_from; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__quoted_prices.quantity_from IS 'Quantidade mínima para este preço';


--
-- TOC entry 7216 (class 0 OID 0)
-- Dependencies: 395
-- Name: COLUMN quotation__quoted_prices.quantity_to; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__quoted_prices.quantity_to IS 'Quantidade máxima para este preço (NULL = ilimitado)';


--
-- TOC entry 7217 (class 0 OID 0)
-- Dependencies: 395
-- Name: COLUMN quotation__quoted_prices.unit_price; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__quoted_prices.unit_price IS 'Preço unitário';


--
-- TOC entry 7218 (class 0 OID 0)
-- Dependencies: 395
-- Name: COLUMN quotation__quoted_prices.total_price; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__quoted_prices.total_price IS 'Preço total para a quantidade';


--
-- TOC entry 7219 (class 0 OID 0)
-- Dependencies: 395
-- Name: COLUMN quotation__quoted_prices.currency; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__quoted_prices.currency IS 'Moeda da cotação';


--
-- TOC entry 7220 (class 0 OID 0)
-- Dependencies: 395
-- Name: COLUMN quotation__quoted_prices.delivery_time_days; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__quoted_prices.delivery_time_days IS 'Prazo de entrega em dias';


--
-- TOC entry 7221 (class 0 OID 0)
-- Dependencies: 395
-- Name: COLUMN quotation__quoted_prices.minimum_order_quantity; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__quoted_prices.minimum_order_quantity IS 'Quantidade mínima para pedido';


--
-- TOC entry 7222 (class 0 OID 0)
-- Dependencies: 395
-- Name: COLUMN quotation__quoted_prices.payment_terms; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__quoted_prices.payment_terms IS 'Condições de pagamento';


--
-- TOC entry 7223 (class 0 OID 0)
-- Dependencies: 395
-- Name: COLUMN quotation__quoted_prices.validity_days; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__quoted_prices.validity_days IS 'Validade da cotação em dias';


--
-- TOC entry 7224 (class 0 OID 0)
-- Dependencies: 395
-- Name: COLUMN quotation__quoted_prices.special_conditions; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__quoted_prices.special_conditions IS 'Condições especiais';


--
-- TOC entry 7225 (class 0 OID 0)
-- Dependencies: 395
-- Name: COLUMN quotation__quoted_prices.audit_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__quoted_prices.audit_id IS 'Identificador único do registro de auditoria';


--
-- TOC entry 7226 (class 0 OID 0)
-- Dependencies: 395
-- Name: COLUMN quotation__quoted_prices.audit_operation; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__quoted_prices.audit_operation IS 'Tipo de operação realizada (INSERT, UPDATE, DELETE)';


--
-- TOC entry 7227 (class 0 OID 0)
-- Dependencies: 395
-- Name: COLUMN quotation__quoted_prices.audit_timestamp; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__quoted_prices.audit_timestamp IS 'Data e hora da operação auditada';


--
-- TOC entry 7228 (class 0 OID 0)
-- Dependencies: 395
-- Name: COLUMN quotation__quoted_prices.audit_user; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__quoted_prices.audit_user IS 'Usuário que executou a operação';


--
-- TOC entry 7229 (class 0 OID 0)
-- Dependencies: 395
-- Name: COLUMN quotation__quoted_prices.audit_session_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__quoted_prices.audit_session_id IS 'Identificador da sessão da aplicação';


--
-- TOC entry 7230 (class 0 OID 0)
-- Dependencies: 395
-- Name: COLUMN quotation__quoted_prices.audit_connection_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__quoted_prices.audit_connection_id IS 'Endereço IP da conexão';


--
-- TOC entry 7231 (class 0 OID 0)
-- Dependencies: 395
-- Name: COLUMN quotation__quoted_prices.audit_partition_date; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__quoted_prices.audit_partition_date IS 'Data para particionamento da tabela de auditoria';


--
-- TOC entry 396 (class 1259 OID 21786)
-- Name: quotation__quoted_prices_2025_08; Type: TABLE; Schema: audit; Owner: postgres
--

CREATE TABLE audit.quotation__quoted_prices_2025_08 (
    quoted_price_id uuid NOT NULL,
    supplier_quotation_id uuid NOT NULL,
    quantity_from numeric NOT NULL,
    quantity_to numeric,
    unit_price numeric NOT NULL,
    total_price numeric NOT NULL,
    currency text,
    delivery_time_days bigint,
    minimum_order_quantity numeric,
    payment_terms text,
    validity_days bigint,
    special_conditions text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    audit_id bigint NOT NULL,
    audit_operation text NOT NULL,
    audit_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    audit_user text DEFAULT CURRENT_USER NOT NULL,
    audit_session_id text DEFAULT current_setting('application_name'::text) NOT NULL,
    audit_connection_id text DEFAULT inet_client_addr() NOT NULL,
    audit_partition_date date DEFAULT CURRENT_DATE NOT NULL
);


ALTER TABLE audit.quotation__quoted_prices_2025_08 OWNER TO postgres;

--
-- TOC entry 394 (class 1259 OID 21769)
-- Name: quotation__quoted_prices_audit_id_seq; Type: SEQUENCE; Schema: audit; Owner: postgres
--

ALTER TABLE audit.quotation__quoted_prices ALTER COLUMN audit_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME audit.quotation__quoted_prices_audit_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 386 (class 1259 OID 21641)
-- Name: quotation__shopping_list_items; Type: TABLE; Schema: audit; Owner: postgres
--

CREATE TABLE audit.quotation__shopping_list_items (
    shopping_list_item_id uuid NOT NULL,
    shopping_list_id uuid NOT NULL,
    item_id uuid NOT NULL,
    product_id uuid,
    composition_id uuid,
    variant_type_id uuid,
    format_id uuid,
    flavor_id uuid,
    filling_id uuid,
    nutritional_variant_id uuid,
    brand_id uuid,
    packaging_id uuid,
    quantity_id uuid,
    term text NOT NULL,
    quantity numeric NOT NULL,
    notes text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    audit_id bigint NOT NULL,
    audit_operation text NOT NULL,
    audit_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    audit_user text DEFAULT CURRENT_USER NOT NULL,
    audit_session_id text DEFAULT current_setting('application_name'::text) NOT NULL,
    audit_connection_id text DEFAULT inet_client_addr() NOT NULL,
    audit_partition_date date DEFAULT CURRENT_DATE NOT NULL
)
PARTITION BY RANGE (audit_partition_date);


ALTER TABLE audit.quotation__shopping_list_items OWNER TO postgres;

--
-- TOC entry 7232 (class 0 OID 0)
-- Dependencies: 386
-- Name: TABLE quotation__shopping_list_items; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON TABLE audit.quotation__shopping_list_items IS 'AUDITORIA: Itens dentro das listas de compras com decomposição completa para busca refinada';


--
-- TOC entry 7233 (class 0 OID 0)
-- Dependencies: 386
-- Name: COLUMN quotation__shopping_list_items.shopping_list_item_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__shopping_list_items.shopping_list_item_id IS 'Identificador único do item da lista de compras';


--
-- TOC entry 7234 (class 0 OID 0)
-- Dependencies: 386
-- Name: COLUMN quotation__shopping_list_items.shopping_list_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__shopping_list_items.shopping_list_id IS 'Referência para a lista de compras';


--
-- TOC entry 7235 (class 0 OID 0)
-- Dependencies: 386
-- Name: COLUMN quotation__shopping_list_items.item_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__shopping_list_items.item_id IS 'Referência para catalog.items (item genérico - OBRIGATÓRIO)';


--
-- TOC entry 7236 (class 0 OID 0)
-- Dependencies: 386
-- Name: COLUMN quotation__shopping_list_items.product_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__shopping_list_items.product_id IS 'Referência para catalog.products (produto específico se encontrado)';


--
-- TOC entry 7237 (class 0 OID 0)
-- Dependencies: 386
-- Name: COLUMN quotation__shopping_list_items.composition_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__shopping_list_items.composition_id IS 'Referência para catalog.compositions (composição do produto)';


--
-- TOC entry 7238 (class 0 OID 0)
-- Dependencies: 386
-- Name: COLUMN quotation__shopping_list_items.variant_type_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__shopping_list_items.variant_type_id IS 'Referência para catalog.variant_types (tipo de variante)';


--
-- TOC entry 7239 (class 0 OID 0)
-- Dependencies: 386
-- Name: COLUMN quotation__shopping_list_items.format_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__shopping_list_items.format_id IS 'Referência para catalog.formats (formato do produto)';


--
-- TOC entry 7240 (class 0 OID 0)
-- Dependencies: 386
-- Name: COLUMN quotation__shopping_list_items.flavor_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__shopping_list_items.flavor_id IS 'Referência para catalog.flavors (sabor do produto)';


--
-- TOC entry 7241 (class 0 OID 0)
-- Dependencies: 386
-- Name: COLUMN quotation__shopping_list_items.filling_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__shopping_list_items.filling_id IS 'Referência para catalog.fillings (recheio do produto)';


--
-- TOC entry 7242 (class 0 OID 0)
-- Dependencies: 386
-- Name: COLUMN quotation__shopping_list_items.nutritional_variant_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__shopping_list_items.nutritional_variant_id IS 'Referência para catalog.nutritional_variants (variante nutricional)';


--
-- TOC entry 7243 (class 0 OID 0)
-- Dependencies: 386
-- Name: COLUMN quotation__shopping_list_items.brand_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__shopping_list_items.brand_id IS 'Referência para catalog.brands (marca do produto)';


--
-- TOC entry 7244 (class 0 OID 0)
-- Dependencies: 386
-- Name: COLUMN quotation__shopping_list_items.packaging_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__shopping_list_items.packaging_id IS 'Referência para catalog.packagings (embalagem do produto)';


--
-- TOC entry 7245 (class 0 OID 0)
-- Dependencies: 386
-- Name: COLUMN quotation__shopping_list_items.quantity_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__shopping_list_items.quantity_id IS 'Referência para catalog.quantities (quantidade/medida)';


--
-- TOC entry 7246 (class 0 OID 0)
-- Dependencies: 386
-- Name: COLUMN quotation__shopping_list_items.term; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__shopping_list_items.term IS 'Termo original digitado pelo usuário para busca';


--
-- TOC entry 7247 (class 0 OID 0)
-- Dependencies: 386
-- Name: COLUMN quotation__shopping_list_items.quantity; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__shopping_list_items.quantity IS 'Quantidade solicitada';


--
-- TOC entry 7248 (class 0 OID 0)
-- Dependencies: 386
-- Name: COLUMN quotation__shopping_list_items.notes; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__shopping_list_items.notes IS 'Observações sobre o item';


--
-- TOC entry 7249 (class 0 OID 0)
-- Dependencies: 386
-- Name: COLUMN quotation__shopping_list_items.audit_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__shopping_list_items.audit_id IS 'Identificador único do registro de auditoria';


--
-- TOC entry 7250 (class 0 OID 0)
-- Dependencies: 386
-- Name: COLUMN quotation__shopping_list_items.audit_operation; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__shopping_list_items.audit_operation IS 'Tipo de operação realizada (INSERT, UPDATE, DELETE)';


--
-- TOC entry 7251 (class 0 OID 0)
-- Dependencies: 386
-- Name: COLUMN quotation__shopping_list_items.audit_timestamp; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__shopping_list_items.audit_timestamp IS 'Data e hora da operação auditada';


--
-- TOC entry 7252 (class 0 OID 0)
-- Dependencies: 386
-- Name: COLUMN quotation__shopping_list_items.audit_user; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__shopping_list_items.audit_user IS 'Usuário que executou a operação';


--
-- TOC entry 7253 (class 0 OID 0)
-- Dependencies: 386
-- Name: COLUMN quotation__shopping_list_items.audit_session_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__shopping_list_items.audit_session_id IS 'Identificador da sessão da aplicação';


--
-- TOC entry 7254 (class 0 OID 0)
-- Dependencies: 386
-- Name: COLUMN quotation__shopping_list_items.audit_connection_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__shopping_list_items.audit_connection_id IS 'Endereço IP da conexão';


--
-- TOC entry 7255 (class 0 OID 0)
-- Dependencies: 386
-- Name: COLUMN quotation__shopping_list_items.audit_partition_date; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__shopping_list_items.audit_partition_date IS 'Data para particionamento da tabela de auditoria';


--
-- TOC entry 387 (class 1259 OID 21668)
-- Name: quotation__shopping_list_items_2025_08; Type: TABLE; Schema: audit; Owner: postgres
--

CREATE TABLE audit.quotation__shopping_list_items_2025_08 (
    shopping_list_item_id uuid NOT NULL,
    shopping_list_id uuid NOT NULL,
    item_id uuid NOT NULL,
    product_id uuid,
    composition_id uuid,
    variant_type_id uuid,
    format_id uuid,
    flavor_id uuid,
    filling_id uuid,
    nutritional_variant_id uuid,
    brand_id uuid,
    packaging_id uuid,
    quantity_id uuid,
    term text NOT NULL,
    quantity numeric NOT NULL,
    notes text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    audit_id bigint NOT NULL,
    audit_operation text NOT NULL,
    audit_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    audit_user text DEFAULT CURRENT_USER NOT NULL,
    audit_session_id text DEFAULT current_setting('application_name'::text) NOT NULL,
    audit_connection_id text DEFAULT inet_client_addr() NOT NULL,
    audit_partition_date date DEFAULT CURRENT_DATE NOT NULL
);


ALTER TABLE audit.quotation__shopping_list_items_2025_08 OWNER TO postgres;

--
-- TOC entry 385 (class 1259 OID 21640)
-- Name: quotation__shopping_list_items_audit_id_seq; Type: SEQUENCE; Schema: audit; Owner: postgres
--

ALTER TABLE audit.quotation__shopping_list_items ALTER COLUMN audit_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME audit.quotation__shopping_list_items_audit_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 383 (class 1259 OID 21606)
-- Name: quotation__shopping_lists; Type: TABLE; Schema: audit; Owner: postgres
--

CREATE TABLE audit.quotation__shopping_lists (
    shopping_list_id uuid NOT NULL,
    establishment_id uuid NOT NULL,
    employee_id uuid NOT NULL,
    name text NOT NULL,
    description text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    audit_id bigint NOT NULL,
    audit_operation text NOT NULL,
    audit_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    audit_user text DEFAULT CURRENT_USER NOT NULL,
    audit_session_id text DEFAULT current_setting('application_name'::text) NOT NULL,
    audit_connection_id text DEFAULT inet_client_addr() NOT NULL,
    audit_partition_date date DEFAULT CURRENT_DATE NOT NULL
)
PARTITION BY RANGE (audit_partition_date);


ALTER TABLE audit.quotation__shopping_lists OWNER TO postgres;

--
-- TOC entry 7256 (class 0 OID 0)
-- Dependencies: 383
-- Name: TABLE quotation__shopping_lists; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON TABLE audit.quotation__shopping_lists IS 'AUDITORIA: Listas de compras criadas pelos estabelecimentos';


--
-- TOC entry 7257 (class 0 OID 0)
-- Dependencies: 383
-- Name: COLUMN quotation__shopping_lists.shopping_list_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__shopping_lists.shopping_list_id IS 'Identificador único da lista de compras';


--
-- TOC entry 7258 (class 0 OID 0)
-- Dependencies: 383
-- Name: COLUMN quotation__shopping_lists.establishment_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__shopping_lists.establishment_id IS 'Referência para accounts.establishments';


--
-- TOC entry 7259 (class 0 OID 0)
-- Dependencies: 383
-- Name: COLUMN quotation__shopping_lists.employee_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__shopping_lists.employee_id IS 'Referência para accounts.employees (usuário que criou a lista)';


--
-- TOC entry 7260 (class 0 OID 0)
-- Dependencies: 383
-- Name: COLUMN quotation__shopping_lists.name; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__shopping_lists.name IS 'Nome da lista de compras';


--
-- TOC entry 7261 (class 0 OID 0)
-- Dependencies: 383
-- Name: COLUMN quotation__shopping_lists.description; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__shopping_lists.description IS 'Descrição da lista de compras';


--
-- TOC entry 7262 (class 0 OID 0)
-- Dependencies: 383
-- Name: COLUMN quotation__shopping_lists.created_at; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__shopping_lists.created_at IS 'Data de criação do registro';


--
-- TOC entry 7263 (class 0 OID 0)
-- Dependencies: 383
-- Name: COLUMN quotation__shopping_lists.updated_at; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__shopping_lists.updated_at IS 'Data da última atualização do registro';


--
-- TOC entry 7264 (class 0 OID 0)
-- Dependencies: 383
-- Name: COLUMN quotation__shopping_lists.audit_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__shopping_lists.audit_id IS 'Identificador único do registro de auditoria';


--
-- TOC entry 7265 (class 0 OID 0)
-- Dependencies: 383
-- Name: COLUMN quotation__shopping_lists.audit_operation; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__shopping_lists.audit_operation IS 'Tipo de operação realizada (INSERT, UPDATE, DELETE)';


--
-- TOC entry 7266 (class 0 OID 0)
-- Dependencies: 383
-- Name: COLUMN quotation__shopping_lists.audit_timestamp; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__shopping_lists.audit_timestamp IS 'Data e hora da operação auditada';


--
-- TOC entry 7267 (class 0 OID 0)
-- Dependencies: 383
-- Name: COLUMN quotation__shopping_lists.audit_user; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__shopping_lists.audit_user IS 'Usuário que executou a operação';


--
-- TOC entry 7268 (class 0 OID 0)
-- Dependencies: 383
-- Name: COLUMN quotation__shopping_lists.audit_session_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__shopping_lists.audit_session_id IS 'Identificador da sessão da aplicação';


--
-- TOC entry 7269 (class 0 OID 0)
-- Dependencies: 383
-- Name: COLUMN quotation__shopping_lists.audit_connection_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__shopping_lists.audit_connection_id IS 'Endereço IP da conexão';


--
-- TOC entry 7270 (class 0 OID 0)
-- Dependencies: 383
-- Name: COLUMN quotation__shopping_lists.audit_partition_date; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__shopping_lists.audit_partition_date IS 'Data para particionamento da tabela de auditoria';


--
-- TOC entry 384 (class 1259 OID 21623)
-- Name: quotation__shopping_lists_2025_08; Type: TABLE; Schema: audit; Owner: postgres
--

CREATE TABLE audit.quotation__shopping_lists_2025_08 (
    shopping_list_id uuid NOT NULL,
    establishment_id uuid NOT NULL,
    employee_id uuid NOT NULL,
    name text NOT NULL,
    description text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    audit_id bigint NOT NULL,
    audit_operation text NOT NULL,
    audit_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    audit_user text DEFAULT CURRENT_USER NOT NULL,
    audit_session_id text DEFAULT current_setting('application_name'::text) NOT NULL,
    audit_connection_id text DEFAULT inet_client_addr() NOT NULL,
    audit_partition_date date DEFAULT CURRENT_DATE NOT NULL
);


ALTER TABLE audit.quotation__shopping_lists_2025_08 OWNER TO postgres;

--
-- TOC entry 382 (class 1259 OID 21605)
-- Name: quotation__shopping_lists_audit_id_seq; Type: SEQUENCE; Schema: audit; Owner: postgres
--

ALTER TABLE audit.quotation__shopping_lists ALTER COLUMN audit_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME audit.quotation__shopping_lists_audit_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 377 (class 1259 OID 21544)
-- Name: quotation__submission_statuses; Type: TABLE; Schema: audit; Owner: postgres
--

CREATE TABLE audit.quotation__submission_statuses (
    submission_status_id uuid NOT NULL,
    name text NOT NULL,
    description text,
    color text,
    is_active boolean,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    audit_id bigint NOT NULL,
    audit_operation text NOT NULL,
    audit_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    audit_user text DEFAULT CURRENT_USER NOT NULL,
    audit_session_id text DEFAULT current_setting('application_name'::text) NOT NULL,
    audit_connection_id text DEFAULT inet_client_addr() NOT NULL,
    audit_partition_date date DEFAULT CURRENT_DATE NOT NULL
)
PARTITION BY RANGE (audit_partition_date);


ALTER TABLE audit.quotation__submission_statuses OWNER TO postgres;

--
-- TOC entry 7271 (class 0 OID 0)
-- Dependencies: 377
-- Name: TABLE quotation__submission_statuses; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON TABLE audit.quotation__submission_statuses IS 'AUDITORIA: Status das submissões de cotação (controle interno do sistema)';


--
-- TOC entry 7272 (class 0 OID 0)
-- Dependencies: 377
-- Name: COLUMN quotation__submission_statuses.submission_status_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__submission_statuses.submission_status_id IS 'Identificador único do status de submissão';


--
-- TOC entry 7273 (class 0 OID 0)
-- Dependencies: 377
-- Name: COLUMN quotation__submission_statuses.name; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__submission_statuses.name IS 'Nome do status (ex: pending, sent, completed)';


--
-- TOC entry 7274 (class 0 OID 0)
-- Dependencies: 377
-- Name: COLUMN quotation__submission_statuses.description; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__submission_statuses.description IS 'Descrição detalhada do status';


--
-- TOC entry 7275 (class 0 OID 0)
-- Dependencies: 377
-- Name: COLUMN quotation__submission_statuses.color; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__submission_statuses.color IS 'Código de cor hexadecimal para interface';


--
-- TOC entry 7276 (class 0 OID 0)
-- Dependencies: 377
-- Name: COLUMN quotation__submission_statuses.is_active; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__submission_statuses.is_active IS 'Indica se o status está ativo para uso';


--
-- TOC entry 7277 (class 0 OID 0)
-- Dependencies: 377
-- Name: COLUMN quotation__submission_statuses.audit_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__submission_statuses.audit_id IS 'Identificador único do registro de auditoria';


--
-- TOC entry 7278 (class 0 OID 0)
-- Dependencies: 377
-- Name: COLUMN quotation__submission_statuses.audit_operation; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__submission_statuses.audit_operation IS 'Tipo de operação realizada (INSERT, UPDATE, DELETE)';


--
-- TOC entry 7279 (class 0 OID 0)
-- Dependencies: 377
-- Name: COLUMN quotation__submission_statuses.audit_timestamp; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__submission_statuses.audit_timestamp IS 'Data e hora da operação auditada';


--
-- TOC entry 7280 (class 0 OID 0)
-- Dependencies: 377
-- Name: COLUMN quotation__submission_statuses.audit_user; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__submission_statuses.audit_user IS 'Usuário que executou a operação';


--
-- TOC entry 7281 (class 0 OID 0)
-- Dependencies: 377
-- Name: COLUMN quotation__submission_statuses.audit_session_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__submission_statuses.audit_session_id IS 'Identificador da sessão da aplicação';


--
-- TOC entry 7282 (class 0 OID 0)
-- Dependencies: 377
-- Name: COLUMN quotation__submission_statuses.audit_connection_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__submission_statuses.audit_connection_id IS 'Endereço IP da conexão';


--
-- TOC entry 7283 (class 0 OID 0)
-- Dependencies: 377
-- Name: COLUMN quotation__submission_statuses.audit_partition_date; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__submission_statuses.audit_partition_date IS 'Data para particionamento da tabela de auditoria';


--
-- TOC entry 378 (class 1259 OID 21559)
-- Name: quotation__submission_statuses_2025_08; Type: TABLE; Schema: audit; Owner: postgres
--

CREATE TABLE audit.quotation__submission_statuses_2025_08 (
    submission_status_id uuid NOT NULL,
    name text NOT NULL,
    description text,
    color text,
    is_active boolean,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    audit_id bigint NOT NULL,
    audit_operation text NOT NULL,
    audit_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    audit_user text DEFAULT CURRENT_USER NOT NULL,
    audit_session_id text DEFAULT current_setting('application_name'::text) NOT NULL,
    audit_connection_id text DEFAULT inet_client_addr() NOT NULL,
    audit_partition_date date DEFAULT CURRENT_DATE NOT NULL
);


ALTER TABLE audit.quotation__submission_statuses_2025_08 OWNER TO postgres;

--
-- TOC entry 376 (class 1259 OID 21543)
-- Name: quotation__submission_statuses_audit_id_seq; Type: SEQUENCE; Schema: audit; Owner: postgres
--

ALTER TABLE audit.quotation__submission_statuses ALTER COLUMN audit_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME audit.quotation__submission_statuses_audit_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 380 (class 1259 OID 21575)
-- Name: quotation__supplier_quotation_statuses; Type: TABLE; Schema: audit; Owner: postgres
--

CREATE TABLE audit.quotation__supplier_quotation_statuses (
    quotation_status_id uuid NOT NULL,
    name text NOT NULL,
    description text,
    color text,
    is_active boolean,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    audit_id bigint NOT NULL,
    audit_operation text NOT NULL,
    audit_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    audit_user text DEFAULT CURRENT_USER NOT NULL,
    audit_session_id text DEFAULT current_setting('application_name'::text) NOT NULL,
    audit_connection_id text DEFAULT inet_client_addr() NOT NULL,
    audit_partition_date date DEFAULT CURRENT_DATE NOT NULL
)
PARTITION BY RANGE (audit_partition_date);


ALTER TABLE audit.quotation__supplier_quotation_statuses OWNER TO postgres;

--
-- TOC entry 7284 (class 0 OID 0)
-- Dependencies: 380
-- Name: TABLE quotation__supplier_quotation_statuses; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON TABLE audit.quotation__supplier_quotation_statuses IS 'AUDITORIA: Status das cotações recebidas dos fornecedores';


--
-- TOC entry 7285 (class 0 OID 0)
-- Dependencies: 380
-- Name: COLUMN quotation__supplier_quotation_statuses.quotation_status_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__supplier_quotation_statuses.quotation_status_id IS 'Identificador único do status de cotação';


--
-- TOC entry 7286 (class 0 OID 0)
-- Dependencies: 380
-- Name: COLUMN quotation__supplier_quotation_statuses.name; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__supplier_quotation_statuses.name IS 'Nome do status (ex: pending, received, accepted)';


--
-- TOC entry 7287 (class 0 OID 0)
-- Dependencies: 380
-- Name: COLUMN quotation__supplier_quotation_statuses.description; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__supplier_quotation_statuses.description IS 'Descrição detalhada do status';


--
-- TOC entry 7288 (class 0 OID 0)
-- Dependencies: 380
-- Name: COLUMN quotation__supplier_quotation_statuses.color; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__supplier_quotation_statuses.color IS 'Código de cor hexadecimal para interface';


--
-- TOC entry 7289 (class 0 OID 0)
-- Dependencies: 380
-- Name: COLUMN quotation__supplier_quotation_statuses.is_active; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__supplier_quotation_statuses.is_active IS 'Indica se o status está ativo para uso';


--
-- TOC entry 7290 (class 0 OID 0)
-- Dependencies: 380
-- Name: COLUMN quotation__supplier_quotation_statuses.audit_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__supplier_quotation_statuses.audit_id IS 'Identificador único do registro de auditoria';


--
-- TOC entry 7291 (class 0 OID 0)
-- Dependencies: 380
-- Name: COLUMN quotation__supplier_quotation_statuses.audit_operation; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__supplier_quotation_statuses.audit_operation IS 'Tipo de operação realizada (INSERT, UPDATE, DELETE)';


--
-- TOC entry 7292 (class 0 OID 0)
-- Dependencies: 380
-- Name: COLUMN quotation__supplier_quotation_statuses.audit_timestamp; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__supplier_quotation_statuses.audit_timestamp IS 'Data e hora da operação auditada';


--
-- TOC entry 7293 (class 0 OID 0)
-- Dependencies: 380
-- Name: COLUMN quotation__supplier_quotation_statuses.audit_user; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__supplier_quotation_statuses.audit_user IS 'Usuário que executou a operação';


--
-- TOC entry 7294 (class 0 OID 0)
-- Dependencies: 380
-- Name: COLUMN quotation__supplier_quotation_statuses.audit_session_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__supplier_quotation_statuses.audit_session_id IS 'Identificador da sessão da aplicação';


--
-- TOC entry 7295 (class 0 OID 0)
-- Dependencies: 380
-- Name: COLUMN quotation__supplier_quotation_statuses.audit_connection_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__supplier_quotation_statuses.audit_connection_id IS 'Endereço IP da conexão';


--
-- TOC entry 7296 (class 0 OID 0)
-- Dependencies: 380
-- Name: COLUMN quotation__supplier_quotation_statuses.audit_partition_date; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__supplier_quotation_statuses.audit_partition_date IS 'Data para particionamento da tabela de auditoria';


--
-- TOC entry 381 (class 1259 OID 21590)
-- Name: quotation__supplier_quotation_statuses_2025_08; Type: TABLE; Schema: audit; Owner: postgres
--

CREATE TABLE audit.quotation__supplier_quotation_statuses_2025_08 (
    quotation_status_id uuid NOT NULL,
    name text NOT NULL,
    description text,
    color text,
    is_active boolean,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    audit_id bigint NOT NULL,
    audit_operation text NOT NULL,
    audit_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    audit_user text DEFAULT CURRENT_USER NOT NULL,
    audit_session_id text DEFAULT current_setting('application_name'::text) NOT NULL,
    audit_connection_id text DEFAULT inet_client_addr() NOT NULL,
    audit_partition_date date DEFAULT CURRENT_DATE NOT NULL
);


ALTER TABLE audit.quotation__supplier_quotation_statuses_2025_08 OWNER TO postgres;

--
-- TOC entry 379 (class 1259 OID 21574)
-- Name: quotation__supplier_quotation_statuses_audit_id_seq; Type: SEQUENCE; Schema: audit; Owner: postgres
--

ALTER TABLE audit.quotation__supplier_quotation_statuses ALTER COLUMN audit_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME audit.quotation__supplier_quotation_statuses_audit_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 392 (class 1259 OID 21731)
-- Name: quotation__supplier_quotations; Type: TABLE; Schema: audit; Owner: postgres
--

CREATE TABLE audit.quotation__supplier_quotations (
    supplier_quotation_id uuid NOT NULL,
    quotation_submission_id uuid NOT NULL,
    shopping_list_item_id uuid NOT NULL,
    supplier_id uuid NOT NULL,
    quotation_status_id uuid NOT NULL,
    quotation_date timestamp with time zone,
    notes text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    audit_id bigint NOT NULL,
    audit_operation text NOT NULL,
    audit_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    audit_user text DEFAULT CURRENT_USER NOT NULL,
    audit_session_id text DEFAULT current_setting('application_name'::text) NOT NULL,
    audit_connection_id text DEFAULT inet_client_addr() NOT NULL,
    audit_partition_date date DEFAULT CURRENT_DATE NOT NULL
)
PARTITION BY RANGE (audit_partition_date);


ALTER TABLE audit.quotation__supplier_quotations OWNER TO postgres;

--
-- TOC entry 7297 (class 0 OID 0)
-- Dependencies: 392
-- Name: TABLE quotation__supplier_quotations; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON TABLE audit.quotation__supplier_quotations IS 'AUDITORIA: Cotações recebidas dos fornecedores para itens específicos';


--
-- TOC entry 7298 (class 0 OID 0)
-- Dependencies: 392
-- Name: COLUMN quotation__supplier_quotations.supplier_quotation_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__supplier_quotations.supplier_quotation_id IS 'Identificador único da cotação do fornecedor';


--
-- TOC entry 7299 (class 0 OID 0)
-- Dependencies: 392
-- Name: COLUMN quotation__supplier_quotations.quotation_submission_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__supplier_quotations.quotation_submission_id IS 'Referência para a submissão de cotação';


--
-- TOC entry 7300 (class 0 OID 0)
-- Dependencies: 392
-- Name: COLUMN quotation__supplier_quotations.shopping_list_item_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__supplier_quotations.shopping_list_item_id IS 'Referência para o item da lista de compras';


--
-- TOC entry 7301 (class 0 OID 0)
-- Dependencies: 392
-- Name: COLUMN quotation__supplier_quotations.supplier_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__supplier_quotations.supplier_id IS 'Referência para accounts.suppliers';


--
-- TOC entry 7302 (class 0 OID 0)
-- Dependencies: 392
-- Name: COLUMN quotation__supplier_quotations.quotation_status_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__supplier_quotations.quotation_status_id IS 'Referência para o status da cotação';


--
-- TOC entry 7303 (class 0 OID 0)
-- Dependencies: 392
-- Name: COLUMN quotation__supplier_quotations.quotation_date; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__supplier_quotations.quotation_date IS 'Data da cotação do fornecedor';


--
-- TOC entry 7304 (class 0 OID 0)
-- Dependencies: 392
-- Name: COLUMN quotation__supplier_quotations.notes; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__supplier_quotations.notes IS 'Observações sobre a cotação do fornecedor';


--
-- TOC entry 7305 (class 0 OID 0)
-- Dependencies: 392
-- Name: COLUMN quotation__supplier_quotations.audit_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__supplier_quotations.audit_id IS 'Identificador único do registro de auditoria';


--
-- TOC entry 7306 (class 0 OID 0)
-- Dependencies: 392
-- Name: COLUMN quotation__supplier_quotations.audit_operation; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__supplier_quotations.audit_operation IS 'Tipo de operação realizada (INSERT, UPDATE, DELETE)';


--
-- TOC entry 7307 (class 0 OID 0)
-- Dependencies: 392
-- Name: COLUMN quotation__supplier_quotations.audit_timestamp; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__supplier_quotations.audit_timestamp IS 'Data e hora da operação auditada';


--
-- TOC entry 7308 (class 0 OID 0)
-- Dependencies: 392
-- Name: COLUMN quotation__supplier_quotations.audit_user; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__supplier_quotations.audit_user IS 'Usuário que executou a operação';


--
-- TOC entry 7309 (class 0 OID 0)
-- Dependencies: 392
-- Name: COLUMN quotation__supplier_quotations.audit_session_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__supplier_quotations.audit_session_id IS 'Identificador da sessão da aplicação';


--
-- TOC entry 7310 (class 0 OID 0)
-- Dependencies: 392
-- Name: COLUMN quotation__supplier_quotations.audit_connection_id; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__supplier_quotations.audit_connection_id IS 'Endereço IP da conexão';


--
-- TOC entry 7311 (class 0 OID 0)
-- Dependencies: 392
-- Name: COLUMN quotation__supplier_quotations.audit_partition_date; Type: COMMENT; Schema: audit; Owner: postgres
--

COMMENT ON COLUMN audit.quotation__supplier_quotations.audit_partition_date IS 'Data para particionamento da tabela de auditoria';


--
-- TOC entry 393 (class 1259 OID 21750)
-- Name: quotation__supplier_quotations_2025_08; Type: TABLE; Schema: audit; Owner: postgres
--

CREATE TABLE audit.quotation__supplier_quotations_2025_08 (
    supplier_quotation_id uuid NOT NULL,
    quotation_submission_id uuid NOT NULL,
    shopping_list_item_id uuid NOT NULL,
    supplier_id uuid NOT NULL,
    quotation_status_id uuid NOT NULL,
    quotation_date timestamp with time zone,
    notes text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    audit_id bigint NOT NULL,
    audit_operation text NOT NULL,
    audit_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    audit_user text DEFAULT CURRENT_USER NOT NULL,
    audit_session_id text DEFAULT current_setting('application_name'::text) NOT NULL,
    audit_connection_id text DEFAULT inet_client_addr() NOT NULL,
    audit_partition_date date DEFAULT CURRENT_DATE NOT NULL
);


ALTER TABLE audit.quotation__supplier_quotations_2025_08 OWNER TO postgres;

--
-- TOC entry 391 (class 1259 OID 21730)
-- Name: quotation__supplier_quotations_audit_id_seq; Type: SEQUENCE; Schema: audit; Owner: postgres
--

ALTER TABLE audit.quotation__supplier_quotations ALTER COLUMN audit_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME audit.quotation__supplier_quotations_audit_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 267 (class 1259 OID 18022)
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
-- TOC entry 7312 (class 0 OID 0)
-- Dependencies: 267
-- Name: TABLE brands; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON TABLE catalogs.brands IS 'Marca ou fabricante do produto';


--
-- TOC entry 7313 (class 0 OID 0)
-- Dependencies: 267
-- Name: COLUMN brands.brand_id; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.brands.brand_id IS 'Identificador único da marca';


--
-- TOC entry 7314 (class 0 OID 0)
-- Dependencies: 267
-- Name: COLUMN brands.name; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.brands.name IS 'Nome da marca';


--
-- TOC entry 7315 (class 0 OID 0)
-- Dependencies: 267
-- Name: COLUMN brands.created_at; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.brands.created_at IS 'Data de criação do registro';


--
-- TOC entry 7316 (class 0 OID 0)
-- Dependencies: 267
-- Name: COLUMN brands.updated_at; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.brands.updated_at IS 'Data da última atualização do registro';


--
-- TOC entry 258 (class 1259 OID 17916)
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
-- TOC entry 7317 (class 0 OID 0)
-- Dependencies: 258
-- Name: TABLE categories; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON TABLE catalogs.categories IS 'Categorias amplas para agrupamento dos produtos';


--
-- TOC entry 7318 (class 0 OID 0)
-- Dependencies: 258
-- Name: COLUMN categories.category_id; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.categories.category_id IS 'Identificador único da categoria';


--
-- TOC entry 7319 (class 0 OID 0)
-- Dependencies: 258
-- Name: COLUMN categories.name; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.categories.name IS 'Nome da categoria';


--
-- TOC entry 7320 (class 0 OID 0)
-- Dependencies: 258
-- Name: COLUMN categories.description; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.categories.description IS 'Descrição da categoria';


--
-- TOC entry 7321 (class 0 OID 0)
-- Dependencies: 258
-- Name: COLUMN categories.created_at; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.categories.created_at IS 'Data de criação do registro';


--
-- TOC entry 7322 (class 0 OID 0)
-- Dependencies: 258
-- Name: COLUMN categories.updated_at; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.categories.updated_at IS 'Data da última atualização do registro';


--
-- TOC entry 261 (class 1259 OID 17956)
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
-- TOC entry 7323 (class 0 OID 0)
-- Dependencies: 261
-- Name: TABLE compositions; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON TABLE catalogs.compositions IS 'Composição ou matéria-prima do produto (ex: Grano Duro)';


--
-- TOC entry 7324 (class 0 OID 0)
-- Dependencies: 261
-- Name: COLUMN compositions.composition_id; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.compositions.composition_id IS 'Identificador único da composição';


--
-- TOC entry 7325 (class 0 OID 0)
-- Dependencies: 261
-- Name: COLUMN compositions.name; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.compositions.name IS 'Nome da composição';


--
-- TOC entry 7326 (class 0 OID 0)
-- Dependencies: 261
-- Name: COLUMN compositions.description; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.compositions.description IS 'Descrição da composição';


--
-- TOC entry 7327 (class 0 OID 0)
-- Dependencies: 261
-- Name: COLUMN compositions.created_at; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.compositions.created_at IS 'Data de criação do registro';


--
-- TOC entry 7328 (class 0 OID 0)
-- Dependencies: 261
-- Name: COLUMN compositions.updated_at; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.compositions.updated_at IS 'Data da última atualização do registro';


--
-- TOC entry 265 (class 1259 OID 18000)
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
-- TOC entry 7329 (class 0 OID 0)
-- Dependencies: 265
-- Name: TABLE fillings; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON TABLE catalogs.fillings IS 'Recheio principal do produto (ex: Morango, Baunilha)';


--
-- TOC entry 7330 (class 0 OID 0)
-- Dependencies: 265
-- Name: COLUMN fillings.filling_id; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.fillings.filling_id IS 'Identificador único do recheio';


--
-- TOC entry 7331 (class 0 OID 0)
-- Dependencies: 265
-- Name: COLUMN fillings.name; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.fillings.name IS 'Nome do recheio';


--
-- TOC entry 7332 (class 0 OID 0)
-- Dependencies: 265
-- Name: COLUMN fillings.description; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.fillings.description IS 'Descrição do recheio';


--
-- TOC entry 7333 (class 0 OID 0)
-- Dependencies: 265
-- Name: COLUMN fillings.created_at; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.fillings.created_at IS 'Data de criação do registro';


--
-- TOC entry 7334 (class 0 OID 0)
-- Dependencies: 265
-- Name: COLUMN fillings.updated_at; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.fillings.updated_at IS 'Data da última atualização do registro';


--
-- TOC entry 264 (class 1259 OID 17989)
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
-- TOC entry 7335 (class 0 OID 0)
-- Dependencies: 264
-- Name: TABLE flavors; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON TABLE catalogs.flavors IS 'Perfil de sabor ou tempero (ex: Picante, Galinha Caipira)';


--
-- TOC entry 7336 (class 0 OID 0)
-- Dependencies: 264
-- Name: COLUMN flavors.flavor_id; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.flavors.flavor_id IS 'Identificador único do sabor';


--
-- TOC entry 7337 (class 0 OID 0)
-- Dependencies: 264
-- Name: COLUMN flavors.name; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.flavors.name IS 'Nome do sabor';


--
-- TOC entry 7338 (class 0 OID 0)
-- Dependencies: 264
-- Name: COLUMN flavors.description; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.flavors.description IS 'Descrição do sabor';


--
-- TOC entry 7339 (class 0 OID 0)
-- Dependencies: 264
-- Name: COLUMN flavors.created_at; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.flavors.created_at IS 'Data de criação do registro';


--
-- TOC entry 7340 (class 0 OID 0)
-- Dependencies: 264
-- Name: COLUMN flavors.updated_at; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.flavors.updated_at IS 'Data da última atualização do registro';


--
-- TOC entry 263 (class 1259 OID 17978)
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
-- TOC entry 7341 (class 0 OID 0)
-- Dependencies: 263
-- Name: TABLE formats; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON TABLE catalogs.formats IS 'Formato físico de apresentação (ex: Fatiada, Bolinha)';


--
-- TOC entry 7342 (class 0 OID 0)
-- Dependencies: 263
-- Name: COLUMN formats.format_id; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.formats.format_id IS 'Identificador único do formato';


--
-- TOC entry 7343 (class 0 OID 0)
-- Dependencies: 263
-- Name: COLUMN formats.name; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.formats.name IS 'Nome do formato';


--
-- TOC entry 7344 (class 0 OID 0)
-- Dependencies: 263
-- Name: COLUMN formats.description; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.formats.description IS 'Descrição do formato';


--
-- TOC entry 7345 (class 0 OID 0)
-- Dependencies: 263
-- Name: COLUMN formats.created_at; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.formats.created_at IS 'Data de criação do registro';


--
-- TOC entry 7346 (class 0 OID 0)
-- Dependencies: 263
-- Name: COLUMN formats.updated_at; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.formats.updated_at IS 'Data da última atualização do registro';


--
-- TOC entry 260 (class 1259 OID 17941)
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
-- TOC entry 7347 (class 0 OID 0)
-- Dependencies: 260
-- Name: TABLE items; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON TABLE catalogs.items IS 'Itens genéricos que representam o núcleo de um produto';


--
-- TOC entry 7348 (class 0 OID 0)
-- Dependencies: 260
-- Name: COLUMN items.item_id; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.items.item_id IS 'Identificador único do item';


--
-- TOC entry 7349 (class 0 OID 0)
-- Dependencies: 260
-- Name: COLUMN items.subcategory_id; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.items.subcategory_id IS 'Subcategoria à qual este item pertence';


--
-- TOC entry 7350 (class 0 OID 0)
-- Dependencies: 260
-- Name: COLUMN items.name; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.items.name IS 'Nome genérico do item';


--
-- TOC entry 7351 (class 0 OID 0)
-- Dependencies: 260
-- Name: COLUMN items.description; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.items.description IS 'Descrição do item';


--
-- TOC entry 7352 (class 0 OID 0)
-- Dependencies: 260
-- Name: COLUMN items.created_at; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.items.created_at IS 'Data de criação do registro';


--
-- TOC entry 7353 (class 0 OID 0)
-- Dependencies: 260
-- Name: COLUMN items.updated_at; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.items.updated_at IS 'Data da última atualização do registro';


--
-- TOC entry 266 (class 1259 OID 18011)
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
-- TOC entry 7354 (class 0 OID 0)
-- Dependencies: 266
-- Name: TABLE nutritional_variants; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON TABLE catalogs.nutritional_variants IS 'Variações nutricionais (ex: Light, Zero, Sem Lactose)';


--
-- TOC entry 7355 (class 0 OID 0)
-- Dependencies: 266
-- Name: COLUMN nutritional_variants.nutritional_variant_id; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.nutritional_variants.nutritional_variant_id IS 'Identificador único da variação';


--
-- TOC entry 7356 (class 0 OID 0)
-- Dependencies: 266
-- Name: COLUMN nutritional_variants.name; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.nutritional_variants.name IS 'Nome da variação nutricional';


--
-- TOC entry 7357 (class 0 OID 0)
-- Dependencies: 266
-- Name: COLUMN nutritional_variants.description; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.nutritional_variants.description IS 'Descrição da variação nutricional';


--
-- TOC entry 7358 (class 0 OID 0)
-- Dependencies: 266
-- Name: COLUMN nutritional_variants.created_at; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.nutritional_variants.created_at IS 'Data de criação do registro';


--
-- TOC entry 7359 (class 0 OID 0)
-- Dependencies: 266
-- Name: COLUMN nutritional_variants.updated_at; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.nutritional_variants.updated_at IS 'Data da última atualização do registro';


--
-- TOC entry 271 (class 1259 OID 18113)
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
-- TOC entry 7360 (class 0 OID 0)
-- Dependencies: 271
-- Name: TABLE offers; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON TABLE catalogs.offers IS 'Oferta de um produto específico por um fornecedor com condições comerciais';


--
-- TOC entry 7361 (class 0 OID 0)
-- Dependencies: 271
-- Name: COLUMN offers.offer_id; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.offers.offer_id IS 'Identificador único da oferta';


--
-- TOC entry 7362 (class 0 OID 0)
-- Dependencies: 271
-- Name: COLUMN offers.product_id; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.offers.product_id IS 'Produto ofertado';


--
-- TOC entry 7363 (class 0 OID 0)
-- Dependencies: 271
-- Name: COLUMN offers.supplier_id; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.offers.supplier_id IS 'Fornecedor que oferta o produto';


--
-- TOC entry 7364 (class 0 OID 0)
-- Dependencies: 271
-- Name: COLUMN offers.price; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.offers.price IS 'Preço da oferta';


--
-- TOC entry 7365 (class 0 OID 0)
-- Dependencies: 271
-- Name: COLUMN offers.available_from; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.offers.available_from IS 'Data de início da disponibilidade da oferta';


--
-- TOC entry 7366 (class 0 OID 0)
-- Dependencies: 271
-- Name: COLUMN offers.available_until; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.offers.available_until IS 'Data de término da disponibilidade da oferta (opcional)';


--
-- TOC entry 7367 (class 0 OID 0)
-- Dependencies: 271
-- Name: COLUMN offers.is_active; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.offers.is_active IS 'Indica se a oferta está ativa';


--
-- TOC entry 7368 (class 0 OID 0)
-- Dependencies: 271
-- Name: COLUMN offers.created_at; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.offers.created_at IS 'Data de criação do registro';


--
-- TOC entry 7369 (class 0 OID 0)
-- Dependencies: 271
-- Name: COLUMN offers.updated_at; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.offers.updated_at IS 'Data da última atualização do registro';


--
-- TOC entry 268 (class 1259 OID 18033)
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
-- TOC entry 7370 (class 0 OID 0)
-- Dependencies: 268
-- Name: TABLE packagings; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON TABLE catalogs.packagings IS 'Tipo de embalagem do produto (ex: Caixa, Lata, Pacote)';


--
-- TOC entry 7371 (class 0 OID 0)
-- Dependencies: 268
-- Name: COLUMN packagings.packaging_id; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.packagings.packaging_id IS 'Identificador único da embalagem';


--
-- TOC entry 7372 (class 0 OID 0)
-- Dependencies: 268
-- Name: COLUMN packagings.name; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.packagings.name IS 'Nome do tipo de embalagem';


--
-- TOC entry 7373 (class 0 OID 0)
-- Dependencies: 268
-- Name: COLUMN packagings.description; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.packagings.description IS 'Descrição da embalagem';


--
-- TOC entry 7374 (class 0 OID 0)
-- Dependencies: 268
-- Name: COLUMN packagings.created_at; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.packagings.created_at IS 'Data de criação do registro';


--
-- TOC entry 7375 (class 0 OID 0)
-- Dependencies: 268
-- Name: COLUMN packagings.updated_at; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.packagings.updated_at IS 'Data da última atualização do registro';


--
-- TOC entry 270 (class 1259 OID 18053)
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
-- TOC entry 7376 (class 0 OID 0)
-- Dependencies: 270
-- Name: TABLE products; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON TABLE catalogs.products IS 'Produto padronizado resultante da combinação de um item com suas variações e atributos dimensionais';


--
-- TOC entry 7377 (class 0 OID 0)
-- Dependencies: 270
-- Name: COLUMN products.product_id; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.products.product_id IS 'Identificador único do produto';


--
-- TOC entry 7378 (class 0 OID 0)
-- Dependencies: 270
-- Name: COLUMN products.item_id; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.products.item_id IS 'FK para o item base deste produto';


--
-- TOC entry 7379 (class 0 OID 0)
-- Dependencies: 270
-- Name: COLUMN products.composition_id; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.products.composition_id IS 'FK para a composição (matéria-prima)';


--
-- TOC entry 7380 (class 0 OID 0)
-- Dependencies: 270
-- Name: COLUMN products.variant_type_id; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.products.variant_type_id IS 'FK para o tipo de variação';


--
-- TOC entry 7381 (class 0 OID 0)
-- Dependencies: 270
-- Name: COLUMN products.format_id; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.products.format_id IS 'FK para o formato físico';


--
-- TOC entry 7382 (class 0 OID 0)
-- Dependencies: 270
-- Name: COLUMN products.flavor_id; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.products.flavor_id IS 'FK para o sabor';


--
-- TOC entry 7383 (class 0 OID 0)
-- Dependencies: 270
-- Name: COLUMN products.filling_id; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.products.filling_id IS 'FK para o recheio';


--
-- TOC entry 7384 (class 0 OID 0)
-- Dependencies: 270
-- Name: COLUMN products.nutritional_variant_id; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.products.nutritional_variant_id IS 'FK para a variação nutricional';


--
-- TOC entry 7385 (class 0 OID 0)
-- Dependencies: 270
-- Name: COLUMN products.brand_id; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.products.brand_id IS 'FK para a marca';


--
-- TOC entry 7386 (class 0 OID 0)
-- Dependencies: 270
-- Name: COLUMN products.packaging_id; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.products.packaging_id IS 'FK para a embalagem';


--
-- TOC entry 7387 (class 0 OID 0)
-- Dependencies: 270
-- Name: COLUMN products.quantity_id; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.products.quantity_id IS 'FK para a quantidade';


--
-- TOC entry 7388 (class 0 OID 0)
-- Dependencies: 270
-- Name: COLUMN products.visibility; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.products.visibility IS 'Define se o produto é público ou privado';


--
-- TOC entry 7389 (class 0 OID 0)
-- Dependencies: 270
-- Name: COLUMN products.created_at; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.products.created_at IS 'Data de criação do registro';


--
-- TOC entry 7390 (class 0 OID 0)
-- Dependencies: 270
-- Name: COLUMN products.updated_at; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.products.updated_at IS 'Data da última atualização do registro';


--
-- TOC entry 269 (class 1259 OID 18044)
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
-- TOC entry 7391 (class 0 OID 0)
-- Dependencies: 269
-- Name: TABLE quantities; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON TABLE catalogs.quantities IS 'Quantidade ou medida do produto (ex: 500g, 12 unidades)';


--
-- TOC entry 7392 (class 0 OID 0)
-- Dependencies: 269
-- Name: COLUMN quantities.quantity_id; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.quantities.quantity_id IS 'Identificador único da quantidade';


--
-- TOC entry 7393 (class 0 OID 0)
-- Dependencies: 269
-- Name: COLUMN quantities.unit; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.quantities.unit IS 'Unidade de medida (ex: g, ml, un)';


--
-- TOC entry 7394 (class 0 OID 0)
-- Dependencies: 269
-- Name: COLUMN quantities.value; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.quantities.value IS 'Valor numérico da unidade';


--
-- TOC entry 7395 (class 0 OID 0)
-- Dependencies: 269
-- Name: COLUMN quantities.display_name; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.quantities.display_name IS 'Nome formatado para exibição';


--
-- TOC entry 7396 (class 0 OID 0)
-- Dependencies: 269
-- Name: COLUMN quantities.created_at; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.quantities.created_at IS 'Data de criação do registro';


--
-- TOC entry 7397 (class 0 OID 0)
-- Dependencies: 269
-- Name: COLUMN quantities.updated_at; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.quantities.updated_at IS 'Data da última atualização do registro';


--
-- TOC entry 259 (class 1259 OID 17927)
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
-- TOC entry 7398 (class 0 OID 0)
-- Dependencies: 259
-- Name: TABLE subcategories; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON TABLE catalogs.subcategories IS 'Subcategorias específicas dentro de uma categoria principal';


--
-- TOC entry 7399 (class 0 OID 0)
-- Dependencies: 259
-- Name: COLUMN subcategories.subcategory_id; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.subcategories.subcategory_id IS 'Identificador único da subcategoria';


--
-- TOC entry 7400 (class 0 OID 0)
-- Dependencies: 259
-- Name: COLUMN subcategories.category_id; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.subcategories.category_id IS 'Categoria à qual esta subcategoria pertence';


--
-- TOC entry 7401 (class 0 OID 0)
-- Dependencies: 259
-- Name: COLUMN subcategories.name; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.subcategories.name IS 'Nome da subcategoria';


--
-- TOC entry 7402 (class 0 OID 0)
-- Dependencies: 259
-- Name: COLUMN subcategories.description; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.subcategories.description IS 'Descrição da subcategoria';


--
-- TOC entry 7403 (class 0 OID 0)
-- Dependencies: 259
-- Name: COLUMN subcategories.created_at; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.subcategories.created_at IS 'Data de criação do registro';


--
-- TOC entry 7404 (class 0 OID 0)
-- Dependencies: 259
-- Name: COLUMN subcategories.updated_at; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.subcategories.updated_at IS 'Data da última atualização do registro';


--
-- TOC entry 262 (class 1259 OID 17967)
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
-- TOC entry 7405 (class 0 OID 0)
-- Dependencies: 262
-- Name: TABLE variant_types; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON TABLE catalogs.variant_types IS 'Tipo ou variação específica do item (ex: Espaguete nº 08)';


--
-- TOC entry 7406 (class 0 OID 0)
-- Dependencies: 262
-- Name: COLUMN variant_types.variant_type_id; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.variant_types.variant_type_id IS 'Identificador único do tipo';


--
-- TOC entry 7407 (class 0 OID 0)
-- Dependencies: 262
-- Name: COLUMN variant_types.name; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.variant_types.name IS 'Nome do tipo de variação';


--
-- TOC entry 7408 (class 0 OID 0)
-- Dependencies: 262
-- Name: COLUMN variant_types.description; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.variant_types.description IS 'Descrição do tipo de variação';


--
-- TOC entry 7409 (class 0 OID 0)
-- Dependencies: 262
-- Name: COLUMN variant_types.created_at; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.variant_types.created_at IS 'Data de criação do registro';


--
-- TOC entry 7410 (class 0 OID 0)
-- Dependencies: 262
-- Name: COLUMN variant_types.updated_at; Type: COMMENT; Schema: catalogs; Owner: postgres
--

COMMENT ON COLUMN catalogs.variant_types.updated_at IS 'Data da última atualização do registro';


--
-- TOC entry 373 (class 1259 OID 21376)
-- Name: quotation_submissions; Type: TABLE; Schema: quotation; Owner: postgres
--

CREATE TABLE quotation.quotation_submissions (
    quotation_submission_id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    shopping_list_id uuid NOT NULL,
    submission_status_id uuid NOT NULL,
    submission_date timestamp with time zone DEFAULT now(),
    total_items integer DEFAULT 0,
    notes text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE quotation.quotation_submissions OWNER TO postgres;

--
-- TOC entry 7411 (class 0 OID 0)
-- Dependencies: 373
-- Name: TABLE quotation_submissions; Type: COMMENT; Schema: quotation; Owner: postgres
--

COMMENT ON TABLE quotation.quotation_submissions IS 'Submissões de cotação quando as listas de compras são enviadas';


--
-- TOC entry 7412 (class 0 OID 0)
-- Dependencies: 373
-- Name: COLUMN quotation_submissions.quotation_submission_id; Type: COMMENT; Schema: quotation; Owner: postgres
--

COMMENT ON COLUMN quotation.quotation_submissions.quotation_submission_id IS 'Identificador único da submissão de cotação';


--
-- TOC entry 7413 (class 0 OID 0)
-- Dependencies: 373
-- Name: COLUMN quotation_submissions.shopping_list_id; Type: COMMENT; Schema: quotation; Owner: postgres
--

COMMENT ON COLUMN quotation.quotation_submissions.shopping_list_id IS 'Referência para a lista de compras';


--
-- TOC entry 7414 (class 0 OID 0)
-- Dependencies: 373
-- Name: COLUMN quotation_submissions.submission_status_id; Type: COMMENT; Schema: quotation; Owner: postgres
--

COMMENT ON COLUMN quotation.quotation_submissions.submission_status_id IS 'Referência para o status da submissão';


--
-- TOC entry 7415 (class 0 OID 0)
-- Dependencies: 373
-- Name: COLUMN quotation_submissions.submission_date; Type: COMMENT; Schema: quotation; Owner: postgres
--

COMMENT ON COLUMN quotation.quotation_submissions.submission_date IS 'Data de submissão da cotação';


--
-- TOC entry 7416 (class 0 OID 0)
-- Dependencies: 373
-- Name: COLUMN quotation_submissions.total_items; Type: COMMENT; Schema: quotation; Owner: postgres
--

COMMENT ON COLUMN quotation.quotation_submissions.total_items IS 'Total de itens na submissão (calculado automaticamente)';


--
-- TOC entry 7417 (class 0 OID 0)
-- Dependencies: 373
-- Name: COLUMN quotation_submissions.notes; Type: COMMENT; Schema: quotation; Owner: postgres
--

COMMENT ON COLUMN quotation.quotation_submissions.notes IS 'Observações sobre a submissão';


--
-- TOC entry 375 (class 1259 OID 21399)
-- Name: quoted_prices; Type: TABLE; Schema: quotation; Owner: postgres
--

CREATE TABLE quotation.quoted_prices (
    quoted_price_id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    supplier_quotation_id uuid NOT NULL,
    quantity_from numeric(10,3) NOT NULL,
    quantity_to numeric(10,3),
    unit_price numeric(10,2) NOT NULL,
    total_price numeric(10,2) NOT NULL,
    currency character varying(3) DEFAULT 'BRL'::character varying,
    delivery_time_days integer,
    minimum_order_quantity numeric(10,3),
    payment_terms character varying(100),
    validity_days integer DEFAULT 30,
    special_conditions text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE quotation.quoted_prices OWNER TO postgres;

--
-- TOC entry 7418 (class 0 OID 0)
-- Dependencies: 375
-- Name: TABLE quoted_prices; Type: COMMENT; Schema: quotation; Owner: postgres
--

COMMENT ON TABLE quotation.quoted_prices IS 'Preços cotados pelos fornecedores com condições comerciais';


--
-- TOC entry 7419 (class 0 OID 0)
-- Dependencies: 375
-- Name: COLUMN quoted_prices.quoted_price_id; Type: COMMENT; Schema: quotation; Owner: postgres
--

COMMENT ON COLUMN quotation.quoted_prices.quoted_price_id IS 'Identificador único do preço cotado';


--
-- TOC entry 7420 (class 0 OID 0)
-- Dependencies: 375
-- Name: COLUMN quoted_prices.supplier_quotation_id; Type: COMMENT; Schema: quotation; Owner: postgres
--

COMMENT ON COLUMN quotation.quoted_prices.supplier_quotation_id IS 'Referência para a cotação do fornecedor';


--
-- TOC entry 7421 (class 0 OID 0)
-- Dependencies: 375
-- Name: COLUMN quoted_prices.quantity_from; Type: COMMENT; Schema: quotation; Owner: postgres
--

COMMENT ON COLUMN quotation.quoted_prices.quantity_from IS 'Quantidade mínima para este preço';


--
-- TOC entry 7422 (class 0 OID 0)
-- Dependencies: 375
-- Name: COLUMN quoted_prices.quantity_to; Type: COMMENT; Schema: quotation; Owner: postgres
--

COMMENT ON COLUMN quotation.quoted_prices.quantity_to IS 'Quantidade máxima para este preço (NULL = ilimitado)';


--
-- TOC entry 7423 (class 0 OID 0)
-- Dependencies: 375
-- Name: COLUMN quoted_prices.unit_price; Type: COMMENT; Schema: quotation; Owner: postgres
--

COMMENT ON COLUMN quotation.quoted_prices.unit_price IS 'Preço unitário';


--
-- TOC entry 7424 (class 0 OID 0)
-- Dependencies: 375
-- Name: COLUMN quoted_prices.total_price; Type: COMMENT; Schema: quotation; Owner: postgres
--

COMMENT ON COLUMN quotation.quoted_prices.total_price IS 'Preço total para a quantidade';


--
-- TOC entry 7425 (class 0 OID 0)
-- Dependencies: 375
-- Name: COLUMN quoted_prices.currency; Type: COMMENT; Schema: quotation; Owner: postgres
--

COMMENT ON COLUMN quotation.quoted_prices.currency IS 'Moeda da cotação';


--
-- TOC entry 7426 (class 0 OID 0)
-- Dependencies: 375
-- Name: COLUMN quoted_prices.delivery_time_days; Type: COMMENT; Schema: quotation; Owner: postgres
--

COMMENT ON COLUMN quotation.quoted_prices.delivery_time_days IS 'Prazo de entrega em dias';


--
-- TOC entry 7427 (class 0 OID 0)
-- Dependencies: 375
-- Name: COLUMN quoted_prices.minimum_order_quantity; Type: COMMENT; Schema: quotation; Owner: postgres
--

COMMENT ON COLUMN quotation.quoted_prices.minimum_order_quantity IS 'Quantidade mínima para pedido';


--
-- TOC entry 7428 (class 0 OID 0)
-- Dependencies: 375
-- Name: COLUMN quoted_prices.payment_terms; Type: COMMENT; Schema: quotation; Owner: postgres
--

COMMENT ON COLUMN quotation.quoted_prices.payment_terms IS 'Condições de pagamento';


--
-- TOC entry 7429 (class 0 OID 0)
-- Dependencies: 375
-- Name: COLUMN quoted_prices.validity_days; Type: COMMENT; Schema: quotation; Owner: postgres
--

COMMENT ON COLUMN quotation.quoted_prices.validity_days IS 'Validade da cotação em dias';


--
-- TOC entry 7430 (class 0 OID 0)
-- Dependencies: 375
-- Name: COLUMN quoted_prices.special_conditions; Type: COMMENT; Schema: quotation; Owner: postgres
--

COMMENT ON COLUMN quotation.quoted_prices.special_conditions IS 'Condições especiais';


--
-- TOC entry 372 (class 1259 OID 21366)
-- Name: shopping_list_items; Type: TABLE; Schema: quotation; Owner: postgres
--

CREATE TABLE quotation.shopping_list_items (
    shopping_list_item_id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    shopping_list_id uuid NOT NULL,
    item_id uuid NOT NULL,
    product_id uuid,
    composition_id uuid,
    variant_type_id uuid,
    format_id uuid,
    flavor_id uuid,
    filling_id uuid,
    nutritional_variant_id uuid,
    brand_id uuid,
    packaging_id uuid,
    quantity_id uuid,
    term character varying(255) NOT NULL,
    quantity numeric(10,3) NOT NULL,
    notes text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE quotation.shopping_list_items OWNER TO postgres;

--
-- TOC entry 7431 (class 0 OID 0)
-- Dependencies: 372
-- Name: TABLE shopping_list_items; Type: COMMENT; Schema: quotation; Owner: postgres
--

COMMENT ON TABLE quotation.shopping_list_items IS 'Itens dentro das listas de compras com decomposição completa para busca refinada';


--
-- TOC entry 7432 (class 0 OID 0)
-- Dependencies: 372
-- Name: COLUMN shopping_list_items.shopping_list_item_id; Type: COMMENT; Schema: quotation; Owner: postgres
--

COMMENT ON COLUMN quotation.shopping_list_items.shopping_list_item_id IS 'Identificador único do item da lista de compras';


--
-- TOC entry 7433 (class 0 OID 0)
-- Dependencies: 372
-- Name: COLUMN shopping_list_items.shopping_list_id; Type: COMMENT; Schema: quotation; Owner: postgres
--

COMMENT ON COLUMN quotation.shopping_list_items.shopping_list_id IS 'Referência para a lista de compras';


--
-- TOC entry 7434 (class 0 OID 0)
-- Dependencies: 372
-- Name: COLUMN shopping_list_items.item_id; Type: COMMENT; Schema: quotation; Owner: postgres
--

COMMENT ON COLUMN quotation.shopping_list_items.item_id IS 'Referência para catalog.items (item genérico - OBRIGATÓRIO)';


--
-- TOC entry 7435 (class 0 OID 0)
-- Dependencies: 372
-- Name: COLUMN shopping_list_items.product_id; Type: COMMENT; Schema: quotation; Owner: postgres
--

COMMENT ON COLUMN quotation.shopping_list_items.product_id IS 'Referência para catalog.products (produto específico se encontrado)';


--
-- TOC entry 7436 (class 0 OID 0)
-- Dependencies: 372
-- Name: COLUMN shopping_list_items.composition_id; Type: COMMENT; Schema: quotation; Owner: postgres
--

COMMENT ON COLUMN quotation.shopping_list_items.composition_id IS 'Referência para catalog.compositions (composição do produto)';


--
-- TOC entry 7437 (class 0 OID 0)
-- Dependencies: 372
-- Name: COLUMN shopping_list_items.variant_type_id; Type: COMMENT; Schema: quotation; Owner: postgres
--

COMMENT ON COLUMN quotation.shopping_list_items.variant_type_id IS 'Referência para catalog.variant_types (tipo de variante)';


--
-- TOC entry 7438 (class 0 OID 0)
-- Dependencies: 372
-- Name: COLUMN shopping_list_items.format_id; Type: COMMENT; Schema: quotation; Owner: postgres
--

COMMENT ON COLUMN quotation.shopping_list_items.format_id IS 'Referência para catalog.formats (formato do produto)';


--
-- TOC entry 7439 (class 0 OID 0)
-- Dependencies: 372
-- Name: COLUMN shopping_list_items.flavor_id; Type: COMMENT; Schema: quotation; Owner: postgres
--

COMMENT ON COLUMN quotation.shopping_list_items.flavor_id IS 'Referência para catalog.flavors (sabor do produto)';


--
-- TOC entry 7440 (class 0 OID 0)
-- Dependencies: 372
-- Name: COLUMN shopping_list_items.filling_id; Type: COMMENT; Schema: quotation; Owner: postgres
--

COMMENT ON COLUMN quotation.shopping_list_items.filling_id IS 'Referência para catalog.fillings (recheio do produto)';


--
-- TOC entry 7441 (class 0 OID 0)
-- Dependencies: 372
-- Name: COLUMN shopping_list_items.nutritional_variant_id; Type: COMMENT; Schema: quotation; Owner: postgres
--

COMMENT ON COLUMN quotation.shopping_list_items.nutritional_variant_id IS 'Referência para catalog.nutritional_variants (variante nutricional)';


--
-- TOC entry 7442 (class 0 OID 0)
-- Dependencies: 372
-- Name: COLUMN shopping_list_items.brand_id; Type: COMMENT; Schema: quotation; Owner: postgres
--

COMMENT ON COLUMN quotation.shopping_list_items.brand_id IS 'Referência para catalog.brands (marca do produto)';


--
-- TOC entry 7443 (class 0 OID 0)
-- Dependencies: 372
-- Name: COLUMN shopping_list_items.packaging_id; Type: COMMENT; Schema: quotation; Owner: postgres
--

COMMENT ON COLUMN quotation.shopping_list_items.packaging_id IS 'Referência para catalog.packagings (embalagem do produto)';


--
-- TOC entry 7444 (class 0 OID 0)
-- Dependencies: 372
-- Name: COLUMN shopping_list_items.quantity_id; Type: COMMENT; Schema: quotation; Owner: postgres
--

COMMENT ON COLUMN quotation.shopping_list_items.quantity_id IS 'Referência para catalog.quantities (quantidade/medida)';


--
-- TOC entry 7445 (class 0 OID 0)
-- Dependencies: 372
-- Name: COLUMN shopping_list_items.term; Type: COMMENT; Schema: quotation; Owner: postgres
--

COMMENT ON COLUMN quotation.shopping_list_items.term IS 'Termo original digitado pelo usuário para busca';


--
-- TOC entry 7446 (class 0 OID 0)
-- Dependencies: 372
-- Name: COLUMN shopping_list_items.quantity; Type: COMMENT; Schema: quotation; Owner: postgres
--

COMMENT ON COLUMN quotation.shopping_list_items.quantity IS 'Quantidade solicitada';


--
-- TOC entry 7447 (class 0 OID 0)
-- Dependencies: 372
-- Name: COLUMN shopping_list_items.notes; Type: COMMENT; Schema: quotation; Owner: postgres
--

COMMENT ON COLUMN quotation.shopping_list_items.notes IS 'Observações sobre o item';


--
-- TOC entry 371 (class 1259 OID 21356)
-- Name: shopping_lists; Type: TABLE; Schema: quotation; Owner: postgres
--

CREATE TABLE quotation.shopping_lists (
    shopping_list_id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    establishment_id uuid NOT NULL,
    employee_id uuid NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE quotation.shopping_lists OWNER TO postgres;

--
-- TOC entry 7448 (class 0 OID 0)
-- Dependencies: 371
-- Name: TABLE shopping_lists; Type: COMMENT; Schema: quotation; Owner: postgres
--

COMMENT ON TABLE quotation.shopping_lists IS 'Listas de compras criadas pelos estabelecimentos';


--
-- TOC entry 7449 (class 0 OID 0)
-- Dependencies: 371
-- Name: COLUMN shopping_lists.shopping_list_id; Type: COMMENT; Schema: quotation; Owner: postgres
--

COMMENT ON COLUMN quotation.shopping_lists.shopping_list_id IS 'Identificador único da lista de compras';


--
-- TOC entry 7450 (class 0 OID 0)
-- Dependencies: 371
-- Name: COLUMN shopping_lists.establishment_id; Type: COMMENT; Schema: quotation; Owner: postgres
--

COMMENT ON COLUMN quotation.shopping_lists.establishment_id IS 'Referência para accounts.establishments';


--
-- TOC entry 7451 (class 0 OID 0)
-- Dependencies: 371
-- Name: COLUMN shopping_lists.employee_id; Type: COMMENT; Schema: quotation; Owner: postgres
--

COMMENT ON COLUMN quotation.shopping_lists.employee_id IS 'Referência para accounts.employees (usuário que criou a lista)';


--
-- TOC entry 7452 (class 0 OID 0)
-- Dependencies: 371
-- Name: COLUMN shopping_lists.name; Type: COMMENT; Schema: quotation; Owner: postgres
--

COMMENT ON COLUMN quotation.shopping_lists.name IS 'Nome da lista de compras';


--
-- TOC entry 7453 (class 0 OID 0)
-- Dependencies: 371
-- Name: COLUMN shopping_lists.description; Type: COMMENT; Schema: quotation; Owner: postgres
--

COMMENT ON COLUMN quotation.shopping_lists.description IS 'Descrição da lista de compras';


--
-- TOC entry 7454 (class 0 OID 0)
-- Dependencies: 371
-- Name: COLUMN shopping_lists.created_at; Type: COMMENT; Schema: quotation; Owner: postgres
--

COMMENT ON COLUMN quotation.shopping_lists.created_at IS 'Data de criação do registro';


--
-- TOC entry 7455 (class 0 OID 0)
-- Dependencies: 371
-- Name: COLUMN shopping_lists.updated_at; Type: COMMENT; Schema: quotation; Owner: postgres
--

COMMENT ON COLUMN quotation.shopping_lists.updated_at IS 'Data da última atualização do registro';


--
-- TOC entry 369 (class 1259 OID 21330)
-- Name: submission_statuses; Type: TABLE; Schema: quotation; Owner: postgres
--

CREATE TABLE quotation.submission_statuses (
    submission_status_id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(50) NOT NULL,
    description text,
    color character varying(7),
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE quotation.submission_statuses OWNER TO postgres;

--
-- TOC entry 7456 (class 0 OID 0)
-- Dependencies: 369
-- Name: TABLE submission_statuses; Type: COMMENT; Schema: quotation; Owner: postgres
--

COMMENT ON TABLE quotation.submission_statuses IS 'Status das submissões de cotação (controle interno do sistema)';


--
-- TOC entry 7457 (class 0 OID 0)
-- Dependencies: 369
-- Name: COLUMN submission_statuses.submission_status_id; Type: COMMENT; Schema: quotation; Owner: postgres
--

COMMENT ON COLUMN quotation.submission_statuses.submission_status_id IS 'Identificador único do status de submissão';


--
-- TOC entry 7458 (class 0 OID 0)
-- Dependencies: 369
-- Name: COLUMN submission_statuses.name; Type: COMMENT; Schema: quotation; Owner: postgres
--

COMMENT ON COLUMN quotation.submission_statuses.name IS 'Nome do status (ex: pending, sent, completed)';


--
-- TOC entry 7459 (class 0 OID 0)
-- Dependencies: 369
-- Name: COLUMN submission_statuses.description; Type: COMMENT; Schema: quotation; Owner: postgres
--

COMMENT ON COLUMN quotation.submission_statuses.description IS 'Descrição detalhada do status';


--
-- TOC entry 7460 (class 0 OID 0)
-- Dependencies: 369
-- Name: COLUMN submission_statuses.color; Type: COMMENT; Schema: quotation; Owner: postgres
--

COMMENT ON COLUMN quotation.submission_statuses.color IS 'Código de cor hexadecimal para interface';


--
-- TOC entry 7461 (class 0 OID 0)
-- Dependencies: 369
-- Name: COLUMN submission_statuses.is_active; Type: COMMENT; Schema: quotation; Owner: postgres
--

COMMENT ON COLUMN quotation.submission_statuses.is_active IS 'Indica se o status está ativo para uso';


--
-- TOC entry 370 (class 1259 OID 21343)
-- Name: supplier_quotation_statuses; Type: TABLE; Schema: quotation; Owner: postgres
--

CREATE TABLE quotation.supplier_quotation_statuses (
    quotation_status_id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(100) NOT NULL,
    description text,
    color character varying(7),
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE quotation.supplier_quotation_statuses OWNER TO postgres;

--
-- TOC entry 7462 (class 0 OID 0)
-- Dependencies: 370
-- Name: TABLE supplier_quotation_statuses; Type: COMMENT; Schema: quotation; Owner: postgres
--

COMMENT ON TABLE quotation.supplier_quotation_statuses IS 'Status das cotações recebidas dos fornecedores';


--
-- TOC entry 7463 (class 0 OID 0)
-- Dependencies: 370
-- Name: COLUMN supplier_quotation_statuses.quotation_status_id; Type: COMMENT; Schema: quotation; Owner: postgres
--

COMMENT ON COLUMN quotation.supplier_quotation_statuses.quotation_status_id IS 'Identificador único do status de cotação';


--
-- TOC entry 7464 (class 0 OID 0)
-- Dependencies: 370
-- Name: COLUMN supplier_quotation_statuses.name; Type: COMMENT; Schema: quotation; Owner: postgres
--

COMMENT ON COLUMN quotation.supplier_quotation_statuses.name IS 'Nome do status (ex: pending, received, accepted)';


--
-- TOC entry 7465 (class 0 OID 0)
-- Dependencies: 370
-- Name: COLUMN supplier_quotation_statuses.description; Type: COMMENT; Schema: quotation; Owner: postgres
--

COMMENT ON COLUMN quotation.supplier_quotation_statuses.description IS 'Descrição detalhada do status';


--
-- TOC entry 7466 (class 0 OID 0)
-- Dependencies: 370
-- Name: COLUMN supplier_quotation_statuses.color; Type: COMMENT; Schema: quotation; Owner: postgres
--

COMMENT ON COLUMN quotation.supplier_quotation_statuses.color IS 'Código de cor hexadecimal para interface';


--
-- TOC entry 7467 (class 0 OID 0)
-- Dependencies: 370
-- Name: COLUMN supplier_quotation_statuses.is_active; Type: COMMENT; Schema: quotation; Owner: postgres
--

COMMENT ON COLUMN quotation.supplier_quotation_statuses.is_active IS 'Indica se o status está ativo para uso';


--
-- TOC entry 374 (class 1259 OID 21388)
-- Name: supplier_quotations; Type: TABLE; Schema: quotation; Owner: postgres
--

CREATE TABLE quotation.supplier_quotations (
    supplier_quotation_id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    quotation_submission_id uuid NOT NULL,
    shopping_list_item_id uuid NOT NULL,
    supplier_id uuid NOT NULL,
    quotation_status_id uuid NOT NULL,
    quotation_date timestamp with time zone DEFAULT now(),
    notes text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE quotation.supplier_quotations OWNER TO postgres;

--
-- TOC entry 7468 (class 0 OID 0)
-- Dependencies: 374
-- Name: TABLE supplier_quotations; Type: COMMENT; Schema: quotation; Owner: postgres
--

COMMENT ON TABLE quotation.supplier_quotations IS 'Cotações recebidas dos fornecedores para itens específicos';


--
-- TOC entry 7469 (class 0 OID 0)
-- Dependencies: 374
-- Name: COLUMN supplier_quotations.supplier_quotation_id; Type: COMMENT; Schema: quotation; Owner: postgres
--

COMMENT ON COLUMN quotation.supplier_quotations.supplier_quotation_id IS 'Identificador único da cotação do fornecedor';


--
-- TOC entry 7470 (class 0 OID 0)
-- Dependencies: 374
-- Name: COLUMN supplier_quotations.quotation_submission_id; Type: COMMENT; Schema: quotation; Owner: postgres
--

COMMENT ON COLUMN quotation.supplier_quotations.quotation_submission_id IS 'Referência para a submissão de cotação';


--
-- TOC entry 7471 (class 0 OID 0)
-- Dependencies: 374
-- Name: COLUMN supplier_quotations.shopping_list_item_id; Type: COMMENT; Schema: quotation; Owner: postgres
--

COMMENT ON COLUMN quotation.supplier_quotations.shopping_list_item_id IS 'Referência para o item da lista de compras';


--
-- TOC entry 7472 (class 0 OID 0)
-- Dependencies: 374
-- Name: COLUMN supplier_quotations.supplier_id; Type: COMMENT; Schema: quotation; Owner: postgres
--

COMMENT ON COLUMN quotation.supplier_quotations.supplier_id IS 'Referência para accounts.suppliers';


--
-- TOC entry 7473 (class 0 OID 0)
-- Dependencies: 374
-- Name: COLUMN supplier_quotations.quotation_status_id; Type: COMMENT; Schema: quotation; Owner: postgres
--

COMMENT ON COLUMN quotation.supplier_quotations.quotation_status_id IS 'Referência para o status da cotação';


--
-- TOC entry 7474 (class 0 OID 0)
-- Dependencies: 374
-- Name: COLUMN supplier_quotations.quotation_date; Type: COMMENT; Schema: quotation; Owner: postgres
--

COMMENT ON COLUMN quotation.supplier_quotations.quotation_date IS 'Data da cotação do fornecedor';


--
-- TOC entry 7475 (class 0 OID 0)
-- Dependencies: 374
-- Name: COLUMN supplier_quotations.notes; Type: COMMENT; Schema: quotation; Owner: postgres
--

COMMENT ON COLUMN quotation.supplier_quotations.notes IS 'Observações sobre a cotação do fornecedor';


--
-- TOC entry 4794 (class 0 OID 0)
-- Name: accounts__api_keys_2025_08; Type: TABLE ATTACH; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.accounts__api_keys ATTACH PARTITION audit.accounts__api_keys_2025_08 FOR VALUES FROM ('2025-08-01') TO ('2025-09-01');


--
-- TOC entry 4795 (class 0 OID 0)
-- Name: accounts__api_scopes_2025_08; Type: TABLE ATTACH; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.accounts__api_scopes ATTACH PARTITION audit.accounts__api_scopes_2025_08 FOR VALUES FROM ('2025-08-01') TO ('2025-09-01');


--
-- TOC entry 4796 (class 0 OID 0)
-- Name: accounts__apis_2025_08; Type: TABLE ATTACH; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.accounts__apis ATTACH PARTITION audit.accounts__apis_2025_08 FOR VALUES FROM ('2025-08-01') TO ('2025-09-01');


--
-- TOC entry 4824 (class 0 OID 0)
-- Name: accounts__employee_addresses_2025_08; Type: TABLE ATTACH; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.accounts__employee_addresses ATTACH PARTITION audit.accounts__employee_addresses_2025_08 FOR VALUES FROM ('2025-08-01') TO ('2025-09-01');


--
-- TOC entry 4823 (class 0 OID 0)
-- Name: accounts__employee_personal_data_2025_08; Type: TABLE ATTACH; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.accounts__employee_personal_data ATTACH PARTITION audit.accounts__employee_personal_data_2025_08 FOR VALUES FROM ('2025-08-01') TO ('2025-09-01');


--
-- TOC entry 4797 (class 0 OID 0)
-- Name: accounts__employee_roles_2025_08; Type: TABLE ATTACH; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.accounts__employee_roles ATTACH PARTITION audit.accounts__employee_roles_2025_08 FOR VALUES FROM ('2025-08-01') TO ('2025-09-01');


--
-- TOC entry 4798 (class 0 OID 0)
-- Name: accounts__employees_2025_08; Type: TABLE ATTACH; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.accounts__employees ATTACH PARTITION audit.accounts__employees_2025_08 FOR VALUES FROM ('2025-08-01') TO ('2025-09-01');


--
-- TOC entry 4799 (class 0 OID 0)
-- Name: accounts__establishment_addresses_2025_08; Type: TABLE ATTACH; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.accounts__establishment_addresses ATTACH PARTITION audit.accounts__establishment_addresses_2025_08 FOR VALUES FROM ('2025-08-01') TO ('2025-09-01');


--
-- TOC entry 4800 (class 0 OID 0)
-- Name: accounts__establishment_business_data_2025_08; Type: TABLE ATTACH; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.accounts__establishment_business_data ATTACH PARTITION audit.accounts__establishment_business_data_2025_08 FOR VALUES FROM ('2025-08-01') TO ('2025-09-01');


--
-- TOC entry 4801 (class 0 OID 0)
-- Name: accounts__establishments_2025_08; Type: TABLE ATTACH; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.accounts__establishments ATTACH PARTITION audit.accounts__establishments_2025_08 FOR VALUES FROM ('2025-08-01') TO ('2025-09-01');


--
-- TOC entry 4802 (class 0 OID 0)
-- Name: accounts__features_2025_08; Type: TABLE ATTACH; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.accounts__features ATTACH PARTITION audit.accounts__features_2025_08 FOR VALUES FROM ('2025-08-01') TO ('2025-09-01');


--
-- TOC entry 4803 (class 0 OID 0)
-- Name: accounts__modules_2025_08; Type: TABLE ATTACH; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.accounts__modules ATTACH PARTITION audit.accounts__modules_2025_08 FOR VALUES FROM ('2025-08-01') TO ('2025-09-01');


--
-- TOC entry 4804 (class 0 OID 0)
-- Name: accounts__platforms_2025_08; Type: TABLE ATTACH; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.accounts__platforms ATTACH PARTITION audit.accounts__platforms_2025_08 FOR VALUES FROM ('2025-08-01') TO ('2025-09-01');


--
-- TOC entry 4805 (class 0 OID 0)
-- Name: accounts__role_features_2025_08; Type: TABLE ATTACH; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.accounts__role_features ATTACH PARTITION audit.accounts__role_features_2025_08 FOR VALUES FROM ('2025-08-01') TO ('2025-09-01');


--
-- TOC entry 4806 (class 0 OID 0)
-- Name: accounts__roles_2025_08; Type: TABLE ATTACH; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.accounts__roles ATTACH PARTITION audit.accounts__roles_2025_08 FOR VALUES FROM ('2025-08-01') TO ('2025-09-01');


--
-- TOC entry 4807 (class 0 OID 0)
-- Name: accounts__suppliers_2025_08; Type: TABLE ATTACH; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.accounts__suppliers ATTACH PARTITION audit.accounts__suppliers_2025_08 FOR VALUES FROM ('2025-08-01') TO ('2025-09-01');


--
-- TOC entry 4808 (class 0 OID 0)
-- Name: accounts__users_2025_08; Type: TABLE ATTACH; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.accounts__users ATTACH PARTITION audit.accounts__users_2025_08 FOR VALUES FROM ('2025-08-01') TO ('2025-09-01');


--
-- TOC entry 4809 (class 0 OID 0)
-- Name: catalogs__brands_2025_08; Type: TABLE ATTACH; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.catalogs__brands ATTACH PARTITION audit.catalogs__brands_2025_08 FOR VALUES FROM ('2025-08-01') TO ('2025-09-01');


--
-- TOC entry 4810 (class 0 OID 0)
-- Name: catalogs__categories_2025_08; Type: TABLE ATTACH; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.catalogs__categories ATTACH PARTITION audit.catalogs__categories_2025_08 FOR VALUES FROM ('2025-08-01') TO ('2025-09-01');


--
-- TOC entry 4811 (class 0 OID 0)
-- Name: catalogs__compositions_2025_08; Type: TABLE ATTACH; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.catalogs__compositions ATTACH PARTITION audit.catalogs__compositions_2025_08 FOR VALUES FROM ('2025-08-01') TO ('2025-09-01');


--
-- TOC entry 4812 (class 0 OID 0)
-- Name: catalogs__fillings_2025_08; Type: TABLE ATTACH; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.catalogs__fillings ATTACH PARTITION audit.catalogs__fillings_2025_08 FOR VALUES FROM ('2025-08-01') TO ('2025-09-01');


--
-- TOC entry 4813 (class 0 OID 0)
-- Name: catalogs__flavors_2025_08; Type: TABLE ATTACH; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.catalogs__flavors ATTACH PARTITION audit.catalogs__flavors_2025_08 FOR VALUES FROM ('2025-08-01') TO ('2025-09-01');


--
-- TOC entry 4814 (class 0 OID 0)
-- Name: catalogs__formats_2025_08; Type: TABLE ATTACH; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.catalogs__formats ATTACH PARTITION audit.catalogs__formats_2025_08 FOR VALUES FROM ('2025-08-01') TO ('2025-09-01');


--
-- TOC entry 4815 (class 0 OID 0)
-- Name: catalogs__items_2025_08; Type: TABLE ATTACH; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.catalogs__items ATTACH PARTITION audit.catalogs__items_2025_08 FOR VALUES FROM ('2025-08-01') TO ('2025-09-01');


--
-- TOC entry 4816 (class 0 OID 0)
-- Name: catalogs__nutritional_variants_2025_08; Type: TABLE ATTACH; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.catalogs__nutritional_variants ATTACH PARTITION audit.catalogs__nutritional_variants_2025_08 FOR VALUES FROM ('2025-08-01') TO ('2025-09-01');


--
-- TOC entry 4817 (class 0 OID 0)
-- Name: catalogs__offers_2025_08; Type: TABLE ATTACH; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.catalogs__offers ATTACH PARTITION audit.catalogs__offers_2025_08 FOR VALUES FROM ('2025-08-01') TO ('2025-09-01');


--
-- TOC entry 4818 (class 0 OID 0)
-- Name: catalogs__packagings_2025_08; Type: TABLE ATTACH; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.catalogs__packagings ATTACH PARTITION audit.catalogs__packagings_2025_08 FOR VALUES FROM ('2025-08-01') TO ('2025-09-01');


--
-- TOC entry 4819 (class 0 OID 0)
-- Name: catalogs__products_2025_08; Type: TABLE ATTACH; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.catalogs__products ATTACH PARTITION audit.catalogs__products_2025_08 FOR VALUES FROM ('2025-08-01') TO ('2025-09-01');


--
-- TOC entry 4820 (class 0 OID 0)
-- Name: catalogs__quantities_2025_08; Type: TABLE ATTACH; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.catalogs__quantities ATTACH PARTITION audit.catalogs__quantities_2025_08 FOR VALUES FROM ('2025-08-01') TO ('2025-09-01');


--
-- TOC entry 4821 (class 0 OID 0)
-- Name: catalogs__subcategories_2025_08; Type: TABLE ATTACH; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.catalogs__subcategories ATTACH PARTITION audit.catalogs__subcategories_2025_08 FOR VALUES FROM ('2025-08-01') TO ('2025-09-01');


--
-- TOC entry 4822 (class 0 OID 0)
-- Name: catalogs__variant_types_2025_08; Type: TABLE ATTACH; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.catalogs__variant_types ATTACH PARTITION audit.catalogs__variant_types_2025_08 FOR VALUES FROM ('2025-08-01') TO ('2025-09-01');


--
-- TOC entry 4829 (class 0 OID 0)
-- Name: quotation__quotation_submissions_2025_08; Type: TABLE ATTACH; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.quotation__quotation_submissions ATTACH PARTITION audit.quotation__quotation_submissions_2025_08 FOR VALUES FROM ('2025-08-01') TO ('2025-09-01');


--
-- TOC entry 4831 (class 0 OID 0)
-- Name: quotation__quoted_prices_2025_08; Type: TABLE ATTACH; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.quotation__quoted_prices ATTACH PARTITION audit.quotation__quoted_prices_2025_08 FOR VALUES FROM ('2025-08-01') TO ('2025-09-01');


--
-- TOC entry 4828 (class 0 OID 0)
-- Name: quotation__shopping_list_items_2025_08; Type: TABLE ATTACH; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.quotation__shopping_list_items ATTACH PARTITION audit.quotation__shopping_list_items_2025_08 FOR VALUES FROM ('2025-08-01') TO ('2025-09-01');


--
-- TOC entry 4827 (class 0 OID 0)
-- Name: quotation__shopping_lists_2025_08; Type: TABLE ATTACH; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.quotation__shopping_lists ATTACH PARTITION audit.quotation__shopping_lists_2025_08 FOR VALUES FROM ('2025-08-01') TO ('2025-09-01');


--
-- TOC entry 4825 (class 0 OID 0)
-- Name: quotation__submission_statuses_2025_08; Type: TABLE ATTACH; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.quotation__submission_statuses ATTACH PARTITION audit.quotation__submission_statuses_2025_08 FOR VALUES FROM ('2025-08-01') TO ('2025-09-01');


--
-- TOC entry 4826 (class 0 OID 0)
-- Name: quotation__supplier_quotation_statuses_2025_08; Type: TABLE ATTACH; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.quotation__supplier_quotation_statuses ATTACH PARTITION audit.quotation__supplier_quotation_statuses_2025_08 FOR VALUES FROM ('2025-08-01') TO ('2025-09-01');


--
-- TOC entry 4830 (class 0 OID 0)
-- Name: quotation__supplier_quotations_2025_08; Type: TABLE ATTACH; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.quotation__supplier_quotations ATTACH PARTITION audit.quotation__supplier_quotations_2025_08 FOR VALUES FROM ('2025-08-01') TO ('2025-09-01');


--
-- TOC entry 6455 (class 0 OID 17697)
-- Dependencies: 254
-- Data for Name: api_keys; Type: TABLE DATA; Schema: accounts; Owner: postgres
--

INSERT INTO accounts.api_keys VALUES ('f55b2638-ac83-4584-a8d8-8f83084a6789', '3a63d392-60fe-4d9c-82a9-e5848a4d3665', 'Chave Pública Jonathan', 'secret-teste-jonathan', '2025-05-27 02:31:06.489197', NULL);
INSERT INTO accounts.api_keys VALUES ('d30c9876-b5c3-4d50-92bc-d7154bd664e6', '199ecc7b-d75d-4913-bc7a-e44940fd3ff2', 'Chave Publica Vinícius', 'secret-teste-vinicius', '2025-08-14 17:20:04.353752', NULL);


--
-- TOC entry 6456 (class 0 OID 17711)
-- Dependencies: 255
-- Data for Name: api_scopes; Type: TABLE DATA; Schema: accounts; Owner: postgres
--

INSERT INTO accounts.api_scopes VALUES ('9b87fc07-f647-484b-882b-0bb8a73f1240', 'f55b2638-ac83-4584-a8d8-8f83084a6789', '3225eae1-60f6-4dab-8b5b-3290312fad3f', '2025-05-27 10:44:37.208236');
INSERT INTO accounts.api_scopes VALUES ('0bca55ff-4156-4996-8760-9de48de8936e', 'f55b2638-ac83-4584-a8d8-8f83084a6789', 'b562e3df-78a3-43af-aa3d-46cfd7c90f9c', '2025-05-27 10:44:37.208236');


--
-- TOC entry 6454 (class 0 OID 17420)
-- Dependencies: 253
-- Data for Name: apis; Type: TABLE DATA; Schema: accounts; Owner: postgres
--

INSERT INTO accounts.apis VALUES ('029af1c1-cf12-436a-afb7-844f405f09f1', '/shopping-lists', 'POST', 'Criar nova lista de compras', '2025-05-17 01:20:42.114603', NULL, NULL);
INSERT INTO accounts.apis VALUES ('95fd97bf-360e-4fce-a790-36ccd427e3ea', '/quotations', 'POST', 'Solicitar cotação de produtos', '2025-05-17 01:20:42.114603', NULL, NULL);
INSERT INTO accounts.apis VALUES ('58eedfe0-8f6d-401c-8a93-f9c4da54ada0', '/shopping-lists/{id}/send', 'POST', 'Enviar lista de compras para cotação', '2025-05-17 01:20:42.114603', NULL, NULL);
INSERT INTO accounts.apis VALUES ('f4e8e8f1-db95-497d-ba49-b14c3b1713f0', '/shopping-lists/{id}/quotes', 'GET', 'Consultar cotações recebidas', '2025-05-17 01:20:42.114603', NULL, NULL);
INSERT INTO accounts.apis VALUES ('723608c1-4dc0-47a6-8c1c-0087ef68191f', '/catalog/products', 'POST', 'Cadastrar produtos no catálogo', '2025-05-17 01:20:42.114603', NULL, NULL);
INSERT INTO accounts.apis VALUES ('484394aa-be37-49a3-81c1-2539a2a32946', '/quotations/response', 'POST', 'Responder cotações recebidas', '2025-05-17 01:20:42.114603', NULL, NULL);


--
-- TOC entry 6532 (class 0 OID 21204)
-- Dependencies: 362
-- Data for Name: employee_addresses; Type: TABLE DATA; Schema: accounts; Owner: postgres
--



--
-- TOC entry 6531 (class 0 OID 21180)
-- Dependencies: 361
-- Data for Name: employee_personal_data; Type: TABLE DATA; Schema: accounts; Owner: postgres
--



--
-- TOC entry 6453 (class 0 OID 17398)
-- Dependencies: 252
-- Data for Name: employee_roles; Type: TABLE DATA; Schema: accounts; Owner: postgres
--

INSERT INTO accounts.employee_roles VALUES ('0bc59b18-088d-4986-8283-bcaf4e7ba33a', '3a63d392-60fe-4d9c-82a9-e5848a4d3665', '9b43bd06-9b89-42bb-b105-d5ef057657ea', '2025-05-17 01:31:11.106129', NULL);
INSERT INTO accounts.employee_roles VALUES ('40c1fd77-5bdb-4014-81b1-bbd54c032cd4', '199ecc7b-d75d-4913-bc7a-e44940fd3ff2', '1dae8888-f954-4f17-9f58-a9b99ff12ede', '2025-05-17 01:31:11.106129', NULL);
INSERT INTO accounts.employee_roles VALUES ('391c35b3-a5cc-417f-b1f5-d280d1809401', '60688fde-6798-46eb-9a35-4902b35cbe75', '1362ebf0-191f-41a1-9f98-da7657f38263', '2025-05-17 01:31:11.106129', NULL);


--
-- TOC entry 6447 (class 0 OID 17272)
-- Dependencies: 246
-- Data for Name: employees; Type: TABLE DATA; Schema: accounts; Owner: postgres
--

INSERT INTO accounts.employees VALUES ('3a63d392-60fe-4d9c-82a9-e5848a4d3665', '270e14d4-04c8-4319-8e49-0f1b38e54c07', '9416b02a-bc71-4441-a6cc-535b3d497c75', NULL, true, '2025-05-17 01:24:04.420438', NULL, '2025-05-17 01:24:04.420438', NULL);
INSERT INTO accounts.employees VALUES ('199ecc7b-d75d-4913-bc7a-e44940fd3ff2', '29263b69-5212-4dc8-9207-19ad696e538d', NULL, '0b53ccb4-f36c-4b0e-bc0e-570a6cb800af', true, '2025-05-17 01:24:04.420438', NULL, '2025-05-17 01:24:04.420438', NULL);
INSERT INTO accounts.employees VALUES ('60688fde-6798-46eb-9a35-4902b35cbe75', '58920904-0ad1-4f3d-a907-333bb38bfe41', NULL, '0b53ccb4-f36c-4b0e-bc0e-570a6cb800af', true, '2025-05-17 01:24:04.420438', NULL, '2025-05-17 01:24:04.420438', NULL);


--
-- TOC entry 6472 (class 0 OID 18335)
-- Dependencies: 273
-- Data for Name: establishment_addresses; Type: TABLE DATA; Schema: accounts; Owner: postgres
--



--
-- TOC entry 6471 (class 0 OID 18317)
-- Dependencies: 272
-- Data for Name: establishment_business_data; Type: TABLE DATA; Schema: accounts; Owner: postgres
--



--
-- TOC entry 6446 (class 0 OID 17256)
-- Dependencies: 245
-- Data for Name: establishments; Type: TABLE DATA; Schema: accounts; Owner: postgres
--

INSERT INTO accounts.establishments VALUES ('0b53ccb4-f36c-4b0e-bc0e-570a6cb800af', 'Burgeria do Vini', true, '2025-05-17 01:22:28.598373', NULL, '2025-05-17 01:22:28.598373', NULL);


--
-- TOC entry 6450 (class 0 OID 17339)
-- Dependencies: 249
-- Data for Name: features; Type: TABLE DATA; Schema: accounts; Owner: postgres
--

INSERT INTO accounts.features VALUES ('e764c452-77d9-4e45-815e-d6918e1f5196', '40a09388-1d79-4f8a-a83d-1e5710c209aa', 'Criar lista de compras', 'criar_lista_compras', 'Permite criar uma nova lista de compras', '2025-05-27 02:49:44.792881', NULL, '1595b7e8-7828-4733-bf45-912023627234');
INSERT INTO accounts.features VALUES ('4e8fb761-f302-4cc9-b9bd-e3e28cb53f79', '40a09388-1d79-4f8a-a83d-1e5710c209aa', 'Cotar produtos', 'cotar_produtos', 'Permite selecionar produtos para cotação', '2025-05-27 02:49:44.792881', NULL, '1595b7e8-7828-4733-bf45-912023627234');
INSERT INTO accounts.features VALUES ('5991f57e-e241-44a3-b62c-5513b1b36f66', 'bbdf7f53-bd82-4725-b7fd-4c443c26b584', 'Enviar lista para cotação', 'enviar_lista_cotacao', 'Permite enviar a lista para fornecedores', '2025-05-27 02:49:44.792881', NULL, '1595b7e8-7828-4733-bf45-912023627234');
INSERT INTO accounts.features VALUES ('4452dd21-fe5a-4d41-9532-54e8a00e4a82', 'bbdf7f53-bd82-4725-b7fd-4c443c26b584', 'Ver cotações recebidas', 'ver_cotacoes_recebidas', 'Visualiza as cotações retornadas', '2025-05-27 02:49:44.792881', NULL, '1595b7e8-7828-4733-bf45-912023627234');
INSERT INTO accounts.features VALUES ('3225eae1-60f6-4dab-8b5b-3290312fad3f', '74f2c3c3-11e5-40b5-af53-448abedb4510', 'Cadastrar catálogo de produtos', 'cadastrar_catalogo', 'Permite cadastrar produtos no catálogo', '2025-05-27 02:49:44.792881', NULL, '5950a0ea-68fa-49bc-8386-52f78e0ccadb');
INSERT INTO accounts.features VALUES ('b562e3df-78a3-43af-aa3d-46cfd7c90f9c', '84713bfb-452c-4c74-adac-6377d4c80082', 'Responder cotações recebidas', 'responder_cotacoes', 'Permite responder cotações enviadas', '2025-05-27 02:49:44.792881', NULL, '5950a0ea-68fa-49bc-8386-52f78e0ccadb');


--
-- TOC entry 6449 (class 0 OID 17318)
-- Dependencies: 248
-- Data for Name: modules; Type: TABLE DATA; Schema: accounts; Owner: postgres
--

INSERT INTO accounts.modules VALUES ('40a09388-1d79-4f8a-a83d-1e5710c209aa', 'Lista de Compras', 'Criação e gerenciamento de listas de compras', '2025-05-17 01:19:51.512309', NULL);
INSERT INTO accounts.modules VALUES ('bbdf7f53-bd82-4725-b7fd-4c443c26b584', 'Envio de Cotações', 'Envio de listas para cotação pelos fornecedores', '2025-05-17 01:19:51.512309', NULL);
INSERT INTO accounts.modules VALUES ('74f2c3c3-11e5-40b5-af53-448abedb4510', 'Catálogo de Produtos', 'Gerenciamento do catálogo do fornecedor', '2025-05-17 01:19:51.512309', NULL);
INSERT INTO accounts.modules VALUES ('84713bfb-452c-4c74-adac-6377d4c80082', 'Gestão de Cotações', 'Recebimento e resposta de cotações', '2025-05-17 01:19:51.512309', NULL);


--
-- TOC entry 6448 (class 0 OID 17302)
-- Dependencies: 247
-- Data for Name: platforms; Type: TABLE DATA; Schema: accounts; Owner: postgres
--

INSERT INTO accounts.platforms VALUES ('5950a0ea-68fa-49bc-8386-52f78e0ccadb', 'Área do Fornecedor', 'Ambiente exclusivo para fornecedores', '2025-05-17 01:18:06.913173', NULL);
INSERT INTO accounts.platforms VALUES ('1595b7e8-7828-4733-bf45-912023627234', 'Área do Estabelecimento', 'Ambiente exclusivo para estabelecimentos', '2025-05-17 01:18:06.913173', NULL);


--
-- TOC entry 6452 (class 0 OID 17376)
-- Dependencies: 251
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
-- TOC entry 6451 (class 0 OID 17360)
-- Dependencies: 250
-- Data for Name: roles; Type: TABLE DATA; Schema: accounts; Owner: postgres
--

INSERT INTO accounts.roles VALUES ('1dae8888-f954-4f17-9f58-a9b99ff12ede', 'admin_estabelecimento', 'Acesso total à plataforma do estabelecimento', '2025-05-17 01:30:16.304337', NULL);
INSERT INTO accounts.roles VALUES ('9b43bd06-9b89-42bb-b105-d5ef057657ea', 'admin_fornecedor', 'Acesso total à plataforma do fornecedor', '2025-05-17 01:30:16.304337', NULL);
INSERT INTO accounts.roles VALUES ('1362ebf0-191f-41a1-9f98-da7657f38263', 'consulta_estabelecimento', 'Visualiza apenas as cotações enviadas', '2025-05-17 01:30:16.304337', NULL);


--
-- TOC entry 6445 (class 0 OID 17240)
-- Dependencies: 244
-- Data for Name: suppliers; Type: TABLE DATA; Schema: accounts; Owner: postgres
--

INSERT INTO accounts.suppliers VALUES ('9416b02a-bc71-4441-a6cc-535b3d497c75', 'Atacadão do Tião', true, '2025-05-17 01:22:28.598373', NULL, '2025-05-17 01:22:28.598373', NULL);
INSERT INTO accounts.suppliers VALUES ('de93c8b5-52d3-4352-b18b-f9fddd6f92a4', 'Distribuidora São Paulo', true, '2025-08-12 13:58:31.229754', NULL, '2025-08-12 13:58:31.229754', NULL);
INSERT INTO accounts.suppliers VALUES ('40ebea12-e124-4f0b-9177-303981c8793a', 'Mega Atacadão', true, '2025-08-12 13:58:31.393915', NULL, '2025-08-12 13:58:31.393915', NULL);
INSERT INTO accounts.suppliers VALUES ('69fa9957-82c8-4a18-9e06-5ec9e61f5fab', 'Vini Atacado', true, '2025-08-12 13:58:31.551486', NULL, '2025-08-12 13:58:31.551486', NULL);


--
-- TOC entry 6444 (class 0 OID 17226)
-- Dependencies: 243
-- Data for Name: users; Type: TABLE DATA; Schema: accounts; Owner: postgres
--

INSERT INTO accounts.users VALUES ('270e14d4-04c8-4319-8e49-0f1b38e54c07', 'jonathan@tiao.com', 'Jonathan Silva', 'sub-jonathan', true, '2025-05-17 01:22:17.357785', NULL);
INSERT INTO accounts.users VALUES ('29263b69-5212-4dc8-9207-19ad696e538d', 'laura@burgeria.com', 'Laura Almeida', 'sub-laura', true, '2025-05-17 01:22:17.357785', NULL);
INSERT INTO accounts.users VALUES ('58920904-0ad1-4f3d-a907-333bb38bfe41', 'julia@burgeria.com', 'Julia Costa', 'sub-julia', true, '2025-05-17 01:22:17.357785', NULL);


--
-- TOC entry 6474 (class 0 OID 20100)
-- Dependencies: 276
-- Data for Name: accounts__api_keys_2025_08; Type: TABLE DATA; Schema: audit; Owner: postgres
--



--
-- TOC entry 6476 (class 0 OID 20134)
-- Dependencies: 279
-- Data for Name: accounts__api_scopes_2025_08; Type: TABLE DATA; Schema: audit; Owner: postgres
--



--
-- TOC entry 6478 (class 0 OID 20168)
-- Dependencies: 282
-- Data for Name: accounts__apis_2025_08; Type: TABLE DATA; Schema: audit; Owner: postgres
--



--
-- TOC entry 6536 (class 0 OID 21302)
-- Dependencies: 368
-- Data for Name: accounts__employee_addresses_2025_08; Type: TABLE DATA; Schema: audit; Owner: postgres
--



--
-- TOC entry 6534 (class 0 OID 21269)
-- Dependencies: 365
-- Data for Name: accounts__employee_personal_data_2025_08; Type: TABLE DATA; Schema: audit; Owner: postgres
--



--
-- TOC entry 6480 (class 0 OID 20202)
-- Dependencies: 285
-- Data for Name: accounts__employee_roles_2025_08; Type: TABLE DATA; Schema: audit; Owner: postgres
--



--
-- TOC entry 6482 (class 0 OID 20238)
-- Dependencies: 288
-- Data for Name: accounts__employees_2025_08; Type: TABLE DATA; Schema: audit; Owner: postgres
--



--
-- TOC entry 6484 (class 0 OID 20273)
-- Dependencies: 291
-- Data for Name: accounts__establishment_addresses_2025_08; Type: TABLE DATA; Schema: audit; Owner: postgres
--



--
-- TOC entry 6486 (class 0 OID 20306)
-- Dependencies: 294
-- Data for Name: accounts__establishment_business_data_2025_08; Type: TABLE DATA; Schema: audit; Owner: postgres
--



--
-- TOC entry 6488 (class 0 OID 20338)
-- Dependencies: 297
-- Data for Name: accounts__establishments_2025_08; Type: TABLE DATA; Schema: audit; Owner: postgres
--



--
-- TOC entry 6490 (class 0 OID 20371)
-- Dependencies: 300
-- Data for Name: accounts__features_2025_08; Type: TABLE DATA; Schema: audit; Owner: postgres
--



--
-- TOC entry 6492 (class 0 OID 20404)
-- Dependencies: 303
-- Data for Name: accounts__modules_2025_08; Type: TABLE DATA; Schema: audit; Owner: postgres
--



--
-- TOC entry 6494 (class 0 OID 20435)
-- Dependencies: 306
-- Data for Name: accounts__platforms_2025_08; Type: TABLE DATA; Schema: audit; Owner: postgres
--



--
-- TOC entry 6496 (class 0 OID 20468)
-- Dependencies: 309
-- Data for Name: accounts__role_features_2025_08; Type: TABLE DATA; Schema: audit; Owner: postgres
--



--
-- TOC entry 6498 (class 0 OID 20501)
-- Dependencies: 312
-- Data for Name: accounts__roles_2025_08; Type: TABLE DATA; Schema: audit; Owner: postgres
--



--
-- TOC entry 6500 (class 0 OID 20532)
-- Dependencies: 315
-- Data for Name: accounts__suppliers_2025_08; Type: TABLE DATA; Schema: audit; Owner: postgres
--



--
-- TOC entry 6502 (class 0 OID 20563)
-- Dependencies: 318
-- Data for Name: accounts__users_2025_08; Type: TABLE DATA; Schema: audit; Owner: postgres
--



--
-- TOC entry 6504 (class 0 OID 20594)
-- Dependencies: 321
-- Data for Name: catalogs__brands_2025_08; Type: TABLE DATA; Schema: audit; Owner: postgres
--



--
-- TOC entry 6506 (class 0 OID 20625)
-- Dependencies: 324
-- Data for Name: catalogs__categories_2025_08; Type: TABLE DATA; Schema: audit; Owner: postgres
--



--
-- TOC entry 6508 (class 0 OID 20656)
-- Dependencies: 327
-- Data for Name: catalogs__compositions_2025_08; Type: TABLE DATA; Schema: audit; Owner: postgres
--



--
-- TOC entry 6510 (class 0 OID 20687)
-- Dependencies: 330
-- Data for Name: catalogs__fillings_2025_08; Type: TABLE DATA; Schema: audit; Owner: postgres
--



--
-- TOC entry 6512 (class 0 OID 20718)
-- Dependencies: 333
-- Data for Name: catalogs__flavors_2025_08; Type: TABLE DATA; Schema: audit; Owner: postgres
--



--
-- TOC entry 6514 (class 0 OID 20749)
-- Dependencies: 336
-- Data for Name: catalogs__formats_2025_08; Type: TABLE DATA; Schema: audit; Owner: postgres
--



--
-- TOC entry 6516 (class 0 OID 20781)
-- Dependencies: 339
-- Data for Name: catalogs__items_2025_08; Type: TABLE DATA; Schema: audit; Owner: postgres
--



--
-- TOC entry 6518 (class 0 OID 20813)
-- Dependencies: 342
-- Data for Name: catalogs__nutritional_variants_2025_08; Type: TABLE DATA; Schema: audit; Owner: postgres
--



--
-- TOC entry 6520 (class 0 OID 20846)
-- Dependencies: 345
-- Data for Name: catalogs__offers_2025_08; Type: TABLE DATA; Schema: audit; Owner: postgres
--



--
-- TOC entry 6522 (class 0 OID 20879)
-- Dependencies: 348
-- Data for Name: catalogs__packagings_2025_08; Type: TABLE DATA; Schema: audit; Owner: postgres
--



--
-- TOC entry 6524 (class 0 OID 20920)
-- Dependencies: 351
-- Data for Name: catalogs__products_2025_08; Type: TABLE DATA; Schema: audit; Owner: postgres
--



--
-- TOC entry 6526 (class 0 OID 20961)
-- Dependencies: 354
-- Data for Name: catalogs__quantities_2025_08; Type: TABLE DATA; Schema: audit; Owner: postgres
--



--
-- TOC entry 6528 (class 0 OID 20993)
-- Dependencies: 357
-- Data for Name: catalogs__subcategories_2025_08; Type: TABLE DATA; Schema: audit; Owner: postgres
--



--
-- TOC entry 6530 (class 0 OID 21025)
-- Dependencies: 360
-- Data for Name: catalogs__variant_types_2025_08; Type: TABLE DATA; Schema: audit; Owner: postgres
--



--
-- TOC entry 6553 (class 0 OID 21713)
-- Dependencies: 390
-- Data for Name: quotation__quotation_submissions_2025_08; Type: TABLE DATA; Schema: audit; Owner: postgres
--



--
-- TOC entry 6557 (class 0 OID 21786)
-- Dependencies: 396
-- Data for Name: quotation__quoted_prices_2025_08; Type: TABLE DATA; Schema: audit; Owner: postgres
--



--
-- TOC entry 6551 (class 0 OID 21668)
-- Dependencies: 387
-- Data for Name: quotation__shopping_list_items_2025_08; Type: TABLE DATA; Schema: audit; Owner: postgres
--



--
-- TOC entry 6549 (class 0 OID 21623)
-- Dependencies: 384
-- Data for Name: quotation__shopping_lists_2025_08; Type: TABLE DATA; Schema: audit; Owner: postgres
--



--
-- TOC entry 6545 (class 0 OID 21559)
-- Dependencies: 378
-- Data for Name: quotation__submission_statuses_2025_08; Type: TABLE DATA; Schema: audit; Owner: postgres
--



--
-- TOC entry 6547 (class 0 OID 21590)
-- Dependencies: 381
-- Data for Name: quotation__supplier_quotation_statuses_2025_08; Type: TABLE DATA; Schema: audit; Owner: postgres
--



--
-- TOC entry 6555 (class 0 OID 21750)
-- Dependencies: 393
-- Data for Name: quotation__supplier_quotations_2025_08; Type: TABLE DATA; Schema: audit; Owner: postgres
--



--
-- TOC entry 6466 (class 0 OID 18022)
-- Dependencies: 267
-- Data for Name: brands; Type: TABLE DATA; Schema: catalogs; Owner: postgres
--



--
-- TOC entry 6457 (class 0 OID 17916)
-- Dependencies: 258
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
-- TOC entry 6460 (class 0 OID 17956)
-- Dependencies: 261
-- Data for Name: compositions; Type: TABLE DATA; Schema: catalogs; Owner: postgres
--



--
-- TOC entry 6464 (class 0 OID 18000)
-- Dependencies: 265
-- Data for Name: fillings; Type: TABLE DATA; Schema: catalogs; Owner: postgres
--



--
-- TOC entry 6463 (class 0 OID 17989)
-- Dependencies: 264
-- Data for Name: flavors; Type: TABLE DATA; Schema: catalogs; Owner: postgres
--



--
-- TOC entry 6462 (class 0 OID 17978)
-- Dependencies: 263
-- Data for Name: formats; Type: TABLE DATA; Schema: catalogs; Owner: postgres
--



--
-- TOC entry 6459 (class 0 OID 17941)
-- Dependencies: 260
-- Data for Name: items; Type: TABLE DATA; Schema: catalogs; Owner: postgres
--



--
-- TOC entry 6465 (class 0 OID 18011)
-- Dependencies: 266
-- Data for Name: nutritional_variants; Type: TABLE DATA; Schema: catalogs; Owner: postgres
--



--
-- TOC entry 6470 (class 0 OID 18113)
-- Dependencies: 271
-- Data for Name: offers; Type: TABLE DATA; Schema: catalogs; Owner: postgres
--



--
-- TOC entry 6467 (class 0 OID 18033)
-- Dependencies: 268
-- Data for Name: packagings; Type: TABLE DATA; Schema: catalogs; Owner: postgres
--



--
-- TOC entry 6469 (class 0 OID 18053)
-- Dependencies: 270
-- Data for Name: products; Type: TABLE DATA; Schema: catalogs; Owner: postgres
--



--
-- TOC entry 6468 (class 0 OID 18044)
-- Dependencies: 269
-- Data for Name: quantities; Type: TABLE DATA; Schema: catalogs; Owner: postgres
--



--
-- TOC entry 6458 (class 0 OID 17927)
-- Dependencies: 259
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
-- TOC entry 6461 (class 0 OID 17967)
-- Dependencies: 262
-- Data for Name: variant_types; Type: TABLE DATA; Schema: catalogs; Owner: postgres
--



--
-- TOC entry 6541 (class 0 OID 21376)
-- Dependencies: 373
-- Data for Name: quotation_submissions; Type: TABLE DATA; Schema: quotation; Owner: postgres
--



--
-- TOC entry 6543 (class 0 OID 21399)
-- Dependencies: 375
-- Data for Name: quoted_prices; Type: TABLE DATA; Schema: quotation; Owner: postgres
--



--
-- TOC entry 6540 (class 0 OID 21366)
-- Dependencies: 372
-- Data for Name: shopping_list_items; Type: TABLE DATA; Schema: quotation; Owner: postgres
--



--
-- TOC entry 6539 (class 0 OID 21356)
-- Dependencies: 371
-- Data for Name: shopping_lists; Type: TABLE DATA; Schema: quotation; Owner: postgres
--



--
-- TOC entry 6537 (class 0 OID 21330)
-- Dependencies: 369
-- Data for Name: submission_statuses; Type: TABLE DATA; Schema: quotation; Owner: postgres
--

INSERT INTO quotation.submission_statuses VALUES ('267d35c2-d4b5-49fc-9785-1a4b07ee82b5', 'pending', 'Submissão pendente de envio', '#FFA500', true, '2025-08-15 00:12:20.373312+00', '2025-08-15 00:12:20.373312+00');
INSERT INTO quotation.submission_statuses VALUES ('db4e9d33-78a5-4855-8223-c345828b8c31', 'sent', 'Submissão enviada para cotação', '#008000', true, '2025-08-15 00:12:20.373312+00', '2025-08-15 00:12:20.373312+00');
INSERT INTO quotation.submission_statuses VALUES ('4c884185-5c5c-4044-b8ee-ac8611c50148', 'in_progress', 'Cotação em andamento', '#0066CC', true, '2025-08-15 00:12:20.373312+00', '2025-08-15 00:12:20.373312+00');
INSERT INTO quotation.submission_statuses VALUES ('894ea221-b66a-4f31-816d-ce237a7f9937', 'completed', 'Cotação finalizada', '#006600', true, '2025-08-15 00:12:20.373312+00', '2025-08-15 00:12:20.373312+00');
INSERT INTO quotation.submission_statuses VALUES ('ccbdc740-75ac-4721-8ac9-aabc4c0b133e', 'cancelled', 'Submissão cancelada', '#CC0000', true, '2025-08-15 00:12:20.373312+00', '2025-08-15 00:12:20.373312+00');


--
-- TOC entry 6538 (class 0 OID 21343)
-- Dependencies: 370
-- Data for Name: supplier_quotation_statuses; Type: TABLE DATA; Schema: quotation; Owner: postgres
--

INSERT INTO quotation.supplier_quotation_statuses VALUES ('abcfcd70-9da7-44c6-ac9a-a7e55f1a7c98', 'pending', 'Cotação pendente de resposta do fornecedor', '#FFA500', true, '2025-08-15 00:12:20.373312+00', '2025-08-15 00:12:20.373312+00');
INSERT INTO quotation.supplier_quotation_statuses VALUES ('03d8f7a1-24f7-477f-97d1-4516daa923e9', 'received', 'Cotação recebida do fornecedor', '#008000', true, '2025-08-15 00:12:20.373312+00', '2025-08-15 00:12:20.373312+00');
INSERT INTO quotation.supplier_quotation_statuses VALUES ('3b572e91-2f16-4774-9bec-9d5f0f901c7a', 'accepted', 'Cotação aceita pelo estabelecimento', '#0066CC', true, '2025-08-15 00:12:20.373312+00', '2025-08-15 00:12:20.373312+00');
INSERT INTO quotation.supplier_quotation_statuses VALUES ('0bebec27-3c3b-46d0-8f27-a7a6e28a91fc', 'rejected', 'Cotação rejeitada pelo estabelecimento', '#CC0000', true, '2025-08-15 00:12:20.373312+00', '2025-08-15 00:12:20.373312+00');
INSERT INTO quotation.supplier_quotation_statuses VALUES ('2cf97bfd-f426-4959-aa6f-e53242533479', 'expired', 'Cotação expirada', '#808080', true, '2025-08-15 00:12:20.373312+00', '2025-08-15 00:12:20.373312+00');
INSERT INTO quotation.supplier_quotation_statuses VALUES ('fd8d297a-83cf-4bba-9135-3ca98cc97c5f', 'cancelled', 'Cotação cancelada', '#FF0000', true, '2025-08-15 00:12:20.373312+00', '2025-08-15 00:12:20.373312+00');


--
-- TOC entry 6542 (class 0 OID 21388)
-- Dependencies: 374
-- Data for Name: supplier_quotations; Type: TABLE DATA; Schema: quotation; Owner: postgres
--



--
-- TOC entry 7476 (class 0 OID 0)
-- Dependencies: 274
-- Name: accounts__api_keys_audit_id_seq; Type: SEQUENCE SET; Schema: audit; Owner: postgres
--

SELECT pg_catalog.setval('audit.accounts__api_keys_audit_id_seq', 1, false);


--
-- TOC entry 7477 (class 0 OID 0)
-- Dependencies: 277
-- Name: accounts__api_scopes_audit_id_seq; Type: SEQUENCE SET; Schema: audit; Owner: postgres
--

SELECT pg_catalog.setval('audit.accounts__api_scopes_audit_id_seq', 1, false);


--
-- TOC entry 7478 (class 0 OID 0)
-- Dependencies: 280
-- Name: accounts__apis_audit_id_seq; Type: SEQUENCE SET; Schema: audit; Owner: postgres
--

SELECT pg_catalog.setval('audit.accounts__apis_audit_id_seq', 1, false);


--
-- TOC entry 7479 (class 0 OID 0)
-- Dependencies: 366
-- Name: accounts__employee_addresses_audit_id_seq; Type: SEQUENCE SET; Schema: audit; Owner: postgres
--

SELECT pg_catalog.setval('audit.accounts__employee_addresses_audit_id_seq', 1, false);


--
-- TOC entry 7480 (class 0 OID 0)
-- Dependencies: 363
-- Name: accounts__employee_personal_data_audit_id_seq; Type: SEQUENCE SET; Schema: audit; Owner: postgres
--

SELECT pg_catalog.setval('audit.accounts__employee_personal_data_audit_id_seq', 1, false);


--
-- TOC entry 7481 (class 0 OID 0)
-- Dependencies: 283
-- Name: accounts__employee_roles_audit_id_seq; Type: SEQUENCE SET; Schema: audit; Owner: postgres
--

SELECT pg_catalog.setval('audit.accounts__employee_roles_audit_id_seq', 1, false);


--
-- TOC entry 7482 (class 0 OID 0)
-- Dependencies: 286
-- Name: accounts__employees_audit_id_seq; Type: SEQUENCE SET; Schema: audit; Owner: postgres
--

SELECT pg_catalog.setval('audit.accounts__employees_audit_id_seq', 1, false);


--
-- TOC entry 7483 (class 0 OID 0)
-- Dependencies: 289
-- Name: accounts__establishment_addresses_audit_id_seq; Type: SEQUENCE SET; Schema: audit; Owner: postgres
--

SELECT pg_catalog.setval('audit.accounts__establishment_addresses_audit_id_seq', 1, false);


--
-- TOC entry 7484 (class 0 OID 0)
-- Dependencies: 292
-- Name: accounts__establishment_business_data_audit_id_seq; Type: SEQUENCE SET; Schema: audit; Owner: postgres
--

SELECT pg_catalog.setval('audit.accounts__establishment_business_data_audit_id_seq', 1, false);


--
-- TOC entry 7485 (class 0 OID 0)
-- Dependencies: 295
-- Name: accounts__establishments_audit_id_seq; Type: SEQUENCE SET; Schema: audit; Owner: postgres
--

SELECT pg_catalog.setval('audit.accounts__establishments_audit_id_seq', 1, false);


--
-- TOC entry 7486 (class 0 OID 0)
-- Dependencies: 298
-- Name: accounts__features_audit_id_seq; Type: SEQUENCE SET; Schema: audit; Owner: postgres
--

SELECT pg_catalog.setval('audit.accounts__features_audit_id_seq', 1, false);


--
-- TOC entry 7487 (class 0 OID 0)
-- Dependencies: 301
-- Name: accounts__modules_audit_id_seq; Type: SEQUENCE SET; Schema: audit; Owner: postgres
--

SELECT pg_catalog.setval('audit.accounts__modules_audit_id_seq', 1, false);


--
-- TOC entry 7488 (class 0 OID 0)
-- Dependencies: 304
-- Name: accounts__platforms_audit_id_seq; Type: SEQUENCE SET; Schema: audit; Owner: postgres
--

SELECT pg_catalog.setval('audit.accounts__platforms_audit_id_seq', 1, false);


--
-- TOC entry 7489 (class 0 OID 0)
-- Dependencies: 307
-- Name: accounts__role_features_audit_id_seq; Type: SEQUENCE SET; Schema: audit; Owner: postgres
--

SELECT pg_catalog.setval('audit.accounts__role_features_audit_id_seq', 1, false);


--
-- TOC entry 7490 (class 0 OID 0)
-- Dependencies: 310
-- Name: accounts__roles_audit_id_seq; Type: SEQUENCE SET; Schema: audit; Owner: postgres
--

SELECT pg_catalog.setval('audit.accounts__roles_audit_id_seq', 1, false);


--
-- TOC entry 7491 (class 0 OID 0)
-- Dependencies: 313
-- Name: accounts__suppliers_audit_id_seq; Type: SEQUENCE SET; Schema: audit; Owner: postgres
--

SELECT pg_catalog.setval('audit.accounts__suppliers_audit_id_seq', 1, false);


--
-- TOC entry 7492 (class 0 OID 0)
-- Dependencies: 316
-- Name: accounts__users_audit_id_seq; Type: SEQUENCE SET; Schema: audit; Owner: postgres
--

SELECT pg_catalog.setval('audit.accounts__users_audit_id_seq', 1, false);


--
-- TOC entry 7493 (class 0 OID 0)
-- Dependencies: 319
-- Name: catalogs__brands_audit_id_seq; Type: SEQUENCE SET; Schema: audit; Owner: postgres
--

SELECT pg_catalog.setval('audit.catalogs__brands_audit_id_seq', 1, false);


--
-- TOC entry 7494 (class 0 OID 0)
-- Dependencies: 322
-- Name: catalogs__categories_audit_id_seq; Type: SEQUENCE SET; Schema: audit; Owner: postgres
--

SELECT pg_catalog.setval('audit.catalogs__categories_audit_id_seq', 1, false);


--
-- TOC entry 7495 (class 0 OID 0)
-- Dependencies: 325
-- Name: catalogs__compositions_audit_id_seq; Type: SEQUENCE SET; Schema: audit; Owner: postgres
--

SELECT pg_catalog.setval('audit.catalogs__compositions_audit_id_seq', 1, false);


--
-- TOC entry 7496 (class 0 OID 0)
-- Dependencies: 328
-- Name: catalogs__fillings_audit_id_seq; Type: SEQUENCE SET; Schema: audit; Owner: postgres
--

SELECT pg_catalog.setval('audit.catalogs__fillings_audit_id_seq', 1, false);


--
-- TOC entry 7497 (class 0 OID 0)
-- Dependencies: 331
-- Name: catalogs__flavors_audit_id_seq; Type: SEQUENCE SET; Schema: audit; Owner: postgres
--

SELECT pg_catalog.setval('audit.catalogs__flavors_audit_id_seq', 1, false);


--
-- TOC entry 7498 (class 0 OID 0)
-- Dependencies: 334
-- Name: catalogs__formats_audit_id_seq; Type: SEQUENCE SET; Schema: audit; Owner: postgres
--

SELECT pg_catalog.setval('audit.catalogs__formats_audit_id_seq', 1, false);


--
-- TOC entry 7499 (class 0 OID 0)
-- Dependencies: 337
-- Name: catalogs__items_audit_id_seq; Type: SEQUENCE SET; Schema: audit; Owner: postgres
--

SELECT pg_catalog.setval('audit.catalogs__items_audit_id_seq', 1, false);


--
-- TOC entry 7500 (class 0 OID 0)
-- Dependencies: 340
-- Name: catalogs__nutritional_variants_audit_id_seq; Type: SEQUENCE SET; Schema: audit; Owner: postgres
--

SELECT pg_catalog.setval('audit.catalogs__nutritional_variants_audit_id_seq', 1, false);


--
-- TOC entry 7501 (class 0 OID 0)
-- Dependencies: 343
-- Name: catalogs__offers_audit_id_seq; Type: SEQUENCE SET; Schema: audit; Owner: postgres
--

SELECT pg_catalog.setval('audit.catalogs__offers_audit_id_seq', 1, false);


--
-- TOC entry 7502 (class 0 OID 0)
-- Dependencies: 346
-- Name: catalogs__packagings_audit_id_seq; Type: SEQUENCE SET; Schema: audit; Owner: postgres
--

SELECT pg_catalog.setval('audit.catalogs__packagings_audit_id_seq', 1, false);


--
-- TOC entry 7503 (class 0 OID 0)
-- Dependencies: 349
-- Name: catalogs__products_audit_id_seq; Type: SEQUENCE SET; Schema: audit; Owner: postgres
--

SELECT pg_catalog.setval('audit.catalogs__products_audit_id_seq', 1, false);


--
-- TOC entry 7504 (class 0 OID 0)
-- Dependencies: 352
-- Name: catalogs__quantities_audit_id_seq; Type: SEQUENCE SET; Schema: audit; Owner: postgres
--

SELECT pg_catalog.setval('audit.catalogs__quantities_audit_id_seq', 1, false);


--
-- TOC entry 7505 (class 0 OID 0)
-- Dependencies: 355
-- Name: catalogs__subcategories_audit_id_seq; Type: SEQUENCE SET; Schema: audit; Owner: postgres
--

SELECT pg_catalog.setval('audit.catalogs__subcategories_audit_id_seq', 1, false);


--
-- TOC entry 7506 (class 0 OID 0)
-- Dependencies: 358
-- Name: catalogs__variant_types_audit_id_seq; Type: SEQUENCE SET; Schema: audit; Owner: postgres
--

SELECT pg_catalog.setval('audit.catalogs__variant_types_audit_id_seq', 1, false);


--
-- TOC entry 7507 (class 0 OID 0)
-- Dependencies: 388
-- Name: quotation__quotation_submissions_audit_id_seq; Type: SEQUENCE SET; Schema: audit; Owner: postgres
--

SELECT pg_catalog.setval('audit.quotation__quotation_submissions_audit_id_seq', 1, false);


--
-- TOC entry 7508 (class 0 OID 0)
-- Dependencies: 394
-- Name: quotation__quoted_prices_audit_id_seq; Type: SEQUENCE SET; Schema: audit; Owner: postgres
--

SELECT pg_catalog.setval('audit.quotation__quoted_prices_audit_id_seq', 1, false);


--
-- TOC entry 7509 (class 0 OID 0)
-- Dependencies: 385
-- Name: quotation__shopping_list_items_audit_id_seq; Type: SEQUENCE SET; Schema: audit; Owner: postgres
--

SELECT pg_catalog.setval('audit.quotation__shopping_list_items_audit_id_seq', 1, false);


--
-- TOC entry 7510 (class 0 OID 0)
-- Dependencies: 382
-- Name: quotation__shopping_lists_audit_id_seq; Type: SEQUENCE SET; Schema: audit; Owner: postgres
--

SELECT pg_catalog.setval('audit.quotation__shopping_lists_audit_id_seq', 1, false);


--
-- TOC entry 7511 (class 0 OID 0)
-- Dependencies: 376
-- Name: quotation__submission_statuses_audit_id_seq; Type: SEQUENCE SET; Schema: audit; Owner: postgres
--

SELECT pg_catalog.setval('audit.quotation__submission_statuses_audit_id_seq', 1, false);


--
-- TOC entry 7512 (class 0 OID 0)
-- Dependencies: 379
-- Name: quotation__supplier_quotation_statuses_audit_id_seq; Type: SEQUENCE SET; Schema: audit; Owner: postgres
--

SELECT pg_catalog.setval('audit.quotation__supplier_quotation_statuses_audit_id_seq', 1, false);


--
-- TOC entry 7513 (class 0 OID 0)
-- Dependencies: 391
-- Name: quotation__supplier_quotations_audit_id_seq; Type: SEQUENCE SET; Schema: audit; Owner: postgres
--

SELECT pg_catalog.setval('audit.quotation__supplier_quotations_audit_id_seq', 1, false);


--
-- TOC entry 5373 (class 2606 OID 17705)
-- Name: api_keys api_keys_pkey; Type: CONSTRAINT; Schema: accounts; Owner: postgres
--

ALTER TABLE ONLY accounts.api_keys
    ADD CONSTRAINT api_keys_pkey PRIMARY KEY (api_key_id);


--
-- TOC entry 5375 (class 2606 OID 17717)
-- Name: api_scopes api_scopes_pkey; Type: CONSTRAINT; Schema: accounts; Owner: postgres
--

ALTER TABLE ONLY accounts.api_scopes
    ADD CONSTRAINT api_scopes_pkey PRIMARY KEY (api_scope_id);


--
-- TOC entry 5370 (class 2606 OID 17428)
-- Name: apis apis_pkey; Type: CONSTRAINT; Schema: accounts; Owner: postgres
--

ALTER TABLE ONLY accounts.apis
    ADD CONSTRAINT apis_pkey PRIMARY KEY (api_id);


--
-- TOC entry 5796 (class 2606 OID 21220)
-- Name: employee_addresses employee_addresses_pkey; Type: CONSTRAINT; Schema: accounts; Owner: postgres
--

ALTER TABLE ONLY accounts.employee_addresses
    ADD CONSTRAINT employee_addresses_pkey PRIMARY KEY (employee_address_id);


--
-- TOC entry 5798 (class 2606 OID 21222)
-- Name: employee_addresses employee_addresses_primary_unique; Type: CONSTRAINT; Schema: accounts; Owner: postgres
--

ALTER TABLE ONLY accounts.employee_addresses
    ADD CONSTRAINT employee_addresses_primary_unique UNIQUE (employee_id, is_primary) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 5786 (class 2606 OID 21196)
-- Name: employee_personal_data employee_personal_data_cpf_unique; Type: CONSTRAINT; Schema: accounts; Owner: postgres
--

ALTER TABLE ONLY accounts.employee_personal_data
    ADD CONSTRAINT employee_personal_data_cpf_unique UNIQUE (cpf);


--
-- TOC entry 5788 (class 2606 OID 21198)
-- Name: employee_personal_data employee_personal_data_employee_id_unique; Type: CONSTRAINT; Schema: accounts; Owner: postgres
--

ALTER TABLE ONLY accounts.employee_personal_data
    ADD CONSTRAINT employee_personal_data_employee_id_unique UNIQUE (employee_id);


--
-- TOC entry 5790 (class 2606 OID 21194)
-- Name: employee_personal_data employee_personal_data_pkey; Type: CONSTRAINT; Schema: accounts; Owner: postgres
--

ALTER TABLE ONLY accounts.employee_personal_data
    ADD CONSTRAINT employee_personal_data_pkey PRIMARY KEY (employee_personal_data_id);


--
-- TOC entry 5366 (class 2606 OID 17404)
-- Name: employee_roles employee_roles_pkey; Type: CONSTRAINT; Schema: accounts; Owner: postgres
--

ALTER TABLE ONLY accounts.employee_roles
    ADD CONSTRAINT employee_roles_pkey PRIMARY KEY (employee_role_id);


--
-- TOC entry 5342 (class 2606 OID 17281)
-- Name: employees employees_pkey; Type: CONSTRAINT; Schema: accounts; Owner: postgres
--

ALTER TABLE ONLY accounts.employees
    ADD CONSTRAINT employees_pkey PRIMARY KEY (employee_id);


--
-- TOC entry 5432 (class 2606 OID 18346)
-- Name: establishment_addresses establishment_addresses_pkey; Type: CONSTRAINT; Schema: accounts; Owner: postgres
--

ALTER TABLE ONLY accounts.establishment_addresses
    ADD CONSTRAINT establishment_addresses_pkey PRIMARY KEY (establishment_address_id);


--
-- TOC entry 5423 (class 2606 OID 18327)
-- Name: establishment_business_data establishment_business_data_cnpj_unique; Type: CONSTRAINT; Schema: accounts; Owner: postgres
--

ALTER TABLE ONLY accounts.establishment_business_data
    ADD CONSTRAINT establishment_business_data_cnpj_unique UNIQUE (cnpj);


--
-- TOC entry 5425 (class 2606 OID 18329)
-- Name: establishment_business_data establishment_business_data_establishment_id_unique; Type: CONSTRAINT; Schema: accounts; Owner: postgres
--

ALTER TABLE ONLY accounts.establishment_business_data
    ADD CONSTRAINT establishment_business_data_establishment_id_unique UNIQUE (establishment_id);


--
-- TOC entry 5427 (class 2606 OID 18325)
-- Name: establishment_business_data establishment_business_data_pkey; Type: CONSTRAINT; Schema: accounts; Owner: postgres
--

ALTER TABLE ONLY accounts.establishment_business_data
    ADD CONSTRAINT establishment_business_data_pkey PRIMARY KEY (establishment_business_data_id);


--
-- TOC entry 5340 (class 2606 OID 17266)
-- Name: establishments establishments_pkey; Type: CONSTRAINT; Schema: accounts; Owner: postgres
--

ALTER TABLE ONLY accounts.establishments
    ADD CONSTRAINT establishments_pkey PRIMARY KEY (establishment_id);


--
-- TOC entry 5353 (class 2606 OID 17349)
-- Name: features features_code_key; Type: CONSTRAINT; Schema: accounts; Owner: postgres
--

ALTER TABLE ONLY accounts.features
    ADD CONSTRAINT features_code_key UNIQUE (code);


--
-- TOC entry 5355 (class 2606 OID 17347)
-- Name: features features_pkey; Type: CONSTRAINT; Schema: accounts; Owner: postgres
--

ALTER TABLE ONLY accounts.features
    ADD CONSTRAINT features_pkey PRIMARY KEY (feature_id);


--
-- TOC entry 5349 (class 2606 OID 17328)
-- Name: modules modules_name_key; Type: CONSTRAINT; Schema: accounts; Owner: postgres
--

ALTER TABLE ONLY accounts.modules
    ADD CONSTRAINT modules_name_key UNIQUE (name);


--
-- TOC entry 5351 (class 2606 OID 17326)
-- Name: modules modules_pkey; Type: CONSTRAINT; Schema: accounts; Owner: postgres
--

ALTER TABLE ONLY accounts.modules
    ADD CONSTRAINT modules_pkey PRIMARY KEY (module_id);


--
-- TOC entry 5345 (class 2606 OID 17312)
-- Name: platforms platforms_name_key; Type: CONSTRAINT; Schema: accounts; Owner: postgres
--

ALTER TABLE ONLY accounts.platforms
    ADD CONSTRAINT platforms_name_key UNIQUE (name);


--
-- TOC entry 5347 (class 2606 OID 17310)
-- Name: platforms platforms_pkey; Type: CONSTRAINT; Schema: accounts; Owner: postgres
--

ALTER TABLE ONLY accounts.platforms
    ADD CONSTRAINT platforms_pkey PRIMARY KEY (platform_id);


--
-- TOC entry 5364 (class 2606 OID 17382)
-- Name: role_features role_features_pkey; Type: CONSTRAINT; Schema: accounts; Owner: postgres
--

ALTER TABLE ONLY accounts.role_features
    ADD CONSTRAINT role_features_pkey PRIMARY KEY (role_feature_id);


--
-- TOC entry 5359 (class 2606 OID 17370)
-- Name: roles roles_name_key; Type: CONSTRAINT; Schema: accounts; Owner: postgres
--

ALTER TABLE ONLY accounts.roles
    ADD CONSTRAINT roles_name_key UNIQUE (name);


--
-- TOC entry 5361 (class 2606 OID 17368)
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: accounts; Owner: postgres
--

ALTER TABLE ONLY accounts.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (role_id);


--
-- TOC entry 5338 (class 2606 OID 17250)
-- Name: suppliers suppliers_pkey; Type: CONSTRAINT; Schema: accounts; Owner: postgres
--

ALTER TABLE ONLY accounts.suppliers
    ADD CONSTRAINT suppliers_pkey PRIMARY KEY (supplier_id);


--
-- TOC entry 5332 (class 2606 OID 17239)
-- Name: users users_cognito_sub_key; Type: CONSTRAINT; Schema: accounts; Owner: postgres
--

ALTER TABLE ONLY accounts.users
    ADD CONSTRAINT users_cognito_sub_key UNIQUE (cognito_sub);


--
-- TOC entry 5334 (class 2606 OID 17237)
-- Name: users users_email_key; Type: CONSTRAINT; Schema: accounts; Owner: postgres
--

ALTER TABLE ONLY accounts.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- TOC entry 5336 (class 2606 OID 17235)
-- Name: users users_pkey; Type: CONSTRAINT; Schema: accounts; Owner: postgres
--

ALTER TABLE ONLY accounts.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (user_id);


--
-- TOC entry 5438 (class 2606 OID 20093)
-- Name: accounts__api_keys accounts__api_keys_pkey; Type: CONSTRAINT; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.accounts__api_keys
    ADD CONSTRAINT accounts__api_keys_pkey PRIMARY KEY (audit_id, audit_partition_date);


--
-- TOC entry 5448 (class 2606 OID 20109)
-- Name: accounts__api_keys_2025_08 accounts__api_keys_2025_08_pkey; Type: CONSTRAINT; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.accounts__api_keys_2025_08
    ADD CONSTRAINT accounts__api_keys_2025_08_pkey PRIMARY KEY (audit_id, audit_partition_date);


--
-- TOC entry 5450 (class 2606 OID 20126)
-- Name: accounts__api_scopes accounts__api_scopes_pkey; Type: CONSTRAINT; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.accounts__api_scopes
    ADD CONSTRAINT accounts__api_scopes_pkey PRIMARY KEY (audit_id, audit_partition_date);


--
-- TOC entry 5462 (class 2606 OID 20143)
-- Name: accounts__api_scopes_2025_08 accounts__api_scopes_2025_08_pkey; Type: CONSTRAINT; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.accounts__api_scopes_2025_08
    ADD CONSTRAINT accounts__api_scopes_2025_08_pkey PRIMARY KEY (audit_id, audit_partition_date);


--
-- TOC entry 5464 (class 2606 OID 20161)
-- Name: accounts__apis accounts__apis_pkey; Type: CONSTRAINT; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.accounts__apis
    ADD CONSTRAINT accounts__apis_pkey PRIMARY KEY (audit_id, audit_partition_date);


--
-- TOC entry 5474 (class 2606 OID 20177)
-- Name: accounts__apis_2025_08 accounts__apis_2025_08_pkey; Type: CONSTRAINT; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.accounts__apis_2025_08
    ADD CONSTRAINT accounts__apis_2025_08_pkey PRIMARY KEY (audit_id, audit_partition_date);


--
-- TOC entry 5817 (class 2606 OID 21295)
-- Name: accounts__employee_addresses accounts__employee_addresses_pkey; Type: CONSTRAINT; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.accounts__employee_addresses
    ADD CONSTRAINT accounts__employee_addresses_pkey PRIMARY KEY (audit_id, audit_partition_date);


--
-- TOC entry 5827 (class 2606 OID 21311)
-- Name: accounts__employee_addresses_2025_08 accounts__employee_addresses_2025_08_pkey; Type: CONSTRAINT; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.accounts__employee_addresses_2025_08
    ADD CONSTRAINT accounts__employee_addresses_2025_08_pkey PRIMARY KEY (audit_id, audit_partition_date);


--
-- TOC entry 5805 (class 2606 OID 21262)
-- Name: accounts__employee_personal_data accounts__employee_personal_data_pkey; Type: CONSTRAINT; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.accounts__employee_personal_data
    ADD CONSTRAINT accounts__employee_personal_data_pkey PRIMARY KEY (audit_id, audit_partition_date);


--
-- TOC entry 5814 (class 2606 OID 21278)
-- Name: accounts__employee_personal_data_2025_08 accounts__employee_personal_data_2025_08_pkey; Type: CONSTRAINT; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.accounts__employee_personal_data_2025_08
    ADD CONSTRAINT accounts__employee_personal_data_2025_08_pkey PRIMARY KEY (audit_id, audit_partition_date);


--
-- TOC entry 5476 (class 2606 OID 20194)
-- Name: accounts__employee_roles accounts__employee_roles_pkey; Type: CONSTRAINT; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.accounts__employee_roles
    ADD CONSTRAINT accounts__employee_roles_pkey PRIMARY KEY (audit_id, audit_partition_date);


--
-- TOC entry 5487 (class 2606 OID 20211)
-- Name: accounts__employee_roles_2025_08 accounts__employee_roles_2025_08_pkey; Type: CONSTRAINT; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.accounts__employee_roles_2025_08
    ADD CONSTRAINT accounts__employee_roles_2025_08_pkey PRIMARY KEY (audit_id, audit_partition_date);


--
-- TOC entry 5490 (class 2606 OID 20229)
-- Name: accounts__employees accounts__employees_pkey; Type: CONSTRAINT; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.accounts__employees
    ADD CONSTRAINT accounts__employees_pkey PRIMARY KEY (audit_id, audit_partition_date);


--
-- TOC entry 5502 (class 2606 OID 20247)
-- Name: accounts__employees_2025_08 accounts__employees_2025_08_pkey; Type: CONSTRAINT; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.accounts__employees_2025_08
    ADD CONSTRAINT accounts__employees_2025_08_pkey PRIMARY KEY (audit_id, audit_partition_date);


--
-- TOC entry 5506 (class 2606 OID 20266)
-- Name: accounts__establishment_addresses accounts__establishment_addresses_pkey; Type: CONSTRAINT; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.accounts__establishment_addresses
    ADD CONSTRAINT accounts__establishment_addresses_pkey PRIMARY KEY (audit_id, audit_partition_date);


--
-- TOC entry 5515 (class 2606 OID 20282)
-- Name: accounts__establishment_addresses_2025_08 accounts__establishment_addresses_2025_08_pkey; Type: CONSTRAINT; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.accounts__establishment_addresses_2025_08
    ADD CONSTRAINT accounts__establishment_addresses_2025_08_pkey PRIMARY KEY (audit_id, audit_partition_date);


--
-- TOC entry 5518 (class 2606 OID 20299)
-- Name: accounts__establishment_business_data accounts__establishment_business_data_pkey; Type: CONSTRAINT; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.accounts__establishment_business_data
    ADD CONSTRAINT accounts__establishment_business_data_pkey PRIMARY KEY (audit_id, audit_partition_date);


--
-- TOC entry 5525 (class 2606 OID 20315)
-- Name: accounts__establishment_business_data_2025_08 accounts__establishment_business_data_2025_08_pkey; Type: CONSTRAINT; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.accounts__establishment_business_data_2025_08
    ADD CONSTRAINT accounts__establishment_business_data_2025_08_pkey PRIMARY KEY (audit_id, audit_partition_date);


--
-- TOC entry 5530 (class 2606 OID 20332)
-- Name: accounts__establishments accounts__establishments_pkey; Type: CONSTRAINT; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.accounts__establishments
    ADD CONSTRAINT accounts__establishments_pkey PRIMARY KEY (audit_id, audit_partition_date);


--
-- TOC entry 5538 (class 2606 OID 20347)
-- Name: accounts__establishments_2025_08 accounts__establishments_2025_08_pkey; Type: CONSTRAINT; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.accounts__establishments_2025_08
    ADD CONSTRAINT accounts__establishments_2025_08_pkey PRIMARY KEY (audit_id, audit_partition_date);


--
-- TOC entry 5540 (class 2606 OID 20363)
-- Name: accounts__features accounts__features_pkey; Type: CONSTRAINT; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.accounts__features
    ADD CONSTRAINT accounts__features_pkey PRIMARY KEY (audit_id, audit_partition_date);


--
-- TOC entry 5551 (class 2606 OID 20380)
-- Name: accounts__features_2025_08 accounts__features_2025_08_pkey; Type: CONSTRAINT; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.accounts__features_2025_08
    ADD CONSTRAINT accounts__features_2025_08_pkey PRIMARY KEY (audit_id, audit_partition_date);


--
-- TOC entry 5554 (class 2606 OID 20398)
-- Name: accounts__modules accounts__modules_pkey; Type: CONSTRAINT; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.accounts__modules
    ADD CONSTRAINT accounts__modules_pkey PRIMARY KEY (audit_id, audit_partition_date);


--
-- TOC entry 5562 (class 2606 OID 20413)
-- Name: accounts__modules_2025_08 accounts__modules_2025_08_pkey; Type: CONSTRAINT; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.accounts__modules_2025_08
    ADD CONSTRAINT accounts__modules_2025_08_pkey PRIMARY KEY (audit_id, audit_partition_date);


--
-- TOC entry 5564 (class 2606 OID 20429)
-- Name: accounts__platforms accounts__platforms_pkey; Type: CONSTRAINT; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.accounts__platforms
    ADD CONSTRAINT accounts__platforms_pkey PRIMARY KEY (audit_id, audit_partition_date);


--
-- TOC entry 5571 (class 2606 OID 20444)
-- Name: accounts__platforms_2025_08 accounts__platforms_2025_08_pkey; Type: CONSTRAINT; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.accounts__platforms_2025_08
    ADD CONSTRAINT accounts__platforms_2025_08_pkey PRIMARY KEY (audit_id, audit_partition_date);


--
-- TOC entry 5574 (class 2606 OID 20460)
-- Name: accounts__role_features accounts__role_features_pkey; Type: CONSTRAINT; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.accounts__role_features
    ADD CONSTRAINT accounts__role_features_pkey PRIMARY KEY (audit_id, audit_partition_date);


--
-- TOC entry 5584 (class 2606 OID 20477)
-- Name: accounts__role_features_2025_08 accounts__role_features_2025_08_pkey; Type: CONSTRAINT; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.accounts__role_features_2025_08
    ADD CONSTRAINT accounts__role_features_2025_08_pkey PRIMARY KEY (audit_id, audit_partition_date);


--
-- TOC entry 5588 (class 2606 OID 20495)
-- Name: accounts__roles accounts__roles_pkey; Type: CONSTRAINT; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.accounts__roles
    ADD CONSTRAINT accounts__roles_pkey PRIMARY KEY (audit_id, audit_partition_date);


--
-- TOC entry 5595 (class 2606 OID 20510)
-- Name: accounts__roles_2025_08 accounts__roles_2025_08_pkey; Type: CONSTRAINT; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.accounts__roles_2025_08
    ADD CONSTRAINT accounts__roles_2025_08_pkey PRIMARY KEY (audit_id, audit_partition_date);


--
-- TOC entry 5598 (class 2606 OID 20526)
-- Name: accounts__suppliers accounts__suppliers_pkey; Type: CONSTRAINT; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.accounts__suppliers
    ADD CONSTRAINT accounts__suppliers_pkey PRIMARY KEY (audit_id, audit_partition_date);


--
-- TOC entry 5605 (class 2606 OID 20541)
-- Name: accounts__suppliers_2025_08 accounts__suppliers_2025_08_pkey; Type: CONSTRAINT; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.accounts__suppliers_2025_08
    ADD CONSTRAINT accounts__suppliers_2025_08_pkey PRIMARY KEY (audit_id, audit_partition_date);


--
-- TOC entry 5608 (class 2606 OID 20557)
-- Name: accounts__users accounts__users_pkey; Type: CONSTRAINT; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.accounts__users
    ADD CONSTRAINT accounts__users_pkey PRIMARY KEY (audit_id, audit_partition_date);


--
-- TOC entry 5615 (class 2606 OID 20572)
-- Name: accounts__users_2025_08 accounts__users_2025_08_pkey; Type: CONSTRAINT; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.accounts__users_2025_08
    ADD CONSTRAINT accounts__users_2025_08_pkey PRIMARY KEY (audit_id, audit_partition_date);


--
-- TOC entry 5618 (class 2606 OID 20588)
-- Name: catalogs__brands catalogs__brands_pkey; Type: CONSTRAINT; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.catalogs__brands
    ADD CONSTRAINT catalogs__brands_pkey PRIMARY KEY (audit_id, audit_partition_date);


--
-- TOC entry 5626 (class 2606 OID 20603)
-- Name: catalogs__brands_2025_08 catalogs__brands_2025_08_pkey; Type: CONSTRAINT; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.catalogs__brands_2025_08
    ADD CONSTRAINT catalogs__brands_2025_08_pkey PRIMARY KEY (audit_id, audit_partition_date);


--
-- TOC entry 5628 (class 2606 OID 20619)
-- Name: catalogs__categories catalogs__categories_pkey; Type: CONSTRAINT; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.catalogs__categories
    ADD CONSTRAINT catalogs__categories_pkey PRIMARY KEY (audit_id, audit_partition_date);


--
-- TOC entry 5636 (class 2606 OID 20634)
-- Name: catalogs__categories_2025_08 catalogs__categories_2025_08_pkey; Type: CONSTRAINT; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.catalogs__categories_2025_08
    ADD CONSTRAINT catalogs__categories_2025_08_pkey PRIMARY KEY (audit_id, audit_partition_date);


--
-- TOC entry 5638 (class 2606 OID 20650)
-- Name: catalogs__compositions catalogs__compositions_pkey; Type: CONSTRAINT; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.catalogs__compositions
    ADD CONSTRAINT catalogs__compositions_pkey PRIMARY KEY (audit_id, audit_partition_date);


--
-- TOC entry 5646 (class 2606 OID 20665)
-- Name: catalogs__compositions_2025_08 catalogs__compositions_2025_08_pkey; Type: CONSTRAINT; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.catalogs__compositions_2025_08
    ADD CONSTRAINT catalogs__compositions_2025_08_pkey PRIMARY KEY (audit_id, audit_partition_date);


--
-- TOC entry 5648 (class 2606 OID 20681)
-- Name: catalogs__fillings catalogs__fillings_pkey; Type: CONSTRAINT; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.catalogs__fillings
    ADD CONSTRAINT catalogs__fillings_pkey PRIMARY KEY (audit_id, audit_partition_date);


--
-- TOC entry 5656 (class 2606 OID 20696)
-- Name: catalogs__fillings_2025_08 catalogs__fillings_2025_08_pkey; Type: CONSTRAINT; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.catalogs__fillings_2025_08
    ADD CONSTRAINT catalogs__fillings_2025_08_pkey PRIMARY KEY (audit_id, audit_partition_date);


--
-- TOC entry 5658 (class 2606 OID 20712)
-- Name: catalogs__flavors catalogs__flavors_pkey; Type: CONSTRAINT; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.catalogs__flavors
    ADD CONSTRAINT catalogs__flavors_pkey PRIMARY KEY (audit_id, audit_partition_date);


--
-- TOC entry 5666 (class 2606 OID 20727)
-- Name: catalogs__flavors_2025_08 catalogs__flavors_2025_08_pkey; Type: CONSTRAINT; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.catalogs__flavors_2025_08
    ADD CONSTRAINT catalogs__flavors_2025_08_pkey PRIMARY KEY (audit_id, audit_partition_date);


--
-- TOC entry 5668 (class 2606 OID 20743)
-- Name: catalogs__formats catalogs__formats_pkey; Type: CONSTRAINT; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.catalogs__formats
    ADD CONSTRAINT catalogs__formats_pkey PRIMARY KEY (audit_id, audit_partition_date);


--
-- TOC entry 5676 (class 2606 OID 20758)
-- Name: catalogs__formats_2025_08 catalogs__formats_2025_08_pkey; Type: CONSTRAINT; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.catalogs__formats_2025_08
    ADD CONSTRAINT catalogs__formats_2025_08_pkey PRIMARY KEY (audit_id, audit_partition_date);


--
-- TOC entry 5678 (class 2606 OID 20774)
-- Name: catalogs__items catalogs__items_pkey; Type: CONSTRAINT; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.catalogs__items
    ADD CONSTRAINT catalogs__items_pkey PRIMARY KEY (audit_id, audit_partition_date);


--
-- TOC entry 5687 (class 2606 OID 20790)
-- Name: catalogs__items_2025_08 catalogs__items_2025_08_pkey; Type: CONSTRAINT; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.catalogs__items_2025_08
    ADD CONSTRAINT catalogs__items_2025_08_pkey PRIMARY KEY (audit_id, audit_partition_date);


--
-- TOC entry 5690 (class 2606 OID 20807)
-- Name: catalogs__nutritional_variants catalogs__nutritional_variants_pkey; Type: CONSTRAINT; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.catalogs__nutritional_variants
    ADD CONSTRAINT catalogs__nutritional_variants_pkey PRIMARY KEY (audit_id, audit_partition_date);


--
-- TOC entry 5697 (class 2606 OID 20822)
-- Name: catalogs__nutritional_variants_2025_08 catalogs__nutritional_variants_2025_08_pkey; Type: CONSTRAINT; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.catalogs__nutritional_variants_2025_08
    ADD CONSTRAINT catalogs__nutritional_variants_2025_08_pkey PRIMARY KEY (audit_id, audit_partition_date);


--
-- TOC entry 5700 (class 2606 OID 20838)
-- Name: catalogs__offers catalogs__offers_pkey; Type: CONSTRAINT; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.catalogs__offers
    ADD CONSTRAINT catalogs__offers_pkey PRIMARY KEY (audit_id, audit_partition_date);


--
-- TOC entry 5710 (class 2606 OID 20855)
-- Name: catalogs__offers_2025_08 catalogs__offers_2025_08_pkey; Type: CONSTRAINT; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.catalogs__offers_2025_08
    ADD CONSTRAINT catalogs__offers_2025_08_pkey PRIMARY KEY (audit_id, audit_partition_date);


--
-- TOC entry 5714 (class 2606 OID 20873)
-- Name: catalogs__packagings catalogs__packagings_pkey; Type: CONSTRAINT; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.catalogs__packagings
    ADD CONSTRAINT catalogs__packagings_pkey PRIMARY KEY (audit_id, audit_partition_date);


--
-- TOC entry 5722 (class 2606 OID 20888)
-- Name: catalogs__packagings_2025_08 catalogs__packagings_2025_08_pkey; Type: CONSTRAINT; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.catalogs__packagings_2025_08
    ADD CONSTRAINT catalogs__packagings_2025_08_pkey PRIMARY KEY (audit_id, audit_partition_date);


--
-- TOC entry 5724 (class 2606 OID 20904)
-- Name: catalogs__products catalogs__products_pkey; Type: CONSTRAINT; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.catalogs__products
    ADD CONSTRAINT catalogs__products_pkey PRIMARY KEY (audit_id, audit_partition_date);


--
-- TOC entry 5749 (class 2606 OID 20929)
-- Name: catalogs__products_2025_08 catalogs__products_2025_08_pkey; Type: CONSTRAINT; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.catalogs__products_2025_08
    ADD CONSTRAINT catalogs__products_2025_08_pkey PRIMARY KEY (audit_id, audit_partition_date);


--
-- TOC entry 5754 (class 2606 OID 20955)
-- Name: catalogs__quantities catalogs__quantities_pkey; Type: CONSTRAINT; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.catalogs__quantities
    ADD CONSTRAINT catalogs__quantities_pkey PRIMARY KEY (audit_id, audit_partition_date);


--
-- TOC entry 5761 (class 2606 OID 20970)
-- Name: catalogs__quantities_2025_08 catalogs__quantities_2025_08_pkey; Type: CONSTRAINT; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.catalogs__quantities_2025_08
    ADD CONSTRAINT catalogs__quantities_2025_08_pkey PRIMARY KEY (audit_id, audit_partition_date);


--
-- TOC entry 5764 (class 2606 OID 20986)
-- Name: catalogs__subcategories catalogs__subcategories_pkey; Type: CONSTRAINT; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.catalogs__subcategories
    ADD CONSTRAINT catalogs__subcategories_pkey PRIMARY KEY (audit_id, audit_partition_date);


--
-- TOC entry 5773 (class 2606 OID 21002)
-- Name: catalogs__subcategories_2025_08 catalogs__subcategories_2025_08_pkey; Type: CONSTRAINT; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.catalogs__subcategories_2025_08
    ADD CONSTRAINT catalogs__subcategories_2025_08_pkey PRIMARY KEY (audit_id, audit_partition_date);


--
-- TOC entry 5776 (class 2606 OID 21019)
-- Name: catalogs__variant_types catalogs__variant_types_pkey; Type: CONSTRAINT; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.catalogs__variant_types
    ADD CONSTRAINT catalogs__variant_types_pkey PRIMARY KEY (audit_id, audit_partition_date);


--
-- TOC entry 5783 (class 2606 OID 21034)
-- Name: catalogs__variant_types_2025_08 catalogs__variant_types_2025_08_pkey; Type: CONSTRAINT; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.catalogs__variant_types_2025_08
    ADD CONSTRAINT catalogs__variant_types_2025_08_pkey PRIMARY KEY (audit_id, audit_partition_date);


--
-- TOC entry 5937 (class 2606 OID 21705)
-- Name: quotation__quotation_submissions quotation__quotation_submissions_pkey; Type: CONSTRAINT; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.quotation__quotation_submissions
    ADD CONSTRAINT quotation__quotation_submissions_pkey PRIMARY KEY (audit_id, audit_partition_date);


--
-- TOC entry 5941 (class 2606 OID 21722)
-- Name: quotation__quotation_submissions_2025_08 quotation__quotation_submissions_2025_08_pkey; Type: CONSTRAINT; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.quotation__quotation_submissions_2025_08
    ADD CONSTRAINT quotation__quotation_submissions_2025_08_pkey PRIMARY KEY (audit_id, audit_partition_date);


--
-- TOC entry 5968 (class 2606 OID 21779)
-- Name: quotation__quoted_prices quotation__quoted_prices_pkey; Type: CONSTRAINT; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.quotation__quoted_prices
    ADD CONSTRAINT quotation__quoted_prices_pkey PRIMARY KEY (audit_id, audit_partition_date);


--
-- TOC entry 5972 (class 2606 OID 21795)
-- Name: quotation__quoted_prices_2025_08 quotation__quoted_prices_2025_08_pkey; Type: CONSTRAINT; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.quotation__quoted_prices_2025_08
    ADD CONSTRAINT quotation__quoted_prices_2025_08_pkey PRIMARY KEY (audit_id, audit_partition_date);


--
-- TOC entry 5913 (class 2606 OID 21650)
-- Name: quotation__shopping_list_items quotation__shopping_list_items_pkey; Type: CONSTRAINT; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.quotation__shopping_list_items
    ADD CONSTRAINT quotation__shopping_list_items_pkey PRIMARY KEY (audit_id, audit_partition_date);


--
-- TOC entry 5924 (class 2606 OID 21677)
-- Name: quotation__shopping_list_items_2025_08 quotation__shopping_list_items_2025_08_pkey; Type: CONSTRAINT; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.quotation__shopping_list_items_2025_08
    ADD CONSTRAINT quotation__shopping_list_items_2025_08_pkey PRIMARY KEY (audit_id, audit_partition_date);


--
-- TOC entry 5889 (class 2606 OID 21615)
-- Name: quotation__shopping_lists quotation__shopping_lists_pkey; Type: CONSTRAINT; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.quotation__shopping_lists
    ADD CONSTRAINT quotation__shopping_lists_pkey PRIMARY KEY (audit_id, audit_partition_date);


--
-- TOC entry 5895 (class 2606 OID 21632)
-- Name: quotation__shopping_lists_2025_08 quotation__shopping_lists_2025_08_pkey; Type: CONSTRAINT; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.quotation__shopping_lists_2025_08
    ADD CONSTRAINT quotation__shopping_lists_2025_08_pkey PRIMARY KEY (audit_id, audit_partition_date);


--
-- TOC entry 5867 (class 2606 OID 21553)
-- Name: quotation__submission_statuses quotation__submission_statuses_pkey; Type: CONSTRAINT; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.quotation__submission_statuses
    ADD CONSTRAINT quotation__submission_statuses_pkey PRIMARY KEY (audit_id, audit_partition_date);


--
-- TOC entry 5871 (class 2606 OID 21568)
-- Name: quotation__submission_statuses_2025_08 quotation__submission_statuses_2025_08_pkey; Type: CONSTRAINT; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.quotation__submission_statuses_2025_08
    ADD CONSTRAINT quotation__submission_statuses_2025_08_pkey PRIMARY KEY (audit_id, audit_partition_date);


--
-- TOC entry 5877 (class 2606 OID 21584)
-- Name: quotation__supplier_quotation_statuses quotation__supplier_quotation_statuses_pkey; Type: CONSTRAINT; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.quotation__supplier_quotation_statuses
    ADD CONSTRAINT quotation__supplier_quotation_statuses_pkey PRIMARY KEY (audit_id, audit_partition_date);


--
-- TOC entry 5879 (class 2606 OID 21599)
-- Name: quotation__supplier_quotation_statuses_2025_08 quotation__supplier_quotation_statuses_2025_08_pkey; Type: CONSTRAINT; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.quotation__supplier_quotation_statuses_2025_08
    ADD CONSTRAINT quotation__supplier_quotation_statuses_2025_08_pkey PRIMARY KEY (audit_id, audit_partition_date);


--
-- TOC entry 5953 (class 2606 OID 21740)
-- Name: quotation__supplier_quotations quotation__supplier_quotations_pkey; Type: CONSTRAINT; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.quotation__supplier_quotations
    ADD CONSTRAINT quotation__supplier_quotations_pkey PRIMARY KEY (audit_id, audit_partition_date);


--
-- TOC entry 5957 (class 2606 OID 21759)
-- Name: quotation__supplier_quotations_2025_08 quotation__supplier_quotations_2025_08_pkey; Type: CONSTRAINT; Schema: audit; Owner: postgres
--

ALTER TABLE ONLY audit.quotation__supplier_quotations_2025_08
    ADD CONSTRAINT quotation__supplier_quotations_2025_08_pkey PRIMARY KEY (audit_id, audit_partition_date);


--
-- TOC entry 5409 (class 2606 OID 18032)
-- Name: brands brands_name_key; Type: CONSTRAINT; Schema: catalogs; Owner: postgres
--

ALTER TABLE ONLY catalogs.brands
    ADD CONSTRAINT brands_name_key UNIQUE (name);


--
-- TOC entry 5411 (class 2606 OID 18030)
-- Name: brands brands_pkey; Type: CONSTRAINT; Schema: catalogs; Owner: postgres
--

ALTER TABLE ONLY catalogs.brands
    ADD CONSTRAINT brands_pkey PRIMARY KEY (brand_id);


--
-- TOC entry 5377 (class 2606 OID 17926)
-- Name: categories categories_name_key; Type: CONSTRAINT; Schema: catalogs; Owner: postgres
--

ALTER TABLE ONLY catalogs.categories
    ADD CONSTRAINT categories_name_key UNIQUE (name);


--
-- TOC entry 5379 (class 2606 OID 17924)
-- Name: categories categories_pkey; Type: CONSTRAINT; Schema: catalogs; Owner: postgres
--

ALTER TABLE ONLY catalogs.categories
    ADD CONSTRAINT categories_pkey PRIMARY KEY (category_id);


--
-- TOC entry 5385 (class 2606 OID 17966)
-- Name: compositions compositions_name_key; Type: CONSTRAINT; Schema: catalogs; Owner: postgres
--

ALTER TABLE ONLY catalogs.compositions
    ADD CONSTRAINT compositions_name_key UNIQUE (name);


--
-- TOC entry 5387 (class 2606 OID 17964)
-- Name: compositions compositions_pkey; Type: CONSTRAINT; Schema: catalogs; Owner: postgres
--

ALTER TABLE ONLY catalogs.compositions
    ADD CONSTRAINT compositions_pkey PRIMARY KEY (composition_id);


--
-- TOC entry 5401 (class 2606 OID 18010)
-- Name: fillings fillings_name_key; Type: CONSTRAINT; Schema: catalogs; Owner: postgres
--

ALTER TABLE ONLY catalogs.fillings
    ADD CONSTRAINT fillings_name_key UNIQUE (name);


--
-- TOC entry 5403 (class 2606 OID 18008)
-- Name: fillings fillings_pkey; Type: CONSTRAINT; Schema: catalogs; Owner: postgres
--

ALTER TABLE ONLY catalogs.fillings
    ADD CONSTRAINT fillings_pkey PRIMARY KEY (filling_id);


--
-- TOC entry 5397 (class 2606 OID 17999)
-- Name: flavors flavors_name_key; Type: CONSTRAINT; Schema: catalogs; Owner: postgres
--

ALTER TABLE ONLY catalogs.flavors
    ADD CONSTRAINT flavors_name_key UNIQUE (name);


--
-- TOC entry 5399 (class 2606 OID 17997)
-- Name: flavors flavors_pkey; Type: CONSTRAINT; Schema: catalogs; Owner: postgres
--

ALTER TABLE ONLY catalogs.flavors
    ADD CONSTRAINT flavors_pkey PRIMARY KEY (flavor_id);


--
-- TOC entry 5393 (class 2606 OID 17988)
-- Name: formats formats_name_key; Type: CONSTRAINT; Schema: catalogs; Owner: postgres
--

ALTER TABLE ONLY catalogs.formats
    ADD CONSTRAINT formats_name_key UNIQUE (name);


--
-- TOC entry 5395 (class 2606 OID 17986)
-- Name: formats formats_pkey; Type: CONSTRAINT; Schema: catalogs; Owner: postgres
--

ALTER TABLE ONLY catalogs.formats
    ADD CONSTRAINT formats_pkey PRIMARY KEY (format_id);


--
-- TOC entry 5383 (class 2606 OID 17949)
-- Name: items items_pkey; Type: CONSTRAINT; Schema: catalogs; Owner: postgres
--

ALTER TABLE ONLY catalogs.items
    ADD CONSTRAINT items_pkey PRIMARY KEY (item_id);


--
-- TOC entry 5405 (class 2606 OID 18021)
-- Name: nutritional_variants nutritional_variants_name_key; Type: CONSTRAINT; Schema: catalogs; Owner: postgres
--

ALTER TABLE ONLY catalogs.nutritional_variants
    ADD CONSTRAINT nutritional_variants_name_key UNIQUE (name);


--
-- TOC entry 5407 (class 2606 OID 18019)
-- Name: nutritional_variants nutritional_variants_pkey; Type: CONSTRAINT; Schema: catalogs; Owner: postgres
--

ALTER TABLE ONLY catalogs.nutritional_variants
    ADD CONSTRAINT nutritional_variants_pkey PRIMARY KEY (nutritional_variant_id);


--
-- TOC entry 5421 (class 2606 OID 18120)
-- Name: offers offers_pkey; Type: CONSTRAINT; Schema: catalogs; Owner: postgres
--

ALTER TABLE ONLY catalogs.offers
    ADD CONSTRAINT offers_pkey PRIMARY KEY (offer_id);


--
-- TOC entry 5413 (class 2606 OID 18043)
-- Name: packagings packagings_name_key; Type: CONSTRAINT; Schema: catalogs; Owner: postgres
--

ALTER TABLE ONLY catalogs.packagings
    ADD CONSTRAINT packagings_name_key UNIQUE (name);


--
-- TOC entry 5415 (class 2606 OID 18041)
-- Name: packagings packagings_pkey; Type: CONSTRAINT; Schema: catalogs; Owner: postgres
--

ALTER TABLE ONLY catalogs.packagings
    ADD CONSTRAINT packagings_pkey PRIMARY KEY (packaging_id);


--
-- TOC entry 5419 (class 2606 OID 18062)
-- Name: products products_pkey; Type: CONSTRAINT; Schema: catalogs; Owner: postgres
--

ALTER TABLE ONLY catalogs.products
    ADD CONSTRAINT products_pkey PRIMARY KEY (product_id);


--
-- TOC entry 5417 (class 2606 OID 18052)
-- Name: quantities quantities_pkey; Type: CONSTRAINT; Schema: catalogs; Owner: postgres
--

ALTER TABLE ONLY catalogs.quantities
    ADD CONSTRAINT quantities_pkey PRIMARY KEY (quantity_id);


--
-- TOC entry 5381 (class 2606 OID 17935)
-- Name: subcategories subcategories_pkey; Type: CONSTRAINT; Schema: catalogs; Owner: postgres
--

ALTER TABLE ONLY catalogs.subcategories
    ADD CONSTRAINT subcategories_pkey PRIMARY KEY (subcategory_id);


--
-- TOC entry 5389 (class 2606 OID 17977)
-- Name: variant_types variant_types_name_key; Type: CONSTRAINT; Schema: catalogs; Owner: postgres
--

ALTER TABLE ONLY catalogs.variant_types
    ADD CONSTRAINT variant_types_name_key UNIQUE (name);


--
-- TOC entry 5391 (class 2606 OID 17975)
-- Name: variant_types variant_types_pkey; Type: CONSTRAINT; Schema: catalogs; Owner: postgres
--

ALTER TABLE ONLY catalogs.variant_types
    ADD CONSTRAINT variant_types_pkey PRIMARY KEY (variant_type_id);


--
-- TOC entry 5851 (class 2606 OID 21387)
-- Name: quotation_submissions quotation_submissions_pkey; Type: CONSTRAINT; Schema: quotation; Owner: postgres
--

ALTER TABLE ONLY quotation.quotation_submissions
    ADD CONSTRAINT quotation_submissions_pkey PRIMARY KEY (quotation_submission_id);


--
-- TOC entry 5862 (class 2606 OID 21410)
-- Name: quoted_prices quoted_prices_pkey; Type: CONSTRAINT; Schema: quotation; Owner: postgres
--

ALTER TABLE ONLY quotation.quoted_prices
    ADD CONSTRAINT quoted_prices_pkey PRIMARY KEY (quoted_price_id);


--
-- TOC entry 5846 (class 2606 OID 21375)
-- Name: shopping_list_items shopping_list_items_pkey; Type: CONSTRAINT; Schema: quotation; Owner: postgres
--

ALTER TABLE ONLY quotation.shopping_list_items
    ADD CONSTRAINT shopping_list_items_pkey PRIMARY KEY (shopping_list_item_id);


--
-- TOC entry 5840 (class 2606 OID 21365)
-- Name: shopping_lists shopping_lists_pkey; Type: CONSTRAINT; Schema: quotation; Owner: postgres
--

ALTER TABLE ONLY quotation.shopping_lists
    ADD CONSTRAINT shopping_lists_pkey PRIMARY KEY (shopping_list_id);


--
-- TOC entry 5829 (class 2606 OID 21342)
-- Name: submission_statuses submission_statuses_name_key; Type: CONSTRAINT; Schema: quotation; Owner: postgres
--

ALTER TABLE ONLY quotation.submission_statuses
    ADD CONSTRAINT submission_statuses_name_key UNIQUE (name);


--
-- TOC entry 5831 (class 2606 OID 21340)
-- Name: submission_statuses submission_statuses_pkey; Type: CONSTRAINT; Schema: quotation; Owner: postgres
--

ALTER TABLE ONLY quotation.submission_statuses
    ADD CONSTRAINT submission_statuses_pkey PRIMARY KEY (submission_status_id);


--
-- TOC entry 5833 (class 2606 OID 21355)
-- Name: supplier_quotation_statuses supplier_quotation_statuses_name_key; Type: CONSTRAINT; Schema: quotation; Owner: postgres
--

ALTER TABLE ONLY quotation.supplier_quotation_statuses
    ADD CONSTRAINT supplier_quotation_statuses_name_key UNIQUE (name);


--
-- TOC entry 5835 (class 2606 OID 21353)
-- Name: supplier_quotation_statuses supplier_quotation_statuses_pkey; Type: CONSTRAINT; Schema: quotation; Owner: postgres
--

ALTER TABLE ONLY quotation.supplier_quotation_statuses
    ADD CONSTRAINT supplier_quotation_statuses_pkey PRIMARY KEY (quotation_status_id);


--
-- TOC entry 5857 (class 2606 OID 21398)
-- Name: supplier_quotations supplier_quotations_pkey; Type: CONSTRAINT; Schema: quotation; Owner: postgres
--

ALTER TABLE ONLY quotation.supplier_quotations
    ADD CONSTRAINT supplier_quotations_pkey PRIMARY KEY (supplier_quotation_id);


--
-- TOC entry 5371 (class 1259 OID 17595)
-- Name: idx_apis_path_method; Type: INDEX; Schema: accounts; Owner: postgres
--

CREATE INDEX idx_apis_path_method ON accounts.apis USING btree (path, method);


--
-- TOC entry 5799 (class 1259 OID 21245)
-- Name: idx_employee_addresses_city; Type: INDEX; Schema: accounts; Owner: postgres
--

CREATE INDEX idx_employee_addresses_city ON accounts.employee_addresses USING btree (city);


--
-- TOC entry 5800 (class 1259 OID 21248)
-- Name: idx_employee_addresses_neighborhood; Type: INDEX; Schema: accounts; Owner: postgres
--

CREATE INDEX idx_employee_addresses_neighborhood ON accounts.employee_addresses USING btree (neighborhood);


--
-- TOC entry 5801 (class 1259 OID 21244)
-- Name: idx_employee_addresses_postal_code; Type: INDEX; Schema: accounts; Owner: postgres
--

CREATE INDEX idx_employee_addresses_postal_code ON accounts.employee_addresses USING btree (postal_code);


--
-- TOC entry 5802 (class 1259 OID 21246)
-- Name: idx_employee_addresses_state; Type: INDEX; Schema: accounts; Owner: postgres
--

CREATE INDEX idx_employee_addresses_state ON accounts.employee_addresses USING btree (state);


--
-- TOC entry 5803 (class 1259 OID 21247)
-- Name: idx_employee_addresses_street; Type: INDEX; Schema: accounts; Owner: postgres
--

CREATE INDEX idx_employee_addresses_street ON accounts.employee_addresses USING btree (street);


--
-- TOC entry 5791 (class 1259 OID 21242)
-- Name: idx_employee_personal_data_birth_date; Type: INDEX; Schema: accounts; Owner: postgres
--

CREATE INDEX idx_employee_personal_data_birth_date ON accounts.employee_personal_data USING btree (birth_date);


--
-- TOC entry 5792 (class 1259 OID 21240)
-- Name: idx_employee_personal_data_cpf; Type: INDEX; Schema: accounts; Owner: postgres
--

CREATE INDEX idx_employee_personal_data_cpf ON accounts.employee_personal_data USING btree (cpf);


--
-- TOC entry 5793 (class 1259 OID 21241)
-- Name: idx_employee_personal_data_full_name; Type: INDEX; Schema: accounts; Owner: postgres
--

CREATE INDEX idx_employee_personal_data_full_name ON accounts.employee_personal_data USING btree (full_name);


--
-- TOC entry 5794 (class 1259 OID 21243)
-- Name: idx_employee_personal_data_gender; Type: INDEX; Schema: accounts; Owner: postgres
--

CREATE INDEX idx_employee_personal_data_gender ON accounts.employee_personal_data USING btree (gender);


--
-- TOC entry 5367 (class 1259 OID 17597)
-- Name: idx_employee_roles_employee; Type: INDEX; Schema: accounts; Owner: postgres
--

CREATE INDEX idx_employee_roles_employee ON accounts.employee_roles USING btree (employee_id);


--
-- TOC entry 5368 (class 1259 OID 17591)
-- Name: idx_employee_roles_user; Type: INDEX; Schema: accounts; Owner: postgres
--

CREATE INDEX idx_employee_roles_user ON accounts.employee_roles USING btree (employee_id);


--
-- TOC entry 5343 (class 1259 OID 17596)
-- Name: idx_employees_supplier_active; Type: INDEX; Schema: accounts; Owner: postgres
--

CREATE INDEX idx_employees_supplier_active ON accounts.employees USING btree (supplier_id, is_active);


--
-- TOC entry 5433 (class 1259 OID 18356)
-- Name: idx_establishment_addresses_city; Type: INDEX; Schema: accounts; Owner: postgres
--

CREATE INDEX idx_establishment_addresses_city ON accounts.establishment_addresses USING btree (city);


--
-- TOC entry 5434 (class 1259 OID 18358)
-- Name: idx_establishment_addresses_establishment_id; Type: INDEX; Schema: accounts; Owner: postgres
--

CREATE INDEX idx_establishment_addresses_establishment_id ON accounts.establishment_addresses USING btree (establishment_id);


--
-- TOC entry 5435 (class 1259 OID 18355)
-- Name: idx_establishment_addresses_postal_code; Type: INDEX; Schema: accounts; Owner: postgres
--

CREATE INDEX idx_establishment_addresses_postal_code ON accounts.establishment_addresses USING btree (postal_code);


--
-- TOC entry 5436 (class 1259 OID 18357)
-- Name: idx_establishment_addresses_state; Type: INDEX; Schema: accounts; Owner: postgres
--

CREATE INDEX idx_establishment_addresses_state ON accounts.establishment_addresses USING btree (state);


--
-- TOC entry 5428 (class 1259 OID 18352)
-- Name: idx_establishment_business_data_cnpj; Type: INDEX; Schema: accounts; Owner: postgres
--

CREATE INDEX idx_establishment_business_data_cnpj ON accounts.establishment_business_data USING btree (cnpj);


--
-- TOC entry 5429 (class 1259 OID 18354)
-- Name: idx_establishment_business_data_corporate_name; Type: INDEX; Schema: accounts; Owner: postgres
--

CREATE INDEX idx_establishment_business_data_corporate_name ON accounts.establishment_business_data USING btree (corporate_name);


--
-- TOC entry 5430 (class 1259 OID 18353)
-- Name: idx_establishment_business_data_trade_name; Type: INDEX; Schema: accounts; Owner: postgres
--

CREATE INDEX idx_establishment_business_data_trade_name ON accounts.establishment_business_data USING btree (trade_name);


--
-- TOC entry 5356 (class 1259 OID 17593)
-- Name: idx_features_code; Type: INDEX; Schema: accounts; Owner: postgres
--

CREATE INDEX idx_features_code ON accounts.features USING btree (code);


--
-- TOC entry 5357 (class 1259 OID 17598)
-- Name: idx_features_module; Type: INDEX; Schema: accounts; Owner: postgres
--

CREATE INDEX idx_features_module ON accounts.features USING btree (module_id);


--
-- TOC entry 5362 (class 1259 OID 17592)
-- Name: idx_role_features_role_feature; Type: INDEX; Schema: accounts; Owner: postgres
--

CREATE INDEX idx_role_features_role_feature ON accounts.role_features USING btree (role_id, feature_id);


--
-- TOC entry 5439 (class 1259 OID 20094)
-- Name: idx_accounts__api_keys_api_key_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_accounts__api_keys_api_key_id ON ONLY audit.accounts__api_keys USING btree (api_key_id);


--
-- TOC entry 5443 (class 1259 OID 20110)
-- Name: accounts__api_keys_2025_08_api_key_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX accounts__api_keys_2025_08_api_key_id_idx ON audit.accounts__api_keys_2025_08 USING btree (api_key_id);


--
-- TOC entry 5440 (class 1259 OID 20097)
-- Name: idx_accounts__api_keys_audit_operation; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_accounts__api_keys_audit_operation ON ONLY audit.accounts__api_keys USING btree (audit_operation);


--
-- TOC entry 5444 (class 1259 OID 20113)
-- Name: accounts__api_keys_2025_08_audit_operation_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX accounts__api_keys_2025_08_audit_operation_idx ON audit.accounts__api_keys_2025_08 USING btree (audit_operation);


--
-- TOC entry 5441 (class 1259 OID 20096)
-- Name: idx_accounts__api_keys_audit_timestamp; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_accounts__api_keys_audit_timestamp ON ONLY audit.accounts__api_keys USING btree (audit_timestamp);


--
-- TOC entry 5445 (class 1259 OID 20112)
-- Name: accounts__api_keys_2025_08_audit_timestamp_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX accounts__api_keys_2025_08_audit_timestamp_idx ON audit.accounts__api_keys_2025_08 USING btree (audit_timestamp);


--
-- TOC entry 5442 (class 1259 OID 20095)
-- Name: idx_accounts__api_keys_fk_employee_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_accounts__api_keys_fk_employee_id ON ONLY audit.accounts__api_keys USING btree (employee_id);


--
-- TOC entry 5446 (class 1259 OID 20111)
-- Name: accounts__api_keys_2025_08_employee_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX accounts__api_keys_2025_08_employee_id_idx ON audit.accounts__api_keys_2025_08 USING btree (employee_id);


--
-- TOC entry 5454 (class 1259 OID 20128)
-- Name: idx_accounts__api_scopes_fk_api_key_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_accounts__api_scopes_fk_api_key_id ON ONLY audit.accounts__api_scopes USING btree (api_key_id);


--
-- TOC entry 5456 (class 1259 OID 20145)
-- Name: accounts__api_scopes_2025_08_api_key_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX accounts__api_scopes_2025_08_api_key_id_idx ON audit.accounts__api_scopes_2025_08 USING btree (api_key_id);


--
-- TOC entry 5451 (class 1259 OID 20127)
-- Name: idx_accounts__api_scopes_api_scope_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_accounts__api_scopes_api_scope_id ON ONLY audit.accounts__api_scopes USING btree (api_scope_id);


--
-- TOC entry 5457 (class 1259 OID 20144)
-- Name: accounts__api_scopes_2025_08_api_scope_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX accounts__api_scopes_2025_08_api_scope_id_idx ON audit.accounts__api_scopes_2025_08 USING btree (api_scope_id);


--
-- TOC entry 5452 (class 1259 OID 20131)
-- Name: idx_accounts__api_scopes_audit_operation; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_accounts__api_scopes_audit_operation ON ONLY audit.accounts__api_scopes USING btree (audit_operation);


--
-- TOC entry 5458 (class 1259 OID 20148)
-- Name: accounts__api_scopes_2025_08_audit_operation_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX accounts__api_scopes_2025_08_audit_operation_idx ON audit.accounts__api_scopes_2025_08 USING btree (audit_operation);


--
-- TOC entry 5453 (class 1259 OID 20130)
-- Name: idx_accounts__api_scopes_audit_timestamp; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_accounts__api_scopes_audit_timestamp ON ONLY audit.accounts__api_scopes USING btree (audit_timestamp);


--
-- TOC entry 5459 (class 1259 OID 20147)
-- Name: accounts__api_scopes_2025_08_audit_timestamp_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX accounts__api_scopes_2025_08_audit_timestamp_idx ON audit.accounts__api_scopes_2025_08 USING btree (audit_timestamp);


--
-- TOC entry 5455 (class 1259 OID 20129)
-- Name: idx_accounts__api_scopes_fk_feature_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_accounts__api_scopes_fk_feature_id ON ONLY audit.accounts__api_scopes USING btree (feature_id);


--
-- TOC entry 5460 (class 1259 OID 20146)
-- Name: accounts__api_scopes_2025_08_feature_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX accounts__api_scopes_2025_08_feature_id_idx ON audit.accounts__api_scopes_2025_08 USING btree (feature_id);


--
-- TOC entry 5465 (class 1259 OID 20162)
-- Name: idx_accounts__apis_api_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_accounts__apis_api_id ON ONLY audit.accounts__apis USING btree (api_id);


--
-- TOC entry 5469 (class 1259 OID 20178)
-- Name: accounts__apis_2025_08_api_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX accounts__apis_2025_08_api_id_idx ON audit.accounts__apis_2025_08 USING btree (api_id);


--
-- TOC entry 5466 (class 1259 OID 20165)
-- Name: idx_accounts__apis_audit_operation; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_accounts__apis_audit_operation ON ONLY audit.accounts__apis USING btree (audit_operation);


--
-- TOC entry 5470 (class 1259 OID 20181)
-- Name: accounts__apis_2025_08_audit_operation_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX accounts__apis_2025_08_audit_operation_idx ON audit.accounts__apis_2025_08 USING btree (audit_operation);


--
-- TOC entry 5467 (class 1259 OID 20164)
-- Name: idx_accounts__apis_audit_timestamp; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_accounts__apis_audit_timestamp ON ONLY audit.accounts__apis USING btree (audit_timestamp);


--
-- TOC entry 5471 (class 1259 OID 20180)
-- Name: accounts__apis_2025_08_audit_timestamp_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX accounts__apis_2025_08_audit_timestamp_idx ON audit.accounts__apis_2025_08 USING btree (audit_timestamp);


--
-- TOC entry 5468 (class 1259 OID 20163)
-- Name: idx_accounts__apis_fk_module_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_accounts__apis_fk_module_id ON ONLY audit.accounts__apis USING btree (module_id);


--
-- TOC entry 5472 (class 1259 OID 20179)
-- Name: accounts__apis_2025_08_module_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX accounts__apis_2025_08_module_id_idx ON audit.accounts__apis_2025_08 USING btree (module_id);


--
-- TOC entry 5818 (class 1259 OID 21299)
-- Name: idx_accounts__employee_addresses_audit_operation; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_accounts__employee_addresses_audit_operation ON ONLY audit.accounts__employee_addresses USING btree (audit_operation);


--
-- TOC entry 5822 (class 1259 OID 21315)
-- Name: accounts__employee_addresses_2025_08_audit_operation_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX accounts__employee_addresses_2025_08_audit_operation_idx ON audit.accounts__employee_addresses_2025_08 USING btree (audit_operation);


--
-- TOC entry 5819 (class 1259 OID 21298)
-- Name: idx_accounts__employee_addresses_audit_timestamp; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_accounts__employee_addresses_audit_timestamp ON ONLY audit.accounts__employee_addresses USING btree (audit_timestamp);


--
-- TOC entry 5823 (class 1259 OID 21314)
-- Name: accounts__employee_addresses_2025_08_audit_timestamp_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX accounts__employee_addresses_2025_08_audit_timestamp_idx ON audit.accounts__employee_addresses_2025_08 USING btree (audit_timestamp);


--
-- TOC entry 5820 (class 1259 OID 21296)
-- Name: idx_accounts__employee_addresses_employee_address_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_accounts__employee_addresses_employee_address_id ON ONLY audit.accounts__employee_addresses USING btree (employee_address_id);


--
-- TOC entry 5824 (class 1259 OID 21312)
-- Name: accounts__employee_addresses_2025_08_employee_address_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX accounts__employee_addresses_2025_08_employee_address_id_idx ON audit.accounts__employee_addresses_2025_08 USING btree (employee_address_id);


--
-- TOC entry 5821 (class 1259 OID 21297)
-- Name: idx_accounts__employee_addresses_fk_employee_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_accounts__employee_addresses_fk_employee_id ON ONLY audit.accounts__employee_addresses USING btree (employee_id);


--
-- TOC entry 5825 (class 1259 OID 21313)
-- Name: accounts__employee_addresses_2025_08_employee_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX accounts__employee_addresses_2025_08_employee_id_idx ON audit.accounts__employee_addresses_2025_08 USING btree (employee_id);


--
-- TOC entry 5806 (class 1259 OID 21266)
-- Name: idx_accounts__employee_personal_data_audit_operation; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_accounts__employee_personal_data_audit_operation ON ONLY audit.accounts__employee_personal_data USING btree (audit_operation);


--
-- TOC entry 5810 (class 1259 OID 21282)
-- Name: accounts__employee_personal_data_2025_08_audit_operation_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX accounts__employee_personal_data_2025_08_audit_operation_idx ON audit.accounts__employee_personal_data_2025_08 USING btree (audit_operation);


--
-- TOC entry 5807 (class 1259 OID 21265)
-- Name: idx_accounts__employee_personal_data_audit_timestamp; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_accounts__employee_personal_data_audit_timestamp ON ONLY audit.accounts__employee_personal_data USING btree (audit_timestamp);


--
-- TOC entry 5811 (class 1259 OID 21281)
-- Name: accounts__employee_personal_data_2025_08_audit_timestamp_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX accounts__employee_personal_data_2025_08_audit_timestamp_idx ON audit.accounts__employee_personal_data_2025_08 USING btree (audit_timestamp);


--
-- TOC entry 5809 (class 1259 OID 21264)
-- Name: idx_accounts__employee_personal_data_fk_employee_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_accounts__employee_personal_data_fk_employee_id ON ONLY audit.accounts__employee_personal_data USING btree (employee_id);


--
-- TOC entry 5812 (class 1259 OID 21280)
-- Name: accounts__employee_personal_data_2025_08_employee_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX accounts__employee_personal_data_2025_08_employee_id_idx ON audit.accounts__employee_personal_data_2025_08 USING btree (employee_id);


--
-- TOC entry 5808 (class 1259 OID 21263)
-- Name: idx_accounts__employee_personal_data_employee_personal_data_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_accounts__employee_personal_data_employee_personal_data_id ON ONLY audit.accounts__employee_personal_data USING btree (employee_personal_data_id);


--
-- TOC entry 5815 (class 1259 OID 21279)
-- Name: accounts__employee_personal_data__employee_personal_data_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX accounts__employee_personal_data__employee_personal_data_id_idx ON audit.accounts__employee_personal_data_2025_08 USING btree (employee_personal_data_id);


--
-- TOC entry 5477 (class 1259 OID 20199)
-- Name: idx_accounts__employee_roles_audit_operation; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_accounts__employee_roles_audit_operation ON ONLY audit.accounts__employee_roles USING btree (audit_operation);


--
-- TOC entry 5482 (class 1259 OID 20216)
-- Name: accounts__employee_roles_2025_08_audit_operation_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX accounts__employee_roles_2025_08_audit_operation_idx ON audit.accounts__employee_roles_2025_08 USING btree (audit_operation);


--
-- TOC entry 5478 (class 1259 OID 20198)
-- Name: idx_accounts__employee_roles_audit_timestamp; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_accounts__employee_roles_audit_timestamp ON ONLY audit.accounts__employee_roles USING btree (audit_timestamp);


--
-- TOC entry 5483 (class 1259 OID 20215)
-- Name: accounts__employee_roles_2025_08_audit_timestamp_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX accounts__employee_roles_2025_08_audit_timestamp_idx ON audit.accounts__employee_roles_2025_08 USING btree (audit_timestamp);


--
-- TOC entry 5480 (class 1259 OID 20196)
-- Name: idx_accounts__employee_roles_fk_employee_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_accounts__employee_roles_fk_employee_id ON ONLY audit.accounts__employee_roles USING btree (employee_id);


--
-- TOC entry 5484 (class 1259 OID 20213)
-- Name: accounts__employee_roles_2025_08_employee_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX accounts__employee_roles_2025_08_employee_id_idx ON audit.accounts__employee_roles_2025_08 USING btree (employee_id);


--
-- TOC entry 5479 (class 1259 OID 20195)
-- Name: idx_accounts__employee_roles_employee_role_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_accounts__employee_roles_employee_role_id ON ONLY audit.accounts__employee_roles USING btree (employee_role_id);


--
-- TOC entry 5485 (class 1259 OID 20212)
-- Name: accounts__employee_roles_2025_08_employee_role_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX accounts__employee_roles_2025_08_employee_role_id_idx ON audit.accounts__employee_roles_2025_08 USING btree (employee_role_id);


--
-- TOC entry 5481 (class 1259 OID 20197)
-- Name: idx_accounts__employee_roles_fk_role_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_accounts__employee_roles_fk_role_id ON ONLY audit.accounts__employee_roles USING btree (role_id);


--
-- TOC entry 5488 (class 1259 OID 20214)
-- Name: accounts__employee_roles_2025_08_role_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX accounts__employee_roles_2025_08_role_id_idx ON audit.accounts__employee_roles_2025_08 USING btree (role_id);


--
-- TOC entry 5491 (class 1259 OID 20235)
-- Name: idx_accounts__employees_audit_operation; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_accounts__employees_audit_operation ON ONLY audit.accounts__employees USING btree (audit_operation);


--
-- TOC entry 5497 (class 1259 OID 20253)
-- Name: accounts__employees_2025_08_audit_operation_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX accounts__employees_2025_08_audit_operation_idx ON audit.accounts__employees_2025_08 USING btree (audit_operation);


--
-- TOC entry 5492 (class 1259 OID 20234)
-- Name: idx_accounts__employees_audit_timestamp; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_accounts__employees_audit_timestamp ON ONLY audit.accounts__employees USING btree (audit_timestamp);


--
-- TOC entry 5498 (class 1259 OID 20252)
-- Name: accounts__employees_2025_08_audit_timestamp_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX accounts__employees_2025_08_audit_timestamp_idx ON audit.accounts__employees_2025_08 USING btree (audit_timestamp);


--
-- TOC entry 5493 (class 1259 OID 20230)
-- Name: idx_accounts__employees_employee_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_accounts__employees_employee_id ON ONLY audit.accounts__employees USING btree (employee_id);


--
-- TOC entry 5499 (class 1259 OID 20248)
-- Name: accounts__employees_2025_08_employee_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX accounts__employees_2025_08_employee_id_idx ON audit.accounts__employees_2025_08 USING btree (employee_id);


--
-- TOC entry 5494 (class 1259 OID 20233)
-- Name: idx_accounts__employees_fk_establishment_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_accounts__employees_fk_establishment_id ON ONLY audit.accounts__employees USING btree (establishment_id);


--
-- TOC entry 5500 (class 1259 OID 20251)
-- Name: accounts__employees_2025_08_establishment_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX accounts__employees_2025_08_establishment_id_idx ON audit.accounts__employees_2025_08 USING btree (establishment_id);


--
-- TOC entry 5495 (class 1259 OID 20232)
-- Name: idx_accounts__employees_fk_supplier_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_accounts__employees_fk_supplier_id ON ONLY audit.accounts__employees USING btree (supplier_id);


--
-- TOC entry 5503 (class 1259 OID 20250)
-- Name: accounts__employees_2025_08_supplier_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX accounts__employees_2025_08_supplier_id_idx ON audit.accounts__employees_2025_08 USING btree (supplier_id);


--
-- TOC entry 5496 (class 1259 OID 20231)
-- Name: idx_accounts__employees_fk_user_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_accounts__employees_fk_user_id ON ONLY audit.accounts__employees USING btree (user_id);


--
-- TOC entry 5504 (class 1259 OID 20249)
-- Name: accounts__employees_2025_08_user_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX accounts__employees_2025_08_user_id_idx ON audit.accounts__employees_2025_08 USING btree (user_id);


--
-- TOC entry 5507 (class 1259 OID 20270)
-- Name: idx_accounts__establishment_addresses_audit_operation; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_accounts__establishment_addresses_audit_operation ON ONLY audit.accounts__establishment_addresses USING btree (audit_operation);


--
-- TOC entry 5511 (class 1259 OID 20286)
-- Name: accounts__establishment_addresses_2025_08_audit_operation_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX accounts__establishment_addresses_2025_08_audit_operation_idx ON audit.accounts__establishment_addresses_2025_08 USING btree (audit_operation);


--
-- TOC entry 5508 (class 1259 OID 20269)
-- Name: idx_accounts__establishment_addresses_audit_timestamp; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_accounts__establishment_addresses_audit_timestamp ON ONLY audit.accounts__establishment_addresses USING btree (audit_timestamp);


--
-- TOC entry 5512 (class 1259 OID 20285)
-- Name: accounts__establishment_addresses_2025_08_audit_timestamp_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX accounts__establishment_addresses_2025_08_audit_timestamp_idx ON audit.accounts__establishment_addresses_2025_08 USING btree (audit_timestamp);


--
-- TOC entry 5510 (class 1259 OID 20268)
-- Name: idx_accounts__establishment_addresses_fk_establishment_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_accounts__establishment_addresses_fk_establishment_id ON ONLY audit.accounts__establishment_addresses USING btree (establishment_id);


--
-- TOC entry 5513 (class 1259 OID 20284)
-- Name: accounts__establishment_addresses_2025_08_establishment_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX accounts__establishment_addresses_2025_08_establishment_id_idx ON audit.accounts__establishment_addresses_2025_08 USING btree (establishment_id);


--
-- TOC entry 5509 (class 1259 OID 20267)
-- Name: idx_accounts__establishment_addresses_establishment_address_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_accounts__establishment_addresses_establishment_address_id ON ONLY audit.accounts__establishment_addresses USING btree (establishment_address_id);


--
-- TOC entry 5516 (class 1259 OID 20283)
-- Name: accounts__establishment_addresses__establishment_address_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX accounts__establishment_addresses__establishment_address_id_idx ON audit.accounts__establishment_addresses_2025_08 USING btree (establishment_address_id);


--
-- TOC entry 5521 (class 1259 OID 20300)
-- Name: idx_accounts__establishment_business_data_establishment_busines; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_accounts__establishment_business_data_establishment_busines ON ONLY audit.accounts__establishment_business_data USING btree (establishment_business_data_id);


--
-- TOC entry 5523 (class 1259 OID 20316)
-- Name: accounts__establishment_busin_establishment_business_data_i_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX accounts__establishment_busin_establishment_business_data_i_idx ON audit.accounts__establishment_business_data_2025_08 USING btree (establishment_business_data_id);


--
-- TOC entry 5519 (class 1259 OID 20303)
-- Name: idx_accounts__establishment_business_data_audit_operation; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_accounts__establishment_business_data_audit_operation ON ONLY audit.accounts__establishment_business_data USING btree (audit_operation);


--
-- TOC entry 5526 (class 1259 OID 20319)
-- Name: accounts__establishment_business_data_2025__audit_operation_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX accounts__establishment_business_data_2025__audit_operation_idx ON audit.accounts__establishment_business_data_2025_08 USING btree (audit_operation);


--
-- TOC entry 5520 (class 1259 OID 20302)
-- Name: idx_accounts__establishment_business_data_audit_timestamp; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_accounts__establishment_business_data_audit_timestamp ON ONLY audit.accounts__establishment_business_data USING btree (audit_timestamp);


--
-- TOC entry 5527 (class 1259 OID 20318)
-- Name: accounts__establishment_business_data_2025__audit_timestamp_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX accounts__establishment_business_data_2025__audit_timestamp_idx ON audit.accounts__establishment_business_data_2025_08 USING btree (audit_timestamp);


--
-- TOC entry 5522 (class 1259 OID 20301)
-- Name: idx_accounts__establishment_business_data_fk_establishment_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_accounts__establishment_business_data_fk_establishment_id ON ONLY audit.accounts__establishment_business_data USING btree (establishment_id);


--
-- TOC entry 5528 (class 1259 OID 20317)
-- Name: accounts__establishment_business_data_2025_establishment_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX accounts__establishment_business_data_2025_establishment_id_idx ON audit.accounts__establishment_business_data_2025_08 USING btree (establishment_id);


--
-- TOC entry 5531 (class 1259 OID 20335)
-- Name: idx_accounts__establishments_audit_operation; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_accounts__establishments_audit_operation ON ONLY audit.accounts__establishments USING btree (audit_operation);


--
-- TOC entry 5534 (class 1259 OID 20350)
-- Name: accounts__establishments_2025_08_audit_operation_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX accounts__establishments_2025_08_audit_operation_idx ON audit.accounts__establishments_2025_08 USING btree (audit_operation);


--
-- TOC entry 5532 (class 1259 OID 20334)
-- Name: idx_accounts__establishments_audit_timestamp; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_accounts__establishments_audit_timestamp ON ONLY audit.accounts__establishments USING btree (audit_timestamp);


--
-- TOC entry 5535 (class 1259 OID 20349)
-- Name: accounts__establishments_2025_08_audit_timestamp_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX accounts__establishments_2025_08_audit_timestamp_idx ON audit.accounts__establishments_2025_08 USING btree (audit_timestamp);


--
-- TOC entry 5533 (class 1259 OID 20333)
-- Name: idx_accounts__establishments_establishment_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_accounts__establishments_establishment_id ON ONLY audit.accounts__establishments USING btree (establishment_id);


--
-- TOC entry 5536 (class 1259 OID 20348)
-- Name: accounts__establishments_2025_08_establishment_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX accounts__establishments_2025_08_establishment_id_idx ON audit.accounts__establishments_2025_08 USING btree (establishment_id);


--
-- TOC entry 5541 (class 1259 OID 20368)
-- Name: idx_accounts__features_audit_operation; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_accounts__features_audit_operation ON ONLY audit.accounts__features USING btree (audit_operation);


--
-- TOC entry 5546 (class 1259 OID 20385)
-- Name: accounts__features_2025_08_audit_operation_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX accounts__features_2025_08_audit_operation_idx ON audit.accounts__features_2025_08 USING btree (audit_operation);


--
-- TOC entry 5542 (class 1259 OID 20367)
-- Name: idx_accounts__features_audit_timestamp; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_accounts__features_audit_timestamp ON ONLY audit.accounts__features USING btree (audit_timestamp);


--
-- TOC entry 5547 (class 1259 OID 20384)
-- Name: accounts__features_2025_08_audit_timestamp_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX accounts__features_2025_08_audit_timestamp_idx ON audit.accounts__features_2025_08 USING btree (audit_timestamp);


--
-- TOC entry 5543 (class 1259 OID 20364)
-- Name: idx_accounts__features_feature_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_accounts__features_feature_id ON ONLY audit.accounts__features USING btree (feature_id);


--
-- TOC entry 5548 (class 1259 OID 20381)
-- Name: accounts__features_2025_08_feature_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX accounts__features_2025_08_feature_id_idx ON audit.accounts__features_2025_08 USING btree (feature_id);


--
-- TOC entry 5544 (class 1259 OID 20365)
-- Name: idx_accounts__features_fk_module_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_accounts__features_fk_module_id ON ONLY audit.accounts__features USING btree (module_id);


--
-- TOC entry 5549 (class 1259 OID 20382)
-- Name: accounts__features_2025_08_module_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX accounts__features_2025_08_module_id_idx ON audit.accounts__features_2025_08 USING btree (module_id);


--
-- TOC entry 5545 (class 1259 OID 20366)
-- Name: idx_accounts__features_fk_platform_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_accounts__features_fk_platform_id ON ONLY audit.accounts__features USING btree (platform_id);


--
-- TOC entry 5552 (class 1259 OID 20383)
-- Name: accounts__features_2025_08_platform_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX accounts__features_2025_08_platform_id_idx ON audit.accounts__features_2025_08 USING btree (platform_id);


--
-- TOC entry 5555 (class 1259 OID 20401)
-- Name: idx_accounts__modules_audit_operation; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_accounts__modules_audit_operation ON ONLY audit.accounts__modules USING btree (audit_operation);


--
-- TOC entry 5558 (class 1259 OID 20416)
-- Name: accounts__modules_2025_08_audit_operation_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX accounts__modules_2025_08_audit_operation_idx ON audit.accounts__modules_2025_08 USING btree (audit_operation);


--
-- TOC entry 5556 (class 1259 OID 20400)
-- Name: idx_accounts__modules_audit_timestamp; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_accounts__modules_audit_timestamp ON ONLY audit.accounts__modules USING btree (audit_timestamp);


--
-- TOC entry 5559 (class 1259 OID 20415)
-- Name: accounts__modules_2025_08_audit_timestamp_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX accounts__modules_2025_08_audit_timestamp_idx ON audit.accounts__modules_2025_08 USING btree (audit_timestamp);


--
-- TOC entry 5557 (class 1259 OID 20399)
-- Name: idx_accounts__modules_module_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_accounts__modules_module_id ON ONLY audit.accounts__modules USING btree (module_id);


--
-- TOC entry 5560 (class 1259 OID 20414)
-- Name: accounts__modules_2025_08_module_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX accounts__modules_2025_08_module_id_idx ON audit.accounts__modules_2025_08 USING btree (module_id);


--
-- TOC entry 5565 (class 1259 OID 20432)
-- Name: idx_accounts__platforms_audit_operation; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_accounts__platforms_audit_operation ON ONLY audit.accounts__platforms USING btree (audit_operation);


--
-- TOC entry 5568 (class 1259 OID 20447)
-- Name: accounts__platforms_2025_08_audit_operation_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX accounts__platforms_2025_08_audit_operation_idx ON audit.accounts__platforms_2025_08 USING btree (audit_operation);


--
-- TOC entry 5566 (class 1259 OID 20431)
-- Name: idx_accounts__platforms_audit_timestamp; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_accounts__platforms_audit_timestamp ON ONLY audit.accounts__platforms USING btree (audit_timestamp);


--
-- TOC entry 5569 (class 1259 OID 20446)
-- Name: accounts__platforms_2025_08_audit_timestamp_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX accounts__platforms_2025_08_audit_timestamp_idx ON audit.accounts__platforms_2025_08 USING btree (audit_timestamp);


--
-- TOC entry 5567 (class 1259 OID 20430)
-- Name: idx_accounts__platforms_platform_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_accounts__platforms_platform_id ON ONLY audit.accounts__platforms USING btree (platform_id);


--
-- TOC entry 5572 (class 1259 OID 20445)
-- Name: accounts__platforms_2025_08_platform_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX accounts__platforms_2025_08_platform_id_idx ON audit.accounts__platforms_2025_08 USING btree (platform_id);


--
-- TOC entry 5575 (class 1259 OID 20465)
-- Name: idx_accounts__role_features_audit_operation; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_accounts__role_features_audit_operation ON ONLY audit.accounts__role_features USING btree (audit_operation);


--
-- TOC entry 5580 (class 1259 OID 20482)
-- Name: accounts__role_features_2025_08_audit_operation_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX accounts__role_features_2025_08_audit_operation_idx ON audit.accounts__role_features_2025_08 USING btree (audit_operation);


--
-- TOC entry 5576 (class 1259 OID 20464)
-- Name: idx_accounts__role_features_audit_timestamp; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_accounts__role_features_audit_timestamp ON ONLY audit.accounts__role_features USING btree (audit_timestamp);


--
-- TOC entry 5581 (class 1259 OID 20481)
-- Name: accounts__role_features_2025_08_audit_timestamp_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX accounts__role_features_2025_08_audit_timestamp_idx ON audit.accounts__role_features_2025_08 USING btree (audit_timestamp);


--
-- TOC entry 5577 (class 1259 OID 20463)
-- Name: idx_accounts__role_features_fk_feature_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_accounts__role_features_fk_feature_id ON ONLY audit.accounts__role_features USING btree (feature_id);


--
-- TOC entry 5582 (class 1259 OID 20480)
-- Name: accounts__role_features_2025_08_feature_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX accounts__role_features_2025_08_feature_id_idx ON audit.accounts__role_features_2025_08 USING btree (feature_id);


--
-- TOC entry 5579 (class 1259 OID 20461)
-- Name: idx_accounts__role_features_role_feature_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_accounts__role_features_role_feature_id ON ONLY audit.accounts__role_features USING btree (role_feature_id);


--
-- TOC entry 5585 (class 1259 OID 20478)
-- Name: accounts__role_features_2025_08_role_feature_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX accounts__role_features_2025_08_role_feature_id_idx ON audit.accounts__role_features_2025_08 USING btree (role_feature_id);


--
-- TOC entry 5578 (class 1259 OID 20462)
-- Name: idx_accounts__role_features_fk_role_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_accounts__role_features_fk_role_id ON ONLY audit.accounts__role_features USING btree (role_id);


--
-- TOC entry 5586 (class 1259 OID 20479)
-- Name: accounts__role_features_2025_08_role_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX accounts__role_features_2025_08_role_id_idx ON audit.accounts__role_features_2025_08 USING btree (role_id);


--
-- TOC entry 5589 (class 1259 OID 20498)
-- Name: idx_accounts__roles_audit_operation; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_accounts__roles_audit_operation ON ONLY audit.accounts__roles USING btree (audit_operation);


--
-- TOC entry 5592 (class 1259 OID 20513)
-- Name: accounts__roles_2025_08_audit_operation_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX accounts__roles_2025_08_audit_operation_idx ON audit.accounts__roles_2025_08 USING btree (audit_operation);


--
-- TOC entry 5590 (class 1259 OID 20497)
-- Name: idx_accounts__roles_audit_timestamp; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_accounts__roles_audit_timestamp ON ONLY audit.accounts__roles USING btree (audit_timestamp);


--
-- TOC entry 5593 (class 1259 OID 20512)
-- Name: accounts__roles_2025_08_audit_timestamp_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX accounts__roles_2025_08_audit_timestamp_idx ON audit.accounts__roles_2025_08 USING btree (audit_timestamp);


--
-- TOC entry 5591 (class 1259 OID 20496)
-- Name: idx_accounts__roles_role_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_accounts__roles_role_id ON ONLY audit.accounts__roles USING btree (role_id);


--
-- TOC entry 5596 (class 1259 OID 20511)
-- Name: accounts__roles_2025_08_role_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX accounts__roles_2025_08_role_id_idx ON audit.accounts__roles_2025_08 USING btree (role_id);


--
-- TOC entry 5599 (class 1259 OID 20529)
-- Name: idx_accounts__suppliers_audit_operation; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_accounts__suppliers_audit_operation ON ONLY audit.accounts__suppliers USING btree (audit_operation);


--
-- TOC entry 5602 (class 1259 OID 20544)
-- Name: accounts__suppliers_2025_08_audit_operation_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX accounts__suppliers_2025_08_audit_operation_idx ON audit.accounts__suppliers_2025_08 USING btree (audit_operation);


--
-- TOC entry 5600 (class 1259 OID 20528)
-- Name: idx_accounts__suppliers_audit_timestamp; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_accounts__suppliers_audit_timestamp ON ONLY audit.accounts__suppliers USING btree (audit_timestamp);


--
-- TOC entry 5603 (class 1259 OID 20543)
-- Name: accounts__suppliers_2025_08_audit_timestamp_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX accounts__suppliers_2025_08_audit_timestamp_idx ON audit.accounts__suppliers_2025_08 USING btree (audit_timestamp);


--
-- TOC entry 5601 (class 1259 OID 20527)
-- Name: idx_accounts__suppliers_supplier_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_accounts__suppliers_supplier_id ON ONLY audit.accounts__suppliers USING btree (supplier_id);


--
-- TOC entry 5606 (class 1259 OID 20542)
-- Name: accounts__suppliers_2025_08_supplier_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX accounts__suppliers_2025_08_supplier_id_idx ON audit.accounts__suppliers_2025_08 USING btree (supplier_id);


--
-- TOC entry 5609 (class 1259 OID 20560)
-- Name: idx_accounts__users_audit_operation; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_accounts__users_audit_operation ON ONLY audit.accounts__users USING btree (audit_operation);


--
-- TOC entry 5612 (class 1259 OID 20575)
-- Name: accounts__users_2025_08_audit_operation_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX accounts__users_2025_08_audit_operation_idx ON audit.accounts__users_2025_08 USING btree (audit_operation);


--
-- TOC entry 5610 (class 1259 OID 20559)
-- Name: idx_accounts__users_audit_timestamp; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_accounts__users_audit_timestamp ON ONLY audit.accounts__users USING btree (audit_timestamp);


--
-- TOC entry 5613 (class 1259 OID 20574)
-- Name: accounts__users_2025_08_audit_timestamp_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX accounts__users_2025_08_audit_timestamp_idx ON audit.accounts__users_2025_08 USING btree (audit_timestamp);


--
-- TOC entry 5611 (class 1259 OID 20558)
-- Name: idx_accounts__users_user_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_accounts__users_user_id ON ONLY audit.accounts__users USING btree (user_id);


--
-- TOC entry 5616 (class 1259 OID 20573)
-- Name: accounts__users_2025_08_user_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX accounts__users_2025_08_user_id_idx ON audit.accounts__users_2025_08 USING btree (user_id);


--
-- TOC entry 5619 (class 1259 OID 20591)
-- Name: idx_catalogs__brands_audit_operation; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_catalogs__brands_audit_operation ON ONLY audit.catalogs__brands USING btree (audit_operation);


--
-- TOC entry 5622 (class 1259 OID 20606)
-- Name: catalogs__brands_2025_08_audit_operation_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX catalogs__brands_2025_08_audit_operation_idx ON audit.catalogs__brands_2025_08 USING btree (audit_operation);


--
-- TOC entry 5620 (class 1259 OID 20590)
-- Name: idx_catalogs__brands_audit_timestamp; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_catalogs__brands_audit_timestamp ON ONLY audit.catalogs__brands USING btree (audit_timestamp);


--
-- TOC entry 5623 (class 1259 OID 20605)
-- Name: catalogs__brands_2025_08_audit_timestamp_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX catalogs__brands_2025_08_audit_timestamp_idx ON audit.catalogs__brands_2025_08 USING btree (audit_timestamp);


--
-- TOC entry 5621 (class 1259 OID 20589)
-- Name: idx_catalogs__brands_brand_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_catalogs__brands_brand_id ON ONLY audit.catalogs__brands USING btree (brand_id);


--
-- TOC entry 5624 (class 1259 OID 20604)
-- Name: catalogs__brands_2025_08_brand_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX catalogs__brands_2025_08_brand_id_idx ON audit.catalogs__brands_2025_08 USING btree (brand_id);


--
-- TOC entry 5629 (class 1259 OID 20622)
-- Name: idx_catalogs__categories_audit_operation; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_catalogs__categories_audit_operation ON ONLY audit.catalogs__categories USING btree (audit_operation);


--
-- TOC entry 5632 (class 1259 OID 20637)
-- Name: catalogs__categories_2025_08_audit_operation_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX catalogs__categories_2025_08_audit_operation_idx ON audit.catalogs__categories_2025_08 USING btree (audit_operation);


--
-- TOC entry 5630 (class 1259 OID 20621)
-- Name: idx_catalogs__categories_audit_timestamp; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_catalogs__categories_audit_timestamp ON ONLY audit.catalogs__categories USING btree (audit_timestamp);


--
-- TOC entry 5633 (class 1259 OID 20636)
-- Name: catalogs__categories_2025_08_audit_timestamp_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX catalogs__categories_2025_08_audit_timestamp_idx ON audit.catalogs__categories_2025_08 USING btree (audit_timestamp);


--
-- TOC entry 5631 (class 1259 OID 20620)
-- Name: idx_catalogs__categories_category_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_catalogs__categories_category_id ON ONLY audit.catalogs__categories USING btree (category_id);


--
-- TOC entry 5634 (class 1259 OID 20635)
-- Name: catalogs__categories_2025_08_category_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX catalogs__categories_2025_08_category_id_idx ON audit.catalogs__categories_2025_08 USING btree (category_id);


--
-- TOC entry 5639 (class 1259 OID 20653)
-- Name: idx_catalogs__compositions_audit_operation; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_catalogs__compositions_audit_operation ON ONLY audit.catalogs__compositions USING btree (audit_operation);


--
-- TOC entry 5642 (class 1259 OID 20668)
-- Name: catalogs__compositions_2025_08_audit_operation_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX catalogs__compositions_2025_08_audit_operation_idx ON audit.catalogs__compositions_2025_08 USING btree (audit_operation);


--
-- TOC entry 5640 (class 1259 OID 20652)
-- Name: idx_catalogs__compositions_audit_timestamp; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_catalogs__compositions_audit_timestamp ON ONLY audit.catalogs__compositions USING btree (audit_timestamp);


--
-- TOC entry 5643 (class 1259 OID 20667)
-- Name: catalogs__compositions_2025_08_audit_timestamp_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX catalogs__compositions_2025_08_audit_timestamp_idx ON audit.catalogs__compositions_2025_08 USING btree (audit_timestamp);


--
-- TOC entry 5641 (class 1259 OID 20651)
-- Name: idx_catalogs__compositions_composition_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_catalogs__compositions_composition_id ON ONLY audit.catalogs__compositions USING btree (composition_id);


--
-- TOC entry 5644 (class 1259 OID 20666)
-- Name: catalogs__compositions_2025_08_composition_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX catalogs__compositions_2025_08_composition_id_idx ON audit.catalogs__compositions_2025_08 USING btree (composition_id);


--
-- TOC entry 5649 (class 1259 OID 20684)
-- Name: idx_catalogs__fillings_audit_operation; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_catalogs__fillings_audit_operation ON ONLY audit.catalogs__fillings USING btree (audit_operation);


--
-- TOC entry 5652 (class 1259 OID 20699)
-- Name: catalogs__fillings_2025_08_audit_operation_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX catalogs__fillings_2025_08_audit_operation_idx ON audit.catalogs__fillings_2025_08 USING btree (audit_operation);


--
-- TOC entry 5650 (class 1259 OID 20683)
-- Name: idx_catalogs__fillings_audit_timestamp; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_catalogs__fillings_audit_timestamp ON ONLY audit.catalogs__fillings USING btree (audit_timestamp);


--
-- TOC entry 5653 (class 1259 OID 20698)
-- Name: catalogs__fillings_2025_08_audit_timestamp_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX catalogs__fillings_2025_08_audit_timestamp_idx ON audit.catalogs__fillings_2025_08 USING btree (audit_timestamp);


--
-- TOC entry 5651 (class 1259 OID 20682)
-- Name: idx_catalogs__fillings_filling_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_catalogs__fillings_filling_id ON ONLY audit.catalogs__fillings USING btree (filling_id);


--
-- TOC entry 5654 (class 1259 OID 20697)
-- Name: catalogs__fillings_2025_08_filling_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX catalogs__fillings_2025_08_filling_id_idx ON audit.catalogs__fillings_2025_08 USING btree (filling_id);


--
-- TOC entry 5659 (class 1259 OID 20715)
-- Name: idx_catalogs__flavors_audit_operation; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_catalogs__flavors_audit_operation ON ONLY audit.catalogs__flavors USING btree (audit_operation);


--
-- TOC entry 5662 (class 1259 OID 20730)
-- Name: catalogs__flavors_2025_08_audit_operation_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX catalogs__flavors_2025_08_audit_operation_idx ON audit.catalogs__flavors_2025_08 USING btree (audit_operation);


--
-- TOC entry 5660 (class 1259 OID 20714)
-- Name: idx_catalogs__flavors_audit_timestamp; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_catalogs__flavors_audit_timestamp ON ONLY audit.catalogs__flavors USING btree (audit_timestamp);


--
-- TOC entry 5663 (class 1259 OID 20729)
-- Name: catalogs__flavors_2025_08_audit_timestamp_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX catalogs__flavors_2025_08_audit_timestamp_idx ON audit.catalogs__flavors_2025_08 USING btree (audit_timestamp);


--
-- TOC entry 5661 (class 1259 OID 20713)
-- Name: idx_catalogs__flavors_flavor_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_catalogs__flavors_flavor_id ON ONLY audit.catalogs__flavors USING btree (flavor_id);


--
-- TOC entry 5664 (class 1259 OID 20728)
-- Name: catalogs__flavors_2025_08_flavor_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX catalogs__flavors_2025_08_flavor_id_idx ON audit.catalogs__flavors_2025_08 USING btree (flavor_id);


--
-- TOC entry 5669 (class 1259 OID 20746)
-- Name: idx_catalogs__formats_audit_operation; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_catalogs__formats_audit_operation ON ONLY audit.catalogs__formats USING btree (audit_operation);


--
-- TOC entry 5672 (class 1259 OID 20761)
-- Name: catalogs__formats_2025_08_audit_operation_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX catalogs__formats_2025_08_audit_operation_idx ON audit.catalogs__formats_2025_08 USING btree (audit_operation);


--
-- TOC entry 5670 (class 1259 OID 20745)
-- Name: idx_catalogs__formats_audit_timestamp; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_catalogs__formats_audit_timestamp ON ONLY audit.catalogs__formats USING btree (audit_timestamp);


--
-- TOC entry 5673 (class 1259 OID 20760)
-- Name: catalogs__formats_2025_08_audit_timestamp_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX catalogs__formats_2025_08_audit_timestamp_idx ON audit.catalogs__formats_2025_08 USING btree (audit_timestamp);


--
-- TOC entry 5671 (class 1259 OID 20744)
-- Name: idx_catalogs__formats_format_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_catalogs__formats_format_id ON ONLY audit.catalogs__formats USING btree (format_id);


--
-- TOC entry 5674 (class 1259 OID 20759)
-- Name: catalogs__formats_2025_08_format_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX catalogs__formats_2025_08_format_id_idx ON audit.catalogs__formats_2025_08 USING btree (format_id);


--
-- TOC entry 5679 (class 1259 OID 20778)
-- Name: idx_catalogs__items_audit_operation; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_catalogs__items_audit_operation ON ONLY audit.catalogs__items USING btree (audit_operation);


--
-- TOC entry 5683 (class 1259 OID 20794)
-- Name: catalogs__items_2025_08_audit_operation_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX catalogs__items_2025_08_audit_operation_idx ON audit.catalogs__items_2025_08 USING btree (audit_operation);


--
-- TOC entry 5680 (class 1259 OID 20777)
-- Name: idx_catalogs__items_audit_timestamp; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_catalogs__items_audit_timestamp ON ONLY audit.catalogs__items USING btree (audit_timestamp);


--
-- TOC entry 5684 (class 1259 OID 20793)
-- Name: catalogs__items_2025_08_audit_timestamp_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX catalogs__items_2025_08_audit_timestamp_idx ON audit.catalogs__items_2025_08 USING btree (audit_timestamp);


--
-- TOC entry 5682 (class 1259 OID 20775)
-- Name: idx_catalogs__items_item_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_catalogs__items_item_id ON ONLY audit.catalogs__items USING btree (item_id);


--
-- TOC entry 5685 (class 1259 OID 20791)
-- Name: catalogs__items_2025_08_item_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX catalogs__items_2025_08_item_id_idx ON audit.catalogs__items_2025_08 USING btree (item_id);


--
-- TOC entry 5681 (class 1259 OID 20776)
-- Name: idx_catalogs__items_fk_subcategory_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_catalogs__items_fk_subcategory_id ON ONLY audit.catalogs__items USING btree (subcategory_id);


--
-- TOC entry 5688 (class 1259 OID 20792)
-- Name: catalogs__items_2025_08_subcategory_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX catalogs__items_2025_08_subcategory_id_idx ON audit.catalogs__items_2025_08 USING btree (subcategory_id);


--
-- TOC entry 5691 (class 1259 OID 20810)
-- Name: idx_catalogs__nutritional_variants_audit_operation; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_catalogs__nutritional_variants_audit_operation ON ONLY audit.catalogs__nutritional_variants USING btree (audit_operation);


--
-- TOC entry 5694 (class 1259 OID 20825)
-- Name: catalogs__nutritional_variants_2025_08_audit_operation_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX catalogs__nutritional_variants_2025_08_audit_operation_idx ON audit.catalogs__nutritional_variants_2025_08 USING btree (audit_operation);


--
-- TOC entry 5692 (class 1259 OID 20809)
-- Name: idx_catalogs__nutritional_variants_audit_timestamp; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_catalogs__nutritional_variants_audit_timestamp ON ONLY audit.catalogs__nutritional_variants USING btree (audit_timestamp);


--
-- TOC entry 5695 (class 1259 OID 20824)
-- Name: catalogs__nutritional_variants_2025_08_audit_timestamp_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX catalogs__nutritional_variants_2025_08_audit_timestamp_idx ON audit.catalogs__nutritional_variants_2025_08 USING btree (audit_timestamp);


--
-- TOC entry 5693 (class 1259 OID 20808)
-- Name: idx_catalogs__nutritional_variants_nutritional_variant_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_catalogs__nutritional_variants_nutritional_variant_id ON ONLY audit.catalogs__nutritional_variants USING btree (nutritional_variant_id);


--
-- TOC entry 5698 (class 1259 OID 20823)
-- Name: catalogs__nutritional_variants_2025__nutritional_variant_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX catalogs__nutritional_variants_2025__nutritional_variant_id_idx ON audit.catalogs__nutritional_variants_2025_08 USING btree (nutritional_variant_id);


--
-- TOC entry 5701 (class 1259 OID 20843)
-- Name: idx_catalogs__offers_audit_operation; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_catalogs__offers_audit_operation ON ONLY audit.catalogs__offers USING btree (audit_operation);


--
-- TOC entry 5706 (class 1259 OID 20860)
-- Name: catalogs__offers_2025_08_audit_operation_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX catalogs__offers_2025_08_audit_operation_idx ON audit.catalogs__offers_2025_08 USING btree (audit_operation);


--
-- TOC entry 5702 (class 1259 OID 20842)
-- Name: idx_catalogs__offers_audit_timestamp; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_catalogs__offers_audit_timestamp ON ONLY audit.catalogs__offers USING btree (audit_timestamp);


--
-- TOC entry 5707 (class 1259 OID 20859)
-- Name: catalogs__offers_2025_08_audit_timestamp_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX catalogs__offers_2025_08_audit_timestamp_idx ON audit.catalogs__offers_2025_08 USING btree (audit_timestamp);


--
-- TOC entry 5705 (class 1259 OID 20839)
-- Name: idx_catalogs__offers_offer_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_catalogs__offers_offer_id ON ONLY audit.catalogs__offers USING btree (offer_id);


--
-- TOC entry 5708 (class 1259 OID 20856)
-- Name: catalogs__offers_2025_08_offer_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX catalogs__offers_2025_08_offer_id_idx ON audit.catalogs__offers_2025_08 USING btree (offer_id);


--
-- TOC entry 5703 (class 1259 OID 20840)
-- Name: idx_catalogs__offers_fk_product_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_catalogs__offers_fk_product_id ON ONLY audit.catalogs__offers USING btree (product_id);


--
-- TOC entry 5711 (class 1259 OID 20857)
-- Name: catalogs__offers_2025_08_product_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX catalogs__offers_2025_08_product_id_idx ON audit.catalogs__offers_2025_08 USING btree (product_id);


--
-- TOC entry 5704 (class 1259 OID 20841)
-- Name: idx_catalogs__offers_fk_supplier_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_catalogs__offers_fk_supplier_id ON ONLY audit.catalogs__offers USING btree (supplier_id);


--
-- TOC entry 5712 (class 1259 OID 20858)
-- Name: catalogs__offers_2025_08_supplier_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX catalogs__offers_2025_08_supplier_id_idx ON audit.catalogs__offers_2025_08 USING btree (supplier_id);


--
-- TOC entry 5715 (class 1259 OID 20876)
-- Name: idx_catalogs__packagings_audit_operation; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_catalogs__packagings_audit_operation ON ONLY audit.catalogs__packagings USING btree (audit_operation);


--
-- TOC entry 5718 (class 1259 OID 20891)
-- Name: catalogs__packagings_2025_08_audit_operation_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX catalogs__packagings_2025_08_audit_operation_idx ON audit.catalogs__packagings_2025_08 USING btree (audit_operation);


--
-- TOC entry 5716 (class 1259 OID 20875)
-- Name: idx_catalogs__packagings_audit_timestamp; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_catalogs__packagings_audit_timestamp ON ONLY audit.catalogs__packagings USING btree (audit_timestamp);


--
-- TOC entry 5719 (class 1259 OID 20890)
-- Name: catalogs__packagings_2025_08_audit_timestamp_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX catalogs__packagings_2025_08_audit_timestamp_idx ON audit.catalogs__packagings_2025_08 USING btree (audit_timestamp);


--
-- TOC entry 5717 (class 1259 OID 20874)
-- Name: idx_catalogs__packagings_packaging_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_catalogs__packagings_packaging_id ON ONLY audit.catalogs__packagings USING btree (packaging_id);


--
-- TOC entry 5720 (class 1259 OID 20889)
-- Name: catalogs__packagings_2025_08_packaging_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX catalogs__packagings_2025_08_packaging_id_idx ON audit.catalogs__packagings_2025_08 USING btree (packaging_id);


--
-- TOC entry 5725 (class 1259 OID 20917)
-- Name: idx_catalogs__products_audit_operation; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_catalogs__products_audit_operation ON ONLY audit.catalogs__products USING btree (audit_operation);


--
-- TOC entry 5738 (class 1259 OID 20942)
-- Name: catalogs__products_2025_08_audit_operation_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX catalogs__products_2025_08_audit_operation_idx ON audit.catalogs__products_2025_08 USING btree (audit_operation);


--
-- TOC entry 5726 (class 1259 OID 20916)
-- Name: idx_catalogs__products_audit_timestamp; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_catalogs__products_audit_timestamp ON ONLY audit.catalogs__products USING btree (audit_timestamp);


--
-- TOC entry 5739 (class 1259 OID 20941)
-- Name: catalogs__products_2025_08_audit_timestamp_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX catalogs__products_2025_08_audit_timestamp_idx ON audit.catalogs__products_2025_08 USING btree (audit_timestamp);


--
-- TOC entry 5727 (class 1259 OID 20913)
-- Name: idx_catalogs__products_fk_brand_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_catalogs__products_fk_brand_id ON ONLY audit.catalogs__products USING btree (brand_id);


--
-- TOC entry 5740 (class 1259 OID 20938)
-- Name: catalogs__products_2025_08_brand_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX catalogs__products_2025_08_brand_id_idx ON audit.catalogs__products_2025_08 USING btree (brand_id);


--
-- TOC entry 5728 (class 1259 OID 20907)
-- Name: idx_catalogs__products_fk_composition_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_catalogs__products_fk_composition_id ON ONLY audit.catalogs__products USING btree (composition_id);


--
-- TOC entry 5741 (class 1259 OID 20932)
-- Name: catalogs__products_2025_08_composition_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX catalogs__products_2025_08_composition_id_idx ON audit.catalogs__products_2025_08 USING btree (composition_id);


--
-- TOC entry 5729 (class 1259 OID 20911)
-- Name: idx_catalogs__products_fk_filling_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_catalogs__products_fk_filling_id ON ONLY audit.catalogs__products USING btree (filling_id);


--
-- TOC entry 5742 (class 1259 OID 20936)
-- Name: catalogs__products_2025_08_filling_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX catalogs__products_2025_08_filling_id_idx ON audit.catalogs__products_2025_08 USING btree (filling_id);


--
-- TOC entry 5730 (class 1259 OID 20910)
-- Name: idx_catalogs__products_fk_flavor_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_catalogs__products_fk_flavor_id ON ONLY audit.catalogs__products USING btree (flavor_id);


--
-- TOC entry 5743 (class 1259 OID 20935)
-- Name: catalogs__products_2025_08_flavor_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX catalogs__products_2025_08_flavor_id_idx ON audit.catalogs__products_2025_08 USING btree (flavor_id);


--
-- TOC entry 5731 (class 1259 OID 20909)
-- Name: idx_catalogs__products_fk_format_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_catalogs__products_fk_format_id ON ONLY audit.catalogs__products USING btree (format_id);


--
-- TOC entry 5744 (class 1259 OID 20934)
-- Name: catalogs__products_2025_08_format_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX catalogs__products_2025_08_format_id_idx ON audit.catalogs__products_2025_08 USING btree (format_id);


--
-- TOC entry 5732 (class 1259 OID 20906)
-- Name: idx_catalogs__products_fk_item_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_catalogs__products_fk_item_id ON ONLY audit.catalogs__products USING btree (item_id);


--
-- TOC entry 5745 (class 1259 OID 20931)
-- Name: catalogs__products_2025_08_item_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX catalogs__products_2025_08_item_id_idx ON audit.catalogs__products_2025_08 USING btree (item_id);


--
-- TOC entry 5733 (class 1259 OID 20912)
-- Name: idx_catalogs__products_fk_nutritional_variant_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_catalogs__products_fk_nutritional_variant_id ON ONLY audit.catalogs__products USING btree (nutritional_variant_id);


--
-- TOC entry 5746 (class 1259 OID 20937)
-- Name: catalogs__products_2025_08_nutritional_variant_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX catalogs__products_2025_08_nutritional_variant_id_idx ON audit.catalogs__products_2025_08 USING btree (nutritional_variant_id);


--
-- TOC entry 5734 (class 1259 OID 20914)
-- Name: idx_catalogs__products_fk_packaging_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_catalogs__products_fk_packaging_id ON ONLY audit.catalogs__products USING btree (packaging_id);


--
-- TOC entry 5747 (class 1259 OID 20939)
-- Name: catalogs__products_2025_08_packaging_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX catalogs__products_2025_08_packaging_id_idx ON audit.catalogs__products_2025_08 USING btree (packaging_id);


--
-- TOC entry 5737 (class 1259 OID 20905)
-- Name: idx_catalogs__products_product_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_catalogs__products_product_id ON ONLY audit.catalogs__products USING btree (product_id);


--
-- TOC entry 5750 (class 1259 OID 20930)
-- Name: catalogs__products_2025_08_product_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX catalogs__products_2025_08_product_id_idx ON audit.catalogs__products_2025_08 USING btree (product_id);


--
-- TOC entry 5735 (class 1259 OID 20915)
-- Name: idx_catalogs__products_fk_quantity_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_catalogs__products_fk_quantity_id ON ONLY audit.catalogs__products USING btree (quantity_id);


--
-- TOC entry 5751 (class 1259 OID 20940)
-- Name: catalogs__products_2025_08_quantity_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX catalogs__products_2025_08_quantity_id_idx ON audit.catalogs__products_2025_08 USING btree (quantity_id);


--
-- TOC entry 5736 (class 1259 OID 20908)
-- Name: idx_catalogs__products_fk_variant_type_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_catalogs__products_fk_variant_type_id ON ONLY audit.catalogs__products USING btree (variant_type_id);


--
-- TOC entry 5752 (class 1259 OID 20933)
-- Name: catalogs__products_2025_08_variant_type_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX catalogs__products_2025_08_variant_type_id_idx ON audit.catalogs__products_2025_08 USING btree (variant_type_id);


--
-- TOC entry 5755 (class 1259 OID 20958)
-- Name: idx_catalogs__quantities_audit_operation; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_catalogs__quantities_audit_operation ON ONLY audit.catalogs__quantities USING btree (audit_operation);


--
-- TOC entry 5758 (class 1259 OID 20973)
-- Name: catalogs__quantities_2025_08_audit_operation_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX catalogs__quantities_2025_08_audit_operation_idx ON audit.catalogs__quantities_2025_08 USING btree (audit_operation);


--
-- TOC entry 5756 (class 1259 OID 20957)
-- Name: idx_catalogs__quantities_audit_timestamp; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_catalogs__quantities_audit_timestamp ON ONLY audit.catalogs__quantities USING btree (audit_timestamp);


--
-- TOC entry 5759 (class 1259 OID 20972)
-- Name: catalogs__quantities_2025_08_audit_timestamp_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX catalogs__quantities_2025_08_audit_timestamp_idx ON audit.catalogs__quantities_2025_08 USING btree (audit_timestamp);


--
-- TOC entry 5757 (class 1259 OID 20956)
-- Name: idx_catalogs__quantities_quantity_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_catalogs__quantities_quantity_id ON ONLY audit.catalogs__quantities USING btree (quantity_id);


--
-- TOC entry 5762 (class 1259 OID 20971)
-- Name: catalogs__quantities_2025_08_quantity_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX catalogs__quantities_2025_08_quantity_id_idx ON audit.catalogs__quantities_2025_08 USING btree (quantity_id);


--
-- TOC entry 5765 (class 1259 OID 20990)
-- Name: idx_catalogs__subcategories_audit_operation; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_catalogs__subcategories_audit_operation ON ONLY audit.catalogs__subcategories USING btree (audit_operation);


--
-- TOC entry 5769 (class 1259 OID 21006)
-- Name: catalogs__subcategories_2025_08_audit_operation_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX catalogs__subcategories_2025_08_audit_operation_idx ON audit.catalogs__subcategories_2025_08 USING btree (audit_operation);


--
-- TOC entry 5766 (class 1259 OID 20989)
-- Name: idx_catalogs__subcategories_audit_timestamp; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_catalogs__subcategories_audit_timestamp ON ONLY audit.catalogs__subcategories USING btree (audit_timestamp);


--
-- TOC entry 5770 (class 1259 OID 21005)
-- Name: catalogs__subcategories_2025_08_audit_timestamp_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX catalogs__subcategories_2025_08_audit_timestamp_idx ON audit.catalogs__subcategories_2025_08 USING btree (audit_timestamp);


--
-- TOC entry 5767 (class 1259 OID 20988)
-- Name: idx_catalogs__subcategories_fk_category_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_catalogs__subcategories_fk_category_id ON ONLY audit.catalogs__subcategories USING btree (category_id);


--
-- TOC entry 5771 (class 1259 OID 21004)
-- Name: catalogs__subcategories_2025_08_category_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX catalogs__subcategories_2025_08_category_id_idx ON audit.catalogs__subcategories_2025_08 USING btree (category_id);


--
-- TOC entry 5768 (class 1259 OID 20987)
-- Name: idx_catalogs__subcategories_subcategory_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_catalogs__subcategories_subcategory_id ON ONLY audit.catalogs__subcategories USING btree (subcategory_id);


--
-- TOC entry 5774 (class 1259 OID 21003)
-- Name: catalogs__subcategories_2025_08_subcategory_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX catalogs__subcategories_2025_08_subcategory_id_idx ON audit.catalogs__subcategories_2025_08 USING btree (subcategory_id);


--
-- TOC entry 5777 (class 1259 OID 21022)
-- Name: idx_catalogs__variant_types_audit_operation; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_catalogs__variant_types_audit_operation ON ONLY audit.catalogs__variant_types USING btree (audit_operation);


--
-- TOC entry 5780 (class 1259 OID 21037)
-- Name: catalogs__variant_types_2025_08_audit_operation_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX catalogs__variant_types_2025_08_audit_operation_idx ON audit.catalogs__variant_types_2025_08 USING btree (audit_operation);


--
-- TOC entry 5778 (class 1259 OID 21021)
-- Name: idx_catalogs__variant_types_audit_timestamp; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_catalogs__variant_types_audit_timestamp ON ONLY audit.catalogs__variant_types USING btree (audit_timestamp);


--
-- TOC entry 5781 (class 1259 OID 21036)
-- Name: catalogs__variant_types_2025_08_audit_timestamp_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX catalogs__variant_types_2025_08_audit_timestamp_idx ON audit.catalogs__variant_types_2025_08 USING btree (audit_timestamp);


--
-- TOC entry 5779 (class 1259 OID 21020)
-- Name: idx_catalogs__variant_types_variant_type_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_catalogs__variant_types_variant_type_id ON ONLY audit.catalogs__variant_types USING btree (variant_type_id);


--
-- TOC entry 5784 (class 1259 OID 21035)
-- Name: catalogs__variant_types_2025_08_variant_type_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX catalogs__variant_types_2025_08_variant_type_id_idx ON audit.catalogs__variant_types_2025_08 USING btree (variant_type_id);


--
-- TOC entry 5931 (class 1259 OID 21710)
-- Name: idx_quotation__quotation_submissions_audit_operation; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_quotation__quotation_submissions_audit_operation ON ONLY audit.quotation__quotation_submissions USING btree (audit_operation);


--
-- TOC entry 5932 (class 1259 OID 21709)
-- Name: idx_quotation__quotation_submissions_audit_timestamp; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_quotation__quotation_submissions_audit_timestamp ON ONLY audit.quotation__quotation_submissions USING btree (audit_timestamp);


--
-- TOC entry 5933 (class 1259 OID 21707)
-- Name: idx_quotation__quotation_submissions_fk_shopping_list_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_quotation__quotation_submissions_fk_shopping_list_id ON ONLY audit.quotation__quotation_submissions USING btree (shopping_list_id);


--
-- TOC entry 5934 (class 1259 OID 21708)
-- Name: idx_quotation__quotation_submissions_fk_submission_status_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_quotation__quotation_submissions_fk_submission_status_id ON ONLY audit.quotation__quotation_submissions USING btree (submission_status_id);


--
-- TOC entry 5935 (class 1259 OID 21706)
-- Name: idx_quotation__quotation_submissions_quotation_submission_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_quotation__quotation_submissions_quotation_submission_id ON ONLY audit.quotation__quotation_submissions USING btree (quotation_submission_id);


--
-- TOC entry 5963 (class 1259 OID 21783)
-- Name: idx_quotation__quoted_prices_audit_operation; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_quotation__quoted_prices_audit_operation ON ONLY audit.quotation__quoted_prices USING btree (audit_operation);


--
-- TOC entry 5964 (class 1259 OID 21782)
-- Name: idx_quotation__quoted_prices_audit_timestamp; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_quotation__quoted_prices_audit_timestamp ON ONLY audit.quotation__quoted_prices USING btree (audit_timestamp);


--
-- TOC entry 5965 (class 1259 OID 21781)
-- Name: idx_quotation__quoted_prices_fk_supplier_quotation_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_quotation__quoted_prices_fk_supplier_quotation_id ON ONLY audit.quotation__quoted_prices USING btree (supplier_quotation_id);


--
-- TOC entry 5966 (class 1259 OID 21780)
-- Name: idx_quotation__quoted_prices_quoted_price_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_quotation__quoted_prices_quoted_price_id ON ONLY audit.quotation__quoted_prices USING btree (quoted_price_id);


--
-- TOC entry 5897 (class 1259 OID 21665)
-- Name: idx_quotation__shopping_list_items_audit_operation; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_quotation__shopping_list_items_audit_operation ON ONLY audit.quotation__shopping_list_items USING btree (audit_operation);


--
-- TOC entry 5898 (class 1259 OID 21664)
-- Name: idx_quotation__shopping_list_items_audit_timestamp; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_quotation__shopping_list_items_audit_timestamp ON ONLY audit.quotation__shopping_list_items USING btree (audit_timestamp);


--
-- TOC entry 5899 (class 1259 OID 21661)
-- Name: idx_quotation__shopping_list_items_fk_brand_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_quotation__shopping_list_items_fk_brand_id ON ONLY audit.quotation__shopping_list_items USING btree (brand_id);


--
-- TOC entry 5900 (class 1259 OID 21655)
-- Name: idx_quotation__shopping_list_items_fk_composition_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_quotation__shopping_list_items_fk_composition_id ON ONLY audit.quotation__shopping_list_items USING btree (composition_id);


--
-- TOC entry 5901 (class 1259 OID 21659)
-- Name: idx_quotation__shopping_list_items_fk_filling_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_quotation__shopping_list_items_fk_filling_id ON ONLY audit.quotation__shopping_list_items USING btree (filling_id);


--
-- TOC entry 5902 (class 1259 OID 21658)
-- Name: idx_quotation__shopping_list_items_fk_flavor_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_quotation__shopping_list_items_fk_flavor_id ON ONLY audit.quotation__shopping_list_items USING btree (flavor_id);


--
-- TOC entry 5903 (class 1259 OID 21657)
-- Name: idx_quotation__shopping_list_items_fk_format_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_quotation__shopping_list_items_fk_format_id ON ONLY audit.quotation__shopping_list_items USING btree (format_id);


--
-- TOC entry 5904 (class 1259 OID 21653)
-- Name: idx_quotation__shopping_list_items_fk_item_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_quotation__shopping_list_items_fk_item_id ON ONLY audit.quotation__shopping_list_items USING btree (item_id);


--
-- TOC entry 5905 (class 1259 OID 21660)
-- Name: idx_quotation__shopping_list_items_fk_nutritional_variant_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_quotation__shopping_list_items_fk_nutritional_variant_id ON ONLY audit.quotation__shopping_list_items USING btree (nutritional_variant_id);


--
-- TOC entry 5906 (class 1259 OID 21662)
-- Name: idx_quotation__shopping_list_items_fk_packaging_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_quotation__shopping_list_items_fk_packaging_id ON ONLY audit.quotation__shopping_list_items USING btree (packaging_id);


--
-- TOC entry 5907 (class 1259 OID 21654)
-- Name: idx_quotation__shopping_list_items_fk_product_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_quotation__shopping_list_items_fk_product_id ON ONLY audit.quotation__shopping_list_items USING btree (product_id);


--
-- TOC entry 5908 (class 1259 OID 21663)
-- Name: idx_quotation__shopping_list_items_fk_quantity_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_quotation__shopping_list_items_fk_quantity_id ON ONLY audit.quotation__shopping_list_items USING btree (quantity_id);


--
-- TOC entry 5909 (class 1259 OID 21652)
-- Name: idx_quotation__shopping_list_items_fk_shopping_list_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_quotation__shopping_list_items_fk_shopping_list_id ON ONLY audit.quotation__shopping_list_items USING btree (shopping_list_id);


--
-- TOC entry 5910 (class 1259 OID 21656)
-- Name: idx_quotation__shopping_list_items_fk_variant_type_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_quotation__shopping_list_items_fk_variant_type_id ON ONLY audit.quotation__shopping_list_items USING btree (variant_type_id);


--
-- TOC entry 5911 (class 1259 OID 21651)
-- Name: idx_quotation__shopping_list_items_shopping_list_item_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_quotation__shopping_list_items_shopping_list_item_id ON ONLY audit.quotation__shopping_list_items USING btree (shopping_list_item_id);


--
-- TOC entry 5883 (class 1259 OID 21620)
-- Name: idx_quotation__shopping_lists_audit_operation; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_quotation__shopping_lists_audit_operation ON ONLY audit.quotation__shopping_lists USING btree (audit_operation);


--
-- TOC entry 5884 (class 1259 OID 21619)
-- Name: idx_quotation__shopping_lists_audit_timestamp; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_quotation__shopping_lists_audit_timestamp ON ONLY audit.quotation__shopping_lists USING btree (audit_timestamp);


--
-- TOC entry 5885 (class 1259 OID 21618)
-- Name: idx_quotation__shopping_lists_fk_employee_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_quotation__shopping_lists_fk_employee_id ON ONLY audit.quotation__shopping_lists USING btree (employee_id);


--
-- TOC entry 5886 (class 1259 OID 21617)
-- Name: idx_quotation__shopping_lists_fk_establishment_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_quotation__shopping_lists_fk_establishment_id ON ONLY audit.quotation__shopping_lists USING btree (establishment_id);


--
-- TOC entry 5887 (class 1259 OID 21616)
-- Name: idx_quotation__shopping_lists_shopping_list_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_quotation__shopping_lists_shopping_list_id ON ONLY audit.quotation__shopping_lists USING btree (shopping_list_id);


--
-- TOC entry 5863 (class 1259 OID 21556)
-- Name: idx_quotation__submission_statuses_audit_operation; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_quotation__submission_statuses_audit_operation ON ONLY audit.quotation__submission_statuses USING btree (audit_operation);


--
-- TOC entry 5864 (class 1259 OID 21555)
-- Name: idx_quotation__submission_statuses_audit_timestamp; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_quotation__submission_statuses_audit_timestamp ON ONLY audit.quotation__submission_statuses USING btree (audit_timestamp);


--
-- TOC entry 5865 (class 1259 OID 21554)
-- Name: idx_quotation__submission_statuses_submission_status_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_quotation__submission_statuses_submission_status_id ON ONLY audit.quotation__submission_statuses USING btree (submission_status_id);


--
-- TOC entry 5873 (class 1259 OID 21587)
-- Name: idx_quotation__supplier_quotation_statuses_audit_operation; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_quotation__supplier_quotation_statuses_audit_operation ON ONLY audit.quotation__supplier_quotation_statuses USING btree (audit_operation);


--
-- TOC entry 5874 (class 1259 OID 21586)
-- Name: idx_quotation__supplier_quotation_statuses_audit_timestamp; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_quotation__supplier_quotation_statuses_audit_timestamp ON ONLY audit.quotation__supplier_quotation_statuses USING btree (audit_timestamp);


--
-- TOC entry 5875 (class 1259 OID 21585)
-- Name: idx_quotation__supplier_quotation_statuses_quotation_status_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_quotation__supplier_quotation_statuses_quotation_status_id ON ONLY audit.quotation__supplier_quotation_statuses USING btree (quotation_status_id);


--
-- TOC entry 5945 (class 1259 OID 21747)
-- Name: idx_quotation__supplier_quotations_audit_operation; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_quotation__supplier_quotations_audit_operation ON ONLY audit.quotation__supplier_quotations USING btree (audit_operation);


--
-- TOC entry 5946 (class 1259 OID 21746)
-- Name: idx_quotation__supplier_quotations_audit_timestamp; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_quotation__supplier_quotations_audit_timestamp ON ONLY audit.quotation__supplier_quotations USING btree (audit_timestamp);


--
-- TOC entry 5947 (class 1259 OID 21745)
-- Name: idx_quotation__supplier_quotations_fk_quotation_status_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_quotation__supplier_quotations_fk_quotation_status_id ON ONLY audit.quotation__supplier_quotations USING btree (quotation_status_id);


--
-- TOC entry 5948 (class 1259 OID 21742)
-- Name: idx_quotation__supplier_quotations_fk_quotation_submission_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_quotation__supplier_quotations_fk_quotation_submission_id ON ONLY audit.quotation__supplier_quotations USING btree (quotation_submission_id);


--
-- TOC entry 5949 (class 1259 OID 21743)
-- Name: idx_quotation__supplier_quotations_fk_shopping_list_item_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_quotation__supplier_quotations_fk_shopping_list_item_id ON ONLY audit.quotation__supplier_quotations USING btree (shopping_list_item_id);


--
-- TOC entry 5950 (class 1259 OID 21744)
-- Name: idx_quotation__supplier_quotations_fk_supplier_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_quotation__supplier_quotations_fk_supplier_id ON ONLY audit.quotation__supplier_quotations USING btree (supplier_id);


--
-- TOC entry 5951 (class 1259 OID 21741)
-- Name: idx_quotation__supplier_quotations_supplier_quotation_id; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX idx_quotation__supplier_quotations_supplier_quotation_id ON ONLY audit.quotation__supplier_quotations USING btree (supplier_quotation_id);


--
-- TOC entry 5938 (class 1259 OID 21727)
-- Name: quotation__quotation_submissions_2025_08_audit_operation_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX quotation__quotation_submissions_2025_08_audit_operation_idx ON audit.quotation__quotation_submissions_2025_08 USING btree (audit_operation);


--
-- TOC entry 5939 (class 1259 OID 21726)
-- Name: quotation__quotation_submissions_2025_08_audit_timestamp_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX quotation__quotation_submissions_2025_08_audit_timestamp_idx ON audit.quotation__quotation_submissions_2025_08 USING btree (audit_timestamp);


--
-- TOC entry 5942 (class 1259 OID 21724)
-- Name: quotation__quotation_submissions_2025_08_shopping_list_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX quotation__quotation_submissions_2025_08_shopping_list_id_idx ON audit.quotation__quotation_submissions_2025_08 USING btree (shopping_list_id);


--
-- TOC entry 5943 (class 1259 OID 21725)
-- Name: quotation__quotation_submissions_2025__submission_status_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX quotation__quotation_submissions_2025__submission_status_id_idx ON audit.quotation__quotation_submissions_2025_08 USING btree (submission_status_id);


--
-- TOC entry 5944 (class 1259 OID 21723)
-- Name: quotation__quotation_submissions_20_quotation_submission_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX quotation__quotation_submissions_20_quotation_submission_id_idx ON audit.quotation__quotation_submissions_2025_08 USING btree (quotation_submission_id);


--
-- TOC entry 5969 (class 1259 OID 21799)
-- Name: quotation__quoted_prices_2025_08_audit_operation_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX quotation__quoted_prices_2025_08_audit_operation_idx ON audit.quotation__quoted_prices_2025_08 USING btree (audit_operation);


--
-- TOC entry 5970 (class 1259 OID 21798)
-- Name: quotation__quoted_prices_2025_08_audit_timestamp_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX quotation__quoted_prices_2025_08_audit_timestamp_idx ON audit.quotation__quoted_prices_2025_08 USING btree (audit_timestamp);


--
-- TOC entry 5973 (class 1259 OID 21796)
-- Name: quotation__quoted_prices_2025_08_quoted_price_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX quotation__quoted_prices_2025_08_quoted_price_id_idx ON audit.quotation__quoted_prices_2025_08 USING btree (quoted_price_id);


--
-- TOC entry 5974 (class 1259 OID 21797)
-- Name: quotation__quoted_prices_2025_08_supplier_quotation_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX quotation__quoted_prices_2025_08_supplier_quotation_id_idx ON audit.quotation__quoted_prices_2025_08 USING btree (supplier_quotation_id);


--
-- TOC entry 5914 (class 1259 OID 21692)
-- Name: quotation__shopping_list_items_2025_08_audit_operation_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX quotation__shopping_list_items_2025_08_audit_operation_idx ON audit.quotation__shopping_list_items_2025_08 USING btree (audit_operation);


--
-- TOC entry 5915 (class 1259 OID 21691)
-- Name: quotation__shopping_list_items_2025_08_audit_timestamp_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX quotation__shopping_list_items_2025_08_audit_timestamp_idx ON audit.quotation__shopping_list_items_2025_08 USING btree (audit_timestamp);


--
-- TOC entry 5916 (class 1259 OID 21688)
-- Name: quotation__shopping_list_items_2025_08_brand_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX quotation__shopping_list_items_2025_08_brand_id_idx ON audit.quotation__shopping_list_items_2025_08 USING btree (brand_id);


--
-- TOC entry 5917 (class 1259 OID 21682)
-- Name: quotation__shopping_list_items_2025_08_composition_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX quotation__shopping_list_items_2025_08_composition_id_idx ON audit.quotation__shopping_list_items_2025_08 USING btree (composition_id);


--
-- TOC entry 5918 (class 1259 OID 21686)
-- Name: quotation__shopping_list_items_2025_08_filling_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX quotation__shopping_list_items_2025_08_filling_id_idx ON audit.quotation__shopping_list_items_2025_08 USING btree (filling_id);


--
-- TOC entry 5919 (class 1259 OID 21685)
-- Name: quotation__shopping_list_items_2025_08_flavor_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX quotation__shopping_list_items_2025_08_flavor_id_idx ON audit.quotation__shopping_list_items_2025_08 USING btree (flavor_id);


--
-- TOC entry 5920 (class 1259 OID 21684)
-- Name: quotation__shopping_list_items_2025_08_format_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX quotation__shopping_list_items_2025_08_format_id_idx ON audit.quotation__shopping_list_items_2025_08 USING btree (format_id);


--
-- TOC entry 5921 (class 1259 OID 21680)
-- Name: quotation__shopping_list_items_2025_08_item_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX quotation__shopping_list_items_2025_08_item_id_idx ON audit.quotation__shopping_list_items_2025_08 USING btree (item_id);


--
-- TOC entry 5922 (class 1259 OID 21689)
-- Name: quotation__shopping_list_items_2025_08_packaging_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX quotation__shopping_list_items_2025_08_packaging_id_idx ON audit.quotation__shopping_list_items_2025_08 USING btree (packaging_id);


--
-- TOC entry 5925 (class 1259 OID 21681)
-- Name: quotation__shopping_list_items_2025_08_product_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX quotation__shopping_list_items_2025_08_product_id_idx ON audit.quotation__shopping_list_items_2025_08 USING btree (product_id);


--
-- TOC entry 5926 (class 1259 OID 21690)
-- Name: quotation__shopping_list_items_2025_08_quantity_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX quotation__shopping_list_items_2025_08_quantity_id_idx ON audit.quotation__shopping_list_items_2025_08 USING btree (quantity_id);


--
-- TOC entry 5927 (class 1259 OID 21679)
-- Name: quotation__shopping_list_items_2025_08_shopping_list_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX quotation__shopping_list_items_2025_08_shopping_list_id_idx ON audit.quotation__shopping_list_items_2025_08 USING btree (shopping_list_id);


--
-- TOC entry 5928 (class 1259 OID 21683)
-- Name: quotation__shopping_list_items_2025_08_variant_type_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX quotation__shopping_list_items_2025_08_variant_type_id_idx ON audit.quotation__shopping_list_items_2025_08 USING btree (variant_type_id);


--
-- TOC entry 5929 (class 1259 OID 21678)
-- Name: quotation__shopping_list_items_2025_0_shopping_list_item_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX quotation__shopping_list_items_2025_0_shopping_list_item_id_idx ON audit.quotation__shopping_list_items_2025_08 USING btree (shopping_list_item_id);


--
-- TOC entry 5930 (class 1259 OID 21687)
-- Name: quotation__shopping_list_items_2025__nutritional_variant_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX quotation__shopping_list_items_2025__nutritional_variant_id_idx ON audit.quotation__shopping_list_items_2025_08 USING btree (nutritional_variant_id);


--
-- TOC entry 5890 (class 1259 OID 21637)
-- Name: quotation__shopping_lists_2025_08_audit_operation_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX quotation__shopping_lists_2025_08_audit_operation_idx ON audit.quotation__shopping_lists_2025_08 USING btree (audit_operation);


--
-- TOC entry 5891 (class 1259 OID 21636)
-- Name: quotation__shopping_lists_2025_08_audit_timestamp_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX quotation__shopping_lists_2025_08_audit_timestamp_idx ON audit.quotation__shopping_lists_2025_08 USING btree (audit_timestamp);


--
-- TOC entry 5892 (class 1259 OID 21635)
-- Name: quotation__shopping_lists_2025_08_employee_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX quotation__shopping_lists_2025_08_employee_id_idx ON audit.quotation__shopping_lists_2025_08 USING btree (employee_id);


--
-- TOC entry 5893 (class 1259 OID 21634)
-- Name: quotation__shopping_lists_2025_08_establishment_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX quotation__shopping_lists_2025_08_establishment_id_idx ON audit.quotation__shopping_lists_2025_08 USING btree (establishment_id);


--
-- TOC entry 5896 (class 1259 OID 21633)
-- Name: quotation__shopping_lists_2025_08_shopping_list_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX quotation__shopping_lists_2025_08_shopping_list_id_idx ON audit.quotation__shopping_lists_2025_08 USING btree (shopping_list_id);


--
-- TOC entry 5868 (class 1259 OID 21571)
-- Name: quotation__submission_statuses_2025_08_audit_operation_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX quotation__submission_statuses_2025_08_audit_operation_idx ON audit.quotation__submission_statuses_2025_08 USING btree (audit_operation);


--
-- TOC entry 5869 (class 1259 OID 21570)
-- Name: quotation__submission_statuses_2025_08_audit_timestamp_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX quotation__submission_statuses_2025_08_audit_timestamp_idx ON audit.quotation__submission_statuses_2025_08 USING btree (audit_timestamp);


--
-- TOC entry 5872 (class 1259 OID 21569)
-- Name: quotation__submission_statuses_2025_08_submission_status_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX quotation__submission_statuses_2025_08_submission_status_id_idx ON audit.quotation__submission_statuses_2025_08 USING btree (submission_status_id);


--
-- TOC entry 5880 (class 1259 OID 21602)
-- Name: quotation__supplier_quotation_statuses_2025_audit_operation_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX quotation__supplier_quotation_statuses_2025_audit_operation_idx ON audit.quotation__supplier_quotation_statuses_2025_08 USING btree (audit_operation);


--
-- TOC entry 5881 (class 1259 OID 21601)
-- Name: quotation__supplier_quotation_statuses_2025_audit_timestamp_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX quotation__supplier_quotation_statuses_2025_audit_timestamp_idx ON audit.quotation__supplier_quotation_statuses_2025_08 USING btree (audit_timestamp);


--
-- TOC entry 5882 (class 1259 OID 21600)
-- Name: quotation__supplier_quotation_statuses__quotation_status_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX quotation__supplier_quotation_statuses__quotation_status_id_idx ON audit.quotation__supplier_quotation_statuses_2025_08 USING btree (quotation_status_id);


--
-- TOC entry 5954 (class 1259 OID 21766)
-- Name: quotation__supplier_quotations_2025_08_audit_operation_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX quotation__supplier_quotations_2025_08_audit_operation_idx ON audit.quotation__supplier_quotations_2025_08 USING btree (audit_operation);


--
-- TOC entry 5955 (class 1259 OID 21765)
-- Name: quotation__supplier_quotations_2025_08_audit_timestamp_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX quotation__supplier_quotations_2025_08_audit_timestamp_idx ON audit.quotation__supplier_quotations_2025_08 USING btree (audit_timestamp);


--
-- TOC entry 5958 (class 1259 OID 21764)
-- Name: quotation__supplier_quotations_2025_08_quotation_status_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX quotation__supplier_quotations_2025_08_quotation_status_id_idx ON audit.quotation__supplier_quotations_2025_08 USING btree (quotation_status_id);


--
-- TOC entry 5959 (class 1259 OID 21763)
-- Name: quotation__supplier_quotations_2025_08_supplier_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX quotation__supplier_quotations_2025_08_supplier_id_idx ON audit.quotation__supplier_quotations_2025_08 USING btree (supplier_id);


--
-- TOC entry 5960 (class 1259 OID 21762)
-- Name: quotation__supplier_quotations_2025_0_shopping_list_item_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX quotation__supplier_quotations_2025_0_shopping_list_item_id_idx ON audit.quotation__supplier_quotations_2025_08 USING btree (shopping_list_item_id);


--
-- TOC entry 5961 (class 1259 OID 21760)
-- Name: quotation__supplier_quotations_2025_0_supplier_quotation_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX quotation__supplier_quotations_2025_0_supplier_quotation_id_idx ON audit.quotation__supplier_quotations_2025_08 USING btree (supplier_quotation_id);


--
-- TOC entry 5962 (class 1259 OID 21761)
-- Name: quotation__supplier_quotations_2025_quotation_submission_id_idx; Type: INDEX; Schema: audit; Owner: postgres
--

CREATE INDEX quotation__supplier_quotations_2025_quotation_submission_id_idx ON audit.quotation__supplier_quotations_2025_08 USING btree (quotation_submission_id);


--
-- TOC entry 5841 (class 1259 OID 21520)
-- Name: idx_quotation_shopping_list_items_item_id; Type: INDEX; Schema: quotation; Owner: postgres
--

CREATE INDEX idx_quotation_shopping_list_items_item_id ON quotation.shopping_list_items USING btree (item_id);


--
-- TOC entry 5842 (class 1259 OID 21521)
-- Name: idx_quotation_shopping_list_items_product_id; Type: INDEX; Schema: quotation; Owner: postgres
--

CREATE INDEX idx_quotation_shopping_list_items_product_id ON quotation.shopping_list_items USING btree (product_id);


--
-- TOC entry 5843 (class 1259 OID 21519)
-- Name: idx_quotation_shopping_list_items_shopping_list_id; Type: INDEX; Schema: quotation; Owner: postgres
--

CREATE INDEX idx_quotation_shopping_list_items_shopping_list_id ON quotation.shopping_list_items USING btree (shopping_list_id);


--
-- TOC entry 5844 (class 1259 OID 21522)
-- Name: idx_quotation_shopping_list_items_term; Type: INDEX; Schema: quotation; Owner: postgres
--

CREATE INDEX idx_quotation_shopping_list_items_term ON quotation.shopping_list_items USING btree (term);


--
-- TOC entry 5836 (class 1259 OID 21518)
-- Name: idx_quotation_shopping_lists_created_at; Type: INDEX; Schema: quotation; Owner: postgres
--

CREATE INDEX idx_quotation_shopping_lists_created_at ON quotation.shopping_lists USING btree (created_at);


--
-- TOC entry 5837 (class 1259 OID 21517)
-- Name: idx_quotation_shopping_lists_employee_id; Type: INDEX; Schema: quotation; Owner: postgres
--

CREATE INDEX idx_quotation_shopping_lists_employee_id ON quotation.shopping_lists USING btree (employee_id);


--
-- TOC entry 5838 (class 1259 OID 21516)
-- Name: idx_quotation_shopping_lists_establishment_id; Type: INDEX; Schema: quotation; Owner: postgres
--

CREATE INDEX idx_quotation_shopping_lists_establishment_id ON quotation.shopping_lists USING btree (establishment_id);


--
-- TOC entry 5847 (class 1259 OID 21523)
-- Name: idx_quotation_submissions_shopping_list_id; Type: INDEX; Schema: quotation; Owner: postgres
--

CREATE INDEX idx_quotation_submissions_shopping_list_id ON quotation.quotation_submissions USING btree (shopping_list_id);


--
-- TOC entry 5848 (class 1259 OID 21524)
-- Name: idx_quotation_submissions_status_id; Type: INDEX; Schema: quotation; Owner: postgres
--

CREATE INDEX idx_quotation_submissions_status_id ON quotation.quotation_submissions USING btree (submission_status_id);


--
-- TOC entry 5849 (class 1259 OID 21525)
-- Name: idx_quotation_submissions_submission_date; Type: INDEX; Schema: quotation; Owner: postgres
--

CREATE INDEX idx_quotation_submissions_submission_date ON quotation.quotation_submissions USING btree (submission_date);


--
-- TOC entry 5858 (class 1259 OID 21530)
-- Name: idx_quoted_prices_supplier_quotation_id; Type: INDEX; Schema: quotation; Owner: postgres
--

CREATE INDEX idx_quoted_prices_supplier_quotation_id ON quotation.quoted_prices USING btree (supplier_quotation_id);


--
-- TOC entry 5859 (class 1259 OID 21531)
-- Name: idx_quoted_prices_unit_price; Type: INDEX; Schema: quotation; Owner: postgres
--

CREATE INDEX idx_quoted_prices_unit_price ON quotation.quoted_prices USING btree (unit_price);


--
-- TOC entry 5860 (class 1259 OID 21532)
-- Name: idx_quoted_prices_validity_days; Type: INDEX; Schema: quotation; Owner: postgres
--

CREATE INDEX idx_quoted_prices_validity_days ON quotation.quoted_prices USING btree (validity_days);


--
-- TOC entry 5852 (class 1259 OID 21527)
-- Name: idx_supplier_quotations_shopping_list_item_id; Type: INDEX; Schema: quotation; Owner: postgres
--

CREATE INDEX idx_supplier_quotations_shopping_list_item_id ON quotation.supplier_quotations USING btree (shopping_list_item_id);


--
-- TOC entry 5853 (class 1259 OID 21529)
-- Name: idx_supplier_quotations_status_id; Type: INDEX; Schema: quotation; Owner: postgres
--

CREATE INDEX idx_supplier_quotations_status_id ON quotation.supplier_quotations USING btree (quotation_status_id);


--
-- TOC entry 5854 (class 1259 OID 21526)
-- Name: idx_supplier_quotations_submission_id; Type: INDEX; Schema: quotation; Owner: postgres
--

CREATE INDEX idx_supplier_quotations_submission_id ON quotation.supplier_quotations USING btree (quotation_submission_id);


--
-- TOC entry 5855 (class 1259 OID 21528)
-- Name: idx_supplier_quotations_supplier_id; Type: INDEX; Schema: quotation; Owner: postgres
--

CREATE INDEX idx_supplier_quotations_supplier_id ON quotation.supplier_quotations USING btree (supplier_id);


--
-- TOC entry 5975 (class 0 OID 0)
-- Name: accounts__api_keys_2025_08_api_key_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_accounts__api_keys_api_key_id ATTACH PARTITION audit.accounts__api_keys_2025_08_api_key_id_idx;


--
-- TOC entry 5976 (class 0 OID 0)
-- Name: accounts__api_keys_2025_08_audit_operation_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_accounts__api_keys_audit_operation ATTACH PARTITION audit.accounts__api_keys_2025_08_audit_operation_idx;


--
-- TOC entry 5977 (class 0 OID 0)
-- Name: accounts__api_keys_2025_08_audit_timestamp_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_accounts__api_keys_audit_timestamp ATTACH PARTITION audit.accounts__api_keys_2025_08_audit_timestamp_idx;


--
-- TOC entry 5978 (class 0 OID 0)
-- Name: accounts__api_keys_2025_08_employee_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_accounts__api_keys_fk_employee_id ATTACH PARTITION audit.accounts__api_keys_2025_08_employee_id_idx;


--
-- TOC entry 5979 (class 0 OID 0)
-- Name: accounts__api_keys_2025_08_pkey; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.accounts__api_keys_pkey ATTACH PARTITION audit.accounts__api_keys_2025_08_pkey;


--
-- TOC entry 5980 (class 0 OID 0)
-- Name: accounts__api_scopes_2025_08_api_key_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_accounts__api_scopes_fk_api_key_id ATTACH PARTITION audit.accounts__api_scopes_2025_08_api_key_id_idx;


--
-- TOC entry 5981 (class 0 OID 0)
-- Name: accounts__api_scopes_2025_08_api_scope_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_accounts__api_scopes_api_scope_id ATTACH PARTITION audit.accounts__api_scopes_2025_08_api_scope_id_idx;


--
-- TOC entry 5982 (class 0 OID 0)
-- Name: accounts__api_scopes_2025_08_audit_operation_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_accounts__api_scopes_audit_operation ATTACH PARTITION audit.accounts__api_scopes_2025_08_audit_operation_idx;


--
-- TOC entry 5983 (class 0 OID 0)
-- Name: accounts__api_scopes_2025_08_audit_timestamp_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_accounts__api_scopes_audit_timestamp ATTACH PARTITION audit.accounts__api_scopes_2025_08_audit_timestamp_idx;


--
-- TOC entry 5984 (class 0 OID 0)
-- Name: accounts__api_scopes_2025_08_feature_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_accounts__api_scopes_fk_feature_id ATTACH PARTITION audit.accounts__api_scopes_2025_08_feature_id_idx;


--
-- TOC entry 5985 (class 0 OID 0)
-- Name: accounts__api_scopes_2025_08_pkey; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.accounts__api_scopes_pkey ATTACH PARTITION audit.accounts__api_scopes_2025_08_pkey;


--
-- TOC entry 5986 (class 0 OID 0)
-- Name: accounts__apis_2025_08_api_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_accounts__apis_api_id ATTACH PARTITION audit.accounts__apis_2025_08_api_id_idx;


--
-- TOC entry 5987 (class 0 OID 0)
-- Name: accounts__apis_2025_08_audit_operation_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_accounts__apis_audit_operation ATTACH PARTITION audit.accounts__apis_2025_08_audit_operation_idx;


--
-- TOC entry 5988 (class 0 OID 0)
-- Name: accounts__apis_2025_08_audit_timestamp_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_accounts__apis_audit_timestamp ATTACH PARTITION audit.accounts__apis_2025_08_audit_timestamp_idx;


--
-- TOC entry 5989 (class 0 OID 0)
-- Name: accounts__apis_2025_08_module_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_accounts__apis_fk_module_id ATTACH PARTITION audit.accounts__apis_2025_08_module_id_idx;


--
-- TOC entry 5990 (class 0 OID 0)
-- Name: accounts__apis_2025_08_pkey; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.accounts__apis_pkey ATTACH PARTITION audit.accounts__apis_2025_08_pkey;


--
-- TOC entry 6125 (class 0 OID 0)
-- Name: accounts__employee_addresses_2025_08_audit_operation_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_accounts__employee_addresses_audit_operation ATTACH PARTITION audit.accounts__employee_addresses_2025_08_audit_operation_idx;


--
-- TOC entry 6126 (class 0 OID 0)
-- Name: accounts__employee_addresses_2025_08_audit_timestamp_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_accounts__employee_addresses_audit_timestamp ATTACH PARTITION audit.accounts__employee_addresses_2025_08_audit_timestamp_idx;


--
-- TOC entry 6127 (class 0 OID 0)
-- Name: accounts__employee_addresses_2025_08_employee_address_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_accounts__employee_addresses_employee_address_id ATTACH PARTITION audit.accounts__employee_addresses_2025_08_employee_address_id_idx;


--
-- TOC entry 6128 (class 0 OID 0)
-- Name: accounts__employee_addresses_2025_08_employee_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_accounts__employee_addresses_fk_employee_id ATTACH PARTITION audit.accounts__employee_addresses_2025_08_employee_id_idx;


--
-- TOC entry 6129 (class 0 OID 0)
-- Name: accounts__employee_addresses_2025_08_pkey; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.accounts__employee_addresses_pkey ATTACH PARTITION audit.accounts__employee_addresses_2025_08_pkey;


--
-- TOC entry 6120 (class 0 OID 0)
-- Name: accounts__employee_personal_data_2025_08_audit_operation_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_accounts__employee_personal_data_audit_operation ATTACH PARTITION audit.accounts__employee_personal_data_2025_08_audit_operation_idx;


--
-- TOC entry 6121 (class 0 OID 0)
-- Name: accounts__employee_personal_data_2025_08_audit_timestamp_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_accounts__employee_personal_data_audit_timestamp ATTACH PARTITION audit.accounts__employee_personal_data_2025_08_audit_timestamp_idx;


--
-- TOC entry 6122 (class 0 OID 0)
-- Name: accounts__employee_personal_data_2025_08_employee_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_accounts__employee_personal_data_fk_employee_id ATTACH PARTITION audit.accounts__employee_personal_data_2025_08_employee_id_idx;


--
-- TOC entry 6123 (class 0 OID 0)
-- Name: accounts__employee_personal_data_2025_08_pkey; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.accounts__employee_personal_data_pkey ATTACH PARTITION audit.accounts__employee_personal_data_2025_08_pkey;


--
-- TOC entry 6124 (class 0 OID 0)
-- Name: accounts__employee_personal_data__employee_personal_data_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_accounts__employee_personal_data_employee_personal_data_id ATTACH PARTITION audit.accounts__employee_personal_data__employee_personal_data_id_idx;


--
-- TOC entry 5991 (class 0 OID 0)
-- Name: accounts__employee_roles_2025_08_audit_operation_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_accounts__employee_roles_audit_operation ATTACH PARTITION audit.accounts__employee_roles_2025_08_audit_operation_idx;


--
-- TOC entry 5992 (class 0 OID 0)
-- Name: accounts__employee_roles_2025_08_audit_timestamp_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_accounts__employee_roles_audit_timestamp ATTACH PARTITION audit.accounts__employee_roles_2025_08_audit_timestamp_idx;


--
-- TOC entry 5993 (class 0 OID 0)
-- Name: accounts__employee_roles_2025_08_employee_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_accounts__employee_roles_fk_employee_id ATTACH PARTITION audit.accounts__employee_roles_2025_08_employee_id_idx;


--
-- TOC entry 5994 (class 0 OID 0)
-- Name: accounts__employee_roles_2025_08_employee_role_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_accounts__employee_roles_employee_role_id ATTACH PARTITION audit.accounts__employee_roles_2025_08_employee_role_id_idx;


--
-- TOC entry 5995 (class 0 OID 0)
-- Name: accounts__employee_roles_2025_08_pkey; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.accounts__employee_roles_pkey ATTACH PARTITION audit.accounts__employee_roles_2025_08_pkey;


--
-- TOC entry 5996 (class 0 OID 0)
-- Name: accounts__employee_roles_2025_08_role_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_accounts__employee_roles_fk_role_id ATTACH PARTITION audit.accounts__employee_roles_2025_08_role_id_idx;


--
-- TOC entry 5997 (class 0 OID 0)
-- Name: accounts__employees_2025_08_audit_operation_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_accounts__employees_audit_operation ATTACH PARTITION audit.accounts__employees_2025_08_audit_operation_idx;


--
-- TOC entry 5998 (class 0 OID 0)
-- Name: accounts__employees_2025_08_audit_timestamp_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_accounts__employees_audit_timestamp ATTACH PARTITION audit.accounts__employees_2025_08_audit_timestamp_idx;


--
-- TOC entry 5999 (class 0 OID 0)
-- Name: accounts__employees_2025_08_employee_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_accounts__employees_employee_id ATTACH PARTITION audit.accounts__employees_2025_08_employee_id_idx;


--
-- TOC entry 6000 (class 0 OID 0)
-- Name: accounts__employees_2025_08_establishment_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_accounts__employees_fk_establishment_id ATTACH PARTITION audit.accounts__employees_2025_08_establishment_id_idx;


--
-- TOC entry 6001 (class 0 OID 0)
-- Name: accounts__employees_2025_08_pkey; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.accounts__employees_pkey ATTACH PARTITION audit.accounts__employees_2025_08_pkey;


--
-- TOC entry 6002 (class 0 OID 0)
-- Name: accounts__employees_2025_08_supplier_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_accounts__employees_fk_supplier_id ATTACH PARTITION audit.accounts__employees_2025_08_supplier_id_idx;


--
-- TOC entry 6003 (class 0 OID 0)
-- Name: accounts__employees_2025_08_user_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_accounts__employees_fk_user_id ATTACH PARTITION audit.accounts__employees_2025_08_user_id_idx;


--
-- TOC entry 6004 (class 0 OID 0)
-- Name: accounts__establishment_addresses_2025_08_audit_operation_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_accounts__establishment_addresses_audit_operation ATTACH PARTITION audit.accounts__establishment_addresses_2025_08_audit_operation_idx;


--
-- TOC entry 6005 (class 0 OID 0)
-- Name: accounts__establishment_addresses_2025_08_audit_timestamp_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_accounts__establishment_addresses_audit_timestamp ATTACH PARTITION audit.accounts__establishment_addresses_2025_08_audit_timestamp_idx;


--
-- TOC entry 6006 (class 0 OID 0)
-- Name: accounts__establishment_addresses_2025_08_establishment_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_accounts__establishment_addresses_fk_establishment_id ATTACH PARTITION audit.accounts__establishment_addresses_2025_08_establishment_id_idx;


--
-- TOC entry 6007 (class 0 OID 0)
-- Name: accounts__establishment_addresses_2025_08_pkey; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.accounts__establishment_addresses_pkey ATTACH PARTITION audit.accounts__establishment_addresses_2025_08_pkey;


--
-- TOC entry 6008 (class 0 OID 0)
-- Name: accounts__establishment_addresses__establishment_address_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_accounts__establishment_addresses_establishment_address_id ATTACH PARTITION audit.accounts__establishment_addresses__establishment_address_id_idx;


--
-- TOC entry 6009 (class 0 OID 0)
-- Name: accounts__establishment_busin_establishment_business_data_i_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_accounts__establishment_business_data_establishment_busines ATTACH PARTITION audit.accounts__establishment_busin_establishment_business_data_i_idx;


--
-- TOC entry 6010 (class 0 OID 0)
-- Name: accounts__establishment_business_data_2025_08_pkey; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.accounts__establishment_business_data_pkey ATTACH PARTITION audit.accounts__establishment_business_data_2025_08_pkey;


--
-- TOC entry 6011 (class 0 OID 0)
-- Name: accounts__establishment_business_data_2025__audit_operation_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_accounts__establishment_business_data_audit_operation ATTACH PARTITION audit.accounts__establishment_business_data_2025__audit_operation_idx;


--
-- TOC entry 6012 (class 0 OID 0)
-- Name: accounts__establishment_business_data_2025__audit_timestamp_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_accounts__establishment_business_data_audit_timestamp ATTACH PARTITION audit.accounts__establishment_business_data_2025__audit_timestamp_idx;


--
-- TOC entry 6013 (class 0 OID 0)
-- Name: accounts__establishment_business_data_2025_establishment_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_accounts__establishment_business_data_fk_establishment_id ATTACH PARTITION audit.accounts__establishment_business_data_2025_establishment_id_idx;


--
-- TOC entry 6014 (class 0 OID 0)
-- Name: accounts__establishments_2025_08_audit_operation_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_accounts__establishments_audit_operation ATTACH PARTITION audit.accounts__establishments_2025_08_audit_operation_idx;


--
-- TOC entry 6015 (class 0 OID 0)
-- Name: accounts__establishments_2025_08_audit_timestamp_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_accounts__establishments_audit_timestamp ATTACH PARTITION audit.accounts__establishments_2025_08_audit_timestamp_idx;


--
-- TOC entry 6016 (class 0 OID 0)
-- Name: accounts__establishments_2025_08_establishment_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_accounts__establishments_establishment_id ATTACH PARTITION audit.accounts__establishments_2025_08_establishment_id_idx;


--
-- TOC entry 6017 (class 0 OID 0)
-- Name: accounts__establishments_2025_08_pkey; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.accounts__establishments_pkey ATTACH PARTITION audit.accounts__establishments_2025_08_pkey;


--
-- TOC entry 6018 (class 0 OID 0)
-- Name: accounts__features_2025_08_audit_operation_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_accounts__features_audit_operation ATTACH PARTITION audit.accounts__features_2025_08_audit_operation_idx;


--
-- TOC entry 6019 (class 0 OID 0)
-- Name: accounts__features_2025_08_audit_timestamp_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_accounts__features_audit_timestamp ATTACH PARTITION audit.accounts__features_2025_08_audit_timestamp_idx;


--
-- TOC entry 6020 (class 0 OID 0)
-- Name: accounts__features_2025_08_feature_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_accounts__features_feature_id ATTACH PARTITION audit.accounts__features_2025_08_feature_id_idx;


--
-- TOC entry 6021 (class 0 OID 0)
-- Name: accounts__features_2025_08_module_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_accounts__features_fk_module_id ATTACH PARTITION audit.accounts__features_2025_08_module_id_idx;


--
-- TOC entry 6022 (class 0 OID 0)
-- Name: accounts__features_2025_08_pkey; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.accounts__features_pkey ATTACH PARTITION audit.accounts__features_2025_08_pkey;


--
-- TOC entry 6023 (class 0 OID 0)
-- Name: accounts__features_2025_08_platform_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_accounts__features_fk_platform_id ATTACH PARTITION audit.accounts__features_2025_08_platform_id_idx;


--
-- TOC entry 6024 (class 0 OID 0)
-- Name: accounts__modules_2025_08_audit_operation_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_accounts__modules_audit_operation ATTACH PARTITION audit.accounts__modules_2025_08_audit_operation_idx;


--
-- TOC entry 6025 (class 0 OID 0)
-- Name: accounts__modules_2025_08_audit_timestamp_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_accounts__modules_audit_timestamp ATTACH PARTITION audit.accounts__modules_2025_08_audit_timestamp_idx;


--
-- TOC entry 6026 (class 0 OID 0)
-- Name: accounts__modules_2025_08_module_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_accounts__modules_module_id ATTACH PARTITION audit.accounts__modules_2025_08_module_id_idx;


--
-- TOC entry 6027 (class 0 OID 0)
-- Name: accounts__modules_2025_08_pkey; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.accounts__modules_pkey ATTACH PARTITION audit.accounts__modules_2025_08_pkey;


--
-- TOC entry 6028 (class 0 OID 0)
-- Name: accounts__platforms_2025_08_audit_operation_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_accounts__platforms_audit_operation ATTACH PARTITION audit.accounts__platforms_2025_08_audit_operation_idx;


--
-- TOC entry 6029 (class 0 OID 0)
-- Name: accounts__platforms_2025_08_audit_timestamp_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_accounts__platforms_audit_timestamp ATTACH PARTITION audit.accounts__platforms_2025_08_audit_timestamp_idx;


--
-- TOC entry 6030 (class 0 OID 0)
-- Name: accounts__platforms_2025_08_pkey; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.accounts__platforms_pkey ATTACH PARTITION audit.accounts__platforms_2025_08_pkey;


--
-- TOC entry 6031 (class 0 OID 0)
-- Name: accounts__platforms_2025_08_platform_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_accounts__platforms_platform_id ATTACH PARTITION audit.accounts__platforms_2025_08_platform_id_idx;


--
-- TOC entry 6032 (class 0 OID 0)
-- Name: accounts__role_features_2025_08_audit_operation_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_accounts__role_features_audit_operation ATTACH PARTITION audit.accounts__role_features_2025_08_audit_operation_idx;


--
-- TOC entry 6033 (class 0 OID 0)
-- Name: accounts__role_features_2025_08_audit_timestamp_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_accounts__role_features_audit_timestamp ATTACH PARTITION audit.accounts__role_features_2025_08_audit_timestamp_idx;


--
-- TOC entry 6034 (class 0 OID 0)
-- Name: accounts__role_features_2025_08_feature_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_accounts__role_features_fk_feature_id ATTACH PARTITION audit.accounts__role_features_2025_08_feature_id_idx;


--
-- TOC entry 6035 (class 0 OID 0)
-- Name: accounts__role_features_2025_08_pkey; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.accounts__role_features_pkey ATTACH PARTITION audit.accounts__role_features_2025_08_pkey;


--
-- TOC entry 6036 (class 0 OID 0)
-- Name: accounts__role_features_2025_08_role_feature_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_accounts__role_features_role_feature_id ATTACH PARTITION audit.accounts__role_features_2025_08_role_feature_id_idx;


--
-- TOC entry 6037 (class 0 OID 0)
-- Name: accounts__role_features_2025_08_role_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_accounts__role_features_fk_role_id ATTACH PARTITION audit.accounts__role_features_2025_08_role_id_idx;


--
-- TOC entry 6038 (class 0 OID 0)
-- Name: accounts__roles_2025_08_audit_operation_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_accounts__roles_audit_operation ATTACH PARTITION audit.accounts__roles_2025_08_audit_operation_idx;


--
-- TOC entry 6039 (class 0 OID 0)
-- Name: accounts__roles_2025_08_audit_timestamp_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_accounts__roles_audit_timestamp ATTACH PARTITION audit.accounts__roles_2025_08_audit_timestamp_idx;


--
-- TOC entry 6040 (class 0 OID 0)
-- Name: accounts__roles_2025_08_pkey; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.accounts__roles_pkey ATTACH PARTITION audit.accounts__roles_2025_08_pkey;


--
-- TOC entry 6041 (class 0 OID 0)
-- Name: accounts__roles_2025_08_role_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_accounts__roles_role_id ATTACH PARTITION audit.accounts__roles_2025_08_role_id_idx;


--
-- TOC entry 6042 (class 0 OID 0)
-- Name: accounts__suppliers_2025_08_audit_operation_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_accounts__suppliers_audit_operation ATTACH PARTITION audit.accounts__suppliers_2025_08_audit_operation_idx;


--
-- TOC entry 6043 (class 0 OID 0)
-- Name: accounts__suppliers_2025_08_audit_timestamp_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_accounts__suppliers_audit_timestamp ATTACH PARTITION audit.accounts__suppliers_2025_08_audit_timestamp_idx;


--
-- TOC entry 6044 (class 0 OID 0)
-- Name: accounts__suppliers_2025_08_pkey; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.accounts__suppliers_pkey ATTACH PARTITION audit.accounts__suppliers_2025_08_pkey;


--
-- TOC entry 6045 (class 0 OID 0)
-- Name: accounts__suppliers_2025_08_supplier_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_accounts__suppliers_supplier_id ATTACH PARTITION audit.accounts__suppliers_2025_08_supplier_id_idx;


--
-- TOC entry 6046 (class 0 OID 0)
-- Name: accounts__users_2025_08_audit_operation_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_accounts__users_audit_operation ATTACH PARTITION audit.accounts__users_2025_08_audit_operation_idx;


--
-- TOC entry 6047 (class 0 OID 0)
-- Name: accounts__users_2025_08_audit_timestamp_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_accounts__users_audit_timestamp ATTACH PARTITION audit.accounts__users_2025_08_audit_timestamp_idx;


--
-- TOC entry 6048 (class 0 OID 0)
-- Name: accounts__users_2025_08_pkey; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.accounts__users_pkey ATTACH PARTITION audit.accounts__users_2025_08_pkey;


--
-- TOC entry 6049 (class 0 OID 0)
-- Name: accounts__users_2025_08_user_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_accounts__users_user_id ATTACH PARTITION audit.accounts__users_2025_08_user_id_idx;


--
-- TOC entry 6050 (class 0 OID 0)
-- Name: catalogs__brands_2025_08_audit_operation_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_catalogs__brands_audit_operation ATTACH PARTITION audit.catalogs__brands_2025_08_audit_operation_idx;


--
-- TOC entry 6051 (class 0 OID 0)
-- Name: catalogs__brands_2025_08_audit_timestamp_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_catalogs__brands_audit_timestamp ATTACH PARTITION audit.catalogs__brands_2025_08_audit_timestamp_idx;


--
-- TOC entry 6052 (class 0 OID 0)
-- Name: catalogs__brands_2025_08_brand_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_catalogs__brands_brand_id ATTACH PARTITION audit.catalogs__brands_2025_08_brand_id_idx;


--
-- TOC entry 6053 (class 0 OID 0)
-- Name: catalogs__brands_2025_08_pkey; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.catalogs__brands_pkey ATTACH PARTITION audit.catalogs__brands_2025_08_pkey;


--
-- TOC entry 6054 (class 0 OID 0)
-- Name: catalogs__categories_2025_08_audit_operation_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_catalogs__categories_audit_operation ATTACH PARTITION audit.catalogs__categories_2025_08_audit_operation_idx;


--
-- TOC entry 6055 (class 0 OID 0)
-- Name: catalogs__categories_2025_08_audit_timestamp_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_catalogs__categories_audit_timestamp ATTACH PARTITION audit.catalogs__categories_2025_08_audit_timestamp_idx;


--
-- TOC entry 6056 (class 0 OID 0)
-- Name: catalogs__categories_2025_08_category_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_catalogs__categories_category_id ATTACH PARTITION audit.catalogs__categories_2025_08_category_id_idx;


--
-- TOC entry 6057 (class 0 OID 0)
-- Name: catalogs__categories_2025_08_pkey; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.catalogs__categories_pkey ATTACH PARTITION audit.catalogs__categories_2025_08_pkey;


--
-- TOC entry 6058 (class 0 OID 0)
-- Name: catalogs__compositions_2025_08_audit_operation_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_catalogs__compositions_audit_operation ATTACH PARTITION audit.catalogs__compositions_2025_08_audit_operation_idx;


--
-- TOC entry 6059 (class 0 OID 0)
-- Name: catalogs__compositions_2025_08_audit_timestamp_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_catalogs__compositions_audit_timestamp ATTACH PARTITION audit.catalogs__compositions_2025_08_audit_timestamp_idx;


--
-- TOC entry 6060 (class 0 OID 0)
-- Name: catalogs__compositions_2025_08_composition_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_catalogs__compositions_composition_id ATTACH PARTITION audit.catalogs__compositions_2025_08_composition_id_idx;


--
-- TOC entry 6061 (class 0 OID 0)
-- Name: catalogs__compositions_2025_08_pkey; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.catalogs__compositions_pkey ATTACH PARTITION audit.catalogs__compositions_2025_08_pkey;


--
-- TOC entry 6062 (class 0 OID 0)
-- Name: catalogs__fillings_2025_08_audit_operation_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_catalogs__fillings_audit_operation ATTACH PARTITION audit.catalogs__fillings_2025_08_audit_operation_idx;


--
-- TOC entry 6063 (class 0 OID 0)
-- Name: catalogs__fillings_2025_08_audit_timestamp_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_catalogs__fillings_audit_timestamp ATTACH PARTITION audit.catalogs__fillings_2025_08_audit_timestamp_idx;


--
-- TOC entry 6064 (class 0 OID 0)
-- Name: catalogs__fillings_2025_08_filling_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_catalogs__fillings_filling_id ATTACH PARTITION audit.catalogs__fillings_2025_08_filling_id_idx;


--
-- TOC entry 6065 (class 0 OID 0)
-- Name: catalogs__fillings_2025_08_pkey; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.catalogs__fillings_pkey ATTACH PARTITION audit.catalogs__fillings_2025_08_pkey;


--
-- TOC entry 6066 (class 0 OID 0)
-- Name: catalogs__flavors_2025_08_audit_operation_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_catalogs__flavors_audit_operation ATTACH PARTITION audit.catalogs__flavors_2025_08_audit_operation_idx;


--
-- TOC entry 6067 (class 0 OID 0)
-- Name: catalogs__flavors_2025_08_audit_timestamp_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_catalogs__flavors_audit_timestamp ATTACH PARTITION audit.catalogs__flavors_2025_08_audit_timestamp_idx;


--
-- TOC entry 6068 (class 0 OID 0)
-- Name: catalogs__flavors_2025_08_flavor_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_catalogs__flavors_flavor_id ATTACH PARTITION audit.catalogs__flavors_2025_08_flavor_id_idx;


--
-- TOC entry 6069 (class 0 OID 0)
-- Name: catalogs__flavors_2025_08_pkey; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.catalogs__flavors_pkey ATTACH PARTITION audit.catalogs__flavors_2025_08_pkey;


--
-- TOC entry 6070 (class 0 OID 0)
-- Name: catalogs__formats_2025_08_audit_operation_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_catalogs__formats_audit_operation ATTACH PARTITION audit.catalogs__formats_2025_08_audit_operation_idx;


--
-- TOC entry 6071 (class 0 OID 0)
-- Name: catalogs__formats_2025_08_audit_timestamp_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_catalogs__formats_audit_timestamp ATTACH PARTITION audit.catalogs__formats_2025_08_audit_timestamp_idx;


--
-- TOC entry 6072 (class 0 OID 0)
-- Name: catalogs__formats_2025_08_format_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_catalogs__formats_format_id ATTACH PARTITION audit.catalogs__formats_2025_08_format_id_idx;


--
-- TOC entry 6073 (class 0 OID 0)
-- Name: catalogs__formats_2025_08_pkey; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.catalogs__formats_pkey ATTACH PARTITION audit.catalogs__formats_2025_08_pkey;


--
-- TOC entry 6074 (class 0 OID 0)
-- Name: catalogs__items_2025_08_audit_operation_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_catalogs__items_audit_operation ATTACH PARTITION audit.catalogs__items_2025_08_audit_operation_idx;


--
-- TOC entry 6075 (class 0 OID 0)
-- Name: catalogs__items_2025_08_audit_timestamp_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_catalogs__items_audit_timestamp ATTACH PARTITION audit.catalogs__items_2025_08_audit_timestamp_idx;


--
-- TOC entry 6076 (class 0 OID 0)
-- Name: catalogs__items_2025_08_item_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_catalogs__items_item_id ATTACH PARTITION audit.catalogs__items_2025_08_item_id_idx;


--
-- TOC entry 6077 (class 0 OID 0)
-- Name: catalogs__items_2025_08_pkey; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.catalogs__items_pkey ATTACH PARTITION audit.catalogs__items_2025_08_pkey;


--
-- TOC entry 6078 (class 0 OID 0)
-- Name: catalogs__items_2025_08_subcategory_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_catalogs__items_fk_subcategory_id ATTACH PARTITION audit.catalogs__items_2025_08_subcategory_id_idx;


--
-- TOC entry 6079 (class 0 OID 0)
-- Name: catalogs__nutritional_variants_2025_08_audit_operation_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_catalogs__nutritional_variants_audit_operation ATTACH PARTITION audit.catalogs__nutritional_variants_2025_08_audit_operation_idx;


--
-- TOC entry 6080 (class 0 OID 0)
-- Name: catalogs__nutritional_variants_2025_08_audit_timestamp_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_catalogs__nutritional_variants_audit_timestamp ATTACH PARTITION audit.catalogs__nutritional_variants_2025_08_audit_timestamp_idx;


--
-- TOC entry 6081 (class 0 OID 0)
-- Name: catalogs__nutritional_variants_2025_08_pkey; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.catalogs__nutritional_variants_pkey ATTACH PARTITION audit.catalogs__nutritional_variants_2025_08_pkey;


--
-- TOC entry 6082 (class 0 OID 0)
-- Name: catalogs__nutritional_variants_2025__nutritional_variant_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_catalogs__nutritional_variants_nutritional_variant_id ATTACH PARTITION audit.catalogs__nutritional_variants_2025__nutritional_variant_id_idx;


--
-- TOC entry 6083 (class 0 OID 0)
-- Name: catalogs__offers_2025_08_audit_operation_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_catalogs__offers_audit_operation ATTACH PARTITION audit.catalogs__offers_2025_08_audit_operation_idx;


--
-- TOC entry 6084 (class 0 OID 0)
-- Name: catalogs__offers_2025_08_audit_timestamp_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_catalogs__offers_audit_timestamp ATTACH PARTITION audit.catalogs__offers_2025_08_audit_timestamp_idx;


--
-- TOC entry 6085 (class 0 OID 0)
-- Name: catalogs__offers_2025_08_offer_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_catalogs__offers_offer_id ATTACH PARTITION audit.catalogs__offers_2025_08_offer_id_idx;


--
-- TOC entry 6086 (class 0 OID 0)
-- Name: catalogs__offers_2025_08_pkey; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.catalogs__offers_pkey ATTACH PARTITION audit.catalogs__offers_2025_08_pkey;


--
-- TOC entry 6087 (class 0 OID 0)
-- Name: catalogs__offers_2025_08_product_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_catalogs__offers_fk_product_id ATTACH PARTITION audit.catalogs__offers_2025_08_product_id_idx;


--
-- TOC entry 6088 (class 0 OID 0)
-- Name: catalogs__offers_2025_08_supplier_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_catalogs__offers_fk_supplier_id ATTACH PARTITION audit.catalogs__offers_2025_08_supplier_id_idx;


--
-- TOC entry 6089 (class 0 OID 0)
-- Name: catalogs__packagings_2025_08_audit_operation_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_catalogs__packagings_audit_operation ATTACH PARTITION audit.catalogs__packagings_2025_08_audit_operation_idx;


--
-- TOC entry 6090 (class 0 OID 0)
-- Name: catalogs__packagings_2025_08_audit_timestamp_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_catalogs__packagings_audit_timestamp ATTACH PARTITION audit.catalogs__packagings_2025_08_audit_timestamp_idx;


--
-- TOC entry 6091 (class 0 OID 0)
-- Name: catalogs__packagings_2025_08_packaging_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_catalogs__packagings_packaging_id ATTACH PARTITION audit.catalogs__packagings_2025_08_packaging_id_idx;


--
-- TOC entry 6092 (class 0 OID 0)
-- Name: catalogs__packagings_2025_08_pkey; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.catalogs__packagings_pkey ATTACH PARTITION audit.catalogs__packagings_2025_08_pkey;


--
-- TOC entry 6093 (class 0 OID 0)
-- Name: catalogs__products_2025_08_audit_operation_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_catalogs__products_audit_operation ATTACH PARTITION audit.catalogs__products_2025_08_audit_operation_idx;


--
-- TOC entry 6094 (class 0 OID 0)
-- Name: catalogs__products_2025_08_audit_timestamp_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_catalogs__products_audit_timestamp ATTACH PARTITION audit.catalogs__products_2025_08_audit_timestamp_idx;


--
-- TOC entry 6095 (class 0 OID 0)
-- Name: catalogs__products_2025_08_brand_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_catalogs__products_fk_brand_id ATTACH PARTITION audit.catalogs__products_2025_08_brand_id_idx;


--
-- TOC entry 6096 (class 0 OID 0)
-- Name: catalogs__products_2025_08_composition_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_catalogs__products_fk_composition_id ATTACH PARTITION audit.catalogs__products_2025_08_composition_id_idx;


--
-- TOC entry 6097 (class 0 OID 0)
-- Name: catalogs__products_2025_08_filling_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_catalogs__products_fk_filling_id ATTACH PARTITION audit.catalogs__products_2025_08_filling_id_idx;


--
-- TOC entry 6098 (class 0 OID 0)
-- Name: catalogs__products_2025_08_flavor_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_catalogs__products_fk_flavor_id ATTACH PARTITION audit.catalogs__products_2025_08_flavor_id_idx;


--
-- TOC entry 6099 (class 0 OID 0)
-- Name: catalogs__products_2025_08_format_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_catalogs__products_fk_format_id ATTACH PARTITION audit.catalogs__products_2025_08_format_id_idx;


--
-- TOC entry 6100 (class 0 OID 0)
-- Name: catalogs__products_2025_08_item_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_catalogs__products_fk_item_id ATTACH PARTITION audit.catalogs__products_2025_08_item_id_idx;


--
-- TOC entry 6101 (class 0 OID 0)
-- Name: catalogs__products_2025_08_nutritional_variant_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_catalogs__products_fk_nutritional_variant_id ATTACH PARTITION audit.catalogs__products_2025_08_nutritional_variant_id_idx;


--
-- TOC entry 6102 (class 0 OID 0)
-- Name: catalogs__products_2025_08_packaging_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_catalogs__products_fk_packaging_id ATTACH PARTITION audit.catalogs__products_2025_08_packaging_id_idx;


--
-- TOC entry 6103 (class 0 OID 0)
-- Name: catalogs__products_2025_08_pkey; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.catalogs__products_pkey ATTACH PARTITION audit.catalogs__products_2025_08_pkey;


--
-- TOC entry 6104 (class 0 OID 0)
-- Name: catalogs__products_2025_08_product_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_catalogs__products_product_id ATTACH PARTITION audit.catalogs__products_2025_08_product_id_idx;


--
-- TOC entry 6105 (class 0 OID 0)
-- Name: catalogs__products_2025_08_quantity_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_catalogs__products_fk_quantity_id ATTACH PARTITION audit.catalogs__products_2025_08_quantity_id_idx;


--
-- TOC entry 6106 (class 0 OID 0)
-- Name: catalogs__products_2025_08_variant_type_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_catalogs__products_fk_variant_type_id ATTACH PARTITION audit.catalogs__products_2025_08_variant_type_id_idx;


--
-- TOC entry 6107 (class 0 OID 0)
-- Name: catalogs__quantities_2025_08_audit_operation_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_catalogs__quantities_audit_operation ATTACH PARTITION audit.catalogs__quantities_2025_08_audit_operation_idx;


--
-- TOC entry 6108 (class 0 OID 0)
-- Name: catalogs__quantities_2025_08_audit_timestamp_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_catalogs__quantities_audit_timestamp ATTACH PARTITION audit.catalogs__quantities_2025_08_audit_timestamp_idx;


--
-- TOC entry 6109 (class 0 OID 0)
-- Name: catalogs__quantities_2025_08_pkey; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.catalogs__quantities_pkey ATTACH PARTITION audit.catalogs__quantities_2025_08_pkey;


--
-- TOC entry 6110 (class 0 OID 0)
-- Name: catalogs__quantities_2025_08_quantity_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_catalogs__quantities_quantity_id ATTACH PARTITION audit.catalogs__quantities_2025_08_quantity_id_idx;


--
-- TOC entry 6111 (class 0 OID 0)
-- Name: catalogs__subcategories_2025_08_audit_operation_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_catalogs__subcategories_audit_operation ATTACH PARTITION audit.catalogs__subcategories_2025_08_audit_operation_idx;


--
-- TOC entry 6112 (class 0 OID 0)
-- Name: catalogs__subcategories_2025_08_audit_timestamp_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_catalogs__subcategories_audit_timestamp ATTACH PARTITION audit.catalogs__subcategories_2025_08_audit_timestamp_idx;


--
-- TOC entry 6113 (class 0 OID 0)
-- Name: catalogs__subcategories_2025_08_category_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_catalogs__subcategories_fk_category_id ATTACH PARTITION audit.catalogs__subcategories_2025_08_category_id_idx;


--
-- TOC entry 6114 (class 0 OID 0)
-- Name: catalogs__subcategories_2025_08_pkey; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.catalogs__subcategories_pkey ATTACH PARTITION audit.catalogs__subcategories_2025_08_pkey;


--
-- TOC entry 6115 (class 0 OID 0)
-- Name: catalogs__subcategories_2025_08_subcategory_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_catalogs__subcategories_subcategory_id ATTACH PARTITION audit.catalogs__subcategories_2025_08_subcategory_id_idx;


--
-- TOC entry 6116 (class 0 OID 0)
-- Name: catalogs__variant_types_2025_08_audit_operation_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_catalogs__variant_types_audit_operation ATTACH PARTITION audit.catalogs__variant_types_2025_08_audit_operation_idx;


--
-- TOC entry 6117 (class 0 OID 0)
-- Name: catalogs__variant_types_2025_08_audit_timestamp_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_catalogs__variant_types_audit_timestamp ATTACH PARTITION audit.catalogs__variant_types_2025_08_audit_timestamp_idx;


--
-- TOC entry 6118 (class 0 OID 0)
-- Name: catalogs__variant_types_2025_08_pkey; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.catalogs__variant_types_pkey ATTACH PARTITION audit.catalogs__variant_types_2025_08_pkey;


--
-- TOC entry 6119 (class 0 OID 0)
-- Name: catalogs__variant_types_2025_08_variant_type_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_catalogs__variant_types_variant_type_id ATTACH PARTITION audit.catalogs__variant_types_2025_08_variant_type_id_idx;


--
-- TOC entry 6160 (class 0 OID 0)
-- Name: quotation__quotation_submissions_2025_08_audit_operation_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_quotation__quotation_submissions_audit_operation ATTACH PARTITION audit.quotation__quotation_submissions_2025_08_audit_operation_idx;


--
-- TOC entry 6161 (class 0 OID 0)
-- Name: quotation__quotation_submissions_2025_08_audit_timestamp_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_quotation__quotation_submissions_audit_timestamp ATTACH PARTITION audit.quotation__quotation_submissions_2025_08_audit_timestamp_idx;


--
-- TOC entry 6162 (class 0 OID 0)
-- Name: quotation__quotation_submissions_2025_08_pkey; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.quotation__quotation_submissions_pkey ATTACH PARTITION audit.quotation__quotation_submissions_2025_08_pkey;


--
-- TOC entry 6163 (class 0 OID 0)
-- Name: quotation__quotation_submissions_2025_08_shopping_list_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_quotation__quotation_submissions_fk_shopping_list_id ATTACH PARTITION audit.quotation__quotation_submissions_2025_08_shopping_list_id_idx;


--
-- TOC entry 6164 (class 0 OID 0)
-- Name: quotation__quotation_submissions_2025__submission_status_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_quotation__quotation_submissions_fk_submission_status_id ATTACH PARTITION audit.quotation__quotation_submissions_2025__submission_status_id_idx;


--
-- TOC entry 6165 (class 0 OID 0)
-- Name: quotation__quotation_submissions_20_quotation_submission_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_quotation__quotation_submissions_quotation_submission_id ATTACH PARTITION audit.quotation__quotation_submissions_20_quotation_submission_id_idx;


--
-- TOC entry 6174 (class 0 OID 0)
-- Name: quotation__quoted_prices_2025_08_audit_operation_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_quotation__quoted_prices_audit_operation ATTACH PARTITION audit.quotation__quoted_prices_2025_08_audit_operation_idx;


--
-- TOC entry 6175 (class 0 OID 0)
-- Name: quotation__quoted_prices_2025_08_audit_timestamp_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_quotation__quoted_prices_audit_timestamp ATTACH PARTITION audit.quotation__quoted_prices_2025_08_audit_timestamp_idx;


--
-- TOC entry 6176 (class 0 OID 0)
-- Name: quotation__quoted_prices_2025_08_pkey; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.quotation__quoted_prices_pkey ATTACH PARTITION audit.quotation__quoted_prices_2025_08_pkey;


--
-- TOC entry 6177 (class 0 OID 0)
-- Name: quotation__quoted_prices_2025_08_quoted_price_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_quotation__quoted_prices_quoted_price_id ATTACH PARTITION audit.quotation__quoted_prices_2025_08_quoted_price_id_idx;


--
-- TOC entry 6178 (class 0 OID 0)
-- Name: quotation__quoted_prices_2025_08_supplier_quotation_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_quotation__quoted_prices_fk_supplier_quotation_id ATTACH PARTITION audit.quotation__quoted_prices_2025_08_supplier_quotation_id_idx;


--
-- TOC entry 6144 (class 0 OID 0)
-- Name: quotation__shopping_list_items_2025_08_audit_operation_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_quotation__shopping_list_items_audit_operation ATTACH PARTITION audit.quotation__shopping_list_items_2025_08_audit_operation_idx;


--
-- TOC entry 6145 (class 0 OID 0)
-- Name: quotation__shopping_list_items_2025_08_audit_timestamp_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_quotation__shopping_list_items_audit_timestamp ATTACH PARTITION audit.quotation__shopping_list_items_2025_08_audit_timestamp_idx;


--
-- TOC entry 6146 (class 0 OID 0)
-- Name: quotation__shopping_list_items_2025_08_brand_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_quotation__shopping_list_items_fk_brand_id ATTACH PARTITION audit.quotation__shopping_list_items_2025_08_brand_id_idx;


--
-- TOC entry 6147 (class 0 OID 0)
-- Name: quotation__shopping_list_items_2025_08_composition_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_quotation__shopping_list_items_fk_composition_id ATTACH PARTITION audit.quotation__shopping_list_items_2025_08_composition_id_idx;


--
-- TOC entry 6148 (class 0 OID 0)
-- Name: quotation__shopping_list_items_2025_08_filling_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_quotation__shopping_list_items_fk_filling_id ATTACH PARTITION audit.quotation__shopping_list_items_2025_08_filling_id_idx;


--
-- TOC entry 6149 (class 0 OID 0)
-- Name: quotation__shopping_list_items_2025_08_flavor_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_quotation__shopping_list_items_fk_flavor_id ATTACH PARTITION audit.quotation__shopping_list_items_2025_08_flavor_id_idx;


--
-- TOC entry 6150 (class 0 OID 0)
-- Name: quotation__shopping_list_items_2025_08_format_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_quotation__shopping_list_items_fk_format_id ATTACH PARTITION audit.quotation__shopping_list_items_2025_08_format_id_idx;


--
-- TOC entry 6151 (class 0 OID 0)
-- Name: quotation__shopping_list_items_2025_08_item_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_quotation__shopping_list_items_fk_item_id ATTACH PARTITION audit.quotation__shopping_list_items_2025_08_item_id_idx;


--
-- TOC entry 6152 (class 0 OID 0)
-- Name: quotation__shopping_list_items_2025_08_packaging_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_quotation__shopping_list_items_fk_packaging_id ATTACH PARTITION audit.quotation__shopping_list_items_2025_08_packaging_id_idx;


--
-- TOC entry 6153 (class 0 OID 0)
-- Name: quotation__shopping_list_items_2025_08_pkey; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.quotation__shopping_list_items_pkey ATTACH PARTITION audit.quotation__shopping_list_items_2025_08_pkey;


--
-- TOC entry 6154 (class 0 OID 0)
-- Name: quotation__shopping_list_items_2025_08_product_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_quotation__shopping_list_items_fk_product_id ATTACH PARTITION audit.quotation__shopping_list_items_2025_08_product_id_idx;


--
-- TOC entry 6155 (class 0 OID 0)
-- Name: quotation__shopping_list_items_2025_08_quantity_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_quotation__shopping_list_items_fk_quantity_id ATTACH PARTITION audit.quotation__shopping_list_items_2025_08_quantity_id_idx;


--
-- TOC entry 6156 (class 0 OID 0)
-- Name: quotation__shopping_list_items_2025_08_shopping_list_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_quotation__shopping_list_items_fk_shopping_list_id ATTACH PARTITION audit.quotation__shopping_list_items_2025_08_shopping_list_id_idx;


--
-- TOC entry 6157 (class 0 OID 0)
-- Name: quotation__shopping_list_items_2025_08_variant_type_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_quotation__shopping_list_items_fk_variant_type_id ATTACH PARTITION audit.quotation__shopping_list_items_2025_08_variant_type_id_idx;


--
-- TOC entry 6158 (class 0 OID 0)
-- Name: quotation__shopping_list_items_2025_0_shopping_list_item_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_quotation__shopping_list_items_shopping_list_item_id ATTACH PARTITION audit.quotation__shopping_list_items_2025_0_shopping_list_item_id_idx;


--
-- TOC entry 6159 (class 0 OID 0)
-- Name: quotation__shopping_list_items_2025__nutritional_variant_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_quotation__shopping_list_items_fk_nutritional_variant_id ATTACH PARTITION audit.quotation__shopping_list_items_2025__nutritional_variant_id_idx;


--
-- TOC entry 6138 (class 0 OID 0)
-- Name: quotation__shopping_lists_2025_08_audit_operation_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_quotation__shopping_lists_audit_operation ATTACH PARTITION audit.quotation__shopping_lists_2025_08_audit_operation_idx;


--
-- TOC entry 6139 (class 0 OID 0)
-- Name: quotation__shopping_lists_2025_08_audit_timestamp_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_quotation__shopping_lists_audit_timestamp ATTACH PARTITION audit.quotation__shopping_lists_2025_08_audit_timestamp_idx;


--
-- TOC entry 6140 (class 0 OID 0)
-- Name: quotation__shopping_lists_2025_08_employee_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_quotation__shopping_lists_fk_employee_id ATTACH PARTITION audit.quotation__shopping_lists_2025_08_employee_id_idx;


--
-- TOC entry 6141 (class 0 OID 0)
-- Name: quotation__shopping_lists_2025_08_establishment_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_quotation__shopping_lists_fk_establishment_id ATTACH PARTITION audit.quotation__shopping_lists_2025_08_establishment_id_idx;


--
-- TOC entry 6142 (class 0 OID 0)
-- Name: quotation__shopping_lists_2025_08_pkey; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.quotation__shopping_lists_pkey ATTACH PARTITION audit.quotation__shopping_lists_2025_08_pkey;


--
-- TOC entry 6143 (class 0 OID 0)
-- Name: quotation__shopping_lists_2025_08_shopping_list_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_quotation__shopping_lists_shopping_list_id ATTACH PARTITION audit.quotation__shopping_lists_2025_08_shopping_list_id_idx;


--
-- TOC entry 6130 (class 0 OID 0)
-- Name: quotation__submission_statuses_2025_08_audit_operation_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_quotation__submission_statuses_audit_operation ATTACH PARTITION audit.quotation__submission_statuses_2025_08_audit_operation_idx;


--
-- TOC entry 6131 (class 0 OID 0)
-- Name: quotation__submission_statuses_2025_08_audit_timestamp_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_quotation__submission_statuses_audit_timestamp ATTACH PARTITION audit.quotation__submission_statuses_2025_08_audit_timestamp_idx;


--
-- TOC entry 6132 (class 0 OID 0)
-- Name: quotation__submission_statuses_2025_08_pkey; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.quotation__submission_statuses_pkey ATTACH PARTITION audit.quotation__submission_statuses_2025_08_pkey;


--
-- TOC entry 6133 (class 0 OID 0)
-- Name: quotation__submission_statuses_2025_08_submission_status_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_quotation__submission_statuses_submission_status_id ATTACH PARTITION audit.quotation__submission_statuses_2025_08_submission_status_id_idx;


--
-- TOC entry 6134 (class 0 OID 0)
-- Name: quotation__supplier_quotation_statuses_2025_08_pkey; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.quotation__supplier_quotation_statuses_pkey ATTACH PARTITION audit.quotation__supplier_quotation_statuses_2025_08_pkey;


--
-- TOC entry 6135 (class 0 OID 0)
-- Name: quotation__supplier_quotation_statuses_2025_audit_operation_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_quotation__supplier_quotation_statuses_audit_operation ATTACH PARTITION audit.quotation__supplier_quotation_statuses_2025_audit_operation_idx;


--
-- TOC entry 6136 (class 0 OID 0)
-- Name: quotation__supplier_quotation_statuses_2025_audit_timestamp_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_quotation__supplier_quotation_statuses_audit_timestamp ATTACH PARTITION audit.quotation__supplier_quotation_statuses_2025_audit_timestamp_idx;


--
-- TOC entry 6137 (class 0 OID 0)
-- Name: quotation__supplier_quotation_statuses__quotation_status_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_quotation__supplier_quotation_statuses_quotation_status_id ATTACH PARTITION audit.quotation__supplier_quotation_statuses__quotation_status_id_idx;


--
-- TOC entry 6166 (class 0 OID 0)
-- Name: quotation__supplier_quotations_2025_08_audit_operation_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_quotation__supplier_quotations_audit_operation ATTACH PARTITION audit.quotation__supplier_quotations_2025_08_audit_operation_idx;


--
-- TOC entry 6167 (class 0 OID 0)
-- Name: quotation__supplier_quotations_2025_08_audit_timestamp_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_quotation__supplier_quotations_audit_timestamp ATTACH PARTITION audit.quotation__supplier_quotations_2025_08_audit_timestamp_idx;


--
-- TOC entry 6168 (class 0 OID 0)
-- Name: quotation__supplier_quotations_2025_08_pkey; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.quotation__supplier_quotations_pkey ATTACH PARTITION audit.quotation__supplier_quotations_2025_08_pkey;


--
-- TOC entry 6169 (class 0 OID 0)
-- Name: quotation__supplier_quotations_2025_08_quotation_status_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_quotation__supplier_quotations_fk_quotation_status_id ATTACH PARTITION audit.quotation__supplier_quotations_2025_08_quotation_status_id_idx;


--
-- TOC entry 6170 (class 0 OID 0)
-- Name: quotation__supplier_quotations_2025_08_supplier_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_quotation__supplier_quotations_fk_supplier_id ATTACH PARTITION audit.quotation__supplier_quotations_2025_08_supplier_id_idx;


--
-- TOC entry 6171 (class 0 OID 0)
-- Name: quotation__supplier_quotations_2025_0_shopping_list_item_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_quotation__supplier_quotations_fk_shopping_list_item_id ATTACH PARTITION audit.quotation__supplier_quotations_2025_0_shopping_list_item_id_idx;


--
-- TOC entry 6172 (class 0 OID 0)
-- Name: quotation__supplier_quotations_2025_0_supplier_quotation_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_quotation__supplier_quotations_supplier_quotation_id ATTACH PARTITION audit.quotation__supplier_quotations_2025_0_supplier_quotation_id_idx;


--
-- TOC entry 6173 (class 0 OID 0)
-- Name: quotation__supplier_quotations_2025_quotation_submission_id_idx; Type: INDEX ATTACH; Schema: audit; Owner: postgres
--

ALTER INDEX audit.idx_quotation__supplier_quotations_fk_quotation_submission_id ATTACH PARTITION audit.quotation__supplier_quotations_2025_quotation_submission_id_idx;


--
-- TOC entry 6269 (class 2620 OID 22015)
-- Name: establishment_business_data clean_cnpj_trigger; Type: TRIGGER; Schema: accounts; Owner: postgres
--

CREATE TRIGGER clean_cnpj_trigger BEFORE INSERT OR UPDATE ON accounts.establishment_business_data FOR EACH ROW EXECUTE FUNCTION aux.clean_cnpj_before_insert_update();


--
-- TOC entry 6275 (class 2620 OID 22017)
-- Name: employee_personal_data clean_cpf_trigger; Type: TRIGGER; Schema: accounts; Owner: postgres
--

CREATE TRIGGER clean_cpf_trigger BEFORE INSERT OR UPDATE ON accounts.employee_personal_data FOR EACH ROW EXECUTE FUNCTION aux.clean_cpf_before_insert_update();


--
-- TOC entry 6278 (class 2620 OID 22018)
-- Name: employee_addresses clean_postal_code_trigger; Type: TRIGGER; Schema: accounts; Owner: postgres
--

CREATE TRIGGER clean_postal_code_trigger BEFORE INSERT OR UPDATE ON accounts.employee_addresses FOR EACH ROW EXECUTE FUNCTION aux.clean_postal_code_before_insert_update();


--
-- TOC entry 6272 (class 2620 OID 22016)
-- Name: establishment_addresses clean_postal_code_trigger; Type: TRIGGER; Schema: accounts; Owner: postgres
--

CREATE TRIGGER clean_postal_code_trigger BEFORE INSERT OR UPDATE ON accounts.establishment_addresses FOR EACH ROW EXECUTE FUNCTION aux.clean_postal_code_before_insert_update();


--
-- TOC entry 6253 (class 2620 OID 20099)
-- Name: api_keys trg_audit_accounts_api_keys; Type: TRIGGER; Schema: accounts; Owner: postgres
--

CREATE TRIGGER trg_audit_accounts_api_keys AFTER INSERT OR DELETE OR UPDATE ON accounts.api_keys FOR EACH ROW EXECUTE FUNCTION audit.audit_accounts_api_keys_trigger();


--
-- TOC entry 6254 (class 2620 OID 20133)
-- Name: api_scopes trg_audit_accounts_api_scopes; Type: TRIGGER; Schema: accounts; Owner: postgres
--

CREATE TRIGGER trg_audit_accounts_api_scopes AFTER INSERT OR DELETE OR UPDATE ON accounts.api_scopes FOR EACH ROW EXECUTE FUNCTION audit.audit_accounts_api_scopes_trigger();


--
-- TOC entry 6251 (class 2620 OID 20167)
-- Name: apis trg_audit_accounts_apis; Type: TRIGGER; Schema: accounts; Owner: postgres
--

CREATE TRIGGER trg_audit_accounts_apis AFTER INSERT OR DELETE OR UPDATE ON accounts.apis FOR EACH ROW EXECUTE FUNCTION audit.audit_accounts_apis_trigger();


--
-- TOC entry 6279 (class 2620 OID 21301)
-- Name: employee_addresses trg_audit_accounts_employee_addresses; Type: TRIGGER; Schema: accounts; Owner: postgres
--

CREATE TRIGGER trg_audit_accounts_employee_addresses AFTER INSERT OR DELETE OR UPDATE ON accounts.employee_addresses FOR EACH ROW EXECUTE FUNCTION audit.audit_accounts_employee_addresses_trigger();


--
-- TOC entry 6276 (class 2620 OID 21268)
-- Name: employee_personal_data trg_audit_accounts_employee_personal_data; Type: TRIGGER; Schema: accounts; Owner: postgres
--

CREATE TRIGGER trg_audit_accounts_employee_personal_data AFTER INSERT OR DELETE OR UPDATE ON accounts.employee_personal_data FOR EACH ROW EXECUTE FUNCTION audit.audit_accounts_employee_personal_data_trigger();


--
-- TOC entry 6249 (class 2620 OID 20201)
-- Name: employee_roles trg_audit_accounts_employee_roles; Type: TRIGGER; Schema: accounts; Owner: postgres
--

CREATE TRIGGER trg_audit_accounts_employee_roles AFTER INSERT OR DELETE OR UPDATE ON accounts.employee_roles FOR EACH ROW EXECUTE FUNCTION audit.audit_accounts_employee_roles_trigger();


--
-- TOC entry 6237 (class 2620 OID 20237)
-- Name: employees trg_audit_accounts_employees; Type: TRIGGER; Schema: accounts; Owner: postgres
--

CREATE TRIGGER trg_audit_accounts_employees AFTER INSERT OR DELETE OR UPDATE ON accounts.employees FOR EACH ROW EXECUTE FUNCTION audit.audit_accounts_employees_trigger();


--
-- TOC entry 6273 (class 2620 OID 20272)
-- Name: establishment_addresses trg_audit_accounts_establishment_addresses; Type: TRIGGER; Schema: accounts; Owner: postgres
--

CREATE TRIGGER trg_audit_accounts_establishment_addresses AFTER INSERT OR DELETE OR UPDATE ON accounts.establishment_addresses FOR EACH ROW EXECUTE FUNCTION audit.audit_accounts_establishment_addresses_trigger();


--
-- TOC entry 6270 (class 2620 OID 20305)
-- Name: establishment_business_data trg_audit_accounts_establishment_business_data; Type: TRIGGER; Schema: accounts; Owner: postgres
--

CREATE TRIGGER trg_audit_accounts_establishment_business_data AFTER INSERT OR DELETE OR UPDATE ON accounts.establishment_business_data FOR EACH ROW EXECUTE FUNCTION audit.audit_accounts_establishment_business_data_trigger();


--
-- TOC entry 6235 (class 2620 OID 20337)
-- Name: establishments trg_audit_accounts_establishments; Type: TRIGGER; Schema: accounts; Owner: postgres
--

CREATE TRIGGER trg_audit_accounts_establishments AFTER INSERT OR DELETE OR UPDATE ON accounts.establishments FOR EACH ROW EXECUTE FUNCTION audit.audit_accounts_establishments_trigger();


--
-- TOC entry 6243 (class 2620 OID 20370)
-- Name: features trg_audit_accounts_features; Type: TRIGGER; Schema: accounts; Owner: postgres
--

CREATE TRIGGER trg_audit_accounts_features AFTER INSERT OR DELETE OR UPDATE ON accounts.features FOR EACH ROW EXECUTE FUNCTION audit.audit_accounts_features_trigger();


--
-- TOC entry 6241 (class 2620 OID 20403)
-- Name: modules trg_audit_accounts_modules; Type: TRIGGER; Schema: accounts; Owner: postgres
--

CREATE TRIGGER trg_audit_accounts_modules AFTER INSERT OR DELETE OR UPDATE ON accounts.modules FOR EACH ROW EXECUTE FUNCTION audit.audit_accounts_modules_trigger();


--
-- TOC entry 6239 (class 2620 OID 20434)
-- Name: platforms trg_audit_accounts_platforms; Type: TRIGGER; Schema: accounts; Owner: postgres
--

CREATE TRIGGER trg_audit_accounts_platforms AFTER INSERT OR DELETE OR UPDATE ON accounts.platforms FOR EACH ROW EXECUTE FUNCTION audit.audit_accounts_platforms_trigger();


--
-- TOC entry 6247 (class 2620 OID 20467)
-- Name: role_features trg_audit_accounts_role_features; Type: TRIGGER; Schema: accounts; Owner: postgres
--

CREATE TRIGGER trg_audit_accounts_role_features AFTER INSERT OR DELETE OR UPDATE ON accounts.role_features FOR EACH ROW EXECUTE FUNCTION audit.audit_accounts_role_features_trigger();


--
-- TOC entry 6245 (class 2620 OID 20500)
-- Name: roles trg_audit_accounts_roles; Type: TRIGGER; Schema: accounts; Owner: postgres
--

CREATE TRIGGER trg_audit_accounts_roles AFTER INSERT OR DELETE OR UPDATE ON accounts.roles FOR EACH ROW EXECUTE FUNCTION audit.audit_accounts_roles_trigger();


--
-- TOC entry 6233 (class 2620 OID 20531)
-- Name: suppliers trg_audit_accounts_suppliers; Type: TRIGGER; Schema: accounts; Owner: postgres
--

CREATE TRIGGER trg_audit_accounts_suppliers AFTER INSERT OR DELETE OR UPDATE ON accounts.suppliers FOR EACH ROW EXECUTE FUNCTION audit.audit_accounts_suppliers_trigger();


--
-- TOC entry 6231 (class 2620 OID 20562)
-- Name: users trg_audit_accounts_users; Type: TRIGGER; Schema: accounts; Owner: postgres
--

CREATE TRIGGER trg_audit_accounts_users AFTER INSERT OR DELETE OR UPDATE ON accounts.users FOR EACH ROW EXECUTE FUNCTION audit.audit_accounts_users_trigger();


--
-- TOC entry 6252 (class 2620 OID 22029)
-- Name: apis trg_set_updated_at_apis; Type: TRIGGER; Schema: accounts; Owner: postgres
--

CREATE TRIGGER trg_set_updated_at_apis BEFORE UPDATE ON accounts.apis FOR EACH ROW EXECUTE FUNCTION aux.set_updated_at();


--
-- TOC entry 6280 (class 2620 OID 22033)
-- Name: employee_addresses trg_set_updated_at_employee_addresses; Type: TRIGGER; Schema: accounts; Owner: postgres
--

CREATE TRIGGER trg_set_updated_at_employee_addresses BEFORE UPDATE ON accounts.employee_addresses FOR EACH ROW EXECUTE FUNCTION aux.set_updated_at();


--
-- TOC entry 6277 (class 2620 OID 22032)
-- Name: employee_personal_data trg_set_updated_at_employee_personal_data; Type: TRIGGER; Schema: accounts; Owner: postgres
--

CREATE TRIGGER trg_set_updated_at_employee_personal_data BEFORE UPDATE ON accounts.employee_personal_data FOR EACH ROW EXECUTE FUNCTION aux.set_updated_at();


--
-- TOC entry 6250 (class 2620 OID 22028)
-- Name: employee_roles trg_set_updated_at_employee_roles; Type: TRIGGER; Schema: accounts; Owner: postgres
--

CREATE TRIGGER trg_set_updated_at_employee_roles BEFORE UPDATE ON accounts.employee_roles FOR EACH ROW EXECUTE FUNCTION aux.set_updated_at();


--
-- TOC entry 6238 (class 2620 OID 22022)
-- Name: employees trg_set_updated_at_employees; Type: TRIGGER; Schema: accounts; Owner: postgres
--

CREATE TRIGGER trg_set_updated_at_employees BEFORE UPDATE ON accounts.employees FOR EACH ROW EXECUTE FUNCTION aux.set_updated_at();


--
-- TOC entry 6274 (class 2620 OID 22031)
-- Name: establishment_addresses trg_set_updated_at_establishment_addresses; Type: TRIGGER; Schema: accounts; Owner: postgres
--

CREATE TRIGGER trg_set_updated_at_establishment_addresses BEFORE UPDATE ON accounts.establishment_addresses FOR EACH ROW EXECUTE FUNCTION aux.set_updated_at();


--
-- TOC entry 6271 (class 2620 OID 22030)
-- Name: establishment_business_data trg_set_updated_at_establishment_business_data; Type: TRIGGER; Schema: accounts; Owner: postgres
--

CREATE TRIGGER trg_set_updated_at_establishment_business_data BEFORE UPDATE ON accounts.establishment_business_data FOR EACH ROW EXECUTE FUNCTION aux.set_updated_at();


--
-- TOC entry 6236 (class 2620 OID 22021)
-- Name: establishments trg_set_updated_at_establishments; Type: TRIGGER; Schema: accounts; Owner: postgres
--

CREATE TRIGGER trg_set_updated_at_establishments BEFORE UPDATE ON accounts.establishments FOR EACH ROW EXECUTE FUNCTION aux.set_updated_at();


--
-- TOC entry 6244 (class 2620 OID 22025)
-- Name: features trg_set_updated_at_features; Type: TRIGGER; Schema: accounts; Owner: postgres
--

CREATE TRIGGER trg_set_updated_at_features BEFORE UPDATE ON accounts.features FOR EACH ROW EXECUTE FUNCTION aux.set_updated_at();


--
-- TOC entry 6242 (class 2620 OID 22024)
-- Name: modules trg_set_updated_at_modules; Type: TRIGGER; Schema: accounts; Owner: postgres
--

CREATE TRIGGER trg_set_updated_at_modules BEFORE UPDATE ON accounts.modules FOR EACH ROW EXECUTE FUNCTION aux.set_updated_at();


--
-- TOC entry 6240 (class 2620 OID 22023)
-- Name: platforms trg_set_updated_at_platforms; Type: TRIGGER; Schema: accounts; Owner: postgres
--

CREATE TRIGGER trg_set_updated_at_platforms BEFORE UPDATE ON accounts.platforms FOR EACH ROW EXECUTE FUNCTION aux.set_updated_at();


--
-- TOC entry 6248 (class 2620 OID 22027)
-- Name: role_features trg_set_updated_at_role_features; Type: TRIGGER; Schema: accounts; Owner: postgres
--

CREATE TRIGGER trg_set_updated_at_role_features BEFORE UPDATE ON accounts.role_features FOR EACH ROW EXECUTE FUNCTION aux.set_updated_at();


--
-- TOC entry 6246 (class 2620 OID 22026)
-- Name: roles trg_set_updated_at_roles; Type: TRIGGER; Schema: accounts; Owner: postgres
--

CREATE TRIGGER trg_set_updated_at_roles BEFORE UPDATE ON accounts.roles FOR EACH ROW EXECUTE FUNCTION aux.set_updated_at();


--
-- TOC entry 6234 (class 2620 OID 22020)
-- Name: suppliers trg_set_updated_at_suppliers; Type: TRIGGER; Schema: accounts; Owner: postgres
--

CREATE TRIGGER trg_set_updated_at_suppliers BEFORE UPDATE ON accounts.suppliers FOR EACH ROW EXECUTE FUNCTION aux.set_updated_at();


--
-- TOC entry 6232 (class 2620 OID 22019)
-- Name: users trg_set_updated_at_users; Type: TRIGGER; Schema: accounts; Owner: postgres
--

CREATE TRIGGER trg_set_updated_at_users BEFORE UPDATE ON accounts.users FOR EACH ROW EXECUTE FUNCTION aux.set_updated_at();


--
-- TOC entry 6264 (class 2620 OID 20593)
-- Name: brands trg_audit_catalogs_brands; Type: TRIGGER; Schema: catalogs; Owner: postgres
--

CREATE TRIGGER trg_audit_catalogs_brands AFTER INSERT OR DELETE OR UPDATE ON catalogs.brands FOR EACH ROW EXECUTE FUNCTION audit.audit_catalogs_brands_trigger();


--
-- TOC entry 6255 (class 2620 OID 20624)
-- Name: categories trg_audit_catalogs_categories; Type: TRIGGER; Schema: catalogs; Owner: postgres
--

CREATE TRIGGER trg_audit_catalogs_categories AFTER INSERT OR DELETE OR UPDATE ON catalogs.categories FOR EACH ROW EXECUTE FUNCTION audit.audit_catalogs_categories_trigger();


--
-- TOC entry 6258 (class 2620 OID 20655)
-- Name: compositions trg_audit_catalogs_compositions; Type: TRIGGER; Schema: catalogs; Owner: postgres
--

CREATE TRIGGER trg_audit_catalogs_compositions AFTER INSERT OR DELETE OR UPDATE ON catalogs.compositions FOR EACH ROW EXECUTE FUNCTION audit.audit_catalogs_compositions_trigger();


--
-- TOC entry 6262 (class 2620 OID 20686)
-- Name: fillings trg_audit_catalogs_fillings; Type: TRIGGER; Schema: catalogs; Owner: postgres
--

CREATE TRIGGER trg_audit_catalogs_fillings AFTER INSERT OR DELETE OR UPDATE ON catalogs.fillings FOR EACH ROW EXECUTE FUNCTION audit.audit_catalogs_fillings_trigger();


--
-- TOC entry 6261 (class 2620 OID 20717)
-- Name: flavors trg_audit_catalogs_flavors; Type: TRIGGER; Schema: catalogs; Owner: postgres
--

CREATE TRIGGER trg_audit_catalogs_flavors AFTER INSERT OR DELETE OR UPDATE ON catalogs.flavors FOR EACH ROW EXECUTE FUNCTION audit.audit_catalogs_flavors_trigger();


--
-- TOC entry 6260 (class 2620 OID 20748)
-- Name: formats trg_audit_catalogs_formats; Type: TRIGGER; Schema: catalogs; Owner: postgres
--

CREATE TRIGGER trg_audit_catalogs_formats AFTER INSERT OR DELETE OR UPDATE ON catalogs.formats FOR EACH ROW EXECUTE FUNCTION audit.audit_catalogs_formats_trigger();


--
-- TOC entry 6257 (class 2620 OID 20780)
-- Name: items trg_audit_catalogs_items; Type: TRIGGER; Schema: catalogs; Owner: postgres
--

CREATE TRIGGER trg_audit_catalogs_items AFTER INSERT OR DELETE OR UPDATE ON catalogs.items FOR EACH ROW EXECUTE FUNCTION audit.audit_catalogs_items_trigger();


--
-- TOC entry 6263 (class 2620 OID 20812)
-- Name: nutritional_variants trg_audit_catalogs_nutritional_variants; Type: TRIGGER; Schema: catalogs; Owner: postgres
--

CREATE TRIGGER trg_audit_catalogs_nutritional_variants AFTER INSERT OR DELETE OR UPDATE ON catalogs.nutritional_variants FOR EACH ROW EXECUTE FUNCTION audit.audit_catalogs_nutritional_variants_trigger();


--
-- TOC entry 6268 (class 2620 OID 20845)
-- Name: offers trg_audit_catalogs_offers; Type: TRIGGER; Schema: catalogs; Owner: postgres
--

CREATE TRIGGER trg_audit_catalogs_offers AFTER INSERT OR DELETE OR UPDATE ON catalogs.offers FOR EACH ROW EXECUTE FUNCTION audit.audit_catalogs_offers_trigger();


--
-- TOC entry 6265 (class 2620 OID 20878)
-- Name: packagings trg_audit_catalogs_packagings; Type: TRIGGER; Schema: catalogs; Owner: postgres
--

CREATE TRIGGER trg_audit_catalogs_packagings AFTER INSERT OR DELETE OR UPDATE ON catalogs.packagings FOR EACH ROW EXECUTE FUNCTION audit.audit_catalogs_packagings_trigger();


--
-- TOC entry 6267 (class 2620 OID 20919)
-- Name: products trg_audit_catalogs_products; Type: TRIGGER; Schema: catalogs; Owner: postgres
--

CREATE TRIGGER trg_audit_catalogs_products AFTER INSERT OR DELETE OR UPDATE ON catalogs.products FOR EACH ROW EXECUTE FUNCTION audit.audit_catalogs_products_trigger();


--
-- TOC entry 6266 (class 2620 OID 20960)
-- Name: quantities trg_audit_catalogs_quantities; Type: TRIGGER; Schema: catalogs; Owner: postgres
--

CREATE TRIGGER trg_audit_catalogs_quantities AFTER INSERT OR DELETE OR UPDATE ON catalogs.quantities FOR EACH ROW EXECUTE FUNCTION audit.audit_catalogs_quantities_trigger();


--
-- TOC entry 6256 (class 2620 OID 20992)
-- Name: subcategories trg_audit_catalogs_subcategories; Type: TRIGGER; Schema: catalogs; Owner: postgres
--

CREATE TRIGGER trg_audit_catalogs_subcategories AFTER INSERT OR DELETE OR UPDATE ON catalogs.subcategories FOR EACH ROW EXECUTE FUNCTION audit.audit_catalogs_subcategories_trigger();


--
-- TOC entry 6259 (class 2620 OID 21024)
-- Name: variant_types trg_audit_catalogs_variant_types; Type: TRIGGER; Schema: catalogs; Owner: postgres
--

CREATE TRIGGER trg_audit_catalogs_variant_types AFTER INSERT OR DELETE OR UPDATE ON catalogs.variant_types FOR EACH ROW EXECUTE FUNCTION audit.audit_catalogs_variant_types_trigger();


--
-- TOC entry 6290 (class 2620 OID 21712)
-- Name: quotation_submissions trg_audit_quotation_quotation_submissions; Type: TRIGGER; Schema: quotation; Owner: postgres
--

CREATE TRIGGER trg_audit_quotation_quotation_submissions AFTER INSERT OR DELETE OR UPDATE ON quotation.quotation_submissions FOR EACH ROW EXECUTE FUNCTION audit.audit_quotation_quotation_submissions_trigger();


--
-- TOC entry 6294 (class 2620 OID 21785)
-- Name: quoted_prices trg_audit_quotation_quoted_prices; Type: TRIGGER; Schema: quotation; Owner: postgres
--

CREATE TRIGGER trg_audit_quotation_quoted_prices AFTER INSERT OR DELETE OR UPDATE ON quotation.quoted_prices FOR EACH ROW EXECUTE FUNCTION audit.audit_quotation_quoted_prices_trigger();


--
-- TOC entry 6287 (class 2620 OID 21667)
-- Name: shopping_list_items trg_audit_quotation_shopping_list_items; Type: TRIGGER; Schema: quotation; Owner: postgres
--

CREATE TRIGGER trg_audit_quotation_shopping_list_items AFTER INSERT OR DELETE OR UPDATE ON quotation.shopping_list_items FOR EACH ROW EXECUTE FUNCTION audit.audit_quotation_shopping_list_items_trigger();


--
-- TOC entry 6285 (class 2620 OID 21622)
-- Name: shopping_lists trg_audit_quotation_shopping_lists; Type: TRIGGER; Schema: quotation; Owner: postgres
--

CREATE TRIGGER trg_audit_quotation_shopping_lists AFTER INSERT OR DELETE OR UPDATE ON quotation.shopping_lists FOR EACH ROW EXECUTE FUNCTION audit.audit_quotation_shopping_lists_trigger();


--
-- TOC entry 6281 (class 2620 OID 21558)
-- Name: submission_statuses trg_audit_quotation_submission_statuses; Type: TRIGGER; Schema: quotation; Owner: postgres
--

CREATE TRIGGER trg_audit_quotation_submission_statuses AFTER INSERT OR DELETE OR UPDATE ON quotation.submission_statuses FOR EACH ROW EXECUTE FUNCTION audit.audit_quotation_submission_statuses_trigger();


--
-- TOC entry 6283 (class 2620 OID 21589)
-- Name: supplier_quotation_statuses trg_audit_quotation_supplier_quotation_statuses; Type: TRIGGER; Schema: quotation; Owner: postgres
--

CREATE TRIGGER trg_audit_quotation_supplier_quotation_statuses AFTER INSERT OR DELETE OR UPDATE ON quotation.supplier_quotation_statuses FOR EACH ROW EXECUTE FUNCTION audit.audit_quotation_supplier_quotation_statuses_trigger();


--
-- TOC entry 6292 (class 2620 OID 21749)
-- Name: supplier_quotations trg_audit_quotation_supplier_quotations; Type: TRIGGER; Schema: quotation; Owner: postgres
--

CREATE TRIGGER trg_audit_quotation_supplier_quotations AFTER INSERT OR DELETE OR UPDATE ON quotation.supplier_quotations FOR EACH ROW EXECUTE FUNCTION audit.audit_quotation_supplier_quotations_trigger();


--
-- TOC entry 6288 (class 2620 OID 21542)
-- Name: shopping_list_items trg_calculate_total_items_shopping_list_items; Type: TRIGGER; Schema: quotation; Owner: postgres
--

CREATE TRIGGER trg_calculate_total_items_shopping_list_items AFTER INSERT OR DELETE OR UPDATE ON quotation.shopping_list_items FOR EACH ROW EXECUTE FUNCTION quotation.calculate_total_items();


--
-- TOC entry 6291 (class 2620 OID 21537)
-- Name: quotation_submissions trg_set_updated_at_quotation_submissions; Type: TRIGGER; Schema: quotation; Owner: postgres
--

CREATE TRIGGER trg_set_updated_at_quotation_submissions BEFORE UPDATE ON quotation.quotation_submissions FOR EACH ROW EXECUTE FUNCTION quotation.set_updated_at();


--
-- TOC entry 6295 (class 2620 OID 21541)
-- Name: quoted_prices trg_set_updated_at_quoted_prices; Type: TRIGGER; Schema: quotation; Owner: postgres
--

CREATE TRIGGER trg_set_updated_at_quoted_prices BEFORE UPDATE ON quotation.quoted_prices FOR EACH ROW EXECUTE FUNCTION quotation.set_updated_at();


--
-- TOC entry 6289 (class 2620 OID 21536)
-- Name: shopping_list_items trg_set_updated_at_shopping_list_items; Type: TRIGGER; Schema: quotation; Owner: postgres
--

CREATE TRIGGER trg_set_updated_at_shopping_list_items BEFORE UPDATE ON quotation.shopping_list_items FOR EACH ROW EXECUTE FUNCTION quotation.set_updated_at();


--
-- TOC entry 6286 (class 2620 OID 21535)
-- Name: shopping_lists trg_set_updated_at_shopping_lists; Type: TRIGGER; Schema: quotation; Owner: postgres
--

CREATE TRIGGER trg_set_updated_at_shopping_lists BEFORE UPDATE ON quotation.shopping_lists FOR EACH ROW EXECUTE FUNCTION quotation.set_updated_at();


--
-- TOC entry 6282 (class 2620 OID 21538)
-- Name: submission_statuses trg_set_updated_at_submission_statuses; Type: TRIGGER; Schema: quotation; Owner: postgres
--

CREATE TRIGGER trg_set_updated_at_submission_statuses BEFORE UPDATE ON quotation.submission_statuses FOR EACH ROW EXECUTE FUNCTION quotation.set_updated_at();


--
-- TOC entry 6284 (class 2620 OID 21539)
-- Name: supplier_quotation_statuses trg_set_updated_at_supplier_quotation_statuses; Type: TRIGGER; Schema: quotation; Owner: postgres
--

CREATE TRIGGER trg_set_updated_at_supplier_quotation_statuses BEFORE UPDATE ON quotation.supplier_quotation_statuses FOR EACH ROW EXECUTE FUNCTION quotation.set_updated_at();


--
-- TOC entry 6293 (class 2620 OID 21540)
-- Name: supplier_quotations trg_set_updated_at_supplier_quotations; Type: TRIGGER; Schema: quotation; Owner: postgres
--

CREATE TRIGGER trg_set_updated_at_supplier_quotations BEFORE UPDATE ON quotation.supplier_quotations FOR EACH ROW EXECUTE FUNCTION quotation.set_updated_at();


--
-- TOC entry 6189 (class 2606 OID 17706)
-- Name: api_keys api_keys_employee_id_fkey; Type: FK CONSTRAINT; Schema: accounts; Owner: postgres
--

ALTER TABLE ONLY accounts.api_keys
    ADD CONSTRAINT api_keys_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES accounts.employees(employee_id);


--
-- TOC entry 6190 (class 2606 OID 17718)
-- Name: api_scopes api_scopes_api_key_id_fkey; Type: FK CONSTRAINT; Schema: accounts; Owner: postgres
--

ALTER TABLE ONLY accounts.api_scopes
    ADD CONSTRAINT api_scopes_api_key_id_fkey FOREIGN KEY (api_key_id) REFERENCES accounts.api_keys(api_key_id) ON DELETE CASCADE;


--
-- TOC entry 6191 (class 2606 OID 17723)
-- Name: api_scopes api_scopes_feature_id_fkey; Type: FK CONSTRAINT; Schema: accounts; Owner: postgres
--

ALTER TABLE ONLY accounts.api_scopes
    ADD CONSTRAINT api_scopes_feature_id_fkey FOREIGN KEY (feature_id) REFERENCES accounts.features(feature_id) ON DELETE CASCADE;


--
-- TOC entry 6188 (class 2606 OID 17733)
-- Name: apis apis_module_id_fkey; Type: FK CONSTRAINT; Schema: accounts; Owner: postgres
--

ALTER TABLE ONLY accounts.apis
    ADD CONSTRAINT apis_module_id_fkey FOREIGN KEY (module_id) REFERENCES accounts.modules(module_id);


--
-- TOC entry 6209 (class 2606 OID 21224)
-- Name: employee_addresses employee_addresses_employee_id_fkey; Type: FK CONSTRAINT; Schema: accounts; Owner: postgres
--

ALTER TABLE ONLY accounts.employee_addresses
    ADD CONSTRAINT employee_addresses_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES accounts.employees(employee_id) ON DELETE CASCADE;


--
-- TOC entry 6208 (class 2606 OID 21199)
-- Name: employee_personal_data employee_personal_data_employee_id_fkey; Type: FK CONSTRAINT; Schema: accounts; Owner: postgres
--

ALTER TABLE ONLY accounts.employee_personal_data
    ADD CONSTRAINT employee_personal_data_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES accounts.employees(employee_id) ON DELETE CASCADE;


--
-- TOC entry 6186 (class 2606 OID 17405)
-- Name: employee_roles employee_roles_employee_id_fkey; Type: FK CONSTRAINT; Schema: accounts; Owner: postgres
--

ALTER TABLE ONLY accounts.employee_roles
    ADD CONSTRAINT employee_roles_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES accounts.employees(employee_id);


--
-- TOC entry 6187 (class 2606 OID 17410)
-- Name: employee_roles employee_roles_role_id_fkey; Type: FK CONSTRAINT; Schema: accounts; Owner: postgres
--

ALTER TABLE ONLY accounts.employee_roles
    ADD CONSTRAINT employee_roles_role_id_fkey FOREIGN KEY (role_id) REFERENCES accounts.roles(role_id);


--
-- TOC entry 6179 (class 2606 OID 17292)
-- Name: employees employees_establishment_id_fkey; Type: FK CONSTRAINT; Schema: accounts; Owner: postgres
--

ALTER TABLE ONLY accounts.employees
    ADD CONSTRAINT employees_establishment_id_fkey FOREIGN KEY (establishment_id) REFERENCES accounts.establishments(establishment_id);


--
-- TOC entry 6180 (class 2606 OID 17287)
-- Name: employees employees_supplier_id_fkey; Type: FK CONSTRAINT; Schema: accounts; Owner: postgres
--

ALTER TABLE ONLY accounts.employees
    ADD CONSTRAINT employees_supplier_id_fkey FOREIGN KEY (supplier_id) REFERENCES accounts.suppliers(supplier_id);


--
-- TOC entry 6181 (class 2606 OID 17282)
-- Name: employees employees_user_id_fkey; Type: FK CONSTRAINT; Schema: accounts; Owner: postgres
--

ALTER TABLE ONLY accounts.employees
    ADD CONSTRAINT employees_user_id_fkey FOREIGN KEY (user_id) REFERENCES accounts.users(user_id);


--
-- TOC entry 6207 (class 2606 OID 18347)
-- Name: establishment_addresses establishment_addresses_establishment_id_fkey; Type: FK CONSTRAINT; Schema: accounts; Owner: postgres
--

ALTER TABLE ONLY accounts.establishment_addresses
    ADD CONSTRAINT establishment_addresses_establishment_id_fkey FOREIGN KEY (establishment_id) REFERENCES accounts.establishments(establishment_id) ON DELETE CASCADE;


--
-- TOC entry 6206 (class 2606 OID 18330)
-- Name: establishment_business_data establishment_business_data_establishment_id_fkey; Type: FK CONSTRAINT; Schema: accounts; Owner: postgres
--

ALTER TABLE ONLY accounts.establishment_business_data
    ADD CONSTRAINT establishment_business_data_establishment_id_fkey FOREIGN KEY (establishment_id) REFERENCES accounts.establishments(establishment_id) ON DELETE CASCADE;


--
-- TOC entry 6182 (class 2606 OID 17350)
-- Name: features features_module_id_fkey; Type: FK CONSTRAINT; Schema: accounts; Owner: postgres
--

ALTER TABLE ONLY accounts.features
    ADD CONSTRAINT features_module_id_fkey FOREIGN KEY (module_id) REFERENCES accounts.modules(module_id);


--
-- TOC entry 6183 (class 2606 OID 17728)
-- Name: features features_platform_id_fkey; Type: FK CONSTRAINT; Schema: accounts; Owner: postgres
--

ALTER TABLE ONLY accounts.features
    ADD CONSTRAINT features_platform_id_fkey FOREIGN KEY (platform_id) REFERENCES accounts.platforms(platform_id);


--
-- TOC entry 6184 (class 2606 OID 17388)
-- Name: role_features role_features_feature_id_fkey; Type: FK CONSTRAINT; Schema: accounts; Owner: postgres
--

ALTER TABLE ONLY accounts.role_features
    ADD CONSTRAINT role_features_feature_id_fkey FOREIGN KEY (feature_id) REFERENCES accounts.features(feature_id);


--
-- TOC entry 6185 (class 2606 OID 17383)
-- Name: role_features role_features_role_id_fkey; Type: FK CONSTRAINT; Schema: accounts; Owner: postgres
--

ALTER TABLE ONLY accounts.role_features
    ADD CONSTRAINT role_features_role_id_fkey FOREIGN KEY (role_id) REFERENCES accounts.roles(role_id);


--
-- TOC entry 6193 (class 2606 OID 17950)
-- Name: items items_subcategory_id_fkey; Type: FK CONSTRAINT; Schema: catalogs; Owner: postgres
--

ALTER TABLE ONLY catalogs.items
    ADD CONSTRAINT items_subcategory_id_fkey FOREIGN KEY (subcategory_id) REFERENCES catalogs.subcategories(subcategory_id);


--
-- TOC entry 6204 (class 2606 OID 18121)
-- Name: offers offers_product_id_fkey; Type: FK CONSTRAINT; Schema: catalogs; Owner: postgres
--

ALTER TABLE ONLY catalogs.offers
    ADD CONSTRAINT offers_product_id_fkey FOREIGN KEY (product_id) REFERENCES catalogs.products(product_id);


--
-- TOC entry 6205 (class 2606 OID 18126)
-- Name: offers offers_supplier_id_fkey; Type: FK CONSTRAINT; Schema: catalogs; Owner: postgres
--

ALTER TABLE ONLY catalogs.offers
    ADD CONSTRAINT offers_supplier_id_fkey FOREIGN KEY (supplier_id) REFERENCES accounts.suppliers(supplier_id);


--
-- TOC entry 6194 (class 2606 OID 18098)
-- Name: products products_brand_id_fkey; Type: FK CONSTRAINT; Schema: catalogs; Owner: postgres
--

ALTER TABLE ONLY catalogs.products
    ADD CONSTRAINT products_brand_id_fkey FOREIGN KEY (brand_id) REFERENCES catalogs.brands(brand_id);


--
-- TOC entry 6195 (class 2606 OID 18068)
-- Name: products products_composition_id_fkey; Type: FK CONSTRAINT; Schema: catalogs; Owner: postgres
--

ALTER TABLE ONLY catalogs.products
    ADD CONSTRAINT products_composition_id_fkey FOREIGN KEY (composition_id) REFERENCES catalogs.compositions(composition_id);


--
-- TOC entry 6196 (class 2606 OID 18088)
-- Name: products products_filling_id_fkey; Type: FK CONSTRAINT; Schema: catalogs; Owner: postgres
--

ALTER TABLE ONLY catalogs.products
    ADD CONSTRAINT products_filling_id_fkey FOREIGN KEY (filling_id) REFERENCES catalogs.fillings(filling_id);


--
-- TOC entry 6197 (class 2606 OID 18083)
-- Name: products products_flavor_id_fkey; Type: FK CONSTRAINT; Schema: catalogs; Owner: postgres
--

ALTER TABLE ONLY catalogs.products
    ADD CONSTRAINT products_flavor_id_fkey FOREIGN KEY (flavor_id) REFERENCES catalogs.flavors(flavor_id);


--
-- TOC entry 6198 (class 2606 OID 18078)
-- Name: products products_format_id_fkey; Type: FK CONSTRAINT; Schema: catalogs; Owner: postgres
--

ALTER TABLE ONLY catalogs.products
    ADD CONSTRAINT products_format_id_fkey FOREIGN KEY (format_id) REFERENCES catalogs.formats(format_id);


--
-- TOC entry 6199 (class 2606 OID 18063)
-- Name: products products_item_id_fkey; Type: FK CONSTRAINT; Schema: catalogs; Owner: postgres
--

ALTER TABLE ONLY catalogs.products
    ADD CONSTRAINT products_item_id_fkey FOREIGN KEY (item_id) REFERENCES catalogs.items(item_id);


--
-- TOC entry 6200 (class 2606 OID 18093)
-- Name: products products_nutritional_variant_id_fkey; Type: FK CONSTRAINT; Schema: catalogs; Owner: postgres
--

ALTER TABLE ONLY catalogs.products
    ADD CONSTRAINT products_nutritional_variant_id_fkey FOREIGN KEY (nutritional_variant_id) REFERENCES catalogs.nutritional_variants(nutritional_variant_id);


--
-- TOC entry 6201 (class 2606 OID 18103)
-- Name: products products_packaging_id_fkey; Type: FK CONSTRAINT; Schema: catalogs; Owner: postgres
--

ALTER TABLE ONLY catalogs.products
    ADD CONSTRAINT products_packaging_id_fkey FOREIGN KEY (packaging_id) REFERENCES catalogs.packagings(packaging_id);


--
-- TOC entry 6202 (class 2606 OID 18108)
-- Name: products products_quantity_id_fkey; Type: FK CONSTRAINT; Schema: catalogs; Owner: postgres
--

ALTER TABLE ONLY catalogs.products
    ADD CONSTRAINT products_quantity_id_fkey FOREIGN KEY (quantity_id) REFERENCES catalogs.quantities(quantity_id);


--
-- TOC entry 6203 (class 2606 OID 18073)
-- Name: products products_variant_type_id_fkey; Type: FK CONSTRAINT; Schema: catalogs; Owner: postgres
--

ALTER TABLE ONLY catalogs.products
    ADD CONSTRAINT products_variant_type_id_fkey FOREIGN KEY (variant_type_id) REFERENCES catalogs.variant_types(variant_type_id);


--
-- TOC entry 6192 (class 2606 OID 17936)
-- Name: subcategories subcategories_category_id_fkey; Type: FK CONSTRAINT; Schema: catalogs; Owner: postgres
--

ALTER TABLE ONLY catalogs.subcategories
    ADD CONSTRAINT subcategories_category_id_fkey FOREIGN KEY (category_id) REFERENCES catalogs.categories(category_id);


--
-- TOC entry 6224 (class 2606 OID 21481)
-- Name: quotation_submissions fk_quotation_submissions_shopping_list; Type: FK CONSTRAINT; Schema: quotation; Owner: postgres
--

ALTER TABLE ONLY quotation.quotation_submissions
    ADD CONSTRAINT fk_quotation_submissions_shopping_list FOREIGN KEY (shopping_list_id) REFERENCES quotation.shopping_lists(shopping_list_id) ON DELETE CASCADE;


--
-- TOC entry 6225 (class 2606 OID 21486)
-- Name: quotation_submissions fk_quotation_submissions_status; Type: FK CONSTRAINT; Schema: quotation; Owner: postgres
--

ALTER TABLE ONLY quotation.quotation_submissions
    ADD CONSTRAINT fk_quotation_submissions_status FOREIGN KEY (submission_status_id) REFERENCES quotation.submission_statuses(submission_status_id);


--
-- TOC entry 6230 (class 2606 OID 21511)
-- Name: quoted_prices fk_quoted_prices_supplier_quotation; Type: FK CONSTRAINT; Schema: quotation; Owner: postgres
--

ALTER TABLE ONLY quotation.quoted_prices
    ADD CONSTRAINT fk_quoted_prices_supplier_quotation FOREIGN KEY (supplier_quotation_id) REFERENCES quotation.supplier_quotations(supplier_quotation_id) ON DELETE CASCADE;


--
-- TOC entry 6212 (class 2606 OID 21466)
-- Name: shopping_list_items fk_shopping_list_items_brand; Type: FK CONSTRAINT; Schema: quotation; Owner: postgres
--

ALTER TABLE ONLY quotation.shopping_list_items
    ADD CONSTRAINT fk_shopping_list_items_brand FOREIGN KEY (brand_id) REFERENCES catalogs.brands(brand_id);


--
-- TOC entry 6213 (class 2606 OID 21436)
-- Name: shopping_list_items fk_shopping_list_items_composition; Type: FK CONSTRAINT; Schema: quotation; Owner: postgres
--

ALTER TABLE ONLY quotation.shopping_list_items
    ADD CONSTRAINT fk_shopping_list_items_composition FOREIGN KEY (composition_id) REFERENCES catalogs.compositions(composition_id);


--
-- TOC entry 6214 (class 2606 OID 21456)
-- Name: shopping_list_items fk_shopping_list_items_filling; Type: FK CONSTRAINT; Schema: quotation; Owner: postgres
--

ALTER TABLE ONLY quotation.shopping_list_items
    ADD CONSTRAINT fk_shopping_list_items_filling FOREIGN KEY (filling_id) REFERENCES catalogs.fillings(filling_id);


--
-- TOC entry 6215 (class 2606 OID 21451)
-- Name: shopping_list_items fk_shopping_list_items_flavor; Type: FK CONSTRAINT; Schema: quotation; Owner: postgres
--

ALTER TABLE ONLY quotation.shopping_list_items
    ADD CONSTRAINT fk_shopping_list_items_flavor FOREIGN KEY (flavor_id) REFERENCES catalogs.flavors(flavor_id);


--
-- TOC entry 6216 (class 2606 OID 21446)
-- Name: shopping_list_items fk_shopping_list_items_format; Type: FK CONSTRAINT; Schema: quotation; Owner: postgres
--

ALTER TABLE ONLY quotation.shopping_list_items
    ADD CONSTRAINT fk_shopping_list_items_format FOREIGN KEY (format_id) REFERENCES catalogs.formats(format_id);


--
-- TOC entry 6217 (class 2606 OID 21426)
-- Name: shopping_list_items fk_shopping_list_items_item; Type: FK CONSTRAINT; Schema: quotation; Owner: postgres
--

ALTER TABLE ONLY quotation.shopping_list_items
    ADD CONSTRAINT fk_shopping_list_items_item FOREIGN KEY (item_id) REFERENCES catalogs.items(item_id);


--
-- TOC entry 6218 (class 2606 OID 21461)
-- Name: shopping_list_items fk_shopping_list_items_nutritional_variant; Type: FK CONSTRAINT; Schema: quotation; Owner: postgres
--

ALTER TABLE ONLY quotation.shopping_list_items
    ADD CONSTRAINT fk_shopping_list_items_nutritional_variant FOREIGN KEY (nutritional_variant_id) REFERENCES catalogs.nutritional_variants(nutritional_variant_id);


--
-- TOC entry 6219 (class 2606 OID 21471)
-- Name: shopping_list_items fk_shopping_list_items_packaging; Type: FK CONSTRAINT; Schema: quotation; Owner: postgres
--

ALTER TABLE ONLY quotation.shopping_list_items
    ADD CONSTRAINT fk_shopping_list_items_packaging FOREIGN KEY (packaging_id) REFERENCES catalogs.packagings(packaging_id);


--
-- TOC entry 6220 (class 2606 OID 21431)
-- Name: shopping_list_items fk_shopping_list_items_product; Type: FK CONSTRAINT; Schema: quotation; Owner: postgres
--

ALTER TABLE ONLY quotation.shopping_list_items
    ADD CONSTRAINT fk_shopping_list_items_product FOREIGN KEY (product_id) REFERENCES catalogs.products(product_id);


--
-- TOC entry 6221 (class 2606 OID 21476)
-- Name: shopping_list_items fk_shopping_list_items_quantity; Type: FK CONSTRAINT; Schema: quotation; Owner: postgres
--

ALTER TABLE ONLY quotation.shopping_list_items
    ADD CONSTRAINT fk_shopping_list_items_quantity FOREIGN KEY (quantity_id) REFERENCES catalogs.quantities(quantity_id);


--
-- TOC entry 6222 (class 2606 OID 21421)
-- Name: shopping_list_items fk_shopping_list_items_shopping_list; Type: FK CONSTRAINT; Schema: quotation; Owner: postgres
--

ALTER TABLE ONLY quotation.shopping_list_items
    ADD CONSTRAINT fk_shopping_list_items_shopping_list FOREIGN KEY (shopping_list_id) REFERENCES quotation.shopping_lists(shopping_list_id) ON DELETE CASCADE;


--
-- TOC entry 6223 (class 2606 OID 21441)
-- Name: shopping_list_items fk_shopping_list_items_variant_type; Type: FK CONSTRAINT; Schema: quotation; Owner: postgres
--

ALTER TABLE ONLY quotation.shopping_list_items
    ADD CONSTRAINT fk_shopping_list_items_variant_type FOREIGN KEY (variant_type_id) REFERENCES catalogs.variant_types(variant_type_id);


--
-- TOC entry 6210 (class 2606 OID 21416)
-- Name: shopping_lists fk_shopping_lists_employee; Type: FK CONSTRAINT; Schema: quotation; Owner: postgres
--

ALTER TABLE ONLY quotation.shopping_lists
    ADD CONSTRAINT fk_shopping_lists_employee FOREIGN KEY (employee_id) REFERENCES accounts.employees(employee_id);


--
-- TOC entry 6211 (class 2606 OID 21411)
-- Name: shopping_lists fk_shopping_lists_establishment; Type: FK CONSTRAINT; Schema: quotation; Owner: postgres
--

ALTER TABLE ONLY quotation.shopping_lists
    ADD CONSTRAINT fk_shopping_lists_establishment FOREIGN KEY (establishment_id) REFERENCES accounts.establishments(establishment_id);


--
-- TOC entry 6226 (class 2606 OID 21496)
-- Name: supplier_quotations fk_supplier_quotations_shopping_list_item; Type: FK CONSTRAINT; Schema: quotation; Owner: postgres
--

ALTER TABLE ONLY quotation.supplier_quotations
    ADD CONSTRAINT fk_supplier_quotations_shopping_list_item FOREIGN KEY (shopping_list_item_id) REFERENCES quotation.shopping_list_items(shopping_list_item_id) ON DELETE CASCADE;


--
-- TOC entry 6227 (class 2606 OID 21506)
-- Name: supplier_quotations fk_supplier_quotations_status; Type: FK CONSTRAINT; Schema: quotation; Owner: postgres
--

ALTER TABLE ONLY quotation.supplier_quotations
    ADD CONSTRAINT fk_supplier_quotations_status FOREIGN KEY (quotation_status_id) REFERENCES quotation.supplier_quotation_statuses(quotation_status_id);


--
-- TOC entry 6228 (class 2606 OID 21491)
-- Name: supplier_quotations fk_supplier_quotations_submission; Type: FK CONSTRAINT; Schema: quotation; Owner: postgres
--

ALTER TABLE ONLY quotation.supplier_quotations
    ADD CONSTRAINT fk_supplier_quotations_submission FOREIGN KEY (quotation_submission_id) REFERENCES quotation.quotation_submissions(quotation_submission_id) ON DELETE CASCADE;


--
-- TOC entry 6229 (class 2606 OID 21501)
-- Name: supplier_quotations fk_supplier_quotations_supplier; Type: FK CONSTRAINT; Schema: quotation; Owner: postgres
--

ALTER TABLE ONLY quotation.supplier_quotations
    ADD CONSTRAINT fk_supplier_quotations_supplier FOREIGN KEY (supplier_id) REFERENCES accounts.suppliers(supplier_id);


-- Completed on 2025-08-15 00:30:47 -03

--
-- PostgreSQL database dump complete
--

