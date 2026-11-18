import 'package:flutter_test/flutter_test.dart';
import 'package:cikoko/role_catalog.dart';

void main() {
 test('Seluruh role memiliki menu utama', () {
   for (final role in roleNames.keys) {
     expect(roleMenus.containsKey(role),isTrue,reason:role);
     expect(roleMenus[role],isNotEmpty);
   }
 });
 test('PTSP, Sosial dan ASN mempunyai menu sendiri tanpa eskalasi administrasi', () {
   for(final role in ['ptsp','sosial','asn']){
     expect(roleNames.containsKey(role),isTrue);
     expect(roleMenus[role],isNotEmpty);
   }
   final ptsp=modulesForRole('ptsp',{'reports:view':true,'archive:view':true});
   expect(ptsp.any((f)=>f.route=='Alur PTSP'),isTrue);
   expect(ptsp.any((f)=>f.route=='Verifikasi Laporan'),isTrue);
   expect(ptsp.any((f)=>!f.connected),isFalse);
   final sosial=modulesForRole('sosial',{'report:kegiatan':true});
   expect(sosial.any((f)=>f.route=='Alur Sosial'),isTrue);
   expect(sosial.any((f)=>f.route=='Laporan Kegiatan'),isTrue);
   expect(sosial.any((f)=>f.route=='Verifikasi Laporan'),isFalse);
   expect(sosial.any((f)=>f.route=='Kelola Akun Petugas'),isFalse);
   expect(modulesForRole('asn',{}).any((f)=>f.route=='Alur Kerja ASN'),isTrue);
 });
 test('Super Admin chat role toggle changes PTSP and Social menus', () {
   for(final role in ['ptsp','sosial']){
     final off=modulesForRole(role,{'chat:reply':false,'report:kegiatan':true});
     expect(off.any((f)=>f.route=='Pesan Masuk'),isFalse,reason:role);
     final on=modulesForRole(role,{'chat:reply':true,'report:kegiatan':true});
     expect(on.any((f)=>f.route=='Pesan Masuk'),isTrue,reason:role);
     expect(on.where((f)=>f.route=='Pesan Masuk').length,1,reason:role);
   }
 });
 test('Role permission toggles reveal and hide newly granted reporting', () {
   final off=modulesForRole('sosial',{'report:kegiatan':false});
   expect(off.any((f)=>f.route=='Laporan Kegiatan'),isFalse);
   final on=modulesForRole('sosial',{'report:kegiatan':true,'reports:view':true});
   expect(on.any((f)=>f.route=='Laporan Kegiatan'),isTrue);
   expect(on.any((f)=>f.route=='Verifikasi Laporan'),isTrue);
 });
 test('Warga tidak melihat menu verifikasi dan administrasi', () {
   final caps={'waris:create':true,'report:jumantik':true};
   final modules=modulesForRole('warga',caps);
   expect(modules.any((f)=>f.route=='Surat Ahli Waris'),isTrue);
   expect(modules.any((f)=>f.route=='Verifikasi Laporan'),isFalse);
   expect(modules.any((f)=>f.route=='Tambah Berita'),isFalse);
 });
 test('Izin kosong menyembunyikan menu sensitif', () {
   final modules=modulesForRole('admin_kelurahan',{});
   expect(modules.any((f)=>f.route=='Tambah Arsip Ahli Waris'),isFalse);
   expect(modules.any((f)=>f.route=='Pesan Masuk'),isFalse);
 });
 test('Admin Utama mendapat pengelolaan hak akses', () {
   final modules=modulesForRole('admin',{'role:manage':true});
   expect(modules.any((f)=>f.route=='Hak Akses Role'),isTrue);
 });
}
