<?php
declare(strict_types=1);
/**
 * Bank Sampah Cikoko 2618: public, read-only annual total for Beranda.
 * Returns approved/closed totals only. No personal data or write actions.
 */
ini_set('display_errors', '0');
header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store, max-age=0');
header('X-Content-Type-Options: nosniff');
set_exception_handler(static function(Throwable $error):void {
    error_log('[Cikoko Bank 2618 Beranda] '.$error->getMessage());
    if(!headers_sent())http_response_code(503);
    echo json_encode(['ok'=>false,'error'=>'Rekap Bank Sampah belum tersedia.'],JSON_UNESCAPED_UNICODE);
});
if(($_SERVER['REQUEST_METHOD']??'GET')!=='GET'){
    http_response_code(405);
    header('Allow: GET');
    echo json_encode(['ok'=>false,'error'=>'Metode tidak diizinkan.'],JSON_UNESCAPED_UNICODE);
    exit;
}
require_once __DIR__.'/bootstrap.php';
$now=new DateTimeImmutable('now',new DateTimeZone('Asia/Jakarta'));
$year=filter_var($_GET['year']??$now->format('Y'),FILTER_VALIDATE_INT);
if($year===false||$year<2020||$year>2100){
    http_response_code(422);
    echo json_encode(['ok'=>false,'error'=>'Tahun tidak valid.'],JSON_UNESCAPED_UNICODE);
    exit;
}
$from=sprintf('%04d-01-01',$year);
$to=sprintf('%04d-01-01',$year+1);
$today=$now->format('Y-m-d');
$db=mobile_db();
// Only session data approved by Admin. Draft/open and voided items excluded.
$live=$db->prepare('SELECT
    COALESCE(SUM(e.weight_kg),0) AS kg,
    COALESCE(SUM(e.amount_rp),0) AS rp,
    COUNT(*) AS entries
  FROM mobile_bank_sampah_sessions_2610 s
  JOIN mobile_bank_sampah_entries_2610 e ON e.session_id=s.id
  WHERE s.status="closed" AND e.voided_at IS NULL
    AND s.session_date>=? AND s.session_date<? AND s.session_date<=?');
$live->execute([$from,$to,$today]);
$a=$live->fetch(PDO::FETCH_ASSOC)?:[];
// Archive 2026 uses the same suppression rule as the existing annual module:
// a date replaced by published live weighing must never count twice.
$archive=$db->prepare('SELECT
    COALESCE(SUM(a.weight_kg),0) AS kg,
    COALESCE(SUM(a.amount_rp),0) AS rp,
    COUNT(*) AS entries
  FROM mobile_bank_sampah_archive_entries_2026 a
  WHERE a.review_status="confirmed"
    AND a.session_date>=? AND a.session_date<? AND a.session_date<=?
    AND NOT EXISTS (
      SELECT 1 FROM mobile_bank_sampah_sessions_2610 s
      JOIN mobile_bank_sampah_entries_2610 e ON e.session_id=s.id
      WHERE s.session_date=a.session_date
        AND s.status="closed" AND e.voided_at IS NULL
    )');
$archive->execute([$from,$to,$today]);
$b=$archive->fetch(PDO::FETCH_ASSOC)?:[];
$grams=(int)round((float)($a['kg']??0)*1000)+(int)round((float)($b['kg']??0)*1000);
$rupiah=(int)($a['rp']??0)+(int)($b['rp']??0);
$entries=(int)($a['entries']??0)+(int)($b['entries']??0);
echo json_encode([
 'ok'=>true,
 'year'=>$year,
 'totals'=>[
  'weight_kg'=>number_format($grams/1000,3,'.',''),
  'amount_rp'=>$rupiah,
  'entries'=>$entries,
 ],
 'as_of'=>$today,
 'published_only'=>true
],JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
