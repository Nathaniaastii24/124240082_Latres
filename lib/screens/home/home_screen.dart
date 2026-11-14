
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/app_colors.dart';
import '../auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  String _userName = 'Explorer';
  String _selectedStatus = 'All';

  final TextEditingController _searchController =
      TextEditingController();

  Timer? _searchTimer;

  List<Map<String, dynamic>> _characters = [];
  List<Map<String, dynamic>> _favorites = [];
  List<Map<String, dynamic>> _episodes = [];

  bool _isLoading = true;
  bool _isLoadingEpisodes = false;

  String? _characterError;
  String? _episodeError;

  static const String _baseUrl =
      'https://rickandmortyapi.com/api';

  @override
  void initState() {
    super.initState();
    _initializeHome();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeHome() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      _userName = prefs.getString('user_name') ?? 'Explorer';
    });

    await _loadFavorites();
    await _loadCharacters();
  }

  // ==========================================
  // API: LOAD CHARACTERS
  // ==========================================

  Future<void> _loadCharacters() async {
    setState(() {
      _isLoading = true;
      _characterError = null;
    });

    try {
      final queryParameters = <String, String>{};

      if (_selectedStatus != 'All') {
        queryParameters['status'] =
            _selectedStatus.toLowerCase();
      }

      if (_searchController.text.trim().isNotEmpty) {
        queryParameters['name'] =
            _searchController.text.trim();
      }

      final uri = Uri.parse('$_baseUrl/character')
          .replace(queryParameters: queryParameters);

      final response = await http.get(uri).timeout(
        const Duration(seconds: 15),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final List results = data['results'];

        if (!mounted) return;

        setState(() {
          _characters = results
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
          _isLoading = false;
        });
      } else if (response.statusCode == 404) {
        if (!mounted) return;

        setState(() {
          _characters = [];
          _isLoading = false;
        });
      } else {
        throw Exception('Gagal mengambil data karakter.');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _characterError =
            'Tidak dapat mengambil data karakter. Periksa koneksi internet.';
      });
    }
  }

  // ==========================================
  // API: LOAD EPISODES
  // ==========================================

  Future<void> _loadEpisodes() async {
    if (_episodes.isNotEmpty) return;

    setState(() {
      _isLoadingEpisodes = true;
      _episodeError = null;
    });

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/episode'),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List results = data['results'];

        if (!mounted) return;

        setState(() {
          _episodes = results
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
          _isLoadingEpisodes = false;
        });
      } else {
        throw Exception('Gagal mengambil episode.');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingEpisodes = false;
        _episodeError = 'Gagal memuat episode. Coba lagi.';
      });
    }
  }

  // ==========================================
  // SEARCH
  // ==========================================

  void _onSearchChanged(String value) {
    _searchTimer?.cancel();

    _searchTimer = Timer(
      const Duration(milliseconds: 500),
      () {
        _loadCharacters();
      },
    );
  }

  // ==========================================
  // FAVORITES: SHARED PREFERENCES
  // ==========================================

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();

    final savedFavorites =
        prefs.getStringList('favorite_characters') ?? [];

    final loaded = <Map<String, dynamic>>[];

    for (final item in savedFavorites) {
      try {
        final decoded = jsonDecode(item);

        loaded.add(
          Map<String, dynamic>.from(decoded),
        );
      } catch (e) {
        // Lewati data favorit yang tidak valid.
      }
    }

    if (!mounted) return;

    setState(() {
      _favorites = loaded;
    });
  }

  Future<void> _toggleFavorite(
    Map<String, dynamic> character,
  ) async {
    final id = character['id'];

    final exists = _favorites.any(
      (item) => item['id'] == id,
    );

    setState(() {
      if (exists) {
        _favorites.removeWhere(
          (item) => item['id'] == id,
        );
      } else {
        _favorites.add(character);
      }
    });

    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      'favorite_characters',
      _favorites.map((item) => jsonEncode(item)).toList(),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          exists
              ? '${character['name']} dihapus dari favorit.'
              : '${character['name']} ditambahkan ke favorit!',
        ),
        backgroundColor: AppColors.purpleDark,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  bool _isFavorite(int id) {
    return _favorites.any(
      (item) => item['id'] == id,
    );
  }

  // ==========================================
  // LOGOUT
  // ==========================================

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('user_id');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    await prefs.setBool('is_logged_in', false);

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  // ==========================================
  // MAIN UI
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildHomeTab(),
      _buildFavoriteTab(),
      _buildEpisodeTab(),
      _buildProfileTab(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: pages,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });

          if (index == 1) {
            _loadFavorites();
          }

          if (index == 2) {
            _loadEpisodes();
          }
        },
        backgroundColor: Colors.white,
        indicatorColor: AppColors.purpleSoft,
        elevation: 0,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border_rounded),
            selectedIcon: Icon(Icons.favorite_rounded),
            label: 'Favorit',
          ),
          NavigationDestination(
            icon: Icon(Icons.movie_outlined),
            selectedIcon: Icon(Icons.movie_rounded),
            label: 'Episode',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  // ==========================================
  // HOME TAB
  // ==========================================

  Widget _buildHomeTab() {
    return RefreshIndicator(
      color: AppColors.purple,
      onRefresh: _loadCharacters,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
            sliver: SliverToBoxAdapter(
              child: _buildHeader(),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 15),
            sliver: SliverToBoxAdapter(
              child: _buildSearchField(),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: _buildStatusFilter(),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            sliver: SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Jelajahi Karakter',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    '${_characters.length} karakter',
                    style: const TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_isLoading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.purple,
                ),
              ),
            )
          else if (_characterError != null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildError(
                _characterError!,
                _loadCharacters,
              ),
            )
          else if (_characters.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  'Karakter tidak ditemukan.',
                  style: TextStyle(
                    color: AppColors.secondaryText,
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 25),
              sliver: SliverGrid(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 13,
                  mainAxisSpacing: 13,
                  childAspectRatio: 0.69,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return _buildCharacterCard(
                      _characters[index],
                    );
                  },
                  childCount: _characters.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ==========================================
  // HEADER
  // ==========================================

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Halo, Explorer!',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Selamat datang, $_userName',
                style: const TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              _selectedIndex = 3;
            });
          },
          child: CircleAvatar(
            radius: 25,
            backgroundColor: AppColors.purpleSoft,
            backgroundImage: const NetworkImage(
              'https://rickandmortyapi.com/api/character/avatar/1.jpeg',
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // SEARCH FIELD
  // ==========================================

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: _onSearchChanged,
      decoration: InputDecoration(
        hintText: 'Cari nama karakter...',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: IconButton(
          onPressed: () {
            _searchController.clear();
            _loadCharacters();
          },
          icon: const Icon(Icons.close_rounded),
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
      ),
    );
  }

  // ==========================================
  // STATUS FILTER
  // ==========================================

  Widget _buildStatusFilter() {
    final statuses = [
      'All',
      'Alive',
      'Dead',
      'Unknown',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Filter Status',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 11),
        Wrap(
          spacing: 8,
          children: statuses.map((status) {
            final selected = _selectedStatus == status;

            return ChoiceChip(
              label: Text(
                status == 'All' ? 'Semua' : status,
              ),
              selected: selected,
              onSelected: (_) {
                setState(() {
                  _selectedStatus = status;
                });
                _loadCharacters();
              },
              selectedColor: AppColors.purple,
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: selected
                    ? Colors.white
                    : AppColors.secondaryText,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ==========================================
  // CHARACTER CARD
  // ==========================================

  Widget _buildCharacterCard(
    Map<String, dynamic> character,
  ) {
    final int id = character['id'];
    final bool favorite = _isFavorite(id);

    return GestureDetector(
      onTap: () => _showCharacterDetail(character),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppColors.purple.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    character['image'],
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;

                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.purple,
                          strokeWidth: 2,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppColors.purpleSoft,
                        child: const Icon(
                          Icons.person_rounded,
                          size: 65,
                          color: AppColors.purple,
                        ),
                      );
                    },
                  ),
                  Positioned(
                    top: 9,
                    right: 9,
                    child: Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      child: IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          _toggleFavorite(character);
                        },
                        icon: Icon(
                          favorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: AppColors.purple,
                          size: 21,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    character['name'] ?? 'Unknown',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 7),
                  _buildStatusBadge(
                    character['status'] ?? 'Unknown',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // STATUS BADGE
  // ==========================================

  Widget _buildStatusBadge(String status) {
    Color color;

    switch (status.toLowerCase()) {
      case 'alive':
        color = AppColors.alive;
        break;
      case 'dead':
        color = AppColors.dead;
        break;
      default:
        color = AppColors.unknown;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // CHARACTER DETAIL
  // ==========================================

  void _showCharacterDetail(
    Map<String, dynamic> character,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final fields = {
          'Spesies': character['species'],
          'Gender': character['gender'],
          'Asal': character['origin']?['name'],
          'Lokasi': character['location']?['name'],
        };

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.purpleSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Image.network(
                    character['image'],
                    height: 190,
                    width: 190,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  character['name'],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 23,
                  ),
                ),
                const SizedBox(height: 10),
                _buildStatusBadge(character['status']),
                const SizedBox(height: 22),
                ...fields.entries.map((entry) {
                  return _buildDetailRow(
                    entry.key,
                    entry.value?.toString() ?? '-',
                  );
                }),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _toggleFavorite(character);
                      Navigator.pop(context);
                    },
                    icon: Icon(
                      _isFavorite(character['id'])
                          ? Icons.favorite
                          : Icons.favorite_border,
                    ),
                    label: Text(
                      _isFavorite(character['id'])
                          ? 'Hapus dari Favorit'
                          : 'Tambah ke Favorit',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 85,
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.secondaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // FAVORITE TAB
  // ==========================================

  Widget _buildFavoriteTab() {
    return _buildPage(
      title: 'Karakter Favorit',
      subtitle: 'Kumpulan karakter pilihanmu.',
      child: _favorites.isEmpty
          ? _buildEmptyState(
              Icons.favorite_border_rounded,
              'Belum ada favorit',
              'Tekan ikon hati pada karakter untuk menyimpannya.',
            )
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(20, 15, 20, 25),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 13,
                mainAxisSpacing: 13,
                childAspectRatio: 0.69,
              ),
              itemCount: _favorites.length,
              itemBuilder: (context, index) {
                return _buildCharacterCard(_favorites[index]);
              },
            ),
    );
  }

  // ==========================================
  // EPISODE TAB
  // ==========================================

  Widget _buildEpisodeTab() {
    return _buildPage(
      title: 'Daftar Episode',
      subtitle: 'Jelajahi episode Rick & Morty.',
      child: _isLoadingEpisodes
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.purple,
              ),
            )
          : _episodeError != null
              ? _buildError(
                  _episodeError!,
                  () {
                    _episodes.clear();
                    _loadEpisodes();
                  },
                )
              : _episodes.isEmpty
                  ? _buildEmptyState(
                      Icons.movie_outlined,
                      'Episode belum tersedia',
                      'Silakan coba muat ulang.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        20,
                        15,
                        20,
                        25,
                      ),
                      itemCount: _episodes.length,
                      itemBuilder: (context, index) {
                        final episode = _episodes[index];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.purpleSoft,
                                  borderRadius:
                                      BorderRadius.circular(15),
                                ),
                                child: const Icon(
                                  Icons.play_circle_fill_rounded,
                                  color: AppColors.purple,
                                  size: 27,
                                ),
                              ),
                              const SizedBox(width: 13),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      episode['name'] ?? '-',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      episode['episode'] ?? '',
                                      style: const TextStyle(
                                        color: AppColors.purple,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      episode['air_date'] ?? '-',
                                      style: const TextStyle(
                                        color: AppColors.secondaryText,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }

  // ==========================================
  // PROFILE TAB
  // ==========================================

  Widget _buildProfileTab() {
    return _buildPage(
      title: 'Profil Saya',
      subtitle: 'Informasi akun pengguna.',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 15),
            CircleAvatar(
              radius: 58,
              backgroundColor: AppColors.purpleSoft,
              backgroundImage: const NetworkImage(
                'https://rickandmortyapi.com/api/character/avatar/1.jpeg',
              ),
            ),
            const SizedBox(height: 15),
            Text(
              _userName,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Rick & Morty Explorer',
              style: TextStyle(
                color: AppColors.secondaryText,
              ),
            ),
            const SizedBox(height: 30),

            _profileMenu(
              Icons.favorite_rounded,
              'Karakter Favorit',
              'Lihat karakter kesukaanmu',
              () {
                setState(() {
                  _selectedIndex = 1;
                });
                _loadFavorites();
              },
            ),

            _profileMenu(
              Icons.movie_rounded,
              'Daftar Episode',
              'Jelajahi episode',
              () {
                setState(() {
                  _selectedIndex = 2;
                });
                _loadEpisodes();
              },
            ),

            _profileMenu(
              Icons.logout_rounded,
              'Keluar',
              'Logout dari akun',
              _logout,
              isLogout: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileMenu(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    bool isLogout = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          icon,
          color: isLogout ? AppColors.dead : AppColors.purple,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: isLogout ? AppColors.dead : AppColors.ink,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 11),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: AppColors.secondaryText,
        ),
      ),
    );
  }

  // ==========================================
  // REUSABLE PAGE
  // ==========================================

  Widget _buildPage({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 25, 20, 5),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.secondaryText,
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }

  // ==========================================
  // EMPTY STATE
  // ==========================================

  Widget _buildEmptyState(
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 65,
              color: AppColors.purpleSoft,
            ),
            const SizedBox(height: 15),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.secondaryText,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // ERROR STATE
  // ==========================================

  Widget _buildError(
    String message,
    VoidCallback onRetry,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              color: AppColors.dead,
              size: 55,
            ),
            const SizedBox(height: 15),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.secondaryText,
              ),
            ),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
