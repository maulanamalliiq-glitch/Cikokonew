<?php
declare(strict_types=1);

/**
 * Cikoko Smart 2620 — shared, allow-listed mobile UI layout schema.
 *
 * IMPORTANT: A layout is presentation data, never PHP/HTML/JS/Dart code.
 * Permissions, form validations, fixed navigation and existing data queries
 * remain implemented in the native Flutter app and API.
 */
function cikoko_ui_pages_2620():array {
  return [
    'Dashboard'=>'Beranda / Dashboard',
    'Layanan Online'=>'Layanan Masyarakat',
    'Inovasi'=>'Inovasi',
    'Laporan Terpadu'=>'Laporan Terpadu',
    'Profil'=>'Profil Pengguna',
    'Edit Profil'=>'Edit Profil',
    'Bank Sampah Cikoko'=>'Bank Sampah Cikoko',
    'Laporan Jumantik'=>'Laporan Jumantik',
    'Laporan Jumantik RT/RW'=>'Jumantik RT/RW',
    'Jumantik Mandiri'=>'Jumantik Mandiri Warga',
    'Berita Jumantik Cikoko'=>'Berita Jumantik',
    'Berita Jumantik Mandiri Warga'=>'Berita Jumantik Mandiri',
    'Verifikasi Jumantik'=>'Verifikasi Jumantik',
    'Verifikasi Jumantik Mandiri'=>'Verifikasi Jumantik Mandiri',
    'Absensi dan Kinerja PJLP'=>'Absensi & Kinerja PJLP',
    'Kehadiran PPPK'=>'Kehadiran PPPK',
    'Kinerja PPPK'=>'Kinerja PPPK',
    'Cuti PPPK'=>'Cuti PPPK',
    'Kelola Cuti PPPK'=>'Persetujuan Cuti PPPK',
    'Cuti PPSU'=>'Cuti PJLP / PPSU',
    'Kelola Cuti PPSU'=>'Kelola Cuti PJLP / PPSU',
    'Persetujuan Cuti PPSU'=>'Persetujuan Cuti PJLP',
    'Riwayat'=>'Riwayat',
    'Surat Pengantar RT/RW'=>'Surat Pengantar RT/RW',
    'Surat Ahli Waris'=>'Surat Ahli Waris',
    'Surat Wilayah'=>'Surat Wilayah',
    'Berita & Kegiatan'=>'Berita & Kegiatan',
    'Pengumuman'=>'Pengumuman',
    'Agenda'=>'Pengumuman & Agenda',
    'Galeri'=>'Galeri',
    'Tentang Kami'=>'Tentang Kami',
    'Profil Wilayah'=>'Profil Wilayah',
    'Data Rumah Kos'=>'Data Rumah Kos',
    'Pendataan Rumah Kos'=>'Pendataan Rumah Kos',
    'Katalog DKI'=>'Katalog Layanan DKI',
    'Hubungi Kami'=>'Hubungi Kami / Chat',
    'Pesan Masuk'=>'Pesan Masuk Admin',
    'Percakapan Chat'=>'Percakapan Chat',
    'Notifikasi'=>'Notifikasi',
    'Ulasan Aplikasi'=>'Ulasan Aplikasi',
    'Rekap Ulasan'=>'Rekap Ulasan',
    'Menu Cikoko'=>'Menu Cikoko',
    'Modul Dinamis'=>'Modul Dinamis',
    'Kelola Semua Halaman'=>'Kelola Semua Halaman',
    'Push Notifikasi'=>'Push Notifikasi',
    'Kelola Layanan Terpadu'=>'Kelola Layanan Terpadu',
    'Verifikasi Laporan'=>'Verifikasi Laporan',
    'Verifikasi Ahli Waris'=>'Verifikasi Ahli Waris',
    'Kelola Akun Petugas'=>'Kelola Akun Petugas',
    'Hak Akses Role'=>'Hak Akses Role',
    'Tambah Berita'=>'Tambah Berita',
    'Tambah Pengumuman'=>'Tambah Pengumuman',
    'Tambah Arsip Ahli Waris'=>'Tambah Arsip Ahli Waris',
    'Arsip Ahli Waris'=>'Arsip Ahli Waris',
    'Laporan Kegiatan'=>'Laporan Kegiatan',
    'Laporan Kegiatan Admin'=>'Laporan Kegiatan Admin',
    'Laporan LPJ RT'=>'Laporan LPJ RT',
    'Laporan LPJ RW'=>'Laporan LPJ RW',
    'Laporan LPJ LMK'=>'Laporan LPJ LMK',
    'Laporan LPJ LMK A'=>'Laporan LPJ LMK A',
    'Laporan LPJ LMK B'=>'Laporan LPJ LMK B',
    'Laporan FKDM'=>'Laporan FKDM',
    'Laporan LMK'=>'Laporan LMK',
    'Laporan Posyandu'=>'Laporan Posyandu',
    'Laporan Dasawisma'=>'Laporan Dasawisma',
    'Laporan Kerja Bakti'=>'Laporan Kerja Bakti',
    'Laporan PPSU'=>'Laporan PPSU',
    'Alur PTSP'=>'Alur PTSP',
    'Alur Sosial'=>'Alur Sosial',
    'Alur Kerja ASN'=>'Alur Kerja ASN',
    'Wilayah Ketua RT/RW'=>'Wilayah Ketua RT/RW',
    'TTD & Stempel'=>'Tanda Tangan & Stempel',
    'Manajemen Bendahara RT/RW'=>'Manajemen Bendahara RT/RW',
  ];
}

