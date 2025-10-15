-- -------------------------------------------------------------------
-- TAHAP EKSTRAKSI sales.csv

IF OBJECT_ID('ekstraksi.crm_sales', 'U' ) IS NOT NULL
	DROP TABLE ekstraksi.crm_sales;
GO

-- Nama tabel disamakan dengan nama filenya
CREATE TABLE ekstraksi.crm_sales(
	order_number VARCHAR(50),
	customer_key INT,
	product_key INT,
	order_date DATE,
	shipping_date DATE,
	due_date DATE,
	sales INT,
	quantity INT,
	price INT
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
		PRINT 'Truncate Table: ekstraksi.crm_sales'; 
		-- Hilangkan semua data di tabel terlebih dahulu, supaya tidak double
		TRUNCATE TABLE ekstraksi.crm_sales;
		PRINT 'Insert Data: ekstraksi.crm_sales';
		-- Load ulang data yang updated 
		BULK INSERT ekstraksi.crm_sales
		FROM 'D:\University\4th Semester\ETL Data Warehouse\Dataset\ETL_updated\sales.csv' -- Sesuaikan dengan path di laptop masing-masing
		WITH (
			FIRSTROW = 2, -- Data pertama ada di baris ke-2, supaya baris ke-1 (nama kolom) tidak dimasukkan
			FIELDTERMINATOR = ',', -- Pemisah data pakai koma
			ROWTERMINATOR = '\n',  -- Baris baru dengan line feed
			TABLOCK -- Untuk memastikan tabel ini tidak dipakai selama proses ekstraksi
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

SELECT * FROM ekstraksi.crm_sales;
