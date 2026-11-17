<?php
declare(strict_types=1);
/** App reviews: public aggregates, one editable review per authenticated user,
 * full identity visible to admin only. No public phone, email or user IDs.
 */
function cikoko_reviews_schema(PDO $db):void {
    // Never run CREATE TABLE on every unauthenticated read. Admin imports
    // migrate_reviews_2571.sql once, after a database backup.
    try{
        $db->query('SELECT id,user_id,stars,review_text FROM mobile_app_reviews LIMIT 0');
    }catch(Throwable $e){
        error_log('[Cikoko REVIEW_SCHEMA] '.$e->getMessage());
        mobile_error('Ulasan belum siap pada server (REVIEW_SCHEMA). Admin perlu memasang migrasi database.',503);
    }
}
function cikoko_reviews_dispatch(string $action,string $method):void {
    $db=mobile_db();
    cikoko_reviews_schema($db);
    if($action==='review_public' && $method==='GET'){
        $s=$db->query('SELECT COUNT(*) AS review_count, COALESCE(AVG(stars),0) AS average_stars FROM mobile_app_reviews');
        $stats=$s->fetch(PDO::FETCH_ASSOC)?:[];
        $q=$db->query('SELECT stars,display_name,review_text,created_at FROM mobile_app_reviews ORDER BY updated_at DESC LIMIT 30');
        mobile_json(['ok'=>true,'review_count'=>(int)($stats['review_count']??0),
          'average_stars'=>round((float)($stats['average_stars']??0),1),
          'items'=>$q->fetchAll(PDO::FETCH_ASSOC)]);
    }
    $actor=mobile_auth();
    $uid=(string)$actor['user_id'];
    if($action==='review_submit' && $method==='POST'){
        cikoko_rate_limit($db,'review_submit',$uid,12,3600);
        $v=mobile_body();
        $stars=filter_var($v['stars']??null,FILTER_VALIDATE_INT);
        $comment=mobile_text($v['review']??'',1200);
        if($stars===false||$stars<1||$stars>5)mobile_error('Pilih bintang 1 sampai 5.',422);
        if(mobile_strlen($comment)<10)mobile_error('Ulasan minimal 10 karakter.',422);
        $name=(string)$actor['username'];
        foreach(db_read('portal_users') as $user){
           if((string)($user['id']??'')===$uid){$name=(string)($user['name']??$name);break;}
        }
        // Public card shows only the first name, never a full identity.
        $first=trim(preg_split('/\s+/u',trim($name))[0]??'Pengguna');
        $display=mobile_text($first,45);
        $q=$db->prepare('INSERT INTO mobile_app_reviews(user_id,user_role,display_name,stars,review_text)
          VALUES(?,?,?,?,?) ON DUPLICATE KEY UPDATE stars=VALUES(stars),
          review_text=VALUES(review_text),display_name=VALUES(display_name),updated_at=NOW()');
        $q->execute([$uid,(string)$actor['user_role'],$display,(int)$stars,$comment]);
        mobile_json(['ok'=>true,'message'=>'Ulasan berhasil disimpan.']);
    }
    if($action==='review_admin' && $method==='GET'){
        mobile_admin($actor);
        $profiles=[];
        foreach(db_read('portal_users') as $u)$profiles[(string)($u['id']??'')]=$u;
        $rows=$db->query('SELECT user_id,user_role,stars,review_text,created_at,updated_at FROM mobile_app_reviews ORDER BY updated_at DESC LIMIT 500')->fetchAll(PDO::FETCH_ASSOC);
        foreach($rows as &$row){
            $p=$profiles[(string)$row['user_id']]??[];
            $row['name']=(string)($p['name']??'');
            $row['username']=(string)($p['username']??'');
            $row['phone']=(string)($p['phone']??'');
            $row['email']=(string)($p['email']??'');
        }unset($row);
        $sum=$db->query('SELECT COUNT(*) AS total,COALESCE(AVG(stars),0) AS average_stars FROM mobile_app_reviews')->fetch(PDO::FETCH_ASSOC);
        mobile_json(['ok'=>true,'items'=>$rows,'total'=>(int)($sum['total']??0),
          'average_stars'=>round((float)($sum['average_stars']??0),2)]);
    }
    mobile_error('Aksi ulasan tidak tersedia.',404);
}
