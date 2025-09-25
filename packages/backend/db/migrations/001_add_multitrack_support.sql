-- Migration: Add Multi-Track Audio Recording Support
-- Version: 001
-- Description: Adds tables and columns to support multi-track audio recording

-- Add multi-track support columns to meeting_recordings table
ALTER TABLE meeting_recordings 
ADD COLUMN IF NOT EXISTS track_metadata JSONB DEFAULT '{}',
ADD COLUMN IF NOT EXISTS tracks_file_path TEXT,
ADD COLUMN IF NOT EXISTS master_mix_path TEXT,
ADD COLUMN IF NOT EXISTS recording_format VARCHAR(20) DEFAULT 'single',
ADD COLUMN IF NOT EXISTS total_tracks INTEGER DEFAULT 1,
ADD COLUMN IF NOT EXISTS sample_rate INTEGER DEFAULT 44100,
ADD COLUMN IF NOT EXISTS bit_depth INTEGER DEFAULT 16,
ADD COLUMN IF NOT EXISTS duration_seconds FLOAT DEFAULT 0;

-- Create audio_tracks table for individual track metadata
CREATE TABLE IF NOT EXISTS audio_tracks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recording_id UUID REFERENCES meeting_recordings(id) ON DELETE CASCADE,
    track_number INTEGER NOT NULL,
    source_type VARCHAR(50) NOT NULL, -- 'microphone', 'system_output', 'application', 'line_input'
    source_name VARCHAR(100) NOT NULL,
    device_id VARCHAR(255), -- Device identifier for hardware sources
    application_name VARCHAR(100), -- For application-specific tracks
    file_path TEXT NOT NULL,
    duration_seconds FLOAT DEFAULT 0,
    sample_rate INTEGER DEFAULT 48000,
    channels INTEGER DEFAULT 1,
    bit_depth INTEGER DEFAULT 16,
    file_size_bytes BIGINT DEFAULT 0,
    peak_level_db FLOAT, -- Peak audio level in dB
    rms_level_db FLOAT, -- RMS audio level in dB
    is_active BOOLEAN DEFAULT true,
    track_metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Ensure unique track numbers per recording
    UNIQUE(recording_id, track_number)
);

-- Create audio_sources table for managing available audio sources
CREATE TABLE IF NOT EXISTS audio_sources (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id VARCHAR(255) NOT NULL,
    source_type VARCHAR(50) NOT NULL,
    source_name VARCHAR(100) NOT NULL,
    display_name VARCHAR(100),
    is_system_source BOOLEAN DEFAULT false,
    is_available BOOLEAN DEFAULT true,
    capabilities JSONB DEFAULT '{}', -- Sample rates, channels, etc.
    last_detected TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB DEFAULT '{}',
    
    UNIQUE(device_id, source_type, source_name)
);

-- Create recording_sessions table for managing active recording sessions
CREATE TABLE IF NOT EXISTS recording_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    session_name VARCHAR(255),
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'paused', 'stopped', 'completed', 'failed')),
    recording_format VARCHAR(20) DEFAULT 'multitrack',
    selected_tracks JSONB DEFAULT '[]', -- Array of selected track configurations
    output_directory TEXT,
    sync_reference_track INTEGER, -- Track number used for synchronization
    auto_level_enabled BOOLEAN DEFAULT true,
    noise_reduction_enabled BOOLEAN DEFAULT false,
    real_time_transcription BOOLEAN DEFAULT false,
    started_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    ended_at TIMESTAMP WITH TIME ZONE,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create track_settings table for per-track recording configurations
CREATE TABLE IF NOT EXISTS track_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID REFERENCES recording_sessions(id) ON DELETE CASCADE,
    track_number INTEGER NOT NULL,
    source_id UUID REFERENCES audio_sources(id),
    is_enabled BOOLEAN DEFAULT true,
    gain_db FLOAT DEFAULT 0.0,
    is_muted BOOLEAN DEFAULT false,
    is_solo BOOLEAN DEFAULT false,
    monitor_enabled BOOLEAN DEFAULT false,
    noise_gate_threshold_db FLOAT DEFAULT -60.0,
    compressor_enabled BOOLEAN DEFAULT false,
    eq_enabled BOOLEAN DEFAULT false,
    eq_settings JSONB DEFAULT '{}',
    track_color VARCHAR(7) DEFAULT '#3B82F6', -- Hex color for UI
    track_metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(session_id, track_number)
);

