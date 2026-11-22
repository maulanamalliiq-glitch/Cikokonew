<?php
declare(strict_types=1);
require_once dirname(__DIR__).'/cpanel/app-designer-schema-2620.php';

function check2620(bool $ok,string $message):void {
 if(!$ok)throw new RuntimeException('SDUI 2620: '.$message);
}
$pages=cikoko_ui_pages_2620();
check2620(count($pages)>=60,'halaman master tidak lengkap');
check2620(isset($pages['Bank Sampah Cikoko'],$pages['Dashboard'],$pages['Kinerja PPPK'],$pages['Profil']),'halaman penting hilang');
$d=cikoko_ui_default_page_2620('Dashboard');
check2620(count($d['sections'])===count(cikoko_ui_home_keys_2620()),'susunan default tidak lengkap');
$draft=cikoko_ui_normalize_page_2620([
 'title'=>'<img onerror="evil">Judul Aman','description'=>"Deskripsi",
 'accent'=>'#13Ac00',
 'blocks'=>[
   ['id'=>'text_01','type'=>'card','title'=>'<script>Isi</script>','body'=>'Detail','visible'=>true,'size'=>'wide']
 ],
 'sections'=>[
   ['key'=>'bank_annual','visible'=>true],
   ['key'=>'letters','visible'=>false],
   ['key'=>'hero','visible'=>true],
 ],
],'Dashboard');
check2620($draft['title']==='Judul Aman','HTML judul tidak dibersihkan');
check2620($draft['blocks'][0]['title']==='Isi','HTML komponen tidak dibersihkan');
check2620($draft['accent']==='#13AC00','warna tidak divalidasi');
check2620($draft['sections'][0]['key']==='bank_annual','urutan tidak tersimpan');
check2620($draft['sections'][1]['visible']===true,'status surat wajib tidak boleh disembunyikan');
check2620(count($draft['sections'])===count($d['sections']),'susunan bawaan hilang');
try{
 cikoko_ui_normalize_page_2620(['blocks'=>[['type'=>'script','id'=>'evil']]],'Dashboard');
 throw new RuntimeException('Komponen terlarang diterima');
}catch(InvalidArgumentException $expected){}
try{
 cikoko_ui_normalize_page_2620(['blocks'=>[
   ['type'=>'card','id'=>'duplicate'],['type'=>'card','id'=>'duplicate']
 ]],'Dashboard');
 throw new RuntimeException('ID ganda diterima');
}catch(InvalidArgumentException $expected){}
try{
 cikoko_ui_normalize_page_2620([],'HALAMAN-SUNTIKAN');
 throw new RuntimeException('Halaman terlarang diterima');
}catch(InvalidArgumentException $expected){}
echo "PASS: SDUI Cikoko Smart 2620 schema, sanitization, pages, mandatory section.\n";
