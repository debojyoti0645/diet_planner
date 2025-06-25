import 'package:flutter/material.dart';

class CalorieBurnedEstimator extends StatefulWidget {
  @override
  State<CalorieBurnedEstimator> createState() => _CalorieBurnedEstimatorState();
}

class _CalorieBurnedEstimatorState extends State<CalorieBurnedEstimator> {
  final _formKey = GlobalKey<FormState>();
  double weight = 70; // kg
  double height = 170; // cm
  int age = 25;
  String activityLevel = 'Moderate';
  String exercise = 'Running';
  double duration = 30; // minutes

  double? caloriesBurned;

  final List<String> activityLevels = [
    'Sedentary',
    'Light',
    'Moderate',
    'Active',
    'Very Active',
  ];

  final List<String> exercises = [
    'Running',
    'Cycling',
    'Weightlifting',
    'Swimming',
    'Walking',
    'Yoga',
  ];

  // MET values for each exercise (approximate)
  final Map<String, double> exerciseMETs = {
    'Running': 9.8,
    'Cycling': 7.5,
    'Weightlifting': 6.0,
    'Swimming': 8.0,
    'Walking': 3.8,
    'Yoga': 2.5,
  };

  void estimateCalories() {
    double met = exerciseMETs[exercise] ?? 6.0;
    double caloriesPerMinute = (met * 3.5 * weight) / 200;
    setState(() {
      caloriesBurned = caloriesPerMinute * duration;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Calories Burned Estimator',
          style: TextStyle(
            color: Color(0xFF6366F1),
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 1.1,
          ),
        ),
        centerTitle: true,
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 28,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                                      Icons.local_fire_department,
                                      color: Color(0xFF6366F1),
                                      size: 38,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Calories Burned Estimator',
                                    style: TextStyle(
                                      color: const Color(0xFF6366F1),
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "While not perfectly accurate, it can give you a general idea of your energy expenditure.",
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
                            // Weight & Height in one row
                            Row(
                              children: [
                                Flexible(
                                  flex: 1,
                                  child: TextFormField(
                                    decoration: const InputDecoration(
                                      labelText: 'Weight (kg)',
                                      prefixIcon: Icon(Icons.monitor_weight),
                                    ),
                                    initialValue: weight.toString(),
                                    keyboardType: TextInputType.number,
                                    onChanged:
                                        (val) =>
                                            weight =
                                                double.tryParse(val) ?? weight,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Flexible(
                                  flex: 1,
                                  child: TextFormField(
                                    decoration: const InputDecoration(
                                      labelText: 'Height (cm)',
                                      prefixIcon: Icon(Icons.height),
                                    ),
                                    initialValue: height.toString(),
                                    keyboardType: TextInputType.number,
                                    onChanged:
                                        (val) =>
                                            height =
                                                double.tryParse(val) ?? height,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Duration & Age in one row
                            Row(
                              children: [
                                Flexible(
                                  flex: 1,
                                  child: TextFormField(
                                    decoration: const InputDecoration(
                                      labelText: 'Age',
                                      prefixIcon: Icon(Icons.cake),
                                    ),
                                    initialValue: age.toString(),
                                    keyboardType: TextInputType.number,
                                    onChanged:
                                        (val) => age = int.tryParse(val) ?? age,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Activity Level and Exercise dropdowns in a column
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Activity Level',
                                prefixIcon: Icon(Icons.directions_walk),
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 12,
                                ),
                              ),
                              dropdownColor: Colors.white,
                              value: activityLevel,
                              items: activityLevels
                                  .map(
                                    (level) => DropdownMenuItem(
                                      value: level,
                                      child: Text(
                                        level,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.black,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => activityLevel = val);
                              },
                              style: const TextStyle(fontSize: 13, color: Colors.black),
                              isExpanded: true,
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Exercise/Workout',
                                prefixIcon: Icon(Icons.fitness_center),
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 12,
                                ),
                              ),
                              dropdownColor: Colors.white,
                              value: exercise,
                              items: exercises
                                  .map(
                                    (ex) => DropdownMenuItem(
                                      value: ex,
                                      child: Text(
                                        ex,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.black,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => exercise = val);
                              },
                              style: const TextStyle(fontSize: 13, color: Colors.black),
                              isExpanded: true,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Duration (minutes)',
                                prefixIcon: Icon(Icons.timer),
                              ),
                              initialValue: duration.toString(),
                              keyboardType: TextInputType.number,
                              onChanged:
                                  (val) =>
                                      duration =
                                          double.tryParse(val) ?? duration,
                            ),

                            const SizedBox(height: 24),
                            Divider(
                              color: Colors.indigo[100],
                              thickness: 1.1,
                              height: 1,
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: estimateCalories,
                                icon: const Icon(Icons.calculate),
                                label: const Text('Estimate Calories Burned'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6366F1),
                                  foregroundColor: Colors.white,
                                  elevation: 6,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
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
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (caloriesBurned != null)
                    Card(
                      color: Colors.green[50],
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.local_fire_department,
                              color: Color(0xFF22C55E),
                              size: 38,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Estimated Calories Burned',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[800],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${caloriesBurned!.toStringAsFixed(1)} kcal',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF22C55E),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '(${(caloriesBurned! / duration).toStringAsFixed(1)} kcal/min | ${(caloriesBurned! * 60 / duration).toStringAsFixed(1)} kcal/hr)',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.green[700],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 18),
                  Card(
                    color: Colors.white.withOpacity(0.97),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Color(0xFF6366F1),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Why it's useful: Helps you understand your energy balance and fitness goals.",
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.copyWith(
                                fontStyle: FontStyle.italic,
                                color: Colors.grey[700],
                              ),
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
    );
  }
}
