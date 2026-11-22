import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_message_model.dart';
import 'cache_service.dart';

class AiService {
  final _client = Supabase.instance.client;
  final _cacheService = CacheService();

  Future<String> chat({
    required String sessionId,
    required String message,
    String? documentId,
  }) async {
    final response = await _client.functions.invoke(
      'ai-chat',
      body: {
        'session_id': sessionId,
        'message': message,
        'document_id': documentId,
      },
    );

    if (response.status != 200) {
      throw Exception(response.data?['error'] ?? 'AI request failed');
    }
    return response.data['reply'] as String;
  }

  Future<String> generateSummary({
    required String documentId,
    required String summaryType,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'generate-summary',
        body: {
          'document_id': documentId,
          'summary_type': summaryType,
        },
      );

      if (response.status != 200) {
        throw Exception(response.data?['error'] ?? 'Summary generation failed');
      }
      final content = response.data['content'] as String;
      await _cacheService.saveSummary(documentId, summaryType, content);
      return content;
    } catch (e) {
      final cached = await _cacheService.getSummary(documentId, summaryType);
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<Map<String, dynamic>> generateQuiz({
    required String documentId,
    required String quizType,
    int questionCount = 10,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'generate-quiz',
        body: {
          'document_id': documentId,
          'quiz_type': quizType,
          'question_count': questionCount,
        },
      );

      if (response.status != 200) {
        throw Exception(response.data?['error'] ?? 'Quiz generation failed');
      }
      final quizData = response.data as Map<String, dynamic>;
      await _cacheService.saveQuiz(documentId, quizType, quizData);
      return quizData;
    } catch (e) {
      final cached = await _cacheService.getQuiz(documentId, quizType);
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> generateFlashcards({
    required String documentId,
    int count = 15,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'generate-flashcards',
        body: {
          'document_id': documentId,
          'count': count,
        },
      );

      if (response.status != 200) {
        throw Exception(response.data?['error'] ?? 'Flashcard generation failed');
      }
      final flashcardsList = List<Map<String, dynamic>>.from(response.data['flashcards']);
      await _cacheService.saveFlashcards(documentId, flashcardsList);
      return flashcardsList;
    } catch (e) {
      final cached = await _cacheService.getFlashcards(documentId);
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<Map<String, dynamic>> generateStudyPlan({
    required DateTime examDate,
    required double dailyHours,
    required List<String> subjects,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'generate-study-plan',
        body: {
          'exam_date': examDate.toIso8601String().split('T').first,
          'daily_hours': dailyHours,
          'subjects': subjects,
        },
      );

      if (response.status != 200) {
        throw Exception(response.data?['error'] ?? 'Study plan generation failed');
      }
      final planData = response.data as Map<String, dynamic>;
      await _cacheService.saveStudyPlan(planData);
      return planData;
    } catch (e) {
      final cached = await _cacheService.getStudyPlan();
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<String> createChatSession({String? documentId, String? title}) async {
    final userId = _client.auth.currentUser!.id;
    final response = await _client
        .from('chat_sessions')
        .insert({
          'user_id': userId,
          'document_id': documentId,
          'title': title ?? 'New Chat',
        })
        .select()
        .single();
    return response['id'] as String;
  }

  Future<List<ChatMessageModel>> getChatMessages(String sessionId) async {
    final response = await _client
        .from('chat_messages')
        .select()
        .eq('session_id', sessionId)
        .order('created_at');

    return (response as List)
        .map((json) => ChatMessageModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getChatSessions() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];
    final response = await _client
        .from('chat_sessions')
        .select('*, documents(title)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getSavedSummaries() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];
    final response = await _client
        .from('summaries')
        .select('*, documents(title)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }
}
