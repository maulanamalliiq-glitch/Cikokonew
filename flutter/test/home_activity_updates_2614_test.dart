import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cikoko/cikoko_activity_updates_2614.dart';

void main(){
  final approved=<String,dynamic>{
    'rt':{'ok':true,'items':[
      {'tanggal':'2026-11-18','rt':'002','rw':'003','jentik':'Tidak'}
    ]},
    'mandiri':{'ok':true,'items':[
      {'waktu':'2026-11-19 14:00:00','kegiatan':'sudah_terlaksana'}
    ]},
    'bank':{'ok':true,'items':[
      {'date':'2026-11-15','weight_kg':'324.000',
        'amount_rp':231000,'entries':5}
    ]},
  };

  testWidgets('Home cards show verified Jumantik and approved Bank Sampah below innovations',
    (tester)async{
      await tester.binding.setSurfaceSize(const Size(390,1100));
      addTearDown(()=>tester.binding.setSurfaceSize(null));
      final opened=<String>[];
      await tester.pumpWidget(MaterialApp(home:Scaffold(
        body:SingleChildScrollView(child:CikokoActivityUpdates2614(
          role:'pjlp',navigate:opened.add,fetcher:()async=>approved,
        )),
      )));
      await tester.pumpAndSettle();
      expect(find.text('Update Kegiatan Terbaru'),findsOneWidget);
      expect(find.text('Kegiatan Jumantik'),findsOneWidget);
      expect(find.text('Kegiatan Bank Sampah'),findsOneWidget);
      expect(find.text('Pemeriksaan Jumantik RT/RW'),findsOneWidget);
      expect(find.text('Jumantik Mandiri Warga'),findsOneWidget);
      expect(find.textContaining('324 Kg'),findsOneWidget);
      expect(find.textContaining('Rp 231.000'),findsOneWidget);
      expect(find.textContaining('nama kepala keluarga'),findsNothing);
      expect(find.textContaining('nomor hp'),findsNothing);
      await tester.ensureVisible(find.text('Penimbangan Bank Sampah Cikoko'));
      await tester.tap(find.text('Penimbangan Bank Sampah Cikoko'));
      expect(opened,contains('Bank Sampah Cikoko'));
    });

  testWidgets('Unpublished activity never uses fabricated counts and has a refresh',
    (tester)async{
      await tester.binding.setSurfaceSize(const Size(390,1100));
      addTearDown(()=>tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(MaterialApp(home:Scaffold(
        body:SingleChildScrollView(child:CikokoActivityUpdates2614(
          role:'guest',navigate:(_){},
          fetcher:()async=>{
            'rt':{'ok':true,'items':[]},
            'mandiri':{'ok':true,'items':[]},
            'bank':{'ok':true,'items':[]},
          },
        )),
      )));
      await tester.pumpAndSettle();
      expect(find.text('Belum ada pembaruan Jumantik terverifikasi.'),findsOneWidget);
      expect(find.text('Belum ada penimbangan Bank Sampah yang disahkan.'),findsOneWidget);
      expect(find.byKey(const Key('home_activities_refresh_2614')),findsOneWidget);
    });
}
