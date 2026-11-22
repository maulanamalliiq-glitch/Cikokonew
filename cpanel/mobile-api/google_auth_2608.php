<?php
declare(strict_types=1);

/**
 * Google Sign-In Cikoko 2608. Keep old password login and all existing roles.
 * Never derive a privileged role from email. Only a Google subject that was
 * explicitly linked while logged in may reopen an existing non-admin account.
 * New Google subjects can create WARGA only, never admin/PJLP/PPPK/Jumantik.
 */
const CIKOKO_GOOGLE_WEB_CLIENT = '417622897353-5s9dm00fpbv9eik69u8ri8d9mot6hibe.apps.googleusercontent.com';
const CIKOKO_GOOGLE_ANDROID_CLIENT = '417622897353-ops3tfbnc7pq03gtcc3u02u89vb2ddfi.apps.googleusercontent.com';
const CIKOKO_GOOGLE_CERT_ENDPOINT = 'https://www.googleapis.com/oauth2/v1/certs';

function cikoko_google_token_part(string $encoded):string {
    if($encoded===''||strlen($encoded)>16384||!preg_match('/^[A-Za-z0-9_-]+$/D',$encoded))
        mobile_error('Token Google tidak valid.',401);
    $result=base64_decode(strtr($encoded,'-_','+/'),true);
    if(!is_string($result))mobile_error('Token Google tidak valid.',401);
    return $result;
}

function cikoko_google_certificates():array {
    // Keep a short, local cache of public certificates only; never store ID tokens.
    static $cache=null;
    if(is_array($cache))return $cache;
    // Keep cached signing certificates inside the existing non-public API private folder.
    $path=__DIR__.'/private/google-oauth-certs-2608.json';
    $now=time();
    if(is_file($path)&&(@filemtime($path)?:0)>$now-1800){
        $decoded=json_decode((string)@file_get_contents($path),true);
        if(is_array($decoded)&&count($decoded)>0)return $cache=$decoded;
    }
    if(!function_exists('curl_init'))mobile_error('Verifikasi Google belum tersedia di server.',503);
    $curl=curl_init(CIKOKO_GOOGLE_CERT_ENDPOINT);
    curl_setopt_array($curl,[
      CURLOPT_RETURNTRANSFER=>true,
      CURLOPT_TIMEOUT=>9,
      CURLOPT_CONNECTTIMEOUT=>5,
      CURLOPT_FOLLOWLOCATION=>false,
      CURLOPT_SSL_VERIFYPEER=>true,
      CURLOPT_SSL_VERIFYHOST=>2,
      CURLOPT_MAXREDIRS=>0,
      CURLOPT_USERAGENT=>'CikokoSmart-GoogleLogin-2608',
    ]);
    $body=curl_exec($curl);
    $status=(int)curl_getinfo($curl,CURLINFO_RESPONSE_CODE);
    curl_close($curl);
    if($status!==200||!is_string($body)||strlen($body)>200000)
        mobile_error('Verifikasi Google sementara tidak dapat dihubungi.',503);
    $decoded=json_decode($body,true);
    if(!is_array($decoded)||count($decoded)<1||count($decoded)>10)
        mobile_error('Kunci verifikasi Google tidak tersedia.',503);
    foreach($decoded as $kid=>$pem){
        if(!is_string($kid)||!preg_match('/^[a-zA-Z0-9_-]{1,128}$/D',$kid)||
           !is_string($pem)||!str_contains($pem,'BEGIN CERTIFICATE'))
            mobile_error('Kunci verifikasi Google tidak valid.',503);
    }
    // Cache public X509 data only; failure to cache must not block login.
    @file_put_contents($path,json_encode($decoded),LOCK_EX);
    @chmod($path,0600);
    return $cache=$decoded;
}

