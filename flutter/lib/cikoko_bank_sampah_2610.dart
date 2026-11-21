import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'api.dart';
import 'cikoko_bank_sampah_mockup_2613.dart';

/// Bank Sampah Cikoko: project-specific module, isolated from attendance,
/// PJLP leave, PPPK performance and Jumantik reporting.
abstract final class CikokoBankSampahApi2610 {
  static Uri url(String action, [Map<String, String>? query]) =>
      Uri.parse(CikokoApi.root.replaceFirst('index.php', 'bank_sampah_2610.php'))
          .replace(queryParameters: {'action': action, ...?query});

  static Future<Map<String, dynamic>> call(
    CikokoApi api,
    String action, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
  }) async {
    final token = api.token;
    if (token == null || token.isEmpty) {
      throw ApiError('Silakan login ke Cikoko Smart.');
    }
    final headers = <String, String>{
      'Authorization': 'Bearer ' + token,
      'Accept': 'application/json',
    };
    if (body != null) headers['Content-Type'] = 'application/json';
    final uri = url(action, query);
    final http.Response response = body == null
        ? await http.get(uri, headers: headers).timeout(const Duration(seconds: 25))
        : await http.post(uri, headers: headers, body: jsonEncode(body))
            .timeout(const Duration(seconds: 35));
    dynamic data;
    try {
      data = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      throw ApiError('API Bank Sampah belum terpasang di hosting.');
    }
    if (data is! Map<String, dynamic> || response.statusCode >= 400 || data['ok'] != true) {
      throw ApiError(data is Map
          ? (data['error'] ?? 'Layanan Bank Sampah tidak tersedia.').toString()
          : 'Server Bank Sampah tidak mengirim respons yang valid.');
    }
    return data;
  }

  static String kilos(Object? value) {
    final n = double.tryParse((value ?? '0').toString()) ?? 0;
    return n.toStringAsFixed(3).replaceFirst(RegExp(r'\.?0+$'), '');
  }

  static String money(Object? value) {
    final n = int.tryParse((value ?? '0').toString()) ?? 0;
    final digits = n.toString();
    return digits.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
  }

  static String heading(Map<String, dynamic> totals) =>
      kilos(totals['weight_kg']) + ' Kg   |   Rp ' + money(totals['amount_rp']) + ',-';

  static String dateLocal(String iso) {
    final parts = iso.split('-');
    if (parts.length != 3) return iso;
    return parts[2] + '/' + parts[1] + '/' + parts[0];
  }

  static const supportedRoles = <String>[
    'pjlp', 'pppk', 'asn', 'lurah', 'admin', 'admin_kelurahan'
  ];
}

class BankSampahProfileSummary2610 extends StatefulWidget {
  final CikokoApi api;
  final VoidCallback onOpen;
  const BankSampahProfileSummary2610({
    super.key, required this.api, required this.onOpen
  });
  @override
  State<BankSampahProfileSummary2610> createState() => _BankSampahProfileSummary2610State();
}
class _BankSampahProfileSummary2610State extends State<BankSampahProfileSummary2610> {
  late Future<Map<String, dynamic>> pending;
  @override
  void initState() { super.initState(); reload(); }
  void reload() => pending = CikokoBankSampahApi2610.call(
    widget.api, 'summary', query: {'year': DateTime.now().year.toString()}
  );
  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
    future: pending, builder: (context, result) {
      final totals = result.data?['totals'] is Map
          ? Map<String, dynamic>.from(result.data!['totals'] as Map)
          : <String, dynamic>{};
      return Card(
        key: const Key('bank_sampah_profile_2610'),
        margin: const EdgeInsets.only(top: 12, bottom: 4),
        child: InkWell(
          onTap: widget.onOpen,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Icon(Icons.recycling_outlined, color: Color(0xff16834d)),
                SizedBox(width: 8),
                Expanded(child: Text('Bank Sampah Cikoko',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800))),
                Icon(Icons.chevron_right),
              ]),
              const SizedBox(height: 5),
              Text('Total hasil penyerahan tahun ' + DateTime.now().year.toString(),
                style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
              const SizedBox(height: 7),
              if (result.hasData)
                Text(CikokoBankSampahApi2610.heading(totals),
                  key: const Key('bank_sampah_profile_total_2610'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))
              else if (result.hasError)
                const Text('Rekap belum dapat dimuat. Buka Bank Sampah untuk memeriksa koneksi.',
                  style: TextStyle(fontSize: 12, color: Colors.deepOrange))
              else
                const LinearProgressIndicator(minHeight: 2),
            ]),
          ),
        ),
      );
    },
  );
}

