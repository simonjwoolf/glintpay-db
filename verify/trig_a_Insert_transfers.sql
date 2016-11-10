-- Verify glintpay-db:trig_a_Insert_transfers on mysql

BEGIN;

SELECT sqitch.checkit(COUNT(*), 'Trigger "trig_a_Insert_transfers" does not exist')
  FROM INFORMATION_SCHEMA.TRIGGERS
 WHERE TRIGGER_SCHEMA = DATABASE()
   AND TRIGGER_NAME = 'trig_a_Insert_transfers';

ROLLBACK;
