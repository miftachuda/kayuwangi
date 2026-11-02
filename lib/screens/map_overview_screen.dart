import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:kayuwangi/models/plant_model.dart';
import 'package:kayuwangi/utils/constants.dart';
import 'package:kayuwangi/screens/plant_detail_screen.dart';

class MapOverviewScreen extends StatefulWidget {
  final List<PlantModel> plants;

  const MapOverviewScreen({
    super.key,
    required this.plants,
  });

  @override
  State<MapOverviewScreen> createState() => _MapOverviewScreenState();
}

class _MapOverviewScreenState extends State<MapOverviewScreen> {
  final MapController _mapController = MapController();
  late List<PlantModel> _geotaggedPlants;

  @override
  void initState() {
    super.initState();
    _geotaggedPlants = widget.plants.where((p) => p.latitude != null && p.longitude != null).toList();
  }

  LatLng _getInitialCenter() {
    if (_geotaggedPlants.isNotEmpty) {
      return LatLng(_geotaggedPlants.first.latitude!, _geotaggedPlants.first.longitude!);
    }
    // Default coordinate around Banyuwangi / East Java
    return const LatLng(-8.2191, 114.3692);
  }

  void _showPlantModal(PlantModel plant) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final statusColor = AppConstants.getStatusColor(plant.kondisiTerkini);
        return Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryGreen.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      plant.nomor,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppConstants.primaryGreen),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      plant.kondisiTerkini,
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                plant.jenisTanaman,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Usia Tanaman: ${plant.usiaText} (${plant.usiaHari} hari)',
                style: const TextStyle(color: Color(0xFF15803D), fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                'Koordinat: ${plant.latitude!.toStringAsFixed(6)}, ${plant.longitude!.toStringAsFixed(6)}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => PlantDetailScreen(plant: plant)),
                    );
                  },
                  icon: const Icon(Icons.arrow_forward, color: Colors.white),
                  label: const Text('Buka Detail Tanaman', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryGreen),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Peta Sebaran Tanaman (${_geotaggedPlants.length})',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
        ),
        backgroundColor: AppConstants.primaryGreen,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _geotaggedPlants.isEmpty
          ? const Center(
              child: Text(
                'Belum ada tanaman dengan koordinat GPS tersimpan.',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _getInitialCenter(),
                initialZoom: 15.0,
                maxZoom: 18.0,
                minZoom: 4.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.kayuwangi.monitoring',
                ),
                MarkerLayer(
                  markers: _geotaggedPlants.map((plant) {
                    final color = AppConstants.getStatusColor(plant.kondisiTerkini);
                    return Marker(
                      point: LatLng(plant.latitude!, plant.longitude!),
                      width: 48,
                      height: 48,
                      child: GestureDetector(
                        onTap: () => _showPlantModal(plant),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.eco, color: Colors.white, size: 16),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                plant.nomor,
                                style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_geotaggedPlants.isNotEmpty) {
            _mapController.move(_getInitialCenter(), 16.0);
          }
        },
        backgroundColor: Colors.white,
        foregroundColor: AppConstants.primaryGreen,
        child: const Icon(Icons.my_location),
      ),
    );
  }
}
