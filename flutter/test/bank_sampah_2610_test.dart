import 'package:flutter_test/flutter_test.dart';
import 'package:cikoko/cikoko_bank_sampah_2610.dart';

void main() {
  test('Bank Sampah only exposes staff/Admin role catalog', () {
    expect(CikokoBankSampahApi2610.supportedRoles,
      containsAll(['pjlp','pppk','asn','lurah','admin','admin_kelurahan']));
    expect(CikokoBankSampahApi2610.supportedRoles, isNot(contains('warga')));
    expect(CikokoBankSampahApi2610.supportedRoles, isNot(contains('guest')));
  });

  test('Kg and Rp captions use readable local units, not placeholder totals', () {
    expect(CikokoBankSampahApi2610.kilos('324.000'), '324');
    expect(CikokoBankSampahApi2610.kilos('1.250'), '1.25');
    expect(CikokoBankSampahApi2610.money(231000), '231.000');
    expect(CikokoBankSampahApi2610.heading({
      'weight_kg':'324.000','amount_rp':231000
    }), '324 Kg   |   Rp 231.000,-');
  });

  test('The Bank Sampah API is isolated from the existing main API', () {
    expect(CikokoBankSampahApi2610.url('summary').toString(),
      contains('bank_sampah_2610.php?action=summary'));
    expect(CikokoBankSampahApi2610.url('annual').toString(),
      contains('bank_sampah_2610.php?action=annual'));
  });
}
