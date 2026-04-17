import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:hansol_high_school/data/analytics_service.dart';
import 'package:hansol_high_school/data/post_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Draft {
  final String? title;
  final String? content;
  final String? category;
  Draft({this.title, this.content, this.category});
}

class ExistingPostData {
  final bool isAnonymous;
  final bool isPinned;
  final bool attachPoll;
  final List<String> pollOptions;
  final bool attachEvent;
  final DateTime? eventDate;
  final String eventContent;
  final TimeOfDay? eventStartTime;
  final TimeOfDay? eventEndTime;

  ExistingPostData({
    required this.isAnonymous,
    required this.isPinned,
    required this.attachPoll,
    required this.pollOptions,
    required this.attachEvent,
    this.eventDate,
    required this.eventContent,
    this.eventStartTime,
    this.eventEndTime,
  });
}

class WriteDraftManager {
  static Future<Draft> load() async {
    final prefs = await SharedPreferences.getInstance();
    return Draft(
      title: prefs.getString('draft_title'),
      content: prefs.getString('draft_content'),
      category: prefs.getString('draft_category'),
    );
  }

  static Future<void> save({
    required String title,
    required String content,
    required String category,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (title.isEmpty && content.isEmpty) {
      await clear();
      return;
    }
    await prefs.setString('draft_title', title);
    await prefs.setString('draft_content', content);
    await prefs.setString('draft_category', category);
    unawaited(AnalyticsService.logPostDraft());
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('draft_title');
    await prefs.remove('draft_content');
    await prefs.remove('draft_category');
  }

  static Future<ExistingPostData?> loadExistingPost(String postId) async {
    try {
      final doc = await PostRepository.instance.getPost(postId);
      if (!doc.exists) return null;
      final data = doc.data()!;

      var pollOptions = <String>[];
      final attachPoll = data['pollOptions'] != null && (data['pollOptions'] as List).isNotEmpty;
      if (attachPoll) {
        pollOptions = (data['pollOptions'] as List).cast<String>();
      }

      var attachEvent = false;
      DateTime? eventDate;
      var eventContent = '';
      TimeOfDay? eventStartTime;
      TimeOfDay? eventEndTime;
      if (data['eventDate'] != null) {
        attachEvent = true;
        eventDate = DateTime.parse(data['eventDate']);
        eventContent = data['eventContent'] ?? '';
        final st = data['eventStartTime'] as int?;
        final et = data['eventEndTime'] as int?;
        if (st != null && st >= 0) eventStartTime = TimeOfDay(hour: st ~/ 60, minute: st % 60);
        if (et != null && et >= 0) eventEndTime = TimeOfDay(hour: et ~/ 60, minute: et % 60);
      }

      return ExistingPostData(
        isAnonymous: data['isAnonymous'] == true,
        isPinned: data['isPinned'] == true,
        attachPoll: attachPoll,
        pollOptions: pollOptions,
        attachEvent: attachEvent,
        eventDate: eventDate,
        eventContent: eventContent,
        eventStartTime: eventStartTime,
        eventEndTime: eventEndTime,
      );
    } catch (e) {
      log('WriteDraftManager: loadExistingPost error: $e');
      return null;
    }
  }
}
