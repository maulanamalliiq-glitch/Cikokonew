import 'package:cikoko/api.dart';
import 'package:cikoko/cikoko_home_extra.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _BoardingApiStub extends CikokoApi {
  @override
  Future<Map<String, dynamic>> call(String action,
      {Map<String, dynamic>? body, bool authorized = false}) async {
    if (action == 'boarding_public') {
      return {
        'ok': true,
        'items': [
          {
            'name': 'Kos Uji Cikoko',
            'rt': '01',
            'rw': '02',
            'total_rooms': 10,
            'available_rooms': 4,
            'photo_url': '',
            'address': '',
            'facilities': <String>[],
            'public_phone': '081234567890',
          }
        ]
      };
    }
    return {'ok': true};
  }
}

void main() {
  testWidgets('Nomor kos tidak ditampilkan kepada pengunjung tanpa login',
      (tester) async {
    final api = _BoardingApiStub();
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: V6BoardingHouseDirectoryPage(api: api))));
    await tester.pumpAndSettle();
    expect(find.text('Kos Uji Cikoko'), findsOneWidget);
    expect(find.text('Hubungi lewat WhatsApp'), findsNothing);
    expect(find.textContaining('081234567890'), findsNothing);
  });

  testWidgets('Tombol WhatsApp kos tampil sesudah login', (tester) async {
    final api = _BoardingApiStub()..token = 'testing-session';
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: V6BoardingHouseDirectoryPage(api: api))));
    await tester.pumpAndSettle();
    expect(find.text('Kos Uji Cikoko'), findsOneWidget);
    expect(find.text('Hubungi lewat WhatsApp'), findsOneWidget);
  });
}
