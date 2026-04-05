import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:hansol_high_school/data/auth_service.dart';
import 'package:hansol_high_school/styles/app_colors.dart';
import 'package:image_picker/image_picker.dart';

/// 건의사항 작성 화면 (앱 건의/버그 + 학생회 건의)
///
/// - 텍스트(1000자) + 사진 첨부(최대 3장, 640px 압축)
/// - type에 따라 app_feedbacks / council_feedbacks 컬렉션에 저장
class FeedbackScreen extends StatefulWidget {
  final String type; // 'app' or 'council'

  const FeedbackScreen({Key? key, required this.type}) : super(key: key);

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _contentController = TextEditingController();
  final List<File> _images = [];
  bool _isSending = false;

  bool get _isApp => widget.type == 'app';
  String get _title => _isApp ? '앱 건의사항 & 버그 제보' : '학생회 건의사항';
  String get _collection => _isApp ? 'app_feedbacks' : 'council_feedbacks';
  String get _hint => _isApp
      ? '버그가 발생한 상황이나 개선 사항을 자세히 적어주세요'
      : '학생회에 전달할 건의사항을 적어주세요';

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_images.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사진은 최대 3장까지 첨부할 수 있습니다')));
      return;
    }

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1024);
    if (picked == null) return;

    final compressed = await FlutterImageCompress.compressAndGetFile(
      picked.path,
      '${picked.path}_compressed.jpg',
      quality: 70,
      minWidth: 640,
      minHeight: 640,
    );

    if (compressed != null && mounted) {
      setState(() => _images.add(File(compressed.path)));
    }
  }

  Future<List<String>> _uploadImages() async {
    final urls = <String>[];
    final uid = AuthService.currentUser?.uid ?? 'unknown';
    final ts = DateTime.now().millisecondsSinceEpoch;

    for (int i = 0; i < _images.length; i++) {
      final ref = FirebaseStorage.instance
          .ref()
          .child('feedbacks/${widget.type}/${uid}_${ts}_$i.jpg');
      await ref.putFile(_images[i]);
      urls.add(await ref.getDownloadURL());
    }
    return urls;
  }

  Future<void> _submit() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('내용을 입력해주세요')));
      return;
    }

    setState(() => _isSending = true);

    try {
      final imageUrls = _images.isNotEmpty ? await _uploadImages() : <String>[];
      final profile = await AuthService.getCachedProfile();

      await FirebaseFirestore.instance.collection(_collection).add({
        'content': content,
        'imageUrls': imageUrls,
        'authorUid': AuthService.currentUser?.uid ?? '',
        'authorName': profile?.displayName ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending', // pending / reviewed / resolved
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isApp ? '제보가 접수되었습니다' : '건의사항이 전달되었습니다')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('전송에 실패했습니다')));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final fillColor = isDark ? const Color(0xFF1E2028) : const Color(0xFFF5F5F5);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: textColor,
        title: Text(_title),
        centerTitle: true,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isSending ? null : _submit,
            child: _isSending
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text('보내기', style: TextStyle(
                    color: AppColors.theme.primaryColor, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _contentController,
              maxLines: 8,
              maxLength: 1000,
              style: TextStyle(fontSize: 15, color: textColor),
              decoration: InputDecoration(
                hintText: _hint,
                hintStyle: TextStyle(color: AppColors.theme.darkGreyColor),
                filled: true,
                fillColor: fillColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 16),

            Text('사진 첨부 (최대 3장)', style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.theme.darkGreyColor)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._images.asMap().entries.map((entry) => Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(entry.value,
                        width: 80, height: 80, fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: -4, right: -4,
                      child: GestureDetector(
                        onTap: () => setState(() => _images.removeAt(entry.key)),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                )),
                if (_images.length < 3)
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        color: fillColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.theme.darkGreyColor.withAlpha(60)),
                      ),
                      child: Icon(Icons.add_photo_alternate_outlined,
                        color: AppColors.theme.darkGreyColor, size: 28),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
