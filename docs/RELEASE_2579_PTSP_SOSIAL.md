# Cikoko Smart 2.5.79 (2579) — role PTSP dan SOSIAL

## Perubahan
- Role **PTSP** yang sudah ada: panduan alur PTSP serta menu verifikasi/arsip sesuai izin server.
- Role baru **SOSIAL**: kegiatan, riwayat, informasi layanan, berita, pengumuman, dan panduan peran.
- Role ASN: panduan dalam aplikasi yang membedakan verifikasi laporan, supervisor cuti PPPK, Lurah, dan cuti PJLP.
- Admin Utama tetap satu-satunya pihak yang boleh mengelola akun dan hak akses.
- Belum termasuk modul kelayakan bantuan sosial atau sinkronisasi data khusus antarbidang.

## Pemasangan API secara aman
Karena `bootstrap.php` memerlukan `roles-lib.php`, role SOSIAL baru hanya terdeteksi setelah backend dan `roles-lib.php` yang kompatibel dipasang. Paket GitHub Actions memuat **roles-lib.php** dan **mobile-api/permissions.php**. Sebelum mengganti file PHP cPanel, lakukan backup dan diff terhadap file aktif, terutama jika di cPanel ada perubahan manual terbaru pada chat atau website site-v3. **Jangan unggah ulang seluruh public_html** atau menghapus `mobile-api/private`, data, akun, atau dokumen.

Pembuatan akun dilakukan oleh Admin Utama di aplikasi:
**Kelola Akun Petugas → Tambah Akun → PTSP atau Sosial / Kesejahteraan Rakyat**.
Isi nama, username unik, sandi pribadi yang kuat, dan kontak jika diperlukan.
Kode ini tidak otomatis menerbitkan identitas, tidak mengubah akun yang sudah ada, dan tidak membuat akun melalui SQL.

Uji sebelum peluncuran:
1. Login PTSP, Sosial, ASN, Admin Utama, dan Warga dengan masing-masing akun uji.
2. SOSIAL hanya boleh mengirim laporan kegiatan sendiri, bukan membuka seluruh laporan atau mengubah peran.
3. PTSP tidak dapat mengelola akun; batas akses laporan PTSP mengikuti izin server yang sudah aktif.
4. ASN hanya boleh melakukan persetujuan atasan untuk permohonan PPPK yang ditugaskan.
5. Uji status backend dan foto/chat yang sudah ada, terutama kondisi `CHAT_ID_SCHEMA` pada database produksi — build APK bukan bukti perbaikan database.

Lihat `docs/AKUN_PTSP_SOSIAL_ALUR_ASN_CIKOKO.md` untuk alur dan batasan rinci.
