import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:hansol_high_school/widgets/error_snackbar.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hansol_high_school/data/analytics_service.dart';
import 'package:hansol_high_school/data/image_utils.dart';
import 'package:hansol_high_school/data/input_sanitizer.dart';
import 'package:hansol_high_school/l10n/app_localizations.dart';
import 'package:hansol_high_school/data/auth_service.dart';
import 'package:hansol_high_school/data/search_tokens.dart';
import 'package:hansol_high_school/screens/board/write_widgets/pinned_limit_sheet.dart';
import 'package:hansol_high_school/screens/board/write_widgets/unsaved_draft_sheet.dart';
import 'package:hansol_high_school/screens/board/write_widgets/write_draft_manager.dart';
import 'package:hansol_high_school/screens/board/write_widgets/write_category_selector.dart';
import 'package:hansol_high_school/screens/board/write_widgets/write_event_form_section.dart';
import 'package:hansol_high_school/screens/board/write_widgets/write_image_section.dart';
import 'package:hansol_high_school/screens/board/write_widgets/write_poll_form_section.dart';
import 'package:hansol_high_school/screens/board/write_widgets/write_post_validator.dart';
import 'package:hansol_high_school/screens/board/write_widgets/write_toggle_row.dart';
import 'package:hansol_high_school/data/board_categories.dart';
import 'package:hansol_high_school/data/post_repository.dart';
import 'package:hansol_high_school/styles/app_colors.dart';
import 'package:image_picker/image_picker.dart';

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
    final d = await WriteDraftManager.load();
    if (d.title == null && d.content == null) return;
    if (!mounted) return;
    setState(() {
      if (d.title != null && _titleController.text.isEmpty) _titleController.text = d.title!;
      if (d.content != null && _contentController.text.isEmpty) _contentController.text = d.content!;
      if (d.category != null) _category = d.category!;
    });
  }

  Future<void> _saveDraft() => WriteDraftManager.save(
    title: _titleController.text.trim(),
    content: _contentController.text.trim(),
    category: _category,
  );

  Future<void> _clearDraft() => WriteDraftManager.clear();

  Future<void> _loadExistingData() async {
    final d = await WriteDraftManager.loadExistingPost(widget.postId!);
    if (d == null || !mounted) return;
    setState(() {
      _isAnonymous = d.isAnonymous;
      _isPinned = d.isPinned;
      if (d.attachPoll) {
        _attachPoll = true;
        _pollControllers.clear();
        for (var o in d.pollOptions) {
          _pollControllers.add(TextEditingController(text: o));
        }
      }
      if (d.attachEvent) {
        _attachEvent = true;
        _eventDate = d.eventDate;
        _eventContentController.text = d.eventContent;
        _eventStartTime = d.eventStartTime;
        _eventEndTime = d.eventEndTime;
      }
    });
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
                  onDateChanged: (d) => setState(() => _eventDate = d),
                  onTimeChanged: (t, isStart) => setState(() {
                    if (isStart) {
                      _eventStartTime = t;
                    } else {
                      _eventEndTime = t;
                    }
                  }),
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
      final compressed = await ImageUtils.compress(File(xFile.path));
      if (compressed != null) {
        setState(() => _images.add(compressed));
      }
    }
  }

  Future<void> _onSubmit() async {
    final title = InputSanitizer.sanitize(_titleController.text.trim());
    final content = InputSanitizer.sanitize(_contentController.text.trim());

    final l = AppLocalizations.of(context)!;

    final error = WritePostValidator.validate(
      title: title,
      content: content,
      attachPoll: _attachPoll,
      pollControllers: _pollControllers,
      attachEvent: _attachEvent,
      eventDate: _eventDate,
      eventContent: _eventContentController.text.trim(),
      l: l,
    );
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    if (!_isEdit && !await WritePostValidator.checkRateLimit()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.write_errorRateLimit)),
        );
      }
      return;
    }

    setState(() => _saving = true);
    if (!AuthService.isLoggedIn) {
      if (mounted) { setState(() => _saving = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.write_errorLoginRequired))); }
      return;
    }
    UserProfile? profile;
    for (int i = 0; i < 3; i++) { profile = await AuthService.getUserProfile(); if (profile != null) break; await Future.delayed(const Duration(seconds: 1)); }
    if (profile == null) {
      if (mounted) { setState(() => _saving = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.write_errorProfileLoadFailed))); }
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
      final postData = WritePostValidator.buildPostData(
        title: title,
        content: content,
        category: _category,
        authorUid: AuthService.currentUser!.uid,
        displayName: displayName,
        realName: profile.displayName,
        isAnonymous: _isAnonymous,
        isPinned: _isPinned,
        searchTokens: SearchTokens.forDocument(title, content),
        attachPoll: _attachPoll,
        pollControllers: _pollControllers,
        attachEvent: _attachEvent,
        eventDate: _eventDate,
        eventContent: _eventContentController.text.trim(),
        eventStartTime: _eventStartTime,
        eventEndTime: _eventEndTime,
      );

      if (_isPinned) {
        postData['pinnedAt'] = FieldValue.serverTimestamp();
      }

      if (_isEdit) {
        if (_images.isNotEmpty) {
          final urls = await ImageUtils.uploadPostImages(_images, widget.postId!);
          postData['imageUrls'] = FieldValue.arrayUnion(urls);
        }
        await repo.updatePost(widget.postId!, postData);
      } else {
        WritePostValidator.addNewPostDefaults(postData);
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
            final urls = await ImageUtils.uploadPostImages(_images, docRef.id);
            await docRef.update({'imageUrls': urls});
          }
        }
        unawaited(AnalyticsService.logPostCreate(boardType: _category, isAnonymous: _isAnonymous));
      }

      if (!_isEdit) {
        await WritePostValidator.markPostTime();
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
