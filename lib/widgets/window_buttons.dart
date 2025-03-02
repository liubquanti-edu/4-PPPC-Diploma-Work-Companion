import 'package:fluent_ui/fluent_ui.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';

class WindowButtons extends StatelessWidget {
  const WindowButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);

    return SizedBox(
      width: 138,
      height: 32,
      child: Row(
        children: [
          MinimizeWindowButton(
            colors: WindowButtonColors(
              iconNormal: theme.resources.textFillColorPrimary,
              iconMouseDown: theme.resources.textFillColorPrimary,
              iconMouseOver: theme.resources.textFillColorPrimary,
              mouseOver: theme.resources.controlFillColorSecondary,
              mouseDown: theme.resources.controlFillColorTertiary,
              normal: Colors.transparent,
            ),
          ),
          MaximizeWindowButton(
            colors: WindowButtonColors(
              iconNormal: theme.resources.textFillColorPrimary,
              iconMouseDown: theme.resources.textFillColorPrimary,
              iconMouseOver: theme.resources.textFillColorPrimary,
              mouseOver: theme.resources.controlFillColorSecondary,
              mouseDown: theme.resources.controlFillColorTertiary,
              normal: Colors.transparent,
            ),
          ),
          CloseWindowButton(
            colors: WindowButtonColors(
              iconNormal: theme.resources.textFillColorPrimary,
              mouseOver: Colors.red,
              mouseDown: Colors.red.darker,
              iconMouseOver: Colors.white,
              iconMouseDown: Colors.white,
              normal: Colors.transparent,
            ),
          ),
        ],
      ),
    );
  }
}