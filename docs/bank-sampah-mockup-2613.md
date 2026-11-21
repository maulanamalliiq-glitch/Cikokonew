# Cikoko Smart 2.6.13+2613 — UI Bank Sampah sesuai mockup

## Antarmuka utama
- Navbar bawah **Layanan · Inovasi · Beranda · Laporan · Profil**, dan Chat tetap melalui tombol mengambang.
- Halaman **Laporan → Bank Sampah** menampilkan header biru **Cikoko Smart · Kelurahan Cikoko**, judul besar **Input Bank Sampah** dengan ikon daur ulang.
- Kartu **Data Penimbangan**: Hari Minggu, **Tanggal** (pilih dari jadwal yang sudah dibuka Admin), **Petugas** (nama akun PJLP atau PPPK yang login).
- Dua kartu hijau untuk **Total Kg** dan **Total Rupiah**. Angka dihitung langsung dari kolom input aktual; **324 Kg / Rp 231.000** hanya angka contoh pada mockup, bukan data palsu di aplikasi.
- Tabel biru dengan kolom **No, Nama Anggota, Nama Barang, Hasil Timbangan (Kg), Jumlah (Rp)**. Baris diisi langsung di tabel; nama anggota dipilih dari daftar PJLP/PPPK aktif dan nama barang dari pilihan cepat atau teks bebas.
- Tabel bisa digeser mendatar pada HP sempit agar nama/angka tetap terbaca tanpa terpotong. Tidak mengubah lebar navbar bawah.
- Tombol **Tambah Baris**, **Simpan Draft**, dan **Simpan Penimbangan** mempunyai aksi nyata.
- Area petunjuk di bawah form menegaskan hak petugas, sumber data anggota, dan proses pengesahan Admin.

## Alur data
- **Petugas** harus ditunjuk Super Admin; petugas boleh **PJLP atau PPPK** maksimal lima aktif gabungan.
- Tiap baris memiliki validasi nama, anggota, kilogram maksimal 3 desimal, dan angka rupiah.
- **Simpan Draft** menyimpan perubahan baris (tabel \`mobile_bank_sampah_entries_2610\`) pada sesi terbuka; angka pada kartu berubah saat pengguna mengetik.
- **Simpan Penimbangan** melakukan penyimpanan draft terlebih dahulu, meminta konfirmasi, lalu mengubah sesi \`open → submitted\`; Admin mendapat notifikasi untuk memeriksa.
- **Super Admin** mengesahkan sesi sehingga status \`closed\`, atau mengembalikan ke \`open\` untuk koreksi; data tetap di database dan masuk rekap tahunan.
- Pindah tanggal menawarkan penyimpanan draft terlebih dahulu jika ada perubahan belum tersimpan.
- ASN/Lurah hanya melihat hasil dan rekap; PJLP/PPPK yang tidak ditunjuk hanya melihat ringkasan milik sendiri.

## Deployment dan keamanan
- Tidak perlu SQL baru. **Backend Bank Sampah 2612 tetap digunakan.**
- Apabila file backend terbaru belum dipasang, gunakan patch aman yang sudah dibuat untuk 2612, **bukan** paket lengkap yang menimpa \`mobile-api/index.php\`.
- Satu-satunya perubahan 2613 adalah Flutter UI dan pengujian UI, sehingga **Play Store memerlukan AAB Android baru 2.6.13+2613**. Sumber produksi, data PJLP/PPPK, chat, Jumantik, cuti, absensi, login Google dan konfigurasi privat tidak diubah.
- Pemasangan AAB dan cPanel **tidak dilakukan otomatis**. Jangan mengaktifkan force-update sampai versi baru tersedia penuh dan diuji.
- Tampilan sudah dibangun untuk mengikuti mockup sedekat mungkin; penilaian kesamaan visual di berbagai ukuran HP masih memerlukan pengujian perangkat nyata sebelum klaim identik secara piksel.

## Checklist uji
1. Admin tunjuk seorang petugas PPPK dan petugas PJLP; gabungan aktif maksimum lima.
2. Admin buat tanggal pada Minggu ke-2 atau ke-4; buka **Laporan → Bank Sampah**.
3. Petugas pilih tanggal pada kartu Data Penimbangan; tambah baris, isi nama anggota, kardus, 2,5 Kg, Rp 3.000.
4. Pastikan total berubah ke 2,5 Kg dan Rp 3.000; simpan draft, keluar lalu buka kembali.
5. Kirim penimbangan; pastikan status menunggu Admin, tombol input terkunci, dan notif tersedia.
6. Admin sahkan; ASN/Lurah lihat rekap, PJLP/PPPK lihat ringkasan masing-masing di Profil.
7. Periksa layar kecil, teks besar, orientasi layar, dan scroll tabel. Uji chat mengambang dan menu laporan lain tidak terganggu.
