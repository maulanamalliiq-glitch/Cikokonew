import 'package:flutter_test/flutter_test.dart';
import 'package:cikoko/push.dart';
void main(){
 test('chat notification opens a conversation directly',(){
  expect(destinationForPushCategory('chat',isStaff:false),'Hubungi Kami');
  expect(destinationForPushCategory('chat',isStaff:true),'Pesan Masuk');
 });
 test('letter update navigates to user tracking',(){
  expect(destinationForPushCategory('surat',isStaff:false),'Riwayat');
  expect(destinationForPushCategory('progres_surat',isStaff:true),'Verifikasi Laporan');
  expect(destinationForPushCategory('pengumuman',isStaff:false),'Berita & Kegiatan');
  expect(destinationForPushCategory('berita',isStaff:true),'Berita & Kegiatan');
  expect(destinationForPushCategory('inovasi',isStaff:false),'Inovasi');
  expect(destinationForPushCategory('info_aplikasi',isStaff:false),'Notifikasi');
 });
 test('read flags use the same rule for bell, list and polling',(){
  expect(cikokoNotificationIsRead(true),isTrue);
  expect(cikokoNotificationIsRead(1),isTrue);
  expect(cikokoNotificationIsRead('1'),isTrue);
  expect(cikokoNotificationIsRead('true'),isTrue);
  expect(cikokoNotificationIsRead(0),isFalse);
  expect(cikokoNotificationIsRead(false),isFalse);
  expect(cikokoNotificationIsRead(null),isFalse);
 });
}
