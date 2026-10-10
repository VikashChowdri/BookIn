import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../data/services/database_service.dart';

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
                      const CircleAvatar(
                        radius: 48,
                        backgroundColor: Colors.indigo,
                        child: Icon(Icons.person, size: 50, color: Colors.white),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: const Icon(
                            Icons.camera_alt,
                            size: 16,
                            color: Colors.white,
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