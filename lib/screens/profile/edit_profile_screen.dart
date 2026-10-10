import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../data/services/database_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/storage_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
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
                        const Positioned.fill(
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _isUploadingImage ? null : _pickAndUploadImage,
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: theme.colorScheme.primary,
                            child: const Icon(
                              Icons.camera_alt,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
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

  Future<void> _pickAndUploadImage() async {
    if (_userModel == null) return;
    
    setState(() => _isUploadingImage = true);
    try {
      final newUrl = await StorageService.instance.pickAndUploadProfilePicture(_userModel!.id);
      if (newUrl != null) {
        setState(() {
          _userModel = _userModel!.copyWith(profilePictureUrl: newUrl);
        });
        // Optionally save to database immediately or wait for Save Changes
        await DatabaseService.instance.updateUserProfile(_userModel!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile picture updated!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
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