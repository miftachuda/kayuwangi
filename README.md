# 🌿 Kayuwangi Plant Monitoring App

Aplikasi Android berbasis Flutter untuk pemantauan dan inventarisasi tanaman di perkebunan/lahan Kayuwangi dengan fitur **sistem geotagging GPS presisi tinggi**, **perekaman foto dengan stempel banner lokasi & pin peta mini di dalam gambar**, serta sinkronisasi database **PocketBase** (`https://base.loc-2.com`).

---

## 🚀 Fitur Utama

1. **Tampilan Utama (Dashboard & List Tanaman)**:
   - Daftar tanaman dengan thumbnail foto (`pict`) langsung dari PocketBase.
   - **Kalkulasi Usia Tanaman Otomatis**: Menghitung usia pohon secara akurat dari tanggal tanam (contoh: *1 tahun 4 bulan*, *3 bulan 12 hari*).
   - **Ringkasan Analitik**: Total pohon, pohon sehat, pohon butuh perhatian/perawatan, dan rata-rata usia tanaman.
   - **Pencarian & Filter**: Filter status kondisi (*Subur & Sehat*, *Butuh Pengairan*, *Butuh Pemupukan*, *Terserang Hama*, dll.) dan pencarian instan berdasarkan kode nomor pohon atau jenis tanaman.
   - **Offline Caching**: Data tersimpan otomatis di perangkat, tetap dapat dibaca meski sedang di area perkebunan minim sinyal.

2. **Form Tambah Tanaman Baru**:
   - Input **Nomor / Kode Tanaman** (contoh: `KW-001`, `BLOK-A-12`).
   - Pilihan **Jenis Tanaman** (Jati Emas, Mahoni Afrika, Sengon, Trembesi, Sonokeling, Gaharu, atau Custom).
   - **Tanggal Tanam** dengan DatePicker kalender Indonesia.
   - **Info Penting Lainnya** (catatan pupuk dasar, varietas bibit, tekstur tanah, blok afdeling).
   - **Pengambilan Gambar & Geotagging Otomatis**:
     - Deteksi GPS real-time (Latitude, Longitude, Ketinggian mdpl, Akurasi GPS, dan Reverse Geocoding Alamat).
     - **Foto Stempel Geotag**: Sistem otomatis menempelkan HUD banner transparan di bagian bawah gambar yang berisi **mini map bergradien dengan pin merah penanda lokasi**, koordinat GPS, elevasi, timestamp tanggal/jam, dan nama tanaman.
     - Gambar hasil komposit disimpan permanen sebagai file JPEG siap upload.

3. **Form Update Kondisi & Riwayat Perkembangan**:
   - Memilih atau melihat pohon yang akan dipantau.
   - Mengubah status kondisi tanaman terkini.
   - Menambahkan deskripsi perkembangan (kondisi daun, batang, hama, pupuk, penyiraman).
   - Mencatat metrik tinggi tanaman (cm) dan diameter batang (cm).
   - Pengambilan foto monitoring baru yang langsung diberi stempel geotag & pin peta.
   - Riwayat pemantauan tersimpan secara kronologis dalam array JSON `riwayat_update`.

4. **Peta Sebaran Lahan (Interactive Map Overview)**:
   - Peta interaktif berbasis OpenStreetMap menampilkan seluruh pin tanaman di lahan.
   - Warna pin menyesuaikan status kondisi (Hijau: Sehat, Kuning/Oranye: Butuh Perhatian, Merah: Terserang Hama).
   - Mengetuk pin menampilkan ringkasan informasi pohon dan tautan cepat ke detail.

5. **Pengaturan Fleksibel PocketBase**:
   - Default ke `https://base.loc-2.com` (koleksi `kayuwangi`).
   - Terdapat tombol uji koneksi (*Ping Connection*) dan kemampuan mengganti endpoint server langsung dari aplikasi tanpa perlu compile ulang.

---

## 🗄️ Spesifikasi Koleksi PocketBase

Pastikan pada PocketBase (`https://base.loc-2.com/_/`) telah dibuat koleksi dengan rincian berikut:

