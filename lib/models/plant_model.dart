import 'dart:convert';
import 'package:kayuwangi/models/update_log_model.dart';

class PlantModel {
  final String id;
  final String? collectionId;
  final String? collectionName;
  final String? pict;
  final DateTime? created;
  final DateTime? updated;

  // Fields inside data JSON
  final String nomor;
  final String jenisTanaman;
  final DateTime tanggalTanam;
  final String infoPentingLainnya;
  final String kondisiTerkini;
  final double? latitude;
  final double? longitude;
  final double? altitude;
  final double? accuracy;
  final String? address;
  final List<UpdateLogModel> riwayatUpdate;

  PlantModel({
    required this.id,
    this.collectionId,
    this.collectionName = 'kayuwangi',
    this.pict,
    this.created,
    this.updated,
    required this.nomor,
    required this.jenisTanaman,
    required this.tanggalTanam,
    required this.infoPentingLainnya,
    this.kondisiTerkini = 'Subur & Sehat',
    this.latitude,
    this.longitude,
    this.altitude,
    this.accuracy,
    this.address,
    List<UpdateLogModel>? riwayatUpdate,
  }) : riwayatUpdate = riwayatUpdate ?? [];

  /// Parse from PocketBase record JSON
  factory PlantModel.fromPocketBase(Map<String, dynamic> record) {
    // PocketBase stores 'data' either as JSON Map or stringified JSON
    Map<String, dynamic> dataMap = {};
    final rawData = record['data'];
    if (rawData is Map<String, dynamic>) {
      dataMap = rawData;
    } else if (rawData is String && rawData.trim().isNotEmpty) {
      try {
        dataMap = jsonDecode(rawData);
      } catch (_) {
        dataMap = {'raw_text': rawData};
      }
    }

    // Nomor
    final nomor = dataMap['nomor']?.toString() ??
        record['nomor']?.toString() ??
        'Tanpa Nomor';

    // Jenis Tanaman
    final jenisTanaman = dataMap['jenis_tanaman']?.toString() ??
        dataMap['jenisTanaman']?.toString() ??
        record['jenis_tanaman']?.toString() ??
        'Tidak Diketahui';

    // Tanggal Tanam
    DateTime tglTanam = DateTime.now();
    final rawDate = dataMap['tanggal_tanam'] ??
        dataMap['tanggalTanam'] ??
        record['tanggal_tanam'];
    if (rawDate != null) {
      tglTanam = DateTime.tryParse(rawDate.toString()) ?? DateTime.now();
    }

    // Info penting lainnya
    final infoLainnya = dataMap['info_penting_lainnya']?.toString() ??
        dataMap['infoPentingLainnya']?.toString() ??
        dataMap['deskripsi']?.toString() ??
        '';

    // Kondisi terkini
    final kondisi = dataMap['kondisi_terkini']?.toString() ??
        dataMap['kondisi']?.toString() ??
        'Subur & Sehat';

    // Lokasi
    double? lat;
    double? lng;
    double? alt;
    double? acc;
    String? addr;

    if (dataMap['lokasi'] is Map<String, dynamic>) {
      final loc = dataMap['lokasi'] as Map<String, dynamic>;
      lat = loc['latitude'] != null ? double.tryParse(loc['latitude'].toString()) : null;
      lng = loc['longitude'] != null ? double.tryParse(loc['longitude'].toString()) : null;
      alt = loc['altitude'] != null ? double.tryParse(loc['altitude'].toString()) : null;
      acc = loc['accuracy'] != null ? double.tryParse(loc['accuracy'].toString()) : null;
      addr = loc['address']?.toString();
    } else {
      lat = dataMap['latitude'] != null ? double.tryParse(dataMap['latitude'].toString()) : null;
      lng = dataMap['longitude'] != null ? double.tryParse(dataMap['longitude'].toString()) : null;
      addr = dataMap['address']?.toString();
    }

    // Riwayat Update
    List<UpdateLogModel> logs = [];
    if (dataMap['riwayat_update'] is List) {
      for (var item in dataMap['riwayat_update']) {
        if (item is Map<String, dynamic>) {
          logs.add(UpdateLogModel.fromJson(item));
        }
      }
    }

    // Sort riwayat by date descending (newest first)
    logs.sort((a, b) => b.tanggal.compareTo(a.tanggal));

    return PlantModel(
      id: record['id']?.toString() ?? '',
      collectionId: record['collectionId']?.toString(),
      collectionName: record['collectionName']?.toString() ?? 'kayuwangi',
      pict: record['pict']?.toString(),
      created: record['created'] != null ? DateTime.tryParse(record['created'].toString()) : null,
      updated: record['updated'] != null ? DateTime.tryParse(record['updated'].toString()) : null,
      nomor: nomor,
      jenisTanaman: jenisTanaman,
      tanggalTanam: tglTanam,
      infoPentingLainnya: infoLainnya,
      kondisiTerkini: kondisi,
      latitude: lat,
      longitude: lng,
      altitude: alt,
      accuracy: acc,
      address: addr,
      riwayatUpdate: logs,
    );
  }

