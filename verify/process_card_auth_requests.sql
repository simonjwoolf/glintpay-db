-- Verify glintpay-db:process_card_auth_requests on mysql

BEGIN;

SELECT sqitch.checkit(COUNT(*), 'Proc "process_card_authorisation_requests" does not exist')
  FROM mysql.proc
 WHERE db = DATABASE()
   AND specific_name = 'process_card_authorisation_request';




ROLLBACK;
