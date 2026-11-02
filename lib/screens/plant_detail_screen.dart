import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kayuwangi/models/plant_model.dart';
import 'package:kayuwangi/services/pocketbase_service.dart';
import 'package:kayuwangi/utils/constants.dart';
import 'package:kayuwangi/utils/date_formatter.dart';
import 'package:kayuwangi/screens/update_condition_screen.dart';

class PlantDetailScreen extends StatefulWidget {
  final PlantModel plant;

  const PlantDetailScreen({
    super.key,
    required this.plant,
  });

  @override
  State<PlantDetailScreen> createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends State<PlantDetailScreen> {
  late PlantModel _plant;

  @override
  void initState() {
    super.initState();
    _plant = widget.plant;
  }

  Future<void> _openUpdateScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UpdateConditionScreen(plant: _plant),
      ),
    );

    if (result == true) {
      // Reload plant details from PocketBase
      try {
        final plants = await PocketbaseService().fetchPlants();
        final found = plants.firstWhere((p) => p.id == _plant.id, orElse: () => _plant);
        setState(() {
          _plant = found;
        });
      } catch (_) {}
    }
  }

  Future<void> _deletePlant() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Tanaman?'),
        content: Text('Apakah Anda yakin ingin menghapus catatan tanaman [${_plant.nomor}] dari PocketBase?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await PocketbaseService().deletePlant(_plant.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tanaman ${_plant.nomor} telah dihapus.')),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menghapus: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseUrl = PocketbaseService().baseUrl;
    final imageUrl = _plant.getImageUrl(baseUrl);
    final statusColor = AppConstants.getStatusColor(_plant.kondisiTerkini);
    final statusIcon = AppConstants.getStatusIcon(_plant.kondisiTerkini);

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      body: CustomScrollView(
        slivers: [
          // App Bar with Photo
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: AppConstants.primaryGreen,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.white),
                tooltip: 'Hapus Tanaman',
                onPressed: _deletePlant,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _plant.nomor,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (imageUrl.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (ctx, url) => Container(
                        color: Colors.grey.shade900,
                        child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                      ),
                      errorWidget: (ctx, url, err) => Container(
                        color: Colors.grey.shade900,
                        child: const Center(
                          child: Icon(Icons.forest, color: Colors.white38, size: 80),
                        ),
                      ),
                    )
                  else
                    Container(
                      color: const Color(0xFF1B5E20),
                      child: const Center(
                        child: Icon(Icons.forest, color: Colors.white54, size: 80),
                      ),
                    ),
                  // Dark gradient overlay
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black45, Colors.transparent, Colors.black87],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main Details Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Status
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _plant.jenisTanaman,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Kode Tag: ${_plant.nomor}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: statusColor.withOpacity(0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, color: statusColor, size: 16),
                            const SizedBox(width: 5),
                            Text(
                              _plant.kondisiTerkini,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Metrics Card: Usia, Tanggal Tanam
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.timelapse_rounded, size: 16, color: AppConstants.primaryGreen),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Usia Tanaman',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _plant.usiaText,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppConstants.primaryGreen,
                                ),
                              ),
                              Text(
                                '${_plant.usiaHari} hari sejak penanaman',
                                style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        ),
                        Container(height: 45, width: 1, color: Colors.grey.shade200),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 15, color: Colors.teal),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Tanggal Tanam',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormatter.formatIndo(_plant.tanggalTanam),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Geotag & Location Card
                  _buildLocationCard(),
                  const SizedBox(height: 16),

                  // Important Info / Notes Card
                  if (_plant.infoPentingLainnya.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.notes_rounded, color: AppConstants.primaryGreen, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Info Penting & Catatan Lainnya',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _plant.infoPentingLainnya,
                            style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // History of condition updates header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.history_rounded, color: AppConstants.primaryGreen, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Riwayat Pemantauan Kondisi',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Text(
                        '${_plant.riwayatUpdate.length} update',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Updates timeline or empty notice
                  if (_plant.riwayatUpdate.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.assignment_outlined, size: 36, color: Colors.grey.shade400),
                            const SizedBox(height: 6),
                            const Text(
                              'Belum ada riwayat perkembangan tercatat',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Gunakan tombol di bawah untuk mencatat pemantauan baru.',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _plant.riwayatUpdate.length,
                      itemBuilder: (context, idx) {
                        final log = _plant.riwayatUpdate[idx];
                        final logColor = AppConstants.getStatusColor(log.kondisi);
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          elevation: 1,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.circle, size: 10, color: logColor),
                                    const SizedBox(width: 6),
                                    Text(
                                      log.kondisi,
                                      style: TextStyle(fontWeight: FontWeight.bold, color: logColor, fontSize: 13),
                                    ),
                                    const Spacer(),
                                    Text(
                                      DateFormatter.formatDateTimeIndo(log.tanggal),
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  log.deskripsi,
                                  style: const TextStyle(fontSize: 13, height: 1.3),
                                ),
                                if (log.tinggiCm != null || log.diameterCm != null) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      if (log.tinggiCm != null)
                                        Text(
                                          'Tinggi: ${log.tinggiCm} cm  ',
                                          style: const TextStyle(fontSize: 11, color: AppConstants.primaryGreen, fontWeight: FontWeight.bold),
                                        ),
                                      if (log.diameterCm != null)
                                        Text(
                                          'Diameter: ${log.diameterCm} cm',
                                          style: const TextStyle(fontSize: 11, color: Colors.teal, fontWeight: FontWeight.bold),
                                        ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 90), // Spacing for bottom button
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SizedBox(
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _openUpdateScreen,
            icon: const Icon(Icons.add_a_photo_outlined, color: Colors.white),
            label: const Text(
              'Update Kondisi & Ambil Foto Baru',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.location_on_rounded, color: Colors.redAccent, size: 20),
              SizedBox(width: 8),
              Text(
                'Data Geotagging GPS',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_plant.latitude != null && _plant.longitude != null) ...[
            Text(
              'Koordinat: ${_plant.latitude!.toStringAsFixed(6)}°, ${_plant.longitude!.toStringAsFixed(6)}°',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 4),
            if (_plant.altitude != null || _plant.accuracy != null)
              Text(
                'Ketinggian: ${_plant.altitude?.toStringAsFixed(1) ?? "-"} m dpl | Akurasi GPS: ±${_plant.accuracy?.toStringAsFixed(1) ?? "-"}m',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            const SizedBox(height: 4),
            Text(
              'Alamat / Blok: ${_plant.address ?? "Tidak tercatat"}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ] else ...[
            const Text(
              'Data koordinat GPS belum direkam untuk tanaman ini.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }
}
