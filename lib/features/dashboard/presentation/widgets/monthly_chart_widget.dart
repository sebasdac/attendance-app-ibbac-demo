import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/dashboard_models.dart';

class MonthlyChartWidget extends StatelessWidget {
  final List<MonthlyAttendance> monthlyAttendance;

  const MonthlyChartWidget({super.key, required this.monthlyAttendance});

  @override
  Widget build(BuildContext context) {
    if (monthlyAttendance.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Text('📊', style: TextStyle(fontSize: 48)),
            SizedBox(height: 8),
            Text(
              'No hay datos para mostrar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Los datos aparecerán cuando haya registros de asistencia',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    final maxCount = monthlyAttendance
        .map((e) => e.count)
        .fold(0, (max, current) => current > max ? current : max);

    final maxDisplay = maxCount == 0 ? 10 : (maxCount * 1.2).ceil();

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: monthlyAttendance.map((item) {
              final heightFactor = maxDisplay == 0
                  ? 0.0
                  : (item.count / maxDisplay);

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (item.count > 0)
                        Text(
                          '${item.count}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      const SizedBox(height: 4),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOut,
                        height: (140 * heightFactor).clamp(4.0, 140.0),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF6366F1),
                              const Color(0xFF6366F1).withValues(alpha: 0.6),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.month,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
