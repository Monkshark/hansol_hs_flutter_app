import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hansol_high_school/data/setting_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingData().init();
  });

  group('SettingData defaults', () {
    test('grade defaults to 0', () {
      expect(SettingData().grade, 0);
    });

    test('classNum defaults to 0', () {
      expect(SettingData().classNum, 0);
    });

    test('isGradeSet returns false when both are 0', () {
      expect(SettingData().isGradeSet, false);
    });

    test('isDarkMode defaults to false', () {
      expect(SettingData().isDarkMode, false);
    });

    test('themeModeIndex defaults to 2', () {
      expect(SettingData().themeModeIndex, 2);
    });

    test('notification flags default to true', () {
      expect(SettingData().isBreakfastNotificationOn, true);
      expect(SettingData().isLunchNotificationOn, true);
      expect(SettingData().isDinnerNotificationOn, true);
      expect(SettingData().isBoardNotificationOn, true);
    });

    test('meal times have correct defaults', () {
      expect(SettingData().breakfastTime, '06:30');
      expect(SettingData().lunchTime, '12:00');
      expect(SettingData().dinnerTime, '17:00');
    });

    test('localeCode defaults to empty string', () {
      expect(SettingData().localeCode, '');
    });
  });

  group('SettingData setters', () {
    test('grade setter and getter work', () {
      SettingData().grade = 2;
      expect(SettingData().grade, 2);
    });

    test('classNum setter and getter work', () {
      SettingData().classNum = 5;
      expect(SettingData().classNum, 5);
    });

    test('isGradeSet returns true when both set', () {
      SettingData().grade = 1;
      SettingData().classNum = 3;
      expect(SettingData().isGradeSet, true);
    });

    test('isGradeSet returns false when only grade set', () {
      SettingData().grade = 2;
      expect(SettingData().isGradeSet, false);
    });

    test('isGradeSet returns false when only classNum set', () {
      SettingData().classNum = 3;
      expect(SettingData().isGradeSet, false);
    });

    test('isDarkMode setter works', () {
      SettingData().isDarkMode = true;
      expect(SettingData().isDarkMode, true);
    });

    test('themeModeIndex setter works', () {
      SettingData().themeModeIndex = 0;
      expect(SettingData().themeModeIndex, 0);
    });

    test('notification toggle works', () {
      SettingData().isBreakfastNotificationOn = false;
      expect(SettingData().isBreakfastNotificationOn, false);
    });

    test('meal time setter works', () {
      SettingData().breakfastTime = '07:00';
      expect(SettingData().breakfastTime, '07:00');
    });

    test('localeCode setter works', () {
      SettingData().localeCode = 'en';
      expect(SettingData().localeCode, 'en');
    });
  });

  group('SettingData generic bool', () {
    test('getBool returns default when key not set', () {
      expect(SettingData().getBool('unknown_key'), false);
      expect(SettingData().getBool('unknown_key', defaultValue: true), true);
    });

    test('setBool and getBool roundtrip', () {
      SettingData().setBool('custom_flag', true);
      expect(SettingData().getBool('custom_flag'), true);
    });
  });

  group('SettingData singleton', () {
    test('factory returns same instance', () {
      final a = SettingData();
      final b = SettingData();
      expect(identical(a, b), true);
    });
  });
}
