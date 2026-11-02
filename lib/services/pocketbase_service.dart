import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kayuwangi/models/plant_model.dart';
import 'package:kayuwangi/models/update_log_model.dart';
import 'package:kayuwangi/utils/constants.dart';

class PocketbaseService {
  static final PocketbaseService _instance = PocketbaseService._internal();
  factory PocketbaseService() => _instance;
  PocketbaseService._internal();

  String _baseUrl = AppConstants.defaultPocketBaseUrl;

  String get baseUrl => _baseUrl;

  /// Initialize service and load saved custom base URL if any
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString(AppConstants.keyPocketBaseUrl);
    if (savedUrl != null && savedUrl.trim().isNotEmpty) {
      _baseUrl = savedUrl.trim();
    }
  }

  /// Update and save custom base URL
  Future<void> setBaseUrl(String newUrl) async {
    var url = newUrl.trim();
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    _baseUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyPocketBaseUrl, _baseUrl);
  }

  /// Test connectivity to PocketBase server
  Future<bool> testConnection() async {
    try {
      final uri = Uri.parse('$_baseUrl/api/health');
      final res = await http.get(uri).timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {
      try {
        final uri = Uri.parse('$_baseUrl/api/collections/${AppConstants.collectionName}/records?page=1&perPage=1');
        final res = await http.get(uri).timeout(const Duration(seconds: 5));
        return res.statusCode == 200 || res.statusCode == 403;
      } catch (_) {
        return false;
      }
    }
  }

  /// Fetch all plants from PocketBase collection 'kayuwangi'
  Future<List<PlantModel>> fetchPlants({int page = 1, int perPage = 100}) async {
    final uri = Uri.parse('$_baseUrl/api/collections/${AppConstants.collectionName}/records?page=$page&perPage=$perPage&sort=-created');
    
    try {
      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        final List<dynamic> items = jsonResponse['items'] ?? [];
        final plants = items.map((item) => PlantModel.fromPocketBase(item as Map<String, dynamic>)).toList();
        
        // Cache to local storage for offline resilience
        _cachePlantsLocally(items);
        return plants;
      } else {
        throw Exception('Gagal memuat data dari PocketBase (HTTP ${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      // If network fails, attempt to return cached records
      final cached = await _getCachedPlantsLocally();
      if (cached.isNotEmpty) {
        return cached;
      }
      rethrow;
    }
  }

  /// Create a new plant record with watermarked image and data JSON
  Future<PlantModel> createPlant({
    required PlantModel plant,
    required File imageFile,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/collections/${AppConstants.collectionName}/records');

    final request = http.MultipartRequest('POST', uri);

    // 1. Add 'data' JSON field
    final dataJsonString = jsonEncode(plant.toDataPayload());
    request.fields['data'] = dataJsonString;

    // 2. Add 'pict' image file
    final ext = p.extension(imageFile.path).toLowerCase();
    String mimeSubtype = 'jpeg';
    if (ext == '.png') {
      mimeSubtype = 'png';
    } else if (ext == '.webp') {
      mimeSubtype = 'webp';
    }

    final multipartFile = await http.MultipartFile.fromPath(
      'pict',
      imageFile.path,
      contentType: MediaType('image', mimeSubtype),
      filename: 'plant_${plant.nomor.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}$ext',
    );
    request.files.add(multipartFile);

    // 3. Send request
    final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final Map<String, dynamic> responseJson = jsonDecode(response.body);
      return PlantModel.fromPocketBase(responseJson);
    } else {
      throw Exception('Gagal menyimpan tanaman ke PocketBase (HTTP ${response.statusCode}): ${response.body}');
    }
  }

  /// Update plant condition and append new update log, with optional new photo
  Future<PlantModel> updatePlantCondition({
    required PlantModel currentPlant,
    required UpdateLogModel newLog,
    File? newImageFile,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/collections/${AppConstants.collectionName}/records/${currentPlant.id}');

    // Append new log to history
    final updatedHistory = List<UpdateLogModel>.from(currentPlant.riwayatUpdate)..insert(0, newLog);
    final updatedPlant = currentPlant.copyWith(
      kondisiTerkini: newLog.kondisi,
      riwayatUpdate: updatedHistory,
    );

    final dataPayload = updatedPlant.toDataPayload();
    final dataJsonString = jsonEncode(dataPayload);

    if (newImageFile != null) {
      // Multipart PATCH with new photo
      final request = http.MultipartRequest('PATCH', uri);
      request.fields['data'] = dataJsonString;

      final ext = p.extension(newImageFile.path).toLowerCase();
      final multipartFile = await http.MultipartFile.fromPath(
        'pict',
        newImageFile.path,
        contentType: MediaType('image', ext == '.png' ? 'png' : 'jpeg'),
        filename: 'update_${currentPlant.nomor.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}$ext',
      );
      request.files.add(multipartFile);

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseJson = jsonDecode(response.body);
        return PlantModel.fromPocketBase(responseJson);
      } else {
        throw Exception('Gagal mengupdate kondisi (HTTP ${response.statusCode}): ${response.body}');
      }
    } else {
      // Simple JSON PATCH
      final response = await http.patch(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'data': dataJsonString}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseJson = jsonDecode(response.body);
        return PlantModel.fromPocketBase(responseJson);
      } else {
        throw Exception('Gagal mengupdate kondisi (HTTP ${response.statusCode}): ${response.body}');
      }
    }
  }

  /// Delete plant record
  Future<bool> deletePlant(String recordId) async {
    final uri = Uri.parse('$_baseUrl/api/collections/${AppConstants.collectionName}/records/$recordId');
    final response = await http.delete(uri).timeout(const Duration(seconds: 10));
    return response.statusCode == 204 || response.statusCode == 200;
  }

  // --- Local Offline Caching ---
  static const String _cacheKey = 'cached_kayuwangi_records';

  Future<void> _cachePlantsLocally(List<dynamic> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(items));
    } catch (_) {}
  }

  Future<List<PlantModel>> _getCachedPlantsLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> list = jsonDecode(raw);
        return list.map((item) => PlantModel.fromPocketBase(item as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }
}
