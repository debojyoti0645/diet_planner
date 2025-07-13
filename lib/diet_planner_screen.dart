import 'dart:convert';
import 'dart:io'; // Add this import

import 'package:diet_planner/gemini_service.dart';
import 'package:diet_planner/input_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart'; // Add this import
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class DietPlannerScreen extends StatefulWidget {
  const DietPlannerScreen({super.key});

  @override
  State<DietPlannerScreen> createState() => _DietPlannerScreenState();
}

class _DietPlannerScreenState extends State<DietPlannerScreen> {
  final _everydayLifeController = TextEditingController();
  final _cultureController = TextEditingController();
  final _foodHabitsController = TextEditingController();
  final _regionController = TextEditingController();
  final _religionController = TextEditingController();
  final _stapleFoodController = TextEditingController();
  String? _selectedExerciseGoal;
  String _dietPlanJson = '';
  Map<String, dynamic>? _dietPlanData;
  bool _isLoadingDiet = false;

  @override
  void dispose() {
    _everydayLifeController.dispose();
    _cultureController.dispose();
    _foodHabitsController.dispose();
    _regionController.dispose();
    _religionController.dispose();
    _stapleFoodController.dispose();
    super.dispose();
  }

  Future<void> _generateDietPlan() async {
    setState(() {
      _isLoadingDiet = true;
      _dietPlanJson = '';
      _dietPlanData = null;
    });

    if (_selectedExerciseGoal == null || _selectedExerciseGoal!.isEmpty) {
      setState(() {
        _dietPlanJson =
            'Please select an exercise goal to generate a diet plan.';
        _isLoadingDiet = false;
      });
      return;
    }

    final prompt = '''
Generate a personalized 7-day diet plan for a user.

Everyday Life: ${_everydayLifeController.text.isNotEmpty ? _everydayLifeController.text : 'Standard, moderate activity'}.
Culture: ${_cultureController.text.isNotEmpty ? _cultureController.text : 'General Western'}.
State/Region: ${_regionController.text.isNotEmpty ? _regionController.text : 'Not specified'}.
Religion/Caste: ${_religionController.text.isNotEmpty ? _religionController.text : 'Not specified'}.
Preferred Staple Foods: ${_stapleFoodController.text.isNotEmpty ? _stapleFoodController.text : 'Not specified'}.
Food Habits: ${_foodHabitsController.text.isNotEmpty ? _foodHabitsController.text : 'Omnivore, prefers home-cooked meals'}.
Exercise Goal: $_selectedExerciseGoal.

The plan should include breakfast, lunch, dinner, and 1–2 snacks per day.
Provide estimated calories per meal and total daily calories.
Include some general hydration tips. Format it clearly with days and meals.
''';

    final rawPlan = await GeminiService.callGeminiAPI(prompt);
    final cleanedJson = await GeminiService.postProcessDietPlan(rawPlan);

    try {
      String cleanedJsonStr =
          cleanedJson.replaceAll(RegExp(r'```json|```'), '').trim();
      final data = jsonDecode(cleanedJsonStr);
      setState(() {
        _dietPlanJson = '';
        _dietPlanData = data;
        _isLoadingDiet = false;
      });
    } catch (e) {
      setState(() {
        // Show the cleanedJson as plain text fallback
        _dietPlanJson =
            'Sorry, could not parse the plan as JSON. Here is the raw output:\n\n$cleanedJson';
        _dietPlanData = null;
        _isLoadingDiet = false;
      });
    }
  }

