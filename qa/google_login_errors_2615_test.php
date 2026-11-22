<?php
declare(strict_types=1);
$root=dirname(__DIR__);
$google=file_get_contents($root.'/flutter/lib/cikoko_google_auth_2608.dart');
$login=file_get_contents($root.'/flutter/lib/main.dart');
$server=file_get_contents($root.'/cpanel/mobile-api/google_auth_2608.php');
if(!is_string($google)||!is_string($login)||!is_string($server))
    throw new RuntimeException('Google auth source missing.');
foreach([
  'loginFailureMessage',
  'GoogleSignInExceptionCode.canceled',
  'SHA-1 Play App Signing',
  'GoogleSignInExceptionCode.clientConfigurationError',
] as $needle){
  if(!str_contains($google,$needle))
      throw new RuntimeException('Missing public Google auth diagnosis: '.$needle);
}
if(str_contains($login,'!CikokoGoogleAuth2608.userCancelled(e)'))
    throw new RuntimeException('Do not suppress canceled-after-account-selection errors.');
if(!str_contains($login,'CikokoGoogleAuth2608.loginFailureMessage(e)'))
    throw new RuntimeException('Google login must surface a safe diagnostic.');
if(!str_contains($server,'openssl_verify(')||
   !str_contains($server,'CIKOKO_GOOGLE_WEB_CLIENT')||
   !str_contains($server,"'email_verified'"))
    throw new RuntimeException('Never weaken server token verification.');
echo "Google 2615: unexpected canceled errors visible; server OAuth verification intact\n";
