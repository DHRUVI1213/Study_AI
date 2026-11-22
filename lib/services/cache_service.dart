import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  Future<void> saveSummary(String documentId, String type, String content) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('summary_${documentId}_$type', content);
  }

  Future<String?> getSummary(String documentId, String type) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('summary_${documentId}_$type');
  }

  Future<void> saveQuiz(String documentId, String type, Map<String, dynamic> quizData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('quiz_${documentId}_$type', jsonEncode(quizData));
  }

  Future<Map<String, dynamic>?> getQuiz(String documentId, String type) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('quiz_${documentId}_$type');
    if (jsonStr == null) return null;
    try {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveFlashcards(String documentId, List<Map<String, dynamic>> flashcards) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('flashcards_$documentId', jsonEncode(flashcards));
  }

  Future<List<Map<String, dynamic>>?> getFlashcards(String documentId) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('flashcards_$documentId');
    if (jsonStr == null) return null;
    try {
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> saveStudyPlan(Map<String, dynamic> planData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('study_plan_latest', jsonEncode(planData));
  }

  Future<Map<String, dynamic>?> getStudyPlan() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('study_plan_latest');
    if (jsonStr == null) return null;
    try {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
