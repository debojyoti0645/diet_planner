import 'dart:convert';

import 'package:diet_planner/recipe_api_service.dart';
import 'package:flutter/material.dart';

class HealthyRecipeScreen extends StatefulWidget {
  const HealthyRecipeScreen({super.key});

  @override
  State<HealthyRecipeScreen> createState() => _HealthyRecipeScreenState();
}

class _HealthyRecipeScreenState extends State<HealthyRecipeScreen> {
  final TextEditingController _ingredientsController = TextEditingController();
  final TextEditingController _specificRecipeController =
      TextEditingController();
  String _dietType = 'Vegetarian';
  String _goal = 'General Health';
  bool _isLoading = false;
  String _recipeResult = '';
  Map<String, dynamic>? _recipeJson;

  final List<String> _dietTypes = [
    'Vegetarian',
    'Non-Vegetarian',
    'Vegan',
    'Eggetarian',
  ];
  final List<String> _goals = [
    'General Health',
    'Cutting (⬇️ Fat, ⬆️ Protein)',
    'Bulking (⬆️ Protein, ⬇️ Carbs)',
    'Weight Loss',
    'Muscle Gain',
    'Diabetic Friendly',
    'Low Carb',
    'High Fiber',
    'Gluten Free',
  ];

  @override
  void dispose() {
    _ingredientsController.dispose();
    _specificRecipeController.dispose();
    super.dispose();
  }

