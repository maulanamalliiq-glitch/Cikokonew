import 'package:flutter_test/flutter_test.dart';
import 'package:cikoko/app_update_2606.dart';

void main() {
  Map<String, dynamic> policy({
    required int minimum,
    required int latest,
    required bool forced,
  }) => {
    'ok': true,
    'minimum_supported_build': minimum,
    'latest_play_build': latest,
    'force_update': forced,
    'message': 'Perbarui aplikasi',
  };

  test('Never force before target build is available on Play', () {
    final item = CikokoUpdatePolicy2606.fromResponse(policy(
      minimum: 2606, latest: 2605, forced: true));
    expect(item.blocks(2605), isFalse);
    expect(item.forceUpdate, isFalse);
  });

  test('Only older builds are blocked when forced update is enabled', () {
    final item = CikokoUpdatePolicy2606.fromResponse(policy(
      minimum: 2606, latest: 2606, forced: true));
    expect(item.blocks(2605), isTrue);
    expect(item.blocks(2606), isFalse);
    expect(item.blocks(2607), isFalse);
  });

  test('Optional update never blocks a user', () {
    final item = CikokoUpdatePolicy2606.fromResponse(policy(
      minimum: 2606, latest: 2606, forced: false));
    expect(item.blocks(2500), isFalse);
  });

  test('Invalid server policy is rejected', () {
    expect(() => CikokoUpdatePolicy2606.fromResponse({
      'ok': true, 'minimum_supported_build': '2606',
      'latest_play_build': 2606, 'force_update': true,
    }), throwsFormatException);
    expect(() => CikokoUpdatePolicy2606.fromResponse({
      'ok': false, 'minimum_supported_build': 2606,
      'latest_play_build': 2606, 'force_update': true,
    }), throwsFormatException);
  });
}
