import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kayuwangi/models/plant_model.dart';
import 'package:kayuwangi/services/pocketbase_service.dart';
import 'package:kayuwangi/utils/constants.dart';
import 'package:kayuwangi/utils/date_formatter.dart';

class PlantCard extends StatelessWidget {
  final PlantModel plant;
  final VoidCallback onTap;
  final VoidCallback? onUpdateCondition;

  const PlantCard({
    super.key,
    required this.plant,
    required this.onTap,
    this.onUpdateCondition,
  });

  @override
  Widget build(BuildContext context) {
    final baseUrl = PocketbaseService().baseUrl;
    final imageUrl = plant.getImageUrl(baseUrl);
    final statusColor = AppConstants.getStatusColor(plant.kondisiTerkini);
    final statusIcon = AppConstants.getStatusIcon(plant.kondisiTerkini);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      elevation: 2.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.12)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Image thumbnail & Key Metadata
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Photo Thumbnail with Geotag badge
                Stack(
                  children: [
                    Container(
                      width: 125,
                      height: 125,
                      color: Colors.grey.shade200,
                      child: imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppConstants.primaryGreen),
                                ),
                              ),
                              errorWidget: (context, url, error) => Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.broken_image_outlined, color: Colors.grey.shade500, size: 32),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Foto Offline',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                                  ),
                                ],
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.forest_outlined, color: Colors.grey.shade400, size: 36),
                                const SizedBox(height: 4),
                                Text('Belum ada foto', style: TextStyle(color: Colors.grey.shade500, fontSize: 9)),
                              ],
                            ),
                    ),
                    // Mini Geotag marker indicator
                    if (plant.latitude != null && plant.longitude != null)
                      Positioned(
                        bottom: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.75),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white24, width: 0.5),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.location_on, color: Colors.redAccent, size: 10),
                              SizedBox(width: 2),
                              Text(
                                'GPS',
                                style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),

                // Plant Information
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Plant Number & Status Badge
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppConstants.primaryGreen.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppConstants.primaryGreen.withOpacity(0.3)),
                              ),
                              child: Text(
                                plant.nomor,
                                style: const TextStyle(
                                  color: AppConstants.primaryGreen,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const Spacer(),
                            // Status Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(statusIcon, color: statusColor, size: 11),
                                  const SizedBox(width: 3),
                                  Text(
                                    plant.kondisiTerkini,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Plant Species
                        Text(
                          plant.jenisTanaman,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),

                        // Usia Tanaman (Highlight)
                        Row(
                          children: [
                            const Icon(Icons.timelapse_rounded, size: 14, color: Color(0xFF475569)),
                            const SizedBox(width: 4),
                            Text(
                              'Usia: ',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                            Text(
                              plant.usiaText,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF15803D), // Forest green
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),

                        // Tanggal Tanam
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 13, color: Color(0xFF64748B)),
                            const SizedBox(width: 4),
                            Text(
                              DateFormatter.formatIndo(plant.tanggalTanam),
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Bottom bar: Location & Action
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.place, size: 14, color: Colors.redAccent),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      plant.address ??
                          (plant.latitude != null
                              ? '${plant.latitude!.toStringAsFixed(5)}, ${plant.longitude!.toStringAsFixed(5)}'
                              : 'Lokasi belum direkam'),
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (onUpdateCondition != null) ...[
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: onUpdateCondition,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppConstants.primaryLight.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit_note, size: 14, color: AppConstants.primaryGreen),
                            SizedBox(width: 3),
                            Text(
                              'Update',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppConstants.primaryGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
