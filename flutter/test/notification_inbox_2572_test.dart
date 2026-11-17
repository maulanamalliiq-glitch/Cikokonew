import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cikoko/cikoko_v6_content.dart';

void main(){
 test('Known categories are consistently labeled',(){
  expect(cikokoNotificationCategoryLabel('chat'),'Pesan');
  expect(cikokoNotificationCategoryLabel('leave'),'Cuti PJLP');
  expect(cikokoNotificationCategoryLabel('pppk_leave'),'Cuti PPPK');
  expect(cikokoNotificationCategoryLabel('pppk_performance'),'Kinerja PPPK');
  expect(cikokoNotificationCategoryLabel('unknown'),'Informasi');
 });
 testWidgets('Personal inbox filters by read state and opens selected event', (tester)async{
  String opened='';bool markedAll=false;
  final events=<Map<String,dynamic>>[
   {'id':1,'category':'chat','title':'Pesan petugas','message':'Halo warga',
     'is_read':0,'created_at':'2026-11-18 10:10:00'},
   {'id':2,'category':'pppk_leave','title':'Cuti diproses','message':'Menunggu atasan',
     'is_read':1,'created_at':'2026-11-18 08:10:00'},
  ];
  await tester.pumpWidget(MaterialApp(home:Scaffold(
   body:V6NotificationPage(
    guest:false,events:events,login:(){},
    onOpen:(event)=>opened=event['id'].toString(),
    onReadAll:()async{markedAll=true;},
   ))));
  await tester.pumpAndSettle();
  expect(find.text('1 belum dibaca'),findsOneWidget);
  expect(find.byKey(const Key('notification_event_1')),findsOneWidget);
  expect(find.byKey(const Key('notification_event_2')),findsOneWidget);
  await tester.tap(find.byKey(const Key('notification_filter_Belum Dibaca')));
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('notification_event_1')),findsOneWidget);
  expect(find.byKey(const Key('notification_event_2')),findsNothing);
  await tester.tap(find.byKey(const Key('notification_event_1')));
  expect(opened,'1');
  await tester.tap(find.byKey(const Key('notification_read_all')));
  await tester.pumpAndSettle();
  expect(markedAll,isTrue);
 });
 testWidgets('Guests see login rather than private activity',(tester)async{
  await tester.pumpWidget(MaterialApp(home:Scaffold(
   body:V6NotificationPage(guest:true,events:const [],
    onOpen:(_){},login:(){}))));
  await tester.pumpAndSettle();
  expect(find.textContaining('Masuk untuk membaca notifikasi pribadi'),findsOneWidget);
  expect(find.byKey(const Key('notification_read_all')),findsNothing);
 });
}
