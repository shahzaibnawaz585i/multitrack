import 'dart:convert';
import 'dart:io';

/// Standalone MultiTrack API server.
/// Run: dart run server/login_api.dart
///
/// Endpoints:
/// POST /api/login
/// { "userId": "mtdemo1", "password": "123456" }
///
/// GET /api/get_devices
Future<void> main() async {
  final HttpServer server =
      await HttpServer.bind(InternetAddress.anyIPv4, 8080);
  stdout.writeln('MultiTrack API listening on http://0.0.0.0:8080');

  const Map<String, String> accounts = <String, String>{
    'mtdemo1': '123456',
    'admin@gmail.com': 'admin123',
  };

  await for (final HttpRequest request in server) {
    _addCors(request.response);

    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.noContent;
      await request.response.close();
      continue;
    }

    if (request.method == 'POST' && request.uri.path == '/api/login') {
      final String body = await utf8.decodeStream(request);
      Map<String, dynamic> json = <String, dynamic>{};
      try {
        if (body.isNotEmpty) {
          final Object? decoded = jsonDecode(body);
          if (decoded is Map<String, dynamic>) {
            json = decoded;
          }
        }
      } catch (_) {
        // Try form url encoded
        try {
          final Uri queryUri = Uri.parse('?$body');
          json = queryUri.queryParameters;
        } catch (_) {}
      }

      final String userId =
          (json['userId'] ?? json['username'] ?? json['email'] ?? '')
              .toString()
              .trim()
              .toLowerCase();
      final String password = (json['password'] ?? '').toString();
      final String? expected = accounts[userId];

      request.response.headers.contentType = ContentType.json;
      if (expected == null || expected != password) {
        request.response.statusCode = HttpStatus.unauthorized;
        request.response.write(
          jsonEncode(<String, dynamic>{
            'status': 0,
            'success': false,
            'message': 'Invalid User ID or Password',
          }),
        );
      } else {
        request.response.statusCode = HttpStatus.ok;
        request.response.write(
          jsonEncode(<String, dynamic>{
            'status': 1,
            'success': true,
            'message': 'Login successful',
            'user_api_hash': 'mt_${userId}_${DateTime.now().millisecondsSinceEpoch}',
            'token': 'mt_${userId}_${DateTime.now().millisecondsSinceEpoch}',
            'user': <String, String>{
              'id': userId,
              'name': userId == 'admin@gmail.com' ? 'Admin' : userId,
            },
          }),
        );
      }
      await request.response.close();
      continue;
    }

    if (request.uri.path == '/api/get_devices') {
      request.response.headers.contentType = ContentType.json;
      request.response.statusCode = HttpStatus.ok;
      request.response.write(
        jsonEncode(<Map<String, dynamic>>[
          {
            'name': 'RJ14TF1654',
            'status': 'RUNNING',
            'online': 'online',
            'speed': '17',
            'distance': '0 km',
            'time': 'since 0d 0h 35m',
            'liveTime': '08:06:59 PM',
            'location': 'Heading towards Lower Mall, Anarkali, Lahore',
            'date': 'Sep 04, 2025',
          },
          {
            'name': 'PB11DD9661',
            'status': 'STOPPED',
            'online': 'offline',
            'speed': '00',
            'distance': '0 km',
            'time': 'since 0d 2h 52m',
            'liveTime': '02:26:27 PM',
            'location':
                'گلشن راو، لاہور City Tehsil, Lahore District, Punjab, Pakistan',
            'date': 'Sep 04, 2025',
          },
          {
            'name': 'RK15OK8551',
            'status': 'STOPPED',
            'online': 'offline',
            'speed': '00',
            'distance': '0 km',
            'time': 'since 0d 0h 55m',
            'liveTime': '02:26:27 PM',
            'location': 'Liberty Market Parking, Lahore',
            'date': 'Sep 04, 2025',
          },
          {
            'name': 'RJ14TF1654',
            'status': 'RUNNING',
            'online': 'online',
            'speed': '17',
            'distance': '0 km',
            'time': 'since 0d 0h 35m',
            'liveTime': '08:06:59 PM',
            'location': 'Heading towards Lower Mall, Anarkali, Lahore',
            'date': 'Sep 04, 2025',
            'lat': 31.5732,
            'lng': 74.3089,
          },
          {
            'name': 'PB11DD9661',
            'status': 'STOPPED',
            'online': 'offline',
            'speed': '00',
            'distance': '0 km',
            'time': 'since 0d 2h 52m',
            'liveTime': '02:26:27 PM',
            'location':
                'گلشن راو، لاہور City Tehsil, Lahore District, Punjab, Pakistan',
            'date': 'Sep 04, 2025',
            'lat': 31.5124,
            'lng': 74.3312,
          },
          {
            'name': 'RK15OK8551',
            'status': 'STOPPED',
            'online': 'offline',
            'speed': '00',
            'distance': '0 km',
            'time': 'since 0d 0h 55m',
            'liveTime': '02:26:27 PM',
            'location': 'Liberty Market Parking, Lahore',
            'date': 'Sep 04, 2025',
            'lat': 31.5115,
            'lng': 74.3448,
          },
          {
            'name': 'BR09GB6140',
            'status': 'Not Reporting',
            'online': 'offline',
            'speed': '00',
            'distance': '0 km',
            'time': 'since 0d 0h 45m',
            'liveTime': '02:26:27 PM',
            'location': 'Mall Road, Near Regal Chowk, Lahore',
            'date': 'Sep 04, 2025',
            'lat': 31.5204,
            'lng': 74.3587,
          },
          {
            'name': 'KL45Q8460',
            'status': 'Not Reporting',
            'online': 'offline',
            'speed': '00',
            'distance': '0 km',
            'time': 'since 0d 0h 45m',
            'liveTime': '02:26:27 PM',
            'location': 'Model Town Link Road, Lahore',
            'date': 'Sep 04, 2025',
            'lat': 31.4812,
            'lng': 74.3031,
          },
          {
            'name': 'RJ01RB3996',
            'status': 'Not Reporting',
            'online': 'offline',
            'speed': '00',
            'distance': '0 km',
            'time': 'since 0d 1h 10m',
            'liveTime': '02:26:27 PM',
            'location': 'Johar Town Phase 2, Lahore',
            'date': 'Sep 04, 2025',
            'lat': 31.4697,
            'lng': 74.2728,
          },
          {
            'name': 'RJ14OK8241',
            'status': 'Not Reporting',
            'online': 'offline',
            'speed': '00',
            'distance': '0 km',
            'time': 'since 0d 3h 20m',
            'liveTime': '02:26:27 PM',
            'location': 'Gulberg III, Main Boulevard, Lahore',
            'date': 'Sep 04, 2025',
            'lat': 31.5312,
            'lng': 74.3540,
          },
          {
            'name': 'MH12RK8741',
            'status': 'EXPIRED',
            'online': 'expire',
            'speed': '00',
            'distance': '0 km',
            'time': '389d 20h 40m',
            'liveTime': '02:26:27 PM',
            'location': 'Railway Station Circle, Lahore',
            'date': 'Sep 04, 2025',
            'validity': '163 Days Validity',
            'lat': 31.5546,
            'lng': 74.3572,
          },
          {
            'name': '5612',
            'status': 'EXPIRED',
            'online': 'expire',
            'speed': '00',
            'distance': '0 km',
            'time': 'since 118d 20h 40m',
            'liveTime': '02:26:27 PM',
            'location': 'DHA Phase 5 Commercial Area, Lahore',
            'date': 'Sep 04, 2025',
            'validity': '163 Days Validity',
            'lat': 31.4705,
            'lng': 74.4103,
          },
        ]),
      );
      await request.response.close();
      continue;
    }

    request.response.statusCode = HttpStatus.notFound;
    request.response.headers.contentType = ContentType.json;
    request.response.write(
      jsonEncode(<String, dynamic>{
        'success': false,
        'message': 'Not found',
      }),
    );
    await request.response.close();
  }
}

void _addCors(HttpResponse response) {
  response.headers.set('Access-Control-Allow-Origin', '*');
  response.headers.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  response.headers.set(
    'Access-Control-Allow-Headers',
    'Content-Type, Authorization',
  );
}
