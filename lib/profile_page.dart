// profile_page.dart
import 'dart:async';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'report_page.dart';
import 'src/core/api/auth_provider.dart';
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _currentPasswordController;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;
  String _originalEmail = '';
  
  // Stats variables
  double _totalHours = 0;
  String _favoriteGenre = 'None';
  final Map<String, int> _listCounts = {
    'Completed': 0,
    'Plan to Watch': 0,
    'Watching': 0,
    'Dropped': 0,
    'On Hold': 0,
  };

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _usernameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _currentPasswordController = TextEditingController();
    _setupUserListener();
    _setupWatchlistListener();
  }

  String _sanitizeUsername(String username) {
    return username.trim().replaceAll(RegExp(r'[^\w]'), '_').toLowerCase();
  }

  void _setupUserListener() async {
    try {
      final authService = ref.read(authServiceProvider);
      final result = await authService.getCurrentUser();
      if (result.success && result.user != null && mounted) {
        setState(() {
          _nameController.text = result.user!['name'] ?? '';
          _usernameController.text = result.user!['username'] ?? '';
          _emailController.text = result.user!['email'] ?? '';
          _originalEmail = result.user!['email'] ?? '';
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _setupWatchlistListener() {
    // TODO: Implement via API when watchlist endpoint is available
    // Watchlist stats are stubbed out for now
  }

  void _processWatchlistData(List<Map<String, dynamic>> watchlistItems) {
    final tempCounts = Map<String, int>.from(_listCounts);
    final genreCounts = <String, int>{};
    int totalMinutes = 0;

    tempCounts.updateAll((key, value) => 0);

    for (final data in watchlistItems) {
      final listType = data['listType']?.toString() ?? '';
      final runtimeString = data['runtime']?.toString() ?? '0';
      final runtime = int.tryParse(runtimeString) ?? 0;
      final genres = List<String>.from(data['genres'] ?? const []);
      final isFavorite = data['isFavorite'] ?? false;

      if (tempCounts.containsKey(listType)) {
        tempCounts[listType] = tempCounts[listType]! + 1;
      }

      if (listType == 'Completed') {
        totalMinutes += runtime;
      }

      if (isFavorite) {
        for (final genre in genres) {
          genreCounts[genre] = (genreCounts[genre] ?? 0) + 1;
        }
      }
    }

    String mostFrequent = 'None';
    int maxCount = 0;
    genreCounts.forEach((key, value) {
      if (value > maxCount) {
        maxCount = value;
        mostFrequent = key;
      }
    });

    if (mounted) {
      setState(() {
        _totalHours = totalMinutes / 60;
        _favoriteGenre = mostFrequent;
        _listCounts.forEach((key, value) => _listCounts[key] = tempCounts[key] ?? 0);
      });
    }
  }

  Widget _buildProgressBar(String label, int count, int total) {
    final double progress = total > 0 ? count / total : 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[800],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final dataService = ref.read(dataServiceProvider);
      final result = await dataService.updateProfile({
        'name': _nameController.text.trim(),
        'username': _sanitizeUsername(_usernameController.text.trim()),
        'email': _emailController.text.trim(),
      });

      if (result.success) {
        if (mounted) {
          AwesomeDialog(
            context: context,
            dialogType: DialogType.success,
            animType: AnimType.rightSlide,
            title: 'Success',
            desc: 'Profile updated successfully',
          ).show();
          setState(() => _isEditing = false);
        }
      } else {
        AwesomeDialog(
          context: context,
          dialogType: DialogType.error,
          animType: AnimType.rightSlide,
          title: 'Error',
          desc: result.message,
        ).show();
      }
    } catch (e) {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        animType: AnimType.rightSlide,
        title: 'Error',
        desc: 'An unexpected error occurred',
      ).show();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildProfileInfo() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.deepPurple.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(20),
            child: const Icon(
              Icons.person,
              size: 80,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 30),
          Text(
            _nameController.text,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            _emailController.text,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStatsCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesList() {
    // TODO: Implement via API when favorites endpoint is available
    return const SizedBox.shrink();
  }

  void _removeFromFavorites(String movieId) async {
    // TODO: Implement via API
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Feature coming soon')),
    );
  }

  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          margin: const EdgeInsets.only(top: 20),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Display Name',
                        labelStyle: const TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.white54),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.person, color: Colors.white70),
                        filled: true,
                        fillColor: Colors.black.withOpacity(0.3),
                      ),
                      style: const TextStyle(color: Colors.white),
                      validator: (value) {
                        if (value!.isEmpty) return 'Display name cannot be empty';
                        return null;
                      },
                    ),
                    const SizedBox(height: 25),
                    TextFormField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        labelStyle: const TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.white54),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.person_pin, color: Colors.white70),
                        filled: true,
                        fillColor: Colors.black.withOpacity(0.3),
                      ),
                      style: const TextStyle(color: Colors.white),
                      validator: (value) {
                        if (value!.isEmpty) return "Username Can't Be Empty!";
                        if (value.length < 3) return "Username must be at least 3 characters";
                        if (RegExp(r'[^a-zA-Z0-9_]').hasMatch(value)) {
                          return "Only letters, numbers and underscores allowed";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 25),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: const TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.white54),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.email, color: Colors.white70),
                        filled: true,
                        fillColor: Colors.black.withOpacity(0.3),
                      ),
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) =>
                          value!.contains('@') ? null : 'Invalid email address',
                    ),
                    const SizedBox(height: 25),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'New Password (optional)',
                        labelStyle: const TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.white54),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.lock, color: Colors.white70),
                        filled: true,
                        fillColor: Colors.black.withOpacity(0.3),
                      ),
                      style: const TextStyle(color: Colors.white),
                      obscureText: true,
                      validator: (value) {
                        if (value!.isNotEmpty && value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 25),
                    TextFormField(
                      controller: _currentPasswordController,
                      decoration: InputDecoration(
                        labelText: 'Current Password (required for changes)',
                        labelStyle: const TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.white54),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.security, color: Colors.white70),
                        filled: true,
                        fillColor: Colors.black.withOpacity(0.3),
                      ),
                      style: const TextStyle(color: Colors.white),
                      obscureText: true,
                      validator: (value) {
                        if ((_emailController.text.trim() != 
                              _originalEmail ||
                              _passwordController.text.isNotEmpty) &&
                            value!.isEmpty) {
                          return 'Current password required for security changes';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 35),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return _isEditing
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Save Changes',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving
                        ? null
                        : () => setState(() {
                              _isEditing = false;
                              _setupUserListener();
                            }),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      side: const BorderSide(color: Colors.white54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                  ),
                ),
              ],
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => setState(() => _isEditing = true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 40,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Edit Profile',
                  style: TextStyle(fontSize: 16),
                ),
              ),

              OutlinedButton(
                onPressed: _confirmLogout,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                ),
                ),
                child: const Text('Logout'),
              ),
            ],
          );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final auth = ref.read(authProvider.notifier);
              await auth.logout();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.deepPurple),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(top: 20),
                  child: Center(
                    child: _isEditing ? _buildEditForm() : Column(
                      children: [
                        _buildProfileInfo(),
                        const SizedBox(height: 20),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          childAspectRatio: 1,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          children: [
                            _buildStatsCard('Total Hours', _totalHours.toStringAsFixed(1)),
                            _buildStatsCard('Favorite Genre', _favoriteGenre),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Column(
                            children: [
                              _buildProgressBar(
                                'Completed',
                                _listCounts['Completed']!,
                                _listCounts.values.reduce((a, b) => a + b),
                              ),
                              _buildProgressBar(
                                'Watching',
                                _listCounts['Watching']!,
                                _listCounts.values.reduce((a, b) => a + b),
                              ),
                              _buildProgressBar(
                                'Plan to Watch',
                                _listCounts['Plan to Watch']!,
                                _listCounts.values.reduce((a, b) => a + b),
                              ),
                            ],
                          ),
                        ),
                        _buildFavoritesList(),
                        ListTile(
                          leading: const Icon(Icons.report, color: Colors.red),
                          title: const Text('Report Problem'),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ReportPage()),
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 30, top: 20),
                child: _buildActionButtons(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    _watchlistSubscription?.cancel();
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _currentPasswordController.dispose();
    super.dispose();
  }
}