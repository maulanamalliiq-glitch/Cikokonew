import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'api.dart';

/// Independent PPPK attendance. Uses only pppk_staff_* endpoints.
class CikokoPppkAttendancePage extends StatefulWidget{
 final CikokoApi api;
 const CikokoPppkAttendancePage({super.key,required this.api});
 @override State<CikokoPppkAttendancePage> createState()=>_AttendanceState();
}
class _AttendanceState extends State<CikokoPppkAttendancePage>{
 bool busy=false;String? error;Map<String,dynamic> info={};
 String shift='pagi',workType='rutin';
 final notes=TextEditingController(),description=TextEditingController();
 @override void initState(){super.initState();reload();}
 @override void dispose(){notes.dispose();description.dispose();super.dispose();}
 Future<void> reload()async{
  try{final d=await widget.api.call('pppk_staff_attendance_me');
   if(mounted)setState((){info=d;error=null;});
  }catch(e){if(mounted)setState(()=>error=e.toString());}
 }
 Future<Position> location()async{
  if(!await Geolocator.isLocationServiceEnabled())throw ApiError('Aktifkan GPS.');
  var permission=await Geolocator.checkPermission();
  if(permission==LocationPermission.denied)permission=await Geolocator.requestPermission();
  if(permission!=LocationPermission.always&&permission!=LocationPermission.whileInUse)
   throw ApiError('Izinkan akses lokasi presisi.');
  final p=await Geolocator.getCurrentPosition(locationSettings:const LocationSettings(
   accuracy:LocationAccuracy.high,timeLimit:Duration(seconds:20)));
  if(p.isMocked||p.accuracy<=0||p.accuracy>100)
   throw ApiError('Akurasi lokasi belum cukup (maksimal 100 m).');
  return p;
 }
 Future<String?> capture()async{
  final x=await ImagePicker().pickImage(source:ImageSource.camera,
   imageQuality:60,maxWidth:1200,maxHeight:1200);
  if(x==null)return null;
  final file=File(x.path);
  try{final data=await file.readAsBytes();
   if(data.length>2000000)throw ApiError('Foto lebih besar dari 2 MB.');
   return base64Encode(data);
  }finally{try{await file.delete();}catch(_){}}
 }
 Future<void> punch(String type)async{
  if(busy)return;
  setState(()=>busy=true);
  try{
   final p=await location();
   final photo=await capture();if(photo==null)return;
   await widget.api.call('pppk_staff_punch',body:{
    'type':type,'shift':shift,'report_type':workType,
    'notes':notes.text.trim(),'latitude':p.latitude,'longitude':p.longitude,
    'accuracy_m':p.accuracy,'photo_base64':photo,
   });
   await reload();
  }catch(e){if(mounted)setState(()=>error=e.toString());}
  finally{if(mounted)setState(()=>busy=false);}
 }
 Future<void> stage(int percent)async{
  if(busy)return;
  if(description.text.trim().length<5){setState(()=>error='Isi keterangan pekerjaan.');return;}
  setState(()=>busy=true);
  try{
   final photo=await capture();if(photo==null)return;
   await widget.api.call('pppk_staff_report',body:{
    'stage':percent,'description':description.text.trim(),'photo_base64':photo,
   });
   description.clear();await reload();
  }catch(e){if(mounted)setState(()=>error=e.toString());}
  finally{if(mounted)setState(()=>busy=false);}
 }
 @override Widget build(BuildContext context){
  final active=info['active_shift'] is Map?info['active_shift'] as Map:null;
  final date=(active?['work_date']??'').toString();
  final done=(info['reports'] as List? ?? []).whereType<Map>()
   .where((r)=>r['work_date']==date)
   .map((r)=>int.tryParse((r['stage']??'').toString())??-1).toSet();
  final next=!done.contains(0)?0:!done.contains(50)?50:!done.contains(100)?100:null;
  final rows=(info['items'] as List? ?? []).whereType<Map>();
  final minutes=int.tryParse((info['total_work_minutes']??0).toString())??0;
  return RefreshIndicator(onRefresh:reload,child:ListView(
   key:const Key('pppk_attendance_screen'),
   padding:const EdgeInsets.all(16),children:[
    const Text('Kehadiran PPPK',style:TextStyle(fontSize:21,fontWeight:FontWeight.w800)),
    const Text('Absensi PPPK terpisah dari PJLP. Gunakan kamera dan GPS saat absen.'),
    if(error!=null)Card(child:ListTile(title:Text(error!,
     style:const TextStyle(color:Colors.red)))),
    const SizedBox(height:12),
    Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(
     crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text(active==null?'Tidak ada shift aktif':'Shift '+(active['shift_name']??'').toString()+
       ' • '+date,style:const TextStyle(fontWeight:FontWeight.bold)),
      if(active==null)...[
       DropdownButtonFormField<String>(initialValue:shift,
        decoration:const InputDecoration(labelText:'Shift PPPK'),
        items:const [
         DropdownMenuItem(value:'pagi',child:Text('Pagi')),
         DropdownMenuItem(value:'siang',child:Text('Siang')),
         DropdownMenuItem(value:'malam',child:Text('Malam'))],
        onChanged:busy?null:(v){if(v!=null)setState(()=>shift=v);}),
       DropdownButtonFormField<String>(initialValue:workType,
        decoration:const InputDecoration(labelText:'Jenis kerja'),
        items:const [
         DropdownMenuItem(value:'rutin',child:Text('Kerja di kantor')),
         DropdownMenuItem(value:'dinas_luar',child:Text('Dinas luar'))],
        onChanged:busy?null:(v){if(v!=null)setState(()=>workType=v);}),
       if(workType=='dinas_luar')TextField(controller:notes,
        decoration:const InputDecoration(labelText:'Keterangan dinas luar')),
       FilledButton.icon(onPressed:busy?null:()=>punch('checkin'),
        icon:const Icon(Icons.login),label:const Text('Absen masuk')),
      ]else...[
       Text('Masuk: '+(active['checkin_at']??'').toString()),
       TextField(controller:description,maxLines:2,
        decoration:const InputDecoration(labelText:'Keterangan pekerjaan')),
       if(next!=null)OutlinedButton.icon(onPressed:busy?null:()=>stage(next),
        icon:const Icon(Icons.camera_alt_outlined),
        label:Text('Bukti foto '+next.toString()+'%')),
       if(next==null)const Text('Bukti 0%, 50% dan 100% lengkap.'),
       FilledButton.icon(onPressed:busy?null:()=>punch('checkout'),
        icon:const Icon(Icons.logout),label:const Text('Absen pulang')),
      ],
     ]))),
    const SizedBox(height:15),
    Text('Rekap '+(info['month']??'').toString()+' • '+
     (minutes/60).toStringAsFixed(1)+' jam',
     style:const TextStyle(fontWeight:FontWeight.w800)),
    const Text('Target standar 8 jam kerja; dihitung dari waktu masuk dan pulang.',
     style:TextStyle(color:Colors.black54,fontSize:11)),
    for(final x in rows)Card(child:ListTile(
     title:Text((x['work_date']??'').toString()+' • '+(x['shift_name']??'').toString()),
     subtitle:Text('Masuk: '+(x['checkin_at']??'').toString()+
      ' • Pulang: '+(x['checkout_at']??'Belum').toString()))),
    if(rows.isEmpty)const ListTile(title:Text('Belum ada absensi PPPK.')),
   ],
  ));
 }
}

