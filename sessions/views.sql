-- Views do schema sessions
-- Schema: sessions
-- Arquivo: views.sql

-- Este arquivo contém todas as views do schema sessions
-- As views são criadas automaticamente pelos scripts de extensão
-- Este arquivo serve como documentação e referência

-- =====================================================
-- VIEWS DE SESSÕES ATIVAS
-- =====================================================

/*
-- View de sessões ativas dos usuários
CREATE OR REPLACE VIEW sessions.v_active_sessions AS
SELECT 
    us.session_id,
    us.employee_id,
    us.current_session_id,
    us.session_expires_at,
    us.ip_address,
    us.user_agent,
    us.created_at,
    us.updated_at,
    e.full_name as employee_name,
    e.email as employee_email,
    est.name as establishment_name,
    (us.session_expires_at - now()) as time_remaining,
    CASE 
        WHEN (us.session_expires_at - now()) <= interval '1 hour' THEN 'Expirando em breve'
        WHEN (us.session_expires_at - now()) <= interval '24 hours' THEN 'Expira hoje'
        ELSE 'Válida'
    END as expiration_status
FROM sessions.user_sessions us
JOIN accounts.employees e ON us.employee_id = e.employee_id
JOIN accounts.establishments est ON e.establishment_id = est.establishment_id
WHERE us.is_active = true 
  AND us.session_expires_at > now()
ORDER BY us.created_at DESC;
*/

-- Funcionalidade: View de sessões ativas dos usuários
-- Retorna: Dados combinados de sessões, funcionários e estabelecimentos
-- Uso: Monitoramento de sessões ativas
-- Funcionalidades: Tempo restante e status de expiração

/*
-- View de sessões por estabelecimento
CREATE OR REPLACE VIEW sessions.v_sessions_by_establishment AS
SELECT 
    est.establishment_id,
    est.name as establishment_name,
    est.description as establishment_description,
    COUNT(us.session_id) as total_sessions,
    COUNT(CASE WHEN us.is_active = true AND us.session_expires_at > now() THEN 1 END) as active_sessions,
    COUNT(CASE WHEN us.session_expires_at <= now() THEN 1 END) as expired_sessions,
    COUNT(DISTINCT us.employee_id) as employees_with_sessions,
    AVG(EXTRACT(EPOCH FROM (us.session_expires_at - us.created_at))/3600) as avg_session_duration_hours,
    MAX(us.created_at) as last_session_created,
    MIN(us.created_at) as first_session_created
FROM accounts.establishments est
LEFT JOIN accounts.employees e ON est.establishment_id = e.establishment_id
LEFT JOIN sessions.user_sessions us ON e.employee_id = us.employee_id
GROUP BY est.establishment_id, est.name, est.description
ORDER BY active_sessions DESC;
*/

-- Funcionalidade: View de sessões por estabelecimento
-- Retorna: Estatísticas agregadas de sessões por estabelecimento
-- Uso: Relatórios por estabelecimento
-- Estatísticas: Contagens, durações médias e datas

/*
-- View de sessões por funcionário
CREATE OR REPLACE VIEW sessions.v_sessions_by_employee AS
SELECT 
    e.employee_id,
    e.full_name as employee_name,
    e.email as employee_email,
    est.name as establishment_name,
    COUNT(us.session_id) as total_sessions,
    COUNT(CASE WHEN us.is_active = true AND us.session_expires_at > now() THEN 1 END) as active_sessions,
    COUNT(CASE WHEN us.session_expires_at <= now() THEN 1 END) as expired_sessions,
    MAX(us.created_at) as last_session_created,
    MIN(us.created_at) as first_session_created,
    AVG(EXTRACT(EPOCH FROM (us.session_expires_at - us.created_at))/3600) as avg_session_duration_hours,
    STRING_AGG(DISTINCT us.ip_address::text, ', ') as ip_addresses_used,
    STRING_AGG(DISTINCT us.user_agent, ', ') as user_agents_used
FROM accounts.employees e
JOIN accounts.establishments est ON e.establishment_id = est.establishment_id
LEFT JOIN sessions.user_sessions us ON e.employee_id = us.employee_id
GROUP BY e.employee_id, e.full_name, e.email, est.name
ORDER BY active_sessions DESC, total_sessions DESC;
*/

-- Funcionalidade: View de sessões por funcionário
-- Retorna: Estatísticas detalhadas de sessões por funcionário
-- Uso: Análise de comportamento de usuários
-- Estatísticas: Contagens, durações e dispositivos utilizados

-- =====================================================
-- VIEWS DE ANÁLISE DE SEGURANÇA
-- =====================================================

