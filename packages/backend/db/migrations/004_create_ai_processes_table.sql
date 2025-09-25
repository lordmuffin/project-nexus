-- Migration: Create AI Processes table for tracking AI operations
-- This table stores information about all AI processes (transcription, analysis, etc.)

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
    elapsed_time INTEGER DEFAULT 0, -- in seconds
    estimated_time_remaining INTEGER, -- in seconds
    resource_usage JSONB DEFAULT '{"cpu": 0, "memory": 0}',
    logs JSONB DEFAULT '[]',
    error_details JSONB,
    result JSONB,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_ai_processes_meeting_id ON ai_processes(meeting_id);
CREATE INDEX IF NOT EXISTS idx_ai_processes_status ON ai_processes(status);
CREATE INDEX IF NOT EXISTS idx_ai_processes_type ON ai_processes(process_type);
CREATE INDEX IF NOT EXISTS idx_ai_processes_created_at ON ai_processes(created_at DESC);

-- Create trigger to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_ai_processes_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER trigger_update_ai_processes_updated_at
    BEFORE UPDATE ON ai_processes
    FOR EACH ROW
    EXECUTE FUNCTION update_ai_processes_updated_at();

-- Add comments for documentation
COMMENT ON TABLE ai_processes IS 'Tracks AI processing operations like transcription, analysis, and chat interactions';
COMMENT ON COLUMN ai_processes.process_type IS 'Type of AI process: transcription, analysis, chat, auto-summary';
COMMENT ON COLUMN ai_processes.status IS 'Current status: queued, running, completed, failed, cancelled';
COMMENT ON COLUMN ai_processes.progress IS 'Progress percentage from 0 to 100';
COMMENT ON COLUMN ai_processes.phase IS 'Current processing phase (e.g., preparing, analyzing, extracting, finalizing)';
COMMENT ON COLUMN ai_processes.resource_usage IS 'CPU and memory usage metrics during processing';
COMMENT ON COLUMN ai_processes.logs IS 'Array of log entries with timestamp, level, and message';
COMMENT ON COLUMN ai_processes.error_details IS 'Detailed error information if process failed';
COMMENT ON COLUMN ai_processes.result IS 'Process result data (summary, transcription, etc.)';
COMMENT ON COLUMN ai_processes.metadata IS 'Additional process-specific metadata';