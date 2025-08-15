# 🗄️ Sistema de Banco de Dados PostgreSQL

Este repositório contém scripts SQL para um sistema de banco de dados PostgreSQL com schemas `accounts` e `catalogs`, incluindo extensões e sistema de auditoria completo.

## 📚 **Documentação Completa**

### **📖 Guias Detalhados por Schema**
- **[📚 README_SCHEMAS.md](README_SCHEMAS.md)** - **Documentação completa** de todos os schemas, funções e exemplos de uso
- **[🔧 README_SCHEMA_AUX.md](README_SCHEMA_AUX.md)** - **Guia detalhado** do schema aux com todas as funções de validação e exemplos práticos
- **[📊 README_SCHEMA_AUDIT.md](README_SCHEMA_AUDIT.md)** - **Guia completo** do sistema de auditoria com consultas avançadas e monitoramento

### **🎯 O que você encontrará nos guias:**
- ✅ **Exemplos práticos** de todas as funções
- ✅ **Consultas SQL** com exemplos reais
- ✅ **Guias de manutenção** e monitoramento
- ✅ **Solução de problemas** comuns
- ✅ **Boas práticas** e padrões recomendados

### **🔗 Links Rápidos**
- **[📋 Accounts](https://www.figma.com/board/01WWFqQuhgNF0WvlO1WvT7/Agilizei-Fluxo-de-trabalho?node-id=55-4936&t=CE9oFJPFjtpnMZsm-4)** - Protótipos de autenticação
- **[🛍️ Catalogs](https://www.figma.com/board/01WWFqQuhgNF0WvlO1WvT7/Agilizei-Fluxo-de-trabalho?node-id=55-5599&t=CE9oFJPFjtpnMZsm-4)** - Protótipos de produtos
- **[💰 Quotation](https://www.figma.com/board/01WWFqQuhgNF0WvlO1WvT7/Agilizei-Fluxo-de-trabalho?node-id=176-1201&t=CE9oFJPFjtpnMZsm-4)** - Protótipos de cotações

## ⚠️ Pré-requisitos

- **PostgreSQL 12 ou superior**
- **Acesso de superusuário** ou permissões para criar schemas e extensões
- **Extensão pg_trgm** (opcional - comum no RDS, mas não obrigatória)
- **Funcionalidades nativas** do PostgreSQL sempre funcionam

## 📁 Estrutura do Projeto

### **🗄️ Schemas Principais**

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
- ✅ Índices de busca otimizados (GIN + trigram se disponível, padrão se não)
- ✅ Constraints de negócio
- ✅ Compatível com RDS PostgreSQL

#### `employees_extension.sql`
Extensão do schema `accounts` para dados pessoais dos funcionários:

- **employee_personal_data** - Dados pessoais (CPF, nome, nascimento, sexo, foto)
- **employee_addresses** - Endereços dos funcionários

**Características:**
- ✅ Validação completa de CPF brasileiro
- ✅ Limpeza automática de CPF e CEP (remove máscaras)
- ✅ Validação de data de nascimento (idade mínima 14 anos)
- ✅ Validação de URL de foto
- ✅ Soft delete implementado
- ✅ Índices de busca otimizados (GIN + trigram se disponível, padrão se não)
- ✅ Constraints de negócio robustas
- ✅ Compatível com RDS PostgreSQL

#### `audit_system.sql`
Sistema completo de auditoria genérico:

- **Schema `audit`** - Tabelas de auditoria
- **Nomenclatura** - `schema__table` (ex: `accounts__users`)
- **Particionamento** - Automático por data (ano/mês/dia)
- **Triggers** - Captura INSERT, UPDATE, DELETE
- **Sincronização** - Detecta mudanças estruturais automaticamente

#### `quotation_schema.sql`
Schema completo para sistema de cotações:

- **`shopping_lists`** - Listas de compras dos estabelecimentos
- **`shopping_list_items`** - Itens com decomposição completa para busca refinada
- **`quotation_submissions`** - Submissões de cotação
- **`supplier_quotations`** - Cotações recebidas dos fornecedores
- **`quoted_prices`** - Preços cotados com condições comerciais
- **Tabelas de domínio** - Status para submissões e cotações
- **Integração completa** - Foreign keys para accounts e catalogs
- **Sistema de auditoria** - Integrado automaticamente

## 🚀 Como Usar

### 1. Instalação Base
```sql
-- Execute o dump principal
\i dump-poc-202508141109.sql
```

### 2. Extensões de Estabelecimentos e Funcionários
```sql
-- Adicione dados empresariais
\i establishments_extension.sql

-- Adicione dados pessoais dos funcionários
\i employees_extension.sql
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

### 4. Schema de Cotações
```sql
-- Instale o schema de cotações
\i quotation_schema.sql

-- Teste o schema
\i test_quotation_schema.sql
```

## 🔧 Funcionalidades Principais

## 🚨 Troubleshooting

### Erro: "operator class 'gin_trgm_ops' does not exist for access method 'gin'"

**Causa:** A extensão `pg_trgm` não está disponível (comum no RDS PostgreSQL).

**Solução:** Os scripts agora são **compatíveis com RDS** e funcionam sem a extensão:
- ✅ **Índices padrão** sempre funcionam
- ✅ **Busca ILIKE** para funcionalidade similar
- ✅ **Índices trigram** criados apenas se disponíveis

**Teste de compatibilidade:**
```sql
\i test_pg_trgm.sql
```

### Erro: "permission denied for extension pg_trgm"

**Causa:** Usuário sem permissões para criar extensões (comum no RDS).

**Solução:** Os scripts não tentam mais criar extensões - funcionam com funcionalidades nativas.

### Limpeza Automática de Dados
```sql
-- CNPJ e CEP são limpos automaticamente
INSERT INTO accounts.establishment_business_data (establishment_id, cnpj, trade_name, corporate_name)
VALUES (gen_random_uuid(), '12.345.678/0001-90', 'Empresa Teste', 'Empresa Teste LTDA');
-- CNPJ será armazenado como: 12345678000190

-- CPF também é limpo automaticamente
INSERT INTO accounts.employee_personal_data (employee_id, cpf, full_name, birth_date, gender)
VALUES (gen_random_uuid(), '123.456.789-01', 'João Silva', '1990-05-15', 'M');
-- CPF será armazenado como: 12345678901
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

-- Busca fuzzy por nome de funcionário
SELECT * FROM accounts.search_employees_by_name('joão');

-- Busca funcionário por CPF
SELECT * FROM accounts.find_employee_by_cpf('123.456.789-01');

-- Busca funcionários por CEP
SELECT * FROM accounts.find_employees_by_postal_code('01234-567');
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

### Criação de Funcionário Completo
```sql
-- 1. Criar usuário primeiro
INSERT INTO accounts.users (email, full_name, cognito_sub, is_active) 
VALUES ('joao@empresa.com', 'João Silva Santos', 'cognito-joao', true)
RETURNING user_id;

-- 2. Criar funcionário vinculado ao usuário
INSERT INTO accounts.employees (user_id, establishment_id, is_active) 
VALUES ('uuid-do-usuario', 'uuid-do-estabelecimento', true)
RETURNING employee_id;

-- 3. Adicionar dados pessoais
INSERT INTO accounts.employee_personal_data (
    employee_id, cpf, full_name, birth_date, gender, photo_url
) VALUES (
    'uuid-do-funcionario',
    '123.456.789-01',
    'João Silva Santos',
    '1990-05-15',
    'M',
    'https://example.com/photos/joao.jpg'
);

-- 4. Adicionar endereço
INSERT INTO accounts.employee_addresses (
    employee_id, postal_code, street, number, neighborhood, city, state
) VALUES (
    'uuid-do-funcionario',
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

### Consulta de Funcionário Completo
```sql
-- View que combina todos os dados
SELECT * FROM accounts.v_employees_complete 
WHERE employee_id = 'uuid-do-funcionario';
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
