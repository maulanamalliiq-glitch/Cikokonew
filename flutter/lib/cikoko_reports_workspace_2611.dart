import 'package:flutter/material.dart';
import 'role_catalog.dart';

/// Restrict the report workspace to modules already allowed by the user's
/// role/capabilities. Permissions for every API action remain server-side.
class CikokoReportDestination2611 {
  final String title, route, group;
  final IconData icon;
  const CikokoReportDestination2611(this.title,this.route,this.group,this.icon);
}

/// Readable/interactive reports are scoped to the existing role catalog.
/// Do not invent new routes, show unavailable modules, or bypass permissions.
List<CikokoReportDestination2611> cikokoReportsForModules2611(
    List<RoleFeature> modules) {
  const explicit = <String>{
    'Riwayat', 'Jumantik Mandiri', 'Laporan Jumantik RT/RW',
    'Verifikasi Jumantik', 'Verifikasi Jumantik Mandiri',
    'Bank Sampah Cikoko', 'Absensi dan Kinerja PJLP',
    'Kehadiran PPPK', 'Kinerja PPPK', 'Cuti PPPK',
    'Cuti PPSU', 'Kelola Cuti PPPK', 'Kelola Cuti PPSU',
    'Persetujuan Cuti PPSU', 'Verifikasi Laporan',
    'Verifikasi Ahli Waris', 'Laporan Kegiatan Admin',
    'Surat Wilayah', 'Kehadiran', 'Monitoring Wilayah',
  };
  final result=<CikokoReportDestination2611>[];
  final seen=<String>{};
  for(final item in modules) {
    final route=item.route;
    final isReport=explicit.contains(route) || route.startsWith('Laporan ');
    if(!item.connected || !isReport || !seen.add(route)) continue;
    String group;
    IconData icon;
    if(route.contains('Jumantik')) {
      group='Jumantik';icon=Icons.bug_report_outlined;
    } else if(route=='Bank Sampah Cikoko') {
      group='Bank Sampah';icon=Icons.recycling_outlined;
    } else if(route.startsWith('Verifikasi') ||
        route.startsWith('Kelola') || route.startsWith('Persetujuan')) {
      group='Verifikasi & Persetujuan';icon=Icons.verified_outlined;
    } else if(route.contains('Kinerja') || route.contains('Cuti') ||
        route.contains('Kehadiran') || route.contains('Absensi')) {
      group='Kepegawaian';icon=Icons.badge_outlined;
    } else if(route=='Riwayat') {
      group='Riwayat';icon=Icons.history_outlined;
    } else {
      group='Laporan Wilayah';icon=Icons.description_outlined;
    }
    result.add(CikokoReportDestination2611(item.title,route,group,icon));
  }
  const order=['Jumantik','Bank Sampah','Kepegawaian',
      'Laporan Wilayah','Verifikasi & Persetujuan','Riwayat'];
  result.sort((a,b){
    final g=order.indexOf(a.group).compareTo(order.indexOf(b.group));
    return g!=0?g:a.title.compareTo(b.title);
  });
  return result;
}

/// In portrait, a left-side Drawer keeps the report form at full width.
/// Tablets/landscape keep a persistent left sidebar next to the selected form.
class CikokoReportsWorkspace2611 extends StatefulWidget {
  final String role;
  final bool guest;
  final List<RoleFeature> modules;
  final Map<String,int>? letterCounts;
  final Widget Function(String route) buildReport;
  final void Function(String route) navigate;
  const CikokoReportsWorkspace2611({
    super.key,required this.role,required this.guest,required this.modules,
    required this.letterCounts,required this.buildReport,required this.navigate
  });
  @override
  State<CikokoReportsWorkspace2611> createState()=>_CikokoReportsWorkspace2611State();
}

class _CikokoReportsWorkspace2611State extends State<CikokoReportsWorkspace2611> {
  final shell=GlobalKey<ScaffoldState>();
  String? chosenRoute;
  List<CikokoReportDestination2611> get items=>
      cikokoReportsForModules2611(widget.modules);
  String get title {
    for(final item in items)if(item.route==chosenRoute)return item.title;
    return 'Seluruh Laporan';
  }

  @override
  void didUpdateWidget(covariant CikokoReportsWorkspace2611 oldWidget){
    super.didUpdateWidget(oldWidget);
    if(chosenRoute!=null && !items.any((e)=>e.route==chosenRoute))chosenRoute=null;
  }

  void choose(CikokoReportDestination2611 item){
    if(widget.guest){widget.navigate(item.route);return;}
    if(shell.currentState?.isDrawerOpen==true)Navigator.of(context).pop();
    setState(()=>chosenRoute=item.route);
  }

