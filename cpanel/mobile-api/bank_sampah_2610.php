<?php
declare(strict_types=1);
/**
 * Bank Sampah Cikoko 2610. Isolated additive API.
 * Members are a roster, NOT user account creation/deletion. All staff roles,
 * permissions, profiles, PJLP/PPPK reports and attendance remain untouched.
 */
ini_set('display_errors','0');
header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: private,no-store');
header('X-Content-Type-Options: nosniff');
set_exception_handler(static function(Throwable $e):void {
    error_log('[Cikoko Bank Sampah 2610] '.$e->getMessage());
    if(!headers_sent())http_response_code(503);
    echo json_encode(['ok'=>false,'error'=>'Layanan Bank Sampah sedang mengalami kendala.'],JSON_UNESCAPED_UNICODE);
});
require_once __DIR__.'/bootstrap.php';

const CKBS_PREFIX='mobile_bank_sampah_';
const CKBS_ROLE_VIEW=['admin','admin_kelurahan','asn','lurah'];
const CKBS_ROLE_MEMBER=['pjlp','pppk'];

function ckbs_schema(PDO $db):void {
    static $done=false;if($done)return;
    // Identical to additive SQL migration. Safe for repeated requests.
    $tables=[
      'CREATE TABLE IF NOT EXISTS mobile_bank_sampah_config_2610 (
        id TINYINT UNSIGNED NOT NULL PRIMARY KEY,
        cadence VARCHAR(24) NOT NULL DEFAULT "twice_monthly",
        anchor_month TINYINT UNSIGNED NOT NULL DEFAULT 1,
        members_initialized TINYINT(1) NOT NULL DEFAULT 0,
        updated_by VARCHAR(80) NOT NULL DEFAULT "",
        updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4',
      'CREATE TABLE IF NOT EXISTS mobile_bank_sampah_members_2610 (
        user_id VARCHAR(80) NOT NULL PRIMARY KEY,
        active TINYINT(1) NOT NULL DEFAULT 1,
        assigned_by VARCHAR(80) NOT NULL,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        INDEX idx_active(active)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4',
      'CREATE TABLE IF NOT EXISTS mobile_bank_sampah_officers_2610 (
        user_id VARCHAR(80) NOT NULL PRIMARY KEY,
        active TINYINT(1) NOT NULL DEFAULT 1,
        assigned_by VARCHAR(80) NOT NULL,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        INDEX idx_active(active)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4',
      'CREATE TABLE IF NOT EXISTS mobile_bank_sampah_sessions_2610 (
        id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
        session_date DATE NOT NULL UNIQUE,
        status VARCHAR(12) NOT NULL DEFAULT "open",
        note VARCHAR(240) NOT NULL DEFAULT "",
        created_by VARCHAR(80) NOT NULL,updated_by VARCHAR(80) NOT NULL,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        INDEX idx_date(status,session_date)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4',
      'CREATE TABLE IF NOT EXISTS mobile_bank_sampah_entries_2610 (
        id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
        session_id BIGINT UNSIGNED NOT NULL,
        member_user_id VARCHAR(80) NOT NULL,
        item_name VARCHAR(140) NOT NULL,
        weight_kg DECIMAL(12,3) NOT NULL,
        amount_rp BIGINT UNSIGNED NOT NULL DEFAULT 0,
        entered_by VARCHAR(80) NOT NULL,updated_by VARCHAR(80) NOT NULL,
        voided_at DATETIME DEFAULT NULL,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        INDEX idx_session(session_id,voided_at),
        INDEX idx_member(member_user_id,voided_at),
        CONSTRAINT fk_bank2610_session FOREIGN KEY (session_id)
          REFERENCES mobile_bank_sampah_sessions_2610(id) ON DELETE RESTRICT
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4',
      // Independent historical archive: never overwrite live 2610 sessions/entries.
      'CREATE TABLE IF NOT EXISTS mobile_bank_sampah_archive_sessions_2026 (
        session_date DATE NOT NULL PRIMARY KEY,
        source_sheet VARCHAR(90) NOT NULL,
        reported_weight_kg DECIMAL(12,3) NOT NULL,
        reported_amount_rp BIGINT UNSIGNED NOT NULL,
        source_label VARCHAR(120) NOT NULL DEFAULT "Bank Sampah Mandiri PPSU Kelurahan Cikoko.xlsx",
        imported_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4',
      'CREATE TABLE IF NOT EXISTS mobile_bank_sampah_archive_entries_2026 (
        source_key CHAR(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL PRIMARY KEY,
        session_date DATE NOT NULL,
        source_sheet VARCHAR(90) NOT NULL,
        source_row SMALLINT UNSIGNED NOT NULL,
        source_member_name VARCHAR(160) NOT NULL,
        item_name VARCHAR(140) NOT NULL,
        unit_price_rp BIGINT UNSIGNED NOT NULL,
        weight_kg DECIMAL(12,3) NOT NULL,
        amount_rp BIGINT UNSIGNED NOT NULL,
        review_status VARCHAR(16) NOT NULL DEFAULT "confirmed",
        imported_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        INDEX idx_bank2026_date (session_date,review_status),
        INDEX idx_bank2026_name (source_member_name),
        CONSTRAINT fk_bank2026_session FOREIGN KEY(session_date)
           REFERENCES mobile_bank_sampah_archive_sessions_2026(session_date) ON DELETE RESTRICT
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4',
    ];
    foreach($tables as $sql)$db->exec($sql);
    $db->exec('INSERT IGNORE INTO mobile_bank_sampah_config_2610
       (id,cadence,anchor_month,members_initialized) VALUES (1,"twice_monthly",1,0)');
    $done=true;
}

function ckbs_users():array {
    $out=[];
    foreach(db_read('portal_users') as $r){
        if(!is_array($r)||!isset($r['id']))continue;
        $out[(string)$r['id']]=[
         'id'=>(string)$r['id'],'name'=>(string)($r['name']??''),
         'role'=>(string)($r['role']??''),'active'=>!empty($r['active'])
        ];
    }
    return $out;
}
function ckbs_member_init(PDO $db,array $users):void {
    // Staff roster follows existing active PJLP/PPPK accounts each year.
    // INSERT IGNORE only adds genuinely new accounts; an Admin-disabled
    // member retains active=0 and is NEVER reactivated automatically.
    $db->beginTransaction();
    try{
        $cfg=$db->query('SELECT members_initialized FROM mobile_bank_sampah_config_2610
         WHERE id=1 FOR UPDATE')->fetch(PDO::FETCH_ASSOC);
        $insert=$db->prepare('INSERT IGNORE INTO mobile_bank_sampah_members_2610
             (user_id,active,assigned_by) VALUES (?,1,"system-2614")');
        foreach($users as $u){
            if($u['active']&&in_array($u['role'],CKBS_ROLE_MEMBER,true))
                $insert->execute([$u['id']]);
        }
        if(empty($cfg['members_initialized'])){
            $db->exec('UPDATE mobile_bank_sampah_config_2610
                 SET members_initialized=1 WHERE id=1');
        }
        $db->commit();
    }catch(Throwable $e){if($db->inTransaction())$db->rollBack();throw $e;}
}
function ckbs_only_role(array $actor,array $roles):void {
    if(!in_array((string)($actor['user_role']??''),$roles,true))
        mobile_error('Akun Anda tidak memiliki izin untuk Bank Sampah.',403);
}
function ckbs_officer(PDO $db,array $actor):bool {
    if($actor['user_role']==='admin')return true;
    if(!in_array((string)$actor['user_role'],CKBS_ROLE_MEMBER,true))return false;
    $q=$db->prepare('SELECT 1 FROM mobile_bank_sampah_officers_2610
      WHERE user_id=? AND active=1 LIMIT 1');
    $q->execute([(string)$actor['user_id']]);
    return (bool)$q->fetchColumn();
}
function ckbs_full_view(PDO $db,array $actor):bool {
    return in_array((string)$actor['user_role'],CKBS_ROLE_VIEW,true)||
         ckbs_officer($db,$actor);
}
function ckbs_valid_date(string $date):DateTimeImmutable {
    $d=DateTimeImmutable::createFromFormat('!Y-m-d',$date,new DateTimeZone('Asia/Jakarta'));
    if(!$d||$d->format('Y-m-d')!==$date)mobile_error('Tanggal kegiatan tidak valid.',422);
    return $d;
}
function ckbs_year(mixed $raw):int {
    $year=filter_var($raw,FILTER_VALIDATE_INT);
    if($year===false||$year<2020||$year>2100)
        mobile_error('Tahun rekap tidak valid.',422);
    return $year;
}
function ckbs_id(mixed $raw):int {
    $id=filter_var($raw,FILTER_VALIDATE_INT,['options'=>['min_range'=>1]]);
    if($id===false||$id===null)mobile_error('Nomor data tidak valid.',422);
    return (int)$id;
}
function ckbs_schedule(int $year,string $cadence,int $anchor):array {
    $out=[];
    for($month=1;$month<=12;$month++){
        if($cadence==='every_two_months' && (($month-$anchor+12)%2)!==0)continue;
        $first=new DateTimeImmutable(sprintf('%04d-%02d-01',$year,$month),
              new DateTimeZone('Asia/Jakarta'));
        $offset=(7-(int)$first->format('w'))%7;
        $days=$cadence==='twice_monthly'?[8+$offset,22+$offset]:[8+$offset];
        foreach($days as $day)$out[]=sprintf('%04d-%02d-%02d',$year,$month,$day);
    }
    return $out;
}
function ckbs_config(PDO $db):array {
    return $db->query('SELECT cadence,anchor_month FROM mobile_bank_sampah_config_2610 WHERE id=1')
      ->fetch(PDO::FETCH_ASSOC) ?: ['cadence'=>'twice_monthly','anchor_month'=>1];
}
function ckbs_archive_report_name(string $source):string {
    // Full names confirmed in the SAME ordinal roster from later 2026 sheets.
    // Keep the literal source_member_name unchanged in the audit archive.
    // Do NOT use this matching to claim any live portal account.
    static $known=[
       'Subhan'=>'Aan Subhan','Somad'=>'Abdul Somad',
       'Sauki'=>'Achmad Sauqie','Ady'=>'Ady Dwi Harjanto',
       'Agus K'=>'Agus Kurniawan','Agus S'=>'Agus Santoso',
       'Dalo'=>'Ami Dalo','Awal'=>'Awaludin',
       'Baskara'=>'Baskara Nirwana','Dimas'=>'Dimas Ichsan Ashari',
       'Edwin'=>'Edwin Dwi Effendi','Melly P'=>'Melly Puspitoningrum',
       'Mellyda SD'=>'Mellyda Sari Daulay'
    ];
    return $known[$source]??$source;
}

function ckbs_entries(PDO $db,int $year,array $users,?int $sessionId=null):array {
    $sql='SELECT e.id,e.session_id,e.member_user_id,e.item_name,e.weight_kg,
       e.amount_rp,e.entered_by,e.updated_at,s.session_date,s.status AS session_status
       FROM mobile_bank_sampah_entries_2610 e
       JOIN mobile_bank_sampah_sessions_2610 s ON s.id=e.session_id
       WHERE e.voided_at IS NULL';
    $args=[];
    if($sessionId!==null){$sql.=' AND e.session_id=?';$args[]=$sessionId;}
    else{$sql.=' AND s.session_date>=? AND s.session_date<?';
         $args[]=$year.'-01-01';$args[]=($year+1).'-01-01';}
    $sql.=' ORDER BY s.session_date DESC,e.id DESC LIMIT 6000';
    $q=$db->prepare($sql);$q->execute($args);
    $rows=$q->fetchAll(PDO::FETCH_ASSOC);
    $result=array_map(static function($r)use($users){
        $r['id']=(int)$r['id'];$r['session_id']=(int)$r['session_id'];
        $r['weight_kg']=(string)$r['weight_kg'];
        $r['amount_rp']=(int)$r['amount_rp'];
        $r['member_name']=$users[(string)$r['member_user_id']]['name']??'Pegawai (akun tidak aktif)';
        return $r;
    },$rows);
    if($sessionId===null && $year===2026){
        // Source names in older Excel sheets cannot safely be mapped to
        // live portal user IDs without explicit identity verification.
        // Historical rows are annual read-only; never affect personal role,
        // account status or already entered live sessions.
        // To prevent double counting, a date with ANY live weighed item
        // takes precedence over its archived copy in the annual totals.
        $sqlArchive='SELECT a.session_date,a.source_row,a.source_member_name,
             a.item_name,a.weight_kg,a.amount_rp,a.source_sheet
          FROM mobile_bank_sampah_archive_entries_2026 a
          WHERE a.review_status="confirmed"
            AND NOT EXISTS(
              SELECT 1 FROM mobile_bank_sampah_sessions_2610 s
              JOIN mobile_bank_sampah_entries_2610 e
                ON e.session_id=s.id AND e.voided_at IS NULL
              WHERE s.session_date=a.session_date
            )
          ORDER BY a.session_date DESC,a.source_row DESC LIMIT 6000';
        $historical=$db->query($sqlArchive)->fetchAll(PDO::FETCH_ASSOC);
        foreach($historical as $item){
            $sourceName=(string)$item['source_member_name'];
            $reportName=ckbs_archive_report_name($sourceName);
            $result[]=[
              'id'=>0,'session_id'=>0,'member_user_id'=>'archive26_'.
                substr(hash('sha256',strtolower($reportName)),0,20),
              'member_name'=>$reportName,'source_member_name'=>$sourceName,'item_name'=>(string)$item['item_name'],
              'weight_kg'=>(string)$item['weight_kg'],
              'amount_rp'=>(int)$item['amount_rp'],
              'session_date'=>(string)$item['session_date'],
              'session_status'=>'closed','entered_by'=>'archive-2026',
              'updated_at'=>null,'source_sheet'=>$item['source_sheet'],
              'source_row'=>(int)$item['source_row'],'archive_2026'=>true
            ];
        }
    }
    return $result;
}
function ckbs_totals(array $rows):array {
    $grams=0;$rupiah=0;
    foreach($rows as $r){$grams+=(int)round((float)$r['weight_kg']*1000);$rupiah+=(int)$r['amount_rp'];}
    return ['weight_kg'=>number_format($grams/1000,3,'.',''),'amount_rp'=>$rupiah,
      'entries'=>count($rows)];
}

$action=(string)($_GET['action']??'');
$method=(string)($_SERVER['REQUEST_METHOD']??'GET');
$methods=[
 'public_activity'=>'GET','archive_2026'=>'GET','status'=>'GET','summary'=>'GET','dashboard'=>'GET','members'=>'GET','schedule'=>'GET',
 'session_entries'=>'GET','annual'=>'GET','annual_csv'=>'GET',
 'member_set'=>'POST','officer_set'=>'POST','config_set'=>'POST',
 'session_create'=>'POST','session_submit'=>'POST','session_status'=>'POST','entry_save'=>'POST','entry_void'=>'POST'
];
if(!isset($methods[$action]))mobile_error('Layanan Bank Sampah tidak tersedia.',404);
if($methods[$action]!==$method)mobile_error('Metode tidak diizinkan.',405);
// Public bulletin: only already approved/closed aggregate weighing sessions.
// Never expose staff names, individual amounts, phone numbers or draft results.
if($action==='public_activity'){
    $db=mobile_db();
    $q=$db->query('SELECT s.session_date,
        COALESCE(SUM(e.weight_kg),0) AS weight_kg,
        COALESCE(SUM(e.amount_rp),0) AS amount_rp,
        COUNT(e.id) AS entries
      FROM mobile_bank_sampah_sessions_2610 s
      JOIN mobile_bank_sampah_entries_2610 e
        ON e.session_id=s.id AND e.voided_at IS NULL
      WHERE s.status="closed" AND s.session_date<=CURDATE()
      GROUP BY s.id,s.session_date
      HAVING COUNT(e.id)>0
      ORDER BY s.session_date DESC,s.id DESC
      LIMIT 3');
    $items=[];
    foreach($q->fetchAll(PDO::FETCH_ASSOC) as $row){
        $items[]=[
          'date'=>(string)$row['session_date'],
          'weight_kg'=>(string)$row['weight_kg'],
          'amount_rp'=>(int)$row['amount_rp'],
          'entries'=>(int)$row['entries'],
        ];
    }
    mobile_json(['ok'=>true,'items'=>$items]);
}
$actor=mobile_auth();
ckbs_only_role($actor,['admin','admin_kelurahan','asn','lurah','pjlp','pppk']);
$db=mobile_db();ckbs_schema($db);
$users=ckbs_users();ckbs_member_init($db,$users);
$uid=(string)$actor['user_id'];$role=(string)$actor['user_role'];
$full=ckbs_full_view($db,$actor);$admin=$role==='admin';
if($action==='status'){
    $cfg=ckbs_config($db);
    mobile_json(['ok'=>true,'role'=>$role,'can_input'=>ckbs_officer($db,$actor),
      'can_view_full'=>$full,'can_manage'=>$admin,
      'cadence'=>$cfg['cadence'],'anchor_month'=>(int)$cfg['anchor_month']]);
}
if($action==='summary'){
    ckbs_only_role($actor,CKBS_ROLE_MEMBER);
    $year=ckbs_year($_GET['year']??date('Y'));
    // Profile headline shows this member's totals for the selected calendar year.
    $st=$db->prepare('SELECT e.weight_kg,e.amount_rp FROM mobile_bank_sampah_entries_2610 e
     JOIN mobile_bank_sampah_sessions_2610 s ON s.id=e.session_id
     WHERE e.member_user_id=? AND e.voided_at IS NULL
       AND s.session_date>=? AND s.session_date<?');
    $st->execute([$uid,$year.'-01-01',($year+1).'-01-01']);
    mobile_json(['ok'=>true,'year'=>$year,'totals'=>ckbs_totals($st->fetchAll(PDO::FETCH_ASSOC))]);
}
if($action==='members'){
    if(!$full)mobile_error('Hanya petugas, ASN atau Admin dapat melihat daftar anggota.',403);
    $members=[];
    $q=$db->query('SELECT user_id,active FROM mobile_bank_sampah_members_2610');
    foreach($q->fetchAll(PDO::FETCH_ASSOC) as $r)$members[$r['user_id']]=(bool)$r['active'];
    $officers=[];
    $q=$db->query('SELECT user_id FROM mobile_bank_sampah_officers_2610 WHERE active=1');
    foreach($q->fetchAll(PDO::FETCH_ASSOC) as $r)$officers[(string)$r['user_id']]=true;
    $rows=[];
    foreach($users as $u){
        if(!in_array($u['role'],CKBS_ROLE_MEMBER,true))continue;
        if(!$admin && (!$u['active']||empty($members[$u['id']])))continue;
        $rows[]=$u+['is_member'=>!empty($members[$u['id']]),
                    'is_officer'=>!empty($officers[$u['id']])];
    }
    usort($rows,static fn($a,$b)=>strnatcasecmp($a['name'],$b['name']));
    mobile_json(['ok'=>true,'items'=>$rows,'officer_count'=>count($officers)]);
}
if($action==='schedule'||$action==='dashboard'){
    if(!$full)mobile_error('Hanya petugas, ASN atau Admin dapat membuka jadwal kegiatan.',403);
    $year=ckbs_year($_GET['year']??date('Y'));
    $cfg=ckbs_config($db);
    $q=$db->prepare('SELECT s.id,s.session_date,s.status,s.note,
     COALESCE(SUM(CASE WHEN e.voided_at IS NULL THEN e.weight_kg ELSE 0 END),0) AS weight_kg,
     COALESCE(SUM(CASE WHEN e.voided_at IS NULL THEN e.amount_rp ELSE 0 END),0) AS amount_rp,
     COUNT(CASE WHEN e.voided_at IS NULL THEN e.id END) AS entries
     FROM mobile_bank_sampah_sessions_2610 s
     LEFT JOIN mobile_bank_sampah_entries_2610 e ON e.session_id=s.id
     WHERE s.session_date>=? AND s.session_date<?
     GROUP BY s.id,s.session_date,s.status,s.note ORDER BY s.session_date DESC');
    $q->execute([$year.'-01-01',($year+1).'-01-01']);
    mobile_json(['ok'=>true,'year'=>$year,'cadence'=>$cfg['cadence'],
      'anchor_month'=>(int)$cfg['anchor_month'],
      'suggested_dates'=>ckbs_schedule($year,(string)$cfg['cadence'],(int)$cfg['anchor_month']),
      'sessions'=>$q->fetchAll(PDO::FETCH_ASSOC),'can_input'=>ckbs_officer($db,$actor),
      'can_manage'=>$admin]);
}
if($action==='session_entries'){
    if(!$full)mobile_error('Tidak memiliki izin membaca tabel timbang.',403);
    $sessionId=ckbs_id($_GET['session_id']??null);
    $session=$db->prepare('SELECT id,session_date,status,note FROM mobile_bank_sampah_sessions_2610 WHERE id=?');
    $session->execute([$sessionId]);$s=$session->fetch(PDO::FETCH_ASSOC);
    if(!$s)mobile_error('Sesi penimbangan tidak ditemukan.',404);
    $rows=ckbs_entries($db,(int)substr($s['session_date'],0,4),$users,$sessionId);
    mobile_json(['ok'=>true,'session'=>$s,'items'=>$rows,'totals'=>ckbs_totals($rows)]);
}
if($action==='archive_2026'){
    if(!$full)mobile_error('Hanya petugas, ASN atau Admin dapat melihat arsip tahun 2026.',403);
    $s=$db->query('SELECT session_date,source_sheet,reported_weight_kg,reported_amount_rp
       FROM mobile_bank_sampah_archive_sessions_2026 ORDER BY session_date')->fetchAll(PDO::FETCH_ASSOC);
    $q=$db->query('SELECT review_status,COUNT(*) AS total_rows,
       COALESCE(SUM(weight_kg),0) AS weight_kg,
       COALESCE(SUM(amount_rp),0) AS amount_rp
       FROM mobile_bank_sampah_archive_entries_2026 GROUP BY review_status');
    mobile_json(['ok'=>true,'year'=>2026,'sessions'=>$s,'status_summary'=>$q->fetchAll(PDO::FETCH_ASSOC),
       'message'=>'Rincian perlu pemeriksaan tidak termasuk total resmi.']);
}
if($action==='annual'||$action==='annual_csv'){
    if(!$full)mobile_error('Hanya petugas, ASN atau Admin dapat membaca rekap tahunan.',403);
    $year=ckbs_year($_GET['year']??date('Y'));
    $rows=ckbs_entries($db,$year,$users);
    $byMember=[];$byMonth=[];
    foreach($rows as $row){
        $id=(string)$row['member_user_id'];
        $byMember[$id]['member_user_id']=$id;
        $byMember[$id]['member_name']=$row['member_name'];
        $byMember[$id]['role']=$users[$id]['role']??'';
        $byMember[$id]['rows'][]=$row;
        $m=substr((string)$row['session_date'],0,7);
        $byMonth[$m][]=$row;
    }
    $members=[];
    foreach($byMember as $m){$members[]=[
      'member_user_id'=>$m['member_user_id'],'member_name'=>$m['member_name'],
      'role'=>$m['role'],'totals'=>ckbs_totals($m['rows'])
    ];}
    usort($members,static fn($a,$b)=>strnatcasecmp($a['member_name'],$b['member_name']));
    if($action==='annual_csv'){
        header('Content-Type: text/csv; charset=utf-8');
        header('Content-Disposition: attachment; filename="bank-sampah-cikoko-'.$year.'.csv"');
        echo "\xEF\xBB\xBF";
        $handle=fopen('php://output','w');
        fputcsv($handle,['Tanggal','Nama Anggota','Peran','Nama Barang','Hasil Timbangan (Kg)','Jumlah (Rp)']);
        foreach($rows as $row){
            $name=(string)$row['member_name'];$item=(string)$row['item_name'];
            // Stop spreadsheet formula injection through user-supplied labels.
            foreach([&$name,&$item] as &$cell)if(preg_match('/^[\\s]*[=+\\-@]/u',$cell))$cell="'".$cell;
            unset($cell);
            fputcsv($handle,[$row['session_date'],$name,
              $users[(string)$row['member_user_id']]['role']??'',
              $item,$row['weight_kg'],$row['amount_rp']]);
        }
        fclose($handle);exit;
    }
    $months=[];
    foreach($byMonth as $key=>$list)$months[]=['month'=>$key,'totals'=>ckbs_totals($list)];
    usort($months,static fn($a,$b)=>strcmp($a['month'],$b['month']));
    mobile_json(['ok'=>true,'year'=>$year,'totals'=>ckbs_totals($rows),
        'members'=>$members,'months'=>$months,'items'=>$rows]);
}

if(!$admin && !in_array($action,['entry_save','session_submit','session_create'],true))
    mobile_error('Pengaturan Bank Sampah hanya untuk Admin Utama.',403);
$b=mobile_body();
if($action==='member_set'||$action==='officer_set'){
    $id=mobile_text($b['user_id']??'',80);$active=$b['active']??null;
    if(!is_bool($active))mobile_error('Status keanggotaan harus aktif/tidak.',422);
    $candidate=$users[$id]??null;
    $allowed=CKBS_ROLE_MEMBER; // Anggota dan petugas dapat berasal dari PJLP maupun PPPK.
    if($candidate===null||!in_array($candidate['role'],$allowed,true)||
       ($active&&!$candidate['active']))
        mobile_error('Pilih akun pegawai aktif yang sesuai kewenangan.',422);
    $table=$action==='member_set'?'mobile_bank_sampah_members_2610':'mobile_bank_sampah_officers_2610';
    $db->beginTransaction();
    try{
        if($active && $action==='officer_set'){
            // Batasi total maksimal lima petugas aktif gabungan PJLP dan PPPK.
            $db->query('SELECT id FROM mobile_bank_sampah_config_2610 WHERE id=1 FOR UPDATE')->fetch();
            $count=(int)$db->query('SELECT COUNT(*) FROM mobile_bank_sampah_officers_2610 WHERE active=1')->fetchColumn();
            $exists=$db->prepare('SELECT active FROM mobile_bank_sampah_officers_2610 WHERE user_id=?');
            $exists->execute([$id]);$old=$exists->fetchColumn();
            if($count>=5 && (string)$old!=='1')mobile_error('Maksimal lima petugas Bank Sampah gabungan PJLP dan PPPK.',422);
        }
        $q=$db->prepare("INSERT INTO {$table} (user_id,active,assigned_by)
          VALUES(?,?,?) ON DUPLICATE KEY UPDATE active=VALUES(active),
            assigned_by=VALUES(assigned_by)");
        $q->execute([$id,$active?1:0,$uid]);$db->commit();
    }catch(Throwable $e){if($db->inTransaction())$db->rollBack();throw $e;}
    if($active)mobile_emit('bank_sampah_anggota',
         $action==='officer_set'?'Anda ditunjuk sebagai petugas Bank Sampah':'Keanggotaan Bank Sampah Cikoko',
         $action==='officer_set'?'Anda dapat mengisi timbangan dan nilai rupiah di menu Bank Sampah.':
           'Anda terdaftar sebagai anggota Bank Sampah Cikoko.','personal',$id);
    mobile_json(['ok'=>true,'message'=>'Pengaturan '.($action==='officer_set'?'petugas':'anggota').' disimpan.']);
}
if($action==='config_set'){
    $cadence=(string)($b['cadence']??'');
    $anchor=filter_var($b['anchor_month']??1,FILTER_VALIDATE_INT);
    if(!in_array($cadence,['twice_monthly','every_two_months'],true)||
        $anchor===false||$anchor<1||$anchor>12)mobile_error('Jadwal tidak valid.',422);
    $db->prepare('UPDATE mobile_bank_sampah_config_2610
      SET cadence=?,anchor_month=?,updated_by=? WHERE id=1')
      ->execute([$cadence,$anchor,$uid]);
    mobile_json(['ok'=>true,'message'=>'Pola jadwal diperbarui. Jadwal yang sudah dibuat tetap tersimpan.']);
}
if($action==='session_create'){
    // Petugas PJLP/PPPK yang ditunjuk dapat memilih tanggal berikutnya
    // sendiri. Tidak wajib hari Minggu; pilihan harian sesuai kegiatan.
    if(!ckbs_officer($db,$actor))
        mobile_error('Hanya petugas Bank Sampah yang ditunjuk atau Admin dapat memilih tanggal.',403);
    $date=ckbs_valid_date(mobile_text($b['session_date']??'',10));
    $today=new DateTimeImmutable('today',new DateTimeZone('Asia/Jakarta'));
    if(!$admin && $date<$today)
        mobile_error('Petugas hanya dapat memilih tanggal hari ini atau mendatang.',422);
    $max=$today->modify('+2 years');
    if($date>$max||($admin&&$date<$today->modify('-2 years')))
        mobile_error('Tanggal kegiatan berada di luar rentang pengisian.',422);
    $note=mobile_text($b['note']??'',240);
    $q=$db->prepare('INSERT INTO mobile_bank_sampah_sessions_2610
      (session_date,note,created_by,updated_by) VALUES (?,?,?,?)');
    try{$q->execute([$date->format('Y-m-d'),$note,$uid,$uid]);}
    catch(PDOException $e){mobile_error('Tanggal penimbangan sudah tersedia. Pilih tanggal tersebut dari daftar.',409);}
    $id=(int)$db->lastInsertId();
    $officers=$db->query('SELECT user_id FROM mobile_bank_sampah_officers_2610 WHERE active=1')->fetchAll(PDO::FETCH_COLUMN);
    foreach($officers as $officer)mobile_emit('bank_sampah_tugas','Jadwal Bank Sampah Cikoko',
      'Penimbangan '.$date->format('d-m-Y').' sudah dibuat dan siap diisi.','personal',(string)$officer);
    mobile_json(['ok'=>true,'id'=>$id,'message'=>'Sesi penimbangan dibuat.']);
}

if($action==='session_submit'){
    if(!ckbs_officer($db,$actor))
        mobile_error('Hanya petugas PJLP/PPPK yang ditunjuk Admin dapat mengirim penimbangan.',403);
    $id=ckbs_id($b['session_id']??null);
    // Serialize with entry_save; no more edits after submission until Admin reopens.
    $db->beginTransaction();
    try{
        $q=$db->prepare('SELECT status FROM mobile_bank_sampah_sessions_2610 WHERE id=? FOR UPDATE');
        $q->execute([$id]);
        $status=$q->fetchColumn();
        if($status!=='open')mobile_error('Sesi sudah dikirim atau ditutup.',409);
        $q=$db->prepare('SELECT COUNT(*) FROM mobile_bank_sampah_entries_2610
         WHERE session_id=? AND voided_at IS NULL');
        $q->execute([$id]);
        if((int)$q->fetchColumn()<1)mobile_error('Tambahkan sekurangnya satu hasil timbang.',422);
        $q=$db->prepare('UPDATE mobile_bank_sampah_sessions_2610
         SET status="submitted",updated_by=? WHERE id=? AND status="open"');
        $q->execute([$uid,$id]);
        if($q->rowCount()!==1)mobile_error('Sesi sudah berubah. Muat ulang.',409);
        $db->commit();
    }catch(Throwable $e){if($db->inTransaction())$db->rollBack();throw $e;}
    mobile_emit('bank_sampah_review','Penimbangan Bank Sampah menunggu pemeriksaan',
        'Hasil penimbangan #'.$id.' telah dikirim oleh petugas PJLP/PPPK untuk disahkan.',
        'personal','admin');
    mobile_emit('bank_sampah_tugas','Hasil timbang berhasil dikirim',
        'Penimbangan #'.$id.' telah dikirim dan menunggu pengesahan Admin.',
        'personal',$uid);
    mobile_json(['ok'=>true,'message'=>'Penimbangan dikirim. Menunggu pengesahan Admin.']);
}
if($action==='session_status'){
    $id=ckbs_id($b['session_id']??null);
    $status=(string)($b['status']??'');
    if(!in_array($status,['open','closed'],true))mobile_error('Status sesi tidak valid.',422);
    $q=$db->prepare('UPDATE mobile_bank_sampah_sessions_2610
      SET status=?,updated_by=? WHERE id=? AND status<>?');
    $q->execute([$status,$uid,$id,$status]);
    if($q->rowCount()!==1)mobile_error('Sesi tidak ditemukan atau status tidak berubah.',409);
    if($status==='closed'){
       $members=$db->prepare('SELECT DISTINCT member_user_id
         FROM mobile_bank_sampah_entries_2610 WHERE session_id=? AND voided_at IS NULL');
       $members->execute([$id]);
       foreach($members->fetchAll(PDO::FETCH_COLUMN) as $member)
           mobile_emit('bank_sampah_rekap','Hasil penimbangan Bank Sampah sudah disahkan',
             'Ringkasan kilogram dan rupiah Anda sudah tersedia di bawah foto Profil.',
             'personal',(string)$member);
    }
    mobile_json(['ok'=>true,'message'=>$status==='closed'
      ?'Penimbangan ditutup; rekap kini disahkan.':'Penimbangan dibuka kembali untuk koreksi.']);
}
if($action==='entry_void'){
    $id=ckbs_id($b['id']??null);
    $q=$db->prepare('UPDATE mobile_bank_sampah_entries_2610 e
      JOIN mobile_bank_sampah_sessions_2610 s ON s.id=e.session_id
      SET e.voided_at=NOW(),e.updated_by=?
      WHERE e.id=? AND e.voided_at IS NULL AND s.status="open"');
    $q->execute([$uid,$id]);
    if($q->rowCount()!==1)mobile_error('Hanya baris sesi terbuka dapat dibatalkan.',409);
    mobile_json(['ok'=>true,'message'=>'Baris dibatalkan tanpa menghapus riwayat database.']);
}
if($action==='entry_save'){
    if(!ckbs_officer($db,$actor))mobile_error('Hanya petugas PJLP/PPPK yang ditunjuk Admin dapat mengisi timbangan.',403);
    $sessionId=ckbs_id($b['session_id']??null);
    $memberId=mobile_text($b['member_user_id']??'',80);
    $member=$users[$memberId]??null;
    if(!$member||!$member['active']||!in_array($member['role'],CKBS_ROLE_MEMBER,true))
        mobile_error('Anggota PJLP/PPPK tidak ditemukan.',422);
    $item=mobile_text($b['item_name']??'',140);
    $weight=trim((string)($b['weight_kg']??''));
    if(mobile_strlen($item)<2||!preg_match('/^\\d{1,5}(?:\\.\\d{1,3})?$/D',$weight)||
        (float)$weight<=0||(float)$weight>10000)
        mobile_error('Isi nama barang dan hasil timbangan Kg yang valid.',422);
    $amount=$b['amount_rp']??0;
    if(!is_int($amount)&&!(is_string($amount)&&preg_match('/^\\d{1,12}$/D',$amount)))
        mobile_error('Jumlah rupiah harus bilangan bulat.',422);
    $amount=(int)$amount;
    if($amount<0||$amount>100000000000)
        mobile_error('Jumlah rupiah di luar batas.',422);
    $id=isset($b['id'])&&$b['id']!==null?ckbs_id($b['id']):null;
    $db->beginTransaction();
    try{
        $q=$db->prepare('SELECT status FROM mobile_bank_sampah_sessions_2610 WHERE id=? FOR UPDATE');
        $q->execute([$sessionId]);$s=$q->fetchColumn();
        if($s!=='open')mobile_error('Sesi tidak ditemukan atau sudah ditutup.',409);
        $q=$db->prepare('SELECT active FROM mobile_bank_sampah_members_2610 WHERE user_id=?');
        $q->execute([$memberId]);
        if((string)$q->fetchColumn()!=='1')mobile_error('Anggota tidak aktif di daftar Bank Sampah.',403);
        if($id===null){
            $q=$db->prepare('INSERT INTO mobile_bank_sampah_entries_2610
              (session_id,member_user_id,item_name,weight_kg,amount_rp,entered_by,updated_by)
              VALUES (?,?,?,?,?,?,?)');
            $q->execute([$sessionId,$memberId,$item,$weight,$amount,$uid,$uid]);
            $id=(int)$db->lastInsertId();
        }else{
            $q=$db->prepare('UPDATE mobile_bank_sampah_entries_2610
             SET item_name=?,weight_kg=?,amount_rp=?,updated_by=?
             WHERE id=? AND session_id=? AND member_user_id=? AND voided_at IS NULL');
            $q->execute([$item,$weight,$amount,$uid,$id,$sessionId,$memberId]);
            if($q->rowCount()!==1)mobile_error('Baris tidak ditemukan atau tidak berubah.',409);
        }
        $db->commit();
    }catch(Throwable $e){if($db->inTransaction())$db->rollBack();throw $e;}
    mobile_emit('bank_sampah_timbang','Timbangan Bank Sampah diperbarui',
       'Data '.$item.' sebesar '.$weight.' Kg telah dicatat. Nilai rupiah: Rp '.number_format($amount,0,',','.').'.',
       'personal',$memberId);
    mobile_emit('bank_sampah_timbang','Timbangan Bank Sampah Cikoko',
       'Ada pembaruan data penimbangan untuk salah satu anggota.',
       'personal','admin');
    mobile_json(['ok'=>true,'id'=>$id,'message'=>'Barang, hasil timbangan dan nilai rupiah tersimpan.']);
}
mobile_error('Aksi Bank Sampah tidak tersedia.',404);
