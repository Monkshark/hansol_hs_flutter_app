// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get main_accountDeleted => '계정이 삭제되었습니다. 다시 가입해주세요.';

  @override
  String get login_canceled => '로그인이 취소되었습니다';

  @override
  String get login_schoolName => '한솔고등학교';

  @override
  String get login_subtitle => '로그인하면 더 많은 기능을 이용할 수 있어요';

  @override
  String get login_googleContinue => 'Google로 계속하기';

  @override
  String get login_appleContinue => 'Apple로 계속하기';

  @override
  String get login_kakaoContinue => '카카오로 계속하기';

  @override
  String get login_githubContinue => 'GitHub로 계속하기';

  @override
  String get login_skipButton => '나중에 하기';

  @override
  String get profileSetup_nameRequired => '이름을 입력해주세요';

  @override
  String get profileSetup_studentIdError => '학번을 정확히 입력해주세요';

  @override
  String get profileSetup_saveFailed => '저장에 실패했습니다. 다시 시도해주세요.';

  @override
  String get profileSetup_signupRequest => '가입 요청';

  @override
  String profileSetup_signupNotification(Object name) {
    return '$name님이 가입을 요청했습니다.';
  }

  @override
  String get profileSetup_userType => '신분';

  @override
  String get profileSetup_student => '재학생';

  @override
  String get profileSetup_graduate => '졸업생';

  @override
  String get profileSetup_teacher => '교사';

  @override
  String get profileSetup_parent => '학부모';

  @override
  String get profileSetup_name => '이름';

  @override
  String get profileSetup_nameHint => '이름을 입력하세요';

  @override
  String get profileSetup_studentId => '학번';

  @override
  String get profileSetup_studentIdHint => '예: 20301';

  @override
  String profileSetup_gradeClass(Object grade, Object classNum) {
    return '$grade학년 $classNum반';
  }

  @override
  String get profileSetup_graduationYear => '졸업연도';

  @override
  String get profileSetup_graduationYearHint => '예: 2025';

  @override
  String get profileSetup_teacherSubject => '담당과목 (선택)';

  @override
  String get profileSetup_teacherSubjectHint => '예: 수학';

  @override
  String get profileSetup_parentInfo => '학부모로 가입하면 게시판을 이용할 수 있습니다.';

  @override
  String get profileSetup_privacyTitle => '개인정보 수집·이용 동의 (필수)';

  @override
  String get profileSetup_privacyDescription =>
      '원활한 서비스 제공을 위해 이름, 학번 등 기본 정보를 수집합니다. 수집된 정보는 앱 이용 목적으로만 사용되며, 회원 탈퇴 시 즉시 삭제됩니다.';

  @override
  String get profileSetup_updateTitle => '프로필 업데이트';

  @override
  String get profileSetup_setupTitle => '정보 입력';

  @override
  String get profileSetup_updateSubtitle => '새 학기 정보를 업데이트해주세요';

  @override
  String get profileSetup_setupSubtitle => '환영합니다!';

  @override
  String get profileSetup_updateHint => '학번, 학년/반을 확인해주세요';

  @override
  String get profileSetup_setupHint => '기본 정보를 입력해주세요';

  @override
  String get profileSetup_updateButton => '업데이트';

  @override
  String get profileSetup_completeButton => '완료';

  @override
  String get profileEdit_accountTitle => '내 계정';

  @override
  String get profileEdit_camera => '카메라';

  @override
  String get profileEdit_gallery => '갤러리';

  @override
  String get profileEdit_deletePhoto => '사진 삭제';

  @override
  String get profileEdit_photoChangedSuccess => '프로필 사진이 변경되었습니다';

  @override
  String get profileEdit_photoChangeFailed => '사진 변경에 실패했습니다';

  @override
  String get profileEdit_photoDeletedSuccess => '프로필 사진이 삭제되었습니다';

  @override
  String get profileEdit_photoDeleteFailed => '삭제에 실패했습니다';

  @override
  String get profileEdit_deleteAccountTitle => '회원 탈퇴';

  @override
  String get profileEdit_deleteAccountConfirm =>
      '정말 탈퇴하시겠습니까?\n모든 데이터가 삭제되며 복구할 수 없습니다.';

  @override
  String get profileEdit_confirm => '확인';

  @override
  String get profileEdit_emailLabel => '이메일';

  @override
  String get profileEdit_nameLabel => '이름';

  @override
  String get profileEdit_finalConfirmTitle => '최종 확인';

  @override
  String profileEdit_finalConfirmMessage(Object confirmLabel) {
    return '탈퇴를 진행하려면 $confirmLabel을 정확히 입력하세요.';
  }

  @override
  String profileEdit_inputPlaceholder(Object confirmLabel) {
    return '$confirmLabel 입력';
  }

  @override
  String get profileEdit_withdrawButton => '탈퇴';

  @override
  String get profileEdit_reauthRequired => '재인증이 필요합니다. 다시 로그인 후 시도해주세요.';

  @override
  String get profileEdit_reauthFailed => '재인증에 실패했습니다. 다시 로그인 후 시도해주세요.';

  @override
  String get profileEdit_deleteAccountFailed => '회원 탈퇴에 실패했습니다. 다시 시도해주세요.';

  @override
  String get profileEdit_studentId => '학번';

  @override
  String get profileEdit_gradeClass => '학년/반';

  @override
  String get profileEdit_graduationYear => '졸업연도';

  @override
  String get profileEdit_teacherSubject => '담당과목';

  @override
  String get profileEdit_loginProvider => '로그인';

  @override
  String get home_scheduleLoading => '일정 로딩중...';

  @override
  String get home_ddaySet => 'D-day를 설정하세요';

  @override
  String home_schoolInfo(Object grade, Object classNum) {
    return '한솔고 $grade학년 $classNum반';
  }

  @override
  String get home_schoolName => '한솔고등학교';

  @override
  String get home_lunchPreview => '급식 정보 로딩중...';

  @override
  String get home_lunchNoInfo => '오늘 급식 정보가 없습니다';

  @override
  String get home_timetableTitle => '시간표';

  @override
  String get home_timetableSubtitle => '이번 주 시간표를 확인하세요';

  @override
  String get home_gradesTitle => '성적 관리';

  @override
  String get home_gradesSubtitle => '내신/모의고사 성적을 기록하세요';

  @override
  String get home_boardTitle => '게시판';

  @override
  String get home_boardSubtitle => '자유롭게 소통해보세요';

  @override
  String get home_chatTitle => '채팅';

  @override
  String get home_chatSubtitle => '1:1 대화하기';

  @override
  String get home_linkRiroschool => '리로스쿨';

  @override
  String get home_linkOfficial => '한솔 공식';

  @override
  String get meal_noInfo => '급식 정보 없음';

  @override
  String get meal_noInfoEmpty => '급식 정보가 없습니다';

  @override
  String get meal_refreshHint => '탭하여 새로고침';

  @override
  String meal_error(Object error) {
    return '오류: $error';
  }

  @override
  String get meal_noData => '급식 정보가 없습니다';

  @override
  String get meal_nutritionTitle => '영양 정보';

  @override
  String get meal_mealType => '식사';

  @override
  String get meal_calorie => '칼로리';

  @override
  String get meal_noInfoShort => '정보 없음';

  @override
  String get meal_nutrition => '영양 성분';

  @override
  String get meal_allergy => '포함된 알레르기 유발 식품';

  @override
  String get meal_today => '오늘';

  @override
  String get meal_breakfast => '조식';

  @override
  String get meal_lunch => '중식';

  @override
  String get meal_dinner => '석식';

  @override
  String get notice_noSchedule => '일정이 없습니다';

  @override
  String get notice_continuousDeleteTitle => '연속 일정 삭제';

  @override
  String get notice_deleteThisDayOnly => '이 날만 삭제';

  @override
  String get notice_deleteAllSchedule => '전체 일정 삭제';

  @override
  String get notice_noSchoolSchedule => '학사일정이 없습니다';

  @override
  String get board_title => '게시판';

  @override
  String get board_searchHint => '제목/본문 검색...';

  @override
  String get board_emptyPosts => '게시글이 없습니다';

  @override
  String get board_searchEmptyQuery => '검색어를 입력하세요';

  @override
  String get board_recentSearches => '최근 검색어';

  @override
  String get board_clearAllSearches => '전체 삭제';

  @override
  String get board_searchNoResults => '검색 결과가 없습니다';

  @override
  String get board_accountSuspended => '계정 정지 상태입니다';

  @override
  String board_suspendedRemaining(Object duration) {
    return '남은 기간: $duration';
  }

  @override
  String get board_awaitingAdminApproval => '관리자 승인 대기 중입니다';

  @override
  String get board_categoryAll => '전체';

  @override
  String get board_categoryFree => '자유';

  @override
  String get board_categoryPopular => '인기글';

  @override
  String get board_categoryQuestion => '질문';

  @override
  String get board_categoryInfoShare => '정보공유';

  @override
  String get board_categoryLostFound => '분실물';

  @override
  String get board_categoryStudentCouncil => '학생회';

  @override
  String get board_categoryClub => '동아리';

  @override
  String get common_justNow => '방금';

  @override
  String common_minutesAgo(Object minutes) {
    return '$minutes분 전';
  }

  @override
  String common_hoursAgo(Object hours) {
    return '$hours시간 전';
  }

  @override
  String common_daysAgo(Object days) {
    return '$days일 전';
  }

  @override
  String get common_cancel => '취소';

  @override
  String get common_delete => '삭제';

  @override
  String get common_confirm => '확인';

  @override
  String get common_save => '저장';

  @override
  String get common_loginRequired => '로그인이 필요합니다';

  @override
  String get common_chatPartner => '대화상대';

  @override
  String get common_dateYmd => 'yyyy년 M월 d일';

  @override
  String get common_dateMdE => 'M월 d일 (E)';

  @override
  String get common_dateYM => 'yyyy년 M월';

  @override
  String get common_dateYmdE => 'yyyy년 M월 d일 (E)';

  @override
  String get common_dateMdEHm => 'M월 d일 (E) HH:mm';

  @override
  String get common_dateYMdE => 'yyyy.M.d (E)';

  @override
  String get common_dateMdEEEE => 'M월 d일 EEEE';

  @override
  String get post_resolved => '해결';

  @override
  String get post_bookmark => '저장';

  @override
  String get post_chat => '채팅';

  @override
  String get post_share => '공유';

  @override
  String get post_edit => '수정';

  @override
  String get post_delete => '삭제';

  @override
  String get post_deleteByAdmin => '삭제 (관리자)';

  @override
  String get post_pinAsNotice => '공지 등록';

  @override
  String get post_unpinNotice => '공지 해제';

  @override
  String get post_report => '신고';

  @override
  String get post_reportSelectReason => '신고 사유 선택';

  @override
  String get post_reportReasonSwearing => '욕설/비방';

  @override
  String get post_reportReasonAdult => '음란물';

  @override
  String get post_reportReasonSpam => '광고/스팸';

  @override
  String get post_reportReasonPrivacy => '개인정보 노출';

  @override
  String get post_reportReasonOther => '기타';

  @override
  String get post_reportButton => '신고';

  @override
  String get post_reportAlreadyReported => '이미 신고한 게시글입니다';

  @override
  String get post_reportSuccess => '신고가 접수되었습니다';

  @override
  String get post_found => '찾았어요';

  @override
  String get post_resolvedLabel => '해결됨';

  @override
  String post_comments(Object count) {
    return '댓글 $count';
  }

  @override
  String get post_firstComment => '첫 댓글을 남겨보세요';

  @override
  String post_replyTo(Object name) {
    return '$name에게 답글';
  }

  @override
  String get post_anonymous => '익명';

  @override
  String get post_commentPlaceholder => '댓글을 입력하세요';

  @override
  String get post_confirmDeleteComment => '댓글 삭제';

  @override
  String get post_confirmDeleteCommentMessage => '댓글을 삭제하시겠습니까?';

  @override
  String get post_commentTooLong => '댓글은 1000자 이내로 입력하세요';

  @override
  String get post_commentRateLimit => '댓글은 10초에 한 번만 작성할 수 있습니다';

  @override
  String get post_pinMaxed => '공지는 최대 3개까지 가능합니다';

  @override
  String get post_pinSuccess => '공지로 등록되었습니다';

  @override
  String get post_unpinSuccess => '공지가 해제되었습니다';

  @override
  String post_eventAdded(Object date) {
    return '$date 일정에 추가되었습니다';
  }

  @override
  String get post_deleteConfirm => '게시글 삭제';

  @override
  String get post_deleteConfirmMessage => '정말 삭제하시겠습니까?';

  @override
  String get post_resolvedMarked => '해결됨으로 표시되었습니다';

  @override
  String get post_anonymousAuthor => '익명(글쓴이)';

  @override
  String post_anonymousNum(Object num) {
    return '익명$num';
  }

  @override
  String get post_authorBadge => '글쓴이';

  @override
  String get write_title => '글쓰기';

  @override
  String get write_editTitle => '글 수정';

  @override
  String get write_draftSave => '임시저장';

  @override
  String get write_draftSaved => '임시저장되었습니다';

  @override
  String get write_unsavedChanges => '작성 중인 글이 있습니다';

  @override
  String get write_draftDelete => '삭제';

  @override
  String get write_category => '카테고리';

  @override
  String get write_titlePlaceholder => '제목을 입력하세요';

  @override
  String get write_contentPlaceholder => '내용을 입력하세요';

  @override
  String get write_eventAttach => '일정 첨부';

  @override
  String get write_pollAttach => '투표 첨부';

  @override
  String get write_anonymous => '익명으로 작성';

  @override
  String get write_pinAsNotice => '공지로 등록';

  @override
  String get write_expiresInfo => '작성한 글은 1년 후 자동 삭제됩니다';

  @override
  String get write_errorTitleRequired => '제목을 입력하세요';

  @override
  String get write_errorTitleTooLong => '제목은 200자 이내로 입력하세요';

  @override
  String get write_errorContentRequired => '내용을 입력하세요';

  @override
  String get write_errorContentTooLong => '내용은 5000자 이내로 입력하세요';

  @override
  String get write_errorPollOptionsRequired => '투표 선택지를 2개 이상 입력하세요';

  @override
  String get write_errorPollOptionTooLong => '투표 선택지는 100자 이내로 입력하세요';

  @override
  String get write_errorEventDateRequired => '일정 날짜를 선택하세요';

  @override
  String get write_errorEventContentRequired => '일정 내용을 입력하세요';

  @override
  String get write_errorEventContentTooLong => '일정 내용은 200자 이내로 입력하세요';

  @override
  String get write_errorRateLimit => '게시글은 30초에 한 번만 작성할 수 있습니다';

  @override
  String get write_errorLoginRequired => '로그인이 필요합니다';

  @override
  String get write_errorProfileLoadFailed => '프로필 정보를 불러올 수 없습니다. 다시 시도해주세요.';

  @override
  String get write_pinLimitExceeded => '공지가 이미 3개입니다';

  @override
  String get write_pinLimitMessage => '기존 공지를 해제하거나, 이 글을 일반 글로 등록하세요.';

  @override
  String get write_pinUnpinAction => '해제';

  @override
  String get write_registerWithoutPin => '공지 없이 등록';

  @override
  String get write_noTitle => '제목 없음';

  @override
  String get write_eventContentHint => '일정 내용 (예: 중간고사, 체육대회)';

  @override
  String get write_eventSelectDate => '날짜를 선택하세요';

  @override
  String get write_eventStartTimeOptional => '시작 (선택)';

  @override
  String get write_eventEndTimeOptional => '종료 (선택)';

  @override
  String write_pollOptionHint(Object num) {
    return '선택지 $num';
  }

  @override
  String get write_pollAddOption => '선택지 추가';

  @override
  String write_imageAddButton(Object current, Object max) {
    return '사진 추가 ($current/$max)';
  }

  @override
  String get myActivity_title => '내 활동';

  @override
  String get myActivity_myPosts => '내가 쓴 글';

  @override
  String get myActivity_myComments => '내가 쓴 댓글';

  @override
  String get myActivity_savedPosts => '저장한 글';

  @override
  String get myActivity_noPosts => '작성한 글이 없습니다';

  @override
  String get myActivity_noComments => '작성한 댓글이 없습니다';

  @override
  String get bookmarks_title => '저장한 글';

  @override
  String get bookmarks_empty => '저장한 글이 없습니다';

  @override
  String get bookmarks_emptyHelper => '게시글에서 북마크 아이콘을 눌러 저장하세요';

  @override
  String get notification_title => '알림';

  @override
  String get notification_markAllRead => '모두 읽음';

  @override
  String get notification_empty => '알림이 없습니다';

  @override
  String notification_typeComment(Object name) {
    return '$name님이 댓글을 남겼습니다';
  }

  @override
  String notification_typeReply(Object name) {
    return '$name님이 답글을 남겼습니다';
  }

  @override
  String get admin_title => 'Admin';

  @override
  String get admin_userManagement => '사용자 관리';

  @override
  String get admin_usersPending => '승인 대기';

  @override
  String get admin_usersSuspended => '정지된 사용자';

  @override
  String get admin_usersApproved => '일반 사용자';

  @override
  String get admin_boardManagement => '게시판 관리';

  @override
  String get admin_reportsTab => '신고';

  @override
  String get admin_deleteLogs => '삭제 로그';

  @override
  String get admin_feedback => '건의사항';

  @override
  String get admin_feedbackCouncil => '학생회 건의';

  @override
  String get admin_feedbackApp => '앱 건의/버그';

  @override
  String get admin_emergencyNotice => '긴급 공지';

  @override
  String get admin_usersNoPending => '대기 중인 사용자가 없습니다';

  @override
  String get admin_usersNoApproved => '승인된 사용자가 없습니다';

  @override
  String get admin_usersNoSuspended => '정지된 사용자가 없습니다';

  @override
  String get admin_usersApprove => '승인';

  @override
  String get admin_usersReject => '거절';

  @override
  String get admin_usersRemoveAdmin => 'Admin 해제';

  @override
  String get admin_usersMakeManager => '매니저';

  @override
  String get admin_usersRemoveManager => '매니저 해제';

  @override
  String get admin_usersMakeAdmin => 'Admin';

  @override
  String get admin_usersSuspend => '정지';

  @override
  String get admin_usersDelete => '삭제';

  @override
  String get admin_usersUnsuspend => '정지 해제';

  @override
  String admin_usersSuspendTitle(Object name) {
    return '$name 정지';
  }

  @override
  String get admin_usersSuspendSelectDuration => '정지 기간을 선택하세요';

  @override
  String get admin_usersSuspend1Hour => '1시간';

  @override
  String get admin_usersSuspend6Hours => '6시간';

  @override
  String get admin_usersSuspend12Hours => '12시간';

  @override
  String get admin_usersSuspend1Day => '1일';

  @override
  String get admin_usersSuspend3Days => '3일';

  @override
  String get admin_usersSuspend7Days => '7일';

  @override
  String get admin_usersSuspend30Days => '30일';

  @override
  String admin_usersSuspendHours(Object hours) {
    return '$hours시간';
  }

  @override
  String admin_usersSuspendDays(Object days) {
    return '$days일';
  }

  @override
  String get admin_usersDeleteConfirm => '계정 삭제';

  @override
  String admin_usersDeleteConfirmMessage(Object name) {
    return '$name 계정을 삭제하시겠습니까?';
  }

  @override
  String get admin_usersDeleteFinal => '최종 확인';

  @override
  String admin_usersDeleteFinalMessage(Object name) {
    return '$name 계정을 정말 삭제합니까?\n되돌릴 수 없습니다.';
  }

  @override
  String admin_usersSuspendedRemaining(Object duration) {
    return '남은 기간: $duration';
  }

  @override
  String admin_usersMinutesLeft(Object minutes) {
    return '$minutes분';
  }

  @override
  String admin_usersHoursLeft(Object hours) {
    return '$hours시간';
  }

  @override
  String admin_usersDaysLeft(Object days) {
    return '$days일';
  }

  @override
  String get admin_usersLessThan1Minute => '1분 미만';

  @override
  String get admin_usersAccountApproved => '가입 승인';

  @override
  String get admin_usersApprovedMessage => '가입이 승인되었습니다.';

  @override
  String get admin_usersAccountRejected => '가입 거절';

  @override
  String get admin_usersRejectedMessage => '가입이 거절되었습니다.';

  @override
  String get admin_usersAccountSuspended => '계정 정지';

  @override
  String admin_usersSuspendedMessage(Object duration) {
    return '$duration 동안 계정이 정지되었습니다.';
  }

  @override
  String get admin_usersAccountDeleted => '계정 삭제';

  @override
  String get admin_usersDeletedMessage => '관리자에 의해 계정이 삭제되었습니다.';

  @override
  String get admin_usersSuspendRemoved => '정지 해제';

  @override
  String get admin_usersSuspendRemovedMessage => '계정 정지가 해제되었습니다.';

  @override
  String get admin_reportsEmpty => '신고가 없습니다';

  @override
  String get admin_reportsViewPost => '글 보기';

  @override
  String get admin_reportsDeletePost => '글 삭제';

  @override
  String get admin_reportsIgnore => '무시';

  @override
  String get admin_logsEmpty => '삭제 로그가 없습니다';

  @override
  String get admin_logsFeedbackDeleted => '건의 삭제';

  @override
  String get admin_logsPostDeleted => '게시글 삭제';

  @override
  String admin_logsAuthor(Object name) {
    return '작성자: $name';
  }

  @override
  String admin_logsDeletedBy(Object name) {
    return '삭제: $name';
  }

  @override
  String get admin_logsNoTitle => '제목 없음';

  @override
  String get admin_logsNoContent => '내용 없음';

  @override
  String get admin_logsUnknown => '알 수 없음';

  @override
  String get admin_popupActivate => '팝업 활성화';

  @override
  String get admin_popupTypeEmergency => '긴급';

  @override
  String get admin_popupTypeNotice => '공지';

  @override
  String get admin_popupTypeEvent => '이벤트';

  @override
  String get admin_popupTitle => '제목';

  @override
  String get admin_popupContent => '내용';

  @override
  String get admin_popupStartDate => '시작일';

  @override
  String get admin_popupEndDate => '종료일';

  @override
  String get admin_popupDismissible => '\"오늘 안 보기\" 허용';

  @override
  String get admin_popupSave => '저장';

  @override
  String get admin_popupSaved => '저장되었습니다';

  @override
  String get event_cardTitle => '일정 공유';

  @override
  String get event_cardAddButton => '내 일정에 추가';

  @override
  String get event_am => '오전';

  @override
  String get event_pm => '오후';

  @override
  String get poll_cardTitle => '투표';

  @override
  String poll_cardParticipants(Object count) {
    return '$count명 참여';
  }

  @override
  String get grade_screenTitle => '성적 관리';

  @override
  String get grade_deleteTitle => '시험 삭제';

  @override
  String grade_deleteMsg(Object examName) {
    return '$examName을(를) 삭제하시겠습니까?';
  }

  @override
  String get grade_noDataMsg => '시험 데이터가 없습니다';

  @override
  String get grade_targetTitle => '과목별 목표 백분위';

  @override
  String get grade_targetGradeTitle => '과목별 목표 등급';

  @override
  String get grade_notice => '성적 점수는 서버에 저장되지 않습니다';

  @override
  String get grade_sujungTab => '수시';

  @override
  String get grade_jeongsiTab => '정시';

  @override
  String grade_loadFailed(Object error) {
    return '불러오기 실패: $error';
  }

  @override
  String get grade_addPrompt => '시험을 추가하세요';

  @override
  String get grade_averageLabel => '평균';

  @override
  String grade_averageRank(Object rank) {
    return '평균 $rank등급';
  }

  @override
  String get grade_classSetting => '학년 · 반 설정';

  @override
  String get grade_grade => '학년';

  @override
  String get grade_class => '반';

  @override
  String get grade_percentile => '백분위';

  @override
  String get grade_standardScore => '표준점수';

  @override
  String get grade_rawScore => '원점수';

  @override
  String get grade_rank => '등급';

  @override
  String get grade_noData => '데이터가 없습니다';

  @override
  String get grade_scoreNoData => '점수 데이터가 없습니다';

  @override
  String get grade_goalGrade => '목표 등급';

  @override
  String get gradeInput_screenTitle => '시험 추가';

  @override
  String get gradeInput_screenEdit => '시험 수정';

  @override
  String get gradeInput_typeSection => '시험 유형';

  @override
  String get gradeInput_infoSection => '시험 정보';

  @override
  String get gradeInput_year => '연도';

  @override
  String get gradeInput_semester => '학기';

  @override
  String get gradeInput_grade => '학년';

  @override
  String get gradeInput_month => '시행월';

  @override
  String get gradeInput_privateLabel => '사설모의 이름';

  @override
  String get gradeInput_subjectSection => '과목 및 점수';

  @override
  String get gradeInput_fromTimetable => '시간표에서 선택';

  @override
  String get gradeInput_mockSubjects => '모의고사 과목 선택';

  @override
  String get gradeInput_addManual => '직접 추가';

  @override
  String get gradeInput_noSubjects => '위 버튼으로 과목을 추가해주세요';

  @override
  String get gradeInput_subjectCol => '과목';

  @override
  String get gradeInput_rawScore => '원점수';

  @override
  String get gradeInput_average => '평균';

  @override
  String get gradeInput_rank => '등급';

  @override
  String get gradeInput_achievement => '성취도';

  @override
  String get gradeInput_percentile => '백분위';

  @override
  String get gradeInput_standard => '표준';

  @override
  String get gradeInput_selectSubjects => '시간표 과목 선택';

  @override
  String get gradeInput_mockSubjectPicker => '모의고사 과목 선택';

  @override
  String get gradeInput_noTimetable => '저장된 시간표가 없습니다. 시간표를 먼저 설정해주세요.';

  @override
  String get gradeInput_allSubjectsAdded => '시간표의 모든 과목이 이미 추가되어 있습니다.';

  @override
  String get gradeInput_allMockAdded => '모든 과목이 이미 추가되어 있습니다.';

  @override
  String get gradeInput_addSubject => '과목 추가';

  @override
  String get gradeInput_subjectName => '과목명 입력';

  @override
  String gradeInput_addSubjectDuplicate(Object name) {
    return '\'$name\' 과목이 이미 추가되어 있습니다.';
  }

  @override
  String get gradeInput_addMinSubjects => '과목을 1개 이상 추가해주세요.';

  @override
  String get gradeInput_privateNameRequired => '사설모의 이름을 입력해주세요.';

  @override
  String get gradeInput_hintScore => '0~100';

  @override
  String get gradeInput_typeMidterm => '중간고사';

  @override
  String get gradeInput_typeFinal => '기말고사';

  @override
  String get gradeInput_typeMock => '모의고사';

  @override
  String get gradeInput_typePrivateMock => '사설모의';

  @override
  String get gradeInput_monthMar => '3월';

  @override
  String get gradeInput_monthJun => '6월';

  @override
  String get gradeInput_monthSep => '9월';

  @override
  String get gradeInput_monthNov => '11월';

  @override
  String get gradeInput_privateHint => '예: 메가스터디 3회';

  @override
  String gradeInput_yearSuffix(Object year) {
    return '$year년';
  }

  @override
  String gradeInput_semesterSuffix(Object semester) {
    return '$semester학기';
  }

  @override
  String gradeInput_gradeSuffix(Object grade) {
    return '$grade학년';
  }

  @override
  String gradeInput_mockMonthSuffix(Object month) {
    return '$month 모의고사';
  }

  @override
  String get timetable_screenTitle => '시간표';

  @override
  String get timetable_teacherScreenTitle => '내 수업 시간표';

  @override
  String timetable_classTitle(Object grade, Object classNum) {
    return '$grade학년 $classNum반 시간표';
  }

  @override
  String get timetable_setting => '수업 설정';

  @override
  String get timetable_changeClass => '반 변경';

  @override
  String get timetable_refresh => '새로고침';

  @override
  String get timetable_loadError => '시간표를 불러올 수 없습니다';

  @override
  String get timetable_setTeachingMsg => '수업을 설정하면 시간표가 표시됩니다';

  @override
  String get timetable_setSetting => '수업 설정';

  @override
  String get timetable_setGradeMsg => '학년/반을 먼저 설정해주세요';

  @override
  String get timetable_setGrade => '학년/반 설정';

  @override
  String get timetable_set1stMsg => '학년/반을 설정하면 시간표가 표시됩니다';

  @override
  String get timetable_setSubjectMsg => '선택과목을 설정하면 시간표가 표시됩니다';

  @override
  String get timetable_setSubject => '선택과목 설정';

  @override
  String get timetable_dayMon => '월';

  @override
  String get timetable_dayTue => '화';

  @override
  String get timetable_dayWed => '수';

  @override
  String get timetable_dayThu => '목';

  @override
  String get timetable_dayFri => '금';

  @override
  String get timetable_selectTitle => '선택과목 설정';

  @override
  String get timetable_selectAlert => '변경사항이 있습니다';

  @override
  String get timetable_selectDiscardMsg => '저장하지 않고 나가시겠습니까?';

  @override
  String get timetable_selectLeave => '나가기';

  @override
  String get timetable_selectSaved => '저장되었습니다';

  @override
  String timetable_selectCount(Object count) {
    return '$count개 과목 선택됨';
  }

  @override
  String get timetable_selectLoadError => '과목을 불러올 수 없습니다';

  @override
  String timetable_selectConflict(Object day, Object period, Object subject) {
    return '$day $period교시에 $subject과(와) 겹침';
  }

  @override
  String get timetable_selectSpecial => '특별실';

  @override
  String timetable_selectClass(Object classNum) {
    return '$classNum반';
  }

  @override
  String timetable_selectPeriod(Object day, Object period) {
    return '$day $period교시';
  }

  @override
  String get timetable_teacherSelectTitle => '수업 시간표 설정';

  @override
  String get timetable_teacherTab1 => '1학년';

  @override
  String get timetable_teacherTab2 => '2학년';

  @override
  String get timetable_teacherTab3 => '3학년';

  @override
  String get timetable_teacherAlert => '변경사항이 있습니다';

  @override
  String get timetable_teacherDiscardMsg => '저장하지 않고 나가시겠습니까?';

  @override
  String get timetable_teacherLeave => '나가기';

  @override
  String get timetable_teacherSaved => '저장되었습니다';

  @override
  String timetable_teacherCount(Object count) {
    return '총 $count개 수업 선택됨';
  }

  @override
  String get timetable_teacherLoadError => '과목을 불러올 수 없습니다';

  @override
  String get timetable_teacherSpecial => '특별실';

  @override
  String timetable_teacherClass(Object classNum) {
    return '$classNum반';
  }

  @override
  String timetable_conflictTitle(Object day, Object period) {
    return '$day요일 $period교시';
  }

  @override
  String get timetable_conflictQuestion => '어떤 과목을 듣나요?';

  @override
  String get timetable_colorPickerReset => '기본 색상으로 초기화';

  @override
  String get dday_screenTitle => 'D-day 관리';

  @override
  String get dday_addTitle => 'D-day 추가';

  @override
  String get dday_hint => '예: 중간고사, 수행평가';

  @override
  String get dday_selectDate => '날짜를 선택하세요';

  @override
  String get dday_addButton => '추가';

  @override
  String get dday_empty => 'D-day를 추가해보세요';

  @override
  String get dday_upcoming => '예정된 일정';

  @override
  String get dday_today => '오늘';

  @override
  String dday_daysPrefix(Object days) {
    return 'D-$days';
  }

  @override
  String dday_daysPastPrefix(Object days) {
    return 'D+$days';
  }

  @override
  String get dday_dday => 'D-Day';

  @override
  String get dday_school => '학사';

  @override
  String dday_added(Object title) {
    return '$title이(가) D-day에 추가되었습니다';
  }

  @override
  String get feedback_appTitle => '앱 건의사항 & 버그 제보';

  @override
  String get feedback_councilTitle => '학생회 건의사항';

  @override
  String get feedback_appHint => '버그가 발생한 상황이나 개선 사항을 자세히 적어주세요';

  @override
  String get feedback_councilHint => '학생회에 전달할 건의사항을 적어주세요';

  @override
  String get feedback_photoLabel => '사진 첨부 (최대 3장)';

  @override
  String get feedback_photoLimit => '사진은 최대 3장까지 첨부할 수 있습니다';

  @override
  String get feedback_noContent => '내용을 입력해주세요';

  @override
  String get feedback_success => '제보가 접수되었습니다';

  @override
  String get feedback_councilSuccess => '건의사항이 전달되었습니다';

  @override
  String get feedback_sendError => '전송에 실패했습니다';

  @override
  String get feedback_send => '보내기';

  @override
  String get feedback_listTitle => '앱 건의/버그 목록';

  @override
  String get feedback_listCouncilTitle => '학생회 건의사항 목록';

  @override
  String get feedback_empty => '건의사항이 없습니다';

  @override
  String get feedback_unknown => '알 수 없음';

  @override
  String feedback_photoCount(Object count) {
    return '사진 $count장';
  }

  @override
  String get feedback_reviewed => '확인됨';

  @override
  String get feedback_resolved => '해결됨';

  @override
  String get feedback_pending => '대기중';

  @override
  String get feedback_deleted => '삭제되었습니다';

  @override
  String get feedback_delete => '삭제';

  @override
  String get notiSetting_screenTitle => '알림 설정';

  @override
  String get notiSetting_mealSection => '급식 알림';

  @override
  String get notiSetting_breakfast => '조식 알림';

  @override
  String get notiSetting_lunch => '중식 알림';

  @override
  String get notiSetting_dinner => '석식 알림';

  @override
  String get notiSetting_boardSection => '게시판 알림';

  @override
  String get notiSetting_comment => '내 글 댓글 알림';

  @override
  String get notiSetting_commentDesc => '내 게시글에 댓글이 달리면 알림';

  @override
  String get notiSetting_reply => '대댓글 알림';

  @override
  String get notiSetting_replyDesc => '내 댓글에 답글이 달리면 알림';

  @override
  String get notiSetting_mention => '멘션 알림';

  @override
  String get notiSetting_mentionDesc => '댓글에서 누군가 나를 @로 언급하면 알림';

  @override
  String get notiSetting_newPost => '새 글 알림 (공지)';

  @override
  String get notiSetting_newPostDesc => '공지글이 올라오면 알림';

  @override
  String get notiSetting_popular => '인기글 알림';

  @override
  String get notiSetting_popularDesc => '좋아요 10개 이상 달성 시 알림';

  @override
  String get notiSetting_categorySection => '카테고리별 새 글 알림';

  @override
  String notiSetting_categoryDesc(Object category) {
    return '$category 게시판에 새 글이 올라오면 알림';
  }

  @override
  String get notiSetting_chatSection => '채팅 알림';

  @override
  String get notiSetting_chat => '메시지 알림';

  @override
  String get notiSetting_chatDesc => '새 채팅 메시지가 오면 알림';

  @override
  String get notiSetting_accountSection => '계정 알림';

  @override
  String get notiSetting_account => '승인/정지/역할 변경';

  @override
  String get notiSetting_accountDesc => '계정 상태 변경 시 알림';

  @override
  String get onboarding_meal => '급식 정보';

  @override
  String get onboarding_mealDesc => '조식/중식/석식 메뉴를\n한눈에 확인하세요';

  @override
  String get onboarding_timetable => '시간표';

  @override
  String get onboarding_timetableDesc => '선택과목 기반 시간표를\n자동으로 구성해드려요';

  @override
  String get onboarding_schedule => '일정 관리';

  @override
  String get onboarding_scheduleDesc => '개인 일정과 학사일정을\n한 곳에서 관리하세요';

  @override
  String get onboarding_board => '게시판';

  @override
  String get onboarding_boardDesc => '자유롭게 소통하고\n투표, 일정 공유도 가능해요';

  @override
  String get onboarding_skip => '건너뛰기';

  @override
  String get onboarding_next => '다음';

  @override
  String get onboarding_start => '시작하기';

  @override
  String get notiPermission_title => '알림 허용';

  @override
  String get notiPermission_desc => '알림을 허용하면 급식 메뉴 등\n다양한 알림을 받을 수 있어요';

  @override
  String get notiPermission_allow => '허용';

  @override
  String get notiPermission_later => '나중에';

  @override
  String get notiPermission_settingsDesc => '알림을 받으려면 설정에서\n알림 권한을 허용해 주세요';

  @override
  String get notiPermission_openSettings => '설정으로 이동';

  @override
  String get settings_title => '설정';

  @override
  String get settings_schoolSection => '학교 정보';

  @override
  String get settings_gradeClass => '학년 반 설정';

  @override
  String settings_gradeClassLabel(Object grade, Object classNum) {
    return '$grade학년 $classNum반';
  }

  @override
  String get settings_gradeClassError => '학년/반을 먼저 설정해주세요';

  @override
  String get settings_selectiveSubject => '선택과목 시간표';

  @override
  String get settings_themeSection => '테마';

  @override
  String get settings_light => '라이트';

  @override
  String get settings_dark => '다크';

  @override
  String get settings_system => '시스템';

  @override
  String get settings_notificationSection => '알림';

  @override
  String get settings_notification => '알림 설정';

  @override
  String get settings_feedbackSection => '건의사항';

  @override
  String get settings_appFeedback => '앱 건의사항 & 버그 제보';

  @override
  String get settings_councilFeedback => '학생회 건의사항';

  @override
  String get settings_etcSection => '기타';

  @override
  String get settings_privacy => '개인정보 처리방침';

  @override
  String settings_cacheLabel(Object cacheSize) {
    return '캐시 삭제$cacheSize';
  }

  @override
  String get settings_cacheSuccess => '캐시가 삭제되었습니다';

  @override
  String get settings_cacheDelete => '삭제';

  @override
  String get settings_appVersion => '앱 버전';

  @override
  String get settings_myAccount => '내 계정';

  @override
  String get settings_nameDefault => '이름 없음';

  @override
  String get settings_approved => '승인됨';

  @override
  String get settings_pendingApproval => '승인 대기중';

  @override
  String get settings_logout => '로그아웃';

  @override
  String get settings_login => '로그인';

  @override
  String get settings_loginDesc => 'Google 계정으로 로그인하세요';

  @override
  String get settings_loginKakao => 'Kakao 로그인';

  @override
  String get settings_loginApple => 'Apple 로그인';

  @override
  String get settings_loginGithub => 'GitHub 로그인';

  @override
  String get settings_loginGoogle => 'Google 로그인';

  @override
  String get settings_privacyTitle => '개인정보 처리방침';

  @override
  String get settings_privacyEffectiveDate => '시행일자: 2026년 4월 10일';

  @override
  String get settings_privacyIntro =>
      '한솔고등학교 앱(이하 \"앱\")은 「개인정보 보호법」 제30조에 따라 이용자의 개인정보를 보호하고, 이와 관련한 고충을 신속하게 처리하기 위하여 다음과 같이 개인정보 처리방침을 수립·공개합니다.';

  @override
  String get settings_privacySection1Title => '제1조 (개인정보의 처리 목적)';

  @override
  String get settings_privacySection1Intro =>
      '앱은 다음의 목적을 위하여 개인정보를 처리합니다. 처리한 개인정보는 아래 목적 이외의 용도로는 이용하지 않으며, 목적이 변경되는 경우 별도의 동의를 받겠습니다.';

  @override
  String get settings_privacySection1Content =>
      '1. 회원 가입 및 인증: 소셜 로그인(Google, Apple, Kakao, GitHub)을 통한 본인 확인 및 회원 식별\n2. 프로필 관리: 학교 구성원(학생, 졸업생, 교사, 학부모) 식별 및 학년·반 정보 관리\n3. 게시판 서비스: 게시글·댓글·좋아요·북마크·투표·익명글 기능 제공\n4. 1:1 채팅 서비스: 사용자 간 메시지 송수신\n5. 알림 서비스: 급식 알림, 댓글·멘션·인기글·새글·채팅·계정 상태 변경 푸시 알림\n6. 학사 정보 조회: 급식 메뉴, 시간표 정보 제공 및 로컬 알림\n7. 성적 관리: 시험 성적·목표 성적 저장 (기기 내 암호화 저장, 서버 미전송)\n8. 앱 개선: 이용 통계 분석 및 오류·충돌 수집을 통한 서비스 안정성 향상\n9. 부정 이용 방지: 신고·차단·계정 정지 처리 및 서비스 건전성 유지';

  @override
  String get settings_privacySection2Title => '제2조 (수집하는 개인정보의 항목 및 수집 방법)';

  @override
  String get settings_privacySection2Required => '필수 수집 항목';

  @override
  String get settings_privacySection2RequiredContent =>
      '• 이름: 소셜 로그인 프로필 또는 직접 입력\n• 이메일: 소셜 로그인 제공자로부터 자동 수집\n• 고유 사용자 식별자(UID): Firebase 인증 시 자동 생성\n• 로그인 제공자 정보: Google/Apple/Kakao/GitHub 로그인 시 자동 수집\n• 사용자 유형: 학생/졸업생/교사/학부모 중 직접 선택\n• 학년·반: 직접 입력';

  @override
  String get settings_privacySection2Optional => '선택 수집 항목';

  @override
  String get settings_privacySection2OptionalContent =>
      '• 프로필 사진: 소셜 로그인 프로필 또는 직접 업로드\n• 졸업연도: 졸업생인 경우 직접 입력\n• 담당 과목: 교사인 경우 직접 입력';

  @override
  String get settings_privacySection2Auto => '서비스 이용 중 자동 생성되는 정보';

  @override
  String get settings_privacySection2AutoContent =>
      '• 게시글·댓글·채팅 내용 (사용자가 작성한 텍스트 및 이미지)\n• 상호작용 기록 (좋아요·싫어요·북마크·투표 참여)\n• 신고·차단 기록\n• 검색 기록: 최근 검색어 최대 10개 (기기 내에만 저장)\n• 알림 설정값 (푸시·급식 알림 on/off 및 알림 시간)';

  @override
  String get settings_privacySection2AutoCollect => '자동 수집 항목';

  @override
  String get settings_privacySection2AutoCollectContent =>
      '• FCM 디바이스 토큰: 푸시 알림 발송을 위한 기기 식별 토큰\n• 앱 이용 로그: 화면 조회, 로그인/로그아웃, 게시글 작성·조회 등 (Firebase Analytics)\n• 오류·충돌 정보: 스택트레이스, 기기 OS 버전, 앱 버전 등 (Firebase Crashlytics)\n• 기기 정보: OS 종류·버전, 화면 크기, 앱 버전 (Firebase SDK 자동 수집)';

  @override
  String get settings_privacySection2LocalOnly => '기기 내에만 저장되는 정보 (서버 미전송)';

  @override
  String get settings_privacySection2LocalOnlyContent =>
      '• 시험 성적·목표 성적: Android Keystore / iOS Keychain 암호화 저장\n• D-day 목록: 암호화 로컬 저장\n• 임시저장 게시글, 테마·알림 시간 설정: 기기 내 저장';

  @override
  String get settings_privacySection3Title => '제3조 (개인정보의 보유 및 이용 기간)';

  @override
  String get settings_privacySection3Content =>
      '앱은 개인정보 수집·이용 목적이 달성된 후에는 해당 정보를 지체 없이 파기합니다.\n\n• 회원 정보 (프로필·인증): 회원 탈퇴 시까지\n• 게시글·댓글·첨부 이미지: 작성일로부터 4년 (고정 공지 제외)\n• 채팅 메시지: 회원 탈퇴 시까지\n• 앱 이용 로그 (Analytics): 수집일로부터 14개월\n• 오류·충돌 보고 (Crashlytics): 수집일로부터 90일';

  @override
  String get settings_privacySection4Title => '제4조 (개인정보의 제3자 제공)';

  @override
  String get settings_privacySection4Content =>
      '앱은 이용자의 개인정보를 제1조에서 명시한 범위 내에서만 처리하며, 이용자의 사전 동의 없이 제3자에게 제공하지 않습니다. 다만 다음의 경우에는 예외로 합니다.\n\n• 이용자가 사전에 동의한 경우\n• 법령의 규정에 의거하거나, 수사 목적으로 법령에 정해진 절차와 방법에 따라 수사기관의 요구가 있는 경우';

  @override
  String get settings_privacySection5Title => '제5조 (개인정보 처리의 위탁)';

  @override
  String get settings_privacySection5Content =>
      '앱은 원활한 서비스 제공을 위하여 다음과 같이 개인정보 처리 업무를 위탁하고 있습니다.\n\n• Google LLC (Firebase): 인증, 데이터 저장, 푸시 알림, 이용 통계, 오류 수집, 호스팅 — 소재국: 미국\n• Google LLC: Google 계정 로그인 인증 — 소재국: 미국\n• Apple Inc.: Apple 계정 로그인 인증 — 소재국: 미국\n• Kakao Corp.: 카카오 계정 로그인 인증 — 소재국: 한국\n• GitHub Inc. (Microsoft): GitHub 계정 로그인 인증 — 소재국: 미국';

  @override
  String get settings_privacySection6Title => '제6조 (개인정보의 국외 이전)';

  @override
  String get settings_privacySection6Content =>
      '앱은 「개인정보 보호법」 제28조의8에 따라 다음과 같이 개인정보를 국외로 이전하고 있습니다.\n\n• 이전받는 자: Google LLC\n• 이전되는 국가: 미국\n• 이전 항목: 회원 정보, 게시글·댓글·채팅 내용, 첨부 이미지, 이용 로그, 오류 정보, FCM 토큰\n• 이전 목적: 클라우드 서버를 통한 서비스 제공 및 앱 안정성 개선\n• 보유·이용 기간: 제3조에 명시된 기간과 동일\n• 보호 조치: Google Cloud 보안 인증(SOC 2, ISO 27001), 전송 구간 TLS 암호화, 저장 데이터 AES-256 암호화';

  @override
  String get settings_privacySection7Title => '제7조 (정보주체의 권리·의무 및 행사 방법)';

  @override
  String get settings_privacySection7Content =>
      '이용자(정보주체)는 언제든지 다음의 권리를 행사할 수 있습니다.\n\n1. 개인정보 열람 요구: 본인의 개인정보 처리 현황을 열람할 수 있습니다.\n2. 개인정보 정정·삭제 요구: 앱 내 프로필 수정 기능을 통해 이름·사진·학년·반 등을 직접 정정할 수 있으며, 게시글·댓글은 직접 삭제할 수 있습니다.\n3. 개인정보 처리정지 요구: 개인정보 처리의 정지를 요구할 수 있습니다.\n4. 동의 철회(회원 탈퇴): 앱 내 설정 → 계정 삭제 기능을 통해 언제든지 회원 탈퇴 및 동의 철회가 가능합니다. 탈퇴 시 서버에 저장된 회원 정보, 하위 데이터가 즉시 삭제됩니다.\n\n위 권리 행사는 앱 내 기능 또는 아래 개인정보 보호책임자에게 이메일로 요청하실 수 있으며, 지체 없이 조치하겠습니다.\n\n※ 만 14세 미만 아동의 경우 법정대리인이 해당 아동의 개인정보에 대한 열람, 정정·삭제, 처리정지를 요구할 수 있습니다.';

  @override
  String get settings_privacySection8Title => '제8조 (개인정보의 파기 절차 및 방법)';

  @override
  String get settings_privacySection8Content =>
      '앱은 개인정보의 보유 기간이 경과하거나 처리 목적이 달성된 때에는 지체 없이 해당 개인정보를 파기합니다.\n\n[파기 절차]\n• 회원 탈퇴 시: Firebase 인증 정보 삭제, Firestore 프로필 문서 및 하위 컬렉션(알림 등) 일괄 삭제\n• 게시글 자동 파기: 작성일로부터 4년이 경과한 비고정 게시글과 해당 첨부 이미지·댓글을 자동으로 일괄 삭제\n• 기기 내 데이터: 앱 삭제 시 SharedPreferences 및 SecureStorage 데이터 자동 삭제\n\n[파기 방법]\n• 전자적 파일: 복구 불가능한 방법으로 영구 삭제\n• 서버 저장 데이터: Firebase Firestore·Storage에서 문서 및 파일 영구 삭제';

  @override
  String get settings_privacySection9Title => '제9조 (개인정보의 안전성 확보 조치)';

  @override
  String get settings_privacySection9Content =>
      '앱은 「개인정보 보호법」 제29조에 따라 다음과 같은 안전성 확보 조치를 취하고 있습니다.\n\n1. 전송 구간 암호화: 모든 서버 통신은 HTTPS/TLS로 암호화됩니다.\n2. 접근 통제: Firestore Security Rules를 통해 본인 데이터만 수정 가능하도록 제한하고, 관리자 권한을 분리하고 있습니다.\n3. 민감 정보 암호화 저장: 시험 성적 등 민감 데이터는 Android Keystore / iOS Keychain을 이용하여 기기 내 암호화 저장합니다.\n4. 앱 무결성 검증: Firebase App Check(Android Play Integrity)를 적용하여 무단 접근을 방지합니다.\n5. 비밀번호 미보관: 소셜 로그인만 사용하며, 앱에서 비밀번호를 직접 저장하거나 관리하지 않습니다.\n6. 부정 이용 방지: 신고 기능에 5분당 3건 제한(rate limiting)을 적용하고 있습니다.';

  @override
  String get settings_privacySection10Title => '제10조 (자동 수집 장치의 설치·운영 및 거부)';

  @override
  String get settings_privacySection10Content =>
      '앱은 웹 쿠키를 사용하지 않습니다. 다만 Firebase Analytics SDK를 통해 앱 이용 로그(화면 조회, 이벤트 등)를 자동으로 수집합니다.\n\n• 수집 목적: 서비스 이용 통계 분석 및 앱 개선\n• 거부 방법: 기기 설정에서 광고 추적 제한을 활성화하거나, 앱을 삭제하여 수집을 중단할 수 있습니다.';

  @override
  String get settings_privacySection11Title => '제11조 (익명 게시에 관한 사항)';

  @override
  String get settings_privacySection11Content =>
      '앱은 게시판에서 익명 게시 기능을 제공합니다. 익명으로 작성된 게시글·댓글의 작성자 정보(이름 등)는 다른 이용자에게 표시되지 않습니다. 다만, 서비스 운영 및 신고 처리 목적으로 작성자 식별 정보(UID)는 서버에 보관됩니다.';

  @override
  String get settings_privacySection12Title => '제12조 (만 14세 미만 아동의 개인정보)';

  @override
  String get settings_privacySection12Content =>
      '앱은 고등학생 및 학교 관계자를 주 이용 대상으로 하며, 만 14세 미만 아동의 개인정보를 수집하지 않습니다. 만 14세 미만임이 확인된 경우 회원 가입이 제한될 수 있으며, 수집된 정보는 지체 없이 파기합니다.';

  @override
  String get settings_privacySection13Title => '제13조 (개인정보 보호책임자)';

  @override
  String get settings_privacySection13Content =>
      '앱은 개인정보 처리에 관한 업무를 총괄하고, 이용자의 불만 처리 및 피해 구제를 위하여 아래와 같이 개인정보 보호책임자를 지정하고 있습니다.\n\n• 성명: 추희도\n• 직위: 앱 개발자\n• 연락처: justinchoo0814@gmail.com\n\n개인정보 관련 문의, 불만, 피해 구제 등은 위 연락처로 문의해 주시기 바랍니다.';

  @override
  String get settings_privacySection14Title => '제14조 (권익 침해 구제 방법)';

  @override
  String get settings_privacySection14Content =>
      '이용자는 개인정보 침해로 인한 피해 구제를 아래 기관에 문의할 수 있습니다.';

  @override
  String get settings_privacySection14Link1 => '개인정보침해 신고센터 (KISA)';

  @override
  String get settings_privacySection14Phone1 => '118';

  @override
  String get settings_privacySection14Url1 => 'https://privacy.kisa.or.kr';

  @override
  String get settings_privacySection14Link2 => '개인정보 분쟁조정위원회';

  @override
  String get settings_privacySection14Phone2 => '1833-6972';

  @override
  String get settings_privacySection14Url2 => 'https://www.kopico.go.kr';

  @override
  String get settings_privacySection14Link3 => '대검찰청 사이버수사과';

  @override
  String get settings_privacySection14Phone3 => '1301';

  @override
  String get settings_privacySection14Url3 => 'https://www.spo.go.kr';

  @override
  String get settings_privacySection14Link4 => '경찰청 사이버수사국';

  @override
  String get settings_privacySection14Phone4 => '182';

  @override
  String get settings_privacySection14Url4 => 'https://ecrm.police.go.kr';

  @override
  String get settings_privacySection15Title => '제15조 (개인정보 처리방침의 변경)';

  @override
  String get settings_privacySection15Content =>
      '이 개인정보 처리방침은 시행일로부터 적용되며, 법령·정책 또는 서비스 변경에 따라 내용이 수정될 수 있습니다. 변경 사항이 있을 경우 시행일 7일 전부터 앱 내 공지사항 또는 푸시 알림을 통해 고지하겠습니다.\n\n• 공고일자: 2026년 4월 10일\n• 시행일자: 2026년 4월 10일';

  @override
  String get chat_title => '채팅';

  @override
  String get chat_loginRequired => '로그인이 필요합니다';

  @override
  String get chat_newChat => '새 채팅';

  @override
  String get chat_noChats => '채팅이 없습니다';

  @override
  String get chat_startTip => '게시글에서 사용자를 탭하면 채팅을 시작할 수 있어요';

  @override
  String get chat_unknownUser => '알 수 없음';

  @override
  String get chat_searchPlaceholder => '이름 또는 학번으로 검색';

  @override
  String get chat_noResults => '검색 결과가 없습니다';

  @override
  String get chat_loadingAdmins => '관리자를 불러오는 중...';

  @override
  String get chat_managerLabel => '매니저';

  @override
  String chat_leaveConfirmation(Object name) {
    return '$name 님과의 채팅방을 나가시겠습니까?\n상대방에게 퇴장 메시지가 표시됩니다.';
  }

  @override
  String get chat_leaveAction => '채팅방 나가기';

  @override
  String chat_leftMessage(Object name) {
    return '$name님이 채팅방을 나갔습니다.';
  }

  @override
  String chat_leftShort(Object name) {
    return '$name님이 나갔습니다.';
  }

  @override
  String get chat_leftSuccess => '채팅방을 나갔습니다';

  @override
  String get chat_leftError => '채팅방 나가기에 실패했습니다';

  @override
  String get chat_leaveConfirmationRoom =>
      '채팅방을 나가시겠습니까?\n상대방에게 퇴장 메시지가 표시됩니다.';

  @override
  String get chat_deleteForMe => '나만 삭제';

  @override
  String get chat_deleteForAll => '같이 삭제';

  @override
  String get chat_deletedMessage => '삭제된 메시지입니다.';

  @override
  String get chat_firstMessage => '첫 메시지를 보내보세요';

  @override
  String get chat_read => '읽음';

  @override
  String get chat_imageCaption => '[사진]';

  @override
  String get chat_imageSendError => '이미지 전송에 실패했습니다';

  @override
  String get chat_leaveButton => '나가기';

  @override
  String get chat_messagePlaceholder => '메시지를 입력하세요';

  @override
  String get chat_sendImage => '사진 보내기';

  @override
  String widget_currentPeriod(Object period) {
    return '$period교시는';
  }

  @override
  String widget_isClass(Object subject) {
    return '$subject이에요!';
  }

  @override
  String widget_willStart(Object subject) {
    return '$subject 시작 예정';
  }

  @override
  String widget_nextClass(Object period, Object subject) {
    return '$period교시 $subject';
  }

  @override
  String get widget_gradeNotSet => '학년/반을 설정하면\n시간표가 표시됩니다';

  @override
  String get widget_weekend => '주말에는 수업이 없어요';

  @override
  String get widget_loadingSchedule => '오늘 시간표를 불러오는 중...';

  @override
  String get widget_noClass => '오늘 남은 수업이 없어요';

  @override
  String get widget_morning => '오전';

  @override
  String get widget_afternoon => '오후';

  @override
  String get widget_timetableNotSet => '학년/반을 설정해주세요';

  @override
  String get widget_noMealInfo => '정보 없음';

  @override
  String get calendar_createSchedule => '일정 만들기';

  @override
  String get calendar_scheduleContent => '일정 내용을 입력하세요';

  @override
  String get calendar_startDate => '시작일';

  @override
  String get calendar_endDate => '종료일';

  @override
  String calendar_multiDay(Object days) {
    return '$days일간';
  }

  @override
  String get calendar_color => '색상';

  @override
  String get calendar_add => '추가';

  @override
  String get calendar_colorPreview => '미리보기';

  @override
  String get calendar_colorSelect => '선택';

  @override
  String get calendar_school => '학사';

  @override
  String get calendar_weekdaySun => '일';

  @override
  String get calendar_weekdayMon => '월';

  @override
  String get calendar_weekdayTue => '화';

  @override
  String get calendar_weekdayWed => '수';

  @override
  String get calendar_weekdayThu => '목';

  @override
  String get calendar_weekdayFri => '금';

  @override
  String get calendar_weekdaySat => '토';

  @override
  String data_teacherLabel(Object name) {
    return '교사 $name';
  }

  @override
  String data_parentLabel(Object name) {
    return '학부모 $name';
  }

  @override
  String data_graduateLabel(Object name) {
    return '졸업생 $name';
  }

  @override
  String get data_allergyEgg => '난류';

  @override
  String get data_allergyMilk => '우유';

  @override
  String get data_allergyBuckwheat => '메밀';

  @override
  String get data_allergyPeanut => '땅콩';

  @override
  String get data_allergyBean => '대두';

  @override
  String get data_allergyWheat => '밀';

  @override
  String get data_allergyMackerel => '고등어';

  @override
  String get data_allergyCrab => '게';

  @override
  String get data_allergyShrimp => '새우';

  @override
  String get data_allergyPork => '돼지고기';

  @override
  String get data_allergyPeach => '복숭아';

  @override
  String get data_allergyTomato => '토마토';

  @override
  String get data_allergySulfite => '아황산류';

  @override
  String get data_allergyWalnut => '호두';

  @override
  String get data_allergyChicken => '닭고기';

  @override
  String get data_allergyBeef => '쇠고기';

  @override
  String get data_allergySquid => '오징어';

  @override
  String get data_allergyShellfish => '조개류';

  @override
  String data_midterm(Object semester) {
    return '$semester학기 중간고사';
  }

  @override
  String data_final(Object semester) {
    return '$semester학기 기말고사';
  }

  @override
  String data_mock(Object year, Object mockLabel) {
    return '$year $mockLabel 모의고사';
  }

  @override
  String data_privateMock(Object year, Object mockLabel) {
    return '$year $mockLabel';
  }

  @override
  String data_exam(Object year) {
    return '$year 시험';
  }

  @override
  String data_suspendDays(Object days) {
    return '$days일';
  }

  @override
  String data_suspendHours(Object hours) {
    return '$hours시간';
  }

  @override
  String data_suspendMinutes(Object minutes) {
    return '$minutes분';
  }

  @override
  String data_suspendSeconds(Object seconds) {
    return '$seconds초';
  }

  @override
  String get noti_updateRequired => '필수 업데이트';

  @override
  String get noti_updateAvailable => '업데이트 안내';

  @override
  String get noti_updateDefault => '새로운 버전이 출시되었습니다.';

  @override
  String get noti_updateButton => '업데이트';

  @override
  String get noti_updateLater => '나중에';

  @override
  String get noti_popupDefault => '공지';

  @override
  String get noti_popupConfirm => '확인';

  @override
  String get noti_popupDismiss => '오늘 하루 안 보기';

  @override
  String get noti_boardChannelName => '게시판 알림';

  @override
  String get noti_boardChannelDesc => '새 댓글, 게시글 알림';

  @override
  String get noti_mealChannelName => '급식 알림';

  @override
  String get noti_mealChannelDesc => '급식 정보 알림을 제공합니다.';

  @override
  String get noti_mealBreakfast => '🍽️ 조식 알림';

  @override
  String get noti_mealLunch => '🍽️ 중식 알림';

  @override
  String get noti_mealDinner => '🍽️ 석식 알림';

  @override
  String noti_mealConfirm(Object mealLabel) {
    return '오늘의 $mealLabel 메뉴를 확인하세요';
  }

  @override
  String get noti_mealTestTitle => '🍽️ 중식 알림 (테스트)';

  @override
  String get noti_mealTestBody => '5초 후 알림 테스트';

  @override
  String get noti_mealTestDetail => '테스트 알림입니다.\n오늘의 중식 메뉴를 확인하세요!';

  @override
  String get noti_schoolName => '한솔고등학교';

  @override
  String get api_noInternet => '식단 정보를 확인하려면 인터넷에 연결하세요';

  @override
  String get api_mealNoData => '급식 정보가 없습니다.';

  @override
  String get api_menuLabel => '메뉴';

  @override
  String get api_calorieLabel => '칼로리';

  @override
  String get api_nutritionLabel => '영양정보';

  @override
  String get delete_confirm => '삭제';

  @override
  String get delete_cancel => '취소';

  @override
  String get offline_status => '오프라인 상태입니다';

  @override
  String get settings_languageSection => '언어';

  @override
  String get settings_langSystem => '시스템';

  @override
  String get settings_langKo => '한국어';

  @override
  String get settings_langEn => 'English';
}
