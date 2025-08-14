# 🗄️ Sistema de Banco de Dados PostgreSQL

Este repositório contém scripts SQL para um sistema de banco de dados PostgreSQL com schemas `accounts` e `catalogs`, incluindo extensões e sistema de auditoria completo.

## 📁 Estrutura do Projeto

### Schemas Principais

#### `accounts` - Autenticação e Autorização
- **users** - Usuários do sistema
- **employees** - Funcionários/Colaboradores
- **roles** - Perfis de acesso
- **establishments** - Estabelecimentos/Empresas
- **api_keys** - Chaves de API para autenticação

#### `catalogs` - Catálogo de Produtos
- **products** - Produtos
- **categories** - Categorias
- **brands** - Marcas
- **variations** - Variações de produtos
- **variant_types** - Tipos de variação

### Extensões

#### `establishments_extension.sql`
Extensão do schema `accounts` para dados empresariais:

- **establishment_business_data** - Dados empresariais (CNPJ, Razão Social, Nome Fantasia)
- **establishment_addresses** - Endereços dos estabelecimentos

**Características:**
- ✅ Limpeza automática de CNPJ e CEP (remove máscaras)
- ✅ Validação completa de CNPJ
- ✅ Soft delete implementado
- ✅ Índices de busca otimizados (GIN + trigram)
- ✅ Constraints de negócio

#### `audit_system.sql`
Sistema completo de auditoria genérico:

- **Schema `audit`** - Tabelas de auditoria
- **Nomenclatura** - `schema__table` (ex: `accounts__users`)
- **Particionamento** - Automático por data (ano/mês/dia)
- **Triggers** - Captura INSERT, UPDATE, DELETE
- **Sincronização** - Detecta mudanças estruturais automaticamente

## 🚀 Como Usar

### 1. Instalação Base
```sql
-- Execute o dump principal
\i dump-poc-202508141109.sql
```

### 2. Extensão de Estabelecimentos
```sql
-- Adicione dados empresariais
\i establishments_extension.sql
```

### 3. Sistema de Auditoria
```sql
-- Instale o sistema de auditoria
\i audit_system.sql

-- Audite schemas específicos
SELECT audit.audit_schemas(ARRAY['accounts', 'catalogs']);

-- Ou audite uma tabela específica
SELECT audit.create_audit_table('accounts', 'users');
```

## 🔧 Funcionalidades Principais

### Limpeza Automática de Dados
```sql
-- CNPJ e CEP são limpos automaticamente
INSERT INTO accounts.establishment_business_data (establishment_id, cnpj, trade_name, corporate_name)
VALUES (gen_random_uuid(), '12.345.678/0001-90', 'Empresa Teste', 'Empresa Teste LTDA');
-- CNPJ será armazenado como: 12345678000190
```

### Sistema de Auditoria
```sql
-- Todas as operações são auditadas automaticamente
INSERT INTO accounts.users (email, full_name, cognito_sub) 
VALUES ('teste@email.com', 'Usuário Teste', 'cognito123');

-- Verificar auditoria
SELECT * FROM audit.accounts__users ORDER BY audit_timestamp DESC;
```

### Busca Otimizada
```sql
-- Busca fuzzy por nome de estabelecimento
SELECT * FROM accounts.search_establishments_by_name('empresa');

-- Busca por CEP
SELECT * FROM accounts.find_establishments_by_postal_code('01234567');
```

## 📊 Estrutura de Auditoria

### Campos de Auditoria
- `audit_id` - ID único da auditoria
- `audit_operation` - Tipo de operação (INSERT/UPDATE/DELETE)
- `audit_timestamp` - Data/hora da operação
- `audit_user` - Usuário que executou
- `audit_session_id` - ID da sessão
- `audit_connection_id` - IP da conexão
- `audit_partition_date` - Data para particionamento

### Particionamento
```sql
-- Tabelas são particionadas automaticamente por data
-- Exemplo: audit.accounts__users_2025_08
```

## 🛠️ Manutenção

### Adicionar Nova Auditoria
```sql
-- Para nova tabela
SELECT audit.create_audit_table('novo_schema', 'nova_tabela');

-- Para novo schema
SELECT audit.audit_schemas(ARRAY['novo_schema']);
```

### Sincronização de Estrutura
O sistema detecta automaticamente:
- ✅ Novas colunas adicionadas
- ✅ Colunas removidas (mantidas como NULL na auditoria)
- ✅ Mudanças de tipo (convertidas para text)

## 📝 Exemplos de Uso

### Criação de Estabelecimento Completo
```sql
-- 1. Criar estabelecimento
INSERT INTO accounts.establishments (name, description) 
VALUES ('Minha Empresa', 'Descrição da empresa')
RETURNING establishment_id;

-- 2. Adicionar dados empresariais
INSERT INTO accounts.establishment_business_data (
    establishment_id, cnpj, trade_name, corporate_name, state_registration
) VALUES (
    'uuid-do-estabelecimento', 
    '12.345.678/0001-90', 
    'Nome Fantasia', 
    'Razão Social LTDA',
    '123456789'
);

-- 3. Adicionar endereço
INSERT INTO accounts.establishment_addresses (
    establishment_id, postal_code, street, number, neighborhood, city, state
) VALUES (
    'uuid-do-estabelecimento',
    '01234-567',
    'Rua das Flores',
    '123',
    'Centro',
    'São Paulo',
    'SP'
);
```

### Consulta de Estabelecimento Completo
```sql
-- View que combina todos os dados
SELECT * FROM accounts.v_establishments_complete 
WHERE establishment_id = 'uuid-do-estabelecimento';
```

## 🔍 Monitoramento

### Relatórios de Auditoria
```sql
-- Relatório básico de auditoria
SELECT audit.generate_audit_report('accounts', 'users', '2025-01-01', '2025-12-31');
```

### Verificação de Integridade
```sql
-- Verificar tabelas auditadas
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'audit' 
ORDER BY table_name;
```

## 📋 Requisitos

- PostgreSQL 12+
- Extensão `pg_trgm` (para busca fuzzy)
- Extensão `uuid-ossp` (para UUIDs)

## 🤝 Contribuição

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo `LICENSE` para mais detalhes.

---

**Desenvolvido com ❤️ para sistemas robustos e auditáveis**
