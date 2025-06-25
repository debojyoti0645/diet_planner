import 'package:diet_planner/gemini_service.dart';
import 'package:flutter/material.dart';

class ExercisePlanScreen extends StatefulWidget {
  const ExercisePlanScreen({super.key});

  @override
  State<ExercisePlanScreen> createState() => _ExercisePlanScreenState();
}

class _ExercisePlanScreenState extends State<ExercisePlanScreen> {
  String? _selectedGoal;
  String? _preferredTime;
  String? _workoutType;
  bool _wantYoga = false;
  bool _hasGym = false;
  bool _canRun = false;
  bool _canCycle = false;
  String _exercisePlan = '';
  bool _isLoading = false;

  final List<String> _goals = [
    'Bulking',
    'Cutting',
    'Weight Gain',
    'Weight Loss',
    'Fat Loss',
    'Muscle Toning',
    'General Fitness',
  ];

  final List<String> _times = [
    'Morning',
    'Afternoon',
    'Evening',
    'Night',
    'Flexible',
  ];

  final List<String> _workoutTypes = [
    'Strength Training',
    'Cardio',
    'HIIT',
    'Mixed',
    'Bodyweight',
    'No Preference',
  ];

  Future<void> _generateExercisePlan() async {
    setState(() {
      _isLoading = true;
      _exercisePlan = '';
    });

    if (_selectedGoal == null || _selectedGoal!.isEmpty) {
      setState(() {
        _exercisePlan = 'Please select a goal to generate the plan.';
        _isLoading = false;
      });
      return;
    }

    final prompt = '''
Generate a 7-day exercise plan for the following user preferences:

Goal: $_selectedGoal
Preferred workout time: ${_preferredTime ?? 'Any'}
Preferred workout type: ${_workoutType ?? 'Any'}
Wants yoga: ${_wantYoga ? 'Yes' : 'No'}
Has gym access: ${_hasGym ? 'Yes' : 'No'}
Can go for a run: ${_canRun ? 'Yes' : 'No'}
Can go cycling: ${_canCycle ? 'Yes' : 'No'}

Each day should include:
- Warm-up
- Main exercises (with sets, reps, rest)
- Cool-down
- Suggest yoga if wanted
- Suggest outdoor activities if possible
Include rest days if needed. Format it clearly by day.
''';

    final result = await GeminiService.callGeminiAPI(prompt);

    setState(() {
      _exercisePlan = result;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE0EAFC), Color(0xFFCFDEF3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildInputCard(context),
              const SizedBox(height: 24),
              _buildOutputCard(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputCard(BuildContext context) {
    return Card(
      elevation: 10,
      shadowColor: Colors.indigo[100],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      color: Colors.white.withOpacity(0.97),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                      Icons.fitness_center,
                      color: Color(0xFF6366F1),
                      size: 38,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Personalized Workout Planner',
                    style: TextStyle(
                      color: const Color(0xFF6366F1),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tell us about your workout preferences',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              value: _selectedGoal,
              items:
                  _goals
                      .map(
                        (goal) =>
                            DropdownMenuItem(value: goal, child: Text(goal)),
                      )
                      .toList(),
              decoration: const InputDecoration(
                labelText: 'Select Goal',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _selectedGoal = value;
                });
              },
            ),
            const SizedBox(height: 18),
            DropdownButtonFormField<String>(
              value: _preferredTime,
              items:
                  _times
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
              decoration: const InputDecoration(
                labelText: 'Preferred Workout Time',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _preferredTime = value;
                });
              },
            ),
            const SizedBox(height: 18),
            DropdownButtonFormField<String>(
              value: _workoutType,
              items:
                  _workoutTypes
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
              decoration: const InputDecoration(
                labelText: 'Preferred Workout Type',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _workoutType = value;
                });
              },
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _wantYoga,
                        onChanged: (val) => setState(() => _wantYoga = val ?? false),
                        activeColor: const Color(0xFF6366F1),
                      ),
                      const Icon(Icons.self_improvement, color: Color(0xFF6366F1)),
                      const SizedBox(width: 8),
                      const Text('Include Yoga'),
                    ],
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: _hasGym,
                        onChanged: (val) => setState(() => _hasGym = val ?? false),
                        activeColor: const Color(0xFF6366F1),
                      ),
                      const Icon(Icons.fitness_center, color: Color(0xFF6366F1)),
                      const SizedBox(width: 8),
                      const Text('Gym Access'),
                    ],
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: _canRun,
                        onChanged: (val) => setState(() => _canRun = val ?? false),
                        activeColor: const Color(0xFF6366F1),
                      ),
                      const Icon(Icons.directions_run, color: Color(0xFF6366F1)),
                      const SizedBox(width: 8),
                      const Text('Can go for a run'),
                    ],
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: _canCycle,
                        onChanged: (val) => setState(() => _canCycle = val ?? false),
                        activeColor: const Color(0xFF6366F1),
                      ),
                      const Icon(Icons.directions_bike, color: Color(0xFF6366F1)),
                      const SizedBox(width: 8),
                      const Text('Can go cycling'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Divider(color: Colors.indigo[100], thickness: 1.1, height: 1),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    (_isLoading || _selectedGoal == null)
                        ? null
                        : _generateExercisePlan,
                icon:
                    _isLoading
                        ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : const Icon(Icons.auto_awesome),
                label: const Text('Generate Workout Plan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutputCard(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child:
            _exercisePlan.isEmpty
                ? Text(
                  'Your personalized exercise plan will appear here.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                )
                : SingleChildScrollView(
                  child: Text(
                    _exercisePlan,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
      ),
    );
  }
}
