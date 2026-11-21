import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'api.dart';
import 'cikoko_jumantik_2605.dart';
import 'cikoko_jumantik_mandiri_2607.dart';

/// Activity cards only use Super Admin-published Jumantik and aggregated
/// closed Bank Sampah sessions. No citizen name, phone, address or draft.
class CikokoActivityUpdates2614 extends StatefulWidget {
  final String role;
  final ValueChanged<String> navigate;
  final Future<Map<String,dynamic>> Function()? fetcher;
  const CikokoActivityUpdates2614({
    super.key,required this.role,required this.navigate,this.fetcher,
  });
  @override
  State<CikokoActivityUpdates2614> createState()=>
      _CikokoActivityUpdates2614State();

  static Future<Map<String,dynamic>> fetchPublished() async {
    Future<Map<String,dynamic>> safe(Future<Map<String,dynamic>> task) async {
      try{return await task;}
      catch(_){return {'ok':false,'items':<dynamic>[]};}
    }
    Future<Map<String,dynamic>> bank() async {
      try {
        final uri=Uri.parse(CikokoApi.root.replaceFirst(
          'index.php','bank_sampah_2610.php'))
            .replace(queryParameters:const {'action':'public_activity'});
        final res=await http.get(uri,headers:const {'Accept':'application/json'})
          .timeout(const Duration(seconds:15));
        if(res.statusCode!=200)throw const FormatException('Bank Sampah API');
        final data=jsonDecode(utf8.decode(res.bodyBytes));
        if(data is! Map<String,dynamic>||data['ok']!=true){
          throw const FormatException('Bank Sampah response');
        }
        return data;
      }catch(_){return {'ok':false,'items':<dynamic>[]};}
    }
    final feeds=await Future.wait<Map<String,dynamic>>([
      safe(Jumantik2605Api.news()),
      safe(CikokoJumantikMandiri2607.news()),
      bank(),
    ]);
    return {'rt':feeds[0],'mandiri':feeds[1],'bank':feeds[2]};
  }
}

