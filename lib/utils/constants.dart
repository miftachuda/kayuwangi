import 'package:flutter/material.dart';

class AppConstants {
  // PocketBase configuration
  static const String defaultPocketBaseUrl = 'https://base.loc-2.com';
  static const String collectionName = 'kayuwangi';
  static const String keyPocketBaseUrl = 'pb_base_url';

  // App Title
  static const String appName = 'Kayuwangi Monitoring';
  static const String appTagline = 'Smart Geotagging & Plant Surveillance';

  // Theme Colors
  static const Color primaryGreen = Color(0xFF1B5E20);      // Forest green
  static const Color primaryLight = Color(0xFF4CAF50);      // Leaf green
  static const Color accentGreen = Color(0xFF2E7D32);
  static const Color darkBg = Color(0xFF121212);
  static const Color surfaceLight = Color(0xFFF7FBF7);
  static const Color cardBg = Colors.white;

  // Plant Conditions
  static const List<String> kondisiOptions = [
    'Subur & Sehat',
    'Cukup Baik',
    'Butuh Pengairan',
    'Butuh Pemupukan',
    'Menguning / Daun Rontok',
    'Terserang Hama / Penyakit',
    'Batang Rusak / Patah',
  ];

  // Common Plant Types for quick selection
  static const List<String> jenisTanamanOptions = [
    'Jati Emas (Tectona grandis)',
    'Mahoni Afrika (Khaya senegalensis)',
    'Sengon Laut (Falcataria moluccana)',
    'Trembesi (Samanea saman)',
    'Sonokeling (Dalbergia latifolia)',
    'Gaharu (Aquilaria microcarpa)',
    'Akasia (Acacia mangium)',
    'Kelapa Sawit (Elaeis guineensis)',
    'Kopi Robusta',
    'Karet (Hevea brasiliensis)',
    'Lainnya (Custom)',
  ];

  // Helper for status badge color
  static Color getStatusColor(String status) {
    switch (status) {
      case 'Subur & Sehat':
        return const Color(0xFF2E7D32); // Green
      case 'Cukup Baik':
        return const Color(0xFF00897B); // Teal
      case 'Butuh Pengairan':
        return const Color(0xFF0288D1); // Blue
      case 'Butuh Pemupukan':
        return const Color(0xFFF57C00); // Orange
      case 'Menguning / Daun Rontok':
        return const Color(0xFFE65100); // Amber/Deep Orange
      case 'Terserang Hama / Penyakit':
        return const Color(0xFFC62828); // Red
      case 'Batang Rusak / Patah':
        return const Color(0xFF880E4F); // Dark Red
      default:
        return const Color(0xFF546E7A); // Gray
    }
  }

  // Helper for status icon
  static IconData getStatusIcon(String status) {
    switch (status) {
      case 'Subur & Sehat':
        return Icons.eco;
      case 'Cukup Baik':
        return Icons.check_circle_outline;
      case 'Butuh Pengairan':
        return Icons.water_drop_outlined;
      case 'Butuh Pemupukan':
        return Icons.compost;
      case 'Menguning / Daun Rontok':
        return Icons.warning_amber_rounded;
      case 'Terserang Hama / Penyakit':
        return Icons.bug_report_outlined;
      case 'Batang Rusak / Patah':
        return Icons.report_problem_outlined;
      default:
        return Icons.info_outline;
    }
  }
}
