# Cikoko Smart — Cikokonew

Repository pengembangan Cikoko Smart sekarang menggunakan **satu branch: `main`**.
Ini tetap aplikasi yang sama: **`com.KelurahanCikoko.malik`**, Firebase yang sama,
dan API **https://datawebs.my.id/mobile-api/index.php**.

## Sumber yang dipindahkan

Snapshot dari `maulanamalliiq-glitch/CikokoSmartAPPS`, branch
`feat/chat-runtime-2566`, commit `93597f7b779ba0d25a3ea1c497412765a3a41b78`.
Snapshot ini memuat kode Android **2.5.65+2565** dan pembaruan server chat **2566**.
Branch tersebut berada 5 commit di depan branch `feat/chat-hardcheck-2565`, tanpa commit tertinggal.
Riwayat commit dan branch lama tetap tersedia di repository asal; tidak dihapus.

- `flutter/`: aplikasi, aset, dan pengujian Flutter.
- `cpanel/`: kode backend dari repository asal, bukan salinan lengkap website produksi.
- `qa/`, `tests/`: pengujian PHP.
- `.github/workflows/cikoko.yml`: satu workflow aktif untuk pemeriksaan dan build.
- `docs/legacy-workflows/`: workflow lama yang diarsipkan dengan akhiran `.disabled`.

## Cara build APK dan AAB

1. Tambahkan kembali signing secrets lama di **Settings → Secrets and variables → Actions**:
   `CIKOKO_KEYSTORE_B64`, `CIKOKO_STORE_PASSWORD`, `CIKOKO_KEY_PASSWORD`.
   GitHub tidak menyalin secret saat kode dipindahkan. Jangan membuat keystore baru dan jangan commit kunci atau password.
2. Buka **Actions → Cikoko - Pemeriksaan dan Build APK AAB → Run workflow**.
3. Pilih branch **main**, aktifkan **build_release**, isi versi dan version code.
   Nilai awal yang ditawarkan adalah **2.5.67 / 2567**; pastikan version code lebih tinggi
   dari SEMUA versi yang pernah diunggah ke Play Console. Skrip tidak dapat memeriksa Play Console.
4. Setelah semua job berhasil, unduh artifact **CikokoSmart-[version_code]-APK-AAB**.
   Isinya APK ARM64 dan AAB yang diperiksa menggunakan fingerprint upload key lama.

Push ke `main` menjalankan pemeriksaan saja. Build signed dijalankan manual setelah secrets siap.
Versi input diterapkan pada workspace build; versi snapshot sumber tetap 2.5.65+2565.
Tidak ada pembuatan aplikasi Play Store baru dan tidak ada publikasi Play Store otomatis.

## Batas migrasi

Migrasi repository tidak mengubah website cPanel, database, akun, atau aplikasi yang sudah terpasang.
Jangan menimpa seluruh website dengan direktori `cpanel/`: website produksi memiliki perubahan tersendiri.
Pengujian di perangkat, kecocokan PDF, dan pengiriman FCM tetap perlu diverifikasi sebelum rilis.
Dokumen lama di `docs/legacy-*` hanya referensi historis; gunakan README ini untuk alur build aktif.
