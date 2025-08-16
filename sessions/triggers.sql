-- Triggers do schema sessions
-- Schema: sessions
-- Arquivo: triggers.sql

-- Este arquivo contém todos os triggers do schema sessions
-- Os triggers são criados automaticamente pelos scripts de extensão
-- Este arquivo serve como documentação e referência

-- =====================================================
-- TRIGGERS DE TIMESTAMP
-- =====================================================

/*
-- Trigger para atualizar automaticamente o campo updated_at
CREATE OR REPLACE FUNCTION sessions.set_updated_at()
RETURNS trigger AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar trigger em todas as tabelas com campo updated_at
CREATE TRIGGER trigger_user_sessions_updated_at
    BEFORE UPDATE ON sessions.user_sessions
    FOR EACH ROW EXECUTE FUNCTION sessions.set_updated_at();
*/

-- Funcionalidade: Atualiza automaticamente o campo updated_at
-- Uso: Manter timestamps de modificação sempre atualizados
-- Aplicação: Todas as tabelas com campo updated_at

-- =====================================================
-- TRIGGERS DE VALIDAÇÃO
-- =====================================================

/*
-- Trigger para validar data de expiração antes de inserir/atualizar
CREATE OR REPLACE FUNCTION sessions.validate_expiration_date()
RETURNS trigger AS $$
BEGIN
    -- Verificar se a data de expiração é futura
    IF NEW.session_expires_at <= now() THEN
        RAISE EXCEPTION 'Data de expiração deve ser futura';
    END IF;
    
    -- Verificar se a data de expiração não é muito distante (opcional)
    IF NEW.session_expires_at > now() + interval '1 year' THEN
        RAISE NOTICE 'Data de expiração muito distante: %', NEW.session_expires_at;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar trigger de validação de data de expiração
CREATE TRIGGER trigger_user_sessions_validate_expiration
    BEFORE INSERT OR UPDATE ON sessions.user_sessions
    FOR EACH ROW EXECUTE FUNCTION sessions.validate_expiration_date();
*/

-- Funcionalidade: Valida data de expiração de sessões
-- Uso: Garantir que sessões não sejam criadas com data de expiração passada
-- Validações: Data de expiração deve ser futura

/*
-- Trigger para validar funcionário antes de inserir/atualizar
CREATE OR REPLACE FUNCTION sessions.validate_employee()
RETURNS trigger AS $$
BEGIN
    -- Verificar se o funcionário existe
    IF NOT EXISTS (
        SELECT 1 FROM accounts.employees 
        WHERE employee_id = NEW.employee_id
    ) THEN
        RAISE EXCEPTION 'Funcionário não encontrado';
    END IF;
    
    -- Verificar se o funcionário está ativo
    IF NOT EXISTS (
        SELECT 1 FROM accounts.employees 
        WHERE employee_id = NEW.employee_id AND is_active = true
    ) THEN
        RAISE EXCEPTION 'Funcionário não está ativo';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar trigger de validação de funcionário
CREATE TRIGGER trigger_user_sessions_validate_employee
    BEFORE INSERT OR UPDATE ON sessions.user_sessions
    FOR EACH ROW EXECUTE FUNCTION sessions.validate_employee();
*/

-- Funcionalidade: Valida funcionário vinculado à sessão
-- Uso: Garantir que funcionários existam e estejam ativos
-- Validações: Funcionário existe e está ativo

/*
-- Trigger para validar tokens antes de inserir/atualizar
CREATE OR REPLACE FUNCTION sessions.validate_tokens()
RETURNS trigger AS $$
BEGIN
    -- Verificar se pelo menos um token foi fornecido
    IF NEW.refresh_token_hash IS NULL AND NEW.access_token_hash IS NULL THEN
        RAISE EXCEPTION 'Pelo menos um token deve ser fornecido (refresh ou access)';
    END IF;
    
    -- Verificar se os tokens não estão vazios
    IF NEW.refresh_token_hash IS NOT NULL AND LENGTH(TRIM(NEW.refresh_token_hash)) = 0 THEN
        RAISE EXCEPTION 'Refresh token não pode estar vazio';
    END IF;
    
    IF NEW.access_token_hash IS NOT NULL AND LENGTH(TRIM(NEW.access_token_hash)) = 0 THEN
        RAISE EXCEPTION 'Access token não pode estar vazio';
    END IF;
    
    -- Verificar se os tokens têm tamanho mínimo (hash típico)
    IF NEW.refresh_token_hash IS NOT NULL AND LENGTH(NEW.refresh_token_hash) < 32 THEN
        RAISE NOTICE 'Refresh token muito curto, pode não ser um hash válido';
    END IF;
    
    IF NEW.access_token_hash IS NOT NULL AND LENGTH(NEW.access_token_hash) < 32 THEN
        RAISE NOTICE 'Access token muito curto, pode não ser um hash válido';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar trigger de validação de tokens
CREATE TRIGGER trigger_user_sessions_validate_tokens
    BEFORE INSERT OR UPDATE ON sessions.user_sessions
    FOR EACH ROW EXECUTE FUNCTION sessions.validate_tokens();
*/

