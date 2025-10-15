---------------------------------------------------------
----- Membuat loading.customer_report view.

-- Tentang loading.customer_report view 
----- 1. Dibuat untuk menganalisis perilaku pelanggan.
----- 2. Bisa digunakan oleh tim marketing, manajemen, dan analis data.

-- Fungsi loading.customer_report view 
----- 1. Segmentasi pelanggan berdasarkan total sales (NEW/VIP) dan 
---		 recency_category (Recent, Moderate, Inactive) untuk membantu
---		 dalam kampanye loyalitas dan retargeting.
----- 2. Analisis umur dan demografi berdasarkan pengelompokkan umur 
---		 (age_group), gender, dan negara (country) untuk mempermudah 
---		 targeting berdasarkan demografi.
----- 3. Mengetahui retensi dan engagement melalui kolom recency, 
---		 last_order_date, dan time_span yang menunjukkan seberapa sering 
---		 dan lama pelanggan aktif. 
----- 4. Memberi gambaran tentang nilai finansial tiap pelanggan  
---		 melalui kolom seperti total_sales, avg_order_value, dan  
---		 avg_monthly_value. 
----- 5. Menggambarkan kebiasaan belanja pelanggan melalui 
---		 kolom seperti total_products, avg_quantity_per_order, 
---		 dan purchase_frequency.
----- 6. Mendukung pengambilan keputusan bisnis, bisa digunakan untuk 
---		 CRM (Customer Relationship Management), scoring model, 
---		 churn prediction, dan strategi diskon.

----------------------------------------------------------

IF OBJECT_ID('loading.customer_report', 'V') IS NOT NULL
	DROP VIEW loading.customer_report;
GO

CREATE VIEW loading.customer_report AS
SELECT 
	-- PEMBEDA (PK)
	ROW_NUMBER() OVER(ORDER BY tcus.customer_number) AS customer_number,
	
	-- NAMA 
	tcus.first_name AS first_name,
	tcus.last_name AS last_name,
	tcus.gender AS gender,
	tcus.country AS country,
	
	-- PENGELOMPOKKAN UMUR
	CASE
		WHEN DATEDIFF(YEAR, tcus.birth_date, GETDATE()) <= 19 THEN '19 & Under'
        WHEN DATEDIFF(YEAR, tcus.birth_date, GETDATE()) BETWEEN 20 AND 29 THEN '20-29'
        WHEN DATEDIFF(YEAR, tcus.birth_date, GETDATE()) BETWEEN 30 AND 39 THEN '30-39'
        WHEN DATEDIFF(YEAR, tcus.birth_date, GETDATE()) BETWEEN 40 AND 49 THEN '40-49'
        WHEN DATEDIFF(YEAR, tcus.birth_date, GETDATE()) BETWEEN 50 AND 59 THEN '50-59'
        ELSE '60 & Above'
	END AS age_group,
	
	-- SEGMENTASI BERDASARKAN TOTAL SALES
	CASE 
		WHEN SUM(tsls.sales) <5000 THEN 'NEW'
		ELSE 'VIP'
	END AS cust_segmentation,
	
	-- LAST ORDER DATE AND RECENCY
	MAX(tsls.order_date) AS last_order_date,
	DATEDIFF(DAY, MAX(tsls.order_date), GETDATE()) AS recency,

	-- KATEGORI RECENCY
    CASE
        WHEN DATEDIFF(DAY, MAX(tsls.order_date), GETDATE()) <= 30 THEN 'Recent'
        WHEN DATEDIFF(DAY, MAX(tsls.order_date), GETDATE()) <= 90 THEN 'Moderate'
        ELSE 'Inactive'
    END AS recency_category,
	
	-- TOTAL ORDER & PRODUK
	COUNT(DISTINCT tsls.order_number) AS total_orders,
    COUNT(DISTINCT tsls.product_key) AS total_products,

	-- TOTAL SALES AND QUANTITY PER CUSTOMER
    SUM(tsls.sales) AS total_sales,
    SUM(tsls.quantity) AS total_quantity,

	-- LAMA MENJADI CUSTOMER (DALAM BULAN -> SEJAK ORDER KE-1 S/D TERAKHIR)
    DATEDIFF(MONTH, MIN(tsls.order_date), MAX(tsls.order_date)) AS time_span,

	-- NILAI RATA-RATA PER ORDER
    CASE 
        WHEN COUNT(DISTINCT tsls.order_number) = 0 THEN 0
        ELSE SUM(tsls.sales) / COUNT(DISTINCT tsls.order_number)
    END AS avg_order_value,

	-- RATA-RATA PENJUALAN PER BULAN
    CASE 
        WHEN DATEDIFF(MONTH, MIN(tsls.order_date), MAX(tsls.order_date)) = 0 THEN SUM(tsls.sales)
        ELSE SUM(tsls.sales) / DATEDIFF(MONTH, MIN(tsls.order_date), MAX(tsls.order_date))
    END AS avg_monthly_value,

	-- RATA-RATA QUANTITY PER ORDER
    CASE 
        WHEN COUNT(DISTINCT tsls.order_number) = 0 THEN 0
        ELSE SUM(tsls.quantity) * 1.0 / COUNT(DISTINCT tsls.order_number)
    END AS avg_quantity_per_order,

    -- FREKUENSI PEMBELIAN (order per bulan)
    CASE 
        WHEN DATEDIFF(MONTH, MIN(tsls.order_date), MAX(tsls.order_date)) = 0 THEN COUNT(DISTINCT tsls.order_number)
        ELSE COUNT(DISTINCT tsls.order_number) * 1.0 / DATEDIFF(MONTH, MIN(tsls.order_date), MAX(tsls.order_date))
    END AS purchase_frequency,

    -- JUMLAH HARI AKTIF BELANJA
    COUNT(DISTINCT tsls.order_date) AS active_days

	FROM transform.crm_customers tcus
	LEFT JOIN transform.crm_sales tsls ON tcus.customer_key = tsls.customer_key
	LEFT JOIN transform.erp_products tpdt ON tsls.product_key = tpdt.product_key
	GROUP BY 
		tcus.customer_number,
		tcus.first_name,
		tcus.last_name,
		tcus.country,
		tcus.gender,
		tcus.marital_status,
		tcus.birth_date;
GO

-- CEK
SELECT * FROM loading.customer_report;