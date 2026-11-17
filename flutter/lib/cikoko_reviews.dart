import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'api.dart';

class CikokoReviewSummary extends StatefulWidget{
 final CikokoApi api;final VoidCallback onAll;
 const CikokoReviewSummary({super.key,required this.api,required this.onAll});
 @override State<CikokoReviewSummary> createState()=>_ReviewSummaryState();
}
class _ReviewSummaryState extends State<CikokoReviewSummary>{
 Map<String,dynamic>? data;
 bool unavailable=false;
 @override void initState(){super.initState();load();}
 Future<void> load()async{
  try{final v=await widget.api.call('review_public');
   if(mounted)setState((){data=v;unavailable=false;});
  }catch(_){if(mounted)setState(()=>unavailable=true);}
 }
 @override Widget build(BuildContext context){
  final rows=(data?['items'] as List? ?? []).whereType<Map>().take(3);
  return Column(key:const Key('cikoko_home_reviews'),crossAxisAlignment:CrossAxisAlignment.start,children:[
   Row(children:[const Expanded(child:Text('Ulasan Pengguna',style:TextStyle(fontSize:15,fontWeight:FontWeight.w800))),
    TextButton(onPressed:widget.onAll,child:const Text('Lihat semua  →'))]),
   Card(color:Colors.white,child:Padding(padding:const EdgeInsets.all(13),
    child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
     if(data!=null)Row(children:[const Icon(Icons.star_rounded,color:Color(0xFFFFB000),size:27),const SizedBox(width:7),
      Text((data?['average_stars']??0).toString()+'/5',style:const TextStyle(fontWeight:FontWeight.w800,fontSize:18)),
      const SizedBox(width:8),Text((data?['review_count']??0).toString()+' ulasan')]),
     if(unavailable)const Text('Layanan ulasan belum tersedia di server. Admin perlu memperbarui Mobile API.',
    style:TextStyle(color:Colors.deepOrange,fontSize:12)),
     if(!unavailable&&data!=null&&rows.isEmpty)const Text('Belum ada ulasan pengguna.'),
     for(final row in rows)Padding(padding:const EdgeInsets.only(top:8),child:Column(
       crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text((row['display_name']??'Pengguna').toString()+' • '+('★'*(int.tryParse((row['stars']??0).toString())??0)),
          style:const TextStyle(fontWeight:FontWeight.bold)),
        Text((row['review_text']??'').toString(),maxLines:3,overflow:TextOverflow.ellipsis),
       ])),
    ]))),
  ]);
 }
}
class CikokoReviewPage extends StatefulWidget{
 final CikokoApi api;
 const CikokoReviewPage({super.key,required this.api});
 @override State<CikokoReviewPage> createState()=>_ReviewPageState();
}
class _ReviewPageState extends State<CikokoReviewPage>{
 final text=TextEditingController();int stars=5;bool sending=false;String? error;
 Map<String,dynamic>? data;
 @override void initState(){super.initState();refresh();}
 @override void dispose(){text.dispose();super.dispose();}
 Future<void> refresh()async{
  try{final v=await widget.api.call('review_public');if(mounted)setState(()=>data=v);}
  catch(e){if(mounted)setState(()=>error='Daftar ulasan gagal dimuat: '+e.toString());}
 }
 Future<void> submit()async{
  if(widget.api.token==null){setState(()=>error='Silakan login untuk mengirim ulasan.');return;}
  if(text.text.trim().length<10){setState(()=>error='Ulasan minimal 10 karakter.');return;}
  setState((){sending=true;error=null;});
  try{
   await widget.api.call('review_submit',body:{'stars':stars,'review':text.text.trim()});
   text.clear();await refresh();
   if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Ulasan berhasil disimpan.')));
  }catch(e){if(mounted)setState(()=>error=e.toString());}
  finally{if(mounted)setState(()=>sending=false);}
 }
 @override Widget build(BuildContext context)=>Scaffold(
  appBar:AppBar(title:const Text('Ulasan Aplikasi')),
  body:ListView(padding:const EdgeInsets.all(16),children:[
   const Text('Berikan penilaian Cikoko Smart'),
   Row(children:[for(var i=1;i<=5;i++)IconButton(tooltip:i.toString()+' bintang',
    onPressed:()=>setState(()=>stars=i),icon:Icon(i<=stars?Icons.star:Icons.star_border,
      color:const Color(0xFFE6A100),size:29))]),
   TextField(controller:text,maxLength:1200,maxLines:4,
    decoration:const InputDecoration(labelText:'Tulis ulasan',border:OutlineInputBorder())),
   if(error!=null)Text(error!,style:const TextStyle(color:Colors.red)),
   FilledButton.icon(onPressed:sending?null:submit,icon:const Icon(Icons.rate_review),
    label:const Text('Kirim Ulasan')),
   const SizedBox(height:14),
   if(data!=null)Text('Rata-rata '+(data?['average_stars']??0).toString()+'/5 • '+(data?['review_count']??0).toString()+' ulasan'),
   for(final row in (data?['items'] as List? ?? []).whereType<Map>())
    Card(child:ListTile(title:Text((row['display_name']??'Pengguna').toString()+' • '+
      ('★'*(int.tryParse((row['stars']??0).toString())??0))),
      subtitle:Text((row['review_text']??'').toString()))),
  ]));
}
class CikokoAdminReviewReport extends StatefulWidget{
 final CikokoApi api;
 const CikokoAdminReviewReport({super.key,required this.api});
 @override State<CikokoAdminReviewReport> createState()=>_AdminReviewState();
}
class _AdminReviewState extends State<CikokoAdminReviewReport>{
 late Future<Map<String,dynamic>> future;
 @override void initState(){super.initState();future=widget.api.call('review_admin');}
 Future<Uint8List> makePdf(Map<String,dynamic> data)async{
  final rows=(data['items'] as List? ?? []).whereType<Map>().toList();
  final pdf=pw.Document();
  pw.Widget line(String value,{bool bold=false})=>pw.Text(value,style:pw.TextStyle(
    fontSize:9,fontWeight:bold?pw.FontWeight.bold:pw.FontWeight.normal));
  pdf.addPage(pw.MultiPage(pageFormat:PdfPageFormat.a4,
   margin:const pw.EdgeInsets.all(32),build:(_)=>[
    pw.Center(child:line('REKAP ULASAN CIKOKO SMART',bold:true)),
    pw.SizedBox(height:10),
    line('Jumlah ulasan: '+(data['total']??0).toString(),bold:true),
    line('Rata-rata: '+(data['average_stars']??0).toString()+'/5',bold:true),
    for(var star=5;star>=1;star--)line(star.toString()+' bintang: '+
      rows.where((e)=>int.tryParse((e['stars']??0).toString())==star).length.toString()),
    pw.SizedBox(height:12),
    for(var i=0;i<rows.length;i++)...[
     line((i+1).toString()+'. '+(rows[i]['name']??'').toString()+' • '+
       (rows[i]['stars']??'').toString()+'/5',bold:true),
     line('Akun: '+(rows[i]['username']??'').toString()+' ('+
       (rows[i]['user_role']??'').toString()+')'),
     line('ID: '+(rows[i]['user_id']??'').toString()),
     line('Email: '+(rows[i]['email']??'').toString()+' • Telp: '+(rows[i]['phone']??'').toString()),
     line('Tanggal: '+(rows[i]['updated_at']??'').toString()),
     line('Ulasan: '+(rows[i]['review_text']??'').toString()),
     pw.Divider(),
    ]
   ]));
  return pdf.save();
 }
 @override Widget build(BuildContext context)=>Scaffold(
  appBar:AppBar(title:const Text('Rekap Ulasan Pengguna')),
  body:FutureBuilder<Map<String,dynamic>>(future:future,builder:(context,s){
   if(s.hasError)return Center(child:Text('Gagal memuat ulasan: '+s.error.toString()));
   if(!s.hasData)return const Center(child:CircularProgressIndicator());
   return PdfPreview(build:(_)=>makePdf(s.data!),canChangePageFormat:false,
     canChangeOrientation:false,allowPrinting:true,allowSharing:true);
  }));
}
