import 'package:dio/dio.dart';
import 'package:campuscast/core/constants/app_config.dart';

class ApiClient {
  ApiClient._();

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl:        AppConfig.serverUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept':       'application/json',
      },
    ),
  );

  /// The shared Dio instance used by all API classes.
  static Dio get instance => _dio;
}
