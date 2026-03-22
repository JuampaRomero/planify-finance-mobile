import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../providers/wallet_provider.dart';
import '../../models/gasto.dart';
import '../../services/api_service.dart';

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  final ApiService _api = ApiService();
  final ScrollController _scrollController = ScrollController();

  List<Gasto> _gastos = [];
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;
  int _page = 1;
  int _totalPages = 1;
  int _total = 0;
  double _resumenTotal = 0;

  // Filtros
  String? _categoriaFiltro;
  String? _tipoFiltro;
  String _searchText = '';
  final TextEditingController _searchController = TextEditingController();

  static const List<String> _categorias = [
    'Alimentacion',
    'Servicios',
    'Transporte',
    'Vivienda',
    'Salud',
    'Entretenimiento',
    'Educacion',
    'Tarjeta de credito',
    'Otros',
  ];

  static const List<String> _tipos = [
    'personal_variable',
    'personal_fixed',
    'credit_card',
  ];

  static const Map<String, String> _tipoLabels = {
    'personal_variable': 'Variable',
    'personal_fixed': 'Fijo',
    'credit_card': 'Tarjeta',
  };

  static Color _colorForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'alimentacion':
      case 'alimentación':
        return Colors.green;
      case 'servicios':
        return Colors.blue;
      case 'transporte':
        return Colors.orange;
      case 'vivienda':
        return Colors.purple;
      case 'salud':
        return Colors.red;
      case 'entretenimiento':
        return Colors.pink;
      case 'educacion':
      case 'educación':
        return Colors.teal;
      case 'tarjeta de credito':
      case 'tarjeta de crédito':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  static IconData _iconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'alimentacion':
      case 'alimentación':
        return Icons.restaurant;
      case 'servicios':
        return Icons.electrical_services;
      case 'transporte':
        return Icons.directions_car;
      case 'vivienda':
        return Icons.home;
      case 'salud':
        return Icons.local_hospital;
      case 'entretenimiento':
        return Icons.movie;
      case 'educacion':
      case 'educación':
        return Icons.school;
      case 'tarjeta de credito':
      case 'tarjeta de crédito':
        return Icons.credit_card;
      default:
        return Icons.receipt_long;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargar(reset: true);
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_loadingMore &&
        _page < _totalPages) {
      _cargarMas();
    }
  }

  int? _getUserId() {
    final provider = context.read<WalletProvider>();
    return provider.selectedUser?.id;
  }

  Future<void> _cargar({bool reset = false}) async {
    final userId = _getUserId();
    if (userId == null) return;

    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _page = 1;
        _gastos = [];
      });
    }

    try {
      final result = await _api.getHistorial(
        userId: userId,
        page: 1,
        categoria: _categoriaFiltro,
        tipo: _tipoFiltro,
        search: _searchText.isEmpty ? null : _searchText,
      );
      if (!mounted) return;
      setState(() {
        _gastos = result.gastos;
        _total = result.total;
        _totalPages = result.totalPages;
        _page = 1;
        _resumenTotal = result.resumenTotal;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _cargarMas() async {
    final userId = _getUserId();
    if (userId == null || _loadingMore || _page >= _totalPages) return;

    setState(() => _loadingMore = true);
    try {
      final nextPage = _page + 1;
      final result = await _api.getHistorial(
        userId: userId,
        page: nextPage,
        categoria: _categoriaFiltro,
        tipo: _tipoFiltro,
        search: _searchText.isEmpty ? null : _searchText,
      );
      if (!mounted) return;
      setState(() {
        _gastos.addAll(result.gastos);
        _page = nextPage;
        _totalPages = result.totalPages;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  Future<void> _eliminar(Gasto gasto) async {
    try {
      await _api.deleteGasto(gasto.id);
      if (!mounted) return;
      setState(() {
        _gastos.removeWhere((g) => g.id == gasto.id);
        _total = (_total - 1).clamp(0, _total);
        _resumenTotal = (_resumenTotal - gasto.amount).clamp(0, _resumenTotal);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Gasto eliminado'),
          backgroundColor: AppColors.surface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: AppColors.cardBorder),
          ),
        ),
      );
      // Refrescar dashboard en background
      final provider = context.read<WalletProvider>();
      final userId = provider.selectedUser?.id;
      if (userId != null) {
        provider.loadDashboard(userId);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar: $e'),
          backgroundColor: AppColors.rose,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _abrirFiltros() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _FiltrosSheet(
        categoriaActual: _categoriaFiltro,
        tipoActual: _tipoFiltro,
        categorias: _categorias,
        tipos: _tipos,
        tipoLabels: _tipoLabels,
        onAplicar: (cat, tipo) {
          Navigator.pop(ctx);
          setState(() {
            _categoriaFiltro = cat;
            _tipoFiltro = tipo;
          });
          _cargar(reset: true);
        },
        onLimpiar: () {
          Navigator.pop(ctx);
          setState(() {
            _categoriaFiltro = null;
            _tipoFiltro = null;
          });
          _cargar(reset: true);
        },
      ),
    );
  }

  String _formatFecha(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Consumer<WalletProvider>(
          builder: (context, provider, _) {
            if (provider.selectedUser == null && !provider.loading) {
              return const _EmptyState(
                icon: Icons.person_outline,
                message: 'Seleccioná un usuario en Mi Billetera para ver el historial.',
              );
            }

            return Column(
              children: [
                // Header
                _buildHeader(provider),
                // Barra de búsqueda
                _buildSearchBar(),
                // Resumen
                if (!_loading && _error == null)
                  _buildResumen(),
                // Lista
                Expanded(
                  child: _buildBody(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(WalletProvider provider) {
    final hasFiltros = _categoriaFiltro != null || _tipoFiltro != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'Histo',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    TextSpan(
                      text: 'rial',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                provider.selectedUser != null
                    ? provider.selectedUser!.name
                    : '',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Botón filtros
          GestureDetector(
            onTap: _abrirFiltros,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: hasFiltros
                    ? AppColors.accent.withOpacity(0.15)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: hasFiltros ? AppColors.accent : AppColors.cardBorder,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.tune,
                    color: hasFiltros ? AppColors.accent : AppColors.textSecondary,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    hasFiltros ? 'Filtros activos' : 'Filtrar',
                    style: TextStyle(
                      color: hasFiltros ? AppColors.accent : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Buscar por descripcion...',
          hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 18),
          suffixIcon: _searchText.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    setState(() => _searchText = '');
                    _cargar(reset: true);
                  },
                  child: const Icon(Icons.close, color: AppColors.textSecondary, size: 16),
                )
              : null,
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.cardBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.cardBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.accent.withOpacity(0.5)),
          ),
        ),
        onChanged: (val) {
          setState(() => _searchText = val);
          if (val.isEmpty) {
            _cargar(reset: true);
          }
        },
        onSubmitted: (_) => _cargar(reset: true),
        textInputAction: TextInputAction.search,
      ),
    );
  }

  Widget _buildResumen() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long, color: AppColors.accent, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '$_total transacciones',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.trending_down, color: AppColors.rose, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Total: \$${_resumenTotal.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.rose, size: 48),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.rose, fontSize: 14),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _cargar(reset: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.accent,
                  side: const BorderSide(color: AppColors.accent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_gastos.isEmpty) {
      return const _EmptyState(
        icon: Icons.inbox_outlined,
        message: 'No hay gastos registrados.',
      );
    }

    return RefreshIndicator(
      color: AppColors.accent,
      backgroundColor: AppColors.surface,
      onRefresh: () => _cargar(reset: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        itemCount: _gastos.length + (_loadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _gastos.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.accent,
                  strokeWidth: 2,
                ),
              ),
            );
          }
          final gasto = _gastos[index];
          return _GastoTile(
            gasto: gasto,
            formatFecha: _formatFecha,
            colorForCategory: _colorForCategory,
            iconForCategory: _iconForCategory,
            onDismissed: () => _eliminar(gasto),
          );
        },
      ),
    );
  }
}

// =============================================================================
// Tile de gasto con swipe-to-delete
// =============================================================================
class _GastoTile extends StatelessWidget {
  final Gasto gasto;
  final String Function(String) formatFecha;
  final Color Function(String) colorForCategory;
  final IconData Function(String) iconForCategory;
  final VoidCallback onDismissed;

  const _GastoTile({
    required this.gasto,
    required this.formatFecha,
    required this.colorForCategory,
    required this.iconForCategory,
    required this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    final catColor = colorForCategory(gasto.category);
    final catIcon = iconForCategory(gasto.category);

    return Dismissible(
      key: Key('gasto_${gasto.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.rose.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.rose.withOpacity(0.3)),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.rose, size: 22),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.cardBorder),
            ),
            title: const Text(
              'Eliminar gasto',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
            ),
            content: Text(
              'Se eliminara "${gasto.description}". Esta accion no se puede deshacer.',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Eliminar',
                  style: TextStyle(color: AppColors.rose, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (_) => onDismissed(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            // Icono categoria
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: catColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: catColor.withOpacity(0.25)),
              ),
              child: Icon(catIcon, color: catColor, size: 18),
            ),
            const SizedBox(width: 12),
            // Descripcion + chips
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gasto.description.isNotEmpty
                        ? gasto.description
                        : 'Sin descripcion',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: catColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          gasto.category,
                          style: TextStyle(
                            color: catColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        formatFecha(gasto.date),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Monto
            Text(
              '-\$${gasto.amount.toStringAsFixed(0)}',
              style: const TextStyle(
                color: AppColors.rose,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Empty State
// =============================================================================
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Bottom Sheet de Filtros
// =============================================================================
class _FiltrosSheet extends StatefulWidget {
  final String? categoriaActual;
  final String? tipoActual;
  final List<String> categorias;
  final List<String> tipos;
  final Map<String, String> tipoLabels;
  final void Function(String? categoria, String? tipo) onAplicar;
  final VoidCallback onLimpiar;

  const _FiltrosSheet({
    required this.categoriaActual,
    required this.tipoActual,
    required this.categorias,
    required this.tipos,
    required this.tipoLabels,
    required this.onAplicar,
    required this.onLimpiar,
  });

  @override
  State<_FiltrosSheet> createState() => _FiltrosSheetState();
}

class _FiltrosSheetState extends State<_FiltrosSheet> {
  String? _categoria;
  String? _tipo;

  @override
  void initState() {
    super.initState();
    _categoria = widget.categoriaActual;
    _tipo = widget.tipoActual;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Filtros',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          // Categoria
          const Text(
            'Categoria',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Theme(
            data: Theme.of(context).copyWith(canvasColor: AppColors.surface),
            child: DropdownButtonFormField<String>(
              value: _categoria,
              isExpanded: true,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
              ),
              hint: const Text(
                'Todas las categorias',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Todas'),
                ),
                ...widget.categorias.map(
                  (c) => DropdownMenuItem<String>(value: c, child: Text(c)),
                ),
              ],
              onChanged: (val) => setState(() => _categoria = val),
            ),
          ),
          const SizedBox(height: 16),
          // Tipo
          const Text(
            'Tipo de gasto',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('Todos'),
                selected: _tipo == null,
                onSelected: (_) => setState(() => _tipo = null),
                selectedColor: AppColors.accent.withOpacity(0.2),
                checkmarkColor: AppColors.accent,
                labelStyle: TextStyle(
                  color: _tipo == null ? AppColors.accent : AppColors.textSecondary,
                  fontSize: 12,
                ),
                backgroundColor: AppColors.background,
                side: BorderSide(
                  color: _tipo == null ? AppColors.accent : AppColors.cardBorder,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              ...widget.tipos.map((t) {
                final isSelected = _tipo == t;
                return FilterChip(
                  label: Text(widget.tipoLabels[t] ?? t),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _tipo = isSelected ? null : t),
                  selectedColor: AppColors.accent.withOpacity(0.2),
                  checkmarkColor: AppColors.accent,
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.accent : AppColors.textSecondary,
                    fontSize: 12,
                  ),
                  backgroundColor: AppColors.background,
                  side: BorderSide(
                    color: isSelected ? AppColors.accent : AppColors.cardBorder,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 24),
          // Botones
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onLimpiar,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.cardBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Limpiar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => widget.onAplicar(_categoria, _tipo),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Aplicar',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
