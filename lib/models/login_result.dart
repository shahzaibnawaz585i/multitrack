class LoginResult {
  const LoginResult({
    required this.success,
    required this.message,
    this.token,
    this.userId,
    this.name,
  });

  final bool success;
  final String message;
  final String? token;
  final String? userId;
  final String? name;

  factory LoginResult.failure(String message) {
    return LoginResult(success: false, message: message);
  }

  factory LoginResult.fromJson(
    Map<String, dynamic> json, {
    String? fallbackUserId,
  }) {
    final Map<String, dynamic> user = _asMap(json['user'] ?? json['data']);
    final Map<String, dynamic> items = _asMap(json['items']);
    final Object? status = json['status'] ?? json['success'];

    final String token = (json['token'] ??
            json['user_api_hash'] ??
            json['api_hash'] ??
            json['api_key'] ??
            json['accessToken'] ??
            json['access_token'] ??
            items['user_api_hash'] ??
            items['token'] ??
            user['token'] ??
            user['user_api_hash'] ??
            user['api_hash'] ??
            '')
        .toString()
        .trim();

    final bool success = status == true ||
        status == 1 ||
        status == '1' ||
        status == 'ok' ||
        status == 'success' ||
        (status != 0 && status != '0' && status != false && token.isNotEmpty);

    final String userId = (json['userId'] ??
            json['userid'] ??
            json['username'] ??
            json['email'] ??
            user['id'] ??
            user['userId'] ??
            user['userid'] ??
            user['username'] ??
            user['email'] ??
            fallbackUserId ??
            '')
        .toString()
        .trim();

    final String name = (json['name'] ??
            user['name'] ??
            user['username'] ??
            user['email'] ??
            userId)
        .toString()
        .trim();

    final String message = (json['message'] ??
            json['msg'] ??
            json['error'] ??
            (success ? 'Login successful' : 'Invalid User ID or Password'))
        .toString();

    return LoginResult(
      success: success && (userId.isNotEmpty || token.isNotEmpty),
      message: message,
      token: token.isEmpty ? null : token,
      userId: userId.isEmpty ? (fallbackUserId ?? 'user') : userId,
      name: name.isEmpty ? null : name,
    );
  }

  static Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map(
        (Object? key, Object? nested) => MapEntry(key.toString(), nested),
      );
    }
    return <String, dynamic>{};
  }
}
