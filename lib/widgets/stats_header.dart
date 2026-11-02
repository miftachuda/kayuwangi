import 'package:flutter/material.dart';
import 'package:kayuwangi/models/plant_model.dart';
import 'package:kayuwangi/utils/constants.dart';

class StatsHeader extends StatelessWidget {
  final List<PlantModel> plants;
  final VoidCallback? onMapTap;

  const StatsHeader({
    super.key,
    required this.plants,
    this.onMapTap,
  });

  @override
  Widget build(BuildContext context) {
    final total = plants.length;
    final healthy = plants.where((p) => p.kondisiTerkini.toLowerCase().contains('subur') || p.kondisiTerkini.toLowerCase().contains('sehat') || p.kondisiTerkini.toLowerCase().contains('baik')).length;
    final attention = total - healthy;

    double avgDays = 0;
    if (total > 0) {
      final totalDays = plants.fold<int>(0, (sum, p) => sum + p.usiaHari);
      avgDays = totalDays / total;
    }
    final avgMonths = (avgDays / 30).toStringAsFixed(1);

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.dashboard_customize_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Ringkasan Monitoring Kayuwangi',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              if (onMapTap != null)
                InkWell(
                  onTap: onMapTap,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.map_outlined, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Peta Lahan',
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildStatItem('Total', '$total', Icons.forest, Colors.white),
              _buildDivider(),
              _buildStatItem('Sehat', '$healthy', Icons.eco, const Color(0xFF81C784)),
              _buildDivider(),
              _buildStatItem('Perhatian', '$attention', Icons.warning_amber_rounded, const Color(0xFFFFB74D)),
              _buildDivider(),
              _buildStatItem('Rata2 Usia', '$avgMonths bln', Icons.timelapse, const Color(0xFF80DEEA)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 32,
      width: 1,
      color: Colors.white.withOpacity(0.2),
    );
  }
}
