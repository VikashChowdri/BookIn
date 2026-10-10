import 'package:flutter/material.dart';
import '../../models/book.dart';
import '../../models/user_model.dart';
import '../../data/services/database_service.dart';
import '../../routes/app_routes.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/chat_service.dart';
import '../../utils/favorites_manager.dart';
import '../../widgets/book_card.dart';
import '../review/reviews_list_widget.dart';

class PublicProfileScreen extends StatelessWidget {
  final UserModel user;

  const PublicProfileScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(user.publicName),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: theme.colorScheme.primary,
              backgroundImage: user.profilePictureUrl.isNotEmpty && 
                              !user.profilePictureUrl.contains('unsplash')
                  ? NetworkImage(user.profilePictureUrl)
                  : null,
              child: user.profilePictureUrl.isEmpty || user.profilePictureUrl.contains('unsplash')
                  ? Text(
                      user.publicName.isNotEmpty ? user.publicName[0].toUpperCase() : 'U',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              user.publicName,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '@${user.username}',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                final currentUserId = AuthService.instance.currentUser?.uid;
                if (currentUserId == null || currentUserId == user.id) return;
                
                // Show loading
                showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
                try {
                  final roomId = await ChatService.instance.getOrCreateChatRoom(user.id);
                  if (context.mounted) {
                    Navigator.pop(context); // pop loading
                    Navigator.pushNamed(
                      context,
                      AppRoutes.chatDetail,
                      arguments: {
                        'roomId': roomId,
                        'otherUser': user,
                      },
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context); // pop loading
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error starting chat: $e')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.chat_bubble_rounded, size: 20),
              label: const Text('Message'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(140, 40),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Books by ${user.publicName}',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<Book>>(
              stream: DatabaseService.instance.getUserBooksStream(user.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error loading books: ${snapshot.error}'),
                  );
                }

                final books = snapshot.data ?? [];

                if (books.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        'No books listed yet.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  );
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.65,
                  ),
                  itemCount: books.length,
                  itemBuilder: (context, index) {
                    final book = books[index];
                    return BookCard(
                      book: book,
                      isGridMode: true,
                      isWishlist: FavoritesManager.instance.isWishlist(book),
                      onWishlistTap: () {
                        // The widget is stateful so we shouldn't necessarily call setState here 
                        // if we want to update the BookCard, but BookCard doesn't manage its own state.
                        // So wait, maybe we should just rely on a parent rebuild or just let it be since it's simple.
                        // Actually, we can just call FavoritesManager.instance.toggleWishlist(book); and 
                        // rebuilding might happen or not. Since it's a simple app, let's just do it.
                        // We are in a builder anyway. Actually we are in a StatelessWidget? Let's check!
                        FavoritesManager.instance.toggleWishlist(book);
                      },
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.bookDetails,
                          arguments: book,
                        );
                      },
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            ReviewsListWidget(
              targetId: user.id,
              targetType: 'user',
              targetName: user.publicName,
            ),
          ],
        ),
      ),
    );
  }
}
