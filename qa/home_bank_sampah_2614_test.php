<?php
declare(strict_types=1);
$root=dirname(__DIR__);
$home=file_get_contents($root.'/flutter/lib/cikoko_v6_showcase.dart');
$activity=file_get_contents($root.'/flutter/lib/cikoko_activity_updates_2614.dart');
$form=file_get_contents($root.'/flutter/lib/cikoko_bank_sampah_mockup_2613.dart');
$api=file_get_contents($root.'/cpanel/mobile-api/bank_sampah_2610.php');
function check2614(bool $value,string $error):void {
 if(!$value)throw new RuntimeException($error);
}
foreach([$home,$activity,$form,$api] as $src)check2614(is_string($src)&&strlen($src)>400,'Source missing.');

// Support both the historical static home and SDUI 2620. The latter must
// preserve every native widget and the exact default order, but may re-order
// it after a validated Admin Utama publication.
if(str_contains($home,'CikokoUiHome2620(')){
  $order=strpos($home,"'hero', 'news', 'announcement', 'bank_annual', 'letters'");
  check2614($order!==false,
    'SDUI default must retain Berita, Agenda, Bank Sampah and Surat order.');
  foreach([
    "'news': V6NewsCarousel(",
    "'announcement': V6AnnouncementTicker(",
    "'bank_annual': const BankSampahAnnualHome2618()",
    "'letters': V6LetterStatusStrip(",
    "'boarding': V6BoardingHousePreview(",
    "'innovation': V6InnovationPreview(",
    "'activity': CikokoActivityUpdates2614("
  ] as $signature){
    check2614(str_contains($home,$signature),'Missing protected home widget: '.$signature);
  }
  $client=file_get_contents($root.'/flutter/lib/cikoko_sdui_2620.dart');
  check2614(str_contains($client,"key == 'letters'")&&
    str_contains($client,"if (visible[key] != false || key == 'letters')"),
    'Status pelayanan surat must always be visible in SDUI.');
}else{
  $news=strpos($home,"V6NewsCarousel(items:items,api:api,onOpen:articleTap");
  $agenda=strpos($home,"V6AnnouncementTicker(items:items,onAll:()=>navigate('Pengumuman'))");
  $status=strpos($home,"V6LetterStatusStrip(counts:letterCounts,onStatus:letterStatus)");
  $kos=strpos($home,"V6BoardingHousePreview(api:api,onAll:()=>navigate('Data Rumah Kos'))");
  $inovasi=strpos($home,"V6InnovationPreview(api:api,onAll:()=>navigate('Inovasi'))");
  $activities=strpos($home,"CikokoActivityUpdates2614(role:role,navigate:navigate)");
  check2614($news!==false&&$agenda!==false&&$status!==false,
    'Missing Berita/Agenda/Surat blocks.');
  check2614($news<$agenda&&$agenda<$status,
    'The default home order must be Berita, Agenda, Surat.');
  check2614($kos!==false&&$inovasi!==false&&$activities!==false&&
    $kos<$inovasi&&$inovasi<$activities,
    'Jumantik/Bank Sampah must appear below Inovasi.');
}
check2614(str_contains($activity,'Jumantik2605Api.news()')&&
 str_contains($activity,'CikokoJumantikMandiri2607.news()'),
 'Use only published Jumantik feeds, never unverified reports.');
check2614(str_contains($activity,"'action':'public_activity'"),
 'Bank Sampah updates must use the public approved aggregate API.');
check2614(str_contains($api,"if(\$action==='public_activity')"),
 'Missing new Bank Sampah public aggregate endpoint.');
check2614(str_contains($api,'s.status="closed"')&&
 str_contains($api,'SUM(e.weight_kg)')&&
 str_contains($api,'SUM(e.amount_rp)'),
 'Activity must contain approved aggregated Kg and rupiah only.');
check2614(str_contains($api,"'date'=>(string)\$row['session_date']")&&
 !str_contains($api,"'member_user_id'=>(string)\$row['member_user_id']"),
 'Public activity response must not expose individual members.');
check2614(str_contains($form,'bank_table_compact_header_2614')&&
 str_contains($form,'constraints.maxWidth<470'),
 'Phone table must be compact, not a horizontally cut five-column row.');
check2614(str_contains($form,"for(final member in eligibleMembers)")&&
 str_contains($form,'if(row.id==null&&!_hasContent(row))continue;'),
 'Employee names must autofill, but empty rows must not be saved.');
check2614(str_contains($api,'INSERT IGNORE INTO mobile_bank_sampah_members_2610')&&
 str_contains($api,'system-2614'),
 'Sync only new active PJLP/PPPK users, preserve Admin-disabled membership.');
check2614(!str_contains($api,'DELETE FROM portal_users')&&!str_contains($api,'UPDATE portal_users'),
 'Do not edit/delete original accounts.');
echo "HOME/ROSTER 2614: Berita-Agenda-Surat, latest verified activities, compact table PASSED\n";