  /// Convert to JSON payload specifically for PocketBase 'data' field
  Map<String, dynamic> toDataPayload() {
    return {
      'nomor': nomor,
      'jenis_tanaman': jenisTanaman,
      'tanggal_tanam': tanggalTanam.toIso8601String().split('T').first,
      'info_penting_lainnya': infoPentingLainnya,
      'kondisi_terkini': kondisiTerkini,
      'lokasi': {
        'latitude': latitude,
        'longitude': longitude,
        'altitude': altitude,
        'accuracy': accuracy,
        'address': address,
      },
      'riwayat_update': riwayatUpdate.map((e) => e.toJson()).toList(),
    };
  }

  /// Construct PocketBase file thumbnail / view URL
  String getImageUrl(String baseUrl) {
    if (pict == null || pict!.isEmpty) return '';
    // Format: http://base.loc-2.com/api/files/kayuwangi/{id}/{pict}
    final cleanBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final coll = collectionName ?? 'kayuwangi';
    return '$cleanBase/api/files/$coll/$id/$pict';
  }

  /// Usia tanaman dalam format hari
  int get usiaHari {
    final now = DateTime.now();
    return now.difference(tanggalTanam).inDays;
  }

  /// Usia tanaman dalam bahasa Indonesia ramah pengguna: e.g. "1 tahun 4 bulan", "3 bulan 12 hari", atau "5 hari"
  String get usiaText {
    final now = DateTime.now();
    if (now.isBefore(tanggalTanam)) {
      return 'Baru ditanam (hari ini)';
    }

    int years = now.year - tanggalTanam.year;
    int months = now.month - tanggalTanam.month;
    int days = now.day - tanggalTanam.day;

    if (days < 0) {
      months -= 1;
      final prevMonth = DateTime(now.year, now.month, 0);
      days += prevMonth.day;
    }
    if (months < 0) {
      years -= 1;
      months += 12;
    }

    if (years > 0) {
      if (months > 0) {
        return '$years tahun $months bulan';
      }
      return '$years tahun';
    } else if (months > 0) {
      if (days > 0) {
        return '$months bulan $days hari';
      }
      return '$months bulan';
    } else {
      return '$days hari';
    }
  }

  /// Copy with helper for immutability
  PlantModel copyWith({
    String? id,
    String? collectionId,
    String? collectionName,
    String? pict,
    DateTime? created,
    DateTime? updated,
    String? nomor,
    String? jenisTanaman,
    DateTime? tanggalTanam,
    String? infoPentingLainnya,
    String? kondisiTerkini,
    double? latitude,
    double? longitude,
    double? altitude,
    double? accuracy,
    String? address,
    List<UpdateLogModel>? riwayatUpdate,
  }) {
    return PlantModel(
      id: id ?? this.id,
      collectionId: collectionId ?? this.collectionId,
      collectionName: collectionName ?? this.collectionName,
      pict: pict ?? this.pict,
      created: created ?? this.created,
      updated: updated ?? this.updated,
      nomor: nomor ?? this.nomor,
      jenisTanaman: jenisTanaman ?? this.jenisTanaman,
      tanggalTanam: tanggalTanam ?? this.tanggalTanam,
      infoPentingLainnya: infoPentingLainnya ?? this.infoPentingLainnya,
      kondisiTerkini: kondisiTerkini ?? this.kondisiTerkini,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      altitude: altitude ?? this.altitude,
      accuracy: accuracy ?? this.accuracy,
      address: address ?? this.address,
      riwayatUpdate: riwayatUpdate ?? this.riwayatUpdate,
    );
  }
}
