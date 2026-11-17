import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cikoko/api.dart';
import 'package:cikoko/cikoko_pppk_performance.dart';
import 'package:cikoko/cikoko_reviews.dart';
import 'package:cikoko/integrated_services.dart';
import 'package:cikoko/role_catalog.dart';

class _ReviewsApi extends CikokoApi{
 @override Future<Map<String,dynamic>> call(String action,
   {Map<String,dynamic>? body,bool authorized=false})async{
  if(action=='review_public')return {
   'ok':true,'review_count':2,'average_stars':4.5,
   'items':[{'display_name':'Warga','stars':5,'review_text':'Layanan sangat membantu.'}]
  };
  return {'ok':true};
 }
}
void main(){
 test('PPPK uses distinct official attachment indicators',(){
  expect(pppkIndicatorsForJob('Operator Layanan Administrasi').length,4);
  expect(pppkIndicatorsForJob('Operator Layanan Umum').length,5);
  expect(pppkIndicatorsForJob('Operator Layanan Administrasi')[0],
    contains('peninjauan lapangan'));
  expect(pppkIndicatorsForJob('Operator Layanan Umum')[0],
    contains('jalan/gang'));
  expect(pppkIndicatorsForJob('Operator Layanan Umum')[4],
    contains('tugas-tugas kedinasan lainnya'));
 });
 test('Staff menus have attendance, monthly performance and leave, without roster',(){
  for(final role in ['pjlp','pppk']){
   final routes=modulesForRole(role,{}).map((e)=>e.title).toList();
   expect(routes,contains('Kehadiran'));
   expect(routes,contains('Kinerja Bulanan'));
   expect(routes,contains('Cuti Pegawai'));
   expect(routes,isNot(contains('Jadwal Piket & Dinas')));
  }
 });
 testWidgets('Service without uploaded logo uses a descriptive category pictogram',(tester)async{
  await tester.pumpWidget(const MaterialApp(home:Scaffold(
   body:CikokoServiceLogo(entry:{'id':'dukcapil','logo_url':''}))));
  expect(find.byIcon(Icons.badge_outlined),findsOneWidget);
 });
 testWidgets('Public review card displays rating but no user phone or email',(tester)async{
  await tester.pumpWidget(MaterialApp(home:Scaffold(
   body:CikokoReviewSummary(api:_ReviewsApi(),onAll:(){}))));
  await tester.pumpAndSettle();
  expect(find.text('Ulasan Pengguna'),findsOneWidget);
  expect(find.text('4.5/5'),findsOneWidget);
  expect(find.text('2 ulasan'),findsOneWidget);
  expect(find.textContaining('Layanan sangat membantu'),findsOneWidget);
  expect(find.textContaining('0812'),findsNothing);
 });
}
