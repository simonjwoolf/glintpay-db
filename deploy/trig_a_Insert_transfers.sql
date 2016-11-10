-- Deploy glintpay-db:trig_a_Insert_transfers to mysql

BEGIN;

DELIMITER $$

DROP TRIGGER /*!50032 IF EXISTS */ trig_a_Insert_transfers$$

CREATE
    TRIGGER trig_a_Insert_transfers AFTER INSERT ON transfers
    FOR EACH ROW
    BEGIN
		UPDATE accounts SET locked = 0 WHERE id = NEW.from_account_id OR id = NEW.to_account_id;
    END;
$$

DELIMITER ;

COMMIT;
