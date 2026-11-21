import 'package:flutter_test/flutter_test.dart';
import 'package:cikoko/cikoko_google_auth_2608.dart';

void main() {
  test('Google Sign-In uses known Cikoko OAuth web client', () {
    expect(CikokoGoogleAuth2608.webClientId,
      '417622897353-5s9dm00fpbv9eik69u8ri8d9mot6hibe.apps.googleusercontent.com');
  });
}
