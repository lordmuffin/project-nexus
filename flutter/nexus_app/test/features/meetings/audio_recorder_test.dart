import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/features/meetings/services/audio_recorder.dart';

void main() {
  group('AudioRecorderService', () {
    late AudioRecorderService audioRecorder;

    setUp(() {
      audioRecorder = AudioRecorderService();
    });

    tearDown(() {
      audioRecorder.dispose();
    });

    test('should create instance', () {
      expect(audioRecorder, isNotNull);
    });

    test('should have empty streams initially', () {
      expect(audioRecorder.stateStream, isNotNull);
      expect(audioRecorder.amplitudeStream, isNotNull);
    });
  });
}