-- Funcionalidade: Valida tokens de autenticação
-- Uso: Garantir que tokens sejam válidos e não vazios
-- Validações: Pelo menos um token, não vazios, tamanho mínimo

-- =====================================================
-- TRIGGERS DE INTEGRIDADE HIERÁRQUICA
-- =====================================================

/*
-- Trigger para validar hierarquia de sessões
CREATE OR REPLACE FUNCTION sessions.validate_session_hierarchy()
RETURNS trigger AS $$
BEGIN
    -- Verificar se o funcionário pertence a um estabelecimento ativo
    IF NOT EXISTS (
        SELECT 1 FROM accounts.employees e
        JOIN accounts.establishments est ON e.establishment_id = est.establishment_id
        WHERE e.employee_id = NEW.employee_id 
          AND e.is_active = true 
          AND est.is_active = true
    ) THEN
        RAISE EXCEPTION 'Funcionário deve pertencer a um estabelecimento ativo';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar trigger de validação hierárquica
CREATE TRIGGER trigger_user_sessions_validate_hierarchy
    BEFORE INSERT OR UPDATE ON sessions.user_sessions
    FOR EACH ROW EXECUTE FUNCTION sessions.validate_session_hierarchy();
*/

-- Funcionalidade: Valida hierarquia de sessões
-- Uso: Garantir que funcionários pertençam a estabelecimentos ativos
-- Validações: Estabelecimento ativo, funcionário ativo

-- =====================================================
-- TRIGGERS DE AUDITORIA
-- =====================================================

/*
-- Trigger para auditar mudanças de sessões
CREATE OR REPLACE FUNCTION sessions.audit_session_changes()
RETURNS trigger AS $$
BEGIN
    -- Registrar mudanças importantes
    IF TG_OP = 'UPDATE' THEN
        -- Mudança de status
        IF OLD.is_active != NEW.is_active THEN
            RAISE NOTICE 'Status da sessão % alterado: % -> %', 
                NEW.session_id, OLD.is_active, NEW.is_active;
        END IF;
        
        -- Mudança de data de expiração
        IF OLD.session_expires_at != NEW.session_expires_at THEN
            RAISE NOTICE 'Data de expiração da sessão % alterada: % -> %', 
                NEW.session_id, OLD.session_expires_at, NEW.session_expires_at;
        END IF;
        
        -- Mudança de IP
        IF OLD.ip_address IS DISTINCT FROM NEW.ip_address THEN
            RAISE NOTICE 'IP da sessão % alterado: % -> %', 
                NEW.session_id, OLD.ip_address, NEW.ip_address;
        END IF;
        
        -- Mudança de user agent
        IF OLD.user_agent IS DISTINCT FROM NEW.user_agent THEN
            RAISE NOTICE 'User Agent da sessão % alterado: % -> %', 
                NEW.session_id, OLD.user_agent, NEW.user_agent;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar trigger de auditoria
CREATE TRIGGER trigger_user_sessions_audit
    AFTER UPDATE ON sessions.user_sessions
    FOR EACH ROW EXECUTE FUNCTION sessions.audit_session_changes();
*/

-- Funcionalidade: Audita mudanças importantes em sessões
-- Uso: Rastrear alterações para análise de segurança
-- Ações: Notifica mudanças de status, expiração, IP e user agent

-- =====================================================
-- TRIGGERS DE LIMPEZA AUTOMÁTICA
-- =====================================================

/*
-- Trigger para limpar sessões expiradas automaticamente
CREATE OR REPLACE FUNCTION sessions.auto_cleanup_expired_sessions()
RETURNS trigger AS $$
BEGIN
    -- Marcar sessões expiradas como inativas
    UPDATE sessions.user_sessions SET
        is_active = false,
        updated_at = now()
    WHERE session_expires_at <= now() 
      AND is_active = true;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar trigger de limpeza automática
CREATE TRIGGER trigger_auto_cleanup_expired_sessions
    AFTER INSERT OR UPDATE ON sessions.user_sessions
    FOR EACH ROW EXECUTE FUNCTION sessions.auto_cleanup_expired_sessions();
*/

