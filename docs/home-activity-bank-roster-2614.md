# Cikoko Smart 2.6.14+2614 — Perbaikan berdasarkan 3 screenshot 21 Nov 2026

## Foto 1 — Update kegiatan di bawah Inovasi Kelurahan
- Beranda akun publik/pegawai menampilkan **Update Kegiatan Terbaru** tepat setelah daftar **Inovasi Kelurahan**.
- Dua bagian dengan kartu kecil: **Kegiatan Jumantik** (hanya berita yang sudah diterbitkan Super Admin dari Jumantik RT/RW atau Jumantik Mandiri) dan **Kegiatan Bank Sampah** (hanya hasil timbang sesi `closed` yang sudah disahkan).
- Menampilkan waktu/tanggal, informasi wilayah seperlunya, serta total agregat **Kg / Rupiah / jumlah setoran** untuk Bank Sampah.
- Identitas keluarga, HP, alamat rumah, nama anggota individual, draft/penimbangan yang belum disahkan **tidak ditampilkan**.
- Tombol `Refresh` memuat informasi terbaru dari API. Jika belum ada publikasi, tampil pesan kosong yang jelas; **tidak ada angka demo**.

## Foto 2 — Tabel input Bank Sampah lebih kompak dan pegawai otomatis
- Form `Laporan → Bank Sampah Cikoko` tetap memakai desain 2613 (Data Penimbangan, tanggal, petugas, total, draft/kirim).
- Pada HP sempit, setiap anggota menjadi baris ringkas **No + Nama** di atas serta **Nama Barang · Kg · Rupiah** di bawah. Seluruh bagian terlihat tanpa horizontal cutoff.
- Daftar anggota tetap bersumber dari akun PJLP/PPPK aktif dan keanggotaan Bank Sampah yang ditentukan Admin. **Pegawai diisi otomatis** (tidak mengetik ulang tiap penimbangan).
- Pegawai baru yang ditambahkan pada tahun berikutnya masuk melalui `INSERT IGNORE` bila akun aktif PJLP/PPPK. Pegawai yang sengaja dinonaktifkan di daftar Bank Sampah oleh Admin **tidak diaktifkan otomatis lagi**. Riwayat lama tetap utuh.
- Baris kosong bukan setoran dan tidak akan dikirim; tambah baris diperlukan hanya jika satu anggota menyetor lebih dari satu jenis sampah.
- Hak petugas **PJLP atau PPPK** yang ditunjuk maksimal 5 orang gabungan; data divalidasi oleh API.

## Foto 3 — Urutan Beranda
Setelah header foto:
1. **Berita Terbaru** — menggantikan posisi awal **Status Pelayanan Surat**.
2. **Pengumuman & Agenda**.
3. **Status Pelayanan Surat** — tepat setelah Pengumuman & Agenda.
4. Menu layanan, Data Rumah Kos, Inovasi Kelurahan, **Update Kegiatan Jumantik & Bank Sampah**, Informasi & Kegiatan.
Navbar tetap **Layanan – Inovasi – Beranda – Laporan – Profil**; **Chat mengambang** tetap berada di kanan bawah.

## Perubahan server & keamanan deployment
- Hanya file API yang diperbarui: `public_html/mobile-api/bank_sampah_2610.php`.
- Endpoint GET publik `?action=public_activity` mengeluarkan hanya tanggal, total kg, total rupiah dan jumlah catatan dari sesi `closed` tanpa data identitas pribadi.
- Skema database **tidak diubah**. Jika 2613/2612 sudah terpasang, **jangan impor ulang SQL**.
- Backup file lama, unggah versi API Bank Sampah terbaru dari artifact SAFE, jangan menimpa `index.php`, `bootstrap.php`, `portal_users`, data chat/Jumantik/cuti/absensi atau folder privat.
- Untuk tampilan Android baru diperlukan build `2.6.14+2614`. AAB signed untuk Play Store harus diuji pada Internal Testing; belum ada publikasi otomatis.
- Jangan aktifkan `force_update` sebelum AAB sudah berhasil terbit dan semua pengguna target bisa mengakses.

## Uji lapangan
1. Akun PJLP/PPPK: lihat urutan Berita → Agenda → Status Surat.
2. Gulir setelah Inovasi: dua bagian kegiatan muncul; tidak ada draft ataupun identitas pribadi yang dipublikasikan.
3. Laporan Bank Sampah: semua anggota aktif terdaftar, baris tidak melebar terpotong; simpan draft 2,5 Kg Rp 3.000 dan muat ulang.
4. Tambahkan PPPK baru/anggota baru dari Admin, pastikan muncul otomatis; nonaktifkan salah satu anggota, pastikan tidak dimunculkan kembali otomatis.
5. Super Admin sahkan hasil timbang, kemudian refresh Beranda dan pastikan agregat kegiatan Bank Sampah muncul.
6. Uji login, notifikasi, chat mengambang, PPID, menu lama, data Jumantik, cuti, kehadiran dan kinerja.
