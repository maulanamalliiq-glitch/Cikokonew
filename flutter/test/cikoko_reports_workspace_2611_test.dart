import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cikoko/role_catalog.dart';
import 'package:cikoko/cikoko_reports_workspace_2611.dart';

void main() {
  test('Only reports already allowed by role modules are displayed', () {
    final routes=cikokoReportsForModules2611([
      roleFeatures['bank_sampah']!,
      roleFeatures['jumantik']!,
      roleFeatures['news']!,
      roleFeatures['verify']!,
      roleFeatures['bank_sampah']!,
      roleFeatures['monitor']!,
    ]).map((e)=>e.route).toList();
    expect(routes,contains('Bank Sampah Cikoko'));
    expect(routes,contains('Jumantik Mandiri'));
    expect(routes,contains('Verifikasi Laporan'));
    expect(routes.where((e)=>e=='Bank Sampah Cikoko').length,1);
    expect(routes,isNot(contains('Berita & Kegiatan')));
    expect(routes,isNot(contains('Monitoring Wilayah')));
    final citizen=cikokoReportsForModules2611([
      roleFeatures['jumantik']!,roleFeatures['history']!,roleFeatures['news']!,
    ]).map((e)=>e.route).toList();
    expect(citizen,containsAll(['Jumantik Mandiri','Riwayat']));
    expect(citizen,isNot(contains('Verifikasi Laporan')));
    expect(citizen,isNot(contains('Bank Sampah Cikoko')));
  });

  testWidgets('Phone opens sidebar from left, selects a live module form',
    (tester) async {
    await tester.binding.setSurfaceSize(const Size(390,820));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(home:CikokoReportsWorkspace2611(
      role:'pjlp',guest:false,
      modules:[roleFeatures['bank_sampah']!,roleFeatures['history']!],
      letterCounts:null,
      navigate:(_){},
      buildReport:(route)=>Center(child:Text('FORM: $route')),
    )));
    expect(find.text('Laporan Cikoko'),findsOneWidget);
    await tester.tap(find.byTooltip('Buka menu laporan di kiri'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('reports_menu_Bank Sampah Cikoko')),findsOneWidget);
    await tester.tap(find.byKey(const Key('reports_menu_Bank Sampah Cikoko')));
    await tester.pumpAndSettle();
    expect(find.text('FORM: Bank Sampah Cikoko'),findsOneWidget);
    await tester.tap(find.byTooltip('Kembali ke daftar laporan'));
    await tester.pumpAndSettle();
    expect(find.text('Pusat Laporan Cikoko'),findsOneWidget);
  });

  testWidgets('Tablet keeps a persistent left sidebar and embedded forms',
    (tester) async {
    await tester.binding.setSurfaceSize(const Size(850,720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(home:CikokoReportsWorkspace2611(
      role:'admin',guest:false,letterCounts:null,
      modules:[roleFeatures['jumantik_review']!,roleFeatures['bank_sampah']!],
      navigate:(_){},
      buildReport:(route)=>Center(child:Text('CONTENT: $route')),
    )));
    expect(find.byKey(const Key('reports_menu_Bank Sampah Cikoko')),findsOneWidget);
    await tester.tap(find.byKey(const Key('reports_menu_Bank Sampah Cikoko')));
    await tester.pumpAndSettle();
    expect(find.text('CONTENT: Bank Sampah Cikoko'),findsOneWidget);
    expect(find.byKey(const Key('reports_menu_Verifikasi Jumantik')),findsOneWidget);
  });
}
