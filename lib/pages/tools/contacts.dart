//-----------------------------------------
//-  Copyright (c) 2025. Liubchenko Oleh  -
//-----------------------------------------

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class TeacherContactsScreen extends StatefulWidget {
  const TeacherContactsScreen({super.key});

  @override
  State<TeacherContactsScreen> createState() => _TeacherContactsScreenState();
}

class _TeacherContactsScreenState extends State<TeacherContactsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchQuery = '';

  Future<void> _makePhoneCall(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      _showErrorSnackBar('Номер телефону недоступний');
      return;
    }

    final Uri url = Uri.parse('tel:$phoneNumber');
    if (!await launchUrl(url)) {
      _showErrorSnackBar('Не вдалося здійснити виклик');
    }
  }

  Future<void> _sendEmail(String? email) async {
    if (email == null || email.isEmpty) {
      _showErrorSnackBar('Електронна пошта недоступна');
      return;
    }

    final Uri url = Uri.parse('mailto:$email');
    if (!await launchUrl(url)) {
      _showErrorSnackBar('Не вдалося відкрити поштовий клієнт');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Контакти викладачів'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Пошук викладача',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.onSecondary,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('teachers').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Помилка завантаження: ${snapshot.error}'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final teachers = snapshot.data!.docs;
                
                if (teachers.isEmpty) {
                  return const Center(
                    child: Text('Список викладачів порожній'),
                  );
                }

                final filteredTeachers = teachers.where((doc) {
                  final teacherData = doc.data() as Map<String, dynamic>;
                  final fullName = '${teacherData['surname'] ?? ''} ${teacherData['name'] ?? ''}'.toLowerCase();
                  return _searchQuery.isEmpty || fullName.contains(_searchQuery);
                }).toList();

                if (filteredTeachers.isEmpty) {
                  return const Center(
                    child: Text('За вашим запитом нічого не знайдено'),
                  );
                }

                return ListView.builder(
                  itemCount: filteredTeachers.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemBuilder: (context, index) {
                    final teacherData = filteredTeachers[index].data() as Map<String, dynamic>;
                    final fullName = '${teacherData['surname'] ?? ''} ${teacherData['name'] ?? ''}';
                    final phone = teacherData['phone'] as String?;
                    final email = teacherData['email'] as String?;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fullName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (phone != null && phone.isNotEmpty)
                              Row(
                                children: [
                                  const Icon(Icons.phone, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(phone)),
                                ],
                              ),
                            if (email != null && email.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    const Icon(Icons.email, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(email)),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (phone != null && phone.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(Icons.call),
                                    color: Theme.of(context).colorScheme.primary,
                                    onPressed: () => _makePhoneCall(phone),
                                    tooltip: 'Зателефонувати',
                                  ),
                                if (email != null && email.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(Icons.email),
                                    color: Theme.of(context).colorScheme.primary, 
                                    onPressed: () => _sendEmail(email),
                                    tooltip: 'Написати листа',
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}