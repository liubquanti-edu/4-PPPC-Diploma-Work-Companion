import 'package:flutter/material.dart';
import 'package:pppc_companion/services/user_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '/services/storage_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class EditProfilePage extends StatefulWidget {
  final String currentNickname;
  final String currentAvatar;
  final Map<String, dynamic> userData;

  const EditProfilePage({
    Key? key, 
    required this.currentNickname, 
    required this.currentAvatar,
    required this.userData,
  }) : super(key: key);

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _avatarController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _userService = UserService();
  bool _isLoading = false;
  File? _imageFile;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nicknameController.text = widget.currentNickname;
    _avatarController.text = widget.currentAvatar;
    _contactNumberController.text = widget.userData['contactnumber'] ?? '';
    _contactEmailController.text = widget.userData['contactemail'] ?? '';
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _removeAvatar() async {
    setState(() => _isLoading = true);
    try {
      await _userService.removeUserAvatar();
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Аватар успішно видалено')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveChanges() async {
    if (_isLoading || !_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      String? newAvatarUrl;

      // Prepare update data
      final Map<String, dynamic> updateData = {
        'nickname': _nicknameController.text.trim(),
        'contactnumber': _contactNumberController.text.trim(),
        'contactemail': _contactEmailController.text.trim(),
      };

      // Upload new avatar if selected
      if (_imageFile != null) {
        try {
          // Upload new avatar first
          newAvatarUrl = await StorageService.uploadAvatar(_imageFile!, userId);
          debugPrint('New avatar URL: $newAvatarUrl');
          
          if (newAvatarUrl != null) {
            // Add new avatar URL to update data
            updateData['avatar'] = newAvatarUrl;
            
            // Delete old avatar after successful upload and Firestore update
            if (widget.currentAvatar.isNotEmpty) {
              await StorageService.deleteOldAvatar(widget.currentAvatar);
            }
          }
        } catch (e) {
          debugPrint('Error uploading new avatar: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Помилка завантаження аватара: $e')),
            );
          }
          setState(() => _isLoading = false);
          return;
        }
      }

      // Update Firestore document
      await FirebaseFirestore.instance
          .collection('students')
          .doc(userId)
          .update(updateData);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Профіль успішно оновлено')),
        );
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка оновлення профілю: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override 
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Редагувати профіль'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Center(
                child: CircleAvatar(
                  radius: 80,
                  backgroundImage: _imageFile != null 
                    ? FileImage(_imageFile!) as ImageProvider
                    : (widget.currentAvatar.isNotEmpty 
                        ? NetworkImage(widget.currentAvatar) 
                        : const AssetImage('assets/img/noavatar.png')) as ImageProvider,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2.0,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.onSecondary,
                      foregroundColor: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: _pickImage,
                    child: const Text('Змінити фото'),
                  ),
                  if (widget.currentAvatar.isNotEmpty && _imageFile == null) ...[
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.onSecondary,
                        foregroundColor: Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: _isLoading ? null : _removeAvatar,
                      child: const Text('Видалити фото'),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nicknameController,
                decoration: const InputDecoration(
                  labelText: 'Нікнейм',
                  border: OutlineInputBorder(),
                  helperText: 'Можна використовувати англійські букви, цифри, крапку та нижнє підкреслення',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Будь ласка, введіть нікнейм';
                  }
                  if (value.length < 3) {
                    return 'Нікнейм має бути не менше 3 символів';
                  }
                  if (value.length > 20) {
                    return 'Нікнейм має бути не більше 20 символів';
                  }
                  if (!RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(value)) {
                    return 'Дозволені лише англійські букви, цифри, крапка та нижнє підкреслення';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _contactNumberController,
                decoration: const InputDecoration(
                  labelText: 'Контактний номер',
                  border: OutlineInputBorder(),
                  helperText: 'Номер телефону для зв\'язку',
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _contactEmailController,
                decoration: const InputDecoration(
                  labelText: 'Контактна пошта',
                  border: OutlineInputBorder(),
                  helperText: 'Електронна пошта для зв\'язку',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Введіть коректний email';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _saveChanges,
                    child: const Text('Зберегти'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.onSecondary,
                      foregroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _avatarController.dispose();
    _contactNumberController.dispose();
    _contactEmailController.dispose();
    super.dispose();
  }
}