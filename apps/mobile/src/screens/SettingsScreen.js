import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  Alert,
  ScrollView,
} from 'react-native';
import { useNavigation } from '@react-navigation/native';
import WebSocketClient from '../services/WebSocketClient';

export default function SettingsScreen() {
  const navigation = useNavigation();
  const [serverInfo, setServerInfo] = useState(WebSocketClient.getServerInfo());

  const handleDisconnect = () => {
    Alert.alert(
      'Disconnect',
      'Are you sure you want to disconnect from the Nexus server?',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Disconnect',
          style: 'destructive',
          onPress: () => {
            WebSocketClient.disconnect();
            navigation.navigate('Home');
          }
        }
      ]
    );
  };

  const handleTestConnection = async () => {
    try {
      Alert.alert('Testing Connection', 'Checking connection to server...', [], { cancelable: false });
      
      if (serverInfo) {
        const response = await fetch(`http://${serverInfo.host}:${serverInfo.port}/api/health`);
        if (response.ok) {
          Alert.alert('Connection Test', 'Connection to server is healthy!');
        } else {
          throw new Error('Server not responding properly');
        }
      } else {
        throw new Error('No server connection');
      }
    } catch (error) {
      Alert.alert(
        'Connection Test Failed', 
        `Could not connect to server: ${error.message}`,
        [{ text: 'OK' }]
      );
    }
  };

  const handleAbout = () => {
    Alert.alert(
      'About Nexus Companion',
      'Version 1.0.0\n\nA privacy-first mobile companion for Project Nexus.\n\nAll audio processing happens locally on your Nexus server - no data leaves your network.',
      [{ text: 'OK' }]
    );
  };

  return (
    <ScrollView style={styles.container}>
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Connection</Text>
        
        {serverInfo ? (
          <View style={styles.connectionInfo}>
            <Text style={styles.infoLabel}>Connected Server:</Text>
            <Text style={styles.infoValue}>{serverInfo.host}:{serverInfo.port}</Text>
            
            <Text style={styles.infoLabel}>Server Name:</Text>
            <Text style={styles.infoValue}>{serverInfo.name || 'Unknown'}</Text>
            
            <Text style={styles.infoLabel}>Version:</Text>
            <Text style={styles.infoValue}>{serverInfo.version || 'Unknown'}</Text>
          </View>
        ) : (
          <Text style={styles.noConnection}>Not connected to any server</Text>
        )}

        <TouchableOpacity style={styles.button} onPress={handleTestConnection}>
          <Text style={styles.buttonText}>Test Connection</Text>
        </TouchableOpacity>

        {serverInfo && (
          <TouchableOpacity style={[styles.button, styles.dangerButton]} onPress={handleDisconnect}>
            <Text style={[styles.buttonText, styles.dangerButtonText]}>Disconnect</Text>
          </TouchableOpacity>
        )}
      </View>

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Recording Settings</Text>
        
        <View style={styles.settingRow}>
          <Text style={styles.settingLabel}>Audio Quality</Text>
          <Text style={styles.settingValue}>High (Default)</Text>
        </View>
        
        <View style={styles.settingRow}>
          <Text style={styles.settingLabel}>Recording Format</Text>
          <Text style={styles.settingValue}>MP4/AAC</Text>
        </View>
      </View>

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Privacy</Text>
        
        <View style={styles.privacyInfo}>
          <Text style={styles.privacyText}>
            🔒 All audio processing happens locally on your Nexus server
          </Text>
          <Text style={styles.privacyText}>
            🏠 No data is sent to external servers
          </Text>
          <Text style={styles.privacyText}>
            📱 This app only communicates with devices on your local network
          </Text>
        </View>
      </View>

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Support</Text>
        
        <TouchableOpacity style={styles.button} onPress={handleAbout}>
          <Text style={styles.buttonText}>About</Text>
        </TouchableOpacity>
      </View>

      <View style={styles.footer}>
        <Text style={styles.footerText}>
          Nexus Companion v1.0.0{'\n'}
          Privacy-first mobile recording
        </Text>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f8fafc',
    padding: 20,
  },
  section: {
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 16,
    marginBottom: 16,
    shadowColor: '#000',
    shadowOffset: {
      width: 0,
      height: 2,
    },
    shadowOpacity: 0.1,
    shadowRadius: 3.84,
    elevation: 5,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#1e293b',
    marginBottom: 12,
  },
  connectionInfo: {
    marginBottom: 16,
  },
  infoLabel: {
    fontSize: 14,
    color: '#6b7280',
    marginTop: 8,
  },
  infoValue: {
    fontSize: 16,
    fontWeight: '500',
    color: '#1e293b',
    marginTop: 2,
  },
  noConnection: {
    fontSize: 14,
    color: '#ef4444',
    fontStyle: 'italic',
    marginBottom: 16,
  },
  settingRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 8,
  },
  settingLabel: {
    fontSize: 16,
    color: '#374151',
  },
  settingValue: {
    fontSize: 16,
    color: '#6b7280',
  },
  privacyInfo: {
    marginTop: 8,
  },
  privacyText: {
    fontSize: 14,
    color: '#374151',
    marginBottom: 8,
    lineHeight: 20,
  },
  button: {
    backgroundColor: '#2563eb',
    paddingVertical: 12,
    paddingHorizontal: 16,
    borderRadius: 8,
    marginBottom: 8,
  },
  buttonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
    textAlign: 'center',
  },
  dangerButton: {
    backgroundColor: '#ef4444',
  },
  dangerButtonText: {
    color: '#fff',
  },
  footer: {
    alignItems: 'center',
    marginTop: 20,
    marginBottom: 40,
  },
  footerText: {
    fontSize: 12,
    color: '#9ca3af',
    textAlign: 'center',
    lineHeight: 18,
  },
});