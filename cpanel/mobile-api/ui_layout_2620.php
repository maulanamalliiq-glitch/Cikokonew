<?php
declare(strict_types=1);
/**
 * Public GET only. Published presentation metadata; no credentials,
 * names, private records, executable code or draft configurations.
 */
ini_set('display_errors','0');
header('Content-Type: application/json; charset=utf-8');
header('X-Content-Type-Options: nosniff');
header('Access-Control-Allow-Methods: GET');
if(($_SERVER['REQUEST_METHOD']??'GET')!=='GET'){
  header('Allow: GET');http_response_code(405);
  echo json_encode(['ok'=>false,'error'=>'Hanya GET.']);exit;
}
require_once dirname(__DIR__).'/lib.php';
require_once dirname(__DIR__).'/app-designer-schema-2620.php';
session_write_close();
header('Cache-Control: public, max-age=30, must-revalidate');
$layout=cikoko_ui_published_2620();
$page=trim((string)($_GET['page']??''));
if($page!==''){
  if(!array_key_exists($page,cikoko_ui_pages_2620())){
    http_response_code(404);
    echo json_encode(['ok'=>false,'error'=>'Halaman tidak tersedia.']);exit;
  }
  $layout['pages']=isset($layout['pages'][$page])
    ?[$page=>$layout['pages'][$page]]:[];
}
$response=json_encode(['ok'=>true]+$layout,JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES|JSON_INVALID_UTF8_SUBSTITUTE);
$etag='"'.hash('sha256',$response).'"';
header('ETag: '.$etag);
if(trim((string)($_SERVER['HTTP_IF_NONE_MATCH']??''))===$etag){
  http_response_code(304);exit;
}
echo $response;
