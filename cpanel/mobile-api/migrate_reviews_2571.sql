-- Cikoko Smart / Cikokonew 2571 - Tabel ulasan publik dan admin.
-- Jalankan setelah BACKUP database cPanel. Hanya CREATE TABLE IF NOT EXISTS.
-- Jangan gunakan DROP, TRUNCATE atau impor ulang database produksi.
CREATE TABLE IF NOT EXISTS mobile_app_reviews (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id VARCHAR(80) NOT NULL UNIQUE,
  user_role VARCHAR(40) NOT NULL,
  display_name VARCHAR(120) NOT NULL,
  stars TINYINT UNSIGNED NOT NULL,
  review_text VARCHAR(1200) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_updated(updated_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Pemeriksaan saja (tanpa perubahan data).
SHOW COLUMNS FROM mobile_app_reviews;
SELECT COUNT(*) AS review_count, COALESCE(AVG(stars),0) AS average_stars
  FROM mobile_app_reviews;
