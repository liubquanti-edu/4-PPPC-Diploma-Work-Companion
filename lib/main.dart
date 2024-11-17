import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange, brightness: Brightness.dark),
        useMaterial3: true,
        fontFamily: 'Comfortaa',
      ),
        home: MyHomePage(title: getGreeting()),
      );
    }
  
    String getGreeting() {
      String _name = "Олег";
        return 'Привіт, $_name 👋';
    }
  }

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
        body: SingleChildScrollView(
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40.0),
                child: SvgPicture.asset(
                  'assets/svg/ППФК.svg',
                  colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.primary, BlendMode.srcIn),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      widget.title,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 24.0),
                      textAlign: TextAlign.left,
                    ),
                  ),
                  const SizedBox(height: 10.0, width: double.infinity),
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      'Твій календар 📆',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 20.0),
                      textAlign: TextAlign.left,
                    ),
                  ),
                  Padding(padding: const EdgeInsets.only(top: 10.0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceBright,
                        borderRadius: BorderRadius.circular(10.0),
                        border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2.0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      SizedBox(height: 70, width: 5, child: DecoratedBox(decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(5)))),
                                      const SizedBox(width: 10.0),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Архітект.комп.', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 20.0)),
                                          Row(
                                            children: [
                                              Icon(Icons.info_outline, size: 16.0, color: Theme.of(context).colorScheme.primary),
                                              const SizedBox(width: 5.0),
                                              Text('Ігор Дегтяр 304 ауд.', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 12.0)),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Icon(Icons.access_time_outlined, size: 16.0, color: Theme.of(context).colorScheme.primary),
                                              const SizedBox(width: 5.0),
                                              Text('09:00 - 10:00', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 12.0)),
                                              const SizedBox(width: 5.0),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10.0, width: double.infinity),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      SizedBox(height: 60, width: 5, child: DecoratedBox(decoration: BoxDecoration(color: Theme.of(context).colorScheme.secondary, borderRadius: BorderRadius.circular(5)))),
                                      const SizedBox(width: 10.0),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Проєктування АІС', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 16.0)),
                                          Row(
                                            children: [
                                              Icon(Icons.info_outline, size: 16.0, color: Theme.of(context).colorScheme.secondary),
                                              const SizedBox(width: 5.0),
                                              Text('Світлана Гриценко 317 ауд.', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 12.0)),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Icon(Icons.access_time_outlined, size: 16.0, color: Theme.of(context).colorScheme.secondary),
                                              const SizedBox(width: 5.0),
                                              Text('10:10 - 11:10', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 12.0)),
                                              const SizedBox(width: 5.0),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10.0, width: double.infinity),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      SizedBox(height: 60, width: 5, child: DecoratedBox(decoration: BoxDecoration(color: Theme.of(context).colorScheme.secondary, borderRadius: BorderRadius.circular(5)))),
                                      const SizedBox(width: 10.0),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Осн.патентознав.', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 16.0)),
                                          Row(
                                            children: [
                                              Icon(Icons.info_outline, size: 16.0, color: Theme.of(context).colorScheme.secondary),
                                              const SizedBox(width: 5.0),
                                              Text('Марина Яненко 313 ауд.', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 12.0)),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Icon(Icons.access_time_outlined, size: 16.0, color: Theme.of(context).colorScheme.secondary),
                                              const SizedBox(width: 5.0),
                                              Text('11:50 - 12:50', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 12.0)),
                                              const SizedBox(width: 5.0),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20.0, width: double.infinity),
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      'Останні новини 📰',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 20.0), 
                      textAlign: TextAlign.left,
                    ),
                  ),
                  Padding(padding: const EdgeInsets.only(top: 10.0),
                    child: Column(
                      children: List.generate(10, (index) {
                        return Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Container(
                          padding: const EdgeInsets.all(10.0),
                          decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceBright,
                          borderRadius: BorderRadius.circular(10.0),
                          border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2.0),
                          ),
                          child: Row (
                            children: [
                                Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5 ),
                                  image: const DecorationImage(
                                  image: AssetImage('assets/img/news.jpg'),
                                  fit: BoxFit.cover,
                                  ),
                                ),
                                ),
                              const SizedBox(width: 10.0),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    Text(
                                    'Утвердження української',
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 14.0),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    ),
                                  SizedBox(
                                    width: MediaQuery.of(context).size.width * 0.6,
                                    child: Text(
                                      'З метою утвердження державного статусу української мови, піднесення її престижу серед студентської молоді',
                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10.0),
                                      softWrap: true,
                                      overflow: TextOverflow.visible,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 10.0, width: double.infinity),
                ],
              ),
            ),
          ],
        ), 
      ),
    );
  }
}
