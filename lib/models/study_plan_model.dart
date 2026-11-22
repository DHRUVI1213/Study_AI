class StudyPlanDay {
  final String date;
  final List<String> topics;
  final String focus;

  const StudyPlanDay({
    required this.date,
    required this.topics,
    required this.focus,
  });

  factory StudyPlanDay.fromJson(Map<String, dynamic> json) {
    return StudyPlanDay(
      date: json['date'] as String,
      topics: (json['topics'] as List<dynamic>).cast<String>(),
      focus: json['focus'] as String? ?? '',
    );
  }
}

class StudyPlanModel {
  final String id;
  final DateTime examDate;
  final double dailyHours;
  final List<String> subjects;
  final List<StudyPlanDay> schedule;

  const StudyPlanModel({
    required this.id,
    required this.examDate,
    required this.dailyHours,
    required this.subjects,
    required this.schedule,
  });

  factory StudyPlanModel.fromJson(Map<String, dynamic> json) {
    final planContent = json['plan_content'] as Map<String, dynamic>? ?? {};
    final scheduleJson = planContent['schedule'] as List<dynamic>? ?? [];
    return StudyPlanModel(
      id: json['id'] as String,
      examDate: DateTime.parse(json['exam_date'] as String),
      dailyHours: (json['daily_hours'] as num).toDouble(),
      subjects: (json['subjects'] as List<dynamic>).cast<String>(),
      schedule: scheduleJson
          .map((d) => StudyPlanDay.fromJson(d as Map<String, dynamic>))
          .toList(),
    );
  }
}
