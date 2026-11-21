# Perbaikan 2617 — Saldo Bank Sampah 2026 per akun

## Masalah pada screenshot
Pada halaman Profil, kartu **Bank Sampah Cikoko** milik akun PPPK tertulis **0 Kg | Rp 0** walaupun Excel penimbangan 2026 memuat nama pegawai. Sumber masalah dalam kode: `summary?year=2026` sebelumnya hanya membaca `mobile_bank_sampah_entries_2610.member_user_id`, sedangkan impor Excel menggunakan `source_member_name` pada tabel arsip independen. Tidak ada jembatan identitas per akun.

## Hasil baca sumber Excel
- `Maulana Malik`: **18 rincian barang, 54,200 Kg, Rp 166.850**, sepanjang 16 tanggal penimbangan, dari baris yang dinyatakan `confirmed` pada CSV impor 2026.
- Angka tersebut adalah **hasil Excel**, bukan klaim nilai yang sudah muncul di cPanel.
- Setelah SQL 2026 benar-benar diimpor dan API 2617 dipasang, akun Maulana Malik yang nama resminya persis cocok dan unik akan menerima agregat historis pada kartu profil. Jika ada penimbangan live untuk tanggal yang sama, entri live menjadi prioritas untuk menghindari duplikasi; angka dapat berbeda dari Excel mentah.

## Dua identitas arsip yang dikonfirmasi
Pemilik proyek mengonfirmasi langsung: **Subhan = Aan Subhan** dan
**Agus K = Agus Kurniawan**. Kedua nama singkat ini sekarang diterjemahkan
ke nama lengkap sebelum pencocokan ID akun. Akun PJLP/PPPK tujuan **harus
memiliki nama lengkap yang cocok secara unik**; bila tidak ada atau ganda,
saldo tidak diberikan otomatis dan Super Admin perlu memverifikasi.

Nama singkat lain pada file tidak ikut ditautkan otomatis hanya karena
ada dugaan nama lengkap yang mirip. Nama pada baris arsip tidak diubah.

## Aturan pengaitan yang aman
1. **Otomatis hanya untuk nama lengkap yang cocok unik** antara `source_member_name` dan `portal_users.name` (case-insensitive dan whitespace-normalized), dengan role PJLP/PPPK. Nama akun ganda atau nama disingkat tidak ditautkan otomatis.
2. **Super Admin** dapat memeriksa nama tidak cocok pada **Laporan → Bank Sampah → Verifikasi Nama Arsip Excel 2026**, memilih satu akun PJLP/PPPK yang tepat, lalu menyimpan verifikasi. Nama sumber, nilai rupiah, dan Kg asli tidak diubah.
3. Pemetaan disimpan pada tabel **tambahan** `mobile_bank_sampah_archive_member_links_2026` dengan `source_member_name, user_id, verified_by, verified_at`, bukan mengubah tabel `portal_users`.
4. **Hanya baris Excel berstatus `confirmed`** yang dihitung. Dua baris `review` tidak menjadi saldo sampai diklarifikasi. Tanggal yang memiliki penimbangan live aktif didahulukan, sama seperti aturan rekap 2616.
5. `summary?year=2026` dan rekap tahunan kini memakai penautan identitas konsisten; nominal ditambah dari live+arsip tanpa menggandakan sesi tanggal yang sama.
6. Tahun lainnya tetap menghitung data penimbangan aplikasi seperti sebelumnya.

## Langkah pemasangan
1. **Backup database dan file `public_html/mobile-api/bank_sampah_2610.php`**.
2. Pastikan SQL arsip 2026 sudah diimpor. Jika belum, impor **`CIKOKO_BANK_SAMPAH_IMPOR_2026_SAFE.sql`** yang disediakan sebelumnya. Tidak perlu mengimpor ulang jika tabel arsip sudah berisi data.
3. Ekstrak patch khusus `mobile-api/bank_sampah_2610.php` versi 2617 ke dalam `public_html`. Jangan timpa `bootstrap.php`, `index.php`, atau folder privat. Database live lainnya tidak diubah.
4. Login ulang atau buka ulang menu Profil pada HP dan periksa kartu 2026. **Aplikasi lama 2614/2616 bisa menampilkan angka yang benar dengan patch server 2617**, karena format respons `summary` tetap sama.
5. Untuk menautkan **nama Excel yang disingkat atau belum cocok**, gunakan layar Admin di APK versi **2.6.17 (build 2617)** setelah rilis dan uji.
6. Uji akun contoh nama lengkap yang persis cocok dan nama singkat yang seharusnya tetap belum terhubung. Pastikan tidak terjadi penetapan saldo ke akun berbeda.
7. Jangan aktifkan force-update sampai AAB 2617 diterbitkan dan diuji jika fitur verifikasi Admin diperlukan.

## Catatan status
Pengembangan pada branch/PR GitHub tidak memasang file ke cPanel secara otomatis. Kami tidak memiliki sesi akses tulis MySQL cPanel, sehingga nilai nyata dan apakah SQL 2026 telah diimpor **belum diverifikasi di produksi**.
