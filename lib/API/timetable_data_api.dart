import 'dart:convert';
import 'dart:developer';

import 'package:hansol_high_school/API/nies_api_keys.dart';
import 'package:hansol_high_school/Data/subject.dart';
import 'package:hansol_high_school/Network/network_status.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TimetableDataApi {
  static const TAG = 'TimetableDataApi';

  var myTimetable = [
    Subject(subjectName: '문학', subjectClass: 1),
    Subject(subjectName: '수학Ⅰ', subjectClass: 1),
    Subject(subjectName: '물리학Ⅰ', subjectClass: 5),
    Subject(subjectName: '세계 문제와 미래 사회', subjectClass: 6),
    Subject(subjectName: '운동과 건강', subjectClass: 1),
    Subject(subjectName: '정보과학', subjectClass: 1),
    Subject(subjectName: '자율활동', subjectClass: 1),
    Subject(subjectName: '화학Ⅰ', subjectClass: 7),
    Subject(subjectName: '기하', subjectClass: 1),
    Subject(subjectName: '영어Ⅰ', subjectClass: 1),
    Subject(subjectName: '지구과학Ⅰ', subjectClass: 6),
    Subject(subjectName: '진로활동', subjectClass: 1),
  ];

  static Future<List<String>> getTimeTable({
    required DateTime date,
    required String grade,
    required String classNum,
  }) async {
    final formattedDate = DateFormat('yyyyMMdd').format(date);
    final cacheKey = '$formattedDate-$grade-$classNum';
    final prefs = await SharedPreferences.getInstance();

    if (prefs.containsKey(cacheKey)) {
      final cachedTimestamp = prefs.getInt('$cacheKey-timestamp') ?? 0;
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      const oneDayInMilliseconds = 12 * 60 * 60 * 1000;

      if (currentTime - cachedTimestamp < oneDayInMilliseconds) {
        final timetableData = prefs.getStringList(cacheKey);
        if (timetableData != null) {
          return timetableData;
        }
      } else {
        prefs.remove(cacheKey);
        prefs.remove('$cacheKey-timestamp');
      }
    }

    if (await NetworkStatus.isUnconnected()) {
      return ["시간표를 확인하려면 인터넷에 연결하세요"];
    }

    final requestURL = 'https://open.neis.go.kr/hub/hisTimetable?'
        'key=${niesApiKeys.NIES_API_KEY}'
        '&Type=json&ATPT_OFCDC_SC_CODE=${niesApiKeys.ATPT_OFCDC_SC_CODE}'
        '&SD_SCHUL_CODE=${niesApiKeys.SD_SCHUL_CODE}'
        '&ALL_TI_YMD=$formattedDate'
        '&GRADE=$grade'
        '&CLASS_NM=$classNum';

    log('$TAG: getTimeTable: $requestURL');

    final data = await fetchData(requestURL);
    if (data == null) return ["정보 없음"];

    final timetable = processTimetable(data['hisTimetable']);
    prefs.setStringList(cacheKey, timetable);
    prefs.setInt('$cacheKey-timestamp', DateTime.now().millisecondsSinceEpoch);

    return timetable;
  }

  static Future<Map<String, dynamic>?> fetchData(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) return null;
    return jsonDecode(response.body);
  }

  static List<String> processTimetable(List<dynamic> timetableArray) {
    List<String> resultList = [];

    for (var i = 0; i < timetableArray.length; i++) {
      final rowArray = timetableArray[i]['row'];
      if (rowArray != null) {
        for (var j = 0; j < rowArray.length; j++) {
          final itemObject = rowArray[j];
          final content = itemObject['ITRT_CNTNT'];
          resultList.add(content);
        }
      }
    }

    return resultList;
  }

  static Future<List<String>?> getSubjects({required int grade}) async {
    List<String> subjects = [];
    DateTime now = DateTime.now();
    int year = now.year;

    DateTime startDate = DateTime(year, 3, 1);
    DateTime endDate = DateTime(year, 3, 7);

    for (DateTime date = startDate;
        date.isBefore(endDate.add(const Duration(days: 1)));
        date = date.add(const Duration(days: 1))) {
      if (date.weekday == DateTime.saturday ||
          date.weekday == DateTime.sunday) {
        continue;
      }

      for (var i = 1; i < await getClassCount(grade) + 1; i++) {
        List<String> timetable = await getTimeTable(
            date: date, grade: grade.toString(), classNum: i.toString());

        subjects.addAll(timetable);
      }
    }

    subjects = subjects.toSet().toList()..sort();

    log(subjects.toString());
    return subjects;
  }

  static Future<List<List<String?>>> getCustomTimeTable({
    required List<Subject> userSubjects,
    required String grade,
    bool writeLog = false,
  }) async {
    List<List<String?>> customTimeTable = [
      [null, '', '', '', '', '', '', ''],
      [null, '', '', '', '', '', '', ''],
      [null, '', '', '', '', '', '', ''],
      [null, '', '', '', '', '', '', ''],
      [null, '', '', '', '', '', '', '']
    ];

    DateTime now = DateTime.now();
    int year = now.year;
    int month = now.month;
    int day = now.day;

    DateTime startDate = DateTime(year, month, day + 6);
    DateTime endDate = DateTime(year, month, day + 13);

    for (DateTime date = startDate;
        date.isBefore(endDate.add(const Duration(days: 1)));
        date = date.add(const Duration(days: 1))) {
      if (date.weekday == DateTime.saturday ||
          date.weekday == DateTime.sunday) {
        continue;
      }

      for (var subject in userSubjects) {
        List<String> timetable = await getTimeTable(
            date: date,
            grade: grade,
            classNum: subject.subjectClass.toString());

        log(timetable.toString());

        for (var i = 0; i < timetable.length; i++) {
          if (timetable[i] == subject.subjectName) {
            customTimeTable[date.weekday - 1][i + 1] = subject.subjectName;
          }
        }
      }
    }

    if (writeLog) {
      for (var weekday in customTimeTable) {
        log('day${customTimeTable.indexOf(weekday) + 1}: ${weekday.toString()}');
      }
    }

    return customTimeTable;
  }

  static Future<int> getClassCount(int grade) async {
    final cacheKey = 'classCount-$grade';
    final prefs = await SharedPreferences.getInstance();

    if (prefs.containsKey(cacheKey)) {
      final cachedTimestamp = prefs.getInt('$cacheKey-timestamp') ?? 0;
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      const twelveHoursInMilliseconds = 12 * 60 * 60 * 1000;

      if (currentTime - cachedTimestamp < twelveHoursInMilliseconds) {
        final cachedClassCount = prefs.getInt(cacheKey);
        if (cachedClassCount != null) {
          return cachedClassCount;
        }
      } else {
        prefs.remove(cacheKey);
        prefs.remove('$cacheKey-timestamp');
      }
    }

    final requestURL = 'https://open.neis.go.kr/hub/classInfo?'
        'key=${niesApiKeys.NIES_API_KEY}'
        '&Type=json&ATPT_OFCDC_SC_CODE=${niesApiKeys.ATPT_OFCDC_SC_CODE}'
        '&SD_SCHUL_CODE=${niesApiKeys.SD_SCHUL_CODE}'
        '&AY=${DateTime.now().year}'
        '&GRADE=$grade';

    log('$TAG: getClassCount: $requestURL');

    final data = await fetchData(requestURL);
    if (data == null) return 0;

    final classInfo = data['classInfo'][0]['head'][0];
    final classCount = classInfo['list_total_count'];

    prefs.setInt(cacheKey, classCount);
    prefs.setInt('$cacheKey-timestamp', DateTime.now().millisecondsSinceEpoch);

    return classCount;
  }
}
