-- Cikoko Smart Google Login 2608 - additive, safe for existing accounts.
-- This stores ONLY the Google stable subject mapped to a Cikoko user id.
-- No old passwords, portal_users, or employee roles are changed.
CREATE TABLE IF NOT EXISTS mobile_google_accounts_2608 (
  google_sub VARCHAR(64) NOT NULL PRIMARY KEY,
  user_id VARCHAR(80) NOT NULL UNIQUE,
  google_email VARCHAR(160) NOT NULL,
  linked_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_email (google_email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
