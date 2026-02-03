import 'package:flutter/material.dart';
import 'dart:async';

// Habit model
class Habit {
  String id;
  String name;
  IconData icon;
  Color color;
  int dailyGoal;
  int currentProgress;
  int streak;
  Map<String, int> weeklyHistory; // Date string -> completions
  DateTime createdAt;
  DateTime lastCompletedDate;

  Habit({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.dailyGoal = 1,
    this.currentProgress = 0,
    this.streak = 0,
    Map<String, int>? weeklyHistory,
    DateTime? createdAt,
    DateTime? lastCompletedDate,
  })  : weeklyHistory = weeklyHistory ?? {},
        createdAt = createdAt ?? DateTime.now(),
        lastCompletedDate = lastCompletedDate ?? DateTime.now();

  double get progressPercentage =>
      dailyGoal > 0 ? (currentProgress / dailyGoal).clamp(0.0, 1.0) : 0.0;

  bool get isCompletedToday => currentProgress >= dailyGoal;

  Habit copyWith({
    String? id,
    String? name,
    IconData? icon,
    Color? color,
    int? dailyGoal,
    int? currentProgress,
    int? streak,
    Map<String, int>? weeklyHistory,
    DateTime? createdAt,
    DateTime? lastCompletedDate,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      currentProgress: currentProgress ?? this.currentProgress,
      streak: streak ?? this.streak,
      weeklyHistory: weeklyHistory ?? Map.from(this.weeklyHistory),
      createdAt: createdAt ?? this.createdAt,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
    );
  }
}

// Available icons for habits
final List<IconData> habitIcons = [
  Icons.fitness_center,
  Icons.self_improvement,
  Icons.water_drop,
  Icons.book,
  Icons.directions_run,
  Icons.restaurant,
  Icons.bedtime,
  Icons.code,
  Icons.music_note,
  Icons.brush,
  Icons.pets,
  Icons.local_florist,
  Icons.favorite,
  Icons.star,
  Icons.emoji_events,
  Icons.lightbulb,
  Icons.school,
  Icons.work,
  Icons.home,
  Icons.phone_android,
  Icons.medication,
  Icons.local_cafe,
  Icons.directions_walk,
  Icons.psychology,
];

// Available colors for habits
final List<Color> habitColors = [
  Colors.deepPurple,
  Colors.blue,
  Colors.teal,
  Colors.green,
  Colors.orange,
  Colors.red,
  Colors.pink,
  Colors.indigo,
  Colors.cyan,
  Colors.amber,
  Colors.lime,
  Colors.brown,
];

// Motivational messages
final List<String> motivationalMessages = [
  "You're doing amazing! Keep it up! 🌟",
  "Every small step counts! 💪",
  "Consistency is key to success! 🔑",
  "You're building something great! 🏗️",
  "One day at a time! ⏰",
  "Champions never give up! 🏆",
  "Your future self will thank you! 🙏",
  "Progress, not perfection! 📈",
  "You've got this! 💯",
  "Make today count! 🎯",
  "Believe in yourself! ✨",
  "Small habits, big results! 🚀",
];

class HabitTrackerScreen extends StatefulWidget {
  const HabitTrackerScreen({super.key});

  @override
  State<HabitTrackerScreen> createState() => _HabitTrackerScreenState();
}

