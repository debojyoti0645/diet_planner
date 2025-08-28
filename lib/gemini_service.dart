import 'dart:convert';

import 'package:http/http.dart' as http;

class GeminiService {
  static const String _apiKey = "AIzaSyBF0P7J0kvBvOSnYw027zZB_HQB7ttj314";
  static Future<String> callGeminiAPI(
    String prompt, {
    String model = "gemini-2.0-flash",
  }) async {
    final Uri apiUrl = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$_apiKey',
    );

    try {
      final Map<String, dynamic> payload = {
        "contents": [
          {
            "role": "user",
            "parts": [
              {"text": prompt},
            ],
          },
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

  static Future<String> postProcessExercisePlan(String rawPlan) async {
    final prompt = '''
You are a helpful assistant for a fitness app that needs to reformat exercise plans into a specific JSON structure.

Please reformat the following exercise plan into a valid JSON object with EXACTLY this structure:

{
  "days": [
    {
      "day": "Monday",
      "warmup": "5-10 minute warm-up description",
      "main": [
        {"exercise": "Exercise Name", "sets": 3, "reps": 12, "rest": "60s"},
        {"exercise": "Exercise Name", "sets": 3, "reps": 15, "rest": "90s"},
        {"exercise": "Exercise Name", "sets": 4, "reps": 10, "rest": "60s"},
        {"exercise": "Exercise Name", "sets": 3, "reps": 12, "rest": "60s"},
        {"exercise": "Exercise Name", "sets": 3, "reps": 8, "rest": "90s"},
        {"exercise": "Exercise Name", "sets": 2, "reps": 20, "rest": "45s"}
      ],
      "cooldown": "5-10 minute cool-down description",
      "yoga": "Yoga routine description (if applicable)",
      "outdoor": "Outdoor activity description (if applicable)",
      "notes": "Additional notes or tips"
    }
  ]
}

CRITICAL REQUIREMENTS:
- Output ONLY valid JSON, no markdown formatting, no ```json blocks, no extra text
- Each day MUST have exactly 6 exercises in the "main" array
- All "sets" and "reps" values must be integers (numbers, not strings)
- "rest" values should be strings with time units (e.g., "60s", "90s", "2min")
- Include all 7 days of the week (Monday through Sunday)
- If yoga/outdoor activities don't apply, use empty strings "" not null
- Ensure proper JSON syntax with correct quotes and commas

EXERCISE GUIDELINES:
- Warm-up should be 5-10 minutes of light cardio or dynamic stretching
- Cool-down should be 5-10 minutes of stretching or light walking
- Main exercises should vary by day and target different muscle groups
- Rest periods typically 45s-90s for strength training, 30s-60s for cardio
- Include compound movements and isolation exercises
- Consider the user's goals, equipment access, and preferences from the original plan

Here is the raw plan to reformat:
$rawPlan
''';

    try {
      final response = await callGeminiAPI(prompt);

      // Additional cleaning to ensure valid JSON
      String cleanedResponse = response
          .trim()
          .replaceAll(RegExp(r'```json|```'), '') // Remove code blocks
          .replaceAll(RegExp(r'^[^{]*'), '') // Remove text before first {
          .replaceAll(RegExp(r'}[^}]*$'), '}'); // Remove text after last }

      // Validate JSON structure before returning
      try {
        final testDecode = jsonDecode(cleanedResponse);
        if (testDecode is Map && testDecode.containsKey('days')) {
          final days = testDecode['days'] as List;
          if (days.isNotEmpty) {
            // Validate first day structure
            final firstDay = days[0] as Map;
            if (firstDay.containsKey('main') && firstDay['main'] is List) {
              final mainExercises = firstDay['main'] as List;
              // Ensure we have exercises and proper structure
              if (mainExercises.isNotEmpty) {
                return cleanedResponse;
              }
            }
          }
        }
        // If validation fails, return fallback
        return _generateFallbackExercisePlan();
      } catch (e) {
        // If JSON parsing fails, return fallback
        return _generateFallbackExercisePlan();
      }
    } catch (e) {
      // If API call fails, return fallback
      return _generateFallbackExercisePlan();
    }
  }

  static String _generateFallbackExercisePlan() {
    return '''
{
  "days": [
    {
      "day": "Monday",
      "warmup": "5 minutes brisk walking and arm circles",
      "main": [
        {"exercise": "Push-ups", "sets": 3, "reps": 12, "rest": "60s"},
        {"exercise": "Bodyweight Squats", "sets": 3, "reps": 15, "rest": "60s"},
        {"exercise": "Plank Hold", "sets": 3, "reps": 30, "rest": "45s"},
        {"exercise": "Lunges", "sets": 3, "reps": 12, "rest": "60s"},
        {"exercise": "Mountain Climbers", "sets": 3, "reps": 20, "rest": "45s"},
        {"exercise": "Glute Bridges", "sets": 3, "reps": 15, "rest": "45s"}
      ],
      "cooldown": "5 minutes full body stretching",
      "yoga": "",
      "outdoor": "",
      "notes": "Focus on proper form over speed"
    },
    {
      "day": "Tuesday",
      "warmup": "5 minutes light jogging in place",
      "main": [
        {"exercise": "Jumping Jacks", "sets": 3, "reps": 30, "rest": "45s"},
        {"exercise": "Burpees", "sets": 3, "reps": 8, "rest": "90s"},
        {"exercise": "High Knees", "sets": 3, "reps": 20, "rest": "30s"},
        {"exercise": "Sit-ups", "sets": 3, "reps": 15, "rest": "45s"},
        {"exercise": "Wall Push-ups", "sets": 3, "reps": 12, "rest": "45s"},
        {"exercise": "Calf Raises", "sets": 3, "reps": 20, "rest": "30s"}
      ],
      "cooldown": "5 minutes walking and stretching",
      "yoga": "",
      "outdoor": "",
      "notes": "Stay hydrated throughout the workout"
    },
    {
      "day": "Wednesday",
      "warmup": "5 minutes dynamic stretching",
      "main": [
        {"exercise": "Modified Push-ups", "sets": 3, "reps": 10, "rest": "60s"},
        {"exercise": "Step-ups", "sets": 3, "reps": 12, "rest": "60s"},
        {"exercise": "Side Plank", "sets": 2, "reps": 20, "rest": "45s"},
        {"exercise": "Chair Dips", "sets": 3, "reps": 10, "rest": "60s"},
        {"exercise": "Leg Raises", "sets": 3, "reps": 12, "rest": "45s"},
        {"exercise": "Standing Calf Raises", "sets": 3, "reps": 18, "rest": "30s"}
      ],
      "cooldown": "5 minutes gentle stretching",
      "yoga": "",
      "outdoor": "",
      "notes": "Rest day option - light activity"
    },
    {
      "day": "Thursday",
      "warmup": "5 minutes marching in place",
      "main": [
        {"exercise": "Squats", "sets": 4, "reps": 15, "rest": "60s"},
        {"exercise": "Push-ups", "sets": 3, "reps": 10, "rest": "60s"},
        {"exercise": "Dead Bug", "sets": 3, "reps": 12, "rest": "45s"},
        {"exercise": "Reverse Lunges", "sets": 3, "reps": 12, "rest": "60s"},
        {"exercise": "Bicycle Crunches", "sets": 3, "reps": 20, "rest": "45s"},
        {"exercise": "Wall Sits", "sets": 3, "reps": 30, "rest": "60s"}
      ],
      "cooldown": "5 minutes full body stretch",
      "yoga": "",
      "outdoor": "",
      "notes": "Focus on controlled movements"
    },
    {
      "day": "Friday",
      "warmup": "5 minutes arm swings and leg swings",
      "main": [
        {"exercise": "Burpees", "sets": 3, "reps": 6, "rest": "90s"},
        {"exercise": "Jump Squats", "sets": 3, "reps": 12, "rest": "60s"},
        {"exercise": "Pike Push-ups", "sets": 3, "reps": 8, "rest": "60s"},
        {"exercise": "Russian Twists", "sets": 3, "reps": 20, "rest": "45s"},
        {"exercise": "Single Leg Glute Bridges", "sets": 3, "reps": 10, "rest": "45s"},
        {"exercise": "Plank to Downward Dog", "sets": 3, "reps": 10, "rest": "45s"}
      ],
      "cooldown": "5 minutes relaxing stretches",
      "yoga": "",
      "outdoor": "",
      "notes": "End the week strong!"
    },
    {
      "day": "Saturday",
      "warmup": "5 minutes light movement",
      "main": [
        {"exercise": "Walking Lunges", "sets": 3, "reps": 14, "rest": "60s"},
        {"exercise": "Incline Push-ups", "sets": 3, "reps": 12, "rest": "60s"},
        {"exercise": "Bear Crawl", "sets": 3, "reps": 10, "rest": "60s"},
        {"exercise": "Supermans", "sets": 3, "reps": 12, "rest": "45s"},
        {"exercise": "Squat Pulses", "sets": 3, "reps": 15, "rest": "45s"},
        {"exercise": "Standing Side Crunches", "sets": 3, "reps": 15, "rest": "30s"}
      ],
      "cooldown": "5 minutes gentle stretching",
      "yoga": "",
      "outdoor": "",
      "notes": "Weekend warrior session"
    },
    {
      "day": "Sunday",
      "warmup": "5 minutes gentle movement",
      "main": [
        {"exercise": "Gentle Squats", "sets": 2, "reps": 12, "rest": "60s"},
        {"exercise": "Wall Push-ups", "sets": 2, "reps": 10, "rest": "60s"},
        {"exercise": "Standing Marches", "sets": 2, "reps": 20, "rest": "30s"},
        {"exercise": "Seated Leg Extensions", "sets": 2, "reps": 12, "rest": "45s"},
        {"exercise": "Arm Circles", "sets": 2, "reps": 15, "rest": "30s"},
        {"exercise": "Gentle Stretching Hold", "sets": 2, "reps": 30, "rest": "45s"}
      ],
      "cooldown": "10 minutes relaxation and stretching",
      "yoga": "",
      "outdoor": "",
      "notes": "Recovery day - keep it light and easy"
    }
  ]
}''';
  }
}