class BankSampahPage2610 extends StatefulWidget {
  final CikokoApi api;
  const BankSampahPage2610({super.key, required this.api});
  @override
  State<BankSampahPage2610> createState() => _BankSampahPage2610State();
}

class _BankSampahPage2610State extends State<BankSampahPage2610> {
  int year = DateTime.now().year;
  bool loading = true;
  String error = '';
  Map<String, dynamic> permissions = {};
  Map<String, dynamic> dashboard = {};
  Map<String, dynamic> annual = {};
  Map<String, dynamic> members = {};
  Map<String, dynamic> summary = {};
  Map<String, dynamic> selectedSession = {};
  int? sessionId;

  bool get canManage => permissions['can_manage'] == true;
  bool get canInput => permissions['can_input'] == true;
  bool get canSeeAll => permissions['can_view_full'] == true;

  List<Map<String, dynamic>> records(Map<String, dynamic> source, String key) =>
      (source[key] is List ? source[key] as List : [])
          .whereType<Map>()
          .map((r) => Map<String, dynamic>.from(r))
          .toList();

  @override
  void initState() {
    super.initState();
    refresh();
  }

  void message(String value) {
    if (mounted) ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(value)));
  }

  Future<void> refresh() async {
    if (mounted) setState(() { loading = true; error = ''; });
    try {
      final access = await CikokoBankSampahApi2610.call(widget.api, 'status');
      Map<String, dynamic> dash = {};
      Map<String, dynamic> annualData = {};
      Map<String, dynamic> membersData = {};
      Map<String, dynamic> myData = {};
      Map<String, dynamic> sessionData = {};
      int? nextSession = sessionId;
      if (access['can_view_full'] == true) {
        final responses = await Future.wait([
          CikokoBankSampahApi2610.call(widget.api, 'dashboard',
              query: {'year': year.toString()}),
          CikokoBankSampahApi2610.call(widget.api, 'annual',
              query: {'year': year.toString()}),
          CikokoBankSampahApi2610.call(widget.api, 'members'),
        ]);
        dash = responses[0]; annualData = responses[1]; membersData = responses[2];
        final sessions = records(dash, 'sessions');
        if (sessions.isEmpty) {
          nextSession = null;
        } else if (!sessions.any((s) => s['id'].toString() == nextSession.toString())) {
          nextSession = int.tryParse(sessions.first['id'].toString());
        }
        if (nextSession != null) {
          sessionData = await CikokoBankSampahApi2610.call(widget.api,
              'session_entries', query: {'session_id': nextSession.toString()});
        }
      } else {
        myData = await CikokoBankSampahApi2610.call(widget.api,
            'summary', query: {'year': year.toString()});
      }
      if (mounted) setState(() {
        permissions = access; dashboard = dash; annual = annualData;
        members = membersData; summary = myData; selectedSession = sessionData;
        sessionId = nextSession; loading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        loading = false;
        error = cikokoFormalMessage(e);
      });
    }
  }

  Future<void> act(String action, Map<String, dynamic> body) async {
    try {
      final result = await CikokoBankSampahApi2610.call(
        widget.api, action, body: body);
      message((result['message'] ?? 'Data berhasil disimpan.').toString());
      await refresh();
    } catch (e) {
      message('Perubahan gagal: ' + cikokoFormalMessage(e));
    }
  }

  Widget totalsCard(Map<String, dynamic> data, String title) {
    final totals = data['totals'] is Map
        ? Map<String, dynamic>.from(data['totals'] as Map)
        : <String, dynamic>{};
    return Card(child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(CikokoBankSampahApi2610.heading(totals),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
              color: Color(0xff11693e))),
        Text('Total catatan: ' + (totals['entries'] ?? 0).toString(),
          style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
      ]),
    ));
  }

  Future<void> chooseYear(int offset) async {
    final next = year + offset;
    if (next < 2020 || next > 2100) return;
    setState(() { year = next; sessionId = null; });
    await refresh();
  }

  Widget yearChooser() => Row(mainAxisAlignment: MainAxisAlignment.center,
    children: [
      IconButton(onPressed: loading ? null : () => chooseYear(-1),
        icon: const Icon(Icons.chevron_left), tooltip: 'Tahun sebelumnya'),
      Text(year.toString(), style: const TextStyle(fontWeight: FontWeight.bold,
        fontSize: 17)),
      IconButton(onPressed: loading ? null : () => chooseYear(1),
        icon: const Icon(Icons.chevron_right), tooltip: 'Tahun berikutnya'),
    ]);

  Widget mySummary() => Column(crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      totalsCard(summary, 'Hasil Bank Sampah Saya · ' + year.toString()),
      const Card(child: Padding(
        padding: EdgeInsets.all(14),
        child: Text('Penimbangan dicatat oleh petugas PJLP atau PPPK yang ditunjuk Admin. '
          'Rekap nama barang dan laporan lengkap dapat dilihat oleh ASN dan Admin.'),
      )),
    ],
  );

  Future<void> createSession() async {
    final now = DateTime.now();
    DateTime sunday = DateTime(now.year, now.month, now.day);
    while (sunday.weekday != DateTime.sunday) {
      sunday = sunday.add(const Duration(days: 1));
    }
    final date = await showDatePicker(
      context: context, initialDate: sunday,
      firstDate: DateTime(now.year - 2, 1, 1),
      lastDate: DateTime(now.year + 2, 12, 31),
      selectableDayPredicate: (d) => d.weekday == DateTime.sunday,
      helpText: 'Pilih tanggal Minggu untuk Bank Sampah',
    );
    if (date == null) return;
    final text = date.year.toString().padLeft(4, '0') + '-' +
        date.month.toString().padLeft(2, '0') + '-' +
        date.day.toString().padLeft(2, '0');
    await act('session_create', {'session_date': text, 'note': 'Penimbangan Bank Sampah Cikoko'});
  }

  Future<void> setCadence(String cadence) async {
    await act('config_set', {
      'cadence': cadence,
      'anchor_month': (dashboard['anchor_month'] ?? 1),
    });
  }

  Future<void> changeSession(int id) async {
    setState(() { sessionId = id; loading = true; });
    try {
      final result = await CikokoBankSampahApi2610.call(
        widget.api, 'session_entries', query: {'session_id': id.toString()});
      if (mounted) setState(() { selectedSession = result; loading = false; });
    } catch (e) {
      if (mounted) setState(() { error = cikokoFormalMessage(e); loading = false; });
    }
  }

  Future<void> editEntry([Map<String, dynamic>? entry]) async {
    final eligible = records(members, 'items')
        .where((r) => r['active'] == true && r['is_member'] == true)
        .toList();
    if (eligible.isEmpty) { message('Admin perlu mengaktifkan anggota PJLP/PPPK.'); return; }
    final selected = selectedSession['session'] is Map
        ? Map<String, dynamic>.from(selectedSession['session'] as Map)
        : <String, dynamic>{};
    if (selected['status'] != 'open') {
      message('Pilih penimbangan yang masih terbuka.'); return;
    }
    String selectedMember = entry?['member_user_id']?.toString() ??
        eligible.first['id'].toString();
    final item = TextEditingController(text: entry?['item_name']?.toString() ?? '');
    final kg = TextEditingController(text: entry?['weight_kg']?.toString() ?? '');
    final rupiah = TextEditingController(text: entry?['amount_rp']?.toString() ?? '0');
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(entry == null ? 'Tambah Hasil Timbang' : 'Perbarui Timbang / Rupiah'),
          scrollable: true,
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<String>(
              initialValue: selectedMember,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Nama Anggota'),
              items: [
                for (final p in eligible)
                  DropdownMenuItem(value: p['id'].toString(),
                      child: Text(p['name'].toString(), overflow: TextOverflow.ellipsis)),
              ],
              onChanged: entry == null
                  ? (value) => setDialogState(() => selectedMember = value ?? selectedMember)
                  : null,
            ),
            TextField(controller: item,
              decoration: const InputDecoration(labelText: 'Nama Barang',
                  hintText: 'Contoh: Kardus, Kertas, Botol, Besi')),
            TextField(controller: kg,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Hasil Timbangan (Kg)',
                  hintText: 'Contoh: 2.5')),
            TextField(controller: rupiah, keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Jumlah Rupiah (Rp)',
                helperText: 'Boleh 0 dahulu; petugas dapat memperbarui kemudian.')),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialog),
              child: const Text('Batal')),
            FilledButton(onPressed: () {
              final weight = kg.text.trim().replaceAll(',', '.');
              final money = int.tryParse(rupiah.text.trim());
              if (selectedMember.isEmpty || item.text.trim().length < 2 ||
                  double.tryParse(weight) == null ||
                  double.parse(weight) <= 0 ||
                  money == null || money < 0) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Periksa anggota, barang, Kg, dan Rupiah.')));
                return;
              }
              Navigator.pop(dialog, {
                if (entry != null) 'id': entry['id'],
                'session_id': selected['id'],
                'member_user_id': selectedMember,
                'item_name': item.text.trim(),
                'weight_kg': weight,
                'amount_rp': money,
              });
            }, child: const Text('Simpan')),
          ],
        ),
      ),
    );
    item.dispose(); kg.dispose(); rupiah.dispose();
    if (result != null) await act('entry_save', result);
  }

  /// The existing edit dialog writes each row straight to the server in
  /// an open session. This button verifies/reloads the saved draft, without
  /// publishing or closing the session.
  Future<void> saveDraft() async {
    final id=sessionId;
    if(id==null){message('Pilih tanggal timbang terlebih dahulu.');return;}
    try {
      final result=await CikokoBankSampahApi2610.call(
        widget.api,'session_entries',query:{'session_id':id.toString()});
      if(!mounted)return;
      setState(()=>selectedSession=result);
      message('Draft sudah tersimpan di server (' +
        records(result,'items').length.toString() + ' baris).');
    }catch(e){
      message('Belum dapat memeriksa draft: '+cikokoFormalMessage(e));
    }
  }

  Future<void> submitWeighing() async {
    final id=sessionId;
    if(id==null){message('Pilih tanggal timbang dahulu.');return;}
    final existing=records(selectedSession,'items');
    if(existing.isEmpty){message('Tambahkan minimal satu baris timbangan.');return;}
    final approved=await showDialog<bool>(context:context,builder:(dialog)=>
      AlertDialog(
        title:const Text('Kirim hasil penimbangan?'),
        content:const Text('Setelah dikirim, petugas tidak dapat mengubah '
          'draft sampai Super Admin membuka kembali sesi. '
          'Hasil akan menunggu pemeriksaan dan pengesahan Admin.'),
        actions:[
          TextButton(onPressed:()=>Navigator.pop(dialog,false),
            child:const Text('Kembali')),
          FilledButton(onPressed:()=>Navigator.pop(dialog,true),
            child:const Text('Ya, Kirim Penimbangan')),
        ],
      ));
    if(approved==true)await act('session_submit',{'session_id':id});
  }

  Widget weighingTotals(Map<String,dynamic> result){
    final data=result['totals'] is Map
      ? Map<String,dynamic>.from(result['totals'] as Map)
      : <String,dynamic>{};
    Widget metric(IconData icon,String label,String value)=>Expanded(
      child:Container(
        padding:const EdgeInsets.all(12),
        decoration:BoxDecoration(
          color:const Color(0xffeef8f0),
          borderRadius:BorderRadius.circular(13)),
        child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Icon(icon,color:const Color(0xff218541),size:24),
          const SizedBox(height:4),
          Text(label,style:const TextStyle(fontSize:11.2,color:Color(0xff335342))),
          const SizedBox(height:3),
          Text(value,style:const TextStyle(fontSize:16.5,
            fontWeight:FontWeight.w800,color:Color(0xff153e69))),
        ]),
      ),
    );
    return Row(children:[
      metric(Icons.scale_outlined,'Total Kg',
        CikokoBankSampahApi2610.kilos(data['weight_kg'])+' Kg'),
      const SizedBox(width:9),
      metric(Icons.monetization_on_outlined,'Total Rupiah',
        'Rp '+CikokoBankSampahApi2610.money(data['amount_rp'])),
    ]);
  }

  Widget sessionPanel() {
    final sessions=records(dashboard,'sessions');
    final session=selectedSession['session'] is Map
        ?Map<String,dynamic>.from(selectedSession['session'] as Map)
        :<String,dynamic>{};
    final entries=records(selectedSession,'items');
    final users=records(members,'items');
    return Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      if(canManage)
        Card(
          margin:const EdgeInsets.only(bottom:12),
          child:Padding(padding:const EdgeInsets.all(13),child:
            Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
              const Row(children:[
                Icon(Icons.settings_suggest_outlined,color:Color(0xff12548b)),
                SizedBox(width:8),
                Text('Pengaturan Jadwal Penimbangan',
                  style:TextStyle(fontSize:13.5,fontWeight:FontWeight.w800)),
              ]),
              const SizedBox(height:6),
              const Text('Jadwal awal Minggu ke-2 dan ke-4. '
                'Admin dapat memilih pola kegiatan.',
                style:TextStyle(fontSize:11,color:Colors.blueGrey)),
              const SizedBox(height:9),
              DropdownButtonFormField<String>(
                key:ValueKey('bank_cadence_'+
                    (dashboard['cadence']??'twice_monthly').toString()),
                initialValue:(dashboard['cadence']??'twice_monthly').toString(),
                isExpanded:true,
                decoration:const InputDecoration(
                  labelText:'Pola Penimbangan',border:OutlineInputBorder()),
                items:const [
                  DropdownMenuItem(value:'twice_monthly',
                    child:Text('Minggu ke-2 dan ke-4 (2x sebulan)')),
                  DropdownMenuItem(value:'every_two_months',
                    child:Text('Sekali setiap 2 bulan')),
                ],
                onChanged:(v){if(v!=null)setCadence(v);},
              ),
              const SizedBox(height:9),
              OutlinedButton.icon(onPressed:createSession,
                icon:const Icon(Icons.calendar_month_outlined),
                label:const Text('Buat Tanggal Penimbangan')),
            ]),
          ),
        ),
      if(sessions.isEmpty)
        const Card(child:ListTile(
          leading:Icon(Icons.event_busy_outlined),
          title:Text('Belum ada sesi penimbangan'),
          subtitle:Text('Super Admin membuat tanggal sebelum petugas mengisi data.'))),
      if(session.isNotEmpty)
        CikokoBankSampahMockup2613(
          key:ValueKey('bank_form_mockup_2613_'+(sessionId??0).toString()),
          session:session,
          entries:entries,
          members:users,
          availableSessions:sessions,
          onSelectSession:changeSession,
          officerName:(widget.api.profile?['name']??'Petugas Bank Sampah').toString(),
          canInput:canInput,
          canManage:canManage,
          request:(action,body)=>CikokoBankSampahApi2610.call(
            widget.api,action,body:body),
          reload:refresh,
          notify:message,
        ),
    ]);
  }

  Widget membersPanel() {
    final users = records(members, 'items');
    if (!canManage) return const SizedBox.shrink();
    final officers = users.where((u) => u['is_officer'] == true).length;
    return ExpansionTile(
      title: const Text('Kelola Anggota dan Petugas Bank Sampah'),
      subtitle: Text('Petugas aktif: ' + officers.toString() +
        '/5. Pilih 4–5 petugas dari PJLP atau PPPK. Semua PJLP/PPPK bisa menjadi anggota.'),
      children: [
        const Padding(padding: EdgeInsets.all(12), child: Text(
          'Menghapus keanggotaan hanya menonaktifkan daftar Bank Sampah. '
          'Akun pegawai dan hasil timbang sebelumnya tetap tersimpan.')),
        for (final u in users) Column(children: [
          SwitchListTile(
            dense: true,
            title: Text(u['name'].toString()),
            subtitle: Text(u['role'].toString().toUpperCase() + ' · Anggota'),
            value: u['is_member'] == true,
            onChanged: (v) => act('member_set',
              {'user_id': u['id'], 'active': v}),
          ),
          if (u['role'] == 'pjlp' || u['role'] == 'pppk') SwitchListTile(
            dense: true,
            contentPadding: const EdgeInsets.only(left: 34, right: 16),
            title: const Text('Petugas Bank Sampah (ditunjuk Admin)'),
            value: u['is_officer'] == true,
            onChanged: (v) => act('officer_set',
              {'user_id': u['id'], 'active': v}),
          ),
          const Divider(height: 1),
        ]),
      ],
    );
  }

  Future<void> copyAnnual() async {
    final entries = records(annual, 'items');
    String sanitize(Object? input) =>
        (input ?? '').toString().replaceAll('\n', ' ').replaceAll('\t', ' ');
    final lines = <String>[
      'Tanggal\tNama\tNama Barang\tHasil Timbangan (Kg)\tJumlah Rupiah',
      for (final r in entries)
        [
          r['session_date'],r['member_name'],r['item_name'],
          r['weight_kg'],r['amount_rp']
        ].map(sanitize).join('\t'),
    ];
    await Clipboard.setData(ClipboardData(text: lines.join('\n')));
    message('Rekap ' + year.toString() + ' disalin. Tempel ke Excel.');
  }

  Widget annualPanel() {
    final months = records(annual, 'months');
    final membersRows = records(annual, 'members');
    return ExpansionTile(
      initiallyExpanded: true,
      title: Text('Rekap Tahunan · ' + year.toString()),
      subtitle: const Text('Total, per bulan, dan per pegawai'),
      childrenPadding: const EdgeInsets.all(8),
      children: [
        totalsCard(annual, 'Total Tahunan Bank Sampah Cikoko'),
        OutlinedButton.icon(
          onPressed: copyAnnual,
          icon: const Icon(Icons.copy_all_outlined),
          label: const Text('Salin tabel tahunan ke Excel')),
        const Text('Rekap per bulan', style: TextStyle(fontWeight: FontWeight.bold)),
        if (months.isEmpty) const ListTile(title: Text('Belum ada data tahun ini.')),
        for (final m in months) ListTile(
          dense: true,
          title: Text(m['month'].toString()),
          trailing: Text(CikokoBankSampahApi2610.heading(
            Map<String, dynamic>.from(m['totals'] as Map))),
        ),
        const Divider(),
        const Text('Rekap per anggota', style: TextStyle(fontWeight: FontWeight.bold)),
        for (final u in membersRows) ListTile(
          dense: true,
          title: Text(u['member_name'].toString() + ' (' +
            u['role'].toString().toUpperCase() + ')'),
          subtitle: Text(CikokoBankSampahApi2610.heading(
            Map<String, dynamic>.from(u['totals'] as Map))),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = (widget.api.profile?['role'] ?? '').toString();
    if (!CikokoBankSampahApi2610.supportedRoles.contains(role)) {
      return const Center(child: Text('Bank Sampah hanya untuk pegawai dan Admin.'));
    }
    return RefreshIndicator(
      onRefresh: refresh,
      child: ListView(padding: const EdgeInsets.all(12), children: [
        const Text('BANK SAMPAH CIKOKO',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
        const Text('Kelurahan Cikoko · Penimbangan berkala dan rekap tahunan',
          style: TextStyle(color: Colors.blueGrey)),
        yearChooser(),
        if (loading) const LinearProgressIndicator(),
        if (error.isNotEmpty) Card(child: ListTile(
          title: const Text('Data belum dapat dimuat'),
          subtitle: Text(error),
          trailing: IconButton(onPressed: refresh, icon: const Icon(Icons.refresh)))),
        if (!loading && error.isEmpty) ...[
          if (!canSeeAll) mySummary(),
          if (canSeeAll) ...[
            if (canInput) const Card(child: Padding(padding: EdgeInsets.all(12),
              child: Text('Petugas PJLP/PPPK: isikan jenis barang dan hasil timbang. '
                'Rupiah dapat diperbarui pada baris yang masih terbuka.'))),
            if (!canInput && !canManage) const Card(child: Padding(
              padding: EdgeInsets.all(12),
              child: Text('Halaman monitoring Bank Sampah. ASN/Lurah hanya dapat melihat laporan, bukan mengubah data.'))),
            membersPanel(),
            sessionPanel(),
            const SizedBox(height: 14),
            annualPanel(),
          ],
        ],
        const SizedBox(height: 40),
      ]),
    );
  }
}
