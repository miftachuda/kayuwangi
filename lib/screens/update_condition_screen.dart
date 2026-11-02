import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kayuwangi/models/plant_model.dart';
import 'package:kayuwangi/models/update_log_model.dart';
import 'package:kayuwangi/services/location_service.dart';
import 'package:kayuwangi/services/pocketbase_service.dart';
import 'package:kayuwangi/services/watermarking_service.dart';
import 'package:kayuwangi/utils/constants.dart';

class UpdateConditionScreen extends StatefulWidget {
  final PlantModel plant;

  const UpdateConditionScreen({
    super.key,
    required this.plant,
  });

  @override
  State<UpdateConditionScreen> createState() => _UpdateConditionScreenState();
}

class _UpdateConditionScreenState extends State<UpdateConditionScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _selectedKondisi;
  final _deskripsiController = TextEditingController();
  final _tinggiController = TextEditingController();
  final _diameterController = TextEditingController();

  LocationResult? _currentLocation;
  bool _isFetchingLocation = false;
  File? _stampedImageFile;
  bool _isProcessingStamp = false;
  bool _isSubmitting = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _selectedKondisi = widget.plant.kondisiTerkini;
    _fetchCurrentLocation();
  }

  @override
  void dispose() {
    _deskripsiController.dispose();
    _tinggiController.dispose();
    _diameterController.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() => _isFetchingLocation = true);
    try {
      final loc = await LocationService().getCurrentLocation();
      setState(() {
        _currentLocation = loc;
        _isFetchingLocation = false;
      });
    } catch (_) {
      setState(() => _isFetchingLocation = false);
    }
  }

  Future<void> _pickAndProcessImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 88,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (pickedFile == null) return;

      if (_currentLocation == null) {
        await _fetchCurrentLocation();
      }

      final loc = _currentLocation ??
          LocationResult(
            latitude: widget.plant.latitude ?? -7.1983,
            longitude: widget.plant.longitude ?? 112.5934,
            altitude: widget.plant.altitude ?? 0.0,
            accuracy: 5.0,
            address: widget.plant.address ?? 'Plot ${widget.plant.nomor}',
            timestamp: DateTime.now(),
          );

      setState(() => _isProcessingStamp = true);

      final stamped = await WatermarkingService().stampImage(
        originalImageFile: File(pickedFile.path),
        location: loc,
        plantNomor: widget.plant.nomor,
        plantSpecies: '${widget.plant.jenisTanaman} (Update)',
        customNote: _deskripsiController.text.trim(),
      );

      setState(() {
        _stampedImageFile = stamped;
        _isProcessingStamp = false;
      });
    } catch (e) {
      setState(() => _isProcessingStamp = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal geotag foto: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _submitUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final newLog = UpdateLogModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        tanggal: DateTime.now(),
        kondisi: _selectedKondisi,
        deskripsi: _deskripsiController.text.trim(),
        tinggiCm: double.tryParse(_tinggiController.text.trim()),
        diameterCm: double.tryParse(_diameterController.text.trim()),
        latitude: _currentLocation?.latitude ?? widget.plant.latitude,
        longitude: _currentLocation?.longitude ?? widget.plant.longitude,
        address: _currentLocation?.address ?? widget.plant.address,
      );

      await PocketbaseService().updatePlantCondition(
        currentPlant: widget.plant,
        newLog: newLog,
        newImageFile: _stampedImageFile,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kondisi tanaman berhasil diperbarui di PocketBase!'),
            backgroundColor: AppConstants.primaryGreen,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Gagal Memperbarui'),
            content: Text(e.toString().replaceAll('Exception: ', '')),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      appBar: AppBar(
        title: Text(
          'Update Kondisi: ${widget.plant.nomor}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
        ),
        backgroundColor: AppConstants.primaryGreen,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _isSubmitting
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppConstants.primaryGreen),
                  SizedBox(height: 18),
                  Text(
                    'Menyimpan log perkembangan & update PocketBase...',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Plant info preview card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppConstants.primaryGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.park, color: AppConstants.primaryGreen, size: 28),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.plant.nomor,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                Text(
                                  widget.plant.jenisTanaman,
                                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                                ),
                                Text(
                                  'Usia saat ini: ${widget.plant.usiaText}',
                                  style: const TextStyle(
                                    color: Color(0xFF15803D),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section Photo Geotag
                    const Text('Foto Kondisi Terkini (Dengan Geotag & Map Pin)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    _buildPhotoBox(),

                    const SizedBox(height: 20),

                    // Condition Dropdown
                    const Text('Status Kondisi Terbaru *',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _selectedKondisi,
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          AppConstants.getStatusIcon(_selectedKondisi),
                          color: AppConstants.getStatusColor(_selectedKondisi),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: AppConstants.kondisiOptions.map((k) {
                        return DropdownMenuItem(
                          value: k,
                          child: Row(
                            children: [
                              Icon(AppConstants.getStatusIcon(k), color: AppConstants.getStatusColor(k), size: 16),
                              const SizedBox(width: 8),
                              Text(k, style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedKondisi = val);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Deskripsi Perkembangan
                    const Text('Deskripsi Kondisi Tanaman *',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _deskripsiController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Tuliskan pengamatan kondisi daun, batang, hama, penyiraman, atau pemupukan...',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Deskripsi kondisi wajib diisi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Metrics (Height & Diameter)
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Tinggi (cm)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              const SizedBox(height: 4),
                              TextFormField(
                                controller: _tinggiController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: 'mis. 175',
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Diameter Batang (cm)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              const SizedBox(height: 4),
                              TextFormField(
                                controller: _diameterController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: 'mis. 6.5',
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _isProcessingStamp ? null : _submitUpdate,
                        icon: const Icon(Icons.save_rounded, color: Colors.white),
                        label: const Text(
                          'Simpan Update Perkembangan',
                          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.primaryGreen,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPhotoBox() {
    if (_isProcessingStamp) {
      return Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppConstants.primaryGreen),
              SizedBox(height: 10),
              Text('Menempelkan banner koordinat & map pin...'),
            ],
          ),
        ),
      );
    }

    if (_stampedImageFile != null) {
      return Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(_stampedImageFile!, height: 220, width: double.infinity, fit: BoxFit.cover),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _pickAndProcessImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt, size: 16),
                label: const Text('Ganti Foto'),
                style: TextButton.styleFrom(foregroundColor: AppConstants.primaryGreen),
              ),
            ],
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Icon(Icons.add_a_photo_outlined, size: 40, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          const Text(
            'Ambil foto kondisi saat ini (opsional tapi disarankan)',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => _pickAndProcessImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                label: const Text('Buka Kamera', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryGreen),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () => _pickAndProcessImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library, color: AppConstants.primaryGreen, size: 16),
                label: const Text('Galeri', style: TextStyle(color: AppConstants.primaryGreen)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
