import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_config.dart';
import '../models/device_group_model.dart';
import 'api_client.dart';
import 'auth_service.dart';

class VehicleGroupService {
  VehicleGroupService._();

  static const String _fleetCacheKey = 'vehicle_service_get_devices_v1';

  static List<DeviceGroupModel> _groupsFromLastFleet = <DeviceGroupModel>[];

  static void cacheGroupsFromFleetResponse(dynamic response) {
    _groupsFromLastFleet = _parseGroupsFromTree(response);
  }

  static Future<List<DeviceGroupModel>> fetchGroups() async {
    if (_groupsFromLastFleet.isNotEmpty) {
      return List<DeviceGroupModel>.from(_groupsFromLastFleet);
    }

    final String server = await AuthService.server();
    final String? token = await AuthService.token();
    if (!ApiConfig.usesRemoteApi(server) || token == null || token.isEmpty) {
      return _groupsFromPrefs();
    }

    try {
      final Uri uri = ApiConfig.getGroupsUri(server, token: token);
      final dynamic response = await ApiClient.get(uri, token: token);
      final List<DeviceGroupModel> fromApi = _parseGroupsFromTree(response);
      if (fromApi.isNotEmpty) {
        _groupsFromLastFleet = fromApi;
        return fromApi;
      }
    } catch (_) {}

    try {
      final Uri uri = ApiConfig.getGroupsUri(server);
      final dynamic response = await ApiClient.postFormRaw(
        uri,
        body: <String, dynamic>{'user_api_hash': token},
        token: token,
      );
      final List<DeviceGroupModel> fromPost = _parseGroupsFromTree(response);
      if (fromPost.isNotEmpty) {
        _groupsFromLastFleet = fromPost;
        return fromPost;
      }
    } catch (_) {}

    final List<DeviceGroupModel> fromPrefs = await _groupsFromPrefs();
    if (fromPrefs.isNotEmpty) {
      _groupsFromLastFleet = fromPrefs;
    }
    return fromPrefs;
  }

  static Future<List<DeviceGroupModel>> _groupsFromPrefs() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_fleetCacheKey);
      if (raw == null || raw.isEmpty) {
        return <DeviceGroupModel>[];
      }
      final dynamic decoded = jsonDecode(raw);
      return _parseGroupsFromTree(decoded);
    } catch (_) {
      return <DeviceGroupModel>[];
    }
  }

  static List<DeviceGroupModel> _parseGroupsFromTree(dynamic node) {
    final Map<int, DeviceGroupModel> byId = <int, DeviceGroupModel>{};
    _walkForGroups(node, byId);
    final List<DeviceGroupModel> list = byId.values.toList()
      ..sort((DeviceGroupModel a, DeviceGroupModel b) => a.name.compareTo(b.name));
    return list;
  }

  static void _walkForGroups(dynamic node, Map<int, DeviceGroupModel> target) {
    if (node is List) {
      for (final dynamic item in node) {
        _walkForGroups(item, target);
      }
      return;
    }
    if (node is! Map) {
      return;
    }

    final Map<String, dynamic> map = node.map(
      (Object? k, Object? v) => MapEntry(k.toString(), v),
    );

    final bool hasItems = map.containsKey('items');
    final String name = (map['title'] ?? map['name'] ?? map['group_name'] ?? '')
        .toString()
        .trim();
    final int? id = int.tryParse((map['id'] ?? map['group_id'] ?? '').toString());

    if (hasItems && name.isNotEmpty && id != null) {
      target[id] = DeviceGroupModel(id: id, name: name);
    }

    if (_looksLikeFlatGroup(map)) {
      final int? gid = int.tryParse((map['id'] ?? map['group_id'] ?? '').toString());
      final String gname =
          (map['title'] ?? map['name'] ?? map['group_name'] ?? '').toString().trim();
      if (gid != null && gname.isNotEmpty) {
        target[gid] = DeviceGroupModel(id: gid, name: gname);
      }
    }

    for (final dynamic value in map.values) {
      _walkForGroups(value, target);
    }
  }

  static bool _looksLikeFlatGroup(Map<String, dynamic> map) {
    if (map.containsKey('items') || map.containsKey('devices')) {
      return false;
    }
    final bool hasId =
        map.containsKey('id') || map.containsKey('group_id');
    final bool hasName = map.containsKey('title') ||
        map.containsKey('name') ||
        map.containsKey('group_name');
    return hasId && hasName;
  }
}
