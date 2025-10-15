-- -------------------------------------------------------------------
-- TAHAP TRANSFORMASI crm_customers

IF OBJECT_ID('transform.crm_customers', 'U' ) IS NOT NULL
	DROP TABLE transform.crm_customers;
GO

-- Membuat tabel transform untuk customers
CREATE TABLE transform.crm_customers (
	customer_key INT,
	customer_id INT,
	customer_number VARCHAR(50),
	first_name VARCHAR(50),
	last_name VARCHAR(50),
	country VARCHAR(50),
	gender VARCHAR(50),
	marital_status VARCHAR(50),
	birth_date DATE,
	create_date DATE,
	-- kalo tahap transform, perlu catat kapan data masuk untuk ditransform
	dwh_create_date DATETIME DEFAULT GETDATE() -- untuk mengetahui kapan per row data masuk ke tabel transformasi
);
GO

-- Periksa data
SELECT TOP (100000) [customer_key]
				, [customer_id]
				, [customer_number]
				, [first_name]
				, [last_name]
				, [country]
				, [gender]
				, [marital_status]
				, [birth_date]
				, [create_date]
	FROM [DW_KelasC_Kelompok8].[ekstraksi].[crm_customers]

-- Cek duplikat data
SELECT	customer_key, customer_id, customer_number, first_name, last_name, country, 
		gender, marital_status, birth_date, create_date,
	COUNT(*) as Jumlah
	FROM ekstraksi.crm_customers
	GROUP BY	customer_key, customer_id, customer_number, first_name, last_name, country, 
				gender, marital_status, birth_date, create_date
	HAVING COUNT(*) > 1;

-- Cek data duplicate: 20, 6079, 18463
SELECT * FROM ekstraksi.crm_customers WHERE customer_key = 20 OR 
											customer_key = 6079 OR 
											customer_key = 18463;
SELECT * FROM ekstraksi.crm_customers WHERE customer_key = 6079;
SELECT * FROM ekstraksi.crm_customers WHERE customer_key = 18463;

-- Hapus data yang double
WITH DuplicateData AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY customer_key, customer_id, customer_number, first_name, 
							last_name, country, gender, marital_status, birth_date
			   ORDER BY create_date DESC -- yang paling update yang jadi flag = 1
           ) AS flag
    FROM ekstraksi.crm_customers
)
DELETE FROM DuplicateData
WHERE flag > 1;

-- Cek duplikat data
SELECT customer_key, customer_id, customer_number, first_name, last_name, 
		country, gender, marital_status, birth_date, create_date,
	COUNT(*) as Jumlah
	FROM ekstraksi.crm_customers
	GROUP BY	customer_key, customer_id, customer_number, first_name, 
				last_name, country, gender, marital_status, birth_date, 
				create_date
	HAVING COUNT(*) > 1;

-- Cek apakah first_name ada spasi di awal/akhir
SELECT * FROM ekstraksi.crm_customers
	WHERE first_name != TRIM(first_name);
	-- hasil: first_name tidak ada yang mengandung spasi

-- cek apakah last_name ada spasi di awal/akhir
SELECT * FROM ekstraksi.crm_customers
	WHERE last_name != TRIM(last_name);
	-- hasil: last_name tidak ada yang mengandung spasi

-- cek apakah masih ada yang null di setiap kolom
SELECT * 
FROM ekstraksi.crm_customers
WHERE customer_key IS NULL
   OR customer_id IS NULL
   OR customer_number IS NULL
   OR first_name IS NULL
   OR last_name IS NULL
   OR country IS NULL
   OR gender IS NULL
   OR marital_status IS NULL
   OR birth_date IS NULL
   OR create_date IS NULL;

