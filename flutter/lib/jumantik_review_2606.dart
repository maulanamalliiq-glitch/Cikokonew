import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'api.dart';
import 'cikoko_jumantik_2605.dart';

/// Private Super Admin review: no report or photo is public until approved.
class CikokoJumantikReview2606 extends StatefulWidget {
  final CikokoApi api;
  const CikokoJumantikReview2606({super.key, required this.api});
  @override
  State<CikokoJumantikReview2606> createState() => _CikokoJumantikReview2606State();
}

class _CikokoJumantikReview2606State extends State<CikokoJumantikReview2606> {
  late Future<List<Map<String, dynamic>>> pending;
  int? processing;

  @override
  void initState() { super.initState(); pending = load(); }

  Future<List<Map<String, dynamic>>> load() async {
    final r = await http.get(Jumantik2605Api.url('admin_list'),
      headers: Jumantik2605Api.headers(widget.api))
      .timeout(const Duration(seconds: 25));
    final data = Jumantik2605Api.decode(r);
    return (data['items'] as List? ?? []).whereType<Map>()
      .map((x) => Map<String, dynamic>.from(x)).toList();
  }

  Future<void> decide(int id, String choice) async {
    if (processing != null) return;
    setState(() => processing = id);
    try {
      final r = await http.post(Jumantik2605Api.url('admin_publish'),
        headers: {
          ...Jumantik2605Api.headers(widget.api),
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'id': id, 'decision': choice}),
      ).timeout(const Duration(seconds: 25));
      final data = Jumantik2605Api.decode(r);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text((data['message'] ?? 'Keputusan tersimpan.').toString())));
      setState(() => pending = load());
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memeriksa laporan: $e')));
    } finally {
      if (mounted) setState(() => processing = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    if ((widget.api.profile?['role'] ?? '').toString() != 'admin') {
      return const Center(child: Text('Khusus Super Admin.'));
    }
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: pending, builder: (context, snapshot) {
        if (!snapshot.hasData) {
          if (snapshot.hasError) return Center(child: TextButton(
            onPressed: () => setState(() => pending = load()),
            child: Text('Gagal memuat laporan. Coba lagi: ${snapshot.error}')));
          return const Center(child: CircularProgressIndicator());
        }
        return RefreshIndicator(
          onRefresh: () async {
            setState(() => pending = load());
            await pending;
          },
          child: ListView(padding: const EdgeInsets.all(14), children: [
            const Text('Verifikasi Jumantik RT/RW',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Periksa foto dan hasil pemeriksaan sebelum berita diterbitkan. '
              'Nama kepala keluarga dan alamat lengkap hanya untuk pemeriksaan internal.'),
            const SizedBox(height: 12),
            if (snapshot.data!.isEmpty) const Card(child: Padding(
              padding: EdgeInsets.all(16), child: Text('Tidak ada laporan yang menunggu verifikasi.'))),
            for (final item in snapshot.data!) Builder(builder: (context) {
              final id = int.tryParse('${item['id'] ?? ''}') ?? 0;
              final photo = Jumantik2605Api.url('admin_photo').replace(
                queryParameters: {'action': 'admin_photo', 'id': '$id'});
              return Card(child: Padding(padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${item['tanggal'] ?? ''} • RT ${item['rt'] ?? ''} / RW ${item['rw'] ?? ''}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('Petugas: ${item['officer_name'] ?? ''}'),
                  Text('Koordinator: ${item['coordinator'] ?? ''}'),
                  Text('Lokasi: ${item['lokasi'] ?? ''}'),
                  Text('Alamat (internal): ${item['alamat_lengkap'] ?? ''}'),
                  Text('Minggu ke-${item['minggu_ke'] ?? ''} • Jentik: ${item['jentik'] ?? ''}'),
                  Text('Tempat umum: ${item['tempat_umum_lainnya'] ?? ''}'),
                  const SizedBox(height: 9),
                  if (id > 0) Image.network(photo.toString(),
                    headers: Jumantik2605Api.headers(widget.api),
                    height: 180, fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                      const Text('Foto belum bisa dimuat. Jangan terbitkan sebelum melihat foto.')),
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, children: [
                    OutlinedButton(
                      onPressed: processing != null || id <= 0 ? null : () => decide(id, 'reject'),
                      child: const Text('Tolak')),
                    FilledButton.icon(
                      onPressed: processing != null || id <= 0 ? null : () => decide(id, 'publish'),
                      icon: const Icon(Icons.verified_outlined),
                      label: const Text('Verifikasi & Terbitkan')),
                  ]),
                ])));
            }),
          ]),
        );
      },
    );
  }
}
