-- -------------------------------------------------------------------
-- TAHAP EKSTRAKSI customers.csv

IF OBJECT_ID('ekstraksi.crm_customers', 'U' ) IS NOT NULL
	DROP TABLE ekstraksi.crm_customers;
GO

-- Membuat tabel dengan kolom dan tipe data berikut
CREATE TABLE ekstraksi.crm_customers(
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
);
GO

-- Procedure pakai skema ekstraksi
CREATE OR ALTER PROCEDURE ekstraksi.load_data_ekstraksi AS
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME,
			-- start_time, end_time untuk menyimpan waktu ekstraksi setiap tabel
			@batch_start_time DATETIME, @batch_end_time DATETIME;
			-- batch untuk menyimpan waktu load tiap tabel

	BEGIN TRY
		SET @batch_start_time = GETDATE();
		PRINT '=====================================';
		PRINT 'Memulai Proses Ekstraksi';
		PRINT '=====================================';

		PRINT '-------------------------------------';
		PRINT 'Ekstraksi Tabel CRM';
		PRINT '-------------------------------------';

		SET @start_time = GETDATE();
		PRINT 'Truncate Table: ekstraksi.crm_customers'; 
		-- Datanya dihilangkan dlu semua data di tabel itu, supaya tidak double
		TRUNCATE TABLE ekstraksi.crm_customers;
		PRINT 'Insert Data: ekstraksi.crm_customers';
		-- Load ulang data yang updated 
		BULK INSERT ekstraksi.crm_customers
		FROM 'D:\University\4th Semester\ETL Data Warehouse\Dataset\ETL_updated\customers.csv' 
		-- Sesuaikan dengan path di laptop masing-masing
		WITH (
			FIRSTROW = 2, -- Data pertama ada di baris ke-2, supaya baris ke-1 (nama kolom) tidak dimasukkan
			FIELDTERMINATOR = ',', -- Pemisah data pakai koma
			ROWTERMINATOR = '\n',  -- or '0x0a' for line feed
			TABLOCK, -- Untuk memastikan tabel ini tidak dipakai selama proses ekstraksi
			FORMAT = 'CSV',  -- This helps with quoted fields
			DATAFILETYPE = 'char'
		);
		SET @end_time = GETDATE();
		-- Print ini untuk durasi upload satu tabel aja
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

EXEC ekstraksi.load_data_ekstraksi;

SELECT * FROM ekstraksi.crm_customers;