class _CikokoActivityUpdates2614State extends State<CikokoActivityUpdates2614> {
  static const ink=Color(0xff112e53);
  static const blue=Color(0xff146ad1);
  static const green=Color(0xff158347);
  late Future<Map<String,dynamic>> future;
  @override void initState(){super.initState();_reset();}
  void _reset(){future=widget.fetcher?.call() ??
    CikokoActivityUpdates2614.fetchPublished();}
  @override void didUpdateWidget(covariant CikokoActivityUpdates2614 old){
    super.didUpdateWidget(old);
    if(old.role!=widget.role||old.fetcher!=widget.fetcher)_reset();
  }
  Future<void> _refresh() async {setState(_reset);await future;}
  List<Map<String,dynamic>> rows(dynamic block){
    if(block is! Map)return [];
    final src=block['items'];
    if(src is! List)return [];
    return src.whereType<Map>().map((e)=>Map<String,dynamic>.from(e)).toList();
  }
  Widget _heading(String title,IconData icon,VoidCallback? action)=>Padding(
    padding:const EdgeInsets.fromLTRB(0,11,0,8),
    child:Row(children:[
      Icon(icon,color:green,size:19),const SizedBox(width:7),
      Expanded(child:Text(title,style:const TextStyle(
        color:ink,fontSize:14.8,fontWeight:FontWeight.w900))),
      if(action!=null)TextButton(
        onPressed:action,
        child:const Text('Lihat semua',style:TextStyle(fontSize:11))),
    ]),
  );
  Widget _activity({
    required String title,required String subtitle,required String date,
    required IconData icon,required VoidCallback? onTap,
  })=>Card(
    elevation:0,margin:const EdgeInsets.only(bottom:7),
    color:Colors.white,
    shape:RoundedRectangleBorder(
      side:const BorderSide(color:Color(0xffe0e9f2)),
      borderRadius:BorderRadius.circular(13)),
    child:InkWell(
      onTap:onTap,borderRadius:BorderRadius.circular(13),
      child:Padding(padding:const EdgeInsets.all(10),
        child:Row(children:[
          Container(width:40,height:40,
            decoration:BoxDecoration(color:const Color(0xffeaf5f0),
              borderRadius:BorderRadius.circular(10)),
            child:Icon(icon,color:green,size:22)),
          const SizedBox(width:10),
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,
            children:[
              Text(title,maxLines:1,overflow:TextOverflow.ellipsis,
                style:const TextStyle(color:ink,fontSize:12.3,
                  fontWeight:FontWeight.w800)),
              const SizedBox(height:3),
              Text(subtitle,maxLines:2,overflow:TextOverflow.ellipsis,
                style:const TextStyle(color:Color(0xff62748a),fontSize:10.6)),
              if(date.isNotEmpty)Padding(
                padding:const EdgeInsets.only(top:3),
                child:Text(cikokoDateOnly(date),
                  style:const TextStyle(fontSize:10,color:blue))),
            ])),
          if(onTap!=null)const Icon(Icons.chevron_right,color:blue,size:18),
        ]),
      ),
    ),
  );
  @override Widget build(BuildContext context){
    final bankAccessible=const <String>[
      'admin','admin_kelurahan','asn','lurah','pjlp','pppk',
    ].contains(widget.role);
    return FutureBuilder<Map<String,dynamic>>(
      future:future,builder:(context,snapshot){
        final data=snapshot.data;
        final rt=rows(data?['rt']);
        final mandiri=rows(data?['mandiri']);
        final bank=rows(data?['bank']);
        final jumantik=[
          ...rt.map((e)=>{...e,'_source':'rt'}),
          ...mandiri.map((e)=>{...e,'_source':'mandiri'}),
        ]..sort((a,b){
          final da=(a['_source']=='rt'?a['tanggal']:a['waktu']??'').toString();
          final db=(b['_source']=='rt'?b['tanggal']:b['waktu']??'').toString();
          return db.compareTo(da);
        });
        return Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
          Row(children:[
            const Expanded(child:Text('Update Kegiatan Terbaru',
              style:TextStyle(fontWeight:FontWeight.w900,color:ink,fontSize:16))),
            IconButton(
              key:const Key('home_activities_refresh_2614'),
              onPressed:_refresh,icon:const Icon(Icons.refresh,color:blue,size:19),
              tooltip:'Perbarui kegiatan Jumantik dan Bank Sampah'),
          ]),
          const Text('Hanya kegiatan terverifikasi dan penimbangan yang disahkan Admin.',
            style:TextStyle(fontSize:11,color:Color(0xff62748a))),
          if(snapshot.connectionState==ConnectionState.waiting)
            const Padding(padding:EdgeInsets.symmetric(vertical:10),
              child:LinearProgressIndicator(minHeight:2)),
          _heading('Kegiatan Jumantik',Icons.health_and_safety_outlined,
            ()=>widget.navigate('Berita Jumantik Cikoko')),
          if(snapshot.hasData&&jumantik.isEmpty)
            const Padding(padding:EdgeInsets.all(9),
              child:Text('Belum ada pembaruan Jumantik terverifikasi.',
                style:TextStyle(fontSize:11,color:Color(0xff62748a)))),
          for(final entry in jumantik.take(2))
            _activity(
              title:entry['_source']=='rt'
                ?'Pemeriksaan Jumantik RT/RW':'Jumantik Mandiri Warga',
              subtitle:entry['_source']=='rt'
                ?'RT '+(entry['rt']??'-').toString()+' / RW '+
                  (entry['rw']??'-').toString()+' · Hasil pemantauan jentik'
                :'Laporan pemeriksaan warga telah diverifikasi Super Admin',
              date:(entry['_source']=='rt'
                ?entry['tanggal']:entry['waktu']??'').toString(),
              icon:Icons.bug_report_outlined,
              onTap:()=>widget.navigate(entry['_source']=='rt'
                ?'Berita Jumantik Cikoko':'Berita Jumantik Mandiri Warga'),
            ),
          _heading('Kegiatan Bank Sampah',Icons.recycling_outlined,
            bankAccessible?()=>widget.navigate('Bank Sampah Cikoko'):null),
          if(snapshot.hasData&&bank.isEmpty)
            Padding(padding:const EdgeInsets.all(9),
              child:Text(data?['bank'] is Map &&
                (data!['bank'] as Map)['ok']==false
                ?'Update Bank Sampah belum dapat dimuat dari server.'
                :'Belum ada penimbangan Bank Sampah yang disahkan.',
                style:const TextStyle(fontSize:11,color:Color(0xff62748a)))),
          for(final row in bank.take(2))
            _activity(
              title:'Penimbangan Bank Sampah Cikoko',
              subtitle:'Total '+_kg(row['weight_kg'])+' Kg · Rp '+
                _rupiah(row['amount_rp'])+' · '+
                (row['entries']??0).toString()+' catatan',
              date:(row['date']??'').toString(),
              icon:Icons.scale_outlined,
              onTap:bankAccessible?()=>widget.navigate('Bank Sampah Cikoko'):null,
            ),
        ]);
      },
    );
  }
  static String _kg(Object? input){
    final n=double.tryParse((input??'0').toString())??0;
    return n.toStringAsFixed(3).replaceFirst(RegExp(r'\\.?0+$'),'');
  }
  static String _rupiah(Object? input){
    final n=int.tryParse((input??'0').toString())??0;
    return n.toString().replaceAllMapped(
      RegExp(r'\\B(?=(\\d{3})+(?!\\d))'),(m)=>'.');
  }
}
