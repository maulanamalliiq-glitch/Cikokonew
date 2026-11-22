<?php
declare(strict_types=1);
require __DIR__.'/../cpanel/mobile-api/app_update_policy_2606.php';
function assertPolicy(bool $ok, string $message): void {
  if (!$ok) throw new RuntimeException($message);
}
$tmp = tempnam(sys_get_temp_dir(), 'cikoko-policy-');
try {
  file_put_contents($tmp, '{"minimum_supported_build":2606,"latest_play_build":2605,"force_update":true}');
  $invalid = cikoko_version_policy_2606($tmp);
  assertPolicy($invalid['force_update'] === false, 'Cannot force version not available on Play');
  file_put_contents($tmp, '{"minimum_supported_build":2606,"latest_play_build":2606,"force_update":true,"message":"Perbarui"}');
  $ready = cikoko_version_policy_2606($tmp);
  assertPolicy($ready['force_update'] === true && $ready['minimum_supported_build'] === 2606, 'Ready policy failed');
  file_put_contents($tmp, '{"minimum_supported_build":"999999","latest_play_build":2606,"force_update":true}');
  $bad = cikoko_version_policy_2606($tmp);
  assertPolicy($bad['force_update'] === false, 'Non integer values must not enable lockout');
  file_put_contents($tmp, 'not json');
  $broken = cikoko_version_policy_2606($tmp);
  assertPolicy($broken['force_update'] === false, 'Broken config must fail safe');
} finally { @unlink($tmp); }
echo "Cikoko version policy 2606 OK\n";
