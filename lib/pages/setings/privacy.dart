import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PrivacySettings extends StatefulWidget {
  const PrivacySettings({Key? key}) : super(key: key);

  @override
  State<PrivacySettings> createState() => _PrivacySettingsState();
}

class _PrivacySettingsState extends State<PrivacySettings> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  bool _isPrivate = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrivacySettings();
  }

  Future<void> _loadPrivacySettings() async {
    final doc = await _firestore
        .collection('students')
        .doc(_auth.currentUser!.uid)
        .get();
    
    if (mounted) {
      setState(() {
        _isPrivate = doc.data()?['isPrivate'] ?? false;
        _isLoading = false;
      });
    }
  }

  Future<void> _updatePrivacySettings(bool value) async {
    setState(() => _isLoading = true);
    
    try {
      await _firestore
          .collection('students')
          .doc(_auth.currentUser!.uid)
          .update({'isPrivate': value});
      
      if (mounted) {
        setState(() {
          _isPrivate = value;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Налаштування оновлено')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Приватність'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
                color: Theme.of(context).colorScheme.onSecondary,
                child: SwitchListTile(
                  title: const Text('Приховати профіль'),
                  subtitle: const Text('Ваш профіль не буде відображатися в пошуку'),
                  value: _isPrivate,
                  onChanged: _updatePrivacySettings,
                ),
              ),
            ),
    );
  }
}