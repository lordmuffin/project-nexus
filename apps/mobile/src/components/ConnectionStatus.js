import React from 'react';
import { View, Text, StyleSheet } from 'react-native';

export default function ConnectionStatus({ status, serverInfo }) {
  const getStatusConfig = () => {
    switch (status) {
      case 'connected':
        return {
          color: '#10b981',
          icon: '🟢',
          text: 'Connected',
          detail: serverInfo ? `${serverInfo.host}:${serverInfo.port}` : 'Connected to server'
        };
      case 'connecting':
        return {
          color: '#f59e0b',
          icon: '🟡',
          text: 'Connecting...',
          detail: 'Searching for Nexus server'
        };
      case 'disconnected':
      default:
        return {
          color: '#ef4444',
          icon: '🔴',
          text: 'Disconnected',
          detail: 'Not connected to any server'
        };
    }
  };

  const config = getStatusConfig();

  return (
    <View style={styles.container}>
      <View style={styles.statusRow}>
        <Text style={styles.icon}>{config.icon}</Text>
        <View style={styles.textContainer}>
          <Text style={[styles.statusText, { color: config.color }]}>
            {config.text}
          </Text>
          <Text style={styles.detailText}>{config.detail}</Text>
        </View>
      </View>
      
      {serverInfo && status === 'connected' && (
        <View style={styles.serverInfo}>
          <Text style={styles.serverLabel}>Server Details:</Text>
          <Text style={styles.serverDetail}>Name: {serverInfo.name}</Text>
          <Text style={styles.serverDetail}>Version: {serverInfo.version}</Text>
        </View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
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
  statusRow: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  icon: {
    fontSize: 24,
    marginRight: 12,
  },
  textContainer: {
    flex: 1,
  },
  statusText: {
    fontSize: 18,
    fontWeight: '600',
    marginBottom: 2,
  },
  detailText: {
    fontSize: 14,
    color: '#6b7280',
  },
  serverInfo: {
    marginTop: 12,
    paddingTop: 12,
    borderTopWidth: 1,
    borderTopColor: '#e5e7eb',
  },
  serverLabel: {
    fontSize: 14,
    fontWeight: '600',
    color: '#374151',
    marginBottom: 4,
  },
  serverDetail: {
    fontSize: 12,
    color: '#6b7280',
    marginBottom: 2,
  },
});