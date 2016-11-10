-- Revert glintpay-db:trig_b_Insert_transfers from mysql

BEGIN;

DROP TRIGGER trig_b_Insert_transfers;

COMMIT;