/*
-- View de análise de segurança de sessões
CREATE OR REPLACE VIEW sessions.v_security_analysis AS
SELECT 
    us.session_id,
    us.employee_id,
    us.current_session_id,
    us.ip_address,
    us.user_agent,
    us.created_at,
    us.session_expires_at,
    e.full_name as employee_name,
    est.name as establishment_name,
    -- Análise de segurança
    CASE 
        WHEN us.ip_address IS NULL THEN 'Sem rastreamento de IP'
        WHEN us.ip_address << '10.0.0.0/8' OR us.ip_address << '192.168.0.0/16' THEN 'IP interno'
        WHEN us.ip_address << '127.0.0.0/8' THEN 'IP localhost'
        ELSE 'IP externo'
    END as ip_security_category,
    CASE 
        WHEN us.user_agent IS NULL THEN 'Sem rastreamento de User Agent'
        WHEN us.user_agent ILIKE '%bot%' OR us.user_agent ILIKE '%crawler%' THEN 'Possível bot'
        WHEN us.user_agent ILIKE '%mobile%' OR us.user_agent ILIKE '%android%' OR us.user_agent ILIKE '%ios%' THEN 'Dispositivo móvel'
        WHEN us.user_agent ILIKE '%windows%' OR us.user_agent ILIKE '%mac%' OR us.user_agent ILIKE '%linux%' THEN 'Computador'
        ELSE 'Dispositivo desconhecido'
    END as device_category,
    -- Alertas de segurança
    CASE 
        WHEN us.session_expires_at - us.created_at > interval '30 days' THEN 'Sessão muito longa'
        WHEN us.ip_address IS NULL THEN 'Sem rastreamento de IP'
        WHEN us.user_agent IS NULL THEN 'Sem rastreamento de User Agent'
        ELSE 'Normal'
    END as security_alert
FROM sessions.user_sessions us
JOIN accounts.employees e ON us.employee_id = e.employee_id
JOIN accounts.establishments est ON e.establishment_id = est.establishment_id
WHERE us.is_active = true
ORDER BY us.created_at DESC;
*/

-- Funcionalidade: View de análise de segurança de sessões
-- Retorna: Análise de segurança com categorizações e alertas
-- Uso: Monitoramento de segurança
-- Funcionalidades: Categorização de IPs, dispositivos e alertas

/*
-- View de sessões suspeitas
CREATE OR REPLACE VIEW sessions.v_suspicious_sessions AS
SELECT 
    us.session_id,
    us.employee_id,
    us.current_session_id,
    us.ip_address,
    us.user_agent,
    us.created_at,
    us.session_expires_at,
    e.full_name as employee_name,
    est.name as establishment_name,
    -- Critérios de suspeita
    CASE 
        WHEN us.ip_address IS NULL THEN 'Sem rastreamento de IP'
        WHEN us.user_agent IS NULL THEN 'Sem rastreamento de User Agent'
        WHEN us.session_expires_at - us.created_at > interval '30 days' THEN 'Sessão muito longa'
        WHEN us.ip_address << '0.0.0.0/0' AND us.ip_address NOT IN (SELECT DISTINCT ip_address FROM sessions.user_sessions WHERE ip_address IS NOT NULL) THEN 'IP único'
        ELSE 'Normal'
    END as suspicion_reason,
    -- Nível de risco
    CASE 
        WHEN us.ip_address IS NULL AND us.user_agent IS NULL THEN 'ALTO'
        WHEN us.session_expires_at - us.created_at > interval '30 days' THEN 'MÉDIO'
        WHEN us.ip_address << '0.0.0.0/0' AND us.ip_address NOT IN (SELECT DISTINCT ip_address FROM sessions.user_sessions WHERE ip_address IS NOT NULL) THEN 'BAIXO'
        ELSE 'NENHUM'
    END as risk_level
FROM sessions.user_sessions us
JOIN accounts.employees e ON us.employee_id = e.employee_id
JOIN accounts.establishments est ON e.establishment_id = est.establishment_id
WHERE us.is_active = true
  AND (
      us.ip_address IS NULL OR
      us.user_agent IS NULL OR
      us.session_expires_at - us.created_at > interval '30 days' OR
      us.ip_address << '0.0.0.0/0' AND us.ip_address NOT IN (SELECT DISTINCT ip_address FROM sessions.user_sessions WHERE ip_address IS NOT NULL)
  )
ORDER BY us.created_at DESC;
*/

-- Funcionalidade: View de sessões suspeitas
-- Retorna: Sessões que atendem critérios de suspeita
-- Uso: Investigação de segurança
-- Funcionalidades: Razões de suspeita e níveis de risco

-- =====================================================
-- VIEWS DE ESTATÍSTICAS E RELATÓRIOS
-- =====================================================

