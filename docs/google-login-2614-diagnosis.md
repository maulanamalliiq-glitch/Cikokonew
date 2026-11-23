# Diagnosis Login dengan Google pada Cikoko Smart 2.6.14 (build 2614)

Tanggal pemeriksaan: 21 November 2026. Gejala: pemilih akun Gmail muncul, tetapi setelah akun dipilih proses login gagal atau tidak ada pesan.

## Hasil pemeriksaan source dan APK
- Android package name: `com.KelurahanCikoko.malik`
- Firebase project ID: `kelurahan-cikoko-862d3`
- Google Web Client ID pada Flutter `serverClientId`, Firebase JSON, dan verifikasi token PHP **konsisten**.
- Sertifikat dari APK ARM64 dan AAB signed 2614 (diperiksa dengan `keytool -printcert -jarfile`):
  `SHA-1 A2:A9:06:4B:EB:CF:1A:33:F4:86:29:7D:44:32:6F:94:01:4B:AC:05`
  `SHA-256 39:46:33:E6:A2:F4:C9:1C:15:0D:81:B2:28:90:85:62:D2:30:D7:63:03:1A:0A:0C:20:56:18:B9:D6:69:D4:E5`
- SHA-1 sertifikat **APK langsung/upload key** cocok dengan Android OAuth client `certificate_hash` di `flutter/android/app/google-services.json`.
- Sertifikat yang digunakan **Google Play App Signing** setelah publikasi AAB dapat berbeda. Fingerprint Play App Signing **belum bisa diperiksa** dari repositori atau AAB; memerlukan akses Play Console.
- Kode aplikasi `flutter/lib/main.dart` sebelumnya sengaja menekan semua `GoogleSignInExceptionCode.canceled` tanpa menampilkan pesan. Plugin Google Sign-In Android mendokumentasikan bahwa salah konfigurasi OAuth bisa menghasilkan `canceled` setelah pemilihan akun selesai. Itu menjelaskan kegagalan yang terlihat seperti aplikasi diam, tetapi **belum membuktikan akar masalah**.
- Sesudah Google berhasil, API `mobile-api/google_login_2608.php` dapat menolak akun yang emailnya sudah terdaftar tetapi **belum ditautkan**. Petugas PJLP/PPPK harus masuk dengan password Cikoko lama, kemudian dari Profil memilih `Hubungkan Akun Google`. Pembuatan Google akun baru hanya diizinkan untuk Warga; admin tidak dapat melakukan Google Login.
- Tidak ada bukti perubahan logika OAuth antara 2608 dan 2614 yang dengan sendirinya mengharuskan database dihapus.

## Urutan pemeriksaan cepat tanpa merusak akun/data
1. Identifikasi sumber instalasi: **APK unduhan GitHub** atau **Google Play Store**. Jika APK langsung berhasil tetapi aplikasi Play Store gagal, periksa SHA-1 **Play App Signing** terlebih dahulu.
2. Google Play Console → aplikasi Cikoko Smart → **App integrity / Integritas aplikasi** → **App signing key certificate** → catat nilai SHA-1 dan SHA-256. Jangan salah mengambil **Upload key certificate**.
3. Firebase Console → proyek **kelurahan-cikoko-862d3** → Project settings → Your apps → aplikasi Android **com.KelurahanCikoko.malik** → tambahkan SHA-1 dan SHA-256 Play App Signing bila belum ada. Alternatif/periksa OAuth Android client pada Google Cloud Console dengan **package + SHA-1** yang sesuai.
4. Pastikan `serverClientId` adalah tipe OAuth **Web application**, bukan Android, dan Google Sign-In diaktifkan di proyek yang sama.
5. Coba lagi setelah konfigurasi tersinkron. Menambahkan SHA-1 ke Google/Firebase **tidak otomatis membutuhkan build APK** apabila kode dan OAuth Web Client ID tidak berubah.
6. Jika masih gagal, catat pesan yang muncul dan tahapnya (sebelum/sesudah memilih akun); jangan kirim **ID token, refresh token, cookie, keystore/password, atau access token**.
7. Jika aplikasi menampilkan pesan **Email sudah terdaftar**, masuk dengan username/password Cikoko lalu `Profil → Hubungkan Akun Google` (untuk role yang diizinkan). Jangan membuat akun warga kedua hanya untuk menghindari tautan.
8. Jika pesan dari API berupa **Layanan Google sedang mengalami kendala**, periksa file `public_html/mobile-api/google_login_2608.php`, `google_auth_2608.php`, ekstensi PHP `curl/openssl`, database `mobile_google_accounts_2608`, dan log PHP cPanel. Jangan kirim isi log yang mengandung identitas atau token.

## Patch diagnostik (branch 2615)
- Hanya `flutter/lib/cikoko_google_auth_2608.dart`, `flutter/lib/main.dart`, QA test, dan workflow verifikasi.
- Mengubah kegagalan Android `canceled` setelah memilih akun dari *diam tanpa pesan* menjadi instruksi yang bisa dibaca; tetap tidak mencatat/menampilkan token.
- **Bukan perbaikan otomatis terhadap konfigurasi Firebase/Play Console**. Untuk membawa pesan baru ke HP dibutuhkan APK/AAB baru setelah testing.
- Tidak mengubah PHP Google Auth, skema database, akun, role, Jumantik, bank sampah, atau pengaturan keystore.
- PR tetap draft dan belum dipasang ke Play Store/cPanel.
