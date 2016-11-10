-- Deploy glintpay-db:process_card_auth_requests to mysql

BEGIN;

DELIMITER $$

DROP PROCEDURE  /*!50032 IF EXISTS */  process_card_authorisation_request$$

CREATE PROCEDURE process_card_authorisation_request
		(
		  p_username 			VARCHAR(100)
		, p_ggm_amount  		DECIMAL(15,6)
		, p_description 		VARCHAR(255)
		, p_days_in_future 		TINYINT
		, p_original_currency 		CHAR(3)
		, p_original_amount 		DECIMAL(15,6)
		, p_TX_reference_hash 		VARCHAR(25)
		, p_usd_markup 			DECIMAL(15,6)
		, p_usd_ggm 			DECIMAL(15,6)
		, p_usd_amount  		DECIMAL(15,6)
		, OUT p_transfer_id		INT
		)



	BEGIN
		# error handler for cannot insert child row, so that failure to add custom fields if main insert fails will not halt procedure
		DECLARE CONTINUE HANDLER FOR 1452
		#SELECT 'Payment not inserted' AS error;  # don't return an error message as it snaffles up Python when we get two result sets returned

		SET @account_id 	= (SELECT id FROM accounts WHERE owner_name = p_username AND type_id = 6);	#customer gold A/C		
		SET @to_account_id 	= (SELECT id FROM accounts WHERE type_id = 11);					#glint corporate gold A/C
		SET @transfer_type_id 	= 6;										#spending gold (customer > glint)
		SET @tx_time			= NOW();

		START TRANSACTION;	# the following statements need to be ACID-safe
		#######################################################################

			INSERT INTO scheduled_payments
				(from_account_id, to_account_id, type_id, `date`, amount, `status`, description, reserve_amount)

			SELECT
				  @account_id
				, @to_account_id
				, @transfer_type_id
				, @tx_time
				, p_ggm_amount
				, 'S'
				, p_description
				, TRUE

			FROM
				(SELECT
					SUM(CASE WHEN to_account_id = @account_id THEN amount ELSE 0 END) -
					SUM(CASE WHEN from_account_id = @account_id THEN amount ELSE 0 END)  AS balance
				 FROM
					transfers
				WHERE
					(from_account_id = @account_id OR to_account_id = @account_id) AND
					`status` IN ('O','S')) b
			WHERE
				b.balance > p_ggm_amount * 1.1;


				### Grab the ID of the scheduled payment we just inserted ###

				SET @scheduled_payment_id = IF(ROW_COUNT() = 1, LAST_INSERT_ID(),-1);

				### add custom fields to the scheduled payment ###

				INSERT INTO custom_field_values
					(subclass, field_id, string_value, scheduled_payment_id)

				VALUES
					('pmt', 1, p_original_currency, @scheduled_payment_id),
					('pmt', 2, p_original_amount, @scheduled_payment_id),
					('pmt', 3, p_TX_reference_hash, @scheduled_payment_id),
					('pmt', 5, p_usd_markup, @scheduled_payment_id),
					('pmt', 7, p_usd_ggm, @scheduled_payment_id),
					('pmt', 8, p_usd_amount, @scheduled_payment_id);


				### Now add the future dated transfer record ###

				INSERT INTO transfers
					(from_account_id, to_account_id, type_id, `date`, amount, `status`, description, scheduled_payment_id)

				SELECT

					  @account_id
					, @to_account_id
					, @transfer_type_id
					, DATE_ADD(@tx_time, INTERVAL p_days_in_future DAY)
					, p_ggm_amount
					, 'S'
					, p_description
					, @scheduled_payment_id
				FROM
					(SELECT 1) s
				WHERE
					@scheduled_payment_id > 0;

				SET @transfer_id = IF(ROW_COUNT() = 1, LAST_INSERT_ID(),-1);

				### add custom fields to the transfer ###

				INSERT INTO custom_field_values
					(subclass, field_id, string_value, transfer_id)

				VALUES
					('pmt', 1, p_original_currency, @transfer_id),
					('pmt', 2, p_original_amount, @transfer_id),
					('pmt', 3, p_TX_reference_hash, @transfer_id),
					('pmt', 5, p_usd_markup, @transfer_id),
					('pmt', 7, p_usd_ggm, @transfer_id),
					('pmt', 8, p_usd_amount, @transfer_id);


		COMMIT;	#we should have both a scheduled payment record and a transfer record now
		#################################################################################

		SELECT @transfer_id INTO p_transfer_id;

	END$$

DELIMITER ;

COMMIT;
