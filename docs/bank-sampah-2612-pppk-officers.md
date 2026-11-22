# Cikoko Smart 2.6.12+2612 — Bank Sampah sesuai mockup dan petugas PPPK

## Perubahan dari versi 2610/2611
- Super Admin dapat menunjuk **petugas Bank Sampah dari PJLP atau PPPK**, maksimal **lima petugas aktif secara total** (bukan lima tiap role).
- Semua PJLP/PPPK tetap tercatat sebagai **anggota**, terpisah dari status petugas. Perubahan penunjukan tidak menghapus akun, absensi, kinerja, cuti, Jumantik, atau rekam penimbangan yang sudah ada.
- Form di **Laporan → Bank Sampah Cikoko** dibuat mengikuti mockup: **Input Bank Sampah**, **Data Penimbangan** (Hari Minggu, Tanggal, Petugas), kartu **Total Kg** dan **Total Rupiah**, tabel **No, Nama Anggota, Nama Barang, Hasil Timbangan (Kg), Jumlah (Rp)**, serta tombol **Tambah Baris, Simpan Draft, Simpan Penimbangan**.
- Nama anggota dipilih dari daftar PJLP/PPPK aktif; nama barang, Kg, dan Rp dapat diisi atau dikoreksi petugas pada sesi terbuka.
- **Tambah Baris** membuka formulir per baris. Setiap baris yang disimpan langsung tersimpan aman di server sebagai draft; **Simpan Draft** memeriksa dan memuat ulang draft tersebut tanpa menutup sesi.
- **Simpan Penimbangan** mengirim sesi berisi sedikitnya satu baris untuk diperiksa Admin: status `open → submitted`; petugas tidak bisa mengedit sampai Admin membuka kembali. Notifikasi pribadi dikirim ke petugas dan Super Admin.
- Admin dapat **Sahkan Penimbangan** (status `closed`, rekap tahunan berlaku), atau **Buka Kembali untuk Koreksi** (status `open`).
- Di bawah foto Profil PJLP/PPPK, ringkasan angka `Kg | Rp` tetap mengambil data asli server. Akses ASN/Lurah untuk melihat semua hasil dan rekap tahunan dipertahankan.
- Jadwal default Minggu ke-2 dan ke-4, atau alternatif per 2 bulan yang dipilih Admin.
- Navbar bawah tetap **Layanan – Inovasi – Beranda – Laporan – Profil**; chat tetap tombol mengambang.

## Patch cPanel aman
Gunakan artifact **`CikokoSmart-2612-BankSampah-PPPK-API-SAFE`** pada GitHub Actions (setelah workflow lulus). Paket khusus Bank Sampah:
```
mobile-api/bank_sampah_2610.php     (file PHP API Bank Sampah yang diperbarui)
sql/migrate_bank_sampah_2610.sql   (skema aditif sama; hanya jika tabel belum ada)
PETUNJUK-PASANG.txt
```
1. Backup database dan `public_html/mobile-api/bank_sampah_2610.php` (serta semua data/foto lama).
2. Untuk hosting yang **sudah memasang versi 2610**, cukup ganti `mobile-api/bank_sampah_2610.php`; **jangan impor SQL lagi** karena tabel tidak berubah.
3. Jika Bank Sampah belum pernah dipasang, jalankan `sql/migrate_bank_sampah_2610.sql` setelah backup dan unggah file PHP baru sesuai struktur.
4. Jangan timpa `index.php`, `bootstrap.php`, `private/`, `portal_users`, atau modul lain. Jangan import ulang schema lengkap.
5. Uji akun PPPK yang ditunjuk Admin: dapat membuka formulir dan mengisi berat/rupiah. Uji PPPK biasa: hanya lihat ringkasan, tidak bisa menulis. Uji PJLP petugas tetap bisa input, lalu uji batas maksimum lima petugas gabungan.
6. Uji satu sesi terbuka: tambah dua baris → Simpan Draft → kirim → status `submitted` → Admin sahkan → rekap tahun dan kartu profil benar. Pastikan setelah dikirim petugas tidak bisa mengedit.
7. Notifikasi admin dan petugas memerlukan mekanisme Cikoko lama (`mobile_emit` + dispatcher/FCM) tetap berjalan.
8. **Jangan aktifkan force_update** sebelum versi Android baru **2612** benar-benar tersedia untuk semua pengguna sasaran di Play Store dan lolos Internal Testing.

## APK/AAB
Tampilan Flutter membutuhkan rilis aplikasi baru. Target versionName `2.6.12`, versionCode `2612`, paket Android dan keystore sama seperti rilis sebelumnya. Sebelum upload, cek bahwa versionCode ini lebih tinggi dari nilai tertinggi di Play Console. Perubahan API/anggota/data setelah aplikasi baru terpasang tidak memerlukan Play Store.

## Catatan hasil uji
PR dan workflow GitHub kandidat rilis bukan berarti fitur sudah aktif pada hosting produksi atau Play Store. Pengujian database nyata, notifikasi FCM, dan pemasangan pada perangkat masih perlu dilakukan sebelum pengumuman rilis.
