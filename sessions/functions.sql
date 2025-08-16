-- Funções do schema sessions
-- Schema: sessions
-- Arquivo: functions.sql

-- Este arquivo contém todas as funções do schema sessions
-- As funções são criadas automaticamente pelos scripts de extensão
-- Este arquivo serve como documentação e referência

-- =====================================================
-- FUNÇÕES DE GESTÃO DE SESSÕES
-- =====================================================

/*
-- Criar nova sessão de usuário
CREATE OR REPLACE FUNCTION sessions.create_user_session(
    p_employee_id uuid,
    p_current_session_id text,
    p_session_expires_at timestamp with time zone,
    p_refresh_token_hash text DEFAULT NULL,
    p_access_token_hash text DEFAULT NULL,
    p_ip_address inet DEFAULT NULL,
    p_user_agent text DEFAULT NULL
) RETURNS uuid AS $$
DECLARE
    v_session_id uuid;
BEGIN
    -- Verificar se o funcionário existe
    IF NOT EXISTS (
        SELECT 1 FROM accounts.employees 
        WHERE employee_id = p_employee_id
    ) THEN
        RAISE EXCEPTION 'Funcionário não encontrado';
    END IF;
    
    -- Verificar se a data de expiração é futura
    IF p_session_expires_at <= now() THEN
        RAISE EXCEPTION 'Data de expiração deve ser futura';
    END IF;
    
    -- Criar nova sessão
    INSERT INTO sessions.user_sessions (
        employee_id,
        current_session_id,
        session_expires_at,
        refresh_token_hash,
        access_token_hash,
        ip_address,
        user_agent
    ) VALUES (
        p_employee_id,
        p_current_session_id,
        p_session_expires_at,
        p_refresh_token_hash,
        p_access_token_hash,
        p_ip_address,
        p_user_agent
    ) RETURNING session_id INTO v_session_id;
    
    RETURN v_session_id;
END;
$$ LANGUAGE plpgsql;
*/

-- Funcionalidade: Cria nova sessão de usuário
-- Parâmetros: employee_id, current_session_id, session_expires_at, tokens, IP, user_agent
-- Retorna: ID da sessão criada
-- Validações: Funcionário existe, data de expiração futura

/*
-- Atualizar sessão existente
CREATE OR REPLACE FUNCTION sessions.update_user_session(
    p_session_id uuid,
    p_current_session_id text DEFAULT NULL,
    p_session_expires_at timestamp with time zone DEFAULT NULL,
    p_refresh_token_hash text DEFAULT NULL,
    p_access_token_hash text DEFAULT NULL,
    p_ip_address inet DEFAULT NULL,
    p_user_agent text DEFAULT NULL
) RETURNS boolean AS $$
DECLARE
    v_updated boolean := false;
BEGIN
    -- Verificar se a sessão existe e está ativa
    IF NOT EXISTS (
        SELECT 1 FROM sessions.user_sessions 
        WHERE session_id = p_session_id AND is_active = true
    ) THEN
        RAISE EXCEPTION 'Sessão não encontrada ou inativa';
    END IF;
    
    -- Atualizar apenas os campos fornecidos
    UPDATE sessions.user_sessions SET
        current_session_id = COALESCE(p_current_session_id, current_session_id),
        session_expires_at = COALESCE(p_session_expires_at, session_expires_at),
        refresh_token_hash = COALESCE(p_refresh_token_hash, refresh_token_hash),
        access_token_hash = COALESCE(p_access_token_hash, access_token_hash),
        ip_address = COALESCE(p_ip_address, ip_address),
        user_agent = COALESCE(p_user_agent, user_agent),
        updated_at = now()
    WHERE session_id = p_session_id;
    
    GET DIAGNOSTICS v_updated = ROW_COUNT;
    RETURN v_updated > 0;
END;
$$ LANGUAGE plpgsql;
*/

-- Funcionalidade: Atualiza sessão existente
-- Parâmetros: session_id e campos opcionais para atualização
-- Retorna: true se atualizado com sucesso
-- Validações: Sessão existe e está ativa

/*
-- Invalidar sessão (logout)
CREATE OR REPLACE FUNCTION sessions.invalidate_session(
    p_session_id uuid
) RETURNS boolean AS $$
DECLARE
    v_updated boolean := false;
BEGIN
    -- Invalidar sessão
    UPDATE sessions.user_sessions SET
        is_active = false,
        updated_at = now()
    WHERE session_id = p_session_id AND is_active = true;
    
    GET DIAGNOSTICS v_updated = ROW_COUNT;
    RETURN v_updated > 0;
END;
$$ LANGUAGE plpgsql;
*/

