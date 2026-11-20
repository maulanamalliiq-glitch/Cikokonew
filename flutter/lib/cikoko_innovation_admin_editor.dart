import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'api.dart';

const _innoNavy = Color(0xff12375d);
const _innoBlue = Color(0xff246ac5);

/// Uses the same innovation JSON stores as website 2602, never a second CMS.
abstract final class CikokoInnovationAdminApi {
  static Uri get endpoint => Uri.parse(
      CikokoApi.root.replaceFirst('index.php', 'inovasi-editor-2603.php'));

  static Map<String, String> headers(CikokoApi api) {
    if (api.token == null || api.token!.isEmpty) {
      throw ApiError('Silakan login Super Admin terlebih dahulu.');
    }
    return {'Authorization': 'Bearer ${api.token}',
      'Accept': 'application/json'};
  }

  static Map<String, dynamic> decode(http.Response response) {
    final dynamic json;
    try {
      json = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      throw ApiError('Pengelola Inovasi belum tersedia di server.');
    }
    if (json is! Map<String, dynamic> || json['ok'] != true ||
        response.statusCode >= 400) {
      throw ApiError(json is Map
          ? (json['error'] ?? 'Data Inovasi belum dapat disimpan.').toString()
          : 'Data Inovasi belum dapat diproses.');
    }
    return json;
  }

  static Future<List<Map<String, dynamic>>> load(CikokoApi api) async {
    final res = await http.get(endpoint, headers: headers(api))
        .timeout(const Duration(seconds: 20));
    final decoded = decode(res);
    final items = decoded['items'];
    if (items is! List) throw ApiError('Daftar inovasi tidak valid.');
    return items.whereType<Map>().map(
        (e) => Map<String, dynamic>.from(e)).toList();
  }

  static Future<void> hide(CikokoApi api, String slug) async {
    final req = http.MultipartRequest('POST', endpoint);
    req.headers.addAll(headers(api));
    req.fields['mode'] = 'hide';
    req.fields['slug'] = slug;
    final res = await http.Response.fromStream(
        await req.send().timeout(const Duration(seconds: 35)));
    decode(res);
  }
}

class CikokoInnovationAdminPage extends StatefulWidget {
  final CikokoApi api;
  const CikokoInnovationAdminPage({super.key, required this.api});

  @override
  State<CikokoInnovationAdminPage> createState() =>
      _CikokoInnovationAdminPageState();
}

