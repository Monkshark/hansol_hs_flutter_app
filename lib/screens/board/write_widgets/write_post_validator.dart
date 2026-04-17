import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hansol_high_school/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WritePostValidator {
  static String? validate({
    required String title,
    required String content,
    required bool attachPoll,
    required List<TextEditingController> pollControllers,
    required bool attachEvent,
    required DateTime? eventDate,
    required String eventContent,
    required AppLocalizations l,
  }) {
    if (title.isEmpty) return l.write_errorTitleRequired;
    if (title.length > 200) return l.write_errorTitleTooLong;
    if (content.isEmpty) return l.write_errorContentRequired;
    if (content.length > 5000) return l.write_errorContentTooLong;

    if (attachPoll) {
      final validOptions = pollControllers.where((c) => c.text.trim().isNotEmpty).toList();
      if (validOptions.length < 2) return l.write_errorPollOptionsRequired;
      for (var c in pollControllers) {
        if (c.text.trim().length > 100) return l.write_errorPollOptionTooLong;
      }
    }

    if (attachEvent && eventDate == null) return l.write_errorEventDateRequired;
    if (attachEvent && eventContent.isEmpty) return l.write_errorEventContentRequired;
    if (attachEvent && eventContent.length > 200) return l.write_errorEventContentTooLong;

    return null;
  }

  static Map<String, dynamic> buildPostData({
    required String title,
    required String content,
    required String category,
    required String authorUid,
    required String displayName,
    required String realName,
    required bool isAnonymous,
    required bool isPinned,
    required List<String> searchTokens,
    required bool attachPoll,
    required List<TextEditingController> pollControllers,
    required bool attachEvent,
    required DateTime? eventDate,
    required String eventContent,
    required TimeOfDay? eventStartTime,
    required TimeOfDay? eventEndTime,
  }) {
    final postData = <String, dynamic>{
      'title': title,
      'content': content,
      'category': category,
      'authorUid': authorUid,
      'authorName': displayName,
      'authorRealName': realName,
      'isAnonymous': isAnonymous,
      'isPinned': isPinned,
      'searchTokens': searchTokens,
    };

    if (attachPoll) {
      final options = pollControllers
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();
      postData['pollOptions'] = options;
      postData['pollVoters'] = <String, dynamic>{};
    } else {
      postData['pollOptions'] = null;
      postData['pollVoters'] = null;
    }

    if (attachEvent && eventDate != null) {
      postData['eventDate'] = eventDate.toIso8601String();
      postData['eventContent'] = eventContent;
      postData['eventStartTime'] = eventStartTime != null
          ? eventStartTime.hour * 60 + eventStartTime.minute
          : -1;
      postData['eventEndTime'] = eventEndTime != null
          ? eventEndTime.hour * 60 + eventEndTime.minute
          : -1;
    } else {
      postData['eventDate'] = null;
      postData['eventContent'] = null;
      postData['eventStartTime'] = null;
      postData['eventEndTime'] = null;
    }

    return postData;
  }

  static void addNewPostDefaults(Map<String, dynamic> postData) {
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
  }

  static Future<bool> checkRateLimit() async {
    final prefs = await SharedPreferences.getInstance();
    final lastPostTime = prefs.getInt('last_post_time') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    return now - lastPostTime >= 30000;
  }

  static Future<void> markPostTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_post_time', DateTime.now().millisecondsSinceEpoch);
  }
}
