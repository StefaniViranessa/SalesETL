-- -------------------------------------------------------------------
-- TAHAP TRANSFORMASI crm_sales

IF OBJECT_ID('transform.crm_sales', 'U' ) IS NOT NULL
	DROP TABLE transform.crm_sales;
GO

-- nama tabel disamakan saja dengan nama filenya
CREATE TABLE transform.crm_sales(
	order_number VARCHAR(50),
	customer_key INT,
	product_key INT,
	order_date DATE,
	shipping_date DATE,
	due_date DATE,
	sales INT,
	quantity INT,
	price INT,
	-- kalo tahap transform, perlu catat kapan data masuk untuk ditransform
	dwh_create_date DATETIME DEFAULT GETDATE() 
	-- untuk mengetahui kapan per row data masuk ke tabel transformasi
);
GO

SELECT * FROM ekstraksi.crm_sales

-- Cek duplikat data
SELECT	order_number, customer_key, product_key, order_date, 
		shipping_date, due_date, sales, quantity, price, 
       COUNT(*) AS jumlah
FROM ekstraksi.crm_sales
GROUP BY order_number, customer_key, product_key, order_date, 
		 shipping_date, due_date, sales, quantity, price
HAVING COUNT(*) > 1;

-- Hapus data yang double
WITH DuplicateRows AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY order_number, customer_key, product_key, 
							order_date, shipping_date, due_date, sales, 
							quantity, price
               ORDER BY order_number
           ) AS rn
    FROM ekstraksi.crm_sales
)
DELETE FROM DuplicateRows
WHERE rn > 1;

-- Cek Null
SELECT
    SUM(CASE WHEN order_number IS NULL THEN 1 ELSE 0 END) AS null_order_number,
    SUM(CASE WHEN customer_key IS NULL THEN 1 ELSE 0 END) AS null_customer_key,
    SUM(CASE WHEN product_key IS NULL THEN 1 ELSE 0 END) AS null_product_key,
    SUM(CASE WHEN order_date IS NULL THEN 1 ELSE 0 END) AS null_order_date,
    SUM(CASE WHEN shipping_date IS NULL THEN 1 ELSE 0 END) AS null_shipping_date,
    SUM(CASE WHEN due_date IS NULL THEN 1 ELSE 0 END) AS null_due_date,
    SUM(CASE WHEN sales IS NULL THEN 1 ELSE 0 END) AS null_sales,
    SUM(CASE WHEN quantity IS NULL THEN 1 ELSE 0 END) AS null_quantity,
    SUM(CASE WHEN price IS NULL THEN 1 ELSE 0 END) AS null_price
FROM ekstraksi.crm_sales;

-- Procedurenya pakai skema transform 
CREATE OR ALTER PROCEDURE transform.transform_data AS
	BEGIN
		DECLARE @start_time DATETIME, @end_time DATETIME,
				-- start_time, end_time untuk menyimpan waktu transform tiap tabel
				@batch_start_time DATETIME, @batch_end_time DATETIME;
				-- batch itu untuk nyimpen waktu ngeload tiap tabel
		BEGIN TRY
			SET @batch_start_time = GETDATE();
			PRINT '=====================================';
			PRINT 'Memulai Proses Transform';
			PRINT '=====================================';

			PRINT '-------------------------------------';
			PRINT 'Transform Tabel CRM';
			PRINT '-------------------------------------';

			SET @start_time = GETDATE();
			PRINT 'Truncate Table: transform.crm_sales'; 
			-- datanya dihilangkan dlu semua data di tabel itu, supaya tidak double
			TRUNCATE TABLE transform.crm_sales;
			PRINT 'Insert Data: transform.crm_sales';
			-- load ulang data yang updated 
			INSERT INTO transform.crm_sales (
				order_number, 
				customer_key, 
				product_key, 
				order_date, 
				shipping_date, 
				due_date, 
				sales, 
				quantity, 
				price
			)
			SELECT 
				-- Hilangkan Null
				COALESCE(order_number, 'N/A') AS order_number,
				COALESCE(customer_key, -1) AS customer_key,
				COALESCE(product_key, -1) AS product_key,
				COALESCE(order_date, '1900-01-01') AS order_date,
				COALESCE(shipping_date, '1900-01-01') AS shipping_date,
				COALESCE(due_date, '1900-01-01') AS due_date,
				COALESCE(sales, 0) AS sales,
				COALESCE(quantity, 0) AS quantity,
				COALESCE(price, 0) AS price
			FROM (
				SELECT *, 
					   ROW_NUMBER() OVER (
						   PARTITION BY order_number, customer_key, product_key, order_date, 
						   shipping_date, due_date, sales, quantity, price
						   ORDER BY order_number
					   ) AS rn
				FROM ekstraksi.crm_sales
			) AS sub
			WHERE rn = 1;

		
		SET @end_time = GETDATE();
		-- print ini untuk durasi upload satu tabel aja
		PRINT 'Durasi Upload: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + ' detik';
		PRINT '-------------------------------------';
	END TRY

	-- Agar keliatan error nya di bagian mana
	BEGIN CATCH 
		PRINT '======================================';
		PRINT 'Pesan Error = ' + error_message();
		PRINT 'Pesan Error = ' + CAST(ERROR_NUMBER() AS VARCHAR);
		PRINT 'Pesan Error = ' + CAST(ERROR_STATE() AS VARCHAR);
		PRINT '======================================';
	END CATCH
END

EXEC transform.transform_data;

SELECT * FROM transform.crm_sales;
