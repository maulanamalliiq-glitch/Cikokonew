import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'api.dart';

abstract final class Jumantik2605Api {
  static Uri url(String action)=>Uri.parse(CikokoApi.root.replaceFirst('index.php','jumantik-2605.php')+'?action='+action);
  static bool isStaff(String role)=>role=='jumantik_rt'||role=='jumantik_rw';
  static Map<String,String> headers(CikokoApi api){
    if(api.token==null||api.token!.isEmpty)throw ApiError('Silakan login kembali.');
    return {'Authorization':'Bearer '+api.token!,'Accept':'application/json'};
  }
  static Map<String,dynamic> decode(http.Response r){
    dynamic result;
    try{result=jsonDecode(utf8.decode(r.bodyBytes));}catch(_){throw ApiError('Endpoint Jumantik belum terpasang di server.');}
    if(result is! Map<String,dynamic>||r.statusCode>=400||result['ok']!=true){
      throw ApiError(result is Map?(result['error']??'Tidak dapat memproses laporan.').toString():'Balasan server tidak valid.');
    }
    return result;
  }
  static Future<Map<String,dynamic>> me(CikokoApi api)async=>decode(await http.get(url('me'),headers:headers(api)).timeout(const Duration(seconds:25)));
  static Future<Map<String,dynamic>> news()async=>decode(await http.get(url('news'),headers:{'Accept':'application/json'}).timeout(const Duration(seconds:20)));
}

