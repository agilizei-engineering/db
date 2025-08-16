# 🔧 SCHEMA: `aux` - FUNÇÕES AUXILIARES E VALIDAÇÕES

## 🎯 VISÃO GERAL

O schema `aux` é o coração do sistema, contendo todas as funções compartilhadas, validações e utilitários que são utilizados por todos os outros schemas. Ele centraliza a lógica comum e evita duplicação de código.

---

## 📋 FUNÇÕES DISPONÍVEIS

### **📧 VALIDAÇÃO DE EMAIL**

#### **`aux.validate_email(email text)`**
Valida se o formato do email está correto.

```sql
-- Exemplos de uso
SELECT aux.validate_email('usuario@exemplo.com');     -- true
SELECT aux.validate_email('usuario.exemplo@dominio.com.br'); -- true
SELECT aux.validate_email('email-invalido');         -- false
SELECT aux.validate_email('usuario@');               -- false
SELECT aux.validate_email('@dominio.com');           -- false
SELECT aux.validate_email('');                       -- false
SELECT aux.validate_email(NULL);                     -- false
```

#### **`aux.clean_and_validate_email(email text)`**
Limpa o email (remove espaços, converte para minúsculo) e valida o formato.

```sql
-- Exemplos de uso
SELECT aux.clean_and_validate_email('  USUARIO@EXEMPLO.COM  '); -- 'usuario@exemplo.com'
SELECT aux.clean_and_validate_email('Usuario.Exemplo@Dominio.com'); -- 'usuario.exemplo@dominio.com'
SELECT aux.clean_and_validate_email('  email@teste.com  '); -- 'email@teste.com'
```

---

### **🆔 VALIDAÇÃO DE CPF**

#### **`aux.validate_cpf(cpf text)`**
Valida se o CPF é válido (algoritmo oficial da Receita Federal).

```sql
-- Exemplos de uso
SELECT aux.validate_cpf('123.456.789-09'); -- true
SELECT aux.validate_cpf('12345678909');    -- true
SELECT aux.validate_cpf('111.111.111-11'); -- false (CPF inválido)
SELECT aux.validate_cpf('000.000.000-00'); -- false (CPF inválido)
SELECT aux.validate_cpf('123.456.789-10'); -- false (CPF inválido)
SELECT aux.validate_cpf('123');            -- false (formato inválido)
```

#### **`aux.clean_and_validate_cpf(cpf text)`**
Remove máscaras e caracteres especiais, valida e retorna apenas os números.

```sql
-- Exemplos de uso
SELECT aux.clean_and_validate_cpf('123.456.789-09'); -- '12345678909'
SELECT aux.clean_and_validate_cpf('123.456.789-09'); -- '12345678909'
SELECT aux.clean_and_validate_cpf('12345678909');     -- '12345678909'
SELECT aux.clean_and_validate_cpf('123-456-789-09'); -- '12345678909'
SELECT aux.clean_and_validate_cpf('123 456 789 09'); -- '12345678909'
```

#### **`aux.format_cpf(cpf_numerico text)`**
Formata um CPF numérico com máscara padrão.

```sql
-- Exemplos de uso
SELECT aux.format_cpf('12345678909'); -- '123.456.789-09'
SELECT aux.format_cpf('12345678909'); -- '123.456.789-09'
SELECT aux.format_cpf('12345678909'); -- '123.456.789-09'
```

---

### **🏢 VALIDAÇÃO DE CNPJ**

#### **`aux.validate_cnpj(cnpj text)`**
Valida se o CNPJ é válido (algoritmo oficial da Receita Federal).

```sql
-- Exemplos de uso
SELECT aux.validate_cnpj('11.222.333/0001-81'); -- true
SELECT aux.validate_cnpj('11222333000181');      -- true
SELECT aux.validate_cnpj('11.111.111/1111-11'); -- false (CNPJ inválido)
SELECT aux.validate_cnpj('00.000.000/0000-00'); -- false (CNPJ inválido)
SELECT aux.validate_cnpj('11.222.333/0001-82'); -- false (CNPJ inválido)
```

#### **`aux.clean_and_validate_cnpj(cnpj text)`**
Remove máscaras e caracteres especiais, valida e retorna apenas os números.

