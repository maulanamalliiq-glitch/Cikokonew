import 'package:flutter_test/flutter_test.dart';
import 'package:cikoko/cikoko_jumantik_2605.dart';
import 'package:cikoko/role_catalog.dart';
void main(){
 test('Form RT/RW khusus Petugas Jumantik',(){
  expect(Jumantik2605Api.isStaff('jumantik_rt'),isTrue);
  expect(Jumantik2605Api.isStaff('jumantik_rw'),isTrue);
  for(final role in ['admin','admin_kelurahan','warga','pppk','pjlp','rt','rw','fkdm'])
    expect(Jumantik2605Api.isStaff(role),isFalse,reason:role);
 });
 test('Mandiri tidak tersedia untuk Super Admin',(){
  expect(modulesForRole('warga',{}).any((f)=>f.route=='Jumantik Mandiri'),isTrue);
  expect(modulesForRole('admin',{'report:jumantik':true}).any((f)=>f.route=='Jumantik Mandiri'),isFalse);
 });
 test('Role lain tidak bisa membuka formulir RT/RW meski punya izin laporan generik',(){
  for(final role in ['jumantik_rt','jumantik_rw'])
    expect(modulesForRole(role,{}).any((f)=>f.route=='Laporan Jumantik RT/RW'),isTrue);
  for(final role in ['warga','admin','pppk','pjlp','rt','rw'])
    expect(modulesForRole(role,{'report:jumantik':true}).any((f)=>f.route=='Laporan Jumantik RT/RW'),isFalse,reason:role);
 });
}