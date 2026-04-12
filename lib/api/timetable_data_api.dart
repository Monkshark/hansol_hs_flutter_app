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
  static const _tag = 'TimetableDataApi';
  static const _subjectCacheKeyPrefix = 'subjects_grade_';

  static Future<Map<String, Map<String, List<String>>>> getTimeTable({
    required DateTime startDate,
    required DateTime endDate,
    required String grade,
    String? classNum,
  }) async {
    final formattedStartDate = DateFormat('yyyyMMdd').format(startDate);
    final formattedEndDate = DateFormat('yyyyMMdd').format(endDate);
    final cacheKey =
        '$formattedStartDate-$formattedEndDate-$grade${classNum != null ? '-$classNum' : ''}';
    final prefs = await SharedPreferences.getInstance();

    log('$_tag: getTimeTable cacheKey=$cacheKey');
    if (prefs.containsKey(cacheKey)) {
      final cachedTimestamp = prefs.getInt('$cacheKey-timestamp') ?? 0;
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      const oneDay = 12 * 60 * 60 * 1000;
      const maxStale = 3 * 24 * 60 * 60 * 1000; // SWR: 3일까지 stale 허용

      final cachedData = prefs.getString(cacheKey);
      if (cachedData != null) {
        final age = currentTime - cachedTimestamp;
        if (age < oneDay) {
          log('$_tag: getTimeTable cache HIT');
          final decoded = jsonDecode(cachedData) as Map<String, dynamic>;
          return decoded.map((key, value) => MapEntry(
                key,
                (value as Map<String, dynamic>)
                    .map((k, v) => MapEntry(k, List<String>.from(v))),
              ));
        } else if (age < maxStale) {
          // SWR: stale 캐시 즉시 반환, 백그라운드 갱신은 다음 호출에서 처리
          log('$_tag: getTimeTable stale cache (${(age / 3600000).toStringAsFixed(1)}h old)');
          final decoded = jsonDecode(cachedData) as Map<String, dynamic>;
          return decoded.map((key, value) => MapEntry(
                key,
                (value as Map<String, dynamic>)
                    .map((k, v) => MapEntry(k, List<String>.from(v))),
              ));
        } else {
          prefs.remove(cacheKey);
          prefs.remove('$cacheKey-timestamp');
        }
      }
    }

    if (await NetworkStatus.isUnconnected()) {
      return {
        "error": {
          "error": ["시간표를 확인하려면 인터넷에 연결하세요"]
        }
      };
    }

    final requestURL = 'https://open.neis.go.kr/hub/hisTimetable?'
        'key=${niesApiKeys.NIES_API_KEY}'
        '&Type=json&pIndex=1&pSize=1000'
        '&ATPT_OFCDC_SC_CODE=${niesApiKeys.ATPT_OFCDC_SC_CODE}'
        '&SD_SCHUL_CODE=${niesApiKeys.SD_SCHUL_CODE}'
        '&TI_FROM_YMD=$formattedStartDate'
        '&TI_TO_YMD=$formattedEndDate'
        '&GRADE=$grade'
        '${classNum != null ? '&CLASS_NM=$classNum' : ''}';

    final data = await _fetchData(requestURL);
    if (data == null) {
      return {
        "error": {
          "error": ["정보 없음"]
        }
      };
    }

    if (data['hisTimetable'] == null) {
      return {"error": {"error": ["정보 없음"]}};
    }
    final timetable = _processTimetable(data['hisTimetable']);
    if (!timetable.containsKey('error')) {
      final encodedData = jsonEncode(timetable);
      prefs.setString(cacheKey, encodedData);
      prefs.setInt('$cacheKey-timestamp', DateTime.now().millisecondsSinceEpoch);
    }

    return timetable;
  }

  static Future<Map<String, dynamic>?> _fetchData(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        log('$_tag: _fetchData: Failed with status code ${response.statusCode}');
        return null;
      }
      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      log('$_tag: _fetchData error: $e');
      return null;
    }
  }

  static Map<String, Map<String, List<String>>> _processTimetable(
      List<dynamic> timetableArray) {
    Map<String, Map<String, List<String>>> resultMap = {};
    try {
      for (var data in timetableArray) {
        final rowArray = data['row'] as List<dynamic>?;
        if (rowArray == null) continue;
        for (var item in rowArray) {
          final rawClassNum = item['CLASS_NM'];
          final date = item['ALL_TI_YMD'] as String?;
          final content = item['ITRT_CNTNT'] as String?;
          final perio = int.tryParse(item['PERIO']?.toString() ?? '');
          if (date == null || content == null || perio == null) continue;

          final classNum = rawClassNum?.toString() ?? 'special';

          final dayMap = resultMap.putIfAbsent(date, () => {});
          final classList = dayMap.putIfAbsent(classNum, () => []);

          while (classList.length < perio) {
            classList.add('');
          }
          classList[perio - 1] = content;
        }
      }
    } catch (e) {
      log('$_tag: _processTimetable error: $e');
      return {
        "error": {"error": []}
      };
    }
    return resultMap;
  }

  static Future<Map<String, Map<String, List<String>>>> _getWeekTimetableWithFallback(
      String grade) async {
    final now = DateTime.now();
    final thisMonday = now.subtract(Duration(days: now.weekday - 1));

    var timetable = await getTimeTable(
      startDate: thisMonday,
      endDate: thisMonday.add(const Duration(days: 4)),
      grade: grade,
    );
    if (_hasData(timetable)) return timetable;

    final nextMonday = thisMonday.add(const Duration(days: 7));
    timetable = await getTimeTable(
      startDate: nextMonday,
      endDate: nextMonday.add(const Duration(days: 4)),
      grade: grade,
    );
    if (_hasData(timetable)) return timetable;

    final prevMonday = thisMonday.subtract(const Duration(days: 7));
    timetable = await getTimeTable(
      startDate: prevMonday,
      endDate: prevMonday.add(const Duration(days: 4)),
      grade: grade,
    );
    return timetable;
  }

  static bool _hasData(Map<String, Map<String, List<String>>> timetable) {
    if (timetable.containsKey('error')) return false;
    return timetable.values.any((classMap) =>
        classMap.values.any((subjects) => subjects.isNotEmpty));
  }

  static Future<List<String>?> getSubjects({required int grade}) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'subjects-$grade';
    final cachedData = prefs.getString(cacheKey);
    if (cachedData != null) {
      final cachedTimestamp = prefs.getInt('$cacheKey-timestamp') ?? 0;
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      const oneWeek = 7 * 24 * 60 * 60 * 1000;
      if (currentTime - cachedTimestamp < oneWeek) {
        return jsonDecode(cachedData).cast<String>();
      }
    }

    List<String> subjects = [];

    final timetable = await _getWeekTimetableWithFallback(grade.toString());

    timetable.forEach((date, classMap) {
      if (date == 'error') return;
      classMap.forEach((classNum, subjectsList) {
        subjects.addAll(subjectsList
            .where((name) => name.isNotEmpty && !name.contains('[보강]') && name != '토요휴업일'));
      });
    });

    subjects = subjects.toSet().toList()..sort();
    await prefs.setString(cacheKey, jsonEncode(subjects));
    await prefs.setInt(
        '$cacheKey-timestamp', DateTime.now().millisecondsSinceEpoch);
    return subjects;
  }

  static Future<List<List<String?>>> getCustomTimeTable({
    required List<Subject> userSubjects,
    required String grade,
  }) async {
    const maxPeriods = 7;
    List<List<String?>> customTimeTable = List.generate(
      6,
      (i) => i == 0 ? [] : [null, ...List.filled(maxPeriods, '')],
    );

    DateTime now = DateTime.now();
    DateTime startDate = now;
    DateTime endDate = now.add(const Duration(days: 6));

    try {
      final timetable = await getTimeTable(
        startDate: startDate,
        endDate: endDate,
        grade: grade,
        classNum: null,
      );

      final classToSubjects = <int, List<Subject>>{};
      for (var subject in userSubjects) {
        classToSubjects
            .putIfAbsent(subject.subjectClass, () => [])
            .add(subject);
      }

      timetable.forEach((date, classMap) {
        int weekday = DateFormat('yyyyMMdd').parse(date).weekday;
        if (weekday >= 6) return;

        classMap.forEach((classNum, subjectsList) {
          final classSubjects = classToSubjects[int.parse(classNum)] ?? [];
          for (var subject in classSubjects) {
            for (var i = 0; i < subjectsList.length && i < maxPeriods; i++) {
              if (subjectsList[i] == subject.subjectName &&
                  subject.subjectName != '토요휴업일') {
                customTimeTable[weekday][i + 1] = subject.subjectName;
              }
            }
          }
        });
      });
    } catch (e) {
      log('$_tag: getCustomTimeTable error: $e');
      return List.generate(
        6,
        (i) => i == 0 ? [] : [null, ...List.filled(maxPeriods, '')],
      );
    }

    return customTimeTable;
  }

  static Future<int> getClassCount(int grade) async {
    final cacheKey = 'classCount-$grade';
    final prefs = await SharedPreferences.getInstance();
    final cachedClassCount = prefs.getInt(cacheKey);
    final cachedTimestamp = prefs.getInt('$cacheKey-timestamp') ?? 0;
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    const oneWeek = 7 * 24 * 60 * 60 * 1000;

    if (cachedClassCount != null && currentTime - cachedTimestamp < oneWeek) {
      return cachedClassCount;
    }

    final requestURL = 'https://open.neis.go.kr/hub/classInfo?'
        'key=${niesApiKeys.NIES_API_KEY}'
        '&Type=json&ATPT_OFCDC_SC_CODE=${niesApiKeys.ATPT_OFCDC_SC_CODE}'
        '&SD_SCHUL_CODE=${niesApiKeys.SD_SCHUL_CODE}'
        '&AY=${DateTime.now().year}'
        '&GRADE=$grade';

    final data = await _fetchData(requestURL);
    if (data == null) {
      return 0;
    }

    if (data['classInfo'] == null) return 0;
    final classCount =
        data['classInfo'][0]['head'][0]['list_total_count'] as int;
    await prefs.setInt(cacheKey, classCount);
    await prefs.setInt('$cacheKey-timestamp', currentTime);
    return classCount;
  }

  static Future<List<Subject>?> _loadCachedSubjects(int grade) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = '$_subjectCacheKeyPrefix$grade';
    final timestampKey = '${cacheKey}_timestamp';

    final jsonString = prefs.getString(cacheKey);
    final cachedTimestamp = prefs.getInt(timestampKey) ?? 0;
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    const oneWeek = 7 * 24 * 60 * 60 * 1000;

    if (jsonString != null && currentTime - cachedTimestamp < oneWeek) {
      try {
        final List<dynamic> jsonList = json.decode(jsonString);
        final subjects = jsonList
            .map((item) => Subject(
                  subjectName: item['subjectName'],
                  subjectClass: item['subjectClass'],
                ))
            .toList();
        return subjects;
      } catch (e) {
        log('$_tag: _loadCachedSubjects error: $e');
        return null;
      }
    }
    return null;
  }

  static Future<void> _saveSubjectsToCache(
      int grade, List<Subject> subjects) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = '$_subjectCacheKeyPrefix$grade';
    final timestampKey = '${cacheKey}_timestamp';

    final jsonList = subjects
        .map((s) => {
              'subjectName': s.subjectName,
              'subjectClass': s.subjectClass,
            })
        .toList();
    final jsonString = json.encode(jsonList);

    await prefs.setString(cacheKey, jsonString);
    await prefs.setInt(timestampKey, DateTime.now().millisecondsSinceEpoch);
  }

  static Future<List<Subject>> getAllSubjectCombinations({
    required int grade,
    int maxRetries = 3,
  }) async {
    final cachedSubjects = await _loadCachedSubjects(grade);
    if (cachedSubjects != null && cachedSubjects.isNotEmpty) {
      return cachedSubjects;
    }

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        Set<Subject> subjectSet = {};

        final timetable = await _getWeekTimetableWithFallback(grade.toString());

        if (timetable.isNotEmpty) {
          final firstDate = timetable.keys.first;
          final classKeys = timetable[firstDate]?.keys.toList() ?? [];
          log('$_tag: timetable classKeys for $firstDate: $classKeys');
        }

        timetable.forEach((date, classMap) {
          if (date == 'error') return;
          classMap.forEach((classNum, subjectsList) {
            if (classNum == 'error') return;
            final classInt = classNum == 'special' ? -1 : (int.tryParse(classNum) ?? -1);
            for (var subjectName in subjectsList) {
              if (subjectName.isNotEmpty && !subjectName.contains('[보강]') && subjectName != '토요휴업일') {
                subjectSet.add(Subject(
                  subjectName: subjectName,
                  subjectClass: classInt,
                ));
              }
            }
          });
        });

        List<Subject> subjectList = subjectSet.toList();
        subjectList.sort((a, b) {
          int nameCompare = a.subjectName.compareTo(b.subjectName);
          if (nameCompare != 0) return nameCompare;
          return a.subjectClass.compareTo(b.subjectClass);
        });

        final specialCount = subjectList.where((s) => s.subjectClass < 0).length;
        log('$_tag: getAllSubjectCombinations found ${subjectList.length} subjects ($specialCount 특별실)');
        for (var s in subjectList) {
          if (s.subjectClass < 0) {
            log('$_tag: 특별실: ${s.subjectName}');
          }
        }
        if (subjectList.isNotEmpty) {
          await _saveSubjectsToCache(grade, subjectList);
        }
        return subjectList;
      } catch (e) {
        log('$_tag: getAllSubjectCombinations attempt $attempt failed: $e');
        if (attempt == maxRetries) {
          return [];
        }
        await Future.delayed(Duration(seconds: 2 * attempt));
      }
    }
    return [];
  }

  static Future<List<Subject>> getSubjectsFromAdminFirestore(int grade) async {
    List<Subject> result = [];
    final query = await FirebaseFirestore.instance
        .collection('grade')
        .doc(grade.toString())
        .collection('subject')
        .get();

    for (var doc in query.docs) {
      final data = doc.data();
      result.add(
        Subject(
          subjectName: doc.id,
          subjectClass: -1,
          category: data['category'],
          isOriginal: data['isOriginal'] ?? false,
        ),
      );
    }
    return result;
  }
}
