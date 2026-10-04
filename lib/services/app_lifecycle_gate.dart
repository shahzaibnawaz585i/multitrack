import 'package:flutter/widgets.dart';

/// Tracks foreground vs background without extra rebuilds.
class AppLifecycleGate with WidgetsBindingObserver {
  AppLifecycleGate._();

  static final AppLifecycleGate instance = AppLifecycleGate._();

  AppLifecycleState state = AppLifecycleState.resumed;
  bool _bound = false;

  void ensureBound() {
    if (_bound) {
      return;
    }
    _bound = true;
    WidgetsBinding.instance.addObserver(this);
    state = WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed;
  }

  bool get isForeground => state == AppLifecycleState.resumed;

  /// TTS while app is visible (includes notification shade / brief inactive).
  bool get isForegroundForVoice =>
      state == AppLifecycleState.resumed ||
      state == AppLifecycleState.inactive;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    this.state = state;
  }
}