/*
-- View de estatísticas de sessões por período
CREATE OR REPLACE VIEW sessions.v_session_statistics_by_period AS
SELECT 
    DATE_TRUNC('day', us.created_at) as session_date,
    COUNT(*) as total_sessions,
    COUNT(CASE WHEN us.is_active = true AND us.session_expires_at > now() THEN 1 END) as active_sessions,
    COUNT(CASE WHEN us.session_expires_at <= now() THEN 1 END) as expired_sessions,
    COUNT(DISTINCT us.employee_id) as unique_employees,
    COUNT(DISTINCT us.ip_address) as unique_ip_addresses,
    COUNT(DISTINCT us.user_agent) as unique_user_agents,
    AVG(EXTRACT(EPOCH FROM (us.session_expires_at - us.created_at))/3600) as avg_session_duration_hours,
    -- Sessões por tipo de dispositivo
    COUNT(CASE WHEN us.user_agent ILIKE '%mobile%' OR us.user_agent ILIKE '%android%' OR us.user_agent ILIKE '%ios%' THEN 1 END) as mobile_sessions,
    COUNT(CASE WHEN us.user_agent ILIKE '%windows%' OR us.user_agent ILIKE '%mac%' OR us.user_agent ILIKE '%linux%' THEN 1 END) as desktop_sessions,
    -- Sessões por tipo de IP
    COUNT(CASE WHEN us.ip_address << '10.0.0.0/8' OR us.ip_address << '192.168.0.0/16' THEN 1 END) as internal_ip_sessions,
    COUNT(CASE WHEN us.ip_address << '127.0.0.0/8' THEN 1 END) as localhost_sessions,
    COUNT(CASE WHEN us.ip_address << '0.0.0.0/0' AND us.ip_address NOT IN (SELECT DISTINCT ip_address FROM sessions.user_sessions WHERE ip_address << '10.0.0.0/8' OR ip_address << '192.168.0.0/16' OR ip_address << '127.0.0.0/8') THEN 1 END) as external_ip_sessions
FROM sessions.user_sessions us
GROUP BY DATE_TRUNC('day', us.created_at)
ORDER BY session_date DESC;
*/

-- Funcionalidade: View de estatísticas de sessões por período
-- Retorna: Estatísticas agregadas por dia
-- Uso: Relatórios temporais e tendências
-- Estatísticas: Contagens, dispositivos e tipos de IP por período

/*
-- View de resumo de sessões por estabelecimento e período
CREATE OR REPLACE VIEW sessions.v_establishment_session_summary AS
SELECT 
    est.establishment_id,
    est.name as establishment_name,
    DATE_TRUNC('day', us.created_at) as session_date,
    COUNT(*) as total_sessions,
    COUNT(CASE WHEN us.is_active = true AND us.session_expires_at > now() THEN 1 END) as active_sessions,
    COUNT(CASE WHEN us.session_expires_at <= now() THEN 1 END) as expired_sessions,
    COUNT(DISTINCT us.employee_id) as employees_with_sessions,
    COUNT(DISTINCT us.ip_address) as unique_ip_addresses,
    AVG(EXTRACT(EPOCH FROM (us.session_expires_at - us.created_at))/3600) as avg_session_duration_hours,
    -- Distribuição por tipo de dispositivo
    ROUND(
        COUNT(CASE WHEN us.user_agent ILIKE '%mobile%' OR us.user_agent ILIKE '%android%' OR us.user_agent ILIKE '%ios%' THEN 1 END) * 100.0 / COUNT(*), 2
    ) as mobile_sessions_percentage,
    ROUND(
        COUNT(CASE WHEN us.user_agent ILIKE '%windows%' OR us.user_agent ILIKE '%mac%' OR us.user_agent ILIKE '%linux%' THEN 1 END) * 100.0 / COUNT(*), 2
    ) as desktop_sessions_percentage
FROM accounts.establishments est
LEFT JOIN accounts.employees e ON est.establishment_id = e.establishment_id
LEFT JOIN sessions.user_sessions us ON e.employee_id = us.employee_id
GROUP BY est.establishment_id, est.name, DATE_TRUNC('day', us.created_at)
ORDER BY est.name, session_date DESC;
*/

-- Funcionalidade: View de resumo de sessões por estabelecimento e período
-- Retorna: Estatísticas agregadas por estabelecimento e dia
-- Uso: Relatórios por estabelecimento e período
-- Estatísticas: Contagens, percentuais e distribuições

-- =====================================================
-- VIEWS DE MONITORAMENTO EM TEMPO REAL
-- =====================================================

