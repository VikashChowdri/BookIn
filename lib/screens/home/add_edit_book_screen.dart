import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/database_service.dart';
import '../../data/services/storage_service.dart';
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
  late final TextEditingController _rentPriceController;
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

  bool _offerForSale = true;
  bool _offerForRent = false;

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
    _rentPriceController = TextEditingController(
      text: book != null && book.rentPrice > 0 ? book.rentPrice.toStringAsFixed(0) : '',
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
    if (book != null) {
      _offerForSale = book.price > 0;
      _offerForRent = book.rentPrice > 0;
      if (!_offerForSale && !_offerForRent) {
        _offerForSale = true;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _subjectController.dispose();
    _priceController.dispose();
    _rentPriceController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  bool _isLoading = false;
  bool _isUploadingCover = false;
  bool _showUrlField = false;

  Future<void> _pickAndUploadCover() async {
    setState(() => _isUploadingCover = true);
    try {
      final downloadUrl = await StorageService.instance.pickAndUploadBookImage(
        context,
        bookId: widget.book?.id,
      );
      if (downloadUrl != null) {
        setState(() {
          _imageUrlController.text = downloadUrl;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Book cover uploaded successfully!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingCover = false);
    }
  }

  Future<void> _saveBook() async {
    if (!_offerForSale && !_offerForRent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one option: Sell or Rent')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final currentUser = AuthService.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to post a book.')),
      );
      return;
    }

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
        sellerName: currentUser.displayName ?? 'User',
        sellerId: currentUser.uid,
        available: _isAvailable,
        price: _offerForSale ? (double.tryParse(_priceController.text.trim()) ?? 0) : 0,
        rentPrice: _offerForRent ? (double.tryParse(_rentPriceController.text.trim()) ?? 0) : 0,
        status: _isAvailable ? 'available' : widget.book?.status ?? 'sold',
      );

      if (_isEditMode) {
        await DatabaseService.instance.updateBook(newBook);
      } else {
        await DatabaseService.instance.addBook(newBook);
      }

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      
      messenger.showSnackBar(
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
            onPressed: _isLoading ? null : _saveBook,
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
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
              // ── Book Cover Section ──
              _buildImagePreview(theme, isDark),

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

              // ── Category ──
              _buildSectionLabel(theme, 'Category *'),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                isExpanded: true,
                hint: const Text('Select Category'),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: _categories
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c, overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _selectedCategory = v),
                validator: (v) =>
                    v == null ? 'Pick a category' : null,
              ),

              const SizedBox(height: 16),

              // ── Department ──
              _buildSectionLabel(theme, 'Department *'),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _selectedDepartment,
                isExpanded: true,
                hint: const Text('Select Department'),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.school_outlined),
                ),
                items: _departments
                    .map((d) => DropdownMenuItem(
                          value: d,
                          child: Text(d, overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _selectedDepartment = v),
                validator: (v) =>
                    v == null ? 'Pick a department' : null,
              ),

              const SizedBox(height: 16),

              _buildSectionLabel(theme, 'Selling Options *'),
              const SizedBox(height: 6),
              CheckboxListTile(
                title: const Text('Offer for Sale'),
                value: _offerForSale,
                onChanged: (v) => setState(() => _offerForSale = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                activeColor: theme.colorScheme.primary,
              ),
              if (_offerForSale) ...[
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    hintText: 'Selling Price (e.g. 250)',
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
              ],
              
              CheckboxListTile(
                title: const Text('Offer for Rent'),
                value: _offerForRent,
                onChanged: (v) => setState(() => _offerForRent = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                activeColor: theme.colorScheme.primary,
              ),
              if (_offerForRent) ...[
                TextFormField(
                  controller: _rentPriceController,
                  decoration: const InputDecoration(
                    hintText: 'Rent Price per day (e.g. 10)',
                    prefixIcon: Icon(Icons.currency_rupee_rounded),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Rent price is required';
                    final price = double.tryParse(v.trim());
                    if (price == null || price <= 0) {
                      return 'Enter a valid rent price';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],

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
                                ? 'Book is available for sale/rent'
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
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveBook,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isEditMode
                                  ? Icons.save_rounded
                                  : Icons.publish_rounded,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isEditMode ? 'Save Changes' : 'Post Book',
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

  // ─────────────────────────── Image Preview ──────────────────────────────

  Widget _buildImagePreview(ThemeData theme, bool isDark) {
    final url = _imageUrlController.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(theme, 'Book Cover'),
        const SizedBox(height: 8),
        InkWell(
          onTap: _isUploadingCover ? null : _pickAndUploadCover,
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBackground : AppColors.shimmerBase,
              borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 1.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (url.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      errorWidget: (context, url, error) =>
                          _imagePlaceholder(theme, isError: true),
                    )
                  else
                    _imagePlaceholder(theme),

                  // Uploading progress overlay
                  if (_isUploadingCover)
                    Container(
                      color: Colors.black54,
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: Colors.white),
                            SizedBox(height: 12),
                            Text(
                              'Uploading book cover...',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Quick action buttons overlay when an image is present
                  if (url.isNotEmpty && !_isUploadingCover)
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
                              tooltip: 'Change Photo',
                              onPressed: _pickAndUploadCover,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                              tooltip: 'Remove Photo',
                              onPressed: () => setState(() => _imageUrlController.clear()),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: _isUploadingCover ? null : _pickAndUploadCover,
              icon: const Icon(Icons.add_a_photo_rounded, size: 18),
              label: Text(url.isEmpty ? 'Take or Pick Photo' : 'Change Photo'),
            ),
            TextButton(
              onPressed: () => setState(() => _showUrlField = !_showUrlField),
              child: Text(
                _showUrlField ? 'Hide URL input' : 'Enter image URL',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        if (_showUrlField) ...[
          const SizedBox(height: 4),
          TextFormField(
            controller: _imageUrlController,
            decoration: const InputDecoration(
              hintText: 'https://example.com/book-cover.jpg',
              prefixIcon: Icon(Icons.link_rounded),
            ),
            keyboardType: TextInputType.url,
            onChanged: (_) => setState(() {}),
          ),
        ],
      ],
    );
  }

  Widget _imagePlaceholder(ThemeData theme, {bool isError = false}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isError ? Icons.broken_image_outlined : Icons.add_a_photo_outlined,
              size: 36,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isError ? 'Could not load image' : 'Tap to take or choose book photo',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Camera or Gallery',
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
