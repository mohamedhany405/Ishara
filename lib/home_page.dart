// home_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ionicons/ionicons.dart';
import 'review_page.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';

enum SortOption {
  ratingHighToLow,
  ratingLowToHigh,
  yearNewestFirst,
  yearOldestFirst,
  runtimeLongestFirst,
  runtimeShortestFirst,
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _buttonController;
  late Animation<double> _buttonScale;
  final List<String> _selectedGenres = [];
  List<Map<String, dynamic>> _movies = [];
  List<Map<String, dynamic>> _allMovies = [];
  List<Map<String, dynamic>> _searchResults = [];
  bool _showAllGenres = false;
  SortOption? _selectedSort;
  final int _initialVisibleGenres = 8;
  final double _genreButtonWidth = 160;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<String> _watchlistMovieIds = {};
  bool _hideWatched = false;
  late VideoPlayerController _videoController;
  late Future<void> _initializeVideoPlayerFuture;
  bool _isFetching = false;
  bool _filtersApplied = false;
  final FocusNode _searchFocusNode = FocusNode();

  final Map<String, Map<String, dynamic>> _streamingServices = {
    'Netflix': {'asset': 'assets/serviceapps/netflix.png', 'url': 'https://www.netflix.com'},
    'OSN': {'asset': 'assets/serviceapps/osn.png', 'url': 'https://osnplus.com'},
    'Watch It': {'asset': 'assets/serviceapps/watchit.png', 'url': 'https://watchit.com'},
    'Disney+': {'asset': 'assets/serviceapps/disney.png', 'url': 'https://disneyplus.com'},
    'Shahid': {'asset': 'assets/serviceapps/shahid.png', 'url': 'https://shahid.mbc.net'},
    'Prime Video': {'asset': 'assets/serviceapps/prime.png', 'url': 'https://primevideo.com'},
  };

  final List<Map<String, dynamic>> _genreOptions = [
    {'icon': Ionicons.flame, 'label': 'Action'},
    {'icon': Ionicons.compass, 'label': 'Adventure'},
    {'icon': Ionicons.color_palette, 'label': 'Animation'},
    {'icon': Icons.perm_identity, 'label': 'Biography'},
    {'icon': Ionicons.happy, 'label': 'Comedy'},
    {'icon': Ionicons.finger_print, 'label': 'Crime'},
    {'icon': Ionicons.book, 'label': 'Documentary'},
    {'icon': Ionicons.videocam, 'label': 'Drama'},
    {'icon': Ionicons.people, 'label': 'Family'},
    {'icon': Ionicons.sparkles, 'label': 'Fantasy'},
    {'icon': Ionicons.time, 'label': 'Historical'},
    {'icon': Ionicons.skull, 'label': 'Horror'},
    {'icon': Ionicons.musical_notes, 'label': 'Musical'},
    {'icon': Ionicons.help, 'label': 'Mystery'},
    {'icon': Ionicons.glasses, 'label': 'Noir'},
    {'icon': Icons.psychology, 'label': 'Psychological'},
    {'icon': Ionicons.heart, 'label': 'Romance'},
    {'icon': Ionicons.rocket, 'label': 'Sci-Fi'},
    {'icon': Ionicons.trophy, 'label': 'Sport'},
    {'icon': Icons.flash_on, 'label': 'Superhero'},
    {'icon': Icons.theater_comedy, 'label': 'Theater'},
    {'icon': Ionicons.eye, 'label': 'Thriller'},
    {'icon': Ionicons.flag, 'label': 'War'},
    {'icon': Icons.smoking_rooms, 'label': 'Western'},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _buttonScale = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );

    try {
      _videoController = VideoPlayerController.asset('assets/videos/homepagevideo.mp4');
      _initializeVideoPlayerFuture = _videoController.initialize().then((_) {
        setState(() {});
        _videoController.play();
        _videoController.setLooping(true);
      });
    } catch (e) {
      _showErrorSnackbar('Failed to load video: ${e.toString()}');
    }

    _fetchWatchlist();
    _fetchAllMovies();
    _triggerInitialAnimation();
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

