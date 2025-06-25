import 'dart:convert';

import 'package:diet_planner/gemini_service.dart';
import 'package:flutter/material.dart';

class NutritionLookupScreen extends StatefulWidget {
  const NutritionLookupScreen({super.key});

  @override
  State<NutritionLookupScreen> createState() => _NutritionLookupScreenState();
}

class _NutritionLookupScreenState extends State<NutritionLookupScreen> {
  final TextEditingController _foodController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(text: "100");
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String _selectedUnit = 'g';
  String? _selectedMealType;
  String _nutritionInfo = '';
  bool _isLoading = false;

  final List<String> _units = ['g', 'ml', 'piece', 'cup', 'tbsp', 'tsp'];
  final List<String> _mealTypes = [
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snack',
    'Other'
  ];

  Map<String, dynamic>? _nutritionJson;

  @override
  void dispose() {
    _foodController.dispose();
    _quantityController.dispose();
    _brandController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _lookupNutrition() async {
    final query = _foodController.text.trim();
    final quantity = _quantityController.text.trim();
    final brand = _brandController.text.trim();
    final notes = _notesController.text.trim();

    if (query.isEmpty || quantity.isEmpty) {
      setState(() {
        _nutritionInfo = 'Please enter a food item and quantity.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _nutritionInfo = '';
      _nutritionJson = null;
    });

    final prompt = '''
Provide the approximate nutritional details for "$query", quantity: $quantity $_selectedUnit.
${brand.isNotEmpty ? "Brand: $brand." : ""}
${_selectedMealType != null ? "This is for $_selectedMealType." : ""}
${notes.isNotEmpty ? "Notes: $notes." : ""}
If the item is a dish or meal, list ALL main and secondary ingredients used to prepare it (not just 2-3), and their approximate nutrition in this format:
"ingredients": [
  {
    "name": "...",
    "quantity": "...",
    "unit": "...",
    "nutrition": {
      "calories": "...",
      "protein_g": "...",
      "carbohydrates_g": "...",
      "fat_g": "...",
      "fiber_g": "...",
      "sugar_g": "...",
      "sodium_mg": "..."
    }
  }
]
If the item is a packaged snack or ingredient, list all its main ingredients (if known) in the same way.
Respond ONLY in this JSON format:

{
  "food": "...",
  "quantity": "...",
  "unit": "...",
  "brand": "...",
  "meal_type": "...",
  "notes": "...",
  "nutrition": {
    "calories": "...",
    "protein_g": "...",
    "carbohydrates_g": "...",
    "fat_g": "...",
    "fiber_g": "...",
    "sugar_g": "...",
    "sodium_mg": "..."
  },
  "ingredients": [
    {
      "name": "...",
      "quantity": "...",
      "unit": "...",
      "nutrition": {
        "calories": "...",
        "protein_g": "...",
        "carbohydrates_g": "...",
        "fat_g": "...",
        "fiber_g": "...",
        "sugar_g": "...",
        "sodium_mg": "..."
      }
    }
  ],
  "tips": [
    "tip 1"
  ]
}

If you are unsure, output: {"nutrition":{}}
NO markdown, no commentary, no code block markers.
''';

    final response = await GeminiService.callGeminiAPI(prompt);

    try {
      final cleaned = response.replaceAll(RegExp(r'```json|```'), '').trim();
      final data = jsonDecode(cleaned);
      setState(() {
        _nutritionJson = data;
        _nutritionInfo = '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _nutritionInfo = response;
        _nutritionJson = null;
        _isLoading = false;
      });
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
                      Icons.search,
                      color: Color(0xFF6366F1),
                      size: 38,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Nutrition Lookup',
                    style: TextStyle(
                      color: const Color(0xFF6366F1),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Find nutrition info for any food or ingredient',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _foodController,
              decoration: const InputDecoration(
                labelText: 'Food or Ingredient *',
                hintText: 'e.g., Apple, Rice, Chicken Breast',
                prefixIcon: Icon(Icons.fastfood),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Flexible(
                  flex: 2,
                  child: TextField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantity *',
                      hintText: 'e.g., 100',
                      prefixIcon: Icon(Icons.scale),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: _selectedUnit,
                    items: _units
                        .map((u) => DropdownMenuItem(
                              value: u,
                              child: Text(
                                u,
                                style: const TextStyle(fontSize: 13), // Reduced font size
                              ),
                            ))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedUnit = val!;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Unit',
                      prefixIcon: Icon(Icons.straighten),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _brandController,
              decoration: const InputDecoration(
                labelText: 'Brand (optional)',
                hintText: 'e.g., Amul, Britannia, Nestle',
                prefixIcon: Icon(Icons.business),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedMealType,
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text(
                    'Meal Type (optional)',
                    style: TextStyle(fontSize: 13), // Reduced font size
                  ),
                ),
                ..._mealTypes.map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(
                        type,
                        style: const TextStyle(fontSize: 13), // Reduced font size
                      ),
                    )),
              ],
              onChanged: (val) {
                setState(() {
                  _selectedMealType = val;
                });
              },
              decoration: const InputDecoration(
                labelText: 'Meal Type',
                prefixIcon: Icon(Icons.restaurant),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes / Preparation (optional)',
                hintText: 'e.g., Cooked, raw, with skin, fried, etc.',
                prefixIcon: Icon(Icons.edit_note),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            Divider(color: Colors.indigo[100], thickness: 1.1, height: 1),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _lookupNutrition,
                icon: _isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Icon(Icons.search),
                label: const Text('Look Up Nutrition'),
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_nutritionJson != null && _nutritionJson!['nutrition'] != null && _nutritionJson!['nutrition'].isNotEmpty) {
      return _buildNutritionJsonCard(_nutritionJson!, context);
    }
    return Card(
      color: Colors.grey.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: _nutritionInfo.isEmpty
            ? Text(
                'Nutritional information will appear here.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: const Color(0xFF6B7280),
                    ),
              )
            : SelectableText(
                _nutritionInfo,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 15),
              ),
      ),
    );
  }

