import 'package:flutter/material.dart';

class InputFields {
  static Widget buildTextField({
    required TextEditingController controller,
    String? label,
    Widget? labelWidget,
    String? hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelWidget != null)
          labelWidget
        else if (label != null)
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF374151),
            ),
          ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(hintText: hint, alignLabelWithHint: true),
        ),
      ],
    );
  }

  static Widget buildExerciseGoalDropdown({
    required String? value,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Exercise Goal:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: const InputDecoration(
            hintText: 'Select your goal',
            hintStyle: TextStyle(fontSize: 12),
          ),
          items:
              <String>[
                'Bulking (muscle gain)',
                'Cutting (fat loss with muscle retention)',
                'Weight Gain',
                'Weight Loss',
                'Fat Loss',
                'General Fitness / Endurance',
                'Strength Training',
                'Flexibility / Mobility',
                'Stress Reduction / Mind-Body',
              ].map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF374151),
                    ),
                  ),
                );
              }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  static Widget buildOutputContainer(
    String content,
    String placeholder,
    BuildContext context,
  ) {
    // Helper to prettify meal plan output
    List<Widget> parseDietPlan(String text) {
      final List<Widget> widgets = [];
      final lines = text.split('\n');
      final dayRegex = RegExp(r'^Day\s*\d+', caseSensitive: false);
      final mealRegex = RegExp(
        r'^(Breakfast|Lunch|Dinner|Snacks?)[:\-]?',
        caseSensitive: false,
      );
      final caloriesRegex = RegExp(
        r'(calories|kcal|total)',
        caseSensitive: false,
      );

      for (final rawLine in lines) {
        String line = rawLine.trim();
        if (line.isEmpty) continue;

        // Remove leading bullets or dashes
        line = line.replaceFirst(RegExp(r'^(\*|\-)\s*'), '');

        if (dayRegex.hasMatch(line)) {
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 6),
              child: Text(
                line,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF6366F1),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          );
        } else if (mealRegex.hasMatch(line)) {
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 2, left: 4),
              child: Text(
                line,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6366F1),
                  fontSize: 15,
                ),
              ),
            ),
          );
        } else if (caloriesRegex.hasMatch(line)) {
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 2, bottom: 2),
              child: Text(
                line,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.deepOrange,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          );
        } else {
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(left: 18, bottom: 2),
              child: Text(
                line,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontSize: 14),
              ),
            ),
          );
        }
      }
      return widgets;
    }

    Widget formattedContent() {
      // Try to prettify as a diet plan if it contains "Day" and "Breakfast"
      if (content.contains('Day') && content.contains('Breakfast')) {
        final widgets = parseDietPlan(content);
        if (widgets.isNotEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: widgets,
          );
        }
      }
      // Fallback: show as selectable text
      return SelectableText(
        content,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      constraints: const BoxConstraints(minHeight: 120),
      child:
          content.isNotEmpty
              ? formattedContent()
              : Text(
                placeholder,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: const Color(0xFF6B7280),
                ),
              ),
    );
  }
}