```sql
-- Exemplos de uso
SELECT aux.clean_and_validate_cnpj('11.222.333/0001-81'); -- '11222333000181'
SELECT aux.clean_and_validate_cnpj('11.222.333/0001-81'); -- '11222333000181'
SELECT aux.clean_and_validate_cnpj('11222333000181');      -- '11222333000181'
SELECT aux.clean_and_validate_cnpj('11-222-333-0001-81'); -- '11222333000181'
SELECT aux.clean_and_validate_cnpj('11 222 333 0001 81'); -- '11222333000181'
```

#### **`aux.format_cnpj(cnpj_numerico text)`**
Formata um CNPJ numérico com máscara padrão.

```sql
-- Exemplos de uso
SELECT aux.format_cnpj('11222333000181'); -- '11.222.333/0001-81'
SELECT aux.format_cnpj('11222333000181'); -- '11.222.333/0001-81'
```

---

### **📍 VALIDAÇÃO DE CEP**

#### **`aux.validate_postal_code(cep text)`**
Valida se o CEP está no formato correto (8 dígitos).

```sql
-- Exemplos de uso
SELECT aux.validate_postal_code('12345-678'); -- true
SELECT aux.validate_postal_code('12345678');  -- true
SELECT aux.validate_postal_code('12345');     -- false (muito curto)
SELECT aux.validate_postal_code('123456789'); -- false (muito longo)
SELECT aux.validate_postal_code('12345-67');  -- false (formato inválido)
```

#### **`aux.clean_and_validate_postal_code(cep text)`**
Remove máscaras e caracteres especiais, valida e retorna apenas os números.

```sql
-- Exemplos de uso
SELECT aux.clean_and_validate_postal_code('12345-678'); -- '12345678'
SELECT aux.clean_and_validate_postal_code('12345-678'); -- '12345678'
SELECT aux.clean_and_validate_postal_code('12345678');  -- '12345678'
SELECT aux.clean_and_validate_postal_code('12345 678'); -- '12345678'
SELECT aux.clean_and_validate_postal_code('12345.678'); -- '12345678'
```

#### **`aux.format_postal_code(cep_numerico text)`**
Formata um CEP numérico com máscara padrão.

```sql
-- Exemplos de uso
SELECT aux.format_postal_code('12345678'); -- '12345-678'
SELECT aux.format_postal_code('12345678'); -- '12345-678'
```

---

### **🌐 VALIDAÇÃO DE URL**

#### **`aux.validate_url(url text)`**
Valida se a URL está no formato correto.

```sql
-- Exemplos de uso
SELECT aux.validate_url('https://exemplo.com');           -- true
SELECT aux.validate_url('http://exemplo.com.br');        -- true
SELECT aux.validate_url('https://www.exemplo.com/path'); -- true
SELECT aux.validate_url('ftp://exemplo.com');            -- true
SELECT aux.validate_url('url-invalida');                 -- false
SELECT aux.validate_url('exemplo.com');                  -- false
SELECT aux.validate_url('');                             -- false
```

---

### **📅 VALIDAÇÃO DE DATA DE NASCIMENTO**

#### **`aux.validate_birth_date(birth_date date, min_age_years integer DEFAULT 14)`**
Valida se a data de nascimento atende à idade mínima (padrão: 14 anos).

```sql
-- Exemplos de uso (idade mínima padrão: 14 anos)
SELECT aux.validate_birth_date('2000-01-01'); -- true (24 anos)
SELECT aux.validate_birth_date('2010-01-01'); -- true (14 anos)
SELECT aux.validate_birth_date('2015-01-01'); -- false (9 anos)

-- Exemplos com idade mínima personalizada
SELECT aux.validate_birth_date('2005-01-01', 18); -- false (19 anos, mas mínimo é 18)
SELECT aux.validate_birth_date('2000-01-01', 18); -- true (24 anos)
SELECT aux.validate_birth_date('1990-01-01', 21); -- true (33 anos)
```

---

### **🇧🇷 VALIDAÇÃO DE ESTADO BRASILEIRO**

#### **`aux.validate_estado_brasileiro(estado text)`**
Valida se o estado está na lista de estados brasileiros válidos.

