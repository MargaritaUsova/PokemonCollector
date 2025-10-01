import 'dart:convert';
import 'package:http/http.dart' as http;

class NetworkClient {
  final String baseUrl;

  NetworkClient({required this.baseUrl});

  Future<http.Response> get(String path) async {
    final url = Uri.parse('$baseUrl$path');
    return await http.get(url, headers: {'Accept': 'application/json'});
  }

  Future<http.Response> getWithParams(String path, Map<String, String> params) async {
    final url = Uri.parse('$baseUrl$path').replace(queryParameters: params);
    return await http.get(url, headers: {'Accept': 'application/json'});
  }

  Future<http.Response> post(String path, {Map<String, dynamic>? body}) async {
    final url = Uri.parse('$baseUrl$path');
    return await http.post(url,
        headers: {'Content-Type': 'application/json'}, 
        body: body != null ? jsonEncode(body) : null);
  }
}
