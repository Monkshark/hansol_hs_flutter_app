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

    log('$TAG: getTimeTable: Checking cache for key: $cacheKey');
    if (prefs.containsKey(cacheKey)) {
      final cachedTimestamp = prefs.getInt('$cacheKey-timestamp') ?? 0;
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      const oneDay = 12 * 60 * 60 * 1000;

      if (currentTime - cachedTimestamp < oneDay) {
        final cachedData = prefs.getString(cacheKey);
        if (cachedData != null) {
          log('$TAG: getTimeTable: Cache hit for $cacheKey');
          final decoded = jsonDecode(cachedData) as Map<String, dynamic>;
          return decoded.map((key, value) => MapEntry(
                key,
                (value as Map<String, dynamic>)
                    .map((k, v) => MapEntry(k, List<String>.from(v))),
              ));
        }
      } else {
        log('$TAG: getTimeTable: Cache expired for $cacheKey, removing');
        prefs.remove(cacheKey);
        prefs.remove('$cacheKey-timestamp');
      }
    }

    if (await NetworkStatus.isUnconnected()) {
      log('$TAG: getTimeTable: No internet connection');
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

    log('$TAG: getTimeTable: Requesting URL: $requestURL');

    final data = await fetchData(requestURL);
    if (data == null) {
      log('$TAG: getTimeTable: No data received from API');
      return {
        "error": {
          "error": ["정보 없음"]
        }
      };
    }

    final timetable = processTimetable(data['hisTimetable']);
    log('$TAG: getTimeTable: Processed timetable: $timetable');
    final encodedData = jsonEncode(timetable);
    prefs.setString(cacheKey, encodedData);
    prefs.setInt('$cacheKey-timestamp', DateTime.now().millisecondsSinceEpoch);
    log('$TAG: getTimeTable: Cached timetable for $cacheKey');

    return timetable;
  }

  static Future<Map<String, dynamic>?> fetchData(String url) async {
    log('$TAG: fetchData: Sending GET request to $url');
    try {
      final response = await http.get(Uri.parse(url));
      log('$TAG: fetchData: Response status code: ${response.statusCode}');
      if (response.statusCode != 200) {
        log('$TAG: fetchData: Failed with status code ${response.statusCode}');
        return null;
      }
      final data = jsonDecode(response.body);
      log('$TAG: fetchData: Successfully decoded response');
      return data;
    } catch (e) {
      log('$TAG: fetchData error: $e');
      return null;
    }
  }

  static Map<String, Map<String, List<String>>> processTimetable(
      List<dynamic> timetableArray) {
    Map<String, Map<String, List<String>>> resultMap = {};
    log('$TAG: processTimetable: Starting to process timetable array with ${timetableArray.length} entries');
    try {
      for (var data in timetableArray) {
        final rowArray = data['row'] as List<dynamic>?;
        if (rowArray != null) {
          log('$TAG: processTimetable: Processing ${rowArray.length} rows');
          for (var item in rowArray) {
            final classNum = item['CLASS_NM'] as String?;
            final date = item['ALL_TI_YMD'] as String?;
            final content = item['ITRT_CNTNT'] as String?;
            if (classNum != null && date != null && content != null) {
              resultMap
                  .putIfAbsent(date, () => {})
                  .putIfAbsent(classNum, () => [])
                  .add(content);
              log('$TAG: processTimetable: Added $content for class $classNum on $date');
            }
          }
        }
      }
    } catch (e) {
      log('$TAG: processTimetable error: $e');
      return {
        "error": {"error": []}
      };
    }
    log('$TAG: processTimetable: Completed with ${resultMap.length} dates');
    return resultMap;
  }

  static Future<List<String>?> getSubjects({required int grade}) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'subjects-$grade';
    final cachedData = prefs.getString(cacheKey);
    log('$TAG: getSubjects: Checking cache for key: $cacheKey');
    if (cachedData != null) {
      final cachedTimestamp = prefs.getInt('$cacheKey-timestamp') ?? 0;
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      const oneMonth = 30 * 24 * 60 * 60 * 1000;
      if (currentTime - cachedTimestamp < oneMonth) {
        log('$TAG: getSubjects: Cache hit for $cacheKey');
        return jsonDecode(cachedData).cast<String>();
      }
      log('$TAG: getSubjects: Cache expired for $cacheKey');
    }

    List<String> subjects = [];
    DateTime now = DateTime.now();
    DateTime startDate = DateTime(now.year, 3, 8);
    DateTime endDate = DateTime(now.year, 3, 14);
    log('$TAG: getSubjects: Fetching subjects for grade $grade from $startDate to $endDate');

    final timetable = await getTimeTable(
      startDate: startDate,
      endDate: endDate,
      grade: grade.toString(),
      classNum: null,
    );

    timetable.forEach((date, classMap) {
      log('$TAG: getSubjects: Processing date $date with ${classMap.length} classes');
      classMap.forEach((classNum, subjectsList) {
        subjects.addAll(subjectsList
            .where((name) => !name.contains('[보강]') && name != '토요휴업일'));
        log('$TAG: getSubjects: Added ${subjectsList.length} subjects for class $classNum on $date');
      });
    });

    subjects = subjects.toSet().toList()..sort();
    log('$TAG: getSubjects: Total unique subjects: ${subjects.length}');
    await prefs.setString(cacheKey, jsonEncode(subjects));
    await prefs.setInt(
        '$cacheKey-timestamp', DateTime.now().millisecondsSinceEpoch);
    log('$TAG: getSubjects: Cached subjects for $cacheKey');
    return subjects;
  }

  static Future<List<List<String?>>> getCustomTimeTable({
    required List<Subject> userSubjects,
    required String grade,
    bool writeLog = false,
  }) async {
    const maxPeriods = 7;
    List<List<String?>> customTimeTable = List.generate(
      6,
      (i) => i == 0 ? [] : [null, ...List.filled(maxPeriods, '')],
    );
    log('$TAG: getCustomTimeTable: Initializing timetable for grade $grade with ${userSubjects.length} subjects');

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
      log('$TAG: getCustomTimeTable: Received timetable for ${timetable.length} dates');

      final classToSubjects = <int, List<Subject>>{};
      for (var subject in userSubjects) {
        classToSubjects
            .putIfAbsent(subject.subjectClass, () => [])
            .add(subject);
        log('$TAG: getCustomTimeTable: Grouped subject ${subject.subjectName} for class ${subject.subjectClass}');
      }

      timetable.forEach((date, classMap) {
        int weekday = DateFormat('yyyyMMdd').parse(date).weekday;
        if (weekday >= 6) {
          log('$TAG: getCustomTimeTable: Skipping weekend date $date');
          return;
        }

        log('$TAG: getCustomTimeTable: Processing date $date for weekday $weekday');
        classMap.forEach((classNum, subjectsList) {
          final classSubjects = classToSubjects[int.parse(classNum)] ?? [];
          for (var subject in classSubjects) {
            for (var i = 0; i < subjectsList.length && i < maxPeriods; i++) {
              if (subjectsList[i] == subject.subjectName &&
                  subject.subjectName != '토요휴업일') {
                customTimeTable[weekday][i + 1] = subject.subjectName;
                log('$TAG: getCustomTimeTable: Set ${subject.subjectName} at weekday $weekday, period ${i + 1}');
              }
            }
          }
        });
      });
    } catch (e) {
      log('$TAG: getCustomTimeTable error: $e');
      return List.generate(
        6,
        (i) => i == 0 ? [] : [null, ...List.filled(maxPeriods, '')],
      );
    }

    if (writeLog) {
      for (var weekday in customTimeTable.sublist(1)) {
        log('$TAG: getCustomTimeTable: day${customTimeTable.indexOf(weekday)}: ${weekday.toString()}');
      }
    }
    log('$TAG: getCustomTimeTable: Completed with timetable: $customTimeTable');
    return customTimeTable;
  }

  static Future<int> getClassCount(int grade) async {
    final cacheKey = 'classCount-$grade';
    final prefs = await SharedPreferences.getInstance();
    final cachedClassCount = prefs.getInt(cacheKey);
    final cachedTimestamp = prefs.getInt('$cacheKey-timestamp') ?? 0;
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    const oneMonth = 30 * 24 * 60 * 60 * 1000;

    log('$TAG: getClassCount: Checking cache for key: $cacheKey');
    if (cachedClassCount != null && currentTime - cachedTimestamp < oneMonth) {
      log('$TAG: getClassCount: Cache hit, returning $cachedClassCount classes');
      return cachedClassCount;
    }

    final requestURL = 'https://open.neis.go.kr/hub/classInfo?'
        'key=${niesApiKeys.NIES_API_KEY}'
        '&Type=json&ATPT_OFCDC_SC_CODE=${niesApiKeys.ATPT_OFCDC_SC_CODE}'
        '&SD_SCHUL_CODE=${niesApiKeys.SD_SCHUL_CODE}'
        '&AY=${DateTime.now().year}'
        '&GRADE=$grade';

    log('$TAG: getClassCount: Requesting URL: $requestURL');

    final data = await fetchData(requestURL);
    if (data == null) {
      log('$TAG: getClassCount: No data received from API');
      return 0;
    }

    final classCount =
        data['classInfo'][0]['head'][0]['list_total_count'] as int;
    await prefs.setInt(cacheKey, classCount);
    await prefs.setInt('$cacheKey-timestamp', currentTime);
    log('$TAG: getClassCount: Cached $classCount classes for $cacheKey');
    return classCount;
  }

  static Future<List<Subject>?> _loadCachedSubjects(int grade) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = '$_subjectCacheKeyPrefix$grade';
    final timestampKey = '${cacheKey}_timestamp';

    log('$TAG: _loadCachedSubjects: Checking cache for key: $cacheKey');
    final jsonString = prefs.getString(cacheKey);
    final cachedTimestamp = prefs.getInt(timestampKey) ?? 0;
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    const oneMonth = 30 * 24 * 60 * 60 * 1000;

    if (jsonString != null && currentTime - cachedTimestamp < oneMonth) {
      try {
        final List<dynamic> jsonList = json.decode(jsonString);
        final subjects = jsonList
            .map((item) => Subject(
                  subjectName: item['subjectName'],
                  subjectClass: item['subjectClass'],
                ))
            .toList();
        log('$TAG: _loadCachedSubjects: Loaded ${subjects.length} subjects from cache');
        return subjects;
      } catch (e) {
        log('$TAG: _loadCachedSubjects error: $e');
        return null;
      }
    }
    log('$TAG: _loadCachedSubjects: No valid cache found');
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
    log('$TAG: _saveSubjectsToCache: Saved ${subjects.length} subjects for grade $grade');
  }

  static Future<List<Subject>> getAllSubjectCombinations({
    required int grade,
    int maxRetries = 3,
  }) async {
    final cachedSubjects = await _loadCachedSubjects(grade);
    if (cachedSubjects != null && cachedSubjects.isNotEmpty) {
      log('$TAG: getAllSubjectCombinations: Returning ${cachedSubjects.length} cached subjects for grade $grade');
      return cachedSubjects;
    }

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      log('$TAG: getAllSubjectCombinations: Attempt $attempt for grade $grade');
      try {
        Set<Subject> subjectSet = {};
        DateTime now = DateTime.now();
        DateTime startDate = DateTime(now.year, 3, 8);
        DateTime endDate = DateTime(now.year, 3, 14);

        final timetable = await getTimeTable(
          startDate: startDate,
          endDate: endDate,
          grade: grade.toString(),
          classNum: null,
        );

        timetable.forEach((date, classMap) {
          log('$TAG: getAllSubjectCombinations: Processing date $date with ${classMap.length} classes');
          classMap.forEach((classNum, subjectsList) {
            for (var subjectName in subjectsList) {
              if (!subjectName.contains('[보강]') && subjectName != '토요휴업일') {
                subjectSet.add(Subject(
                  subjectName: subjectName,
                  subjectClass: int.parse(classNum),
                ));
                log('$TAG: getAllSubjectCombinations: Added subject $subjectName for class $classNum');
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

        if (subjectList.isNotEmpty) {
          await _saveSubjectsToCache(grade, subjectList);
          log('$TAG: getAllSubjectCombinations: Saved ${subjectList.length} subjects to cache');
        }
        log('$TAG: getAllSubjectCombinations: Returning ${subjectList.length} subjects');
        return subjectList;
      } catch (e) {
        log('$TAG: getAllSubjectCombinations attempt $attempt failed: $e');
        if (attempt == maxRetries) {
          log('$TAG: getAllSubjectCombinations: Max retries reached for grade $grade');
          return [];
        }
        await Future.delayed(Duration(seconds: 2 * attempt));
      }
    }
    return [];
  }

  static Future<List<Subject>> getSubjectsFromAdminFirestore(int grade) async {
    log('$TAG: getSubjectsFromAdminFirestore: Fetching subjects for grade $grade from Firestore');
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
      log('$TAG: getSubjectsFromAdminFirestore: Added subject ${doc.id}');
    }
    log('$TAG: getSubjectsFromAdminFirestore: Loaded ${result.length} subjects');
    return result;
  }
}
