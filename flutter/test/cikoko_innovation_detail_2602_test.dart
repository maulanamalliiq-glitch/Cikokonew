import 'package:flutter_test/flutter_test.dart';
import 'package:cikoko/cikoko_innovation_detail.dart';

void main() {
  test('Lima foto maksimum, validasi path, dan fallback foto lama', () {
    final photos = cikokoInnovationPhotos({
      'images': [
        for (var i = 1; i <= 7; i++) 'assets/images/inovasi-' + i.toString() + '.jpg',
        '../private/photo.jpg'
      ],
    });
    expect(photos.length, 5);
    expect(photos.last, 'assets/images/inovasi-5.jpg');
    expect(cikokoInnovationPhotos({'image':'assets/images/old.webp'}),
      ['assets/images/old.webp']);
    expect(cikokoInnovationPhotos({'image':'../../file.png'}), isEmpty);
  });

  test('Nomor WhatsApp benar dan tidak menerima alamat palsu', () {
    expect(cikokoInnovationWhatsapp({'whatsapp':'081234567890'}),
      '6281234567890');
    expect(cikokoInnovationWhatsapp({'whatsapp':'6281234567890'}),
      '6281234567890');
    expect(cikokoInnovationWhatsapp({'whatsapp':'abc'}), '');
  });
}
