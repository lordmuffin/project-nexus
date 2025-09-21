# Phase 2 Audio Streaming Workflow Test Plan

## Test Overview
This document outlines the comprehensive testing procedure for the Phase 2 audio streaming and transcription workflow.

## Test Components

### 1. Desktop PWA Device Pairing
**Test Steps:**
1. Open desktop PWA at http://localhost:3000
2. Navigate to Settings → Device Pairing
3. Click "Generate QR Code"
4. Verify QR code appears with 5-minute expiration timer
5. Verify token is displayed (truncated)

**Expected Results:**
- QR code generates successfully
- Expiration countdown is visible
- Token is properly formatted and secure

### 2. Mobile App Pairing
**Test Steps:**
1. Open Nexus Companion mobile app
2. Scan QR code from desktop
3. Verify successful pairing notification
4. Check connection status indicator

**Expected Results:**
- QR code scanning works correctly
- Device pairing token validation succeeds
- WebSocket connection establishes
- Both devices show "connected" status

### 3. Audio Recording and Upload
**Test Steps:**
1. On mobile app, navigate to Recording screen
2. Grant microphone permissions if prompted
3. Tap record button to start recording
4. Speak for 30-60 seconds
5. Tap stop button to end recording
6. Verify audio upload notification

**Expected Results:**
- Recording UI provides visual feedback
- Audio permissions granted successfully
- Recording timer functions correctly
- Audio file uploads to backend
- Upload progress indication shown

### 4. Real-time Transcription
**Test Steps:**
1. Monitor desktop PWA Meetings section during recording
2. Verify "Recording..." indicator appears
3. Check for live transcription updates
4. Wait for transcription completion notification

**Expected Results:**
- Desktop shows recording status
- Live transcription text appears (if implemented)
- Transcription completes successfully
- Final transcript appears in Meetings list

### 5. AI Analysis and Summary
**Test Steps:**
1. Select completed meeting from Meetings list
2. Navigate to Summary tab
3. Click "Generate Summary" if not auto-generated
4. Review generated summary and action items
5. Check Action Items tab for extracted tasks

**Expected Results:**
- Meeting appears in list with transcript
- AI summary generates successfully
- Action items are extracted correctly
- Summary is coherent and relevant

### 6. Data Persistence
**Test Steps:**
1. Restart Docker containers
2. Refresh desktop PWA
3. Verify meetings and transcripts persist
4. Check database for stored data

**Expected Results:**
- All meeting data persists across restarts
- Transcripts remain accessible
- Database integrity maintained
- No data loss occurs

## Privacy and Security Validation

### 1. Network Traffic Analysis
**Test Steps:**
1. Use network monitoring tools (Wireshark, etc.)
2. Record audio on mobile device
3. Monitor all network traffic
4. Verify no external data transmission

**Expected Results:**
- All traffic stays within local network
- No external API calls for transcription
- Audio data only sent to local backend
- No telemetry or analytics data sent

### 2. Local Data Processing
**Test Steps:**
1. Disconnect from internet
2. Perform complete audio recording workflow
3. Verify all functionality works offline
4. Check that transcription still processes

**Expected Results:**
- All core functionality works without internet
- Transcription processes locally via Whisper
- AI analysis works via local Ollama
- No external dependencies for core features

### 3. Container Isolation
**Test Steps:**
1. Check Docker network configuration
2. Verify container communication is isolated
3. Test firewall rules and port access
4. Validate data volume security

**Expected Results:**
- Containers communicate only on internal network
- No unnecessary port exposure to host
- Data volumes properly secured
- Network isolation properly configured

## Performance Testing

### 1. Transcription Speed
**Metrics to measure:**
- Time from upload to transcription start
- Processing time for 1-minute audio
- End-to-end latency for complete workflow

**Targets:**
- Upload processing: <5 seconds
- Transcription: <30 seconds per minute of audio
- Total workflow: <60 seconds for 1-minute recording

### 2. Mobile App Performance
**Metrics to measure:**
- Battery usage during recording
- Memory consumption
- Audio quality and file size
- Connection stability

**Targets:**
- Battery drain: <5% per hour of recording
- Memory usage: <100MB
- Audio quality: Clear and intelligible
- Connection: Stable without dropouts

### 3. Desktop PWA Performance
**Metrics to measure:**
- Real-time UI updates
- WebSocket message handling
- Meeting list performance
- Transcript display responsiveness

**Targets:**
- UI updates: <500ms latency
- WebSocket: Reliable message delivery
- List performance: Smooth scrolling with 100+ meetings
- Transcript: Fast rendering and search

