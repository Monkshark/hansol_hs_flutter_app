import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:hansol_high_school/widgets/error_snackbar.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:hansol_high_school/data/analytics_service.dart';
import 'package:hansol_high_school/data/input_sanitizer.dart';
import 'package:hansol_high_school/l10n/app_localizations.dart';
import 'package:hansol_high_school/data/auth_service.dart';
import 'package:hansol_high_school/data/search_tokens.dart';
import 'package:hansol_high_school/screens/board/write_widgets/pinned_limit_sheet.dart';
import 'package:hansol_high_school/screens/board/write_widgets/unsaved_draft_sheet.dart';
import 'package:hansol_high_school/screens/board/write_widgets/write_category_selector.dart';
import 'package:hansol_high_school/screens/board/write_widgets/write_event_form_section.dart';
import 'package:hansol_high_school/screens/board/write_widgets/write_image_section.dart';
import 'package:hansol_high_school/screens/board/write_widgets/write_poll_form_section.dart';
import 'package:hansol_high_school/screens/board/write_widgets/write_toggle_row.dart';
import 'package:hansol_high_school/data/board_categories.dart';
import 'package:hansol_high_school/data/post_repository.dart';
import 'package:hansol_high_school/styles/app_colors.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

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
    super.key,
  });

  @override
  State<WritePostScreen> createState() => _WritePostScreenState();
}

class _WritePostScreenState extends State<WritePostScreen> {
  static const _categoryKeys = BoardCategories.writeKeys;
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
    _category = widget.initialCategory ?? _categoryKeys[0];
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    _contentController = TextEditingController(text: widget.initialContent ?? '');
    _eventContentController = TextEditingController();
    if (_isEdit) {
      _loadExistingData();
    } else {
      unawaited(AnalyticsService.logPostStart(boardType: _category));
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
    unawaited(AnalyticsService.logPostDraft());
  }

  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('draft_title');
    await prefs.remove('draft_content');
    await prefs.remove('draft_category');
  }

  Future<void> _loadExistingData() async {
    try {
      final doc = await PostRepository.instance.getPost(widget.postId!);
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
    } catch (e) {
      log('WritePostScreen: load post error: $e');
    }
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
          final action = await showUnsavedDraftSheet(context);
          if (action == 'save') await _saveDraft();
          if (action == 'discard') await _clearDraft();
          if (action == null) return;
        }
        if (context.mounted) Navigator.of(context).pop();
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
                if (context.mounted) {
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
            WriteCategorySelector(
              categoryKeys: _categoryKeys,
              selectedCategory: _category,
              onCategoryChanged: (cat) => setState(() {
                _category = cat;
                if (cat != BoardCategories.info) _attachEvent = false;
              }),
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

            if (_category == BoardCategories.info) ...[
              const SizedBox(height: 16),
              WriteToggleRow(
                value: _attachEvent,
                onTap: () => setState(() => _attachEvent = !_attachEvent),
                label: AppLocalizations.of(context)!.write_eventAttach,
                activeColor: AppColors.theme.tertiaryColor,
                icon: Icons.event,
                labelWeight: FontWeight.w600,
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
            WriteToggleRow(
              value: _attachPoll,
              onTap: () => setState(() => _attachPoll = !_attachPoll),
              label: AppLocalizations.of(context)!.write_pollAttach,
              activeColor: AppColors.theme.secondaryColor,
              icon: Icons.poll,
              labelWeight: FontWeight.w600,
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
            WriteToggleRow(
              value: _isAnonymous,
              onTap: () => setState(() => _isAnonymous = !_isAnonymous),
              label: AppLocalizations.of(context)!.write_anonymous,
              activeColor: AppColors.theme.primaryColor,
            ),

            if (AuthService.cachedProfile?.isManager == true) ...[
              const SizedBox(height: 16),
              WriteToggleRow(
                value: _isPinned,
                onTap: () => setState(() => _isPinned = !_isPinned),
                label: AppLocalizations.of(context)!.write_pinAsNotice,
                activeColor: Colors.red,
                icon: Icons.push_pin,
                iconColor: Colors.red,
                labelWeight: FontWeight.w600,
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
    final targetPath = p.join(
      dir.path,
      'compressed_${DateTime.now().millisecondsSinceEpoch}_${p.basenameWithoutExtension(file.path)}.jpg',
    );

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
    final title = InputSanitizer.sanitize(_titleController.text.trim());
    final content = InputSanitizer.sanitize(_contentController.text.trim());

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
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.write_errorLoginRequired)),
        );
      }
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
    if (!mounted) return;

    final displayName = _isAnonymous ? AppLocalizations.of(context)!.post_anonymous : profile.displayName;

    final repo = PostRepository.instance;

    if (_isPinned) {
      final pinnedSnap = await repo.getPinnedPosts();
      if (pinnedSnap.docs.length >= 3 && mounted) {
        final result = await showPinnedLimitSheet(context, pinnedSnap.docs);
        if (result == null) {
          setState(() => _saving = false);
          return;
        }
        if (result == 'cancel') {
          _isPinned = false;
        }
      }
    }

    if (!_isEdit) unawaited(AnalyticsService.logPostSubmit(boardType: _category));

    try {
      final postData = <String, dynamic>{
        'title': title,
        'content': content,
        'category': _category,
        'authorUid': AuthService.currentUser!.uid,
        'authorName': displayName,
        'authorRealName': profile.displayName,
        'isAnonymous': _isAnonymous,
        'isPinned': _isPinned,
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
        await repo.updatePost(widget.postId!, postData);
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
        final docRef = await repo.createPost(postData);

        if (docRef == null) {
          // 오프라인 → 큐에 저장됨
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppLocalizations.of(context)!.offline_postQueued)),
            );
          }
        } else {
          if (_images.isNotEmpty) {
            final urls = await _uploadImages(docRef.id);
            await docRef.update({'imageUrls': urls});
          }
        }
        unawaited(AnalyticsService.logPostCreate(boardType: _category, isAnonymous: _isAnonymous));
      }

      if (!_isEdit) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('last_post_time', DateTime.now().millisecondsSinceEpoch);
        await _clearDraft();
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      log('WritePostScreen: submit error: $e');
      if (mounted) {
        setState(() => _saving = false);
        showErrorSnackbar(context, e);
      }
    }
  }
}
