import 'package:fluent_ui/fluent_ui.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import '../widgets/window_buttons.dart';

class TeachersScreen extends StatefulWidget {
  const TeachersScreen({super.key});

  @override
  State<TeachersScreen> createState() => _TeachersScreenState();
}

class _TeachersScreenState extends State<TeachersScreen> {
  @override
  Widget build(BuildContext context) {
    return NavigationView(
      appBar: NavigationAppBar(
        automaticallyImplyLeading: true,
        title: MoveWindow(
          child: const Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text('Викладачі'),
          ),
        ),
        actions: const WindowButtons(),
      ),
      content: ScaffoldPage(
        content: Center(
          child: Text(
            'Екран викладачів',
            style: FluentTheme.of(context).typography.title,
          ),
        ),
      ),
    );
  }
}