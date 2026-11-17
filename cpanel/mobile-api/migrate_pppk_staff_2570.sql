-- Cikoko Smart 2570 / Cikokonew main: PPPK independent data only.
-- BACK UP the production MySQL database BEFORE import.
-- Additive migration: NO DROP / DELETE / TRUNCATE / existing row UPDATE.
-- Does not modify PJLP tables, account roles, or existing chat messages.
-- MySQL 8 / MariaDB 10.6+ with InnoDB required.

CREATE TABLE IF NOT EXISTS pppk_staff_attendance (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id VARCHAR(80) NOT NULL,
  work_date DATE NOT NULL,
  shift_name ENUM('pagi','siang','malam') NOT NULL,
  report_type ENUM('rutin','dinas_luar') NOT NULL DEFAULT 'rutin',
  checkin_at DATETIME NOT NULL,
  checkout_at DATETIME NULL,
  latitude DOUBLE NOT NULL,
  longitude DOUBLE NOT NULL,
  accuracy_m DOUBLE NOT NULL,
  checkin_photo LONGBLOB NOT NULL,
  checkout_photo LONGBLOB NULL,
  notes VARCHAR(1000) NOT NULL DEFAULT '',
  UNIQUE KEY uq_pppk_day(user_id,work_date),
  INDEX idx_pppk_attendance_month(user_id,work_date)
 ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS pppk_staff_daily (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  attendance_id BIGINT UNSIGNED NOT NULL,
  stage TINYINT UNSIGNED NOT NULL,
  description VARCHAR(1200) NOT NULL,
  photo LONGBLOB NOT NULL,
  created_at DATETIME NOT NULL,
  UNIQUE KEY uq_pppk_stage(attendance_id,stage),
  CONSTRAINT fk_pppk_daily_att FOREIGN KEY(attendance_id)
    REFERENCES pppk_staff_attendance(id)
 ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS pppk_staff_leave_settings(
  user_id VARCHAR(80) NOT NULL,
  supervisor_user_id VARCHAR(80) NOT NULL,
  leave_year SMALLINT UNSIGNED NOT NULL,
  allowance_days SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  updated_by VARCHAR(80) NOT NULL,
  updated_at DATETIME NOT NULL,
  PRIMARY KEY (user_id,leave_year)
 ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS pppk_staff_leave_requests(
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id VARCHAR(80) NOT NULL,
  leave_year SMALLINT UNSIGNED NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  requested_days SMALLINT UNSIGNED NOT NULL,
  reason VARCHAR(1000) NOT NULL,
  leave_address VARCHAR(500) NOT NULL,
  phone VARCHAR(40) NOT NULL,
  supervisor_user_id VARCHAR(80) NOT NULL,
  status ENUM('pending_admin','pending_supervisor','pending_lurah',
    'approved','rejected','revision') NOT NULL DEFAULT 'pending_admin',
  official_number VARCHAR(100) NULL UNIQUE,
  submitted_at DATETIME NOT NULL,
  reviewed_at DATETIME NULL,
  INDEX idx_pppk_leave_user(user_id,leave_year),
  INDEX idx_pppk_leave_dates(start_date,end_date,status)
 ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS pppk_staff_leave_approvals(
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  request_id BIGINT UNSIGNED NOT NULL,
  stage ENUM('admin','supervisor','lurah') NOT NULL,
  actor_id VARCHAR(80) NOT NULL,
  decision ENUM('approve','reject') NOT NULL,
  note VARCHAR(1000) NOT NULL DEFAULT '',
  created_at DATETIME NOT NULL,
  UNIQUE KEY uq_pppk_approval(request_id,stage),
  CONSTRAINT fk_pppk_leave_approval FOREIGN KEY(request_id)
    REFERENCES pppk_staff_leave_requests(id)
 ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Read-only post-import checks. Verify each table exists:
SHOW COLUMNS FROM pppk_staff_attendance;
SHOW COLUMNS FROM pppk_staff_daily;
SHOW COLUMNS FROM pppk_staff_leave_settings;
SHOW COLUMNS FROM pppk_staff_leave_requests;
SHOW COLUMNS FROM pppk_staff_leave_approvals;
