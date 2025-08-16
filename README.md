# 🗄️ Sistema de Banco de Dados PostgreSQL

Este repositório contém scripts SQL para um sistema de banco de dados PostgreSQL robusto e auditável, com schemas para autenticação, catálogo de produtos, cotações e sistema automático de auditoria.

## 📚 **Documentação Completa**

### **📖 Guias Detalhados por Schema**
- **[📚 README_SCHEMAS.md](README_SCHEMAS.md)** - **Documentação completa** de todos os schemas, funções e exemplos de uso
- **[🔐 README_SCHEMA_ACCOUNTS.md](README_SCHEMA_ACCOUNTS.md)** - **Guia completo** do schema accounts (autenticação e autorização)
- **[🛍️ README_SCHEMA_CATALOGS.md](README_SCHEMA_CATALOGS.md)** - **Guia completo** do schema catalogs (catálogo de produtos)
- **[💰 README_SCHEMA_QUOTATION.md](README_SCHEMA_QUOTATION.md)** - **Guia completo** do schema quotation (sistema de cotações)
- **[🔐 README_SCHEMA_SESSIONS.md](README_SCHEMA_SESSIONS.md)** - **Guia completo** do schema sessions (controle de sessões)
- **[🔧 README_SCHEMA_AUX.md](README_SCHEMA_AUX.md)** - **Guia detalhado** do schema aux com todas as funções de validação e exemplos práticos
- **[📊 README_SCHEMA_AUDIT.md](README_SCHEMA_AUDIT.md)** - **Guia completo** do sistema de auditoria com consultas avançadas e monitoramento

