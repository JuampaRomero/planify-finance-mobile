import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../providers/wallet_provider.dart';
import '../../models/dashboard_data.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<WalletProvider>();
      if (provider.users.isEmpty) {
        provider.loadUsers();
      }
    });
  }

  String _formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(0)}';
  }

  String _formatAxisY(double value) {
    if (value >= 1000) {
      return '\$${(value / 1000).toStringAsFixed(0)}k';
    }
    return '\$${value.toStringAsFixed(0)}';
  }

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'alimentacion':
      case 'alimentación':
        return Icons.restaurant;
      case 'transporte':
        return Icons.directions_car;
      case 'vivienda':
        return Icons.home;
      case 'salud':
        return Icons.local_hospital;
      case 'entretenimiento':
        return Icons.movie;
      case 'servicios':
        return Icons.electrical_services;
      default:
        return Icons.receipt_long;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Consumer<WalletProvider>(
          builder: (context, provider, _) {
            if (provider.loading) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppColors.accent,
                ),
              );
            }

            if (provider.error != null) {
              return _ErrorView(
                message: provider.error!,
                onRetry: () => provider.loadUsers(),
              );
            }

            final data = provider.dashboardData;

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _buildHeader(provider),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: data != null
                        ? _buildStatsRow(data)
                        : _buildStatsRowEmpty(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: _buildBarChartCard(data),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                    child: _buildRecentActivityCard(data),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------
  Widget _buildHeader(WalletProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'Plani',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    TextSpan(
                      text: 'Fy',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    TextSpan(
                      text: ' Finance',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 26,
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (provider.selectedUser != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person_outline,
                          color: AppColors.accent, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        provider.selectedUser!.name,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Dashboard General',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Stats Row — con datos
  // ---------------------------------------------------------------------------
  Widget _buildStatsRow(DashboardData data) {
    final marginColor = data.margin >= 0 ? AppColors.green : AppColors.rose;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.trending_down,
            iconColor: AppColors.accent,
            label: 'Gastos del mes',
            value: _formatCurrency(data.totalSpent),
            valueColor: AppColors.accent,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.savings_outlined,
            iconColor: marginColor,
            label: 'Tu margen',
            value: _formatCurrency(data.margin),
            valueColor: marginColor,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.account_balance_outlined,
            iconColor: AppColors.textSecondary,
            label: 'Tu salario',
            value: _formatCurrency(data.salary),
            valueColor: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Stats Row — vacío (sin datos cargados aún)
  // ---------------------------------------------------------------------------
  Widget _buildStatsRowEmpty() {
    return Row(
      children: List.generate(3, (i) => Expanded(
        child: Container(
          margin: EdgeInsets.only(right: i < 2 ? 10 : 0),
          height: 90,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
        ),
      )),
    );
  }

  // ---------------------------------------------------------------------------
  // Bar Chart Card
  // ---------------------------------------------------------------------------
  Widget _buildBarChartCard(DashboardData? data) {
    final categories = data?.categories ?? [];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bar_chart_rounded,
                    color: AppColors.accent, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Gastos por categoría',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (categories.isEmpty)
              _EmptyState(
                icon: Icons.bar_chart_outlined,
                message: 'Sin movimientos este mes',
              )
            else
              SizedBox(
                height: 200,
                child: _CategoryBarChart(
                  categories: categories,
                  formatAxisY: _formatAxisY,
                  formatCurrency: _formatCurrency,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Recent Activity Card
  // ---------------------------------------------------------------------------
  Widget _buildRecentActivityCard(DashboardData? data) {
    final movimientos = data?.movimientos ?? [];
    final recent = movimientos.take(5).toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.receipt_long_outlined,
                    color: AppColors.accent, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Actividad reciente',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (recent.isEmpty)
              _EmptyState(
                icon: Icons.inbox_outlined,
                message: 'Sin actividad reciente',
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recent.length,
                separatorBuilder: (_, __) => const Divider(
                  color: AppColors.cardBorder,
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  final mov = recent[index];
                  return _MovimientoTile(
                    movimiento: mov,
                    icon: _categoryIcon(mov.category),
                    formatCurrency: _formatCurrency,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Stat Card
// =============================================================================
class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color valueColor;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Category Bar Chart
// =============================================================================
class _CategoryBarChart extends StatefulWidget {
  final List<CategoryData> categories;
  final String Function(double) formatAxisY;
  final String Function(double) formatCurrency;

  const _CategoryBarChart({
    required this.categories,
    required this.formatAxisY,
    required this.formatCurrency,
  });

  @override
  State<_CategoryBarChart> createState() => _CategoryBarChartState();
}

class _CategoryBarChartState extends State<_CategoryBarChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final maxValue = widget.categories
        .map((c) => c.value)
        .reduce((a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        maxY: maxValue * 1.25,
        barTouchData: BarTouchData(
          enabled: true,
          touchCallback: (event, response) {
            setState(() {
              if (response?.spot != null &&
                  event is! FlTapUpEvent &&
                  event is! FlPanEndEvent) {
                _touchedIndex = response!.spot!.touchedBarGroupIndex;
              } else {
                _touchedIndex = -1;
              }
            });
          },
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppColors.cardBorder,
            tooltipRoundedRadius: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final cat = widget.categories[groupIndex];
              return BarTooltipItem(
                '${cat.name}\n',
                const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                children: [
                  TextSpan(
                    text: widget.formatCurrency(rod.toY),
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    widget.formatAxisY(value),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.right,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= widget.categories.length) {
                  return const SizedBox.shrink();
                }
                final name = widget.categories[index].name;
                final truncated = name.length > 6 ? name.substring(0, 6) : name;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    truncated,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxValue > 0 ? maxValue / 4 : 1,
          getDrawingHorizontalLine: (_) => const FlLine(
            color: AppColors.cardBorder,
            strokeWidth: 1,
            dashArray: [4, 4],
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(widget.categories.length, (index) {
          final cat = widget.categories[index];
          final isTouched = index == _touchedIndex;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: cat.value,
                color: isTouched
                    ? AppColors.accent
                    : AppColors.accent.withOpacity(0.75),
                width: 18,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxValue * 1.25,
                  color: AppColors.accent.withOpacity(0.05),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// =============================================================================
// Movimiento Tile
// =============================================================================
class _MovimientoTile extends StatelessWidget {
  final Movimiento movimiento;
  final IconData icon;
  final String Function(double) formatCurrency;

  const _MovimientoTile({
    required this.movimiento,
    required this.icon,
    required this.formatCurrency,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.accent.withOpacity(0.2),
              ),
            ),
            child: Icon(icon, color: AppColors.accent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movimiento.description,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  movimiento.date,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '-${formatCurrency(movimiento.amount)}',
            style: const TextStyle(
              color: AppColors.rose,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 36),
            const SizedBox(height: 10),
            Text(
              message,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Error View
// =============================================================================
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.rose, size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.rose,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.accent,
                side: const BorderSide(color: AppColors.accent),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text(
                'Reintentar',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
