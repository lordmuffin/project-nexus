import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  Alert,
  Dimensions,
  Animated,
} from 'react-native';
import { Audio } from 'expo-av';
import { useNavigation } from '@react-navigation/native';
import WebSocketClient from '../services/WebSocketClient';

const { width } = Dimensions.get('window');

export default function RecordingScreen() {
  const navigation = useNavigation();
  const [recording, setRecording] = useState(null);
  const [isRecording, setIsRecording] = useState(false);
  const [recordingDuration, setRecordingDuration] = useState(0);
  const [permissionResponse, requestPermission] = Audio.usePermissions();
  const [pulseAnim] = useState(new Animated.Value(1));

  useEffect(() => {
    // Check if connected
    if (WebSocketClient.getConnectionStatus() !== 'connected') {
      Alert.alert(
        'Not Connected',
        'Connection lost. Please return to home and reconnect.',
        [{ text: 'OK', onPress: () => navigation.goBack() }]
      );
    }
  }, []);

  useEffect(() => {
    let interval;
    if (isRecording) {
      interval = setInterval(() => {
        setRecordingDuration(prev => prev + 1);
      }, 1000);

      // Start pulse animation
      Animated.loop(
        Animated.sequence([
          Animated.timing(pulseAnim, {
            toValue: 1.2,
            duration: 800,
            useNativeDriver: true,
          }),
          Animated.timing(pulseAnim, {
            toValue: 1,
            duration: 800,
            useNativeDriver: true,
          }),
        ])
      ).start();
    } else {
      pulseAnim.setValue(1);
    }

    return () => {
      if (interval) clearInterval(interval);
    };
  }, [isRecording]);

  const formatDuration = (seconds) => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  };

  const startRecording = async () => {
    try {
      if (permissionResponse?.status !== 'granted') {
        console.log('Requesting permission..');
        await requestPermission();
      }

      await Audio.setAudioModeAsync({
        allowsRecordingIOS: true,
        playsInSilentModeIOS: true,
      });

      console.log('Starting recording..');
      const { recording } = await Audio.Recording.createAsync(
        Audio.RECORDING_OPTIONS_PRESET_HIGH_QUALITY
      );
      
      setRecording(recording);
      setIsRecording(true);
      setRecordingDuration(0);
      console.log('Recording started');

    } catch (err) {
      console.error('Failed to start recording', err);
      Alert.alert(
        'Recording Error',
        'Failed to start recording. Please check microphone permissions.',
        [{ text: 'OK' }]
      );
    }
  };

  const stopRecording = async () => {
    console.log('Stopping recording..');
    setIsRecording(false);
    
    if (!recording) return;

    try {
      await recording.stopAndUnloadAsync();
      await Audio.setAudioModeAsync({
        allowsRecordingIOS: false,
      });

      const uri = recording.getURI();
      console.log('Recording stopped and stored at', uri);

      // Upload to server
      try {
        Alert.alert(
          'Uploading Recording',
          'Sending audio to Nexus server for transcription...',
          [],
          { cancelable: false }
        );

        const result = await WebSocketClient.sendAudioRecording(uri, recordingDuration);
        
        Alert.alert(
          'Upload Successful',
          'Your recording has been sent for transcription!',
          [
            {
              text: 'Record Another',
              onPress: () => setRecording(null)
            },
            {
              text: 'Go Home',
              onPress: () => navigation.navigate('Home')
            }
          ]
        );

      } catch (uploadError) {
        console.error('Upload failed:', uploadError);
        Alert.alert(
          'Upload Failed',
          'Failed to send recording to server. Please try again.',
          [
            {
              text: 'Retry',
              onPress: () => {
                WebSocketClient.sendAudioRecording(uri, recordingDuration);
              }
            },
            {
              text: 'Discard',
              onPress: () => {
                setRecording(null);
                setRecordingDuration(0);
              }
            }
          ]
        );
      }

    } catch (error) {
      console.error('Failed to stop recording:', error);
      Alert.alert(
        'Recording Error',
        'Failed to stop recording properly.',
        [{ text: 'OK' }]
      );
    }
  };

  const handleRecordButton = () => {
    if (isRecording) {
      stopRecording();
    } else {
      startRecording();
    }
  };

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.title}>Recording</Text>
        <Text style={styles.duration}>{formatDuration(recordingDuration)}</Text>
      </View>

      <View style={styles.recordingArea}>
        <Animated.View style={[styles.recordButtonContainer, { transform: [{ scale: pulseAnim }] }]}>
          <TouchableOpacity
            style={[
              styles.recordButton,
              isRecording ? styles.recordButtonActive : styles.recordButtonInactive
            ]}
            onPress={handleRecordButton}
          >
            <Text style={styles.recordIcon}>
              {isRecording ? '⏹️' : '🎤'}
            </Text>
          </TouchableOpacity>
        </Animated.View>

        <Text style={styles.instruction}>
          {isRecording ? 'Tap to stop recording' : 'Tap to start recording'}
        </Text>

        {isRecording && (
          <View style={styles.recordingIndicator}>
            <View style={styles.pulsingDot} />
            <Text style={styles.recordingText}>Recording...</Text>
          </View>
        )}
      </View>

      <View style={styles.controls}>
        <TouchableOpacity
          style={styles.cancelButton}
          onPress={() => {
            if (isRecording) {
              stopRecording();
            }
            navigation.goBack();
          }}
        >
          <Text style={styles.cancelButtonText}>Cancel</Text>
        </TouchableOpacity>
      </View>

      <View style={styles.footer}>
        <Text style={styles.footerText}>
          Your audio will be transcribed locally on the Nexus server
        </Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f8fafc',
    padding: 20,
  },
  header: {
    alignItems: 'center',
    marginBottom: 60,
    marginTop: 20,
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#1e293b',
    marginBottom: 12,
  },
  duration: {
    fontSize: 32,
    fontWeight: '600',
    color: '#dc2626',
    fontFamily: 'monospace',
  },
  recordingArea: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  recordButtonContainer: {
    marginBottom: 40,
  },
  recordButton: {
    width: width * 0.5,
    height: width * 0.5,
    borderRadius: width * 0.25,
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: {
      width: 0,
      height: 4,
    },
    shadowOpacity: 0.3,
    shadowRadius: 4.65,
    elevation: 8,
  },
  recordButtonInactive: {
    backgroundColor: '#dc2626',
  },
  recordButtonActive: {
    backgroundColor: '#991b1b',
  },
  recordIcon: {
    fontSize: 64,
  },
  instruction: {
    fontSize: 16,
    color: '#64748b',
    textAlign: 'center',
    marginBottom: 20,
  },
  recordingIndicator: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#dc2626',
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 20,
  },
  pulsingDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    backgroundColor: '#fff',
    marginRight: 8,
  },
  recordingText: {
    color: '#fff',
    fontSize: 14,
    fontWeight: '600',
  },
  controls: {
    marginBottom: 20,
  },
  cancelButton: {
    backgroundColor: '#6b7280',
    paddingVertical: 12,
    paddingHorizontal: 24,
    borderRadius: 8,
    alignSelf: 'center',
  },
  cancelButtonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
  },
  footer: {
    alignItems: 'center',
    marginBottom: 20,
  },
  footerText: {
    fontSize: 12,
    color: '#9ca3af',
    textAlign: 'center',
    lineHeight: 18,
  },
});