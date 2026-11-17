<?php
declare(strict_types=1);
// Static privacy/routing contract: runtime FCM delivery still requires phone tests.
$root=dirname(__DIR__);
$read=static function(string $file)use($root):string{
 $data=file_get_contents($root.'/'.$file);
 if($data===false)throw new RuntimeException('Missing file '.$file);
 return $data;
};
$assert=static function(bool $ok,string $msg):void{
 if(!$ok)throw new RuntimeException('Notification contract failed: '.$msg);
};
$index=$read('cpanel/mobile-api/index.php');
$pjlp=$read('cpanel/mobile-api/pjlp_leave.php');
$pppk=$read('cpanel/mobile-api/pppk_staff.php');
$performance=$read('cpanel/mobile-api/pppk_performance.php');
$flutter=$read('flutter/lib/main.dart');
$push=$read('flutter/lib/push.dart');
$inbox=$read('flutter/lib/cikoko_v6_content.dart');

$assert(str_contains($index,"if(\$action==='event_read_all'"),'read-all API route');
$assert(str_contains($index,'e.audience="personal" AND e.recipient=?'),
 'read-all must scope to requesting account only');
$assert(str_contains($pjlp,"VALUES('leave',?,?,'personal',?)"),
 'PJLP leave goes into the visible personal inbox');
$assert(str_contains($pppk,"VALUES('pppk_leave',?,?,'personal',?)"),
 'PPPK leave events are recipient-scoped');
$assert(str_contains($pppk,"'pending_supervisor'=>'menunggu atasan langsung'"),
 'PPPK supervisor status clearly labeled');
$assert(str_contains($pppk,'if($supervisor&&!$admin)'),
 'Admin can see all pending PPPK requests while supervisors only see assigned ones');
$assert(str_contains($pppk,"'pending_lurah'=>'menunggu Lurah'"),
 'PPPK lurah status clearly labeled');
$assert(str_contains($performance,"VALUES('pppk_performance',?,?,'personal',?)"),
 'PPPK performance status events are private');
$assert(str_contains($flutter,"case 'Notifikasi':return V6NotificationPage"),
 'inbox route exists');
$assert(str_contains($flutter,"case 'Cuti PPPK'"),
 'PPPK leave destination exists');
$assert(str_contains($flutter,"if(category=='pppk_performance')"),
 'PPPK performance deep link exists');
$assert(str_contains($push,'opened?.cancel()'),
 'FCM opened-app subscriptions are cancelled');
$assert(str_contains($push,'final duplicate=id.isNotEmpty'),
 'FCM and polling same event are deduplicated');
$assert(str_contains($inbox,"'Belum Dibaca'"),
 'inbox has an unread filter');
$assert(str_contains($inbox,'notification_read_all'),
 'inbox has an explicit read-all control');
echo "Notification 2572 routing, read-state and privacy contracts passed\n";
