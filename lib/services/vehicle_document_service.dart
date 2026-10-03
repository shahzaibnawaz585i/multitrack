import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_config.dart';
import '../models/vehicle_document_model.dart';
import 'api_client.dart';
import 'auth_service.dart';

class VehicleDocumentService {
  VehicleDocumentService._();

  static String _storageKey(int deviceId) =>
      'vehicle_documents_device_$deviceId';

  static Future<List<VehicleDocumentModel>> fetchDocuments(
    int deviceId,
  ) async {
    final List<VehicleDocumentModel> fromApi =
        await _fetchFromApi(deviceId);
    if (fromApi.isNotEmpty) {
      await _saveLocal(deviceId, fromApi);
      return fromApi;
    }

    final List<VehicleDocumentModel> fromFleet =
        await _fetchFromFleetCache(deviceId);
    if (fromFleet.isNotEmpty) {
      await _saveLocal(deviceId, fromFleet);
      return fromFleet;
    }

    return _loadLocal(deviceId);
  }

  static Future<bool> saveDocument({
    required int deviceId,
    required VehicleDocumentModel document,
    File? imageFile,
  }) async {
    final bool apiSaved = await _uploadToApi(
      deviceId: deviceId,
      document: document,
      imageFile: imageFile,
    );

    final List<VehicleDocumentModel> current =
        await fetchDocuments(deviceId);
    final List<VehicleDocumentModel> updated = <VehicleDocumentModel>[
      document,
      ...current.where((VehicleDocumentModel d) => d.id != document.id),
    ];
    await _saveLocal(deviceId, updated);
    return apiSaved;
  }

  static Future<void> deleteDocument({
    required int deviceId,
    required String documentId,
  }) async {
    await _deleteFromApi(deviceId: deviceId, documentId: documentId);
    final List<VehicleDocumentModel> current =
        await fetchDocuments(deviceId);
    final List<VehicleDocumentModel> updated = current
        .where((VehicleDocumentModel d) => d.id != documentId)
        .toList();
    await _saveLocal(deviceId, updated);
  }

  static Future<List<VehicleDocumentModel>> _fetchFromApi(int deviceId) async {
    final String? token = await AuthService.token();
    final String server = await AuthService.server();
    if (token == null ||
        token.isEmpty ||
        !ApiConfig.usesRemoteApi(server)) {
      return <VehicleDocumentModel>[];
    }

    final List<Uri> uris = <Uri>[
      ApiConfig.getDeviceDocumentsUri(server, token: token, deviceId: deviceId),
      ApiConfig.apiUri(
        server,
        ApiConfig.getDeviceDocumentsPath,
        token: token,
      ),
    ];

    for (final Uri uri in uris) {
      try {
        final dynamic response = await ApiClient.get(uri, token: token);
        final List<VehicleDocumentModel> parsed = _parseList(response);
        if (parsed.isNotEmpty) {
          return parsed;
        }
      } catch (_) {}
    }

    try {
      final dynamic response = await ApiClient.postFormRaw(
        ApiConfig.getDeviceDocumentsUri(server),
        body: <String, dynamic>{
          'user_api_hash': token,
          'device_id': deviceId.toString(),
        },
        token: token,
      );
      return _parseList(response);
    } catch (_) {}

    return <VehicleDocumentModel>[];
  }

