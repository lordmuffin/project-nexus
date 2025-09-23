// AudioRecorder Component - TDD Implementation (GREEN PHASE)
// This is the minimal implementation to make tests pass

import React, { useState, useEffect } from 'react';
import { View, Text, TouchableOpacity, StyleSheet, Platform } from 'react-native';
import { Audio } from 'expo-av';

const AudioRecorder = ({ 
  onRecordingComplete, 
  qualitySettings,
  style = {} 
}) => {
  const [isRecording, setIsRecording] = useState(false);
  const [hasPermission, setHasPermission] = useState(null);
  const [recording, setRecording] = useState(null);
  const [error, setError] = useState(null);

  useEffect(() => {
    requestPermissions();
  }, []);

  const requestPermissions = async () => {
    try {
      const permission = await Audio.requestPermissionsAsync();
      setHasPermission(permission.status === 'granted');
    } catch (error) {
      setError('Failed to request permissions');
    }
  };

  const startRecording = async () => {
    try {
      setError(null);
      
      // Set audio mode for recording
      await Audio.setAudioModeAsync({
        allowsRecordingIOS: true,
        playsInSilentModeIOS: true,
      });

      // Create recording with default or custom settings
      const recordingOptions = qualitySettings || {
        android: {
          extension: '.m4a',
          outputFormat: Audio.RECORDING_OPTION_ANDROID_OUTPUT_FORMAT_MPEG_4,
          audioEncoder: Audio.RECORDING_OPTION_ANDROID_AUDIO_ENCODER_AAC,
          sampleRate: 44100,
          numberOfChannels: 2,
          bitRate: 128000,
        },
        ios: {
          extension: '.m4a',
          outputFormat: Audio.RECORDING_OPTION_IOS_OUTPUT_FORMAT_MPEG4AAC,
          audioQuality: Audio.RECORDING_OPTION_IOS_AUDIO_QUALITY_HIGH,
          sampleRate: 44100,
          numberOfChannels: 2,
          bitRate: 128000,
          linearPCMBitDepth: 16,
          linearPCMIsBigEndian: false,
          linearPCMIsFloat: false,
        },
      };

      const { recording: newRecording } = await Audio.Recording.createAsync(
        recordingOptions
      );
      
      setRecording(newRecording);
      await newRecording.startAsync();
      setIsRecording(true);
    } catch (error) {
      if (error.message === 'Recording failed') {
        setError('Recording failed. Try again.');
      } else if (error.message === 'Start failed') {
        setError('Failed to start recording');
      } else {
        setError('Failed to start recording');
      }
    }
  };

  const stopRecording = async () => {
    try {
      if (recording) {
        await recording.stopAndUnloadAsync();
        const uri = recording.getURI();
        
        if (onRecordingComplete && uri) {
          onRecordingComplete(uri);
        }
        
        setRecording(null);
        setIsRecording(false);
      }
    } catch (error) {
      setError('Failed to stop recording');
    }
  };

  const handleRecordingToggle = () => {
    if (isRecording) {
      stopRecording();
    } else {
      startRecording();
    }
  };

  // Permission denied state
  if (hasPermission === false) {
    return (
      <View style={[styles.container, style.container]}>
        <Text style={styles.errorText}>Microphone permission required</Text>
        <TouchableOpacity 
          style={[styles.button, styles.permissionButton]}
          onPress={requestPermissions}
          accessibilityRole="button"
          accessibilityLabel="Request microphone permission"
        >
          <Text style={styles.buttonText}>Request Permission</Text>
        </TouchableOpacity>
      </View>
    );
  }

  // Loading state
  if (hasPermission === null) {
    return (
      <View style={[styles.container, style.container]}>
        <Text style={styles.loadingText}>Checking permissions...</Text>
      </View>
    );
  }

  // Error state
  if (error) {
    return (
      <View style={[styles.container, style.container]}>
        <Text style={styles.errorText}>{error}</Text>
        <TouchableOpacity 
          style={[styles.button, styles.retryButton]}
          onPress={() => {
            setError(null);
            setIsRecording(false);
            setRecording(null);
          }}
          accessibilityRole="button"
          accessibilityLabel="Retry recording"
        >
          <Text style={styles.buttonText}>Try Again</Text>
        </TouchableOpacity>
      </View>
    );
  }

  // Main recording interface
  return (
    <View style={[styles.container, style.container]}>
      <View style={styles.statusContainer}>
        {isRecording ? (
          <>
            <Text style={styles.recordingIndicator}>🔴</Text>
            <Text style={styles.statusText}>Recording...</Text>
          </>
        ) : (
          <Text style={styles.microphoneIcon}>🎤</Text>
        )}
      </View>
      
      <TouchableOpacity 
        style={[
          styles.button, 
          styles.recordButton,
          isRecording ? styles.stopButton : styles.startButton,
          style.button
        ]}
        onPress={handleRecordingToggle}
        accessibilityRole="button"
        accessibilityLabel={isRecording ? 'Stop audio recording' : 'Start audio recording'}
        accessibilityState={isRecording ? { expanded: true } : { expanded: false }}
      >
        <Text style={[
          styles.buttonText,
          isRecording ? styles.stopButtonText : styles.startButtonText
        ]}>
          {isRecording ? 'Stop Recording' : 'Start Recording'}
        </Text>
      </TouchableOpacity>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    alignItems: 'center',
    justifyContent: 'center',
    padding: 20,
  },
  statusContainer: {
    alignItems: 'center',
    marginBottom: 20,
  },
  microphoneIcon: {
    fontSize: 48,
  },
  recordingIndicator: {
    fontSize: 24,
    marginBottom: 8,
  },
  statusText: {
    fontSize: 16,
    color: '#ef4444',
    fontWeight: '600',
  },
  button: {
    paddingVertical: 12,
    paddingHorizontal: 24,
    borderRadius: 8,
    minWidth: 150,
    alignItems: 'center',
  },
  recordButton: {
    paddingVertical: 16,
    paddingHorizontal: 32,
  },
  startButton: {
    backgroundColor: '#10b981',
  },
  stopButton: {
    backgroundColor: '#ef4444',
  },
  permissionButton: {
    backgroundColor: '#3b82f6',
  },
  retryButton: {
    backgroundColor: '#6b7280',
  },
  buttonText: {
    color: 'white',
    fontSize: 16,
    fontWeight: '600',
  },
  startButtonText: {
    color: 'white',
  },
  stopButtonText: {
    color: 'white',
  },
  errorText: {
    color: '#ef4444',
    fontSize: 16,
    textAlign: 'center',
    marginBottom: 16,
  },
  loadingText: {
    color: '#6b7280',
    fontSize: 16,
    textAlign: 'center',
  },
});

export default AudioRecorder;