// review_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReviewPage extends StatefulWidget {
  final String movieId;
  final String movieTitle;
  final String posterUrl;

  const ReviewPage({
    super.key,
    required this.movieId,
    required this.movieTitle,
    required this.posterUrl,
  });

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  final TextEditingController _reviewController = TextEditingController();
  final TextEditingController _replyController = TextEditingController();
  final TextEditingController _editReviewController = TextEditingController();
  double _userRating = 5.0;
  double _editUserRating = 5.0;
  String? _replyingToReviewId;
  String? _editingReviewId;
  // TODO: Replace with actual API calls when review endpoints are available
  // Reviews and replies will be fetched from/sent to the backend API
  final List<Map<String, dynamic>> _reviews = [];
  UniqueKey _listKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    // Removed FCM token storage code
  }

  @override
  void dispose() {
    _reviewController.dispose();
    _replyController.dispose();
    _editReviewController.dispose();
    super.dispose();
  }

  void _submitReview() async {
    if (_reviewController.text.isEmpty) return;
    // TODO: Submit review via API
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reviews will be available soon')),
    );
    _reviewController.clear();
    setState(() => _userRating = 5.0);
  }

  void _submitReply(String reviewId) async {
    if (_replyController.text.isEmpty) return;
    // TODO: Submit reply via API
    _replyController.clear();
    setState(() => _replyingToReviewId = null);
  }

  void _deleteReview(String reviewId) async {
    // TODO: Delete review via API
    setState(() => _listKey = UniqueKey());
  }

  void _startEditReview(Map<String, dynamic> review, String reviewId) {
    setState(() {
      _editingReviewId = reviewId;
      _editUserRating = (review['rating'] as num).toDouble();
      _editReviewController.text = review['comment'] ?? '';
    });
  }

  void _submitEditReview() async {
    if (_editReviewController.text.isEmpty || _editingReviewId == null) return;
    // TODO: Update review via API
    setState(() {
      _editingReviewId = null;
      _editReviewController.clear();
      _listKey = UniqueKey();
    });
  }

  Widget _buildRatingIndicator(double avgRating) {
  IconData icon;
  Color color;
  
  if (avgRating >= 8) {
    icon = Icons.sentiment_very_satisfied;
    color = Colors.green;
  } else if (avgRating >= 5) {
    icon = Icons.sentiment_neutral;
    color = Colors.amber;
  } else if (avgRating >= 1) {
    icon = Icons.sentiment_very_dissatisfied;
    color = Colors.red;
  } else {
    icon = Icons.sentiment_neutral;
    color = Colors.white;
  }

  return Chip(
    avatar: Icon(icon, color: color),
    label: Text(
      avgRating.toStringAsFixed(1),
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
    backgroundColor: Colors.grey[800],
  );
}
  Widget _buildReviewInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_editingReviewId == null) ...[
          const Text(
            'Your Rating:',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          Slider(
            value: _userRating,
            min: 1,
            max: 10,
            divisions: 9,
            label: _userRating.round().toString(),
            onChanged: (value) => setState(() => _userRating = value),
            activeColor: const Color(0xFFD94CF7),
            inactiveColor: Colors.grey[800],
          ),
          TextField(
            controller: _reviewController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Write your review...',
              hintStyle: const TextStyle(color: Colors.white54),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[900],
              suffixIcon: IconButton(
                icon: const Icon(Icons.send, color: Color(0xFFD94CF7)),
                onPressed: _submitReview,
              ),
            ),
            maxLines: 3,
          ),
        ] else ...[
          const Text(
            'Edit Rating:',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          Slider(
            value: _editUserRating,
            min: 1,
            max: 10,
            divisions: 9,
            label: _editUserRating.round().toString(),
            onChanged: (value) => setState(() => _editUserRating = value),
            activeColor: const Color(0xFFD94CF7),
            inactiveColor: Colors.grey[800],
          ),
          TextField(
            controller: _editReviewController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Edit your review...',
              hintStyle: const TextStyle(color: Colors.white54),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[900],
              suffixIcon: IconButton(
                icon: const Icon(Icons.save, color: Color(0xFFD94CF7)),
                onPressed: _submitEditReview,
              ),
            ),
            maxLines: 3,
          ),
          TextButton(
            onPressed: () => setState(() => _editingReviewId = null),
            child: const Text(
              'Cancel Editing',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildReviewItem(Map<String, dynamic> review, String reviewId) {
    final List<Map<String, dynamic>> replies = 
        (review['replies'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                review['userName'] ?? 'Anonymous',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Chip(
                label: Text(
                  (review['rating'] as num?)?.round().toString() ?? '0',
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            review['comment'] ?? '',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          ...replies.map((reply) {
            return Padding(
              padding: const EdgeInsets.only(left: 16, top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('↪ ', style: TextStyle(color: Colors.white54)),
                      Text(
                        reply['userName'] ?? 'Anonymous',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Text(
                      reply['comment'] ?? '',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            );
          }),
          TextButton(
            onPressed: () => setState(() {
              _replyingToReviewId = 
                _replyingToReviewId == reviewId ? null : reviewId;
            }),
            child: Text(
              _replyingToReviewId == reviewId ? 'Cancel' : 'Reply',
              style: const TextStyle(color: Color(0xFFD94CF7)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.movieTitle),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[900],
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      widget.posterUrl,
                      width: 80,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, _, __) => Container(
                        color: Colors.grey[800],
                        child: const Icon(Icons.movie, color: Colors.white54),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.movieTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // TODO: Replace with API-backed rating summary
                        _buildRatingIndicator(0.0),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildReviewInput(),
                  const SizedBox(height: 20),
                  // TODO: Replace with API-backed review list
                  if (_reviews.isEmpty)
                    const Center(
                      child: Text(
                        'No reviews yet. Be the first!',
                        style: TextStyle(color: Colors.white54)),
                    )
                  else
                    ListView.builder(
                      key: _listKey,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _reviews.length,
                      itemBuilder: (context, index) {
                        final review = _reviews[index];
                        return _buildReviewItem(review, review['id'] ?? index.toString());
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}