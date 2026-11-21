# Bank Sampah Cikoko 2.6.18+2618 — Rincian timbang pribadi

## Perubahan berdasarkan dua screenshot Profil akun PJLP
Dari **Profil → Bank Sampah Cikoko** (panah kanan pada kartu), halaman kedua sekarang tetap menampilkan **total Kg, Rupiah, dan jumlah catatan tahun tersebut** di atas, tetapi di bawahnya terdapat **Rincian Penimbangan Saya**, bukan kartu petunjuk yang mengatakan detail hanya untuk Admin/ASN.

Rincian dirancang kompak untuk HP:
- Filter **Semua Bulan / bulan tertentu**, di bawah total tahunan.
- Pengelompokan **per tanggal penimbangan**.
- Setiap baris: **Nama Barang · Berat Kg · Harga/Nilai Rupiah** (angka sebenarnya dari database).
- Subtotal Kg dan Rupiah untuk tiap tanggal.
- Rekap filter bulan (Kg, Rp, jumlah rincian).
- Label arsip untuk setoran yang berasal dari Excel terverifikasi 2026.
- Empty state ketika belum ada setoran pada tahun/bulan terpilih.
- Angka contoh dari screenshot Wawan Setiawan: **333,1 Kg | Rp 652.500 | 36 catatan**; **nama barang dan nominal per transaksi tidak diisi dari asumsi** — selalu dari API anggota yang sedang login.

## Perlindungan
- Endpoint baru `GET mobile-api/bank_sampah_2610.php?action=personal_entries&year=2026` wajib autentikasi, hanya untuk `pjlp` atau `pppk`, dan mengambil `$actor['user_id']` dari sesi. **Tidak ada parameter `user_id` untuk memilih anggota lain**.
- Endpoint `summary` dan `personal_entries` kini memakai helper `ckbs_personal_entries` yang sama, agar total Kg/Rp/catatan selalu sama dengan rincian baris.
- Catatan `voided` tidak ditampilkan. Arsip Excel hanya baris `confirmed` dan identitas yang cocok unik atau ditautkan Admin (termasuk `Subhan → Aan Subhan` dan `Agus K → Agus Kurniawan`).
- Jika suatu tanggal sudah ada setoran aplikasi, arsip untuk tanggal tersebut tidak digandakan.
- Tidak ada penggantian database, tidak mengubah akun, Jumantik, chat, cuti, absensi, kinerja atau riwayat lama.

## Instalasi
1. Backup database dan `public_html/mobile-api/bank_sampah_2610.php`.
2. Jika data 2026 belum diimpor, impor SQL 2026 **melalui phpMyAdmin**, bukan menaruhnya di `public_html`. Bila sudah ada, **jangan impor ulang**.
3. Unggah paket **API Bank Sampah 2618 saja** dan ekstrak ke `public_html`; jangan menimpa `index.php`, `bootstrap.php`, file auth atau database.
4. Untuk **melihat tabel rincian per barang di HP**, harus menggunakan APK/AAB **2.6.18+2618** setelah build lulus dan uji di Internal Testing. Pada APK lama, hanya kartu total yang tersedia.
5. Uji dengan akun PJLP/PPPK sendiri: buka profil → Bank Sampah → rincian per tanggal → bandingkan jumlah seluruh Kg/Rp dengan kartu total di atas. Ganti bulan, tarik refresh, lihat juga 2027 kosong.
6. Akun PJLP lain tidak boleh melihat nama barang / harga milik Wawan. Super Admin / ASN / Lurah tetap menggunakan akses monitoring terpisah.
7. Belum ada pemasangan otomatis ke cPanel ataupun Play Store dari PR draft ini.

## Status
PR berbasis perubahan bertahap hingga 2617; belum di-merge ke `main`. Nama dan nilai transaksi yang ditampilkan bergantung pada database produksi yang telah diimpor dan tervalidasi, **bukan** hardcode contoh pada screenshot.
