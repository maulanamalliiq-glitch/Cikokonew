# PPPK — Bukti Foto Kehadiran Berlokasi (Usulan)

Tujuan: memperbaiki pencatatan titik GPS dan bukti foto absensi PPPK saja, tanpa mengubah website, desain, cuti, PDF kinerja, chat, atau notifikasi.

## Perubahan
- Kamera langsung dari Android (bukan galeri).
- GPS presisi diambil sebelum dan sesudah membuka kamera; jika akurasi lebih dari 50 m, lokasi terlalu lama, atau perpindahan lebih dari 70 m, foto harus diulang.
- Reverse-geocoding lokal platform Android. Keterangan alamat adalah perkiraan, bukan jaminan nomor rumah tepat. Bila geocoder gagal, koordinat dan akurasi tetap dicatat pada foto.
- Label dicetak pada piksel JPEG: nama akun aktif, keanggotaan PPPK/Kelurahan Cikoko, jenis foto, waktu WIB dari perangkat, GPS, akurasi, dan alamat perkiraan.
- Bukti foto berlaku untuk absen masuk, pulang, dan laporan pekerjaan tahap 0, 50 dan 100 persen.
- Endpoint baca foto: pppk_staff_photo, hanya pemilik foto dan admin, HTTP Cache-Control no-store.
- Endpoint pemantauan: pppk_staff_monitor, hanya admin, tidak mengirim byte gambar di daftar.
- APK lama masih bisa mengakses API lama karena validasi captured_at/GPS tahap foto opsional pada permintaan lama.

## Keamanan dan batasan
- Koordinat, alamat dan foto termasuk data internal pegawai. Jangan mempublikasikan gambar ke publik.
- Stempel gambar bukan tanda tangan elektronik atau bukti anti-pemalsuan. Jam resmi absensi tetap waktu server, bukan jam HP.
- Geocoder dapat tidak menyediakan nama jalan/nomor rumah. Jangan menggantinya dengan alamat kantor bila sedang dinas luar.
- Saat GPS kurang akurat, petugas harus mencoba lagi dari lokasi lebih terbuka.
- Cabang ini belum dipasang ke cPanel/Play Store.

## Uji penerimaan sebelum rilis
1. Jalankan flutter pub get, flutter analyze dan flutter test.
2. Jalankan php -l pada modul dan tes regresi PHP.
3. Uji akun PPPK pada lokasi kantor, lalu dinas luar dan ketiga tahap bukti foto.
4. Uji foto masuk/pulang/tahap dapat dibuka hanya oleh pemilik atau admin; akun lain ditolak.
5. Bandingkan stempel waktu foto dengan waktu server, dan uji jika jam HP tidak otomatis.
6. Backup modul API lama sebelum pemasangan. Gunakan signing Android lama.

Tidak ada perubahan SQL atau penghapusan data pada usulan ini.