-- Create system_audio_permissions table for tracking user permissions
CREATE TABLE IF NOT EXISTS system_audio_permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    device_id VARCHAR(255) NOT NULL,
    permission_type VARCHAR(50) NOT NULL, -- 'microphone', 'system_audio', 'screen_recording'
    is_granted BOOLEAN DEFAULT false,
    granted_at TIMESTAMP WITH TIME ZONE,
    revoked_at TIMESTAMP WITH TIME ZONE,
    last_requested TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB DEFAULT '{}',
    
    UNIQUE(user_id, device_id, permission_type)
);

-- Create indexes for optimal performance
CREATE INDEX IF NOT EXISTS idx_audio_tracks_recording_id ON audio_tracks(recording_id);
CREATE INDEX IF NOT EXISTS idx_audio_tracks_source_type ON audio_tracks(source_type);
CREATE INDEX IF NOT EXISTS idx_audio_tracks_active ON audio_tracks(is_active);
CREATE INDEX IF NOT EXISTS idx_audio_sources_device_id ON audio_sources(device_id);
CREATE INDEX IF NOT EXISTS idx_audio_sources_available ON audio_sources(is_available);
CREATE INDEX IF NOT EXISTS idx_recording_sessions_user_id ON recording_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_recording_sessions_status ON recording_sessions(status);
CREATE INDEX IF NOT EXISTS idx_track_settings_session_id ON track_settings(session_id);
CREATE INDEX IF NOT EXISTS idx_track_settings_enabled ON track_settings(is_enabled);
CREATE INDEX IF NOT EXISTS idx_system_audio_permissions_user_device ON system_audio_permissions(user_id, device_id);
CREATE INDEX IF NOT EXISTS idx_system_audio_permissions_granted ON system_audio_permissions(is_granted);

-- Insert default audio sources for common system configurations
INSERT INTO audio_sources (device_id, source_type, source_name, display_name, is_system_source, capabilities) 
VALUES 
    ('default', 'microphone', 'default_microphone', 'Default Microphone', false, '{"sample_rates": [44100, 48000], "channels": [1, 2]}'),
    ('system', 'system_output', 'speakers', 'System Audio (Speakers)', true, '{"sample_rates": [44100, 48000], "channels": [2]}'),
    ('system', 'system_output', 'headphones', 'System Audio (Headphones)', true, '{"sample_rates": [44100, 48000], "channels": [2]}')
ON CONFLICT (device_id, source_type, source_name) DO NOTHING;

-- Create a function to automatically update track count when tracks are added/removed
CREATE OR REPLACE FUNCTION update_recording_track_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE meeting_recordings 
        SET total_tracks = (
            SELECT COUNT(*) 
            FROM audio_tracks 
            WHERE recording_id = NEW.recording_id AND is_active = true
        ),
        updated_at = CURRENT_TIMESTAMP
        WHERE id = NEW.recording_id;
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        UPDATE meeting_recordings 
        SET total_tracks = (
            SELECT COUNT(*) 
            FROM audio_tracks 
            WHERE recording_id = NEW.recording_id AND is_active = true
        ),
        updated_at = CURRENT_TIMESTAMP
        WHERE id = NEW.recording_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE meeting_recordings 
        SET total_tracks = (
            SELECT COUNT(*) 
            FROM audio_tracks 
            WHERE recording_id = OLD.recording_id AND is_active = true
        ),
        updated_at = CURRENT_TIMESTAMP
        WHERE id = OLD.recording_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Create triggers to maintain track count consistency
DROP TRIGGER IF EXISTS trigger_update_track_count ON audio_tracks;
CREATE TRIGGER trigger_update_track_count
    AFTER INSERT OR UPDATE OR DELETE ON audio_tracks
    FOR EACH ROW EXECUTE FUNCTION update_recording_track_count();

-- Add comments to document the schema
COMMENT ON TABLE audio_tracks IS 'Individual audio track metadata for multi-track recordings';
COMMENT ON TABLE audio_sources IS 'Available audio input/output sources on the system';
COMMENT ON TABLE recording_sessions IS 'Active recording session management and configuration';
COMMENT ON TABLE track_settings IS 'Per-track recording configuration and audio processing settings';
COMMENT ON TABLE system_audio_permissions IS 'User permissions for accessing system audio sources';

COMMENT ON COLUMN meeting_recordings.recording_format IS 'Recording format: single, multitrack, or mixed';
COMMENT ON COLUMN audio_tracks.source_type IS 'Type of audio source: microphone, system_output, application, line_input';
COMMENT ON COLUMN audio_tracks.peak_level_db IS 'Peak audio level in decibels for level monitoring';
COMMENT ON COLUMN track_settings.track_color IS 'Hex color code for UI track visualization';