## Error Handling and Recovery

### 1. Connection Failures
**Test Scenarios:**
- WiFi disconnection during recording
- Backend service restart during transcription
- Mobile app force-close during upload
- Desktop PWA refresh during processing

**Expected Behavior:**
- Graceful handling of connection loss
- Automatic reconnection when possible
- Clear error messages to users
- Data preservation during failures

### 2. Invalid Audio Files
**Test Scenarios:**
- Upload corrupted audio file
- Use unsupported audio format
- Upload extremely long recording
- Upload silent/empty audio

**Expected Behavior:**
- Proper validation and error messages
- Graceful handling of edge cases
- No system crashes or data corruption
- Clear feedback to users

### 3. Resource Constraints
**Test Scenarios:**
- Low disk space conditions
- High CPU usage during transcription
- Memory constraints on mobile device
- Multiple simultaneous recordings

**Expected Behavior:**
- System degrades gracefully under load
- Clear resource usage indicators
- Proper queuing of transcription jobs
- No data loss under resource pressure

## Integration Testing

### 1. Cross-Platform Compatibility
**Test Platforms:**
- Desktop: Windows, macOS, Linux browsers
- Mobile: iOS and Android devices
- Network: Various WiFi configurations

**Expected Results:**
- Consistent behavior across platforms
- Proper audio format handling
- Reliable WebSocket connections
- UI responsiveness on all devices

### 2. Multi-Device Scenarios
**Test Scenarios:**
- Multiple mobile devices paired to one desktop
- One mobile device switching between desktops
- Simultaneous recordings from different devices
- Device unpairing and re-pairing

**Expected Behavior:**
- Proper device management
- Clear separation of recording sessions
- No interference between devices
- Secure device authentication

## Test Environment Setup

### Prerequisites
1. Docker and Docker Compose installed
2. Mobile device with camera for QR scanning
3. Network monitoring tools (optional)
4. Test audio content prepared

### Startup Procedure
1. Clone repository: `git clone <repository-url>`
2. Navigate to project: `cd project-nexus`
3. Start services: `docker-compose up`
4. Install mobile app on test device
5. Ensure both devices on same WiFi network

### Test Data Cleanup
1. Remove test recordings from uploads directory
2. Clear database test data
3. Reset device pairings
4. Clear mobile app cache

## Success Criteria

### Phase 2 Complete Success Requires:
- ✅ All 6 core workflow tests passing
- ✅ Privacy and security validation complete
- ✅ Performance targets met
- ✅ Error handling robust
- ✅ Cross-platform compatibility verified
- ✅ Complete documentation provided

### Critical Path Items:
1. QR code pairing works reliably
2. Audio uploads without data loss
3. Transcription accuracy acceptable
4. AI analysis provides value
5. No external data transmission
6. System performs within targets

## Troubleshooting Guide

### Common Issues:
1. **QR Code Not Generating**: Check backend logs, verify API endpoint
2. **Mobile App Connection Failed**: Verify WiFi network, check firewall
3. **Transcription Not Starting**: Check Whisper service health, disk space
4. **AI Analysis Failed**: Verify Ollama service, check model availability
5. **Performance Issues**: Monitor resource usage, check container logs

### Debug Commands:
```bash
# Check service health
docker-compose ps
docker-compose logs backend
docker-compose logs transcription

# Monitor resource usage
docker stats

# Test API endpoints
curl http://localhost:3001/api/health
curl http://localhost:3001/api/pairing/generate-qr -X POST
curl http://localhost:8000/health

# View database
docker-compose exec database psql -U nexus -d nexus -c "SELECT * FROM meeting_recordings;"
```

## Test Results Documentation

### Test Execution Log
- [ ] Desktop PWA pairing test
- [ ] Mobile app pairing test
- [ ] Audio recording test
- [ ] Real-time transcription test
- [ ] AI analysis test
- [ ] Data persistence test
- [ ] Privacy validation test
- [ ] Performance testing
- [ ] Error handling test
- [ ] Integration testing

### Performance Metrics
- Transcription speed: _____ seconds per minute
- Upload latency: _____ seconds
- Memory usage: _____ MB (mobile), _____ MB (desktop)
- Battery consumption: _____ % per hour

### Issues Found
- [ ] No critical issues
- [ ] Minor issues (document below)
- [ ] Major issues requiring fixes

### Final Validation
- [ ] All acceptance criteria met
- [ ] Privacy requirements satisfied
- [ ] Performance targets achieved
- [ ] System ready for production use