import 'package:flutter/material.dart';
import 'package:pppc_companion/services/user_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '/services/imgbb_service.dart';

class EditProfilePage extends StatefulWidget {
  final String currentNickname;
  final String currentAvatar;

  const EditProfilePage({Key? key, required this.currentNickname, required this.currentAvatar}) : super(key: key);

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _avatarController = TextEditingController();
  final _userService = UserService();
  bool _isLoading = false;
  File? _imageFile;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nicknameController.text = widget.currentNickname;
    _avatarController.text = widget.currentAvatar;
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_imageFile != null) {
        final imageUrl = await ImgbbService.uploadImage(_imageFile!);
        await _userService.updateUserAvatar(imageUrl); 
      }
      if (_nicknameController.text != widget.currentNickname) {
        await _userService.updateUserNickname(_nicknameController.text);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Профіль успішно оновлено')),
        );
        Navigator.pop(context);
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

  // Add method to handle avatar deletion
  Future<void> _removeAvatar() async {
    setState(() => _isLoading = true);
    try {
      await _userService.removeUserAvatar();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Аватар видалено')),
        );
        Navigator.pop(context);
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
                    onPressed: _pickImage,
                    child: const Text('Змінити фото'),
                  ),
                  if (widget.currentAvatar.isNotEmpty && _imageFile == null) ...[
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _removeAvatar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                        foregroundColor: Theme.of(context).colorScheme.onError,
                      ),
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
              _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _saveChanges,
                    child: const Text('Зберегти'),
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
    super.dispose();
  }
}