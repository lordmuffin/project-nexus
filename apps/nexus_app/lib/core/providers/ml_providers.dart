import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexus_app/core/ml/ml_service.dart';

/// Provider for the ML Service used for language identification and
/// future model-driven features that operate on saved recordings.
final mlServiceProvider = Provider<MLService>((ref) {
  final service = MLService();
  ref.onDispose(service.dispose);
  return service;
});
