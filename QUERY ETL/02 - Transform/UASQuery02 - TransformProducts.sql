IF OBJECT_ID('transform.erp_products', 'U') IS NOT NULL
    DROP TABLE transform.erp_products;
GO

CREATE TABLE transform.erp_products (
    product_key VARCHAR(50),
    product_id VARCHAR(50),
    product_number VARCHAR(50),
    product_name VARCHAR(50),
    category_id VARCHAR(50),
    category VARCHAR(50),
    sub_category VARCHAR(50),
    maintenance VARCHAR(50),
    product_ine VARCHAR(50),
    cost INT,
    start_date DATE,
    dwh_create_date DATETIME DEFAULT GETDATE()
);
GO

-- Cek duplikat data
SELECT product_key, COUNT(*) AS jumlah
	FROM ekstraksi.erp_products
	GROUP BY product_key
	HAVING COUNT(*) > 1;

-- Cek data yang duplikat
SELECT * FROM ekstraksi.erp_products WHERE product_key = 6 OR product_key = 133 OR product_key = 272;

-- Cek NULL
SELECT * FROM ekstraksi.erp_products
WHERE 
    product_key IS NULL OR
    product_id IS NULL OR
    product_number IS NULL OR
    product_name IS NULL OR
    category_id IS NULL OR
    category IS NULL OR
    sub_category IS NULL OR
    maintenance IS NULL OR
    product_ine IS NULL OR
    cost IS NULL OR
    start_date IS NULL;

-- hapus duplikat data 
WITH DuplicateRank AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY product_id, product_number
            ORDER BY start_date DESC
        ) AS rn
    FROM ekstraksi.erp_products
)
DELETE FROM DuplicateRank
WHERE rn > 1;

CREATE OR ALTER PROCEDURE transform.transform_data AS
BEGIN
    DECLARE @start_time DATETIME, @end_time DATETIME,
            @batch_start_time DATETIME, @batch_end_time DATETIME;

    BEGIN TRY
        SET @batch_start_time = GETDATE();
        PRINT '=====================================';
        PRINT 'Memulai Proses Transform';
        PRINT '=====================================';

        PRINT 'Transform Tabel ERP Products';
        SET @start_time = GETDATE();

        -- Kosongkan tabel target
        TRUNCATE TABLE transform.erp_products;

        -- Transformasi dan insert data
        WITH CleanDataProduct AS (
            SELECT
                COALESCE(product_key, 0) AS product_key,
                COALESCE(product_id, 'N/A') AS product_id,
                COALESCE(product_number, 'N/A') AS product_number,
                COALESCE(product_name, 'N/A') AS product_name,
                COALESCE(category_id, 'N/A') AS category_id,
                COALESCE(category, 'N/A') AS category,
                COALESCE(sub_category, 'N/A') AS sub_category,
                -- Ubah Y jadi Yes, selain itu jadi N/A jika NULL
				CASE
					WHEN UPPER(TRIM(maintenance)) = 'Y' THEN 'Yes'
					WHEN maintenance IS NULL THEN 'N/A'
					ELSE maintenance
				END AS maintenance,
				CASE
					WHEN UPPER(TRIM(product_ine)) = 'M' THEN 'Mountain'
					WHEN UPPER(TRIM(product_ine)) = 'R' THEN 'Road'
					WHEN UPPER(TRIM(product_ine)) = 'T' THEN 'Touring'
					WHEN product_ine IS NULL THEN 'N/A'
					ELSE product_ine
				END AS product_ine,
				COALESCE(cost, 0) AS cost,
				COALESCE(start_date, '1900-01-01') AS start_date,
                ROW_NUMBER() OVER (
                    PARTITION BY product_key, product_id, product_number, product_name, category_id,
                                 category, sub_category, maintenance, product_ine, cost, start_date
                    ORDER BY start_date
                ) AS rn
            FROM ekstraksi.erp_products
        )

        INSERT INTO transform.erp_products (
            product_key, product_id, product_number, product_name, category_id,
            category, sub_category, maintenance, product_ine, cost, start_date
        )
        SELECT product_key, product_id, product_number, product_name, category_id,
               category, sub_category, maintenance, product_ine, cost, start_date
        FROM CleanDataProduct
        WHERE rn = 1;

        SET @end_time = GETDATE();
        PRINT 'Durasi Upload: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + ' detik';

    END TRY
    BEGIN CATCH
        PRINT '======================================';
        PRINT 'Pesan Error = ' + ERROR_MESSAGE();
        PRINT 'Error Number = ' + CAST(ERROR_NUMBER() AS VARCHAR);
        PRINT 'Error State = ' + CAST(ERROR_STATE() AS VARCHAR);
        PRINT '======================================';
    END CATCH
END;
GO

EXEC transform.transform_data;

-- Periksa Data
SELECT * FROM transform.erp_products;
