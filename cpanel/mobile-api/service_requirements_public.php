<?php
declare(strict_types=1);
/**
 * Cikoko Smart 2601: public READ-ONLY subservice catalog for Flutter.
 * Shares the exact /data/cikoko_service_requirements.json file written by
 * website patch 2600. No auth, POST, database or API router changes.
 */
header('Content-Type: application/json; charset=utf-8');
header('X-Content-Type-Options: nosniff');
header('Cache-Control: public, max-age=30');
if (($_SERVER['REQUEST_METHOD'] ?? 'GET') !== 'GET') {
    header('Allow: GET'); http_response_code(405);
    echo json_encode(['ok'=>false,'error'=>'Metode tidak tersedia.']); exit;
}
$root = dirname(__DIR__);
$module = $root.'/site-v3/modules/service-requirements.php';
if (!is_file($module)) {
    http_response_code(503);
    echo json_encode(['ok'=>false,'error'=>'Katalog persyaratan belum terpasang.']); exit;
}
try {
    require_once $module;
    $requirements = cksr_read(); // Website 2600: validated, sanitized list.
    $cms = [];
    $contentPath = $root.'/data/content.json';
    if (is_file($contentPath) && ($size = @filesize($contentPath)) !== false && $size <= 2*1024*1024) {
        $raw = @file_get_contents($contentPath);
        $rows = is_string($raw) ? json_decode($raw, true) : null;
        if (is_array($rows)) {
            $rows = array_values(array_filter($rows, static fn($v): bool => is_array($v) && ($v['type']??'')==='layanan'));
            usort($rows, static fn($a,$b): int => strcmp((string)($b['created_at']??''),(string)($a['created_at']??'')));
            foreach (array_slice($rows, 0, 8) as $row) {
                $id = (string)($row['id']??'');
                $title = trim((string)($row['title']??''));
                if (!preg_match('/^[A-Za-z0-9_-]{1,120}$/D',$id) || $title==='') continue;
                $cms[] = [
                    'id'=>'cms:'.$id,
                    'title'=>(function_exists('mb_substr') ? mb_substr($title,0,120,'UTF-8') : $title),
                    'description'=>(function_exists('mb_substr') ? mb_substr(trim((string)($row['body']??'')),0,250,'UTF-8') : trim((string)($row['body']??''))),
                    'url'=>'https://datawebs.my.id/berita/'.rawurlencode($id),
                    'logo_url'=>'',
                    'active'=>true,
                ];
            }
        }
    }
    echo json_encode(['ok'=>true,'version'=>2601,'items'=>$requirements,'cms_services'=>$cms],
        JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES|JSON_THROW_ON_ERROR);
} catch (Throwable $e) {
    error_log('Cikoko requirements public endpoint failed.');
    http_response_code(503);
    echo json_encode(['ok'=>false,'error'=>'Data pelayanan sedang tidak tersedia.']);
}
