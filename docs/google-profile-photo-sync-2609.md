# Cikoko Smart 2608 — perbaikan sinkronisasi foto profil Google

## Penyebab
Versi Google Login 2608 sudah menggunakan name/email dari claim ID token untuk akun warga baru, namun belum menyimpan claim `picture` menjadi foto profil Cikoko. Sementara itu UI profil aktif membaca `v211_profile` → `has_photo`, lalu endpoint `v211_profile_photo`, sehingga avatar tetap inisial meski Google menyediakan foto.

## Perbaikan tanpa APK baru
Kode pada `mobile-api/google_auth_2608.php` sekarang mengambil foto dari claim `picture` ID token **setelah autentikasi Google diverifikasi**, hanya dari host gambar Google HTTPS yang diizinkan, tanpa redirect, maksimal 2 MB. Foto disimpan ke `mobile-api/private` dan `portal_users.photo_name` **hanya ketika pengguna belum punya foto Cikoko**. Nama/email Google hanya mengisi kolom profil kosong, tidak menimpa data yang sudah terisi. Role, password, token, nomor HP, alamat, NIK, RT/RW, dan laporan tetap sama.

## Langkah pemasangan cPanel
1. **Pastikan login Google 2608 saat ini sudah berjalan.** Patch ini mengganti satu file PHP, bukan paket baru penuh.
2. Backup `public_html/mobile-api/google_auth_2608.php`, `mobile-api/private`, serta data akun `portal_users`.
3. Download artifact `CikokoSmart-2608-GoogleProfil-FIX-SAFE` dari hasil GitHub Actions PR #10. Ekstrak ke `public_html` dan timpa hanya `mobile-api/google_auth_2608.php`.
4. Pastikan PHP 8.4 mengaktifkan `curl`, `openssl` dan `fileinfo`, serta `private/` dapat ditulis oleh PHP.
5. Logout dari Cikoko Smart, pilih **Masuk dengan Google**, lalu buka **Profil**. Kalau Google mengirimkan `picture`, foto akan muncul sebagai avatar Cikoko tanpa memperbarui AAB.
6. Bila avatar belum muncul, pastikan Google memiliki foto profil, PHP dapat mengakses `lh3.googleusercontent.com` via HTTPS, dan file `private` dapat ditulis. Jangan kirim ID token, login cookie, atau password.
7. Nomor HP, alamat, NIK dan RT/RW **tidak bisa diambil dari login Google standar**: tetap harus diisi dan diverifikasi di aplikasi.
8. **Tidak perlu SQL atau AAB baru** untuk patch foto. Jangan mengubah `index.php`, `bootstrap.php`, database, role, cuti, absensi, Jumantik, atau website.

## Keterbatasan
Jika klaim `picture` tidak tersedia atau unduhan foto gagal, login tetap berjalan normal. Foto yang telah diunggah manual ke Cikoko tidak akan diganti otomatis. Nama/email pada akun lama yang sudah terisi tetap digunakan meskipun nama/email Google berbeda.
