-- Script de migración para agregar nuevas columnas a las tablas existentes
-- Ejecuta este script en el SQL Editor de Supabase

-- Agregar nuevas columnas a la tabla activities
ALTER TABLE activities 
ADD COLUMN IF NOT EXISTS archived BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS deleted BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Agregar nuevas columnas a la tabla weekly_goals
ALTER TABLE weekly_goals 
ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'active',
ADD COLUMN IF NOT EXISTS elapsed_minutes INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS start_time TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS end_time TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS archived BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS deleted BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Agregar constraint para el campo status en weekly_goals
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'weekly_goals_status_check'
  ) THEN
    ALTER TABLE weekly_goals 
    ADD CONSTRAINT weekly_goals_status_check 
    CHECK (status IN ('active', 'paused', 'completed'));
  END IF;
END $$;

-- Eliminar la restricción UNIQUE de (user_id, week_start) si existe
-- Esto permite crear múltiples metas
DO $$ 
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'weekly_goals_user_id_week_start_key'
  ) THEN
    ALTER TABLE weekly_goals 
    DROP CONSTRAINT weekly_goals_user_id_week_start_key;
  END IF;
END $$;

-- Actualizar valores existentes para que tengan los valores por defecto correctos
UPDATE activities 
SET archived = FALSE, deleted = FALSE, updated_at = COALESCE(updated_at, created_at)
WHERE archived IS NULL OR deleted IS NULL OR updated_at IS NULL;

UPDATE weekly_goals 
SET status = 'active', 
    elapsed_minutes = 0, 
    archived = FALSE, 
    deleted = FALSE,
    updated_at = COALESCE(updated_at, created_at)
WHERE status IS NULL OR elapsed_minutes IS NULL OR archived IS NULL OR deleted IS NULL OR updated_at IS NULL;

