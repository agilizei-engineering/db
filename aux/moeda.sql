-- Domínio para valores monetários
-- Este arquivo define o domínio aux.moeda

-- O domínio é criado automaticamente pelo aux_schema.sql
-- Este arquivo serve como documentação e referência

/*
CREATE DOMAIN aux.moeda AS text
CHECK (aux.validate_moeda(VALUE));
*/

-- Valores válidos:
-- Aceita formatos brasileiros: 100,50 ou 100.50
-- Suporta valores inteiros: 100
-- Suporta valores decimais: 100,00 ou 100.00
-- Suporta valores com uma casa decimal: 100,5 ou 100.5

-- Exemplos válidos:
-- 100,50
-- 100.50
-- 100
-- 100,00
-- 100.00
-- 100,5
-- 100.5

-- Exemplos inválidos:
-- abc
-- 100,abc
-- 100.abc
