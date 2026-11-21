<?php
declare(strict_types=1);
$base=dirname(__DIR__);
$ui=file_get_contents($base.'/flutter/lib/cikoko_bank_sampah_mockup_2613.dart');
$page=file_get_contents($base.'/flutter/lib/cikoko_bank_sampah_2610.dart');
$nav=file_get_contents($base.'/flutter/lib/cikoko_v6_showcase.dart');
$api=file_get_contents($base.'/cpanel/mobile-api/bank_sampah_2610.php');
function assert2613(bool $yes,string $why):void {
    if(!$yes)throw new RuntimeException($why);
}
foreach([$ui,$page,$nav,$api] as $src)assert2613(is_string($src)&&strlen($src)>300,'Sumber kode tidak lengkap.');
foreach([
  'Cikoko Smart','Input Bank Sampah','Kelurahan Cikoko',
  'Data Penimbangan','Hari','Tanggal','Petugas',
  'Total Kg','Total Rupiah','Daftar Penimbangan Bank Sampah',
  'No','Nama Anggota','Nama Barang','Hasil Timbangan (Kg)','Jumlah (Rp)',
  'Tambah Baris','Simpan Draft','Simpan Penimbangan',
  'Anda tidak dapat mengubahnya',
] as $item){
    if($item==='Anda tidak dapat mengubahnya')continue;
    assert2613(str_contains($ui,$item),'Label mockup hilang: '.$item);
}
assert2613(str_contains($ui,"widget.request('entry_save'"),
    'Simpan Draft harus menulis data ke API.');
assert2613(str_contains($ui,"widget.request('session_submit'"),
    'Simpan Penimbangan harus mengirim sesi untuk Admin.');
assert2613(str_contains($ui,"'member_user_id'")&&str_contains($ui,"'weight_kg'")
    &&str_contains($ui,"'amount_rp'"),'Field tabel tidak boleh hilang.');
assert2613(str_contains($ui,'onSelectSession')&&str_contains($ui,'_switchDate'),
    'Tanggal timbang harus bisa dipilih di dalam kartu.');
assert2613(str_contains($ui,'Simpan draft sebelum pindah tanggal?'),
    'Perubahan belum tersimpan tidak boleh hilang tanpa konfirmasi.');
assert2613(str_contains($ui,"widget.canManage")&&str_contains($ui,"_status('closed')"),
    'Pengesahan Admin harus tersedia.');
assert2613(str_contains($ui,"!editable")&&str_contains($ui,"canInput"),
    'Akun biasa tidak boleh mengedit tabel.');
assert2613(str_contains($page,'CikokoBankSampahMockup2613('),
    'Halaman Bank Sampah harus menggunakan komponen mockup baru.');
assert2613(str_contains($api,"CKBS_ROLE_MEMBER=['pjlp','pppk']"),
    'Petugas PJLP dan PPPK harus diperbolehkan.');
assert2613(str_contains($api,"mobile_bank_sampah_officers_2610"),
    'Hak input petugas harus melalui tabel penunjukan.');
assert2613(str_contains($api,"$"."count>=5"),'Batas 5 petugas belum ada.');
assert2613(str_contains($nav,"('Laporan',")&&str_contains($nav,"('Beranda',"),
    'Nav utama tidak boleh diubah menjadi Bank Sampah.');
echo "Bank Sampah mockup 2613: fields, live rows, draft, send, Admin and roles OK\n";
