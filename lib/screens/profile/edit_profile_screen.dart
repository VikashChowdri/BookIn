import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../data/services/database_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/storage_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  
  UserModel? _userModel;
  bool _isLoading = false;
  bool _isUploadingImage = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_userModel == null) {
      final args = ModalRoute.of(context)?.settings.arguments as UserModel?;
      if (args != null) {
        _userModel = args;
        _nameController.text = args.publicName;
        _usernameController.text = args.username;
        _phoneController.text = args.phone ?? '';
        _bioController.text = args.bio ?? '';
      } else {
        // Fallback if user model doesn't exist yet
        final user = AuthService.instance.currentUser;
        if (user != null) {
          _userModel = UserModel(
            id: user.uid,
            username: user.email?.split('@').first ?? 'user',
            email: user.email ?? '',
            publicName: user.displayName ?? 'BookIn User',
            profilePictureUrl: '',
            createdAt: DateTime.now(),
          );
          _nameController.text = _userModel!.publicName;
          _usernameController.text = _userModel!.username;
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: GestureDetector(
                    onTap: _isUploadingImage ? null : _showAvatarOptions,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                          backgroundImage: _userModel?.profilePictureUrl != null &&
                                  _userModel!.profilePictureUrl.isNotEmpty &&
                                  !_userModel!.profilePictureUrl.contains('unsplash')
                              ? CachedNetworkImageProvider(_userModel!.profilePictureUrl)
                              : null,
                          child: _userModel?.profilePictureUrl == null || 
                                  _userModel!.profilePictureUrl.isEmpty || 
                                  _userModel!.profilePictureUrl.contains('unsplash')
                              ? Text(
                                  _nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : 'U',
                                  style: theme.textTheme.headlineLarge?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        if (_isUploadingImage)
                          Positioned.fill(
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.black45,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            radius: 17,
                            backgroundColor: theme.colorScheme.primary,
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              size: 17,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Public Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (val) =>
                      val != null && val.isNotEmpty ? null : 'Name cannot be empty',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(Icons.alternate_email),
                  ),
                  validator: (val) =>
                      val != null && val.length >= 3 ? null : 'Minimum 3 characters',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _bioController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Bio / Favorite Genres',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.info_outline),
                  ),
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSave,
                  child: _isLoading 
                    ? const SizedBox(
                        height: 20, 
                        width: 20, 
                        child: CircularProgressIndicator(strokeWidth: 2)
                      )
                    : const Text('Save Changes'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAvatarOptions() {
    final hasPhoto = _userModel?.profilePictureUrl != null &&
        _userModel!.profilePictureUrl.isNotEmpty &&
        !_userModel!.profilePictureUrl.contains('unsplash');

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Profile Picture',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.camera_alt_rounded, color: theme.colorScheme.primary),
                ),
                title: const Text('Take Photo', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Capture with device camera'),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _uploadWithSource(ImageSource.camera);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: Colors.green),
                ),
                title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Pick an existing photo'),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _uploadWithSource(ImageSource.gallery);
                },
              ),
              if (hasPhoto) ...[
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                  ),
                  title: const Text('Remove Photo', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Revert to initial avatar'),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _removeProfileImage();
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _uploadWithSource(ImageSource source) async {
    if (_userModel == null) return;
    
    setState(() => _isUploadingImage = true);
    try {
      final newUrl = await StorageService.instance.pickAndUploadProfilePicture(
        context,
        _userModel!.id,
        source: source,
      );
      if (newUrl != null) {
        setState(() {
          _userModel = _userModel!.copyWith(profilePictureUrl: newUrl);
        });
        await DatabaseService.instance.updateUserProfile(_userModel!);
        try {
          await AuthService.instance.currentUser?.updatePhotoURL(newUrl);
        } catch (_) {}
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture updated!'),
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
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _removeProfileImage() async {
    if (_userModel == null) return;
    setState(() {
      _userModel = _userModel!.copyWith(profilePictureUrl: '');
    });
    try {
      await DatabaseService.instance.updateUserProfile(_userModel!);
      try {
        await AuthService.instance.currentUser?.updatePhotoURL(null);
      } catch (_) {}
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture removed'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove photo: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate() || _userModel == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      final newUsername = _usernameController.text.trim();
      
      // If username changed, check availability
      if (newUsername != _userModel!.username) {
        final isAvailable = await DatabaseService.instance.isUsernameAvailable(newUsername);
        if (!isAvailable) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Username is already taken.')),
          );
          setState(() => _isLoading = false);
          return;
        }
      }
      
      final updatedUser = _userModel!.copyWith(
        publicName: _nameController.text.trim(),
        username: newUsername,
        phone: _phoneController.text.trim(),
        bio: _bioController.text.trim(),
      );
      
      await DatabaseService.instance.updateUserProfile(updatedUser);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}