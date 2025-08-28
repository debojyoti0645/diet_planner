import 'dart:convert';

import 'package:diet_planner/gemini_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

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
  List<ExerciseDay>? _parsedPlan;

  String? _splitPreference;
  String? _customSplit;

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

  final List<String> _splitOptions = [
    'Push-Pull-Legs',
    'Each Body Part a Day',
    'Mixed Body Parts',
    'Custom (Type Below)',
  ];

  Future<void> _generateExercisePlan() async {
    setState(() {
      _isLoading = true;
      _exercisePlan = '';
      _parsedPlan = null;
    });

    if (_selectedGoal == null || _selectedGoal!.isEmpty) {
      setState(() {
        _exercisePlan = 'Please select a goal to generate the plan.';
        _isLoading = false;
      });
      return;
    }

    final split =
        _splitPreference == 'Custom (Type Below)'
            ? (_customSplit?.isNotEmpty == true
                ? _customSplit
                : 'No preference')
            : _splitPreference ?? 'No preference';

    final prompt = '''
Generate a comprehensive 7-day exercise plan for the following user preferences:

Goal: $_selectedGoal
Preferred workout time: ${_preferredTime ?? 'Any'}
Preferred workout type: ${_workoutType ?? 'Any'}
Workout split: $split
Wants yoga: ${_wantYoga ? 'Yes' : 'No'}
Has gym access: ${_hasGym ? 'Yes' : 'No'}
Can go for a run: ${_canRun ? 'Yes' : 'No'}
Can go cycling: ${_canCycle ? 'Yes' : 'No'}

Create a balanced weekly routine with:
- Each day having exactly 6 main exercises
- Appropriate warm-up and cool-down for each day
- Exercise variety targeting different muscle groups
- Progressive difficulty throughout the week
- Rest/recovery considerations
- Include yoga sessions if requested
- Include outdoor activities (running/cycling) if available
- Specific sets, reps, and rest periods for each exercise

Focus on exercises that match the user's goal and available equipment/activities.
''';

    try {
      final rawResult = await GeminiService.callGeminiAPI(prompt);
      final cleanedJson = await GeminiService.postProcessExercisePlan(
        rawResult,
      );

      // Clean the result before parsing
      String cleanedResult =
          cleanedJson
              .replaceAll(RegExp(r'```json|```'), '')
              .replaceAll(RegExp(r'^[^{]*'), '') // Remove text before first {
              .replaceAll(RegExp(r'}[^}]*$'), '}') // Remove text after last }
              .trim();

      final decoded = jsonDecode(cleanedResult);

      // Validate the structure
      if (decoded is Map && decoded.containsKey('days')) {
        final daysData = decoded['days'];
        if (daysData is List && daysData.isNotEmpty) {
          final days =
              daysData
                  .map((e) => ExerciseDay.fromJson(e as Map<String, dynamic>))
                  .toList();

          setState(() {
            _parsedPlan = days;
            _exercisePlan = ''; // Clear any error message
            _isLoading = false;
          });
        } else {
          throw Exception('Invalid days structure');
        }
      } else {
        throw Exception('Invalid JSON structure');
      }
    } catch (e) {
      setState(() {
        _exercisePlan =
            'Could not generate plan. Please try again.\nError: ${e.toString()}';
        _parsedPlan = null;
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadExercisePlanAsPdf(BuildContext context) async {
    if (_parsedPlan == null || _parsedPlan!.isEmpty) return;

    try {
      final pdf = pw.Document();

      // Load a TTF font that supports Unicode
      final font = pw.Font.ttf(
        await rootBundle.load('fonts/Roboto-Regular.ttf'),
      );

      pdf.addPage(
        pw.MultiPage(
          pageTheme: pw.PageTheme(
            buildBackground:
                (context) => pw.Center(
                  child: pw.Opacity(
                    opacity: 0.08,
                    child: pw.Text(
                      'Workout Plan by Your Health Planner App',
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 48,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blueGrey,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                ),
          ),
          build:
              (pw.Context context) => [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Center(
                      child: pw.Text(
                        'Personalized Workout Plan',
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 28,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.indigo,
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 20),

                    // Plan Summary
                    pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(
                          color: PdfColors.indigo,
                          width: 1,
                        ),
                        borderRadius: const pw.BorderRadius.all(
                          pw.Radius.circular(8),
                        ),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Plan Details:',
                            style: pw.TextStyle(
                              font: font,
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Goal: ${_selectedGoal ?? "General Fitness"}',
                            style: pw.TextStyle(font: font, fontSize: 12),
                          ),
                          pw.Text(
                            'Workout Type: ${_workoutType ?? "Mixed"}',
                            style: pw.TextStyle(font: font, fontSize: 12),
                          ),
                          pw.Text(
                            'Preferred Time: ${_preferredTime ?? "Flexible"}',
                            style: pw.TextStyle(font: font, fontSize: 12),
                          ),
                          if (_wantYoga)
                            pw.Text(
                              'Includes Yoga Sessions',
                              style: pw.TextStyle(font: font, fontSize: 12),
                            ),
                          if (_hasGym)
                            pw.Text(
                              'Gym Access Available',
                              style: pw.TextStyle(font: font, fontSize: 12),
                            ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 16),

                    for (final day in _parsedPlan!) ...[
                      pw.Text(
                        day.day,
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.indigo,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Bullet(
                        text: 'Warm-up: ${day.warmup}',
                        style: pw.TextStyle(font: font, fontSize: 13),
                      ),
                      pw.Text(
                        'Main Exercises:',
                        style: pw.TextStyle(
                          font: font,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.indigo,
                          fontSize: 14,
                        ),
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          for (final ex in day.main)
                            pw.Bullet(
                              text:
                                  '${ex['exercise']} (${ex['sets']} sets x ${ex['reps']} reps, Rest: ${ex['rest']})',
                              style: pw.TextStyle(font: font, fontSize: 12),
                            ),
                        ],
                      ),
                      pw.Bullet(
                        text: 'Cool-down: ${day.cooldown}',
                        style: pw.TextStyle(font: font, fontSize: 13),
                      ),
                      if (day.yoga != null && day.yoga!.isNotEmpty)
                        pw.Bullet(
                          text: 'Yoga: ${day.yoga}',
                          style: pw.TextStyle(font: font, fontSize: 12),
                        ),
                      if (day.outdoor != null && day.outdoor!.isNotEmpty)
                        pw.Bullet(
                          text: 'Outdoor: ${day.outdoor}',
                          style: pw.TextStyle(font: font, fontSize: 12),
                        ),
                      if (day.notes != null && day.notes!.isNotEmpty)
                        pw.Bullet(
                          text: 'Notes: ${day.notes}',
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 12,
                            color: PdfColors.deepOrange,
                          ),
                        ),
                      pw.Divider(),
                      pw.SizedBox(height: 8),
                    ],
                  ],
                ),
              ],
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Workout_Plan.pdf',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating PDF: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
            padding: const EdgeInsets.all(8),
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
                      fontSize: 22,
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
                        (goal) => DropdownMenuItem(
                          value: goal,
                          child: Text(
                            goal,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      )
                      .toList(),
              decoration: const InputDecoration(
                labelText: 'Select Goal *',
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
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(t, style: const TextStyle(fontSize: 13)),
                        ),
                      )
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
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(t, style: const TextStyle(fontSize: 13)),
                        ),
                      )
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
            DropdownButtonFormField<String>(
              value: _splitPreference,
              items:
                  _splitOptions
                      .map(
                        (split) => DropdownMenuItem(
                          value: split,
                          child: Text(
                            split,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      )
                      .toList(),
              decoration: const InputDecoration(
                labelText: 'Workout Split Preference',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _splitPreference = value;
                  if (value != 'Custom (Type Below)') _customSplit = null;
                });
              },
            ),
            if (_splitPreference == 'Custom (Type Below)')
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Describe your workout split',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) => setState(() => _customSplit = val),
                ),
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
                        onChanged:
                            (val) => setState(() => _wantYoga = val ?? false),
                        activeColor: const Color(0xFF6366F1),
                      ),
                      const Icon(
                        Icons.self_improvement,
                        color: Color(0xFF6366F1),
                      ),
                      const SizedBox(width: 8),
                      const Text('Include Yoga'),
                    ],
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: _hasGym,
                        onChanged:
                            (val) => setState(() => _hasGym = val ?? false),
                        activeColor: const Color(0xFF6366F1),
                      ),
                      const Icon(
                        Icons.fitness_center,
                        color: Color(0xFF6366F1),
                      ),
                      const SizedBox(width: 8),
                      const Text('Gym Access'),
                    ],
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: _canRun,
                        onChanged:
                            (val) => setState(() => _canRun = val ?? false),
                        activeColor: const Color(0xFF6366F1),
                      ),
                      const Icon(
                        Icons.directions_run,
                        color: Color(0xFF6366F1),
                      ),
                      const SizedBox(width: 8),
                      const Text('Can go for a run'),
                    ],
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: _canCycle,
                        onChanged:
                            (val) => setState(() => _canCycle = val ?? false),
                        activeColor: const Color(0xFF6366F1),
                      ),
                      const Icon(
                        Icons.directions_bike,
                        color: Color(0xFF6366F1),
                      ),
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
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : (_parsedPlan == null)
                ? Text(
                  _exercisePlan.isEmpty
                      ? 'Your personalized exercise plan will appear here.'
                      : _exercisePlan,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                )
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with plan summary
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.fitness_center,
                            color: const Color(0xFF6366F1),
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '7-Day Workout Plan',
                            style: Theme.of(
                              context,
                            ).textTheme.titleLarge?.copyWith(
                              color: const Color(0xFF6366F1),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Goal: ${_selectedGoal ?? "General Fitness"}',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    for (final day in _parsedPlan!)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Day header
                            Text(
                              day.day,
                              style: Theme.of(
                                context,
                              ).textTheme.titleMedium?.copyWith(
                                color: const Color(0xFF6366F1),
                                fontWeight: FontWeight.bold,
                                fontSize: 19,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Warm-up
                            Row(
                              children: [
                                const Icon(
                                  Icons.directions_run,
                                  color: Colors.orange,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Warm-up: ',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF6366F1),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    day.warmup,
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            // Main Exercises
                            Row(
                              children: [
                                const Icon(
                                  Icons.fitness_center,
                                  color: Colors.indigo,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Main Exercises:',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF6366F1),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Padding(
                              padding: const EdgeInsets.only(left: 18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  for (final ex in day.main)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 2),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "• ",
                                            style: TextStyle(
                                              fontSize: 18,
                                              color: Color(0xFF6366F1),
                                            ),
                                          ),
                                          Expanded(
                                            child: RichText(
                                              text: TextSpan(
                                                style:
                                                    Theme.of(
                                                      context,
                                                    ).textTheme.bodyMedium,
                                                children: [
                                                  TextSpan(
                                                    text: ex['exercise'],
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color(0xFF6366F1),
                                                    ),
                                                  ),
                                                  TextSpan(
                                                    text: '  (',
                                                    style: TextStyle(
                                                      color: Colors.grey[700],
                                                    ),
                                                  ),
                                                  TextSpan(
                                                    text: '${ex['sets']} sets',
                                                    style: const TextStyle(
                                                      color: Colors.deepOrange,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  TextSpan(
                                                    text: ' x ',
                                                    style: TextStyle(
                                                      color: Colors.grey[700],
                                                    ),
                                                  ),
                                                  TextSpan(
                                                    text: '${ex['reps']} reps',
                                                    style: const TextStyle(
                                                      color: Colors.green,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  TextSpan(
                                                    text: ', Rest: ',
                                                    style: TextStyle(
                                                      color: Colors.grey[700],
                                                    ),
                                                  ),
                                                  TextSpan(
                                                    text: ex['rest'],
                                                    style: const TextStyle(
                                                      color: Colors.blue,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  const TextSpan(text: ')'),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Cool-down
                            Row(
                              children: [
                                const Icon(
                                  Icons.self_improvement,
                                  color: Colors.green,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Cool-down: ',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF6366F1),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    day.cooldown,
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                            // Yoga
                            if (day.yoga != null && day.yoga!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.self_improvement,
                                      color: Colors.purple,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Yoga: ',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF6366F1),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        day.yoga!,
                                        style:
                                            Theme.of(
                                              context,
                                            ).textTheme.bodyMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            // Outdoor
                            if (day.outdoor != null && day.outdoor!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.directions_bike,
                                      color: Colors.blue,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Outdoor: ',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF6366F1),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        day.outdoor!,
                                        style:
                                            Theme.of(
                                              context,
                                            ).textTheme.bodyMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            // Notes
                            if (day.notes != null && day.notes!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.info_outline,
                                      color: Colors.deepOrange,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Notes: ',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF6366F1),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        day.notes!,
                                        style:
                                            Theme.of(
                                              context,
                                            ).textTheme.bodyMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () => _downloadExercisePlanAsPdf(context),
                        icon: const Icon(Icons.download),
                        label: const Text('Download as PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}

class ExerciseDay {
  final String day;
  final String warmup;
  final List<dynamic> main;
  final String cooldown;
  final String? yoga;
  final String? outdoor;
  final String? notes;

  ExerciseDay({
    required this.day,
    required this.warmup,
    required this.main,
    required this.cooldown,
    this.yoga,
    this.outdoor,
    this.notes,
  });

  factory ExerciseDay.fromJson(Map<String, dynamic> json) {
    return ExerciseDay(
      day: json['day'] ?? '',
      warmup: json['warmup'] ?? '',
      main: json['main'] ?? [],
      cooldown: json['cooldown'] ?? '',
      yoga: json['yoga']?.isEmpty == true ? null : json['yoga'],
      outdoor: json['outdoor']?.isEmpty == true ? null : json['outdoor'],
      notes: json['notes']?.isEmpty == true ? null : json['notes'],
    );
  }
}