  void _triggerInitialAnimation() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _animationController.forward(from: 0);
    });
  }

  Future<void> _fetchWatchlist() async {
    // TODO: Implement watchlist fetch via API when endpoint is available
    // For now, watchlist operations are stubbed out since the backend
    // doesn't have movie/watchlist endpoints yet.
    setState(() {
      _watchlistMovieIds.clear();
    });
  }

  List<String> _parseList(dynamic value) {
    if (value == null) return [];
    if (value is List) return List<String>.from(value);
    if (value is String) return value.split(', ');
    return [];
  }

  Future<void> _fetchAllMovies() async {
    if (_isFetching) return;
    setState(() => _isFetching = true);

    try {
      // TODO: Replace with real API call when movie endpoints are available
      // final result = await dataService.getCollection('/api/movies');
      // For now, the movie list will be populated from the backend
      // once the movie collection API is built.
      setState(() {
        _allMovies = [];
      });
    } catch (e) {
      _showErrorSnackbar('Failed to load movies: ${e.toString()}');
    } finally {
      setState(() => _isFetching = false);
    }
  }

  void _searchMovies(String query) {
    final queryLower = query.toLowerCase();
    setState(() {
      _searchResults = _allMovies.where((movie) => 
        movie['title'].toString().toLowerCase().contains(queryLower)
      ).toList();
    });
  }

  void _applyFilters() {
    setState(() {
      _filtersApplied = true;
      List<Map<String, dynamic>> filtered = _allMovies;
      
      if (_selectedGenres.isNotEmpty) {
        filtered = filtered.where((movie) => 
          _selectedGenres.every((genre) => movie['genres'].contains(genre))
        ).toList();
      }

      _movies = _applySortTo(filtered);
    });
  }

  List<Map<String, dynamic>> _applySortTo(List<Map<String, dynamic>> movies) {
    return List.from(movies)..sort((a, b) {
      if (_selectedSort == null) {
        return (b['rating'] as double).compareTo(a['rating'] as double);
      }
      
      switch (_selectedSort!) {
        case SortOption.ratingHighToLow:
          return (b['rating'] as double).compareTo(a['rating'] as double);
        case SortOption.ratingLowToHigh:
          return (a['rating'] as double).compareTo(b['rating'] as double);
        case SortOption.yearNewestFirst:
          int yearA = int.tryParse(a['year'] ?? '') ?? 0;
          int yearB = int.tryParse(b['year'] ?? '') ?? 0;
          return yearB.compareTo(yearA);
        case SortOption.yearOldestFirst:
          int yearA = int.tryParse(a['year'] ?? '') ?? 0;
          int yearB = int.tryParse(b['year'] ?? '') ?? 0;
          return yearA.compareTo(yearB);
        case SortOption.runtimeLongestFirst:
          int runtimeA = int.tryParse(a['runtime'] ?? '') ?? 0;
          int runtimeB = int.tryParse(b['runtime'] ?? '') ?? 0;
          return runtimeB.compareTo(runtimeA);
        case SortOption.runtimeShortestFirst:
          int runtimeA = int.tryParse(a['runtime'] ?? '') ?? 0;
          int runtimeB = int.tryParse(b['runtime'] ?? '') ?? 0;
          return runtimeA.compareTo(runtimeB);
      }
    });
  }

  void _showMovieDetails(BuildContext context, Map<String, dynamic> movie) {
    _searchFocusNode.unfocus();
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
                          child: const Icon(Icons.error, color: Colors.red),
                        ),
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
                          Text(' ${movie['runtime'] ?? 'N/A'} min',
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
                                    movieId: movie['id'],
                                    movieTitle: movie['title'] ?? 'Unknown Title',
                                    posterUrl: movie['poster'] ?? '',
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD94CF7)),
                          ),
                          // TODO: Replace with API review fetch
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

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showAddToListDialog(BuildContext context, String movieId, Map<String, dynamic> movieData) {
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
                  'Add to List',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ..._buildListOptions(context, movieId, movieData),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildListOptions(BuildContext context, String movieId, Map<String, dynamic> movieData) {
    return [
      ListTile(
        leading: const Icon(Icons.check_circle, color: Colors.white70),
        title: const Text('Completed', style: TextStyle(color: Colors.white)),
        trailing: movieData['listType'] == 'Completed'
            ? const Icon(Icons.check, color: Color(0xFFD94CF7))
            : null,
        onTap: () => _addToWatchlist(movieId, movieData, 'Completed'),
      ),
      ListTile(
        leading: const Icon(Icons.calendar_today, color: Colors.white70),
        title: const Text('Plan to Watch', style: TextStyle(color: Colors.white)),
        trailing: movieData['listType'] == 'Plan to Watch'
            ? const Icon(Icons.check, color: Color(0xFFD94CF7))
            : null,
        onTap: () => _addToWatchlist(movieId, movieData, 'Plan to Watch'),
      ),
      ListTile(
        leading: const Icon(Icons.play_arrow, color: Colors.white70),
        title: const Text('Watching', style: TextStyle(color: Colors.white)),
        trailing: movieData['listType'] == 'Watching'
            ? const Icon(Icons.check, color: Color(0xFFD94CF7))
            : null,
        onTap: () => _addToWatchlist(movieId, movieData, 'Watching'),
      ),
      ListTile(
        leading: const Icon(Icons.stop_circle, color: Colors.white70),
        title: const Text('Dropped', style: TextStyle(color: Colors.white)),
        trailing: movieData['listType'] == 'Dropped'
            ? const Icon(Icons.check, color: Color(0xFFD94CF7))
            : null,
        onTap: () => _addToWatchlist(movieId, movieData, 'Dropped'),
      ),
      ListTile(
        leading: const Icon(Icons.pause_circle, color: Colors.white70),
        title: const Text('On Hold', style: TextStyle(color: Colors.white)),
        trailing: movieData['listType'] == 'On Hold'
            ? const Icon(Icons.check, color: Color(0xFFD94CF7))
            : null,
        onTap: () => _addToWatchlist(movieId, movieData, 'On Hold'),
      ),
      const Divider(
        color: Colors.grey,
        height: 20,
        thickness: 1,
        indent: 8,
        endIndent: 8,
      ),
      ListTile(
        leading: Icon(
          movieData['isFavorite'] ?? false
              ? Icons.favorite
              : Icons.favorite_border,
          color: Colors.red,
        ),
        title: const Text('Favorites', style: TextStyle(color: Colors.white)),
        trailing: movieData['isFavorite'] ?? false
            ? const Icon(Icons.check, color: Color(0xFFD94CF7))
            : null,
        onTap: () => _toggleFavorite(movieId, movieData),
      ),
    ];
  }

  Future<void> _toggleFavorite(String movieId, Map<String, dynamic> movieData) async {
    // TODO: Implement via API when watchlist endpoint is available
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Favorites feature coming soon'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _addToWatchlist(String movieId, Map<String, dynamic> movieData, String listType) async {
    // TODO: Implement via API when watchlist endpoint is available
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added to $listType (will sync when API is ready)'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildGenreChip(Map<String, dynamic> genre) {
    final bool isSelected = _selectedGenres.contains(genre['label']);
    return SizedBox(
      width: _genreButtonWidth,
      height: 50,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap: () => setState(() {
            isSelected
                ? _selectedGenres.remove(genre['label'])
                : _selectedGenres.add(genre['label']);
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: isSelected ? Colors.deepPurple[400] : Colors.grey[800],
              borderRadius: BorderRadius.circular(25),
              border: isSelected ? Border.all(color: Colors.white, width: 1.5) : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(genre['icon'], color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  genre['label'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMovieGrid(List<Map<String, dynamic>> movies) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: movies.isEmpty
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.movie_rounded, size: 60, color: Colors.grey[700]),
                const SizedBox(height: 16),
                Text(
                  'No movies found',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            )
          : GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 5,
                mainAxisSpacing: 5,
                childAspectRatio: 0.4,
              ),
              itemCount: movies.length,
              itemBuilder: (context, index) {
                final movie = movies.elementAt(index);
                return GestureDetector(
                  onTap: () => _showMovieDetails(context, movie),
                  child: Card(
                    color: Colors.grey[900],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12)),
                              child: Image.network(
                                movie['poster'],
                                height: 200,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  height: 200,
                                  color: Colors.grey[800],
                                  child: const Icon(Icons.error, color: Colors.red),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    movie['title'],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    (movie['genres'] as List).join(', '),
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Icon(Icons.star, color: Colors.amber[600], size: 20),
                                      Text(
                                        ' ${movie['rating']?.toStringAsFixed(1) ?? 'N/A'}',
                                        style: const TextStyle(color: Colors.white70)),
                                      const Spacer(),
                                      Icon(Icons.timer, color: Colors.grey, size: 20),
                                      Text(
                                        ' ${movie['runtime'] ?? 'N/A'} min',
                                        style: const TextStyle(color: Colors.white70)),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today, color: Colors.grey, size: 20),
                                      Text(
                                        ' ${movie['year'] ?? 'N/A'}',
                                        style: const TextStyle(color: Colors.white70)),
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
                          child: GestureDetector(
                            onTap: () => _showAddToListDialog(context, movie['id'], movie),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Container(
                                key: ValueKey(_watchlistMovieIds.contains(movie['id'])),
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _watchlistMovieIds.contains(movie['id'])
                                      ? Icons.check
                                      : Icons.add,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate(delay: (100 * index).ms)
                    .fadeIn()
                    .slideX(begin: 0.5),
                );
              },
            ),
    );
  }

  String _getSortOptionLabel(SortOption option) {
    switch (option) {
      case SortOption.ratingHighToLow: return 'Rating: High to Low';
      case SortOption.ratingLowToHigh: return 'Rating: Low to High';
      case SortOption.yearNewestFirst: return 'Year: Newest First';
      case SortOption.yearOldestFirst: return 'Year: Oldest First';
      case SortOption.runtimeLongestFirst: return 'Runtime: Longest First';
      case SortOption.runtimeShortestFirst: return 'Runtime: Shortest First';
    }
  }

  void _showSortFilterSheet() {
    _searchFocusNode.unfocus();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[900],
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.8,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Sort & Filter',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        ...SortOption.values.map((option) => RadioListTile<SortOption>(
                          title: Text(
                            _getSortOptionLabel(option),
                            style: const TextStyle(color: Colors.white),
                          ),
                          value: option,
                          groupValue: _selectedSort,
                          activeColor: const Color(0xFFD94CF7),
                          onChanged: (SortOption? value) {
                            setState(() => _selectedSort = value);
                            _applyFilters();
                            Navigator.pop(context);
                          },
                        )
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  title: const Text('Reset Filters',
                    style: TextStyle(color: Colors.white70)),
                  leading: const Icon(Icons.refresh, color: Colors.white70),
                  onTap: () {
                    setState(() {
                      _selectedSort = null;
                      _selectedGenres.clear();
                      _hideWatched = false;
                    });
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final showSearchResults = _searchQuery.isNotEmpty;
    final moviesToDisplay = showSearchResults ? _searchResults : _movies;
    final filteredMovies = _hideWatched
        ? moviesToDisplay.where((movie) => !_watchlistMovieIds.contains(movie['id'])).toList()
        : moviesToDisplay;
    final movieCount = filteredMovies.length;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: showSearchResults
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                    _searchResults.clear();
                  });
                },
              )
            : null,
        title: const Text('Ishara'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Search movies...',
                      prefixIcon: const Icon(Icons.search, color: Colors.white54),
                      filled: true,
                      fillColor: Colors.grey[800],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                      _searchMovies(value);
                    },
                  ),
                ),

                if (!showSearchResults) Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.deepPurple[400]!, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: AspectRatio(
                        aspectRatio: 16/9,
                        child: FutureBuilder(
                          future: _initializeVideoPlayerFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.done) {
                              if (snapshot.hasError) {
                                return Container(
                                  color: Colors.grey[900],
                                  child: const Icon(Icons.error, color: Colors.red),
                                );
                              }
                              return VideoPlayer(_videoController);
                            }
                            return Container(
                              color: Colors.grey[900],
                              child: const Center(child: CircularProgressIndicator()),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),

                if (!showSearchResults) ...[
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Select Your Mood',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final crossAxisCount = (constraints.maxWidth / _genreButtonWidth).floor().clamp(2, 4);
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: _genreButtonWidth / 50,
                              ),
                              itemCount: _showAllGenres 
                                  ? _genreOptions.length 
                                  : _initialVisibleGenres,
                              itemBuilder: (context, index) => _buildGenreChip(_genreOptions[index]),
                            );
                          },
                        ),
                        if (!_showAllGenres && _genreOptions.length > _initialVisibleGenres)
                          TextButton(
                            onPressed: () => setState(() => _showAllGenres = true),
                            child: Text(
                              'Show More Genres', 
                              style: TextStyle(color: Colors.deepPurple[300]),
                            ),
                          ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 150,
                              child: ScaleTransition(
                                scale: _buttonScale,
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.movie_creation),
                                  label: const Text('Find Movies'),
                                  onPressed: _isFetching 
                                      ? null 
                                      : () {
                                          _buttonController.forward().then((_) {
                                            _buttonController.reverse();
                                            if (_allMovies.isNotEmpty) {
                                              _applyFilters();
                                            }
                                          });
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.deepPurple,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.sort),
                              label: const Text('Sort By'),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.deepPurple[300]!),
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                                foregroundColor: Colors.white,
                              ),
                              onPressed: _showSortFilterSheet,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            children: [
                              Checkbox(
                                value: _hideWatched,
                                onChanged: (value) => setState(() => _hideWatched = value ?? false),
                                activeColor: const Color(0xFFD94CF7),
                              ),
                              const Text('Hide Watched Movies', 
                                style: TextStyle(color: Colors.white70)),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (_filtersApplied) Text(
                                '$movieCount movies found',
                                style: const TextStyle(color: Colors.white70)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                _filtersApplied || showSearchResults 
                    ? _buildMovieGrid(filteredMovies)
                    : Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            Icon(Icons.movie_filter, size: 60, color: Colors.grey[700]),
                            const SizedBox(height: 16),
                            Text(
                              'Select genres and press "Find Movies"',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
              ],
            ),
          ),
          if (_isFetching)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _buttonController.dispose();
    _videoController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }
}