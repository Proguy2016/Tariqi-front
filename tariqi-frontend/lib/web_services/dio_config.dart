import 'package:dio/dio.dart';
import 'package:tariqi/const/api_data/api_links.dart';
import 'package:tariqi/main.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;
  final authToken = sharedPreferences.getString("token");

  late Dio dio;

  DioClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiLinks.serverBaseUrl,
        connectTimeout: const Duration(seconds: 130),
        receiveTimeout: const Duration(seconds: 130),
        validateStatus: (status) => status != null && status < 500,
        headers: {
          // 'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      ),
    );

    // اختياري: إضافة Interceptors لعرض اللوج أو التعامل مع الأخطاء
    dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
      ),
    );
  }

  Dio get client => dio;
}
