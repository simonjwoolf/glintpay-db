-- Revert glintpay-db:trig_a_Insert_transfers from mysql

BEGIN;

DROP TRIGGER /*!50032 IF EXISTS */ trig_a_Insert_transfers;

COMMIT;
