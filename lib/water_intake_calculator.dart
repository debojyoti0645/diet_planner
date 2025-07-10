import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WaterIntakeCalculator extends StatefulWidget {
  @override
  _WaterIntakeCalculatorState createState() => _WaterIntakeCalculatorState();
}

class _WaterIntakeCalculatorState extends State<WaterIntakeCalculator> {
  int dailyGoalMl = 2000;
  int consumedMl = 0;
  List<Map<String, dynamic>> dailyHistory = [];
  List<Map<String, dynamic>> waterRecords = [];

  final List<Map<String, dynamic>> glassSizes = [
    {'label': 'Small (150ml)', 'amount': 150},
    {'label': 'Medium (250ml)', 'amount': 250},
    {'label': 'Large (500ml)', 'amount': 500},
  ];

  String todayKey = '';

  @override
  void initState() {
    super.initState();
    todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _loadTodayHistory();
    _loadWaterRecords();
  }

  Future<void> _loadTodayHistory() async {
    final prefs = await SharedPreferences.getInstance();
    todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Load consumedMl
    consumedMl = prefs.getInt('consumed_$todayKey') ?? 0;

    // Load dailyGoalMl
    dailyGoalMl = prefs.getInt('goal') ?? 2000;

    // Load dailyHistory
    final historyList = prefs.getStringList('history_$todayKey') ?? [];
    dailyHistory =
        historyList.map(
          (e) {
            final parts = e.split('|');
            // Explicitly define the type of the map being returned
            return <String, dynamic>{
              'amount': int.parse(parts[0]),
              'time': DateTime.parse(parts[1]),
            };
          },
        ).toList(); // The .cast() might not be strictly necessary if the map creation is typed, but can keep it for extra safety if needed.

    setState(() {});
  }

