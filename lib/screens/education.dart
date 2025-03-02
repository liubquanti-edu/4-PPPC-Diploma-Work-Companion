import 'package:fluent_ui/fluent_ui.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import '../widgets/window_buttons.dart';

class EducationScreen extends StatefulWidget {
  const EducationScreen({super.key});

  @override
  State<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends State<EducationScreen> {
  @override
  Widget build(BuildContext context) {
    return NavigationView(
      appBar: NavigationAppBar(
        automaticallyImplyLeading: true,
        title: MoveWindow(
          child: const Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text('Навчання'),
          ),
        ),
        actions: const WindowButtons(),
      ),
      content: ScaffoldPage(
        content: Center(
          child: Text(
            'Екран навчання',
            style: FluentTheme.of(context).typography.title,
          ),
        ),
      ),
    );
  }
}