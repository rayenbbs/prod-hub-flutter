import 'package:flutter/material.dart';

class TodoList extends StatefulWidget {
  const TodoList({super.key});

  @override
  State<TodoList> createState() => _TodoListState();
}

class _TodoListState extends State<TodoList> {
  final List<Map<String, dynamic>> _todos = [];
  final TextEditingController _controller = TextEditingController();

  void _addTodo() {
    if (_controller.text.trim().isNotEmpty) {
      setState(() {
        _todos.add({'task': _controller.text.trim(), 'isDone': false});
        _controller.clear();
      });
    }
  }

  void _toggleTodo(int index, bool? value) {
    setState(() {
      _todos[index]['isDone'] = value ?? false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    labelText: 'What needs to be done?',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  onSubmitted: (_) => _addTodo(),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _addTodo,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _todos.isEmpty
                ? Center(
                    child: Text(
                      'No tasks yet. Add one above!',
                      style: TextStyle(color: Colors.grey[500], fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: _todos.length,
                    itemBuilder: (context, index) {
                      final todo = _todos[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: CheckboxListTile(
                          title: Text(
                            todo['task'],
                            style: TextStyle(
                              decoration: todo['isDone']
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: todo['isDone']
                                  ? Colors.grey
                                  : Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          value: todo['isDone'],
                          onChanged: (value) => _toggleTodo(index, value),
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: Theme.of(context).primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
