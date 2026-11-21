import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Native, editable Cikoko Bank Sampah form, based on the approved visual
/// mockup. The underlying Bank Sampah 2610 API and its permissions are intact.
class CikokoBankSampahMockup2613 extends StatefulWidget {
  final Map<String,dynamic> session;
  final List<Map<String,dynamic>> entries;
  final List<Map<String,dynamic>> members;
  final String officerName;
  final bool canInput;
  final bool canManage;
  final Future<Map<String,dynamic>> Function(String,Map<String,dynamic>) request;
  final Future<void> Function() reload;
  final ValueChanged<String> notify;

  const CikokoBankSampahMockup2613({
    super.key,required this.session,required this.entries,
    required this.members,required this.officerName,
    required this.canInput,required this.canManage,
    required this.request,required this.reload,required this.notify,
  });

  @override
  State<CikokoBankSampahMockup2613> createState() =>
    _CikokoBankSampahMockup2613State();
}

class _WasteEntry2613 {
  int? id;
  String memberId;
  final String memberName;
  final TextEditingController item;
  final TextEditingController kg;
  final TextEditingController rupiah;
  bool dirty;
  _WasteEntry2613({
    this.id,required this.memberId,required this.memberName,
    required String itemName,required String weight,required String amount,
    this.dirty=false,
  }) : item=TextEditingController(text:itemName),
       kg=TextEditingController(text:weight),
       rupiah=TextEditingController(text:amount);
  void dispose(){item.dispose();kg.dispose();rupiah.dispose();}
}

class _CikokoBankSampahMockup2613State extends State<CikokoBankSampahMockup2613> {
  static const navy=Color(0xff084982);
  static const deepBlue=Color(0xff0d3665);
  static const green=Color(0xff188b47);
  static const blueTint=Color(0xffeaf3ff);
  static const border=Color(0xffc9d9ed);
  static const textMuted=Color(0xff54667d);
  static const items=['Kardus','Botol Plastik','Besi','Kertas',
    'Kaleng','Plastik','Koran','Aluminium','Lainnya'];
  final List<_WasteEntry2613> rows=[];
  bool busy=false;
  String lastSignature='';

  bool get editable => widget.canInput && widget.session['status']=='open';
  bool get submitted => widget.session['status']=='submitted';
  int get sessionId=>int.tryParse((widget.session['id']??'0').toString())??0;

  List<Map<String,dynamic>> get eligibleMembers=>widget.members.where((m)=>
    m['active']==true && m['is_member']==true
  ).toList();

  @override
  void initState(){super.initState();_hydrate();}
  @override
  void didUpdateWidget(covariant CikokoBankSampahMockup2613 old){
    super.didUpdateWidget(old);
    final sig=jsonEncode(widget.entries);
    if((old.session['id']??'').toString()!=(widget.session['id']??'').toString()
        ||(sig!=lastSignature && !rows.any((r)=>r.dirty))){
      _hydrate();
    }
  }
  void _hydrate(){
    for(final r in rows)r.dispose();
    rows.clear();
    for(final e in widget.entries){
      rows.add(_WasteEntry2613(
        id:int.tryParse((e['id']??'').toString()),
        memberId:(e['member_user_id']??'').toString(),
        memberName:(e['member_name']??'').toString(),
        itemName:(e['item_name']??'').toString(),
        weight:(e['weight_kg']??'').toString(),
        amount:_money(e['amount_rp']),
      ));
    }
    lastSignature=jsonEncode(widget.entries);
  }
  @override
  void dispose(){
    for(final row in rows)row.dispose();
    super.dispose();
  }

  static String _money(Object? value){
    final s=(int.tryParse((value??'0').toString())??0).toString();
    return s.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'),(m)=>'.');
  }
  static String _kg(Object? value){
    final n=double.tryParse((value??'0').toString())??0;
    return n.toStringAsFixed(3).replaceFirst(RegExp(r'\.?0+$'),'');
  }
  static String _tanggal(String iso){
    final d=DateTime.tryParse(iso);
    if(d==null)return iso;
    const months=['','Januari','Februari','Maret','April','Mei','Juni',
      'Juli','Agustus','September','Oktober','November','Desember'];
    return d.day.toString()+' '+months[d.month]+' '+d.year.toString();
  }
  static int _amountValue(String value){
    return int.tryParse(value.replaceAll(RegExp(r'[^0-9]'),''))??0;
  }
  void _modified(_WasteEntry2613 row)=>setState(()=>row.dirty=true);