function cikoko_google_verify_id_token(string $jwt):array {
    if(strlen($jwt)>12000||strlen($jwt)<100)mobile_error('Token Google tidak valid.',401);
    $segments=explode('.',$jwt);
    if(count($segments)!==3)mobile_error('Token Google tidak valid.',401);
    [$head,$body,$sig]=$segments;
    $header=json_decode(cikoko_google_token_part($head),true);
    $claims=json_decode(cikoko_google_token_part($body),true);
    if(!is_array($header)||!is_array($claims)||($header['alg']??'')!=='RS256')
        mobile_error('Token Google tidak valid.',401);
    $kid=$header['kid']??'';
    if(!is_string($kid)||!preg_match('/^[A-Za-z0-9_-]{1,128}$/D',$kid))
        mobile_error('Token Google tidak valid.',401);
    $certs=cikoko_google_certificates();
    $certificate=$certs[$kid]??null;
    if(!is_string($certificate))mobile_error('Kunci Google telah berubah. Silakan ulangi.',401);
    $publicKey=openssl_pkey_get_public($certificate);
    if($publicKey===false ||
        openssl_verify($head.'.'.$body,cikoko_google_token_part($sig),$publicKey,OPENSSL_ALGO_SHA256)!==1)
        mobile_error('Tanda tangan token Google tidak sah.',401);
    $now=time();
    if(!in_array($claims['iss']??null,['accounts.google.com','https://accounts.google.com'],true)||
       ($claims['aud']??null)!==CIKOKO_GOOGLE_WEB_CLIENT||
       (isset($claims['azp'])&&!in_array($claims['azp'],[
           CIKOKO_GOOGLE_WEB_CLIENT,CIKOKO_GOOGLE_ANDROID_CLIENT],true))||
       !is_int($claims['exp']??null)||$claims['exp']<=$now-30||
       !is_int($claims['iat']??null)||$claims['iat']>$now+60||
       $claims['iat']<$now-7200)
        mobile_error('Token Google kedaluwarsa atau bukan untuk Cikoko Smart.',401);
    $subject=$claims['sub']??'';
    $email=$claims['email']??'';
    if(!is_string($subject)||!preg_match('/^[0-9]{6,64}$/D',$subject)||
       !is_string($email)||strlen($email)>160||
       !filter_var($email,FILTER_VALIDATE_EMAIL)||
       ($claims['email_verified']??false)!==true)
        mobile_error('Gunakan akun Google dengan email terverifikasi.',403);
    $name=mobile_text($claims['name']??'Pengguna Google',120);
    if(mobile_strlen($name)<3)$name='Pengguna Google';
    return ['sub'=>$subject,'email'=>strtolower($email),'name'=>$name,
      'picture'=>cikoko_google_picture_url($claims['picture']??null)];
}


/**
 * Optional signed Google picture: allow only Google photo hosts. Never fetch
 * arbitrary URLs from clients; no redirects and size limits prevent SSRF.
 */
