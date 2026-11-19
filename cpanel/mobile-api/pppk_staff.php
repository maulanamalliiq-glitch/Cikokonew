<?php
declare(strict_types=1);
/**
 * Independent PPPK attendance and leave storage.
 * This deliberately never inserts into PJLP attendance, shifts, or leave tables.
 */
function pppk_staff_schema(PDO $db):void {
 // Production SQL is migrated explicitly, not created on every API request.
 // Users with SELECT/INSERT permission should not need CREATE TABLE grants.
 foreach(['pppk_staff_attendance','pppk_staff_daily',
   'pppk_staff_leave_settings','pppk_staff_leave_requests',
   'pppk_staff_leave_approvals'] as $table){
  try{
   $db->query('SELECT 1 FROM `'.$table.'` LIMIT 0');
  }catch(Throwable $e){
   error_log('[Cikoko PPPK_SCHEMA '.$table.'] '.$e->getMessage());
   mobile_error('Data PPPK belum siap (PPPK_SCHEMA). Admin perlu memasang migrasi database.',503);
  }
 }
}
/** Queue a personal notification in the same DB transaction as leave changes. */
function pppk_staff_notify(PDO $db,string $recipient,string $title,string $message):void{
 if(trim($recipient)==='')return;
 $q=$db->prepare("INSERT INTO mobile_events(category,title,message,audience,recipient)
   VALUES('pppk_leave',?,?,'personal',?)");
 $q->execute([mobile_text($title,240),mobile_text($message,2000),$recipient]);
}
function pppk_staff_official_recipients(array $roles):array{
 $ids=[];
 if(in_array('admin',$roles,true))$ids['admin']=true;
 foreach(db_read('portal_users') as $account){
  if(!is_array($account)||empty($account['active']))continue;
  $id=trim((string)($account['id']??''));
  if($id!==''&&in_array((string)($account['role']??''),$roles,true))$ids[$id]=true;
 }
 return array_keys($ids);
}
function pppk_staff_json_photo(string $encoded):string {
 if(strlen($encoded)>2800000)mobile_error('Foto melebihi batas 2 MB.',422);
 $bytes=base64_decode($encoded,true);
 if($bytes===false||strlen($bytes)<100||strlen($bytes)>2000000)
  mobile_error('Kirim foto kamera JPEG maksimal 2 MB.',422);
 $mime=(new finfo(FILEINFO_MIME_TYPE))->buffer($bytes);
 if($mime!=='image/jpeg')mobile_error('Foto harus JPEG dari kamera.',422);
 return $bytes;
}
function pppk_staff_gps(array $body):array {
 $lat=filter_var($body['latitude']??null,FILTER_VALIDATE_FLOAT);
 $lon=filter_var($body['longitude']??null,FILTER_VALIDATE_FLOAT);
 $accuracy=filter_var($body['accuracy_m']??null,FILTER_VALIDATE_FLOAT);
 if($lat===false||$lon===false||$accuracy===false||
    $lat===null||$lon===null||$accuracy===null||
    abs((float)$lat)>90||abs((float)$lon)>180||
    (float)$accuracy<=0||(float)$accuracy>100)
   mobile_error('GPS tidak akurat. Gunakan lokasi presisi maksimal 100 meter.',422);
 return [(float)$lat,(float)$lon,(float)$accuracy];
}
function pppk_staff_geofence(PDO $db,array $gps):void {
 try{
  $q=$db->query('SELECT latitude,longitude,radius_m FROM pj57_config WHERE id=1');
  $cfg=$q->fetch(PDO::FETCH_ASSOC)?:null;
 }catch(Throwable $e){$cfg=null;}
 if(!$cfg)mobile_error('Peta kantor belum ditetapkan oleh admin.',503);
 $a1=deg2rad($gps[0]);$a2=deg2rad((float)$cfg['latitude']);
 $delta=deg2rad($gps[0]-(float)$cfg['latitude']);
 $lambda=deg2rad($gps[1]-(float)$cfg['longitude']);
 $h=sin($delta/2)**2+cos($a1)*cos($a2)*sin($lambda/2)**2;
 $meters=6371000*2*asin(min(1,sqrt($h)));
 $radius=max(25,min(1000,(int)$cfg['radius_m']));
 if($meters>$radius+$gps[2])mobile_error('Lokasi di luar radius kantor.',422);
}
/** New mobile clients provide an optional capture time; legacy APKs stay usable. */
function pppk_staff_capture_age(array $payload):void {
 if(!array_key_exists('captured_at',$payload))return;
 $raw=$payload['captured_at'];
 if(!is_string($raw)||strlen($raw)>48||!preg_match('/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:\d{2})$/D',$raw))
  mobile_error('Waktu foto tidak valid. Aktifkan tanggal dan jam otomatis.',422);
 try{$captured=new DateTimeImmutable($raw);}catch(Throwable $e){
  mobile_error('Waktu foto tidak dapat dibaca.',422);
 }
 $seconds=time()-$captured->getTimestamp();
 if($seconds < -60 || $seconds > 300)
  mobile_error('Foto harus baru diambil. Sesuaikan jam HP dan ambil ulang.',422);
}

function pppk_staff_date(string $raw):?DateTimeImmutable{
 $d=DateTimeImmutable::createFromFormat('!Y-m-d',$raw,new DateTimeZone('Asia/Jakarta'));
 return $d&&$d->format('Y-m-d')===$raw?$d:null;
}
function pppk_staff_workdays(PDO $db,DateTimeImmutable $from,DateTimeImmutable $to):int {
 // Reuse the official office holiday calendar, not PJLP employee records.
 try{
  $q=$db->prepare('SELECT holiday_date FROM pjlp_holidays WHERE holiday_date BETWEEN ? AND ?');
  $q->execute([$from->format('Y-m-d'),$to->format('Y-m-d')]);
  $holidays=array_flip($q->fetchAll(PDO::FETCH_COLUMN));
 }catch(Throwable $e){
  error_log('[PPPK holiday calendar] '.$e->getMessage());
  mobile_error('Kalender hari libur kantor belum siap.',503);
 }
 $days=0;
 for($d=$from;$d<=$to;$d=$d->modify('+1 day')){
  if((int)$d->format('N')<=5 && !isset($holidays[$d->format('Y-m-d')]))$days++;
 }
 return $days;
}
function pppk_staff_active_account(string $uid,string $role):bool {
 foreach(db_read('portal_users') as $row){
  if((string)($row['id']??'')===$uid&&($row['active']??false)&&
     ($row['role']??'')===$role)return true;
 }
 return false;
}
function pppk_staff_dispatch(string $action,string $method,?array $trustedWebsiteActor=null):void {
 if($trustedWebsiteActor!==null && (!defined('CIKOKO_TRUSTED_WEB_SUPERADMIN') || CIKOKO_TRUSTED_WEB_SUPERADMIN!==true)) mobile_error('Jalur administrator website tidak diizinkan.',403);
 $actor=$trustedWebsiteActor??mobile_auth();$role=(string)$actor['user_role'];$uid=(string)$actor['user_id'];
 $admin=in_array($role,['admin','admin_kelurahan'],true);
 $worker=$role==='pppk';
 $supervisor=in_array($role,['asn','admin_kelurahan'],true);
 $lurah=$role==='lurah';
 if(!$worker&&!$admin&&!$supervisor&&!$lurah)mobile_error('Hanya akun PPPK dan pejabat berwenang.',403);
 $db=mobile_db();pppk_staff_schema($db);
 if($action==='pppk_staff_monitor'&&$method==='GET'){
  if(!$admin)mobile_error('Rekap PPPK hanya untuk administrator.',403);
  $month=(string)($_GET['month']??date('Y-m'));
  if(!preg_match('/^20[2-9][0-9]-(0[1-9]|1[0-2])$/D',$month))
   mobile_error('Periode tidak valid.',422);
  $q=$db->prepare('SELECT id,user_id,work_date,shift_name,report_type,checkin_at,checkout_at,notes,latitude,longitude,accuracy_m,
    TIMESTAMPDIFF(MINUTE,checkin_at,checkout_at) AS worked_minutes
    FROM pppk_staff_attendance WHERE work_date LIKE ? ORDER BY work_date DESC,id DESC LIMIT 300');
  $q->execute([$month.'%']);$items=$q->fetchAll(PDO::FETCH_ASSOC);
  $names=[];
  foreach(db_read('portal_users') as $member)
   if(($member['role']??'')==='pppk')$names[(string)$member['id']]=(string)($member['name']??'PPPK');
  foreach($items as &$item)$item['employee_name']=$names[(string)$item['user_id']]??'PPPK';
  unset($item);
  $q=$db->prepare('SELECT a.id AS attendance_id,a.user_id,d.stage,d.description,d.created_at
    FROM pppk_staff_daily d JOIN pppk_staff_attendance a ON a.id=d.attendance_id
    WHERE a.work_date LIKE ? ORDER BY d.created_at DESC LIMIT 500');
  $q->execute([$month.'%']);
  mobile_json(['ok'=>true,'month'=>$month,'items'=>$items,'reports'=>$q->fetchAll(PDO::FETCH_ASSOC)]);
 }
 if($action==='pppk_staff_photo'&&$method==='GET'){
  $id=(int)($_GET['id']??0);$kind=(string)($_GET['kind']??'');
  if($id<1||!in_array($kind,['checkin','checkout','stage'],true))
   mobile_error('Jenis atau nomor foto tidak valid.',422);
  if($kind==='stage'){
   $stage=(int)($_GET['stage']??-1);
   if(!in_array($stage,[0,50,100],true))mobile_error('Tahap foto tidak valid.',422);
   $q=$db->prepare('SELECT a.user_id,d.photo AS image
     FROM pppk_staff_daily d JOIN pppk_staff_attendance a ON a.id=d.attendance_id
     WHERE a.id=? AND d.stage=? LIMIT 1');
   $q->execute([$id,$stage]);
  }else{
   $column=$kind==='checkin'?'checkin_photo':'checkout_photo';
   $q=$db->prepare('SELECT user_id,'.$column.' AS image FROM pppk_staff_attendance WHERE id=? LIMIT 1');
   $q->execute([$id]);
  }
  $row=$q->fetch(PDO::FETCH_ASSOC);
  if(!$row||!$row['image'])mobile_error('Foto tidak tersedia.',404);
  if(!$admin && (!$worker || (string)$row['user_id']!==$uid))
   mobile_error('Akses foto ditolak.',403);
  header('Content-Type: image/jpeg');
  header('Cache-Control: private, no-store');
  header('X-Content-Type-Options: nosniff');
  echo $row['image'];exit;
 }
 if($action==='pppk_staff_attendance_me'&&$method==='GET'){
  if(!$worker)mobile_error('Kehadiran hanya untuk akun PPPK.',403);
  $month=(string)($_GET['month']??(new DateTimeImmutable('now',new DateTimeZone('Asia/Jakarta')))->format('Y-m'));
  if(!preg_match('/^20[2-9][0-9]-(0[1-9]|1[0-2])$/D',$month))mobile_error('Periode tidak valid.',422);
  $q=$db->prepare("SELECT id,work_date,shift_name,report_type,checkin_at,checkout_at,notes,
   TIMESTAMPDIFF(MINUTE,checkin_at,checkout_at) AS worked_minutes
   FROM pppk_staff_attendance WHERE user_id=? AND work_date LIKE ?
   ORDER BY work_date DESC LIMIT 45");
  $q->execute([$uid,$month.'%']);$items=$q->fetchAll(PDO::FETCH_ASSOC);
  $active=$db->prepare('SELECT id,work_date,shift_name,report_type,checkin_at FROM pppk_staff_attendance WHERE user_id=? AND checkout_at IS NULL ORDER BY id DESC LIMIT 1');
  $active->execute([$uid]);$current=$active->fetch(PDO::FETCH_ASSOC)?:null;
  $stageRows=$db->prepare('SELECT a.id AS attendance_id,a.work_date,d.stage,d.description,d.created_at FROM pppk_staff_daily d JOIN pppk_staff_attendance a ON a.id=d.attendance_id WHERE a.user_id=? AND a.work_date LIKE ? ORDER BY a.work_date DESC,d.stage');
  $stageRows->execute([$uid,$month.'%']);
  mobile_json(['ok'=>true,'month'=>$month,'items'=>$items,'active_shift'=>$current,
   'reports'=>$stageRows->fetchAll(PDO::FETCH_ASSOC),
   'total_work_minutes'=>array_sum(array_map(static fn($v)=>max(0,(int)($v['worked_minutes']??0)),$items)),
   'server_date'=>(new DateTimeImmutable('now',new DateTimeZone('Asia/Jakarta')))->format('Y-m-d')]);
 }
 if($action==='pppk_staff_punch'&&$method==='POST'){
  if(!$worker)mobile_error('Hanya PPPK dapat mengisi kehadiran.',403);
  cikoko_rate_limit($db,'pppk_punch',$uid,16,86400);
  $body=mobile_body();$type=(string)($body['type']??'');
  if(!in_array($type,['checkin','checkout'],true))mobile_error('Aksi absensi tidak valid.',422);
  pppk_staff_capture_age($body);
  $gps=pppk_staff_gps($body);$photo=pppk_staff_json_photo((string)($body['photo_base64']??''));
  $today=new DateTimeImmutable('now',new DateTimeZone('Asia/Jakarta'));
  $time=$today->format('Y-m-d H:i:s');
  if($type==='checkin'){
   $shift=(string)($body['shift']??'');$work=(string)($body['report_type']??'rutin');
   $notes=mobile_text($body['notes']??'',1000);
   if(!in_array($shift,['pagi','siang','malam'],true)||
       !in_array($work,['rutin','dinas_luar'],true))
       mobile_error('Pilih shift dan jenis pekerjaan.',422);
   if($work==='dinas_luar'&&mobile_strlen($notes)<10)
      mobile_error('Dinas luar memerlukan keterangan minimal 10 karakter.',422);
   if($work==='rutin')pppk_staff_geofence($db,$gps);
   $busy=$db->prepare('SELECT id FROM pppk_staff_attendance WHERE user_id=? AND checkout_at IS NULL LIMIT 1');
   $busy->execute([$uid]);
   if($busy->fetchColumn())mobile_error('Selesaikan absensi pulang sebelum masuk lagi.',409);
   try{
    $q=$db->prepare('INSERT INTO pppk_staff_attendance
      (user_id,work_date,shift_name,report_type,checkin_at,latitude,longitude,accuracy_m,checkin_photo,notes)
      VALUES(?,?,?,?,?,?,?,?,?,?)');
    $q->execute([$uid,$today->format('Y-m-d'),$shift,$work,$time,...$gps,$photo,$notes]);
   }catch(PDOException $e){
    if(($e->errorInfo[1]??0)==1062)mobile_error('Kehadiran hari ini sudah tercatat.',409);
    throw $e;
   }
  }else{
   $q=$db->prepare('SELECT id,checkin_at,report_type FROM pppk_staff_attendance WHERE user_id=? AND checkout_at IS NULL ORDER BY id DESC LIMIT 1');
   $q->execute([$uid]);$row=$q->fetch(PDO::FETCH_ASSOC);
   if(!$row)mobile_error('Belum ada absensi masuk aktif.',409);
   if(strtotime($time)-strtotime((string)$row['checkin_at'])>86400)
     mobile_error('Shift lebih dari 24 jam. Hubungi admin untuk koreksi.',409);
   if($row['report_type']==='rutin')pppk_staff_geofence($db,$gps);
   $q=$db->prepare('UPDATE pppk_staff_attendance SET checkout_at=?,checkout_photo=? WHERE id=? AND user_id=? AND checkout_at IS NULL');
   $q->execute([$time,$photo,$row['id'],$uid]);
   if($q->rowCount()!==1)mobile_error('Absensi pulang sudah tercatat.',409);
  }
  mobile_json(['ok'=>true,'message'=>$type==='checkin'?'Absensi masuk berhasil.':'Absensi pulang berhasil.']);
 }
 if($action==='pppk_staff_report'&&$method==='POST'){
  if(!$worker)mobile_error('Laporan hanya untuk akun PPPK.',403);
  $v=mobile_body();$stage=(int)($v['stage']??-1);
  if(!in_array($stage,[0,50,100],true))mobile_error('Tahap laporan tidak valid.',422);
  $desc=mobile_text($v['description']??'',1200);
  if(mobile_strlen($desc)<5)mobile_error('Isi keterangan pekerjaan.',422);
  pppk_staff_capture_age($v);
  // Extra GPS evidence is required by the new camera, but optional for old APKs.
  // Existing leave, attendance and photos remain untouched.
  if(array_key_exists('latitude',$v)){
   $gps=pppk_staff_gps($v);
   $check=$db->prepare('SELECT report_type FROM pppk_staff_attendance
     WHERE user_id=? AND checkout_at IS NULL ORDER BY id DESC LIMIT 1');
   $check->execute([$uid]);
   if($check->fetchColumn()==='rutin')pppk_staff_geofence($db,$gps);
  }
  $photo=pppk_staff_json_photo((string)($v['photo_base64']??''));
  $q=$db->prepare('SELECT id FROM pppk_staff_attendance WHERE user_id=? AND checkout_at IS NULL ORDER BY id DESC LIMIT 1');
  $q->execute([$uid]);$id=(int)$q->fetchColumn();
  if(!$id)mobile_error('Silakan absen masuk dahulu.',409);
  $q=$db->prepare('SELECT stage FROM pppk_staff_daily WHERE attendance_id=? ORDER BY stage');
  $q->execute([$id]);$done=array_map('intval',$q->fetchAll(PDO::FETCH_COLUMN));
  if(in_array($stage,$done,true))mobile_error('Foto tahap ini sudah disimpan.',409);
  if(($stage===50&&!in_array(0,$done,true))||
     ($stage===100&&!in_array(50,$done,true)))
      mobile_error('Kirim laporan secara berurutan 0%, 50%, 100%.',409);
  $q=$db->prepare('INSERT INTO pppk_staff_daily(attendance_id,stage,description,photo,created_at)
    VALUES(?,?,?,?,?)');
  $q->execute([$id,$stage,$desc,(string)$photo,(new DateTimeImmutable('now',new DateTimeZone('Asia/Jakarta')))->format('Y-m-d H:i:s')]);
  mobile_json(['ok'=>true,'message'=>'Laporan tahap '.$stage.'% tersimpan.']);
 }
 if($action==='pppk_staff_leave_me'&&$method==='GET'){
  if(!$worker)mobile_error('Cuti hanya untuk akun PPPK.',403);
  $year=(int)($_GET['year']??date('Y'));
  $q=$db->prepare('SELECT allowance_days,supervisor_user_id FROM pppk_staff_leave_settings WHERE user_id=? AND leave_year=?');
  $q->execute([$uid,$year]);$config=$q->fetch(PDO::FETCH_ASSOC)?:null;
  $q=$db->prepare('SELECT id,start_date,end_date,requested_days,reason,status,official_number,submitted_at FROM pppk_staff_leave_requests WHERE user_id=? ORDER BY id DESC LIMIT 100');
  $q->execute([$uid]);$items=$q->fetchAll(PDO::FETCH_ASSOC);
  $q=$db->prepare("SELECT COALESCE(SUM(requested_days),0) FROM pppk_staff_leave_requests WHERE user_id=? AND leave_year=? AND status IN ('approved','pending_admin','pending_supervisor','pending_lurah')");
  $q->execute([$uid,$year]);$used=(int)$q->fetchColumn();
  mobile_json(['ok'=>true,'year'=>$year,'configured'=>$config!==null,
   'allowance'=>(int)($config['allowance_days']??0),'used_or_held'=>$used,'items'=>$items]);
 }
 if($action==='pppk_staff_leave_apply'&&$method==='POST'){
  if(!$worker)mobile_error('Pengajuan hanya untuk akun PPPK.',403);
  $v=mobile_body();
  $start=pppk_staff_date((string)($v['start_date']??''));
  $end=pppk_staff_date((string)($v['end_date']??''));
  $today=new DateTimeImmutable('today',new DateTimeZone('Asia/Jakarta'));
  if(!$start||!$end||$end<$start||$start<$today||$start->format('Y')!==$end->format('Y')||
     $end->diff($start)->days>30)mobile_error('Tanggal cuti tidak valid atau melebihi 31 hari.',422);
  $reason=mobile_text($v['reason']??'',1000);
  $address=mobile_text($v['leave_address']??'',500);
  $phone=mobile_text($v['phone']??'',40);
  if(mobile_strlen($reason)<10||$address===''||!preg_match('/^[0-9+ -]{8,25}$/',$phone))
    mobile_error('Lengkapi alasan, alamat cuti, dan nomor telepon.',422);
  $days=pppk_staff_workdays($db,$start,$end);
  if($days<1)mobile_error('Pilih rentang cuti yang memiliki hari kerja.',422);
  $year=(int)$start->format('Y');
  // A single advisory lock covers concurrent submissions in the same calendar year.
  $lock='cikoko_staff_leave_'.$year;
  $lockQ=$db->prepare('SELECT GET_LOCK(?,10)');$lockQ->execute([$lock]);
  if((int)$lockQ->fetchColumn()!==1)mobile_error('Sistem cuti sedang sibuk. Coba kembali.',503);
  try{
   $db->beginTransaction();
   $q=$db->prepare('SELECT * FROM pppk_staff_leave_settings WHERE user_id=? AND leave_year=? FOR UPDATE');
   $q->execute([$uid,$year]);$cfg=$q->fetch(PDO::FETCH_ASSOC);
   if(!$cfg)mobile_error('Jatah cuti dan atasan belum ditetapkan admin.',422);
   $q=$db->prepare("SELECT COALESCE(SUM(requested_days),0) FROM pppk_staff_leave_requests
     WHERE user_id=? AND leave_year=? AND status IN ('pending_admin','pending_supervisor','pending_lurah','approved')");
   $q->execute([$uid,$year]);
   if($days+(int)$q->fetchColumn()>(int)$cfg['allowance_days'])
     mobile_error('Sisa jatah cuti tidak mencukupi.',409);
   $a=$start->format('Y-m-d');$b=$end->format('Y-m-d');
   $q=$db->prepare("SELECT id FROM pppk_staff_leave_requests WHERE start_date<=? AND end_date>=? AND status IN ('pending_admin','pending_supervisor','pending_lurah','approved') LIMIT 1");
   $q->execute([$b,$a]);if($q->fetchColumn())mobile_error('Tanggal sudah dipakai pengajuan pegawai PPPK.',409);
   // Preserve the existing one-employee-per-date rule with PJLP as well.
   try{
    $q=$db->prepare("SELECT id FROM pjlp_leave_requests WHERE start_date<=? AND end_date>=? AND status IN ('pending_admin','pending_supervisor','pending_lurah','approved') LIMIT 1");
    $q->execute([$b,$a]);
    if($q->fetchColumn())mobile_error('Tanggal sudah dipakai pengajuan pegawai lain.',409);
   }catch(PDOException $e){
    error_log('[PPPK leave check] '.$e->getMessage());
    mobile_error('Pemeriksaan kalender cuti belum siap pada server.',503);
   }
   $q=$db->prepare('INSERT INTO pppk_staff_leave_requests
     (user_id,leave_year,start_date,end_date,requested_days,reason,leave_address,phone,supervisor_user_id,submitted_at)
     VALUES(?,?,?,?,?,?,?,?,?,?)');
   $q->execute([$uid,$year,$a,$b,$days,$reason,$address,$phone,$cfg['supervisor_user_id'],
     (new DateTimeImmutable('now',new DateTimeZone('Asia/Jakarta')))->format('Y-m-d H:i:s')]);
   $newId=(int)$db->lastInsertId();
   pppk_staff_notify($db,$uid,'Cuti PPPK diajukan',
    'Pengajuan cuti #'.$newId.' diterima dan menunggu pemeriksaan admin.');
   foreach(pppk_staff_official_recipients(['admin','admin_kelurahan']) as $receiver)
    pppk_staff_notify($db,$receiver,'Pengajuan cuti PPPK baru',
     'Cuti PPPK #'.$newId.' menunggu pemeriksaan admin.');
   $db->commit();
  }finally{
   if($db->inTransaction())$db->rollBack();
   $release=$db->prepare('SELECT RELEASE_LOCK(?)');$release->execute([$lock]);
  }
  mobile_json(['ok'=>true,'message'=>'Pengajuan cuti PPPK terkirim untuk verifikasi admin.']);
 }
 if($action==='pppk_staff_leave_admin'&&$method==='GET'){
  if(!$admin&&!$supervisor&&!$lurah)mobile_error('Akses pejabat diperlukan.',403);
  $sql='SELECT r.*,s.allowance_days FROM pppk_staff_leave_requests r LEFT JOIN pppk_staff_leave_settings s
    ON s.user_id=r.user_id AND s.leave_year=r.leave_year';
  $args=[];
  if($supervisor&&!$admin){$sql.=' WHERE r.supervisor_user_id=?';$args[]=$uid;}
  $sql.=' ORDER BY r.id DESC LIMIT 200';
  $q=$db->prepare($sql);$q->execute($args);
  $rows=$q->fetchAll(PDO::FETCH_ASSOC);
  $profiles=[];
  foreach(db_read('portal_users') as $v){
   if(($v['role']??'')==='pppk')$profiles[(string)$v['id']]=$v;
  }
  foreach($rows as &$row)$row['employee_name']=(string)($profiles[(string)$row['user_id']]['name']??'PPPK');
  unset($row);
  $members=[];
  if($admin)foreach($profiles as $id=>$v)if(($v['active']??false))$members[]=[
   'user_id'=>$id,'name'=>(string)($v['name']??''),
  ];
  $supervisors=[];
  if($admin)foreach(db_read('portal_users') as $v)
   if(($v['active']??false)&&in_array(($v['role']??''),['asn','admin_kelurahan'],true))
    $supervisors[]=['user_id'=>(string)$v['id'],'name'=>(string)$v['name']];
  mobile_json(['ok'=>true,'items'=>$rows,'employees'=>$members,'supervisors'=>$supervisors]);
 }
 if($action==='pppk_staff_leave_setting'&&$method==='POST'){
  if(!$admin)mobile_error('Hanya admin yang mengatur cuti PPPK.',403);
  $v=mobile_body();$owner=mobile_text($v['user_id']??'',80);
  $boss=mobile_text($v['supervisor_user_id']??'',80);
  $year=(int)($v['year']??0);$days=(int)($v['allowance_days']??-1);
  if(!pppk_staff_active_account($owner,'pppk')||$year<2025||$year>2100||
     $days<0||$days>60)mobile_error('Pengaturan pegawai atau jatah cuti tidak valid.',422);
  if(!pppk_staff_active_account($boss,'asn')&&!pppk_staff_active_account($boss,'admin_kelurahan'))
    mobile_error('Atasan langsung harus ASN atau Admin Kelurahan.',422);
  $q=$db->prepare('INSERT INTO pppk_staff_leave_settings
    (user_id,supervisor_user_id,leave_year,allowance_days,updated_by,updated_at)
    VALUES(?,?,?,?,?,NOW()) ON DUPLICATE KEY UPDATE supervisor_user_id=VALUES(supervisor_user_id),
    allowance_days=VALUES(allowance_days),
    updated_by=VALUES(updated_by),updated_at=NOW()');
  $q->execute([$owner,$boss,$year,$days,$uid]);
  mobile_json(['ok'=>true,'message'=>'Jatah dan atasan PPPK berhasil ditetapkan.']);
 }
 if($action==='pppk_staff_leave_review'&&$method==='POST'){
  if(!$admin&&!$supervisor&&!$lurah)mobile_error('Akses pejabat diperlukan.',403);
  $v=mobile_body();$id=(int)($v['id']??0);
  $decision=(string)($v['decision']??'');$note=mobile_text($v['note']??'',1000);
  if($id<1||!in_array($decision,['approve','reject'],true)||
     ($decision==='reject'&&mobile_strlen($note)<5))
      mobile_error('Keputusan dan alasan penolakan wajib diisi.',422);
  $db->beginTransaction();
  try{
   $q=$db->prepare('SELECT * FROM pppk_staff_leave_requests WHERE id=? FOR UPDATE');
   $q->execute([$id]);$leave=$q->fetch(PDO::FETCH_ASSOC);
   if(!$leave)mobile_error('Permohonan cuti tidak ditemukan.',404);
   $status=(string)$leave['status'];$stage='';
   if($status==='pending_admin'&&$admin){$stage='admin';$next='pending_supervisor';}
   elseif($status==='pending_supervisor'&&$supervisor&&$uid===(string)$leave['supervisor_user_id']){$stage='supervisor';$next='pending_lurah';}
   elseif($status==='pending_lurah'&&$lurah){$stage='lurah';$next='approved';}
   else mobile_error('Bukan tahap persetujuan Anda.',403);
   $q=$db->prepare('INSERT INTO pppk_staff_leave_approvals
     (request_id,stage,actor_id,decision,note,created_at) VALUES(?,?,?,?,?,NOW())');
   $q->execute([$id,$stage,$uid,$decision,$note]);
   $next=$decision==='reject'?'rejected':$next;
   $q=$db->prepare('UPDATE pppk_staff_leave_requests SET status=?,reviewed_at=NOW() WHERE id=?');
   $q->execute([$next,$id]);
   $label=[
    'pending_supervisor'=>'menunggu atasan langsung',
    'pending_lurah'=>'menunggu Lurah',
    'approved'=>'disetujui',
    'rejected'=>'ditolak',
   ][$next]??$next;
   pppk_staff_notify($db,(string)$leave['user_id'],'Status cuti PPPK #'.$id,
    'Pengajuan cuti PPPK #'.$id.' '.$label.'.');
   if($next==='pending_supervisor')
    pppk_staff_notify($db,(string)$leave['supervisor_user_id'],
     'Persetujuan atasan: Cuti PPPK','Cuti PPPK #'.$id.' menunggu keputusan Anda.');
   if($next==='pending_lurah')
    foreach(pppk_staff_official_recipients(['lurah']) as $receiver)
     pppk_staff_notify($db,$receiver,'Persetujuan Lurah: Cuti PPPK',
      'Cuti PPPK #'.$id.' menunggu keputusan Lurah.');
   $db->commit();
  }finally{if($db->inTransaction())$db->rollBack();}
  mobile_json(['ok'=>true,'message'=>'Keputusan cuti PPPK berhasil dicatat.']);
 }
 mobile_error('Aksi modul pegawai PPPK belum tersedia.',404);
}