### **🔗 Links Rápidos**
- **[📋 Accounts](https://www.figma.com/board/01WWFqQuhgNF0WvlO1WvT7/Agilizei-Fluxo-de-trabalho?node-id=55-4936&t=CE9oFJPFjtpnMZsm-4)** - Protótipos de autenticação
- **[🛍️ Catalogs](https://www.figma.com/board/01WWFqQuhgNF0WvlO1WvT7/Agilizei-Fluxo-de-trabalho?node-id=55-5599&t=CE9oFJPFjtpnMZsm-4)** - Protótipos de produtos
- **[💰 Quotation](https://www.figma.com/board/01WWFqQuhgNF0WvlO1WvT7/Agilizei-Fluxo-de-trabalho?node-id=176-1201&t=CE9oFJPFjtpnMZsm-4)** - Protótipos de cotações

## ⚠️ **Pré-requisitos**

- **PostgreSQL 12 ou superior**
- **Acesso de superusuário** ou permissões para criar schemas e extensões
- **Funcionalidades nativas** do PostgreSQL (sem dependências externas obrigatórias)

## 📁 **Estrutura do Projeto**

### **🗄️ Schemas e Tabelas**

#### **`accounts` - Autenticação e Autorização**
- **[users](accounts/users.sql)** - Usuários autenticáveis do sistema
- **[employees](accounts/employees.sql)** - Funcionários vinculados a estabelecimentos
- **[roles](accounts/roles.sql)** - Perfis de acesso e permissões
- **[establishments](accounts/establishments.sql)** - Estabelecimentos comerciais
- **[api_keys](accounts/api_keys.sql)** - Chaves de API para autenticação
- **[establishment_business_data](accounts/establishment_business_data.sql)** - Dados empresariais (CNPJ, Razão Social)
- **[establishment_addresses](accounts/establishment_addresses.sql)** - Endereços dos estabelecimentos
- **[employee_personal_data](accounts/employee_personal_data.sql)** - Dados pessoais dos funcionários
- **[employee_addresses](accounts/employee_addresses.sql)** - Endereços dos funcionários
- **[user_google_oauth](accounts/user_google_oauth.sql)** - Dados de autenticação OAuth do Google

#### **`catalogs` - Catálogo de Produtos**
- **[products](catalogs/products.sql)** - Produtos do catálogo
- **[categories](catalogs/categories.sql)** - Categorias de produtos
- **[subcategories](catalogs/subcategories.sql)** - Subcategorias hierárquicas
- **[brands](catalogs/brands.sql)** - Marcas dos produtos
- **[variants](catalogs/variants.sql)** - Variações de produtos
- **[compositions](catalogs/compositions.sql)** - Composições dos produtos
- **[fillings](catalogs/fillings.sql)** - Recheios disponíveis
- **[flavors](catalogs/flavors.sql)** - Sabores disponíveis
- **[formats](catalogs/formats.sql)** - Formatos de produtos
- **[packagings](catalogs/packagings.sql)** - Tipos de embalagem
- **[quantities](catalogs/quantities.sql)** - Quantidades disponíveis
- **[offers](catalogs/offers.sql)** - Ofertas e promoções

#### **`quotation` - Sistema de Cotações**
- **[shopping_lists](quotation/shopping_lists.sql)** - Listas de compras dos estabelecimentos
- **[shopping_list_items](quotation/shopping_list_items.sql)** - Itens das listas com decomposição
- **[quotation_submissions](quotation/quotation_submissions.sql)** - Submissões de cotação
- **[supplier_quotations](quotation/supplier_quotations.sql)** - Cotações dos fornecedores
- **[quoted_prices](quotation/quoted_prices.sql)** - Preços cotados com condições
- **[submission_statuses](quotation/submission_statuses.sql)** - Status das submissões
- **[supplier_quotation_statuses](quotation/supplier_quotation_statuses.sql)** - Status das cotações

#### **`audit` - Sistema Automático de Auditoria**
- **Tabelas automáticas** - Criadas dinamicamente para cada tabela auditada
- **Nomenclatura** - `schema__table` (ex: `audit.accounts__users`)
- **Particionamento** - Automático por data (ano/mês/dia)
- **Captura** - INSERT, UPDATE, DELETE automaticamente
- **Sincronização** - Detecta mudanças estruturais automaticamente

#### **`aux` - Funções Auxiliares e Validações**
- **Validações** - CPF, CNPJ, CEP, Email, URL, Data de Nascimento
- **Formatação** - Padrões brasileiros para documentos
- **Triggers** - Automáticos para validação e updated_at
- **Domínios** - Tipos de dados validados (estado, gênero, moeda)

#### **`sessions` - Controle de Sessões**
- **[user_sessions](sessions/user_sessions.sql)** - Sessões ativas dos usuários
- **Multi-persona** - Um usuário pode ter múltiplas sessões
- **Controle** - Expiração, tokens, IP, user agent
- **Auditoria** - Rastreamento completo integrado

## 📂 **Arquivos do Repositório**

### **Scripts Principais**
- **[aux_schema.sql](aux_schema.sql)** - Schema auxiliar com funções compartilhadas
- **[audit_system.sql](audit_system.sql)** - Sistema completo de auditoria automática
- **[establishments_extension.sql](establishments_extension.sql)** - Extensão para dados empresariais
- **[employees_extension.sql](employees_extension.sql)** - Extensão para dados pessoais
- **[quotation_schema.sql](quotation_schema.sql)** - Schema completo de cotações
- **[enhance_users_security.sql](enhance_users_security.sql)** - Melhorias de segurança e OAuth

### **Scripts de Migração e Limpeza**
- **[migrate_employees_to_aux.sql](migrate_employees_to_aux.sql)** - Migração de employees para schema aux
- **[migrate_establishments_to_aux.sql](migrate_establishments_to_aux.sql)** - Migração de establishments para schema aux
- **[cleanup_duplicated_functions.sql](cleanup_duplicated_functions.sql)** - Limpeza de funções duplicadas
- **[expand_aux_schema.sql](expand_aux_schema.sql)** - Expansão do schema aux

### **Scripts de Teste**
- **[test_aux_schema.sql](test_aux_schema.sql)** - Testes do schema aux
- **[test_employees_extension.sql](test_employees_extension.sql)** - Testes da extensão de funcionários
- **[test_quotation_schema.sql](test_quotation_schema.sql)** - Testes do schema de cotações
- **[test_pg_trgm.sql](test_pg_trgm.sql)** - Testes de compatibilidade RDS

### **Dumps e Documentação**
- **[dump-poc-202508141109.sql](dump-poc-202508141109.sql)** - Dump inicial do banco
- **[dump-poc-202508150029.sql](dump-poc-202508150029.sql)** - Dump atualizado com todas as implementações
- **[README.md](README.md)** - Este arquivo (visão geral)
- **[README_SCHEMAS.md](README_SCHEMAS.md)** - Documentação completa de todos os schemas
- **[README_SCHEMA_ACCOUNTS.md](README_SCHEMA_ACCOUNTS.md)** - Guia do schema accounts
- **[README_SCHEMA_CATALOGS.md](README_SCHEMA_CATALOGS.md)** - Guia do schema catalogs
- **[README_SCHEMA_QUOTATION.md](README_SCHEMA_QUOTATION.md)** - Guia do schema quotation
- **[README_SCHEMA_SESSIONS.md](README_SCHEMA_SESSIONS.md)** - Guia do schema sessions
- **[README_SCHEMA_AUX.md](README_SCHEMA_AUX.md)** - Guia do schema aux
- **[README_SCHEMA_AUDIT.md](README_SCHEMA_AUDIT.md)** - Guia do sistema de auditoria

### **Estrutura de Pastas por Schema**
- **[aux/](aux/)** - Schema auxiliar (domínios e funções)
- **[audit/](audit/)** - Sistema de auditoria
- **[accounts/](accounts/)** - Autenticação e autorização
- **[catalogs/](catalogs/)** - Catálogo de produtos
- **[quotation/](quotation/)** - Sistema de cotações
- **[sessions/](sessions/)** - Controle de sessões

## 🚀 **Como Usar**

### **1. Ordem de Execução**
```bash
# 1. Pré-requisitos
psql -d postgres -f aux_schema.sql

# 2. Sistema de Auditoria
psql -d postgres -f audit_system.sql

# 3. Extensões
psql -d postgres -f establishments_extension.sql
psql -d postgres -f employees_extension.sql
psql -d postgres -f quotation_schema.sql

# 4. Refatoração
psql -d postgres -f migrate_employees_to_aux.sql
psql -d postgres -f migrate_establishments_to_aux.sql
psql -d postgres -f cleanup_duplicated_functions.sql

# 5. Melhorias de Segurança
psql -d postgres -f enhance_users_security.sql
```

### **2. Auditoria Automática**
```sql
-- Auditar schemas inteiros
SELECT audit.audit_schemas(ARRAY['accounts', 'catalogs', 'quotation']);

-- Ou auditar tabelas específicas
SELECT audit.create_audit_table('accounts', 'users');
```

### **3. Validações Automáticas**
```sql
-- Criar triggers de validação
SELECT aux.create_validation_triggers('accounts', 'users', ARRAY['email']);

-- Criar trigger de updated_at
SELECT aux.create_updated_at_trigger('accounts', 'users');
```

## 🔧 **Funcionalidades Principais**

- ✅ **Sistema de Auditoria Automático** - Captura todas as operações INSERT/UPDATE/DELETE
- ✅ **Validações Brasileiras** - CPF, CNPJ, CEP, Email com triggers automáticos
- ✅ **Particionamento Inteligente** - Auditoria organizada por data para performance
- ✅ **Sincronização Automática** - Detecta mudanças estruturais e atualiza auditoria
- ✅ **Compatibilidade RDS** - Funciona sem extensões externas obrigatórias
- ✅ **Multi-persona** - Sistema de sessões para múltiplos papéis por usuário
- ✅ **OAuth Integration** - Suporte para Google OAuth e AWS Cognito

## 🛠️ **Manutenção**

### **Verificar Status**
```sql
-- Tabelas auditadas
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'audit' AND table_name LIKE '%__%';

-- Triggers ativos
SELECT trigger_name FROM information_schema.triggers 
WHERE trigger_name LIKE '%audit%';
```

### **Sincronizar Auditoria**
```sql
-- Após mudanças estruturais
SELECT audit.sync_audit_table('schema', 'tabela');
```

## 📋 **Requisitos**

- **PostgreSQL 12+** - Versão mínima recomendada
- **Permissões** - Superusuário ou permissões para criar schemas
- **Espaço** - Suficiente para tabelas de auditoria particionadas
- **Performance** - Índices automáticos para consultas de auditoria

## 🤝 **Como Contribuir**

1. **Fork** o projeto
2. **Crie uma branch** para sua feature (`git checkout -b feature/NovaFuncionalidade`)
3. **Commit** suas mudanças (`git commit -m 'Adiciona nova funcionalidade'`)
4. **Push** para a branch (`git push origin feature/NovaFuncionalidade`)
5. **Abra um Pull Request**

### **Padrões de Commit**
- `feat:` - Nova funcionalidade
- `fix:` - Correção de bug
- `docs:` - Documentação
- `refactor:` - Refatoração de código
- `test:` - Adição de testes

## 📄 **Licença**

Este projeto está sob a licença **MIT**. Veja o arquivo `LICENSE` para mais detalhes.

---

**Desenvolvido com ❤️ por [Agilizei.app](https://agilizei.app)**

**🎯 Para documentação detalhada, consulte os READMEs específicos de cada schema!**
