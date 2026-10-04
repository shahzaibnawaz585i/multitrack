import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../constants/api_config.dart';
import '../models/vehicle_model.dart';
import 'auth_service.dart';
import 'vehicle_service.dart';

/// Live device coordinates — WebSocket when the server supports it, else fast poll.
class LiveDeviceSocketService {
  LiveDeviceSocketService._();

  static final LiveDeviceSocketService instance = LiveDeviceSocketService._();

  static const Duration _pollInterval = Duration(seconds: 2);
  static const Duration _reconnectDelay = Duration(seconds: 5);

  final StreamController<VehicleModel> _updates =
      StreamController<VehicleModel>.broadcast();

  WebSocket? _socket;
  Timer? _pollTimer;
  Timer? _reconnectTimer;
  int? _trackedDeviceId;
  bool _running = false;
  bool _pollInFlight = false;

  Stream<VehicleModel> streamForDevice(int deviceId) =>
      _updates.stream.where((VehicleModel v) => v.id == deviceId);

  Stream<VehicleModel> get allUpdates => _updates.stream;

  bool get isTracking => _running;

  Future<void> startTracking(int deviceId) async {
    final bool deviceChanged =
        _trackedDeviceId != null && _trackedDeviceId != deviceId;
    _trackedDeviceId = deviceId;
    if (!_running) {
      _running = true;
      _startPollTimer();
      await _connectWebSocket();
    }
    if (deviceChanged || !_pollInFlight) {
      unawaited(_pollOnce(force: true));
    }
    emitCachedDevice(deviceId);
  }

  void stopTracking({int? deviceId}) {
    if (deviceId != null &&
        _trackedDeviceId != null &&
        deviceId != _trackedDeviceId) {
      return;
    }
    _running = false;
    _trackedDeviceId = null;
    _pollTimer?.cancel();
    _pollTimer = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _closeSocket();
  }

  void requestRefresh() {
    if (!_running) {
      return;
    }
    unawaited(_pollOnce(force: true));
  }

  void emitCachedDevice(int deviceId) {
    final VehicleModel? cached = VehicleService.findCachedDevice(deviceId);
    if (cached != null) {
      _publish(cached);
    }
  }

  void _startPollTimer() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      unawaited(_pollOnce(force: true));
    });
  }

  Future<void> _connectWebSocket() async {
    if (kIsWeb) {
      return;
    }
    _closeSocket();
    try {
      final String server = await AuthService.server();
      final String? token = await AuthService.token();
      if (token == null || token.isEmpty) {
        return;
      }
      final String base = ApiConfig.baseUrlFor(server);
      final Uri httpBase = Uri.parse(base);
      final Uri wsUri = httpBase.replace(
        scheme: httpBase.scheme == 'https' ? 'wss' : 'ws',
        path: '/socket',
        queryParameters: <String, String>{'user_api_hash': token},
      );
      _socket = await WebSocket.connect(wsUri.toString());
      _socket!.listen(
        _onSocketMessage,
        onError: (_) => _scheduleReconnect(),
        onDone: _scheduleReconnect,
        cancelOnError: true,
      );
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (!_running || _reconnectTimer != null) {
      return;
    }
    _reconnectTimer = Timer(_reconnectDelay, () {
      _reconnectTimer = null;
      if (_running) {
        unawaited(_connectWebSocket());
      }
    });
  }

  void _closeSocket() {
    try {
      _socket?.close();
    } catch (_) {}
    _socket = null;
  }

  void _onSocketMessage(dynamic raw) {
    if (raw is! String) {
      return;
    }
    try {
      final dynamic decoded = jsonDecode(raw);
      _parseSocketPayload(decoded);
    } catch (_) {}
  }

  void _parseSocketPayload(dynamic decoded) {
    if (decoded is Map) {
      final Map<String, dynamic> map = decoded.map(
        (Object? k, Object? v) => MapEntry(k.toString(), v),
      );
      if (map.containsKey('items')) {
        _parseSocketPayload(map['items']);
        return;
      }
      final VehicleModel? vehicle = _vehicleFromSocketMap(map);
      if (vehicle != null) {
        VehicleService.patchCachedDevice(vehicle);
        _publishIfTracked(vehicle);
      }
      return;
    }
    if (decoded is List) {
      for (final dynamic item in decoded) {
        _parseSocketPayload(item);
      }
    }
  }

  VehicleModel? _vehicleFromSocketMap(Map<String, dynamic> map) {
    final int? id = _readInt(map['id'] ?? map['device_id']);
    if (id == null) {
      return null;
    }
    final VehicleModel? cached = VehicleService.findCachedDevice(id);
    if (cached != null) {
      return VehicleModel.mergeSocketUpdate(cached, map);
    }
    try {
      return VehicleModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> _pollOnce({required bool force}) async {
    if (!_running || _pollInFlight) {
      return;
    }
    _pollInFlight = true;
    try {
      final List<VehicleModel> fleet =
          await VehicleService.getDevices(forceRefresh: force);
      for (final VehicleModel vehicle in fleet) {
        if (_trackedDeviceId != null && vehicle.id == _trackedDeviceId) {
          _publish(vehicle);
          return;
        }
      }
      if (_trackedDeviceId != null) {
        emitCachedDevice(_trackedDeviceId!);
      }
    } finally {
      _pollInFlight = false;
    }
  }

  void _publishIfTracked(VehicleModel vehicle) {
    if (_trackedDeviceId == null || vehicle.id == _trackedDeviceId) {
      _publish(vehicle);
    }
  }

  void _publish(VehicleModel vehicle) {
    if (_updates.isClosed) {
      return;
    }
    _updates.add(vehicle);
  }

  static int? _readInt(dynamic value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '');
  }

}
