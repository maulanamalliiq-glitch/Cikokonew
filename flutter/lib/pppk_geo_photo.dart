import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image/image.dart' as img;

/// Alamat hasil reverse-geocoding adalah perkiraan; koordinat GPS dan
/// akurasinya tetap dicantumkan bila alamat jalan tidak tersedia.
Future<String> pppkAddressFromCoordinates(double latitude, double longitude) async {
  try {
    final matches = await Geocoding(locale: const Locale('id', 'ID'))
        .placemarkFromCoordinates(latitude, longitude)
        .timeout(const Duration(seconds: 12));
    if (matches.isEmpty) return 'Alamat jalan tidak tersedia dari peta';
    final place = matches.first;
    final parts = <String>[];
    final seen = <String>{};
    for (final item in <String?>[
      place.street,
      place.subLocality,
      place.locality,
      place.subAdministrativeArea,
      place.administrativeArea,
      place.postalCode,
      place.country,
    ]) {
      final value = (item ?? '').trim();
      if (value.isEmpty || !seen.add(value.toLowerCase())) continue;
      parts.add(value);
    }
    if (parts.isEmpty) return 'Alamat jalan tidak tersedia dari peta';
    return parts.join(', ');
  } catch (_) {
    return 'Alamat jalan tidak tersedia dari peta';
  }
}

class PppkStampData {
  const PppkStampData({
    required this.jpegBytes,
    required this.capturedAt,
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.address,
    required this.employeeName,
    required this.membership,
    required this.eventLabel,
  });
  final Uint8List jpegBytes;
  final DateTime capturedAt;
  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final String address;
  final String employeeName;
  final String membership;
  final String eventLabel;
}

String pppkWibDateTime(DateTime date) {
  final wib = date.toUtc().add(const Duration(hours: 7));
  String two(int value) => value.toString().padLeft(2, '0');
  return wib.year.toString() + '-' + two(wib.month) + '-' + two(wib.day) +
      ' ' + two(wib.hour) + ':' + two(wib.minute) + ':' +
      two(wib.second) + ' WIB';
}

List<String> pppkWrapText(String input, int limit) {
  final lines = <String>[];
  for (final paragraph in input.trim().split(RegExp(r'\s*\n\s*'))) {
    var line = '';
    for (final word in paragraph.split(RegExp(r'\s+'))) {
      if (word.isEmpty) continue;
      if (word.length > limit) {
        if (line.isNotEmpty) {
          lines.add(line);
          line = '';
        }
        for (var index = 0; index < word.length; index += limit) {
          final end = index + limit < word.length ? index + limit : word.length;
          lines.add(word.substring(index, end));
        }
        continue;
      }
      if (line.isNotEmpty && line.length + word.length + 1 > limit) {
        lines.add(line);
        line = '';
      }
      line = line.isEmpty ? word : '$line $word';
    }
    if (line.isNotEmpty) lines.add(line);
  }
  return lines;
}

/// Menulis keterangan langsung pada piksel JPEG, bukan hanya metadata EXIF.
/// Tanggal resmi transaksi tetap bersumber dari waktu server pada API PPPK.
Uint8List pppkStampPhoto(PppkStampData data) {
  final decoded = img.decodeImage(data.jpegBytes);
  if (decoded == null) throw StateError('Foto kamera tidak dapat dibaca.');
  final image = img.bakeOrientation(decoded);
  if (image.width < 360 || image.height < 360) {
    throw StateError('Resolusi foto terlalu kecil untuk keterangan lokasi.');
  }

  final useSmall = image.width < 850;
  final font = useSmall ? img.arial14 : img.arial24;
  final lineHeight = useSmall ? 21 : 32;
  final maxCharacters = ((image.width - 28) ~/ (useSmall ? 9 : 15)).clamp(18, 90);
  final lines = <String>[
    'CIKOKO SMART | ' + data.eventLabel,
    'Nama: ' + data.employeeName.trim(),
    'Keanggotaan: ' + data.membership.trim(),
    'Tanggal/Jam: ' + pppkWibDateTime(data.capturedAt),
    'GPS: ' + data.latitude.toStringAsFixed(6) + ', ' +
        data.longitude.toStringAsFixed(6) + ' | Akurasi +/- ' +
        data.accuracyMeters.toStringAsFixed(0) + ' m',
    ...pppkWrapText('Alamat (perkiraan): ' + data.address, maxCharacters),
  ];

  final maxLines = ((image.height - 16) ~/ lineHeight) - 1;
  if (lines.length > maxLines) {
    throw StateError('Alamat terlalu panjang untuk dicetak pada foto.');
  }
  final top = image.height - (lines.length * lineHeight + 20);
  img.fillRect(image,
      x1: 0,
      y1: top,
      x2: image.width - 1,
      y2: image.height - 1,
      color: img.ColorRgba8(5, 22, 48, 225));
  for (var index = 0; index < lines.length; index++) {
    img.drawString(image, lines[index],
        font: font,
        x: 12,
        y: top + 9 + index * lineHeight,
        color: img.ColorRgb8(255, 255, 255));
  }

  for (final quality in <int>[84, 72, 60, 48]) {
    final jpeg = Uint8List.fromList(img.encodeJpg(image, quality: quality));
    if (jpeg.length <= 1900000) return jpeg;
  }
  throw StateError('Foto terlalu besar setelah penambahan keterangan. Ambil ulang.');
}
