import 'package:flutter_test/flutter_test.dart';
import 'package:cikoko/cikoko_jumantik_mandiri_2607.dart';

void main() {
  test('Jumantik Mandiri is available to signed-in non-Admin roles', () {
    expect(CikokoJumantikMandiri2607.eligible('warga'), isTrue);
    expect(CikokoJumantikMandiri2607.eligible('jumantik_rt'), isTrue);
    expect(CikokoJumantikMandiri2607.eligible('jumantik_rw'), isTrue);
    expect(CikokoJumantikMandiri2607.eligible('pppk'), isTrue);
    expect(CikokoJumantikMandiri2607.eligible('pjlp'), isTrue);
    expect(CikokoJumantikMandiri2607.eligible('rt'), isTrue);
    expect(CikokoJumantikMandiri2607.eligible('rw'), isTrue);
    expect(CikokoJumantikMandiri2607.eligible('admin'), isFalse);
    expect(CikokoJumantikMandiri2607.eligible('admin_kelurahan'), isFalse);
    expect(CikokoJumantikMandiri2607.eligible('guest'), isFalse);
  });

  test('All 12 requested Yes/No choices are present and unique', () {
    expect(CikokoJumantikMandiri2607.questions.length, 12);
    expect(CikokoJumantikMandiri2607.questions.keys.toSet().length, 12);
    expect(CikokoJumantikMandiri2607.questions['bak_mandi'], 'BAK MANDI');
    expect(CikokoJumantikMandiri2607.questions['toren_air'], 'TOREN AIR');
    expect(CikokoJumantikMandiri2607.questions['tempat_minum_hewan'], 'TEMPAT MINUM HEWAN');
    expect(CikokoJumantikMandiri2607.questions['mendaur_ulang_barang_bekas'],
      'MENDAUR ULANG BARANG BEKAS YANG BISA MENAMPUNG AIR');
  });

  test('Reporter and public news use separate endpoints', () {
    expect(CikokoJumantikMandiri2607.url('mine').toString(),
      contains('jumantik_mandiri_2607.php?action=mine'));
    expect(CikokoJumantikMandiri2607.url('news').toString(),
      contains('jumantik_mandiri_2607.php?action=news'));
  });
}
