import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/document_model.dart';

class DocumentService {
  final _client = Supabase.instance.client;
  final _uuid = const Uuid();

  Future<List<DocumentModel>> getDocuments() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('documents')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => DocumentModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<DocumentModel?> getDocument(String id) async {
    final response = await _client
        .from('documents')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return DocumentModel.fromJson(response);
  }

  Future<DocumentModel> uploadDocument({
    required String title,
    required String subject,
    required Uint8List fileBytes,
    required String fileName,
    String? extractedText,
  }) async {
    final userId = _client.auth.currentUser!.id;
    final docId = _uuid.v4();
    final extension = fileName.split('.').last.toLowerCase();
    final filePath = '$userId/$docId.$extension';

    String contentType = 'application/octet-stream';
    if (extension == 'pdf') {
      contentType = 'application/pdf';
    } else if (extension == 'docx') {
      contentType = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    } else if (extension == 'pptx') {
      contentType = 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
    } else if (extension == 'txt') {
      contentType = 'text/plain';
    } else if (extension == 'csv') {
      contentType = 'text/csv';
    }

    await _client.storage.from('documents').uploadBinary(
          filePath,
          fileBytes,
          fileOptions: FileOptions(contentType: contentType),
        );

    final response = await _client.from('documents').insert({
      'id': docId,
      'user_id': userId,
      'title': title,
      'subject': subject,
      'file_path': filePath,
      'file_size': fileBytes.length,
      'extracted_text': extractedText,
      'status': extractedText != null ? 'ready' : 'processing',
    }).select().single();

    return DocumentModel.fromJson(response);
  }

  Future<void> deleteDocument(String id, String filePath) async {
    await _client.storage.from('documents').remove([filePath]);
    await _client.from('documents').delete().eq('id', id);
  }

  Future<List<String>> getSubjects() async {
    final docs = await getDocuments();
    return docs
        .map((d) => d.subject)
        .where((s) => s != null && s.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();
  }
}
