-- Cikoko Smart 2606: additive Jumantik RT/RW table.
-- Backup database first. Do NOT DROP, DELETE, ALTER existing tables.
CREATE TABLE IF NOT EXISTS mobile_jumantik_reports (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  public_id CHAR(32) NOT NULL UNIQUE,
  user_id VARCHAR(80) NOT NULL,
  officer_role VARCHAR(30) NOT NULL,
  officer_name VARCHAR(160) NOT NULL,
  rt VARCHAR(12) NOT NULL,
  rw VARCHAR(12) NOT NULL,
  coordinator VARCHAR(120) NOT NULL,
  tanggal DATE NOT NULL,
  minggu_ke TINYINT UNSIGNED NOT NULL,
  lokasi VARCHAR(220) NOT NULL,
  tempat_umum_lainnya VARCHAR(10) NOT NULL,
  nama_kepala_keluarga VARCHAR(10) NOT NULL,
  alamat_lengkap VARCHAR(500) NOT NULL,
  jentik VARCHAR(10) NOT NULL,
  photo_name VARCHAR(70) NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'pending',
  published_at DATETIME NULL,
  reviewed_at DATETIME NULL,
  reviewed_by VARCHAR(80) NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_user (user_id,id),
  INDEX idx_review (status,id),
  INDEX idx_published (published_at,id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
