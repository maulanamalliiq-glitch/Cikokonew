import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'api.dart';

/// Inovasi website 2602: public content only. No login, write or SQL changes.
abstract final class CikokoInnovationFeed {
  static const endpoint =
      'https://datawebs.my.id/mobile-api/inovasi-public-2602.php';

  static Future<Map<String, dynamic>> loadPublic() async {
    final response = await http.get(Uri.parse(endpoint),
      headers: const {'Accept': 'application/json', 'Cache-Control': 'no-cache'},
    ).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw const FormatException('Katalog inovasi belum tersedia.');
    }
    final parsed = jsonDecode(utf8.decode(response.bodyBytes));
    if (parsed is! Map<String, dynamic> ||
        parsed['ok'] != true || parsed['items'] is! List) {
      throw const FormatException('Respons katalog inovasi tidak valid.');
    }
    return parsed;
  }

  static Future<Map<String, dynamic>> load(CikokoApi api) async {
    try {
      return await loadPublic();
    } catch (_) {
      return api.call('v211_innovations');
    }
  }
}

List<String> cikokoInnovationPhotos(Map<String, dynamic> item) {
  final raw = item['images'];
  final images = <String>[];
  if (raw is List) {
    for (final photo in raw) {
      final path = photo.toString();
      if (RegExp(r'^assets/images/[A-Za-z0-9._-]+\.(jpg|jpeg|png|webp)$',
          caseSensitive: false).hasMatch(path) && !images.contains(path)) {
        images.add(path);
        if (images.length == 5) break;
      }
    }
  }
  if (images.isEmpty) {
    final fallback = (item['image'] ?? '').toString();
    if (RegExp(r'^assets/images/[A-Za-z0-9._-]+\.(jpg|jpeg|png|webp)$',
        caseSensitive: false).hasMatch(fallback)) {
      images.add(fallback);
    }
  }
  return images;
}

String cikokoInnovationWhatsapp(Map<String, dynamic> item) {
  var number = (item['whatsapp'] ?? '').toString()
      .replaceAll(RegExp(r'[^0-9]'), '');
  if (number.startsWith('0')) number = '62' + number.substring(1);
  if (number.startsWith('8')) number = '62' + number;
  return RegExp(r'^62[0-9]{8,13}$').hasMatch(number) ? number : '';
}

class CikokoInnovationDetailPage extends StatefulWidget {
  final CikokoApi api;
  final Map<String, dynamic> item;
  const CikokoInnovationDetailPage({
    super.key, required this.api, required this.item,
  });
  @override
  State<CikokoInnovationDetailPage> createState() =>
      _CikokoInnovationDetailPageState();
}

