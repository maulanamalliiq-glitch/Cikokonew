<?php
declare(strict_types=1);
require __DIR__.'/../cpanel/mobile-api/pppk_staff.php';
function check_2570(bool $value,string $label):void{
 if(!$value)throw new RuntimeException('PPPK hardcheck failed: '.$label);
}
check_2570(pppk_staff_date('2026-11-18') instanceof DateTimeImmutable,'valid date');
check_2570(pppk_staff_date('2026-02-30')===null,'invalid day rollover');
check_2570(pppk_staff_date('18-11-2026')===null,'date format');
$api=file_get_contents(__DIR__.'/../cpanel/mobile-api/pppk_staff.php');
check_2570(is_string($api),'source available');
foreach(['pppk_staff_attendance','pppk_staff_daily','pppk_staff_leave_requests',
         'pppk_staff_leave_settings','pppk_staff_leave_approvals'] as $name)
 check_2570(str_contains($api,$name),'separate table '.$name);
check_2570(!preg_match('/\b(?:INSERT\s+INTO|UPDATE|DELETE\s+FROM)\s+(?:pj57_|pj58_|pjlp_)/i',$api),
 'PPPK cannot mutate existing PJLP attendance or leave tables');
check_2570(str_contains($api, "\\$role===\'pppk\'"),\'PPPK authorization gate\');
check_2570(str_contains($api,'pppk_staff_geofence'),'geofence verification');
check_2570(str_contains($api,'GET_LOCK'),'concurrent leave requests guarded');
echo "PPPK 2570 route and separation checks passed\n";
