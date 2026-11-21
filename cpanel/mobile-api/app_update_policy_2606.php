<?php
declare(strict_types=1);

/**
 * Public, read-only policy. The JSON config is kept under private/.htaccess.
 * "force_update" must only be enabled AFTER the target is fully available
 * on Google Play (not during staged rollout). No login or database required.
 */
function cikoko_version_policy_2606(?string $configFile = null): array {
    $configFile ??= __DIR__.'/private/app_update_policy_2606.json';
    $config = [];
    if (is_file($configFile)) {
        $raw = @file_get_contents($configFile);
        $decoded = is_string($raw) ? json_decode($raw, true) : null;
        if (is_array($decoded)) $config = $decoded;
    }

    $min = $config['minimum_supported_build'] ?? 0;
    $latest = $config['latest_play_build'] ?? 0;
    $valid = is_int($min) && is_int($latest)
        && $min >= 0 && $latest >= 0 && $min <= 2000000000 && $latest <= 2000000000;
    if (!$valid) { $min = 0; $latest = 0; }
    $enabled = ($config['force_update'] ?? false) === true
        && $min > 0 && $latest >= $min;
    $message = $config['message'] ?? '';
    if (!is_string($message) || trim($message) === '' || strlen($message) > 500)
        $message = 'Versi baru Cikoko Smart tersedia. Perbarui melalui Google Play untuk melanjutkan pelayanan.';

    return [
        'ok' => true,
        'policy_version' => 2606,
        'minimum_supported_build' => $min,
        'latest_play_build' => $latest,
        'force_update' => $enabled,
        'message' => $message,
        'play_store_url' => 'https://play.google.com/store/apps/details?id=com.KelurahanCikoko.malik',
    ];
}
