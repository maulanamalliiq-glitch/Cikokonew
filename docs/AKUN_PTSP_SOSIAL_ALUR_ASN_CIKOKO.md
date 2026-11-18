# Akun PTSP, Unit Sosial, dan Alur ASN — Kelurahan Cikoko

Acuan teknis: `Cikokonew/main`, role login dari `portal_users` dan izin final dari `mobile-api/permissions.php`. **Bukan instruksi untuk mengganti akun/berkas database yang sudah ada.**

## 1. Akun unit PTSP
- Role mesin: `ptsp` — sudah tersedia sebelum perubahan ini.
- Nama tampilan: **PTSP**.
- Menu aplikasi: Alur Pelayanan PTSP; Verifikasi Laporan (hanya bila `reports:view` disetujui); Arsip Ahli Waris (bila `archive:view` tersedia); Laporan Kegiatan; Riwayat; Layanan Masyarakat; Pengumuman.
- Hak awal server yang sudah ada: `report:kegiatan`, `reports:view`, `reports:verify`, `waris:view`, `waris:verify`.
- PTSP bukan Admin Utama. Tidak boleh menciptakan akun, mengubah role, mengedit konten publik, atau menandatangani atas nama Lurah.
- Karena `reports:view` saat ini bersifat umum di API lama, Admin Utama harus membatasi petugas PTSP sesuai penugasan nyata. Audit akses lintas unit perlu dilakukan sebelum data sensitif dibuka.

## 2. Akun unit SOSIAL
- Role mesin baru: `sosial`.
- Nama tampilan: **Sosial / Kesejahteraan Rakyat**.
- Menu aplikasi: Alur Unit Sosial; Laporan Kegiatan; Riwayat; Layanan Masyarakat; Berita; Pengumuman.
- Hak awal: `report:kegiatan` saja; **tidak** mendapat `reports:view`, `reports:verify`, `waris:verify`, `chat:reply`, `content:create`, atau `role:manage`.
- Pengelolaan permohonan bansos, penentuan kelayakan, dan penyaluran dana **belum tersedia sebagai modul tersendiri**. Jangan menganggap laporan kegiatan sebagai keputusan bantuan sosial.
- Jika kelurahan membutuhkan antrean permohonan sosial dan verifikasi sesuai standar, buat modul khusus dengan pemisahan data penerima, riwayat keputusan, serta peran ASN/pejabat yang ditunjuk, setelah SOP disetujui.

## 3. Cara membuat akun oleh Admin Utama
1. Update paket aplikasi dan API yang mendukung role `sosial` (termasuk `roles-lib.php`, `mobile-api/permissions.php`, dan `mobile-api/index.php`). Jangan mengganti seluruh `public_html` ataupun database.
2. Login sebagai **Admin Utama** pada aplikasi, bukan akun warga/admin biasa.
3. Buka **Kelola Akun Petugas** → **Tambah Akun**.
4. Isi **Nama Lengkap**, username unik, sandi awal kuat dan acak, dan pilih **PTSP** atau **Sosial / Kesejahteraan Rakyat**. Kontak petugas diisi sesuai izin penggunaan data internal.
5. Simpan dan pastikan akun aktif; masuk dengan akun baru secara terpisah. Periksa menu dan akses yang benar; jangan menyampaikan sandi melalui grup publik.
6. Jika role Sosial tidak muncul, API cPanel belum menggunakan `roles-lib.php` baru. **Jangan** mengubah role secara langsung melalui SQL, karena akun petugas di aplikasi ini dikelola oleh penyimpanan `portal_users`, bukan tabel MySQL tunggal.

Penetapan user ID dan sandi akun produksi hanya boleh dilakukan melalui proses admin yang sah. Update kode ini **tidak otomatis membuat akun atau mengirim kredensial**.

## 4. Alur ASN dalam kode terpasang

### A. Laporan / pelayanan
Warga atau petugas mengirim laporan → laporan masuk ke sistem → ASN yang punya `reports:view` memeriksa → ASN yang memiliki `reports:verify` memberi status dan catatan sesuai kewenangan → pemohon melihat status pada riwayat/notifikasi. `waris:verify` adalah hak terpisah untuk proses Ahli Waris. Kode saat ini masih memiliki endpoint laporan dengan cakupan umum; pembatasan per bidang yang lebih ketat memerlukan penyesuaian SOP dan API.

### B. Cuti PPPK
**PPPK mengajukan** → **Admin memeriksa** (`pending_admin`) → **ASN yang ditetapkan sebagai atasan langsung** menyetujui/menolak (`pending_supervisor`) → **Lurah** melakukan keputusan akhir (`pending_lurah`) → status disetujui atau ditolak dan notifikasi dikirim. Hanya akun atasan yang tercatat pada permohonan yang berwenang di tahap ASN.

### C. Cuti PJLP
Berbeda dari PPPK: versi backend `pjlp_leave.php` yang diperiksa menggunakan **Admin Kelurahan** untuk keputusan administratif langsung. Dokumen dan QR pejabat diproses sesuai konfigurasi pejabat, tetapi bukan antrean persetujuan ASN→Lurah di dalam API PJLP. Jika SOP Kelurahan mewajibkan dua persetujuan aktif, modul PJLP perlu direvisi sebelum dinyatakan sesuai SOP.

### D. Hal yang tidak otomatis diberikan kepada ASN
ASN bukan Lurah, bukan Admin Utama, tidak berhak membuat akun atau mengubah izin role. Admin Utama mengatur penugasan dan batasan akses; keputusan yang mewajibkan pejabat tertentu tidak boleh dilewati dengan perubahan role.

## 5. Kontrol peluncuran
- Back up `public_html/mobile-api`, `roles-lib.php`, dan penyimpanan `portal_users` sebelum deploy.
- Pastikan cPanel dan APK memakai kode yang kompatibel. Jangan pasang ZIP backend lama di atas update chat/database manual.
- Login sebagai akun PTSP → hanya bisa akses verifikasi sesuai izin; tidak dapat kelola akun.
- Login sebagai akun Sosial → bisa kirim laporan kegiatan dan membaca riwayatnya; tidak dapat melihat atau memutuskan seluruh laporan warga.
- Login sebagai ASN atasan → hanya mengesahkan cuti PPPK yang ditugaskan; Lurah tetap berwenang pada tahap akhir.
- Periksa audit dan notifikasi pada akun yang benar, serta uji login lama setelah update.
