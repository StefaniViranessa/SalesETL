-- -------------------------------------------------------------------
-- TAHAP EKSTRAKSI products.csv

IF OBJECT_ID('ekstraksi.erp_products', 'U' ) IS NOT NULL
	DROP TABLE ekstraksi.erp_products;
GO

CREATE TABLE ekstraksi.erp_products(
	product_key INT,
	product_id VARCHAR(50),
	product_number VARCHAR(50),
	product_name VARCHAR(50),
	category_id VARCHAR(50),
	category VARCHAR(50),
	sub_category VARCHAR(50),
	maintenance VARCHAR (50),
	product_ine VARCHAR (50),
	cost INT,
	start_date DATE
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
		PRINT 'Ekstraksi Tabel ERP';
		PRINT '-------------------------------------';

		SET @start_time = GETDATE();
		PRINT 'Truncate Table: ekstraksi.erp_products'; 
		-- Hhilangkan semua data di tabel itu terlebih dahulu, supaya tidak double
		TRUNCATE TABLE ekstraksi.erp_products;
		PRINT 'Insert Data: ekstraksi.erp_products';
		-- Load ulang data yang updated 
		BULK INSERT ekstraksi.erp_products
		FROM 'D:\University\4th Semester\ETL Data Warehouse\Dataset\ETL_updated\products.csv' 
		-- Sesuaikan dengan path di laptop masing-masing
		WITH (
			FIRSTROW = 2, -- Data pertama ada di baris ke-2, supaya baris ke-1 (nama kolom) tidak dimasukkan
			FIELDTERMINATOR = ',', -- Pemisah data pakai koma
			TABLOCK -- Untuk memastikan tabel ini tidak dipakai selama proses ekstraksi 
		);
		SET @end_time = GETDATE();
		-- Print ini untuk durasi upload satu tabel aja
		PRINT 'Durasi Upload: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + ' detik';
		PRINT '-------------------------------------';
	END TRY

	-- Agar keliatan errornya di bagian mana
	BEGIN CATCH 
		PRINT '======================================';
		PRINT 'Pesan Error = ' + error_message();
		PRINT 'Pesan Error = ' + CAST(ERROR_NUMBER() AS VARCHAR);
		PRINT 'Pesan Error = ' + CAST(ERROR_STATE() AS VARCHAR);
		PRINT '======================================';
	END CATCH
END

EXEC ekstraksi.load_data_ekstraksi;

SELECT * FROM ekstraksi.erp_products