import 'package:flutter_test/flutter_test.dart';

/// MealCard._extractAllergyNumbers 로직 단위 테스트
///
/// private 메서드이므로 동일한 로직을 여기서 재현하여 테스트
void main() {
  Set<String> extractAllergyNumbers(String? meal, Map<String, String> allergyMap) {
    if (meal == null) return {};
    final regex = RegExp(r'\(([0-9.,\s]+)\)');
    final matches = regex.allMatches(meal);
    final numbers = <String>{};
    for (final match in matches) {
      final inside = match.group(1)!;
      for (final num in inside.split(RegExp(r'[.,\s]+'))) {
        final trimmed = num.trim();
        if (trimmed.isNotEmpty && allergyMap.containsKey(trimmed)) {
          numbers.add(trimmed);
        }
      }
    }
    return numbers;
  }

  final allergyMap = {
    '1': '난류', '2': '우유', '3': '메밀', '4': '땅콩',
    '5': '대두', '6': '밀', '7': '고등어', '8': '게',
    '9': '새우', '10': '돼지고기', '11': '복숭아', '12': '토마토',
    '13': '아황산류', '14': '호두', '15': '닭고기', '16': '쇠고기',
    '17': '오징어', '18': '조개류',
  };

  group('알레르기 번호 추출', () {
    test('null 입력 → 빈 세트', () {
      expect(extractAllergyNumbers(null, allergyMap), isEmpty);
    });

    test('알레르기 정보 없는 메뉴', () {
      expect(extractAllergyNumbers('현미밥', allergyMap), isEmpty);
    });

    test('단일 알레르기 번호', () {
      final result = extractAllergyNumbers('우유(2)', allergyMap);
      expect(result, {'2'});
    });

    test('마침표 구분 다중 번호', () {
      final result = extractAllergyNumbers('돈까스(5.6.10)', allergyMap);
      expect(result, {'5', '6', '10'});
    });

    test('쉼표 구분 다중 번호', () {
      final result = extractAllergyNumbers('카레(1,2,5)', allergyMap);
      expect(result, {'1', '2', '5'});
    });

    test('공백 포함', () {
      final result = extractAllergyNumbers('스프(1. 2. 6)', allergyMap);
      expect(result, {'1', '2', '6'});
    });

    test('여러 메뉴 항목', () {
      const meal = '현미밥\n돈까스(5.6.10)\n우유(2)\n김치(13)';
      final result = extractAllergyNumbers(meal, allergyMap);
      expect(result, {'5', '6', '10', '2', '13'});
    });

    test('중복 번호 제거', () {
      const meal = '돈까스(5.6)\n두부(5)';
      final result = extractAllergyNumbers(meal, allergyMap);
      expect(result, {'5', '6'});
    });

    test('유효하지 않은 번호 무시', () {
      final result = extractAllergyNumbers('음식(99)', allergyMap);
      expect(result, isEmpty);
    });

    test('괄호 안 빈 내용', () {
      final result = extractAllergyNumbers('음식()', allergyMap);
      expect(result, isEmpty);
    });

    test('텍스트 괄호 무시', () {
      final result = extractAllergyNumbers('음식(맛있는)', allergyMap);
      expect(result, isEmpty);
    });

    test('혼합 괄호 — 숫자+텍스트', () {
      const meal = '카레(5.6)\n(맛있는)\n우유(2)';
      final result = extractAllergyNumbers(meal, allergyMap);
      expect(result, {'5', '6', '2'});
    });

    test('1~18 전체 번호 인식', () {
      final all = List.generate(18, (i) => '${i + 1}').join('.');
      final result = extractAllergyNumbers('전체($all)', allergyMap);
      expect(result.length, 18);
    });
  });
}
