-- Database initialization script for Project Nexus
-- This script creates the core tables needed for Phase 1

-- Create users table for future authentication
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(255) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create chat sessions table
CREATE TABLE IF NOT EXISTS chat_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create chat messages table
CREATE TABLE IF NOT EXISTS chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID REFERENCES chat_sessions(id) ON DELETE CASCADE,
    role VARCHAR(20) NOT NULL CHECK (role IN ('user', 'assistant')),
    content TEXT NOT NULL,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create notes table
CREATE TABLE IF NOT EXISTS notes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    content TEXT,
    tags TEXT[],
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create device pairing table for QR code connections
CREATE TABLE IF NOT EXISTS device_pairs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id VARCHAR(255) UNIQUE NOT NULL,
    device_info JSONB DEFAULT '{}',
    paired_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    unpaired_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT true,
    last_seen TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create meeting recordings table for future phases
CREATE TABLE IF NOT EXISTS meeting_recordings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255),
    transcript TEXT,
    summary TEXT,
    action_items JSONB DEFAULT '[]',
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create system status table for health monitoring
CREATE TABLE IF NOT EXISTS system_status (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    service_name VARCHAR(100) NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('healthy', 'unhealthy', 'degraded')),
    last_check TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB DEFAULT '{}'
);

-- AI Processes table for tracking AI operations (transcription, analysis, etc.)
CREATE TABLE IF NOT EXISTS ai_processes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    meeting_id UUID REFERENCES meetings(id) ON DELETE CASCADE,
    process_type VARCHAR(50) NOT NULL CHECK (process_type IN ('transcription', 'analysis', 'chat', 'auto-summary')),
    status VARCHAR(20) NOT NULL DEFAULT 'queued' CHECK (status IN ('queued', 'running', 'completed', 'failed', 'cancelled')),
    progress INTEGER NOT NULL DEFAULT 0 CHECK (progress >= 0 AND progress <= 100),
    phase VARCHAR(100),
    message TEXT,
    start_time TIMESTAMP,
    end_time TIMESTAMP,
    elapsed_time INTEGER DEFAULT 0,
    estimated_time_remaining INTEGER,
    resource_usage JSONB DEFAULT '{"cpu": 0, "memory": 0}',
    logs JSONB DEFAULT '[]',
    error_details JSONB,
    result JSONB,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_chat_messages_session_id ON chat_messages(session_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_created_at ON chat_messages(created_at);
CREATE INDEX IF NOT EXISTS idx_notes_user_id ON notes(user_id);
CREATE INDEX IF NOT EXISTS idx_notes_created_at ON notes(created_at);
CREATE INDEX IF NOT EXISTS idx_device_pairs_device_id ON device_pairs(device_id);
CREATE INDEX IF NOT EXISTS idx_device_pairs_active ON device_pairs(is_active);
CREATE INDEX IF NOT EXISTS idx_meeting_recordings_user_id ON meeting_recordings(user_id);
CREATE INDEX IF NOT EXISTS idx_system_status_service ON system_status(service_name);
CREATE INDEX IF NOT EXISTS idx_ai_processes_meeting_id ON ai_processes(meeting_id);
CREATE INDEX IF NOT EXISTS idx_ai_processes_status ON ai_processes(status);
CREATE INDEX IF NOT EXISTS idx_ai_processes_type ON ai_processes(process_type);
CREATE INDEX IF NOT EXISTS idx_ai_processes_created_at ON ai_processes(created_at DESC);

-- Insert default user for demo purposes
INSERT INTO users (id, username, email) 
VALUES ('00000000-0000-0000-0000-000000000001', 'demo', 'demo@nexus.local')
ON CONFLICT (username) DO NOTHING;

-- Insert initial system status entries
INSERT INTO system_status (service_name, status, metadata) 
VALUES 
    ('database', 'healthy', '{"message": "Database initialized successfully"}'),
    ('backend', 'healthy', '{"message": "Backend service started"}')
ON CONFLICT DO NOTHING;