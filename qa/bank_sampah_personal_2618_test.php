<?php
declare(strict_types=1);
$base=dirname(__DIR__);
$api=file_get_contents($base.'/cpanel/mobile-api/bank_sampah_2610.php');
$page=file_get_contents($base.'/flutter/lib/cikoko_bank_sampah_2610.dart');
$ui=file_get_contents($base.'/flutter/lib/cikoko_bank_sampah_personal_2618.dart');
function checkPersonal2618(bool $ok,string $why):void{
  if(!$ok)throw new RuntimeException('Bank Sampah 2618: '.$why);
}
foreach([$api,$page,$ui] as $src){
  checkPersonal2618(is_string($src)&&strlen($src)>1000,'Source files missing');
}
checkPersonal2618(str_contains($api,"'personal_entries'=>'GET'"),
  'Private detail API action missing');
checkPersonal2618(str_contains($api,"if($"."action==='summary'||$"."action==='personal_entries')"),
  'Personal summary and detail must share one source of truth');
checkPersonal2618(str_contains($api,'ckbs_only_role($actor,CKBS_ROLE_MEMBER)'),
  'Only authenticated staff member accounts may use private detail');
checkPersonal2618(str_contains($api,'$items=ckbs_personal_entries($db,$uid,$year,$users)'),
  'Server must use mobile_auth user id, not requested member id');
checkPersonal2618(str_contains($api,'WHERE e.member_user_id=? AND e.voided_at IS NULL'),
  'All live personal entries must be filtered by authenticated user id');
checkPersonal2618(str_contains($api,"(string)$"."entry['source_member_name'],$"."identity)!==$"."uid"),
  'Archive entries must match exact user identity before disclosure');
checkPersonal2618(str_contains($api,'a.review_status="confirmed"'),
  'Historical records must be confirmed');
checkPersonal2618(str_contains($api,'AND NOT EXISTS('),
  'Archive must not duplicate live dates');
checkPersonal2618(str_contains($api,"'item_name'=>(string)$"."entry['item_name']"),
  'Item names must be visible in private detail');
checkPersonal2618(str_contains($api,"'amount_rp'=>(int)$"."entry['amount_rp']"),
  'Rupiah amounts must be visible in private detail');
checkPersonal2618(str_contains($page,"'personal_entries'")&&
  str_contains($page,'BankSampahPersonalDetails2618('),
  'Personal detail UI must be integrated into Profile → Bank Sampah');
checkPersonal2618(str_contains($ui,'Rincian Penimbangan Saya')&&
  str_contains($ui,'Total tanggal ini')&&
  str_contains($ui,'Pilih bulan'),
  'Date/item/month layout missing');
checkPersonal2618(!str_contains($api,'DELETE FROM portal_users')&&
  !str_contains($api,'UPDATE portal_users'),
  'Existing staff data must not change');
echo "Bank Sampah 2618: private own-data detail, Excel archive, Kg/Rp, filters OK\n";
