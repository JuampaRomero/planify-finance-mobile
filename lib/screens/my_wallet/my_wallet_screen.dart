import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../providers/wallet_provider.dart';
import '../../models/user.dart';
import '../../models/dashboard_data.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/movement_tile.dart';

class MyWalletScreen extends StatefulWidget {
  const MyWalletScreen({super.key});

  @override
  State<MyWalletScreen> createState() => _MyWalletScreenState();
}

class _MyWalletScreenState extends State<MyWalletScreen> {
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

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // a) Header con selector de usuario
                  _UserHeader(
                    provider: provider,
                  ),
                  const SizedBox(height: 20),

                  if (provider.dashboardData != null) ...[
                    // b) Card de salario destacado
                    _SalaryCard(data: provider.dashboardData!),
                    const SizedBox(height: 16),

                    // c) Grid 2x2 de StatCards
                    _StatsGrid(data: provider.dashboardData!),
                    const SizedBox(height: 16),

                    // d) Pie Chart
                    _PieChartCard(data: provider.dashboardData!),
                    const SizedBox(height: 16),

                    // e) Lista de movimientos
                    _MovimientosCard(data: provider.dashboardData!),
                    const SizedBox(height: 24),
                  ] else ...[
                    const SizedBox(height: 80),
                    const Center(
                      child: Text(
                        'Seleccioná un usuario para ver sus datos.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header con avatar + info + dropdown de usuario
// ---------------------------------------------------------------------------
class _UserHeader extends StatelessWidget {
  final WalletProvider provider;

  const _UserHeader({required this.provider});

  @override
  Widget build(BuildContext context) {
    final user = provider.selectedUser;
    final initial = user != null && user.name.isNotEmpty
        ? user.name[0].toUpperCase()
        : '?';

    return Row(
      children: [
        // Avatar circular con inicial
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            initial,
            style: const TextStyle(
              color: AppColors.accent,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Nombre + subtítulo
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user?.name ?? 'Sin usuario',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'Mi billetera',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const Spacer(),
        // Dropdown para cambiar usuario
        if (provider.users.isNotEmpty)
          Theme(
            data: Theme.of(context).copyWith(
              canvasColor: AppColors.surface,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<User>(
                value: provider.selectedUser,
                isDense: true,
                iconEnabledColor: AppColors.textSecondary,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                ),
                items: provider.users.map((u) {
                  return DropdownMenuItem<User>(
                    value: u,
                    child: Text(u.name),
                  );
                }).toList(),
                onChanged: (User? u) {
                  if (u != null) {
                    context.read<WalletProvider>().selectUser(u);
                  }
                },
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Card de salario destacado
// ---------------------------------------------------------------------------
class _SalaryCard extends StatelessWidget {
  final DashboardData data;

  const _SalaryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final isPositive = data.margin >= 0;
    final marginColor = isPositive ? AppColors.green : AppColors.rose;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.surface,
            AppColors.accent.withOpacity(0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tu salario mensual',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '\$${data.salary.toStringAsFixed(0)}',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Disponible: \$${data.margin.toStringAsFixed(0)}',
            style: TextStyle(
              color: marginColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Grid 2x2 de StatCards
// ---------------------------------------------------------------------------
class _StatsGrid extends StatelessWidget {
  final DashboardData data;

  const _StatsGrid({required this.data});

  @override
  Widget build(BuildContext context) {
    final isMarginPositive = data.margin >= 0;
    final marginColor = isMarginPositive ? AppColors.green : AppColors.rose;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: 'Gastos Fijos',
                value: '\$${data.fixedExpenses.toStringAsFixed(0)}',
                icon: Icons.home_outlined,
                valueColor: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                label: 'Tarjeta',
                value: '\$${data.creditCard.toStringAsFixed(0)}',
                icon: Icons.credit_card,
                valueColor: AppColors.rose,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: 'Variable',
                value: '\$${data.variableExpenses.toStringAsFixed(0)}',
                icon: Icons.shopping_bag_outlined,
                valueColor: AppColors.amber,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                label: 'Margen libre',
                value: '${data.marginPercentage.toStringAsFixed(0)}%',
                icon: Icons.savings_outlined,
                valueColor: marginColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Pie Chart "Tu consumo este mes"
// ---------------------------------------------------------------------------
class _PieChartCard extends StatefulWidget {
  final DashboardData data;

  const _PieChartCard({required this.data});

  @override
  State<_PieChartCard> createState() => _PieChartCardState();
}

class _PieChartCardState extends State<_PieChartCard> {
  int? _touchedIndex;

  static const List<Color> _chartColors = [
    AppColors.accent,
    AppColors.green,
    AppColors.purple,
    AppColors.rose,
    AppColors.amber,
  ];

  Color _colorForIndex(int index) => _chartColors[index % _chartColors.length];

  @override
  Widget build(BuildContext context) {
    final categories = widget.data.categories;
    final variableExpenses = widget.data.variableExpenses;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.cardBorder, width: 1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tu consumo este mes',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (categories.isEmpty)
            SizedBox(
              height: 200,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.pie_chart_outline,
                      color: AppColors.textSecondary,
                      size: 48,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Sin gastos este mes',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            SizedBox(
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 50,
                      pieTouchData: PieTouchData(
                        touchCallback: (event, response) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                response == null ||
                                response.touchedSection == null) {
                              _touchedIndex = null;
                              return;
                            }
                            _touchedIndex = response
                                .touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      sections: List.generate(categories.length, (i) {
                        final cat = categories[i];
                        final isTouched = i == _touchedIndex;
                        final color = _colorForIndex(i);
                        final radius = isTouched ? 80.0 : 70.0;

                        return PieChartSectionData(
                          color: color,
                          value: cat.value,
                          radius: radius,
                          title: isTouched ? cat.name : '',
                          titleStyle: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          badgeWidget: null,
                        );
                      }),
                    ),
                  ),
                  // Centro del donut
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Gastos',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        '\$${variableExpenses.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Leyenda
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: List.generate(categories.length, (i) {
                final cat = categories[i];
                final color = _colorForIndex(i);
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${cat.name} \$${cat.value.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Lista de movimientos
// ---------------------------------------------------------------------------
class _MovimientosCard extends StatelessWidget {
  final DashboardData data;

  const _MovimientosCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final movimientos = data.movimientos;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.cardBorder, width: 1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Últimos movimientos',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (movimientos.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Text(
                'Sin movimientos registrados',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: movimientos.length,
              itemBuilder: (context, index) {
                return MovementTile(movimiento: movimientos[index]);
              },
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Vista de error
// ---------------------------------------------------------------------------
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.rose,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.background,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
