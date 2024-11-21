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
            children: [
              SizedBox(
                width: double.infinity,
                child: Text(
                  'Головний курс 🎯',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 20.0),
                  textAlign: TextAlign.left,
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
                ),
              ),
              const SizedBox(height: 20.0, width: double.infinity),
              SizedBox(
                width: double.infinity,
                child: Text(
                  'Основна інформація ℹ️',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 20.0),
                  textAlign: TextAlign.left,
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
                ),
              ),
              const SizedBox(height: 20.0, width: double.infinity),
              SizedBox(
                width: double.infinity,
                child: Text(
                  'Додаткові курси 🔎',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 20.0),
                  textAlign: TextAlign.left,
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}