class _CikokoInnovationDetailPageState
    extends State<CikokoInnovationDetailPage> {
  final PageController _controller = PageController();
  Timer? _autoplay;
  late Future<Map<String, dynamic>> _pending;
  int _photoCount = 0;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _pending = _fetchDetail();
    _autoplay = Timer.periodic(const Duration(milliseconds: 4500), (_) {
      if (!mounted || _photoCount < 2 || !_controller.hasClients) return;
      _controller.animateToPage((_current + 1) % _photoCount,
        duration: const Duration(milliseconds: 430),
        curve: Curves.easeInOut);
    });
  }

  Future<Map<String, dynamic>> _fetchDetail() async {
    try {
      final data = await CikokoInnovationFeed.loadPublic();
      final slug = (widget.item['slug'] ?? '').toString();
      for (final raw in (data['items'] as List)) {
        if (raw is Map && raw['slug'] == slug) {
          return Map<String, dynamic>.from(raw);
        }
      }
    } catch (_) {
      // Offline / endpoint not yet installed: retain earlier public snapshot.
    }
    return widget.item;
  }

  @override
  void dispose() {
    _autoplay?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Widget _image(String path, {double height = 255}) {
    final source = widget.api.media(path);
    if (source.isEmpty) {
      return Container(height: height, color: const Color(0xffe9f1fa),
        alignment: Alignment.center,
        child: const Icon(Icons.image_outlined, size: 52,
          color: Color(0xff527ba4)));
    }
    return Image.network(source, height: height, width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
        Container(height: height, alignment: Alignment.center,
          color: const Color(0xffe9f1fa),
          child: const Icon(Icons.broken_image_outlined, size: 48)));
  }

  Future<void> _openWhatsapp(String number, String title) async {
    final uri = Uri.https('wa.me', '/' + number, {
      'text': 'Halo, saya ingin bertanya mengenai inovasi ' + title +
          ' Kelurahan Cikoko.',
    });
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
          mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('WhatsApp belum dapat dibuka.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('WhatsApp belum dapat dibuka.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xff12375d);
    return Scaffold(
      backgroundColor: const Color(0xfff3f7fd),
      appBar: AppBar(title: const Text('Detail Inovasi'),
        backgroundColor: Colors.white, foregroundColor: navy),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _pending,
        builder: (context, snapshot) {
          final item = snapshot.data ?? widget.item;
          final title = (item['title'] ?? 'Inovasi Cikoko').toString();
          final summary = (item['summary'] ?? '').toString();
          final body = (item['body'] ?? '').toString();
          final extra = (item['extra_image'] ?? '').toString();
          final extraText = (item['extra_text'] ?? '').toString();
          final address = (item['address'] ?? '').toString();
          final whatsapp = cikokoInnovationWhatsapp(item);
          final photos = cikokoInnovationPhotos(item);
          _photoCount = photos.length;
          return RefreshIndicator(
            onRefresh: () async {
              setState(() { _current = 0; _pending = _fetchDetail(); });
              await _pending;
              if (_controller.hasClients) _controller.jumpToPage(0);
            },
            child: ListView(
              children: [
                Center(child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 920),
                  child: Card(
                    margin: const EdgeInsets.all(12),
                    color: Colors.white,
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (photos.isNotEmpty)
                          Column(children: [
                            SizedBox(
                              height: 255,
                              child: PageView.builder(
                                controller: _controller,
                                itemCount: photos.length,
                                onPageChanged: (value) =>
                                    setState(() => _current = value),
                                itemBuilder: (ctx, i) =>
                                    _image(photos[i]),
                              ),
                            ),
                            if (photos.length > 1)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    for (var i = 0; i < photos.length; i++)
                                      Container(
                                        width: i == _current ? 18 : 7,
                                        height: 7,
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 3),
                                        decoration: BoxDecoration(
                                          color: i == _current
                                              ? const Color(0xff2369bc)
                                              : const Color(0xffb7cadf),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                          ])
                        else _image('', height: 215),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('INOVASI KELURAHAN CIKOKO',
                                style: TextStyle(
                                  color: Color(0xff246ac5), fontSize: 11,
                                  fontWeight: FontWeight.w800)),
                              const SizedBox(height: 9),
                              Text(title, style: const TextStyle(
                                color: navy, fontSize: 22,
                                fontWeight: FontWeight.w900)),
                              if (summary.isNotEmpty) ...[
                                const SizedBox(height: 11),
                                Text(summary, style: const TextStyle(
                                  color: Color(0xff48657e), fontSize: 14,
                                  height: 1.6)),
                              ],
                              if (body.isNotEmpty) ...[
                                const SizedBox(height: 19),
                                Text(body, style: const TextStyle(
                                  color: Color(0xff354f67),
                                  fontSize: 14, height: 1.75)),
                              ],
                              if (extra.isNotEmpty) ...[
                                const SizedBox(height: 24),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: _image(extra, height: 245)),
                              ],
                              if (extraText.isNotEmpty) ...[
                                const SizedBox(height: 20),
                                Text(extraText, style: const TextStyle(
                                  color: Color(0xff354f67),
                                  fontSize: 14, height: 1.75)),
                              ],
                              const SizedBox(height: 28),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xfff2f7ff),
                                  borderRadius: BorderRadius.circular(13)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Informasi dan Lokasi',
                                      style: TextStyle(color: navy,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800)),
                                    const SizedBox(height: 10),
                                    const Text('Alamat lengkap',
                                      style: TextStyle(fontSize: 12,
                                        fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 5),
                                    Text(address.isEmpty
                                        ? 'Alamat belum ditambahkan pengelola.'
                                        : address,
                                      style: const TextStyle(fontSize: 13,
                                        color: Color(0xff536a80),
                                        height: 1.6)),
                                    if (whatsapp.isNotEmpty) ...[
                                      const SizedBox(height: 17),
                                      FilledButton.icon(
                                        style: FilledButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xff168657)),
                                        onPressed: () =>
                                            _openWhatsapp(whatsapp, title),
                                        icon: const Icon(Icons.chat_rounded),
                                        label: const Text('Hubungi WhatsApp'),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
              ],
            ),
          );
        },
      ),
    );
  }
}
