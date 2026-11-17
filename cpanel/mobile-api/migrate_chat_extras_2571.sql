-- Cikoko Smart 2571 — tambahan non-destruktif untuk foto dan notifikasi chat.
-- WAJIB backup MySQL dahulu. Tidak menghapus / menimpa riwayat chat.
-- Gunakan setelah migrate_chat_2544.sql dan audit mobile_chat.id AUTO_INCREMENT.
CREATE TABLE IF NOT EXISTS mobile_chat_photos (
  message_id BIGINT UNSIGNED NOT NULL PRIMARY KEY,
  owner_id VARCHAR(80) NOT NULL,
  stored_name VARCHAR(100) NOT NULL,
  mime VARCHAR(40) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_owner(owner_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS mobile_event_chat_targets (
  event_id BIGINT UNSIGNED NOT NULL PRIMARY KEY,
  thread_user_id VARCHAR(80) NOT NULL,
  INDEX idx_thread(thread_user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

SHOW COLUMNS FROM mobile_chat_photos;
SHOW COLUMNS FROM mobile_event_chat_targets;
