<?php
declare(strict_types=1);
$root=dirname(__DIR__);
$php=file_get_contents($root.'/cpanel/mobile-api/bank_sampah_2610.php');
$flutter=file_get_contents($root.'/flutter/lib/cikoko_bank_sampah_2610.dart');
if(!is_string($php)||!is_string($flutter))
    throw new RuntimeException('File Bank Sampah tidak ada.');
function ckbs2617check(bool $passed,string $why):void{
    if(!$passed)throw new RuntimeException('Bank Sampah Profile 2617: '.$why);
}
foreach([
  'mobile_bank_sampah_archive_member_links_2026',
  'function ckbs_archive_identity_map(',
  'function ckbs_archive_match_account(',
  'function ckbs_archive_confirmed_rows(',
  'a.review_status="confirmed"',
  'AND NOT EXISTS(',
  'if($year===2026)',
  'archived_entries',
  "if($action==='archive_link_set')",
  "'archive_link_set'=>'POST'",
  'if($admin){',
  'matched_user_id',
  'verified_manually',
  "'member_user_id'=>$realId??",
] as $token)ckbs2617check(str_contains($php,$token),'Missing: '.$token);

ckbs2617check(str_contains($php,'if(array_key_exists($key,$unique))$unique[$key]=null;'),
    'Duplicate account names cannot be matched automatically.');
ckbs2617check(str_contains($php,'$identity[\'exact\']')&&
    str_contains($php,'$identity[\'manual\']'),
    'Require exact unique or explicit Admin verification.');
ckbs2617check(str_contains($php,'$rows[]=[\n              \'weight_kg\'')===false
    || str_contains($php,"'amount_rp'=>(int)$"."historical['amount_rp']"),
    'Summary should combine verified archive and live amounts.');
ckbs2617check(str_contains($php,"$"."st->fetchAll(PDO::FETCH_ASSOC)"),
    'Never remove existing live session amounts.');
ckbs2617check(str_contains($flutter,'archiveMappingPanel()')&&
    str_contains($flutter,'verifyArchiveMember('),
    'Super Admin must be able to resolve unrecognized Excel names.');
ckbs2617check(str_contains($flutter,"'archive_link_set'"),
    'Super Admin map must save to server.');
ckbs2617check(!str_contains($php,'UPDATE portal_users') &&
              !str_contains($php,'DELETE FROM portal_users'),
    'Must never modify original staff accounts.');
echo "BANK SAMPAH 2617: individual 2026 totals, exact unique mapping, Admin aliases and privacy OK\n";