```sql
-- Exemplos de uso
SELECT aux.validate_estado_brasileiro('SP'); -- true
SELECT aux.validate_estado_brasileiro('RJ'); -- true
SELECT aux.validate_estado_brasileiro('MG'); -- true
SELECT aux.validate_estado_brasileiro('XX'); -- false
SELECT aux.validate_estado_brasileiro('sp'); -- true (case insensitive)
SELECT aux.validate_estado_brasileiro('');   -- false
```

---

### **💰 VALIDAÇÃO DE MOEDA**

#### **`aux.validate_moeda(valor text)`**
Valida se o valor está no formato de moeda válido.

```sql
-- Exemplos de uso
SELECT aux.validate_moeda('100,50');    -- true
SELECT aux.validate_moeda('100.50');    -- true
SELECT aux.validate_moeda('100');       -- true
SELECT aux.validate_moeda('100,00');    -- true
SELECT aux.validate_moeda('100.00');    -- true
SELECT aux.validate_moeda('100,5');     -- true
SELECT aux.validate_moeda('100.5');     -- true
SELECT aux.validate_moeda('abc');       -- false
SELECT aux.validate_moeda('100,abc');   -- false
```

---

### **📄 VALIDAÇÃO DE JSON**

#### **`aux.validate_json(json_text text)`**
Valida se o texto é um JSON válido.

```sql
-- Exemplos de uso
SELECT aux.validate_json('{"nome": "João", "idade": 30}'); -- true
SELECT aux.validate_json('{"array": [1, 2, 3]}');          -- true
SELECT aux.validate_json('{"nested": {"key": "value"}}');  -- true
SELECT aux.validate_json('{"invalid": json}');             -- false
SELECT aux.validate_json('texto simples');                 -- false
SELECT aux.validate_json('');                              -- false
```

---

## 🔄 FUNÇÕES DE TRIGGER

### **Triggers de Validação**

#### **`aux.create_validation_triggers(schema_name, table_name, columns[])`**
Cria automaticamente todos os triggers de validação para as colunas especificadas.

```sql
-- Exemplo: Criar triggers para validação de CNPJ e CEP
SELECT aux.create_validation_triggers('accounts', 'establishment_business_data', ARRAY['cnpj']);

-- Exemplo: Criar triggers para validação de CPF e email
SELECT aux.create_validation_triggers('accounts', 'employee_personal_data', ARRAY['cpf', 'email']);

-- Exemplo: Criar triggers para validação de CEP
SELECT aux.create_validation_triggers('accounts', 'establishment_addresses', ARRAY['postal_code']);
```

#### **Triggers Específicos**

```sql
-- Trigger para CNPJ
SELECT aux.create_cnpj_trigger('accounts', 'establishment_business_data', 'cnpj');

-- Trigger para CPF
SELECT aux.create_cpf_trigger('accounts', 'employee_personal_data', 'cpf');

-- Trigger para CEP
SELECT aux.create_postal_code_trigger('accounts', 'establishment_addresses', 'postal_code');

-- Trigger para email
SELECT aux.create_email_trigger('accounts', 'users', 'email');

-- Trigger para URL
SELECT aux.create_url_trigger('accounts', 'user_google_oauth', 'google_picture_url');
```

### **Triggers de Updated At**

#### **`aux.create_updated_at_trigger(schema_name, table_name)`**
Cria automaticamente um trigger que atualiza o campo `updated_at` sempre que a tabela for modificada.

```sql
-- Exemplo: Criar trigger para tabela users
SELECT aux.create_updated_at_trigger('accounts', 'users');

-- Exemplo: Criar trigger para múltiplas tabelas
SELECT aux.create_updated_at_trigger('catalogs', 'products');
SELECT aux.create_updated_at_trigger('catalogs', 'categories');
SELECT aux.create_updated_at_trigger('quotation', 'shopping_lists');
```

---

## 🏷️ DOMÍNIOS DE VALIDAÇÃO

### **Tipos de Dados Validados**

