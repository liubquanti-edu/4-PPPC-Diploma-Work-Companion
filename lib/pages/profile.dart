import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
              radius: 80,
              backgroundImage: AssetImage('assets/img/oleh.png'),
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
              const SizedBox(height: 5.0, width: double.infinity),
              Text(
                'Любченко Олег',
                style: TextStyle(fontSize: 22),
              ),
              Text(
                '@liubquanti',
                style: TextStyle(fontSize: 14),
              ),
              Text(
                'Студент • 45-та група',
                style: TextStyle(fontSize: 12),
              ),
              Text(
                'Інженерія програмного забезпечення',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 10.0, width: double.infinity),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.numbers_rounded, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 10.0),
                    Icon(Icons.code, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 10.0),
                    Icon(Icons.local_police_rounded, color: Theme.of(context).colorScheme.primary),
                  ],
                ),
              ),
              const SizedBox(height: 10.0, width: double.infinity),
              Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Container(
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceBright,
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(
                        color: Theme.of(context).colorScheme.primary, width: 2.0),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        height: 50,
                        width: 50,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHigh,
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
              Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Container(
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceBright,
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(
                        color: Theme.of(context).colorScheme.primary, width: 2.0),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        height: 50,
                        width: 50,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHigh,
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
              Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Container(
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceBright,
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(
                        color: Theme.of(context).colorScheme.primary, width: 2.0),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        height: 50,
                        width: 50,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHigh,
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
              Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Container(
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceBright,
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(
                        color: Theme.of(context).colorScheme.primary, width: 2.0),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        height: 50,
                        width: 50,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHigh,
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
              Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Container(
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceBright,
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(
                        color: Theme.of(context).colorScheme.primary, width: 2.0),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        height: 50,
                        width: 50,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHigh,
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
              Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Container(
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceBright,
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(
                        color: Theme.of(context).colorScheme.primary, width: 2.0),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        height: 50,
                        width: 50,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHigh,
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
              Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Container(
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceBright,
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(
                        color: Theme.of(context).colorScheme.primary, width: 2.0),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        height: 50,
                        width: 50,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHigh,
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
                          Text('Вийти', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 16.0)),
                          Text('Вихід з облікового запису', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 12.0)),
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
            ],
          ),
        ),
      ),
    );
  }
}