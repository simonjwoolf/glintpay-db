-- Revert glintpay-db:process_card_auth_requests from mysql

BEGIN;

DROP PROCEDURE  /*!50032 IF EXISTS */  process_card_authorisation_request;

COMMIT;
