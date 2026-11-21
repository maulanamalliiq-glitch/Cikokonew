import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cikoko/cikoko_bank_sampah_personal_2618.dart';

void main() {
  final data=<String,dynamic>{
    'ok':true,'year':2026,
    'items':[
      {'session_date':'2026-11-15','item_name':'Kardus',
       'weight_kg':'2.500','amount_rp':7500,'source':'arsip_2026'},
      {'session_date':'2026-11-15','item_name':'Botol Plastik',
       'weight_kg':'1.000','amount_rp':5000,'source':'arsip_2026'},
      {'session_date':'2026-06-07','item_name':'Besi',
       'weight_kg':'3.000','amount_rp':15000,'source':'aplikasi'},
    ],
  };

  testWidgets('Personal bank details show barang, Kg, Rp and totals per date',
    (tester)async {
      await tester.binding.setSurfaceSize(const Size(390,1400));
      addTearDown(()=>tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(MaterialApp(home:Scaffold(body:
        SingleChildScrollView(child:BankSampahPersonalDetails2618(
          year:2026,data:data,
        )),
      )));
      await tester.pumpAndSettle();
      expect(tester.takeException(),isNull);
      expect(find.text('Rincian Penimbangan Saya'),findsOneWidget);
      expect(find.text('Kardus'),findsOneWidget);
      expect(find.text('Botol Plastik'),findsOneWidget);
      expect(find.text('Besi'),findsOneWidget);
      expect(find.text('15 November 2026'),findsOneWidget);
      expect(find.text('7 Juni 2026'),findsOneWidget);
      expect(find.text('Rp 7.500'),findsOneWidget);
      expect(find.text('Rp 5.000'),findsOneWidget);
      expect(find.text('Rp 15.000'),findsOneWidget);
      expect(find.text('6.5 Kg  |  Rp 27.500'),findsOneWidget);
      expect(find.text('3 rincian barang'),findsOneWidget);
      expect(find.byKey(const Key('bank_sampah_date_2026-11-15_2618')),
        findsOneWidget);
    });

  testWidgets('Month selection filters own item details without changing year',
    (tester)async {
      await tester.binding.setSurfaceSize(const Size(390,1100));
      addTearDown(()=>tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(MaterialApp(home:Scaffold(body:
        SingleChildScrollView(child:BankSampahPersonalDetails2618(
          year:2026,data:data,
        )),
      )));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Semua Bulan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Juni').last);
      await tester.pumpAndSettle();
      expect(find.text('Besi'),findsOneWidget);
      expect(find.text('Kardus'),findsNothing);
      expect(find.text('Botol Plastik'),findsNothing);
      expect(find.text('3 Kg  |  Rp 15.000'),findsOneWidget);
      expect(find.text('1 rincian barang'),findsOneWidget);
    });

  testWidgets('No entries show a clear empty statement', (tester)async{
    await tester.binding.setSurfaceSize(const Size(390,900));
    addTearDown(()=>tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(home:Scaffold(body:
      SingleChildScrollView(child:BankSampahPersonalDetails2618(
        year:2027,data:const {'ok':true,'items':[]},
      )),
    )));
    await tester.pumpAndSettle();
    expect(find.text('Belum ada rincian penimbangan pada periode ini.'),
      findsOneWidget);
    expect(find.text('0 rincian barang'),findsOneWidget);
  });
}
