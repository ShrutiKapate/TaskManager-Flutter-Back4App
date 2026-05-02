import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'screens/login_screen.dart';
import 'screens/task_list_screen.dart';
import 'secrets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Parse().initialize(
    kBack4AppAppId,
    kBack4AppServerUrl,
    clientKey: kBack4AppClientKey,
    debug: false,
    autoSendSessionId: true,
  );

  runApp(const TaskManagerApp());
}

class TaskManagerApp extends StatelessWidget {
  const TaskManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

/// Decides whether to show login or task list based on session.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Future<ParseUser?> _checkUser() async {
    final cached = await ParseUser.currentUser();
    if (cached is! ParseUser) return null;

    // Verify the cached session is still valid against the server
    final response = await ParseUser.getCurrentUserFromServer(cached.sessionToken!);
    if (response != null && response.success) {
        return response.result as ParseUser;
    }
    // Cached session is dead — clear it
    await cached.logout();
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ParseUser?>(
      future: _checkUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data != null) {
          return const TaskListScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
