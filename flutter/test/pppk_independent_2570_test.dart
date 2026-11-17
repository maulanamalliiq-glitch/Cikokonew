import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cikoko/api.dart';
import 'package:cikoko/role_catalog.dart';
import 'package:cikoko/cikoko_pppk_staff.dart';

class _PppkFakeApi extends CikokoApi{
 @override
 Future<Map<String,dynamic>> call(String action,
  {Map<String,dynamic>? body,bool authorized=false})async {
  if(action=='pppk_staff_attendance_me')return {
   'ok':true,'month':'2026-11','total_work_minutes':0,
   'active_shift':null,'reports':[],'items':[],
  };
  if(action=='pppk_staff_leave_me')return {
   'ok':true,'year':2026,'configured':false,'allowance':0,
   'used_or_held':0,'items':[],
  };
  return {'ok':true};
 }
}
void main(){
 test('PPPK menus do not open PJLP attendance or leave storage routes',(){
  final pppk=modulesForRole('pppk',{}).map((v)=>v.route).toList();
  final pjlp=modulesForRole('pjlp',{}).map((v)=>v.route).toList();
  expect(pppk,contains('Kehadiran PPPK'));
  expect(pppk,contains('Cuti PPPK'));
  expect(pppk,contains('Kinerja PPPK'));
  expect(pppk,contains(isNot('Absensi dan Kinerja PJLP')));
  expect(pppk,contains(isNot('Cuti PPSU')));
  expect(pjlp,contains('Absensi dan Kinerja PJLP'));
  expect(pjlp,contains('Cuti PPSU'));
 });
 testWidgets('PPPK attendance screen uses a separate identity',(tester)async{
  await tester.pumpWidget(MaterialApp(home:Scaffold(
   body:CikokoPppkAttendancePage(api:_PppkFakeApi()))));
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('pppk_attendance_screen')),findsOneWidget);
  expect(find.text('Kehadiran PPPK'),findsOneWidget);
  expect(find.text('Absen masuk'),findsOneWidget);
 });
 testWidgets('PPPK leave refuses submission until admin configuration',(tester)async{
  await tester.pumpWidget(MaterialApp(home:Scaffold(
   body:CikokoPppkLeavePage(api:_PppkFakeApi()))));
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('pppk_leave_screen')),findsOneWidget);
  expect(find.text('Cuti PPPK'),findsOneWidget);
  expect(find.textContaining('belum ditetapkan admin'),findsOneWidget);
 });
}
