import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Server controls the *minimum supported* version, not the phone clock.
/// A new version must be fully available on Play before enabling a forced gate.
class CikokoUpdatePolicy2606 {
  final int minimumBuild;
  final int latestPlayBuild;
  final bool forceUpdate;
  final String message;
  const CikokoUpdatePolicy2606({
    required this.minimumBuild,
    required this.latestPlayBuild,
    required this.forceUpdate,
    required this.message,
  });

  static const disabled = CikokoUpdatePolicy2606(
    minimumBuild: 0, latestPlayBuild: 0, forceUpdate: false,
    message: 'Versi terbaru Cikoko Smart tersedia di Google Play.',
  );

  static CikokoUpdatePolicy2606 fromResponse(Map<String, dynamic> value) {
    if (value['ok'] != true) throw const FormatException('Invalid version policy');
    final min = value['minimum_supported_build'];
    final latest = value['latest_play_build'];
    final force = value['force_update'];
    if (min is! int || latest is! int || force is! bool ||
        min < 0 || latest < 0 || min > 2000000000 || latest > 2000000000) {
      throw const FormatException('Invalid version policy values');
    }
    final rawMessage = (value['message'] ?? '').toString().trim();
    return CikokoUpdatePolicy2606(
      minimumBuild: min, latestPlayBuild: latest,
      forceUpdate: force && min > 0 && latest >= min,
      message: rawMessage.isNotEmpty && rawMessage.length <= 500
          ? rawMessage : disabled.message,
    );
  }

  bool blocks(int installedBuild) =>
      forceUpdate && installedBuild > 0 && installedBuild < minimumBuild;
}

class CikokoVersionService2606 {
  static final Uri endpoint = Uri.parse(
    'https://datawebs.my.id/mobile-api/index.php?action=app_update_policy',
  );
  static final Uri storePage = Uri.parse(
    'https://play.google.com/store/apps/details?id=com.KelurahanCikoko.malik',
  );
  static const String cacheKey = 'cikoko_version_policy_2606';
  static const _storage = FlutterSecureStorage();

  static Future<CikokoUpdatePolicy2606> load() async {
    try {
      final response = await http.get(endpoint, headers: {
        'Accept': 'application/json',
        'Cache-Control': 'no-cache',
      }).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        throw const FormatException('Version service unavailable');
      }
      final parsed = jsonDecode(utf8.decode(response.bodyBytes));
      if (parsed is! Map<String, dynamic>) {
        throw const FormatException('Invalid server response');
      }
      final policy = CikokoUpdatePolicy2606.fromResponse(parsed);
      // Keep the last trusted policy in case the network drops later.
      try { await _storage.write(key: cacheKey, value: jsonEncode(parsed)); }
      catch (_) {}
      return policy;
    } catch (_) {
      try {
        final saved = await _storage.read(key: cacheKey);
        if (saved != null) {
          final parsed = jsonDecode(saved);
          if (parsed is Map<String, dynamic>) {
            return CikokoUpdatePolicy2606.fromResponse(parsed);
          }
        }
      } catch (_) {}
      // Never lock a first-time install merely because the server is down.
      return CikokoUpdatePolicy2606.disabled;
    }
  }
}

/// Entry guard is above authentication, so no private page is shown while
/// an installed Play version is below a *published* minimum version.
class CikokoUpdateGate2606 extends StatefulWidget {
  final Widget child;
  const CikokoUpdateGate2606({super.key, required this.child});

  @override
  State<CikokoUpdateGate2606> createState() => _CikokoUpdateGate2606State();
}

class _CikokoUpdateGate2606State extends State<CikokoUpdateGate2606>
    with WidgetsBindingObserver {
  CikokoUpdatePolicy2606 policy = CikokoUpdatePolicy2606.disabled;
  int installedBuild = 0;
  String installedVersion = '';
  bool checking = true;
  bool updating = false;
  bool runningCheck = false;
  bool autoPrompted = false;
  String hint = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(check());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(check());
  }

  Future<void> check() async {
    if (runningCheck) return;
    runningCheck = true;
    try {
      final info = await PackageInfo.fromPlatform();
      final currentBuild = int.tryParse(info.buildNumber) ?? 0;
      final result = await CikokoVersionService2606.load();
      if (!mounted) return;
      setState(() {
        policy = result;
        installedBuild = currentBuild;
        installedVersion = info.version;
        checking = false;
      });
      if (result.blocks(currentBuild) && !autoPrompted) {
        autoPrompted = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) unawaited(startPlayUpdate(automatic: true));
        });
      }
    } catch (_) {
      if (mounted) setState(() { checking = false; hint = 'Pemeriksaan versi belum berhasil.'; });
    } finally {
      runningCheck = false;
    }
  }

  Future<void> openStore() async {
    try {
      await launchUrl(CikokoVersionService2606.storePage,
          mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) setState(() => hint = 'Buka Google Play dan cari Cikoko Smart.');
    }
  }

  Future<void> startPlayUpdate({bool automatic = false}) async {
    if (updating) return;
    setState(() { updating = true; hint = ''; });
    try {
      if (Platform.isAndroid) {
        final info = await InAppUpdate.checkForUpdate();
        if (info.updateAvailability == UpdateAvailability.updateAvailable &&
            info.immediateUpdateAllowed) {
          await InAppUpdate.performImmediateUpdate();
          await check();
          return;
        }
      }
      if (!automatic) await openStore();
      if (mounted) setState(() => hint =
          'Jika pembaruan belum terlihat, pastikan Play Store menyediakan versi ini untuk akun Anda.');
    } catch (_) {
      if (!automatic) await openStore();
      if (mounted) setState(() => hint =
          'Pembaruan langsung belum tersedia. Gunakan tombol Google Play.');
    } finally {
      if (mounted) setState(() => updating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (checking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!policy.blocks(installedBuild)) return widget.child;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xfff2f7fc),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.system_update_alt, size: 64,
                          color: Color(0xff1763a6)),
                      const SizedBox(height: 16),
                      const Text('Pembaruan Cikoko Smart Wajib',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Text(policy.message, textAlign: TextAlign.center),
                      const SizedBox(height: 14),
                      Text('Terpasang: $installedVersion ($installedBuild)'),
                      Text('Minimal: ${policy.minimumBuild}'),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: updating ? null : startPlayUpdate,
                          icon: const Icon(Icons.download),
                          label: Text(updating ? 'Memeriksa Google Play…'
                              : 'Perbarui melalui Google Play'),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: updating ? null : check,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Periksa ulang versi'),
                      ),
                      if (hint.isNotEmpty) Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(hint, textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12)),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
