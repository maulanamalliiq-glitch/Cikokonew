<?php
declare(strict_types=1);
ini_set('display_errors', '0');
header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store');
header('X-Content-Type-Options: nosniff');
set_exception_handler(static function (Throwable $e): void {
    error_log('[Cikoko Jumantik 2606] '.$e->getMessage());
    if (!headers_sent()) http_response_code(503);
    echo json_encode(['ok'=>false,'error'=>'Layanan Jumantik belum tersedia. Hubungi Admin.'], JSON_UNESCAPED_UNICODE);
});
require_once __DIR__.'/bootstrap.php';

function cikoko_jumantik_schema(PDO $db): void {
    static $done = false;
    if ($done) return;
    $db->exec('CREATE TABLE IF NOT EXISTS mobile_jumantik_reports (
        id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        public_id CHAR(32) NOT NULL UNIQUE,
        user_id VARCHAR(80) NOT NULL,
        officer_role VARCHAR(30) NOT NULL,
        officer_name VARCHAR(160) NOT NULL,
        rt VARCHAR(12) NOT NULL,
        rw VARCHAR(12) NOT NULL,
        coordinator VARCHAR(120) NOT NULL,
        tanggal DATE NOT NULL,
        minggu_ke TINYINT UNSIGNED NOT NULL,
        lokasi VARCHAR(220) NOT NULL,
        tempat_umum_lainnya VARCHAR(10) NOT NULL,
        nama_kepala_keluarga VARCHAR(10) NOT NULL,
        alamat_lengkap VARCHAR(500) NOT NULL,
        jentik VARCHAR(10) NOT NULL,
        photo_name VARCHAR(70) NOT NULL,
        status VARCHAR(20) NOT NULL DEFAULT "pending",
        published_at DATETIME NULL,
        reviewed_at DATETIME NULL,
        reviewed_by VARCHAR(80) NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        INDEX idx_user (user_id,id),
        INDEX idx_review (status,id),
        INDEX idx_published (published_at,id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4');
    $done = true;
}
function cikoko_jumantik_officer(array $actor): array {
    foreach (db_read('portal_users') as $entry) {
        if ((string)($entry['id']??'') === (string)$actor['user_id'] &&
            !empty($entry['active']) &&
            in_array((string)($entry['role']??''), ['jumantik_rt','jumantik_rw'], true) &&
            (string)$entry['role'] === (string)$actor['user_role']) {
            return $entry;
        }
    }
    mobile_error('Akun Jumantik RT/RW tidak aktif atau tidak sesuai.', 403);
}
function cikoko_jumantik_date(string $date): bool {
    if (!preg_match('/^\d{4}-\d{2}-\d{2}$/D', $date)) return false;
    $dt = DateTimeImmutable::createFromFormat('!Y-m-d', $date, new DateTimeZone('Asia/Jakarta'));
    if (!$dt || $dt->format('Y-m-d') !== $date) return false;
    $today = (new DateTimeImmutable('now', new DateTimeZone('Asia/Jakarta')))->format('Y-m-d');
    return $date >= '2020-01-01' && $date <= $today;
}
function cikoko_jumantik_publishable_photo(PDO $db, string $id): ?string {
    $q = $db->prepare('SELECT photo_name FROM mobile_jumantik_reports
        WHERE public_id=? AND published_at IS NOT NULL LIMIT 1');
    $q->execute([$id]);
    $name = (string)($q->fetchColumn() ?: '');
    return preg_match('/^[a-f0-9]{40}\.(jpg|png|webp)$/D', $name) ? $name : null;
}
$action = (string)($_GET['action']??'');
$method = (string)($_SERVER['REQUEST_METHOD']??'GET');
if (!in_array($action, ['me','submit','news','photo','admin_list','admin_publish','admin_photo'], true)) {
    mobile_error('Endpoint Jumantik tidak ditemukan.', 404);
}
if (($action === 'news' || $action === 'photo' || $action === 'me' || $action === 'admin_list' || $action === 'admin_photo') && $method !== 'GET') {
    mobile_error('Metode tidak diperbolehkan.', 405);
}
if (($action === 'submit' || $action === 'admin_publish') && $method !== 'POST') {
    mobile_error('Metode tidak diperbolehkan.', 405);
}
$db = mobile_db();
cikoko_jumantik_schema($db);

if ($action === 'photo') {
    $id = (string)($_GET['id']??'');
    if (!preg_match('/^[a-f0-9]{32}$/D', $id)) mobile_error('Foto tidak ditemukan.',404);
    $filename = cikoko_jumantik_publishable_photo($db,$id);
    if ($filename === null) mobile_error('Foto tidak ditemukan.',404);
    $file = __DIR__.'/private/'.$filename;
    if (!is_file($file)) mobile_error('Foto tidak ditemukan.',404);
    $extension = strtolower(pathinfo($filename,PATHINFO_EXTENSION));
    header('Content-Type: '.(['jpg'=>'image/jpeg','png'=>'image/png','webp'=>'image/webp'][$extension]??'application/octet-stream'));
    header('Cache-Control: public,max-age=3600');
    header('X-Content-Type-Options: nosniff');
    readfile($file);
    exit;
}
if ($action === 'news') {
    $q = $db->query('SELECT public_id,tanggal,rt,rw,minggu_ke,jentik,tempat_umum_lainnya
        FROM mobile_jumantik_reports WHERE published_at IS NOT NULL
        ORDER BY published_at DESC,id DESC LIMIT 60');
    $items = [];
    foreach ($q->fetchAll(PDO::FETCH_ASSOC) as $row) {
        $id = (string)$row['public_id'];
        $items[] = [
            'tanggal'=>(string)$row['tanggal'],'rt'=>(string)$row['rt'],
            'rw'=>(string)$row['rw'],'minggu_ke'=>(int)$row['minggu_ke'],
            'jentik'=>(string)$row['jentik'],
            'tempat_umum_lainnya'=>(string)$row['tempat_umum_lainnya'],
            'photo_url'=>'/mobile-api/jumantik-2605.php?action=photo&id='.$id,
        ];
    }
    mobile_json(['ok'=>true,'items'=>$items]);
}

$actor = mobile_auth();
if ($action === 'admin_list' || $action === 'admin_publish' || $action === 'admin_photo') {
    if ((string)$actor['user_role'] !== 'admin')
        mobile_error('Verifikasi hanya untuk Super Admin.', 403);
    if ($action === 'admin_photo') {
        $id = filter_var($_GET['id']??null,FILTER_VALIDATE_INT,['options'=>['min_range'=>1]]);
        if (!$id) mobile_error('Foto tidak ditemukan.',404);
        $q = $db->prepare('SELECT photo_name FROM mobile_jumantik_reports WHERE id=?');
        $q->execute([$id]);
        $filename = (string)($q->fetchColumn() ?: '');
        if (!preg_match('/^[a-f0-9]{40}\\.(jpg|png|webp)$/D',$filename) ||
            !is_file(__DIR__.'/private/'.$filename)) mobile_error('Foto tidak ditemukan.',404);
        $ext = strtolower(pathinfo($filename,PATHINFO_EXTENSION));
        header('Content-Type: '.(['jpg'=>'image/jpeg','png'=>'image/png','webp'=>'image/webp'][$ext]));
        readfile(__DIR__.'/private/'.$filename);
        exit;
    }
    if ($action === 'admin_list') {
        $q = $db->query('SELECT id,officer_name,officer_role,coordinator,rt,rw,tanggal,
            minggu_ke,lokasi,tempat_umum_lainnya,nama_kepala_keluarga,
            alamat_lengkap,jentik,status,created_at
            FROM mobile_jumantik_reports WHERE status="pending" ORDER BY id DESC LIMIT 80');
        mobile_json(['ok'=>true,'items'=>$q->fetchAll(PDO::FETCH_ASSOC)]);
    }
    $b = mobile_body();
    $id = filter_var($b['id']??null, FILTER_VALIDATE_INT, ['options'=>['min_range'=>1]]);
    $decision = (string)($b['decision']??'');
    if (!$id || !in_array($decision,['publish','reject'],true))
        mobile_error('Keputusan atau ID laporan tidak valid.',422);
    $newStatus = $decision === 'publish' ? 'published' : 'rejected';
    $q = $db->prepare('UPDATE mobile_jumantik_reports SET status=?,
        published_at=CASE WHEN ?="published" THEN NOW() ELSE NULL END,
        reviewed_at=NOW(),reviewed_by=? WHERE id=? AND status="pending"');
    $q->execute([$newStatus,$newStatus,(string)$actor['user_id'],$id]);
    if ($q->rowCount()!==1) mobile_error('Laporan tidak ada atau sudah diperiksa.',409);
    mobile_json(['ok'=>true,'message'=>$newStatus==='published'
        ? 'Laporan berhasil diterbitkan sebagai Berita Jumantik.'
        : 'Laporan ditolak. Tidak diterbitkan.']);
}
$officer = cikoko_jumantik_officer($actor);
$uid = (string)$actor['user_id'];
$profile = [
    'name'=>(string)($officer['name']??''),
    'role'=>(string)$officer['role'],
    'rt'=>(string)($officer['rt']??''),
    'rw'=>(string)($officer['rw']??''),
    'coordinator'=>(string)($officer['jumantik_coordinator']??''),
];
if ($action === 'me') {
    $q = $db->prepare('SELECT tanggal,jentik,status,published_at
        FROM mobile_jumantik_reports WHERE user_id=? ORDER BY id DESC LIMIT 50');
    $q->execute([$uid]);
    $items = [];
    foreach ($q->fetchAll(PDO::FETCH_ASSOC) as $row) {
        $items[] = [
            'tanggal'=>(string)$row['tanggal'],'jentik'=>(string)$row['jentik'],
            'status'=>(string)$row['status'],'published'=>$row['published_at']!==null,
        ];
    }
    mobile_json(['ok'=>true,'profile'=>$profile,'items'=>$items]);
}

if (trim($profile['rt'])==='' || trim($profile['rw'])==='' || trim($profile['coordinator'])==='') {
    mobile_error('RT, RW, dan Koordinator belum ditetapkan oleh Super Admin.',422);
}
$postedRole = (string)($_POST['anggota']??'');
if ($postedRole !== $profile['role']) mobile_error('Jenis anggota tidak sesuai role akun.',403);
$tanggal = mobile_text($_POST['tanggal']??'',10);
$minggu = filter_var($_POST['minggu_ke']??null, FILTER_VALIDATE_INT,
    ['options'=>['min_range'=>1,'max_range'=>6]]);
$lokasi = mobile_text($_POST['lokasi']??'',220);
$alamat = mobile_text($_POST['alamat_lengkap']??'',500);
$tempat = mobile_text($_POST['tempat_umum_lainnya']??'',10);
$keluarga = mobile_text($_POST['nama_kepala_keluarga']??'',10);
$jentik = mobile_text($_POST['jentik']??'',10);
if (!cikoko_jumantik_date($tanggal) || !$minggu || $lokasi==='' || $alamat==='' ||
    !in_array($tempat,['sudah','belum'],true) ||
    !in_array($keluarga,['sudah','belum'],true) ||
    !in_array($jentik,['ada','tidak'],true)) {
    mobile_error('Periksa tanggal, minggu, lokasi, alamat dan hasil pemeriksaan.',422);
}
$photoName = mobile_file('foto1',true);
try {
    $q = $db->prepare('INSERT INTO mobile_jumantik_reports
        (public_id,user_id,officer_role,officer_name,rt,rw,coordinator,tanggal,
         minggu_ke,lokasi,tempat_umum_lainnya,nama_kepala_keluarga,
         alamat_lengkap,jentik,photo_name,status)
        VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,"pending")');
    $q->execute([
        bin2hex(random_bytes(16)),$uid,$profile['role'],$profile['name'],
        $profile['rt'],$profile['rw'],$profile['coordinator'],$tanggal,
        $minggu,$lokasi,$tempat,$keluarga,$alamat,$jentik,$photoName,
    ]);
} catch (Throwable $e) {
    if ($photoName!==null) @unlink(__DIR__.'/private/'.$photoName);
    throw $e;
}
mobile_json(['ok'=>true,'message'=>'Laporan diterima dan menunggu verifikasi Super Admin.']);
