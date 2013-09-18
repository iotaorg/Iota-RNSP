-- Verify appschema

BEGIN;

SELECT 1/COUNT(*) FROM "user";

ROLLBACK;
