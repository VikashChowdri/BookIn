import 'package:flutter/material.dart';
import '../../models/review.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/database_service.dart';
import '../../models/user_model.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';

class ReviewDialog extends StatefulWidget {
  final String targetId;
  final String targetType; // 'book' or 'user'
  final String targetName; // e.g. Book title or User name

  const ReviewDialog({
    super.key,
    required this.targetId,
    required this.targetType,
    required this.targetName,
  });

  @override
  State<ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<ReviewDialog> {
  final _commentController = TextEditingController();
  double _rating = 5.0;
  bool _isLoading = false;

  void _submitReview() async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a comment')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final currentUser = AuthService.instance.currentUser;
      if (currentUser == null) throw Exception('Not logged in');

      final userProfile = await DatabaseService.instance.getUserProfile(currentUser.uid);

      final review = Review(
        id: '',
        targetId: widget.targetId,
        targetType: widget.targetType,
        reviewerId: currentUser.uid,
        reviewerName: userProfile?.publicName ?? 'Anonymous',
        rating: _rating,
        comment: _commentController.text.trim(),
        createdAt: DateTime.now(),
      );

      await DatabaseService.instance.addReview(review);

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Review for ${widget.targetName} submitted!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit review: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: Text('Review ${widget.targetName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                icon: Icon(
                  index < _rating ? Icons.star_rounded : Icons.star_border_rounded,
                  color: Colors.amber,
                  size: 32,
                ),
                onPressed: () {
                  setState(() {
                    _rating = index + 1.0;
                  });
                },
              );
            }),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Write your review here...',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitReview,
          child: _isLoading 
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
            : const Text('Submit'),
        ),
      ],
    );
  }
}
