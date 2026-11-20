# Cikoko 2601 - Persyaratan pelayanan (website to Android)
Sumber tunggal: public_html/data/cikoko_service_requirements.json, dikelola Super Admin website patch 2600.
Endpoint baca-saja: GET https://datawebs.my.id/mobile-api/service_requirements_public.php
Payload items dengan kunci api:<id> atau cms:<id> dan cms_services dari layanan CMS publik. Tanpa perubahan katalog mobile, SQL, atau peran.
Flutter: tombol Layanan Masyarakat Terpadu pada Beranda/Layanan Online/Katalog DKI membuka lightbox kartu Judul - Lihat Persyaratan. Bila kosong, tawarkan tautan utama lama.
Perubahan Super Admin langsung muncul saat pengguna membuka ulang lightbox (GET baru).
Server PHP belum terpasang otomatis oleh APK. Salin cpanel/mobile-api/service_requirements_public.php ke public_html/mobile-api/ setelah website patch 2600.
Jangan menghapus atau menimpa data/cikoko_service_requirements.json.
Release versionCode=2601, versionName=2.6.1, sertifikat keystore lama.
