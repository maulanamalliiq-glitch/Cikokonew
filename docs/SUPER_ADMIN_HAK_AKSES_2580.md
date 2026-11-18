# Cikoko Smart 2.5.80 — Hak Akses Super Admin dan Penugasan Chat

## Panel Super Admin website

Paket patch website `CIKOKO_SUPER_ADMIN_HAK_AKSES_CHAT_2580.zip` memasang menu **Hak Akses Petugas** pada `/admin?section=akses`, menggunakan sesi Super Admin yang sudah ada. Panel menampilkan seluruh kode role petugas dari `mobile_role_names()` dan izin yang dikenal `mobile_permission_keys()`. Tidak ada halaman teknis yang ditampilkan kepada warga.

Simpan izin melalui POST tervalidasi CSRF dan daftar peran/izin yang diizinkan. Penyimpanan dilakukan menggunakan tabel **`mobile_role_permissions`** yang sudah menjadi sumber kebenaran API. Tidak ada ALTER untuk tabel pegawai, surat, maupun chat.

Hanya Super Admin boleh mengubah izin; role `admin` dan `warga` serta capability `role:manage` tidak bisa diedit di panel website.

## Penugasan Chat Warga

Super Admin mengaktifkan `chat:reply` untuk role seperti PTSP, SOSIAL, ASN, dan Admin Kelurahan. **Semua akun aktif** dalam role yang dipilih memperoleh izin; versi ini belum menyediakan penunjukan satu individu dari role yang sama.

`mobile_can()` mengawasi API chat dan notifikasi. Pemeriksaan staff di `chat_offline_bot_2545.php` tidak lagi terbatas pada nama role ASN/Admin, tetapi mengikuti `chat:reply`. Firebase dan inbox dapat mengirim notifikasi kepada role berizin melalui `notification_recipients.php`.

## Sinkronisasi di Android

`modulesForRole()` menambahkan modul yang didukung ketika izin baru diberikan. Aplikasi mengambil ulang izin dari endpoint `permissions` setiap sekitar 15 detik saat aktif; izin yang dicabut membuat menu hilang dan API menolak permintaan berikutnya. Jika server izin tidak tersedia, modul sensitif disembunyikan sampai izin berhasil dimuat.

Pemeriksaan server **tetap menjadi pengamanan utama**. Hak akses tidak diperoleh hanya dengan memodifikasi tampilan, URL, atau state aplikasi.

## Penting sebelum pemasangan

1. Backup `public_html` dan database, termasuk konfigurasi API dan file role.
2. Upload patch website 2580 ke `public_html`; file website di dalam ZIP terbatas pada dua halaman admin, satu modul izin dan satu CSS baru.
3. Pastikan `mobile-api/permissions.php` dan `roles-lib.php` mendukung role SOSIAL. Pasang perbaikan API 2580 dengan **perbandingan file terlebih dahulu**; jangan gunakan paket lama untuk menimpa perubahan chat terbaru.
4. Tabel `mobile_role_permissions` dibuat otomatis dengan `CREATE TABLE IF NOT EXISTS` jika belum tersedia. **Tidak perlu impor SQL untuk sekadar mengatur izin role**.
5. Uji: Super Admin aktifkan chat untuk PTSP, login aplikasi PTSP, cek Pesan Masuk muncul dan API menerima; matikan chat dan cek akses ditolak. Uji akun warga dan role SOSIAL yang belum diberi izin.
6. Kendala `CHAT_ID_SCHEMA` pada database produksi **tidak diperbaiki oleh pengaturan izin**. Pastikan migrasi chat sudah aman dan status `CHAT_READY` sebelum menguji pengiriman.
7. Paket ini **belum** mencakup penugasan individu per akun ataupun modul baru yang belum tersedia pada Flutter. Tampilan kontrol tidak menggantikan SOP kelurahan.

Konten panel role website berasal dari patch untuk **website site-v3**, bukan dari UI admin PHP legacy `cpanel/admin.php` di repository.
