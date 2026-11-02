import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kayuwangi/models/plant_model.dart';
import 'package:kayuwangi/services/location_service.dart';
import 'package:kayuwangi/services/pocketbase_service.dart';
import 'package:kayuwangi/services/watermarking_service.dart';
import 'package:kayuwangi/utils/constants.dart';
import 'package:kayuwangi/utils/date_formatter.dart';

class AddPlantScreen extends StatefulWidget {
  const AddPlantScreen({super.key});

  @override
  State<AddPlantScreen> createState() => _AddPlantScreenState();
}

class _AddPlantScreenState extends State<AddPlantScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text Controllers
  final _nomorController = TextEditingController();
  final _jenisController = TextEditingController();
  final _infoLainnyaController = TextEditingController();
  final _customJenisController = TextEditingController();

  DateTime _tanggalTanam = DateTime.now();
  String _selectedKondisi = 'Subur & Sehat';
  String _selectedJenisDropdown = AppConstants.jenisTanamanOptions.first;

  // Geotagging & Photo State
  LocationResult? _currentLocation;
  bool _isFetchingLocation = false;
  File? _originalImageFile;
  File? _stampedImageFile;
  bool _isProcessingStamp = false;
  bool _isSubmitting = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _jenisController.text = _selectedJenisDropdown;
    // Auto-fetch location on start
    _fetchCurrentLocation();
  }

  @override
  void dispose() {
    _nomorController.dispose();
    _jenisController.dispose();
    _infoLainnyaController.dispose();
    _customJenisController.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() {
      _isFetchingLocation = true;
    });

    try {
      final loc = await LocationService().getCurrentLocation();
      setState(() {
        _currentLocation = loc;
        _isFetchingLocation = false;
      });
    } catch (e) {
      setState(() {
        _isFetchingLocation = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mendapatkan GPS: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.orange.shade800,
          ),
        );
      }
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

      // Ensure we have current location
      if (_currentLocation == null) {
        await _fetchCurrentLocation();
      }

      if (_currentLocation == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Koordinat GPS belum tersedia. Mohon aktifkan GPS perangkat.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      setState(() {
        _originalImageFile = File(pickedFile.path);
        _isProcessingStamp = true;
      });

      // Stamp image with mini map and location pin
      final stamped = await WatermarkingService().stampImage(
        originalImageFile: _originalImageFile!,
        location: _currentLocation!,
        plantNomor: _nomorController.text.trim().isNotEmpty ? _nomorController.text.trim() : 'KW-BARU',
        plantSpecies: _jenisController.text.trim().isNotEmpty ? _jenisController.text.trim() : 'Tanaman',
        customNote: _infoLainnyaController.text.trim(),
      );

      setState(() {
        _stampedImageFile = stamped;
        _isProcessingStamp = false;
      });
    } catch (e) {
      setState(() {
        _isProcessingStamp = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memproses geotag gambar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectTanggalTanam() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggalTanam,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppConstants.primaryGreen,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _tanggalTanam = picked;
      });
    }
  }

  Future<void> _submitPlant() async {
    if (!_formKey.currentState!.validate()) return;

    if (_stampedImageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wajib mengambil foto tanaman dengan geotag sebelum menyimpan!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final plantData = PlantModel(
        id: '',
        nomor: _nomorController.text.trim(),
        jenisTanaman: _selectedJenisDropdown == 'Lainnya (Custom)'
            ? _customJenisController.text.trim()
            : _jenisController.text.trim(),
        tanggalTanam: _tanggalTanam,
        infoPentingLainnya: _infoLainnyaController.text.trim(),
        kondisiTerkini: _selectedKondisi,
        latitude: _currentLocation?.latitude,
        longitude: _currentLocation?.longitude,
        altitude: _currentLocation?.altitude,
        accuracy: _currentLocation?.accuracy,
        address: _currentLocation?.address,
      );

      await PocketbaseService().createPlant(
        plant: plantData,
        imageFile: _stampedImageFile!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tanaman berhasil disimpan ke PocketBase!'),
            backgroundColor: AppConstants.primaryGreen,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red),
                SizedBox(width: 8),
                Text('Gagal Menyimpan'),
              ],
            ),
            content: Text(e.toString().replaceAll('Exception: ', '')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
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
        title: const Text(
          'Tambah Tanaman Baru',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
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
                  SizedBox(height: 20),
                  Text(
                    'Mengunggah data & foto ke PocketBase...',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 6),
                  Text('base.loc-2.com / collection: kayuwangi', style: TextStyle(color: Colors.grey)),
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
                    // Section 1: Geotagging & Photo Capture (Main Feature)
                    _buildSectionHeader('1. Pengambilan Gambar & Geotagging', Icons.add_a_photo_rounded),
                    const SizedBox(height: 10),
                    _buildPhotoGeotagCard(),

                    const SizedBox(height: 24),

                    // Section 2: Data Tanaman (JSON Payload)
                    _buildSectionHeader('2. Data Tanaman (JSON Field)', Icons.forest_rounded),
                    const SizedBox(height: 12),
                    _buildFormInputs(),

                    const SizedBox(height: 30),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _isProcessingStamp ? null : _submitPlant,
                        icon: const Icon(Icons.cloud_upload_rounded, color: Colors.white),
                        label: const Text(
                          'Simpan Tanaman ke PocketBase',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.primaryGreen,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppConstants.primaryGreen, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoGeotagCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // GPS Location Status Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: const Color(0xFFE8F5E9),
            child: Row(
              children: [
                _isFetchingLocation
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppConstants.primaryGreen),
                      )
                    : Icon(
                        _currentLocation != null ? Icons.gps_fixed : Icons.gps_not_fixed,
                        color: _currentLocation != null ? AppConstants.primaryGreen : Colors.orange,
                        size: 20,
                      ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isFetchingLocation
                            ? 'Mendeteksi titik koordinat GPS...'
                            : (_currentLocation != null
                                ? 'GPS Terkunci: ${_currentLocation!.coordinateDisplay}'
                                : 'GPS belum terdeteksi'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      if (_currentLocation != null)
                        Text(
                          '${_currentLocation!.address} (Akurasi: ±${_currentLocation!.accuracy.toStringAsFixed(1)}m)',
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _isFetchingLocation ? null : _fetchCurrentLocation,
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(40, 30)),
                  child: const Text('Refresh GPS', style: TextStyle(fontSize: 11, color: AppConstants.primaryGreen)),
                ),
              ],
            ),
          ),

          // Image Display / Watermark Preview
          if (_isProcessingStamp)
            Container(
              height: 220,
              width: double.infinity,
              color: Colors.grey.shade100,
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppConstants.primaryGreen),
                  SizedBox(height: 12),
                  Text(
                    'Menempelkan watermark lokasi & mini map pin...',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            )
          else if (_stampedImageFile != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Image.file(
                      _stampedImageFile!,
                      height: 260,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Container(
                      margin: const EdgeInsets.all(10),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, color: Color(0xFF81C784), size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Geotag & Map Pin Terpasang',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 14, color: AppConstants.primaryGreen),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          'Gambar di atas sudah memuat banner lokasi & map pin kecil permanen.',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _pickAndProcessImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt, size: 14),
                        label: const Text('Foto Ulang', style: TextStyle(fontSize: 11)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppConstants.primaryGreen,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          else
            Container(
              height: 180,
              width: double.infinity,
              color: Colors.grey.shade50,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_enhance_rounded, size: 54, color: Colors.grey.shade400),
                    const SizedBox(height: 10),
                    const Text(
                      'Ambil foto tanaman di lapangan',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sistem akan otomatis menempelkan info GPS & pin map kecil',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            ),

          // Action Buttons: Camera & Gallery
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessingStamp ? null : () => _pickAndProcessImage(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_rounded, color: Colors.white, size: 18),
                    label: const Text('Buka Kamera', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isProcessingStamp ? null : () => _pickAndProcessImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined, color: AppConstants.primaryGreen, size: 18),
                    label: const Text('Pilih Galeri', style: TextStyle(color: AppConstants.primaryGreen, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppConstants.primaryGreen),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormInputs() {
    return Container(
      padding: const EdgeInsets.all(16),
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
          // 1. Nomor Tanaman
          const Text('Nomor / Kode Tanaman *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _nomorController,
            decoration: InputDecoration(
              hintText: 'Contoh: KW-001, BLOK-A-12',
              prefixIcon: const Icon(Icons.tag, color: AppConstants.primaryGreen),
              filled: true,
              fillColor: const Color(0xFFF8FAF8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Nomor tanaman wajib diisi';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // 2. Jenis Tanaman
          const Text('Jenis Tanaman *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _selectedJenisDropdown,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.park_outlined, color: AppConstants.primaryGreen),
              filled: true,
              fillColor: const Color(0xFFF8FAF8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
            ),
            items: AppConstants.jenisTanamanOptions.map((species) {
              return DropdownMenuItem(value: species, child: Text(species, style: const TextStyle(fontSize: 13)));
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedJenisDropdown = val;
                  _jenisController.text = val;
                });
              }
            },
          ),
          if (_selectedJenisDropdown == 'Lainnya (Custom)') ...[
            const SizedBox(height: 8),
            TextFormField(
              controller: _customJenisController,
              decoration: InputDecoration(
                hintText: 'Ketik nama jenis tanaman...',
                prefixIcon: const Icon(Icons.edit, color: AppConstants.primaryGreen),
                filled: true,
                fillColor: const Color(0xFFF8FAF8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              validator: (val) {
                if (_selectedJenisDropdown == 'Lainnya (Custom)' && (val == null || val.trim().isEmpty)) {
                  return 'Tuliskan jenis tanaman';
                }
                return null;
              },
            ),
          ],
          const SizedBox(height: 16),

          // 3. Tanggal Tanam
          const Text('Tanggal Tanam *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 6),
          InkWell(
            onTap: _selectTanggalTanam,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAF8),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month_outlined, color: AppConstants.primaryGreen),
                  const SizedBox(width: 10),
                  Text(
                    DateFormatter.formatIndo(_tanggalTanam),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const Spacer(),
                  const Text('Pilih Tanggal', style: TextStyle(color: AppConstants.primaryGreen, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 4. Kondisi Awal
          const Text('Kondisi Tanaman Saat Ini *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _selectedKondisi,
            decoration: InputDecoration(
              prefixIcon: Icon(AppConstants.getStatusIcon(_selectedKondisi), color: AppConstants.getStatusColor(_selectedKondisi)),
              filled: true,
              fillColor: const Color(0xFFF8FAF8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
            ),
            items: AppConstants.kondisiOptions.map((kondisi) {
              return DropdownMenuItem(
                value: kondisi,
                child: Row(
                  children: [
                    Icon(AppConstants.getStatusIcon(kondisi), color: AppConstants.getStatusColor(kondisi), size: 16),
                    const SizedBox(width: 8),
                    Text(kondisi, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedKondisi = val;
                });
              }
            },
          ),
          const SizedBox(height: 16),

          // 5. Info Penting Lainnya
          const Text('Info Penting Lainnya (Catatan & Varietas)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _infoLainnyaController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Contoh: Bibit kultur jaringan, pupuk dasar NPK 200gr, jenis tanah lempung berpasir, blok lereng barat...',
              filled: true,
              fillColor: const Color(0xFFF8FAF8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
            ),
          ),
        ],
      ),
    );
  }
}
