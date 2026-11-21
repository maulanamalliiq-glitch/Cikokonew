# Cikoko Smart — Bank Sampah 2.6.10+2610

## Dasar format dokumen
Berdasarkan foto `DAFTAR NAMA PENYERAHAN BANK SAMPAH KELURAHAN CIKOKO`: bagian **Hari** dan **Tanggal**, serta kolom **NO · NAMA · NAMA BARANG · HASIL TIMBANGAN · JUMLAH**. Pada aplikasi `HASIL TIMBANGAN` dicatat dalam **Kg** dan `JUMLAH` sebagai **Rupiah**. Satu anggota bisa menyerahkan beberapa jenis barang.

## Hak akses
| Role | Akses |
|---|---|
| PJLP | Kartu `Kg + Rp` persis di bawah foto Profil; menu Bank Sampah berisi ringkasan sendiri; hanya PJLP yang diaktifkan sebagai petugas bisa input/edit |
| PPPK | Kartu `Kg + Rp` di bawah foto Profil dan ringkasan sendiri; tidak bisa mengisi laporan |
| Petugas Bank Sampah | Dipilih **Admin Utama** dari akun **PJLP aktif**, maksimum 5. Tugas ideal 4–5 orang. Mengisi tanggal sesi yang dibuka admin, nama anggota, nama barang, Kg, dan Rp (Rp boleh 0 lalu direvisi) |
| ASN / Lurah | Halaman Bank Sampah khusus, akses baca penuh daftar penyerahan, seluruh anggota, total, dan rekap tahunan; tidak bisa menyunting |
| Admin Kelurahan | Monitoring baca penuh |
| Admin Utama | Menunjuk/mencabut petugas PJLP, menambah/menonaktifkan keanggotaan, memilih tanggal timbang, mengatur periode, membuka/menutup sesi, membatalkan baris sesi terbuka, serta memantau seluruh rekap |

Tidak ada akses modul untuk warga, RT/RW atau akun tamu. Semua izin ditegakkan backend, bukan hanya menyembunyikan tombol Flutter.

## Anggota
Pada inisialisasi pertama, semua akun PJLP dan PPPK **aktif** dalam `portal_users` akan ditambahkan sebagai anggota Bank Sampah. Admin bisa menambah atau menonaktifkan anggota melalui tabel; **tidak menghapus akun pegawai, data absensi, cuti, performance, atau timbangan lama**. Akun baru yang dibuat setelah inisialisasi bisa ditambahkan Admin.

## Jadwal
Permintaan menyebut dua aturan yang berbeda: `penimbangan setiap 2 bulan` dan `2 kali dalam 1 bulan pada hari Minggu`. Karena permintaan terakhir meminta **2 kali per bulan**, defaultnya **Minggu ke-2 dan ke-4 setiap bulan**. Admin dapat mengganti pola menjadi **sekali setiap dua bulan** di halaman Bank Sampah. Tanggal pelaksanaan diinput sebagai *sesi timbang* yang dipilih Admin (harus hari Minggu); tanggal yang sudah dipakai tidak bisa diduplikasi. Petugas hanya bisa menambah/mengubah hasil pada sesi **open**, dan Admin menutup setelah penimbangan diperiksa.

## Nilai
- **Kg** disimpan sebagai `DECIMAL(12,3)` (hingga 3 angka di belakang koma).
- **Rupiah** disimpan sebagai angka bulat non-negatif `BIGINT UNSIGNED`. Petugas mengisi atau memperbarui nilai sebelum sesi ditutup.
- Anggota PJLP/PPPK melihat jumlah Kg dan Rp milik mereka untuk tahun berjalan; contoh `324 Kg | Rp 231.000,-`. Angka di aplikasi **berasal dari database aktual** dan tidak pernah berupa angka contoh.
- ASN, Lurah dan Admin mendapat daftar penyerahan dan rekap tahunan per bulan/per anggota; tersedia tombol salin tabel tahunan ke Excel.
- Rekap bulan/tahun tetap tersimpan dan bisa dibaca kembali pada tahun berikutnya.

## Notifikasi
Saat petugas mencatat/mengubah timbangan dan rupiah, anggota menerima notifikasi status pribadi, dan Super Admin menerima notifikasi audit aktivitas. Penunjukan petugas dan keanggotaan mengirim notif pribadi. Penutupan sesi oleh Admin mengirim notif rekap kepada anggota yang mempunyai hasil timbang. Tidak ada notifikasi publik yang menampilkan identitas dan nilai pribadi pegawai.

## cPanel dan keamanan data
Hanya paket aman `CikokoSmart-2610-BankSampah-API-SAFE` yang disarankan untuk pasang:
```
mobile-api/bank_sampah_2610.php      (file baru, tanpa ubah index.php)
sql/migrate_bank_sampah_2610.sql    (tabel tambahan, tidak menyentuh tabel lama)
PETUNJUK-PASANG.txt
```
1. **Backup** folder `public_html/mobile-api` serta database dan semua laporan/foto lama.
2. Jalankan SQL migrasi Bank Sampah **saja** di phpMyAdmin, atau gunakan izin CREATE TABLE API jika tersedia.
3. Ekstrak zip di `public_html/`. Hanya file PHP baru ditambahkan ke `mobile-api`; jangan menghapus/mengganti `index.php`, `bootstrap.php`, `private`, `roles-lib.php`, `portal_users`.
4. Uji di lingkungan terpisah: admin tetapkan anggota + 4–5 petugas PJLP, buat tanggal Minggu, petugas catat jenis sampah, Kg, Rp; lihat Profil PJLP/PPPK serta monitoring ASN. Uji anggota yang dinonaktifkan masih dapat melihat total historis.
5. Aplikasi **2.6.10+2610** (APK ARM64 dan AAB) tetap diperlukan untuk menambahkan tampilan Bank Sampah ke instalasi Android. Perubahan data API ke depan dapat muncul seketika, tetapi kode Flutter tidak bisa ditambahkan ke APK lama hanya lewat cPanel.
6. Jangan aktifkan `force_update` sampai 2610 benar-benar tersedia di Google Play untuk seluruh pengguna sasaran.
7. Pastikan versi 2610 lebih tinggi dari versionCode tertinggi yang sudah diunggah ke Play Console dan keystore resmi lama dipertahankan.

## Batasan sekarang
- Input dan monitoring dibuat untuk aplikasi Flutter. Belum menyisipkan menu Bank Sampah ke panel **website cPanel live** yang struktur kodenya tidak sama dengan snapshot GitHub; akan memerlukan patch terarah terhadap admin.php versi produksi bila diinginkan.
- Bukan modul tabungan/deposito atau pembayaran otomatis: petugas mengisi angka Rupiah dari hasil penjualan secara manual.
- Tidak ada perubahan atau import data lama yang mereset pegawai.