class CikokoPppkLeavePage extends StatefulWidget{
 final CikokoApi api;
 const CikokoPppkLeavePage({super.key,required this.api});
 @override State<CikokoPppkLeavePage> createState()=>_LeaveState();
}
class _LeaveState extends State<CikokoPppkLeavePage>{
 late Future<Map<String,dynamic>> future;
 DateTimeRange? selected;
 final reason=TextEditingController(),address=TextEditingController(),phone=TextEditingController();
 String? error;bool saving=false;
 @override void initState(){super.initState();refresh();}
 @override void dispose(){reason.dispose();address.dispose();phone.dispose();super.dispose();}
 void refresh(){future=widget.api.call('pppk_staff_leave_me');if(mounted)setState((){});}
 String date(DateTime d)=>d.year.toString()+'-'+d.month.toString().padLeft(2,'0')+
  '-'+d.day.toString().padLeft(2,'0');
 Future<void> pick()async{
  final d=DateTime.now();
  final v=await showDateRangePicker(context:context,
   firstDate:DateTime(d.year,d.month,d.day),lastDate:DateTime(d.year+2,12,31));
  if(v!=null&&mounted)setState(()=>selected=v);
 }
 Future<void> apply()async{
  if(selected==null||reason.text.trim().length<10||address.text.trim().isEmpty||
   phone.text.trim().isEmpty){setState(()=>error='Lengkapi tanggal, alasan, alamat dan telepon.');return;}
  setState(()=>saving=true);
  try{await widget.api.call('pppk_staff_leave_apply',body:{
   'start_date':date(selected!.start),'end_date':date(selected!.end),
   'reason':reason.text.trim(),'leave_address':address.text.trim(),'phone':phone.text.trim(),
  });
   reason.clear();address.clear();phone.clear();selected=null;error=null;refresh();
  }catch(e){if(mounted)setState(()=>error=e.toString());}
  finally{if(mounted)setState(()=>saving=false);}
 }
 @override Widget build(BuildContext context)=>RefreshIndicator(
  onRefresh:()async{refresh();await future;},
  child:FutureBuilder<Map<String,dynamic>>(future:future,builder:(c,s){
   if(!s.hasData)return ListView(children:[
    const SizedBox(height:90),
    Center(child:s.hasError?Text('Server cuti PPPK belum siap: '+s.error.toString()):
      const CircularProgressIndicator())]);
   final d=s.data!;final list=(d['items'] as List? ?? []).whereType<Map>();
   final available=(int.tryParse((d['allowance']??0).toString())??0)-
    (int.tryParse((d['used_or_held']??0).toString())??0);
   return ListView(key:const Key('pppk_leave_screen'),padding:const EdgeInsets.all(16),children:[
    const Text('Cuti PPPK',style:TextStyle(fontSize:21,fontWeight:FontWeight.w800)),
    const Text('Permohonan dan persetujuan disimpan terpisah dari cuti PJLP.'),
    Card(child:ListTile(title:Text('Sisa jatah: '+available.toString()+' hari'),
     subtitle:Text('Jatah: '+(d['allowance']??0).toString()+
      ' • Terpakai/tertahan: '+(d['used_or_held']??0).toString()))),
    if(d['configured']!=true)const Card(child:ListTile(
     title:Text('Jatah cuti dan atasan langsung belum ditetapkan admin.'))),
    OutlinedButton.icon(onPressed:pick,icon:const Icon(Icons.event),
     label:Text(selected==null?'Pilih tanggal cuti':date(selected!.start)+
      ' sampai '+date(selected!.end))),
    TextField(controller:reason,decoration:const InputDecoration(labelText:'Alasan cuti')),
    TextField(controller:address,decoration:const InputDecoration(labelText:'Alamat selama cuti')),
    TextField(controller:phone,keyboardType:TextInputType.phone,
     decoration:const InputDecoration(labelText:'Nomor telepon')),
    if(error!=null)Text(error!,style:const TextStyle(color:Colors.red)),
    FilledButton(onPressed:saving||d['configured']!=true?null:apply,
     child:const Text('Kirim Pengajuan Cuti PPPK')),
    const SizedBox(height:20),
    const Text('Riwayat cuti PPPK',style:TextStyle(fontWeight:FontWeight.w800)),
    for(final x in list)Card(child:ListTile(
     title:Text((x['start_date']??'').toString()+' – '+(x['end_date']??'').toString()),
     subtitle:Text((x['requested_days']??'').toString()+' hari • '+
      (x['reason']??'').toString()),trailing:Text((x['status']??'').toString(),
       style:const TextStyle(fontSize:10)))),
    if(list.isEmpty)const Text('Belum ada pengajuan cuti PPPK.'),
   ]);
  }),
 );
}

