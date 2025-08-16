-- Views do schema accounts
-- Schema: accounts
-- Arquivo: views.sql

-- Este arquivo contém todas as views do schema accounts
-- As views são criadas automaticamente pelos scripts de extensão
-- Este arquivo serve como documentação e referência

-- =====================================================
-- VIEWS DE FUNCIONÁRIOS COMPLETOS
-- =====================================================

/*
-- View de funcionários com dados completos
CREATE OR REPLACE VIEW accounts.v_employees_complete AS
SELECT 
    e.employee_id,
    e.user_id,
    e.establishment_id,
    e.supplier_id,
    e.is_active,
    e.activated_at,
    e.deactivated_at,
    e.created_at,
    e.updated_at,
    u.email,
    u.full_name as user_full_name,
    u.cognito_sub,
    u.email_verified,
    u.phone_number,
    u.phone_number_verified,
    epd.cpf,
    epd.full_name as employee_full_name,
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
    ea.is_primary as address_is_primary,
    est.name as establishment_name,
    est.description as establishment_description,
    s.name as supplier_name,
    s.description as supplier_description
FROM accounts.employees e
JOIN accounts.users u ON e.user_id = u.user_id
LEFT JOIN accounts.employee_personal_data epd ON e.employee_id = epd.employee_id
LEFT JOIN accounts.employee_addresses ea ON e.employee_id = ea.employee_id AND ea.is_primary = true
LEFT JOIN accounts.establishments est ON e.establishment_id = est.establishment_id
LEFT JOIN accounts.suppliers s ON e.supplier_id = s.supplier_id
WHERE e.is_active = true;
*/

-- Funcionalidade: View completa de funcionários
-- Retorna: Dados combinados de todas as tabelas relacionadas
-- Uso: Ideal para relatórios e dashboards
-- Filtros: Apenas funcionários ativos

/*
-- View de funcionários com acesso a funcionalidades
CREATE OR REPLACE VIEW accounts.v_employee_feature_access AS
SELECT 
    e.employee_id,
    u.email,
    epd.full_name,
    r.name as role_name,
    r.description as role_description,
    f.name as feature_name,
    f.code as feature_code,
    f.description as feature_description,
    m.name as module_name,
    p.name as platform_name
FROM accounts.employees e
JOIN accounts.users u ON e.user_id = u.user_id
JOIN accounts.employee_personal_data epd ON e.employee_id = epd.employee_id
JOIN accounts.employee_roles er ON e.employee_id = er.employee_id
JOIN accounts.roles r ON er.role_id = r.role_id
JOIN accounts.role_features rf ON r.role_id = rf.role_id
JOIN accounts.features f ON rf.feature_id = f.feature_id
JOIN accounts.modules m ON f.module_id = m.module_id
LEFT JOIN accounts.platforms p ON f.platform_id = p.platform_id
WHERE e.is_active = true
  AND r.is_active = true
  AND f.is_active = true;
*/

-- Funcionalidade: View de acesso a funcionalidades por funcionário
-- Retorna: Mapeamento completo de permissões
-- Uso: Controle de acesso e auditoria de permissões
-- Filtros: Apenas registros ativos

-- =====================================================
-- VIEWS DE ESTABELECIMENTOS COMPLETOS
-- =====================================================

/*
-- View de estabelecimentos com dados completos
CREATE OR REPLACE VIEW accounts.v_establishments_complete AS
SELECT 
    est.establishment_id,
    est.name,
    est.description,
    est.is_active,
    est.activated_at,
    est.deactivated_at,
    est.created_at,
    est.updated_at,
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
    ea.state,
    ea.is_primary as address_is_primary,
    COUNT(DISTINCT emp.employee_id) as total_employees,
    COUNT(DISTINCT emp.employee_id) FILTER (WHERE emp.is_active = true) as active_employees
FROM accounts.establishments est
LEFT JOIN accounts.establishment_business_data ebd ON est.establishment_id = ebd.establishment_id
LEFT JOIN accounts.establishment_addresses ea ON est.establishment_id = ea.establishment_id AND ea.is_primary = true
LEFT JOIN accounts.employees emp ON est.establishment_id = emp.establishment_id
GROUP BY 
    est.establishment_id, est.name, est.description, est.is_active, est.activated_at, 
    est.deactivated_at, est.created_at, est.updated_at,
    ebd.cnpj, ebd.trade_name, ebd.corporate_name, ebd.state_registration,
    ea.postal_code, ea.street, ea.number, ea.complement, ea.neighborhood, ea.city, ea.state, ea.is_primary;
*/