#### **Estado Brasileiro**
```sql
-- Criar tabela usando domínio de estado
CREATE TABLE enderecos (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    rua text NOT NULL,
    cidade text NOT NULL,
    estado aux.estado_brasileiro NOT NULL,  -- Apenas estados válidos
    cep text NOT NULL
);

-- Inserir dados válidos
INSERT INTO enderecos (rua, cidade, estado, cep) VALUES 
('Rua das Flores', 'São Paulo', 'SP', '01234-567'),
('Avenida Brasil', 'Rio de Janeiro', 'RJ', '20000-000');

-- Inserir dados inválidos (vai falhar)
INSERT INTO enderecos (rua, cidade, estado, cep) VALUES 
('Rua das Flores', 'São Paulo', 'XX', '01234-567'); -- ERRO: estado inválido
```

#### **Gênero**
```sql
-- Criar tabela usando domínio de gênero
CREATE TABLE pessoas (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    nome text NOT NULL,
    genero aux.genero NOT NULL,  -- Apenas M, F ou O
    data_nascimento date NOT NULL
);

-- Inserir dados válidos
INSERT INTO pessoas (nome, genero, data_nascimento) VALUES 
('João Silva', 'M', '1990-01-01'),
('Maria Santos', 'F', '1985-05-15'),
('Alex Costa', 'O', '1995-12-20');

-- Inserir dados inválidos (vai falhar)
INSERT INTO pessoas (nome, genero, data_nascimento) VALUES 
('João Silva', 'X', '1990-01-01'); -- ERRO: gênero inválido
```

#### **Moeda**
```sql
-- Criar tabela usando domínio de moeda
CREATE TABLE produtos (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    nome text NOT NULL,
    preco aux.moeda NOT NULL  -- Apenas valores monetários válidos
);

-- Inserir dados válidos
INSERT INTO produtos (nome, preco) VALUES 
('Produto A', '100,50'),
('Produto B', '250.00'),
('Produto C', '75,25');

-- Inserir dados inválidos (vai falhar)
INSERT INTO produtos (nome, preco) VALUES 
('Produto D', 'abc'); -- ERRO: valor inválido
```

---

## 🚀 EXEMPLOS PRÁTICOS COMPLETOS

### **Exemplo 1: Criar Tabela com Validações Completas**

```sql
-- 1. Criar tabela
CREATE TABLE clientes (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    nome text NOT NULL,
    email text NOT NULL,
    cpf text NOT NULL,
    telefone text,
    cep text NOT NULL,
    estado aux.estado_brasileiro NOT NULL,
    data_nascimento date NOT NULL,
    foto_url text,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone
);

-- 2. Adicionar constraints de validação
ALTER TABLE clientes 
ADD CONSTRAINT email_valido CHECK (aux.validate_email(email)),
ADD CONSTRAINT cpf_valido CHECK (aux.validate_cpf(cpf)),
ADD CONSTRAINT cep_valido CHECK (aux.validate_postal_code(cep)),
ADD CONSTRAINT data_nascimento_valida CHECK (aux.validate_birth_date(data_nascimento, 18)),
ADD CONSTRAINT foto_url_valida CHECK (aux.validate_url(foto_url));

-- 3. Criar triggers de validação automática
SELECT aux.create_validation_triggers('public', 'clientes', ARRAY['email', 'cpf', 'cep', 'foto_url']);

-- 4. Criar trigger de updated_at
SELECT aux.create_updated_at_trigger('public', 'clientes');

-- 5. Criar auditoria
SELECT audit.create_audit_table('public', 'clientes');
```

### **Exemplo 2: Inserir Dados com Validação**

```sql
-- Inserir cliente válido
INSERT INTO clientes (nome, email, cpf, cep, estado, data_nascimento) VALUES 
('João Silva', 'joao@exemplo.com', '123.456.789-09', '12345-678', 'SP', '1990-01-01');

-- Inserir cliente com foto
INSERT INTO clientes (nome, email, cpf, cep, estado, data_nascimento, foto_url) VALUES 
('Maria Santos', 'maria@exemplo.com', '987.654.321-00', '98765-432', 'RJ', '1985-05-15', 'https://exemplo.com/fotos/maria.jpg');

-- Tentar inserir dados inválidos (vai falhar)
INSERT INTO clientes (nome, email, cpf, cep, estado, data_nascimento) VALUES 
('João Silva', 'email-invalido', '123.456.789-10', '12345', 'XX', '2010-01-01');
-- ERRO: email inválido, CPF inválido, CEP inválido, estado inválido, muito jovem
```

### **Exemplo 3: Busca com Validação**