class _CikokoInnovationAdminPageState
    extends State<CikokoInnovationAdminPage> {
  late Future<List<Map<String, dynamic>>> _pending;
  bool _working = false;

  @override
  void initState() { super.initState(); _reload(); }

  void _reload() { _pending = CikokoInnovationAdminApi.load(widget.api); }

  Future<void> _edit([Map<String, dynamic>? item]) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => CikokoInnovationEditPage(
        api: widget.api, item: item)));
    if (changed == true && mounted) setState(_reload);
  }

  Future<void> _hide(Map<String, dynamic> item) async {
    if (_working) return;
    final accepted = await showDialog<bool>(context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Sembunyikan inovasi?'),
          content: Text('Inovasi "${item['title'] ?? ''}" tidak akan terlihat '
              'oleh warga. Data dan foto tidak akan dihapus.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Batal')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Sembunyikan')),
          ],
        ));
    if (accepted != true || !mounted) return;
    setState(() => _working = true);
    try {
      await CikokoInnovationAdminApi.hide(
          widget.api, (item['slug'] ?? '').toString());
      if (mounted) {
        setState(_reload);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inovasi disembunyikan.')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Belum berhasil: $e')));
    } finally { if (mounted) setState(() => _working = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xfff3f7fd),
    appBar: AppBar(title: const Text('Kelola Inovasi'),
      backgroundColor: Colors.white, foregroundColor: _innoNavy),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _working ? null : () => _edit(),
      icon: const Icon(Icons.add),
      label: const Text('Tambah Inovasi')),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: _pending,
      builder: (ctx, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('Gagal memuat editor Inovasi: ${snapshot.error}',
                  textAlign: TextAlign.center),
              const SizedBox(height: 10),
              OutlinedButton(onPressed: () => setState(_reload),
                  child: const Text('Coba lagi')),
            ]),
          ));
        }
        final items = snapshot.data ?? [];
        return RefreshIndicator(onRefresh: () async {
          setState(_reload); await _pending;
        }, child: ListView(padding: const EdgeInsets.fromLTRB(12, 14, 12, 100),
          children: [
            const Card(child: Padding(
              padding: EdgeInsets.all(15),
              child: Text('Kelola semua Inovasi Kelurahan Cikoko. '
                  'Foto, uraian, alamat, dan WhatsApp yang disimpan akan '
                  'ditampilkan di website dan aplikasi.',
                  style: TextStyle(color: _innoNavy, height: 1.4)))),
            if (items.isEmpty) const Padding(padding: EdgeInsets.all(24),
              child: Center(child: Text('Belum ada inovasi. '
                  'Ketuk Tambah Inovasi.'))),
            for (final item in items) Card(
              child: Padding(padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text((item['title'] ?? 'Inovasi').toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold,
                        fontSize: 16, color: _innoNavy)),
                    const SizedBox(height: 4),
                    Text((item['summary'] ?? '').toString(),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 5),
                    Text(item['active'] == false ? 'Disembunyikan' : 'Ditampilkan',
                      style: const TextStyle(fontSize: 12,
                        color: Colors.blueGrey)),
                    Wrap(spacing: 6, children: [
                      OutlinedButton.icon(
                        onPressed: _working ? null : () => _edit(item),
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Edit lengkap')),
                      if (item['active'] != false)
                        TextButton.icon(
                          onPressed: _working ? null : () => _hide(item),
                          icon: const Icon(Icons.visibility_off_outlined,
                            size: 16),
                          label: const Text('Sembunyikan')),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ));
      },
    ),
  );
}

class CikokoInnovationEditPage extends StatefulWidget {
  final CikokoApi api;
  final Map<String, dynamic>? item;
  const CikokoInnovationEditPage({super.key, required this.api, this.item});
  @override
  State<CikokoInnovationEditPage> createState() =>
      _CikokoInnovationEditPageState();
}

class _CikokoInnovationEditPageState extends State<CikokoInnovationEditPage> {
  final _form = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _field;
  final _picker = ImagePicker();
  late List<String> _keptImages;
  final List<XFile> _newImages = [];
  String _oldExtra = '';
  bool _keepExtra = true;
  XFile? _newExtra;
  bool _active = true, _saving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item ?? <String, dynamic>{};
    _field = {
      for (final key in ['title', 'summary', 'body', 'extra_text',
          'address', 'whatsapp'])
        key: TextEditingController(text: (item[key] ?? '').toString()),
    };
    final images = item['images'];
    _keptImages = images is List
        ? images.map((e) => e.toString()).take(5).toList()
        : [];
    _oldExtra = (item['extra_image'] ?? '').toString();
    _keepExtra = _oldExtra.isNotEmpty;
    _active = item['active'] != false;
  }

  @override
  void dispose() {
    for (final controller in _field.values) { controller.dispose(); }
    super.dispose();
  }

  Future<void> _pickSlides() async {
    if (_saving || _keptImages.length + _newImages.length >= 5) return;
    final result = await _picker.pickMultiImage(
        imageQuality: 82, maxWidth: 1600);
    if (!mounted || result.isEmpty) return;
    final remaining = 5 - _keptImages.length - _newImages.length;
    if (result.length > remaining) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hanya dapat menambah $remaining foto lagi.')));
      return;
    }
    for (final photo in result) {
      if (await File(photo.path).length() > 4 * 1024 * 1024) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maksimal 4 MB per foto.')));
        return;
      }
    }
    setState(() => _newImages.addAll(result));
  }

  Future<void> _pickExtra() async {
    if (_saving) return;
    final selected = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 82, maxWidth: 1600);
    if (selected == null || !mounted) return;
    if (await File(selected.path).length() > 4 * 1024 * 1024) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto tambahan maksimal 4 MB.')));
      return;
    }
    setState(() { _newExtra = selected; _keepExtra = false; });
  }

  Future<void> _submit() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final req = http.MultipartRequest(
          'POST', CikokoInnovationAdminApi.endpoint);
      req.headers.addAll(CikokoInnovationAdminApi.headers(widget.api));
      req.fields['mode'] = 'save';
      req.fields['slug'] = (widget.item?['slug'] ?? '').toString();
      for (final entry in _field.entries) {
        req.fields[entry.key] = entry.value.text.trim();
      }
      req.fields['active'] = _active ? '1' : '0';
      for (var i = 0; i < _keptImages.length; i++) {
        req.fields['keep_images[$i]'] = _keptImages[i];
      }
      req.fields['keep_extra'] = _keepExtra ? '1' : '0';
      for (final photo in _newImages) {
        req.files.add(await http.MultipartFile.fromPath(
            'slides[]', photo.path));
      }
      if (_newExtra != null) {
        req.files.add(await http.MultipartFile.fromPath(
            'extra_photo', _newExtra!.path));
      }
      final res = await http.Response.fromStream(
          await req.send().timeout(const Duration(seconds: 120)));
      CikokoInnovationAdminApi.decode(res);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inovasi berhasil disimpan.')));
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tidak berhasil menyimpan: $e')));
    } finally { if (mounted) setState(() => _saving = false); }
  }

  Widget _textField(String name, String label,
      {int maxLines = 1, int maxLength = 160, bool required = false,
       TextInputType? keyboard}) =>
    Padding(padding: const EdgeInsets.only(bottom: 13),
      child: TextFormField(
        controller: _field[name],
        keyboardType: keyboard,
        maxLength: maxLength,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label,
          border: const OutlineInputBorder()),
        validator: (v) {
          final value = (v ?? '').trim();
          if (required && value.isEmpty) return 'Wajib diisi';
          if (name == 'whatsapp' && value.isNotEmpty &&
              !cikokoInnovationPhoneValid(value)) {
            return 'Nomor WhatsApp Indonesia tidak valid';
          }
          return null;
        },
      ),
    );

  Widget _photoTile({required String label, required Widget photo,
      required VoidCallback? onDelete}) =>
    SizedBox(width: 105, child: Column(children: [
      ClipRRect(borderRadius: BorderRadius.circular(9),
        child: SizedBox(width: 100, height: 80, child: photo)),
      const SizedBox(height: 4),
      Row(children: [
        Expanded(child: Text(label, maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 10))),
        IconButton(icon: const Icon(Icons.close, size: 16),
          tooltip: 'Lepas foto', onPressed: _saving ? null : onDelete),
      ]),
    ]));

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.item == null
        ? 'Tambah Inovasi' : 'Edit Inovasi'),
      backgroundColor: Colors.white, foregroundColor: _innoNavy),
    body: Form(key: _form, child: ListView(
      padding: const EdgeInsets.fromLTRB(14, 15, 14, 90),
      children: [
        _textField('title', 'Judul inovasi',
          required: true, maxLength: 160),
        _textField('summary', 'Ringkasan di kartu beranda',
          maxLines: 2, maxLength: 500),
        const Text('Foto slide atas (maksimal 5)',
          style: TextStyle(fontWeight: FontWeight.bold, color: _innoNavy)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 7, children: [
          for (final path in List<String>.from(_keptImages))
            _photoTile(label: 'Foto tersimpan',
              photo: Image.network(widget.api.media(path),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                  const Icon(Icons.broken_image_outlined)),
              onDelete: () => setState(() => _keptImages.remove(path))),
          for (final photo in List<XFile>.from(_newImages))
            _photoTile(label: 'Foto baru',
              photo: Image.file(File(photo.path), fit: BoxFit.cover),
              onDelete: () => setState(() => _newImages.remove(photo))),
        ]),
        OutlinedButton.icon(
          onPressed: _saving || _keptImages.length + _newImages.length >= 5
              ? null : _pickSlides,
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: Text('Tambah foto slide (${_keptImages.length + _newImages.length}/5)')),
        const SizedBox(height: 16),
        _textField('body', 'Keterangan bagian pertama',
          maxLines: 6, maxLength: 16000),
        const Text('Foto bagian kedua',
          style: TextStyle(fontWeight: FontWeight.bold, color: _innoNavy)),
        const SizedBox(height: 8),
        if (_oldExtra.isNotEmpty && _keepExtra && _newExtra == null)
          _photoTile(label: 'Foto tersimpan',
            photo: Image.network(widget.api.media(_oldExtra),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                const Icon(Icons.broken_image_outlined)),
            onDelete: () => setState(() => _keepExtra = false)),
        if (_newExtra != null)
          _photoTile(label: 'Foto baru',
            photo: Image.file(File(_newExtra!.path), fit: BoxFit.cover),
            onDelete: () => setState(() { _newExtra = null; _keepExtra = false; })),
        OutlinedButton.icon(onPressed: _saving ? null : _pickExtra,
          icon: const Icon(Icons.image_outlined),
          label: const Text('Pilih foto bagian kedua')),
        const SizedBox(height: 14),
        _textField('extra_text', 'Keterangan bagian kedua',
          maxLines: 6, maxLength: 16000),
        _textField('address', 'Alamat lengkap',
          maxLines: 3, maxLength: 1000),
        _textField('whatsapp', 'Nomor WhatsApp',
          maxLength: 30, keyboard: TextInputType.phone),
        SwitchListTile(title: const Text('Tampilkan ke publik'),
          subtitle: const Text('Jika nonaktif, tidak tampil di website dan aplikasi'),
          value: _active, onChanged: _saving ? null :
          (v) => setState(() => _active = v)),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _saving ? null : _submit,
          icon: _saving ? const SizedBox(width: 18, height: 18,
            child: CircularProgressIndicator(strokeWidth: 2,
              color: Colors.white)) : const Icon(Icons.save_outlined),
          label: Text(_saving ? 'Menyimpan...' : 'Simpan Inovasi')),
      ],
    )),
  );
}

/// Pure validation, also tested independently of the widget.
bool cikokoInnovationPhoneValid(String phone) {
  final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
  if (phone.trim().isEmpty) return true;
  if (digits.isEmpty) return false;
  var normalized = digits;
  if (digits.startsWith('0')) normalized = '62${digits.substring(1)}';
  if (digits.startsWith('8')) normalized = '62$digits';
  return RegExp(r'^62[0-9]{8,13}$').hasMatch(normalized);
}
