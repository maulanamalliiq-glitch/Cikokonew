<?php
declare(strict_types=1);
$root=dirname(__DIR__);
$api=file_get_contents($root.'/cpanel/mobile-api/bank_sampah_2610.php');
$dart=file_get_contents($root.'/flutter/lib/cikoko_bank_sampah_2610.dart');
$form=file_get_contents($root.'/flutter/lib/cikoko_bank_sampah_mockup_2613.dart');
function bank2616(bool $yes,string $what):void {
    if(!$yes)throw new RuntimeException('Bank Sampah 2616: '.$what);
}
foreach([$api,$dart,$form] as $s)bank2616(is_string($s)&&strlen($s)>1000,'Source missing');
bank2616(str_contains($api,'mobile_bank_sampah_archive_sessions_2026') &&
         str_contains($api,'mobile_bank_sampah_archive_entries_2026'),
         'Historical archive tables must be additive and independent');
bank2616(str_contains($api,'a.review_status="confirmed"'),
         'Unreconciled Excel items cannot enter official totals');
bank2616(str_contains($api,"'archive_2026'=>true"),
         'Historical read-only records must carry archive metadata');
bank2616(str_contains($api,'NOT EXISTS(') &&
         str_contains($api,'e.voided_at IS NULL'),
         'Annual aggregation must avoid duplicate live weighing sessions');
bank2616(str_contains($api,'source_member_name')&&
         str_contains($api,'ckbs_archive_report_name'),
         'Source names must be retained and roster aliases auditably grouped');
bank2616(str_contains($api,"'archive_2026'=>'GET'"),
         'Admin/staff archive read endpoint missing');
bank2616(str_contains($api,"'session_create'],true)") &&
         str_contains($api,'if(!ckbs_officer($db,$actor))'),
         'Only appointed PJLP/PPPK and Admin may choose dates');
bank2616(!str_contains($api,"if($"."date->format('w')!=='0')"),
         'Officer dates must not be Sunday-only');
bank2616(str_contains($api,'$date<$today')&&
         str_contains($api,'$date>$max'),
         'Officer dates must be future-limited');
bank2616(str_contains($dart,'bank_sampah_choose_any_date_2616')&&
         str_contains($dart,'if(canInput)'),
         'Officer should see self-service calendar button');
bank2616(!str_contains($dart,'selectableDayPredicate: (d) => d.weekday == DateTime.sunday'),
         'Flutter date picker must allow weekdays other than Sunday');
bank2616(str_contains($form,'_hari(widget.session')&&
         str_contains($form,"'Senin','Selasa','Rabu'"),
         'Day text must reflect date chosen');
bank2616(!str_contains($api,'DELETE FROM portal_users')&&
         !str_contains($api,'UPDATE portal_users'),
         'Never touch old accounts');
echo "Bank Sampah 2616: historical safe annual + officer date picking OK\n";
