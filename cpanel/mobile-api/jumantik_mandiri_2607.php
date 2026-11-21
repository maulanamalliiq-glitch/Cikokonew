<?php
declare(strict_types=1);

/**
 * Jumantik Mandiri Warga (2607).
 * Separate from Jumantik RT/RW and legacy website JSON; never migrates,
 * overwrites or deletes historical reports.
 */
ini_set('display_errors', '0');
header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store');
header('X-Content-Type-Options: nosniff');
set_exception_handler(static function(Throwable $e):void {
    error_log('[Jumantik Mandiri 2607] '.$e->getMessage());
    if(!headers_sent())http_response_code(503);
    echo json_encode(['ok'=>false,'error'=>'Layanan Jumantik Mandiri sedang mengalami kendala.'],JSON_UNESCAPED_UNICODE);
});
require_once __DIR__.'/bootstrap.php';

const CKJM_CHECKS = [
 'bak_mandi','tatakan_dispenser','toren_air','tatakan_pot_bunga',
 'tampungan_pembuangan_air_ac','penampungan_sisa_air_kulkas',
 'genangan_air_sekitar_rumah','genangan_air_barang_bekas',
 'tempat_minum_hewan','menguras_membersihkan_tampungan_air',
 'menutup_tempat_tampung_air','mendaur_ulang_barang_bekas'
];
function ckjm_schema(PDO $db):void {
    static $ready=false;if($ready)return;
    $db->exec('CREATE TABLE IF NOT EXISTS mobile_jumantik_mandiri_2607 (
      id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
      public_id CHAR(32) NOT NULL UNIQUE,
      user_id VARCHAR(80) NOT NULL,
      client_key CHAR(32) NOT NULL,
      waktu DATETIME NOT NULL,
      nama_kepala_keluarga VARCHAR(160) NOT NULL,
      nama_pengirim VARCHAR(160) NOT NULL,
      no_handphone VARCHAR(25) NOT NULL,
      alamat VARCHAR(500) NOT NULL,
      checks_json TEXT NOT NULL,
      kegiatan VARCHAR(25) NOT NULL,
      photo_name VARCHAR(70) NOT NULL,
      status VARCHAR(20) NOT NULL DEFAULT "pending",
      reject_reason VARCHAR(300) NOT NULL DEFAULT "",
      reviewed_by VARCHAR(80) DEFAULT NULL,
      reviewed_at DATETIME DEFAULT NULL,
      published_at DATETIME DEFAULT NULL,
      created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
      UNIQUE KEY uq_owner_client (user_id,client_key),
      INDEX idx_owner (user_id,id),
      INDEX idx_review (status,id),
      INDEX idx_public (published_at,id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4');
    $ready=true;
}
function ckjm_nonadmin(array $actor):void {
    if(in_array((string)($actor['user_role']??''),['admin','admin_kelurahan'],true))
        mobile_error('Jumantik Mandiri hanya untuk akun selain Admin.',403);
}
function ckjm_admin(array $actor):void {
    if((string)($actor['user_role']??'')!=='admin')
        mobile_error('Hanya Super Admin dapat memverifikasi laporan.',403);
}
function ckjm_photo(PDO $db,int $id,array $actor):void {
    $q=$db->prepare('SELECT user_id,photo_name FROM mobile_jumantik_mandiri_2607 WHERE id=?');
    $q->execute([$id]);$row=$q->fetch();
    if(!$row)mobile_error('Foto tidak ditemukan.',404);
    if((string)$actor['user_role']!=='admin' && (string)$actor['user_id']!==(string)$row['user_id'])
        mobile_error('Foto hanya untuk pengirim atau Super Admin.',403);
    $name=(string)$row['photo_name'];
    if(!preg_match('/^[a-f0-9]{40}\\.(jpg|png|webp)$/D',$name))
        mobile_error('Foto tidak ditemukan.',404);
    $path=__DIR__.'/private/'.$name;
    if(!is_file($path))mobile_error('Foto tidak ditemukan.',404);
    $ext=strtolower(pathinfo($name,PATHINFO_EXTENSION));
    header('Content-Type: '.(['jpg'=>'image/jpeg','png'=>'image/png','webp'=>'image/webp'][$ext]));
    header('Cache-Control: private,no-store');
    readfile($path);exit;
}
function ckjm_row(array $r,bool $private):array {
    $out=[
      'id'=>(int)$r['id'],
      'waktu'=>(string)$r['waktu'].' WIB',
      'status'=>(string)$r['status'],
      'kegiatan'=>(string)$r['kegiatan'],
      'published_at'=>$r['published_at']===null?null:(string)$r['published_at'],
    ];
    if($private){
        $out+= [
          'nama_kepala_keluarga'=>(string)$r['nama_kepala_keluarga'],
          'nama_pengirim'=>(string)$r['nama_pengirim'],
          'no_handphone'=>(string)$r['no_handphone'],
          'alamat'=>(string)$r['alamat'],
          'checks'=>json_decode((string)$r['checks_json'],true)?:[],
          'reject_reason'=>(string)$r['reject_reason'],
          'user_id'=>(string)$r['user_id'],
          'photo_available'=>(string)$r['photo_name']!=='',
        ];
    }
    return $out;
}
$action=(string)($_GET['action']??'');
$method=(string)($_SERVER['REQUEST_METHOD']??'GET');
$methods=[
  'news'=>'GET','mine'=>'GET','admin_list'=>'GET',
  'photo'=>'GET','submit'=>'POST','admin_decide'=>'POST'
];
if(!isset($methods[$action]))mobile_error('Endpoint Jumantik Mandiri tidak tersedia.',404);
if($methods[$action]!==$method)mobile_error('Metode tidak diizinkan.',405);

$db=mobile_db();
ckjm_schema($db);
if($action==='news'){
    // Public news is an anonymized notice, never a household directory.
    $q=$db->query('SELECT id,waktu,kegiatan,status,published_at
        FROM mobile_jumantik_mandiri_2607
        WHERE status="published" AND published_at IS NOT NULL
        ORDER BY published_at DESC,id DESC LIMIT 60');
    mobile_json(['ok'=>true,'items'=>array_map(
        static fn($r)=>ckjm_row($r,false),$q->fetchAll(PDO::FETCH_ASSOC)
    )]);
}
$actor=mobile_auth();
$uid=(string)$actor['user_id'];

if($action==='photo'){
    $id=filter_var($_GET['id']??null,FILTER_VALIDATE_INT,['options'=>['min_range'=>1]]);
    if(!$id)mobile_error('Foto tidak ditemukan.',404);
    ckjm_photo($db,(int)$id,$actor);
}
if($action==='admin_list'){
    ckjm_admin($actor);
    $q=$db->query('SELECT * FROM mobile_jumantik_mandiri_2607 ORDER BY id DESC LIMIT 120');
    mobile_json(['ok'=>true,'items'=>array_map(
        static fn($r)=>ckjm_row($r,true),$q->fetchAll(PDO::FETCH_ASSOC)
    )]);
}
if($action==='admin_decide'){
    ckjm_admin($actor);
    $b=mobile_body();
    $id=filter_var($b['id']??null,FILTER_VALIDATE_INT,['options'=>['min_range'=>1]]);
    $decision=(string)($b['decision']??'');
    $reason=mobile_text($b['reason']??'',300);
    if(!$id||!in_array($decision,['publish','reject'],true)||
       ($decision==='reject' && $reason===''))
        mobile_error('Pilih keputusan yang benar dan isi alasan jika ditolak.',422);
    $q=$db->prepare('SELECT id,user_id,status FROM mobile_jumantik_mandiri_2607 WHERE id=?');
    $q->execute([$id]);$owner=$q->fetch(PDO::FETCH_ASSOC);
    if(!$owner)mobile_error('Laporan tidak ditemukan.',404);
    if($owner['status']!=='pending')mobile_error('Laporan sudah diverifikasi.',409);
    $status=$decision==='publish'?'published':'rejected';
    $update=$db->prepare('UPDATE mobile_jumantik_mandiri_2607
        SET status=?,reject_reason=?,reviewed_by=?,reviewed_at=NOW(),
        published_at=CASE WHEN ?="published" THEN NOW() ELSE NULL END
        WHERE id=? AND status="pending"');
    $update->execute([$status,$status==='rejected'?$reason:'',$uid,$status,$id]);
    if($update->rowCount()!==1)mobile_error('Status laporan sudah berubah.',409);
    mobile_emit('jumantik_mandiri_status',
      $status==='published'?'Laporan Jumantik Mandiri diverifikasi':'Laporan Jumantik Mandiri perlu diperbaiki',
      $status==='published'?'Laporan Anda sudah diverifikasi Super Admin.':'Laporan ditolak. Buka riwayat untuk melihat alasan.',
      'personal',(string)$owner['user_id']);
    mobile_emit('jumantik_mandiri_review','Verifikasi Jumantik Mandiri selesai',
      'Status laporan #'.$id.': '.$status.'.','personal','admin');
    if($status==='published'){
        mobile_emit('jumantik_mandiri_terbaru','Laporan Jumantik Mandiri Warga terbaru',
          'Laporan pemantauan lingkungan terbaru telah diverifikasi Super Admin.',
          'public');
    }
    mobile_json(['ok'=>true,'message'=>$status==='published'
      ?'Laporan diverifikasi dan berita Jumantik Mandiri diterbitkan.'
      :'Laporan ditolak dan pengirim menerima notifikasi.']);
}
ckjm_nonadmin($actor);
if($action==='mine'){
    $q=$db->prepare('SELECT * FROM mobile_jumantik_mandiri_2607
        WHERE user_id=? ORDER BY id DESC LIMIT 100');
    $q->execute([$uid]);
    mobile_json(['ok'=>true,'items'=>array_map(
        static fn($r)=>ckjm_row($r,true),$q->fetchAll(PDO::FETCH_ASSOC)
    )]);
}
if($action==='submit'){
    $key=mobile_text($_POST['client_key']??'',32);
    if(!preg_match('/^[a-f0-9]{32}$/D',$key))
        mobile_error('Permintaan tidak valid. Buka ulang formulir.',422);
    $q=$db->prepare('SELECT id FROM mobile_jumantik_mandiri_2607
        WHERE user_id=? AND client_key=? LIMIT 1');
    $q->execute([$uid,$key]);
    if($existing=$q->fetchColumn())mobile_json(['ok'=>true,'id'=>(int)$existing,
      'message'=>'Laporan telah diterima sebelumnya.','duplicate'=>true]);
    $family=mobile_text($_POST['nama_kepala_keluarga']??'',160);
    $sender=mobile_text($_POST['nama_pengirim']??'',160);
    $phone=mobile_text($_POST['no_handphone']??'',25);
    $address=mobile_text($_POST['alamat']??'',500);
    $activity=(string)($_POST['kegiatan']??'');
    if(mobile_strlen($family)<3||mobile_strlen($sender)<3||
       !preg_match('/^\\+?[0-9 ()-]{8,25}$/D',$phone)||
       mobile_strlen($address)<8||
       !in_array($activity,['sudah_terlaksana','belum_terlaksana'],true))
        mobile_error('Lengkapi nama, nomor HP, alamat, dan kegiatan.',422);
    $raw=(string)($_POST['checks']??'');
    $checks=json_decode($raw,true);
    if(!is_array($checks)||count($checks)!==count(CKJM_CHECKS)||
       array_keys($checks)!==CKJM_CHECKS)
        mobile_error('Semua pilihan pemeriksaan wajib diisi.',422);
    foreach(CKJM_CHECKS as $k){
        if(!in_array($checks[$k]??null,['ya','tidak'],true))
            mobile_error('Setiap pemeriksaan wajib Ya atau Tidak.',422);
    }
    $photo=mobile_file('foto',true);
    try {
        $waktu=(new DateTimeImmutable('now',new DateTimeZone('Asia/Jakarta')))
            ->format('Y-m-d H:i:s');
        $q=$db->prepare('INSERT INTO mobile_jumantik_mandiri_2607
          (public_id,user_id,client_key,waktu,nama_kepala_keluarga,
           nama_pengirim,no_handphone,alamat,checks_json,kegiatan,photo_name)
          VALUES (?,?,?,?,?,?,?,?,?,?,?)');
        $q->execute([
          bin2hex(random_bytes(16)),$uid,$key,$waktu,$family,$sender,
          $phone,$address,json_encode($checks,JSON_UNESCAPED_UNICODE|JSON_THROW_ON_ERROR),
          $activity,$photo
        ]);
        $id=(int)$db->lastInsertId();
    } catch(Throwable $e) {
        if($photo!==null)@unlink(__DIR__.'/private/'.$photo);
        throw $e;
    }
    mobile_emit('jumantik_mandiri_status','Laporan Jumantik Mandiri diterima',
      'Laporan #'.$id.' masuk dan menunggu verifikasi Super Admin.',
      'personal',$uid);
    mobile_emit('jumantik_mandiri_review','Laporan Jumantik Mandiri Warga baru',
      'Laporan baru #'.$id.' menunggu pemeriksaan foto dan hasil.',
      'personal','admin');
    mobile_json(['ok'=>true,'id'=>$id,'waktu'=>$waktu.' WIB',
       'status'=>'pending','message'=>'Laporan berhasil dikirim dan menunggu verifikasi Super Admin.']);
}
mobile_error('Aksi tidak tersedia.',404);
