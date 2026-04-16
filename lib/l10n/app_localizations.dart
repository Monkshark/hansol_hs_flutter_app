import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko')
  ];

  /// No description provided for @main_accountDeleted.
  ///
  /// In ko, this message translates to:
  /// **'계정이 삭제되었습니다. 다시 가입해주세요.'**
  String get main_accountDeleted;

  /// No description provided for @login_canceled.
  ///
  /// In ko, this message translates to:
  /// **'로그인이 취소되었습니다'**
  String get login_canceled;

  /// No description provided for @login_schoolName.
  ///
  /// In ko, this message translates to:
  /// **'한솔고등학교'**
  String get login_schoolName;

  /// No description provided for @login_subtitle.
  ///
  /// In ko, this message translates to:
  /// **'로그인하면 더 많은 기능을 이용할 수 있어요'**
  String get login_subtitle;

  /// No description provided for @login_googleContinue.
  ///
  /// In ko, this message translates to:
  /// **'Google로 계속하기'**
  String get login_googleContinue;

  /// No description provided for @login_appleContinue.
  ///
  /// In ko, this message translates to:
  /// **'Apple로 계속하기'**
  String get login_appleContinue;

  /// No description provided for @login_kakaoContinue.
  ///
  /// In ko, this message translates to:
  /// **'카카오로 계속하기'**
  String get login_kakaoContinue;

  /// No description provided for @login_githubContinue.
  ///
  /// In ko, this message translates to:
  /// **'GitHub로 계속하기'**
  String get login_githubContinue;

  /// No description provided for @login_skipButton.
  ///
  /// In ko, this message translates to:
  /// **'나중에 하기'**
  String get login_skipButton;

  /// No description provided for @profileSetup_nameRequired.
  ///
  /// In ko, this message translates to:
  /// **'이름을 입력해주세요'**
  String get profileSetup_nameRequired;

  /// No description provided for @profileSetup_nameNoSpace.
  ///
  /// In ko, this message translates to:
  /// **'이름에 띄어쓰기를 포함할 수 없습니다'**
  String get profileSetup_nameNoSpace;

  /// No description provided for @profileSetup_studentIdError.
  ///
  /// In ko, this message translates to:
  /// **'학번을 정확히 입력해주세요'**
  String get profileSetup_studentIdError;

  /// No description provided for @profileSetup_saveFailed.
  ///
  /// In ko, this message translates to:
  /// **'저장에 실패했습니다. 다시 시도해주세요.'**
  String get profileSetup_saveFailed;

  /// No description provided for @profileSetup_signupRequest.
  ///
  /// In ko, this message translates to:
  /// **'가입 요청'**
  String get profileSetup_signupRequest;

  /// No description provided for @profileSetup_signupNotification.
  ///
  /// In ko, this message translates to:
  /// **'{name}님이 가입을 요청했습니다.'**
  String profileSetup_signupNotification(Object name);

  /// No description provided for @profileSetup_userType.
  ///
  /// In ko, this message translates to:
  /// **'신분'**
  String get profileSetup_userType;

  /// No description provided for @profileSetup_student.
  ///
  /// In ko, this message translates to:
  /// **'재학생'**
  String get profileSetup_student;

  /// No description provided for @profileSetup_graduate.
  ///
  /// In ko, this message translates to:
  /// **'졸업생'**
  String get profileSetup_graduate;

  /// No description provided for @profileSetup_teacher.
  ///
  /// In ko, this message translates to:
  /// **'교사'**
  String get profileSetup_teacher;

  /// No description provided for @profileSetup_parent.
  ///
  /// In ko, this message translates to:
  /// **'학부모'**
  String get profileSetup_parent;

  /// No description provided for @profileSetup_name.
  ///
  /// In ko, this message translates to:
  /// **'이름'**
  String get profileSetup_name;

  /// No description provided for @profileSetup_nameHint.
  ///
  /// In ko, this message translates to:
  /// **'이름을 입력하세요'**
  String get profileSetup_nameHint;

  /// No description provided for @profileSetup_studentId.
  ///
  /// In ko, this message translates to:
  /// **'학번'**
  String get profileSetup_studentId;

  /// No description provided for @profileSetup_studentIdHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 20301'**
  String get profileSetup_studentIdHint;

  /// No description provided for @profileSetup_gradeClass.
  ///
  /// In ko, this message translates to:
  /// **'{grade}학년 {classNum}반'**
  String profileSetup_gradeClass(Object grade, Object classNum);

  /// No description provided for @profileSetup_graduationYear.
  ///
  /// In ko, this message translates to:
  /// **'졸업연도'**
  String get profileSetup_graduationYear;

  /// No description provided for @profileSetup_graduationYearHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 2025'**
  String get profileSetup_graduationYearHint;

  /// No description provided for @profileSetup_teacherSubject.
  ///
  /// In ko, this message translates to:
  /// **'담당과목 (선택)'**
  String get profileSetup_teacherSubject;

  /// No description provided for @profileSetup_teacherSubjectHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 수학'**
  String get profileSetup_teacherSubjectHint;

  /// No description provided for @profileSetup_parentInfo.
  ///
  /// In ko, this message translates to:
  /// **'학부모로 가입하면 게시판을 이용할 수 있습니다.'**
  String get profileSetup_parentInfo;

  /// No description provided for @profileSetup_privacyTitle.
  ///
  /// In ko, this message translates to:
  /// **'개인정보 수집·이용 동의 (필수)'**
  String get profileSetup_privacyTitle;

  /// No description provided for @profileSetup_privacyDescription.
  ///
  /// In ko, this message translates to:
  /// **'원활한 서비스 제공을 위해 이름, 학번 등 기본 정보를 수집합니다. 수집된 정보는 앱 이용 목적으로만 사용되며, 회원 탈퇴 시 즉시 삭제됩니다.'**
  String get profileSetup_privacyDescription;

  /// No description provided for @profileSetup_updateTitle.
  ///
  /// In ko, this message translates to:
  /// **'프로필 업데이트'**
  String get profileSetup_updateTitle;

  /// No description provided for @profileSetup_setupTitle.
  ///
  /// In ko, this message translates to:
  /// **'정보 입력'**
  String get profileSetup_setupTitle;

  /// No description provided for @profileSetup_updateSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'새 학기 정보를 업데이트해주세요'**
  String get profileSetup_updateSubtitle;

  /// No description provided for @profileSetup_setupSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'환영합니다!'**
  String get profileSetup_setupSubtitle;

  /// No description provided for @profileSetup_updateHint.
  ///
  /// In ko, this message translates to:
  /// **'학번, 학년/반을 확인해주세요'**
  String get profileSetup_updateHint;

  /// No description provided for @profileSetup_setupHint.
  ///
  /// In ko, this message translates to:
  /// **'기본 정보를 입력해주세요'**
  String get profileSetup_setupHint;

  /// No description provided for @profileSetup_updateButton.
  ///
  /// In ko, this message translates to:
  /// **'업데이트'**
  String get profileSetup_updateButton;

  /// No description provided for @profileSetup_completeButton.
  ///
  /// In ko, this message translates to:
  /// **'완료'**
  String get profileSetup_completeButton;

  /// No description provided for @profileEdit_accountTitle.
  ///
  /// In ko, this message translates to:
  /// **'내 계정'**
  String get profileEdit_accountTitle;

  /// No description provided for @profileEdit_camera.
  ///
  /// In ko, this message translates to:
  /// **'카메라'**
  String get profileEdit_camera;

  /// No description provided for @profileEdit_gallery.
  ///
  /// In ko, this message translates to:
  /// **'갤러리'**
  String get profileEdit_gallery;

  /// No description provided for @profileEdit_deletePhoto.
  ///
  /// In ko, this message translates to:
  /// **'사진 삭제'**
  String get profileEdit_deletePhoto;

  /// No description provided for @profileEdit_photoChangedSuccess.
  ///
  /// In ko, this message translates to:
  /// **'프로필 사진이 변경되었습니다'**
  String get profileEdit_photoChangedSuccess;

  /// No description provided for @profileEdit_photoChangeFailed.
  ///
  /// In ko, this message translates to:
  /// **'사진 변경에 실패했습니다'**
  String get profileEdit_photoChangeFailed;

  /// No description provided for @profileEdit_photoDeletedSuccess.
  ///
  /// In ko, this message translates to:
  /// **'프로필 사진이 삭제되었습니다'**
  String get profileEdit_photoDeletedSuccess;

  /// No description provided for @profileEdit_photoDeleteFailed.
  ///
  /// In ko, this message translates to:
  /// **'삭제에 실패했습니다'**
  String get profileEdit_photoDeleteFailed;

  /// No description provided for @profileEdit_deleteAccountTitle.
  ///
  /// In ko, this message translates to:
  /// **'회원 탈퇴'**
  String get profileEdit_deleteAccountTitle;

  /// No description provided for @profileEdit_deleteAccountConfirm.
  ///
  /// In ko, this message translates to:
  /// **'정말 탈퇴하시겠습니까?\n모든 데이터가 삭제되며 복구할 수 없습니다.'**
  String get profileEdit_deleteAccountConfirm;

  /// No description provided for @profileEdit_confirm.
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get profileEdit_confirm;

  /// No description provided for @profileEdit_emailLabel.
  ///
  /// In ko, this message translates to:
  /// **'이메일'**
  String get profileEdit_emailLabel;

  /// No description provided for @profileEdit_nameLabel.
  ///
  /// In ko, this message translates to:
  /// **'이름'**
  String get profileEdit_nameLabel;

  /// No description provided for @profileEdit_finalConfirmTitle.
  ///
  /// In ko, this message translates to:
  /// **'최종 확인'**
  String get profileEdit_finalConfirmTitle;

  /// No description provided for @profileEdit_finalConfirmMessage.
  ///
  /// In ko, this message translates to:
  /// **'탈퇴를 진행하려면 {confirmLabel}을 정확히 입력하세요.'**
  String profileEdit_finalConfirmMessage(Object confirmLabel);

  /// No description provided for @profileEdit_inputPlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'{confirmLabel} 입력'**
  String profileEdit_inputPlaceholder(Object confirmLabel);

  /// No description provided for @profileEdit_withdrawButton.
  ///
  /// In ko, this message translates to:
  /// **'탈퇴'**
  String get profileEdit_withdrawButton;

  /// No description provided for @profileEdit_reauthRequired.
  ///
  /// In ko, this message translates to:
  /// **'재인증이 필요합니다. 다시 로그인 후 시도해주세요.'**
  String get profileEdit_reauthRequired;

  /// No description provided for @profileEdit_reauthFailed.
  ///
  /// In ko, this message translates to:
  /// **'재인증에 실패했습니다. 다시 로그인 후 시도해주세요.'**
  String get profileEdit_reauthFailed;

  /// No description provided for @profileEdit_deleteAccountFailed.
  ///
  /// In ko, this message translates to:
  /// **'회원 탈퇴에 실패했습니다. 다시 시도해주세요.'**
  String get profileEdit_deleteAccountFailed;

  /// No description provided for @profileEdit_studentId.
  ///
  /// In ko, this message translates to:
  /// **'학번'**
  String get profileEdit_studentId;

  /// No description provided for @profileEdit_gradeClass.
  ///
  /// In ko, this message translates to:
  /// **'학년/반'**
  String get profileEdit_gradeClass;

  /// No description provided for @profileEdit_graduationYear.
  ///
  /// In ko, this message translates to:
  /// **'졸업연도'**
  String get profileEdit_graduationYear;

  /// No description provided for @profileEdit_teacherSubject.
  ///
  /// In ko, this message translates to:
  /// **'담당과목'**
  String get profileEdit_teacherSubject;

  /// No description provided for @profileEdit_loginProvider.
  ///
  /// In ko, this message translates to:
  /// **'로그인'**
  String get profileEdit_loginProvider;

  /// No description provided for @home_scheduleLoading.
  ///
  /// In ko, this message translates to:
  /// **'일정 로딩중...'**
  String get home_scheduleLoading;

  /// No description provided for @home_ddaySet.
  ///
  /// In ko, this message translates to:
  /// **'D-day를 설정하세요'**
  String get home_ddaySet;

  /// No description provided for @home_schoolInfo.
  ///
  /// In ko, this message translates to:
  /// **'한솔고 {grade}학년 {classNum}반'**
  String home_schoolInfo(Object grade, Object classNum);

  /// No description provided for @home_schoolName.
  ///
  /// In ko, this message translates to:
  /// **'한솔고등학교'**
  String get home_schoolName;

  /// No description provided for @home_lunchPreview.
  ///
  /// In ko, this message translates to:
  /// **'급식 정보 로딩중...'**
  String get home_lunchPreview;

  /// No description provided for @home_lunchNoInfo.
  ///
  /// In ko, this message translates to:
  /// **'오늘 급식 정보가 없습니다'**
  String get home_lunchNoInfo;

  /// No description provided for @home_timetableTitle.
  ///
  /// In ko, this message translates to:
  /// **'시간표'**
  String get home_timetableTitle;

  /// No description provided for @home_timetableSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'이번 주 시간표를 확인하세요'**
  String get home_timetableSubtitle;

  /// No description provided for @home_gradesTitle.
  ///
  /// In ko, this message translates to:
  /// **'성적 관리'**
  String get home_gradesTitle;

  /// No description provided for @home_gradesSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'내신/모의고사 성적을 기록하세요'**
  String get home_gradesSubtitle;

  /// No description provided for @home_boardTitle.
  ///
  /// In ko, this message translates to:
  /// **'게시판'**
  String get home_boardTitle;

  /// No description provided for @home_boardSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'자유롭게 소통해보세요'**
  String get home_boardSubtitle;

  /// No description provided for @home_chatTitle.
  ///
  /// In ko, this message translates to:
  /// **'채팅'**
  String get home_chatTitle;

  /// No description provided for @home_chatSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'1:1 대화하기'**
  String get home_chatSubtitle;

  /// No description provided for @home_linkRiroschool.
  ///
  /// In ko, this message translates to:
  /// **'리로스쿨'**
  String get home_linkRiroschool;

  /// No description provided for @home_linkOfficial.
  ///
  /// In ko, this message translates to:
  /// **'한솔 공식'**
  String get home_linkOfficial;

  /// No description provided for @home_admin.
  ///
  /// In ko, this message translates to:
  /// **'관리자'**
  String get home_admin;

  /// No description provided for @home_notification.
  ///
  /// In ko, this message translates to:
  /// **'알림'**
  String get home_notification;

  /// No description provided for @home_settings.
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get home_settings;

  /// No description provided for @home_writePost.
  ///
  /// In ko, this message translates to:
  /// **'글 쓰기'**
  String get home_writePost;

  /// No description provided for @home_search.
  ///
  /// In ko, this message translates to:
  /// **'검색'**
  String get home_search;

  /// No description provided for @home_myPosts.
  ///
  /// In ko, this message translates to:
  /// **'내 글'**
  String get home_myPosts;

  /// No description provided for @home_postImage.
  ///
  /// In ko, this message translates to:
  /// **'게시글 이미지'**
  String get home_postImage;

  /// No description provided for @meal_noInfo.
  ///
  /// In ko, this message translates to:
  /// **'급식 정보 없음'**
  String get meal_noInfo;

  /// No description provided for @meal_noInfoEmpty.
  ///
  /// In ko, this message translates to:
  /// **'급식 정보가 없습니다'**
  String get meal_noInfoEmpty;

  /// No description provided for @meal_refreshHint.
  ///
  /// In ko, this message translates to:
  /// **'탭하여 새로고침'**
  String get meal_refreshHint;

  /// No description provided for @meal_error.
  ///
  /// In ko, this message translates to:
  /// **'오류: {error}'**
  String meal_error(Object error);

  /// No description provided for @meal_noData.
  ///
  /// In ko, this message translates to:
  /// **'급식 정보가 없습니다'**
  String get meal_noData;

  /// No description provided for @meal_nutritionTitle.
  ///
  /// In ko, this message translates to:
  /// **'영양 정보'**
  String get meal_nutritionTitle;

  /// No description provided for @meal_mealType.
  ///
  /// In ko, this message translates to:
  /// **'식사'**
  String get meal_mealType;

  /// No description provided for @meal_calorie.
  ///
  /// In ko, this message translates to:
  /// **'칼로리'**
  String get meal_calorie;

  /// No description provided for @meal_noInfoShort.
  ///
  /// In ko, this message translates to:
  /// **'정보 없음'**
  String get meal_noInfoShort;

  /// No description provided for @meal_nutrition.
  ///
  /// In ko, this message translates to:
  /// **'영양 성분'**
  String get meal_nutrition;

  /// No description provided for @meal_allergy.
  ///
  /// In ko, this message translates to:
  /// **'포함된 알레르기 유발 식품'**
  String get meal_allergy;

  /// No description provided for @meal_today.
  ///
  /// In ko, this message translates to:
  /// **'오늘'**
  String get meal_today;

  /// No description provided for @meal_breakfast.
  ///
  /// In ko, this message translates to:
  /// **'조식'**
  String get meal_breakfast;

  /// No description provided for @meal_lunch.
  ///
  /// In ko, this message translates to:
  /// **'중식'**
  String get meal_lunch;

  /// No description provided for @meal_dinner.
  ///
  /// In ko, this message translates to:
  /// **'석식'**
  String get meal_dinner;

  /// No description provided for @notice_noSchedule.
  ///
  /// In ko, this message translates to:
  /// **'일정이 없습니다'**
  String get notice_noSchedule;

  /// No description provided for @notice_continuousDeleteTitle.
  ///
  /// In ko, this message translates to:
  /// **'연속 일정 삭제'**
  String get notice_continuousDeleteTitle;

  /// No description provided for @notice_deleteThisDayOnly.
  ///
  /// In ko, this message translates to:
  /// **'이 날만 삭제'**
  String get notice_deleteThisDayOnly;

  /// No description provided for @notice_deleteAllSchedule.
  ///
  /// In ko, this message translates to:
  /// **'전체 일정 삭제'**
  String get notice_deleteAllSchedule;

  /// No description provided for @notice_noSchoolSchedule.
  ///
  /// In ko, this message translates to:
  /// **'학사일정이 없습니다'**
  String get notice_noSchoolSchedule;

  /// No description provided for @board_title.
  ///
  /// In ko, this message translates to:
  /// **'게시판'**
  String get board_title;

  /// No description provided for @board_searchHint.
  ///
  /// In ko, this message translates to:
  /// **'제목/본문 검색...'**
  String get board_searchHint;

  /// No description provided for @board_emptyPosts.
  ///
  /// In ko, this message translates to:
  /// **'게시글이 없습니다'**
  String get board_emptyPosts;

  /// No description provided for @board_searchEmptyQuery.
  ///
  /// In ko, this message translates to:
  /// **'검색어를 입력하세요'**
  String get board_searchEmptyQuery;

  /// No description provided for @board_recentSearches.
  ///
  /// In ko, this message translates to:
  /// **'최근 검색어'**
  String get board_recentSearches;

  /// No description provided for @board_clearAllSearches.
  ///
  /// In ko, this message translates to:
  /// **'전체 삭제'**
  String get board_clearAllSearches;

  /// No description provided for @board_searchNoResults.
  ///
  /// In ko, this message translates to:
  /// **'검색 결과가 없습니다'**
  String get board_searchNoResults;

  /// No description provided for @board_accountSuspended.
  ///
  /// In ko, this message translates to:
  /// **'계정 정지 상태입니다'**
  String get board_accountSuspended;

  /// No description provided for @board_suspendedRemaining.
  ///
  /// In ko, this message translates to:
  /// **'남은 기간: {duration}'**
  String board_suspendedRemaining(Object duration);

  /// No description provided for @board_awaitingAdminApproval.
  ///
  /// In ko, this message translates to:
  /// **'관리자 승인 대기 중입니다'**
  String get board_awaitingAdminApproval;

  /// No description provided for @board_categoryAll.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get board_categoryAll;

  /// No description provided for @board_categoryFree.
  ///
  /// In ko, this message translates to:
  /// **'자유'**
  String get board_categoryFree;

  /// No description provided for @board_categoryPopular.
  ///
  /// In ko, this message translates to:
  /// **'인기글'**
  String get board_categoryPopular;

  /// No description provided for @board_categoryQuestion.
  ///
  /// In ko, this message translates to:
  /// **'질문'**
  String get board_categoryQuestion;

  /// No description provided for @board_categoryInfoShare.
  ///
  /// In ko, this message translates to:
  /// **'정보공유'**
  String get board_categoryInfoShare;

  /// No description provided for @board_categoryLostFound.
  ///
  /// In ko, this message translates to:
  /// **'분실물'**
  String get board_categoryLostFound;

  /// No description provided for @board_categoryStudentCouncil.
  ///
  /// In ko, this message translates to:
  /// **'학생회'**
  String get board_categoryStudentCouncil;

  /// No description provided for @board_categoryClub.
  ///
  /// In ko, this message translates to:
  /// **'동아리'**
  String get board_categoryClub;

  /// No description provided for @common_justNow.
  ///
  /// In ko, this message translates to:
  /// **'방금'**
  String get common_justNow;

  /// No description provided for @common_minutesAgo.
  ///
  /// In ko, this message translates to:
  /// **'{minutes}분 전'**
  String common_minutesAgo(Object minutes);

  /// No description provided for @common_hoursAgo.
  ///
  /// In ko, this message translates to:
  /// **'{hours}시간 전'**
  String common_hoursAgo(Object hours);

  /// No description provided for @common_daysAgo.
  ///
  /// In ko, this message translates to:
  /// **'{days}일 전'**
  String common_daysAgo(Object days);

  /// No description provided for @common_cancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get common_cancel;

  /// No description provided for @common_delete.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get common_delete;

  /// No description provided for @common_confirm.
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get common_confirm;

  /// No description provided for @common_save.
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get common_save;

  /// No description provided for @common_loginRequired.
  ///
  /// In ko, this message translates to:
  /// **'로그인이 필요합니다'**
  String get common_loginRequired;

  /// No description provided for @common_chatPartner.
  ///
  /// In ko, this message translates to:
  /// **'대화상대'**
  String get common_chatPartner;

  /// No description provided for @common_dateYmd.
  ///
  /// In ko, this message translates to:
  /// **'yyyy년 M월 d일'**
  String get common_dateYmd;

  /// No description provided for @common_dateMdE.
  ///
  /// In ko, this message translates to:
  /// **'M월 d일 (E)'**
  String get common_dateMdE;

  /// No description provided for @common_dateYM.
  ///
  /// In ko, this message translates to:
  /// **'yyyy년 M월'**
  String get common_dateYM;

  /// No description provided for @common_dateYmdE.
  ///
  /// In ko, this message translates to:
  /// **'yyyy년 M월 d일 (E)'**
  String get common_dateYmdE;

  /// No description provided for @common_dateMdEHm.
  ///
  /// In ko, this message translates to:
  /// **'M월 d일 (E) HH:mm'**
  String get common_dateMdEHm;

  /// No description provided for @common_dateYMdE.
  ///
  /// In ko, this message translates to:
  /// **'yyyy.M.d (E)'**
  String get common_dateYMdE;

  /// No description provided for @common_dateMdEEEE.
  ///
  /// In ko, this message translates to:
  /// **'M월 d일 EEEE'**
  String get common_dateMdEEEE;

  /// No description provided for @post_resolved.
  ///
  /// In ko, this message translates to:
  /// **'해결'**
  String get post_resolved;

  /// No description provided for @post_bookmark.
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get post_bookmark;

  /// No description provided for @post_chat.
  ///
  /// In ko, this message translates to:
  /// **'채팅'**
  String get post_chat;

  /// No description provided for @post_share.
  ///
  /// In ko, this message translates to:
  /// **'공유'**
  String get post_share;

  /// No description provided for @post_edit.
  ///
  /// In ko, this message translates to:
  /// **'수정'**
  String get post_edit;

  /// No description provided for @post_delete.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get post_delete;

  /// No description provided for @post_deleteByAdmin.
  ///
  /// In ko, this message translates to:
  /// **'삭제 (관리자)'**
  String get post_deleteByAdmin;

  /// No description provided for @post_pinAsNotice.
  ///
  /// In ko, this message translates to:
  /// **'공지 등록'**
  String get post_pinAsNotice;

  /// No description provided for @post_unpinNotice.
  ///
  /// In ko, this message translates to:
  /// **'공지 해제'**
  String get post_unpinNotice;

  /// No description provided for @post_report.
  ///
  /// In ko, this message translates to:
  /// **'신고'**
  String get post_report;

  /// No description provided for @post_reportSelectReason.
  ///
  /// In ko, this message translates to:
  /// **'신고 사유 선택'**
  String get post_reportSelectReason;

  /// No description provided for @post_reportReasonSwearing.
  ///
  /// In ko, this message translates to:
  /// **'욕설/비방'**
  String get post_reportReasonSwearing;

  /// No description provided for @post_reportReasonAdult.
  ///
  /// In ko, this message translates to:
  /// **'음란물'**
  String get post_reportReasonAdult;

  /// No description provided for @post_reportReasonSpam.
  ///
  /// In ko, this message translates to:
  /// **'광고/스팸'**
  String get post_reportReasonSpam;

  /// No description provided for @post_reportReasonPrivacy.
  ///
  /// In ko, this message translates to:
  /// **'개인정보 노출'**
  String get post_reportReasonPrivacy;

  /// No description provided for @post_reportReasonOther.
  ///
  /// In ko, this message translates to:
  /// **'기타'**
  String get post_reportReasonOther;

  /// No description provided for @post_reportButton.
  ///
  /// In ko, this message translates to:
  /// **'신고'**
  String get post_reportButton;

  /// No description provided for @post_reportAlreadyReported.
  ///
  /// In ko, this message translates to:
  /// **'이미 신고한 게시글입니다'**
  String get post_reportAlreadyReported;

  /// No description provided for @post_reportSuccess.
  ///
  /// In ko, this message translates to:
  /// **'신고가 접수되었습니다'**
  String get post_reportSuccess;

  /// No description provided for @post_found.
  ///
  /// In ko, this message translates to:
  /// **'찾았어요'**
  String get post_found;

  /// No description provided for @post_resolvedLabel.
  ///
  /// In ko, this message translates to:
  /// **'해결됨'**
  String get post_resolvedLabel;

  /// No description provided for @post_comments.
  ///
  /// In ko, this message translates to:
  /// **'댓글 {count}'**
  String post_comments(Object count);

  /// No description provided for @post_firstComment.
  ///
  /// In ko, this message translates to:
  /// **'첫 댓글을 남겨보세요'**
  String get post_firstComment;

  /// No description provided for @post_replyTo.
  ///
  /// In ko, this message translates to:
  /// **'{name}에게 답글'**
  String post_replyTo(Object name);

  /// No description provided for @post_anonymous.
  ///
  /// In ko, this message translates to:
  /// **'익명'**
  String get post_anonymous;

  /// No description provided for @post_commentPlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'댓글을 입력하세요'**
  String get post_commentPlaceholder;

  /// No description provided for @post_confirmDeleteComment.
  ///
  /// In ko, this message translates to:
  /// **'댓글 삭제'**
  String get post_confirmDeleteComment;

  /// No description provided for @post_confirmDeleteCommentMessage.
  ///
  /// In ko, this message translates to:
  /// **'댓글을 삭제하시겠습니까?'**
  String get post_confirmDeleteCommentMessage;

  /// No description provided for @post_commentTooLong.
  ///
  /// In ko, this message translates to:
  /// **'댓글은 1000자 이내로 입력하세요'**
  String get post_commentTooLong;

  /// No description provided for @post_commentRateLimit.
  ///
  /// In ko, this message translates to:
  /// **'댓글은 10초에 한 번만 작성할 수 있습니다'**
  String get post_commentRateLimit;

  /// No description provided for @post_pinMaxed.
  ///
  /// In ko, this message translates to:
  /// **'공지는 최대 3개까지 가능합니다'**
  String get post_pinMaxed;

  /// No description provided for @post_pinSuccess.
  ///
  /// In ko, this message translates to:
  /// **'공지로 등록되었습니다'**
  String get post_pinSuccess;

  /// No description provided for @post_unpinSuccess.
  ///
  /// In ko, this message translates to:
  /// **'공지가 해제되었습니다'**
  String get post_unpinSuccess;

  /// No description provided for @post_eventAdded.
  ///
  /// In ko, this message translates to:
  /// **'{date} 일정에 추가되었습니다'**
  String post_eventAdded(Object date);

  /// No description provided for @post_deleteConfirm.
  ///
  /// In ko, this message translates to:
  /// **'게시글 삭제'**
  String get post_deleteConfirm;

  /// No description provided for @post_deleteConfirmMessage.
  ///
  /// In ko, this message translates to:
  /// **'정말 삭제하시겠습니까?'**
  String get post_deleteConfirmMessage;

  /// No description provided for @post_resolvedMarked.
  ///
  /// In ko, this message translates to:
  /// **'해결됨으로 표시되었습니다'**
  String get post_resolvedMarked;

  /// No description provided for @post_anonymousAuthor.
  ///
  /// In ko, this message translates to:
  /// **'익명(글쓴이)'**
  String get post_anonymousAuthor;

  /// No description provided for @post_anonymousNum.
  ///
  /// In ko, this message translates to:
  /// **'익명{num}'**
  String post_anonymousNum(Object num);

  /// No description provided for @post_authorBadge.
  ///
  /// In ko, this message translates to:
  /// **'글쓴이'**
  String get post_authorBadge;

  /// No description provided for @write_title.
  ///
  /// In ko, this message translates to:
  /// **'글쓰기'**
  String get write_title;

  /// No description provided for @write_editTitle.
  ///
  /// In ko, this message translates to:
  /// **'글 수정'**
  String get write_editTitle;

  /// No description provided for @write_draftSave.
  ///
  /// In ko, this message translates to:
  /// **'임시저장'**
  String get write_draftSave;

  /// No description provided for @write_draftSaved.
  ///
  /// In ko, this message translates to:
  /// **'임시저장되었습니다'**
  String get write_draftSaved;

  /// No description provided for @write_unsavedChanges.
  ///
  /// In ko, this message translates to:
  /// **'작성 중인 글이 있습니다'**
  String get write_unsavedChanges;

  /// No description provided for @write_draftDelete.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get write_draftDelete;

  /// No description provided for @write_category.
  ///
  /// In ko, this message translates to:
  /// **'카테고리'**
  String get write_category;

  /// No description provided for @write_titlePlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'제목을 입력하세요'**
  String get write_titlePlaceholder;

  /// No description provided for @write_contentPlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'내용을 입력하세요'**
  String get write_contentPlaceholder;

  /// No description provided for @write_eventAttach.
  ///
  /// In ko, this message translates to:
  /// **'일정 첨부'**
  String get write_eventAttach;

  /// No description provided for @write_pollAttach.
  ///
  /// In ko, this message translates to:
  /// **'투표 첨부'**
  String get write_pollAttach;

  /// No description provided for @write_anonymous.
  ///
  /// In ko, this message translates to:
  /// **'익명으로 작성'**
  String get write_anonymous;

  /// No description provided for @write_pinAsNotice.
  ///
  /// In ko, this message translates to:
  /// **'공지로 등록'**
  String get write_pinAsNotice;

  /// No description provided for @write_expiresInfo.
  ///
  /// In ko, this message translates to:
  /// **'작성한 글은 1년 후 자동 삭제됩니다'**
  String get write_expiresInfo;

  /// No description provided for @write_errorTitleRequired.
  ///
  /// In ko, this message translates to:
  /// **'제목을 입력하세요'**
  String get write_errorTitleRequired;

  /// No description provided for @write_errorTitleTooLong.
  ///
  /// In ko, this message translates to:
  /// **'제목은 200자 이내로 입력하세요'**
  String get write_errorTitleTooLong;

  /// No description provided for @write_errorContentRequired.
  ///
  /// In ko, this message translates to:
  /// **'내용을 입력하세요'**
  String get write_errorContentRequired;

  /// No description provided for @write_errorContentTooLong.
  ///
  /// In ko, this message translates to:
  /// **'내용은 5000자 이내로 입력하세요'**
  String get write_errorContentTooLong;

  /// No description provided for @write_errorPollOptionsRequired.
  ///
  /// In ko, this message translates to:
  /// **'투표 선택지를 2개 이상 입력하세요'**
  String get write_errorPollOptionsRequired;

  /// No description provided for @write_errorPollOptionTooLong.
  ///
  /// In ko, this message translates to:
  /// **'투표 선택지는 100자 이내로 입력하세요'**
  String get write_errorPollOptionTooLong;

  /// No description provided for @write_errorEventDateRequired.
  ///
  /// In ko, this message translates to:
  /// **'일정 날짜를 선택하세요'**
  String get write_errorEventDateRequired;

  /// No description provided for @write_errorEventContentRequired.
  ///
  /// In ko, this message translates to:
  /// **'일정 내용을 입력하세요'**
  String get write_errorEventContentRequired;

  /// No description provided for @write_errorEventContentTooLong.
  ///
  /// In ko, this message translates to:
  /// **'일정 내용은 200자 이내로 입력하세요'**
  String get write_errorEventContentTooLong;

  /// No description provided for @write_errorRateLimit.
  ///
  /// In ko, this message translates to:
  /// **'게시글은 30초에 한 번만 작성할 수 있습니다'**
  String get write_errorRateLimit;

  /// No description provided for @write_errorLoginRequired.
  ///
  /// In ko, this message translates to:
  /// **'로그인이 필요합니다'**
  String get write_errorLoginRequired;

  /// No description provided for @write_errorProfileLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'프로필 정보를 불러올 수 없습니다. 다시 시도해주세요.'**
  String get write_errorProfileLoadFailed;

  /// No description provided for @write_pinLimitExceeded.
  ///
  /// In ko, this message translates to:
  /// **'공지가 이미 3개입니다'**
  String get write_pinLimitExceeded;

  /// No description provided for @write_pinLimitMessage.
  ///
  /// In ko, this message translates to:
  /// **'기존 공지를 해제하거나, 이 글을 일반 글로 등록하세요.'**
  String get write_pinLimitMessage;

  /// No description provided for @write_pinUnpinAction.
  ///
  /// In ko, this message translates to:
  /// **'해제'**
  String get write_pinUnpinAction;

  /// No description provided for @write_unpinFailed.
  ///
  /// In ko, this message translates to:
  /// **'공지 해제 실패'**
  String get write_unpinFailed;

  /// No description provided for @write_registerWithoutPin.
  ///
  /// In ko, this message translates to:
  /// **'공지 없이 등록'**
  String get write_registerWithoutPin;

  /// No description provided for @write_noTitle.
  ///
  /// In ko, this message translates to:
  /// **'제목 없음'**
  String get write_noTitle;

  /// No description provided for @write_eventContentHint.
  ///
  /// In ko, this message translates to:
  /// **'일정 내용 (예: 중간고사, 체육대회)'**
  String get write_eventContentHint;

  /// No description provided for @write_eventSelectDate.
  ///
  /// In ko, this message translates to:
  /// **'날짜를 선택하세요'**
  String get write_eventSelectDate;

  /// No description provided for @write_eventStartTimeOptional.
  ///
  /// In ko, this message translates to:
  /// **'시작 (선택)'**
  String get write_eventStartTimeOptional;

  /// No description provided for @write_eventEndTimeOptional.
  ///
  /// In ko, this message translates to:
  /// **'종료 (선택)'**
  String get write_eventEndTimeOptional;

  /// No description provided for @write_pollOptionHint.
  ///
  /// In ko, this message translates to:
  /// **'선택지 {num}'**
  String write_pollOptionHint(Object num);

  /// No description provided for @write_pollAddOption.
  ///
  /// In ko, this message translates to:
  /// **'선택지 추가'**
  String get write_pollAddOption;

  /// No description provided for @write_imageAddButton.
  ///
  /// In ko, this message translates to:
  /// **'사진 추가 ({current}/{max})'**
  String write_imageAddButton(Object current, Object max);

  /// No description provided for @myActivity_title.
  ///
  /// In ko, this message translates to:
  /// **'내 활동'**
  String get myActivity_title;

  /// No description provided for @myActivity_myPosts.
  ///
  /// In ko, this message translates to:
  /// **'내가 쓴 글'**
  String get myActivity_myPosts;

  /// No description provided for @myActivity_myComments.
  ///
  /// In ko, this message translates to:
  /// **'내가 쓴 댓글'**
  String get myActivity_myComments;

  /// No description provided for @myActivity_savedPosts.
  ///
  /// In ko, this message translates to:
  /// **'저장한 글'**
  String get myActivity_savedPosts;

  /// No description provided for @myActivity_noPosts.
  ///
  /// In ko, this message translates to:
  /// **'작성한 글이 없습니다'**
  String get myActivity_noPosts;

  /// No description provided for @myActivity_noComments.
  ///
  /// In ko, this message translates to:
  /// **'작성한 댓글이 없습니다'**
  String get myActivity_noComments;

  /// No description provided for @bookmarks_title.
  ///
  /// In ko, this message translates to:
  /// **'저장한 글'**
  String get bookmarks_title;

  /// No description provided for @bookmarks_empty.
  ///
  /// In ko, this message translates to:
  /// **'저장한 글이 없습니다'**
  String get bookmarks_empty;

  /// No description provided for @bookmarks_emptyHelper.
  ///
  /// In ko, this message translates to:
  /// **'게시글에서 북마크 아이콘을 눌러 저장하세요'**
  String get bookmarks_emptyHelper;

  /// No description provided for @notification_title.
  ///
  /// In ko, this message translates to:
  /// **'알림'**
  String get notification_title;

  /// No description provided for @notification_markAllRead.
  ///
  /// In ko, this message translates to:
  /// **'모두 읽음'**
  String get notification_markAllRead;

  /// No description provided for @notification_empty.
  ///
  /// In ko, this message translates to:
  /// **'알림이 없습니다'**
  String get notification_empty;

  /// No description provided for @notification_typeComment.
  ///
  /// In ko, this message translates to:
  /// **'{name}님이 댓글을 남겼습니다'**
  String notification_typeComment(Object name);

  /// No description provided for @notification_typeReply.
  ///
  /// In ko, this message translates to:
  /// **'{name}님이 답글을 남겼습니다'**
  String notification_typeReply(Object name);

  /// No description provided for @admin_title.
  ///
  /// In ko, this message translates to:
  /// **'Admin'**
  String get admin_title;

  /// No description provided for @admin_userManagement.
  ///
  /// In ko, this message translates to:
  /// **'사용자 관리'**
  String get admin_userManagement;

  /// No description provided for @admin_usersPending.
  ///
  /// In ko, this message translates to:
  /// **'승인 대기'**
  String get admin_usersPending;

  /// No description provided for @admin_usersSuspended.
  ///
  /// In ko, this message translates to:
  /// **'정지된 사용자'**
  String get admin_usersSuspended;

  /// No description provided for @admin_usersApproved.
  ///
  /// In ko, this message translates to:
  /// **'일반 사용자'**
  String get admin_usersApproved;

  /// No description provided for @admin_boardManagement.
  ///
  /// In ko, this message translates to:
  /// **'게시판 관리'**
  String get admin_boardManagement;

  /// No description provided for @admin_reportsTab.
  ///
  /// In ko, this message translates to:
  /// **'신고'**
  String get admin_reportsTab;

  /// No description provided for @admin_deleteLogs.
  ///
  /// In ko, this message translates to:
  /// **'삭제 로그'**
  String get admin_deleteLogs;

  /// No description provided for @admin_feedback.
  ///
  /// In ko, this message translates to:
  /// **'건의사항'**
  String get admin_feedback;

  /// No description provided for @admin_feedbackCouncil.
  ///
  /// In ko, this message translates to:
  /// **'학생회 건의'**
  String get admin_feedbackCouncil;

  /// No description provided for @admin_feedbackApp.
  ///
  /// In ko, this message translates to:
  /// **'앱 건의/버그'**
  String get admin_feedbackApp;

  /// No description provided for @admin_emergencyNotice.
  ///
  /// In ko, this message translates to:
  /// **'긴급 공지'**
  String get admin_emergencyNotice;

  /// No description provided for @admin_usersNoPending.
  ///
  /// In ko, this message translates to:
  /// **'대기 중인 사용자가 없습니다'**
  String get admin_usersNoPending;

  /// No description provided for @admin_usersNoApproved.
  ///
  /// In ko, this message translates to:
  /// **'승인된 사용자가 없습니다'**
  String get admin_usersNoApproved;

  /// No description provided for @admin_usersNoSuspended.
  ///
  /// In ko, this message translates to:
  /// **'정지된 사용자가 없습니다'**
  String get admin_usersNoSuspended;

  /// No description provided for @admin_usersApprove.
  ///
  /// In ko, this message translates to:
  /// **'승인'**
  String get admin_usersApprove;

  /// No description provided for @admin_usersReject.
  ///
  /// In ko, this message translates to:
  /// **'거절'**
  String get admin_usersReject;

  /// No description provided for @admin_usersRemoveAdmin.
  ///
  /// In ko, this message translates to:
  /// **'Admin 해제'**
  String get admin_usersRemoveAdmin;

  /// No description provided for @admin_usersMakeManager.
  ///
  /// In ko, this message translates to:
  /// **'매니저'**
  String get admin_usersMakeManager;

  /// No description provided for @admin_usersRemoveManager.
  ///
  /// In ko, this message translates to:
  /// **'매니저 해제'**
  String get admin_usersRemoveManager;

  /// No description provided for @admin_usersMakeAdmin.
  ///
  /// In ko, this message translates to:
  /// **'Admin'**
  String get admin_usersMakeAdmin;

  /// No description provided for @admin_usersSuspend.
  ///
  /// In ko, this message translates to:
  /// **'정지'**
  String get admin_usersSuspend;

  /// No description provided for @admin_usersDelete.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get admin_usersDelete;

  /// No description provided for @admin_usersUnsuspend.
  ///
  /// In ko, this message translates to:
  /// **'정지 해제'**
  String get admin_usersUnsuspend;

  /// No description provided for @admin_usersSuspendTitle.
  ///
  /// In ko, this message translates to:
  /// **'{name} 정지'**
  String admin_usersSuspendTitle(Object name);

  /// No description provided for @admin_usersSuspendSelectDuration.
  ///
  /// In ko, this message translates to:
  /// **'정지 기간을 선택하세요'**
  String get admin_usersSuspendSelectDuration;

  /// No description provided for @admin_usersSuspend1Hour.
  ///
  /// In ko, this message translates to:
  /// **'1시간'**
  String get admin_usersSuspend1Hour;

  /// No description provided for @admin_usersSuspend6Hours.
  ///
  /// In ko, this message translates to:
  /// **'6시간'**
  String get admin_usersSuspend6Hours;

  /// No description provided for @admin_usersSuspend12Hours.
  ///
  /// In ko, this message translates to:
  /// **'12시간'**
  String get admin_usersSuspend12Hours;

  /// No description provided for @admin_usersSuspend1Day.
  ///
  /// In ko, this message translates to:
  /// **'1일'**
  String get admin_usersSuspend1Day;

  /// No description provided for @admin_usersSuspend3Days.
  ///
  /// In ko, this message translates to:
  /// **'3일'**
  String get admin_usersSuspend3Days;

  /// No description provided for @admin_usersSuspend7Days.
  ///
  /// In ko, this message translates to:
  /// **'7일'**
  String get admin_usersSuspend7Days;

  /// No description provided for @admin_usersSuspend30Days.
  ///
  /// In ko, this message translates to:
  /// **'30일'**
  String get admin_usersSuspend30Days;

  /// No description provided for @admin_usersSuspendHours.
  ///
  /// In ko, this message translates to:
  /// **'{hours}시간'**
  String admin_usersSuspendHours(Object hours);

  /// No description provided for @admin_usersSuspendDays.
  ///
  /// In ko, this message translates to:
  /// **'{days}일'**
  String admin_usersSuspendDays(Object days);

  /// No description provided for @admin_usersDeleteConfirm.
  ///
  /// In ko, this message translates to:
  /// **'계정 삭제'**
  String get admin_usersDeleteConfirm;

  /// No description provided for @admin_usersDeleteConfirmMessage.
  ///
  /// In ko, this message translates to:
  /// **'{name} 계정을 삭제하시겠습니까?'**
  String admin_usersDeleteConfirmMessage(Object name);

  /// No description provided for @admin_usersDeleteFinal.
  ///
  /// In ko, this message translates to:
  /// **'최종 확인'**
  String get admin_usersDeleteFinal;

  /// No description provided for @admin_usersDeleteFinalMessage.
  ///
  /// In ko, this message translates to:
  /// **'{name} 계정을 정말 삭제합니까?\n되돌릴 수 없습니다.'**
  String admin_usersDeleteFinalMessage(Object name);

  /// No description provided for @admin_usersSuspendedRemaining.
  ///
  /// In ko, this message translates to:
  /// **'남은 기간: {duration}'**
  String admin_usersSuspendedRemaining(Object duration);

  /// No description provided for @admin_usersMinutesLeft.
  ///
  /// In ko, this message translates to:
  /// **'{minutes}분'**
  String admin_usersMinutesLeft(Object minutes);

  /// No description provided for @admin_usersHoursLeft.
  ///
  /// In ko, this message translates to:
  /// **'{hours}시간'**
  String admin_usersHoursLeft(Object hours);

  /// No description provided for @admin_usersDaysLeft.
  ///
  /// In ko, this message translates to:
  /// **'{days}일'**
  String admin_usersDaysLeft(Object days);

  /// No description provided for @admin_usersLessThan1Minute.
  ///
  /// In ko, this message translates to:
  /// **'1분 미만'**
  String get admin_usersLessThan1Minute;

  /// No description provided for @admin_usersAccountApproved.
  ///
  /// In ko, this message translates to:
  /// **'가입 승인'**
  String get admin_usersAccountApproved;

  /// No description provided for @admin_usersApprovedMessage.
  ///
  /// In ko, this message translates to:
  /// **'가입이 승인되었습니다.'**
  String get admin_usersApprovedMessage;

  /// No description provided for @admin_usersAccountRejected.
  ///
  /// In ko, this message translates to:
  /// **'가입 거절'**
  String get admin_usersAccountRejected;

  /// No description provided for @admin_usersRejectedMessage.
  ///
  /// In ko, this message translates to:
  /// **'가입이 거절되었습니다.'**
  String get admin_usersRejectedMessage;

  /// No description provided for @admin_usersAccountSuspended.
  ///
  /// In ko, this message translates to:
  /// **'계정 정지'**
  String get admin_usersAccountSuspended;

  /// No description provided for @admin_usersSuspendedMessage.
  ///
  /// In ko, this message translates to:
  /// **'{duration} 동안 계정이 정지되었습니다.'**
  String admin_usersSuspendedMessage(Object duration);

  /// No description provided for @admin_usersAccountDeleted.
  ///
  /// In ko, this message translates to:
  /// **'계정 삭제'**
  String get admin_usersAccountDeleted;

  /// No description provided for @admin_usersDeletedMessage.
  ///
  /// In ko, this message translates to:
  /// **'관리자에 의해 계정이 삭제되었습니다.'**
  String get admin_usersDeletedMessage;

  /// No description provided for @admin_usersSuspendRemoved.
  ///
  /// In ko, this message translates to:
  /// **'정지 해제'**
  String get admin_usersSuspendRemoved;

  /// No description provided for @admin_usersSuspendRemovedMessage.
  ///
  /// In ko, this message translates to:
  /// **'계정 정지가 해제되었습니다.'**
  String get admin_usersSuspendRemovedMessage;

  /// No description provided for @admin_reportsEmpty.
  ///
  /// In ko, this message translates to:
  /// **'신고가 없습니다'**
  String get admin_reportsEmpty;

  /// No description provided for @admin_reportsViewPost.
  ///
  /// In ko, this message translates to:
  /// **'글 보기'**
  String get admin_reportsViewPost;

  /// No description provided for @admin_reportsDeletePost.
  ///
  /// In ko, this message translates to:
  /// **'글 삭제'**
  String get admin_reportsDeletePost;

  /// No description provided for @admin_reportsIgnore.
  ///
  /// In ko, this message translates to:
  /// **'무시'**
  String get admin_reportsIgnore;

  /// No description provided for @admin_logsEmpty.
  ///
  /// In ko, this message translates to:
  /// **'삭제 로그가 없습니다'**
  String get admin_logsEmpty;

  /// No description provided for @admin_logsFeedbackDeleted.
  ///
  /// In ko, this message translates to:
  /// **'건의 삭제'**
  String get admin_logsFeedbackDeleted;

  /// No description provided for @admin_logsPostDeleted.
  ///
  /// In ko, this message translates to:
  /// **'게시글 삭제'**
  String get admin_logsPostDeleted;

  /// No description provided for @admin_logsAuthor.
  ///
  /// In ko, this message translates to:
  /// **'작성자: {name}'**
  String admin_logsAuthor(Object name);

  /// No description provided for @admin_logsDeletedBy.
  ///
  /// In ko, this message translates to:
  /// **'삭제: {name}'**
  String admin_logsDeletedBy(Object name);

  /// No description provided for @admin_logsNoTitle.
  ///
  /// In ko, this message translates to:
  /// **'제목 없음'**
  String get admin_logsNoTitle;

  /// No description provided for @admin_logsNoContent.
  ///
  /// In ko, this message translates to:
  /// **'내용 없음'**
  String get admin_logsNoContent;

  /// No description provided for @admin_logsUnknown.
  ///
  /// In ko, this message translates to:
  /// **'알 수 없음'**
  String get admin_logsUnknown;

  /// No description provided for @admin_popupActivate.
  ///
  /// In ko, this message translates to:
  /// **'팝업 활성화'**
  String get admin_popupActivate;

  /// No description provided for @admin_popupTypeEmergency.
  ///
  /// In ko, this message translates to:
  /// **'긴급'**
  String get admin_popupTypeEmergency;

  /// No description provided for @admin_popupTypeNotice.
  ///
  /// In ko, this message translates to:
  /// **'공지'**
  String get admin_popupTypeNotice;

  /// No description provided for @admin_popupTypeEvent.
  ///
  /// In ko, this message translates to:
  /// **'이벤트'**
  String get admin_popupTypeEvent;

  /// No description provided for @admin_popupTitle.
  ///
  /// In ko, this message translates to:
  /// **'제목'**
  String get admin_popupTitle;

  /// No description provided for @admin_popupContent.
  ///
  /// In ko, this message translates to:
  /// **'내용'**
  String get admin_popupContent;

  /// No description provided for @admin_popupStartDate.
  ///
  /// In ko, this message translates to:
  /// **'시작일'**
  String get admin_popupStartDate;

  /// No description provided for @admin_popupEndDate.
  ///
  /// In ko, this message translates to:
  /// **'종료일'**
  String get admin_popupEndDate;

  /// No description provided for @admin_popupDismissible.
  ///
  /// In ko, this message translates to:
  /// **'\"오늘 안 보기\" 허용'**
  String get admin_popupDismissible;

  /// No description provided for @admin_popupSave.
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get admin_popupSave;

  /// No description provided for @admin_popupSaved.
  ///
  /// In ko, this message translates to:
  /// **'저장되었습니다'**
  String get admin_popupSaved;

  /// No description provided for @event_cardTitle.
  ///
  /// In ko, this message translates to:
  /// **'일정 공유'**
  String get event_cardTitle;

  /// No description provided for @event_cardAddButton.
  ///
  /// In ko, this message translates to:
  /// **'내 일정에 추가'**
  String get event_cardAddButton;

  /// No description provided for @event_am.
  ///
  /// In ko, this message translates to:
  /// **'오전'**
  String get event_am;

  /// No description provided for @event_pm.
  ///
  /// In ko, this message translates to:
  /// **'오후'**
  String get event_pm;

  /// No description provided for @poll_cardTitle.
  ///
  /// In ko, this message translates to:
  /// **'투표'**
  String get poll_cardTitle;

  /// No description provided for @poll_cardParticipants.
  ///
  /// In ko, this message translates to:
  /// **'{count}명 참여'**
  String poll_cardParticipants(Object count);

  /// No description provided for @grade_screenTitle.
  ///
  /// In ko, this message translates to:
  /// **'성적 관리'**
  String get grade_screenTitle;

  /// No description provided for @grade_deleteTitle.
  ///
  /// In ko, this message translates to:
  /// **'시험 삭제'**
  String get grade_deleteTitle;

  /// No description provided for @grade_deleteMsg.
  ///
  /// In ko, this message translates to:
  /// **'{examName}을(를) 삭제하시겠습니까?'**
  String grade_deleteMsg(Object examName);

  /// No description provided for @grade_noDataMsg.
  ///
  /// In ko, this message translates to:
  /// **'시험 데이터가 없습니다'**
  String get grade_noDataMsg;

  /// No description provided for @grade_targetTitle.
  ///
  /// In ko, this message translates to:
  /// **'과목별 목표 백분위'**
  String get grade_targetTitle;

  /// No description provided for @grade_targetGradeTitle.
  ///
  /// In ko, this message translates to:
  /// **'과목별 목표 등급'**
  String get grade_targetGradeTitle;

  /// No description provided for @grade_notice.
  ///
  /// In ko, this message translates to:
  /// **'성적 점수는 서버에 저장되지 않습니다'**
  String get grade_notice;

  /// No description provided for @grade_sujungTab.
  ///
  /// In ko, this message translates to:
  /// **'수시'**
  String get grade_sujungTab;

  /// No description provided for @grade_jeongsiTab.
  ///
  /// In ko, this message translates to:
  /// **'정시'**
  String get grade_jeongsiTab;

  /// No description provided for @grade_loadFailed.
  ///
  /// In ko, this message translates to:
  /// **'불러오기 실패: {error}'**
  String grade_loadFailed(Object error);

  /// No description provided for @grade_addPrompt.
  ///
  /// In ko, this message translates to:
  /// **'시험을 추가하세요'**
  String get grade_addPrompt;

  /// No description provided for @grade_averageLabel.
  ///
  /// In ko, this message translates to:
  /// **'평균'**
  String get grade_averageLabel;

  /// No description provided for @grade_averageRank.
  ///
  /// In ko, this message translates to:
  /// **'평균 {rank}등급'**
  String grade_averageRank(Object rank);

  /// No description provided for @grade_classSetting.
  ///
  /// In ko, this message translates to:
  /// **'학년 · 반 설정'**
  String get grade_classSetting;

  /// No description provided for @grade_grade.
  ///
  /// In ko, this message translates to:
  /// **'학년'**
  String get grade_grade;

  /// No description provided for @grade_class.
  ///
  /// In ko, this message translates to:
  /// **'반'**
  String get grade_class;

  /// No description provided for @grade_percentile.
  ///
  /// In ko, this message translates to:
  /// **'백분위'**
  String get grade_percentile;

  /// No description provided for @grade_standardScore.
  ///
  /// In ko, this message translates to:
  /// **'표준점수'**
  String get grade_standardScore;

  /// No description provided for @grade_rawScore.
  ///
  /// In ko, this message translates to:
  /// **'원점수'**
  String get grade_rawScore;

  /// No description provided for @grade_rank.
  ///
  /// In ko, this message translates to:
  /// **'등급'**
  String get grade_rank;

  /// No description provided for @grade_noData.
  ///
  /// In ko, this message translates to:
  /// **'데이터가 없습니다'**
  String get grade_noData;

  /// No description provided for @grade_scoreNoData.
  ///
  /// In ko, this message translates to:
  /// **'점수 데이터가 없습니다'**
  String get grade_scoreNoData;

  /// No description provided for @grade_goalGrade.
  ///
  /// In ko, this message translates to:
  /// **'목표 등급'**
  String get grade_goalGrade;

  /// No description provided for @gradeInput_screenTitle.
  ///
  /// In ko, this message translates to:
  /// **'시험 추가'**
  String get gradeInput_screenTitle;

  /// No description provided for @gradeInput_screenEdit.
  ///
  /// In ko, this message translates to:
  /// **'시험 수정'**
  String get gradeInput_screenEdit;

  /// No description provided for @gradeInput_typeSection.
  ///
  /// In ko, this message translates to:
  /// **'시험 유형'**
  String get gradeInput_typeSection;

  /// No description provided for @gradeInput_infoSection.
  ///
  /// In ko, this message translates to:
  /// **'시험 정보'**
  String get gradeInput_infoSection;

  /// No description provided for @gradeInput_year.
  ///
  /// In ko, this message translates to:
  /// **'연도'**
  String get gradeInput_year;

  /// No description provided for @gradeInput_semester.
  ///
  /// In ko, this message translates to:
  /// **'학기'**
  String get gradeInput_semester;

  /// No description provided for @gradeInput_grade.
  ///
  /// In ko, this message translates to:
  /// **'학년'**
  String get gradeInput_grade;

  /// No description provided for @gradeInput_month.
  ///
  /// In ko, this message translates to:
  /// **'시행월'**
  String get gradeInput_month;

  /// No description provided for @gradeInput_privateLabel.
  ///
  /// In ko, this message translates to:
  /// **'사설모의 이름'**
  String get gradeInput_privateLabel;

  /// No description provided for @gradeInput_subjectSection.
  ///
  /// In ko, this message translates to:
  /// **'과목 및 점수'**
  String get gradeInput_subjectSection;

  /// No description provided for @gradeInput_fromTimetable.
  ///
  /// In ko, this message translates to:
  /// **'시간표에서 선택'**
  String get gradeInput_fromTimetable;

  /// No description provided for @gradeInput_mockSubjects.
  ///
  /// In ko, this message translates to:
  /// **'모의고사 과목 선택'**
  String get gradeInput_mockSubjects;

  /// No description provided for @gradeInput_addManual.
  ///
  /// In ko, this message translates to:
  /// **'직접 추가'**
  String get gradeInput_addManual;

  /// No description provided for @gradeInput_noSubjects.
  ///
  /// In ko, this message translates to:
  /// **'위 버튼으로 과목을 추가해주세요'**
  String get gradeInput_noSubjects;

  /// No description provided for @gradeInput_subjectCol.
  ///
  /// In ko, this message translates to:
  /// **'과목'**
  String get gradeInput_subjectCol;

  /// No description provided for @gradeInput_rawScore.
  ///
  /// In ko, this message translates to:
  /// **'원점수'**
  String get gradeInput_rawScore;

  /// No description provided for @gradeInput_average.
  ///
  /// In ko, this message translates to:
  /// **'평균'**
  String get gradeInput_average;

  /// No description provided for @gradeInput_rank.
  ///
  /// In ko, this message translates to:
  /// **'등급'**
  String get gradeInput_rank;

  /// No description provided for @gradeInput_achievement.
  ///
  /// In ko, this message translates to:
  /// **'성취도'**
  String get gradeInput_achievement;

  /// No description provided for @gradeInput_percentile.
  ///
  /// In ko, this message translates to:
  /// **'백분위'**
  String get gradeInput_percentile;

  /// No description provided for @gradeInput_standard.
  ///
  /// In ko, this message translates to:
  /// **'표준'**
  String get gradeInput_standard;

  /// No description provided for @gradeInput_selectSubjects.
  ///
  /// In ko, this message translates to:
  /// **'시간표 과목 선택'**
  String get gradeInput_selectSubjects;

  /// No description provided for @gradeInput_mockSubjectPicker.
  ///
  /// In ko, this message translates to:
  /// **'모의고사 과목 선택'**
  String get gradeInput_mockSubjectPicker;

  /// No description provided for @gradeInput_noTimetable.
  ///
  /// In ko, this message translates to:
  /// **'저장된 시간표가 없습니다. 시간표를 먼저 설정해주세요.'**
  String get gradeInput_noTimetable;

  /// No description provided for @gradeInput_allSubjectsAdded.
  ///
  /// In ko, this message translates to:
  /// **'시간표의 모든 과목이 이미 추가되어 있습니다.'**
  String get gradeInput_allSubjectsAdded;

  /// No description provided for @gradeInput_allMockAdded.
  ///
  /// In ko, this message translates to:
  /// **'모든 과목이 이미 추가되어 있습니다.'**
  String get gradeInput_allMockAdded;

  /// No description provided for @gradeInput_addSubject.
  ///
  /// In ko, this message translates to:
  /// **'과목 추가'**
  String get gradeInput_addSubject;

  /// No description provided for @gradeInput_subjectName.
  ///
  /// In ko, this message translates to:
  /// **'과목명 입력'**
  String get gradeInput_subjectName;

  /// No description provided for @gradeInput_addSubjectDuplicate.
  ///
  /// In ko, this message translates to:
  /// **'\'{name}\' 과목이 이미 추가되어 있습니다.'**
  String gradeInput_addSubjectDuplicate(Object name);

  /// No description provided for @gradeInput_addMinSubjects.
  ///
  /// In ko, this message translates to:
  /// **'과목을 1개 이상 추가해주세요.'**
  String get gradeInput_addMinSubjects;

  /// No description provided for @gradeInput_privateNameRequired.
  ///
  /// In ko, this message translates to:
  /// **'사설모의 이름을 입력해주세요.'**
  String get gradeInput_privateNameRequired;

  /// No description provided for @gradeInput_hintScore.
  ///
  /// In ko, this message translates to:
  /// **'0~100'**
  String get gradeInput_hintScore;

  /// No description provided for @gradeInput_typeMidterm.
  ///
  /// In ko, this message translates to:
  /// **'중간고사'**
  String get gradeInput_typeMidterm;

  /// No description provided for @gradeInput_typeFinal.
  ///
  /// In ko, this message translates to:
  /// **'기말고사'**
  String get gradeInput_typeFinal;

  /// No description provided for @gradeInput_typeMock.
  ///
  /// In ko, this message translates to:
  /// **'모의고사'**
  String get gradeInput_typeMock;

  /// No description provided for @gradeInput_typePrivateMock.
  ///
  /// In ko, this message translates to:
  /// **'사설모의'**
  String get gradeInput_typePrivateMock;

  /// No description provided for @gradeInput_monthMar.
  ///
  /// In ko, this message translates to:
  /// **'3월'**
  String get gradeInput_monthMar;

  /// No description provided for @gradeInput_monthJun.
  ///
  /// In ko, this message translates to:
  /// **'6월'**
  String get gradeInput_monthJun;

  /// No description provided for @gradeInput_monthSep.
  ///
  /// In ko, this message translates to:
  /// **'9월'**
  String get gradeInput_monthSep;

  /// No description provided for @gradeInput_monthNov.
  ///
  /// In ko, this message translates to:
  /// **'11월'**
  String get gradeInput_monthNov;

  /// No description provided for @gradeInput_privateHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 메가스터디 3회'**
  String get gradeInput_privateHint;

  /// No description provided for @gradeInput_yearSuffix.
  ///
  /// In ko, this message translates to:
  /// **'{year}년'**
  String gradeInput_yearSuffix(Object year);

  /// No description provided for @gradeInput_semesterSuffix.
  ///
  /// In ko, this message translates to:
  /// **'{semester}학기'**
  String gradeInput_semesterSuffix(Object semester);

  /// No description provided for @gradeInput_gradeSuffix.
  ///
  /// In ko, this message translates to:
  /// **'{grade}학년'**
  String gradeInput_gradeSuffix(Object grade);

  /// No description provided for @gradeInput_mockMonthSuffix.
  ///
  /// In ko, this message translates to:
  /// **'{month} 모의고사'**
  String gradeInput_mockMonthSuffix(Object month);

  /// No description provided for @timetable_screenTitle.
  ///
  /// In ko, this message translates to:
  /// **'시간표'**
  String get timetable_screenTitle;

  /// No description provided for @timetable_teacherScreenTitle.
  ///
  /// In ko, this message translates to:
  /// **'내 수업 시간표'**
  String get timetable_teacherScreenTitle;

  /// No description provided for @timetable_classTitle.
  ///
  /// In ko, this message translates to:
  /// **'{grade}학년 {classNum}반 시간표'**
  String timetable_classTitle(Object grade, Object classNum);

  /// No description provided for @timetable_setting.
  ///
  /// In ko, this message translates to:
  /// **'수업 설정'**
  String get timetable_setting;

  /// No description provided for @timetable_changeClass.
  ///
  /// In ko, this message translates to:
  /// **'반 변경'**
  String get timetable_changeClass;

  /// No description provided for @timetable_refresh.
  ///
  /// In ko, this message translates to:
  /// **'새로고침'**
  String get timetable_refresh;

  /// No description provided for @timetable_loadError.
  ///
  /// In ko, this message translates to:
  /// **'시간표를 불러올 수 없습니다'**
  String get timetable_loadError;

  /// No description provided for @timetable_setTeachingMsg.
  ///
  /// In ko, this message translates to:
  /// **'수업을 설정하면 시간표가 표시됩니다'**
  String get timetable_setTeachingMsg;

  /// No description provided for @timetable_setSetting.
  ///
  /// In ko, this message translates to:
  /// **'수업 설정'**
  String get timetable_setSetting;

  /// No description provided for @timetable_setGradeMsg.
  ///
  /// In ko, this message translates to:
  /// **'학년/반을 먼저 설정해주세요'**
  String get timetable_setGradeMsg;

  /// No description provided for @timetable_setGrade.
  ///
  /// In ko, this message translates to:
  /// **'학년/반 설정'**
  String get timetable_setGrade;

  /// No description provided for @timetable_set1stMsg.
  ///
  /// In ko, this message translates to:
  /// **'학년/반을 설정하면 시간표가 표시됩니다'**
  String get timetable_set1stMsg;

  /// No description provided for @timetable_setSubjectMsg.
  ///
  /// In ko, this message translates to:
  /// **'선택과목을 설정하면 시간표가 표시됩니다'**
  String get timetable_setSubjectMsg;

  /// No description provided for @timetable_setSubject.
  ///
  /// In ko, this message translates to:
  /// **'선택과목 설정'**
  String get timetable_setSubject;

  /// No description provided for @timetable_dayMon.
  ///
  /// In ko, this message translates to:
  /// **'월'**
  String get timetable_dayMon;

  /// No description provided for @timetable_dayTue.
  ///
  /// In ko, this message translates to:
  /// **'화'**
  String get timetable_dayTue;

  /// No description provided for @timetable_dayWed.
  ///
  /// In ko, this message translates to:
  /// **'수'**
  String get timetable_dayWed;

  /// No description provided for @timetable_dayThu.
  ///
  /// In ko, this message translates to:
  /// **'목'**
  String get timetable_dayThu;

  /// No description provided for @timetable_dayFri.
  ///
  /// In ko, this message translates to:
  /// **'금'**
  String get timetable_dayFri;

  /// No description provided for @timetable_selectTitle.
  ///
  /// In ko, this message translates to:
  /// **'선택과목 설정'**
  String get timetable_selectTitle;

  /// No description provided for @timetable_selectAlert.
  ///
  /// In ko, this message translates to:
  /// **'변경사항이 있습니다'**
  String get timetable_selectAlert;

  /// No description provided for @timetable_selectDiscardMsg.
  ///
  /// In ko, this message translates to:
  /// **'저장하지 않고 나가시겠습니까?'**
  String get timetable_selectDiscardMsg;

  /// No description provided for @timetable_selectLeave.
  ///
  /// In ko, this message translates to:
  /// **'나가기'**
  String get timetable_selectLeave;

  /// No description provided for @timetable_selectSaved.
  ///
  /// In ko, this message translates to:
  /// **'저장되었습니다'**
  String get timetable_selectSaved;

  /// No description provided for @timetable_selectCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}개 과목 선택됨'**
  String timetable_selectCount(Object count);

  /// No description provided for @timetable_selectLoadError.
  ///
  /// In ko, this message translates to:
  /// **'과목을 불러올 수 없습니다'**
  String get timetable_selectLoadError;

  /// No description provided for @timetable_selectConflict.
  ///
  /// In ko, this message translates to:
  /// **'{day} {period}교시에 {subject}과(와) 겹침'**
  String timetable_selectConflict(Object day, Object period, Object subject);

  /// No description provided for @timetable_selectSpecial.
  ///
  /// In ko, this message translates to:
  /// **'특별실'**
  String get timetable_selectSpecial;

  /// No description provided for @timetable_selectClass.
  ///
  /// In ko, this message translates to:
  /// **'{classNum}반'**
  String timetable_selectClass(Object classNum);

  /// No description provided for @timetable_selectPeriod.
  ///
  /// In ko, this message translates to:
  /// **'{day} {period}교시'**
  String timetable_selectPeriod(Object day, Object period);

  /// No description provided for @timetable_teacherSelectTitle.
  ///
  /// In ko, this message translates to:
  /// **'수업 시간표 설정'**
  String get timetable_teacherSelectTitle;

  /// No description provided for @timetable_teacherTab1.
  ///
  /// In ko, this message translates to:
  /// **'1학년'**
  String get timetable_teacherTab1;

  /// No description provided for @timetable_teacherTab2.
  ///
  /// In ko, this message translates to:
  /// **'2학년'**
  String get timetable_teacherTab2;

  /// No description provided for @timetable_teacherTab3.
  ///
  /// In ko, this message translates to:
  /// **'3학년'**
  String get timetable_teacherTab3;

  /// No description provided for @timetable_teacherAlert.
  ///
  /// In ko, this message translates to:
  /// **'변경사항이 있습니다'**
  String get timetable_teacherAlert;

  /// No description provided for @timetable_teacherDiscardMsg.
  ///
  /// In ko, this message translates to:
  /// **'저장하지 않고 나가시겠습니까?'**
  String get timetable_teacherDiscardMsg;

  /// No description provided for @timetable_teacherLeave.
  ///
  /// In ko, this message translates to:
  /// **'나가기'**
  String get timetable_teacherLeave;

  /// No description provided for @timetable_teacherSaved.
  ///
  /// In ko, this message translates to:
  /// **'저장되었습니다'**
  String get timetable_teacherSaved;

  /// No description provided for @timetable_teacherCount.
  ///
  /// In ko, this message translates to:
  /// **'총 {count}개 수업 선택됨'**
  String timetable_teacherCount(Object count);

  /// No description provided for @timetable_teacherLoadError.
  ///
  /// In ko, this message translates to:
  /// **'과목을 불러올 수 없습니다'**
  String get timetable_teacherLoadError;

  /// No description provided for @timetable_teacherSpecial.
  ///
  /// In ko, this message translates to:
  /// **'특별실'**
  String get timetable_teacherSpecial;

  /// No description provided for @timetable_teacherClass.
  ///
  /// In ko, this message translates to:
  /// **'{classNum}반'**
  String timetable_teacherClass(Object classNum);

  /// No description provided for @timetable_conflictTitle.
  ///
  /// In ko, this message translates to:
  /// **'{day}요일 {period}교시'**
  String timetable_conflictTitle(Object day, Object period);

  /// No description provided for @timetable_conflictQuestion.
  ///
  /// In ko, this message translates to:
  /// **'어떤 과목을 듣나요?'**
  String get timetable_conflictQuestion;

  /// No description provided for @timetable_colorPickerReset.
  ///
  /// In ko, this message translates to:
  /// **'기본 색상으로 초기화'**
  String get timetable_colorPickerReset;

  /// No description provided for @dday_screenTitle.
  ///
  /// In ko, this message translates to:
  /// **'D-day 관리'**
  String get dday_screenTitle;

  /// No description provided for @dday_addTitle.
  ///
  /// In ko, this message translates to:
  /// **'D-day 추가'**
  String get dday_addTitle;

  /// No description provided for @dday_hint.
  ///
  /// In ko, this message translates to:
  /// **'예: 중간고사, 수행평가'**
  String get dday_hint;

  /// No description provided for @dday_selectDate.
  ///
  /// In ko, this message translates to:
  /// **'날짜를 선택하세요'**
  String get dday_selectDate;

  /// No description provided for @dday_addButton.
  ///
  /// In ko, this message translates to:
  /// **'추가'**
  String get dday_addButton;

  /// No description provided for @dday_empty.
  ///
  /// In ko, this message translates to:
  /// **'D-day를 추가해보세요'**
  String get dday_empty;

  /// No description provided for @dday_upcoming.
  ///
  /// In ko, this message translates to:
  /// **'예정된 일정'**
  String get dday_upcoming;

  /// No description provided for @dday_today.
  ///
  /// In ko, this message translates to:
  /// **'오늘'**
  String get dday_today;

  /// No description provided for @dday_daysPrefix.
  ///
  /// In ko, this message translates to:
  /// **'D-{days}'**
  String dday_daysPrefix(Object days);

  /// No description provided for @dday_daysPastPrefix.
  ///
  /// In ko, this message translates to:
  /// **'D+{days}'**
  String dday_daysPastPrefix(Object days);

  /// No description provided for @dday_dday.
  ///
  /// In ko, this message translates to:
  /// **'D-Day'**
  String get dday_dday;

  /// No description provided for @dday_school.
  ///
  /// In ko, this message translates to:
  /// **'학사'**
  String get dday_school;

  /// No description provided for @dday_added.
  ///
  /// In ko, this message translates to:
  /// **'{title}이(가) D-day에 추가되었습니다'**
  String dday_added(Object title);

  /// No description provided for @feedback_appTitle.
  ///
  /// In ko, this message translates to:
  /// **'앱 건의사항 & 버그 제보'**
  String get feedback_appTitle;

  /// No description provided for @feedback_councilTitle.
  ///
  /// In ko, this message translates to:
  /// **'학생회 건의사항'**
  String get feedback_councilTitle;

  /// No description provided for @feedback_appHint.
  ///
  /// In ko, this message translates to:
  /// **'버그가 발생한 상황이나 개선 사항을 자세히 적어주세요'**
  String get feedback_appHint;

  /// No description provided for @feedback_councilHint.
  ///
  /// In ko, this message translates to:
  /// **'학생회에 전달할 건의사항을 적어주세요'**
  String get feedback_councilHint;

  /// No description provided for @feedback_photoLabel.
  ///
  /// In ko, this message translates to:
  /// **'사진 첨부 (최대 3장)'**
  String get feedback_photoLabel;

  /// No description provided for @feedback_photoLimit.
  ///
  /// In ko, this message translates to:
  /// **'사진은 최대 3장까지 첨부할 수 있습니다'**
  String get feedback_photoLimit;

  /// No description provided for @feedback_noContent.
  ///
  /// In ko, this message translates to:
  /// **'내용을 입력해주세요'**
  String get feedback_noContent;

  /// No description provided for @feedback_success.
  ///
  /// In ko, this message translates to:
  /// **'제보가 접수되었습니다'**
  String get feedback_success;

  /// No description provided for @feedback_councilSuccess.
  ///
  /// In ko, this message translates to:
  /// **'건의사항이 전달되었습니다'**
  String get feedback_councilSuccess;

  /// No description provided for @feedback_sendError.
  ///
  /// In ko, this message translates to:
  /// **'전송에 실패했습니다'**
  String get feedback_sendError;

  /// No description provided for @feedback_send.
  ///
  /// In ko, this message translates to:
  /// **'보내기'**
  String get feedback_send;

  /// No description provided for @feedback_listTitle.
  ///
  /// In ko, this message translates to:
  /// **'앱 건의/버그 목록'**
  String get feedback_listTitle;

  /// No description provided for @feedback_listCouncilTitle.
  ///
  /// In ko, this message translates to:
  /// **'학생회 건의사항 목록'**
  String get feedback_listCouncilTitle;

  /// No description provided for @feedback_empty.
  ///
  /// In ko, this message translates to:
  /// **'건의사항이 없습니다'**
  String get feedback_empty;

  /// No description provided for @feedback_unknown.
  ///
  /// In ko, this message translates to:
  /// **'알 수 없음'**
  String get feedback_unknown;

  /// No description provided for @feedback_photoCount.
  ///
  /// In ko, this message translates to:
  /// **'사진 {count}장'**
  String feedback_photoCount(Object count);

  /// No description provided for @feedback_reviewed.
  ///
  /// In ko, this message translates to:
  /// **'확인됨'**
  String get feedback_reviewed;

  /// No description provided for @feedback_resolved.
  ///
  /// In ko, this message translates to:
  /// **'해결됨'**
  String get feedback_resolved;

  /// No description provided for @feedback_pending.
  ///
  /// In ko, this message translates to:
  /// **'대기중'**
  String get feedback_pending;

  /// No description provided for @feedback_deleted.
  ///
  /// In ko, this message translates to:
  /// **'삭제되었습니다'**
  String get feedback_deleted;

  /// No description provided for @feedback_delete.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get feedback_delete;

  /// No description provided for @notiSetting_screenTitle.
  ///
  /// In ko, this message translates to:
  /// **'알림 설정'**
  String get notiSetting_screenTitle;

  /// No description provided for @notiSetting_mealSection.
  ///
  /// In ko, this message translates to:
  /// **'급식 알림'**
  String get notiSetting_mealSection;

  /// No description provided for @notiSetting_breakfast.
  ///
  /// In ko, this message translates to:
  /// **'조식 알림'**
  String get notiSetting_breakfast;

  /// No description provided for @notiSetting_lunch.
  ///
  /// In ko, this message translates to:
  /// **'중식 알림'**
  String get notiSetting_lunch;

  /// No description provided for @notiSetting_dinner.
  ///
  /// In ko, this message translates to:
  /// **'석식 알림'**
  String get notiSetting_dinner;

  /// No description provided for @notiSetting_boardSection.
  ///
  /// In ko, this message translates to:
  /// **'게시판 알림'**
  String get notiSetting_boardSection;

  /// No description provided for @notiSetting_comment.
  ///
  /// In ko, this message translates to:
  /// **'내 글 댓글 알림'**
  String get notiSetting_comment;

  /// No description provided for @notiSetting_commentDesc.
  ///
  /// In ko, this message translates to:
  /// **'내 게시글에 댓글이 달리면 알림'**
  String get notiSetting_commentDesc;

  /// No description provided for @notiSetting_reply.
  ///
  /// In ko, this message translates to:
  /// **'대댓글 알림'**
  String get notiSetting_reply;

  /// No description provided for @notiSetting_replyDesc.
  ///
  /// In ko, this message translates to:
  /// **'내 댓글에 답글이 달리면 알림'**
  String get notiSetting_replyDesc;

  /// No description provided for @notiSetting_mention.
  ///
  /// In ko, this message translates to:
  /// **'멘션 알림'**
  String get notiSetting_mention;

  /// No description provided for @notiSetting_mentionDesc.
  ///
  /// In ko, this message translates to:
  /// **'댓글에서 누군가 나를 @로 언급하면 알림'**
  String get notiSetting_mentionDesc;

  /// No description provided for @notiSetting_newPost.
  ///
  /// In ko, this message translates to:
  /// **'새 글 알림 (공지)'**
  String get notiSetting_newPost;

  /// No description provided for @notiSetting_newPostDesc.
  ///
  /// In ko, this message translates to:
  /// **'공지글이 올라오면 알림'**
  String get notiSetting_newPostDesc;

  /// No description provided for @notiSetting_popular.
  ///
  /// In ko, this message translates to:
  /// **'인기글 알림'**
  String get notiSetting_popular;

  /// No description provided for @notiSetting_popularDesc.
  ///
  /// In ko, this message translates to:
  /// **'좋아요 10개 이상 달성 시 알림'**
  String get notiSetting_popularDesc;

  /// No description provided for @notiSetting_categorySection.
  ///
  /// In ko, this message translates to:
  /// **'카테고리별 새 글 알림'**
  String get notiSetting_categorySection;

  /// No description provided for @notiSetting_categoryDesc.
  ///
  /// In ko, this message translates to:
  /// **'{category} 게시판에 새 글이 올라오면 알림'**
  String notiSetting_categoryDesc(Object category);

  /// No description provided for @notiSetting_chatSection.
  ///
  /// In ko, this message translates to:
  /// **'채팅 알림'**
  String get notiSetting_chatSection;

  /// No description provided for @notiSetting_chat.
  ///
  /// In ko, this message translates to:
  /// **'메시지 알림'**
  String get notiSetting_chat;

  /// No description provided for @notiSetting_chatDesc.
  ///
  /// In ko, this message translates to:
  /// **'새 채팅 메시지가 오면 알림'**
  String get notiSetting_chatDesc;

  /// No description provided for @notiSetting_accountSection.
  ///
  /// In ko, this message translates to:
  /// **'계정 알림'**
  String get notiSetting_accountSection;

  /// No description provided for @notiSetting_account.
  ///
  /// In ko, this message translates to:
  /// **'승인/정지/역할 변경'**
  String get notiSetting_account;

  /// No description provided for @notiSetting_accountDesc.
  ///
  /// In ko, this message translates to:
  /// **'계정 상태 변경 시 알림'**
  String get notiSetting_accountDesc;

  /// No description provided for @onboarding_meal.
  ///
  /// In ko, this message translates to:
  /// **'급식 정보'**
  String get onboarding_meal;

  /// No description provided for @onboarding_mealDesc.
  ///
  /// In ko, this message translates to:
  /// **'조식/중식/석식 메뉴를\n한눈에 확인하세요'**
  String get onboarding_mealDesc;

  /// No description provided for @onboarding_timetable.
  ///
  /// In ko, this message translates to:
  /// **'시간표'**
  String get onboarding_timetable;

  /// No description provided for @onboarding_timetableDesc.
  ///
  /// In ko, this message translates to:
  /// **'선택과목 기반 시간표를\n자동으로 구성해드려요'**
  String get onboarding_timetableDesc;

  /// No description provided for @onboarding_schedule.
  ///
  /// In ko, this message translates to:
  /// **'일정 관리'**
  String get onboarding_schedule;

  /// No description provided for @onboarding_scheduleDesc.
  ///
  /// In ko, this message translates to:
  /// **'개인 일정과 학사일정을\n한 곳에서 관리하세요'**
  String get onboarding_scheduleDesc;

  /// No description provided for @onboarding_board.
  ///
  /// In ko, this message translates to:
  /// **'게시판'**
  String get onboarding_board;

  /// No description provided for @onboarding_boardDesc.
  ///
  /// In ko, this message translates to:
  /// **'자유롭게 소통하고\n투표, 일정 공유도 가능해요'**
  String get onboarding_boardDesc;

  /// No description provided for @onboarding_skip.
  ///
  /// In ko, this message translates to:
  /// **'건너뛰기'**
  String get onboarding_skip;

  /// No description provided for @onboarding_next.
  ///
  /// In ko, this message translates to:
  /// **'다음'**
  String get onboarding_next;

  /// No description provided for @onboarding_start.
  ///
  /// In ko, this message translates to:
  /// **'시작하기'**
  String get onboarding_start;

  /// No description provided for @notiPermission_title.
  ///
  /// In ko, this message translates to:
  /// **'알림 허용'**
  String get notiPermission_title;

  /// No description provided for @notiPermission_desc.
  ///
  /// In ko, this message translates to:
  /// **'알림을 허용하면 급식 메뉴 등\n다양한 알림을 받을 수 있어요'**
  String get notiPermission_desc;

  /// No description provided for @notiPermission_allow.
  ///
  /// In ko, this message translates to:
  /// **'허용'**
  String get notiPermission_allow;

  /// No description provided for @notiPermission_later.
  ///
  /// In ko, this message translates to:
  /// **'나중에'**
  String get notiPermission_later;

  /// No description provided for @notiPermission_settingsDesc.
  ///
  /// In ko, this message translates to:
  /// **'알림을 받으려면 설정에서\n알림 권한을 허용해 주세요'**
  String get notiPermission_settingsDesc;

  /// No description provided for @notiPermission_openSettings.
  ///
  /// In ko, this message translates to:
  /// **'설정으로 이동'**
  String get notiPermission_openSettings;

  /// No description provided for @settings_title.
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get settings_title;

  /// No description provided for @settings_schoolSection.
  ///
  /// In ko, this message translates to:
  /// **'학교 정보'**
  String get settings_schoolSection;

  /// No description provided for @settings_gradeClass.
  ///
  /// In ko, this message translates to:
  /// **'학년 반 설정'**
  String get settings_gradeClass;

  /// No description provided for @settings_gradeClassLabel.
  ///
  /// In ko, this message translates to:
  /// **'{grade}학년 {classNum}반'**
  String settings_gradeClassLabel(Object grade, Object classNum);

  /// No description provided for @settings_gradeClassError.
  ///
  /// In ko, this message translates to:
  /// **'학년/반을 먼저 설정해주세요'**
  String get settings_gradeClassError;

  /// No description provided for @settings_selectiveSubject.
  ///
  /// In ko, this message translates to:
  /// **'선택과목 시간표'**
  String get settings_selectiveSubject;

  /// No description provided for @settings_themeSection.
  ///
  /// In ko, this message translates to:
  /// **'테마'**
  String get settings_themeSection;

  /// No description provided for @settings_light.
  ///
  /// In ko, this message translates to:
  /// **'라이트'**
  String get settings_light;

  /// No description provided for @settings_dark.
  ///
  /// In ko, this message translates to:
  /// **'다크'**
  String get settings_dark;

  /// No description provided for @settings_system.
  ///
  /// In ko, this message translates to:
  /// **'시스템'**
  String get settings_system;

  /// No description provided for @settings_notificationSection.
  ///
  /// In ko, this message translates to:
  /// **'알림'**
  String get settings_notificationSection;

  /// No description provided for @settings_notification.
  ///
  /// In ko, this message translates to:
  /// **'알림 설정'**
  String get settings_notification;

  /// No description provided for @settings_feedbackSection.
  ///
  /// In ko, this message translates to:
  /// **'건의사항'**
  String get settings_feedbackSection;

  /// No description provided for @settings_appFeedback.
  ///
  /// In ko, this message translates to:
  /// **'앱 건의사항 & 버그 제보'**
  String get settings_appFeedback;

  /// No description provided for @settings_councilFeedback.
  ///
  /// In ko, this message translates to:
  /// **'학생회 건의사항'**
  String get settings_councilFeedback;

  /// No description provided for @settings_etcSection.
  ///
  /// In ko, this message translates to:
  /// **'기타'**
  String get settings_etcSection;

  /// No description provided for @settings_privacy.
  ///
  /// In ko, this message translates to:
  /// **'개인정보 처리방침'**
  String get settings_privacy;

  /// No description provided for @settings_cacheLabel.
  ///
  /// In ko, this message translates to:
  /// **'캐시 삭제{cacheSize}'**
  String settings_cacheLabel(Object cacheSize);

  /// No description provided for @settings_cacheSuccess.
  ///
  /// In ko, this message translates to:
  /// **'캐시가 삭제되었습니다'**
  String get settings_cacheSuccess;

  /// No description provided for @settings_cacheDelete.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get settings_cacheDelete;

  /// No description provided for @settings_appVersion.
  ///
  /// In ko, this message translates to:
  /// **'앱 버전'**
  String get settings_appVersion;

  /// No description provided for @settings_myAccount.
  ///
  /// In ko, this message translates to:
  /// **'내 계정'**
  String get settings_myAccount;

  /// No description provided for @settings_nameDefault.
  ///
  /// In ko, this message translates to:
  /// **'이름 없음'**
  String get settings_nameDefault;

  /// No description provided for @settings_approved.
  ///
  /// In ko, this message translates to:
  /// **'승인됨'**
  String get settings_approved;

  /// No description provided for @settings_pendingApproval.
  ///
  /// In ko, this message translates to:
  /// **'승인 대기중'**
  String get settings_pendingApproval;

  /// No description provided for @settings_logout.
  ///
  /// In ko, this message translates to:
  /// **'로그아웃'**
  String get settings_logout;

  /// No description provided for @settings_login.
  ///
  /// In ko, this message translates to:
  /// **'로그인'**
  String get settings_login;

  /// No description provided for @settings_loginDesc.
  ///
  /// In ko, this message translates to:
  /// **'Google 계정으로 로그인하세요'**
  String get settings_loginDesc;

  /// No description provided for @settings_loginKakao.
  ///
  /// In ko, this message translates to:
  /// **'Kakao 로그인'**
  String get settings_loginKakao;

  /// No description provided for @settings_loginApple.
  ///
  /// In ko, this message translates to:
  /// **'Apple 로그인'**
  String get settings_loginApple;

  /// No description provided for @settings_loginGithub.
  ///
  /// In ko, this message translates to:
  /// **'GitHub 로그인'**
  String get settings_loginGithub;

  /// No description provided for @settings_loginGoogle.
  ///
  /// In ko, this message translates to:
  /// **'Google 로그인'**
  String get settings_loginGoogle;

  /// No description provided for @settings_privacyTitle.
  ///
  /// In ko, this message translates to:
  /// **'개인정보 처리방침'**
  String get settings_privacyTitle;

  /// No description provided for @settings_privacyEffectiveDate.
  ///
  /// In ko, this message translates to:
  /// **'시행일자: 2026년 4월 10일'**
  String get settings_privacyEffectiveDate;

  /// No description provided for @settings_privacyIntro.
  ///
  /// In ko, this message translates to:
  /// **'한솔고등학교 앱(이하 \"앱\")은 「개인정보 보호법」 제30조에 따라 이용자의 개인정보를 보호하고, 이와 관련한 고충을 신속하게 처리하기 위하여 다음과 같이 개인정보 처리방침을 수립·공개합니다.'**
  String get settings_privacyIntro;

  /// No description provided for @settings_privacySection1Title.
  ///
  /// In ko, this message translates to:
  /// **'제1조 (개인정보의 처리 목적)'**
  String get settings_privacySection1Title;

  /// No description provided for @settings_privacySection1Intro.
  ///
  /// In ko, this message translates to:
  /// **'앱은 다음의 목적을 위하여 개인정보를 처리합니다. 처리한 개인정보는 아래 목적 이외의 용도로는 이용하지 않으며, 목적이 변경되는 경우 별도의 동의를 받겠습니다.'**
  String get settings_privacySection1Intro;

  /// No description provided for @settings_privacySection1Content.
  ///
  /// In ko, this message translates to:
  /// **'1. 회원 가입 및 인증: 소셜 로그인(Google, Apple, Kakao, GitHub)을 통한 본인 확인 및 회원 식별\n2. 프로필 관리: 학교 구성원(학생, 졸업생, 교사, 학부모) 식별 및 학년·반 정보 관리\n3. 게시판 서비스: 게시글·댓글·좋아요·북마크·투표·익명글 기능 제공\n4. 1:1 채팅 서비스: 사용자 간 메시지 송수신\n5. 알림 서비스: 급식 알림, 댓글·멘션·인기글·새글·채팅·계정 상태 변경 푸시 알림\n6. 학사 정보 조회: 급식 메뉴, 시간표 정보 제공 및 로컬 알림\n7. 성적 관리: 시험 성적·목표 성적 저장 (기기 내 암호화 저장, 서버 미전송)\n8. 앱 개선: 이용 통계 분석 및 오류·충돌 수집을 통한 서비스 안정성 향상\n9. 부정 이용 방지: 신고·차단·계정 정지 처리 및 서비스 건전성 유지'**
  String get settings_privacySection1Content;

  /// No description provided for @settings_privacySection2Title.
  ///
  /// In ko, this message translates to:
  /// **'제2조 (수집하는 개인정보의 항목 및 수집 방법)'**
  String get settings_privacySection2Title;

  /// No description provided for @settings_privacySection2Required.
  ///
  /// In ko, this message translates to:
  /// **'필수 수집 항목'**
  String get settings_privacySection2Required;

  /// No description provided for @settings_privacySection2RequiredContent.
  ///
  /// In ko, this message translates to:
  /// **'• 이름: 소셜 로그인 프로필 또는 직접 입력\n• 이메일: 소셜 로그인 제공자로부터 자동 수집\n• 고유 사용자 식별자(UID): Firebase 인증 시 자동 생성\n• 로그인 제공자 정보: Google/Apple/Kakao/GitHub 로그인 시 자동 수집\n• 사용자 유형: 학생/졸업생/교사/학부모 중 직접 선택\n• 학년·반: 직접 입력'**
  String get settings_privacySection2RequiredContent;

  /// No description provided for @settings_privacySection2Optional.
  ///
  /// In ko, this message translates to:
  /// **'선택 수집 항목'**
  String get settings_privacySection2Optional;

  /// No description provided for @settings_privacySection2OptionalContent.
  ///
  /// In ko, this message translates to:
  /// **'• 프로필 사진: 소셜 로그인 프로필 또는 직접 업로드\n• 졸업연도: 졸업생인 경우 직접 입력\n• 담당 과목: 교사인 경우 직접 입력'**
  String get settings_privacySection2OptionalContent;

  /// No description provided for @settings_privacySection2Auto.
  ///
  /// In ko, this message translates to:
  /// **'서비스 이용 중 자동 생성되는 정보'**
  String get settings_privacySection2Auto;

  /// No description provided for @settings_privacySection2AutoContent.
  ///
  /// In ko, this message translates to:
  /// **'• 게시글·댓글·채팅 내용 (사용자가 작성한 텍스트 및 이미지)\n• 상호작용 기록 (좋아요·싫어요·북마크·투표 참여)\n• 신고·차단 기록\n• 검색 기록: 최근 검색어 최대 10개 (기기 내에만 저장)\n• 알림 설정값 (푸시·급식 알림 on/off 및 알림 시간)'**
  String get settings_privacySection2AutoContent;

  /// No description provided for @settings_privacySection2AutoCollect.
  ///
  /// In ko, this message translates to:
  /// **'자동 수집 항목'**
  String get settings_privacySection2AutoCollect;

  /// No description provided for @settings_privacySection2AutoCollectContent.
  ///
  /// In ko, this message translates to:
  /// **'• FCM 디바이스 토큰: 푸시 알림 발송을 위한 기기 식별 토큰\n• 앱 이용 로그: 화면 조회, 로그인/로그아웃, 게시글 작성·조회 등 (Firebase Analytics)\n• 오류·충돌 정보: 스택트레이스, 기기 OS 버전, 앱 버전 등 (Firebase Crashlytics)\n• 기기 정보: OS 종류·버전, 화면 크기, 앱 버전 (Firebase SDK 자동 수집)'**
  String get settings_privacySection2AutoCollectContent;

  /// No description provided for @settings_privacySection2LocalOnly.
  ///
  /// In ko, this message translates to:
  /// **'기기 내에만 저장되는 정보 (서버 미전송)'**
  String get settings_privacySection2LocalOnly;

  /// No description provided for @settings_privacySection2LocalOnlyContent.
  ///
  /// In ko, this message translates to:
  /// **'• 시험 성적·목표 성적: Android Keystore / iOS Keychain 암호화 저장\n• D-day 목록: 암호화 로컬 저장\n• 임시저장 게시글, 테마·알림 시간 설정: 기기 내 저장'**
  String get settings_privacySection2LocalOnlyContent;

  /// No description provided for @settings_privacySection3Title.
  ///
  /// In ko, this message translates to:
  /// **'제3조 (개인정보의 보유 및 이용 기간)'**
  String get settings_privacySection3Title;

  /// No description provided for @settings_privacySection3Content.
  ///
  /// In ko, this message translates to:
  /// **'앱은 개인정보 수집·이용 목적이 달성된 후에는 해당 정보를 지체 없이 파기합니다.\n\n• 회원 정보 (프로필·인증): 회원 탈퇴 시까지\n• 게시글·댓글·첨부 이미지: 작성일로부터 4년 (고정 공지 제외)\n• 채팅 메시지: 회원 탈퇴 시까지\n• 앱 이용 로그 (Analytics): 수집일로부터 14개월\n• 오류·충돌 보고 (Crashlytics): 수집일로부터 90일'**
  String get settings_privacySection3Content;

  /// No description provided for @settings_privacySection4Title.
  ///
  /// In ko, this message translates to:
  /// **'제4조 (개인정보의 제3자 제공)'**
  String get settings_privacySection4Title;

  /// No description provided for @settings_privacySection4Content.
  ///
  /// In ko, this message translates to:
  /// **'앱은 이용자의 개인정보를 제1조에서 명시한 범위 내에서만 처리하며, 이용자의 사전 동의 없이 제3자에게 제공하지 않습니다. 다만 다음의 경우에는 예외로 합니다.\n\n• 이용자가 사전에 동의한 경우\n• 법령의 규정에 의거하거나, 수사 목적으로 법령에 정해진 절차와 방법에 따라 수사기관의 요구가 있는 경우'**
  String get settings_privacySection4Content;

  /// No description provided for @settings_privacySection5Title.
  ///
  /// In ko, this message translates to:
  /// **'제5조 (개인정보 처리의 위탁)'**
  String get settings_privacySection5Title;

  /// No description provided for @settings_privacySection5Content.
  ///
  /// In ko, this message translates to:
  /// **'앱은 원활한 서비스 제공을 위하여 다음과 같이 개인정보 처리 업무를 위탁하고 있습니다.\n\n• Google LLC (Firebase): 인증, 데이터 저장, 푸시 알림, 이용 통계, 오류 수집, 호스팅 — 소재국: 미국\n• Google LLC: Google 계정 로그인 인증 — 소재국: 미국\n• Apple Inc.: Apple 계정 로그인 인증 — 소재국: 미국\n• Kakao Corp.: 카카오 계정 로그인 인증 — 소재국: 한국\n• GitHub Inc. (Microsoft): GitHub 계정 로그인 인증 — 소재국: 미국'**
  String get settings_privacySection5Content;

  /// No description provided for @settings_privacySection6Title.
  ///
  /// In ko, this message translates to:
  /// **'제6조 (개인정보의 국외 이전)'**
  String get settings_privacySection6Title;

  /// No description provided for @settings_privacySection6Content.
  ///
  /// In ko, this message translates to:
  /// **'앱은 「개인정보 보호법」 제28조의8에 따라 다음과 같이 개인정보를 국외로 이전하고 있습니다.\n\n• 이전받는 자: Google LLC\n• 이전되는 국가: 미국\n• 이전 항목: 회원 정보, 게시글·댓글·채팅 내용, 첨부 이미지, 이용 로그, 오류 정보, FCM 토큰\n• 이전 목적: 클라우드 서버를 통한 서비스 제공 및 앱 안정성 개선\n• 보유·이용 기간: 제3조에 명시된 기간과 동일\n• 보호 조치: Google Cloud 보안 인증(SOC 2, ISO 27001), 전송 구간 TLS 암호화, 저장 데이터 AES-256 암호화'**
  String get settings_privacySection6Content;

  /// No description provided for @settings_privacySection7Title.
  ///
  /// In ko, this message translates to:
  /// **'제7조 (정보주체의 권리·의무 및 행사 방법)'**
  String get settings_privacySection7Title;

  /// No description provided for @settings_privacySection7Content.
  ///
  /// In ko, this message translates to:
  /// **'이용자(정보주체)는 언제든지 다음의 권리를 행사할 수 있습니다.\n\n1. 개인정보 열람 요구: 본인의 개인정보 처리 현황을 열람할 수 있습니다.\n2. 개인정보 정정·삭제 요구: 앱 내 프로필 수정 기능을 통해 이름·사진·학년·반 등을 직접 정정할 수 있으며, 게시글·댓글은 직접 삭제할 수 있습니다.\n3. 개인정보 처리정지 요구: 개인정보 처리의 정지를 요구할 수 있습니다.\n4. 동의 철회(회원 탈퇴): 앱 내 설정 → 계정 삭제 기능을 통해 언제든지 회원 탈퇴 및 동의 철회가 가능합니다. 탈퇴 시 서버에 저장된 회원 정보, 하위 데이터가 즉시 삭제됩니다.\n\n위 권리 행사는 앱 내 기능 또는 아래 개인정보 보호책임자에게 이메일로 요청하실 수 있으며, 지체 없이 조치하겠습니다.\n\n※ 만 14세 미만 아동의 경우 법정대리인이 해당 아동의 개인정보에 대한 열람, 정정·삭제, 처리정지를 요구할 수 있습니다.'**
  String get settings_privacySection7Content;

  /// No description provided for @settings_privacySection8Title.
  ///
  /// In ko, this message translates to:
  /// **'제8조 (개인정보의 파기 절차 및 방법)'**
  String get settings_privacySection8Title;

  /// No description provided for @settings_privacySection8Content.
  ///
  /// In ko, this message translates to:
  /// **'앱은 개인정보의 보유 기간이 경과하거나 처리 목적이 달성된 때에는 지체 없이 해당 개인정보를 파기합니다.\n\n[파기 절차]\n• 회원 탈퇴 시: Firebase 인증 정보 삭제, Firestore 프로필 문서 및 하위 컬렉션(알림 등) 일괄 삭제\n• 게시글 자동 파기: 작성일로부터 4년이 경과한 비고정 게시글과 해당 첨부 이미지·댓글을 자동으로 일괄 삭제\n• 기기 내 데이터: 앱 삭제 시 SharedPreferences 및 SecureStorage 데이터 자동 삭제\n\n[파기 방법]\n• 전자적 파일: 복구 불가능한 방법으로 영구 삭제\n• 서버 저장 데이터: Firebase Firestore·Storage에서 문서 및 파일 영구 삭제'**
  String get settings_privacySection8Content;

  /// No description provided for @settings_privacySection9Title.
  ///
  /// In ko, this message translates to:
  /// **'제9조 (개인정보의 안전성 확보 조치)'**
  String get settings_privacySection9Title;

  /// No description provided for @settings_privacySection9Content.
  ///
  /// In ko, this message translates to:
  /// **'앱은 「개인정보 보호법」 제29조에 따라 다음과 같은 안전성 확보 조치를 취하고 있습니다.\n\n1. 전송 구간 암호화: 모든 서버 통신은 HTTPS/TLS로 암호화됩니다.\n2. 접근 통제: Firestore Security Rules를 통해 본인 데이터만 수정 가능하도록 제한하고, 관리자 권한을 분리하고 있습니다.\n3. 민감 정보 암호화 저장: 시험 성적 등 민감 데이터는 Android Keystore / iOS Keychain을 이용하여 기기 내 암호화 저장합니다.\n4. 앱 무결성 검증: Firebase App Check(Android Play Integrity)를 적용하여 무단 접근을 방지합니다.\n5. 비밀번호 미보관: 소셜 로그인만 사용하며, 앱에서 비밀번호를 직접 저장하거나 관리하지 않습니다.\n6. 부정 이용 방지: 신고 기능에 5분당 3건 제한(rate limiting)을 적용하고 있습니다.'**
  String get settings_privacySection9Content;

  /// No description provided for @settings_privacySection10Title.
  ///
  /// In ko, this message translates to:
  /// **'제10조 (자동 수집 장치의 설치·운영 및 거부)'**
  String get settings_privacySection10Title;

  /// No description provided for @settings_privacySection10Content.
  ///
  /// In ko, this message translates to:
  /// **'앱은 웹 쿠키를 사용하지 않습니다. 다만 Firebase Analytics SDK를 통해 앱 이용 로그(화면 조회, 이벤트 등)를 자동으로 수집합니다.\n\n• 수집 목적: 서비스 이용 통계 분석 및 앱 개선\n• 거부 방법: 기기 설정에서 광고 추적 제한을 활성화하거나, 앱을 삭제하여 수집을 중단할 수 있습니다.'**
  String get settings_privacySection10Content;

  /// No description provided for @settings_privacySection11Title.
  ///
  /// In ko, this message translates to:
  /// **'제11조 (익명 게시에 관한 사항)'**
  String get settings_privacySection11Title;

  /// No description provided for @settings_privacySection11Content.
  ///
  /// In ko, this message translates to:
  /// **'앱은 게시판에서 익명 게시 기능을 제공합니다. 익명으로 작성된 게시글·댓글의 작성자 정보(이름 등)는 다른 이용자에게 표시되지 않습니다. 다만, 서비스 운영 및 신고 처리 목적으로 작성자 식별 정보(UID)는 서버에 보관됩니다.'**
  String get settings_privacySection11Content;

  /// No description provided for @settings_privacySection12Title.
  ///
  /// In ko, this message translates to:
  /// **'제12조 (만 14세 미만 아동의 개인정보)'**
  String get settings_privacySection12Title;

  /// No description provided for @settings_privacySection12Content.
  ///
  /// In ko, this message translates to:
  /// **'앱은 고등학생 및 학교 관계자를 주 이용 대상으로 하며, 만 14세 미만 아동의 개인정보를 수집하지 않습니다. 만 14세 미만임이 확인된 경우 회원 가입이 제한될 수 있으며, 수집된 정보는 지체 없이 파기합니다.'**
  String get settings_privacySection12Content;

  /// No description provided for @settings_privacySection13Title.
  ///
  /// In ko, this message translates to:
  /// **'제13조 (개인정보 보호책임자)'**
  String get settings_privacySection13Title;

  /// No description provided for @settings_privacySection13Content.
  ///
  /// In ko, this message translates to:
  /// **'앱은 개인정보 처리에 관한 업무를 총괄하고, 이용자의 불만 처리 및 피해 구제를 위하여 아래와 같이 개인정보 보호책임자를 지정하고 있습니다.\n\n• 성명: 추희도\n• 직위: 앱 개발자\n• 연락처: justinchoo0814@gmail.com\n\n개인정보 관련 문의, 불만, 피해 구제 등은 위 연락처로 문의해 주시기 바랍니다.'**
  String get settings_privacySection13Content;

  /// No description provided for @settings_privacySection14Title.
  ///
  /// In ko, this message translates to:
  /// **'제14조 (권익 침해 구제 방법)'**
  String get settings_privacySection14Title;

  /// No description provided for @settings_privacySection14Content.
  ///
  /// In ko, this message translates to:
  /// **'이용자는 개인정보 침해로 인한 피해 구제를 아래 기관에 문의할 수 있습니다.'**
  String get settings_privacySection14Content;

  /// No description provided for @settings_privacySection14Link1.
  ///
  /// In ko, this message translates to:
  /// **'개인정보침해 신고센터 (KISA)'**
  String get settings_privacySection14Link1;

  /// No description provided for @settings_privacySection14Phone1.
  ///
  /// In ko, this message translates to:
  /// **'118'**
  String get settings_privacySection14Phone1;

  /// No description provided for @settings_privacySection14Url1.
  ///
  /// In ko, this message translates to:
  /// **'https://privacy.kisa.or.kr'**
  String get settings_privacySection14Url1;

  /// No description provided for @settings_privacySection14Link2.
  ///
  /// In ko, this message translates to:
  /// **'개인정보 분쟁조정위원회'**
  String get settings_privacySection14Link2;

  /// No description provided for @settings_privacySection14Phone2.
  ///
  /// In ko, this message translates to:
  /// **'1833-6972'**
  String get settings_privacySection14Phone2;

  /// No description provided for @settings_privacySection14Url2.
  ///
  /// In ko, this message translates to:
  /// **'https://www.kopico.go.kr'**
  String get settings_privacySection14Url2;

  /// No description provided for @settings_privacySection14Link3.
  ///
  /// In ko, this message translates to:
  /// **'대검찰청 사이버수사과'**
  String get settings_privacySection14Link3;

  /// No description provided for @settings_privacySection14Phone3.
  ///
  /// In ko, this message translates to:
  /// **'1301'**
  String get settings_privacySection14Phone3;

  /// No description provided for @settings_privacySection14Url3.
  ///
  /// In ko, this message translates to:
  /// **'https://www.spo.go.kr'**
  String get settings_privacySection14Url3;

  /// No description provided for @settings_privacySection14Link4.
  ///
  /// In ko, this message translates to:
  /// **'경찰청 사이버수사국'**
  String get settings_privacySection14Link4;

  /// No description provided for @settings_privacySection14Phone4.
  ///
  /// In ko, this message translates to:
  /// **'182'**
  String get settings_privacySection14Phone4;

  /// No description provided for @settings_privacySection14Url4.
  ///
  /// In ko, this message translates to:
  /// **'https://ecrm.police.go.kr'**
  String get settings_privacySection14Url4;

  /// No description provided for @settings_privacySection15Title.
  ///
  /// In ko, this message translates to:
  /// **'제15조 (개인정보 처리방침의 변경)'**
  String get settings_privacySection15Title;

  /// No description provided for @settings_privacySection15Content.
  ///
  /// In ko, this message translates to:
  /// **'이 개인정보 처리방침은 시행일로부터 적용되며, 법령·정책 또는 서비스 변경에 따라 내용이 수정될 수 있습니다. 변경 사항이 있을 경우 시행일 7일 전부터 앱 내 공지사항 또는 푸시 알림을 통해 고지하겠습니다.\n\n• 공고일자: 2026년 4월 10일\n• 시행일자: 2026년 4월 10일'**
  String get settings_privacySection15Content;

  /// No description provided for @chat_title.
  ///
  /// In ko, this message translates to:
  /// **'채팅'**
  String get chat_title;

  /// No description provided for @chat_loginRequired.
  ///
  /// In ko, this message translates to:
  /// **'로그인이 필요합니다'**
  String get chat_loginRequired;

  /// No description provided for @chat_newChat.
  ///
  /// In ko, this message translates to:
  /// **'새 채팅'**
  String get chat_newChat;

  /// No description provided for @chat_noChats.
  ///
  /// In ko, this message translates to:
  /// **'채팅이 없습니다'**
  String get chat_noChats;

  /// No description provided for @chat_startTip.
  ///
  /// In ko, this message translates to:
  /// **'게시글에서 사용자를 탭하면 채팅을 시작할 수 있어요'**
  String get chat_startTip;

  /// No description provided for @chat_unknownUser.
  ///
  /// In ko, this message translates to:
  /// **'알 수 없음'**
  String get chat_unknownUser;

  /// No description provided for @chat_searchPlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'이름 또는 학번으로 검색'**
  String get chat_searchPlaceholder;

  /// No description provided for @chat_noResults.
  ///
  /// In ko, this message translates to:
  /// **'검색 결과가 없습니다'**
  String get chat_noResults;

  /// No description provided for @chat_loadingAdmins.
  ///
  /// In ko, this message translates to:
  /// **'관리자를 불러오는 중...'**
  String get chat_loadingAdmins;

  /// No description provided for @chat_managerLabel.
  ///
  /// In ko, this message translates to:
  /// **'매니저'**
  String get chat_managerLabel;

  /// No description provided for @chat_leaveConfirmation.
  ///
  /// In ko, this message translates to:
  /// **'{name} 님과의 채팅방을 나가시겠습니까?\n상대방에게 퇴장 메시지가 표시됩니다.'**
  String chat_leaveConfirmation(Object name);

  /// No description provided for @chat_leaveAction.
  ///
  /// In ko, this message translates to:
  /// **'채팅방 나가기'**
  String get chat_leaveAction;

  /// No description provided for @chat_leftMessage.
  ///
  /// In ko, this message translates to:
  /// **'{name}님이 채팅방을 나갔습니다.'**
  String chat_leftMessage(Object name);

  /// No description provided for @chat_leftShort.
  ///
  /// In ko, this message translates to:
  /// **'{name}님이 나갔습니다.'**
  String chat_leftShort(Object name);

  /// No description provided for @chat_leftSuccess.
  ///
  /// In ko, this message translates to:
  /// **'채팅방을 나갔습니다'**
  String get chat_leftSuccess;

  /// No description provided for @chat_leftError.
  ///
  /// In ko, this message translates to:
  /// **'채팅방 나가기에 실패했습니다'**
  String get chat_leftError;

  /// No description provided for @chat_leaveConfirmationRoom.
  ///
  /// In ko, this message translates to:
  /// **'채팅방을 나가시겠습니까?\n상대방에게 퇴장 메시지가 표시됩니다.'**
  String get chat_leaveConfirmationRoom;

  /// No description provided for @chat_deleteForMe.
  ///
  /// In ko, this message translates to:
  /// **'나만 삭제'**
  String get chat_deleteForMe;

  /// No description provided for @chat_deleteForAll.
  ///
  /// In ko, this message translates to:
  /// **'같이 삭제'**
  String get chat_deleteForAll;

  /// No description provided for @chat_deletedMessage.
  ///
  /// In ko, this message translates to:
  /// **'삭제된 메시지입니다.'**
  String get chat_deletedMessage;

  /// No description provided for @chat_firstMessage.
  ///
  /// In ko, this message translates to:
  /// **'첫 메시지를 보내보세요'**
  String get chat_firstMessage;

  /// No description provided for @chat_read.
  ///
  /// In ko, this message translates to:
  /// **'읽음'**
  String get chat_read;

  /// No description provided for @chat_imageCaption.
  ///
  /// In ko, this message translates to:
  /// **'[사진]'**
  String get chat_imageCaption;

  /// No description provided for @chat_imageSendError.
  ///
  /// In ko, this message translates to:
  /// **'이미지 전송에 실패했습니다'**
  String get chat_imageSendError;

  /// No description provided for @chat_leaveButton.
  ///
  /// In ko, this message translates to:
  /// **'나가기'**
  String get chat_leaveButton;

  /// No description provided for @chat_messagePlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'메시지를 입력하세요'**
  String get chat_messagePlaceholder;

  /// No description provided for @chat_sendImage.
  ///
  /// In ko, this message translates to:
  /// **'사진 보내기'**
  String get chat_sendImage;

  /// No description provided for @widget_currentPeriod.
  ///
  /// In ko, this message translates to:
  /// **'{period}교시는'**
  String widget_currentPeriod(Object period);

  /// No description provided for @widget_isClass.
  ///
  /// In ko, this message translates to:
  /// **'{subject}이에요!'**
  String widget_isClass(Object subject);

  /// No description provided for @widget_willStart.
  ///
  /// In ko, this message translates to:
  /// **'{subject} 시작 예정'**
  String widget_willStart(Object subject);

  /// No description provided for @widget_nextClass.
  ///
  /// In ko, this message translates to:
  /// **'{period}교시 {subject}'**
  String widget_nextClass(Object period, Object subject);

  /// No description provided for @widget_gradeNotSet.
  ///
  /// In ko, this message translates to:
  /// **'학년/반을 설정하면\n시간표가 표시됩니다'**
  String get widget_gradeNotSet;

  /// No description provided for @widget_weekend.
  ///
  /// In ko, this message translates to:
  /// **'주말에는 수업이 없어요'**
  String get widget_weekend;

  /// No description provided for @widget_loadingSchedule.
  ///
  /// In ko, this message translates to:
  /// **'오늘 시간표를 불러오는 중...'**
  String get widget_loadingSchedule;

  /// No description provided for @widget_noClass.
  ///
  /// In ko, this message translates to:
  /// **'오늘 남은 수업이 없어요'**
  String get widget_noClass;

  /// No description provided for @widget_morning.
  ///
  /// In ko, this message translates to:
  /// **'오전'**
  String get widget_morning;

  /// No description provided for @widget_afternoon.
  ///
  /// In ko, this message translates to:
  /// **'오후'**
  String get widget_afternoon;

  /// No description provided for @widget_timetableNotSet.
  ///
  /// In ko, this message translates to:
  /// **'학년/반을 설정해주세요'**
  String get widget_timetableNotSet;

  /// No description provided for @widget_noMealInfo.
  ///
  /// In ko, this message translates to:
  /// **'정보 없음'**
  String get widget_noMealInfo;

  /// No description provided for @calendar_createSchedule.
  ///
  /// In ko, this message translates to:
  /// **'일정 만들기'**
  String get calendar_createSchedule;

  /// No description provided for @calendar_scheduleContent.
  ///
  /// In ko, this message translates to:
  /// **'일정 내용을 입력하세요'**
  String get calendar_scheduleContent;

  /// No description provided for @calendar_startDate.
  ///
  /// In ko, this message translates to:
  /// **'시작일'**
  String get calendar_startDate;

  /// No description provided for @calendar_endDate.
  ///
  /// In ko, this message translates to:
  /// **'종료일'**
  String get calendar_endDate;

  /// No description provided for @calendar_multiDay.
  ///
  /// In ko, this message translates to:
  /// **'{days}일간'**
  String calendar_multiDay(Object days);

  /// No description provided for @calendar_color.
  ///
  /// In ko, this message translates to:
  /// **'색상'**
  String get calendar_color;

  /// No description provided for @calendar_add.
  ///
  /// In ko, this message translates to:
  /// **'추가'**
  String get calendar_add;

  /// No description provided for @calendar_colorPreview.
  ///
  /// In ko, this message translates to:
  /// **'미리보기'**
  String get calendar_colorPreview;

  /// No description provided for @calendar_colorSelect.
  ///
  /// In ko, this message translates to:
  /// **'선택'**
  String get calendar_colorSelect;

  /// No description provided for @calendar_school.
  ///
  /// In ko, this message translates to:
  /// **'학사'**
  String get calendar_school;

  /// No description provided for @calendar_weekdaySun.
  ///
  /// In ko, this message translates to:
  /// **'일'**
  String get calendar_weekdaySun;

  /// No description provided for @calendar_weekdayMon.
  ///
  /// In ko, this message translates to:
  /// **'월'**
  String get calendar_weekdayMon;

  /// No description provided for @calendar_weekdayTue.
  ///
  /// In ko, this message translates to:
  /// **'화'**
  String get calendar_weekdayTue;

  /// No description provided for @calendar_weekdayWed.
  ///
  /// In ko, this message translates to:
  /// **'수'**
  String get calendar_weekdayWed;

  /// No description provided for @calendar_weekdayThu.
  ///
  /// In ko, this message translates to:
  /// **'목'**
  String get calendar_weekdayThu;

  /// No description provided for @calendar_weekdayFri.
  ///
  /// In ko, this message translates to:
  /// **'금'**
  String get calendar_weekdayFri;

  /// No description provided for @calendar_weekdaySat.
  ///
  /// In ko, this message translates to:
  /// **'토'**
  String get calendar_weekdaySat;

  /// No description provided for @data_teacherLabel.
  ///
  /// In ko, this message translates to:
  /// **'교사 {name}'**
  String data_teacherLabel(Object name);

  /// No description provided for @data_parentLabel.
  ///
  /// In ko, this message translates to:
  /// **'학부모 {name}'**
  String data_parentLabel(Object name);

  /// No description provided for @data_graduateLabel.
  ///
  /// In ko, this message translates to:
  /// **'졸업생 {name}'**
  String data_graduateLabel(Object name);

  /// No description provided for @data_allergyEgg.
  ///
  /// In ko, this message translates to:
  /// **'난류'**
  String get data_allergyEgg;

  /// No description provided for @data_allergyMilk.
  ///
  /// In ko, this message translates to:
  /// **'우유'**
  String get data_allergyMilk;

  /// No description provided for @data_allergyBuckwheat.
  ///
  /// In ko, this message translates to:
  /// **'메밀'**
  String get data_allergyBuckwheat;

  /// No description provided for @data_allergyPeanut.
  ///
  /// In ko, this message translates to:
  /// **'땅콩'**
  String get data_allergyPeanut;

  /// No description provided for @data_allergyBean.
  ///
  /// In ko, this message translates to:
  /// **'대두'**
  String get data_allergyBean;

  /// No description provided for @data_allergyWheat.
  ///
  /// In ko, this message translates to:
  /// **'밀'**
  String get data_allergyWheat;

  /// No description provided for @data_allergyMackerel.
  ///
  /// In ko, this message translates to:
  /// **'고등어'**
  String get data_allergyMackerel;

  /// No description provided for @data_allergyCrab.
  ///
  /// In ko, this message translates to:
  /// **'게'**
  String get data_allergyCrab;

  /// No description provided for @data_allergyShrimp.
  ///
  /// In ko, this message translates to:
  /// **'새우'**
  String get data_allergyShrimp;

  /// No description provided for @data_allergyPork.
  ///
  /// In ko, this message translates to:
  /// **'돼지고기'**
  String get data_allergyPork;

  /// No description provided for @data_allergyPeach.
  ///
  /// In ko, this message translates to:
  /// **'복숭아'**
  String get data_allergyPeach;

  /// No description provided for @data_allergyTomato.
  ///
  /// In ko, this message translates to:
  /// **'토마토'**
  String get data_allergyTomato;

  /// No description provided for @data_allergySulfite.
  ///
  /// In ko, this message translates to:
  /// **'아황산류'**
  String get data_allergySulfite;

  /// No description provided for @data_allergyWalnut.
  ///
  /// In ko, this message translates to:
  /// **'호두'**
  String get data_allergyWalnut;

  /// No description provided for @data_allergyChicken.
  ///
  /// In ko, this message translates to:
  /// **'닭고기'**
  String get data_allergyChicken;

  /// No description provided for @data_allergyBeef.
  ///
  /// In ko, this message translates to:
  /// **'쇠고기'**
  String get data_allergyBeef;

  /// No description provided for @data_allergySquid.
  ///
  /// In ko, this message translates to:
  /// **'오징어'**
  String get data_allergySquid;

  /// No description provided for @data_allergyShellfish.
  ///
  /// In ko, this message translates to:
  /// **'조개류'**
  String get data_allergyShellfish;

  /// No description provided for @data_midterm.
  ///
  /// In ko, this message translates to:
  /// **'{semester}학기 중간고사'**
  String data_midterm(Object semester);

  /// No description provided for @data_final.
  ///
  /// In ko, this message translates to:
  /// **'{semester}학기 기말고사'**
  String data_final(Object semester);

  /// No description provided for @data_mock.
  ///
  /// In ko, this message translates to:
  /// **'{year} {mockLabel} 모의고사'**
  String data_mock(Object year, Object mockLabel);

  /// No description provided for @data_privateMock.
  ///
  /// In ko, this message translates to:
  /// **'{year} {mockLabel}'**
  String data_privateMock(Object year, Object mockLabel);

  /// No description provided for @data_exam.
  ///
  /// In ko, this message translates to:
  /// **'{year} 시험'**
  String data_exam(Object year);

  /// No description provided for @data_suspendDays.
  ///
  /// In ko, this message translates to:
  /// **'{days}일'**
  String data_suspendDays(Object days);

  /// No description provided for @data_suspendHours.
  ///
  /// In ko, this message translates to:
  /// **'{hours}시간'**
  String data_suspendHours(Object hours);

  /// No description provided for @data_suspendMinutes.
  ///
  /// In ko, this message translates to:
  /// **'{minutes}분'**
  String data_suspendMinutes(Object minutes);

  /// No description provided for @data_suspendSeconds.
  ///
  /// In ko, this message translates to:
  /// **'{seconds}초'**
  String data_suspendSeconds(Object seconds);

  /// No description provided for @noti_updateRequired.
  ///
  /// In ko, this message translates to:
  /// **'필수 업데이트'**
  String get noti_updateRequired;

  /// No description provided for @noti_updateAvailable.
  ///
  /// In ko, this message translates to:
  /// **'업데이트 안내'**
  String get noti_updateAvailable;

  /// No description provided for @noti_updateDefault.
  ///
  /// In ko, this message translates to:
  /// **'새로운 버전이 출시되었습니다.'**
  String get noti_updateDefault;

  /// No description provided for @noti_updateButton.
  ///
  /// In ko, this message translates to:
  /// **'업데이트'**
  String get noti_updateButton;

  /// No description provided for @noti_updateLater.
  ///
  /// In ko, this message translates to:
  /// **'나중에'**
  String get noti_updateLater;

  /// No description provided for @noti_popupDefault.
  ///
  /// In ko, this message translates to:
  /// **'공지'**
  String get noti_popupDefault;

  /// No description provided for @noti_popupConfirm.
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get noti_popupConfirm;

  /// No description provided for @noti_popupDismiss.
  ///
  /// In ko, this message translates to:
  /// **'오늘 하루 안 보기'**
  String get noti_popupDismiss;

  /// No description provided for @noti_boardChannelName.
  ///
  /// In ko, this message translates to:
  /// **'게시판 알림'**
  String get noti_boardChannelName;

  /// No description provided for @noti_boardChannelDesc.
  ///
  /// In ko, this message translates to:
  /// **'새 댓글, 게시글 알림'**
  String get noti_boardChannelDesc;

  /// No description provided for @noti_mealChannelName.
  ///
  /// In ko, this message translates to:
  /// **'급식 알림'**
  String get noti_mealChannelName;

  /// No description provided for @noti_mealChannelDesc.
  ///
  /// In ko, this message translates to:
  /// **'급식 정보 알림을 제공합니다.'**
  String get noti_mealChannelDesc;

  /// No description provided for @noti_mealBreakfast.
  ///
  /// In ko, this message translates to:
  /// **'🍽️ 조식 알림'**
  String get noti_mealBreakfast;

  /// No description provided for @noti_mealLunch.
  ///
  /// In ko, this message translates to:
  /// **'🍽️ 중식 알림'**
  String get noti_mealLunch;

  /// No description provided for @noti_mealDinner.
  ///
  /// In ko, this message translates to:
  /// **'🍽️ 석식 알림'**
  String get noti_mealDinner;

  /// No description provided for @noti_mealConfirm.
  ///
  /// In ko, this message translates to:
  /// **'오늘의 {mealLabel} 메뉴를 확인하세요'**
  String noti_mealConfirm(Object mealLabel);

  /// No description provided for @noti_mealTestTitle.
  ///
  /// In ko, this message translates to:
  /// **'🍽️ 중식 알림 (테스트)'**
  String get noti_mealTestTitle;

  /// No description provided for @noti_mealTestBody.
  ///
  /// In ko, this message translates to:
  /// **'5초 후 알림 테스트'**
  String get noti_mealTestBody;

  /// No description provided for @noti_mealTestDetail.
  ///
  /// In ko, this message translates to:
  /// **'테스트 알림입니다.\n오늘의 중식 메뉴를 확인하세요!'**
  String get noti_mealTestDetail;

  /// No description provided for @noti_schoolName.
  ///
  /// In ko, this message translates to:
  /// **'한솔고등학교'**
  String get noti_schoolName;

  /// No description provided for @api_noInternet.
  ///
  /// In ko, this message translates to:
  /// **'식단 정보를 확인하려면 인터넷에 연결하세요'**
  String get api_noInternet;

  /// No description provided for @api_mealNoData.
  ///
  /// In ko, this message translates to:
  /// **'급식 정보가 없습니다.'**
  String get api_mealNoData;

  /// No description provided for @api_menuLabel.
  ///
  /// In ko, this message translates to:
  /// **'메뉴'**
  String get api_menuLabel;

  /// No description provided for @api_calorieLabel.
  ///
  /// In ko, this message translates to:
  /// **'칼로리'**
  String get api_calorieLabel;

  /// No description provided for @api_nutritionLabel.
  ///
  /// In ko, this message translates to:
  /// **'영양정보'**
  String get api_nutritionLabel;

  /// No description provided for @delete_confirm.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get delete_confirm;

  /// No description provided for @delete_cancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get delete_cancel;

  /// No description provided for @offline_status.
  ///
  /// In ko, this message translates to:
  /// **'오프라인 상태입니다'**
  String get offline_status;

  /// No description provided for @settings_languageSection.
  ///
  /// In ko, this message translates to:
  /// **'언어'**
  String get settings_languageSection;

  /// No description provided for @settings_langSystem.
  ///
  /// In ko, this message translates to:
  /// **'시스템'**
  String get settings_langSystem;

  /// No description provided for @settings_langKo.
  ///
  /// In ko, this message translates to:
  /// **'한국어'**
  String get settings_langKo;

  /// No description provided for @settings_langEn.
  ///
  /// In ko, this message translates to:
  /// **'English'**
  String get settings_langEn;

  /// No description provided for @error_generic.
  ///
  /// In ko, this message translates to:
  /// **'문제가 발생했습니다'**
  String get error_generic;

  /// No description provided for @error_retry.
  ///
  /// In ko, this message translates to:
  /// **'다시 시도'**
  String get error_retry;

  /// No description provided for @error_network.
  ///
  /// In ko, this message translates to:
  /// **'네트워크 연결을 확인해주세요'**
  String get error_network;

  /// No description provided for @error_loadFailed.
  ///
  /// In ko, this message translates to:
  /// **'데이터를 불러올 수 없습니다'**
  String get error_loadFailed;

  /// No description provided for @offline_postQueued.
  ///
  /// In ko, this message translates to:
  /// **'오프라인 상태입니다. 연결되면 자동으로 게시됩니다.'**
  String get offline_postQueued;

  /// No description provided for @offline_commentQueued.
  ///
  /// In ko, this message translates to:
  /// **'오프라인 상태입니다. 연결되면 자동으로 등록됩니다.'**
  String get offline_commentQueued;

  /// No description provided for @offline_syncComplete.
  ///
  /// In ko, this message translates to:
  /// **'동기화 완료'**
  String get offline_syncComplete;

  /// No description provided for @offline_syncFailed.
  ///
  /// In ko, this message translates to:
  /// **'일부 작업을 동기화하지 못했습니다'**
  String get offline_syncFailed;

  /// No description provided for @offline_pendingCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}개 대기 중'**
  String offline_pendingCount(int count);

  /// No description provided for @offline_syncing.
  ///
  /// In ko, this message translates to:
  /// **'동기화 중...'**
  String get offline_syncing;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
