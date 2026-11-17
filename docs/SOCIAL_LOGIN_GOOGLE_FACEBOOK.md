# Login Google dan Facebook — Cikoko Smart

Status: **belum aktif pada aplikasi 2570** sampai kredensial resmi Google Cloud dan Meta for Developers terpasang.
Tidak boleh membuat tombol login palsu yang menerima email / user ID tanpa validasi token server.

## Identitas Android yang dipertahankan
- Android applicationId: `com.KelurahanCikoko.malik`
- Keystore dan sertifikat signing Play Store yang ada tidak diubah.
- Server: `https://datawebs.my.id/mobile-api/`

## Google
1. Di Google Cloud, konfigurasi OAuth consent screen untuk organisasi Kelurahan Cikoko.
2. Buat Android OAuth client menggunakan applicationId dan SHA-1/SHA-256 sertifikat yang sesuai.
3. Buat OAuth Web Client ID untuk validasi token di backend.
4. Aplikasi Android menggunakan Credential Manager / Google Identity (atau plugin Flutter resmi yang kompatibel).
5. Kirim **Google ID token** ke backend lewat HTTPS. Di backend, verifikasi tanda tangan, `aud` ke Web Client ID, `iss`, `exp`, dan ID permanen `sub`. Jangan mempercayai email dari input bebas.

## Facebook
1. Buat aplikasi resmi di Meta for Developers dengan Facebook Login dan Android key hashes.
2. Simpan App ID pada Android, App Secret hanya di server (tidak di APK/GitHub).
3. Kirim access token yang diberikan SDK ke backend lewat HTTPS.
4. Verifikasi dengan Graph API `debug_token` menggunakan kredensial server, periksa status aktif, app_id, subjek, kedaluwarsa; ambil data profil sesuai izin pengguna.
5. Email dari Facebook bersifat opsional, bukan bukti kepemilikan akun Cikoko yang sudah ada.

## Aturan akun untuk keamanan data
- Akun warga baru melalui login sosial hanya memiliki role `warga` (bukan PPPK/PJLP/admin).
- Cocokkan identitas menggunakan ID provider yang sudah diverifikasi, **bukan hanya email/nama**.
- Jangan otomatis menghubungkan akun pegawai/admin yang sudah ada. Pemilik akun harus login biasa terlebih dahulu lalu melakukan tautkan akun secara eksplisit.
- Data yang dapat diambil setelah izin pengguna: nama, email yang diverifikasi, dan avatar bila tersedia; jangan mengambil daftar teman atau data berlebihan.
- Data alamat, RT/RW, telepon dan identitas lain yang belum lengkap diisi melalui **Profil Akun**.
- Token provider tidak disimpan sebagai password aplikasi; sesi Cikoko sendiri disimpan aman dan bisa dicabut.
- Jika kredensial OAuth belum terpasang, login standar yang sudah ada tetap berfungsi tanpa gangguan.

## Syarat sebelum build produksi
- Google Web Client ID, konfigurasi Android dan SHA signing.
- Meta App ID, App Secret server, Android key hashes, status aplikasi live.
- Persetujuan kebijakan privasi / pemeriksaan izin yang diwajibkan provider.
- Uji pendaftaran warga baru, akun sudah ada, pemutusan koneksi, kesalahan token, dan pelindungan akun PPPK/admin.

Tidak ada client secret yang boleh dimasukkan ke dalam repositori atau APK.