  Widget _buildNutritionJsonCard(Map<String, dynamic> data, BuildContext context) {
    final nutrition = data['nutrition'] as Map<String, dynamic>? ?? {};
    final tips = data['tips'] as List<dynamic>? ?? [];
    final ingredients = data['ingredients'] as List<dynamic>? ?? [];
    return Card(
      color: Colors.grey.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.fastfood, color: Color(0xFF6366F1), size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${data['food'] ?? ''} (${data['quantity'] ?? ''} ${data['unit'] ?? ''})',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: const Color(0xFF6366F1),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                  ),
                ),
              ],
            ),
            if ((data['brand'] ?? '').toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 4),
                child: Text(
                  'Brand: ${data['brand']}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[700],
                        fontSize: 13,
                      ),
                ),
              ),
            if ((data['meal_type'] ?? '').toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2, left: 4),
                child: Text(
                  'Meal Type: ${data['meal_type']}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[700],
                        fontSize: 13,
                      ),
                ),
              ),
            if ((data['notes'] ?? '').toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2, left: 4),
                child: Text(
                  'Notes: ${data['notes']}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[700],
                        fontSize: 13,
                      ),
                ),
              ),
            const SizedBox(height: 14),
            // Nutrition Table
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(2),
              },
              border: TableBorder.all(color: Color(0xFFE5E7EB), width: 1),
              children: [
                TableRow(
                  decoration: const BoxDecoration(color: Color(0xFFEEF2FF)),
                  children: [
                    _nutriCell('Nutrient', bold: true),
                    _nutriCell('Amount', bold: true),
                  ],
                ),
                _nutriRow('Calories', nutrition['calories']),
                _nutriRow('Protein', nutrition['protein_g'], suffix: 'g'),
                _nutriRow('Carbs', nutrition['carbohydrates_g'], suffix: 'g'),
                _nutriRow('Fat', nutrition['fat_g'], suffix: 'g'),
                _nutriRow('Fiber', nutrition['fiber_g'], suffix: 'g'),
                _nutriRow('Sugar', nutrition['sugar_g'], suffix: 'g'),
                _nutriRow('Sodium', nutrition['sodium_mg'], suffix: 'mg'),
              ],
            ),
            // INGREDIENTS SECTION
            if (ingredients.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ingredients & Their Nutrition:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.deepPurple,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    ...ingredients.map((ing) {
                      final ingNutrition = ing['nutrition'] as Map<String, dynamic>? ?? {};
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Card(
                          color: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${ing['name'] ?? ''} (${ing['quantity'] ?? ''} ${ing['unit'] ?? ''})',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF6366F1),
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Table(
                                  columnWidths: const {
                                    0: FlexColumnWidth(2),
                                    1: FlexColumnWidth(2),
                                  },
                                  border: TableBorder.all(color: Color(0xFFE5E7EB), width: 0.5),
                                  children: [
                                    _nutriRow('Calories', ingNutrition['calories']),
                                    _nutriRow('Protein', ingNutrition['protein_g'], suffix: 'g'),
                                    _nutriRow('Carbs', ingNutrition['carbohydrates_g'], suffix: 'g'),
                                    _nutriRow('Fat', ingNutrition['fat_g'], suffix: 'g'),
                                    _nutriRow('Fiber', ingNutrition['fiber_g'], suffix: 'g'),
                                    _nutriRow('Sugar', ingNutrition['sugar_g'], suffix: 'g'),
                                    _nutriRow('Sodium', ingNutrition['sodium_mg'], suffix: 'mg'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            if (tips.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tips:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    for (final tip in tips)
                      Padding(
                        padding: const EdgeInsets.only(left: 8, bottom: 2),
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

  TableRow _nutriRow(String label, dynamic value, {String suffix = ''}) {
    return TableRow(
      children: [
        _nutriCell(label),
        _nutriCell(value != null && value.toString().isNotEmpty ? '$value$suffix' : '-', bold: false),
      ],
    );
  }

  Widget _nutriCell(String text, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          fontSize: 14,
          color: bold ? const Color(0xFF6366F1) : const Color(0xFF374151),
        ),
      ),
    );
  }
}
