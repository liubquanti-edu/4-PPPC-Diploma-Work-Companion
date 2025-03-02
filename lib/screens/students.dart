import 'package:fluent_ui/fluent_ui.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import '../widgets/window_buttons.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  @override
  Widget build(BuildContext context) {
    return NavigationView(
      appBar: NavigationAppBar(
        automaticallyImplyLeading: true,
        title: MoveWindow(
          child: const Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text('Студенти'),
          ),
        ),
        actions: const WindowButtons(),
      ),
      content: ScaffoldPage(
        content: Center(
          child: Text(
            'Екран студентів',
            style: FluentTheme.of(context).typography.title,
          ),
        ),
      ),
    );
  }
}