import 'dart:async';
import 'dart:collection';
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
  bool _engineBound = false;
  bool enabled = true;

  Future<void>? _initFuture;
  final Queue<String> _speechQueue = Queue<String>();
  bool _drainRunning = false;
  final LinkedHashSet<String> _spokenAlertKeys = LinkedHashSet<String>();
  static const int _maxSpokenKeys = 400;

  Future<void> prewarm() async {
    await _ensureEngineReady();
  }

  void applySettings({
    required bool notificationOn,
    required bool voiceOn,
  }) {
    // Banner/system notifications are independent; voice follows Voice Command only.
    enabled = voiceOn;
    debugPrint(
      '[VoiceAlertService] enabled=$enabled (notification=$notificationOn voice=$voiceOn)',
    );
  }

  Future<void> _ensureEngineReady({bool forceRebind = false}) async {
    if (!forceRebind && _engineBound && _tts != null) {
      return;
    }

    if (!forceRebind && _initFuture != null) {
      return _initFuture!;
    }

    _initFuture = _bindEngine();
    try {
      await _initFuture;
    } finally {
      _initFuture = null;
    }
  }

  Future<void> _bindEngine() async {
    _engineBound = false;
    try {
      await _tts?.stop();
    } catch (_) {}
    _tts = FlutterTts();

    _tts!.setErrorHandler((dynamic message) {
      debugPrint('[VoiceAlertService] TTS error: $message');
    });

    if (!kIsWeb && Platform.isAndroid) {
      await _pollUntilEngineReady();
      await _pickAndroidEngine();
      await _pollUntilEngineReady();
    } else {
      await _pollUntilEngineReady();
    }

    try {
      await _tts!.awaitSpeakCompletion(true);
    } catch (_) {}

    try {
      await _tts!.setVolume(1.0);
      await _tts!.setSpeechRate(0.48);
      await _tts!.setPitch(1.0);
    } catch (_) {}

    if (!kIsWeb && Platform.isAndroid) {
      try {
        await _tts!.setQueueMode(0);
      } catch (_) {}
    }

    await _applyLanguage();

    if (!kIsWeb && Platform.isIOS) {
      try {
        await _tts!.setSharedInstance(true);
        await _tts!.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          <IosTextToSpeechAudioCategoryOptions>[
            IosTextToSpeechAudioCategoryOptions.allowBluetooth,
            IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
            IosTextToSpeechAudioCategoryOptions.duckOthers,
          ],
          IosTextToSpeechAudioMode.spokenAudio,
        );
      } catch (_) {}
    }

    _engineBound = await _pollUntilEngineReady(
      maxWait: const Duration(seconds: 8),
    );
    if (_engineBound) {
      debugPrint('[VoiceAlertService] TTS engine ready');
    } else {
      debugPrint('[VoiceAlertService] TTS not ready yet — will retry on speak');
    }
  }

  /// Waits until Android TextToSpeech service connection is usable.
  Future<bool> _pollUntilEngineReady({
    Duration maxWait = const Duration(seconds: 15),
  }) async {
    final FlutterTts? tts = _tts;
    if (tts == null) {
      return false;
    }

    final DateTime deadline = DateTime.now().add(maxWait);
    while (DateTime.now().isBefore(deadline)) {
      try {
        final dynamic engines = await tts.getEngines;
        if (engines is List && engines.isNotEmpty) {
          return true;
        }
      } catch (_) {}

      try {
        final dynamic voices = await tts.getVoices;
        if (voices is List && voices.isNotEmpty) {
          return true;
        }
      } catch (_) {}

      await Future<void>.delayed(const Duration(milliseconds: 120));
    }
    return false;
  }

  Future<void> _pickAndroidEngine() async {
    final FlutterTts tts = _tts!;
    try {
      final dynamic engines = await tts.getEngines;
      if (engines is! List || engines.isEmpty) {
        return;
      }
      String? chosen;
      for (final dynamic engine in engines) {
        final String name = engine.toString();
        final String lower = name.toLowerCase();
        if (lower.contains('google')) {
          chosen = name;
          break;
        }
      }
      chosen ??= engines.first.toString();
      final dynamic setResult = await tts.setEngine(chosen);
      if (setResult != 1 && setResult != true) {
        debugPrint('[VoiceAlertService] setEngine returned: $setResult');
      }
      debugPrint('[VoiceAlertService] Using engine: $chosen');
    } catch (e) {
      debugPrint('[VoiceAlertService] Engine pick failed: $e');
    }
  }

  Future<void> _applyLanguage() async {
    final FlutterTts? tts = _tts;
    if (tts == null) {
      return;
    }
    for (final String locale in <String>['en-US', 'en_US', 'en-GB', 'en']) {
      try {
        final dynamic avail = await tts.isLanguageAvailable(locale);
        if (avail == 1 || avail == true) {
          await tts.setLanguage(locale);
          return;
        }
      } catch (_) {}
    }
    try {
      await tts.setLanguage('en-US');
    } catch (_) {}
  }

  void speakText(String text) {
    if (!enabled || text.trim().isEmpty) return;
    _speechQueue.addLast(text.trim());
    unawaited(_drainSpeechQueue());
  }

  void speak(AppNotification notification) {
    if (!enabled) return;
    final String voiceKey = _voiceKeyFor(notification);
    if (_spokenAlertKeys.contains(voiceKey)) {
      return;
    }
    _rememberSpokenKey(voiceKey);
    speakText(_buildSpeech(notification));
  }

  void testVoice() {
    speakText('Alert. Voice notification is working properly.');
  }

  Future<void> _drainSpeechQueue() async {
    if (_drainRunning) {
      return;
    }
    _drainRunning = true;
    try {
      while (_speechQueue.isNotEmpty && enabled) {
        final String text = _speechQueue.removeFirst();
        final bool ok = await _speakWithRetry(text);
        if (!ok) {
          debugPrint('[VoiceAlertService] Failed after retries: "$text"');
        }
      }
    } finally {
      _drainRunning = false;
      if (_speechQueue.isNotEmpty && enabled) {
        unawaited(_drainSpeechQueue());
      }
    }
  }

  Future<bool> _speakWithRetry(String text, {int attempts = 3}) async {
    for (int i = 0; i < attempts; i++) {
      try {
        await _ensureEngineReady(forceRebind: i > 0);
        if (_tts == null) {
          continue;
        }
        debugPrint('[VoiceAlertService] Speaking: "$text"');
        final dynamic result = await _tts!.speak(text);
        if (result == 1 || result == true) {
          final int waitMs = (text.length * 55).clamp(900, 15000);
          await Future<void>.delayed(Duration(milliseconds: waitMs));
          return true;
        }
        await _waitForCompletionFallback(text);
        return true;
      } catch (e) {
        debugPrint('[VoiceAlertService] speak attempt ${i + 1} failed: $e');
        _engineBound = false;
        await Future<void>.delayed(Duration(milliseconds: 400 * (i + 1)));
      }
    }
    return false;
  }

  Future<void> _waitForCompletionFallback(String text) async {
    final Completer<void> done = Completer<void>();
    void completeOnce() {
      if (!done.isCompleted) {
        done.complete();
      }
    }

    try {
      _tts?.setCompletionHandler(completeOnce);
    } catch (_) {}

    final int waitMs = (text.length * 55).clamp(1200, 15000);
    await done.future.timeout(
      Duration(milliseconds: waitMs),
      onTimeout: completeOnce,
    );

    try {
      _tts?.setCompletionHandler(() {});
    } catch (_) {}
  }

  void stop() {
    _speechQueue.clear();
    unawaited(_stopAsync());
  }

  Future<void> _stopAsync() async {
    try {
      await _tts?.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    _speechQueue.clear();
    _spokenAlertKeys.clear();
    _engineBound = false;
    _initFuture = null;
    try {
      await _tts?.stop();
    } catch (_) {}
    _tts = null;
    _drainRunning = false;
  }

  static String _voiceKeyFor(AppNotification n) {
    if (n.id != null) {
      return 'evt_${n.id}';
    }
    final int sec = n.timestamp.millisecondsSinceEpoch ~/ 1000;
    return '${n.vehicleId}_${n.eventType.name}_${n.eventTitle}_$sec';
  }

  void _rememberSpokenKey(String key) {
    _spokenAlertKeys.add(key);
    while (_spokenAlertKeys.length > _maxSpokenKeys) {
      _spokenAlertKeys.remove(_spokenAlertKeys.first);
    }
  }

  String _buildSpeech(AppNotification n) {
    final String vehicle = _shortVehicleName(n.vehicleId);

    switch (n.eventType) {
      case NotificationEventType.ignitionOn:
        return 'Alert. $vehicle ignition on. Engine started.';

      case NotificationEventType.ignitionOff:
        return 'Alert. $vehicle ignition off. Engine stopped.';

      case NotificationEventType.overSpeed:
        final String spd = n.speed != null
            ? '${n.speed!.toStringAsFixed(0)} kilometres per hour'
            : 'speed limit';
        return 'Overspeed alert. $vehicle travelling at $spd. Please slow down.';

      case NotificationEventType.geofenceIn:
        return 'Alert. $vehicle entered geofence zone.';

      case NotificationEventType.geofenceOut:
        return 'Warning. $vehicle exited geofence zone.';

      case NotificationEventType.offline:
        return 'Warning. $vehicle is offline. No signal received.';

      case NotificationEventType.movement:
        return 'Alert. Movement detected on $vehicle.';

      case NotificationEventType.generic:
        return n.eventTitle.isNotEmpty
            ? 'Alert for $vehicle. ${n.eventTitle}.'
            : 'New alert for $vehicle.';
    }
  }

  static String _shortVehicleName(String raw) {
    final String trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return 'Vehicle';
    }
    if (trimmed.length <= 48) {
      return trimmed;
    }
    return '${trimmed.substring(0, 45).trim()}…';
  }
}
