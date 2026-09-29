import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../models/notification_model.dart';

/// Speaks live alert notifications aloud using the device TTS engine.
class VoiceAlertService {
  VoiceAlertService._();

  static final VoiceAlertService _instance = VoiceAlertService._();
  static VoiceAlertService get instance => _instance;

  FlutterTts? _tts;
  bool _ready = false;
  bool enabled = true;

  // ─── Pre-warm ────────────────────────────────────────────────────────────

  Future<void> prewarm() async {
    await _init();
  }

  // ─── Init (internal) ──────────────────────────────────────────────────────

  Future<bool> _init() async {
    if (_ready && _tts != null) return true;

    try {
      _tts = FlutterTts();

      if (!kIsWeb && Platform.isAndroid) {
        await Future<void>.delayed(const Duration(milliseconds: 300));
      }

      try {
        await _tts!.setVolume(1.0);
        await _tts!.setSpeechRate(0.48);
        await _tts!.setPitch(1.0);
      } catch (_) {}

      try {
        await _tts!.setLanguage('en-US');
      } catch (_) {
        try {
          await _tts!.setLanguage('en_US');
        } catch (_) {}
      }

      if (!kIsWeb && Platform.isIOS) {
        try {
          await _tts!.setSharedInstance(true);
          await _tts!.setIosAudioCategory(
            IosTextToSpeechAudioCategory.playback,
            <IosTextToSpeechAudioCategoryOptions>[
              IosTextToSpeechAudioCategoryOptions.allowBluetooth,
              IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
            ],
            IosTextToSpeechAudioMode.defaultMode,
          );
        } catch (_) {}
      }

      _ready = true;
      debugPrint('[VoiceAlertService] ✅ TTS Ready');
      return true;
    } catch (e, st) {
      debugPrint('[VoiceAlertService] ❌ Init error: $e\n$st');
      _ready = false;
      return false;
    }
  }

  // ─── Public API ───────────────────────────────────────────────────────────

  /// Speaks the given raw text message.
  void speakText(String text) {
    if (!enabled || text.trim().isEmpty) return;
    unawaited(_speakRaw(text));
  }

  /// Speaks the voice notification for [notification].
  void speak(AppNotification notification) {
    if (!enabled) return;
    final String text = _buildSpeech(notification);
    speakText(text);
  }

  /// Plays a test voice message so the user can verify audio output.
  void testVoice() {
    speakText('Alert! Voice notification is working properly.');
  }

  Future<void> _speakRaw(String text) async {
    try {
      await _init();
      if (_tts == null) return;
      try {
        await _tts!.stop();
      } catch (_) {}
      debugPrint('[VoiceAlertService] 🔊 Speaking: "$text"');
      await _tts!.speak(text);
    } catch (e) {
      debugPrint('[VoiceAlertService] speak error: $e');
    }
  }

  /// Stop any currently playing speech immediately.
  void stop() {
    unawaited(_stopAsync());
  }

  Future<void> _stopAsync() async {
    try {
      await _tts?.stop();
    } catch (_) {}
  }

  /// Release TTS resources (call on logout).
  Future<void> dispose() async {
    try {
      await _tts?.stop();
    } catch (_) {}
    _tts = null;
    _ready = false;
  }

  // ─── Speech text builder ──────────────────────────────────────────────────

  String _buildSpeech(AppNotification n) {
    final String vehicle = n.vehicleId.isNotEmpty ? n.vehicleId : 'Vehicle';

    switch (n.eventType) {
      case NotificationEventType.ignitionOn:
        return 'Alert! $vehicle ignition is on. Engine has started.';

      case NotificationEventType.ignitionOff:
        return 'Alert! $vehicle ignition is off. Engine has stopped.';

      case NotificationEventType.overSpeed:
        final String spd = n.speed != null
            ? '${n.speed!.toStringAsFixed(0)} kilometres per hour'
            : 'speed limit';
        return 'Overspeed Alert! $vehicle is travelling at $spd. Please slow down.';

      case NotificationEventType.geofenceIn:
        return '$vehicle has entered the geofence zone.';

      case NotificationEventType.geofenceOut:
        return 'Warning! $vehicle has exited the geofence zone.';

      case NotificationEventType.offline:
        return 'Warning! $vehicle is offline. No signal received.';

      case NotificationEventType.movement:
        return 'Alert! Movement detected on $vehicle.';

      case NotificationEventType.generic:
        return n.eventTitle.isNotEmpty
            ? 'Alert for $vehicle. ${n.eventTitle}.'
            : 'New alert for $vehicle.';
    }
  }
}
