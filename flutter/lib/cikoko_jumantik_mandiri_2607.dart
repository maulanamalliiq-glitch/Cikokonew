import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'api.dart';

/// Independent of Jumantik RT/RW: all authenticated non-Admin accounts.
abstract final class CikokoJumantikMandiri2607 {
  static Uri url(String action) => Uri.parse(
    CikokoApi.root.replaceFirst('index.php', 'jumantik_mandiri_2607.php') +
        '?action=$action');
  static const questions = <String, String>{
    'bak_mandi': 'BAK MANDI',
    'tatakan_dispenser': 'TATAKAN DISPENSER',
    'toren_air': 'TOREN AIR',
    'tatakan_pot_bunga': 'TATAKAN POT BUNGA',
    'tampungan_pembuangan_air_ac': 'TAMPUNGAN PEMBUANGAN AIR AC',
    'penampungan_sisa_air_kulkas': 'PENAMPUNGAN BEKAS SISA AIR KULKAS',
    'genangan_air_sekitar_rumah': 'GENANGAN AIR SEKITAR RUMAH',
    'genangan_air_barang_bekas': 'GENANGAN AIR DI BARANG BEKAS',
    'tempat_minum_hewan': 'TEMPAT MINUM HEWAN',
    'menguras_membersihkan_tampungan_air': 'MENGURAS ATAU MEMBERSIHKAN TAMPUNGAN AIR',
    'menutup_tempat_tampung_air': 'MENUTUP TEMPAT TAMPUNG AIR',
    'mendaur_ulang_barang_bekas': 'MENDAUR ULANG BARANG BEKAS YANG BISA MENAMPUNG AIR',
  };
  static bool eligible(String role) =>
      role.isNotEmpty && role != 'guest' &&
      role != 'admin' && role != 'admin_kelurahan';
  static Map<String, String> auth(CikokoApi api) {
    if (api.token == null || api.token!.isEmpty) {
      throw ApiError('Silakan masuk ke akun Anda.');
    }
    return {'Authorization': 'Bearer ${api.token}', 'Accept': 'application/json'};
  }
  static Map<String, dynamic> decode(http.Response response) {
    dynamic data;
    try {
      data = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      throw ApiError('Layanan Jumantik Mandiri belum terpasang di server.');
    }
    if (data is! Map<String, dynamic> || response.statusCode >= 400 || data['ok'] != true) {
      throw ApiError(data is Map
          ? (data['error'] ?? 'Laporan belum dapat diproses.').toString()
          : 'Respons layanan Jumantik Mandiri tidak valid.');
    }
    return data;
  }
  static Future<Map<String, dynamic>> get(CikokoApi api, String action) async =>
      decode(await http.get(url(action), headers: auth(api))
          .timeout(const Duration(seconds: 25)));
  static Future<Map<String, dynamic>> news() async =>
      decode(await http.get(url('news'), headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 20)));
  static String statusText(String status) => switch (status) {
    'published' => 'Diverifikasi / Diterbitkan',
    'rejected' => 'Ditolak / Perlu diperbaiki',
    _ => 'Menunggu verifikasi Super Admin',
  };
}

class JumantikMandiriWarga2607 extends StatefulWidget {
  final CikokoApi api;
  const JumantikMandiriWarga2607({super.key, required this.api});
  @override
  State<JumantikMandiriWarga2607> createState() =>
      _JumantikMandiriWarga2607State();
}

class _JumantikMandiriWarga2607State extends State<JumantikMandiriWarga2607> {
  final form = GlobalKey<FormState>();
  final family = TextEditingController();
  final sender = TextEditingController();
  final phone = TextEditingController();
  final address = TextEditingController();
  final answers = <String, String>{};
  String activity = '';
  String clientKey = _newClientKey();
  bool sending = false;
  XFile? photo;
  Timer? timer;
  DateTime clock = DateTime.now().toUtc().add(const Duration(hours: 7));
  late Future<Map<String, dynamic>> history;