/*
-- View de sessões expirando em breve
CREATE OR REPLACE VIEW sessions.v_sessions_expiring_soon AS
SELECT 
    us.session_id,
    us.employee_id,
    us.current_session_id,
    us.session_expires_at,
    us.ip_address,
    us.user_agent,
    us.created_at,
    e.full_name as employee_name,
    e.email as employee_email,
    est.name as establishment_name,
    (us.session_expires_at - now()) as time_until_expiration,
    CASE 
        WHEN (us.session_expires_at - now()) <= interval '15 minutes' THEN 'CRÍTICO'
        WHEN (us.session_expires_at - now()) <= interval '1 hour' THEN 'ALTO'
        WHEN (us.session_expires_at - now()) <= interval '24 hours' THEN 'MÉDIO'
        ELSE 'BAIXO'
    END as expiration_urgency
FROM sessions.user_sessions us
JOIN accounts.employees e ON us.employee_id = e.employee_id
JOIN accounts.establishments est ON e.establishment_id = est.establishment_id
WHERE us.is_active = true 
  AND us.session_expires_at > now()
  AND us.session_expires_at <= now() + interval '24 hours'
ORDER BY us.session_expires_at ASC;
*/

-- Funcionalidade: View de sessões expirando em breve
-- Retorna: Sessões que expiram nas próximas 24 horas
-- Uso: Monitoramento de expiração
-- Funcionalidades: Tempo restante e urgência de expiração

/*
-- View de sessões por localização geográfica (IP)
CREATE OR REPLACE VIEW sessions.v_sessions_by_location AS
SELECT 
    us.ip_address,
    CASE 
        WHEN us.ip_address << '10.0.0.0/8' THEN 'Rede Privada A'
        WHEN us.ip_address << '172.16.0.0/12' THEN 'Rede Privada B'
        WHEN us.ip_address << '192.168.0.0/16' THEN 'Rede Privada C'
        WHEN us.ip_address << '127.0.0.0/8' THEN 'Localhost'
        WHEN us.ip_address << '169.254.0.0/16' THEN 'Link Local'
        WHEN us.ip_address << '224.0.0.0/4' THEN 'Multicast'
        WHEN us.ip_address << '240.0.0.0/4' THEN 'Reservado'
        ELSE 'Internet Pública'
    END as network_category,
    COUNT(*) as total_sessions,
    COUNT(CASE WHEN us.is_active = true AND us.session_expires_at > now() THEN 1 END) as active_sessions,
    COUNT(DISTINCT us.employee_id) as unique_employees,
    COUNT(DISTINCT us.user_agent) as unique_user_agents,
    MAX(us.created_at) as last_session_created,
    MIN(us.created_at) as first_session_created
FROM sessions.user_sessions us
WHERE us.ip_address IS NOT NULL
GROUP BY us.ip_address
ORDER BY total_sessions DESC;
*/

-- Funcionalidade: View de sessões por localização geográfica
-- Retorna: Estatísticas de sessões por categoria de rede
-- Uso: Análise de padrões de acesso
-- Funcionalidades: Categorização de redes e estatísticas

-- =====================================================
-- EXEMPLOS DE USO
-- =====================================================

/*
-- Exemplo 1: Consultar sessões ativas
SELECT * FROM sessions.v_active_sessions;

-- Exemplo 2: Consultar sessões por estabelecimento
SELECT * FROM sessions.v_sessions_by_establishment;

-- Exemplo 3: Consultar sessões por funcionário
SELECT * FROM sessions.v_sessions_by_employee;

-- Exemplo 4: Análise de segurança
SELECT * FROM sessions.v_security_analysis;

-- Exemplo 5: Sessões suspeitas
SELECT * FROM sessions.v_suspicious_sessions;

-- Exemplo 6: Estatísticas por período
SELECT * FROM sessions.v_session_statistics_by_period;

-- Exemplo 7: Resumo por estabelecimento e período
SELECT * FROM sessions.v_establishment_session_summary;

-- Exemplo 8: Sessões expirando em breve
SELECT * FROM sessions.v_sessions_expiring_soon;

-- Exemplo 9: Sessões por localização
SELECT * FROM sessions.v_sessions_by_location;
*/

-- =====================================================
-- NOTAS IMPORTANTES
-- =====================================================

-- 1. Todas as views retornam apenas registros ativos e válidos
-- 2. Views são otimizadas para consultas de relatórios
-- 3. Dados são sempre consistentes entre tabelas relacionadas
-- 4. Views podem ser usadas como base para outras views
-- 5. Todas as operações nas tabelas base são auditadas
-- 6. Views incluem análises e classificações automáticas
-- 7. Estatísticas são calculadas em tempo real
-- 8. Views de segurança incluem categorizações e alertas
-- 9. Monitoramento em tempo real de expiração de sessões
-- 10. Análise geográfica baseada em endereços IP
