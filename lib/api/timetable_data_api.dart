import 'dart:convert';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hansol_high_school/api/nies_api_keys.dart';
import 'package:hansol_high_school/data/subject.dart';
import 'package:hansol_high_school/network/network_status.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TimetableDataApi {
  static const TAG = 'TimetableDataApi';
  static const _subjectCacheKey = 'selectedSubjects';

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
      const oneDay = 12 * 60 * 60 * 1000;

      if (currentTime - cachedTimestamp < oneDay) {
        final timetableData = prefs.getStringList(cacheKey);
        if (timetableData != null) return timetableData;
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
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) return null;
      return jsonDecode(response.body);
    } catch (e) {
      log('fetchData error: $e');
      return null;
    }
  }

  static List<String> processTimetable(List<dynamic> timetableArray) {
    List<String> resultList = [];
    try {
      for (var data in timetableArray) {
        final rowArray = data['row'];
        if (rowArray != null) {
          for (var item in rowArray) {
            final content = item['ITRT_CNTNT'];
            if (content is String) {
              resultList.add(content);
            }
          }
        }
      }
    } catch (e) {
      log('processTimetable error: $e');
      return [];
    }
    return resultList;
  }

  static Future<List<String>?> getSubjects({required int grade}) async {
    List<String> subjects = [];
    DateTime now = DateTime.now();

    DateTime startDate = DateTime(now.year, 3, 8);
    DateTime endDate = DateTime(now.year, 3, 14);

    for (DateTime date = startDate;
        date.isBefore(endDate.add(const Duration(days: 1)));
        date = date.add(const Duration(days: 1))) {
      if (date.weekday >= 6) continue;

      for (var i = 1; i < await getClassCount(grade) + 1; i++) {
        List<String> timetable = await getTimeTable(
          date: date,
          grade: grade.toString(),
          classNum: i.toString(),
        );

        subjects.addAll(timetable.where((name) => !name.contains('[보강]')));
      }
    }

    subjects = subjects.toSet().toList()..sort();
    return subjects;
  }

  static Future<List<List<String?>>> getCustomTimeTable({
    required List<Subject> userSubjects,
    required String grade,
    bool writeLog = false,
  }) async {
    List<List<String?>> customTimeTable = [
      [],
      [null, '', '', '', '', '', '', ''],
      [null, '', '', '', '', '', '', ''],
      [null, '', '', '', '', '', '', ''],
      [null, '', '', '', '', '', '', ''],
      [null, '', '', '', '', '', '', ''],
    ];

    DateTime now = DateTime.now();
    DateTime startDate = now;
    DateTime endDate = now.add(const Duration(days: 6));

    for (DateTime date = startDate;
        date.isBefore(endDate.add(const Duration(days: 1)));
        date = date.add(const Duration(days: 1))) {
      if (date.weekday >= 6) continue;

      for (var subject in userSubjects) {
        List<String> timetable = await getTimeTable(
          date: date,
          grade: grade,
          classNum: subject.subjectClass.toString(),
        );

        try {
          for (var i = 0; i < timetable.length; i++) {
            if (timetable[i] == subject.subjectName) {
              customTimeTable[date.weekday][i + 1] = subject.subjectName;
            }
          }
        } catch (e) {
          log('getCustomTimeTable error: $e');
          return [
            [],
            [null, '', '', '', '', '', '', ''],
            [null, '', '', '', '', '', '', ''],
            [null, '', '', '', '', '', '', ''],
            [null, '', '', '', '', '', '', ''],
            [null, '', '', '', '', '', '', ''],
          ];
        }
      }
    }

    if (writeLog) {
      for (var weekday in customTimeTable.sublist(1)) {
        log('day${customTimeTable.indexOf(weekday)}: ${weekday.toString()}');
      }
    }

    return customTimeTable;
  }

  static Future<List<Subject>> loadCachedSubjects() async {
    final prefs = await SharedPreferences.getInstance();
    DateTime now = DateTime.now();
    if (now.month < 3 || (now.month == 3 && now.day < 1)) {
      await prefs.remove(_subjectCacheKey);
      return [];
    }

    final jsonString = prefs.getString(_subjectCacheKey);
    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList
          .map((item) => Subject(
                subjectName: item['subjectName'],
                subjectClass: item['subjectClass'],
              ))
          .toList();
    } catch (e) {
      log('loadCachedSubjects error: $e');
      return [];
    }
  }

  static Future<void> saveSubjectsToCache(List<Subject> subjects) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = subjects
        .map((s) => {
              'subjectName': s.subjectName,
              'subjectClass': s.subjectClass,
            })
        .toList();
    final jsonString = json.encode(jsonList);
    await prefs.setString(_subjectCacheKey, jsonString);
  }

  static Future<int> getClassCount(int grade) async {
    final cacheKey = 'classCount-$grade';
    final prefs = await SharedPreferences.getInstance();

    if (prefs.containsKey(cacheKey)) {
      final cachedTimestamp = prefs.getInt('$cacheKey-timestamp') ?? 0;
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      const twelveHours = 12 * 60 * 60 * 1000;

      if (currentTime - cachedTimestamp < twelveHours) {
        final cachedClassCount = prefs.getInt(cacheKey);
        if (cachedClassCount != null) return cachedClassCount;
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

  static Future<List<Subject>> getAllSubjectCombinations(
      {required int grade}) async {
    Set<Subject> subjectSet = {};
    DateTime now = DateTime.now();
    DateTime startDate = DateTime(now.year, 3, 8);
    DateTime endDate = DateTime(now.year, 3, 14);

    for (DateTime date = startDate;
        date.isBefore(endDate.add(const Duration(days: 1)));
        date = date.add(const Duration(days: 1))) {
      if (date.weekday >= 6) continue;

      int classCount = await getClassCount(grade);

      for (int classNum = 1; classNum <= classCount; classNum++) {
        List<String> timetable = await getTimeTable(
          date: date,
          grade: grade.toString(),
          classNum: classNum.toString(),
        );

        subjectSet.addAll(timetable
            .where((name) => !name.contains('[보강]'))
            .map((name) => Subject(subjectName: name, subjectClass: classNum)));
      }
    }

    List<Subject> subjectList = subjectSet.toList();

    subjectList.sort((a, b) {
      int nameCompare = a.subjectName.compareTo(b.subjectName);
      if (nameCompare != 0) return nameCompare;
      return a.subjectClass.compareTo(b.subjectClass);
    });

    return subjectList;
  }

  static Future<List<Subject>> getSubjectsFromAdminFirestore(int grade) async {
    List<Subject> result = [];

    final subjectDoc =
        FirebaseFirestore.instance.collection("subjects").doc(grade.toString());

    final collections = await subjectDoc.collection("과목").get();

    for (final subjectCol in collections.docs) {
      final metaDoc =
          await subjectCol.reference.collection('meta').doc('meta').get();
      if (metaDoc.exists) {
        final data = metaDoc.data()!;
        result.add(Subject(
          subjectName: subjectCol.id,
          subjectClass: -1,
          category: data["category"],
          isOriginal: data["isOriginal"] ?? false,
        ));
      }
    }

    return result;
  }
}