  Widget sidebar({bool wide=false}){
    final available=items;
    return Container(
      width:wide?230:null,
      color:const Color(0xfff8fbff),
      child:ListView(padding:const EdgeInsets.fromLTRB(10,14,10,24),children:[
        const Padding(padding:EdgeInsets.symmetric(horizontal:8,vertical:7),
          child:Text('DAFTAR LAPORAN',
            style:TextStyle(color:Color(0xff29476b),
              fontSize:11,fontWeight:FontWeight.w900,letterSpacing:0.8))),
        const Divider(height:14),
        for(final group in available.map((e)=>e.group).toSet())...[
          Padding(padding:const EdgeInsets.fromLTRB(8,13,8,6),
            child:Text(group.toUpperCase(),
              style:const TextStyle(fontSize:10.2,fontWeight:FontWeight.w800,
                color:Color(0xff507497)))),
          for(final item in available.where((e)=>e.group==group))
            ListTile(
              key:Key('reports_menu_${item.route}'),
              selected:chosenRoute==item.route,
              selectedTileColor:const Color(0xffe6f0ff),
              shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(11)),
              dense:true,
              contentPadding:const EdgeInsets.symmetric(horizontal:8),
              leading:Icon(item.icon,size:20,color:const Color(0xff155baf)),
              title:Text(item.title,
                style:const TextStyle(fontSize:12.1,fontWeight:FontWeight.w600)),
              trailing:const Icon(Icons.chevron_right,size:17),
              onTap:()=>choose(item),
            ),
        ],
        if(available.isEmpty)
          const Padding(padding:EdgeInsets.all(10),
            child:Text('Belum ada laporan yang diizinkan untuk akun ini.')),
      ]),
    );
  }

  Widget home(){
    final entries=items;
    final groups=entries.map((r)=>r.group).toSet().toList();
    return ListView(padding:const EdgeInsets.all(15),children:[
      const Text('Pusat Laporan Cikoko',
        style:TextStyle(fontSize:19,fontWeight:FontWeight.w900,
          color:Color(0xff123963))),
      const SizedBox(height:5),
      const Text('Pilih laporan pada menu sebelah kiri. '
        'Daftar otomatis mengikuti hak akses akun Anda.',
        style:TextStyle(color:Colors.blueGrey,fontSize:12.5)),
      const SizedBox(height:14),
      Wrap(spacing:8,runSpacing:8,children:[
        Chip(avatar:const Icon(Icons.folder_open_outlined,size:18),
          label:Text('${entries.length} modul tersedia')),
        if(widget.role=='admin')const Chip(
          avatar:Icon(Icons.verified_user_outlined,size:18),
          label:Text('Pusat kerja Super Admin')),
      ]),
      const SizedBox(height:12),
      if(entries.isEmpty)const Card(child:ListTile(
        title:Text('Belum ada laporan tersedia'),
        subtitle:Text('Hubungi Admin untuk pemeriksaan hak akses.'))),
      for(final group in groups)...[
        Padding(padding:const EdgeInsets.fromLTRB(2,13,2,7),
          child:Text(group,style:const TextStyle(
            fontSize:14,fontWeight:FontWeight.w800))),
        for(final item in entries.where((e)=>e.group==group))
          Card(
            margin:const EdgeInsets.only(bottom:7),
            child:ListTile(
              leading:CircleAvatar(backgroundColor:const Color(0xffe7f3ff),
                child:Icon(item.icon,color:const Color(0xff1260af))),
              title:Text(item.title,style:const TextStyle(fontSize:12.5,
                fontWeight:FontWeight.w700)),
              trailing:const Icon(Icons.chevron_right),
              onTap:()=>choose(item),
            )),
      ],
      if(widget.guest)const Padding(padding:EdgeInsets.all(9),
        child:Text('Masuk untuk membuka laporan pribadi.',
          style:TextStyle(color:Colors.blueGrey))),
    ]);
  }

  Widget detail()=>chosenRoute==null?home():Column(children:[
    Container(color:Colors.white,
      padding:const EdgeInsets.fromLTRB(10,8,10,8),
      child:Row(children:[
        IconButton(onPressed:()=>setState(()=>chosenRoute=null),
          tooltip:'Kembali ke daftar laporan',
          icon:const Icon(Icons.arrow_back,size:19)),
        Expanded(child:Text(title,overflow:TextOverflow.ellipsis,
          style:const TextStyle(fontSize:14,fontWeight:FontWeight.w800))),
        IconButton(onPressed:()=>shell.currentState?.openDrawer(),
          tooltip:'Pilih laporan lain',
          icon:const Icon(Icons.menu_open_outlined)),
      ])),
    const Divider(height:1),
    Expanded(child:widget.buildReport(chosenRoute!)),
  ]);

  @override
  Widget build(BuildContext context){
    return LayoutBuilder(builder:(context,box){
      final wide=box.maxWidth>=730;
      return Scaffold(
        key:shell,
        backgroundColor:Colors.white,
        drawer:wide?null:Drawer(
          width:MediaQuery.sizeOf(context).width*0.82,
          child:SafeArea(child:sidebar())),
        body:wide?Row(children:[
          sidebar(wide:true),
          const VerticalDivider(width:1),
          Expanded(child:detail()),
        ]):Column(children:[
          Container(
            color:const Color(0xfff2f7fe),
            padding:const EdgeInsets.fromLTRB(8,8,12,8),
            child:Row(children:[
              IconButton(
                onPressed:()=>shell.currentState?.openDrawer(),
                tooltip:'Buka menu laporan di kiri',
                icon:const Icon(Icons.menu_rounded)),
              const SizedBox(width:3),
              const Expanded(child:Column(
                crossAxisAlignment:CrossAxisAlignment.start,children:[
                Text('Laporan Cikoko',
                  style:TextStyle(fontSize:15,fontWeight:FontWeight.w900)),
                Text('Semua laporan sesuai hak akses',
                  style:TextStyle(fontSize:11,color:Colors.blueGrey)),
              ])),
              const Icon(Icons.assignment_outlined,color:Color(0xff2161a6)),
            ]),
          ),
          Expanded(child:detail()),
        ]),
      );
    });
  }
}
