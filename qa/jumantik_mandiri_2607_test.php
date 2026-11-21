<?php
declare(strict_types=1);
function ck_assert(bool $ok,string $message):void {
  if(!$ok)throw new RuntimeException($message);
}
function db_read(string $kind):array {
  if($kind!=='portal_users')throw new RuntimeException('Unexpected read');
  return [
    ['id'=>'warga_test','role'=>'warga','active'=>true],
    ['id'=>'petugas_test','role'=>'pppk','active'=>true],
    ['id'=>'nonaktif','role'=>'warga','active'=>false],
  ];
}
require __DIR__.'/../cpanel/mobile-api/notification_recipients.php';
$public=mobile_notification_recipients('jumantik_mandiri_terbaru','public',null);
$recipients=array_column($public,'recipient');
sort($recipients);
ck_assert($recipients===['admin','petugas_test','warga_test'],
  'Published Mandiri news must notify active accounts and admin');
$notPublic=mobile_notification_recipients('jumantik_mandiri_status','personal','warga_test');
ck_assert(count($notPublic)===1 && $notPublic[0]['recipient']==='warga_test',
  'Private status cannot notify other users');
$forbidden=mobile_notification_recipients('jumantik_mandiri_status','public',null);
ck_assert(count($forbidden)===1 && $forbidden[0]['audience']==='public',
  'Private event category must never fan out to all accounts');

$api=file_get_contents(__DIR__.'/../cpanel/mobile-api/jumantik_mandiri_2607.php');
$sql=file_get_contents(__DIR__.'/../cpanel/mobile-api/migrate_jumantik_mandiri_2607.sql');
$flutter=file_get_contents(__DIR__.'/../flutter/lib/cikoko_jumantik_mandiri_2607.dart');
ck_assert(is_string($api)&&is_string($sql)&&is_string($flutter),'Required source missing');
preg_match('/const CKJM_CHECKS = \\[(.*?)\\];/s',$api,$match);
preg_match_all("/'([a-z_]+)'/",(string)($match[1]??''),$tokens);
$keys=$tokens[1]??[];
$required=[
 'bak_mandi','tatakan_dispenser','toren_air','tatakan_pot_bunga',
 'tampungan_pembuangan_air_ac','penampungan_sisa_air_kulkas',
 'genangan_air_sekitar_rumah','genangan_air_barang_bekas',
 'tempat_minum_hewan','menguras_membersihkan_tampungan_air',
 'menutup_tempat_tampung_air','mendaur_ulang_barang_bekas'
];
ck_assert($keys===$required,'All twelve checks must remain in order');
foreach($required as $key)ck_assert(str_contains($flutter,"'".$key."'"),'Flutter field missing: '.$key);
foreach(['nama_kepala_keluarga','nama_pengirim','no_handphone','alamat','checks_json','kegiatan','photo_name','status','reviewed_by'] as $col)
  ck_assert(str_contains($sql,$col),'Missing SQL column: '.$col);
ck_assert(str_contains($api,'WHERE id=? AND status="pending"'),
  'Review action must be single-transition/atomic');
ck_assert(str_contains($api,"ckjm_nonadmin(\$actor);"),
  'Citizen role guard missing');
ck_assert(str_contains($api,"ckjm_admin(\$actor);"),
  'Admin verification role guard missing');
ck_assert(str_contains($api,"if(\$private){"),'Public/private data separation missing');
echo "Jumantik Mandiri 2607 checks and notification recipients OK\n";
