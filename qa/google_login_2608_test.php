<?php
declare(strict_types=1);
function gassert(bool $cond,string $message):void {
 if(!$cond)throw new RuntimeException($message);
}
// Run without cPanel bootstrap/database or production Google credentials.
function mobile_error(string $msg,int $code=400):void {
 throw new RuntimeException('Rejected HTTP '.$code.': '.$msg);
}
function mobile_text($s,int $max=1000):string {
 return substr(trim((string)$s),0,$max);
}
function mobile_strlen(string $s):int{return strlen($s);}
require_once __DIR__.'/../cpanel/mobile-api/google_auth_2608.php';

$cases=[
 '', 'a.b.c','e30.e30.dG9rZW4',
 str_repeat('X',12001), '!!!.abc.def'
];
foreach($cases as $candidate) {
 try{
   cikoko_google_verify_id_token($candidate);
   throw new RuntimeException('An invalid JWT was accepted');
 }catch(RuntimeException $e){
   gassert(str_contains($e->getMessage(),'Rejected HTTP'),
     'Invalid JWT did not fail securely: '.$e->getMessage());
 }
}
$source=file_get_contents(__DIR__.'/../cpanel/mobile-api/google_auth_2608.php');
$app=file_get_contents(__DIR__.'/../flutter/lib/cikoko_google_auth_2608.dart');
$api=file_get_contents(__DIR__.'/../cpanel/mobile-api/google_login_2608.php');
$sql=file_get_contents(__DIR__.'/../cpanel/mobile-api/migrate_google_login_2608.sql');
gassert(is_string($source)&&is_string($app)&&is_string($api)&&is_string($sql),'Required source unavailable');
gassert(str_contains($source,'openssl_verify('),'Google ID signature must be verified');
gassert(str_contains($source,'CIKOKO_GOOGLE_WEB_CLIENT'),'Token audience restriction missing');
gassert(str_contains($source,"'email_verified'"),'Google email verification missing');
gassert(str_contains($source,"'sub'"),'Unique Google subject missing');
gassert(str_contains($source,"'role'=>'warga'"),'Auto registration must create Warga only');
gassert(str_contains($source,"$"."action==='google_link'"),'Explicit account link missing');
gassert(str_contains($source,"mobile_auth()"),'Account linking must require existing login');
gassert(str_contains($source,"CIKOKO_GOOGLE_CERT_ENDPOINT"),'Google public cert endpoint missing');
gassert(str_contains($source,"google_sub VARCHAR(64) NOT NULL PRIMARY KEY"),'Google subject must be unique');
gassert(str_contains($source,"user_id VARCHAR(80) NOT NULL UNIQUE"),'Each account should map to one Google subject');
gassert(str_contains($api,"'google_login','google_link'"),'Dedicated API Google route missing');
gassert(str_contains($api,"require_once __DIR__.'/bootstrap.php'"),'Google route must use existing token session bootstrap');
gassert(str_contains($app,'signIn.authenticate()'),'Native Google login missing');
gassert(str_contains($sql,'CREATE TABLE IF NOT EXISTS mobile_google_accounts_2608'),'Additive migration missing');
// Google picture comes from a verified ID-token claim. Only approved Google
// hosts can be downloaded; existing uploaded Cikoko avatars must be preserved.
gassert(cikoko_google_picture_url('https://lh3.googleusercontent.com/a/ACg8-test=s96-c')
  ==='https://lh3.googleusercontent.com/a/ACg8-test=s96-c',
  'Google picture host was rejected');
foreach([
  'http://lh3.googleusercontent.com/a/x',
  'https://lh3.googleusercontent.com.evil.test/a/x',
  'https://lh3.googleusercontent.com@evil.test/a/x',
  'https://127.0.0.1/a/x',
  'https://lh3.googleusercontent.com:8443/a/x',
  'file:///etc/passwd',
  'https://evil.test/x'
] as $bad)gassert(cikoko_google_picture_url($bad)===null,
  'Remote picture URL should be rejected: '.$bad);
gassert(str_contains($source,"cikoko_google_autofill(\$user,\$identity)"),
  'Google login must backfill profile data');
gassert(str_contains($source,"trim((string)(\$row['photo_name']??''))===''"),
  'A manually uploaded profile photo must not be overwritten');
gassert(str_contains($source,"CURLOPT_FOLLOWLOCATION=>false"),
  'Remote profile photo must not follow redirects');
gassert(str_contains($source,"2*1024*1024"),
  'Google profile photo must be size-limited');
echo "Cikoko Google SSO 2608 and profile sync QA OK\n";
