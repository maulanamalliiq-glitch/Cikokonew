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
      if (!mounted || CikokoGoogleAuth2608.userCancelled(e)) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Belum berhasil menghubungkan Google: ${cikokoFormalMessage(e)}')));
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