  Future<void> _downloadDietPlanAsPdf(BuildContext context) async {
    if (_dietPlanData == null) return;

    final pdf = pw.Document();

    // Load a TTF font that supports Unicode
    final font = pw.Font.ttf(
      await rootBundle.load('fonts/Roboto-Regular.ttf'),
    );

    final days = _dietPlanData!['days'] as List<dynamic>? ?? [];
    final guidelines = _dietPlanData!['important_guidelines'] as List<dynamic>? ?? [];
    final hydration = _dietPlanData!['hydration_tips'] as List<dynamic>? ?? [];

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          buildBackground: (context) => pw.Center(
            child: pw.Opacity(
              opacity: 0.08,
              child: pw.Text(
                'Diet Chart by Your Health Planner App',
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
        build: (pw.Context context) => [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  'Personalized Diet Plan',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.indigo,
                  ),
                ),
              ),
              pw.SizedBox(height: 16),
              for (final day in days) ...[
                pw.Text(
                  day['day'] ?? '',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.indigo,
                  ),
                ),
                pw.SizedBox(height: 6),
                for (final meal in (day['meals'] as Map<String, dynamic>).entries)
                  pw.Bullet(
                    text: '${meal.key}: ${meal.value}',
                    style: pw.TextStyle(font: font, fontSize: 13),
                  ),
                if (day['total_calories'] != null)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(left: 8, top: 2, bottom: 8),
                    child: pw.Text(
                      'Total Calories: ${day['total_calories']}',
                      style: pw.TextStyle(
                        font: font,
                        color: PdfColors.deepOrange,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                pw.Divider(),
              ],
              if (guidelines.isNotEmpty) ...[
                pw.SizedBox(height: 10),
                pw.Text(
                  'Important Guidelines:',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.indigo,
                  ),
                ),
                pw.SizedBox(height: 4),
                for (final tip in guidelines)
                  pw.Bullet(
                    text: tip,
                    style: pw.TextStyle(font: font, fontSize: 12),
                  ),
              ],
              if (hydration.isNotEmpty) ...[
                pw.SizedBox(height: 10),
                pw.Text(
                  'Hydration Tips:',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue,
                  ),
                ),
                pw.SizedBox(height: 4),
                for (final tip in hydration)
                  pw.Bullet(
                    text: tip,
                    style: pw.TextStyle(font: font, fontSize: 12),
                  ),
              ],
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Diet_Plan.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Add a gradient background
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
              _buildDietPlanOutput(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDietPlanOutput(BuildContext context) {
    if (_isLoadingDiet) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_dietPlanData != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildDietPlanFromJson(_dietPlanData!, context),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton.icon(
              onPressed: () => _downloadDietPlanAsPdf(context),
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
      );
    }
    return InputFields.buildOutputContainer(
      _dietPlanJson,
      'Your personalized diet plan will appear here.',
      context,
    );
  }

  Widget _buildDietPlanFromJson(
    Map<String, dynamic> data,
    BuildContext context,
  ) {
    final days = data['days'] as List<dynamic>? ?? [];
    final guidelines = data['important_guidelines'] as List<dynamic>? ?? [];
    final hydration = data['hydration_tips'] as List<dynamic>? ?? [];

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final day in days)
              Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Day header
                    Text(
                      day['day'] ?? '',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF6366F1),
                        fontWeight: FontWeight.bold,
                        fontSize: 19,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Meals as bullet points
                    for (final meal
                        in (day['meals'] as Map<String, dynamic>).entries)
                      Padding(
                        padding: const EdgeInsets.only(left: 12, bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  children: [
                                    TextSpan(
                                      text: "${meal.key}: ",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF6366F1),
                                      ),
                                    ),
                                    TextSpan(
                                      text: meal.value,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.normal,
                                        color: Color(0xFF374151),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Total calories
                    if (day['total_calories'] != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 12, top: 6),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.local_fire_department,
                              color: Colors.deepOrange,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Total Calories: ${day['total_calories']}',
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.copyWith(
                                color: Colors.deepOrange,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            if (guidelines.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    Text(
                      'Important Guidelines:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.indigo,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    for (final tip in guidelines)
                      Padding(
                        padding: const EdgeInsets.only(left: 12, bottom: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "• ",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.indigo,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                tip,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            if (hydration.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hydration Tips:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    for (final tip in hydration)
                      Padding(
                        padding: const EdgeInsets.only(left: 12, bottom: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "• ",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.blue,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                tip,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
          ],
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
                      Icons.restaurant_menu,
                      color: Color(0xFF6366F1),
                      size: 38,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Personalized Diet Planner',
                    style: TextStyle(
                      color: const Color(0xFF6366F1),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tell us about your lifestyle and preferences',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            InputFields.buildTextField(
              controller: _everydayLifeController,
              label: 'Everyday Life / Activity Level',
              hint: 'e.g., Office job, occasional walks, busy schedule',
              maxLines: 3,
            ),
            const SizedBox(height: 18),
            InputFields.buildTextField(
              controller: _cultureController,
              label: 'Culture / Cuisine Preference',
              hint: 'e.g., Indian, Mediterranean, Vegan',
            ),
            const SizedBox(height: 18),
            InputFields.buildTextField(
              controller: _foodHabitsController,
              label: 'Food Habits / Restrictions',
              hint:
                  'e.g., Vegetarian, prefers whole grains, dislikes spicy food',
              maxLines: 3,
            ),
            const SizedBox(height: 18),
            InputFields.buildTextField(
              controller: _regionController,
              label: 'State/Region',
              hint: 'e.g., Bengali, Punjabi, South Indian, Gujarati',
            ),
            const SizedBox(height: 18),
            InputFields.buildTextField(
              controller: _religionController,
              labelWidget: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Religion/Caste (if relevant)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: const Text('Why do we ask this?'),
                              content: const Text(
                                'Some dietary restrictions and preferences are influenced by religion or caste (e.g., Jain, Muslim, Hindu). '
                                'This helps us personalize your plan. You may skip this if you are not comfortable sharing.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                      );
                    },
                    child: const Icon(
                      Icons.info_outline,
                      size: 18,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                ],
              ),
              hint: 'e.g., Hindu, Jain, Muslim, Sikh, Christian',
            ),
            const SizedBox(height: 18),
            InputFields.buildTextField(
              controller: _stapleFoodController,
              label: 'Preferred Staple Foods',
              hint: 'e.g., Rice, Roti, Millet, Bread',
            ),
            const SizedBox(height: 18),
            InputFields.buildExerciseGoalDropdown(
              value: _selectedExerciseGoal,
              onChanged: (value) {
                setState(() {
                  _selectedExerciseGoal = value;
                });
              },
            ),
            const SizedBox(height: 24),
            Divider(color: Colors.indigo[100], thickness: 1.1, height: 1),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    (_isLoadingDiet || _selectedExerciseGoal == null)
                        ? null
                        : _generateDietPlan,
                icon:
                    _isLoadingDiet
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
                label: const Text('Generate Diet Plan'),
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
}