  static Future<List<VehicleDocumentModel>> _fetchFromFleetCache(
    int deviceId,
  ) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString('vehicle_service_get_devices_v1');
      if (raw == null || raw.isEmpty) {
        return <VehicleDocumentModel>[];
      }
      final dynamic decoded = jsonDecode(raw);
      final Map<String, dynamic>? deviceMap =
          _findDeviceMap(decoded, deviceId);
      if (deviceMap == null) {
        return <VehicleDocumentModel>[];
      }
      return _parseList(
        deviceMap['documents'] ??
            deviceMap['device_documents'] ??
            deviceMap['docs'],
      );
    } catch (_) {
      return <VehicleDocumentModel>[];
    }
  }

  static Map<String, dynamic>? _findDeviceMap(dynamic node, int deviceId) {
    if (node is Map) {
      final Map<String, dynamic> map = node.map(
        (Object? k, Object? v) => MapEntry(k.toString(), v),
      );
      final int? id = int.tryParse((map['id'] ?? '').toString());
      if (id == deviceId) {
        return map;
      }
      for (final dynamic value in map.values) {
        final Map<String, dynamic>? found = _findDeviceMap(value, deviceId);
        if (found != null) {
          return found;
        }
      }
    } else if (node is List) {
      for (final dynamic item in node) {
        final Map<String, dynamic>? found = _findDeviceMap(item, deviceId);
        if (found != null) {
          return found;
        }
      }
    }
    return null;
  }

  static List<VehicleDocumentModel> _parseList(dynamic node) {
    final List<VehicleDocumentModel> list = <VehicleDocumentModel>[];
    if (node == null) {
      return list;
    }
    if (node is List) {
      for (final dynamic item in node) {
        if (item is Map) {
          final Map<String, dynamic> map = item.map(
            (Object? k, Object? v) => MapEntry(k.toString(), v),
          );
          list.add(VehicleDocumentModel.fromJson(map));
        }
      }
      return list;
    }
    if (node is Map) {
      final dynamic items = node['items'] ?? node['documents'] ?? node['data'];
      if (items != null) {
        return _parseList(items);
      }
      for (final dynamic value in node.values) {
        if (value is Map || value is List) {
          list.addAll(_parseList(value));
        }
      }
    }
    return list;
  }

  static Future<bool> _uploadToApi({
    required int deviceId,
    required VehicleDocumentModel document,
    File? imageFile,
  }) async {
    final String? token = await AuthService.token();
    final String server = await AuthService.server();
    if (token == null ||
        token.isEmpty ||
        !ApiConfig.usesRemoteApi(server)) {
      return false;
    }

    final Map<String, String> fields = <String, String>{
      'user_api_hash': token,
      'device_id': deviceId.toString(),
      'name': document.documentType,
      'type': document.documentType,
      'document_id': document.documentId,
      'doc_id': document.documentId,
      'remarks': document.remarks,
      if (document.expiryDate != null)
        'expiry_date': document.expiryDate!.toIso8601String().split('T').first,
    };

    final List<Uri> uris = <Uri>[
      ApiConfig.addDeviceDocumentUri(server),
      ApiConfig.apiUri(server, ApiConfig.addDeviceDocumentPath),
    ];

    for (final Uri uri in uris) {
      try {
        if (imageFile != null && await imageFile.exists()) {
          final http.MultipartRequest request =
              http.MultipartRequest('POST', uri);
          request.fields.addAll(fields);
          request.files.add(
            await http.MultipartFile.fromPath('image', imageFile.path),
          );
          final http.StreamedResponse streamed = await request.send();
          final String body = await streamed.stream.bytesToString();
          if (streamed.statusCode >= 200 && streamed.statusCode < 300) {
            return true;
          }
          if (body.contains('success') || body.contains('"status":1')) {
            return true;
          }
        } else {
          final dynamic response = await ApiClient.postFormRaw(
            uri,
            body: fields,
            token: token,
          );
          if (_isSuccess(response)) {
            return true;
          }
        }
      } catch (_) {}
    }
    return false;
  }

  static Future<void> _deleteFromApi({
    required int deviceId,
    required String documentId,
  }) async {
    final String? token = await AuthService.token();
    final String server = await AuthService.server();
    if (token == null ||
        token.isEmpty ||
        !ApiConfig.usesRemoteApi(server)) {
      return;
    }

    try {
      await ApiClient.postFormRaw(
        ApiConfig.destroyDeviceDocumentUri(server),
        body: <String, dynamic>{
          'user_api_hash': token,
          'device_id': deviceId.toString(),
          'id': documentId,
          'document_id': documentId,
        },
        token: token,
      );
    } catch (_) {}
  }

  static bool _isSuccess(dynamic response) {
    if (response is Map) {
      final dynamic status = response['status'];
      if (status == 1 || status == true || status == '1') {
        return true;
      }
      if (response['success'] == true) {
        return true;
      }
    }
    return false;
  }

  static Future<List<VehicleDocumentModel>> _loadLocal(int deviceId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_storageKey(deviceId));
    if (raw == null || raw.isEmpty) {
      return <VehicleDocumentModel>[];
    }
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map>()
          .map(
            (Map<dynamic, dynamic> m) => VehicleDocumentModel.fromJson(
              m.map((Object? k, Object? v) => MapEntry(k.toString(), v)),
            ),
          )
          .toList();
    } catch (_) {
      return <VehicleDocumentModel>[];
    }
  }

  static Future<void> _saveLocal(
    int deviceId,
    List<VehicleDocumentModel> docs,
  ) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> encoded =
        docs.map((VehicleDocumentModel d) => d.toJson()).toList();
    await prefs.setString(_storageKey(deviceId), jsonEncode(encoded));
  }
}
