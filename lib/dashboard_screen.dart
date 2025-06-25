import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatelessWidget {
  final String userName;

  const DashboardScreen({super.key, this.userName = "Alex"});

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('EEEE, MMM d').format(DateTime.now());

    // Mock Data
    final calories = 0;
    final caloriesTarget = 2000;
    final water = 0;
    final waterTarget = 8;
    final steps = 0;
    final stepsTarget = 10000;
    final workoutDone = false;
    final hasProgress = calories > 0 || water > 0 || steps > 0;

    return Scaffold(
      // Removed appBar here!
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE3F0FF), Color(0xFFF8F8FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          // Adjusted top padding to leave space for the global AppBar
          padding: const EdgeInsets.fromLTRB(16, 32, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Optionally, add a greeting here if you want it below the AppBar
              // Padding(
              //   padding: const EdgeInsets.only(bottom: 16),
              //   child: Text(
              //     'Good morning, $userName! 👋',
              //     style: Theme.of(context).textTheme.titleLarge,
              //   ),
              // ),
              _buildDailyGoalsCard(
                context,
                calories,
                caloriesTarget,
                water,
                waterTarget,
                steps,
                stepsTarget,
                workoutDone,
                hasProgress,
              ),
              const SizedBox(height: 24),
              _buildSummaryCards(context, calories, workoutDone, hasProgress),
              const SizedBox(height: 18),
              _buildNutritionTipCard(),
              const SizedBox(height: 24),
              _buildRemindersCard(context),
              const SizedBox(height: 24),
              _buildWeeklyProgressCard(context, hasProgress),
              const SizedBox(height: 45),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyGoalsCard(
    BuildContext context,
    int calories,
    int caloriesTarget,
    int water,
    int waterTarget,
    int steps,
    int stepsTarget,
    bool workoutDone,
    bool hasProgress,
  ) {
    return Card(
      elevation: 8,
      shadowColor: Colors.indigo[100],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      color: Colors.white.withOpacity(0.97),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: hasProgress
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.flag, color: Colors.indigo[400], size: 26),
                      const SizedBox(width: 8),
                      Text(
                        'Daily Goals',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.indigo[900],
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _progressRow(
                    Icons.local_fire_department,
                    'Calories',
                    '$calories / $caloriesTarget kcal',
                    progress: caloriesTarget > 0 ? calories / caloriesTarget : 0,
                    color: Colors.orange,
                  ),
                  _progressRow(
                    Icons.water_drop,
                    'Water',
                    '$water / $waterTarget glasses',
                    progress: waterTarget > 0 ? water / waterTarget : 0,
                    color: Colors.blueAccent,
                  ),
                  _progressRow(
                    Icons.directions_walk,
                    'Steps',
                    '$steps / $stepsTarget',
                    progress: stepsTarget > 0 ? steps / stepsTarget : 0,
                    color: Colors.green,
                  ),
                  _progressRow(
                    Icons.fitness_center,
                    'Workout',
                    workoutDone ? 'Done' : 'Pending',
                    color: Colors.purple,
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.hourglass_empty, color: Colors.indigo[200], size: 38),
                  const SizedBox(height: 10),
                  const Text(
                    'No progress yet for today!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Start tracking your meals, water, and workouts to see your progress here.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _progressRow(
    IconData icon,
    String label,
    String value, {
    double progress = 0,
    Color color = Colors.indigo,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  value: progress.clamp(0, 1),
                  backgroundColor: color.withOpacity(0.13),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  strokeWidth: 5,
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(width: 14),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(
    BuildContext context,
    int calories,
    bool workoutDone,
    bool hasProgress,
  ) {
    return Row(
      children: [
        Expanded(
          child: Stack(
            children: [
              _summaryCard(
                title: 'Diet',
                icon: Icons.restaurant_menu,
                value: hasProgress ? '$calories kcal' : 'No data',
                subtitle: hasProgress ? 'See recommended meals' : 'Add your meals',
                color: Colors.indigo[50]!,
                iconColor: Colors.indigo[700]!,
              ),
              Positioned(
                top: 10,
                right: 10,
                child: _comingSoonBanner(),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Stack(
            children: [
              _summaryCard(
                title: 'Exercise',
                icon: Icons.fitness_center,
                value: workoutDone ? 'Completed' : 'Pending',
                subtitle: 'See workout plan',
                color: Colors.blue[50]!,
                iconColor: Colors.blue[700]!,
              ),
              Positioned(
                top: 10,
                right: 10,
                child: _comingSoonBanner(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _comingSoonBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'Coming Soon',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 11,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _summaryCard({
    required String title,
    required IconData icon,
    required String value,
    required String subtitle,
    required Color color,
    required Color iconColor,
  }) {
    return Card(
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: iconColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionTipCard() {
    return Card(
      color: Colors.amber[50],
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const Icon(Icons.lightbulb, color: Colors.amber, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                '💡 Drink water before meals to aid digestion.',
                style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemindersCard(BuildContext context) {
    final reminders = [
      {'icon': Icons.access_time, 'text': 'Next meal at 1:00 PM'},
      {'icon': Icons.fitness_center, 'text': 'Workout at 6:00 PM'},
      {'icon': Icons.water_drop, 'text': 'Hydration: Drink a glass now!'},
      {
        'icon': Icons.emoji_emotions,
        'text': '“You are stronger than you think!”',
      },
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notifications_active, color: Colors.indigo[400], size: 22),
                const SizedBox(width: 8),
                Text('Reminders', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 10),
            for (var r in reminders)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Icon(
                      r['icon'] as IconData,
                      size: 20,
                      color: Colors.indigo[700],
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(r['text'] as String)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyProgressCard(BuildContext context, bool hasProgress) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.show_chart, color: Colors.indigo[400], size: 22),
                const SizedBox(width: 8),
                Text(
                  'Weekly Progress',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 10),
            hasProgress
                ? Column(
                    children: [
                      _placeholderGraph('Weight Trend'),
                      _placeholderGraph('Calories Trend'),
                      _placeholderGraph('Workout Frequency'),
                    ],
                  )
                : const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'No weekly progress yet. Start tracking to see your trends!',
                      style: TextStyle(color: Color(0xFF6366F1)),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderGraph(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
          ),
          const SizedBox(height: 8),
          Container(
            height: 48,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEEF2FF), Color(0xFFD1FAE5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xFF6366F1).withOpacity(0.08)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo[300]!),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Graph Placeholder',
                  style: TextStyle(color: Color(0xFF6366F1)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
