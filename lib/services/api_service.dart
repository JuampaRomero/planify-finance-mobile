import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/dashboard_data.dart';
import '../models/gasto.dart';

class ApiService {
  static const String baseUrl = 'https://planifynance.up.railway.app/api';

  // Singleton
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // -------------------------------------------------------------------------
  // GET /api/users
  // -------------------------------------------------------------------------
  Future<List<User>> getUsers() async {
    final uri = Uri.parse('$baseUrl/users');
    try {
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        throw Exception(
          'Error al obtener usuarios: status ${response.statusCode}',
        );
      }
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      return data
          .map((e) => User.fromJson(e as Map<String, dynamic>))
          .toList();
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Error inesperado al obtener usuarios: $e');
    }
  }

  // -------------------------------------------------------------------------
  // GET /api/dashboard/:userId
  // -------------------------------------------------------------------------
  Future<DashboardData> getDashboardData(int userId) async {
    final uri = Uri.parse('$baseUrl/dashboard/$userId');
    try {
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        throw Exception(
          'Error al obtener el dashboard (userId: $userId): status ${response.statusCode}',
        );
      }
      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;
      return DashboardData.fromJson(data);
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Error inesperado al obtener el dashboard: $e');
    }
  }

  // -------------------------------------------------------------------------
  // GET /api/users/:userId/historial
  // -------------------------------------------------------------------------
  Future<HistorialResponse> getHistorial({
    required int userId,
    int page = 1,
    int limit = 20,
    String? categoria,
    String? tipo,
    String? search,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (categoria != null && categoria.isNotEmpty) {
      params['categoria'] = categoria;
    }
    if (tipo != null && tipo.isNotEmpty) {
      params['tipo'] = tipo;
    }
    if (search != null && search.isNotEmpty) {
      params['search'] = search;
    }

    final uri = Uri.parse('$baseUrl/users/$userId/historial')
        .replace(queryParameters: params);

    try {
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        throw Exception(
          'Error al obtener historial: status ${response.statusCode}',
        );
      }
      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;
      return HistorialResponse.fromJson(data);
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Error inesperado al obtener historial: $e');
    }
  }

  // -------------------------------------------------------------------------
  // DELETE /api/gastos/:id
  // -------------------------------------------------------------------------
  Future<void> deleteGasto(int gastoId) async {
    final uri = Uri.parse('$baseUrl/gastos/$gastoId');
    try {
      final response = await http.delete(uri);
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(
          'Error al eliminar gasto: status ${response.statusCode}',
        );
      }
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Error inesperado al eliminar gasto: $e');
    }
  }

  // -------------------------------------------------------------------------
  // POST /api/precios/consulta
  // -------------------------------------------------------------------------
  Future<String> consultarPrecios(
    String query,
    List<Map<String, String>> historial,
  ) async {
    final uri = Uri.parse('$baseUrl/precios/consulta');
    final body = jsonEncode({'query': query, 'historial': historial});

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Error al consultar precios: status ${response.statusCode}',
        );
      }

      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;
      return data['reply'] as String? ?? 'Sin respuesta.';
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Error inesperado al consultar precios: $e');
    }
  }

  // -------------------------------------------------------------------------
  // POST /api/gastos
  // -------------------------------------------------------------------------
  Future<bool> registrarGasto({
    required int payerId,
    required String description,
    required double amount,
    required String category,
    String expenseType = 'personal_variable',
  }) async {
    final uri = Uri.parse('$baseUrl/gastos');
    final body = jsonEncode({
      'payer_id': payerId,
      'description': description,
      'amount': amount,
      'category': category,
      'expense_type': expenseType,
    });

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(
          'Error al registrar gasto: status ${response.statusCode}',
        );
      }

      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;
      return data['success'] == true;
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Error inesperado al registrar gasto: $e');
    }
  }
}
