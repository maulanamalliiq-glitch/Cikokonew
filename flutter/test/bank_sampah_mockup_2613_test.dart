import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cikoko/cikoko_bank_sampah_mockup_2613.dart';

void main() {
  final session=<String,dynamic>{
    'id':7,'session_date':'2026-11-15','status':'open'
  };
  final members=<Map<String,dynamic>>[
    {'id':'pjlp-1','name':'AAN SUBHAN','active':true,'is_member':true,
      'role':'pjlp'},
    {'id':'pppk-2','name':'ABDUL ROHMAN','active':true,'is_member':true,
      'role':'pppk'},
  ];

  testWidgets('Approved mockup renders Cikoko header, live totals and native entry controls',
    (tester) async {
    // Typical 390dp Android layout: the five-column form must remain usable.
    await tester.binding.setSurfaceSize(const Size(390,1400));
    addTearDown(()=>tester.binding.setSurfaceSize(null));
    final requests=<Map<String,dynamic>>[];
    final notifications=<String>[];
    await tester.pumpWidget(MaterialApp(home:Scaffold(body:
      SingleChildScrollView(child:CikokoBankSampahMockup2613(
        session:session,entries:const [],members:members,
        availableSessions:[session],onSelectSession:(_){},
        officerName:'PETUGAS PPPK',canInput:true,canManage:false,
        request:(action,body) async {
          requests.add({'action':action,...body});
          return {'ok':true,'id':88,'message':'Berhasil'};
        },
        reload:() async {},
        notify:notifications.add,
      )),
    )));
    expect(tester.takeException(),isNull);
    expect(find.text('Cikoko Smart'),findsOneWidget);
    expect(find.text('Input Bank Sampah'),findsOneWidget);
    expect(find.text('Data Penimbangan'),findsOneWidget);
    expect(find.byKey(const Key('bank_table_compact_header_2614')),findsOneWidget);
    expect(find.byKey(const Key('bank_member_row_2614_0')),findsOneWidget);
    expect(find.text('15 November 2026'),findsOneWidget);
    expect(find.text('PETUGAS PPPK'),findsOneWidget);
    expect(find.text('0 Kg'),findsOneWidget);
    expect(find.text('Rp 0'),findsOneWidget);
    // Nama semua PJLP/PPPK aktif tersedia otomatis, bukan diinput manual.
    expect(find.text('AAN SUBHAN'),findsOneWidget);
    expect(find.text('ABDUL ROHMAN'),findsOneWidget);
    expect(find.byType(TextField),findsNWidgets(6));
    expect(find.byKey(const Key('bank_sampah_add_row_2613')),findsOneWidget);
    expect(find.byKey(const Key('bank_sampah_save_draft_2613')),findsOneWidget);
    expect(find.byKey(const Key('bank_sampah_submit_2613')),findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('bank_sampah_add_row_2613')));
    await tester.tap(find.byKey(const Key('bank_sampah_add_row_2613')));
    await tester.pumpAndSettle();
    expect(find.byType(TextField),findsNWidgets(9));
    await tester.enterText(find.byType(TextField).at(0),'Kardus');
    await tester.enterText(find.byType(TextField).at(1),'2.5');
    await tester.enterText(find.byType(TextField).at(2),'3000');
    await tester.pumpAndSettle();
    expect(find.text('2.5 Kg'),findsOneWidget);
    expect(find.text('Rp 3.000'),findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('bank_sampah_save_draft_2613')));
    await tester.tap(find.byKey(const Key('bank_sampah_save_draft_2613')));
    await tester.pumpAndSettle();
    expect(requests.length,1);
    expect(requests.first['action'],'entry_save');
    expect(requests.first['member_user_id'],'pjlp-1');
    expect(requests.first['item_name'],'Kardus');
    expect(requests.first['weight_kg'],'2.5');
    expect(requests.first['amount_rp'],3000);
    expect(notifications.any((x)=>x.contains('Draft tersimpan')),isTrue);
  });

  testWidgets('Weekday reflects a chosen non-Sunday weighing date', (tester)async{
    await tester.binding.setSurfaceSize(const Size(390,950));
    addTearDown(()=>tester.binding.setSurfaceSize(null));
    const monday='2026-03-02';
    final chosen=<String,dynamic>{
      'id':12,'session_date':monday,'status':'closed',
    };
    await tester.pumpWidget(MaterialApp(home:Scaffold(
      body:SingleChildScrollView(child:CikokoBankSampahMockup2613(
        session:chosen,availableSessions:[chosen],
        entries:const [],members:members,
        officerName:'Petugas PJLP',canInput:false,canManage:false,
        onSelectSession:(_){},request:(a,b)async=>{},
        reload:()async{},notify:(_){},
      )),
    )));
    expect(find.text('Senin'),findsOneWidget);
    expect(find.text('2 Maret 2026'),findsOneWidget);
  });

  testWidgets('Non-officers can see mockup totals but cannot modify any entry',
    (tester) async {
    await tester.binding.setSurfaceSize(const Size(440,900));
    addTearDown(()=>tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(home:Scaffold(body:SingleChildScrollView(
      child:CikokoBankSampahMockup2613(
        session:{...session,'status':'closed'},
        entries:[{
          'id':1,'member_user_id':'pppk-2','member_name':'ABDUL ROHMAN',
          'item_name':'Kertas','weight_kg':'4.000','amount_rp':12000
        }],
        members:members,availableSessions:[session],onSelectSession:(_){},
        officerName:'Petugas Bank Sampah',
        canInput:false,canManage:false,
        request:(action,body)async=>throw StateError('Read-only UI must not call server'),
        reload:() async {},notify:(_){},
      ),
    ))));
    expect(find.text('4 Kg'),findsOneWidget);
    expect(find.text('Rp 12.000'),findsOneWidget);
    expect(find.text('Disahkan Admin'),findsOneWidget);
    expect(find.byKey(const Key('bank_sampah_add_row_2613')),findsNothing);
    expect(find.byKey(const Key('bank_sampah_save_draft_2613')),findsNothing);
    expect(find.byKey(const Key('bank_sampah_submit_2613')),findsNothing);
  });
}
