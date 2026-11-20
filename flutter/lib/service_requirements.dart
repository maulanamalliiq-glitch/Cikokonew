import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

/// Public, read-only endpoint of website patch 2600.
const cikokoRequirementsEndpoint =
    'https://datawebs.my.id/mobile-api/service_requirements_public.php';

String? cikokoServiceRequirementKey(Map<String, dynamic> service) {
  final id = (service['id'] ?? '').toString();
  if (RegExp(r'^cms:[A-Za-z0-9_-]{1,120}$').hasMatch(id)) return id;
  if (RegExp(r'^[A-Za-z0-9_-]{1,45}$').hasMatch(id)) return 'api:' + id;
  return null;
}

Uri? cikokoSafeRequirementUri(Object? raw) {
  final uri = Uri.tryParse((raw ?? '').toString().trim());
  if (uri == null ||
      uri.scheme.toLowerCase() != 'https' ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty) return null;
  return uri;
}

Future<Map<String, dynamic>> cikokoFetchPublishedServiceData() async {
  final response = await http.get(
    Uri.parse(cikokoRequirementsEndpoint),
    headers: const {'Accept': 'application/json'},
  ).timeout(const Duration(seconds: 12));
  if (response.statusCode != 200) {
    throw StateError('Persyaratan layanan belum tersedia.');
  }
  final result = jsonDecode(utf8.decode(response.bodyBytes));
  if (result is! Map<String, dynamic> || result['ok'] != true) {
    throw StateError('Balasan layanan persyaratan tidak valid.');
  }
  return result;
}

/// Only published HTTPS links, scoped to the selected parent service.
List<Map<String, String>> cikokoPublishedRequirements(
    Map<String, dynamic> data, Map<String, dynamic> service) {
  final key = cikokoServiceRequirementKey(service);
  if (key == null) return [];
  final catalog = data['items'];
  if (catalog is! Map) return [];
  final items = catalog[key];
  if (items is! List) return [];
  final safe = <Map<String, String>>[];
  for (final raw in items.take(40)) {
    if (raw is! Map) continue;
    final title = (raw['title'] ?? '').toString().trim();
    final url = cikokoSafeRequirementUri(raw['url']);
    if (title.isEmpty || url == null) continue;
    safe.add({'title': title, 'url': url.toString()});
  }
  return safe;
}

/// The website has additional CMS service cards; make them visible in APK too.
List<Map<String, dynamic>> cikokoPublishedCmsServices(
    Map<String, dynamic> data) {
  final items = data['cms_services'];
  if (items is! List) return [];
  final services = <Map<String, dynamic>>[];
  for (final raw in items.take(8)) {
    if (raw is! Map) continue;
    final id = (raw['id'] ?? '').toString();
    final title = (raw['title'] ?? '').toString().trim();
    if (!RegExp(r'^cms:[A-Za-z0-9_-]{1,120}$').hasMatch(id) ||
        title.isEmpty) continue;
    final fallback = cikokoSafeRequirementUri(raw['url']);
    services.add({
      'id': id,
      'title': title,
      'description': (raw['description'] ?? '').toString(),
      'url': fallback?.toString() ?? '',
      'logo_url': '',
      'active': true,
    });
  }
  return services;
}

Future<void> _cikokoOpenPublishedLink(
    BuildContext context, String url) async {
  final uri = cikokoSafeRequirementUri(url);
  if (uri == null) return;
  try {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tautan persyaratan belum dapat dibuka.')),
      );
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tautan persyaratan belum dapat dibuka.')),
      );
    }
  }
}

/// Mobile lightbox: always refetches published records when reopened.
/// Does not edit catalog, alter roles, or bypass server access rules.
Future<void> cikokoShowServiceRequirements(
    BuildContext context, Map<String, dynamic> service) async {
  final title = (service['title'] ?? 'Layanan Cikoko').toString();
  final original = cikokoSafeRequirementUri(service['url']);
  final loading = cikokoFetchPublishedServiceData();
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (sheetContext) => FractionallySizedBox(
      heightFactor: 0.80,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: FutureBuilder<Map<String, dynamic>>(
          future: loading,
          builder: (ctx, snapshot) {
            final items = snapshot.hasData
                ? cikokoPublishedRequirements(snapshot.data!, service)
                : <Map<String, String>>[];
            final waiting = snapshot.connectionState != ConnectionState.done;
            final unavailable = snapshot.hasError;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('LAYANAN MASYARAKAT TERPADU',
                    style: TextStyle(
                        color: Color(0xff246ac5),
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: 0.6)),
                const SizedBox(height: 8),
                Text(title,
                    style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: Color(0xff12375d))),
                const SizedBox(height: 5),
                const Text(
                  'Pilih pelayanan untuk melihat persyaratan yang disediakan pengelola.',
                  style: TextStyle(fontSize: 12.5, color: Colors.blueGrey),
                ),
                const Divider(height: 26),
                if (waiting)
                  const Expanded(
                      child: Center(child: CircularProgressIndicator()))
                else if (items.isEmpty)
                  Expanded(
                    child: ListView(children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            unavailable
                                ? 'Daftar persyaratan belum dapat dimuat. Periksa koneksi dan layanan server.'
                                : 'Persyaratan untuk layanan ini belum ditambahkan oleh pengelola.',
                            style: const TextStyle(color: Colors.blueGrey),
                          ),
                        ),
                      ),
                      if (original != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: OutlinedButton.icon(
                            onPressed: () => _cikokoOpenPublishedLink(
                                sheetContext, original.toString()),
                            icon: const Icon(Icons.open_in_new, size: 17),
                            label: const Text('Buka tautan layanan utama'),
                          ),
                        )
                    ]),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 8),
                      itemBuilder: (c, index) {
                        final item = items[index];
                        return Card(
                          elevation: 0,
                          color: const Color(0xfff5f9ff),
                          shape: RoundedRectangleBorder(
                            side: const BorderSide(color: Color(0xffd9e5f4)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['title']!,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xff12375d))),
                                const SizedBox(height: 9),
                                OutlinedButton.icon(
                                  onPressed: () => _cikokoOpenPublishedLink(
                                      sheetContext, item['url']!),
                                  icon: const Icon(Icons.open_in_new, size: 16),
                                  label: const Text('Lihat Persyaratan'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 6),
                const Center(
                  child: Text('Kelurahan Cikoko · Informasi Pelayanan',
                      style: TextStyle(color: Colors.blueGrey, fontSize: 11)),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}
