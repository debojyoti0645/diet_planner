import 'dart:convert';

import 'package:http/http.dart' as http;

class GeminiService {
  static const String _apiKey = "AIzaSyAXv2wagHdL9IEwNsjJ9YTu1TeHL56po78"; // Provide your API key here
  static Future<String> callGeminiAPI(String prompt, {String model = "gemini-2.0-flash"}) async {
    final Uri apiUrl = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$_apiKey');

    try {
      final Map<String, dynamic> payload = {
        "contents": [
          {
            "role": "user",
            "parts": [{"text": prompt}],
          }
        ],
      };

      final http.Response response = await http.post(
        apiUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> result = jsonDecode(response.body);
        if (result['candidates'] != null && result['candidates'].isNotEmpty) {
          return result['candidates'][0]['content']['parts'][0]['text'];
        } else {
          return "Error: Could not generate content. Please try again. Response: ${response.body}";
        }
      } else {
        return "Error: API call failed with status ${response.statusCode}. Body: ${response.body}";
      }
    } catch (e) {
      return "Error: Failed to connect to the AI model. Exception: $e";
    }
  }

  static Future<String> postProcessDietPlan(String rawPlan) async {
    final prompt = '''
You are a helpful assistant for a diet planner app.
Reformat and organize the following diet plan as a JSON object with this structure:

{
  "days": [
    {
      "day": "Day 1",
      "meals": {
        "Breakfast": "...",
        "Snack 1": "...",
        "Lunch": "...",
        "Snack 2": "...",
        "Dinner": "..."
      },
      "total_calories": "..."
    }
  ],
  "important_guidelines": [
    "tip 1"
  ],
  "hydration_tips": [
    "tip 1"
  ]
}

IMPORTANT:
- Output ONLY valid JSON, no markdown, no commentary, no extra text.
- Do NOT include ```json or any code block markers.
- If you are unsure, output: {"days":[],"important_guidelines":[],"hydration_tips":[]}

Here is the plan:
$rawPlan
''';

    return await callGeminiAPI(prompt);
  }
}