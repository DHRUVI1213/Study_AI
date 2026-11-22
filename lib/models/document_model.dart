class DocumentModel {
  final String id;
  final String userId;
  final String title;
  final String? subject;
  final String filePath;
  final int? pageCount;
  final String? extractedText;
  final String status;
  final DateTime createdAt;

  const DocumentModel({
    required this.id,
    required this.userId,
    required this.title,
    this.subject,
    required this.filePath,
    this.pageCount,
    this.extractedText,
    this.status = 'processing',
    required this.createdAt,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      subject: json['subject'] as String?,
      filePath: json['file_path'] as String,
      pageCount: json['page_count'] as int?,
      extractedText: json['extracted_text'] as String?,
      status: json['status'] as String? ?? 'processing',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'subject': subject,
        'file_path': filePath,
        'page_count': pageCount,
        'extracted_text': extractedText,
        'status': status,
      };

  bool get isReady => status == 'ready';
}