  Future<void> _findRecipe() async {
    setState(() {
      _isLoading = true;
      _recipeResult = '';
      _recipeJson = null;
    });

    final ingredients = _ingredientsController.text.trim();
    final specific = _specificRecipeController.text.trim();

    final prompt = '''
You are a healthy recipe assistant for a diet planner app.
Suggest a healthy, detailed recipe based on the following:

Ingredients available: ${ingredients.isNotEmpty ? ingredients : 'Not specified'}
Diet type: $_dietType
Goal: $_goal
${specific.isNotEmpty ? "User request: $specific" : ""}

- If the user asks for a specific recipe (e.g., "Healthy chicken biryani", "Healthy lunch with rice and egg"), provide a healthy version of that recipe.
- If only ingredients are given, suggest a healthy recipe using those, and you may suggest 2-3 additional healthy ingredients if needed.
- The recipe should be detailed, with steps, nutrition info, and tips.
- Respond ONLY in this JSON format (no markdown, no commentary):

{
  "recipe_name": "...",
  "ingredients": [
    {"name": "...", "quantity": "...", "unit": "..."}
  ],
  "additional_suggestions": [
    "ingredient 1", "ingredient 2"
  ],
  "steps": [
    "step 1", "step 2"
  ],
  "nutrition": {
    "calories": "...",
    "protein gm": "...",
    "carbohydrates gm": "...",
    "fat gm": "...",
    "fiber gm": "..."
  },
  "tips": [
    "tip 1"
  ]
}

If you are unsure, output: {"recipe_name": "", "ingredients": [], "steps": [], "nutrition": {}, "tips": []}
''';

    // Use the new service here:
    final response = await HealthyRecipeService.callGeminiAPI(prompt);

    try {
      final cleaned = response.replaceAll(RegExp(r'```json|```'), '').trim();
      final data = jsonDecode(cleaned);
      setState(() {
        _recipeJson = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _recipeResult = response;
        _isLoading = false;
      });
    }
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
                      Icons.restaurant_menu_rounded,
                      color: Color(0xFF6366F1),
                      size: 38,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Find Healthy Recipes',
                    style: TextStyle(
                      color: const Color(0xFF6366F1),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Find healthy recipes based on your ingredients and goals',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _ingredientsController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Ingredients you have (comma separated)',
                labelStyle: TextStyle(fontSize: 15),
                prefixIcon: Icon(Icons.kitchen),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _dietType,
              decoration: const InputDecoration(
                labelText: 'Diet Type',
                prefixIcon: Icon(Icons.eco),
              ),
              items:
                  _dietTypes
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(
                            type,
                            style: const TextStyle(
                              fontSize: 14,
                            ), // Reduced font size
                          ),
                        ),
                      )
                      .toList(),
              onChanged: (val) {
                setState(() {
                  _dietType = val ?? 'Vegetarian';
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _goal,
              decoration: const InputDecoration(
                labelText: 'Goal / Preference',
                prefixIcon: Icon(Icons.flag),
              ),
              items:
                  _goals
                      .map(
                        (goal) => DropdownMenuItem(
                          value: goal,
                          child: Text(
                            goal,
                            style: const TextStyle(
                              fontSize: 13,
                            ), // Reduced font size
                          ),
                        ),
                      )
                      .toList(),
              onChanged: (val) {
                setState(() {
                  _goal = val ?? 'General Health';
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _specificRecipeController,
              decoration: const InputDecoration(
                labelText: 'Specific recipe or request (optional)',
                labelStyle: TextStyle(
                  fontSize: 14,
                  overflow: TextOverflow.visible,
                ),
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 24),
            Divider(color: Colors.indigo[100], thickness: 1.1, height: 1),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon:
                    _isLoading
                        ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                        : const Icon(Icons.auto_awesome),
                label: const Text('Find Healthy Recipe'),
                onPressed: _isLoading ? null : _findRecipe,
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

  Widget _buildRecipeCard(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_recipeJson != null &&
        (_recipeJson!['recipe_name'] ?? '').toString().isNotEmpty) {
      final data = _recipeJson!;
      return Card(
        elevation: 10,
        shadowColor: Colors.indigo[100],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        color: Colors.white.withOpacity(0.97),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(22.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.restaurant,
                      color: Color(0xFF6366F1),
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        data['recipe_name'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if ((data['ingredients'] as List?)?.isNotEmpty ?? false)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ingredients:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ...((data['ingredients'] as List).map((ing) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 8, bottom: 2),
                          child: Text(
                            '• ${ing['name']} (${ing['quantity']} ${ing['unit']})',
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      })),
                    ],
                  ),
                if ((data['additional_suggestions'] as List?)?.isNotEmpty ??
                    false)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.add_circle_outline,
                          color: Colors.teal,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Suggested additional ingredients: ${(data['additional_suggestions'] as List).join(', ')}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.teal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 14),
                if ((data['steps'] as List?)?.isNotEmpty ?? false)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Steps:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ...((data['steps'] as List).asMap().entries.map((entry) {
                        final idx = entry.key + 1;
                        final step = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(left: 8, bottom: 2),
                          child: Text(
                            '$idx. $step',
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      })),
                    ],
                  ),
                const SizedBox(height: 14),
                if ((data['nutrition'] as Map?)?.isNotEmpty ?? false)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Nutrition (per serving):',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Table(
                        columnWidths: const {
                          0: FlexColumnWidth(2),
                          1: FlexColumnWidth(2),
                        },
                        border: TableBorder.all(
                          color: Color(0xFFE5E7EB),
                          width: 1,
                        ),
                        children: [
                          ...((data['nutrition'] as Map).entries.map((e) {
                            return TableRow(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6,
                                    horizontal: 8,
                                  ),
                                  child: Text(
                                    e.key,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF6366F1),
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6,
                                    horizontal: 8,
                                  ),
                                  child: Text(
                                    e.value.toString(),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF374151),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          })),
                        ],
                      ),
                    ],
                  ),
                if ((data['tips'] as List?)?.isNotEmpty ?? false)
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tips:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        for (final tip in data['tips'])
                          Padding(
                            padding: const EdgeInsets.only(left: 8, bottom: 2),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "• ",
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.green,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    tip,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.green,
                                    ),
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
        ),
      );
    }
    if (_recipeResult.isNotEmpty) {
      return Card(
        color: Colors.grey.shade100,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 6,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: SelectableText(_recipeResult),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: const Text('Healthy Recipe Finder'),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
          child: ListView(
            padding: const EdgeInsets.all(8),
            children: [
              _buildInputCard(context),
              const SizedBox(height: 24),
              _buildRecipeCard(context),
            ],
          ),
        ),
      ),
    );
  }
}