-- Masukkin ke tabel transform
INSERT INTO transform.crm_customers(
	customer_key,
	customer_id,
	customer_number,
	first_name, 
	last_name,
	country,
	gender,
	marital_status,
	birth_date,
	create_date
)
-- Mengganti value s = single, m = married, f/fem = female, m = male, 
-- Mengganti valur us = united states, uk = united = kingdom, null = N/A
SELECT COALESCE(customer_key, 0) AS customer_key,  
	COALESCE(customer_id, 0) AS customer_id,
    COALESCE(customer_number, 'N/A') AS customer_number,
    COALESCE(first_name, 'N/A') AS first_name,
    COALESCE(last_name, 'N/A') AS last_name,
    CASE 
		WHEN UPPER(TRIM(country)) = 'US' THEN 'United States'
		WHEN UPPER(TRIM(country)) = 'UK' THEN 'United Kingdom'
		WHEN country IS NULL THEN 'N/A'
		ELSE country
	END AS country,
	CASE
		WHEN UPPER(TRIM(gender)) = 'Fem' THEN 'Female'
		WHEN UPPER(TRIM(gender)) = 'F' THEN 'Female'
		WHEN UPPER(TRIM(gender)) = 'M' THEN 'Male'
		ELSE 'N/A'
	END AS gender,
	CASE
		WHEN UPPER(TRIM(marital_status)) = 'S' THEN 'Single'
		WHEN UPPER(TRIM(marital_status)) = 'M' THEN 'Married'
		ELSE 'N/A'
	END AS marital_status,
	COALESCE(birth_date, '1900-01-01') AS birth_date,         
    COALESCE(create_date, '1900-01-01') AS create_date 
FROM(
	SELECT *, 
		ROW_NUMBER() OVER (
			PARTITION BY customer_id
			ORDER BY create_date DESC
			) AS flag 
	FROM ekstraksi.crm_customers
	WHERE customer_id IS NOT NULL
) AS TAB
WHERE TAB.flag = 1;

-- Procedurenya tetep pake skema transform 
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
		PRINT 'Truncate Table: transform.crm_customers'; 
		-- Hilangkan semua data di tabel itu terlebih dahulu, supaya tidak double
		TRUNCATE TABLE transform.crm_customers;
		PRINT 'Insert Data: transform.crm_customers';
		-- Load ulang data yang updated 
		INSERT INTO transform.crm_customers(
			customer_key,
			customer_id,
			customer_number,
			first_name, 
			last_name,
			country,
			gender,
			marital_status,
			birth_date,
			create_date
		)
		-- Mengganti value s = single, m = married, f/fem = female, m = male, 
		-- Mengganti valur us = united states, uk = united = kingdom, null = N/A
		SELECT COALESCE(customer_key, 0) AS customer_key,  
			COALESCE(customer_id, 0) AS customer_id,
			COALESCE(customer_number, 'N/A') AS customer_number,
			COALESCE(first_name, 'N/A') AS first_name,
			COALESCE(last_name, 'N/A') AS last_name,
			CASE 
				WHEN UPPER(TRIM(country)) = 'US' THEN 'United States'
				WHEN UPPER(TRIM(country)) = 'UK' THEN 'United Kingdom'
				WHEN country IS NULL THEN 'N/A'
				ELSE country
			END AS country,
			CASE
				WHEN UPPER(TRIM(gender)) = 'Fem' THEN 'Female'
				WHEN UPPER(TRIM(gender)) = 'F' THEN 'Female'
				WHEN UPPER(TRIM(gender)) = 'M' THEN 'Male'
				WHEN gender IS NULL THEN 'N/A'
				ELSE gender
			END AS gender,
			CASE
				WHEN UPPER(TRIM(marital_status)) = 'S' THEN 'Single'
				WHEN UPPER(TRIM(marital_status)) = 'M' THEN 'Married'
				WHEN marital_status IS NULL THEN 'N/A'
				ELSE marital_status
			END AS marital_status,
			COALESCE(birth_date, '1900-01-01') AS birth_date,         
			COALESCE(create_date, '1900-01-01') AS create_date  
		FROM(
			SELECT *, 
				ROW_NUMBER() OVER (
					PARTITION BY customer_id
					ORDER BY create_date DESC
					) AS flag 
			FROM ekstraksi.crm_customers
			WHERE customer_id IS NOT NULL
		) AS TAB
		WHERE TAB.flag = 1;
		
		SET @end_time = GETDATE();
		-- print ini untuk durasi upload satu tabel aja
		PRINT 'Durasi Upload: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + ' detik';
		PRINT '-------------------------------------';
	END TRY

	-- biar keliatan error nya di bagian mana
	BEGIN CATCH 
		PRINT '======================================';
		PRINT 'Pesan Error = ' + error_message();
		PRINT 'Pesan Error = ' + CAST(ERROR_NUMBER() AS VARCHAR);
		PRINT 'Pesan Error = ' + CAST(ERROR_STATE() AS VARCHAR);
		PRINT '======================================';
	END CATCH
END

EXEC transform.transform_data;

-- Periksa data
SELECT * FROM transform.crm_customers;