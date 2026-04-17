/// API 계층에서 사용하는 센티널 문자열 상수
/// UI 표시용이 아닌, 데이터 유무 판별용으로 == 비교에 사용됨
class ApiStrings {
  ApiStrings._();

  static const mealNoData = '급식 정보가 없습니다.';
  static const mealNoDataLegacy = '급식 정보가 없습니다';
  static const mealNoInternet = '식단 정보를 확인하려면 인터넷에 연결하세요';

  static const timetableNoInternet = '시간표를 확인하려면 인터넷에 연결하세요';
  static const timetableNoData = '정보 없음';

  static const noticeNoInternet = '학사일정을 확인하려면 인터넷에 연결하세요';
  static const noticeNoData = '학사일정이 없습니다';
}
