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
gassert(str_contains($app,'GoogleSignIn.instance.authenticate()'),'Native Google login missing');
gassert(str_contains($sql,'CREATE TABLE IF NOT EXISTS mobile_google_accounts_2608'),'Additive migration missing');
echo "Cikoko Google SSO 2608 QA OK\n";
