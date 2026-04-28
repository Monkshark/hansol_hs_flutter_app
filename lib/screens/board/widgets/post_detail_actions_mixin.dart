import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hansol_high_school/widgets/error_snackbar.dart';
import 'package:hansol_high_school/data/auth_service.dart';
import 'package:hansol_high_school/l10n/app_localizations.dart';
import 'package:hansol_high_school/screens/board/widgets/post_action_sheet.dart';
import 'package:hansol_high_school/screens/board/write_post_screen.dart';
import 'package:hansol_high_school/data/post_repository.dart';

mixin PostDetailActionsMixin<T extends StatefulWidget> on State<T> {
  PostRepository get actionRepo;
  String get actionPostId;

  Future<void> toggleBookmark(bool isCurrentlyBookmarked) async {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return;
    try {
      await actionRepo.toggleBookmark(actionPostId, uid, isCurrentlyBookmarked);
    } catch (e) {
      log('PostDetailScreen: toggleBookmark error: $e');
      if (mounted) showErrorSnackbar(context, e);
    }
  }

  Future<void> pinPost() async {
    try {
      await actionRepo.pinPost(actionPostId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.post_pinSuccess)),
        );
      }
    } on StateError {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.post_pinMaxed)),
        );
      }
    }
  }

  Future<void> unpinPost() async {
    await actionRepo.unpinPost(actionPostId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.post_unpinSuccess)),
      );
    }
  }

  void editPost(Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WritePostScreen(
          postId: actionPostId,
          initialTitle: data['title'],
          initialContent: data['content'],
          initialCategory: data['category'],
        ),
      ),
    );
  }

  Future<void> deletePost() async {
    final confirm = await showConfirmSheet(context, title: AppLocalizations.of(context)!.post_deleteConfirm, content: AppLocalizations.of(context)!.post_deleteConfirmMessage, confirmLabel: AppLocalizations.of(context)!.common_delete);

    if (confirm == true) {
      try {
        final uid = AuthService.currentUser?.uid;
        final postSnap = await actionRepo.getPost(actionPostId);
        final postData = postSnap.data();
        if (postData != null && uid != null && uid != postData['authorUid']) {
          final profile = await AuthService.getCachedProfile();
          await actionRepo.logAdminAction({
            'action': 'delete_post',
            'adminUid': uid,
            'adminName': profile?.displayName ?? '',
            'postId': actionPostId,
            'postTitle': postData['title'] ?? '',
            'postAuthorUid': postData['authorUid'] ?? '',
            'postAuthorName': postData['authorName'] ?? '',
            'createdAt': FieldValue.serverTimestamp(),
            'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
          });
        }

        await actionRepo.deletePost(actionPostId, actorUid: uid);
        if (mounted) Navigator.pop(context);
      } catch (e) {
        log('PostDetailScreen: deletePost error: $e');
        if (mounted) showErrorSnackbar(context, e);
      }
    }
  }

  Future<void> resolvePost() async {
    try {
      await actionRepo.resolvePost(actionPostId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.post_resolvedMarked)),
        );
      }
    } catch (e) {
      log('PostDetailScreen: resolvePost error: $e');
      if (mounted) showErrorSnackbar(context, e);
    }
  }

  Future<void> confirmDeleteComment(String commentId) async {
    final confirm = await showConfirmSheet(context, title: AppLocalizations.of(context)!.post_confirmDeleteComment, content: AppLocalizations.of(context)!.post_confirmDeleteCommentMessage, confirmLabel: AppLocalizations.of(context)!.common_delete);

    if (confirm == true) {
      try {
        await actionRepo.deleteComment(actionPostId, commentId, actorUid: AuthService.currentUser?.uid);
      } catch (e) {
        log('PostDetailScreen: deleteComment error: $e');
        if (mounted) showErrorSnackbar(context, e);
      }
    }
  }
}
