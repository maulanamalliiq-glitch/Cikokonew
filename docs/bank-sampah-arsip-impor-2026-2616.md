# Impor penimbangan Bank Sampah 2026 & tanggal pilihan petugas — build 2616

## Sumber dan hasil ekstraksi
- File user: `Bank Sampah Mandiri PPSU Kelurahan Cikoko.xlsx`, hanya **17 worksheet bertanggal tahun 2026** (18 Jan–1 Nov 2026).
- Rincian barang asli: 1.050 baris positif.
- Terkonfirmasi menurut subtotal tiap sheet dan rekap akhir: **1.048 item, 2.930,780 Kg, Rp 7.473.660**.
- Dua baris di sumber tidak dijumlahkan ke subtotal:
  - **15 Feb 2026**, sheet row **254**, Suwarto — Bodong A 0,9 Kg Rp 3.600.
  - **7 Jun 2026**, sheet row **242**, Zulfahmi — Gabruk 3,1 Kg Rp 2.170.
  Kedua rincian ada di SQL archive status `review` dan **tidak masuk total resmi** sampai diperiksa Admin. Angka tidak dimanipulasi, item tetap disimpan untuk audit.
- SQL lengkap diberikan ke user sebagai artifact percakapan `CIKOKO_BANK_SAMPAH_IMPOR_2026_SAFE.sql` dan ZIP `CIKOKO_BANK_SAMPAH_2026_IMPOR_DATABASE_SAFE.zip`; tidak ditempel pada source repo (memuat nama individual dari dokumen pengguna).

## Model data aditif dan aman
- SQL hanya menambah tabel `mobile_bank_sampah_archive_sessions_2026` (per tanggal: 17 row) dan `mobile_bank_sampah_archive_entries_2026` (1050 row, 1048 `confirmed`, 2 `review`).
- `source_key` unik SHA-256 per baris tanggal/worksheet; `INSERT IGNORE` sehingga SQL dapat dijalankan ulang tanpa menduplikasi baris yang sama.
- Tabel `mobile_bank_sampah_entries_2610`, sesi aktif, `portal_users`, chat, cuti, absensi, Jumantik, dan kinerja PPPK **tidak disentuh** oleh SQL.
- Nama arsip tetap sesuai Excel. Nama singkat yang jelas berdasarkan nomor urut peserta pada 4 sheet awal dirapikan hanya untuk **display rekap**, tetapi nama sumber asli disimpan terpisah. Tidak ada pengaitan otomatis dengan `portal_users.id` karena identitas beberapa peserta tidak cocok atau bukan akun staf.
- API `annual`/CSV tahun 2026 menyertakan arsip terkonfirmasi hanya bila tidak ada penimbangan aktif yang sudah tersimpan untuk tanggal yang sama. Jika bentrok, baris produksi didahulukan untuk **menghindari penghitungan ganda**; arsip asli tidak dihapus.
- API `archive_2026` hanya dapat dibaca Admin, ASN, Lurah dan petugas yang ditunjuk, bukan publik. Baris review tidak diumumkan pada Beranda atau jumlah resmi.
- Ringkasan personal PJLP/PPPK **tidak otomatis berubah dari arsip nama**, sampai ID masing-masing diverifikasi oleh Admin. Hal ini mencegah nilai setoran orang lain dikaitkan ke akun yang salah.

## Pilih tanggal penimbangan mulai build 2616
- Menu `Laporan → Bank Sampah Cikoko`, tombol **Pilih Tanggal Penimbangan Baru**, terlihat hanya untuk Super Admin dan petugas PJLP/PPPK yang ditunjuk.
- Petugas boleh memilih tanggal **hari ini atau hari mendatang** hingga dua tahun, **tidak dibatasi Minggu**; Super Admin boleh mengelola tanggal koreksi dua tahun terakhir.
- Hari pada kartu penimbangan otomatis mengikuti tanggal, bukan 'Minggu' permanen.
- API membatasi akses pada `ckbs_officer`, memvalidasi tanggal di zona Asia/Jakarta, dan mencegah duplikasi sesi melalui UNIQUE session_date.
- Penambahan sesi tetap membuat form input yang menggunakan draft dan pengesahan Admin.

## Prosedur aktivasi
1. **Backup database produksi dan file `public_html/mobile-api/bank_sampah_2610.php`.**
2. Pasang patch PHP khusus `bank_sampah_2610.php` versi 2616. Jangan menimpa `index.php`, `bootstrap.php`, atau file produksi lain.
3. **phpMyAdmin → database Cikoko → Import → file `CIKOKO_BANK_SAMPAH_IMPOR_2026_SAFE.sql`.** Jangan menaruh SQL atau CSV ke `public_html`.
4. Validasi SQL: 17 tanggal, 1048 confirmed, 2 review, 2930.780 Kg, Rp 7473660.
5. Uji Admin/ASN `annual?year=2026`, hasil bulan dan CSV. Uji akun petugas pilihan tanggal bebas, duplikat tanggal, draft/kirim, dan pengesahan Admin.
6. Build/publish AAB 2616 ke Internal Testing setelah lulus. Tidak ada deployment otomatis dari draft PR ini.

## Status
**SQL belum dijalankan pada database live melalui percakapan ini** karena akses cPanel/MySQL tidak terhubung. Draft PR dan CI bukan bukti bahwa produksi telah diperbarui.
