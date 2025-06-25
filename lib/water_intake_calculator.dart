import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WaterIntakeCalculator extends StatefulWidget {
  @override
  _WaterIntakeCalculatorState createState() => _WaterIntakeCalculatorState();
}

class _WaterIntakeCalculatorState extends State<WaterIntakeCalculator> {
  int dailyGoalMl = 2000;
  int consumedMl = 0;
  List<Map<String, dynamic>> dailyHistory = [];
  TimeOfDay? reminderTime;

  final List<Map<String, dynamic>> glassSizes = [
    {'label': 'Small (150ml)', 'amount': 150},
    {'label': 'Medium (250ml)', 'amount': 250},
    {'label': 'Large (500ml)', 'amount': 500},
  ];

  @override
  void initState() {
    super.initState();
    _loadTodayHistory();
  }

  void _loadTodayHistory() {
    // For demo: resets history every day (no persistent storage)
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    dailyHistory = [];
    consumedMl = 0;
    setState(() {});
  }

  void _logWater(int amount) {
    setState(() {
      consumedMl += amount;
      dailyHistory.add({
        'amount': amount,
        'time': DateTime.now(),
      });
    });
  }

  void _setGoalDialog() async {
    int? newGoal = await showDialog<int>(
      context: context,
      builder: (context) {
        int tempGoal = dailyGoalMl;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('Set Daily Goal (ml)'),
          content: TextField(
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'Enter goal in ml'),
            onChanged: (val) {
              tempGoal = int.tryParse(val) ?? dailyGoalMl;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, tempGoal),
              child: const Text('Set'),
            ),
          ],
        );
      },
    );
    if (newGoal != null && newGoal > 0) {
      setState(() {
        dailyGoalMl = newGoal;
      });
    }
  }

  void _setReminderDialog() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: reminderTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        reminderTime = picked;
      });
      // For demo: No actual notification scheduling
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reminder set for ${picked.format(context)} (demo only)'),
          backgroundColor: Colors.blue[200],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double progress = consumedMl / dailyGoalMl;
    progress = progress > 1.0 ? 1.0 : progress;

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Water Intake Tracker',
          style: TextStyle(
            color: Color(0xFF6366F1),
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 1.1,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.alarm, color: Color(0xFF6366F1)),
            onPressed: _setReminderDialog,
            tooltip: 'Set Reminder',
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Color(0xFF6366F1)),
            onPressed: _setGoalDialog,
            tooltip: 'Set Daily Goal',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE0EAFC), Color(0xFFCFDEF3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 18),
                child: Column(
                  children: [
                    Card(
                      elevation: 10,
                      shadowColor: Colors.indigo[100],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                      color: Colors.white.withOpacity(0.97),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 28),
                        child: Column(
                          children: [
                            // Decorative icon and title
                            Center(
                              child: Column(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF6366F1).withOpacity(0.09),
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(18),
                                    child: const Icon(
                                      Icons.water_drop_rounded,
                                      color: Color(0xFF6366F1),
                                      size: 38,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Stay Hydrated!',
                                    style: TextStyle(
                                      color: const Color(0xFF6366F1),
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Hydration is crucial for overall health and performance.',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Goal and progress
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.flag, color: Color(0xFF6366F1), size: 22),
                                const SizedBox(width: 6),
                                Text(
                                  'Goal: $dailyGoalMl ml',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF6366F1),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 18,
                                backgroundColor: Colors.blue[100],
                                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF60A5FA)),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$consumedMl ml / $dailyGoalMl ml',
                              style: const TextStyle(fontSize: 16, color: Color(0xFF374151)),
                            ),
                            const SizedBox(height: 24),
                            // Log water buttons
                            Text('Log Water Consumed:', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Column(
                              children: glassSizes.map((glass) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(minWidth: double.infinity),
                                    child: ElevatedButton.icon(
                                      onPressed: () => _logWater(glass['amount']),
                                      icon: const Icon(Icons.local_drink, color: Colors.white, size: 20),
                                      label: Text(glass['label']),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF6366F1), // Match theme color
                                        foregroundColor: Colors.white,
                                        elevation: 4,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 14),
                                        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        minimumSize: const Size.fromHeight(48), // Ensures equal height
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 24),
                            // Today's history
                            Row(
                              children: [
                                const Icon(Icons.history, color: Color(0xFF6366F1), size: 22),
                                const SizedBox(width: 6),
                                Text(
                                  "Today's History",
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF6366F1),
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 140,
                              decoration: BoxDecoration(
                                color: Colors.blue[50]?.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: dailyHistory.isEmpty
                                  ? Center(
                                      child: Text(
                                        'No water logged yet.',
                                        style: TextStyle(
                                          color: Colors.blueGrey[400],
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      itemCount: dailyHistory.length,
                                      itemBuilder: (context, idx) {
                                        final entry = dailyHistory[dailyHistory.length - 1 - idx];
                                        return ListTile(
                                          leading: const Icon(Icons.local_drink, color: Color(0xFF60A5FA)),
                                          title: Text('${entry['amount']} ml'),
                                          subtitle: Text(DateFormat('hh:mm a').format(entry['time'])),
                                        );
                                      },
                                    ),
                            ),
                            if (reminderTime != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 12.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.alarm, color: Colors.blueGrey, size: 18),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Reminder set for: ${reminderTime!.format(context)}',
                                      style: const TextStyle(fontSize: 14, color: Colors.blueGrey),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}