-- Funcionalidade: Limpa sessões expiradas automaticamente
-- Uso: Manutenção automática do sistema
-- Ações: Marca sessões expiradas como inativas

-- =====================================================
-- TRIGGERS DE SEGURANÇA
-- =====================================================

/*
-- Trigger para detectar sessões suspeitas
CREATE OR REPLACE FUNCTION sessions.detect_suspicious_sessions()
RETURNS trigger AS $$
BEGIN
    -- Detectar sessões sem IP ou user agent
    IF NEW.ip_address IS NULL OR NEW.user_agent IS NULL THEN
        RAISE WARNING 'Sessão suspeita criada: ID %, Funcionário %, IP: %, User Agent: %', 
            NEW.session_id, NEW.employee_id, NEW.ip_address, NEW.user_agent;
    END IF;
    
    -- Detectar sessões muito longas
    IF NEW.session_expires_at - NEW.created_at > interval '30 days' THEN
        RAISE WARNING 'Sessão muito longa criada: ID %, Duração: % dias', 
            NEW.session_id, EXTRACT(DAY FROM (NEW.session_expires_at - NEW.created_at));
    END IF;
    
    -- Detectar múltiplas sessões do mesmo funcionário em IPs diferentes
    IF EXISTS (
        SELECT 1 FROM sessions.user_sessions 
        WHERE employee_id = NEW.employee_id 
          AND is_active = true 
          AND session_id != NEW.session_id
          AND ip_address IS NOT NULL 
          AND NEW.ip_address IS NOT NULL
          AND ip_address != NEW.ip_address
    ) THEN
        RAISE NOTICE 'Múltiplas sessões ativas para funcionário % em IPs diferentes', NEW.employee_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar trigger de detecção de sessões suspeitas
CREATE TRIGGER trigger_user_sessions_detect_suspicious
    AFTER INSERT ON sessions.user_sessions
    FOR EACH ROW EXECUTE FUNCTION sessions.detect_suspicious_sessions();
*/

-- Funcionalidade: Detecta sessões suspeitas automaticamente
-- Uso: Alertas de segurança em tempo real
-- Detecções: Sessões sem rastreamento, muito longas, múltiplos IPs

-- =====================================================
-- TRIGGERS DE NOTIFICAÇÃO
-- =====================================================

/*
-- Trigger para notificar sobre sessões críticas
CREATE OR REPLACE FUNCTION sessions.notify_critical_sessions()
RETURNS trigger AS $$
BEGIN
    -- Notificar sobre sessões que expiram em menos de 1 hora
    IF NEW.session_expires_at - now() <= interval '1 hour' THEN
        RAISE NOTICE 'SESSÃO CRÍTICA: Sessão % do funcionário % expira em %', 
            NEW.session_id, NEW.employee_id, (NEW.session_expires_at - now());
    END IF;
    
    -- Notificar sobre sessões criadas em horário não comercial (opcional)
    IF EXTRACT(HOUR FROM NEW.created_at) < 6 OR EXTRACT(HOUR FROM NEW.created_at) > 22 THEN
        RAISE NOTICE 'Sessão criada em horário não comercial: ID % às %', 
            NEW.session_id, NEW.created_at;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar trigger de notificação
CREATE TRIGGER trigger_user_sessions_notify_critical
    AFTER INSERT ON sessions.user_sessions
    FOR EACH ROW EXECUTE FUNCTION sessions.notify_critical_sessions();
*/

-- Funcionalidade: Notifica sobre sessões críticas
-- Uso: Alertas em tempo real para administradores
-- Notificações: Sessões expirando, horários não comerciais

-- =====================================================
-- FUNÇÃO PARA CRIAR TODOS OS TRIGGERS
-- =====================================================

