// TDD Example: AudioRecorder Component
// This demonstrates Red-Green-Refactor cycle for a new feature

import React from 'react';
import { render, screen, fireEvent, waitFor } from '../../__tests__/test-utils';
import { mockAudioPermissions, createMockRecording } from '../../__tests__/test-utils';
import AudioRecorder from '../AudioRecorder';

// Mock Expo AV
const mockRecording = createMockRecording();
jest.mock('expo-av', () => ({
  Audio: {
    requestPermissionsAsync: jest.fn(),
    setAudioModeAsync: jest.fn(),
    Recording: {
      createAsync: jest.fn(() => Promise.resolve({ recording: mockRecording })),
    },
  },
}));

describe('AudioRecorder Component - TDD Implementation', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    mockAudioPermissions('granted');
  });

  // RED PHASE: Write failing tests first

  describe('Initial State', () => {
    test('should display start recording button when not recording', () => {
      render(<AudioRecorder onRecordingComplete={jest.fn()} />);
      
      expect(screen.getByText('Start Recording')).toBeOnTheScreen();
      expect(screen.queryByText('Stop Recording')).not.toBeOnTheScreen();
    });

    test('should show microphone icon when ready to record', () => {
      render(<AudioRecorder onRecordingComplete={jest.fn()} />);
      
      expect(screen.getByText('🎤')).toBeOnTheScreen();
    });
  });

  describe('Permission Handling', () => {
    test('should request audio permissions on mount', async () => {
      const { Audio } = require('expo-av');
      
      render(<AudioRecorder onRecordingComplete={jest.fn()} />);
      
      await waitFor(() => {
        expect(Audio.requestPermissionsAsync).toHaveBeenCalledTimes(1);
      });
    });

    test('should display permission denied message when permissions not granted', async () => {
      mockAudioPermissions('denied');
      
      render(<AudioRecorder onRecordingComplete={jest.fn()} />);
      
      await waitFor(() => {
        expect(screen.getByText('Microphone permission required')).toBeOnTheScreen();
      });
    });

    test('should show request permission button when permissions denied', async () => {
      mockAudioPermissions('denied');
      
      render(<AudioRecorder onRecordingComplete={jest.fn()} />);
      
      await waitFor(() => {
        expect(screen.getByText('Request Permission')).toBeOnTheScreen();
      });
    });
  });

  describe('Recording Functionality', () => {
    test('should start recording when start button is pressed', async () => {
      const { Audio } = require('expo-av');
      
      render(<AudioRecorder onRecordingComplete={jest.fn()} />);
      
      // Wait for permissions to be granted
      await waitFor(() => {
        expect(screen.getByText('Start Recording')).toBeOnTheScreen();
      });
      
      fireEvent.press(screen.getByText('Start Recording'));
      
      await waitFor(() => {
        expect(Audio.Recording.createAsync).toHaveBeenCalledTimes(1);
        expect(mockRecording.startAsync).toHaveBeenCalledTimes(1);
      });
    });

    test('should show stop button when recording is active', async () => {
      render(<AudioRecorder onRecordingComplete={jest.fn()} />);
      
      await waitFor(() => {
        expect(screen.getByText('Start Recording')).toBeOnTheScreen();
      });
      
      fireEvent.press(screen.getByText('Start Recording'));
      
      await waitFor(() => {
        expect(screen.getByText('Stop Recording')).toBeOnTheScreen();
        expect(screen.queryByText('Start Recording')).not.toBeOnTheScreen();
      });
    });

    test('should show recording indicator when recording', async () => {
      render(<AudioRecorder onRecordingComplete={jest.fn()} />);
      
      await waitFor(() => {
        fireEvent.press(screen.getByText('Start Recording'));
      });
      
      await waitFor(() => {
        expect(screen.getByText('🔴')).toBeOnTheScreen(); // Red recording indicator
        expect(screen.getByText('Recording...')).toBeOnTheScreen();
      });
    });

    test('should stop recording when stop button is pressed', async () => {
      const mockOnComplete = jest.fn();
      mockRecording.getURI.mockReturnValue('mock-audio-uri');
      
      render(<AudioRecorder onRecordingComplete={mockOnComplete} />);
      
      await waitFor(() => {
        fireEvent.press(screen.getByText('Start Recording'));
      });
      
      await waitFor(() => {
        fireEvent.press(screen.getByText('Stop Recording'));
      });
      
      await waitFor(() => {
        expect(mockRecording.stopAndUnloadAsync).toHaveBeenCalledTimes(1);
        expect(mockOnComplete).toHaveBeenCalledWith('mock-audio-uri');
      });
    });

    test('should return to initial state after stopping recording', async () => {
      render(<AudioRecorder onRecordingComplete={jest.fn()} />);
      
      // Start recording
      await waitFor(() => {
        fireEvent.press(screen.getByText('Start Recording'));
      });
      
      // Stop recording
      await waitFor(() => {
        fireEvent.press(screen.getByText('Stop Recording'));
      });
      
      await waitFor(() => {
        expect(screen.getByText('Start Recording')).toBeOnTheScreen();
        expect(screen.queryByText('Stop Recording')).not.toBeOnTheScreen();
        expect(screen.queryByText('Recording...')).not.toBeOnTheScreen();
      });
    });
  });

  describe('Error Handling', () => {
    test('should handle recording creation errors gracefully', async () => {
      const { Audio } = require('expo-av');
      Audio.Recording.createAsync.mockRejectedValue(new Error('Recording failed'));
      
      render(<AudioRecorder onRecordingComplete={jest.fn()} />);
      
      await waitFor(() => {
        fireEvent.press(screen.getByText('Start Recording'));
      });
      
      await waitFor(() => {
        expect(screen.getByText('Recording failed. Try again.')).toBeOnTheScreen();
      });
    });

    test('should handle recording start errors gracefully', async () => {
      mockRecording.startAsync.mockRejectedValue(new Error('Start failed'));
      
      render(<AudioRecorder onRecordingComplete={jest.fn()} />);
      
      await waitFor(() => {
        fireEvent.press(screen.getByText('Start Recording'));
      });
      
      await waitFor(() => {
        expect(screen.getByText('Failed to start recording')).toBeOnTheScreen();
      });
    });
  });

  describe('Accessibility', () => {
    test('should have proper accessibility labels', async () => {
      render(<AudioRecorder onRecordingComplete={jest.fn()} />);
      
      const startButton = screen.getByText('Start Recording');
      expect(startButton).toHaveAccessibilityRole('button');
      expect(startButton).toHaveAccessibilityLabel('Start audio recording');
    });

    test('should update accessibility state when recording', async () => {
      render(<AudioRecorder onRecordingComplete={jest.fn()} />);
      
      await waitFor(() => {
        fireEvent.press(screen.getByText('Start Recording'));
      });
      
      await waitFor(() => {
        const stopButton = screen.getByText('Stop Recording');
        expect(stopButton).toHaveAccessibilityLabel('Stop audio recording');
        expect(stopButton).toHaveAccessibilityState({ expanded: true });
      });
    });
  });

  describe('Component Props', () => {
    test('should accept custom recording quality settings', () => {
      const qualitySettings = {
        android: {
          extension: '.m4a',
          outputFormat: 'MPEG_4',
          audioEncoder: 'AAC',
          sampleRate: 44100,
          numberOfChannels: 2,
          bitRate: 128000,
        },
        ios: {
          extension: '.m4a',
          outputFormat: 'MPEG4AAC',
          audioQuality: 'HIGH',
          sampleRate: 44100,
          numberOfChannels: 2,
          bitRate: 128000,
          linearPCMBitDepth: 16,
          linearPCMIsBigEndian: false,
          linearPCMIsFloat: false,
        },
      };
      
      render(
        <AudioRecorder 
          onRecordingComplete={jest.fn()} 
          qualitySettings={qualitySettings}
        />
      );
      
      // Component should render without errors with custom settings
      expect(screen.getByText('Start Recording')).toBeOnTheScreen();
    });

    test('should accept custom styling props', () => {
      const customStyle = {
        container: { backgroundColor: '#custom' },
        button: { borderRadius: 20 },
      };
      
      render(
        <AudioRecorder 
          onRecordingComplete={jest.fn()} 
          style={customStyle}
        />
      );
      
      expect(screen.getByText('Start Recording')).toBeOnTheScreen();
    });
  });
});