-- Cikoko Smart 2.5.72 (2572) — perbaikan visibilitas riwayat cuti PJLP.
-- Backup database MySQL produksi dahulu. Perintah berikut tidak menghapus data.
-- Event 'leave' yang dahulu diberi audience='private' tidak dapat dibaca
-- endpoint events, karena inbox hanya memilih audience='personal'.
-- Pembaruan terbatas pada event leave yang memiliki recipient eksplisit.
SELECT COUNT(*) AS old_hidden_leave_events
FROM mobile_events
WHERE category='leave' AND audience='private'
  AND recipient IS NOT NULL AND recipient<>'';

UPDATE mobile_events
SET audience='personal'
WHERE category='leave' AND audience='private'
  AND recipient IS NOT NULL AND recipient<>'';

SELECT COUNT(*) AS remaining_hidden_leave_events
FROM mobile_events
WHERE category='leave' AND audience='private'
  AND recipient IS NOT NULL AND recipient<>'';
