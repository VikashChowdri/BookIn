import 'package:flutter/material.dart';
import '../../models/book.dart';
import '../../models/user_model.dart';
import '../../data/services/database_service.dart';
import '../../routes/app_routes.dart';
import '../../widgets/book_card.dart';

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
          ],
        ),
      ),
    );
  }
}
