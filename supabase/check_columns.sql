-- Script para verificar si las columnas existen
-- Ejecuta esto en el SQL Editor de Supabase para verificar el estado

-- Verificar columnas en activities
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_name = 'activities'
ORDER BY ordinal_position;

-- Verificar columnas en weekly_goals
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_name = 'weekly_goals'
ORDER BY ordinal_position;