  static String _newClientKey() {
    final random = Random.secure();
    return List<int>.generate(16, (_) => random.nextInt(256))
        .map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
  static String _clock(DateTime now) =>
    '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} '
    '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')} WIB';

  @override
  void initState() {
    super.initState();
    sender.text = (widget.api.profile?['name'] ?? '').toString();
    phone.text = (widget.api.profile?['phone'] ?? '').toString();
    history = CikokoJumantikMandiri2607.get(widget.api, 'mine');
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => clock = DateTime.now().toUtc().add(const Duration(hours: 7)));
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    family.dispose(); sender.dispose(); phone.dispose(); address.dispose();
    super.dispose();
  }

  void notify(String text) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> pick(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: source, maxWidth: 1600, imageQuality: 80);
      if (picked == null) return;
      if (await File(picked.path).length() > 4 * 1024 * 1024) {
        notify('Foto maksimal 4 MB.'); return;
      }
      if (mounted) setState(() => photo = picked);
    } catch (_) {
      notify('Kamera atau galeri belum dapat dibuka.');
    }
  }

  Future<void> send() async {
    if (sending || !(form.currentState?.validate() ?? false)) return;
    if (answers.length != CikokoJumantikMandiri2607.questions.length ||
        answers.values.any((v) => v != 'ya' && v != 'tidak')) {
      notify('Semua 12 pemeriksaan wajib dipilih Ya atau Tidak.'); return;
    }
    if (activity.isEmpty) { notify('Status kegiatan wajib diisi.'); return; }
    if (photo == null) { notify('Mohon lampirkan satu foto dari kamera atau galeri.'); return; }
    setState(() => sending = true);
    try {
      final req = http.MultipartRequest('POST', CikokoJumantikMandiri2607.url('submit'));
      req.headers.addAll(CikokoJumantikMandiri2607.auth(widget.api));
      req.fields.addAll({
        'client_key': clientKey,
        'nama_kepala_keluarga': family.text.trim(),
        'nama_pengirim': sender.text.trim(),
        'no_handphone': phone.text.trim(),
        'alamat': address.text.trim(),
        'checks': jsonEncode({for (final k in CikokoJumantikMandiri2607.questions.keys) k: answers[k]}),
        'kegiatan': activity,
      });
      req.files.add(await http.MultipartFile.fromPath('foto', photo!.path));
      final data = CikokoJumantikMandiri2607.decode(
        await http.Response.fromStream(
          await req.send().timeout(const Duration(seconds: 120))));
      if (!mounted) return;
      family.clear(); address.clear();
      form.currentState?.reset();
      setState(() {
        answers.clear();
        activity = '';
        photo = null;
        clientKey = _newClientKey();
        history = CikokoJumantikMandiri2607.get(widget.api, 'mine');
      });
      notify((data['message'] ?? 'Laporan sudah diterima.').toString());
    } catch (e) {
      notify('Laporan belum berhasil dikirim: ${cikokoFormalMessage(e)}');
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Widget field(String label, TextEditingController controller,
      {int max = 160, int lines = 1, TextInputType? keyboard}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLength: max,
        maxLines: lines,
        keyboardType: keyboard,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        validator: (value) {
          final v = (value ?? '').trim();
          if (v.isEmpty) return 'Wajib diisi';
          if (label == 'No Handphone' && !RegExp(r'^\+?[0-9 ()-]{8,25}$').hasMatch(v)) {
            return 'Isi nomor telepon yang valid';
          }
          if (v.length < (label == 'Alamat' ? 8 : 3)) return 'Mohon isi lebih lengkap';
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = (widget.api.profile?['role'] ?? '').toString();
    if (!CikokoJumantikMandiri2607.eligible(role)) {
      return const Center(child: Text('Jumantik Mandiri Warga hanya untuk akun selain Admin.'));
    }
    return RefreshIndicator(
      onRefresh: () async {
        setState(() => history = CikokoJumantikMandiri2607.get(widget.api, 'mine'));
        await history;
      },
      child: ListView(padding: const EdgeInsets.all(14), children: [
        const Text('Laporan Jumantik Mandiri Warga',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Text('Laporan dipastikan masuk ke server dan harus diverifikasi Super Admin sebelum diterbitkan.'),
        const SizedBox(height: 14),
        Card(child: Padding(padding: const EdgeInsets.all(14),
          child: Form(key: form, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Waktu: ${_clock(clock)}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
              const Text('Waktu pengiriman final dicatat otomatis oleh server.',
                style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
              const SizedBox(height: 14),
              field('Nama Kepala Keluarga', family),
              field('Nama Pengirim', sender),
              field('No Handphone', phone, max: 25, keyboard: TextInputType.phone),
              field('Alamat', address, max: 500, lines: 3),
              const SizedBox(height: 10),
              const Text('Pilihan pemeriksaan',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              for (final entry in CikokoJumantikMandiri2607.questions.entries)
                Padding(padding: const EdgeInsets.only(bottom: 12),
                  child: DropdownButtonFormField<String>(
                    key: ValueKey('${entry.key}-${answers[entry.key] ?? ''}'),
                    initialValue: answers[entry.key],
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: entry.value,
                      labelMaxLines: 3,
                      border: const OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'ya', child: Text('Ya')),
                      DropdownMenuItem(value: 'tidak', child: Text('Tidak')),
                    ],
                    onChanged: sending ? null : (value) =>
                      setState(() => answers[entry.key] = value ?? ''),
                    validator: (value) => value == null ? 'Pilih Ya / Tidak' : null,
                  )),
              DropdownButtonFormField<String>(
                key: ValueKey('kegiatan-$activity'),
                initialValue: activity.isEmpty ? null : activity,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Kegiatan', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'sudah_terlaksana', child: Text('Sudah Terlaksana')),
                  DropdownMenuItem(value: 'belum_terlaksana', child: Text('Belum Terlaksana')),
                ],
                onChanged: sending ? null : (v) => setState(() => activity = v ?? ''),
                validator: (value) => value == null ? 'Wajib dipilih' : null,
              ),
              const SizedBox(height: 16),
              const Text('Lampiran Foto', style: TextStyle(fontWeight: FontWeight.w700)),
              Wrap(spacing: 8, children: [
                OutlinedButton.icon(
                  onPressed: sending ? null : () => pick(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Kamera')),
                OutlinedButton.icon(
                  onPressed: sending ? null : () => pick(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Galeri')),
              ]),
              if (photo != null) Image.file(File(photo!.path), height: 165, fit: BoxFit.contain),
              const SizedBox(height: 15),
              SizedBox(width: double.infinity, child: FilledButton.icon(
                onPressed: sending ? null : send,
                icon: const Icon(Icons.send_outlined),
                label: Text(sending ? 'Mengirim laporan…' : 'Kirim Laporan Jumantik Mandiri'))),
            ],
          )))),
        const SizedBox(height: 16),
        const Text('Riwayat laporan saya',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        FutureBuilder<Map<String, dynamic>>(future: history, builder: (context, snap) {
          if (!snap.hasData) {
            if (snap.hasError) return TextButton(
              onPressed: () => setState(() =>
                history = CikokoJumantikMandiri2607.get(widget.api, 'mine')),
              child: Text('Gagal memuat riwayat. Coba lagi: ${cikokoFormalMessage(snap.error)}'));
            return const Center(child: CircularProgressIndicator());
          }
          final records = List<dynamic>.from(snap.data!['items'] ?? []);
          if (records.isEmpty) return const Card(child: ListTile(
            title: Text('Belum ada laporan Jumantik Mandiri.')));
          return Column(children: [
            for (final item in records.whereType<Map>())
              Card(child: ListTile(
                title: Text('Laporan #${item['id'] ?? ''} · ${item['waktu'] ?? ''}'),
                subtitle: Text('${CikokoJumantikMandiri2607.statusText((item['status'] ?? '').toString())}'
                  '${(item['reject_reason'] ?? '').toString().isNotEmpty ? '\nAlasan: ${item['reject_reason']}' : ''}'),
                isThreeLine: true,
              ))
          ]);
        })
      ]),
    );
  }
}

class JumantikMandiriNews2607 extends StatefulWidget {
  const JumantikMandiriNews2607({super.key});
  @override
  State<JumantikMandiriNews2607> createState() => _JumantikMandiriNews2607State();
}
class _JumantikMandiriNews2607State extends State<JumantikMandiriNews2607> {
  late Future<Map<String, dynamic>> published;
  @override
  void initState() { super.initState(); published = CikokoJumantikMandiri2607.news(); }
  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
    future: published, builder: (context, result) {
      if (!result.hasData) {
        if (result.hasError) return Center(child: TextButton(
          onPressed: () => setState(() => published = CikokoJumantikMandiri2607.news()),
          child: const Text('Berita belum bisa dimuat. Coba lagi.')));
        return const Center(child: CircularProgressIndicator());
      }
      final records = List<dynamic>.from(result.data!['items'] ?? []);
      return RefreshIndicator(
        onRefresh: () async {
          setState(() => published = CikokoJumantikMandiri2607.news());
          await published;
        },
        child: ListView(padding: const EdgeInsets.all(16), children: [
          const Text('Berita Jumantik Mandiri Warga',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Laporan warga yang telah diverifikasi. '
            'Identitas keluarga, alamat dan nomor HP tidak dipublikasikan.'),
          if (records.isEmpty) const Card(child: ListTile(
            title: Text('Belum ada laporan warga yang diterbitkan.'))),
          for (final item in records.whereType<Map>())
            Card(child: ListTile(
              leading: const Icon(Icons.verified_user_outlined),
              title: const Text('Laporan Jumantik Mandiri Warga terbaru'),
              subtitle: Text('Diverifikasi: ${item['waktu'] ?? ''}\n'
                'Kegiatan: ${item['kegiatan']=='sudah_terlaksana' ? 'Sudah Terlaksana' : 'Belum Terlaksana'}'),
            )),
        ]));
    });
}

class JumantikMandiriAdmin2607 extends StatefulWidget {
  final CikokoApi api;
  const JumantikMandiriAdmin2607({super.key, required this.api});
  @override
  State<JumantikMandiriAdmin2607> createState() => _JumantikMandiriAdmin2607State();
}
class _JumantikMandiriAdmin2607State extends State<JumantikMandiriAdmin2607> {
  late Future<Map<String, dynamic>> listing;
  int? busyId;
  @override
  void initState() {
    super.initState();
    listing = CikokoJumantikMandiri2607.get(widget.api, 'admin_list');
  }
  Future<void> decide(int id, String decision, {String reason = ''}) async {
    if (busyId != null) return;
    setState(() => busyId = id);
    try {
      final response = await http.post(CikokoJumantikMandiri2607.url('admin_decide'),
        headers: {...CikokoJumantikMandiri2607.auth(widget.api),
          'Content-Type': 'application/json'},
        body: jsonEncode({'id': id, 'decision': decision, 'reason': reason}),
      ).timeout(const Duration(seconds: 35));
      final result = CikokoJumantikMandiri2607.decode(response);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text((result['message'] ?? 'Status berhasil diubah.').toString())));
      setState(() => listing = CikokoJumantikMandiri2607.get(widget.api, 'admin_list'));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verifikasi gagal: ${cikokoFormalMessage(e)}')));
    } finally {
      if (mounted) setState(() => busyId = null);
    }
  }
  Future<void> reject(int id) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(context: context, builder: (dialog) =>
      AlertDialog(
        title: const Text('Alasan penolakan'),
        content: TextField(controller: controller, maxLength: 300, maxLines: 3,
          decoration: const InputDecoration(hintText: 'Jelaskan perbaikan laporan yang diperlukan')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialog), child: const Text('Batal')),
          FilledButton(onPressed: () {
            if (controller.text.trim().isNotEmpty) Navigator.pop(dialog, controller.text.trim());
          }, child: const Text('Tolak laporan')),
        ]));
    controller.dispose();
    if (reason != null && reason.isNotEmpty) await decide(id, 'reject', reason: reason);
  }
  @override
  Widget build(BuildContext context) {
    if ((widget.api.profile?['role'] ?? '') != 'admin') {
      return const Center(child: Text('Hanya Super Admin yang dapat memeriksa laporan warga.'));
    }
    return FutureBuilder<Map<String, dynamic>>(future: listing, builder: (context, snap) {
      if (!snap.hasData) {
        if (snap.hasError) return Center(child: TextButton(
          onPressed: () => setState(() => listing =
            CikokoJumantikMandiri2607.get(widget.api, 'admin_list')),
          child: const Text('Gagal memuat. Periksa API dan coba lagi.')));
        return const Center(child: CircularProgressIndicator());
      }
      final rows = List<dynamic>.from(snap.data!['items'] ?? []);
      return RefreshIndicator(
        onRefresh: () async {
          setState(() => listing = CikokoJumantikMandiri2607.get(widget.api, 'admin_list'));
          await listing;
        },
        child: ListView(padding: const EdgeInsets.all(14), children: [
          const Text('Verifikasi Jumantik Mandiri Warga',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
          const Text('Periksa foto, 12 pilihan, dan kegiatan. Hanya keputusan terverifikasi '
            'yang ditampilkan sebagai berita publik; data pribadi tetap terlindungi.'),
          const SizedBox(height: 12),
          if (rows.isEmpty) const Card(child: ListTile(title: Text('Belum ada laporan Jumantik Mandiri.'))),
          for (final row in rows.whereType<Map>()) Builder(builder: (context) {
            final id = int.tryParse('${row['id'] ?? ''}') ?? 0;
            final status = (row['status'] ?? 'pending').toString();
            final checks = (row['checks'] as Map?) ?? {};
            final photoUrl = CikokoJumantikMandiri2607.url('photo')
              .replace(queryParameters: {'action': 'photo', 'id': '$id'});
            return Card(child: ExpansionTile(
              title: Text('Laporan #$id · ${row['waktu'] ?? ''}'),
              subtitle: Text('Status: ${CikokoJumantikMandiri2607.statusText(status)}'),
              childrenPadding: const EdgeInsets.all(14),
              children: [
                Align(alignment: Alignment.centerLeft, child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Nama Kepala Keluarga: ${row['nama_kepala_keluarga'] ?? ''}'),
                    Text('Nama Pengirim: ${row['nama_pengirim'] ?? ''}'),
                    Text('No Handphone: ${row['no_handphone'] ?? ''}'),
                    Text('Alamat: ${row['alamat'] ?? ''}'),
                    const SizedBox(height: 8),
                    for (final q in CikokoJumantikMandiri2607.questions.entries)
                      Text('${q.value}: ${checks[q.key] ?? '-'}'),
                    Text('Kegiatan: ${row['kegiatan']=='sudah_terlaksana' ? 'Sudah Terlaksana' : 'Belum Terlaksana'}'),
                    const SizedBox(height: 10),
                    if (id > 0) Image.network(photoUrl.toString(),
                      headers: CikokoJumantikMandiri2607.auth(widget.api),
                      height: 190, fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                        const Text('Foto tidak tersedia. Jangan terbitkan sebelum foto diperiksa.')),
                    const SizedBox(height: 10),
                    if (status == 'rejected') Text('Alasan: ${row['reject_reason'] ?? ''}'),
                    if (status == 'pending') Wrap(spacing: 8, children: [
                      OutlinedButton(onPressed: busyId != null ? null : () => reject(id),
                        child: const Text('Tolak')),
                      FilledButton.icon(onPressed: busyId != null ? null : () => decide(id, 'publish'),
                        icon: const Icon(Icons.verified_outlined),
                        label: const Text('Verifikasi & Terbitkan')),
                    ]),
                  ]),
                )),
              ],
            ));
          }),
        ]));
    });
  }
}
