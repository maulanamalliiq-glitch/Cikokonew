# Cikoko Smart 2571 — hardcheck dan prosedur pemasangan server

Repositori sumber tunggal: `maulanamalliiq-glitch/Cikokonew`, branch `main`.
APK yang dibangun adalah **kandidat uji**, bukan bukti seluruh fungsi di server sudah normal.

## Temuan run #44130250917
- Flutter/PHP: PASS.
- Verifikasi keystore: PASS.
- Patch server: tersedia sebagai artefak `CikokoSmart-2571-MobileAPI-Patch`.
- Server publik: `health` 200; `boarding_public` 200; `deployment_status`, `review_public`, `integrated_services_public`, `chat_v2548_status` masing-masing 401.
- HTTP 401 **belum membuktikan** sumber masalah tunggal. Bisa jadi server masih menjalankan API lama atau ada aturan autentikasi/routing di hosting.
- Build APK/AAB pada run tersebut: SKIPPED karena workflow hanya mengaktifkan build pada `workflow_dispatch` dengan `build_release=true` atau commit pemicu rilis, bukan karena status probe.

## Urutan pemasangan ke cPanel (manual, setelah backup)
1. Backup seluruh database MySQL dan `public_html/mobile-api`. Simpan file privat, upload, konfigurasi, token, dan data lama.
2. Buka artefak `CikokoSmart-2571-MobileAPI-Patch` dari GitHub Actions dan ekstrak. Pastikan di dalam ZIP tersedia direktori `mobile-api/` dan `sql/`.
3. Telaah skema database yang sudah aktif di phpMyAdmin. Setelah backup, jalankan **migrasi yang benar-benar diperlukan** dari `sql/migrate_chat_2544.sql`, `sql/migrate_chat_extras_2571.sql`, `sql/migrate_reviews_2571.sql`, dan `sql/migrate_pppk_staff_2570.sql`. Jangan mengimpor ulang `schema.sql` produksi; jangan menjalankan `DROP`, `DELETE`, atau `TRUNCATE`.
4. Salin **isi** direktori `mobile-api/` dari patch ke direktori yang sudah ada `public_html/mobile-api/`. Jangan mengganti seluruh `public_html`, `bootstrap.php`, berkas koneksi database, direktori `private`, atau folder upload.
5. Konfirmasi respons JSON berikut dari luar hosting:
   - `https://datawebs.my.id/mobile-api/index.php?action=deployment_status` → HTTP 200, `api_release=2571`
   - `https://datawebs.my.id/mobile-api/index.php?action=review_public` → HTTP 200, `ok=true`
   - `https://datawebs.my.id/mobile-api/index.php?action=integrated_services_public` → HTTP 200, `ok=true`
   - `https://datawebs.my.id/mobile-api/index.php?action=boarding_public` → HTTP 200, `ok=true`
   - `https://datawebs.my.id/mobile-api/chat_v2548.php?action=chat_v2548_status` → HTTP 200, `ok=true`
6. Bila status masih 401, gunakan **Network tab** dan `error_log` cPanel untuk memeriksa apakah respons berasal dari `index.php`, aturan `.htaccess`, WAF/ModSecurity, atau autentikasi hosting. Jangan menonaktifkan perlindungan server secara menyeluruh.
7. Masuk sebagai warga dan admin di **lingkungan yang terbackup**. Uji kirim/baca chat dua arah, unggahan foto, status pesan, notifikasi, rating ulasan, cetak PDF ulasan, tampilan logo, kos terverifikasi, kehadiran PPPK, cuti PPPK serta persetujuannya.
8. Uji data PJLP lama dan PDF laporan PPPK dua jabatan agar migrasi tidak merusak riwayat.

## Batas pengujian otomatis
GitHub Actions melakukan lint PHP, uji Flutter, pemeriksaan keystore, paket patch, dan HTTP probe publik. CI tidak mempunyai akses login warga/admin ke database produksi; PASS di CI **tidak** berarti chat dan push notification produksi sudah berfungsi.

## Keamanan
Jangan mengirim password, secret, keystore, token API, atau dump database asli ke GitHub. Pertahankan Android application ID, sertifikat signing, dan data akun lama.
