import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'api.dart';

/// Cikoko Smart 2620: safe, read-only, native Server-Driven UI.
///
/// Only allowlisted presentation metadata is interpreted. Never accept a
/// server-delivered route handler, permission, HTML, Dart, arbitrary URL, or
/// action. Existing page widgets retain all their security and functionality.
abstract final class CikokoUi2620 {
  static final Map<String, Map<String, dynamic>> _cache = {};
  static final Map<String, DateTime> _loaded = {};

  static void invalidate(String page) {
    _cache.remove(page);
    _loaded.remove(page);
  }

  static Future<Map<String, dynamic>> page(String page) async {
    final stamp = _loaded[page];
    if (stamp != null &&
        DateTime.now().difference(stamp) < const Duration(seconds: 30)) {
      return _cache[page] ?? {};
    }
    try {
      final uri = Uri.parse(
        CikokoApi.root.replaceFirst('index.php', 'ui_layout_2620.php'),
      ).replace(queryParameters: {'page': page});
      final response = await http.get(uri, headers: {
        'Accept': 'application/json',
      }).timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) return _cache[page] ?? {};
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map || decoded['ok'] != true || decoded['schema'] != 1) {
        return _cache[page] ?? {};
      }
      final pages = decoded['pages'];
      if (pages is! Map || pages[page] is! Map) return _cache[page] ?? {};
      final config = Map<String, dynamic>.from(pages[page] as Map);
      _cache[page] = config;
      _loaded[page] = DateTime.now();
      return config;
    } catch (_) {
      // An older/offline cPanel must never break native navigation.
      return _cache[page] ?? {};
    }
  }

  static Color accent(Map<String, dynamic> config) {
    final raw = (config['accent'] ?? '').toString();
    if (!RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(raw)) {
      return const Color(0xFF0967E7);
    }
    return Color(0xFF000000 | int.parse(raw.substring(1), radix: 16));
  }

  static List<Map<String, dynamic>> blocks(Map<String, dynamic> config) {
    final raw = config['blocks'];
    if (raw is! List) return [];
    final result = <Map<String, dynamic>>[];
    for (final value in raw.take(30)) {
      if (value is! Map) continue;
      final block = Map<String, dynamic>.from(value);
      if (block['visible'] != true) continue;
      if (!const {'heading', 'text', 'card', 'spacer'}
          .contains(block['type'])) continue;
      result.add(block);
    }
    return result;
  }
}

class CikokoUiBlock2620 extends StatelessWidget {
  const CikokoUiBlock2620({
    super.key,
    required this.block,
    required this.accent,
  });
  final Map<String, dynamic> block;
  final Color accent;
  @override
  Widget build(BuildContext context) {
    final kind = (block['type'] ?? '').toString();
    final title = (block['title'] ?? '').toString();
    final body = (block['body'] ?? '').toString();
    switch (kind) {
      case 'spacer':
        final n = (block['height'] is num ? block['height'] as num : 16);
        return SizedBox(height: n.clamp(8, 100).toDouble());
      case 'heading':
        return Text(title,
          style: TextStyle(color: accent, fontSize: 17,
            fontWeight: FontWeight.w800));
      case 'text':
        return Text(body,
          style: const TextStyle(color: Color(0xFF60758F),
            fontSize: 12.5, height: 1.45));
      case 'card':
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFDCE6F2)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (title.isNotEmpty)
              Text(title, style: TextStyle(color: accent,
                fontWeight: FontWeight.w800, fontSize: 14)),
            if (body.isNotEmpty)
              Padding(padding: const EdgeInsets.only(top: 4),
                child: Text(body,
                  style: const TextStyle(
                    color: Color(0xFF61748C), fontSize: 12))),
          ]),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

/// All route widgets are wrapped without changing navigation or private data.
/// Custom title, description and additional blocks are server-controlled.
/// Core forms, chat and signatures remain native and non-removable.
class CikokoUiPageFrame2620 extends StatefulWidget {
  const CikokoUiPageFrame2620({
    super.key,
    required this.pageId,
    required this.child,
    this.loader,
  });
  final String pageId;
  final Widget child;
  final Future<Map<String, dynamic>> Function(String page)? loader;