-- Funcionalidade: View completa de estabelecimentos
-- Retorna: Dados empresariais, endereços e estatísticas de funcionários
-- Uso: Ideal para relatórios e dashboards
-- Estatísticas: Contagem de funcionários total e ativos

-- =====================================================
-- VIEWS DE CHAVES DE API
-- =====================================================

/*
-- View de chaves de API com escopos
CREATE OR REPLACE VIEW accounts.v_api_key_feature_scope AS
SELECT 
    ak.api_key_id,
    ak.name as api_key_name,
    ak.secret,
    ak.is_active,
    ak.created_at,
    e.employee_id,
    epd.full_name as employee_name,
    est.name as establishment_name,
    s.name as supplier_name,
    f.name as feature_name,
    f.code as feature_code,
    f.description as feature_description,
    m.name as module_name,
    p.name as platform_name
FROM accounts.api_keys ak
JOIN accounts.employees e ON ak.employee_id = e.employee_id
JOIN accounts.employee_personal_data epd ON e.employee_id = epd.employee_id
LEFT JOIN accounts.establishments est ON e.establishment_id = est.establishment_id
LEFT JOIN accounts.suppliers s ON e.supplier_id = s.supplier_id
JOIN accounts.api_scopes aps ON ak.api_key_id = aps.api_key_id
JOIN accounts.features f ON aps.feature_id = f.feature_id
JOIN accounts.modules m ON f.module_id = m.module_id
LEFT JOIN accounts.platforms p ON f.platform_id = p.platform_id
WHERE ak.is_active = true
  AND e.is_active = true;
*/

-- Funcionalidade: View de escopos de chaves de API
-- Retorna: Mapeamento completo de permissões por chave de API
-- Uso: Controle de acesso e auditoria de APIs
-- Filtros: Apenas chaves e funcionários ativos

-- =====================================================
-- VIEWS DE USUÁRIOS COM GOOGLE OAUTH
-- =====================================================

/*
-- View de usuários com dados do Google OAuth
CREATE OR REPLACE VIEW accounts.v_users_with_google AS
SELECT 
    u.user_id,
    u.email,
    u.full_name,
    u.cognito_sub,
    u.is_active,
    u.email_verified,
    u.phone_number,
    u.phone_number_verified,
    u.terms_accepted_at,
    u.privacy_policy_accepted_at,
    u.cookies_accepted_at,
    u.created_at,
    u.updated_at,
    go.google_id,
    go.google_picture_url,
    go.google_locale,
    go.google_given_name,
    go.google_family_name,
    go.google_hd,
    go.google_email,
    go.google_email_verified,
    go.google_profile_data
FROM accounts.users u
LEFT JOIN accounts.user_google_oauth go ON u.user_id = go.user_id
WHERE u.is_active = true;
*/

-- Funcionalidade: View de usuários com integração Google
-- Retorna: Dados combinados de users e user_google_oauth
-- Uso: Autenticação e perfil do usuário
-- Filtros: Apenas usuários ativos

-- =====================================================
-- EXEMPLOS DE USO
-- =====================================================

/*
-- Exemplo 1: Consultar funcionários completos
SELECT * FROM accounts.v_employees_complete;

-- Exemplo 2: Consultar acesso a funcionalidades
SELECT * FROM accounts.v_employee_feature_access;

-- Exemplo 3: Consultar estabelecimentos completos
SELECT * FROM accounts.v_establishments_complete;

-- Exemplo 4: Consultar escopos de API
SELECT * FROM accounts.v_api_key_feature_scope;

-- Exemplo 5: Consultar usuários com Google
SELECT * FROM accounts.v_users_with_google;
*/

-- =====================================================
-- NOTAS IMPORTANTES
-- =====================================================

-- 1. Todas as views retornam apenas registros ativos
-- 2. Views são otimizadas para consultas de relatórios
-- 3. Dados são sempre consistentes entre tabelas relacionadas
-- 4. Views podem ser usadas como base para outras views
-- 5. Todas as operações nas tabelas base são auditadas
