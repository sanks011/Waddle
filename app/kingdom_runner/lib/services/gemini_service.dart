import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/diet_entry.dart';

class GeminiService {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const String _apiKeyStorageKey = 'gemini_api_key';
  static String? _cachedApiKey;

  static const String apiUrl =
      'https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent';

  // Storage keys
  static const String _dietHistoryKey = 'diet_history';

  // Initialize with API key (call this once on app start)
  static Future<void> initialize() async {
    try {
      // Try to load from secure storage
      _cachedApiKey = await _secureStorage.read(key: _apiKeyStorageKey);

      // If not found, load from .env file (first run)
      if (_cachedApiKey == null || _cachedApiKey!.isEmpty) {
        final envApiKey = dotenv.env['GEMINI_API_KEY'];
        if (envApiKey != null && envApiKey.isNotEmpty) {
          await setApiKey(envApiKey);
        } else {
          print('Warning: GEMINI_API_KEY not found in .env file');
        }
      }
    } catch (e) {
      print('Error initializing Gemini API key: $e');
    }
  }

  // Update API key
  static Future<void> setApiKey(String apiKey) async {
    await _secureStorage.write(key: _apiKeyStorageKey, value: apiKey);
    _cachedApiKey = apiKey;
  }

  // Get API key
  static Future<String> _getApiKey() async {
    if (_cachedApiKey != null) return _cachedApiKey!;

    _cachedApiKey = await _secureStorage.read(key: _apiKeyStorageKey);
    return _cachedApiKey ?? '';
  }

  // List available models (for debugging)
  static Future<void> listAvailableModels() async {
    final apiKey = await _getApiKey();
    if (apiKey.isEmpty) {
      print('No API key found');
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
          'https://generativelanguage.googleapis.com/v1/models?key=$apiKey',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Available Gemini models:');
        for (var model in data['models']) {
          print('  - ${model['name']} (${model['displayName']})');
          if (model['supportedGenerationMethods'] != null) {
            print(
              '    Methods: ${model['supportedGenerationMethods'].join(', ')}',
            );
          }
        }
      } else {
        print('Error listing models: ${response.statusCode}');
        print('Response: ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  // Save today's diet entry
  static Future<void> saveDietEntry(double protein, double calories) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final dateKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final entry = DietEntry(date: now, protein: protein, calories: calories);

    // Get existing history
    final historyJson = prefs.getString(_dietHistoryKey) ?? '{}';
    final Map<String, dynamic> history = jsonDecode(historyJson);

    // Add new entry
    history[dateKey] = entry.toJson();

    // Save back
    await prefs.setString(_dietHistoryKey, jsonEncode(history));
  }

  // Get last N days diet entries
  static Future<List<DietEntry>> getDietHistory(int days) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_dietHistoryKey) ?? '{}';
    final Map<String, dynamic> history = jsonDecode(historyJson);

    final List<DietEntry> entries = [];
    final now = DateTime.now();

    for (int i = 1; i <= days; i++) {
      final date = now.subtract(Duration(days: i));
      final dateKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      if (history.containsKey(dateKey)) {
        entries.add(DietEntry.fromJson(history[dateKey]));
      }
    }

    return entries.reversed.toList();
  }

  // Analyze food items and calculate nutritional values
  static Future<Map<String, double>?> analyzeFoodItems(
    List<String> foodDays,
  ) async {
    if (foodDays.isEmpty) {
      return null;
    }

    // Get API key from secure storage
    final apiKey = await _getApiKey();
    if (apiKey.isEmpty) {
      return null;
    }

    // Prepare food data
    final foodData = foodDays
        .asMap()
        .entries
        .map((e) => 'Day ${e.key + 1}: ${e.value}')
        .join('\n\n');

    final prompt =
        '''
Analyze these food items consumed over ${foodDays.length} days and calculate the TOTAL nutritional values.

$foodData

Respond ONLY with a JSON object in this exact format (no markdown, no extra text):
{
  "protein": <total grams>,
  "carbs": <total grams>,
  "calories": <total calories>
}

Be accurate with your estimates. Only return the JSON object, nothing else.
''';

    try {
      final response = await http.post(
        Uri.parse('$apiUrl?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt},
              ],
            },
          ],
          'generationConfig': {'temperature': 0.3, 'maxOutputTokens': 2000},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Gemini API Response: ${response.body}');

        final text = data['candidates'][0]['content']['parts'][0]['text'];
        print('Extracted text: $text');

        // Extract JSON from response
        String jsonText = text.trim();
        // Remove markdown code blocks if present
        jsonText = jsonText
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        print('Cleaned JSON text: $jsonText');

        final nutritionData = jsonDecode(jsonText);

        return {
          'protein': (nutritionData['protein'] as num).toDouble(),
          'carbs': (nutritionData['carbs'] as num).toDouble(),
          'calories': (nutritionData['calories'] as num).toDouble(),
        };
      } else {
        print('Gemini API Error: Status ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      print('Error analyzing food items: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  // Analyze diet using Gemini API
  static Future<String> analyzeDietHistory(List<DietEntry> entries) async {
    if (entries.isEmpty) {
      return 'No diet history available. Start tracking your daily nutrition to get insights!';
    }

    // Get API key from secure storage
    final apiKey = await _getApiKey();
    if (apiKey.isEmpty) {
      return 'Gemini API key not configured. Please check your settings.';
    }

    // Prepare prompt
    final dietData = entries
        .map((e) {
          return '${e.date.month}/${e.date.day}: Protein ${e.protein.toStringAsFixed(0)}g, Calories ${e.calories.toStringAsFixed(0)}kcal';
        })
        .join('\n');

    final prompt =
        '''
Analyze this ${entries.length}-day diet history and provide a brief, friendly summary (max 100 words):

$dietData

Focus on:
1. Average daily protein and calorie intake
2. Consistency patterns
3. One quick health recommendation

Keep the tone encouraging and conversational. Use emojis sparingly.
''';

    try {
      final response = await http.post(
        Uri.parse('$apiUrl?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt},
              ],
            },
          ],
          'generationConfig': {'temperature': 0.7, 'maxOutputTokens': 200},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates'][0]['content']['parts'][0]['text'];
        return text.trim();
      } else {
        return 'Unable to analyze diet at the moment. Please try again later.';
      }
    } catch (e) {
      return 'Error analyzing diet: ${e.toString()}';
    }
  }
}
