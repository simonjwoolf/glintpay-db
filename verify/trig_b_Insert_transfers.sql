-- Verify glintpay-db:trig_b_Insert_transfers on mysql

BEGIN;

SELECT sqitch.checkit(COUNT(*), 'Trigger "trig_b_Insert_transfers" does not exist')
  FROM INFORMATION_SCHEMA.TRIGGERS
 WHERE TRIGGER_SCHEMA = database()
   AND TRIGGER_NAME = 'trig_b_Insert_transfers';

ROLLBACK;
