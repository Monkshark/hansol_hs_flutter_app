import 'package:flutter/material.dart';
import 'package:hansol_high_school/l10n/app_localizations.dart';
import 'package:hansol_high_school/styles/app_colors.dart';

/// 게시판 카테고리 상수 — Firestore 값은 한국어이므로 영문 상수로 참조
class BoardCategories {
  BoardCategories._();

  static const all = '전체';
  static const popular = '인기글';
  static const free = '자유';
  static const question = '질문';
  static const info = '정보공유';
  static const lostFound = '분실물';
  static const council = '학생회';
  static const club = '동아리';

  /// 게시판 탭에 표시되는 전체 카테고리 (전체·인기글 포함)
  static const boardKeys = [all, popular, free, question, info, lostFound, council, club];

  /// 글 작성 시 선택 가능한 카테고리 (전체·인기글 제외)
  static const writeKeys = [free, question, info, lostFound, council, club];

  /// FCM 토픽용 영문 키 매핑
  static const topicKey = <String, String>{
    free: 'free',
    question: 'question',
    info: 'info',
    lostFound: 'lost',
    council: 'council',
    club: 'club',
  };

  /// 카테고리 → l10n 이름
  static String localizedName(AppLocalizations l, String key) {
    switch (key) {
      case all: return l.board_categoryAll;
      case popular: return l.board_categoryPopular;
      case free: return l.board_categoryFree;
      case question: return l.board_categoryQuestion;
      case info: return l.board_categoryInfoShare;
      case lostFound: return l.board_categoryLostFound;
      case council: return l.board_categoryStudentCouncil;
      case club: return l.board_categoryClub;
      default: return key;
    }
  }

  /// 카테고리 → 색상
  static Color color(String category) {
    switch (category) {
      case free: return AppColors.theme.primaryColor;
      case question: return AppColors.theme.secondaryColor;
      case info: return AppColors.theme.tertiaryColor;
      case lostFound: return const Color(0xFFFF5722);
      case council: return const Color(0xFF4CAF50);
      case club: return const Color(0xFF9C27B0);
      default: return AppColors.theme.darkGreyColor;
    }
  }
}
