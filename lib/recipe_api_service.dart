import 'dart:convert';

import 'package:http/http.dart' as http;

class HealthyRecipeService {
  static const String _apiKey = "AIzaSyBF0P7J0kvBvOSnYw027zZB_HQB7ttj314";
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
}