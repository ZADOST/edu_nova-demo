import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../db/local_auth_db.dart';

class ApiClient {
  late final Dio _dio;

  ApiClient() {
    // ==========================================
    // ZAS TECH LOCAL DEPLOYMENT CONFIGURATION
    // ==========================================
    // Replace the IP below with your Surface Laptop's exact Wi-Fi IPv4 address.
    // Example: 'http://192.168.1.15/edu_nova_api/endpoints/'
    // Do NOT use 'http://localhost/' or 'http://127.0.0.1/' when deploying to a physical Xiaomi device.
    const String baseUrl = 'http://192.168.1.72/edu_nova_api/endpoints/';

    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15), // Slightly longer for local network testing
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Global Interceptor: Automatically attaches the user's session token to every request
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Retrieve the current session from the local Isar/SharedPreferences database
        final prefs = await SharedPreferences.getInstance();
        final authDb = LocalAuthDb(prefs);
        final token = authDb.authToken;
        
        // If a token exists, inject it into the Authorization header securely
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        // Optional: Handle global 401 Unauthorized errors here in the future
        return handler.next(e);
      },
    ));
  }

  // Generic POST request method
  Future<Response> post(String path, {Map<String, dynamic>? data}) async {
    return await _dio.post(path, data: data);
  }

  // Generic GET request method
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    return await _dio.get(path, queryParameters: queryParameters);
  }
}