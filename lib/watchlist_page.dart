import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'review_page.dart';

class WatchlistPage extends StatefulWidget {
  const WatchlistPage({super.key});

  @override
  _WatchlistPageState createState() => _WatchlistPageState();
}

class _WatchlistPageState extends State<WatchlistPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _watchlistTypes = [
    'Completed',
    'Plan to Watch',
    'Watching',
    'Dropped',
    'On Hold'
  ];

  final Map<String, Map<String, dynamic>> _streamingServices = {
    'Netflix': {
      'asset': 'assets/serviceapps/netflix.png',
      'url': 'https://www.netflix.com/eg-en/',
    },
    'OSN': {
      'asset': 'assets/serviceapps/osn.png',
      'url': 'https://osnplus.com/en-eg',
    },
    'Watch It': {
      'asset': 'assets/serviceapps/watchIt.png',
      'url': 'https://www.watchit.com/#/',
    },
    'Disney+': {
      'asset': 'assets/serviceapps/disney.png',
      'url': 'https://www.apps.disneyplus.com/eg/',
    },
    'Shahid': {
      'asset': 'assets/serviceapps/shahid.png',
      'url': 'https://shahid.mbc.net/en',
    },
    'Prime video': {
      'asset': 'assets/serviceapps/prime.png',
      'url': 'https://www.primevideo.com/',
    },
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _watchlistTypes.length, vsync: this);
  }

  Future<void> _launchServiceUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $url')),
      );
    }
  }

  void _showMovieDetails(BuildContext context, Map<String, dynamic> movie, String movieId) {
    final Color accentColor = const Color(0xFFD94CF7);
    
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          insetPadding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      child: Image.network(
                        movie['poster'] ?? '',
                        height: 400,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, _, __) => Container(
                          height: 400,
                          color: Colors.grey[800],
                          child: const Icon(Icons.error, color: Colors.red)),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context)),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movie['title'] ?? 'Unknown Title',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber[600], size: 20),
                          Text(' ${movie['rating']?.toStringAsFixed(1) ?? 'N/A'}',
                            style: const TextStyle(color: Colors.white70)),
                          const SizedBox(width: 20),
                          Icon(Icons.timer, color: Colors.grey, size: 20),
                          Text(' ${movie['runtime']?.toString() ?? 'N/A'} min',
                            style: const TextStyle(color: Colors.white70)),
                          const SizedBox(width: 20),
                          Icon(Icons.calendar_today, color: Colors.grey, size: 20),
                          Text(' ${movie['year'] ?? 'N/A'}',
                            style: const TextStyle(color: Colors.white70)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text("Available on:",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        children: (movie['streamingServices'] as List<dynamic>?)
                            ?.map((platform) {
                              final service = _streamingServices[platform.toString()];
                              if (service == null) return const SizedBox.shrink();
                              return GestureDetector(
                                onTap: () => _launchServiceUrl(service['url']),
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.white24),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.asset(
                                      service['asset'],
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(Icons.error),
                                    ),
                                  ),
                                ),
                              );
                            }).toList() ?? [
                          const Text("Check JustWatch for availability",
                            style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Moved Genres above Synopsis
                      const Text("Genres:",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: (movie['genres'] as List<dynamic>?)
                            ?.map((genre) => Chip(
                                  label: Text(genre.toString()),
                                  backgroundColor: accentColor.withOpacity(0.2),
                                  labelStyle: const TextStyle(color: Colors.white),
                                ))
                            .toList() ??
                            [const Text("No genres available", style: TextStyle(color: Colors.white70))],
                      ),
                      const SizedBox(height: 20),
                      const Text("Synopsis:",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Text(movie['synopsis'] ?? 'No description available',
                        style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.reviews, color: Colors.white),
                            label: const Text('Reviews'),
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ReviewPage(
                                    movieId: movie['id'] ?? movieId,
                                    movieTitle: movie['title'] ?? 'Unknown Title',
                                    posterUrl: movie['poster'] ?? '',
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD94CF7)),
                          ),
                          // TODO: Replace with API review summary
                          const SizedBox.shrink(),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _toggleFavorite(String movieId, Map<String, dynamic> movie) async {
    // TODO: Implement via API when watchlist endpoint is available
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Favorites feature coming soon'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showActionMenu(
      BuildContext context, String movieId, Map<String, dynamic> movie) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.open_in_new, color: Colors.white70),
                title: const Text('View Details', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _showMovieDetails(context, movie, movieId);
                },
              ),
              ListTile(
                leading: const Icon(Icons.playlist_add, color: Colors.white70),
                title: const Text('Move to List', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _showMoveDialog(context, movieId, movie);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(context);
                  // TODO: Remove via API when watchlist endpoint is available
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Movie removed (will sync when API is ready)'),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMoveDialog(BuildContext context, String movieId,
      Map<String, dynamic> movieData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Move to List',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ..._watchlistTypes.map((listType) {
                  return ListTile(
                    leading: Icon(_getIconForListType(listType)),
                    title: Text(listType, style: const TextStyle(color: Colors.white)),
                    trailing: movieData['listType'] == listType
                        ? const Icon(Icons.check, color: Color(0xFFD94CF7))
                        : null,
                    onTap: () {
                      _moveMovieToList(movieId, listType);
                      Navigator.pop(context);
                    },
                  );
                }),
                const SizedBox(height: 16),
                const Divider(
                  color: Colors.grey,
                  height: 20,
                  thickness: 1,
                  indent: 8,
                  endIndent: 8,
                ),
                ListTile(
                  leading: const Icon(Icons.favorite, color: Colors.red),
                  title: const Text('Favorites', style: TextStyle(color: Colors.white)),
                  trailing: movieData['isFavorite'] ?? false
                      ? const Icon(Icons.check, color: Color(0xFFD94CF7))
                      : null,
                  onTap: () {
                    _toggleFavorite(movieId, movieData);
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _moveMovieToList(String movieId, String newListType) async {
    // TODO: Implement via API when watchlist endpoint is available
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Moved to $newListType (will sync when API is ready)'),
        backgroundColor: Colors.green,
      ),
    );
  }

  IconData _getIconForListType(String listType) {
    switch (listType) {
      case 'Completed': return Icons.check_circle;
      case 'Plan to Watch': return Icons.calendar_today;
      case 'Watching': return Icons.play_arrow;
      case 'Dropped': return Icons.stop_circle;
      case 'On Hold': return Icons.pause_circle;
      default: return Icons.list;
    }
  }

  Widget _buildMovieCard(
      Map<String, dynamic> movie, String movieId, Color accentColor) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 6,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.network(
                      movie['poster'] ?? 'https://via.placeholder.com/200x300',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[800],
                        child: const Icon(Icons.error, color: Colors.red)),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movie['title'] ?? 'Unknown Title',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber[600], size: 18),
                          Text(
                            ' ${(movie['rating'] as num?)?.toStringAsFixed(1) ?? 'N/A'}',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          Icon(Icons.calendar_today, color: Colors.grey, size: 16),
                          Text(
                            ' ${movie['year']?.toString() ?? 'N/A'}',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white70),
                  onPressed: () => _showActionMenu(context, movieId, movie),
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    movie['isFavorite'] ?? false
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: Colors.red,
                  ),
                  onPressed: () => _toggleFavorite(movieId, movie),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color accentColor = const Color(0xFFD94CF7);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Watchlist'),
        backgroundColor: Colors.black,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: accentColor,
          labelColor: accentColor,
          unselectedLabelColor: Colors.white70,
          tabs: _watchlistTypes
              .map((type) => Tab(
                    child: Text(
                      type,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ))
              .toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _watchlistTypes.map((listType) {
          // TODO: Replace with API-backed watchlist data
          return const Center(
            child: Text(
              'Watchlist will be available when the API is ready',
              style: TextStyle(color: Colors.white54),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}