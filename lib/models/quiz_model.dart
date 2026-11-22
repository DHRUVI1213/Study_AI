class QuizQuestion {
  final String question;
  final List<String>? options;
  final String correctAnswer;
  final String? explanation;

  const QuizQuestion({
    required this.question,
    this.options,
    required this.correctAnswer,
    this.explanation,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      question: json['question'] as String,
      options: (json['options'] as List<dynamic>?)?.cast<String>(),
      correctAnswer: json['correct_answer'] as String,
      explanation: json['explanation'] as String?,
    );
  }
}

class QuizModel {
  final String id;
  final String title;
  final String quizType;
  final List<QuizQuestion> questions;
  final String? documentId;

  const QuizModel({
    required this.id,
    required this.title,
    required this.quizType,
    required this.questions,
    this.documentId,
  });

  factory QuizModel.fromJson(Map<String, dynamic> json) {
    final questionsJson = json['questions'] as List<dynamic>? ?? [];
    return QuizModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Practice Quiz',
      quizType: json['quiz_type'] as String? ?? 'mcq',
      documentId: json['document_id'] as String?,
      questions: questionsJson
          .map((q) => QuizQuestion.fromJson(q as Map<String, dynamic>))
          .toList(),
    );
  }
}
