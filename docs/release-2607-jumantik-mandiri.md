# Cikoko Smart 2.6.7+2607 — Jumantik Mandiri Warga

## Status
Kandidat rilis terpisah: **bukan otomatis terpasang di cPanel atau Play Store**. Branch ini dibuat dari paket 2606 agar tidak menghapus fitur Jumantik RT/RW, absensi, cuti, PPPK, chat, berita, atau database lama.

## Lingkup fitur
- **Form Jumantik Mandiri**: semua akun yang telah login **kecuali** `admin` dan `admin_kelurahan`. Pengunjung belum login diarahkan login. Waktu nyata dan waktu final tercatat di server dengan zona WIB.
- Form wajib: Nama Kepala Keluarga, Nama Pengirim, No Handphone, Alamat; 12 pemeriksaan Ya/Tidak sesuai daftar permintaan; Kegiatan: Sudah Terlaksana / Belum Terlaksana; foto dari Kamera atau Galeri maksimal 4 MB.
- Pengiriman menulis tabel **baru** `mobile_jumantik_mandiri_2607`, status `pending`. Kunci permintaan mencegah duplikasi bila koneksi bermasalah.
- **Verifikasi Jumantik Mandiri** hanya Super Admin. Foto, 12 pilihan dan identitas tampil privat; Super Admin bisa menerbitkan atau menolak dengan alasan. Semua keputusan tetap di riwayat.
- **Berita Jumantik Mandiri Warga** memuat ringkasan laporan yang telah diterbitkan, **tanpa nama kepala keluarga, pengirim, no HP, alamat dan foto pribadi**.
- Notifikasi pribadi kepada **pengirim + Super Admin saat laporan masuk**, pengirim + Admin saat hasil verifikasi, serta pengumuman `Laporan Jumantik Mandiri Warga terbaru` kepada akun aktif setelah verifikasi/publikasi. Tidak mengirim notifikasi publik untuk penolakan.
- Untuk **Jumantik RT/RW SQL**, tambahan notifikasi pengiriman/verifikasi/publikasi tanpa mengubah tabel atau laporan lama.

## Cara deploy secara aman
1. Periksa hasil PR/CI `flutter analyze`, `flutter test`, PHP lint, dan `qa/jumantik_mandiri_2607_test.php`.
2. Backup `public_html/mobile-api`, semua file dalam `mobile-api/private/`, penyimpanan JSON website 2605, file akun `portal_users`, dan database SQL; jangan hapus atau impor ulang data lama.
3. Impor hanya **migrasi tambahan** `cpanel/mobile-api/migrate_jumantik_mandiri_2607.sql` melalui phpMyAdmin (atau biarkan API membuat tabel sendiri jika izin CREATE tersedia). Jangan jalankan `DROP`, `TRUNCATE`, atau migrasi lama tanpa audit.
4. Dari paket API deploy file **baru** `mobile-api/jumantik_mandiri_2607.php`, kemudian update terarah `mobile-api/notification_recipients.php`. Untuk notifikasi Jumantik RT/RW SQL, bandingkan dan sinkronkan `mobile-api/jumantik-2605.php` dengan file produksi. **Jangan overwrite seluruh `index.php` atau `bootstrap.php` hanya untuk modul Mandiri.**
5. Pastikan `mobile-api/private/.htaccess` tetap `Require all denied`; jangan mengumumkan URL file foto mentah. Gunakan endpoint `photo` dengan bearer token dan pemeriksaan pemilik/Admin.
6. Uji akun warga dan pegawai: form tampil dan validasi 12 pilihan wajib. Uji akun Admin Utama dan Admin Kelurahan: form Mandiri ditolak 403 dan tidak masuk menu. Super Admin dapat mengakses daftar/Foto/verifikasi.
7. Uji satu laporan (foto kamera), satu (galeri), status `pending`, keputusan terbit dan tolak, riwayat pelapor, daftar berita publik, dan notifikasi inbox + perangkat. Notifikasi push FCM baru muncul bila token aktif, izin Android disetujui dan `cron_dispatch.php` berjalan.
8. Publikasikan AAB 2607 setelah Google Play Internal Testing dan uji bahwa identitas Android serta signing lama tetap sama, serta `versionCode=2607` lebih tinggi daripada kode tertinggi di Play Console. Jika tidak, naikkan nomor build sesuai angka tertinggi.
9. **Jangan aktifkan update wajib lebih dahulu.** `private/app_update_policy_2606.json` tetap `force_update=false` dan `minimum_supported_build=0` sampai build baru *benar-benar tersedia untuk semua pengguna sasaran* di Google Play. Setelah itu `minimum_supported_build=2607`, `latest_play_build=2607`, `force_update=true` boleh diaktifkan jika memang wajib.
10. Versi aplikasi yang belum mengandung mekanisme pemeriksaan update tidak dapat dipaksa menampilkan layar update lewat backend semata. Perubahan kode Flutter tetap membutuhkan AAB baru di Play Store; konten dan API remote langsung terbarui tanpa AAB.

## Notifikasi dan keamanan
- Kategori personal: `jumantik_mandiri_status`, `jumantik_mandiri_review`, `jumantik_rt_rw_status`, `jumantik_rt_rw_review`.
- Kategori pengumuman setelah diverifikasi: `jumantik_mandiri_terbaru`, `jumantik_rt_rw_terbaru` saja (kedua kategori sudah ditambahkan ke daftar kategori publik aman).
- Tidak menyertakan identitas pribadi warga/alamat/nomor HP dalam push publik.
- Sistem notifikasi memakai `mobile_emit` + `mobile_events` + dispatcher FCM yang sudah ada; tidak ada pengiriman diam-diam di luar mekanisme yang sudah terpasang.

## API khusus
- `GET /mobile-api/jumantik_mandiri_2607.php?action=mine` : hanya pengirim yang sudah login.
- `POST ...?action=submit` : multipart dengan 12 Ya/Tidak, kegiatan, foto, otomatis pending.
- `GET ...?action=admin_list`, `POST ...?action=admin_decide` : Super Admin saja.
- `GET ...?action=photo&id=123` : hanya reporter pemilik atau Super Admin.
- `GET ...?action=news` : hanya ringkasan terbit yang aman dipublikasikan.

## Batasan
Website Super Admin produksi memiliki sumber `site-v3/pages/admin.php` yang tidak sama dengan snapshot `cpanel/admin.php` di GitHub. Pembuatan/verifikasi di **aplikasi Flutter Admin** tersedia pada rilis ini; untuk penyatuan menu website, lakukan perubahan terarah pada salinan file live, tanpa menimpa paket website yang sudah diubah secara manual.
