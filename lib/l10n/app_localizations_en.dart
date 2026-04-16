// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get main_accountDeleted =>
      'Your account has been deleted. Please sign up again.';

  @override
  String get login_canceled => 'Login was canceled';

  @override
  String get login_schoolName => 'Hansol High School';

  @override
  String get login_subtitle => 'Sign in to access more features';

  @override
  String get login_googleContinue => 'Continue with Google';

  @override
  String get login_appleContinue => 'Continue with Apple';

  @override
  String get login_kakaoContinue => 'Continue with Kakao';

  @override
  String get login_githubContinue => 'Continue with GitHub';

  @override
  String get login_skipButton => 'Do it later';

  @override
  String get profileSetup_nameRequired => 'Please enter your name';

  @override
  String get profileSetup_nameNoSpace => 'Name cannot contain spaces';

  @override
  String get profileSetup_studentIdError =>
      'Please enter the student ID correctly';

  @override
  String get profileSetup_saveFailed => 'Failed to save. Please try again.';

  @override
  String get profileSetup_signupRequest => 'Signup Request';

  @override
  String profileSetup_signupNotification(Object name) {
    return '$name has requested to sign up.';
  }

  @override
  String get profileSetup_userType => 'Role';

  @override
  String get profileSetup_student => 'Current Student';

  @override
  String get profileSetup_graduate => 'Graduate';

  @override
  String get profileSetup_teacher => 'Teacher';

  @override
  String get profileSetup_parent => 'Parent';

  @override
  String get profileSetup_name => 'Name';

  @override
  String get profileSetup_nameHint => 'Enter your name';

  @override
  String get profileSetup_studentId => 'Student ID';

  @override
  String get profileSetup_studentIdHint => 'e.g. 20301';

  @override
  String profileSetup_gradeClass(Object grade, Object classNum) {
    return 'Grade $grade, Class $classNum';
  }

  @override
  String get profileSetup_graduationYear => 'Graduation Year';

  @override
  String get profileSetup_graduationYearHint => 'e.g. 2025';

  @override
  String get profileSetup_teacherSubject => 'Subject (optional)';

  @override
  String get profileSetup_teacherSubjectHint => 'e.g. Math';

  @override
  String get profileSetup_parentInfo =>
      'Parents can use the bulletin board after registration.';

  @override
  String get profileSetup_privacyTitle =>
      'Consent to Personal Information Collection (Required)';

  @override
  String get profileSetup_privacyDescription =>
      'We collect basic information such as name and student ID for smooth service. Collected information is used only for app purposes and is immediately deleted upon account withdrawal.';

  @override
  String get profileSetup_updateTitle => 'Profile Update';

  @override
  String get profileSetup_setupTitle => 'Enter Information';

  @override
  String get profileSetup_updateSubtitle =>
      'Please update your information for the new semester';

  @override
  String get profileSetup_setupSubtitle => 'Welcome!';

  @override
  String get profileSetup_updateHint =>
      'Please verify your student ID, grade, and class';

  @override
  String get profileSetup_setupHint => 'Please enter basic information';

  @override
  String get profileSetup_updateButton => 'Update';

  @override
  String get profileSetup_completeButton => 'Complete';

  @override
  String get profileEdit_accountTitle => 'My Account';

  @override
  String get profileEdit_camera => 'Camera';

  @override
  String get profileEdit_gallery => 'Gallery';

  @override
  String get profileEdit_deletePhoto => 'Delete Photo';

  @override
  String get profileEdit_photoChangedSuccess =>
      'Profile photo has been changed';

  @override
  String get profileEdit_photoChangeFailed => 'Failed to change photo';

  @override
  String get profileEdit_photoDeletedSuccess =>
      'Profile photo has been deleted';

  @override
  String get profileEdit_photoDeleteFailed => 'Deletion failed';

  @override
  String get profileEdit_deleteAccountTitle => 'Delete Account';

  @override
  String get profileEdit_deleteAccountConfirm =>
      'Are you sure you want to delete your account?\nAll data will be deleted and cannot be recovered.';

  @override
  String get profileEdit_confirm => 'Confirm';

  @override
  String get profileEdit_emailLabel => 'Email';

  @override
  String get profileEdit_nameLabel => 'Name';

  @override
  String get profileEdit_finalConfirmTitle => 'Final Confirmation';

  @override
  String profileEdit_finalConfirmMessage(Object confirmLabel) {
    return 'Please enter $confirmLabel exactly to proceed.';
  }

  @override
  String profileEdit_inputPlaceholder(Object confirmLabel) {
    return 'Enter $confirmLabel';
  }

  @override
  String get profileEdit_withdrawButton => 'Delete Account';

  @override
  String get profileEdit_reauthRequired =>
      'Re-authentication required. Please sign in again.';

  @override
  String get profileEdit_reauthFailed =>
      'Re-authentication failed. Please sign in again.';

  @override
  String get profileEdit_deleteAccountFailed =>
      'Account deletion failed. Please try again.';

  @override
  String get profileEdit_studentId => 'Student ID';

  @override
  String get profileEdit_gradeClass => 'Grade/Class';

  @override
  String get profileEdit_graduationYear => 'Graduation Year';

  @override
  String get profileEdit_teacherSubject => 'Subject';

  @override
  String get profileEdit_loginProvider => 'Login';

  @override
  String get home_scheduleLoading => 'Loading schedule...';

  @override
  String get home_ddaySet => 'Set a D-day';

  @override
  String home_schoolInfo(Object grade, Object classNum) {
    return 'Hansol High Grade $grade Class $classNum';
  }

  @override
  String get home_schoolName => 'Hansol High School';

  @override
  String get home_lunchPreview => 'Loading meal info...';

  @override
  String get home_lunchNoInfo => 'No meal info for today';

  @override
  String get home_timetableTitle => 'Timetable';

  @override
  String get home_timetableSubtitle => 'Check this week\'s timetable';

  @override
  String get home_gradesTitle => 'Grades';

  @override
  String get home_gradesSubtitle => 'Record your exam scores';

  @override
  String get home_boardTitle => 'Board';

  @override
  String get home_boardSubtitle => 'Communicate freely';

  @override
  String get home_chatTitle => 'Chat';

  @override
  String get home_chatSubtitle => '1:1 Conversation';

  @override
  String get home_linkRiroschool => 'RiroSchool';

  @override
  String get home_linkOfficial => 'Hansol Official';

  @override
  String get home_admin => 'Admin';

  @override
  String get home_notification => 'Notifications';

  @override
  String get home_settings => 'Settings';

  @override
  String get home_writePost => 'Write post';

  @override
  String get home_search => 'Search';

  @override
  String get home_myPosts => 'My posts';

  @override
  String get home_postImage => 'Post image';

  @override
  String get meal_noInfo => 'No meal info';

  @override
  String get meal_noInfoEmpty => 'No meal information';

  @override
  String get meal_refreshHint => 'Tap to refresh';

  @override
  String meal_error(Object error) {
    return 'Error: $error';
  }

  @override
  String get meal_noData => 'No meal information';

  @override
  String get meal_nutritionTitle => 'Nutrition Info';

  @override
  String get meal_mealType => 'Meal';

  @override
  String get meal_calorie => 'Calories';

  @override
  String get meal_noInfoShort => 'No info';

  @override
  String get meal_nutrition => 'Nutritional Info';

  @override
  String get meal_allergy => 'Allergens';

  @override
  String get meal_today => 'Today';

  @override
  String get meal_breakfast => 'Breakfast';

  @override
  String get meal_lunch => 'Lunch';

  @override
  String get meal_dinner => 'Dinner';

  @override
  String get notice_noSchedule => 'No schedules';

  @override
  String get notice_continuousDeleteTitle => 'Delete Multi-day Schedule';

  @override
  String get notice_deleteThisDayOnly => 'Delete this day only';

  @override
  String get notice_deleteAllSchedule => 'Delete entire schedule';

  @override
  String get notice_noSchoolSchedule => 'No school schedule';

  @override
  String get board_title => 'Board';

  @override
  String get board_searchHint => 'Search title/content...';

  @override
  String get board_emptyPosts => 'No posts';

  @override
  String get board_searchEmptyQuery => 'Enter a search term';

  @override
  String get board_recentSearches => 'Recent Searches';

  @override
  String get board_clearAllSearches => 'Clear All';

  @override
  String get board_searchNoResults => 'No results found';

  @override
  String get board_accountSuspended => 'Your account is suspended';

  @override
  String board_suspendedRemaining(Object duration) {
    return 'Remaining: $duration';
  }

  @override
  String get board_awaitingAdminApproval => 'Awaiting admin approval';

  @override
  String get board_categoryAll => 'All';

  @override
  String get board_categoryFree => 'Free';

  @override
  String get board_categoryPopular => 'Popular';

  @override
  String get board_categoryQuestion => 'Questions';

  @override
  String get board_categoryInfoShare => 'Info Share';

  @override
  String get board_categoryLostFound => 'Lost & Found';

  @override
  String get board_categoryStudentCouncil => 'Student Council';

  @override
  String get board_categoryClub => 'Club';

  @override
  String get common_justNow => 'Just now';

  @override
  String common_minutesAgo(Object minutes) {
    return '${minutes}m ago';
  }

  @override
  String common_hoursAgo(Object hours) {
    return '${hours}h ago';
  }

  @override
  String common_daysAgo(Object days) {
    return '${days}d ago';
  }

  @override
  String get common_cancel => 'Cancel';

  @override
  String get common_delete => 'Delete';

  @override
  String get common_confirm => 'OK';

  @override
  String get common_save => 'Save';

  @override
  String get common_loginRequired => 'Login required';

  @override
  String get common_chatPartner => 'Chat partner';

  @override
  String get common_dateYmd => 'MMM d, yyyy';

  @override
  String get common_dateMdE => 'MMM d (E)';

  @override
  String get common_dateYM => 'MMMM yyyy';

  @override
  String get common_dateYmdE => 'MMM d, yyyy (E)';

  @override
  String get common_dateMdEHm => 'MMM d (E) HH:mm';

  @override
  String get common_dateYMdE => 'yyyy.M.d (E)';

  @override
  String get common_dateMdEEEE => 'EEEE, MMM d';

  @override
  String get post_resolved => 'Resolved';

  @override
  String get post_bookmark => 'Save';

  @override
  String get post_chat => 'Chat';

  @override
  String get post_share => 'Share';

  @override
  String get post_edit => 'Edit';

  @override
  String get post_delete => 'Delete';

  @override
  String get post_deleteByAdmin => 'Delete (Admin)';

  @override
  String get post_pinAsNotice => 'Pin as Notice';

  @override
  String get post_unpinNotice => 'Unpin Notice';

  @override
  String get post_report => 'Report';

  @override
  String get post_reportSelectReason => 'Select Report Reason';

  @override
  String get post_reportReasonSwearing => 'Swearing/Insults';

  @override
  String get post_reportReasonAdult => 'Adult Content';

  @override
  String get post_reportReasonSpam => 'Spam/Advertising';

  @override
  String get post_reportReasonPrivacy => 'Personal Info Exposure';

  @override
  String get post_reportReasonOther => 'Other';

  @override
  String get post_reportButton => 'Report';

  @override
  String get post_reportAlreadyReported => 'Already reported';

  @override
  String get post_reportSuccess => 'Report submitted';

  @override
  String get post_found => 'Found';

  @override
  String get post_resolvedLabel => 'Resolved';

  @override
  String post_comments(Object count) {
    return 'Comments $count';
  }

  @override
  String get post_firstComment => 'Be the first to comment';

  @override
  String post_replyTo(Object name) {
    return 'Reply to $name';
  }

  @override
  String get post_anonymous => 'Anonymous';

  @override
  String get post_commentPlaceholder => 'Enter a comment';

  @override
  String get post_confirmDeleteComment => 'Delete Comment';

  @override
  String get post_confirmDeleteCommentMessage => 'Delete this comment?';

  @override
  String get post_commentTooLong => 'Comment must be 1000 characters or less';

  @override
  String get post_commentRateLimit =>
      'You can only comment once every 10 seconds';

  @override
  String get post_pinMaxed => 'Maximum 3 pinned posts';

  @override
  String get post_pinSuccess => 'Pinned as notice';

  @override
  String get post_unpinSuccess => 'Notice unpinned';

  @override
  String post_eventAdded(Object date) {
    return 'Added to $date schedule';
  }

  @override
  String get post_deleteConfirm => 'Delete Post';

  @override
  String get post_deleteConfirmMessage => 'Are you sure?';

  @override
  String get post_resolvedMarked => 'Marked as resolved';

  @override
  String get post_anonymousAuthor => 'Anonymous (Author)';

  @override
  String post_anonymousNum(Object num) {
    return 'Anonymous $num';
  }

  @override
  String get post_authorBadge => 'Author';

  @override
  String get write_title => 'Write Post';

  @override
  String get write_editTitle => 'Edit Post';

  @override
  String get write_draftSave => 'Save Draft';

  @override
  String get write_draftSaved => 'Draft saved';

  @override
  String get write_unsavedChanges => 'You have an unsaved post';

  @override
  String get write_draftDelete => 'Delete';

  @override
  String get write_category => 'Category';

  @override
  String get write_titlePlaceholder => 'Enter title';

  @override
  String get write_contentPlaceholder => 'Enter content';

  @override
  String get write_eventAttach => 'Attach Event';

  @override
  String get write_pollAttach => 'Attach Poll';

  @override
  String get write_anonymous => 'Post Anonymously';

  @override
  String get write_pinAsNotice => 'Pin as Notice';

  @override
  String get write_expiresInfo =>
      'Posts are automatically deleted after 1 year';

  @override
  String get write_errorTitleRequired => 'Please enter a title';

  @override
  String get write_errorTitleTooLong => 'Title must be 200 characters or less';

  @override
  String get write_errorContentRequired => 'Please enter content';

  @override
  String get write_errorContentTooLong =>
      'Content must be 5000 characters or less';

  @override
  String get write_errorPollOptionsRequired => 'Enter at least 2 poll options';

  @override
  String get write_errorPollOptionTooLong =>
      'Poll option must be 100 characters or less';

  @override
  String get write_errorEventDateRequired => 'Please select event date';

  @override
  String get write_errorEventContentRequired => 'Please enter event content';

  @override
  String get write_errorEventContentTooLong =>
      'Event content must be 200 characters or less';

  @override
  String get write_errorRateLimit => 'You can only post once every 30 seconds';

  @override
  String get write_errorLoginRequired => 'Login required';

  @override
  String get write_errorProfileLoadFailed =>
      'Could not load profile. Please try again.';

  @override
  String get write_pinLimitExceeded => 'Maximum 3 pinned posts';

  @override
  String get write_pinLimitMessage =>
      'Unpin an existing notice or register as a regular post.';

  @override
  String get write_pinUnpinAction => 'Unpin';

  @override
  String get write_unpinFailed => 'Failed to unpin';

  @override
  String get write_registerWithoutPin => 'Register without pinning';

  @override
  String get write_noTitle => 'No title';

  @override
  String get write_eventContentHint =>
      'Event content (e.g. midterm, sports day)';

  @override
  String get write_eventSelectDate => 'Select date';

  @override
  String get write_eventStartTimeOptional => 'Start (Optional)';

  @override
  String get write_eventEndTimeOptional => 'End (Optional)';

  @override
  String write_pollOptionHint(Object num) {
    return 'Option $num';
  }

  @override
  String get write_pollAddOption => 'Add Option';

  @override
  String write_imageAddButton(Object current, Object max) {
    return 'Add Photos ($current/$max)';
  }

  @override
  String get myActivity_title => 'My Activity';

  @override
  String get myActivity_myPosts => 'My Posts';

  @override
  String get myActivity_myComments => 'My Comments';

  @override
  String get myActivity_savedPosts => 'Saved Posts';

  @override
  String get myActivity_noPosts => 'No posts written';

  @override
  String get myActivity_noComments => 'No comments written';

  @override
  String get bookmarks_title => 'Saved Posts';

  @override
  String get bookmarks_empty => 'No saved posts';

  @override
  String get bookmarks_emptyHelper =>
      'Tap the bookmark icon on posts to save them';

  @override
  String get notification_title => 'Notifications';

  @override
  String get notification_markAllRead => 'Mark All Read';

  @override
  String get notification_empty => 'No notifications';

  @override
  String notification_typeComment(Object name) {
    return '$name left a comment';
  }

  @override
  String notification_typeReply(Object name) {
    return '$name replied';
  }

  @override
  String get admin_title => 'Admin';

  @override
  String get admin_userManagement => 'User Management';

  @override
  String get admin_usersPending => 'Pending Approval';

  @override
  String get admin_usersSuspended => 'Suspended Users';

  @override
  String get admin_usersApproved => 'Regular Users';

  @override
  String get admin_boardManagement => 'Board Management';

  @override
  String get admin_reportsTab => 'Reports';

  @override
  String get admin_deleteLogs => 'Delete Logs';

  @override
  String get admin_feedback => 'Feedback';

  @override
  String get admin_feedbackCouncil => 'Council Feedback';

  @override
  String get admin_feedbackApp => 'App Feedback/Bugs';

  @override
  String get admin_emergencyNotice => 'Emergency Notice';

  @override
  String get admin_usersNoPending => 'No pending users';

  @override
  String get admin_usersNoApproved => 'No approved users';

  @override
  String get admin_usersNoSuspended => 'No suspended users';

  @override
  String get admin_usersApprove => 'Approve';

  @override
  String get admin_usersReject => 'Reject';

  @override
  String get admin_usersRemoveAdmin => 'Remove Admin';

  @override
  String get admin_usersMakeManager => 'Manager';

  @override
  String get admin_usersRemoveManager => 'Remove Manager';

  @override
  String get admin_usersMakeAdmin => 'Admin';

  @override
  String get admin_usersSuspend => 'Suspend';

  @override
  String get admin_usersDelete => 'Delete';

  @override
  String get admin_usersUnsuspend => 'Unsuspend';

  @override
  String admin_usersSuspendTitle(Object name) {
    return 'Suspend $name';
  }

  @override
  String get admin_usersSuspendSelectDuration => 'Select suspension duration';

  @override
  String get admin_usersSuspend1Hour => '1 hour';

  @override
  String get admin_usersSuspend6Hours => '6 hours';

  @override
  String get admin_usersSuspend12Hours => '12 hours';

  @override
  String get admin_usersSuspend1Day => '1 day';

  @override
  String get admin_usersSuspend3Days => '3 days';

  @override
  String get admin_usersSuspend7Days => '7 days';

  @override
  String get admin_usersSuspend30Days => '30 days';

  @override
  String admin_usersSuspendHours(Object hours) {
    return '$hours hours';
  }

  @override
  String admin_usersSuspendDays(Object days) {
    return '$days days';
  }

  @override
  String get admin_usersDeleteConfirm => 'Delete Account';

  @override
  String admin_usersDeleteConfirmMessage(Object name) {
    return 'Delete $name\'s account?';
  }

  @override
  String get admin_usersDeleteFinal => 'Final Confirmation';

  @override
  String admin_usersDeleteFinalMessage(Object name) {
    return 'Really delete $name\'s account?\nThis cannot be undone.';
  }

  @override
  String admin_usersSuspendedRemaining(Object duration) {
    return 'Remaining: $duration';
  }

  @override
  String admin_usersMinutesLeft(Object minutes) {
    return '${minutes}m';
  }

  @override
  String admin_usersHoursLeft(Object hours) {
    return '${hours}h';
  }

  @override
  String admin_usersDaysLeft(Object days) {
    return '${days}d';
  }

  @override
  String get admin_usersLessThan1Minute => 'Less than 1 min';

  @override
  String get admin_usersAccountApproved => 'Account Approved';

  @override
  String get admin_usersApprovedMessage => 'Your account has been approved.';

  @override
  String get admin_usersAccountRejected => 'Account Rejected';

  @override
  String get admin_usersRejectedMessage => 'Your account has been rejected.';

  @override
  String get admin_usersAccountSuspended => 'Account Suspended';

  @override
  String admin_usersSuspendedMessage(Object duration) {
    return 'Your account is suspended for $duration.';
  }

  @override
  String get admin_usersAccountDeleted => 'Account Deleted';

  @override
  String get admin_usersDeletedMessage =>
      'Your account has been deleted by admin.';

  @override
  String get admin_usersSuspendRemoved => 'Suspension Removed';

  @override
  String get admin_usersSuspendRemovedMessage =>
      'Your account suspension has been removed.';

  @override
  String get admin_reportsEmpty => 'No reports';

  @override
  String get admin_reportsViewPost => 'View Post';

  @override
  String get admin_reportsDeletePost => 'Delete Post';

  @override
  String get admin_reportsIgnore => 'Ignore';

  @override
  String get admin_logsEmpty => 'No deletion logs';

  @override
  String get admin_logsFeedbackDeleted => 'Feedback Deleted';

  @override
  String get admin_logsPostDeleted => 'Post Deleted';

  @override
  String admin_logsAuthor(Object name) {
    return 'Author: $name';
  }

  @override
  String admin_logsDeletedBy(Object name) {
    return 'Deleted by: $name';
  }

  @override
  String get admin_logsNoTitle => 'No title';

  @override
  String get admin_logsNoContent => 'No content';

  @override
  String get admin_logsUnknown => 'Unknown';

  @override
  String get admin_popupActivate => 'Activate Popup';

  @override
  String get admin_popupTypeEmergency => 'Emergency';

  @override
  String get admin_popupTypeNotice => 'Notice';

  @override
  String get admin_popupTypeEvent => 'Event';

  @override
  String get admin_popupTitle => 'Title';

  @override
  String get admin_popupContent => 'Content';

  @override
  String get admin_popupStartDate => 'Start Date';

  @override
  String get admin_popupEndDate => 'End Date';

  @override
  String get admin_popupDismissible => 'Allow \"Don\'t show today\"';

  @override
  String get admin_popupSave => 'Save';

  @override
  String get admin_popupSaved => 'Saved';

  @override
  String get event_cardTitle => 'Event Share';

  @override
  String get event_cardAddButton => 'Add to My Schedule';

  @override
  String get event_am => 'AM';

  @override
  String get event_pm => 'PM';

  @override
  String get poll_cardTitle => 'Poll';

  @override
  String poll_cardParticipants(Object count) {
    return '$count participants';
  }

  @override
  String get grade_screenTitle => 'Grades';

  @override
  String get grade_deleteTitle => 'Delete Exam';

  @override
  String grade_deleteMsg(Object examName) {
    return 'Delete $examName?';
  }

  @override
  String get grade_noDataMsg => 'No exam data';

  @override
  String get grade_targetTitle => 'Target Percentile by Subject';

  @override
  String get grade_targetGradeTitle => 'Target Grade by Subject';

  @override
  String get grade_notice => 'Grades are not saved on the server';

  @override
  String get grade_sujungTab => 'Early Admission';

  @override
  String get grade_jeongsiTab => 'Regular Admission';

  @override
  String grade_loadFailed(Object error) {
    return 'Failed to load: $error';
  }

  @override
  String get grade_addPrompt => 'Add an exam';

  @override
  String get grade_averageLabel => 'Average';

  @override
  String grade_averageRank(Object rank) {
    return 'Average grade $rank';
  }

  @override
  String get grade_classSetting => 'Grade & Class Setting';

  @override
  String get grade_grade => 'Grade';

  @override
  String get grade_class => 'Class';

  @override
  String get grade_percentile => 'Percentile';

  @override
  String get grade_standardScore => 'Standard Score';

  @override
  String get grade_rawScore => 'Raw Score';

  @override
  String get grade_rank => 'Grade';

  @override
  String get grade_noData => 'No data';

  @override
  String get grade_scoreNoData => 'No score data';

  @override
  String get grade_goalGrade => 'Target Grade';

  @override
  String get gradeInput_screenTitle => 'Add Exam';

  @override
  String get gradeInput_screenEdit => 'Edit Exam';

  @override
  String get gradeInput_typeSection => 'Exam Type';

  @override
  String get gradeInput_infoSection => 'Exam Information';

  @override
  String get gradeInput_year => 'Year';

  @override
  String get gradeInput_semester => 'Semester';

  @override
  String get gradeInput_grade => 'Grade';

  @override
  String get gradeInput_month => 'Month';

  @override
  String get gradeInput_privateLabel => 'Private Mock Name';

  @override
  String get gradeInput_subjectSection => 'Subjects & Scores';

  @override
  String get gradeInput_fromTimetable => 'Select from Timetable';

  @override
  String get gradeInput_mockSubjects => 'Select Mock Exam Subjects';

  @override
  String get gradeInput_addManual => 'Add Manually';

  @override
  String get gradeInput_noSubjects => 'Add subjects using the buttons above';

  @override
  String get gradeInput_subjectCol => 'Subject';

  @override
  String get gradeInput_rawScore => 'Raw';

  @override
  String get gradeInput_average => 'Avg';

  @override
  String get gradeInput_rank => 'Grade';

  @override
  String get gradeInput_achievement => 'Achievement';

  @override
  String get gradeInput_percentile => 'Percentile';

  @override
  String get gradeInput_standard => 'Standard';

  @override
  String get gradeInput_selectSubjects => 'Select Timetable Subjects';

  @override
  String get gradeInput_mockSubjectPicker => 'Select Mock Exam Subjects';

  @override
  String get gradeInput_noTimetable =>
      'No timetable saved. Please set up a timetable first.';

  @override
  String get gradeInput_allSubjectsAdded =>
      'All timetable subjects already added.';

  @override
  String get gradeInput_allMockAdded => 'All subjects already added.';

  @override
  String get gradeInput_addSubject => 'Add Subject';

  @override
  String get gradeInput_subjectName => 'Enter subject name';

  @override
  String gradeInput_addSubjectDuplicate(Object name) {
    return 'Subject \'$name\' already added.';
  }

  @override
  String get gradeInput_addMinSubjects => 'Add at least one subject.';

  @override
  String get gradeInput_privateNameRequired => 'Enter private mock name.';

  @override
  String get gradeInput_hintScore => '0-100';

  @override
  String get gradeInput_typeMidterm => 'Midterm';

  @override
  String get gradeInput_typeFinal => 'Final';

  @override
  String get gradeInput_typeMock => 'Mock Exam';

  @override
  String get gradeInput_typePrivateMock => 'Private Mock';

  @override
  String get gradeInput_monthMar => 'March';

  @override
  String get gradeInput_monthJun => 'June';

  @override
  String get gradeInput_monthSep => 'September';

  @override
  String get gradeInput_monthNov => 'November';

  @override
  String get gradeInput_privateHint => 'e.g. Megastudy #3';

  @override
  String gradeInput_yearSuffix(Object year) {
    return '$year';
  }

  @override
  String gradeInput_semesterSuffix(Object semester) {
    return 'Sem $semester';
  }

  @override
  String gradeInput_gradeSuffix(Object grade) {
    return 'Grade $grade';
  }

  @override
  String gradeInput_mockMonthSuffix(Object month) {
    return '$month Mock Exam';
  }

  @override
  String get timetable_screenTitle => 'Timetable';

  @override
  String get timetable_teacherScreenTitle => 'My Class Timetable';

  @override
  String timetable_classTitle(Object grade, Object classNum) {
    return 'Grade $grade Class $classNum Timetable';
  }

  @override
  String get timetable_setting => 'Class Settings';

  @override
  String get timetable_changeClass => 'Change Class';

  @override
  String get timetable_refresh => 'Refresh';

  @override
  String get timetable_loadError => 'Cannot load timetable';

  @override
  String get timetable_setTeachingMsg =>
      'Set teaching classes to view timetable';

  @override
  String get timetable_setSetting => 'Class Settings';

  @override
  String get timetable_setGradeMsg => 'Set grade/class first';

  @override
  String get timetable_setGrade => 'Set Grade/Class';

  @override
  String get timetable_set1stMsg => 'Set grade/class to view timetable';

  @override
  String get timetable_setSubjectMsg => 'Set electives to view timetable';

  @override
  String get timetable_setSubject => 'Set Electives';

  @override
  String get timetable_dayMon => 'Mon';

  @override
  String get timetable_dayTue => 'Tue';

  @override
  String get timetable_dayWed => 'Wed';

  @override
  String get timetable_dayThu => 'Thu';

  @override
  String get timetable_dayFri => 'Fri';

  @override
  String get timetable_selectTitle => 'Set Electives';

  @override
  String get timetable_selectAlert => 'Unsaved Changes';

  @override
  String get timetable_selectDiscardMsg => 'Leave without saving?';

  @override
  String get timetable_selectLeave => 'Leave';

  @override
  String get timetable_selectSaved => 'Saved';

  @override
  String timetable_selectCount(Object count) {
    return '$count subjects selected';
  }

  @override
  String get timetable_selectLoadError => 'Cannot load subjects';

  @override
  String timetable_selectConflict(Object day, Object period, Object subject) {
    return 'Conflicts with $subject on $day period $period';
  }

  @override
  String get timetable_selectSpecial => 'Special Room';

  @override
  String timetable_selectClass(Object classNum) {
    return 'Class $classNum';
  }

  @override
  String timetable_selectPeriod(Object day, Object period) {
    return '$day period $period';
  }

  @override
  String get timetable_teacherSelectTitle => 'Teaching Timetable Settings';

  @override
  String get timetable_teacherTab1 => 'Grade 1';

  @override
  String get timetable_teacherTab2 => 'Grade 2';

  @override
  String get timetable_teacherTab3 => 'Grade 3';

  @override
  String get timetable_teacherAlert => 'Unsaved Changes';

  @override
  String get timetable_teacherDiscardMsg => 'Leave without saving?';

  @override
  String get timetable_teacherLeave => 'Leave';

  @override
  String get timetable_teacherSaved => 'Saved';

  @override
  String timetable_teacherCount(Object count) {
    return '$count classes selected';
  }

  @override
  String get timetable_teacherLoadError => 'Cannot load subjects';

  @override
  String get timetable_teacherSpecial => 'Special Room';

  @override
  String timetable_teacherClass(Object classNum) {
    return 'Class $classNum';
  }

  @override
  String timetable_conflictTitle(Object day, Object period) {
    return '$day period $period';
  }

  @override
  String get timetable_conflictQuestion => 'Which subject do you take?';

  @override
  String get timetable_colorPickerReset => 'Reset to default color';

  @override
  String get dday_screenTitle => 'D-day Management';

  @override
  String get dday_addTitle => 'Add D-day';

  @override
  String get dday_hint => 'e.g. Midterm, Performance Assessment';

  @override
  String get dday_selectDate => 'Select a date';

  @override
  String get dday_addButton => 'Add';

  @override
  String get dday_empty => 'Add a D-day';

  @override
  String get dday_upcoming => 'Upcoming Events';

  @override
  String get dday_today => 'Today';

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
  String get dday_school => 'School';

  @override
  String dday_added(Object title) {
    return '$title added to D-day';
  }

  @override
  String get feedback_appTitle => 'App Feedback & Bug Report';

  @override
  String get feedback_councilTitle => 'Student Council Feedback';

  @override
  String get feedback_appHint =>
      'Please describe the bug or improvement in detail';

  @override
  String get feedback_councilHint =>
      'Enter your feedback for the student council';

  @override
  String get feedback_photoLabel => 'Photo Attachment (Max 3)';

  @override
  String get feedback_photoLimit => 'You can attach up to 3 photos';

  @override
  String get feedback_noContent => 'Please enter content';

  @override
  String get feedback_success => 'Report submitted';

  @override
  String get feedback_councilSuccess => 'Feedback delivered';

  @override
  String get feedback_sendError => 'Failed to send';

  @override
  String get feedback_send => 'Send';

  @override
  String get feedback_listTitle => 'App Feedback/Bug List';

  @override
  String get feedback_listCouncilTitle => 'Council Feedback List';

  @override
  String get feedback_empty => 'No feedback';

  @override
  String get feedback_unknown => 'Unknown';

  @override
  String feedback_photoCount(Object count) {
    return '$count photo(s)';
  }

  @override
  String get feedback_reviewed => 'Reviewed';

  @override
  String get feedback_resolved => 'Resolved';

  @override
  String get feedback_pending => 'Pending';

  @override
  String get feedback_deleted => 'Deleted';

  @override
  String get feedback_delete => 'Delete';

  @override
  String get notiSetting_screenTitle => 'Notification Settings';

  @override
  String get notiSetting_mealSection => 'Meal Notifications';

  @override
  String get notiSetting_breakfast => 'Breakfast Notification';

  @override
  String get notiSetting_lunch => 'Lunch Notification';

  @override
  String get notiSetting_dinner => 'Dinner Notification';

  @override
  String get notiSetting_boardSection => 'Board Notifications';

  @override
  String get notiSetting_comment => 'Comment Notification';

  @override
  String get notiSetting_commentDesc =>
      'Notify when someone comments on my post';

  @override
  String get notiSetting_reply => 'Reply Notification';

  @override
  String get notiSetting_replyDesc =>
      'Notify when someone replies to my comment';

  @override
  String get notiSetting_mention => 'Mention Notification';

  @override
  String get notiSetting_mentionDesc => 'Notify when @mentioned in a comment';

  @override
  String get notiSetting_newPost => 'New Post (Notice)';

  @override
  String get notiSetting_newPostDesc => 'Notify when notice is posted';

  @override
  String get notiSetting_popular => 'Popular Post';

  @override
  String get notiSetting_popularDesc => 'Notify when 10+ likes achieved';

  @override
  String get notiSetting_categorySection => 'New Post by Category';

  @override
  String notiSetting_categoryDesc(Object category) {
    return 'Notify when new post in $category';
  }

  @override
  String get notiSetting_chatSection => 'Chat Notifications';

  @override
  String get notiSetting_chat => 'Message Notification';

  @override
  String get notiSetting_chatDesc => 'Notify when new chat message';

  @override
  String get notiSetting_accountSection => 'Account Notifications';

  @override
  String get notiSetting_account => 'Approval/Suspension/Role Change';

  @override
  String get notiSetting_accountDesc => 'Notify on account status change';

  @override
  String get onboarding_meal => 'Meal Info';

  @override
  String get onboarding_mealDesc =>
      'Check breakfast, lunch, dinner\nmenus at a glance';

  @override
  String get onboarding_timetable => 'Timetable';

  @override
  String get onboarding_timetableDesc =>
      'Auto-generate timetable\nbased on your electives';

  @override
  String get onboarding_schedule => 'Schedule';

  @override
  String get onboarding_scheduleDesc =>
      'Manage personal and school\nschedules in one place';

  @override
  String get onboarding_board => 'Board';

  @override
  String get onboarding_boardDesc =>
      'Communicate freely,\nvote and share schedules';

  @override
  String get onboarding_skip => 'Skip';

  @override
  String get onboarding_next => 'Next';

  @override
  String get onboarding_start => 'Get Started';

  @override
  String get notiPermission_title => 'Enable Notifications';

  @override
  String get notiPermission_desc =>
      'Allow notifications to receive\nmeal menus and other updates';

  @override
  String get notiPermission_allow => 'Allow';

  @override
  String get notiPermission_later => 'Later';

  @override
  String get notiPermission_settingsDesc =>
      'Please allow notification\npermission in settings';

  @override
  String get notiPermission_openSettings => 'Open Settings';

  @override
  String get settings_title => 'Settings';

  @override
  String get settings_schoolSection => 'School Information';

  @override
  String get settings_gradeClass => 'Grade/Class Settings';

  @override
  String settings_gradeClassLabel(Object grade, Object classNum) {
    return 'Grade $grade, Class $classNum';
  }

  @override
  String get settings_gradeClassError => 'Please set grade/class first';

  @override
  String get settings_selectiveSubject => 'Elective Timetable';

  @override
  String get settings_themeSection => 'Theme';

  @override
  String get settings_light => 'Light';

  @override
  String get settings_dark => 'Dark';

  @override
  String get settings_system => 'System';

  @override
  String get settings_notificationSection => 'Notifications';

  @override
  String get settings_notification => 'Notification Settings';

  @override
  String get settings_feedbackSection => 'Feedback';

  @override
  String get settings_appFeedback => 'App Feedback & Bug Report';

  @override
  String get settings_councilFeedback => 'Student Council Feedback';

  @override
  String get settings_etcSection => 'Other';

  @override
  String get settings_privacy => 'Privacy Policy';

  @override
  String settings_cacheLabel(Object cacheSize) {
    return 'Clear Cache$cacheSize';
  }

  @override
  String get settings_cacheSuccess => 'Cache cleared';

  @override
  String get settings_cacheDelete => 'Delete';

  @override
  String get settings_appVersion => 'App Version';

  @override
  String get settings_myAccount => 'My Account';

  @override
  String get settings_nameDefault => 'No Name';

  @override
  String get settings_approved => 'Approved';

  @override
  String get settings_pendingApproval => 'Pending Approval';

  @override
  String get settings_logout => 'Logout';

  @override
  String get settings_login => 'Login';

  @override
  String get settings_loginDesc => 'Sign in with your Google account';

  @override
  String get settings_loginKakao => 'Kakao Login';

  @override
  String get settings_loginApple => 'Apple Login';

  @override
  String get settings_loginGithub => 'GitHub Login';

  @override
  String get settings_loginGoogle => 'Google Login';

  @override
  String get settings_privacyTitle => 'Privacy Policy';

  @override
  String get settings_privacyEffectiveDate => 'Effective Date: April 10, 2026';

  @override
  String get settings_privacyIntro =>
      'Hansol High School App (\"App\") establishes and discloses this Privacy Policy in accordance with Article 30 of the Personal Information Protection Act to protect users\' personal information and promptly address related complaints.';

  @override
  String get settings_privacySection1Title =>
      'Article 1 (Purpose of Processing)';

  @override
  String get settings_privacySection1Intro =>
      'The App processes personal information for the following purposes. Information will not be used beyond listed purposes, and separate consent will be obtained if purposes change.';

  @override
  String get settings_privacySection1Content =>
      '1. Registration & Authentication: Identity verification via social login (Google, Apple, Kakao, GitHub)\n2. Profile Management: Identifying school members (students, alumni, teachers, parents) and grade/class info\n3. Board Service: Posts, comments, likes, bookmarks, voting, anonymous posts\n4. Chat Service: User-to-user messaging\n5. Notifications: Meal alerts, comments, mentions, popular posts, new posts, chat, account status push notifications\n6. School Info: Meal menus, timetable, and local notifications\n7. Grade Management: Exam scores stored locally with encryption (not transmitted to server)\n8. App Improvement: Usage statistics and crash collection for stability\n9. Abuse Prevention: Reports, blocks, account suspension for service integrity';

  @override
  String get settings_privacySection2Title =>
      'Article 2 (Items & Methods of Collection)';

  @override
  String get settings_privacySection2Required => 'Required Items';

  @override
  String get settings_privacySection2RequiredContent =>
      '• Name: From social login profile or direct input\n• Email: Auto-collected from social login provider\n• UID: Auto-generated during Firebase authentication\n• Login Provider: Auto-collected during social login\n• User Type: Direct selection (student/alumnus/teacher/parent)\n• Grade/Class: Direct input';

  @override
  String get settings_privacySection2Optional => 'Optional Items';

  @override
  String get settings_privacySection2OptionalContent =>
      '• Profile Picture: From social login or direct upload\n• Graduation Year: Direct input if alumnus\n• Subject: Direct input if teacher';

  @override
  String get settings_privacySection2Auto => 'Auto-Generated During Use';

  @override
  String get settings_privacySection2AutoContent =>
      '• Posts, comments, chat content (text and images)\n• Interaction records (likes, dislikes, bookmarks, voting)\n• Report and block records\n• Search history: Up to 10 recent searches (stored locally only)\n• Notification settings (push/meal on/off and times)';

  @override
  String get settings_privacySection2AutoCollect => 'Auto-Collected Items';

  @override
  String get settings_privacySection2AutoCollectContent =>
      '• FCM Device Token: For push notification delivery\n• Usage Logs: Screen views, login/logout, post activity (Firebase Analytics)\n• Error/Crash Info: Stack trace, OS version, app version (Firebase Crashlytics)\n• Device Info: OS type/version, screen size, app version (Firebase SDK)';

  @override
  String get settings_privacySection2LocalOnly =>
      'Stored Locally Only (Not Transmitted)';

  @override
  String get settings_privacySection2LocalOnlyContent =>
      '• Exam Scores: Encrypted in Android Keystore / iOS Keychain\n• D-day List: Encrypted local storage\n• Draft Posts, Theme/Notification Settings: Device local storage';

  @override
  String get settings_privacySection3Title => 'Article 3 (Retention Period)';

  @override
  String get settings_privacySection3Content =>
      'The App deletes information without delay after collection purposes are fulfilled.\n\n• Member Info (Profile/Auth): Until account withdrawal\n• Posts, Comments, Images: 4 years from creation (except pinned)\n• Chat Messages: Until account withdrawal\n• Usage Logs (Analytics): 14 months from collection\n• Crash Reports (Crashlytics): 90 days from collection';

  @override
  String get settings_privacySection4Title =>
      'Article 4 (Third-Party Disclosure)';

  @override
  String get settings_privacySection4Content =>
      'The App processes personal information only within the scope specified in Article 1 and does not provide it to third parties without prior consent. Exceptions include:\n\n• When the user has given prior consent\n• When required by law or by investigative agencies following legal procedures';

  @override
  String get settings_privacySection5Title =>
      'Article 5 (Outsourcing of Processing)';

  @override
  String get settings_privacySection5Content =>
      'The App outsources the following personal information processing tasks:\n\n• Google LLC (Firebase): Authentication, data storage, push notifications, analytics, crash reporting, hosting — Location: USA\n• Google LLC: Google account login — Location: USA\n• Apple Inc.: Apple account login — Location: USA\n• Kakao Corp.: Kakao account login — Location: South Korea\n• GitHub Inc. (Microsoft): GitHub account login — Location: USA';

  @override
  String get settings_privacySection6Title =>
      'Article 6 (International Transfer)';

  @override
  String get settings_privacySection6Content =>
      'The App transfers personal information overseas in accordance with Article 28-8 of the Personal Information Protection Act:\n\n• Recipient: Google LLC\n• Country: United States\n• Items: Member info, posts, comments, chat content, images, usage logs, error info, FCM tokens\n• Purpose: Service delivery via cloud servers and app stability improvement\n• Retention: Same as Article 3\n• Safeguards: Google Cloud security certifications (SOC 2, ISO 27001), TLS encryption in transit, AES-256 encryption at rest';

  @override
  String get settings_privacySection7Title =>
      'Article 7 (Rights and Obligations of Data Subjects)';

  @override
  String get settings_privacySection7Content =>
      'Users (data subjects) may exercise the following rights at any time:\n\n1. Right to access: View your personal information processing status.\n2. Right to correction/deletion: Correct name, photo, grade, class via profile edit; delete your posts and comments directly.\n3. Right to suspend processing: Request suspension of personal information processing.\n4. Right to withdraw consent (account deletion): Withdraw consent and delete account via Settings → Delete Account. All server-stored data is immediately deleted.\n\nThese rights can be exercised through in-app features or by contacting the Privacy Officer below.\n\n※ For children under 14, a legal guardian may exercise these rights on their behalf.';

  @override
  String get settings_privacySection8Title =>
      'Article 8 (Destruction Procedures and Methods)';

  @override
  String get settings_privacySection8Content =>
      'The App destroys personal information without delay when the retention period expires or the processing purpose is achieved.\n\n[Destruction Procedures]\n• Account deletion: Firebase auth deletion, Firestore profile document and sub-collections batch deletion\n• Automatic post destruction: Non-pinned posts older than 4 years with their images and comments are automatically batch deleted\n• Device data: SharedPreferences and SecureStorage data automatically deleted upon app removal\n\n[Destruction Methods]\n• Electronic files: Permanently deleted using irrecoverable methods\n• Server data: Documents and files permanently deleted from Firebase Firestore/Storage';

  @override
  String get settings_privacySection9Title => 'Article 9 (Security Measures)';

  @override
  String get settings_privacySection9Content =>
      'The App takes the following security measures in accordance with Article 29 of the Personal Information Protection Act:\n\n1. Transport encryption: All server communications are encrypted with HTTPS/TLS.\n2. Access control: Firestore Security Rules restrict modifications to own data only, with separated admin privileges.\n3. Sensitive data encryption: Exam scores and other sensitive data are encrypted using Android Keystore / iOS Keychain.\n4. App integrity verification: Firebase App Check (Android Play Integrity) prevents unauthorized access.\n5. No password storage: Only social login is used; the app does not store or manage passwords directly.\n6. Abuse prevention: Report feature has rate limiting of 3 reports per 5 minutes.';

  @override
  String get settings_privacySection10Title =>
      'Article 10 (Automatic Collection Devices)';

  @override
  String get settings_privacySection10Content =>
      'The App does not use web cookies. However, it automatically collects app usage logs (screen views, events, etc.) through the Firebase Analytics SDK.\n\n• Collection purpose: Usage statistics analysis and app improvement\n• Opt-out: Enable ad tracking restrictions in device settings or uninstall the app.';

  @override
  String get settings_privacySection11Title => 'Article 11 (Anonymous Posting)';

  @override
  String get settings_privacySection11Content =>
      'The App provides anonymous posting on the bulletin board. Author information (name, etc.) of anonymous posts and comments is not shown to other users. However, author identification information (UID) is retained on the server for service operation and report processing purposes.';

  @override
  String get settings_privacySection12Title => 'Article 12 (Children Under 14)';

  @override
  String get settings_privacySection12Content =>
      'The App primarily targets high school students and school personnel, and does not collect personal information from children under 14. If a user is confirmed to be under 14, registration may be restricted, and collected information will be destroyed without delay.';

  @override
  String get settings_privacySection13Title => 'Article 13 (Privacy Officer)';

  @override
  String get settings_privacySection13Content =>
      'The App designates the following Privacy Officer to oversee personal information processing and handle user complaints and remedies:\n\n• Name: Heedo Choo\n• Position: App Developer\n• Contact: justinchoo0814@gmail.com\n\nPlease contact the above for personal information inquiries, complaints, or remedy requests.';

  @override
  String get settings_privacySection14Title =>
      'Article 14 (Remedies for Rights Infringement)';

  @override
  String get settings_privacySection14Content =>
      'Users may contact the following organizations for remedies regarding personal information infringement.';

  @override
  String get settings_privacySection14Link1 => 'KISA Privacy Report Center';

  @override
  String get settings_privacySection14Phone1 => '118';

  @override
  String get settings_privacySection14Url1 => 'https://privacy.kisa.or.kr';

  @override
  String get settings_privacySection14Link2 =>
      'Personal Information Dispute Mediation Committee';

  @override
  String get settings_privacySection14Phone2 => '1833-6972';

  @override
  String get settings_privacySection14Url2 => 'https://www.kopico.go.kr';

  @override
  String get settings_privacySection14Link3 =>
      'Supreme Prosecutors\' Office Cyber Investigation';

  @override
  String get settings_privacySection14Phone3 => '1301';

  @override
  String get settings_privacySection14Url3 => 'https://www.spo.go.kr';

  @override
  String get settings_privacySection14Link4 =>
      'National Police Agency Cyber Bureau';

  @override
  String get settings_privacySection14Phone4 => '182';

  @override
  String get settings_privacySection14Url4 => 'https://ecrm.police.go.kr';

  @override
  String get settings_privacySection15Title =>
      'Article 15 (Changes to Privacy Policy)';

  @override
  String get settings_privacySection15Content =>
      'This Privacy Policy is effective from the enforcement date and may be amended due to changes in laws, policies, or services. Any changes will be announced via in-app notices or push notifications at least 7 days before the enforcement date.\n\n• Announcement date: April 10, 2026\n• Enforcement date: April 10, 2026';

  @override
  String get chat_title => 'Chat';

  @override
  String get chat_loginRequired => 'Login required';

  @override
  String get chat_newChat => 'New Chat';

  @override
  String get chat_noChats => 'No chats';

  @override
  String get chat_startTip => 'Tap a user in a post to start chatting';

  @override
  String get chat_unknownUser => 'Unknown';

  @override
  String get chat_searchPlaceholder => 'Search by name or student ID';

  @override
  String get chat_noResults => 'No results';

  @override
  String get chat_loadingAdmins => 'Loading admins...';

  @override
  String get chat_managerLabel => 'Manager';

  @override
  String chat_leaveConfirmation(Object name) {
    return 'Leave chat with $name?\nA departure message will be shown.';
  }

  @override
  String get chat_leaveAction => 'Leave Chat';

  @override
  String chat_leftMessage(Object name) {
    return '$name has left the chat.';
  }

  @override
  String chat_leftShort(Object name) {
    return '$name has left.';
  }

  @override
  String get chat_leftSuccess => 'You have left the chat';

  @override
  String get chat_leftError => 'Failed to leave chat';

  @override
  String get chat_leaveConfirmationRoom =>
      'Leave this chat?\nA departure message will be shown.';

  @override
  String get chat_deleteForMe => 'Delete for me';

  @override
  String get chat_deleteForAll => 'Delete for all';

  @override
  String get chat_deletedMessage => 'Deleted message.';

  @override
  String get chat_firstMessage => 'Send the first message';

  @override
  String get chat_read => 'Read';

  @override
  String get chat_imageCaption => '[Photo]';

  @override
  String get chat_imageSendError => 'Failed to send image';

  @override
  String get chat_leaveButton => 'Leave';

  @override
  String get chat_messagePlaceholder => 'Enter message';

  @override
  String get chat_sendImage => 'Send photo';

  @override
  String widget_currentPeriod(Object period) {
    return 'Period $period:';
  }

  @override
  String widget_isClass(Object subject) {
    return 'It\'s $subject!';
  }

  @override
  String widget_willStart(Object subject) {
    return '$subject starts soon';
  }

  @override
  String widget_nextClass(Object period, Object subject) {
    return 'Period $period $subject';
  }

  @override
  String get widget_gradeNotSet => 'Set grade/class\nto view timetable';

  @override
  String get widget_weekend => 'No classes on weekends';

  @override
  String get widget_loadingSchedule => 'Loading today\'s schedule...';

  @override
  String get widget_noClass => 'No more classes today';

  @override
  String get widget_morning => 'AM';

  @override
  String get widget_afternoon => 'PM';

  @override
  String get widget_timetableNotSet => 'Please set your grade/class';

  @override
  String get widget_noMealInfo => 'No info';

  @override
  String get calendar_createSchedule => 'Create Schedule';

  @override
  String get calendar_scheduleContent => 'Enter schedule content';

  @override
  String get calendar_startDate => 'Start Date';

  @override
  String get calendar_endDate => 'End Date';

  @override
  String calendar_multiDay(Object days) {
    return '$days days';
  }

  @override
  String get calendar_color => 'Color';

  @override
  String get calendar_add => 'Add';

  @override
  String get calendar_colorPreview => 'Preview';

  @override
  String get calendar_colorSelect => 'Select';

  @override
  String get calendar_school => 'School';

  @override
  String get calendar_weekdaySun => 'Sun';

  @override
  String get calendar_weekdayMon => 'Mon';

  @override
  String get calendar_weekdayTue => 'Tue';

  @override
  String get calendar_weekdayWed => 'Wed';

  @override
  String get calendar_weekdayThu => 'Thu';

  @override
  String get calendar_weekdayFri => 'Fri';

  @override
  String get calendar_weekdaySat => 'Sat';

  @override
  String data_teacherLabel(Object name) {
    return 'Teacher $name';
  }

  @override
  String data_parentLabel(Object name) {
    return 'Parent $name';
  }

  @override
  String data_graduateLabel(Object name) {
    return 'Graduate $name';
  }

  @override
  String get data_allergyEgg => 'Eggs';

  @override
  String get data_allergyMilk => 'Milk';

  @override
  String get data_allergyBuckwheat => 'Buckwheat';

  @override
  String get data_allergyPeanut => 'Peanut';

  @override
  String get data_allergyBean => 'Soybean';

  @override
  String get data_allergyWheat => 'Wheat';

  @override
  String get data_allergyMackerel => 'Mackerel';

  @override
  String get data_allergyCrab => 'Crab';

  @override
  String get data_allergyShrimp => 'Shrimp';

  @override
  String get data_allergyPork => 'Pork';

  @override
  String get data_allergyPeach => 'Peach';

  @override
  String get data_allergyTomato => 'Tomato';

  @override
  String get data_allergySulfite => 'Sulfites';

  @override
  String get data_allergyWalnut => 'Walnut';

  @override
  String get data_allergyChicken => 'Chicken';

  @override
  String get data_allergyBeef => 'Beef';

  @override
  String get data_allergySquid => 'Squid';

  @override
  String get data_allergyShellfish => 'Shellfish';

  @override
  String data_midterm(Object semester) {
    return 'Semester $semester Midterm';
  }

  @override
  String data_final(Object semester) {
    return 'Semester $semester Final';
  }

  @override
  String data_mock(Object year, Object mockLabel) {
    return '$year $mockLabel Mock Exam';
  }

  @override
  String data_privateMock(Object year, Object mockLabel) {
    return '$year $mockLabel';
  }

  @override
  String data_exam(Object year) {
    return '$year Exam';
  }

  @override
  String data_suspendDays(Object days) {
    return '${days}d';
  }

  @override
  String data_suspendHours(Object hours) {
    return '${hours}h';
  }

  @override
  String data_suspendMinutes(Object minutes) {
    return '${minutes}m';
  }

  @override
  String data_suspendSeconds(Object seconds) {
    return '${seconds}s';
  }

  @override
  String get noti_updateRequired => 'Required Update';

  @override
  String get noti_updateAvailable => 'Update Available';

  @override
  String get noti_updateDefault => 'A new version has been released.';

  @override
  String get noti_updateButton => 'Update';

  @override
  String get noti_updateLater => 'Later';

  @override
  String get noti_popupDefault => 'Notice';

  @override
  String get noti_popupConfirm => 'OK';

  @override
  String get noti_popupDismiss => 'Don\'t show today';

  @override
  String get noti_boardChannelName => 'Board Notifications';

  @override
  String get noti_boardChannelDesc => 'New post and comment notifications';

  @override
  String get noti_mealChannelName => 'Meal Notifications';

  @override
  String get noti_mealChannelDesc => 'Provides meal information notifications.';

  @override
  String get noti_mealBreakfast => '🍽️ Breakfast Alert';

  @override
  String get noti_mealLunch => '🍽️ Lunch Alert';

  @override
  String get noti_mealDinner => '🍽️ Dinner Alert';

  @override
  String noti_mealConfirm(Object mealLabel) {
    return 'Check today\'s $mealLabel menu';
  }

  @override
  String get noti_mealTestTitle => '🍽️ Lunch Alert (Test)';

  @override
  String get noti_mealTestBody => 'Test notification in 5 seconds';

  @override
  String get noti_mealTestDetail =>
      'Test notification.\nCheck today\'s lunch menu!';

  @override
  String get noti_schoolName => 'Hansol High School';

  @override
  String get api_noInternet => 'Connect to the internet to check meal info';

  @override
  String get api_mealNoData => 'No meal information available.';

  @override
  String get api_menuLabel => 'Menu';

  @override
  String get api_calorieLabel => 'Calories';

  @override
  String get api_nutritionLabel => 'Nutrition';

  @override
  String get delete_confirm => 'Delete';

  @override
  String get delete_cancel => 'Cancel';

  @override
  String get offline_status => 'You are offline';

  @override
  String get settings_languageSection => 'Language';

  @override
  String get settings_langSystem => 'System';

  @override
  String get settings_langKo => '한국어';

  @override
  String get settings_langEn => 'English';

  @override
  String get error_generic => 'Something went wrong';

  @override
  String get error_retry => 'Retry';

  @override
  String get error_network => 'Please check your network connection';

  @override
  String get error_loadFailed => 'Failed to load data';
}
