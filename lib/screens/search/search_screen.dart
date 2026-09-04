import 'package:flutter/material.dart';
import '../../data/dummy_books.dart';
import '../../models/book.dart';
import 'search_results_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  String? _selectedCategory;
  String? _selectedDepartment;
  String _sortBy = 'Newest';

  List<Book> get _suggestions {
    final query = _controller.text.trim().toLowerCase();
    if (query.isEmpty) return [];
    return dummyBooks
        .where((b) =>
            b.title.toLowerCase().contains(query) ||
            b.author.toLowerCase().contains(query) ||
            b.subject.toLowerCase().contains(query))
        .take(5)
        .toList();
  }

  List<String> get _categories =>
      dummyBooks.map((b) => b.category).toSet().toList();
  List<String> get _departments =>
      dummyBooks.map((b) => b.department).toSet().toList();

  void _runSearch(String query) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchResultsScreen(
          query: query,
          category: _selectedCategory,
          department: _selectedDepartment,
          sortBy: _sortBy,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search by title, author, or subject',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onSubmitted: _runSearch,
              onChanged: (_) => setState(() {}),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    hint: const Text('Category'),
                    items: _categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedCategory = v),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedDepartment,
                    hint: const Text('Department'),
                    items: _departments
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedDepartment = v),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                const Text('Sort by: '),
                DropdownButton<String>(
                  value: _sortBy,
                  items: const [
                    DropdownMenuItem(value: 'Newest', child: Text('Newest')),
                    DropdownMenuItem(
                      value: 'Price: Low to High',
                      child: Text('Price: Low to High'),
                    ),
                    DropdownMenuItem(
                      value: 'Price: High to Low',
                      child: Text('Price: High to Low'),
                    ),
                  ],
                  onChanged: (v) => setState(() => _sortBy = v!),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _suggestions.isEmpty
                ? const Center(child: Text('Start typing to see suggestions'))
                : ListView.builder(
                    itemCount: _suggestions.length,
                    itemBuilder: (context, index) {
                      final book = _suggestions[index];
                      return ListTile(
                        leading: const Icon(Icons.menu_book_outlined),
                        title: Text(book.title),
                        subtitle: Text(book.author),
                        onTap: () => _runSearch(book.title),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
