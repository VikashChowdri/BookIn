import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../data/dummy_books.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/database_service.dart';
import '../../models/book.dart';

class AddEditBookScreen extends StatefulWidget {
  final Book? book; // null = Add mode, non-null = Edit mode

  const AddEditBookScreen({super.key, this.book});

  @override
  State<AddEditBookScreen> createState() => _AddEditBookScreenState();
}

class _AddEditBookScreenState extends State<AddEditBookScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _authorController;
  late final TextEditingController _subjectController;
  late final TextEditingController _priceController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _imageUrlController;

  String? _selectedCategory;
  String? _selectedDepartment;
  bool _isAvailable = true;

  bool get _isEditMode => widget.book != null;

  final List<String> _categories = [
    'Engineering',
    'Science',
    'Arts',
    'Commerce',
    'Medical',
    'Law',
    'Other',
  ];

  final List<String> _departments = [
    'CSE',
    'ECE',
    'EEE',
    'Mechanical',
    'Civil',
    'Biotech',
    'IT',
    'Chemical',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    final book = widget.book;
    _titleController = TextEditingController(text: book?.title ?? '');
    _authorController = TextEditingController(text: book?.author ?? '');
    _subjectController = TextEditingController(text: book?.subject ?? '');
    _priceController = TextEditingController(
      text: book != null ? book.price.toStringAsFixed(0) : '',
    );
    _descriptionController =
        TextEditingController(text: book?.description ?? '');
    _imageUrlController =
        TextEditingController(text: book?.imageUrl ?? '');
    _selectedCategory =
        book != null && _categories.contains(book.category)
            ? book.category
            : null;
    _selectedDepartment =
        book != null && _departments.contains(book.department)
            ? book.department
            : null;
    _isAvailable = book?.available ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _subjectController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  bool _isLoading = false;

  Future<void> _saveBook() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() { _isLoading = true; });

    try {
      final newBook = Book(
        id: _isEditMode
            ? widget.book!.id
            : '', // Firestore will generate the ID
        title: _titleController.text.trim(),
        author: _authorController.text.trim(),
        subject: _subjectController.text.trim(),
        category: _selectedCategory ?? 'Other',
        department: _selectedDepartment ?? 'Other',
        imageUrl: _imageUrlController.text.trim(),
        description: _descriptionController.text.trim(),
        sellerName: AuthService.instance.currentUser?.displayName ?? 'User',
        sellerId: AuthService.instance.currentUser?.uid ?? 'unknown',
        available: _isAvailable,
        price: double.tryParse(_priceController.text.trim()) ?? 0,
      );

      if (_isEditMode) {
        await DatabaseService.instance.updateBook(newBook);
      } else {
        await DatabaseService.instance.addBook(newBook);
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditMode
                ? '"${newBook.title}" updated successfully'
                : '"${newBook.title}" added successfully',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save book: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Book' : 'Add New Book'),
        actions: [
          TextButton.icon(
            onPressed: _saveBook,
            icon: Icon(
                _isEditMode ? Icons.save_rounded : Icons.check_rounded,
                size: 20),
            label: Text(_isEditMode ? 'Save' : 'Post'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image Preview ──
              _buildImagePreview(theme, isDark),

              const SizedBox(height: 20),

              // ── Image URL ──
              _buildSectionLabel(theme, 'Book Cover URL'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(
                  hintText: 'https://example.com/book-cover.jpg',
                  prefixIcon: Icon(Icons.link_rounded),
                ),
                keyboardType: TextInputType.url,
                onChanged: (_) => setState(() {}),
              ),

              const SizedBox(height: 20),

              // ── Title ──
              _buildSectionLabel(theme, 'Book Title *'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Introduction to Algorithms',
                  prefixIcon: Icon(Icons.title_rounded),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Title is required'
                    : null,
              ),

              const SizedBox(height: 16),

              // ── Author ──
              _buildSectionLabel(theme, 'Author *'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _authorController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Thomas H. Cormen',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Author is required'
                    : null,
              ),

              const SizedBox(height: 16),

              // ── Subject ──
              _buildSectionLabel(theme, 'Subject *'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _subjectController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Computer Science',
                  prefixIcon: Icon(Icons.subject_rounded),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Subject is required'
                    : null,
              ),

              const SizedBox(height: 16),

              // ── Category & Department Row ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionLabel(theme, 'Category *'),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedCategory,
                          hint: const Text('Select'),
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.category_outlined),
                          ),
                          items: _categories
                              .map((c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c),
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedCategory = v),
                          validator: (v) =>
                              v == null ? 'Pick a category' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionLabel(theme, 'Department *'),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedDepartment,
                          hint: const Text('Select'),
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.school_outlined),
                          ),
                          items: _departments
                              .map((d) => DropdownMenuItem(
                                    value: d,
                                    child: Text(d),
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedDepartment = v),
                          validator: (v) =>
                              v == null ? 'Pick a department' : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── Price ──
              _buildSectionLabel(theme, 'Price (${AppConstants.defaultCurrencySymbol}) *'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  hintText: 'e.g. 250',
                  prefixIcon: Icon(Icons.currency_rupee_rounded),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Price is required';
                  final price = double.tryParse(v.trim());
                  if (price == null || price <= 0) {
                    return 'Enter a valid price';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // ── Description ──
              _buildSectionLabel(theme, 'Description'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  hintText: 'Describe the book condition, edition, etc.',
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
              ),

              const SizedBox(height: 20),

              // ── Availability Toggle ──
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusMedium),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isAvailable
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      color: _isAvailable
                          ? AppColors.success
                          : AppColors.error,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Availability',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _isAvailable
                                ? 'Book is available for sale/exchange'
                                : 'Book is marked as sold',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isAvailable,
                      onChanged: (v) =>
                          setState(() => _isAvailable = v),
                      activeThumbColor: AppColors.success,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Submit Button ──
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saveBook,
                  icon: Icon(
                    _isEditMode
                        ? Icons.save_rounded
                        : Icons.publish_rounded,
                    size: 20,
                  ),
                  label: Text(
                      _isEditMode ? 'Save Changes' : 'Post Book'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────── Image Preview ──────────────────────────────

  Widget _buildImagePreview(ThemeData theme, bool isDark) {
    final url = _imageUrlController.text.trim();

    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.shimmerBase,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        child: url.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                errorWidget: (context, url, error) =>
                    _imagePlaceholder(theme, isError: true),
              )
            : _imagePlaceholder(theme),
      ),
    );
  }

  Widget _imagePlaceholder(ThemeData theme, {bool isError = false}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isError ? Icons.broken_image_outlined : Icons.add_photo_alternate_outlined,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 8),
          Text(
            isError ? 'Invalid image URL' : 'Add a book cover image',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── Section Label ──────────────────────────────

  Widget _buildSectionLabel(ThemeData theme, String label) {
    return Text(
      label,
      style: theme.textTheme.bodySmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
