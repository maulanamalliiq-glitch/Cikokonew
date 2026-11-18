<?php
declare(strict_types=1);
// Offline access policy checks. Production MySQL and sessions tested separately.
$root=dirname(__DIR__);
require_once $root.'/cpanel/mobile-api/permissions.php';
$assert=static function(bool $ok,string $msg):void{
 if(!$ok)throw new RuntimeException('HAK AKSES GAGAL: '.$msg);
};
$keys=mobile_permission_keys();
$assert(in_array('chat:reply',$keys,true),'Izin balas chat resmi');
$assert(in_array('reports:view',$keys,true),'Izin lihat laporan');
$assert(in_array('reports:verify',$keys,true),'Izin verifikasi laporan');
$assert(in_array('role:manage',mobile_default_permissions('admin'),true),'Role manage Admin');
foreach(['asn','ptsp','sosial','admin_kelurahan','pppk','pjlp'] as $role)
 $assert(!in_array('role:manage',mobile_default_permissions($role),true),'Petugas tidak boleh mengubah izin: '.$role);
$api=file_get_contents($root.'/cpanel/mobile-api/index.php');
$assert(str_contains($api,"mobile_need(\$u,'report:'.\$kind)"),'Izin pelaporan diperiksa server');
$assert(!str_contains($api,'$roleKinds=['),'Tidak ada daftar role statis yang menolak grant baru');
$chat=file_get_contents($root.'/cpanel/mobile-api/chat_offline_bot_2545.php');
$assert(str_contains($chat,"mobile_can(\$user,'chat:reply')"),'Penugasan chat mengikuti izin server');
$assert(!str_contains($chat,"in_array(\$role,['admin','admin_kelurahan','asn']"),'Chat tidak boleh dibatasi ke role bawaan saja');
$client=file_get_contents($root.'/flutter/lib/role_catalog.dart');
$assert(str_contains($client,"'chat:reply':['chat_admin']"),'Menu chat berasal dari izin server');
$assert(str_contains($client,'capabilityMenuBindings'),'Menu tambahan dapat diaktifkan role lain');
echo "Super Admin access 2580: server-backed role grants and chat routing PASS\n";
