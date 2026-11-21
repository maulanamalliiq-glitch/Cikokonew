<?php
declare(strict_types=1);
// Pure source-code test: no database, no server mutation.
$root=dirname(__DIR__);
$nav=file_get_contents($root.'/flutter/lib/cikoko_v6_showcase.dart');
$app=file_get_contents($root.'/flutter/lib/main.dart');
if(!is_string($nav)||!is_string($app))throw new RuntimeException('App sources missing.');
$expected=[
 "('Layanan',Icons.widgets_outlined",
 "('Inovasi',Icons.auto_awesome_outlined",
 "('Beranda',Icons.home_outlined",
 "('Laporan',Icons.assignment_outlined",
 "('Profil',Icons.person_outline",
];
$positions=[];
foreach($expected as $text){
  $pos=strpos($nav,$text);
  if($pos===false)throw new RuntimeException('Nav destination missing: '.$text);
  $positions[]=$pos;
}
if($positions!==array_values(array_unique($positions))||$positions!==array_values(array_unique(array_filter($positions,fn($p)=>true)))){
 throw new RuntimeException('Navigation order is inconsistent.');
}
for($i=1;$i<count($positions);$i++){
 if($positions[$i]<=$positions[$i-1])throw new RuntimeException('Navbar order mismatch.');
}
if(!str_contains($app,"case 3: switchTo('Laporan Terpadu');break;"))
 throw new RuntimeException('Reports destination is not routed to the Reports Hub.');
if(!str_contains($app,"if(route=='Laporan Terpadu')nav=3;"))
 throw new RuntimeException('Reports selection state is incorrect.');
if(!str_contains($app,"bottomNavigationBar:V6BottomNavigation(selected:nav,onSelected:selectNav)"))
 throw new RuntimeException('Unified bottom navigation is not in use.');
if(!str_contains($app,"FloatingActionButton.small(")||
 !str_contains($app,"?'Pesan Masuk':'Hubungi Kami'"))
 throw new RuntimeException('Floating chat button is missing for users or Admin.');
echo "Navbar Layanan / Inovasi / Beranda / Laporan / Profil & floating chat OK\n";
