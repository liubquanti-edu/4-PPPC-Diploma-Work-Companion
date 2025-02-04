import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pppc_companion/services/user_service.dart';
import 'package:pppc_companion/pages/auth/email_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'setings/edit_profile.dart';
import 'setings/appearance.dart';
import 'setings/about_page.dart';
import 'setings/privacy.dart';
import '/models/avatars.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pppc_companion/services/badges_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _userService.getUserData(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Помилка: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>?;
        
        return Scaffold(
          appBar: AppBar(),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CachedAvatar(
                    imageUrl: userData?['avatar'],
                    radius: 80,
                  ),
                  const SizedBox(height: 5.0, width: double.infinity),
                  Text(
                    '${userData?['surname'] ?? ''} ${userData?['name'] ?? ''}',
                    style: TextStyle(fontSize: 22),
                  ),
                  Text(
                    '@${userData?['nickname'] ?? ''}',
                    style: TextStyle(fontSize: 14),
                  ),
                  Text(
                    'Студент • ${userData?['group'] ?? ''}-та група',
                    style: TextStyle(fontSize: 12),
                  ),
                  Text(
                    'Інженерія програмного забезпечення',
                    style: TextStyle(fontSize: 12),
                  ),
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('students')
                        .doc(_auth.currentUser?.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return const SizedBox.shrink();
                      }

                      final userData = snapshot.data!.data() as Map<String, dynamic>;
                      final badges = (userData['badges'] as List?)?.cast<String>() ?? [];

                      if (badges.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return Container(
                        width: double.infinity,
                        height: 50,
                        padding: const EdgeInsets.all(12.0),
                        margin: const EdgeInsets.only(top: 10.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onSecondary,
                          borderRadius: BorderRadius.circular(10.0),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2.0,
                          ),
                        ),
                        child: Center(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: badges.map((badgeId) {
                              return FutureBuilder<Map<String, dynamic>?>(
                                future: BadgeService().getBadge(badgeId),
                                builder: (context, badgeSnapshot) {
                                  if (!badgeSnapshot.hasData) return const SizedBox.shrink();
                                  final badge = badgeSnapshot.data!;
                                  return InkWell(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          icon: SvgPicture.asset(
                                            'assets/badges/${badge['logo']}.svg',
                                            colorFilter: ColorFilter.mode(
                                              Theme.of(context).colorScheme.primary,
                                              BlendMode.srcIn
                                            ),
                                            height: 48,
                                            width: 48,
                                          ),
                                          title: Text(
                                            badge['name'],
                                            textAlign: TextAlign.center,
                                          ),
                                          content: Text(
                                            badge['description'],
                                            textAlign: TextAlign.center,
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text('Закрити'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    child: Tooltip(
                                      message: '${badge['name']}\n${badge['description']}',
                                      textAlign: TextAlign.center,
                                      child: SvgPicture.asset(
                                        'assets/badges/${badge['logo']}.svg',
                                        colorFilter: ColorFilter.mode(
                                          Theme.of(context).colorScheme.primary,
                                          BlendMode.srcIn
                                        ),
                                        height: 24,
                                        width: 24,
                                      ),
                                    ),
                                  );
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: InkWell(
                      customBorder: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditProfilePage(
                              currentNickname: userData?['nickname'] ?? '',
                              currentAvatar: userData?['avatar'] ?? '',
                              userData: userData ?? {}, // Pass userData here
                            ),
                          ),
                        );
                        if (mounted) {
                          setState(() {});
                        }
                      },
                      child: Ink(
                        padding: const EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onSecondary,
                          borderRadius: BorderRadius.circular(10.0),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              height: 50,
                              width: 50,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceContainer,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Icon(
                                  Icons.person_rounded,
                                  size: 30.0,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10.0),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Профіль', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 16.0)),
                                Text('Редагувати інформацію', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 12.0)),
                              ],
                            ),
                            const SizedBox(width: 10.0),
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Icon(Icons.arrow_forward, size: 30.0, color: Theme.of(context).colorScheme.primary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: InkWell(
                      customBorder: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AppearanceSettings(),
                          ),
                        );
                      },
                      child: Ink(
                        padding: const EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onSecondary,
                          borderRadius: BorderRadius.circular(10.0),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              height: 50,
                              width: 50,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceContainer,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Icon(
                                  Icons.palette_rounded,
                                  size: 30.0,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10.0),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Зовнішній вигляд', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 16.0)),
                                Text('Тема та кольори', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 12.0)),
                              ],
                            ),
                            const SizedBox(width: 10.0),
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Icon(Icons.arrow_forward, size: 30.0, color: Theme.of(context).colorScheme.primary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: InkWell(
                      customBorder: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      onTap: () {
                        Navigator.push(
                          context, 
                          MaterialPageRoute(
                            builder: (context) => const PrivacySettings(),
                          ),
                        );
                      },
                      child: Ink(
                        padding: const EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onSecondary,
                          borderRadius: BorderRadius.circular(10.0),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              height: 50,
                              width: 50,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceContainer,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Icon(
                                  Icons.shield_rounded,
                                  size: 30.0,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10.0),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Приватність', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 16.0)),
                                Text('Захист профілю', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 12.0)),
                              ],
                            ),
                            const SizedBox(width: 10.0),
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Icon(Icons.arrow_forward, size: 30.0, color: Theme.of(context).colorScheme.primary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: InkWell(
                      customBorder: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      onTap: () {
                      
                      },
                      child: Ink(
                        padding: const EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onSecondary,
                          borderRadius: BorderRadius.circular(10.0),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              height: 50,
                              width: 50,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceContainer,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Icon(
                                  Icons.notifications_rounded,
                                  size: 30.0,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10.0),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Сповіщення', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 16.0)),
                                Text('Звуки та фільтри', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 12.0)),
                              ],
                            ),
                            const SizedBox(width: 10.0),
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Icon(Icons.arrow_forward, size: 30.0, color: Theme.of(context).colorScheme.primary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                    Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: InkWell(
                      customBorder: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      ),
                      onTap: () async {
                      final Uri url = Uri.parse('https://t.me/pppccsbot');
                      if (!await launchUrl(url)) {
                        if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                          content: const Text('Не вдалося відкрити посилання'),
                          backgroundColor: Theme.of(context).colorScheme.error,
                          ),
                        );
                        }
                      }
                      },
                      child: Ink(
                      padding: const EdgeInsets.all(10.0),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onSecondary,
                        borderRadius: BorderRadius.circular(10.0),
                        border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2.0,
                        ),
                      ),
                      child: Row(
                        children: [
                        SizedBox(
                          height: 50,
                          width: 50,
                          child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Icon(
                            Icons.sos_rounded,
                            size: 30.0,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          ),
                        ),
                        const SizedBox(width: 10.0),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                          Text('Підтримка', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 16.0)),
                          Text('Технічна допомога', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 12.0)),
                          ],
                        ),
                        const SizedBox(width: 10.0),
                        Expanded(
                          child: Align(
                          alignment: Alignment.centerRight,
                          child: Icon(Icons.arrow_forward, size: 30.0, color: Theme.of(context).colorScheme.primary),
                          ),
                        ),
                        ],
                      ),
                      ),
                    ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: InkWell(
                      customBorder: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AboutPage()),
                        );
                      },
                      child: Ink(
                        padding: const EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onSecondary,
                          borderRadius: BorderRadius.circular(10.0),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              height: 50,
                              width: 50,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceContainer,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Icon(
                                  Icons.info_rounded,
                                  size: 30.0,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10.0),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Про програму', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 16.0)),
                                Text('Версія та розробник', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 12.0)),
                              ],
                            ),
                            const SizedBox(width: 10.0),
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Icon(Icons.arrow_forward, size: 30.0, color: Theme.of(context).colorScheme.primary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: InkWell(
                      customBorder: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      onTap: () async {
                        bool confirmSignOut = await showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Вихід'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 10.0),
                                    child: Container(
                                      decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Theme.of(context).colorScheme.primary,
                                            width: 2.0,
                                          ),
                                          borderRadius: BorderRadius.circular(10.0),
                                        ),
                                        child: ClipRRect(
                                        borderRadius: BorderRadius.circular(10.0),
                                        child: Image.asset(
                                          'assets/gif/spongebob-i-quit.gif',
                                          width: 400,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const Text('Ви впевнені, що хочете вийти з облікового запису?'),
                                ],
                              ),
                              actions: <Widget>[
                                TextButton(
                                  child: const Text('Скасувати'),
                                  onPressed: () {
                                    Navigator.of(context).pop(false);
                                  },
                                ),
                                TextButton(
                                  child: const Text('Вийти'),
                                  onPressed: () {
                                    Navigator.of(context).pop(true);
                                  },
                                ),
                              ],
                            );
                          },
                        ) ?? false;

                        if (!confirmSignOut) {
                          return;
                        }
                        try {
                          await _auth.signOut();
                          if (mounted) {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (context) => const EmailScreen()),
                              (route) => false,
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Помилка виходу: ${e.toString()}'),
                                backgroundColor: Theme.of(context).colorScheme.error,
                              ),
                            );
                          }
                        }
                      },
                      child: Ink(
                        padding: const EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onSecondary,
                          borderRadius: BorderRadius.circular(10.0),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              height: 50,
                              width: 50,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceContainer,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Icon(
                                  Icons.exit_to_app_rounded,
                                  size: 30.0,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10.0),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Вийти',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(fontSize: 16.0)),
                                Text('Вихід з облікового запису',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(fontSize: 12.0)),
                              ],
                            ),
                            const SizedBox(width: 10.0),
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Icon(Icons.arrow_forward,
                                    size: 30.0,
                                    color: Theme.of(context).colorScheme.primary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}