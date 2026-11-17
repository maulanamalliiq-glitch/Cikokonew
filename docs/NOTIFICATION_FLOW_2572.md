# Alur Notifikasi Cikoko Smart — 2.5.72 (2572)

Sumber: **maulanamalliiq-glitch/Cikokonew**, branch `main`. 
Nomor rilis pada APK dan `mobile-api` harus sesuai. Jangan gunakan API atau APK dari CikokoSmartAPPS.

## Prinsip operasional
1. **Tersimpan:** baris `mobile_events` dengan `audience=personal` dan `recipient` ID akun yang dituju. Akun lain tidak bisa membaca atau menandainya.
2. **Belum dibaca:** belum ada `mobile_event_reads` untuk akun dan event itu. Lonceng menampilkan angka belum dibaca (hingga 60 event terbaru per respons).
3. **Antrean push:** event personal yang belum diproses oleh cron. Status ini bukan jaminan notifikasi diterima HP.
4. **Firebase menerima:** Google FCM menerima permintaan push, bukan bukti pesan tampil atau dibuka pengguna.
5. **Dibaca:** pemilik akun membuka event, atau secara sadar memilih **Tandai semua**; hanya saat itu event ditandai dibaca.

## Alur per fitur

| Peristiwa | Penerima | Dibuka dari notifikasi |
| --- | --- | --- |
| Warga mengirim chat | Petugas dengan hak chat | Pesan Masuk / percakapan warga |
| Petugas membalas | Warga pemilik percakapan | Hubungi Kami |
| Pengajuan dan perubahan surat atau laporan | Pemohon atau petugas yang berwenang | Detail dokumen jika tertaut; jika tidak, Riwayat / Verifikasi Laporan |
| Pengumuman atau berita | Kelompok akun yang ditetapkan admin | Berita & Kegiatan |
| Inovasi | Kelompok akun yang ditetapkan admin | Inovasi |
| Cuti PJLP diajukan atau diputuskan | Admin atau pemohon yang berhak | Kelola Cuti PPSU / Cuti PPSU |
| Cuti PPPK dibuat | PPPK pemohon dan admin | Cuti PPPK / Kelola Cuti PPPK |
| Cuti PPPK ditelaah admin | Pemohon dan atasan yang ditetapkan | Cuti PPPK / Kelola Cuti PPPK |
| Cuti PPPK disetujui atasan | Pemohon dan Lurah | Cuti PPPK / Kelola Cuti PPPK |
| Cuti PPPK disetujui atau ditolak | PPPK pemohon | Cuti PPPK |
| Laporan kinerja PPPK dikirim | PPPK pemohon dan admin | Kinerja PPPK |
| Kinerja PPPK disetujui / dikembalikan | PPPK pemohon | Kinerja PPPK |
| Pengumuman umum dari admin | Hanya kelompok yang dipilih | Detail berita/inovasi atau isi pesan di Notifikasi |

Untuk kategori tanpa tautan dokumen, aplikasi menampilkan isi notifikasi; **jangan membuat tautan ke akun lain**. 
Untuk notifikasi tanpa `event_id`, aplikasi membuka kotak masuk atau halaman umum yang aman, bukan menebak pemilik percakapan.

## Tata letak
- Halaman Notifikasi: ringkasan **belum dibaca**, filter **Semua / Belum Dibaca / Sudah Dibaca**, kategori, tanggal dan status.
- Urutkan berdasarkan nomor event terbaru. Pesan lama dibaca tetap ada pada daftar, tidak otomatis dihapus.
- Tombol **Tandai semua** hanya berlaku untuk `recipient` akun yang sedang login.
- Notifikasi FCM saat aplikasi terbuka dan polling untuk event yang sama menggunakan satu ID agar tidak berganda.
- Persetujuan atasan cuti PPPK hanya muncul pada akun atasan yang dipasangkan ke pengajuan; admin kelurahan tetap dapat memantau semua pengajuan, bukan mengambil alih keputusan atasan yang lain.
- Admin menampilkan jumlah token HP, antrean, diterima FCM, gagal dan tanpa token; jangan menyebut diterima FCM sebagai **pesan sudah dibaca**.

## Pemasangan server & migrasi
1. Backup seluruh database serta `public_html/mobile-api`. Jangan menimpa konfigurasi privat, data pegawai, dokumen, atau riwayat chat.
2. Unggah **CikokoSmart-2572-MobileAPI-Patch** yang dihasilkan GitHub Actions.
3. Bila ingin menampilkan notifikasi cuti PJLP lama yang sebelumnya tersimpan dengan audience `private`, **setelah audit dan backup** dapat impor `sql/migrate_notifications_2572.sql`. Skrip ini mengubah hanya event `category='leave'` dengan recipient jelas menjadi `personal`; tidak menghapus event.
4. Pastikan `deployment_status` menunjukkan `api_release=2572` dan endpoint chat, ulasan, serta katalog publik HTTP 200.
5. Uji dua perangkat berlogin berbeda: kirim chat → terima → buka percakapan → baca; lanjut uji surat, cuti PJLP, cuti PPPK, kinerja PPPK, dan pengumuman. Pastikan tidak ada notifikasi akun orang lain.
6. Di panel admin, pastikan cron Firebase aktif, perangkat punya token, dan cek laporan gagal. Pengujian CI tidak dapat membuktikan push sampai ke perangkat Android.

## Syarat rilis
Lulus PHP lint, Flutter analyze, semua pengujian, verifikasi sertifikat, build APK/AAB; lalu verifikasi **API produksi dan uji perangkat**. Jika API produksi belum diperbarui, APK hanya menjadi kandidat pengujian.
