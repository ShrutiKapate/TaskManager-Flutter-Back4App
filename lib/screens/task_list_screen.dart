import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'login_screen.dart';
import 'task_edit_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<ParseObject> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    final currentUser = await ParseUser.currentUser() as ParseUser?;
    if (currentUser == null) return;

    final query = QueryBuilder<ParseObject>(ParseObject('Task'))
      ..whereEqualTo('user', currentUser.toPointer())
      ..orderByDescending('createdAt');

    final response = await query.query();

    setState(() {
      _isLoading = false;
      _tasks = response.success && response.results != null
          ? response.results!.cast<ParseObject>()
          : [];
    });
  }

  Future<void> _deleteTask(ParseObject task) async {
    final response = await task.delete();
    if (response.success) {
      _loadTasks();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: ${response.error?.message}')),
      );
    }
  }

  Future<void> _toggleDone(ParseObject task) async {
    final current = task.get<bool>('done') ?? false;
    task.set('done', !current);
    await task.save();
    _loadTasks();
  }

  Future<void> _logout() async {
    final user = await ParseUser.currentUser() as ParseUser?;
    await user?.logout();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  Future<void> _openEditor({ParseObject? task}) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => TaskEditScreen(task: task)),
    );
    if (result == true) _loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadTasks,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tasks.isEmpty
              ? const Center(
                  child: Text('No tasks yet. Tap + to add one.'),
                )
              : RefreshIndicator(
                  onRefresh: _loadTasks,
                  child: ListView.builder(
                    itemCount: _tasks.length,
                    itemBuilder: (context, index) {
                      final task = _tasks[index];
                      final done = task.get<bool>('done') ?? false;
                      return Dismissible(
                        key: Key(task.objectId!),
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => _deleteTask(task),
                        child: ListTile(
                          leading: Checkbox(
                            value: done,
                            onChanged: (_) => _toggleDone(task),
                          ),
                          title: Text(
                            task.get<String>('title') ?? '(no title)',
                            style: TextStyle(
                              decoration: done
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          subtitle: Text(task.get<String>('description') ?? ''),
                          onTap: () => _openEditor(task: task),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