function cikoko_ui_home_keys_2620():array {
  return [
   'hero'=>'Banner / Slider',
   'news'=>'Berita Terbaru',
   'announcement'=>'Pengumuman & Agenda',
   'bank_annual'=>'Total Tahunan Bank Sampah',
   'letters'=>'Status Pelayanan Surat',
   'integrated_services'=>'Layanan Masyarakat Terpadu',
   'boarding'=>'Data Rumah Kos',
   'innovation'=>'Inovasi',
   'activity'=>'Aktivitas Jumantik & Bank Sampah',
   'shortcuts'=>'Informasi & Kegiatan',
   'reviews'=>'Ulasan Aplikasi',
  ];
}
function cikoko_ui_text_2620(mixed $v,int $max):string {
  if(!is_string($v) && !is_numeric($v))return '';
  $s=trim(strip_tags((string)$v));
  $s=(string)preg_replace('/[\x00-\x08\x0B\x0C\x0E-\x1F]/u','',$s);
  return function_exists('mb_substr')?mb_substr($s,0,$max,'UTF-8'):substr($s,0,$max);
}
function cikoko_ui_hex_2620(mixed $v):string {
  return is_string($v)&&preg_match('/^#[0-9a-fA-F]{6}$/D',$v)?strtoupper($v):'#0967E7';
}
function cikoko_ui_default_page_2620(string $page):array {
  return [
    'title'=>'','description'=>'','accent'=>'#0967E7',
    'blocks'=>[],
    'sections'=>$page==='Dashboard'?
      array_map(static fn($key)=>['key'=>$key,'visible'=>true],
        array_keys(cikoko_ui_home_keys_2620())):[],
  ];
}
function cikoko_ui_normalize_page_2620(mixed $value,string $page):array {
  if(!isset(cikoko_ui_pages_2620()[$page]))throw new InvalidArgumentException('Halaman tidak dikenali.');
  if(!is_array($value))throw new InvalidArgumentException('Format halaman harus berupa objek.');
  $clean=cikoko_ui_default_page_2620($page);
  $clean['title']=cikoko_ui_text_2620($value['title']??'',90);
  $clean['description']=cikoko_ui_text_2620($value['description']??'',260);
  $clean['accent']=cikoko_ui_hex_2620($value['accent']??null);
  $blocks=$value['blocks']??[];
  if(!is_array($blocks)||count($blocks)>30)throw new InvalidArgumentException('Maksimal 30 komponen tambahan per halaman.');
  $used=[];
  foreach($blocks as $item){
    if(!is_array($item))throw new InvalidArgumentException('Komponen tidak valid.');
    $type=(string)($item['type']??'');
    if(!in_array($type,['heading','text','card','spacer'],true))throw new InvalidArgumentException('Jenis komponen tidak didukung.');
    $id=(string)($item['id']??'');
    if(!preg_match('/^[a-zA-Z0-9_-]{4,50}$/D',$id)||isset($used[$id]))throw new InvalidArgumentException('ID komponen tidak valid atau ganda.');
    $used[$id]=true;
    $clean['blocks'][]=[
      'id'=>$id,'type'=>$type,
      'title'=>cikoko_ui_text_2620($item['title']??'',95),
      'body'=>cikoko_ui_text_2620($item['body']??'',750),
      'visible'=>($item['visible']??true)===true,
      'size'=>in_array($item['size']??'', ['normal','wide'],true)?$item['size']:'normal',
      'height'=>max(8,min(100,(int)($item['height']??16))),
    ];
  }
  if($page==='Dashboard'){
    $existing=array_keys(cikoko_ui_home_keys_2620());
    $incoming=$value['sections']??[];
    if(!is_array($incoming)||count($incoming)>count($existing))throw new InvalidArgumentException('Susunan beranda tidak valid.');
    $seen=[];$ordered=[];
    foreach($incoming as $item){
      if(!is_array($item))continue;
      $key=(string)($item['key']??'');
      if(!in_array($key,$existing,true)||isset($seen[$key]))continue;
      $seen[$key]=true;
      $ordered[]=['key'=>$key,'visible'=>$key==='letters'?true:(($item['visible']??true)===true)];
    }
    foreach($existing as $key){
      if(!isset($seen[$key]))$ordered[]=['key'=>$key,'visible'=>true];
    }
    $clean['sections']=$ordered;
  }
  return $clean;
}
function cikoko_ui_read_store_2620():array {
  $store=db_read('cikoko_app_designer_2620');
  return is_array($store)?$store:[];
}
function cikoko_ui_published_2620():array {
  $store=cikoko_ui_read_store_2620();
  $pages=is_array($store['published']??null)?$store['published']:[];
  $safe=[];
  foreach(cikoko_ui_pages_2620() as $key=>$_){
    if(!isset($pages[$key]))continue;
    try{$safe[$key]=cikoko_ui_normalize_page_2620($pages[$key],$key);}catch(Throwable $ignored){}
  }
  return ['schema'=>1,'revision'=>max(0,(int)($store['revision']??0)),
    'published_at'=>(string)($store['published_at']??''),'pages'=>$safe];
}
