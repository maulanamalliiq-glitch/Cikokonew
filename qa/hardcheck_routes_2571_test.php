<?php
declare(strict_types=1);
/**
 * Static contract tests only. These DO NOT prove production cPanel has been
 * updated or that MySQL tables/remote HTTP endpoints work.
 */
$root=dirname(__DIR__);
$read=static function(string $path)use($root):string{
 $data=@file_get_contents($root.'/'.$path);
 if($data===false)throw new RuntimeException('Missing source file: '.$path);
 return $data;
};
$assert=static function(bool $condition,string $label):void{
 if(!$condition)throw new RuntimeException('Cikoko hardcheck failed: '.$label);
};
$index=$read('cpanel/mobile-api/index.php');
$services=$read('cpanel/mobile-api/integrated_services.php');
$reviews=$read('cpanel/mobile-api/reviews.php');
$chat=$read('cpanel/mobile-api/chat_v2548.php');
$storage=$read('cpanel/mobile-api/chat_storage_2544.php');
$pppk=$read('cpanel/mobile-api/pppk_staff.php');
$flutter=$read('flutter/lib/main.dart');
$catalog=$read('flutter/lib/role_catalog.dart');
$assert(str_contains($index,"'integrated_services_public'"),'Public services route in index');
$assert(str_contains($index,"'integrated_services_logo'"),'Uploaded logo image route in index');
$assert(str_contains($services,"'integrated_services_public'"),'Public catalog handler');
$assert(str_contains($services,"'integrated_services_logo'"),'Public logo handler');
$assert(str_contains($services,'mobile_auth(!in_array('),'Public read must not require login');
$assert(str_contains($index,"'review_public'"),'Reviews index route');
$assert(strpos($reviews,"if(\$action==='review_public'")!==false,'Public reviews endpoint');
$assert(strpos($reviews,"if(\$action==='review_public'") <
    strpos($reviews,'$actor=mobile_auth();'),'Public reviews before authentication');
$assert(str_contains($reviews,'REVIEW_SCHEMA'),'Missing review schema has actionable code');
$assert(str_contains($chat,"if(\$action==='chat_v2548_status'"),'Public chat-status endpoint');
$assert(strpos($chat,"if(\$action==='chat_v2548_status'")<
    strpos($chat,'$user=mobile_auth();'),'Chat status before authentication');
$assert(str_contains($chat,"'chat_v2548_selfcheck'"),'Authenticated chat selfcheck route');
$assert(str_contains($storage,"'stored'=>true"),'Chat writes acknowledged only after read-back');
$assert(str_contains($chat,"'chat_v2548_diagnostic'"),'Chat diagnostics accessible without selected thread');
foreach(['pppk_staff_attendance','pppk_staff_leave_requests',
  'pppk_staff_leave_approvals'] as $t)
 $assert(str_contains($pppk,$t),'Independent PPPK table '.$t);
$assert(str_contains($flutter,"case 'Kehadiran PPPK':"),'PPPK attendance page is routed');
$assert(str_contains($flutter,"case 'Cuti PPPK':"),'PPPK leave page is routed');
$assert(str_contains($catalog,"'pppk':['pppk_attendance'"),'PPPK is not routed to PJLP');
$assert(is_file($root.'/cpanel/mobile-api/migrate_reviews_2571.sql'),
  'Review additive migration included');
$assert(is_file($root.'/cpanel/mobile-api/migrate_pppk_staff_2570.sql'),
  'PPPK additive migration included');
echo "Cikoko 2571 static route and data-isolation checks passed\n";
