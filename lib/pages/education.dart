import 'package:flutter/material.dart';

class EducationPage extends StatefulWidget {
  const EducationPage({Key? key}) : super(key: key);

  @override
  _EducationPageState createState() => _EducationPageState();
}

class _EducationPageState extends State<EducationPage> {
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
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('РОЗРОБКА ПЗ', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 20.0)),
                          Row(
                            children: [
                              Icon(Icons.info_outline, size: 16.0, color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 5.0),
                              Text('7-й семестр', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 12.0)),
                            ],
                          ),
                          Row(
                            children: [
                              Icon(Icons.access_time_outlined, size: 16.0, color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 5.0),
                              Text('01/09/2024 - 01/01/2025', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 12.0)),
                              const SizedBox(width: 5.0),
                            ],
                          ),
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
                            Icons.verified,
                            size: 30.0,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10.0),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Захист курсової роботи', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 16.0)),
                          Row(
                            children: [
                              Icon(Icons.access_time_outlined, size: 16.0, color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 5.0),
                              Text('13/11/2024 - 14/11/2024', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 12.0)),
                            ],
                          ),
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
              const SizedBox(height: 5.0, width: double.infinity),
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
                            Icons.how_to_reg_sharp,
                            size: 30.0,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10.0),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Сесія', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 16.0)),
                          Row(
                            children: [
                              Icon(Icons.access_time_outlined, size: 16.0, color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 5.0),
                              Text('11/11/2024 - 22/11/2024', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 12.0)),
                            ],
                          ),
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
              const SizedBox(height: 5.0, width: double.infinity),
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
                            Icons.work,
                            size: 30.0,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10.0),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Практика', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 16.0)),
                          Row(
                            children: [
                              Icon(Icons.access_time_outlined, size: 16.0, color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 5.0),
                              Text('01/12/2024 - 31/12/2024', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 12.0)),
                            ],
                          ),
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
                            Icons.stream_rounded,
                            size: 30.0,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10.0),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Зимові канікули', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 16.0)),
                          Row(
                            children: [
                              Icon(Icons.access_time_outlined, size: 16.0, color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 5.0),
                              Text('01/01/2025 - 15/10/2025', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 12.0)),
                            ],
                          ),
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
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Іноземна мова', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 18.0)),
                          Row(
                            children: [
                              Icon(Icons.access_time_outlined, size: 16.0, color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 5.0),
                              Text('01/09/2024 - 01/01/2025', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 12.0)),
                              const SizedBox(width: 5.0),
                            ],
                          ),
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