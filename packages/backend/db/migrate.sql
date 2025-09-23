-- Database migration script for Project Nexus
-- This script ensures the database schema is up-to-date

-- Drop and recreate device_pairs table if it has wrong schema
DO $$ 
BEGIN
    -- Check if device_pairs table exists with old schema
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'device_pairs' 
        AND column_name = 'pairing_code'
    ) THEN
        -- Old schema detected, drop and recreate
        DROP TABLE IF EXISTS device_pairs CASCADE;
        
        CREATE TABLE device_pairs (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            device_id VARCHAR(255) UNIQUE NOT NULL,
            device_info JSONB DEFAULT '{}',
            paired_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            unpaired_at TIMESTAMP WITH TIME ZONE,
            is_active BOOLEAN DEFAULT true,
            last_seen TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );
        
        CREATE INDEX IF NOT EXISTS idx_device_pairs_device_id ON device_pairs(device_id);
        CREATE INDEX IF NOT EXISTS idx_device_pairs_active ON device_pairs(is_active);
        
        RAISE NOTICE 'device_pairs table recreated with correct schema';
    END IF;
    
    -- Ensure device_pairs table exists with correct schema
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_name = 'device_pairs'
    ) THEN
        CREATE TABLE device_pairs (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            device_id VARCHAR(255) UNIQUE NOT NULL,
            device_info JSONB DEFAULT '{}',
            paired_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            unpaired_at TIMESTAMP WITH TIME ZONE,
            is_active BOOLEAN DEFAULT true,
            last_seen TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );
        
        CREATE INDEX IF NOT EXISTS idx_device_pairs_device_id ON device_pairs(device_id);
        CREATE INDEX IF NOT EXISTS idx_device_pairs_active ON device_pairs(is_active);
        
        RAISE NOTICE 'device_pairs table created';
    END IF;
END $$;