import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'api.dart';

/// The web OAuth client is public and belongs to the existing Firebase project.
/// No Google secret or refresh token is bundled in the Android application.
abstract final class CikokoGoogleAuth2608 {
  static const webClientId =
      '417622897353-5s9dm00fpbv9eik69u8ri8d9mot6hibe.apps.googleusercontent.com';
  static Future<void>? _initialized;

  static Future<String> askForIdToken() async {
    if (!Platform.isAndroid) {
      throw ApiError('Masuk dengan Google tersedia untuk aplikasi Android.');
    }
    final signIn = GoogleSignIn.instance;
    _initialized ??= signIn.initialize(serverClientId: webClientId);
    await _initialized;
    if (!signIn.supportsAuthenticate()) {
      throw ApiError('Login Google belum tersedia pada perangkat ini.');
    }
    final account = await signIn.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw ApiError('Google belum memberikan token masuk. Periksa konfigurasi Google Play.');
    }
    return idToken;
  }

  static bool userCancelled(Object error) =>
      error is GoogleSignInException &&
      error.code == GoogleSignInExceptionCode.canceled;

  /// Keep Google ID tokens, credentials and plugin implementation details out
  /// of UI messages. Android Credential Manager sometimes reports real OAuth
  /// configuration failures as "canceled" after an account is selected.
  /// Never silently drop that status on the login screen.
  static String loginFailureMessage(Object error) {
    if (error is GoogleSignInException) {
      final desc=(error.description ?? '').toLowerCase();
      if (error.code == GoogleSignInExceptionCode.canceled) {
        if (desc.contains('reauth') || desc.contains('developer') ||
            desc.contains('configuration')) {
          return 'Google gagal mengautentikasi akun yang dipilih. '
              'Admin perlu memeriksa SHA-1 Play App Signing, OAuth Android, '
              'dan Web Client ID di Firebase.';
        }
        return 'Proses masuk Google terhenti. Jika Anda sudah memilih akun '
            'dan tidak menekan Batal, periksa SHA-1 Play App Signing di '
            'Firebase atau coba jaringan lain.';
      }
      if (error.code == GoogleSignInExceptionCode.clientConfigurationError ||
          error.code == GoogleSignInExceptionCode.providerConfigurationError) {
        return 'Konfigurasi Login Google Android tidak sesuai. '
            'Admin perlu memeriksa package name, SHA-1, dan Web Client ID.';
      }
      return 'Masuk Google tidak berhasil (tahap Google Android). '
          'Coba lagi atau hubungi Admin untuk memeriksa konfigurasi OAuth.';
    }
    return cikokoFormalMessage(error);
  }
}

class CikokoLinkGoogle2608 extends StatefulWidget {
  final CikokoApi api;
  const CikokoLinkGoogle2608({super.key, required this.api});
  @override
  State<CikokoLinkGoogle2608> createState() => _CikokoLinkGoogle2608State();
}

class _CikokoLinkGoogle2608State extends State<CikokoLinkGoogle2608> {
  bool busy = false;
  Future<void> link() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final idToken = await CikokoGoogleAuth2608.askForIdToken();
      await widget.api.googleLink(idToken);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Akun Google berhasil dihubungkan. Berikutnya bisa masuk dengan Google.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Belum berhasil menghubungkan Google: '
            '${CikokoGoogleAuth2608.loginFailureMessage(e)}')));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: OutlinedButton.icon(
        onPressed: busy ? null : link,
        icon: const Icon(Icons.account_circle_outlined),
        label: Text(busy ? 'Menghubungkan Google…' : 'Hubungkan Akun Google'),
      ),
    );
  }
}
