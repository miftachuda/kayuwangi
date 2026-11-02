import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:kayuwangi/models/plant_model.dart';
import 'package:kayuwangi/models/update_log_model.dart';

void main() {
  group('PlantModel and UpdateLogModel Tests', () {
    test('Parses from PocketBase record with Map data correctly', () {
      final mockRecord = {
        'id': 'rec1234567890ab',
        'collectionId': 'col_kayuwangi',
        'collectionName': 'kayuwangi',
        'pict': 'plant_kw001_123.jpg',
        'created': '2026-11-01 10:00:00.000Z',
        'updated': '2026-11-01 10:00:00.000Z',
        'data': {
          'nomor': 'KW-001',
          'jenis_tanaman': 'Jati Emas (Tectona grandis)',
          'tanggal_tanam': '2024-05-15',
          'info_penting_lainnya': 'Bibit kultur jaringan blok lereng barat',
          'kondisi_terkini': 'Subur & Sehat',
          'lokasi': {
            'latitude': -7.198324,
            'longitude': 112.593412,
            'altitude': 28.5,
            'accuracy': 3.2,
            'address': 'Blok A2, Kayuwangi',
          },
          'riwayat_update': [
            {
              'id': 'log_1',
              'tanggal': '2026-11-01T15:00:00Z',
              'kondisi': 'Subur & Sehat',
              'deskripsi': 'Pemberian pupuk NPK dan penyiangan gulma.',
              'tinggi_cm': 185.0,
              'diameter_batang_cm': 5.5,
            }
          ]
        }
      };

      final plant = PlantModel.fromPocketBase(mockRecord);

      expect(plant.id, equals('rec1234567890ab'));
      expect(plant.nomor, equals('KW-001'));
      expect(plant.jenisTanaman, equals('Jati Emas (Tectona grandis)'));
      expect(plant.pict, equals('plant_kw001_123.jpg'));
      expect(plant.kondisiTerkini, equals('Subur & Sehat'));
      expect(plant.latitude, equals(-7.198324));
      expect(plant.longitude, equals(112.593412));
      expect(plant.riwayatUpdate.length, equals(1));
      expect(plant.riwayatUpdate.first.tinggiCm, equals(185.0));
      expect(plant.riwayatUpdate.first.deskripsi, contains('Pemberian pupuk'));
      expect(plant.getImageUrl('https://base.loc-2.com'), equals('https://base.loc-2.com/api/files/kayuwangi/rec1234567890ab/plant_kw001_123.jpg'));
    });

    test('Parses from PocketBase record with JSON string data correctly', () {
      final jsonInner = jsonEncode({
        'nomor': 'KW-042',
        'jenis_tanaman': 'Mahoni Afrika',
        'tanggal_tanam': '2025-01-10',
        'info_penting_lainnya': 'Bibit polybag',
        'kondisi_terkini': 'Butuh Pengairan',
      });

      final mockRecord = {
        'id': 'rec_string_data',
        'collectionName': 'kayuwangi',
        'pict': 'mahoni.jpg',
        'data': jsonInner,
      };

      final plant = PlantModel.fromPocketBase(mockRecord);
      expect(plant.nomor, equals('KW-042'));
      expect(plant.jenisTanaman, equals('Mahoni Afrika'));
      expect(plant.kondisiTerkini, equals('Butuh Pengairan'));
    });

    test('Converts to PocketBase data payload correctly', () {
      final plant = PlantModel(
        id: 'new_id',
        nomor: 'KW-099',
        jenisTanaman: 'Trembesi',
        tanggalTanam: DateTime(2025, 6, 1),
        infoPentingLainnya: 'Dekat saluran drainase',
        kondisiTerkini: 'Cukup Baik',
        latitude: -7.2,
        longitude: 112.6,
        address: 'Blok C',
      );

      final payload = plant.toDataPayload();
      expect(payload['nomor'], equals('KW-099'));
      expect(payload['jenis_tanaman'], equals('Trembesi'));
      expect(payload['tanggal_tanam'], equals('2025-06-01'));
      expect(payload['info_penting_lainnya'], equals('Dekat saluran drainase'));
      expect(payload['lokasi']['latitude'], equals(-7.2));
      expect(payload['lokasi']['address'], equals('Blok C'));
    });
  });
}
