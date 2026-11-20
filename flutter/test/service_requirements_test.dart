import 'package:flutter_test/flutter_test.dart';
import 'package:cikoko/service_requirements.dart';

void main() {
  test('Kunci katalog API dan CMS sama dengan website', () {
    expect(cikokoServiceRequirementKey({'id': 'ptsp'}), 'api:ptsp');
    expect(cikokoServiceRequirementKey({'id': 'cms:service-1'}),
        'cms:service-1');
    expect(cikokoServiceRequirementKey({'id': '../bad'}), isNull);
  });

  test('Tampilkan hanya tautan HTTPS yang aman untuk layanan terpilih', () {
    final data = <String, dynamic>{
      'items': {
        'api:ptsp': [
          {'title': 'Surat Usaha', 'url': 'https://example.org/syarat'},
          {'title': 'Tidak aman', 'url': 'javascript:alert(1)'},
          {'title': 'Tidak aman', 'url': 'https://user:pass@example.org'},
        ],
        'api:sosial': [
          {'title': 'SKTM', 'url': 'https://example.org/sktm'}
        ],
      },
    };
    final ptsp = cikokoPublishedRequirements(data, {'id': 'ptsp'});
    expect(ptsp.length, 1);
    expect(ptsp.single['title'], 'Surat Usaha');
    expect(cikokoPublishedRequirements(data, {'id': 'sosial'}).length, 1);
  });

  test('CMS website dijadikan kartu layanan aplikasi', () {
    final cms = cikokoPublishedCmsServices({
      'cms_services': [
        {'id': 'cms:service-1', 'title': 'Surat Keterangan',
         'description': 'Daftar surat', 'url': 'https://datawebs.my.id/berita/service-1'},
        {'id': 'api:ptsp', 'title': 'Kunci salah', 'url': 'https://example.org'},
      ],
    });
    expect(cms.length, 1);
    expect(cms.first['id'], 'cms:service-1');
  });
}
