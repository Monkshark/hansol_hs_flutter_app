import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:hansol_high_school/data/auth_service.dart';
import 'package:hansol_high_school/styles/app_colors.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// 글쓰기/수정 화면 (WritePostScreen)
///
/// - 카테고리(자유/질문/정보공유) 선택 후 글 작성
/// - 투표 항목 및 일정 첨부(날짜/시간) 기능
/// - 사진 촬영 또는 갤러리에서 이미지 첨부 (압축 후 업로드)
/// - 익명 게시 옵션 및 기존 글 수정 모드 지원
class WritePostScreen extends StatefulWidget {
  final String? postId;
  final String? initialTitle;
  final String? initialContent;
  final String? initialCategory;

  const WritePostScreen({
    this.postId,
    this.initialTitle,
    this.initialContent,
    this.initialCategory,
    Key? key,
  }) : super(key: key);

  @override
  State<WritePostScreen> createState() => _WritePostScreenState();
}

class _WritePostScreenState extends State<WritePostScreen> {
  static const _categories = ['자유', '질문', '정보공유'];
  late String _category;
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final TextEditingController _eventContentController;
  bool _saving = false;
  bool _isAnonymous = false;
  bool _isPinned = false;

  bool _attachEvent = false;
  DateTime? _eventDate;
  TimeOfDay? _eventStartTime;
  TimeOfDay? _eventEndTime;

  final List<File> _images = [];

  bool _attachPoll = false;
  final List<TextEditingController> _pollControllers = [
    TextEditingController(),
    TextEditingController(),
  ];