  Future<void> _loadWaterRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final records = prefs.getStringList('water_records') ?? [];
    waterRecords = records.map((e) {
      final parts = e.split('|');
      return {
        'date': parts[0],
        'amount': int.tryParse(parts[1]) ?? 0,
      };
    }).toList();
    // Sort by date descending
    waterRecords.sort((a, b) => b['date'].compareTo(a['date']));
    setState(() {});
  }

  Future<void> _saveTodayProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('consumed_$todayKey', consumedMl);
    await prefs.setInt('goal', dailyGoalMl);
    final historyList =
        dailyHistory
            .map(
              (e) =>
                  '${e['amount']}|${(e['time'] as DateTime).toIso8601String()}',
            )
            .toList();
    await prefs.setStringList('history_$todayKey', historyList);

    // Save daily total in records
    final records = prefs.getStringList('water_records') ?? [];
    // Remove today's record if exists
    records.removeWhere((e) => e.startsWith(todayKey));
    records.add('$todayKey|$consumedMl');
    await prefs.setStringList('water_records', records);
  }

  void _logWater(int amount) {
    setState(() {
      consumedMl += amount;
      dailyHistory.add({'amount': amount, 'time': DateTime.now()});
    });
    _saveTodayProgress().then((_) => _loadWaterRecords());
  }

  void _setGoalDialog() async {
    int? newGoal = await showDialog<int>(
      context: context,
      builder: (context) {
        int tempGoal = dailyGoalMl;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
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
      _saveTodayProgress();
    }
  }

  String getMotivationQuote(double progress) {
    if (progress >= 1.0) {
      // Goal completed
      return "🎉 Congratulations! You've reached your hydration goal today!";
    } else if (progress >= 0.75) {
      return "Almost there! Just a little more to go. 💧";
    } else if (progress >= 0.5) {
      return "Great job! Keep sipping and stay hydrated!";
    } else if (progress > 0.0) {
      return "Keep going! Every sip counts. 💦";
    } else {
      return "Start your hydration journey today!";
    }
  }

  @override
  Widget build(BuildContext context) {
    double progress = consumedMl / dailyGoalMl;
    progress = progress > 1.0 ? 1.0 : progress;

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(173, 216, 224, 236),
        elevation: 0,
        title: const Text(
          'Water Intake Tracker',
          style: TextStyle(
            color: Color(0xFF6366F1),
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 1.1,
          ),
        ),
        centerTitle: true,
        actions: [
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 18,
                ),
                child: Column(
                  children: [
                    // Show current date
                    Text(
                      DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6366F1),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Card(
                      elevation: 10,
                      shadowColor: Colors.indigo[100],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                      color: Colors.white.withOpacity(0.97),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 28,
                        ),
                        child: Column(
                          children: [
                            // Decorative icon and title
                            Center(
                              child: Column(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF6366F1,
                                      ).withOpacity(0.09),
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
                                    style: const TextStyle(
                                      color: Color(0xFF6366F1),
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Hydration is crucial for overall health and performance.',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.copyWith(
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
                                const Icon(
                                  Icons.flag,
                                  color: Color(0xFF6366F1),
                                  size: 22,
                                ),
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
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFF60A5FA),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$consumedMl ml / $dailyGoalMl ml',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF374151),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              getMotivationQuote(progress),
                              style: TextStyle(
                                color: progress >= 1.0 ? Colors.green[700] : Color(0xFF6366F1),
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            // Log water buttons
                            Text(
                              'Log Water Consumed:',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Column(
                              children:
                                  glassSizes.map((glass) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4.0,
                                      ),
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          minWidth: double.infinity,
                                        ),
                                        child: ElevatedButton.icon(
                                          onPressed:
                                              () => _logWater(
                                                glass['amount'] as int,
                                              ),
                                          icon: const Icon(
                                            Icons.local_drink,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          label: Text(glass['label'] as String),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFF6366F1,
                                            ),
                                            foregroundColor: Colors.white,
                                            elevation: 4,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 0,
                                              vertical: 14,
                                            ),
                                            textStyle: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                            minimumSize: const Size.fromHeight(
                                              48,
                                            ),
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
                                const Icon(
                                  Icons.history,
                                  color: Color(0xFF6366F1),
                                  size: 22,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "Today's History",
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.copyWith(
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
                              child:
                                  dailyHistory.isEmpty
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
                                          final entry =
                                              dailyHistory[dailyHistory.length -
                                                  1 -
                                                  idx];
                                          return ListTile(
                                            leading: const Icon(
                                              Icons.local_drink,
                                              color: Color(0xFF60A5FA),
                                            ),
                                            title: Text(
                                              '${entry['amount']} ml',
                                            ),
                                            subtitle: Text(
                                              DateFormat('hh:mm a').format(
                                                entry['time'] as DateTime,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                            ),
                            const SizedBox(height: 24),
                            // Water Intake Record Section
                            Card(
                              elevation: 6,
                              margin: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: const [
                                        Icon(Icons.calendar_today, color: Color(0xFF6366F1), size: 22),
                                        SizedBox(width: 6),
                                        Text(
                                          "Water Intake Record",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF6366F1),
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      height: 120,
                                      child: waterRecords.isEmpty
                                          ? Center(
                                              child: Text(
                                                'No records yet.',
                                                style: TextStyle(
                                                  color: Colors.blueGrey[400],
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            )
                                          : ListView.builder(
                                              itemCount: waterRecords.length,
                                              itemBuilder: (context, idx) {
                                                final record = waterRecords[idx];
                                                return ListTile(
                                                  leading: const Icon(Icons.water_drop, color: Color(0xFF60A5FA)),
                                                  title: Text(
                                                    DateFormat('EEE, MMM d').format(DateTime.parse(record['date'])),
                                                  ),
                                                  trailing: Text('${record['amount']} ml'),
                                                );
                                              },
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
                    const SizedBox(height: 16),
                    // Motivational Quote
                    Text(
                      getMotivationQuote(progress),
                      style: const TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF6366F1),
                      ),
                      textAlign: TextAlign.center,
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
