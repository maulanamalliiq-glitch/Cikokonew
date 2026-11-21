-- Jumantik Mandiri Warga 2607: isolated additive schema.
-- BACKUP database before migration. Never DROP/DELETE/REPLACE older Jumantik records.
CREATE TABLE IF NOT EXISTS mobile_jumantik_mandiri_2607 (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  public_id CHAR(32) NOT NULL UNIQUE,
  user_id VARCHAR(80) NOT NULL,
  client_key CHAR(32) NOT NULL,
  waktu DATETIME NOT NULL,
  nama_kepala_keluarga VARCHAR(160) NOT NULL,
  nama_pengirim VARCHAR(160) NOT NULL,
  no_handphone VARCHAR(25) NOT NULL,
  alamat VARCHAR(500) NOT NULL,
  checks_json TEXT NOT NULL,
  kegiatan VARCHAR(25) NOT NULL,
  photo_name VARCHAR(70) NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'pending',
  reject_reason VARCHAR(300) NOT NULL DEFAULT '',
  reviewed_by VARCHAR(80) DEFAULT NULL,
  reviewed_at DATETIME DEFAULT NULL,
  published_at DATETIME DEFAULT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_owner_client (user_id,client_key),
  INDEX idx_owner (user_id,id),
  INDEX idx_review (status,id),
  INDEX idx_public (published_at,id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
