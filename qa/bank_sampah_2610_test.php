<?php
declare(strict_types=1);
/** Static regression and pure schedule checks, without production database access. */
function bank_check(bool $condition,string $why):void {
 if(!$condition)throw new RuntimeException($why);
}
$base=dirname(__DIR__);
$php=file_get_contents($base.'/cpanel/mobile-api/bank_sampah_2610.php');
$sql=file_get_contents($base.'/cpanel/mobile-api/migrate_bank_sampah_2610.sql');
$dart=file_get_contents($base.'/flutter/lib/cikoko_bank_sampah_2610.dart');
$mockup=file_get_contents($base.'/flutter/lib/cikoko_bank_sampah_mockup_2613.dart');
$catalog=file_get_contents($base.'/flutter/lib/role_catalog.dart');
$main=file_get_contents($base.'/flutter/lib/main.dart');
$profile=file_get_contents($base.'/flutter/lib/v211_features.dart');
foreach([$php,$sql,$dart,$mockup,$catalog,$main,$profile] as $src)
  bank_check(is_string($src) && strlen($src)>300,'File modul hilang.');

foreach([
 'mobile_bank_sampah_config_2610','mobile_bank_sampah_members_2610',
 'mobile_bank_sampah_officers_2610','mobile_bank_sampah_sessions_2610',
 'mobile_bank_sampah_entries_2610',
] as $name){
 bank_check(str_contains($sql,"CREATE TABLE IF NOT EXISTS ".$name),'Tabel SQL hilang: '.$name);
 bank_check(str_contains($php,$name),'Tabel API hilang: '.$name);
}
foreach(['session_date','member_user_id','item_name','weight_kg','amount_rp','updated_by','voided_at'] as $column)
  bank_check(str_contains($sql,$column),'Kolom timbang hilang: '.$column);
bank_check(str_contains($php,"['pjlp','pppk']"),'Anggota hanya PJLP/PPPK.');
bank_check(str_contains($php,"in_array((string)$"."actor['user_role'],CKBS_ROLE_MEMBER,true)"),
  'Petugas PJLP/PPPK harus melalui daftar role anggota.');
bank_check(str_contains($php,"$"."allowed=CKBS_ROLE_MEMBER;"),
  'Admin harus dapat menunjuk PPPK dan PJLP sebagai petugas.');
bank_check(str_contains($dart,"u['role'] == 'pjlp' || u['role'] == 'pppk'"),
  'Tombol tunjuk petugas harus tersedia untuk PJLP dan PPPK.');
bank_check(str_contains($php,"count>=5") || str_contains($php,"$"."count>=5"),'Batas petugas lima tidak ada.');
bank_check(str_contains($php,"ckbs_officer("),'Hak input berdasarkan penunjukan petugas hilang.');
bank_check(str_contains($php,"'session_submit'")&&str_contains($php,'status="submitted"'),
  'Hasil timbang harus dapat dikirim petugas untuk pemeriksaan Admin.');
bank_check(str_contains($php,"if($"."status!=='open')"),'Penimbangan tidak boleh dikirim dua kali.');
bank_check(str_contains($php,"Maksimal lima petugas"),'Batas 5 PJLP + PPPK hilang.');
bank_check(str_contains($mockup,'Simpan Draft')&&str_contains($mockup,'Simpan Penimbangan'),
  'Tombol draft/final sesuai mockup hilang.');
bank_check(str_contains($mockup,"widget.request('session_submit'"),
  'Form petugas harus mengirim penimbangan untuk disahkan Admin.');
bank_check(str_contains($php,"status=\"submitted\""),
  'Draft harus beralih ke status menunggu pengesahan.');
bank_check(str_contains($mockup,'if(widget.canManage)...['),
  'Tombol pengesahan Admin hilang.');
bank_check(str_contains($php,"$"."uid,$"."year.'-01-01'"),'Ringkasan profil harus dibatasi akun/tahun.');
bank_check(str_contains($php,"$"."s!=='open'"),'Tidak boleh mengubah sesi yang ditutup.');
bank_check(str_contains($php,"'annual_csv'") && str_contains($php,"'annual'"),'Rekap tahunan belum tersedia.');
bank_check(str_contains($mockup,'Input Bank Sampah') &&
   str_contains($mockup,'Data Penimbangan') &&
   str_contains($mockup,'Kelurahan Cikoko'),
   'Judul dan kartu Data Penimbangan sesuai mockup harus tersedia.');
bank_check(str_contains($mockup,'Hasil Timbangan (Kg)')&&str_contains($mockup,'Jumlah (Rp)'),
  'Kolom input timbangan dan rupiah sesuai foto harus tersedia.');
bank_check(str_contains($dart,'CikokoBankSampahMockup2613('),
  'Halaman Bank Sampah harus menggunakan form mockup baru, bukan tabel statis.');
bank_check(str_contains($mockup,"widget.request('entry_save'"),
  'Simpan Draft harus menyimpan setiap baris ke API.');
bank_check(str_contains($profile,'BankSampahProfileSummary2610'),'Ringkasan di bawah foto profil hilang.');
bank_check(str_contains($main,"case 'Bank Sampah Cikoko'"),'Halaman khusus Bank Sampah hilang.');
foreach(["'admin'","'asn'","'lurah'","'pjlp'","'pppk'"] as $role)
  bank_check(str_contains($catalog,$role),'Role katalog hilang: '.$role);
foreach(["'twice_monthly'","'every_two_months'"] as $cadence)
  bank_check(str_contains($php,$cadence),'Pengaturan jadwal belum lengkap.');

// Check second/fourth Sunday formula for all twelve months of a sample year.
for($month=1;$month<=12;$month++){
  $start=new DateTimeImmutable(sprintf('2027-%02d-01',$month));
  $offset=(7-(int)$start->format('w'))%7;
  foreach([8+$offset,22+$offset] as $day){
    $date=new DateTimeImmutable(sprintf('2027-%02d-%02d',$month,$day));
    bank_check($date->format('w')==='0','Jadwal bukan hari Minggu');
  }
}
bank_check(str_contains($php,'[8+$offset,22+$offset]'),'Harus tepat Minggu ke-2 dan ke-4.');
bank_check(!str_contains($php,'DELETE FROM portal_users') &&
           !str_contains($php,'UPDATE portal_users'), 'Modul Bank Sampah tidak boleh mengubah akun pegawai.');
echo "BANK SAMPAH 2610: schema, permissions, menu, privacy and schedule checks PASSED\n";