```sql
-- Buscar clientes por CEP (com validação automática)
SELECT 
    nome,
    email,
    cpf,
    cep,
    estado
FROM clientes 
WHERE aux.clean_and_validate_postal_code('12345-678') = cep;

-- Buscar clientes por CPF (com validação automática)
SELECT 
    nome,
    email,
    cpf,
    cep,
    estado
FROM clientes 
WHERE aux.clean_and_validate_cpf('123.456.789-09') = cpf;

-- Buscar clientes por email (com validação automática)
SELECT 
    nome,
    email,
    cpf,
    cep,
    estado
FROM clientes 
WHERE aux.clean_and_validate_email('  USUARIO@EXEMPLO.COM  ') = email;
```

### **Exemplo 4: Relatórios com Validação**

```sql
-- Relatório de clientes por estado
SELECT 
    estado,
    COUNT(*) as total_clientes,
    COUNT(CASE WHEN aux.validate_email(email) THEN 1 END) as emails_validos,
    COUNT(CASE WHEN aux.validate_cpf(cpf) THEN 1 END) as cpfs_validos,
    COUNT(CASE WHEN aux.validate_postal_code(cep) THEN 1 END) as ceps_validos
FROM clientes 
GROUP BY estado
ORDER BY total_clientes DESC;

-- Relatório de clientes com dados inválidos
SELECT 
    nome,
    email,
    CASE WHEN NOT aux.validate_email(email) THEN 'Email inválido' END as problema_email,
    CASE WHEN NOT aux.validate_cpf(cpf) THEN 'CPF inválido' END as problema_cpf,
    CASE WHEN NOT aux.validate_postal_code(cep) THEN 'CEP inválido' END as problema_cep
FROM clientes 
WHERE NOT aux.validate_email(email) 
   OR NOT aux.validate_cpf(cpf) 
   OR NOT aux.validate_postal_code(cep);
```

---

## 🔧 MANUTENÇÃO E MONITORAMENTO

### **Verificar Funções Disponíveis**

```sql
-- Listar todas as funções do schema aux
SELECT 
    routine_name,
    routine_type,
    data_type,
    routine_definition
FROM information_schema.routines 
WHERE routine_schema = 'aux'
ORDER BY routine_name;
```

### **Verificar Domínios Disponíveis**

```sql
-- Listar todos os domínios do schema aux
SELECT 
    domain_name,
    data_type,
    domain_default,
    check_clause
FROM information_schema.domains 
WHERE domain_schema = 'aux'
ORDER BY domain_name;
```

### **Verificar Triggers Criados**

```sql
-- Listar triggers criados pelo schema aux
SELECT 
    trigger_schema,
    trigger_name,
    event_object_table,
    action_statement
FROM information_schema.triggers 
WHERE trigger_name LIKE '%clean%' 
   OR trigger_name LIKE '%validate%'
   OR trigger_name LIKE '%updated_at%'
ORDER BY trigger_schema, event_object_table;
```

---

### **🔍 VALIDAÇÃO JSONB AUTOMÁTICA**

#### **`aux.validate_json_field(table_name, column_name, json_data)`**
Valida se um campo JSONB contém as chaves corretas baseado nos parâmetros configurados.

```sql
-- Exemplos de uso
SELECT aux.validate_json_field('subscriptions.plans', 'usage_limits', '{"quotations": 100, "suppliers": 10}'); -- true
SELECT aux.validate_json_field('subscriptions.plans', 'usage_limits', '{"quotations": 100}'); -- false (faltando suppliers)
SELECT aux.validate_json_field('subscriptions.plans', 'usage_limits', '{"quotations": 100, "suppliers": 10, "extra": "valor"}'); -- false (chave extra)
```

#### **`aux.create_json_validation_trigger(schema, table, column)`**
Cria trigger de validação JSONB para uma coluna específica.

```sql
-- Exemplos de uso
SELECT aux.create_json_validation_trigger('subscriptions', 'plans', 'usage_limits');
SELECT aux.create_json_validation_trigger('meu_schema', 'minha_tabela', 'campo_jsonb');
```

#### **`aux.setup_json_validation_triggers()`**
Configura automaticamente triggers de validação para todas as colunas JSONB do banco.

