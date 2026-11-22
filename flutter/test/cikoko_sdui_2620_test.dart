import 'package:cikoko/cikoko_sdui_2620.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('all route wrappers render published title and blocks', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body:
      CikokoUiPageFrame2620(
        pageId: 'Bank Sampah Cikoko',
        loader: (_) async => {
          'title': 'Rekap Bank Sampah Terbaru',
          'accent': '#127542',
          'description': 'Pembaruan dari Admin Utama.',
          'blocks': [
            {'id': 'blk1234', 'type': 'card', 'title': 'Rincian Per Akun',
              'body': 'Data diambil dari API.', 'visible': true},
          ],
        },
        child: const Center(child: Text('Fungsi asli Bank Sampah')),
      ),
    )));
    await tester.pumpAndSettle();
    expect(find.text('Rekap Bank Sampah Terbaru'), findsOneWidget);
    expect(find.text('Rincian Per Akun'), findsOneWidget);
    expect(find.text('Fungsi asli Bank Sampah'), findsOneWidget);
  });

  testWidgets('fallback preserves original native page', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body:
      CikokoUiPageFrame2620(
        pageId: 'Cuti PPPK',
        loader: (_) async => {},
        child: const Center(child: Text('Form Persetujuan Tetap Aman')),
      ),
    )));
    await tester.pumpAndSettle();
    expect(find.text('Form Persetujuan Tetap Aman'), findsOneWidget);
  });

  testWidgets('home reorders published sections and locks Surat status',
      (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: CikokoUiHome2620(
        loader: (_) async => {
          'sections': [
            {'key': 'bank_annual', 'visible': true},
            {'key': 'letters', 'visible': false},
            {'key': 'hero', 'visible': true},
            {'key': 'innovation', 'visible': false},
          ]
        },
        onRefresh: () async {},
        defaultOrder: const ['hero', 'letters', 'bank_annual', 'innovation'],
        childrenByKey: const {
          'hero': SizedBox(height: 35, child: Text('Banner')),
          'letters': SizedBox(height: 35, child: Text('Status Pelayanan Surat')),
          'bank_annual': SizedBox(height: 35, child: Text('Total Tahunan')),
          'innovation': SizedBox(height: 35, child: Text('Inovasi')),
        },
      ),
    )));
    await tester.pumpAndSettle();
    expect(find.text('Status Pelayanan Surat'), findsOneWidget);
    expect(find.text('Inovasi'), findsNothing);
    final bank = tester.getTopLeft(find.byKey(
      const ValueKey('sdui_core_bank_annual')));
    final letters = tester.getTopLeft(find.byKey(
      const ValueKey('sdui_core_letters')));
    final hero = tester.getTopLeft(find.byKey(
      const ValueKey('sdui_core_hero')));
    expect(bank.dy, lessThan(letters.dy));
    expect(letters.dy, lessThan(hero.dy));
  });
}
