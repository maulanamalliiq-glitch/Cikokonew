import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cikoko/cikoko_google_auth_2608.dart';

void main() {
  test('OAuth reauthentication error after choosing Gmail is not suppressed', () {
    final failure=GoogleSignInException(
      code:GoogleSignInExceptionCode.canceled,
      description:'[16] Account reauth failed.',
    );
    expect(CikokoGoogleAuth2608.userCancelled(failure),isTrue);
    final message=CikokoGoogleAuth2608.loginFailureMessage(failure);
    expect(message,contains('SHA-1 Play App Signing'));
    expect(message,isNot(contains('Bearer ')));
  });

  test('Generic unexpected Google canceled error displays troubleshooting message', () {
    final failure=GoogleSignInException(
      code:GoogleSignInExceptionCode.canceled,
      description:'Canceled',
    );
    expect(CikokoGoogleAuth2608.loginFailureMessage(failure),
      contains('Proses masuk Google terhenti'));
  });

  test('Google client misconfiguration gives actionable but safe feedback', () {
    final failure=GoogleSignInException(
      code:GoogleSignInExceptionCode.clientConfigurationError,
      description:'Do not include internal provider values in UI.',
    );
    final message=CikokoGoogleAuth2608.loginFailureMessage(failure);
    expect(message,contains('package name'));
    expect(message,isNot(contains('Do not include')));
  });
}
