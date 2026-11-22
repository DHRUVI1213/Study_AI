class FlashcardModel {
  final String id;
  final String front;
  final String back;
  final String? documentId;

  const FlashcardModel({
    required this.id,
    required this.front,
    required this.back,
    this.documentId,
  });

  factory FlashcardModel.fromJson(Map<String, dynamic> json) {
    return FlashcardModel(
      id: json['id'] as String,
      front: json['front'] as String,
      back: json['back'] as String,
      documentId: json['document_id'] as String?,
    );
  }
}
