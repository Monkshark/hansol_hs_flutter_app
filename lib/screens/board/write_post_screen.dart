import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:hansol_high_school/data/analytics_service.dart';
import 'package:hansol_high_school/l10n/app_localizations.dart';
import 'package:hansol_high_school/data/auth_service.dart';
import 'package:hansol_high_school/data/search_tokens.dart';
import 'package:hansol_high_school/screens/board/write_widgets/write_event_form_section.dart';
import 'package:hansol_high_school/screens/board/write_widgets/write_image_section.dart';
import 'package:hansol_high_school/screens/board/write_widgets/write_poll_form_section.dart';
import 'package:hansol_high_school/styles/app_colors.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

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
  // DB category keys (never localized – used for Firestore queries)
  static const _categoryKeys = ['자유', '질문', '정보공유', '분실물', '학생회', '동아리'];
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

  String _localizedCategory(BuildContext context, String key) {
    final l = AppLocalizations.of(context)!;
    switch (key) {
      case '자유': return l.board_categoryFree;
      case '질문': return l.board_categoryQuestion;
      case '정보공유': return l.board_categoryInfoShare;
      case '분실물': return l.board_categoryLostFound;
      case '학생회': return l.board_categoryStudentCouncil;
      case '동아리': return l.board_categoryClub;
      default: return key;
    }
  }

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory ?? _categoryKeys[0];
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    _contentController = TextEditingController(text: widget.initialContent ?? '');
    _eventContentController = TextEditingController();
    if (_isEdit) {
      _loadExistingData();
    } else {
      _loadDraft();
    }
  }

  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final title = prefs.getString('draft_title');
    final content = prefs.getString('draft_content');
    final category = prefs.getString('draft_category');
    if (title == null && content == null) return;
    if (!mounted) return;
    setState(() {
      if (title != null && _titleController.text.isEmpty) _titleController.text = title;
      if (content != null && _contentController.text.isEmpty) _contentController.text = content;
      if (category != null) _category = category;
    });
  }

  Future<void> _saveDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty && content.isEmpty) {
      await _clearDraft();
      return;
    }
    await prefs.setString('draft_title', title);
    await prefs.setString('draft_content', content);
    await prefs.setString('draft_category', _category);
  }

  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('draft_title');
    await prefs.remove('draft_content');
    await prefs.remove('draft_category');
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final title = _titleController.text.trim();
        final content = _contentController.text.trim();
        if (!_isEdit && (title.isNotEmpty || content.isNotEmpty)) {
          final action = await showModalBottomSheet<String>(
            context: context,
            backgroundColor: Colors.transparent,
            builder: (ctx) => Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2028) : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
                const SizedBox(height: 8),
                Container(width: 36, height: 4, decoration: BoxDecoration(
                  color: isDark ? Colors.grey[600] : Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 16),
                Text(AppLocalizations.of(context)!.write_unsavedChanges, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: textColor)),
                const SizedBox(height: 20),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children: [
                  Expanded(child: TextButton(
                    onPressed: () => Navigator.pop(ctx, 'discard'),
                    child: Text(AppLocalizations.of(context)!.write_draftDelete, style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, 'save'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.theme.primaryColor, foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                    child: Text(AppLocalizations.of(context)!.write_draftSave),
                  )),
                ])),
                const SizedBox(height: 12),
              ])),
            ),
          );
          if (action == 'save') await _saveDraft();
          if (action == 'discard') await _clearDraft();
          if (action == null) return;
        }
        if (mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: textColor,
        title: Text(_isEdit ? AppLocalizations.of(context)!.write_editTitle : AppLocalizations.of(context)!.write_title),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (!_isEdit)
            IconButton(
              onPressed: _saving ? null : () async {
                await _saveDraft();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context)!.write_draftSaved)));
                }
              },
              icon: Icon(Icons.save_outlined, color: AppColors.theme.darkGreyColor, size: 24),
              tooltip: AppLocalizations.of(context)!.write_draftSave,
            ),
          IconButton(
            onPressed: _saving ? null : _onSubmit,
            icon: _saving
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : Icon(
                    Icons.check,
                    color: AppColors.theme.primaryColor,
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
            Text(AppLocalizations.of(context)!.write_category, style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.theme.primaryColor)),
            const SizedBox(height: 8),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categoryKeys.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = _categoryKeys[index];
                  final selected = _category == cat;
                  return GestureDetector(
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
                        _localizedCategory(context, cat),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : AppColors.theme.darkGreyColor,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.write_titlePlaceholder,
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
                hintText: AppLocalizations.of(context)!.write_contentPlaceholder,
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
              WriteImageSection(
                images: _images,
                fillColor: fillColor,
                onPick: _pickImages,
                onRemove: (index) => setState(() => _images.removeAt(index)),
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex--;
                    final item = _images.removeAt(oldIndex);
                    _images.insert(newIndex, item);
                  });
                },
              ),
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
                    Text(AppLocalizations.of(context)!.write_eventAttach, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
                    const SizedBox(width: 4),
                    Icon(Icons.event, size: 16, color: AppColors.theme.tertiaryColor),
                  ],
                ),
              ),
              if (_attachEvent) ...[
                const SizedBox(height: 12),
                WriteEventFormSection(
                  eventContentController: _eventContentController,
                  eventDate: _eventDate,
                  eventStartTime: _eventStartTime,
                  eventEndTime: _eventEndTime,
                  onPickDate: _pickDate,
                  onPickTime: _pickTime,
                  isDark: isDark,
                  textColor: textColor,
                  fillColor: fillColor,
                ),
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
                  Text(AppLocalizations.of(context)!.write_pollAttach, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
                  const SizedBox(width: 4),
                  Icon(Icons.poll, size: 16, color: AppColors.theme.secondaryColor),
                ],
              ),
            ),
            if (_attachPoll) ...[
              const SizedBox(height: 12),
              WritePollFormSection(
                pollControllers: _pollControllers,
                isDark: isDark,
                textColor: textColor,
                fillColor: fillColor,
                onAddOption: () => setState(() => _pollControllers.add(TextEditingController())),
                onRemoveOption: (i) => setState(() {
                  _pollControllers[i].dispose();
                  _pollControllers.removeAt(i);
                }),
              ),
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
                  Text(AppLocalizations.of(context)!.write_anonymous, style: TextStyle(fontSize: 14, color: textColor)),
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
                    Text(AppLocalizations.of(context)!.write_pinAsNotice, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
                    const SizedBox(width: 4),
                    const Icon(Icons.push_pin, size: 16, color: Colors.red),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context)!.write_expiresInfo,
              style: TextStyle(fontSize: 12, color: AppColors.theme.darkGreyColor),
            ),
          ],
        ),
      ),
    ),
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
    // 항상 .jpg 확장자로 강제 (HEIC 등 호환성 문제 회피)
    final targetPath = p.join(
      dir.path,
      'compressed_${DateTime.now().millisecondsSinceEpoch}_${p.basenameWithoutExtension(file.path)}.jpg',
    );

    // minWidth만 지정하여 종횡비 유지 (minHeight 지정 시 portrait 사진이 왜곡됨)
    // keepExif: false → GPS/카메라 정보 제거 (개인정보 보호)
    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      minWidth: 1080,
      quality: 80,
      format: CompressFormat.jpeg,
      keepExif: false,
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

    final l = AppLocalizations.of(context)!;

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.write_errorTitleRequired)),
      );
      return;
    }
    if (title.length > 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.write_errorTitleTooLong)),
      );
      return;
    }
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.write_errorContentRequired)),
      );
      return;
    }
    if (content.length > 5000) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.write_errorContentTooLong)),
      );
      return;
    }

    if (_attachPoll) {
      final validOptions = _pollControllers.where((c) => c.text.trim().isNotEmpty).toList();
      if (validOptions.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.write_errorPollOptionsRequired)),
        );
        return;
      }
      for (var c in _pollControllers) {
        if (c.text.trim().length > 100) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l.write_errorPollOptionTooLong)),
          );
          return;
        }
      }
    }

    if (_attachEvent && _eventDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.write_errorEventDateRequired)),
      );
      return;
    }
    if (_attachEvent && _eventContentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.write_errorEventContentRequired)),
      );
      return;
    }
    if (_attachEvent && _eventContentController.text.trim().length > 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.write_errorEventContentTooLong)),
      );
      return;
    }

    // Rate limiting: 30 seconds between posts
    if (!_isEdit) {
      final prefs = await SharedPreferences.getInstance();
      final lastPostTime = prefs.getInt('last_post_time') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - lastPostTime < 30000) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l.write_errorRateLimit)),
          );
        }
        return;
      }
    }

    setState(() => _saving = true);

    if (!AuthService.isLoggedIn) {
      if (mounted) setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.write_errorLoginRequired)),
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
          SnackBar(content: Text(l.write_errorProfileLoadFailed)),
        );
      }
      return;
    }

    final displayName = _isAnonymous ? AppLocalizations.of(context)!.post_anonymous : profile.displayName;

    if (_isPinned) {
      final pinnedSnap = await FirebaseFirestore.instance
          .collection('posts')
          .where('isPinned', isEqualTo: true)
          .get();
      if (pinnedSnap.docs.length >= 3 && mounted) {
        final result = await _showPinnedLimitSheet(pinnedSnap.docs);
        if (result == null) {
          setState(() => _saving = false);
          return;
        }
        if (result == 'cancel') {
          _isPinned = false;
        }
      }
    }

    final postData = <String, dynamic>{
      'title': title,
      'content': content,
      'category': _category,
      'authorUid': AuthService.currentUser!.uid,
      'authorName': displayName,
      'authorRealName': profile.displayName,
      'isAnonymous': _isAnonymous,
      'isPinned': _isPinned,
      // 검색 인덱스: 제목+본문 2-gram (Firestore array-contains-any 매칭용)
      'searchTokens': SearchTokens.forDocument(title, content),
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
      postData['likeCount'] = 0;
      postData['dislikeCount'] = 0;
      postData['likes'] = <String, dynamic>{};
      postData['dislikes'] = <String, dynamic>{};
      postData['imageUrls'] = <String>[];
      postData['anonymousCount'] = 0;
      postData['anonymousMapping'] = <String, dynamic>{};
      final docRef = await FirebaseFirestore.instance.collection('posts').add(postData);

      if (_images.isNotEmpty) {
        final urls = await _uploadImages(docRef.id);
        await docRef.update({'imageUrls': urls});
      }
      unawaited(AnalyticsService.logPostCreate(boardType: _category, isAnonymous: _isAnonymous));
    }

    if (!_isEdit) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_post_time', DateTime.now().millisecondsSinceEpoch);
      await _clearDraft();
    }

    if (mounted) Navigator.pop(context, true);
  }

  Future<String?> _showPinnedLimitSheet(List<QueryDocumentSnapshot<Map<String, dynamic>>> pinnedDocs) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2028) : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(width: 36, height: 4, decoration: BoxDecoration(
                color: isDark ? Colors.grey[600] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              )),
              const SizedBox(height: 16),
              Text(AppLocalizations.of(context)!.write_pinLimitExceeded, style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w700, color: textColor)),
              const SizedBox(height: 8),
              Text(AppLocalizations.of(context)!.write_pinLimitMessage,
                style: TextStyle(fontSize: 13, color: AppColors.theme.darkGreyColor),
                textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ...pinnedDocs.map((doc) {
                final data = doc.data();
                final title = data['title'] ?? AppLocalizations.of(context)!.write_noTitle;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: GestureDetector(
                    onTap: () async {
                      await doc.reference.update({'isPinned': false});
                      if (ctx.mounted) Navigator.pop(ctx, 'unpinned');
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF252830) : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(child: Text(title, style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500, color: textColor),
                            maxLines: 1, overflow: TextOverflow.ellipsis)),
                          const SizedBox(width: 8),
                          Text(AppLocalizations.of(context)!.write_pinUnpinAction, style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600, color: Colors.red)),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx, 'cancel'),
                    child: Text(AppLocalizations.of(context)!.write_registerWithoutPin, style: TextStyle(
                      color: AppColors.theme.darkGreyColor, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