  double get totalKg=>rows.fold(0,(n,r)=>n+(
    double.tryParse(r.kg.text.trim().replaceAll(',','.'))??0));
  int get totalRp=>rows.fold(0,(n,r)=>n+_amountValue(r.rupiah.text));

  void _addRow(){
    final list=eligibleMembers;
    if(list.isEmpty){
      widget.notify('Super Admin perlu mengaktifkan anggota PJLP/PPPK dahulu.');
      return;
    }
    setState(()=>rows.add(_WasteEntry2613(
      memberId:list.first['id'].toString(),
      memberName:list.first['name'].toString(),
      itemName:'',weight:'',amount:'0',dirty:true,
    )));
  }

  String? _validate(_WasteEntry2613 row){
    if(!eligibleMembers.any((m)=>m['id'].toString()==row.memberId)){
      return 'Pilih anggota PJLP/PPPK yang masih aktif.';
    }
    final itemName=row.item.text.trim();
    if(itemName.length<2||itemName.length>140)return 'Isi nama barang (minimal 2 huruf).';
    final kg=row.kg.text.trim().replaceAll(',','.');
    if(!RegExp(r'^\d{1,5}(?:\.\d{1,3})?$').hasMatch(kg)||
       (double.tryParse(kg)??0)<=0||(double.tryParse(kg)??0)>10000){
      return 'Hasil timbang harus angka Kg positif, maksimal 3 desimal.';
    }
    final amountRaw=row.rupiah.text.trim();
    if(!RegExp(r'^[0-9.]+$').hasMatch(amountRaw)||
       _amountValue(amountRaw)>100000000000){
      return 'Jumlah Rupiah harus angka positif atau nol.';
    }
    return null;
  }

  Future<bool> _saveDraft({bool announce=true}) async {
    if(busy)return false;
    if(!editable){widget.notify('Sesi tidak terbuka untuk diubah.');return false;}
    if(rows.isEmpty){widget.notify('Tambahkan baris hasil timbang terlebih dahulu.');return false;}
    for(var i=0;i<rows.length;i++){
      final err=_validate(rows[i]);
      if(err!=null){widget.notify('Baris '+(i+1).toString()+': '+err);return false;}
    }
    setState(()=>busy=true);
    var saved=0;
    try{
      for(final row in rows){
        if(row.id!=null&&!row.dirty)continue;
        final payload=<String,dynamic>{
          if(row.id!=null)'id':row.id,
          'session_id':sessionId,
          'member_user_id':row.memberId,
          'item_name':row.item.text.trim(),
          'weight_kg':row.kg.text.trim().replaceAll(',','.'),
          'amount_rp':_amountValue(row.rupiah.text),
        };
        final response=await widget.request('entry_save',payload);
        row.id=int.tryParse((response['id']??'').toString())??row.id;
        row.dirty=false;
        saved++;
      }
      if(!mounted)return false;
      if(announce)widget.notify('Draft tersimpan: '+rows.length.toString()+
        ' baris ('+saved.toString()+' perubahan).');
      return true;
    }catch(e){
      if(mounted)widget.notify('Sebagian data mungkin tersimpan. Periksa draft: '+e.toString());
      return false;
    }finally{
      if(mounted)setState(()=>busy=false);
    }
  }

  Future<void> _draft(){
    final ok=await _saveDraft();
    if(ok&&mounted)await widget.reload();
  }
  Future<void> _submit(){
    if(busy||!editable)return;
    if(rows.isEmpty){widget.notify('Isi minimal satu baris penimbangan.');return;}
    final confirmed=await showDialog<bool>(
      context:context,builder:(ctx)=>AlertDialog(
        title:const Text('Simpan Penimbangan?'),
        content:const Text('Semua baris akan disimpan dan dikirim untuk '
          'pengesahan Super Admin. Petugas tidak dapat mengubahnya '
          'sampai sesi dibuka kembali.'),
        actions:[
          TextButton(onPressed:()=>Navigator.pop(ctx,false),
            child:const Text('Batal')),
          FilledButton(onPressed:()=>Navigator.pop(ctx,true),
            child:const Text('Ya, Simpan Penimbangan')),
        ],
      ));
    if(confirmed!=true||!mounted)return;
    final saved=await _saveDraft(announce:false);
    if(!saved||!mounted)return;
    setState(()=>busy=true);
    try{
      await widget.request('session_submit',{'session_id':sessionId});
      if(!mounted)return;
      widget.notify('Penimbangan berhasil dikirim untuk pengesahan Admin.');
      await widget.reload();
    }catch(e){
      if(mounted)widget.notify('Gagal mengirim penimbangan: '+e.toString());
    }finally{
      if(mounted)setState(()=>busy=false);
    }
  }