class _HabitTrackerScreenState extends State<HabitTrackerScreen>
    with TickerProviderStateMixin {
  List<Habit> _habits = [];
  Timer? _midnightTimer;
  String _currentMessage = motivationalMessages[0];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSampleHabits();
    _scheduleMidnightReset();
    _updateMotivationalMessage();
  }

  void _loadSampleHabits() {
    // Sample habits for demonstration
    final today = _getDateString(DateTime.now());
    _habits = [
      Habit(
        id: '1',
        name: 'Drink Water',
        icon: Icons.water_drop,
        color: Colors.blue,
        dailyGoal: 8,
        currentProgress: 3,
        streak: 5,
        weeklyHistory: {today: 3},
      ),
      Habit(
        id: '2',
        name: 'Exercise',
        icon: Icons.fitness_center,
        color: Colors.orange,
        dailyGoal: 1,
        currentProgress: 0,
        streak: 12,
        weeklyHistory: {},
      ),
      Habit(
        id: '3',
        name: 'Read',
        icon: Icons.book,
        color: Colors.green,
        dailyGoal: 1,
        currentProgress: 1,
        streak: 7,
        weeklyHistory: {today: 1},
      ),
    ];
  }

  String _getDateString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _scheduleMidnightReset() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final durationUntilMidnight = tomorrow.difference(now);

    _midnightTimer = Timer(durationUntilMidnight, () {
      _resetDailyProgress();
      _scheduleMidnightReset(); // Schedule next reset
    });
  }

  void _resetDailyProgress() {
    setState(() {
      final today = _getDateString(DateTime.now());
      for (int i = 0; i < _habits.length; i++) {
        final habit = _habits[i];
        // Save yesterday's progress to history
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        final yesterdayStr = _getDateString(yesterday);
        habit.weeklyHistory[yesterdayStr] = habit.currentProgress;

        // Update streak
        if (habit.isCompletedToday) {
          habit.streak++;
        } else {
          habit.streak = 0;
        }

        // Reset progress
        habit.currentProgress = 0;
        habit.weeklyHistory[today] = 0;

        // Clean old history (keep only last 7 days)
        final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
        habit.weeklyHistory.removeWhere((key, value) {
          final date = DateTime.tryParse(key);
          return date != null && date.isBefore(sevenDaysAgo);
        });
      }
    });
    _updateMotivationalMessage();
  }

  void _updateMotivationalMessage() {
    setState(() {
      _currentMessage = motivationalMessages[
          DateTime.now().millisecond % motivationalMessages.length];
    });
  }

  void _incrementHabit(int index) {
    setState(() {
      final habit = _habits[index];
      if (habit.currentProgress < habit.dailyGoal) {
        habit.currentProgress++;
        habit.weeklyHistory[_getDateString(DateTime.now())] =
            habit.currentProgress;

        // Update streak on first completion of the day
        if (habit.currentProgress == habit.dailyGoal) {
          final yesterday = DateTime.now().subtract(const Duration(days: 1));
          final yesterdayStr = _getDateString(yesterday);
          if (habit.weeklyHistory[yesterdayStr] != null &&
              habit.weeklyHistory[yesterdayStr]! >= habit.dailyGoal) {
            habit.streak++;
          } else if (habit.streak == 0) {
            habit.streak = 1;
          }
          habit.lastCompletedDate = DateTime.now();
          _showCompletionCelebration(habit);
        }
      }
    });
  }

  void _decrementHabit(int index) {
    setState(() {
      final habit = _habits[index];
      if (habit.currentProgress > 0) {
        habit.currentProgress--;
        habit.weeklyHistory[_getDateString(DateTime.now())] =
            habit.currentProgress;
      }
    });
  }

  void _showCompletionCelebration(Habit habit) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.celebration, color: Colors.white),
            const SizedBox(width: 8),
            Text('🎉 ${habit.name} completed! Streak: ${habit.streak} days'),
          ],
        ),
        backgroundColor: habit.color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showAddHabitDialog() {
    String habitName = '';
    IconData selectedIcon = habitIcons[0];
    Color selectedColor = habitColors[0];
    int dailyGoal = 1;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add New Habit'),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  onChanged: (value) => habitName = value,
                  decoration: InputDecoration(
                    labelText: 'Habit Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.edit),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Choose Icon',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 120,
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemCount: habitIcons.length,
                    itemBuilder: (context, index) => InkWell(
                      onTap: () =>
                          setDialogState(() => selectedIcon = habitIcons[index]),
                      child: Container(
                        decoration: BoxDecoration(
                          color: selectedIcon == habitIcons[index]
                              ? selectedColor.withOpacity(0.2)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: selectedIcon == habitIcons[index]
                              ? Border.all(color: selectedColor, width: 2)
                              : null,
                        ),
                        child: Icon(
                          habitIcons[index],
                          color: selectedIcon == habitIcons[index]
                              ? selectedColor
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Choose Color',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: habitColors.length,
                    itemBuilder: (context, index) => GestureDetector(
                      onTap: () =>
                          setDialogState(() => selectedColor = habitColors[index]),
                      child: Container(
                        width: 40,
                        height: 40,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: habitColors[index],
                          shape: BoxShape.circle,
                          border: selectedColor == habitColors[index]
                              ? Border.all(color: Colors.black, width: 3)
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Daily Goal',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (dailyGoal > 1) {
                          setDialogState(() => dailyGoal--);
                        }
                      },
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: selectedColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$dailyGoal',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: selectedColor,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setDialogState(() => dailyGoal++),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                    const Text('times per day'),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (habitName.trim().isNotEmpty) {
                  _addHabit(habitName, selectedIcon, selectedColor, dailyGoal);
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Add Habit'),
            ),
          ],
        ),
      ),
    );
  }

  void _addHabit(String name, IconData icon, Color color, int dailyGoal) {
    setState(() {
      _habits.add(Habit(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        icon: icon,
        color: color,
        dailyGoal: dailyGoal,
        weeklyHistory: {_getDateString(DateTime.now()): 0},
      ));
    });
  }

  void _showEditHabitDialog(int index) {
    final habit = _habits[index];
    String habitName = habit.name;
    IconData selectedIcon = habit.icon;
    Color selectedColor = habit.color;
    int dailyGoal = habit.dailyGoal;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Habit'),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  onChanged: (value) => habitName = value,
                  controller: TextEditingController(text: habitName),
                  decoration: InputDecoration(
                    labelText: 'Habit Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.edit),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Choose Icon',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 120,
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemCount: habitIcons.length,
                    itemBuilder: (context, index) => InkWell(
                      onTap: () =>
                          setDialogState(() => selectedIcon = habitIcons[index]),
                      child: Container(
                        decoration: BoxDecoration(
                          color: selectedIcon == habitIcons[index]
                              ? selectedColor.withOpacity(0.2)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: selectedIcon == habitIcons[index]
                              ? Border.all(color: selectedColor, width: 2)
                              : null,
                        ),
                        child: Icon(
                          habitIcons[index],
                          color: selectedIcon == habitIcons[index]
                              ? selectedColor
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Choose Color',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: habitColors.length,
                    itemBuilder: (context, index) => GestureDetector(
                      onTap: () =>
                          setDialogState(() => selectedColor = habitColors[index]),
                      child: Container(
                        width: 40,
                        height: 40,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: habitColors[index],
                          shape: BoxShape.circle,
                          border: selectedColor == habitColors[index]
                              ? Border.all(color: Colors.black, width: 3)
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Daily Goal',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (dailyGoal > 1) {
                          setDialogState(() => dailyGoal--);
                        }
                      },
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: selectedColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$dailyGoal',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: selectedColor,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setDialogState(() => dailyGoal++),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                    const Text('times per day'),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _deleteHabit(index);
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (habitName.trim().isNotEmpty) {
                  _updateHabit(
                      index, habitName, selectedIcon, selectedColor, dailyGoal);
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _updateHabit(
      int index, String name, IconData icon, Color color, int dailyGoal) {
    setState(() {
      _habits[index] = _habits[index].copyWith(
        name: name,
        icon: icon,
        color: color,
        dailyGoal: dailyGoal,
      );
    });
  }

  void _deleteHabit(int index) {
    setState(() {
      _habits.removeAt(index);
    });
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  // Statistics calculations
  int get _totalCompletedToday =>
      _habits.where((h) => h.isCompletedToday).length;

  double get _overallCompletionRate {
    if (_habits.isEmpty) return 0;
    int totalCompleted = 0;
    int totalDays = 0;
    for (var habit in _habits) {
      for (var entry in habit.weeklyHistory.entries) {
        totalDays++;
        if (entry.value >= habit.dailyGoal) {
          totalCompleted++;
        }
      }
    }
    return totalDays > 0 ? (totalCompleted / totalDays * 100) : 0;
  }

  int get _longestStreak {
    int longest = 0;
    for (var habit in _habits) {
      if (habit.streak > longest) longest = habit.streak;
    }
    return longest;
  }

  String get _bestDay {
    Map<String, int> dayCompletions = {};
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    for (var habit in _habits) {
      for (var entry in habit.weeklyHistory.entries) {
        final date = DateTime.tryParse(entry.key);
        if (date != null && entry.value >= habit.dailyGoal) {
          final dayName = days[date.weekday - 1];
          dayCompletions[dayName] = (dayCompletions[dayName] ?? 0) + 1;
        }
      }
    }

    if (dayCompletions.isEmpty) return 'N/A';
    return dayCompletions.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.shade50,
              Colors.white,
              Colors.blue.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildMotivationalBanner(),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildHabitsList(),
                    _buildStatistics(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddHabitDialog,
        backgroundColor: Colors.deepPurple,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Habit', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Habit Tracker',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
              ),
              Text(
                '${_totalCompletedToday}/${_habits.length} habits completed today',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_fire_department,
                    color: Colors.orange, size: 24),
                const SizedBox(width: 4),
                Text(
                  '$_longestStreak',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMotivationalBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple.shade400, Colors.purple.shade300],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_emotions, color: Colors.white, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _currentMessage,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            onPressed: _updateMotivationalMessage,
            icon: const Icon(Icons.refresh, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.deepPurple,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Habits'),
          Tab(text: 'Statistics'),
        ],
      ),
    );
  }

  Widget _buildHabitsList() {
    if (_habits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.track_changes, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No habits yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the button below to add your first habit',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      itemCount: _habits.length,
      itemBuilder: (context, index) => _buildHabitCard(index),
    );
  }

  Widget _buildHabitCard(int index) {
    final habit = _habits[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: habit.color.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onLongPress: () => _showEditHabitDialog(index),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: habit.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(habit.icon, color: habit.color, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            habit.name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: habit.isCompletedToday
                                  ? Colors.grey
                                  : Colors.black87,
                              decoration: habit.isCompletedToday
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.local_fire_department,
                                size: 16,
                                color: habit.streak > 0
                                    ? Colors.orange
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${habit.streak} day streak',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => _decrementHabit(index),
                          icon: Icon(
                            Icons.remove_circle_outline,
                            color: habit.currentProgress > 0
                                ? habit.color
                                : Colors.grey[300],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: habit.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${habit.currentProgress}/${habit.dailyGoal}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: habit.color,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _incrementHabit(index),
                          icon: Icon(
                            Icons.add_circle,
                            color: habit.currentProgress < habit.dailyGoal
                                ? habit.color
                                : Colors.grey[300],
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: habit.progressPercentage,
                    backgroundColor: habit.color.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(habit.color),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 12),
                // Weekly history
                _buildWeeklyHistory(habit),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyHistory(Habit habit) {
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final today = DateTime.now();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(7, (index) {
        final date = today.subtract(Duration(days: 6 - index));
        final dateStr = _getDateString(date);
        final completions = habit.weeklyHistory[dateStr] ?? 0;
        final isCompleted = completions >= habit.dailyGoal;
        final isToday = index == 6;

        return Column(
          children: [
            Text(
              days[date.weekday - 1],
              style: TextStyle(
                fontSize: 11,
                color: isToday ? habit.color : Colors.grey,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isCompleted
                    ? habit.color
                    : (completions > 0
                        ? habit.color.withOpacity(0.3)
                        : Colors.grey[200]),
                shape: BoxShape.circle,
                border: isToday
                    ? Border.all(color: habit.color, width: 2)
                    : null,
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 11,
                          color: completions > 0 ? Colors.white : Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildStatistics() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatCard(
            'Overall Completion Rate',
            '${_overallCompletionRate.toStringAsFixed(1)}%',
            Icons.pie_chart,
            Colors.blue,
            _overallCompletionRate / 100,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMiniStatCard(
                  'Total Habits',
                  '${_habits.length}',
                  Icons.track_changes,
                  Colors.purple,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMiniStatCard(
                  'Completed Today',
                  '$_totalCompletedToday',
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMiniStatCard(
                  'Longest Streak',
                  '$_longestStreak days',
                  Icons.local_fire_department,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMiniStatCard(
                  'Best Day',
                  _bestDay,
                  Icons.star,
                  Colors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Habit Streaks',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          ..._habits.map((habit) => _buildStreakItem(habit)),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    double progress,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakItem(Habit habit) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: habit.color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: habit.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(habit.icon, color: habit.color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Daily goal: ${habit.dailyGoal}x',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Icon(
                Icons.local_fire_department,
                color: habit.streak > 0 ? Colors.orange : Colors.grey,
                size: 24,
              ),
              const SizedBox(width: 4),
              Text(
                '${habit.streak}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: habit.streak > 0 ? Colors.orange : Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
