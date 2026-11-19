import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:cikoko/pppk_geo_photo.dart';

void main() {
  test('waktu foto selalu ditampilkan dalam WIB', () {
    expect(
      pppkWibDateTime(DateTime.utc(2026, 11, 18, 23, 45, 6)),
      '2026-11-19 06:45:06 WIB',
    );
  });

  test('alamat panjang tetap dipecah tanpa membuang kata', () {
    const address =
        'Jalan Raya Pancoran Kelurahan Cikoko Kecamatan Pancoran Jakarta Selatan Indonesia';
    final lines = pppkWrapText(address, 22);
    expect(lines.length, greaterThan(2));
    expect(lines.join(' '), address);
    for (final line in lines) {
      expect(line.length, lessThanOrEqualTo(22));
    }
  });

  test('foto JPEG mendapat panel keterangan pada pikselnya', () {
    final source = img.Image(width: 900, height: 1000);
    img.fillRect(source,
      x1: 0, y1: 0, x2: 899, y2: 999,
      color: img.ColorRgb8(242, 242, 242));
    final original = Uint8List.fromList(img.encodeJpg(source, quality: 75));
    final output = pppkStampPhoto(PppkStampData(
      jpegBytes: original,
      capturedAt: DateTime.utc(2026, 11, 18, 23, 45, 6),
      latitude: -6.242000,
      longitude: 106.825000,
      accuracyMeters: 12,
      address: 'Kelurahan Cikoko, Pancoran, Jakarta Selatan',
      employeeName: 'Pegawai PPPK Uji',
      membership: 'PPPK - Kelurahan Cikoko',
      eventLabel: 'ABSEN MASUK',
    ));
    expect(output.length, lessThan(2000000));
    expect(output[0], 0xff);
    expect(output[1], 0xd8);
    final marked = img.decodeJpg(output)!;
    expect(marked.width, 900);
    expect(marked.getPixel(10, 990).r, lessThan(110));
    expect(marked.getPixel(10, 10).r, greaterThan(200));
  });
}
