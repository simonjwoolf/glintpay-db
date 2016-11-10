-- Deploy glintpay-db:trig_b_Insert_transfers to mysql

BEGIN;

DELIMITER $$

DROP TRIGGER /*!50032 IF EXISTS */ `trig_b_Insert_transfers`$$

CREATE
    TRIGGER `trig_b_Insert_transfers` BEFORE INSERT ON `transfers`

    FOR EACH ROW

    BEGIN
		DECLARE msg VARCHAR(128);

		IF 	(SELECT MAX(`locked`)  FROM accounts WHERE id = NEW.from_account_id OR id = NEW.to_account_id)  = 1

		THEN
			# throw an error
			SET msg = 'Sorry, this account is locked as a payment is already being processed. Please try again shortly';
			signal SQLSTATE '45000' SET message_text = msg;

		ELSE

			UPDATE accounts SET locked = 1 WHERE id = NEW.from_account_id OR id = NEW.to_account_id;

		END IF;

    END;

$$

DELIMITER ;
COMMIT;
