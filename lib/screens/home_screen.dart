import 'package:flutter/material.dart';
import 'package:kayuwangi/models/plant_model.dart';
import 'package:kayuwangi/services/pocketbase_service.dart';
import 'package:kayuwangi/utils/constants.dart';
import 'package:kayuwangi/widgets/plant_card.dart';
import 'package:kayuwangi/widgets/stats_header.dart';
import 'package:kayuwangi/screens/add_plant_screen.dart';
import 'package:kayuwangi/screens/plant_detail_screen.dart';
import 'package:kayuwangi/screens/update_condition_screen.dart';
import 'package:kayuwangi/screens/map_overview_screen.dart';
import 'package:kayuwangi/screens/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PocketbaseService _pbService = PocketbaseService();
  List<PlantModel> _allPlants = [];
  List<PlantModel> _filteredPlants = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  String _selectedConditionFilter = 'Semua';

  @override
  void initState() {
    super.initState();
    _loadPlants();
  }

  Future<void> _loadPlants() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final plants = await _pbService.fetchPlants();
      setState(() {
        _allPlants = plants;
        _applyFilter();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    setState(() {
      _filteredPlants = _allPlants.where((p) {
        final matchesQuery = _searchQuery.isEmpty ||
            p.nomor.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            p.jenisTanaman.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (p.address != null && p.address!.toLowerCase().contains(_searchQuery.toLowerCase()));

        final matchesCondition = _selectedConditionFilter == 'Semua' ||
            p.kondisiTerkini.toLowerCase() == _selectedConditionFilter.toLowerCase();

        return matchesQuery && matchesCondition;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F4),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.nature_people_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kayuwangi Monitor',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  'Geotagging Tanaman & PocketBase',
                  style: TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined, color: Colors.white),
            tooltip: 'Peta Sebaran Lahan',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MapOverviewScreen(plants: _allPlants)),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Refresh Data',
            onPressed: _loadPlants,
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            tooltip: 'Pengaturan Server',
            onPressed: () async {
              final changed = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              if (changed == true) {
                _loadPlants();
              }
            },
          ),
        ],
        elevation: 0,
        backgroundColor: AppConstants.primaryGreen,
      ),
      body: RefreshIndicator(
        onRefresh: _loadPlants,
        color: AppConstants.primaryGreen,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Analytics Stats Summary Header
            SliverToBoxAdapter(
              child: StatsHeader(
                plants: _allPlants,
                onMapTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => MapOverviewScreen(plants: _allPlants)),
                  );
                },
              ),
            ),

            // Search Bar & Filter Chips
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Column(
                  children: [
                    // Search Text Field
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Cari nomor (KW-...), jenis pohon, atau blok...',
                        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                        prefixIcon: const Icon(Icons.search, color: AppConstants.primaryGreen),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  setState(() {
                                    _searchQuery = '';
                                    _applyFilter();
                                  });
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppConstants.primaryGreen, width: 1.5),
                        ),
                      ),
                      onChanged: (val) {
                        _searchQuery = val;
                        _applyFilter();
                      },
                    ),
                    const SizedBox(height: 10),

                    // Condition Horizontal Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('Semua'),
                          ...AppConstants.kondisiOptions.map((k) => _buildFilterChip(k)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // Content Body: Loading, Error, Empty, or List of Plants
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppConstants.primaryGreen),
                      SizedBox(height: 14),
                      Text('Memuat data monitoring...', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              )
            else if (_errorMessage != null && _allPlants.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_off_rounded, size: 64, color: Colors.red.shade300),
                        const SizedBox(height: 16),
                        const Text(
                          'Koneksi PocketBase Terhambat',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _loadPlants,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Coba Lagi'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.primaryGreen,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SettingsScreen()),
                            );
                          },
                          icon: const Icon(Icons.settings),
                          label: const Text('Ubah URL PocketBase'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (_filteredPlants.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.eco_outlined, size: 70, color: Colors.green.shade200),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty || _selectedConditionFilter != 'Semua'
                              ? 'Tidak ada tanaman yang cocok dengan pencarian'
                              : 'Belum ada data tanaman tercatat',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Coba gunakan kata kunci pencarian lain.'
                              : 'Gunakan tombol + di bawah untuk mendaftarkan pohon / tanaman baru beserta geotagging.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                        ),
                        const SizedBox(height: 24),
                        if (_searchQuery.isEmpty && _selectedConditionFilter == 'Semua')
                          ElevatedButton.icon(
                            onPressed: _navigateToAddPlant,
                            icon: const Icon(Icons.add_a_photo_outlined),
                            label: const Text('Tambah Tanaman Baru'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppConstants.primaryGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final plant = _filteredPlants[index];
                    return PlantCard(
                      plant: plant,
                      onTap: () async {
                        final updated = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PlantDetailScreen(plant: plant),
                          ),
                        );
                        if (updated == true) _loadPlants();
                      },
                      onUpdateCondition: () async {
                        final updated = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => UpdateConditionScreen(plant: plant),
                          ),
                        );
                        if (updated == true) _loadPlants();
                      },
                    );
                  },
                  childCount: _filteredPlants.length,
                ),
              ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 80), // spacing for FAB
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddPlant,
        backgroundColor: AppConstants.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_location_alt_rounded),
        label: const Text(
          'Tambah Tanaman',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.3),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedConditionFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        labelStyle: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : Colors.grey.shade800,
        ),
        selected: isSelected,
        selectedColor: AppConstants.primaryGreen,
        backgroundColor: Colors.white,
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? AppConstants.primaryGreen : Colors.grey.shade300,
          ),
        ),
        onSelected: (selected) {
          setState(() {
            _selectedConditionFilter = selected ? label : 'Semua';
            _applyFilter();
          });
        },
      ),
    );
  }

  Future<void> _navigateToAddPlant() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddPlantScreen()),
    );
    if (result == true) {
      _loadPlants();
    }
  }
}
