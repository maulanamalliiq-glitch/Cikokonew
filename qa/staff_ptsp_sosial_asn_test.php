<?php
declare(strict_types=1);
// Offline contract checks: no credentials, login or production data required.
$root=dirname(__DIR__);
$read=static function(string $path)use($root):string{
 $data=@file_get_contents($root.'/'.$path);
 if($data===false)throw new RuntimeException('File tidak ditemukan: '.$path);
 return $data;
};
$expect=static function(bool $condition,string $name):void{
 if(!$condition)throw new RuntimeException('KONTRAK AKUN GAGAL: '.$name);
};
require_once $root.'/cpanel/mobile-api/permissions.php';

$roles=mobile_role_names();
$expect(isset($roles['ptsp']),'Role PTSP tersedia');
$expect(isset($roles['sosial']),'Role SOSIAL tersedia');
$expect(isset($roles['asn']),'Role ASN tersedia');
$expect(in_array('reports:view',mobile_default_permissions('ptsp'),true),'PTSP bisa memeriksa laporan');
$expect(in_array('reports:verify',mobile_default_permissions('ptsp'),true),'PTSP bisa memproses laporan menurut izin server');
$expect(in_array('report:kegiatan',mobile_default_permissions('sosial'),true),'SOSIAL bisa melaporkan kegiatan');
foreach(['reports:view','reports:verify','waris:verify','chat:reply','role:manage','content:create'] as $sensitive){
 $expect(!in_array($sensitive,mobile_default_permissions('sosial'),true),'SOSIAL tidak diberi akses lintas bidang: '.$sensitive);
}
$expect(!in_array('role:manage',mobile_default_permissions('ptsp'),true),'PTSP tidak dapat membuat role');
$expect(!in_array('role:manage',mobile_default_permissions('asn'),true),'ASN tidak dapat mengelola role');

$portal=$read('cpanel/roles-lib.php');
$expect(str_contains($portal,'"sosial"=>"Sosial / Kesejahteraan Rakyat"'),'Admin dapat memilih role SOSIAL');
$api=$read('cpanel/mobile-api/index.php');
$expect(str_contains($api,'$allowed=portal_roles()'),'Pembuatan akun harus menggunakan daftar role resmi');
$expect(str_contains($api,"'sosial'=>['kegiatan']"),'Laporan SOSIAL hanya jenis kegiatan');
$expect(str_contains($api,"if((string)\$u['user_role']!=='admin')"),'Manajemen akun hanya untuk admin utama');
$menus=$read('flutter/lib/role_catalog.dart');
$expect(str_contains($menus,"'sosial':['staff_social_guide'"),'Menu Sosial dipisahkan');
$expect(str_contains($menus,"'ptsp':['staff_ptsp_guide'"),'Menu PTSP dipisahkan');
$expect(str_contains($menus,"'asn':['staff_asn_guide'"),'Panduan ASN tersedia');
$expect(!str_contains($menus,"'sosial':['verify'"),'Role SOSIAL tidak diberi verifikasi seluruh laporan');
$expect(is_file($root.'/flutter/lib/cikoko_staff_guides.dart'),'Panduan alur disediakan dalam aplikasi');

$pppk=$read('cpanel/mobile-api/pppk_staff.php');
$expect(str_contains($pppk,"\$status==='pending_supervisor'&&\$supervisor&&\$uid==="),'Atasan PPPK harus sesuai user ID yang ditetapkan');
$expect(str_contains($pppk,"\$status==='pending_lurah'&&\$lurah"),'Lurah memiliki tahap keputusan akhir');
$pjlp=$read('cpanel/mobile-api/pjlp_leave.php');
$expect(str_contains($pjlp,'// Satu tahap: admin Kelurahan memberi keputusan langsung'),'Cuti PJLP berbeda dari cuti PPPK');
echo "PTSP, SOSIAL, ASN: role, menu, akun dan batas hak akses PASS\n";
