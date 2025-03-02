import 'package:fluent_ui/fluent_ui.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import '../widgets/window_buttons.dart';
import 'home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;

  Future<void> _handleLogin() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      await showDialog(
        context: context,
        builder: (context) => ContentDialog(
          title: const Text('Помилка'),
          content: const Text('Будь ласка, заповніть всі поля'),
          actions: [
            Button(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // Sign in
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // Get token and decode claims
      final idToken = await userCredential.user?.getIdToken();
      if (idToken == null) throw FirebaseAuthException(
        code: 'not-authorized',
        message: 'Помилка авторизації'
      );
      
      final decodedToken = JwtDecoder.decode(idToken);
      debugPrint('Decoded token: $decodedToken');
      
      if (decodedToken['admin'] == true) {
        if (!mounted) return;
        await Navigator.pushReplacement(
          context,
          FluentPageRoute(builder: (context) => const HomePage()),
        );
      } else {
        throw FirebaseAuthException(
          code: 'not-admin',
          message: 'Недостатньо прав для входу в панель адміністратора'
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => ContentDialog(
          title: const Text('Помилка'),
          content: Text(_getErrorMessage(e.code)),
          actions: [
            Button(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => ContentDialog(
          title: const Text('Помилка'),
          content: Text(_getErrorMessage('unknown')),
          actions: [
            Button(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Користувача з такою електронною адресою не знайдено';
      case 'wrong-password':
        return 'Неправильний пароль';
      case 'invalid-email':
        return 'Неправильний формат електронної адреси';
      case 'not-admin':
        return 'Недостатньо прав для входу в панель адміністратора';
      default:
        return 'Помилка входу: $code';
    }
  }

  @override
  Widget build(BuildContext context) {
    return NavigationView(
      appBar: NavigationAppBar(
        automaticallyImplyLeading: false,
        title: MoveWindow(
          child: const Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text('Вхід в панель адміністратора'),
          ),
        ),
        actions: const WindowButtons(),
      ),
      content: ScaffoldPage(
        content: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 350),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InfoLabel(
                    label: 'Email',
                    child: TextBox(
                      controller: emailController,
                      placeholder: 'Введіть email',
                      enabled: !isLoading,
                    ),
                  ),
                  const SizedBox(height: 10),
                  InfoLabel(
                    label: 'Пароль',
                    child: PasswordBox(
                      controller: passwordController,
                      placeholder: 'Введіть пароль',
                      enabled: !isLoading,
                      onSubmitted: (_) => _handleLogin(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: isLoading ? null : _handleLogin,
                    child: isLoading
                        ? const ProgressRing()
                        : const Text('Увійти'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}