-- Funcionalidade: Invalida sessão (logout)
-- Parâmetros: session_id
-- Retorna: true se invalidado com sucesso
-- Ações: Define is_active = false

/*
-- Invalidar todas as sessões de um funcionário
CREATE OR REPLACE FUNCTION sessions.invalidate_all_employee_sessions(
    p_employee_id uuid
) RETURNS integer AS $$
DECLARE
    v_updated integer := 0;
BEGIN
    -- Verificar se o funcionário existe
    IF NOT EXISTS (
        SELECT 1 FROM accounts.employees 
        WHERE employee_id = p_employee_id
    ) THEN
        RAISE EXCEPTION 'Funcionário não encontrado';
    END IF;
    
    -- Invalidar todas as sessões ativas
    UPDATE sessions.user_sessions SET
        is_active = false,
        updated_at = now()
    WHERE employee_id = p_employee_id AND is_active = true;
    
    GET DIAGNOSTICS v_updated = ROW_COUNT;
    RETURN v_updated;
END;
$$ LANGUAGE plpgsql;
*/

-- Funcionalidade: Invalida todas as sessões de um funcionário
-- Parâmetros: employee_id
-- Retorna: Número de sessões invalidadas
-- Uso: Logout em todos os dispositivos

-- =====================================================
-- FUNÇÕES DE CONSULTA E VALIDAÇÃO
-- =====================================================

/*
-- Verificar se uma sessão é válida
CREATE OR REPLACE FUNCTION sessions.is_session_valid(
    p_session_id uuid
) RETURNS boolean AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM sessions.user_sessions 
        WHERE session_id = p_session_id 
          AND is_active = true 
          AND session_expires_at > now()
    );
END;
$$ LANGUAGE plpgsql;
*/

-- Funcionalidade: Verifica se uma sessão é válida
-- Parâmetros: session_id
-- Retorna: true se sessão ativa e não expirada
-- Validações: is_active = true e session_expires_at > now()

/*
-- Buscar sessão por ID da sessão atual
CREATE OR REPLACE FUNCTION sessions.find_session_by_current_id(
    p_current_session_id text
) RETURNS TABLE(
    session_id uuid,
    employee_id uuid,
    session_expires_at timestamp with time zone,
    refresh_token_hash text,
    access_token_hash text,
    ip_address inet,
    user_agent text,
    is_active boolean,
    created_at timestamp with time zone
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        us.session_id,
        us.employee_id,
        us.session_expires_at,
        us.refresh_token_hash,
        us.access_token_hash,
        us.ip_address,
        us.user_agent,
        us.is_active,
        us.created_at
    FROM sessions.user_sessions us
    WHERE us.current_session_id = p_current_session_id
      AND us.is_active = true
      AND us.session_expires_at > now();
END;
$$ LANGUAGE plpgsql;
*/

-- Funcionalidade: Busca sessão por ID da sessão atual
-- Parâmetros: current_session_id
-- Retorna: Dados da sessão se válida
-- Filtros: Apenas sessões ativas e não expiradas

/*
-- Buscar sessões ativas de um funcionário
CREATE OR REPLACE FUNCTION sessions.find_active_sessions_by_employee(
    p_employee_id uuid
) RETURNS TABLE(
    session_id uuid,
    current_session_id text,
    session_expires_at timestamp with time zone,
    ip_address inet,
    user_agent text,
    created_at timestamp with time zone,
    time_remaining interval
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        us.session_id,
        us.current_session_id,
        us.session_expires_at,
        us.ip_address,
        us.user_agent,
        us.created_at,
        (us.session_expires_at - now()) as time_remaining
    FROM sessions.user_sessions us
    WHERE us.employee_id = p_employee_id
      AND us.is_active = true
      AND us.session_expires_at > now()
    ORDER BY us.created_at DESC;
END;
$$ LANGUAGE plpgsql;
*/

-- Funcionalidade: Busca sessões ativas de um funcionário
-- Parâmetros: employee_id
-- Retorna: Lista de sessões ativas com tempo restante
-- Ordenação: Por data de criação (mais recente primeiro)

-- =====================================================
-- FUNÇÕES DE LIMPEZA E MANUTENÇÃO
-- =====================================================

