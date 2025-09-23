import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  Alert,
  Dimensions,
} from 'react-native';
import { useNavigation } from '@react-navigation/native';
import ConnectionStatus from '../components/ConnectionStatus';
import WebSocketClient from '../services/WebSocketClient';

const { width, height } = Dimensions.get('window');

export default function HomeScreen() {
  const navigation = useNavigation();
  const [connectionStatus, setConnectionStatus] = useState('disconnected');
  const [serverInfo, setServerInfo] = useState(null);

  useEffect(() => {
    // Initialize WebSocket connection
    WebSocketClient.initialize();
    
    // Set up connection status listener
    const unsubscribe = WebSocketClient.onConnectionChange((status, info) => {
      setConnectionStatus(status);
      setServerInfo(info);
    });

    // Attempt to discover and connect to local Nexus server
    WebSocketClient.discoverServer();

    return unsubscribe;
  }, []);

  const handleStartRecording = () => {
    if (connectionStatus !== 'connected') {
      Alert.alert(
        'Not Connected',
        'Please connect to a Nexus server before starting recording.',
        [{ text: 'OK' }]
      );
      return;
    }

    navigation.navigate('Recording');
  };

  const handleQRScan = () => {
    navigation.navigate('QRScanner');
  };

  const handleSettings = () => {
    navigation.navigate('Settings');
  };

  const handleConnectManually = () => {
    Alert.prompt(
      'Connect to Server',
      'Enter the IP address of your Nexus server:',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Connect',
          onPress: (ip) => {
            if (ip) {
              WebSocketClient.connectToServer(ip);
            }
          },
        },
      ],
      'plain-text',
      '192.168.1.100'
    );
  };

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.title}>Nexus Companion</Text>
        <Text style={styles.subtitle}>Remote Microphone</Text>
      </View>

      <View style={styles.statusSection}>
        <ConnectionStatus 
          status={connectionStatus} 
          serverInfo={serverInfo}
        />
      </View>

      <View style={styles.actionSection}>
        <TouchableOpacity
          style={[
            styles.recordButton,
            connectionStatus !== 'connected' && styles.recordButtonDisabled
          ]}
          onPress={handleStartRecording}
          disabled={connectionStatus !== 'connected'}
        >
          <Text style={styles.recordButtonText}>🎤</Text>
          <Text style={styles.recordButtonLabel}>Start Recording</Text>
        </TouchableOpacity>

        <View style={styles.buttonGrid}>
          <TouchableOpacity
            style={styles.primaryButton}
            onPress={handleQRScan}
          >
            <Text style={styles.buttonIcon}>📱</Text>
            <Text style={styles.primaryButtonText}>Scan QR Code</Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={styles.secondaryButton}
            onPress={handleConnectManually}
          >
            <Text style={styles.secondaryButtonText}>Connect Manually</Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={styles.secondaryButton}
            onPress={handleSettings}
          >
            <Text style={styles.secondaryButtonText}>Settings</Text>
          </TouchableOpacity>
        </View>
      </View>

      <View style={styles.footer}>
        <Text style={styles.footerText}>
          Scan the QR code from Nexus Desktop Settings or ensure your device is on the same network
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
    marginBottom: 40,
    marginTop: 20,
  },
  title: {
    fontSize: 28,
    fontWeight: 'bold',
    color: '#1e293b',
    marginBottom: 8,
  },
  subtitle: {
    fontSize: 16,
    color: '#64748b',
  },
  statusSection: {
    marginBottom: 40,
  },
  actionSection: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  recordButton: {
    width: width * 0.6,
    height: width * 0.6,
    borderRadius: width * 0.3,
    backgroundColor: '#dc2626',
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 40,
    shadowColor: '#000',
    shadowOffset: {
      width: 0,
      height: 4,
    },
    shadowOpacity: 0.3,
    shadowRadius: 4.65,
    elevation: 8,
  },
  recordButtonDisabled: {
    backgroundColor: '#94a3b8',
  },
  recordButtonText: {
    fontSize: 48,
    marginBottom: 8,
  },
  recordButtonLabel: {
    color: 'white',
    fontSize: 16,
    fontWeight: '600',
  },
  buttonGrid: {
    width: '100%',
    paddingHorizontal: 20,
  },
  primaryButton: {
    backgroundColor: '#2563eb',
    paddingVertical: 16,
    paddingHorizontal: 24,
    borderRadius: 12,
    marginBottom: 16,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    shadowColor: '#000',
    shadowOffset: {
      width: 0,
      height: 2,
    },
    shadowOpacity: 0.1,
    shadowRadius: 3.84,
    elevation: 5,
  },
  buttonIcon: {
    fontSize: 20,
    marginRight: 12,
  },
  primaryButtonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
  },
  secondaryButton: {
    backgroundColor: '#e2e8f0',
    paddingVertical: 12,
    paddingHorizontal: 20,
    borderRadius: 8,
    marginBottom: 12,
  },
  secondaryButtonText: {
    color: '#374151',
    fontSize: 14,
    fontWeight: '600',
    textAlign: 'center',
  },
  footer: {
    marginTop: 20,
    alignItems: 'center',
  },
  footerText: {
    fontSize: 12,
    color: '#9ca3af',
    textAlign: 'center',
    lineHeight: 18,
  },
});