/*
-- Função para criar todos os triggers de validação
CREATE OR REPLACE FUNCTION sessions.create_validation_triggers()
RETURNS text AS $$
DECLARE
    v_result text := '';
BEGIN
    -- Criar triggers de updated_at
    EXECUTE 'CREATE TRIGGER IF NOT EXISTS trigger_user_sessions_updated_at
        BEFORE UPDATE ON sessions.user_sessions
        FOR EACH ROW EXECUTE FUNCTION sessions.set_updated_at()';
    v_result := v_result || 'Trigger updated_at para user_sessions criado. ';
    
    -- Criar triggers de validação
    EXECUTE 'CREATE TRIGGER IF NOT EXISTS trigger_user_sessions_validate_expiration
        BEFORE INSERT OR UPDATE ON sessions.user_sessions
        FOR EACH ROW EXECUTE FUNCTION sessions.validate_expiration_date()';
    v_result := v_result || 'Trigger de validação de expiração criado. ';
    
    EXECUTE 'CREATE TRIGGER IF NOT EXISTS trigger_user_sessions_validate_employee
        BEFORE INSERT OR UPDATE ON sessions.user_sessions
        FOR EACH ROW EXECUTE FUNCTION sessions.validate_employee()';
    v_result := v_result || 'Trigger de validação de funcionário criado. ';
    
    EXECUTE 'CREATE TRIGGER IF NOT EXISTS trigger_user_sessions_validate_tokens
        BEFORE INSERT OR UPDATE ON sessions.user_sessions
        FOR EACH ROW EXECUTE FUNCTION sessions.validate_tokens()';
    v_result := v_result || 'Trigger de validação de tokens criado. ';
    
    -- Criar triggers de hierarquia
    EXECUTE 'CREATE TRIGGER IF NOT EXISTS trigger_user_sessions_validate_hierarchy
        BEFORE INSERT OR UPDATE ON sessions.user_sessions
        FOR EACH ROW EXECUTE FUNCTION sessions.validate_session_hierarchy()';
    v_result := v_result || 'Trigger de validação hierárquica criado. ';
    
    -- Criar triggers de auditoria
    EXECUTE 'CREATE TRIGGER IF NOT EXISTS trigger_user_sessions_audit
        AFTER UPDATE ON sessions.user_sessions
        FOR EACH ROW EXECUTE FUNCTION sessions.audit_session_changes()';
    v_result := v_result || 'Trigger de auditoria criado. ';
    
    -- Criar triggers de limpeza
    EXECUTE 'CREATE TRIGGER IF NOT EXISTS trigger_auto_cleanup_expired_sessions
        AFTER INSERT OR UPDATE ON sessions.user_sessions
        FOR EACH ROW EXECUTE FUNCTION sessions.auto_cleanup_expired_sessions()';
    v_result := v_result || 'Trigger de limpeza automática criado. ';
    
    -- Criar triggers de segurança
    EXECUTE 'CREATE TRIGGER IF NOT EXISTS trigger_user_sessions_detect_suspicious
        AFTER INSERT ON sessions.user_sessions
        FOR EACH ROW EXECUTE FUNCTION sessions.detect_suspicious_sessions()';
    v_result := v_result || 'Trigger de detecção de sessões suspeitas criado. ';
    
    -- Criar triggers de notificação
    EXECUTE 'CREATE TRIGGER IF NOT EXISTS trigger_user_sessions_notify_critical
        AFTER INSERT ON sessions.user_sessions
        FOR EACH ROW EXECUTE FUNCTION sessions.notify_critical_sessions()';
    v_result := v_result || 'Trigger de notificação criado. ';
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql;
*/

-- Funcionalidade: Cria todos os triggers de validação
-- Uso: Configuração automática de todos os triggers
-- Retorna: Relatório de triggers criados

-- =====================================================
-- EXEMPLOS DE USO
-- =====================================================

/*
-- Exemplo 1: Criar todos os triggers
SELECT sessions.create_validation_triggers();

-- Exemplo 2: Verificar triggers existentes
SELECT 
    trigger_name,
    event_manipulation,
    event_object_table,
    action_statement
FROM information_schema.triggers
WHERE trigger_schema = 'sessions'
ORDER BY trigger_name;

-- Exemplo 3: Testar validação de data de expiração
INSERT INTO sessions.user_sessions (employee_id, current_session_id, session_expires_at)
VALUES ('uuid-invalido', 'teste', now() - interval '1 hour');

-- Exemplo 4: Testar validação de funcionário
INSERT INTO sessions.user_sessions (employee_id, current_session_id, session_expires_at)
VALUES ('uuid-inexistente', 'teste', now() + interval '1 hour');

-- Exemplo 5: Testar validação de tokens
INSERT INTO sessions.user_sessions (employee_id, current_session_id, session_expires_at, refresh_token_hash, access_token_hash)
VALUES ('uuid-valido', 'teste', now() + interval '1 hour', '', '');
*/

-- =====================================================
-- NOTAS IMPORTANTES
-- =====================================================

-- 1. Todos os triggers são executados em ordem específica
-- 2. Triggers de validação são executados ANTES das operações
-- 3. Triggers de auditoria são executados DEPOIS das operações
-- 4. Triggers de limpeza são executados APÓS mudanças
-- 5. Todos os triggers são auditados automaticamente
-- 6. Triggers de segurança incluem detecção e notificação
-- 7. Função create_validation_triggers() cria todos os triggers necessários
-- 8. Sistema de alertas em tempo real para sessões críticas
-- 9. Limpeza automática de sessões expiradas
-- 10. Validações de segurança para IPs e user agents