class CikokoPppkLeaveApprovalPage extends StatefulWidget{
 final CikokoApi api;final String role;
 const CikokoPppkLeaveApprovalPage({super.key,required this.api,required this.role});
 @override State<CikokoPppkLeaveApprovalPage> createState()=>_LeaveApprovalState();
}
class _LeaveApprovalState extends State<CikokoPppkLeaveApprovalPage>{
 Map<String,dynamic> data={};String? error,employee,boss;
 final days=TextEditingController(text:'12');
 @override void initState(){super.initState();reload();}
 @override void dispose(){days.dispose();super.dispose();}
 Future<void> reload()async{
  try{final d=await widget.api.call('pppk_staff_leave_admin');
   if(mounted)setState((){data=d;error=null;});}
  catch(e){if(mounted)setState(()=>error=e.toString());}
 }
 Future<void> setAllowance()async{
  if(employee==null||boss==null)return;
  try{await widget.api.call('pppk_staff_leave_setting',body:{
   'user_id':employee,'supervisor_user_id':boss,
   'allowance_days':int.tryParse(days.text)??0,'year':DateTime.now().year,
  });await reload();}catch(e){if(mounted)setState(()=>error=e.toString());}
 }
 Future<void> decision(int id,String value)async{
  try{await widget.api.call('pppk_staff_leave_review',body:{
   'id':id,'decision':value,
   'note':value=='reject'?'Perlu melengkapi kembali dokumen.':'',
  });await reload();}catch(e){if(mounted)setState(()=>error=e.toString());}
 }
 @override Widget build(BuildContext context){
  final admin=widget.role=='admin'||widget.role=='admin_kelurahan';
  final people=(data['employees'] as List? ?? []).whereType<Map>();
  final bosses=(data['supervisors'] as List? ?? []).whereType<Map>();
  final requests=(data['items'] as List? ?? []).whereType<Map>();
  return RefreshIndicator(onRefresh:reload,child:ListView(padding:const EdgeInsets.all(14),children:[
   const Text('Persetujuan Cuti PPPK',style:TextStyle(fontSize:20,fontWeight:FontWeight.w800)),
   if(error!=null)Text(error!,style:const TextStyle(color:Colors.red)),
   if(admin)Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(children:[
    const Text('Atur jatah cuti dan atasan PPPK'),
    DropdownButtonFormField<String>(initialValue:employee,hint:const Text('Pegawai PPPK'),
     items:people.map((p)=>DropdownMenuItem<String>(value:p['user_id'].toString(),
      child:Text(p['name'].toString()))).toList(),onChanged:(v)=>setState(()=>employee=v)),
    DropdownButtonFormField<String>(initialValue:boss,hint:const Text('Atasan langsung'),
     items:bosses.map((p)=>DropdownMenuItem<String>(value:p['user_id'].toString(),
      child:Text(p['name'].toString()))).toList(),onChanged:(v)=>setState(()=>boss=v)),
    TextField(controller:days,keyboardType:TextInputType.number,
     decoration:const InputDecoration(labelText:'Jatah hari cuti')),
    FilledButton(onPressed:setAllowance,child:const Text('Simpan')),
   ]))),
   const SizedBox(height:12),
   for(final row in requests)Card(child:Padding(padding:const EdgeInsets.all(12),
    child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
     Text((row['employee_name']??'PPPK').toString(),
      style:const TextStyle(fontWeight:FontWeight.w800)),
     Text((row['start_date']??'').toString()+' sampai '+(row['end_date']??'').toString()),
     Text('Alasan: '+(row['reason']??'').toString()),
     Text('Status: '+(row['status']??'').toString()),
     if((admin&&row['status']=='pending_admin')||
        (['asn','admin_kelurahan'].contains(widget.role)&&
         row['status']=='pending_supervisor'&&
         (row['supervisor_user_id']??'').toString()==
          (widget.api.profile?['id']??widget.api.profile?['user_id']??'').toString())||
        (widget.role=='lurah'&&row['status']=='pending_lurah'))
      Row(children:[
       TextButton(onPressed:()=>decision(int.parse(row['id'].toString()),'approve'),
        child:const Text('Setujui')),
       TextButton(onPressed:()=>decision(int.parse(row['id'].toString()),'reject'),
        child:const Text('Tolak')),
      ]),
    ]))),
   if(requests.isEmpty)const Text('Belum ada pengajuan cuti PPPK.'),
  ]));
 }
}
