import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  Alert,
  TouchableOpacity,
  Dimensions,
} from 'react-native';
import { BarCodeScanner } from 'expo-barcode-scanner';
import { useNavigation } from '@react-navigation/native';
import WebSocketClient from '../services/WebSocketClient';

const { width } = Dimensions.get('window');

export default function QRScannerScreen() {
  const navigation = useNavigation();
  const [hasPermission, setHasPermission] = useState(null);
  const [scanned, setScanned] = useState(false);
  const [scanning, setScanning] = useState(true);

  useEffect(() => {
    const getBarCodeScannerPermissions = async () => {
      const { status } = await BarCodeScanner.requestPermissionsAsync();
      setHasPermission(status === 'granted');
    };

    getBarCodeScannerPermissions();
  }, []);

  const handleBarCodeScanned = async ({ type, data }) => {
    if (scanned) return;
    
    setScanned(true);
    setScanning(false);

    try {
      console.log('QR Code scanned:', data);
      console.log('QR Code length:', data.length);
      
      // Parse QR code data
      const qrData = JSON.parse(data);
      console.log('Parsed QR data:', qrData);
      
      // Debug: Show parsed data in alert
      Alert.alert(
        'Debug: QR Parsed', 
        `Token: ${qrData.token ? 'YES' : 'NO'}\nServerUrl: ${qrData.serverUrl || 'MISSING'}\nData length: ${data.length}`,
        [{ text: 'Continue', onPress: () => {} }]
      );
      
      if (!qrData.token || !qrData.serverUrl) {
        console.error('Missing required fields:', { hasToken: !!qrData.token, hasServerUrl: !!qrData.serverUrl });
        throw new Error('Invalid QR code format - missing token or serverUrl');
      }
      
      console.log('QR data validation passed:', { token: qrData.token.substring(0, 8) + '...', serverUrl: qrData.serverUrl });

      // Show loading alert
      Alert.alert(
        'Pairing Device',
        'Connecting to Nexus server...',
        [],
        { cancelable: false }
      );

      // Attempt to pair with server
      const result = await WebSocketClient.pairWithServer(data);
      
      if (result.success) {
        Alert.alert(
          'Pairing Successful',
          'Your device has been paired successfully!',
          [
            {
              text: 'OK',
              onPress: () => navigation.navigate('Home')
            }
          ]
        );
      } else {
        throw new Error(result.error || 'Pairing failed');
      }

    } catch (error) {
      console.error('QR code processing error:', error);
      
      let errorMessage = 'Failed to pair device';
      if (error.message.includes('JSON')) {
        errorMessage = 'Invalid QR code format. Please scan a valid Nexus pairing code.';
      } else if (error.message.includes('Invalid QR code')) {
        errorMessage = 'Invalid QR code. Please scan a valid Nexus pairing code.';
      } else if (error.message.includes('expired')) {
        errorMessage = 'QR code has expired. Please generate a new one.';
      } else if (error.message.includes('network') || error.message.includes('fetch')) {
        errorMessage = 'Network error. Make sure you\'re on the same WiFi network as your computer.';
      } else if (error.message.includes('timeout')) {
        errorMessage = 'Connection timeout. Check your network connection and try again.';
      }

      Alert.alert(
        'Pairing Failed',
        errorMessage,
        [
          {
            text: 'Try Again',
            onPress: () => {
              setScanned(false);
              setScanning(true);
            }
          },
          {
            text: 'Cancel',
            onPress: () => navigation.goBack()
          }
        ]
      );
    }
  };

  const resetScanner = () => {
    setScanned(false);
    setScanning(true);
  };

  if (hasPermission === null) {
    return (
      <View style={styles.container}>
        <Text style={styles.text}>Requesting camera permission...</Text>
      </View>
    );
  }

  if (hasPermission === false) {
    return (
      <View style={styles.container}>
        <Text style={styles.text}>
          Camera permission is required to scan QR codes.
        </Text>
        <TouchableOpacity
          style={styles.button}
          onPress={() => navigation.goBack()}
        >
          <Text style={styles.buttonText}>Go Back</Text>
        </TouchableOpacity>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      {scanning && (
        <BarCodeScanner
          onBarCodeScanned={scanned ? undefined : handleBarCodeScanned}
          style={styles.scanner}
        />
      )}
      
      <View style={styles.overlay}>
        <View style={styles.scanArea}>
          <View style={styles.scanFrame} />
        </View>
        
        <View style={styles.instructions}>
          <Text style={styles.instructionText}>
            Position the QR code within the frame
          </Text>
          <Text style={styles.subText}>
            Generated from Nexus Desktop Settings
          </Text>
        </View>

        <View style={styles.buttonContainer}>
          {scanned && (
            <TouchableOpacity
              style={styles.button}
              onPress={resetScanner}
            >
              <Text style={styles.buttonText}>Scan Again</Text>
            </TouchableOpacity>
          )}
          
          <TouchableOpacity
            style={[styles.button, styles.cancelButton]}
            onPress={() => navigation.goBack()}
          >
            <Text style={styles.buttonText}>Cancel</Text>
          </TouchableOpacity>
        </View>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#000',
  },
  scanner: {
    flex: 1,
  },
  overlay: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    justifyContent: 'center',
    alignItems: 'center',
  },
  scanArea: {
    width: width * 0.8,
    height: width * 0.8,
    justifyContent: 'center',
    alignItems: 'center',
  },
  scanFrame: {
    width: '100%',
    height: '100%',
    borderWidth: 2,
    borderColor: '#fff',
    borderRadius: 12,
    backgroundColor: 'transparent',
  },
  instructions: {
    position: 'absolute',
    bottom: 120,
    alignItems: 'center',
    paddingHorizontal: 20,
  },
  instructionText: {
    color: '#fff',
    fontSize: 18,
    fontWeight: '600',
    textAlign: 'center',
    marginBottom: 8,
  },
  subText: {
    color: '#ccc',
    fontSize: 14,
    textAlign: 'center',
  },
  buttonContainer: {
    position: 'absolute',
    bottom: 40,
    width: '100%',
    paddingHorizontal: 40,
  },
  button: {
    backgroundColor: '#2563eb',
    paddingVertical: 12,
    paddingHorizontal: 24,
    borderRadius: 8,
    marginBottom: 12,
  },
  cancelButton: {
    backgroundColor: '#6b7280',
  },
  buttonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
    textAlign: 'center',
  },
  text: {
    color: '#fff',
    fontSize: 16,
    textAlign: 'center',
    margin: 20,
  },
});