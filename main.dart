import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'To-Do List',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const TodoScreen(),
    );
  }
}

class TodoScreen extends StatefulWidget {
  const TodoScreen({Key? key}) : super(key: key);

  @override
  State<TodoScreen> createState() => _TodoScreenState();

}

class TodoItem {
  String title = 'To Do List';
  bool isCompleted;

  TodoItem({
    required this.title,
    this.isCompleted = false,
  });
}

class _TodoScreenState extends State<TodoScreen> {
  final List<TodoItem> _tasks = [];
final TextEditingController _controller = TextEditingController();

void _addTask() {
  final task = _controller.text.trim();
  if (task.isNotEmpty) {
    setState(() {
      _tasks.add(TodoItem(title: task));
    });
    _controller.clear();
  }
}

Future<void> _addTodo() async {
  final text = _controller.text.trim();
  if (text.isEmpty) return;
  await _todosRef.add({
    'title': text,
    'isDone': false,
    'createdAt': FieldValue.serverTimestamp(),
  });
  _controller.clear();
}
Future<void> _toggleDone(String id, bool current) async {
  await _todosRef.doc(id).update({'isDone': !current});
}

Future<void> _editTodo(String id, String currentTitle) async {
  final editController = TextEditingController(text: currentTitle);
  await showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Edit Task'),
      content: TextField(
        controller: editController,
        autofocus: true,
        decoration: const InputDecoration(border: OutlineInputBorder()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final newTitle = editController.text.trim();
            if (newTitle.isNotEmpty) {
              await _todosRef.doc(id).update({'title': newTitle});
            }
            Navigator.pop(ctx);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

Future<void> _deleteTodo(String id) async {
  await _todosRef.doc(id).delete();
}

final CollectionReference _todosRef =
    FirebaseFirestore.instance.collection('todos');


void _toggleTask(int index) {
  setState(() {
    _tasks[index].isCompleted = !_tasks[index].isCompleted;
  });
}

void _removeTask(int index) {
  setState(() {
    _tasks.removeAt(index);
  });
}

@override
void dispose() {
  _controller.dispose();
  super.dispose();
}

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('To-Do List'),
      elevation: 2,
    ),
    body: Column(
      children: [
        Padding(
  padding: const EdgeInsets.all(16.0),
  child: Row(
    children: [
      Expanded(
        child: TextField(
          controller: _controller,
          decoration: const InputDecoration(
            hintText: 'Add a new task...',
            border: OutlineInputBorder(),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
          onSubmitted: (_) => _addTodo(),
        ),
      ),
      const SizedBox(width: 8),
      ElevatedButton.icon(
        onPressed: _addTodo,
        icon: const Icon(Icons.add),
        label: const Text('Add'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    ],
  ),
),
Expanded(
  child: StreamBuilder<QuerySnapshot>(
    stream: _todosRef
        .orderBy('createdAt', descending: true)
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return Center(child: Text('Error: ${snapshot.error}'));
      }
      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.checklist, size: 64, color: Colors.grey),
              SizedBox(height: 12),
              Text(
                'No tasks yet!\nAdd one above.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ],
          ),
        );
      }
      final docs = snapshot.data!.docs;
      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: docs.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final doc = docs[index];
          final data = doc.data() as Map<String, dynamic>;
          final isDone = data['isDone'] as bool? ?? false;
          final title = data['title'] as String? ?? '';
          return ListTile(
  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
  leading: Checkbox(
    value: isDone,
    activeColor: Colors.deepPurple,
    onChanged: (_) => _toggleDone(doc.id, isDone),
  ),
  title: Text(
    title,
    style: TextStyle(
      fontSize: 16,
      decoration: isDone ? TextDecoration.lineThrough : null,
      color: isDone ? Colors.grey : Colors.black87,
    ),
  ),
  trailing: Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    IconButton(
      icon: const Icon(Icons.edit_outlined, color: Colors.blue),
      tooltip: 'Edit',
      onPressed: () => _editTodo(doc.id, title),
    ),
    IconButton(
      icon: const Icon(Icons.delete_outline, color: Colors.red),
      tooltip: 'Delete',
      onPressed: () => _deleteTodo(doc.id),
    ),
  ],
),
);
        },
      );
    },
  ),
),
const Divider(height: 1),
        Expanded(
  child: _tasks.isEmpty
      ? const Center(
          child: Text(
            'No tasks yet. Add one above!',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        )
      : ListView.builder(
          itemCount: _tasks.length,
          itemBuilder: (context, index) {
            final task = _tasks[index];
            return Card(
              margin: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              child: ListTile(
                leading: Checkbox(
                  value: task.isCompleted,
                  onChanged: (_) => _toggleTask(index),
                ),
                title: Text(
                  task.title,
                  style: TextStyle(
                    decoration: task.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                    color: task.isCompleted
                        ? Colors.grey
                        : Colors.black,
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeTask(index),
                ),
              ),
            );
          },
        ),
),
      ],
    ),
  );
}

}