/*
-- Limpar sessões expiradas
CREATE OR REPLACE FUNCTION sessions.cleanup_expired_sessions()
RETURNS integer AS $$
DECLARE
    v_cleaned integer := 0;
BEGIN
    -- Marcar sessões expiradas como inativas
    UPDATE sessions.user_sessions SET
        is_active = false,
        updated_at = now()
    WHERE session_expires_at <= now() AND is_active = true;
    
    GET DIAGNOSTICS v_cleaned = ROW_COUNT;
    RETURN v_cleaned;
END;
$$ LANGUAGE plpgsql;
*/

-- Funcionalidade: Limpa sessões expiradas
-- Parâmetros: Nenhum
-- Retorna: Número de sessões limpas
-- Uso: Manutenção automática do sistema

/*
-- Estatísticas de sessões
CREATE OR REPLACE FUNCTION sessions.get_session_statistics()
RETURNS TABLE(
    total_sessions integer,
    active_sessions integer,
    expired_sessions integer,
    total_employees_with_sessions integer,
    avg_sessions_per_employee numeric,
    oldest_session timestamp with time zone,
    newest_session timestamp with time zone
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::integer as total_sessions,
        COUNT(CASE WHEN is_active = true AND session_expires_at > now() THEN 1 END)::integer as active_sessions,
        COUNT(CASE WHEN session_expires_at <= now() THEN 1 END)::integer as expired_sessions,
        COUNT(DISTINCT employee_id)::integer as total_employees_with_sessions,
        ROUND(AVG(sessions_count), 2) as avg_sessions_per_employee,
        MIN(created_at) as oldest_session,
        MAX(created_at) as newest_session
    FROM sessions.user_sessions us
    CROSS JOIN (
        SELECT COUNT(*) as sessions_count
        FROM sessions.user_sessions
        GROUP BY employee_id
    ) sc;
END;
$$ LANGUAGE plpgsql;
*/

-- Funcionalidade: Estatísticas gerais de sessões
-- Parâmetros: Nenhum
-- Retorna: Métricas agregadas de sessões
-- Uso: Relatórios e monitoramento

-- =====================================================
-- FUNÇÕES DE VALIDAÇÃO E LIMPEZA
-- =====================================================

/*
-- Função para atualizar timestamp de updated_at
CREATE OR REPLACE FUNCTION sessions.set_updated_at()
RETURNS trigger AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
*/

-- Funcionalidade: Atualiza automaticamente o campo updated_at
-- Uso: Trigger para manter timestamps atualizados
-- Aplicação: Todas as tabelas com campo updated_at

-- =====================================================
-- EXEMPLOS DE USO
-- =====================================================

/*
-- Exemplo 1: Criar nova sessão
SELECT sessions.create_user_session(
    'uuid-do-funcionario',
    'session-123456',
    now() + interval '24 hours',
    'hash-refresh-token',
    'hash-access-token',
    '192.168.1.100'::inet,
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
);

-- Exemplo 2: Atualizar sessão
SELECT sessions.update_user_session(
    'uuid-da-sessao',
    'session-789012',
    now() + interval '48 hours'
);

-- Exemplo 3: Invalidar sessão
SELECT sessions.invalidate_session('uuid-da-sessao');

-- Exemplo 4: Invalidar todas as sessões de um funcionário
SELECT sessions.invalidate_all_employee_sessions('uuid-do-funcionario');

-- Exemplo 5: Verificar se sessão é válida
SELECT sessions.is_session_valid('uuid-da-sessao');

-- Exemplo 6: Buscar sessão por ID atual
SELECT * FROM sessions.find_session_by_current_id('session-123456');

-- Exemplo 7: Buscar sessões ativas de um funcionário
SELECT * FROM sessions.find_active_sessions_by_employee('uuid-do-funcionario');

-- Exemplo 8: Limpar sessões expiradas
SELECT sessions.cleanup_expired_sessions();

-- Exemplo 9: Estatísticas de sessões
SELECT * FROM sessions.get_session_statistics();
*/

-- =====================================================
-- NOTAS IMPORTANTES
-- =====================================================

-- 1. Todas as funções retornam apenas registros ativos e válidos
-- 2. Validações incluem regras de negócio específicas
-- 3. Funções de criação incluem validações automáticas
-- 4. Estatísticas são calculadas em tempo real
-- 5. Todas as operações são auditadas automaticamente
-- 6. Funções suportam transações para consistência
-- 7. Validações de expiração são aplicadas em todas as consultas
-- 8. Sistema multi-persona permite múltiplas sessões por funcionário
-- 9. Limpeza automática de sessões expiradas
-- 10. Rastreamento completo de IP e user agent
