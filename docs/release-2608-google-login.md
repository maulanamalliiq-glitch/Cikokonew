# Cikoko Smart 2.6.8+2608 — Masuk dengan Google (Android)

**STATUS:** Kandidat (draft) terpisah dari aplikasi produksi. Tidak mengubah akun lama, role, atau data laporan. Perubahan 2606/2607 tetap disertakan dari branch sebelumnya.

## Alur yang dibuat
- Layar Login mempunyai tombol **Masuk dengan Google**. Ini menggunakan Android Google Sign-In resmi, menerima ID token yang kemudian divalidasi di server dengan sertifikat Google (RSA SHA-256), audience OAuth Cikoko, issuer, expiry, email_verified dan subject.
- **Pengguna baru** masuk pertama kali dengan Google akan dibuat sebagai **Warga** saja, kemudian bisa melengkapi alamat/no HP/RT/RW melalui Profil.
- **Akun Cikoko yang sudah terdaftar**, termasuk PJLP, PPPK, RT, RW, Jumantik, perlu **login biasa sekali**, buka **Profil → Hubungkan Akun Google**, lalu pilih Google. Berikutnya dapat memakai tombol Masuk Google dengan role serta data historis yang sama.
- Kecocokan email **tidak pernah** memberi akses otomatis ke akun yang ada; hubungan ditentukan oleh subject unik Google, setelah pemilik melakukan konfirmasi dari sesi login biasa.
- **Admin Utama dan Admin Kelurahan** tetap memakai login lama (tidak diberikan akses Google otomatis). Akses staf bergantung pada role Cikoko yang aktif; token Google tidak dapat menaikkan izin akun.
- Sesi aplikasi setelah Google login tetap token Cikoko biasa (`mobile_tokens`) sehingga profil, laporan, push FCM, dan API lainnya tetap terhubung ke akun semula.
- Data google_sub disimpan terpisah di `mobile_google_accounts_2608` tanpa menyimpan kata sandi/refresh token Google.

## File cPanel yang harus dipasang
Gunakan artifact **CikokoSmart-2608-GoogleLogin-API-SAFE**, **bukan** menimpa semua file `public_html`:
```
mobile-api/google_auth_2608.php        # baru
mobile-api/google_login_2608.php       # baru
sql/migrate_google_login_2608.sql      # tabel tambahan
```
1. Backup seluruh database dan folder `public_html/mobile-api`.
2. Di phpMyAdmin, jalankan `migrate_google_login_2608.sql` sekali, atau biarkan PHP membuat tabel itu jika memiliki izin CREATE.
3. Upload **hanya kedua file baru** ke `public_html/mobile-api`. **Jangan ganti** `index.php`, `bootstrap.php`, `private/`, `portal_users`, `roles-lib.php`, atau konfigurasi app update.
4. Pastikan ekstensi cPanel PHP 8.4: `openssl`, `curl`, `pdo_mysql`. Akses outbound HTTPS ke `www.googleapis.com` diperlukan untuk mengambil sertifikat verifikasi Google.
5. Lindungi `mobile-api/private` (tidak dapat diakses publik) dan izinkan PHP menyimpan cache sertifikat publik di situ.
6. Endpoint `POST /mobile-api/google_login_2608.php?action=google_login` menerima `id_token` yang berasal dari Android Google Sign-In. Tanpa token harus ditolak, bukan membuat akun.
7. Endpoint `POST ...?action=google_link` memerlukan **dua bukti**: token sesi Cikoko aktif (header Authorization Bearer) dan Google ID token yang valid.

## Pengaturan Google Sign-In
- Proyek Firebase yang sudah dikaitkan ke aplikasi: `kelurahan-cikoko-862d3`; paket Android **tetap** `com.KelurahanCikoko.malik`.
- **Di Firebase Console → Authentication → Sign-in method**, aktifkan provider **Google** bila belum aktif.
- Periksa Google Cloud OAuth Android Client terkait package name tersebut; sertakan SHA-1 sertifikat **upload key** dan **Google Play App Signing key** (yang mungkin berbeda). Tambahkan SHA-1 / SHA-256 yang diperlukan pada pengaturan aplikasi Firebase Android, lalu unduh kembali `google-services.json` jika konfigurasi berubah dan build ulang.
- OAuth Web Client ID yang dipakai untuk server token harus tetap sama dengan konfigurasi web OAuth Firebase saat ini; tidak perlu mengirim Google OAuth client secret ke APK.
- Uji Google sign-in pada **Internal Testing Play Store** dan perangkat Android yang memasang APK signed (keduanya mungkin memakai signing certificate berbeda), serta uji kasus user membatalkan Google login, akun sudah ada, akun nonaktif, akun staf tertaut, akun Admin terlarang, dan email belum diverifikasi.

## Release update
- VersionName `2.6.8`, versionCode `2608`; harus **lebih tinggi** daripada seluruh versionCode yang sudah pernah diunggah ke Play Console. Jangan merubah package name atau membuat keystore baru.
- AAB 2608 diperlukan karena tombol login dan Google plugin adalah **kode Flutter/Android baru**. Update GitHub atau cPanel saja tidak dapat menambahkan tombol ke APK yang sudah terpasang.
- Pembaruan wajib tetap **off** di awal. Setelah 2608 sudah tersedia untuk semua pengguna sasaran, admin boleh menyalakan kebijakan minimal build dari API **jika aplikasi lama sudah mendukung pemeriksaan versi**.
- Pengguna 2605 atau lebih lama yang belum memiliki pemeriksa versi **tidak dapat dipaksa menampilkan dialog pembaruan baru** hanya dengan mengganti server.
- Website admin Cikoko aktif memiliki struktur berbeda dari snapshot GitHub; paket ini menargetkan Android lebih dulu, belum memasang tombol Google untuk login website.

## Keamanan
- Tidak menghubungkan akun staf berdasarkan kecocokan email.
- Tidak menyimpan token Google di database.
- Menggunakan JWT RSA signature verification dengan sertifikat Google asli serta validasi `aud`, `iss`, `exp`, `iat`, dan `email_verified`.
- Tautan Google menggunakan `sub` unik, tidak mengandalkan email sebagai identifier permanen.
- Verifikasi akun baru hanya membuat role `warga`. Semua role lebih tinggi hanya bisa diberikan lewat proses Admin Cikoko yang ada.
