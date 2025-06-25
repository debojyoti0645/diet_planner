import 'package:diet_planner/gemini_service.dart';
import 'package:flutter/material.dart';

class NutritionLookupScreen extends StatefulWidget {
  const NutritionLookupScreen({super.key});

  @override
  State<NutritionLookupScreen> createState() => _NutritionLookupScreenState();
}

class _NutritionLookupScreenState extends State<NutritionLookupScreen> {
  final TextEditingController _foodController = TextEditingController();
  String _nutritionInfo = '';
  bool _isLoading = false;

  @override
  void dispose() {
    _foodController.dispose();
    super.dispose();
  }

  Future<void> _lookupNutrition() async {
    final query = _foodController.text.trim();

    if (query.isEmpty) {
      setState(() {
        _nutritionInfo = 'Please enter a food item.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _nutritionInfo = '';
    });

    final prompt = '''
What are the approximate nutritional details (calories, protein, carbohydrates, fat, fiber) for "$query" per 100g? 
If a serving size is more appropriate, provide details for a typical serving. 
Be concise and provide numerical estimates.
''';

    final response = await GeminiService.callGeminiAPI(prompt);

    setState(() {
      _nutritionInfo = response;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition Lookup'),
        centerTitle: true,
        elevation: 2,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildCard(context),
            const SizedBox(height: 20),
            _buildOutputContainer(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Enter a food item to get nutritional info',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _foodController,
              decoration: const InputDecoration(
                labelText: 'Food or Ingredient',
                hintText: 'e.g., Apple, Rice, Chicken Breast',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _lookupNutrition,
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
                        : const Icon(Icons.search),
                label: const Text('Look Up Nutrition'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutputContainer(BuildContext context) {
    return Card(
      color: Colors.grey.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          _nutritionInfo.isEmpty
              ? 'Nutritional information will appear here.'
              : _nutritionInfo,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