- **Collection Name**: `kayuwangi`
- **Fields**:
  1. `data` (Tipe: `JSON`):
     Menyimpan struktur JSON data pohon, lokasi, dan riwayat perkembangan:
     ```json
     {
       "nomor": "KW-001",
       "jenis_tanaman": "Jati Emas (Tectona grandis)",
       "tanggal_tanam": "2024-05-15",
       "info_penting_lainnya": "Bibit kultur jaringan blok lereng barat, pupuk NPK",
       "kondisi_terkini": "Subur & Sehat",
       "lokasi": {
         "latitude": -7.198324,
         "longitude": 112.593412,
         "altitude": 28.5,
         "accuracy": 3.2,
         "address": "Blok A2, Kayuwangi, Giri, Banyuwangi"
       },
       "riwayat_update": [
         {
           "id": "1730456789000",
           "tanggal": "2026-11-01T16:51:37Z",
           "kondisi": "Subur & Sehat",
           "deskripsi": "Pertumbuhan daun lebat, gulma telah disiangi.",
           "tinggi_cm": 185.0,
           "diameter_batang_cm": 5.8
         }
       ]
     }
     ```
  2. `pict` (Tipe: `File`):
     - MIME types: `image/jpeg`, `image/png`, `image/webp`
     - Single file per record.
     - Menyimpan foto tanaman yang telah diberi stempel watermark koordinat dan mini-map pin.

- **API Rules**:
  - Untuk kemudahan akses aplikasi lapangan:
    - `List/Search rule`: kosong (Public) atau sesuai auth token user Anda
    - `View rule`: kosong (Public)
    - `Create rule`: kosong (Public)
    - `Update rule`: kosong (Public)

---

## 🛠️ Struktur Direktori Proyek

```
kayuwangi/
├── android/                        # Konfigurasi platform Android & Permissions
│   └── app/src/main/
│       ├── AndroidManifest.xml     # Izin Kamera, GPS Fine/Coarse, Internet, Storage
│       └── kotlin/.../MainActivity.kt
├── assets/                         # Aset icon & placeholder
├── lib/
│   ├── models/
│   │   ├── plant_model.dart        # Model data tanaman & konversi JSON PocketBase
│   │   └── update_log_model.dart   # Model log perkembangan & pemantauan berkala
│   ├── services/
│   │   ├── pocketbase_service.dart # Client REST & Multipart API PocketBase
│   │   ├── location_service.dart   # Service GPS akurasi tinggi & Reverse Geocoding
│   │   └── watermarking_service.dart # Engine stempel Canvas foto, info GPS & mini map pin
│   ├── utils/
│   │   ├── constants.dart          # Konfigurasi server, warna tema, opsi kondisi & jenis tanaman
│   │   └── date_formatter.dart     # Formatter tanggal & waktu Indonesia
│   ├── widgets/
│   │   ├── plant_card.dart         # Kartu tampilan tanaman dengan cuplikan foto & usia
│   │   └── stats_header.dart       # Banner ringkasan analitik perkebunan
│   ├── screens/
│   │   ├── home_screen.dart        # Tampilan utama (List tanaman, search & filter)
│   │   ├── add_plant_screen.dart   # Form pendaftaran pohon baru + foto geotag
│   │   ├── plant_detail_screen.dart# Detail lengkap, galeri, lokasi & riwayat
│   │   ├── update_condition_screen.dart # Form update kondisi + foto monitoring baru
│   │   ├── map_overview_screen.dart# Peta sebaran seluruh tanaman lahan
│   │   └── settings_screen.dart    # Konfigurasi server PocketBase & tes koneksi
│   └── main.dart                   # Entry point aplikasi & tema Material 3
├── test/
│   └── model_test.dart             # Unit test parsing data JSON & usia tanaman
└── pubspec.yaml                    # Dependensi paket Flutter
```

---

## 📲 Cara Menjalankan Aplikasi

### 1. Prasyarat
- Flutter SDK (versi >= 3.0.0)
- Android SDK (Android Studio atau command-line tools)
- Perangkat Android fisik atau Emulator Android dengan Google Play Services (untuk GPS).

### 2. Instalasi Dependensi
Jalankan perintah berikut di folder proyek `kayuwangi`:
```bash
flutter pub get
```

### 3. Menjalankan di Perangkat Android
Hubungkan HP Android dengan USB Debugging aktif, lalu jalankan:
```bash
flutter run
```

### 4. Membangun Berkas APK
Untuk membuat file APK rilis yang siap dibagikan ke petugas lapangan:
```bash
flutter build apk --release
```
Berkas APK akan tersimpan di:
`build/app/outputs/flutter-apk/app-release.apk`

---

## 💡 Izin Android (Permissions) yang Digunakan
- `android.permission.INTERNET`: Sinkronisasi data dan foto ke server PocketBase.
- `android.permission.ACCESS_FINE_LOCATION`: Mendapatkan koordinat GPS lintang/bujur presisi tinggi.
- `android.permission.ACCESS_COARSE_LOCATION`: Koordinat cadangan jaringan seluler/Wi-Fi.
- `android.permission.CAMERA`: Mengambil foto pohon secara langsung di lahan.
- `android.permission.READ_MEDIA_IMAGES` / `READ_EXTERNAL_STORAGE`: Mengakses foto dari galeri.