  bool get _isEdit => widget.postId != null;

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory ?? _categories[0];
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    _contentController = TextEditingController(text: widget.initialContent ?? '');
    _eventContentController = TextEditingController();
    if (_isEdit) _loadExistingData();
  }

  Future<void> _loadExistingData() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('posts').doc(widget.postId).get();
      if (!doc.exists || !mounted) return;
      final data = doc.data()!;

      setState(() {
        _isAnonymous = data['isAnonymous'] == true;
        _isPinned = data['isPinned'] == true;

        if (data['pollOptions'] != null && (data['pollOptions'] as List).isNotEmpty) {
          _attachPoll = true;
          final options = (data['pollOptions'] as List).cast<String>();
          _pollControllers.clear();
          for (var o in options) {
            _pollControllers.add(TextEditingController(text: o));
          }
        }

        if (data['eventDate'] != null) {
          _attachEvent = true;
          _eventDate = DateTime.parse(data['eventDate']);
          _eventContentController.text = data['eventContent'] ?? '';
          final st = data['eventStartTime'] as int?;
          final et = data['eventEndTime'] as int?;
          if (st != null && st >= 0) _eventStartTime = TimeOfDay(hour: st ~/ 60, minute: st % 60);
          if (et != null && et >= 0) _eventEndTime = TimeOfDay(hour: et ~/ 60, minute: et % 60);
        }
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _eventContentController.dispose();
    for (var c in _pollControllers) {
      c.dispose();
    }
    for (var f in _images) {
      f.delete().ignore();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final fillColor = isDark ? const Color(0xFF252830) : const Color(0xFFF5F5F5);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: textColor,
        title: Text(_isEdit ? '글 수정' : '글쓰기'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _saving ? null : _onSubmit,
            icon: Icon(
              Icons.check,
              color: _saving ? AppColors.theme.darkGreyColor : AppColors.theme.primaryColor,
              size: 28,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).padding.bottom + 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('카테고리', style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.theme.primaryColor)),
            const SizedBox(height: 8),
            Row(
              children: _categories.map((cat) {
                final selected = _category == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _category = cat;
                      if (cat != '정보공유') _attachEvent = false;
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.theme.primaryColor
                            : (isDark ? const Color(0xFF252830) : const Color(0xFFF0F0F0)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : AppColors.theme.darkGreyColor,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
              decoration: InputDecoration(
                hintText: '제목을 입력하세요',
                hintStyle: TextStyle(color: AppColors.theme.darkGreyColor),
                filled: true,
                fillColor: fillColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contentController,
              style: TextStyle(fontSize: 15, color: textColor, height: 1.6),
              maxLines: null,
              minLines: 8,
              decoration: InputDecoration(
                hintText: '내용을 입력하세요',
                hintStyle: TextStyle(color: AppColors.theme.darkGreyColor),
                filled: true,
                fillColor: fillColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            if (_images.isNotEmpty || !_isEdit) ...[
              const SizedBox(height: 16),
              _buildImageSection(fillColor),
            ],

            if (_category == '정보공유') ...[
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => setState(() => _attachEvent = !_attachEvent),
                child: Row(
                  children: [
                    Container(
                      width: 22, height: 22,
                      decoration: BoxDecoration(
                        color: _attachEvent ? AppColors.theme.tertiaryColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _attachEvent ? AppColors.theme.tertiaryColor : AppColors.theme.darkGreyColor,
                          width: 1.5,
                        ),
                      ),
                      child: _attachEvent ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                    ),
                    const SizedBox(width: 8),
                    Text('일정 첨부', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
                    const SizedBox(width: 4),
                    Icon(Icons.event, size: 16, color: AppColors.theme.tertiaryColor),
                  ],
                ),
              ),
              if (_attachEvent) ...[
                const SizedBox(height: 12),
                _buildEventForm(isDark, textColor, fillColor),
              ],
            ],

            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => setState(() => _attachPoll = !_attachPoll),
              child: Row(
                children: [
                  Container(
                    width: 22, height: 22,
                    decoration: BoxDecoration(
                      color: _attachPoll ? AppColors.theme.secondaryColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _attachPoll ? AppColors.theme.secondaryColor : AppColors.theme.darkGreyColor,
                        width: 1.5,
                      ),
                    ),
                    child: _attachPoll ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                  ),
                  const SizedBox(width: 8),
                  Text('투표 첨부', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
                  const SizedBox(width: 4),
                  Icon(Icons.poll, size: 16, color: AppColors.theme.secondaryColor),
                ],
              ),
            ),
            if (_attachPoll) ...[
              const SizedBox(height: 12),
              _buildPollForm(isDark, textColor, fillColor),
            ],

            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => setState(() => _isAnonymous = !_isAnonymous),
              child: Row(
                children: [
                  Container(
                    width: 22, height: 22,
                    decoration: BoxDecoration(
                      color: _isAnonymous ? AppColors.theme.primaryColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _isAnonymous ? AppColors.theme.primaryColor : AppColors.theme.darkGreyColor,
                        width: 1.5,
                      ),
                    ),
                    child: _isAnonymous ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                  ),
                  const SizedBox(width: 8),
                  Text('익명으로 작성', style: TextStyle(fontSize: 14, color: textColor)),
                ],
              ),
            ),

            if (AuthService.cachedProfile?.isManager == true) ...[
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => setState(() => _isPinned = !_isPinned),
                child: Row(
                  children: [
                    Container(
                      width: 22, height: 22,
                      decoration: BoxDecoration(
                        color: _isPinned ? Colors.red : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _isPinned ? Colors.red : AppColors.theme.darkGreyColor,
                          width: 1.5,
                        ),
                      ),
                      child: _isPinned ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                    ),
                    const SizedBox(width: 8),
                    Text('공지로 등록', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
                    const SizedBox(width: 4),
                    const Icon(Icons.push_pin, size: 16, color: Colors.red),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),
            Text(
              '작성한 글은 1년 후 자동 삭제됩니다',
              style: TextStyle(fontSize: 12, color: AppColors.theme.darkGreyColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventForm(bool isDark, Color? textColor, Color fillColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2028) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.theme.tertiaryColor.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _eventContentController,
            style: TextStyle(fontSize: 14, color: textColor),
            decoration: InputDecoration(
              hintText: '일정 내용 (예: 중간고사, 체육대회)',
              hintStyle: TextStyle(color: AppColors.theme.darkGreyColor, fontSize: 14),
              filled: true,
              fillColor: fillColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: fillColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: AppColors.theme.darkGreyColor),
                  const SizedBox(width: 8),
                  Text(
                    _eventDate != null
                        ? DateFormat('yyyy년 M월 d일 (E)', 'ko_KR').format(_eventDate!)
                        : '날짜를 선택하세요',
                    style: TextStyle(
                      fontSize: 14,
                      color: _eventDate != null ? textColor : AppColors.theme.darkGreyColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _pickTime(true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: fillColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.access_time, size: 16, color: AppColors.theme.darkGreyColor),
                        const SizedBox(width: 8),
                        Text(
                          _eventStartTime != null ? _eventStartTime!.format(context) : '시작 (선택)',
                          style: TextStyle(
                            fontSize: 14,
                            color: _eventStartTime != null ? textColor : AppColors.theme.darkGreyColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text('~', style: TextStyle(color: AppColors.theme.darkGreyColor)),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => _pickTime(false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: fillColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.access_time, size: 16, color: AppColors.theme.darkGreyColor),
                        const SizedBox(width: 8),
                        Text(
                          _eventEndTime != null ? _eventEndTime!.format(context) : '종료 (선택)',
                          style: TextStyle(
                            fontSize: 14,
                            color: _eventEndTime != null ? textColor : AppColors.theme.darkGreyColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection(Color fillColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_images.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(_images[index], width: 100, height: 100, fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 4, right: 4,
                      child: GestureDetector(
                        onTap: () => setState(() => _images.removeAt(index)),
                        child: Container(
                          width: 22, height: 22,
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        if (_images.length < 5) ...[
          if (_images.isNotEmpty) const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickImages,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: fillColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt_outlined, size: 18, color: AppColors.theme.darkGreyColor),
                  const SizedBox(width: 6),
                  Text('사진 추가 (${_images.length}/5)',
                    style: TextStyle(fontSize: 13, color: AppColors.theme.darkGreyColor)),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final remaining = 5 - _images.length;
    final picked = await picker.pickMultiImage(limit: remaining);
    if (picked.isEmpty) return;

    for (var xFile in picked) {
      if (_images.length >= 5) break;
      final compressed = await _compressImage(File(xFile.path));
      if (compressed != null) {
        setState(() => _images.add(compressed));
      }
    }
  }

  Future<File?> _compressImage(File file) async {
    final dir = await getTemporaryDirectory();
    final targetPath = p.join(dir.path, 'compressed_${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.path)}');

    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      minWidth: 640,
      minHeight: 640,
      quality: 80,
    );

    return result != null ? File(result.path) : null;
  }

  Future<List<String>> _uploadImages(String postId) async {
    final urls = <String>[];
    final storage = FirebaseStorage.instance;

    for (int i = 0; i < _images.length; i++) {
      final ref = storage.ref('posts/$postId/${DateTime.now().millisecondsSinceEpoch}_$i.jpg');
      await ref.putFile(_images[i]);
      final url = await ref.getDownloadURL();
      urls.add(url);
    }

    return urls;
  }

  Widget _buildPollForm(bool isDark, Color? textColor, Color fillColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2028) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.theme.secondaryColor.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...List.generate(_pollControllers.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.theme.secondaryColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(child: Text(
                      '${i + 1}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.theme.secondaryColor),
                    )),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _pollControllers[i],
                      style: TextStyle(fontSize: 14, color: textColor),
                      decoration: InputDecoration(
                        hintText: '선택지 ${i + 1}',
                        hintStyle: TextStyle(color: AppColors.theme.darkGreyColor, fontSize: 14),
                        filled: true,
                        fillColor: fillColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                  ),
                  if (i >= 2)
                    GestureDetector(
                      onTap: () => setState(() {
                        _pollControllers[i].dispose();
                        _pollControllers.removeAt(i);
                      }),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Icon(Icons.close, size: 18, color: AppColors.theme.darkGreyColor),
                      ),
                    ),
                ],
              ),
            );
          }),
          if (_pollControllers.length < 6)
            GestureDetector(
              onTap: () => setState(() => _pollControllers.add(TextEditingController())),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: fillColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, size: 16, color: AppColors.theme.secondaryColor),
                    const SizedBox(width: 4),
                    Text('선택지 추가', style: TextStyle(
                      fontSize: 13, color: AppColors.theme.secondaryColor, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _eventDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ko', 'KR'),
    );
    if (picked != null) setState(() => _eventDate = picked);
  }

  Future<void> _pickTime(bool isStart) async {
    final initial = isStart
        ? (_eventStartTime ?? TimeOfDay.now())
        : (_eventEndTime ?? TimeOfDay.now());

    if (Platform.isIOS) {
      showCupertinoModalPopup(
        context: context,
        builder: (ctx) => Container(
          height: 250,
          color: Theme.of(context).scaffoldBackgroundColor,
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.time,
            initialDateTime: DateTime(2024, 1, 1, initial.hour, initial.minute),
            use24hFormat: false,
            onDateTimeChanged: (dt) {
              setState(() {
                if (isStart) {
                  _eventStartTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
                } else {
                  _eventEndTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
                }
              });
            },
          ),
        ),
      );
    } else {
      final picked = await showTimePicker(context: context, initialTime: initial);
      if (picked != null) {
        setState(() {
          if (isStart) {
            _eventStartTime = picked;
          } else {
            _eventEndTime = picked;
          }
        });
      }
    }
  }

  Future<void> _onSubmit() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목을 입력하세요')),
      );
      return;
    }
    if (title.length > 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목은 200자 이내로 입력하세요')),
      );
      return;
    }
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('내용을 입력하세요')),
      );
      return;
    }
    if (content.length > 5000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('내용은 5000자 이내로 입력하세요')),
      );
      return;
    }

    if (_attachPoll) {
      final validOptions = _pollControllers.where((c) => c.text.trim().isNotEmpty).toList();
      if (validOptions.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('투표 선택지를 2개 이상 입력하세요')),
        );
        return;
      }
      for (var c in _pollControllers) {
        if (c.text.trim().length > 100) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('투표 선택지는 100자 이내로 입력하세요')),
          );
          return;
        }
      }
    }

    if (_attachEvent && _eventDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('일정 날짜를 선택하세요')),
      );
      return;
    }
    if (_attachEvent && _eventContentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('일정 내용을 입력하세요')),
      );
      return;
    }
    if (_attachEvent && _eventContentController.text.trim().length > 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('일정 내용은 200자 이내로 입력하세요')),
      );
      return;
    }

    setState(() => _saving = true);

    if (!AuthService.isLoggedIn) {
      if (mounted) setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다')),
      );
      return;
    }

    UserProfile? profile;
    for (int i = 0; i < 3; i++) {
      profile = await AuthService.getUserProfile();
      if (profile != null) break;
      await Future.delayed(const Duration(seconds: 1));
    }
    if (profile == null) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('프로필 정보를 불러올 수 없습니다. 다시 시도해주세요.')),
        );
      }
      return;
    }

    final displayName = _isAnonymous ? '익명' : profile.displayName;

    final postData = <String, dynamic>{
      'title': title,
      'content': content,
      'category': _category,
      'authorUid': AuthService.currentUser!.uid,
      'authorName': displayName,
      'authorRealName': profile.displayName,
      'isAnonymous': _isAnonymous,
      'isPinned': _isPinned,
    };

    if (_isPinned) {
      postData['pinnedAt'] = FieldValue.serverTimestamp();
    }

    if (_attachPoll) {
      final options = _pollControllers
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();
      postData['pollOptions'] = options;
      postData['pollVoters'] = <String, dynamic>{};
    } else {
      postData['pollOptions'] = null;
      postData['pollVoters'] = null;
    }

    if (_attachEvent && _eventDate != null) {
      postData['eventDate'] = _eventDate!.toIso8601String();
      postData['eventContent'] = _eventContentController.text.trim();
      postData['eventStartTime'] = _eventStartTime != null
          ? _eventStartTime!.hour * 60 + _eventStartTime!.minute
          : -1;
      postData['eventEndTime'] = _eventEndTime != null
          ? _eventEndTime!.hour * 60 + _eventEndTime!.minute
          : -1;
    } else {
      postData['eventDate'] = null;
      postData['eventContent'] = null;
      postData['eventStartTime'] = null;
      postData['eventEndTime'] = null;
    }

    if (_isEdit) {
      if (_images.isNotEmpty) {
        final urls = await _uploadImages(widget.postId!);
        postData['imageUrls'] = FieldValue.arrayUnion(urls);
      }
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .update(postData);
    } else {
      postData['createdAt'] = FieldValue.serverTimestamp();
      postData['expireAt'] = Timestamp.fromDate(DateTime.now().add(const Duration(days: 365)));
      postData['commentCount'] = 0;
      postData['imageUrls'] = <String>[];
      final docRef = await FirebaseFirestore.instance.collection('posts').add(postData);

      if (_images.isNotEmpty) {
        final urls = await _uploadImages(docRef.id);
        await docRef.update({'imageUrls': urls});
      }
    }

    if (mounted) Navigator.pop(context);
  }
}