function cikoko_google_picture_url(mixed $url):?string {
    if(!is_string($url)||strlen($url)>1500||!filter_var($url,FILTER_VALIDATE_URL))return null;
    $parts=parse_url($url);
    if(!is_array($parts)||strtolower((string)($parts['scheme']??''))!=='https'||
       isset($parts['port'])||isset($parts['user'])||isset($parts['pass'])||
       !preg_match('/^lh[3-6]\\.googleusercontent\\.com$/D',strtolower((string)($parts['host']??''))))return null;
    return $url;
}
function cikoko_google_download_photo(?string $url):?string {
    if($url===null||!function_exists('curl_init'))return null;
    $bytes='';$limit=2*1024*1024;
    $ch=curl_init($url);
    curl_setopt_array($ch,[
      CURLOPT_RETURNTRANSFER=>false,CURLOPT_CONNECTTIMEOUT=>4,CURLOPT_TIMEOUT=>9,
      CURLOPT_FOLLOWLOCATION=>false,CURLOPT_SSL_VERIFYPEER=>true,
      CURLOPT_SSL_VERIFYHOST=>2,CURLOPT_MAXREDIRS=>0,
      CURLOPT_HTTPHEADER=>['Accept: image/jpeg,image/png,image/webp'],
      CURLOPT_WRITEFUNCTION=>static function($curl,string $chunk)use(&$bytes,$limit):int {
          $n=strlen($chunk);if(strlen($bytes)+$n>$limit)return 0;
          $bytes.=$chunk;return $n;
      }
    ]);
    $ok=curl_exec($ch);$status=(int)curl_getinfo($ch,CURLINFO_HTTP_CODE);
    curl_close($ch);
    if($ok!==true||$status!==200||$bytes==='')return null;
    $info=@getimagesizefromstring($bytes);
    if(!is_array($info)||($info[0]??0)<1||($info[1]??0)<1||
       ($info[0]??0)>4096||($info[1]??0)>4096)return null;
    $ext=['image/jpeg'=>'jpg','image/png'=>'png','image/webp'=>'webp'][$info['mime']??'']??null;
    if(!$ext||!is_dir(__DIR__.'/private'))return null;
    $name=bin2hex(random_bytes(20)).'.'.$ext;$path=__DIR__.'/private/'.$name;
    if(@file_put_contents($path,$bytes,LOCK_EX)!==strlen($bytes)){@unlink($path);return null;}
    @chmod($path,0640);
    return $name;
}
/**
 * Synchronize only missing name/email and missing avatar. Existing photos,
 * role, NIK, phone, address, RT/RW and Cikoko account identifiers are preserved.
 * Synchronization must never prevent a successful Google login.
 */
function cikoko_google_autofill(array $account,array $identity,bool $alreadyLocked=false):array {
    $missingPhoto=trim((string)($account['photo_name']??''))==='';
    $missingName=trim((string)($account['name']??''))===''||
        (string)($account['name']??'')==='Pengguna Google';
    $missingEmail=trim((string)($account['email']??''))==='';
    if(!$missingPhoto&&!$missingName&&!$missingEmail)return $account;
    $download=$missingPhoto?cikoko_google_download_photo($identity['picture']??null):null;
    $lock=null;$usedPhoto=false;$saved=false;
    if(!$alreadyLocked){
        $lock=@fopen(data_path('portal_users').'.google-lock','c');
        if(!$lock||!flock($lock,LOCK_EX)){
            if($lock)fclose($lock);
            if($download!==null)@unlink(__DIR__.'/private/'.$download);
            return $account;
        }
    }
    try{
        $rows=db_read('portal_users');$result=$account;$changed=false;
        foreach($rows as &$row){
            if(!is_array($row)||(string)($row['id']??'')!==(string)($account['id']??''))continue;
            if(empty($row['active'])||in_array((string)($row['role']??''),['admin','admin_kelurahan'],true))break;
            if($download!==null&&trim((string)($row['photo_name']??''))===''){
                $row['photo_name']=$download;$usedPhoto=true;$changed=true;
            }
            if((trim((string)($row['name']??''))===''||
                (string)($row['name']??'')==='Pengguna Google')&&
               (string)($identity['name']??'')!=='Pengguna Google'){
                $row['name']=$identity['name'];$changed=true;
            }
            if(trim((string)($row['email']??''))===''&&
                filter_var((string)($identity['email']??''),FILTER_VALIDATE_EMAIL)){
                $row['email']=$identity['email'];$changed=true;
            }
            $result=$row;break;
        }
        unset($row);
        if($changed){$saved=db_write('portal_users',$rows);if(!$saved){
            error_log('[Google Profile Sync] Cannot persist optional profile fields.');
            return $account;
        }}
        return $result;
    }catch(Throwable $e){
        error_log('[Google Profile Sync] Optional profile sync failed.');
        return $account;
    }finally{
        if($download!==null&&(!$usedPhoto||!$saved))@unlink(__DIR__.'/private/'.$download);
        if($lock!==null){flock($lock,LOCK_UN);fclose($lock);}
    }
}