  Future<void> _status(String next) async {
    if(busy||!widget.canManage)return;
    setState(()=>busy=true);
    try{
      await widget.request('session_status',
        {'session_id':sessionId,'status':next});
      if(mounted){
        widget.notify(next=='closed'
          ?'Penimbangan telah disahkan.'
          :'Sesi dibuka kembali untuk koreksi.');
        await widget.reload();
      }
    }catch(e){if(mounted)widget.notify('Gagal mengubah status: '+e.toString());}
    finally{if(mounted)setState(()=>busy=false);}
  }

  BoxDecoration _cardDecoration({Color? fill})=>BoxDecoration(
    color:fill??Colors.white,borderRadius:BorderRadius.circular(18),
    border:Border.all(color:border,width:1),
    boxShadow:[BoxShadow(color:navy.withValues(alpha:0.055),
      blurRadius:12,offset:const Offset(0,3))]);

  Widget _banner(String title,IconData icon)=>Container(
    padding:const EdgeInsets.symmetric(horizontal:13,vertical:12),
    decoration:const BoxDecoration(
      color:blueTint,borderRadius:BorderRadius.vertical(top:Radius.circular(17))),
    child:Row(children:[
      Icon(icon,color:navy,size:24),const SizedBox(width:10),
      Expanded(child:Text(title,style:const TextStyle(
        color:deepBlue,fontWeight:FontWeight.w800,fontSize:15))),
    ]),
  );

