class UpdateLogModel {
  final String id;
  final DateTime tanggal;
  final String kondisi;
  final String deskripsi;
  final double? tinggiCm;
  final double? diameterCm;
  final String? fotoUrl;
  final double? latitude;
  final double? longitude;
  final String? address;

  UpdateLogModel({
    required this.id,
    required this.tanggal,
    required this.kondisi,
    required this.deskripsi,
    this.tinggiCm,
    this.diameterCm,
    this.fotoUrl,
    this.latitude,
    this.longitude,
    this.address,
  });

  factory UpdateLogModel.fromJson(Map<String, dynamic> json) {
    return UpdateLogModel(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      tanggal: json['tanggal'] != null 
          ? DateTime.tryParse(json['tanggal'].toString()) ?? DateTime.now()
          : DateTime.now(),
      kondisi: json['kondisi']?.toString() ?? 'Baik',
      deskripsi: json['deskripsi']?.toString() ?? '',
      tinggiCm: (json['tinggi_cm'] != null) ? double.tryParse(json['tinggi_cm'].toString()) : null,
      diameterCm: (json['diameter_batang_cm'] != null || json['diameter_cm'] != null) 
          ? double.tryParse((json['diameter_batang_cm'] ?? json['diameter_cm']).toString()) 
          : null,
      fotoUrl: json['foto_url']?.toString(),
      latitude: (json['lokasi'] != null && json['lokasi']['latitude'] != null)
          ? double.tryParse(json['lokasi']['latitude'].toString())
          : (json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null),
      longitude: (json['lokasi'] != null && json['lokasi']['longitude'] != null)
          ? double.tryParse(json['lokasi']['longitude'].toString())
          : (json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null),
      address: json['lokasi'] != null ? json['lokasi']['address']?.toString() : json['address']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tanggal': tanggal.toIso8601String(),
      'kondisi': kondisi,
      'deskripsi': deskripsi,
      'tinggi_cm': tinggiCm,
      'diameter_batang_cm': diameterCm,
      'foto_url': fotoUrl,
      'lokasi': {
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
      },
    };
  }
}
