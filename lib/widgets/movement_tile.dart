import 'package:flutter/material.dart';
import '../models/dashboard_data.dart';
import '../theme/app_theme.dart';

class MovementTile extends StatelessWidget {
  final Movimiento movimiento;

  const MovementTile({super.key, required this.movimiento});

  IconData _iconForCategory(String category) {
    switch (category) {
      case 'Alimentacion':
        return Icons.restaurant;
      case 'Transporte':
        return Icons.directions_car;
      case 'Vivienda':
        return Icons.home;
      case 'Salud':
        return Icons.local_hospital;
      case 'Entretenimiento':
        return Icons.movie;
      case 'Servicios':
        return Icons.electrical_services;
      default:
        return Icons.receipt_long;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              // Leading: circular icon container
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _iconForCategory(movimiento.category),
                  color: AppColors.accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Middle: description + category · date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movimiento.description,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          movimiento.category,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const Text(
                          ' · ',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          movimiento.date,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Trailing: amount
              Text(
                '\$${movimiento.amount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.rose,
                ),
              ),
            ],
          ),
        ),
        const Divider(
          height: 1,
          thickness: 1,
          color: AppColors.cardBorder,
          indent: 16,
          endIndent: 16,
        ),
      ],
    );
  }
}