  Widget _dataPenimbangan(){
    final status=(widget.session['status']??'open').toString();
    Widget line(String label,Widget value)=>Padding(
      padding:const EdgeInsets.symmetric(horizontal:15,vertical:7),
      child:Row(crossAxisAlignment:CrossAxisAlignment.center,children:[
        SizedBox(width:71,child:Text(label,
          style:const TextStyle(color:Color(0xff354b63),fontSize:12))),
        const Text(':',style:TextStyle(color:textMuted)),
        const SizedBox(width:12),
        Expanded(child:value),
      ]),
    );
    return Container(
      decoration:_cardDecoration(),
      child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
        _banner('Data Penimbangan',Icons.event_note_outlined),
        const SizedBox(height:7),
        line('Hari',const Text('Minggu',style:TextStyle(
          fontWeight:FontWeight.w800,color:deepBlue))),
        line('Tanggal',Container(
          padding:const EdgeInsets.symmetric(horizontal:10,vertical:10),
          decoration:BoxDecoration(border:Border.all(color:border),
            borderRadius:BorderRadius.circular(8)),
          child:Row(children:[
            const Icon(Icons.calendar_month_outlined,color:navy,size:18),
            const SizedBox(width:8),
            Expanded(child:Text(_tanggal(widget.session['session_date'].toString()),
              style:const TextStyle(fontSize:12,fontWeight:FontWeight.w600))),
            const Icon(Icons.check_circle_outline,size:16,color:green),
          ]),
        )),
        line('Petugas',Container(
          padding:const EdgeInsets.symmetric(horizontal:10,vertical:10),
          decoration:BoxDecoration(border:Border.all(color:border),
            borderRadius:BorderRadius.circular(8)),
          child:Row(children:[
            const Icon(Icons.person_outline,color:navy,size:18),
            const SizedBox(width:8),
            Expanded(child:Text(widget.officerName.isEmpty?
              'Petugas Bank Sampah PJLP/PPPK':widget.officerName,
              overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:12))),
          ]),
        )),
        Padding(padding:const EdgeInsets.fromLTRB(15,5,15,12),
          child:Align(alignment:Alignment.centerRight,
            child:Container(
              padding:const EdgeInsets.symmetric(horizontal:10,vertical:5),
              decoration:BoxDecoration(
                color:status=='closed'?const Color(0xffe2f5e8):
                status=='submitted'?const Color(0xfffff2d8):blueTint,
                borderRadius:BorderRadius.circular(20)),
              child:Text(status=='closed'?'Disahkan Admin':
                status=='submitted'?'Menunggu Pengesahan':'Draft / Sedang Diisi',
                style:TextStyle(fontSize:11,fontWeight:FontWeight.w700,
                  color:status=='closed'?green:
                    status=='submitted'?const Color(0xff9a650a):navy)),
            ),
          )),
      ]),
    );
  }

  Widget _metric(IconData icon,String label,String value){
    return Expanded(child:Container(
      padding:const EdgeInsets.symmetric(horizontal:12,vertical:13),
      decoration:BoxDecoration(
        gradient:const LinearGradient(colors:[Color(0xffedf9ef),Color(0xffe7f5ec)]),
        borderRadius:BorderRadius.circular(15)),
      child:Row(children:[
        Icon(icon,color:green,size:28),
        const SizedBox(width:8),
        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(label,style:const TextStyle(color:deepBlue,fontSize:11)),
          const SizedBox(height:3),
          Text(value,maxLines:1,overflow:TextOverflow.ellipsis,
            style:const TextStyle(color:deepBlue,fontSize:16.5,
              fontWeight:FontWeight.w900)),
        ])),
      ]),
    ));
  }

  Widget _textField(TextEditingController controller,String hint,
      {TextInputType? keyboard,Widget? suffix,ValueChanged<String>? changed}){
    return TextField(
      controller:controller,
      readOnly:!editable||busy,
      keyboardType:keyboard,
      style:const TextStyle(fontSize:11.5,color:Color(0xff243954)),
      maxLines:1,
      onChanged:changed,
      decoration:InputDecoration(
        isDense:true,
        hintText:hint,hintStyle:const TextStyle(fontSize:10,color:Colors.blueGrey),
        filled:true,fillColor:Colors.white,
        contentPadding:const EdgeInsets.symmetric(horizontal:7,vertical:12),
        suffixIcon:suffix,
        suffixIconConstraints:const BoxConstraints(minWidth:22,minHeight:28),
        enabledBorder:OutlineInputBorder(
          borderRadius:BorderRadius.circular(7),
          borderSide:const BorderSide(color:Color(0xffc6d2df))),
        focusedBorder:OutlineInputBorder(
          borderRadius:BorderRadius.circular(7),
          borderSide:const BorderSide(color:navy,width:1.5)),
      ),
    );
  }

  Widget _memberCell(_WasteEntry2613 row){
    final eligible=eligibleMembers;
    final exists=eligible.any((m)=>m['id'].toString()==row.memberId);
    if(!editable||row.id!=null||!exists){
      final names=widget.members.where((m)=>m['id'].toString()==row.memberId);
      final label=names.isNotEmpty?names.first['name'].toString():row.memberName;
      return Tooltip(message:label,child:Text(label,
        maxLines:2,overflow:TextOverflow.ellipsis,
        style:const TextStyle(fontSize:10.5,fontWeight:FontWeight.w700)));
    }
    return DropdownButtonHideUnderline(child:DropdownButton<String>(
      value:row.memberId,isExpanded:true,
      isDense:true,iconSize:14,
      style:const TextStyle(color:deepBlue,fontSize:10.5,
        fontWeight:FontWeight.w700),
      items:eligible.map((m)=>DropdownMenuItem<String>(
        value:m['id'].toString(),
        child:Text(m['name'].toString(),maxLines:2,
          overflow:TextOverflow.ellipsis),
      )).toList(),
      onChanged:busy?null:(s){
        if(s==null)return;
        setState((){row.memberId=s;row.dirty=true;});
      },
    ));
  }

  Widget _tableCell(Widget child,double width)=>SizedBox(
    width:width,child:Padding(padding:const EdgeInsets.symmetric(
      horizontal:3,vertical:6),child:child));

  Widget _editableTable(){
    const numberWidth=37.0,nameWidth=116.0,itemWidth=105.0;
    const kgWidth=68.0,rpWidth=92.0;
    const fullWidth=numberWidth+nameWidth+itemWidth+kgWidth+rpWidth;
    const columns=['No','Nama Anggota','Nama Barang','Hasil Timbangan (Kg)','Jumlah (Rp)'];
    final widths=[numberWidth,nameWidth,itemWidth,kgWidth,rpWidth];
    final entries=rows;
    return Container(
      decoration:_cardDecoration(),clipBehavior:Clip.hardEdge,
      child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
        _banner('Daftar Penimbangan Bank Sampah',Icons.table_rows_outlined),
        SingleChildScrollView(
          key:const Key('bank_sampah_table_scroll_2613'),
          scrollDirection:Axis.horizontal,
          child:SizedBox(width:fullWidth,child:Column(children:[
            Container(
              decoration:const BoxDecoration(
                color:navy,borderRadius:BorderRadius.circular(7)),
              child:Row(children:[
                for(var i=0;i<columns.length;i++)
                  SizedBox(width:widths[i],child:Padding(
                    padding:const EdgeInsets.symmetric(horizontal:3,vertical:10),
                    child:Text(columns[i],textAlign:TextAlign.center,
                      style:const TextStyle(color:Colors.white,
                        fontSize:10.1,fontWeight:FontWeight.w800)))),
              ]),
            ),
            for(var i=0;i<entries.length;i++)
              DecoratedBox(
                decoration:BoxDecoration(color:i.isEven?Colors.white:const Color(0xfff8fafc),
                  border:const Border(bottom:BorderSide(color:Color(0xffe5eaf0)))),
                child:Row(children:[
                  _tableCell(
                    GestureDetector(
                      onLongPress:entries[i].id==null&&editable?(){
                        setState((){
                          final removed=rows.removeAt(i);
                          removed.dispose();
                        });
                      }:null,
                      child:Container(
                        padding:const EdgeInsets.symmetric(vertical:12),
                        decoration:BoxDecoration(
                          color:const Color(0xffeef1f4),
                          borderRadius:BorderRadius.circular(8)),
                        child:Text((i+1).toString(),
                          textAlign:TextAlign.center,
                          style:const TextStyle(fontSize:11,fontWeight:FontWeight.w800))),
                    ),numberWidth),
                  _tableCell(_memberCell(entries[i]),nameWidth),
                  _tableCell(_textField(entries[i].item,'Barang',
                    changed:(_)=>_modified(entries[i]),
                    suffix:editable?PopupMenuButton<String>(
                      tooltip:'Pilih nama barang',
                      padding:EdgeInsets.zero,
                      icon:const Icon(Icons.expand_more,size:15),
                      onSelected:(s){
                        if(s=='Lainnya')return;
                        entries[i].item.text=s;_modified(entries[i]);
                      },
                      itemBuilder:(_)=>[
                        for(final item in items)
                          PopupMenuItem(value:item,child:Text(item)),
                      ],
                    ):null),itemWidth),
                  _tableCell(_textField(entries[i].kg,'0.0',
                    keyboard:const TextInputType.numberWithOptions(decimal:true),
                    changed:(_)=>_modified(entries[i])),kgWidth),
                  _tableCell(_textField(entries[i].rupiah,'0',
                    keyboard:TextInputType.number,
                    changed:(_)=>_modified(entries[i])),rpWidth),
                ]),
              ),
            if(entries.isEmpty)const Padding(padding:EdgeInsets.all(17),
              child:Text('Belum ada penimbangan. Tambahkan baris untuk mulai.',
                style:TextStyle(color:Colors.blueGrey,fontSize:12))),
          ])),
        ),
        const Padding(padding:EdgeInsets.fromLTRB(10,5,10,9),
          child:Text('Geser tabel ke samping jika diperlukan. Ketuk nama barang untuk memilih jenis.',
            style:TextStyle(fontSize:10,color:Colors.blueGrey))),
      ]),
    );
  }

  @override
  Widget build(BuildContext context){
    final isOpen=widget.session['status']=='open';
    final amount=_money(totalRp);
    return Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      Container(
        decoration:BoxDecoration(
          gradient:const LinearGradient(colors:[Color(0xff05376b),Color(0xff0963a4)]),
          borderRadius:BorderRadius.circular(17)),
        padding:const EdgeInsets.symmetric(horizontal:14,vertical:14),
        child:const Row(children:[
          Icon(Icons.account_balance,color:Colors.white,size:28),
          SizedBox(width:10),
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text('Cikoko Smart',style:TextStyle(
              fontSize:18,fontWeight:FontWeight.w900,color:Colors.white)),
            Text('Kelurahan Cikoko',style:TextStyle(
              fontSize:11.5,color:Color(0xffdcecff))),
          ])),
          Icon(Icons.eco_outlined,color:Color(0xff9bde9d),size:34),
        ]),
      ),
      const SizedBox(height:12),
      Row(children:[
        const Icon(Icons.recycling,color:green,size:40),
        const SizedBox(width:8),
        Container(width:3,height:40,color:deepBlue),
        const SizedBox(width:10),
        const Expanded(child:Column(
          crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text('Input Bank Sampah',style:TextStyle(
              color:deepBlue,fontSize:20,fontWeight:FontWeight.w900)),
            Text('Kelurahan Cikoko',style:TextStyle(
              color:Color(0xff444b52),fontSize:12.5)),
          ]),
        )),
      ]),
      const SizedBox(height:12),
      _dataPenimbangan(),
      const SizedBox(height:12),
      Row(children:[
        _metric(Icons.scale_outlined,'Total Kg',_kg(totalKg)+' Kg'),
        const SizedBox(width:10),
        _metric(Icons.savings_outlined,'Total Rupiah','Rp '+amount),
      ]),
      const SizedBox(height:13),
      _editableTable(),
      if(editable)...[
        const SizedBox(height:12),
        SizedBox(height:46,child:OutlinedButton.icon(
          key:const Key('bank_sampah_add_row_2613'),
          onPressed:busy?null:_addRow,
          icon:const Icon(Icons.add,size:22),
          label:const Text('Tambah Baris'),
          style:OutlinedButton.styleFrom(
            foregroundColor:navy,side:const BorderSide(color:navy,width:1.7),
            shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(12))),
        )),
        const SizedBox(height:10),
        Row(children:[
          Expanded(child:SizedBox(height:46,child:OutlinedButton.icon(
            key:const Key('bank_sampah_save_draft_2613'),
            onPressed:busy?null:_draft,
            icon:const Icon(Icons.save_outlined,size:18),
            label:const Text('Simpan Draft',style:TextStyle(fontSize:11.5)),
            style:OutlinedButton.styleFrom(
              foregroundColor:navy,side:const BorderSide(color:navy,width:1.5),
              padding:const EdgeInsets.symmetric(horizontal:4),
              shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(12))),
          ))),
          const SizedBox(width:8),
          Expanded(child:SizedBox(height:46,child:FilledButton.icon(
            key:const Key('bank_sampah_submit_2613'),
            onPressed:busy?null:_submit,
            icon:const Icon(Icons.check_circle_outline,size:17),
            label:const Text('Simpan Penimbangan',
              style:TextStyle(fontSize:10.8)),
            style:FilledButton.styleFrom(backgroundColor:navy,
              padding:const EdgeInsets.symmetric(horizontal:4),
              shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(12))),
          ))),
        ]),
      ],
      if(submitted)
        const Padding(padding:EdgeInsets.only(top:12),
          child:Card(child:ListTile(
            leading:Icon(Icons.hourglass_top,color:Color(0xffca8b16)),
            title:Text('Menunggu pengesahan Super Admin'),
            subtitle:Text('Data terkunci sementara dan belum menjadi laporan final.')))),
      if(widget.canManage)...[
        const SizedBox(height:10),
        if(widget.session['status']!='closed')
          FilledButton.icon(
            onPressed:busy?null:()=>_status('closed'),
            icon:const Icon(Icons.verified_outlined),
            label:const Text('Sahkan Penimbangan')),
        if(!isOpen)
          OutlinedButton.icon(onPressed:busy?null:()=>_status('open'),
            icon:const Icon(Icons.lock_open_outlined),
            label:const Text('Buka Kembali untuk Koreksi')),
      ],
      const SizedBox(height:14),
      Container(
        padding:const EdgeInsets.all(12),
        decoration:BoxDecoration(color:blueTint,
          borderRadius:BorderRadius.circular(12)),
        child:const Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Icon(Icons.info_outline,color:navy),
          SizedBox(width:9),
          Expanded(child:Text(
            '• Hanya petugas Bank Sampah PJLP/PPPK yang ditunjuk Admin dapat mengisi data.\n'
            '• Data anggota berasal dari daftar PJLP dan PPPK aktif.\n'
            '• Draft dapat diperbarui; hasil final memerlukan pengesahan Admin.',
            style:TextStyle(color:Color(0xff274263),fontSize:11.4,height:1.55))),
        ]),
      ),
      const SizedBox(height:10),
    ]);
  }
}
