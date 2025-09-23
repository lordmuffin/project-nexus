// Characterization tests for existing ConnectionStatus component
import React from 'react';
import { render, screen } from '../../__tests__/test-utils';
import ConnectionStatus from '../ConnectionStatus';

describe('ConnectionStatus Component', () => {
  describe('Connected State', () => {
    test('should display connected status with green indicator', () => {
      const serverInfo = {
        host: '192.168.1.100',
        port: 3001,
        name: 'Nexus Server',
        version: '1.0.0'
      };

      render(<ConnectionStatus status="connected" serverInfo={serverInfo} />);
      
      expect(screen.getByText('🟢')).toBeOnTheScreen();
      expect(screen.getByText('Connected')).toBeOnTheScreen();
      expect(screen.getByText('192.168.1.100:3001')).toBeOnTheScreen();
    });

    test('should display server details when connected', () => {
      const serverInfo = {
        host: '192.168.1.100',
        port: 3001,
        name: 'Nexus Server',
        version: '1.0.0'
      };

      render(<ConnectionStatus status="connected" serverInfo={serverInfo} />);
      
      expect(screen.getByText('Server Details:')).toBeOnTheScreen();
      expect(screen.getByText('Name: Nexus Server')).toBeOnTheScreen();
      expect(screen.getByText('Version: 1.0.0')).toBeOnTheScreen();
    });

    test('should show fallback text when connected without server info', () => {
      render(<ConnectionStatus status="connected" serverInfo={null} />);
      
      expect(screen.getByText('Connected')).toBeOnTheScreen();
      expect(screen.getByText('Connected to server')).toBeOnTheScreen();
      expect(screen.queryByText('Server Details:')).not.toBeOnTheScreen();
    });
  });

  describe('Connecting State', () => {
    test('should display connecting status with yellow indicator', () => {
      render(<ConnectionStatus status="connecting" serverInfo={null} />);
      
      expect(screen.getByText('🟡')).toBeOnTheScreen();
      expect(screen.getByText('Connecting...')).toBeOnTheScreen();
      expect(screen.getByText('Searching for Nexus server')).toBeOnTheScreen();
    });

    test('should not display server details when connecting', () => {
      const serverInfo = {
        host: '192.168.1.100',
        port: 3001,
        name: 'Nexus Server',
        version: '1.0.0'
      };

      render(<ConnectionStatus status="connecting" serverInfo={serverInfo} />);
      
      expect(screen.queryByText('Server Details:')).not.toBeOnTheScreen();
    });
  });

  describe('Disconnected State', () => {
    test('should display disconnected status with red indicator', () => {
      render(<ConnectionStatus status="disconnected" serverInfo={null} />);
      
      expect(screen.getByText('🔴')).toBeOnTheScreen();
      expect(screen.getByText('Disconnected')).toBeOnTheScreen();
      expect(screen.getByText('Not connected to any server')).toBeOnTheScreen();
    });

    test('should handle undefined status as disconnected', () => {
      render(<ConnectionStatus status={undefined} serverInfo={null} />);
      
      expect(screen.getByText('🔴')).toBeOnTheScreen();
      expect(screen.getByText('Disconnected')).toBeOnTheScreen();
    });

    test('should handle unknown status as disconnected', () => {
      render(<ConnectionStatus status="unknown" serverInfo={null} />);
      
      expect(screen.getByText('🔴')).toBeOnTheScreen();
      expect(screen.getByText('Disconnected')).toBeOnTheScreen();
    });
  });

  describe('Component Structure', () => {
    test('should have consistent styling structure', () => {
      const { container } = render(<ConnectionStatus status="connected" serverInfo={null} />);
      
      // The component should render without errors
      expect(container).toBeTruthy();
    });

    test('should handle missing props gracefully', () => {
      // Component should not crash with minimal props
      render(<ConnectionStatus />);
      
      expect(screen.getByText('Disconnected')).toBeOnTheScreen();
    });
  });
});