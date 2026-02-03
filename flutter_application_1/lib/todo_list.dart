import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum TodoPriority { low, medium, high }

class TodoList extends StatefulWidget {
  const TodoList({super.key});

  @override
  State<TodoList> createState() => _TodoListState();
}

class _TodoListState extends State<TodoList> {
  final List<Map<String, dynamic>> _todos = [];
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  TodoPriority _selectedPriority = TodoPriority.medium;
  String _selectedCategory = 'General';
  DateTime? _selectedDate;
  String _searchQuery = '';

  final List<String> _categories = [
    'General',
    'Work',
    'Personal',
    'Shopping',
    'Health',
  ];

  void _addTodo() {
    if (_controller.text.trim().isNotEmpty) {
      setState(() {
        _todos.insert(0, {
          'task': _controller.text.trim(),
          'isDone': false,
          'priority': _selectedPriority,
          'category': _selectedCategory,
          'dueDate': _selectedDate,
          'createdAt': DateTime.now(),
        });
        _controller.clear();
        _selectedPriority = TodoPriority.medium;
        _selectedCategory = 'General';
        _selectedDate = null;
      });
    }
  }

  void _toggleTodo(int index, bool? value) {
    setState(() {
      _todos[index]['isDone'] = value ?? false;
    });
  }

  void _deleteTodo(int index) {
    setState(() {
      _todos.removeAt(index);
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Color _getPriorityColor(TodoPriority priority) {
    switch (priority) {
      case TodoPriority.high:
        return Colors.redAccent;
      case TodoPriority.medium:
        return Colors.orangeAccent;
      case TodoPriority.low:
        return Colors.blueAccent;
    }
  }

  List<Map<String, dynamic>> get _filteredTodos {
    return _todos.where((todo) {
      final taskMatches = todo['task'].toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      return taskMatches;
    }).toList();
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchSection(),
        _buildInputSection(),
        Expanded(
          child: _filteredTodos.isEmpty ? _buildEmptyState() : _buildTodoList(),
        ),
      ],
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Search tasks...',
          prefixIcon: const Icon(Icons.search_rounded),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          filled: true,
          fillColor: Colors.grey[50],
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Add a new task...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    prefixIcon: const Icon(Icons.add_task_rounded),
                  ),
                  onSubmitted: (_) => _addTodo(),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _addTodo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 0,
                ),
                child: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Text(
                        'Priority: ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      ...TodoPriority.values.map(
                        (p) => Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: ChoiceChip(
                            label: Text(
                              p.name.toUpperCase(),
                              style: const TextStyle(fontSize: 10),
                            ),
                            selected: _selectedPriority == p,
                            selectedColor: _getPriorityColor(
                              p,
                            ).withOpacity(0.2),
                            onSelected: (selected) {
                              if (selected)
                                setState(() => _selectedPriority = p);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => _selectDate(context),
                icon: const Icon(Icons.calendar_today_rounded, size: 16),
                label: Text(
                  _selectedDate == null
                      ? 'Set Due Date'
                      : DateFormat('MMM d').format(_selectedDate!),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text(
                  'Category: ',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                ..._categories.map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: ChoiceChip(
                      label: Text(c, style: const TextStyle(fontSize: 10)),
                      selected: _selectedCategory == c,
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedCategory = c);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchQuery.isEmpty
                ? Icons.assignment_turned_in_outlined
                : Icons.search_off_rounded,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? 'All caught up!' : 'No results found',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            _searchQuery.isEmpty
                ? 'Add a task to get started'
                : 'Try a different search term',
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildTodoList() {
    final todos = _filteredTodos;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: todos.length,
      itemBuilder: (context, index) {
        final todo = todos[index];
        final bool isDone = todo['isDone'];
        final TodoPriority priority = todo['priority'];
        final DateTime? dueDate = todo['dueDate'];

        return Dismissible(
          key: Key(todo['createdAt'].toString()),
          background: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.redAccent,
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete_outline, color: Colors.white),
          ),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => _deleteTodo(_todos.indexOf(todo)),
          child: Card(
            elevation: 0,
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: Transform.scale(
                scale: 1.2,
                child: Checkbox(
                  value: isDone,
                  onChanged: (value) =>
                      _toggleTodo(_todos.indexOf(todo), value),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  activeColor: Colors.deepPurple,
                ),
              ),
              title: Text(
                todo['task'],
                style: TextStyle(
                  decoration: isDone ? TextDecoration.lineThrough : null,
                  color: isDone ? Colors.grey : Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(priority).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        priority.name.toUpperCase(),
                        style: TextStyle(
                          color: _getPriorityColor(priority),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        todo['category'],
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    if (dueDate != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 10,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('MMM d').format(dueDate),
                              style: const TextStyle(
                                color: Colors.blue,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              trailing: IconButton(
                icon: const Icon(
                  Icons.delete_sweep_outlined,
                  color: Colors.grey,
                ),
                onPressed: () => _deleteTodo(_todos.indexOf(todo)),
              ),
            ),
          ),
        );
      },
    );
  }
}