class JumantikRtRw2605 extends StatefulWidget {
  final CikokoApi api;
  const JumantikRtRw2605({super.key,required this.api});
  @override State<JumantikRtRw2605> createState()=>_JumantikRtRw2605State();
}
class _JumantikRtRw2605State extends State<JumantikRtRw2605>{
  late Future<Map<String,dynamic>> pending;
  final form=GlobalKey<FormState>();
  final week=TextEditingController(),location=TextEditingController(),address=TextEditingController();
  DateTime selectedDate=DateTime.now().toUtc().add(const Duration(hours:7));
  DateTime nowWib=DateTime.now().toUtc().add(const Duration(hours:7));
  Timer? timer;XFile? selectedPhoto;bool busy=false;
  String member='jumantik_rt',publicPlace='',familyChecked='',larvae='';
  @override void initState(){
    super.initState();pending=Jumantik2605Api.me(widget.api);
    final role=(widget.api.profile?['role']??'').toString();
    if(Jumantik2605Api.isStaff(role))member=role;
    timer=Timer.periodic(const Duration(seconds:1),(_){
      if(mounted)setState(()=>nowWib=DateTime.now().toUtc().add(const Duration(hours:7)));
    });
  }
  @override void dispose(){timer?.cancel();week.dispose();location.dispose();address.dispose();super.dispose();}
  static String dateText(DateTime d)=>d.year.toString().padLeft(4,'0')+'-'+d.month.toString().padLeft(2,'0')+'-'+d.day.toString().padLeft(2,'0');
  static String timeText(DateTime d)=>dateText(d)+' '+d.hour.toString().padLeft(2,'0')+':'+d.minute.toString().padLeft(2,'0')+':'+d.second.toString().padLeft(2,'0')+' WIB';
  void notify(String text){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(text)));}
  Future<void> pick(ImageSource source)async{
    try{
      final file=await ImagePicker().pickImage(source:source,maxWidth:1600,imageQuality:80);
      if(file==null||!mounted)return;
      if(await File(file.path).length()>4*1024*1024){notify('Foto maksimal 4 MB.');return;}
      setState(()=>selectedPhoto=file);
    }catch(_){notify('Kamera atau galeri belum dapat digunakan.');}
  }
  Future<void> submit(Map<String,dynamic> profile)async{
    if(busy||!form.currentState!.validate())return;
    if(selectedPhoto==null){notify('Lampiran foto 1 wajib dipilih.');return;}
    if((profile['coordinator']??'').toString().isEmpty||(profile['rt']??'').toString().isEmpty||(profile['rw']??'').toString().isEmpty){
      notify('RT/RW atau koordinator belum diatur oleh Super Admin.');return;
    }
    setState(()=>busy=true);
    try{
      final req=http.MultipartRequest('POST',Jumantik2605Api.url('submit'));
      req.headers.addAll(Jumantik2605Api.headers(widget.api));
      req.fields.addAll({
        'tanggal':dateText(selectedDate),'anggota':member,'minggu_ke':week.text.trim(),
        'lokasi':location.text.trim(),'tempat_umum_lainnya':publicPlace,
        'nama_kepala_keluarga':familyChecked,'alamat_lengkap':address.text.trim(),'jentik':larvae,
      });
      req.files.add(await http.MultipartFile.fromPath('foto1',selectedPhoto!.path));
      final data=Jumantik2605Api.decode(await http.Response.fromStream(
        await req.send().timeout(const Duration(seconds:120))));
      if(!mounted)return;
      week.clear();location.clear();address.clear();
      setState((){selectedPhoto=null;publicPlace='';familyChecked='';larvae='';pending=Jumantik2605Api.me(widget.api);});
      notify((data['message']??'Laporan berhasil dikirim.').toString());
    }catch(e){notify('Laporan belum terkirim: '+e.toString());}
    finally{if(mounted)setState(()=>busy=false);}
  }
  Widget field(TextEditingController ctrl,String label,{int max=500,int lines=1,bool numeric=false})=>
    Padding(padding:const EdgeInsets.only(bottom:12),
      child:TextFormField(controller:ctrl,maxLength:max,maxLines:lines,
      keyboardType:numeric?TextInputType.number:TextInputType.text,
      decoration:InputDecoration(labelText:label,border:const OutlineInputBorder()),
      validator:(value){
        final text=(value??'').trim();
        if(text.isEmpty)return 'Wajib diisi';
        if(numeric&&(int.tryParse(text)==null||int.parse(text)<1||int.parse(text)>6))return 'Isi minggu 1–6';
        return null;
      }));
  Widget choice(String label,String value,List<String> values,ValueChanged<String?> onChange)=>
    Padding(padding:const EdgeInsets.only(bottom:12),child:DropdownButtonFormField<String>(
      initialValue:value.isEmpty?null:value,
      decoration:InputDecoration(labelText:label,border:const OutlineInputBorder()),
      items:[for(final val in values)DropdownMenuItem(value:val,child:Text(val[0].toUpperCase()+val.substring(1)))],
      onChanged:busy?null:onChange,validator:(v)=>(v??'').isEmpty?'Wajib dipilih':null));
  @override Widget build(BuildContext context){
    if(!Jumantik2605Api.isStaff((widget.api.profile?['role']??'').toString())){
      return const Center(child:Text('Form ini hanya untuk akun Jumantik RT/RW.'));
    }
    return FutureBuilder<Map<String,dynamic>>(future:pending,builder:(ctx,s){
      if(!s.hasData){
        if(s.hasError)return Center(child:TextButton(
          onPressed:()=>setState(()=>pending=Jumantik2605Api.me(widget.api)),
          child:Text('Data petugas belum tersedia. Coba lagi: '+s.error.toString())));
        return const Center(child:CircularProgressIndicator());
      }
      final profile=Map<String,dynamic>.from(s.data!['profile'] as Map);
      final ready=(profile['coordinator']??'').toString().isNotEmpty&&(profile['rt']??'').toString().isNotEmpty&&(profile['rw']??'').toString().isNotEmpty;
      final history=List<dynamic>.from(s.data!['items']??[]);
      return RefreshIndicator(onRefresh:()async{
        setState(()=>pending=Jumantik2605Api.me(widget.api));await pending;
      },child:ListView(padding:const EdgeInsets.all(14),children:[
        const Text('Laporan Jumantik RT/RW',style:TextStyle(fontSize:21,fontWeight:FontWeight.w900,color:Color(0xff12375d))),
        const SizedBox(height:9),
        Card(child:Padding(padding:const EdgeInsets.all(13),child:Column(
          crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text('Waktu realtime: '+timeText(nowWib)),
            Text('Petugas: '+(profile['name']??'').toString()),
            Text('Koordinator: '+(profile['coordinator']??'Belum diatur').toString()),
            Text('RT/RW: '+(profile['rt']??'').toString()+' / '+(profile['rw']??'').toString()),
            if(!ready)const Text('Lengkapi RT/RW dan koordinator melalui Super Admin.',style:TextStyle(color:Colors.red)),
          ]))),
        Card(child:Padding(padding:const EdgeInsets.all(13),
          child:Form(key:form,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            OutlinedButton.icon(onPressed:busy?null:()async{
              final d=await showDatePicker(context:context,initialDate:selectedDate,
                firstDate:DateTime(2020),lastDate:DateTime(2035));
              if(d!=null&&mounted)setState(()=>selectedDate=d);
            },icon:const Icon(Icons.calendar_month),label:Text('Hari/Tanggal: '+dateText(selectedDate))),
            const SizedBox(height:12),
            DropdownButtonFormField<String>(initialValue:member,
              decoration:const InputDecoration(labelText:'Anggota',border:OutlineInputBorder()),
              items:const [
                DropdownMenuItem(value:'jumantik_rt',child:Text('Jumantik RT')),
                DropdownMenuItem(value:'jumantik_rw',child:Text('Jumantik RW')),
              ],onChanged:null),
            const SizedBox(height:12),
            field(week,'Minggu Ke',max:1,numeric:true),
            field(location,'Lokasi Pemeriksaan',max:220),
            const Text('Hasil pemeriksaan',style:TextStyle(fontSize:17,fontWeight:FontWeight.w700)),
            const SizedBox(height:11),
            choice('1. Tempat Umum Lainnya',publicPlace,['sudah','belum'],(v)=>setState(()=>publicPlace=v??'')),
            choice('2. Nama Kepala Keluarga (status pemeriksaan)',familyChecked,['sudah','belum'],(v)=>setState(()=>familyChecked=v??'')),
            field(address,'3. Alamat Lengkap',max:500,lines:2),
            choice('4. Jentik',larvae,['ada','tidak'],(v)=>setState(()=>larvae=v??'')),
            const Text('5. Lampiran Foto 1',style:TextStyle(fontWeight:FontWeight.bold)),
            Wrap(spacing:8,children:[
              TextButton.icon(onPressed:busy?null:()=>pick(ImageSource.camera),icon:const Icon(Icons.camera_alt_outlined),label:const Text('Kamera')),
              TextButton.icon(onPressed:busy?null:()=>pick(ImageSource.gallery),icon:const Icon(Icons.photo_library_outlined),label:const Text('Galeri')),
            ]),
            if(selectedPhoto!=null)Image.file(File(selectedPhoto!.path),height:145,fit:BoxFit.contain),
            const SizedBox(height:12),
            const Text('Laporan diperiksa Super Admin sebelum diterbitkan.',style:TextStyle(fontSize:12,color:Colors.blueGrey)),
            const SizedBox(height:12),
            SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:busy||!ready?null:()=>submit(profile),
              icon:const Icon(Icons.send_outlined),label:Text(busy?'Mengirim...':'Kirim Laporan Jumantik'))),
          ])))),
        const SizedBox(height:12),
        const Text('Riwayat saya',style:TextStyle(fontSize:16,fontWeight:FontWeight.w700)),
        if(history.isEmpty)const Card(child:Padding(padding:EdgeInsets.all(14),child:Text('Belum ada laporan.'))),
        for(final item in history.whereType<Map>())Card(child:ListTile(
          title:Text((item['tanggal']??'').toString()+' · Jentik '+(item['jentik']??'').toString()),
          subtitle:Text(item['status']=='rejected'?'Ditolak':item['published']==true?'Sudah diterbitkan':'Menunggu pemeriksaan'))),
      ]));
    });
  }
}

