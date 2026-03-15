import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/dashboard_data.dart';
import '../services/api_service.dart';

class WalletProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<User> _users = [];
  User? _selectedUser;
  DashboardData? _dashboardData;
  bool _loading = false;
  String? _error;

  // ---------------------------------------------------------------------------
  // Getters públicos
  // ---------------------------------------------------------------------------
  List<User> get users => List.unmodifiable(_users);
  User? get selectedUser => _selectedUser;
  DashboardData? get dashboardData => _dashboardData;
  bool get loading => _loading;
  String? get error => _error;

  bool get hasError => _error != null;
  bool get hasData => _dashboardData != null;

  // ---------------------------------------------------------------------------
  // loadUsers: obtiene la lista de usuarios, selecciona el primero y carga
  //            su dashboard automáticamente.
  // ---------------------------------------------------------------------------
  Future<void> loadUsers() async {
    _setLoading(true);
    _clearError();

    try {
      _users = await _api.getUsers();

      if (_users.isNotEmpty) {
        _selectedUser = _users.first;
        await loadDashboard(_selectedUser!.id);
        return; // loadDashboard ya llama notifyListeners + setLoading(false)
      }

      notifyListeners();
    } catch (e) {
      _setError('Error al cargar usuarios: $e');
    } finally {
      // Solo apagamos el loading si loadDashboard no fue llamado
      // (lista vacía o error antes de llamarlo).
      if (_loading) _setLoading(false);
    }
  }

  // ---------------------------------------------------------------------------
  // selectUser: cambia el usuario seleccionado y recarga el dashboard.
  // ---------------------------------------------------------------------------
  Future<void> selectUser(User user) async {
    if (_selectedUser == user) return;
    _selectedUser = user;
    notifyListeners();
    await loadDashboard(user.id);
  }

  // ---------------------------------------------------------------------------
  // loadDashboard: carga los datos del dashboard para un userId dado.
  // ---------------------------------------------------------------------------
  Future<void> loadDashboard(int userId) async {
    _setLoading(true);
    _clearError();

    try {
      _dashboardData = await _api.getDashboardData(userId);
      notifyListeners();
    } catch (e) {
      _setError('Error al cargar el dashboard: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ---------------------------------------------------------------------------
  // registrarGasto: registra un nuevo gasto y recarga el dashboard.
  // ---------------------------------------------------------------------------
  Future<bool> registrarGasto({
    required int payerId,
    required String description,
    required double amount,
    required String category,
    String expenseType = 'personal_variable',
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final success = await _api.registrarGasto(
        payerId: payerId,
        description: description,
        amount: amount,
        category: category,
        expenseType: expenseType,
      );

      if (success && _selectedUser != null) {
        await loadDashboard(_selectedUser!.id);
      } else {
        _setLoading(false);
      }

      return success;
    } catch (e) {
      _setError('Error al registrar gasto: $e');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers privados
  // ---------------------------------------------------------------------------
  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _error = message;
    _loading = false;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }
}
