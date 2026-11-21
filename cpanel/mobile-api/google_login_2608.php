<?php
declare(strict_types=1);
// Dedicated Google OAuth login endpoint: independent of live index.php routing.
ini_set('display_errors','0');
header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store');
header('X-Content-Type-Options: nosniff');
set_exception_handler(static function (Throwable $e):void {
    error_log('[Cikoko Google Auth 2608] '.$e->getMessage());
    if(!headers_sent())http_response_code(503);
    echo json_encode(['ok'=>false,'error'=>'Login Google sedang mengalami kendala.'],JSON_UNESCAPED_UNICODE);
});
require_once __DIR__.'/bootstrap.php';
require_once __DIR__.'/google_auth_2608.php';
$action=(string)($_GET['action']??'');
if(!in_array($action,['google_login','google_link'],true))
    mobile_error('Layanan Google tidak ditemukan.',404);
cikoko_google_route($action,(string)($_SERVER['REQUEST_METHOD']??'GET'));