function cikoko_google_schema(PDO $db):void {
    static $ready=false;
    if($ready)return;
    $db->exec('CREATE TABLE IF NOT EXISTS mobile_google_accounts_2608 (
      google_sub VARCHAR(64) NOT NULL PRIMARY KEY,
      user_id VARCHAR(80) NOT NULL UNIQUE,
      google_email VARCHAR(160) NOT NULL,
      linked_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
      INDEX idx_email (google_email)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4');
    $ready=true;
}

function cikoko_google_find_user(string $id):?array {
    foreach(db_read('portal_users') as $row) {
        if(is_array($row)&&(string)($row['id']??'')===$id)return $row;
    }
    return null;
}

function cikoko_google_eligible(?array $account):bool {
    if($account===null)return false;
    return !empty($account['active']) &&
      !in_array((string)($account['role']??''),['admin','admin_kelurahan'],true);
}

function cikoko_google_issue_session(PDO $db,array $user):void {
    // Always use the current role from the trusted portal account store.
    $token=rtrim(strtr(base64_encode(random_bytes(48)),'+/','-_'),'=');
    $db->prepare('INSERT INTO mobile_tokens
      (token_hash,user_id,username,user_role,expires_at)
      VALUES(?,?,?,?,DATE_ADD(NOW(),INTERVAL 30 DAY))')
      ->execute([hash('sha256',$token),(string)$user['id'],
        (string)$user['username'],(string)$user['role']]);
    mobile_json(['ok'=>true,'token'=>$token,'user'=>[
       'id'=>(string)$user['id'],
       'name'=>(string)($user['name']??''),
       'username'=>(string)$user['username'],
       'role'=>(string)$user['role'],
       'department'=>(string)($user['department']??''),
       'phone'=>(string)($user['phone']??''),
       'email'=>(string)($user['email']??'')
    ]]);
}

function cikoko_google_route(string $action,string $method):void {
    if($method!=='POST')mobile_error('Metode tidak diizinkan.',405);
    $db=mobile_db();
    cikoko_google_schema($db);
    cikoko_rate_limit($db,'google_auth_ip',(string)($_SERVER['REMOTE_ADDR']??''),40,900);
    $input=mobile_body();
    $idToken=$input['id_token']??'';
    if(!is_string($idToken))mobile_error('Token Google tidak valid.',422);
    $identity=cikoko_google_verify_id_token($idToken);
    $subject=$identity['sub'];

    if($action==='google_link'){
        $actor=mobile_auth();
        if(in_array((string)$actor['user_role'],['admin','admin_kelurahan'],true))
            mobile_error('Admin menggunakan login khusus. Tidak dapat menautkan Google.',403);
        $user=cikoko_google_find_user((string)$actor['user_id']);
        if(!cikoko_google_eligible($user) ||
           (string)$user['role']!==(string)$actor['user_role'])
            mobile_error('Akun tidak aktif atau akses berubah.',403);
        $q=$db->prepare('SELECT user_id FROM mobile_google_accounts_2608 WHERE google_sub=?');
        $q->execute([$subject]);$existing=$q->fetchColumn();
        if($existing!==false && (string)$existing!==(string)$user['id'])
            mobile_error('Akun Google sudah terhubung dengan akun lain.',409);
        $q=$db->prepare('SELECT google_sub FROM mobile_google_accounts_2608 WHERE user_id=?');
        $q->execute([(string)$user['id']]);$oldSubject=$q->fetchColumn();
        if($oldSubject!==false && (string)$oldSubject!==$subject)
            mobile_error('Akun Cikoko ini sudah terhubung dengan Google lain.',409);
        if($existing===false && $oldSubject===false){
            try{
                $db->prepare('INSERT INTO mobile_google_accounts_2608(google_sub,user_id,google_email)
                  VALUES(?,?,?)')->execute([$subject,(string)$user['id'],$identity['email']]);
            }catch(PDOException $e){
                mobile_error('Google sudah terhubung dengan akun lain. Muat ulang.',409);
            }
        }
        cikoko_google_autofill($user,$identity);
        mobile_json(['ok'=>true,'message'=>'Google terhubung. Foto Google dipakai bila foto profil Cikoko masih kosong.']);
    }

    if($action!=='google_login')mobile_error('Aksi tidak ditemukan.',404);
    $q=$db->prepare('SELECT user_id FROM mobile_google_accounts_2608 WHERE google_sub=?');
    $q->execute([$subject]);$linkedId=$q->fetchColumn();
    if($linkedId!==false){
        $user=cikoko_google_find_user((string)$linkedId);
        if(!cikoko_google_eligible($user))
            mobile_error('Akun terkait tidak aktif atau membutuhkan login khusus.',403);
        $user=cikoko_google_autofill($user,$identity);
        cikoko_google_issue_session($db,$user);
    }

    // Never claim an existing account via matching email alone; old emails
    // may be unverified. Require normal password login + explicit google_link.
    foreach(db_read('portal_users') as $user){
        if(is_array($user)&&strcasecmp((string)($user['email']??''),$identity['email'])===0)
            mobile_error('Email sudah terdaftar. Login biasa dahulu, lalu buka Profil untuk menghubungkan Google.',409);
    }
    // New Google users are WARGA only. Privileged roles are never auto-created.
    $admin=db_read('admin');
    if(strcasecmp((string)($admin['email']??''),$identity['email'])===0)
        mobile_error('Email akun administrator tidak bisa didaftarkan otomatis.',403);

    $lockPath=data_path('portal_users').'.google-lock';
    $lock=@fopen($lockPath,'c');
    if(!$lock||!flock($lock,LOCK_EX)){
        if($lock)fclose($lock);
        mobile_error('Pendaftaran sedang sibuk. Coba lagi.',503);
    }
    try{
        // Recheck email and subject after acquiring the lock.
        $q=$db->prepare('SELECT user_id FROM mobile_google_accounts_2608 WHERE google_sub=?');
        $q->execute([$subject]);$linkedId=$q->fetchColumn();
        if($linkedId!==false){
            $user=cikoko_google_find_user((string)$linkedId);
            if(!cikoko_google_eligible($user))mobile_error('Akun tidak aktif.',403);
            $user=cikoko_google_autofill($user,$identity,true);
            cikoko_google_issue_session($db,$user);
        }
        $users=db_read('portal_users');
        foreach($users as $entry){
            if(strcasecmp((string)($entry['email']??''),$identity['email'])===0)
                mobile_error('Email terdaftar. Login biasa dan hubungkan akun dari Profil.',409);
        }
        $id=bin2hex(random_bytes(12));
        $username='google_'.substr($id,0,16);
        $new=[
          'id'=>$id,'name'=>$identity['name'],'username'=>$username,
          'password_hash'=>password_hash(bin2hex(random_bytes(32)),PASSWORD_DEFAULT),
          'role'=>'warga','department'=>'Warga','address'=>'','phone'=>'',
          'email'=>$identity['email'],'rt'=>'','rw'=>'','active'=>true,
          'created_at'=>date('c'),'google_registration'=>true
        ];
        $users[]=$new;
        // Persist mapping first. If portal write fails, remove mapping safely.
        $db->prepare('INSERT INTO mobile_google_accounts_2608(google_sub,user_id,google_email)
          VALUES(?,?,?)')->execute([$subject,$id,$identity['email']]);
        if(!db_write('portal_users',$users)){
            $db->prepare('DELETE FROM mobile_google_accounts_2608 WHERE google_sub=? AND user_id=?')
                ->execute([$subject,$id]);
            mobile_error('Pendaftaran Google gagal disimpan. Silakan coba lagi.',503);
        }
        $new=cikoko_google_autofill($new,$identity,true);
        cikoko_google_issue_session($db,$new);
    } finally {
        flock($lock,LOCK_UN);
        fclose($lock);
    }
}