```sql
-- Exemplo de uso
SELECT aux.setup_json_validation_triggers();
-- Cria triggers para todas as colunas JSONB automaticamente
```

#### **`aux.add_json_validation_param(table_name, param_value)`**
Adiciona um parâmetro de validação JSONB.

```sql
-- Exemplos de uso
SELECT aux.add_json_validation_param('subscriptions.plans', 'usage_limits.quotations');
SELECT aux.add_json_validation_param('subscriptions.plans', 'usage_limits.suppliers');
SELECT aux.add_json_validation_param('subscriptions.plans', 'usage_limits.items');
```

#### **`aux.list_json_validation_params(table_name)`**
Lista parâmetros de validação JSONB.

```sql
-- Exemplos de uso
SELECT * FROM aux.list_json_validation_params(); -- Todos os parâmetros
SELECT * FROM aux.list_json_validation_params('subscriptions.plans'); -- Filtrado por tabela
```

#### **Tabela `aux.json_validation_params`**
Armazena parâmetros de validação para campos JSONB em todo o sistema.

```sql
-- Estrutura da tabela
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_schema = 'aux' AND table_name = 'json_validation_params';

-- Exemplo de dados
SELECT * FROM aux.json_validation_params WHERE param_name = 'subscriptions.plans';
```

---

## ⚠️ IMPORTANTE: BOAS PRÁTICAS

### **1. Sempre Use as Funções de Validação**
```sql
-- ✅ CORRETO: Usar função de validação
ALTER TABLE minha_tabela 
ADD CONSTRAINT email_valido CHECK (aux.validate_email(email));

-- ❌ INCORRETO: Validação manual
ALTER TABLE minha_tabela 
ADD CONSTRAINT email_valido CHECK (email LIKE '%@%');
```

### **2. Use Triggers Automáticos**
```sql
-- ✅ CORRETO: Criar triggers automaticamente
SELECT aux.create_validation_triggers('meu_schema', 'minha_tabela', ARRAY['email', 'cpf']);

-- ❌ INCORRETO: Criar triggers manualmente
CREATE TRIGGER ... -- Pode causar inconsistências
```

### **3. Sempre Crie Auditoria**
```sql
-- ✅ CORRETO: Criar auditoria para todas as tabelas
SELECT audit.create_audit_table('meu_schema', 'minha_tabela');

-- ❌ INCORRETO: Não criar auditoria
-- Perde histórico de mudanças
```

### **4. Use Domínios para Validação**
```sql
-- ✅ CORRETO: Usar domínios validados
CREATE TABLE exemplo (
    estado aux.estado_brasileiro NOT NULL,
    genero aux.genero NOT NULL
);

-- ❌ INCORRETO: Validação apenas por constraint
CREATE TABLE exemplo (
    estado text NOT NULL CHECK (estado IN ('SP', 'RJ', 'MG'))
);
```

---

## 🆘 SOLUÇÃO DE PROBLEMAS

### **Problema: Função não encontrada**
```sql
-- Verificar se a função existe
SELECT routine_name FROM information_schema.routines 
WHERE routine_schema = 'aux' AND routine_name = 'validate_email';

-- Se não existir, executar aux_schema.sql
\i aux_schema.sql
```

### **Problema: Trigger não funciona**
```sql
-- Verificar se o trigger foi criado
SELECT trigger_name FROM information_schema.triggers 
WHERE event_object_table = 'minha_tabela';

-- Recriar o trigger
SELECT aux.create_validation_triggers('meu_schema', 'minha_tabela', ARRAY['email']);
```

### **Problema: Validação falha**
```sql
-- Testar a função diretamente
SELECT aux.validate_email('teste@exemplo.com');

-- Verificar se a constraint foi criada
SELECT constraint_name, check_clause 
FROM information_schema.check_constraints 
WHERE constraint_schema = 'meu_schema';
```

---

## 📚 RECURSOS ADICIONAIS

- **README_SCHEMAS.md** - Documentação geral de todos os schemas
- **aux_schema.sql** - Script de criação do schema aux
- **test_aux_schema.sql** - Scripts de teste para validação

---

**🎯 Lembre-se: O schema `aux` é a base de todo o sistema. Use sempre suas funções para manter consistência e qualidade dos dados!**