  @override
  State<CikokoUiPageFrame2620> createState() => _CikokoUiPageFrame2620State();
}

class _CikokoUiPageFrame2620State extends State<CikokoUiPageFrame2620> {
  late Future<Map<String, dynamic>> future;
  void load() => future = (widget.loader ?? CikokoUi2620.page)(widget.pageId);

  @override
  void initState() { super.initState(); load(); }

  @override
  void didUpdateWidget(covariant CikokoUiPageFrame2620 oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageId != widget.pageId || oldWidget.loader != widget.loader) {
      load();
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
    future: future,
    builder: (context, snapshot) {
      final config = snapshot.data ?? {};
      final title = (config['title'] ?? '').toString().trim();
      final desc = (config['description'] ?? '').toString().trim();
      final blocks = CikokoUi2620.blocks(config);
      if (title.isEmpty && desc.isEmpty && blocks.isEmpty) return widget.child;
      final accent = CikokoUi2620.accent(config);
      return Column(children: [
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.30),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(14, 9, 14, 8),
            children: [
              if (title.isNotEmpty)
                Text(title, key: const Key('sdui_page_title_2620'),
                  style: TextStyle(
                    color: accent, fontWeight: FontWeight.w800, fontSize: 18)),
              if (desc.isNotEmpty)
                Text(desc, style: const TextStyle(
                  color: Color(0xFF60758F), fontSize: 12)),
              for (final item in blocks)
                Padding(
                  padding: const EdgeInsets.only(top: 7),
                  child: CikokoUiBlock2620(
                    block: item, accent: accent),
                ),
            ],
          ),
        ),
        Expanded(child: widget.child),
      ]);
    },
  );
}

/// The existing Dashboard widgets can be re-ordered, shown and hidden from
/// Admin Utama. Mandatory Surat status is never suppressed by remote config.
class CikokoUiHome2620 extends StatefulWidget {
  const CikokoUiHome2620({
    super.key,
    required this.childrenByKey,
    required this.defaultOrder,
    required this.onRefresh,
    this.loader,
  });
  final Map<String, Widget> childrenByKey;
  final List<String> defaultOrder;
  final Future<void> Function() onRefresh;
  final Future<Map<String, dynamic>> Function(String page)? loader;

  @override
  State<CikokoUiHome2620> createState() => _CikokoUiHome2620State();
}

class _CikokoUiHome2620State extends State<CikokoUiHome2620> {
  late Future<Map<String, dynamic>> future;

  @override
  void initState() {
    super.initState();
    future = (widget.loader ?? CikokoUi2620.page)('Dashboard');
  }

  Future<void> refresh() async {
    await widget.onRefresh();
    CikokoUi2620.invalidate('Dashboard');
    if (mounted) {
      setState(() => future =
        (widget.loader ?? CikokoUi2620.page)('Dashboard'));
      await future;
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
    future: future,
    builder: (context, snapshot) {
      final config = snapshot.data ?? {};
      final raw = config['sections'];
      final order = <String>[];
      final visible = <String, bool>{};
      if (raw is List) {
        for (final value in raw) {
          if (value is! Map) continue;
          final key = (value['key'] ?? '').toString();
          if (!widget.childrenByKey.containsKey(key) || order.contains(key)) {
            continue;
          }
          order.add(key);
          visible[key] = key == 'letters' || value['visible'] == true;
        }
      }
      for (final key in widget.defaultOrder) {
        if (!order.contains(key)) order.add(key);
      }
      return RefreshIndicator(
        onRefresh: refresh,
        child: ListView(
          key: const Key('v6_home'),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 30),
          children: [
            for (final key in order)
              if (visible[key] != false || key == 'letters')
                Padding(
                  key: ValueKey('sdui_core_$key'),
                  padding: const EdgeInsets.only(bottom: 12),
                  child: widget.childrenByKey[key]!,
                ),
          ],
        ),
      );
    },
  );
}
