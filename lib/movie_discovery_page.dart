import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MovieDiscoveryPage extends StatefulWidget {
  const MovieDiscoveryPage({super.key});

  @override
  State<MovieDiscoveryPage> createState() => _MovieDiscoveryPageState();
}

class _MovieDiscoveryPageState extends State<MovieDiscoveryPage> {
  final List<Map<String, dynamic>> _movies = [];
  final List<String> _watchedIds = [];
  bool _isDragging = false;
  Offset _offset = Offset.zero;
  bool _showTutorial = false;
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _initializePreferences();
    _loadMovies();
  }

  Future<void> _initializePreferences() async {
    _prefs = await SharedPreferences.getInstance();
    final firstTime = _prefs.getBool('first_time_discovery') ?? true;
    
    if (firstTime && mounted) {
      setState(() {
        _showTutorial = true;
      });
      await _prefs.setBool('first_time_discovery', false);
    }
  }

  Future<void> _loadMovies() async {
    // if (_user == null || !mounted) return;

    // final watchlistSnapshot = await _firestore
    //     .collection('users')
    //     .doc(_user.uid)
    //     .collection('watchlist')
    //     .get();

    // if (!mounted) return;
    // setState(() {
    //   _watchedIds.addAll(watchlistSnapshot.docs.map((doc) => doc.id));
    // });

    // final moviesSnapshot = await _firestore.collection('movies').get();
    // final allMovies = moviesSnapshot.docs.map((doc) {
    //   return {
    //     ...doc.data(),
    //     'id': doc.id,
    //   };
    // }).toList();

    // if (!mounted) return;
    // setState(() {
    //   _movies
    //     ..clear()
    //     ..addAll(allMovies.where((movie) => !_watchedIds.contains(movie['id'])))
    //     ..shuffle();
    // });
  }

  void _handleSwipe(bool isRight) async {
    // if (_movies.isEmpty || _user == null || !mounted) return;

    // final currentMovie = _movies.first;
    // if (isRight) {
    //   await _firestore
    //       .collection('users')
    //       .doc(_user.uid)
    //       .collection('watchlist')
    //       .doc(currentMovie['id'])
    //       .set({
    //         ...currentMovie,
    //         'listType': 'Plan to Watch',
    //         'addedAt': FieldValue.serverTimestamp(),
    //       });
    // }

    if (!mounted) return;
    setState(() {
      _movies.removeAt(0);
      _offset = Offset.zero;
      _isDragging = false;
    });
  }

  Widget _buildMovieCard(Map<String, dynamic> movie) {
    return AnimatedContainer(
      duration: 300.ms,
      curve: Curves.easeOut,
      transform: Matrix4.identity()
        ..translate(_offset.dx)
        ..rotateZ(_offset.dx / 500),
      child: Container(
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _isDragging
                  ? (_offset.dx > 0
                      ? Colors.green.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2))
                  : Colors.transparent,
              blurRadius: 20,
              spreadRadius: 5,
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Image.network(
                movie['poster'] ?? 'https://via.placeholder.com/300x450',
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey[900],
                  child: const Icon(Icons.movie, color: Colors.white54),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.9),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movie['title'] ?? 'Unknown Title',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: (movie['genres'] as List<dynamic>?)
                                ?.map((genre) => Chip(
                                      label: Text(
                                        genre.toString(),
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                      backgroundColor: Colors.deepPurple,
                                    ))
                                .toList() ??
                            [],
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber[600], size: 24),
                          Text(
                            ' ${(movie['rating'] as num?)?.toStringAsFixed(1) ?? 'N/A'}',
                            style: const TextStyle(color: Colors.white),
                          ),
                          const SizedBox(width: 20),
                          Icon(Icons.timer, color: Colors.grey[400], size: 24),
                          Text(
                            ' ${movie['runtime']?.toString() ?? 'N/A'} min',
                            style: const TextStyle(color: Colors.white),
                          ),
                          const SizedBox(width: 20),
                          Icon(Icons.calendar_today, color: Colors.grey[400], size: 24),
                          Text(
                            ' ${movie['year']?.toString() ?? 'N/A'}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTutorialOverlay() {
    return AnimatedOpacity(
      opacity: _showTutorial ? 1.0 : 0.0,
      duration: 300.ms,
      child: IgnorePointer(
        ignoring: !_showTutorial,
        child: Container(
          color: Colors.black.withOpacity(0.85),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'How to Use',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _TutorialCard(
                    icon: Icons.arrow_back,
                    color: Colors.red,
                    label: 'Swipe Left\nTo Pass',
                  ),
                  _TutorialCard(
                    icon: Icons.arrow_forward,
                    color: Colors.green,
                    label: 'Swipe Right\nTo Add',
                  ),
                ],
              ),
              const SizedBox(height: 40),
              const Text(
                'Discover movies by swiping\nleft or right on the cards',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  if (mounted) {
                    setState(() {
                      _showTutorial = false;
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: const Text('Got it!', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Movies'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.grey[900],
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              return _movies.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'No more movies to discover!',
                            style: TextStyle(color: Colors.white, fontSize: 24),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _loadMovies,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 30, vertical: 15),
                            ),
                            child: const Text('Refresh List'),
                          ),
                        ],
                      ),
                    )
                  : GestureDetector(
                      onPanUpdate: (details) {
                        if (!mounted) return;
                        setState(() {
                          _offset += details.delta;
                          _isDragging = true;
                        });
                      },
                      onPanEnd: (details) {
                        if (_offset.dx.abs() > constraints.maxWidth * 0.25) {
                          final isRight = _offset.dx > 0;
                          _handleSwipe(isRight);

                          if (!mounted) return;
                          setState(() {
                            _offset = Offset(isRight ? 500 : -500, 0);
                          });

                          Future.delayed(300.ms, () {
                            if (mounted) {
                              setState(() {
                                _offset = Offset.zero;
                                _isDragging = false;
                              });
                            }
                          });
                        } else {
                          if (mounted) {
                            setState(() {
                              _offset = Offset.zero;
                              _isDragging = false;
                            });
                          }
                        }
                      },
                      child: Stack(
                        children: [
                          if (_movies.length > 1)
                            Positioned.fill(
                              child: _buildMovieCard(_movies[1]),
                            ),
                          Positioned.fill(
                            child: _buildMovieCard(_movies[0]),
                          ),
                        ],
                      ),
                    );
            },
          ),
          if (_showTutorial) _buildTutorialOverlay(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class _TutorialCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _TutorialCard({
    required this.icon,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Icon(icon, size: 40, color: color),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}