import 'package:flutter/material.dart';
import 'package:pppc_companion/services/user_service.dart';

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

  @override
  void initState() {
    super.initState();
    _nicknameController.text = widget.currentNickname;
    _avatarController.text = widget.currentAvatar;
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_avatarController.text.isNotEmpty) {
        await _userService.updateUserAvatar(_avatarController.text);
      }
      await _userService.updateUserNickname(_nicknameController.text);
      
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
    }

    if (mounted) {
      setState(() => _isLoading = false);
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
                controller: _avatarController,
                decoration: const InputDecoration(
                  labelText: 'URL аватара',
                  border: OutlineInputBorder(),
                  helperText: 'Введіть посилання на зображення в інтернеті',
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    try {
                      final uri = Uri.parse(value);
                      if (!uri.isAbsolute) {
                        return 'Введіть коректне URL посилання';
                      }
                    } catch (e) {
                      return 'Введіть коректне URL посилання';
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