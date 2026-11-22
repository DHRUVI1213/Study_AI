import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:archive/archive.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../../core/theme/app_colors.dart';
import '../../services/document_service.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/primary_button.dart';

class UploadDocumentScreen extends StatefulWidget {
  const UploadDocumentScreen({super.key});

  @override
  State<UploadDocumentScreen> createState() => _UploadDocumentScreenState();
}

class _UploadDocumentScreenState extends State<UploadDocumentScreen> {
  final _titleController = TextEditingController();
  final _subjectController = TextEditingController();
  final _documentService = DocumentService();

  PlatformFile? _selectedFile;
  bool _isUploading = false;
  double _uploadProgress = 0;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'pptx', 'txt', 'csv'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedFile = result.files.first;
        if (_titleController.text.isEmpty) {
          final dotIndex = _selectedFile!.name.lastIndexOf('.');
          _titleController.text = dotIndex != -1
              ? _selectedFile!.name.substring(0, dotIndex)
              : _selectedFile!.name;
        }
      });
    }
  }

  Future<String> _extractText(PlatformFile file) async {
    final bytes = file.bytes;
    if (bytes == null) return '';

    final extension = file.extension?.toLowerCase() ?? '';

    try {
      if (extension == 'pdf') {
        final PdfDocument document = PdfDocument(inputBytes: bytes);
        final PdfTextExtractor extractor = PdfTextExtractor(document);
        final String text = extractor.extractText();
        document.dispose();
        return text;
      } else if (extension == 'docx') {
        final archive = ZipDecoder().decodeBytes(bytes);
        final docFile = archive.findFile('word/document.xml');
        if (docFile == null) return '';

        final content = String.fromCharCodes(docFile.content as List<int>);
        final regex = RegExp(r'<w:t[^>]*>(.*?)</w:t>');
        final buffer = StringBuffer();
        final matches = regex.allMatches(content);
        for (final match in matches) {
          final text = match.group(1);
          if (text != null && text.isNotEmpty) {
            buffer.write('${_decodeXmlEntities(text)} ');
          }
        }
        return buffer.toString().trim();
      } else if (extension == 'pptx') {
        final archive = ZipDecoder().decodeBytes(bytes);
        final buffer = StringBuffer();

        final slideFiles = archive.files
            .where(
              (f) =>
                  f.name.startsWith('ppt/slides/slide') &&
                  f.name.endsWith('.xml'),
            )
            .toList();

        slideFiles.sort((a, b) {
          final numA =
              int.tryParse(
                RegExp(r'\d+').firstMatch(a.name)?.group(0) ?? '0',
              ) ??
              0;
          final numB =
              int.tryParse(
                RegExp(r'\d+').firstMatch(b.name)?.group(0) ?? '0',
              ) ??
              0;
          return numA.compareTo(numB);
        });

        final regex = RegExp(r'<a:t[^>]*>(.*?)</a:t>');
        for (final f in slideFiles) {
          final content = String.fromCharCodes(f.content as List<int>);
          final matches = regex.allMatches(content);
          for (final match in matches) {
            final text = match.group(1);
            if (text != null && text.isNotEmpty) {
              buffer.write('${_decodeXmlEntities(text)} ');
            }
          }
          buffer.write('\n');
        }
        return buffer.toString().trim();
      } else if (extension == 'txt' || extension == 'csv') {
        return String.fromCharCodes(bytes);
      }
    } catch (e) {
      debugPrint('Error extracting text from $extension: $e');
    }

    return '';
  }

  String _decodeXmlEntities(String text) {
    return text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'");
  }

  IconData _getFileIcon(String? extension) {
    switch (extension?.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'docx':
        return Icons.description_rounded;
      case 'pptx':
        return Icons.slideshow_rounded;
      case 'txt':
        return Icons.article_rounded;
      case 'csv':
        return Icons.table_chart_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  Future<void> _upload() async {
    if (_selectedFile == null || _titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a file and enter a title')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.2;
    });

    try {
      final bytes = _selectedFile!.bytes;
      if (bytes == null) throw Exception('Could not read file');

      setState(() => _uploadProgress = 0.5);

      final extractedText = await _extractText(_selectedFile!);

      setState(() => _uploadProgress = 0.8);

      await _documentService.uploadDocument(
        title: _titleController.text.trim(),
        subject: _subjectController.text.trim(),
        fileBytes: bytes,
        fileName: _selectedFile!.name,
        extractedText: extractedText.isNotEmpty ? extractedText : null,
      );

      setState(() => _uploadProgress = 1.0);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document uploaded successfully!')),
        );
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        final message = e.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              message.contains('Bucket not found')
                  ? 'Upload failed: Create a "documents" bucket in Supabase Storage first.'
                  : 'Upload failed: $message',
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Document'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: GradientBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _isUploading ? null : _pickFile,
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _selectedFile != null
                          ? AppColors.primary
                          : AppColors.cardBorder,
                      width: _selectedFile != null ? 2 : 1,
                    ),
                  ),
                  child: _selectedFile != null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                _getFileIcon(_selectedFile!.extension),
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _selectedFile!.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${(_selectedFile!.size / 1024).toStringAsFixed(1)} KB',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.cloud_upload_rounded,
                              size: 48,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Tap to select document',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'PDF, DOCX, PPTX, TXT, CSV',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              if (_isUploading) ...[
                const SizedBox(height: 20),
                LinearProgressIndicator(
                  value: _uploadProgress,
                  backgroundColor: AppColors.surfaceLight,
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
              const SizedBox(height: 28),
              CustomTextField(
                controller: _titleController,
                label: 'Document Title',
                hint: 'e.g. Operating Systems - Chapter 3',
                prefixIcon: Icons.title_rounded,
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _subjectController,
                label: 'Subject',
                hint: 'e.g. OS, DBMS, Computer Networks',
                prefixIcon: Icons.category_rounded,
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                label: 'Upload & Process',
                icon: Icons.upload_rounded,
                isLoading: _isUploading,
                onPressed: _upload,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
