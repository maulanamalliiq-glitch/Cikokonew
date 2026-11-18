import 'package:flutter/material.dart';

/// Informational handbook only: all actual permissions are enforced by PHP.
/// This screen never pretends to approve requests or change resident data.
class CikokoStaffGuidePage extends StatelessWidget {
  final String role;
  const CikokoStaffGuidePage({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final title = switch (role) {
      'ptsp' => 'Alur Pelayanan PTSP',
      'sosial' => 'Alur Unit Sosial',
      'asn' => 'Alur Kerja ASN',
      _ => 'Panduan Petugas',
    };
    final intro = switch (role) {
      'ptsp' => 'Penerimaan, pemeriksaan, dan tindak lanjut permohonan sesuai hak akses PTSP Kelurahan Cikoko.',
      'sosial' => 'Pelaksanaan kegiatan sosial kelurahan dan pelaporan yang terbatas pada akun unit sosial.',
      'asn' => 'Tugas ASN sesuai penugasan: verifikasi laporan serta persetujuan sebagai atasan langsung yang ditetapkan.',
      _ => 'Pilih menu yang sesuai dengan kewenangan akun.',
    };
    final steps = switch (role) {
      'ptsp' => const <(String, String)>[
        ('1. Terima berkas', 'Permohonan warga masuk melalui layanan yang tersedia. Periksa identitas, kelengkapan, dan jenis permohonan.'),
        ('2. Periksa pengajuan', 'Buka Verifikasi Laporan atau Arsip Ahli Waris sesuai izin server. Jangan memproses data di luar lingkup penugasan.'),
        ('3. Tindak lanjuti', 'Beri status dan catatan administrasi sesuai hasil pemeriksaan. Persetujuan substantif hanya oleh pejabat yang berwenang.'),
        ('4. Informasi pemohon', 'Warga memeriksa perkembangan di Riwayat dan Notifikasi aplikasi.'),
      ],
      'sosial' => const <(String, String)>[
        ('1. Masuk akun unit', 'Gunakan akun Sosial yang dibuat Admin Utama, bukan akun administrator bersama.'),
        ('2. Dokumentasikan kegiatan', 'Isi Laporan Kegiatan disertai keterangan dan foto sesuai tugas.'),
        ('3. Pantau riwayat', 'Periksa status laporan sendiri dari menu Riwayat dan baca pengumuman layanan.'),
        ('4. Eskalasi layanan', 'Permohonan bantuan dan keputusan kelayakan ditangani melalui prosedur resmi kelurahan. Akses verifikasi seluruh laporan warga tidak diberikan otomatis.'),
      ],
      'asn' => const <(String, String)>[
        ('1. Periksa laporan', 'ASN dengan izin reports:view dan reports:verify dapat meninjau serta memperbarui status laporan sesuai penugasan. Setiap keputusan harus memiliki dasar pemeriksaan.'),
        ('2. Cuti PPPK – pengajuan', 'PPPK mengajukan cuti; Admin memeriksa kelengkapan terlebih dahulu.'),
        ('3. Cuti PPPK – atasan langsung', 'Hanya akun ASN yang ditunjuk sebagai atasan langsung pengajuan yang dapat menyetujui atau menolak tahap ini.'),
        ('4. Cuti PPPK – Lurah', 'Setelah atasan menyetujui, pengajuan diteruskan kepada Lurah untuk keputusan akhir.'),
        ('5. Cuti PJLP', 'Modul PJLP yang saat ini terpasang menggunakan keputusan Admin Kelurahan; jangan menganggap alurnya sama dengan PPPK.'),
        ('6. Batas akses', 'ASN tidak dapat menambah akun, mengubah role, atau mewakili Lurah tanpa kewenangan yang diberikan sistem.'),
      ],
      _ => const <(String, String)>[],
    };
    return ListView(
      key: const Key('cikoko_staff_guide'),
      padding: const EdgeInsets.all(16),
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(intro, style: const TextStyle(color: Colors.blueGrey)),
        const SizedBox(height: 12),
        for (final step in steps)
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: const Icon(Icons.assignment_outlined, color: Color(0xFF135BC6)),
              title: Text(step.$1, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(step.$2),
              ),
            ),
          ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 14),
          child: Text(
            'Panduan ini menjelaskan alur kerja di aplikasi, bukan pengganti SOP dan keputusan pejabat yang berwenang.',
            style: TextStyle(fontSize: 12, color: Colors.blueGrey),
          ),
        ),
      ],
    );
  }
}
