# Paket rilis Cikoko Smart 2.6.6+2606 — Pembaruan wajib & Jumantik RT/RW

> STATUS: KANDIDAT / BELUM TERPASANG DI PRODUKSI. Ini pembaruan **inkremental**, bukan pengganti seluruh public_html atau database.

## Isi paket
- Flutter: pemeriksaan versi saat membuka aplikasi dan saat kembali ke foreground. Jika build terpasang di bawah minimum terpublikasi, halaman pembaruan wajib menutup akses sampai versi baru dipasang.
- Integrasi Google Play In-App Updates mode **Immediate**, disertai tombol ke listing Play Store jika Play Core tidak tersedia.
- API: `GET /mobile-api/index.php?action=app_update_policy` tanpa login dan tanpa database; konfigurasi di `mobile-api/private/app_update_policy_2606.json`.
- Akun: RT/RW dan koordinator wajib untuk `jumantik_rt` / `jumantik_rw`; validasi username, password; Admin Utama dapat memperbaiki wilayah akun lama tanpa menghapus akun.
- API Jumantik baru `mobile-api/jumantik-2605.php`: profil petugas, unggah laporan foto, riwayat pribadi, verifikasi/reject Super Admin, daftar berita publik dan foto yang sudah diterbitkan.
- Admin Flutter: menu Verifikasi Jumantik memuat foto privat sebelum publikasi.
- Pengujian: test policy Dart, PHP + lint, Flutter analyze/test pada GitHub Actions; build signed hanya jika rahasia keystore asli tersedia.

## 1. Periksa sebelum merge
1. Pastikan `flutter analyze`, `flutter test`, `qa/app_update_policy_2606_test.php` dan lint PHP lulus pada GitHub Actions.
2. Uji API secara staging. **Jangan upload seluruh direktori `cpanel/` ke produksi**.
3. Backup `public_html/mobile-api`, `public_html/roles-lib.php`, file data `portal_users` dan database sebelum mengubah file apa pun.
4. Bandingkan versi live `mobile-api/index.php` dan `roles-lib.php` dengan patch, lalu gabungkan secara terkendali (hosting bisa memiliki fitur yang tidak ada dalam snapshot GitHub).
5. Deploy `app_update_policy_2606.php`, `jumantik-2605.php`, dan `private/app_update_policy_2606.json` bersama update terarah di `index.php`. Pertahankan `bootstrap.php`, `private/.htaccess` serta seluruh lampiran privat. Pastikan PHP 8.4.

## 2. Uji akun dan laporan Jumantik
- Login sebagai **Admin Utama**, bukan Admin Kelurahan.
- Buat 1 akun uji `jumantik_rt` dan 1 `jumantik_rw` memakai username unik (4–40 karakter huruf/angka/._-), password minimal 5 karakter, RT/RW numerik 1–3 digit, nama koordinator minimal 3 karakter.
- Pastikan daftar akun menampilkan hasil simpan; akun dapat login dan halaman Jumantik menampilkan nama, wilayah serta koordinator.
- Untuk akun lama yang wilayah/koordinatornya kosong, gunakan **Kelola Akun > ... > Atur RT/RW dan Koordinator**.
- Unggah foto JPG/PNG/WebP max 4MB, uji laporan atas akun sendiri; selain role Jumantik harus mendapat HTTP 403 jika mencoba submit. Role harus sesuai identitas akun, tidak boleh dipilih bebas.
- Login Super Admin > **Verifikasi Jumantik**. Foto/label/keterangan privat harus dapat ditinjau; pilih Terbitkan atau Tolak.
- Cek `?action=news`: hanya laporan yang sudah diterbitkan, tanpa nama petugas, nama kepala keluarga, alamat lengkap. Foto yang belum diterbitkan tidak boleh dapat diambil publik.
- Uji akun PJLP, PPPK, RT, RW, chat, cuti dan layanan lama untuk memastikan tidak regresi.

## 3. Urutan rilis Play Store
1. Konfigurasi server pertama kali harus tetap `minimum_supported_build=0`, `latest_play_build=0`, `force_update=false`.
2. Bangun APK ARM64 + AAB pada GitHub Actions dengan **keystore upload yang sama**. Pastikan versionCode `2606` **lebih tinggi daripada seluruh versi di Play Console**. Jika sudah ada build lebih tinggi, gunakan angka lebih tinggi secara konsisten di aplikasi, build dan minimum versi.
3. Uji rilis Play melalui internal testing terlebih dahulu, lalu distribusikan hingga semua pengguna sasaran dapat memperbarui. Pembaruan Immediate hanya berjalan untuk instalasi yang diakui Google Play; APK sideload bisa diarahkan ke listing.
4. Setelah versi Play yang ditargetkan tersedia untuk seluruh pengguna sasaran dan diverifikasi, perbarui file JSON privat, contoh:
   ```json
   {
     "minimum_supported_build": 2606,
     "latest_play_build": 2606,
     "force_update": true,
     "message": "Cikoko Smart telah diperbarui. Silakan perbarui melalui Google Play untuk melanjutkan."
   }
   ```
5. Periksa `https://datawebs.my.id/mobile-api/index.php?action=app_update_policy`, pastikan respons JSON `ok=true`, dan uji dari HP Play Store lama.
6. Untuk update kecil di masa mendatang, `force_update=false` berarti tidak memblokir versi lama; `force_update=true` hanya setelah build minimum dipublikasi merata.

### Hal yang perlu diketahui
- Perangkat yang masih menjalankan **aplikasi versi 2605 atau lebih lama tidak dapat mendeteksi aturan pembaruan baru sebelum menginstal 2606**. Fitur baru pertama kali berlaku mulai rilis yang memuat kode ini.
- Jika server sementara offline, aplikasi menggunakan kebijakan terakhir yang tersimpan; jika belum pernah mendapat kebijakan, aplikasi tidak memblokir secara keliru.
- Aplikasi tidak memasang AAB sendiri, tidak mengirimkan executable dari server. Pembaruan melalui Google Play, sesuai mekanisme resmi Android.
- Tidak ada perubahan data akun lama atau database produksi secara otomatis dari GitHub. Backend menciptakan tabel Jumantik baru jika hak database mengizinkan; tidak menimpa laporan lama.
- Jangan aktifkan pembaruan wajib saat staged rollout atau apabila versi baru belum muncul bagi sebagian pengguna. Jika diperlukan, kembalikan `force_update` menjadi `false` untuk memulihkan akses (ketika API dapat dijangkau).