class JumantikMandiri2605 extends StatelessWidget{
  const JumantikMandiri2605({super.key});
  @override Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.all(16),children:const [
    Text('Jumantik Mandiri',style:TextStyle(fontSize:22,fontWeight:FontWeight.w900,color:Color(0xff12375d))),
    SizedBox(height:12),
    Card(child:Padding(padding:EdgeInsets.all(18),child:Text(
      'Menu tersedia untuk semua akun kecuali Super Admin. '
      'Format pelaporan mandiri/warga akan dibuat terpisah setelah formulir khusus '
      'Jumantik RT/RW selesai diuji. Form petugas RT/RW tidak tersedia di akun lain.',
      style:TextStyle(height:1.6)))),
  ]);
}

class JumantikNews2605 extends StatefulWidget{
  const JumantikNews2605({super.key});
  @override State<JumantikNews2605> createState()=>_JumantikNews2605State();
}
class _JumantikNews2605State extends State<JumantikNews2605>{
  late Future<Map<String,dynamic>> pending;
  @override void initState(){super.initState();pending=Jumantik2605Api.news();}
  @override Widget build(BuildContext context)=>FutureBuilder<Map<String,dynamic>>(
    future:pending,builder:(ctx,s){
      if(!s.hasData){
        if(s.hasError)return Center(child:TextButton(onPressed:()=>setState(
          ()=>pending=Jumantik2605Api.news()),child:const Text('Berita belum tersedia. Muat ulang.')));
        return const Center(child:CircularProgressIndicator());
      }
      final items=List<dynamic>.from(s.data!['items']??[]);
      return RefreshIndicator(onRefresh:()async{setState(()=>pending=Jumantik2605Api.news());await pending;},
        child:ListView(padding:const EdgeInsets.all(14),children:[
          const Text('Berita Jumantik Cikoko',style:TextStyle(fontSize:22,
            fontWeight:FontWeight.w900,color:Color(0xff12375d))),
          const SizedBox(height:6),
          const Text('Hasil pemeriksaan yang telah diterbitkan Super Admin.',
            style:TextStyle(color:Colors.blueGrey)),
          const SizedBox(height:14),
          if(items.isEmpty)const Card(child:Padding(padding:EdgeInsets.all(16),
            child:Text('Belum ada Berita Jumantik yang diterbitkan.'))),
          for(final row in items.whereType<Map>())Card(clipBehavior:Clip.antiAlias,
            child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Builder(builder:(_){
                final photo=(row['photo_url']??'').toString();
                if(!RegExp(r'^/mobile-api/jumantik-2605\.php\?action=photo&id=[a-f0-9]{32}$').hasMatch(photo))return const SizedBox.shrink();
                return Image.network('https://datawebs.my.id'+photo,height:175,width:double.infinity,
                  fit:BoxFit.cover,errorBuilder:(_,__,___)=>const SizedBox(height:8));
              }),
              Padding(padding:const EdgeInsets.all(13),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                Text('Pemeriksaan '+(row['tanggal']??'').toString(),
                  style:const TextStyle(fontWeight:FontWeight.w800,fontSize:16,color:Color(0xff12375d))),
                Text('RT '+(row['rt']??'').toString()+' / RW '+(row['rw']??'').toString()+
                  ' · Minggu '+(row['minggu_ke']??'').toString()),
                Text('Jentik: '+(row['jentik']??'').toString()),
                Text('Tempat umum: '+(row['tempat_umum_lainnya']??'').toString()),
              ])),
            ])),
          const Padding(padding:EdgeInsets.all(9),child:Text('Nama petugas dan alamat lengkap rumah tidak ditampilkan.',
            style:TextStyle(color:Colors.blueGrey,fontSize:11))),
        ]));
    });
}
