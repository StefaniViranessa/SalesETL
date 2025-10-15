---------------------------------------------------------
----- Membuat loading.product_report view.

-- Tentang loading.product_report view 
----- 1. Dibuat untuk mengevaluasi performa setiap produk. 
----- 2. Berguna untuk manajemen produk, pengadaan, dan pricing.

-- Fungsi loading.product_report view 
----- 1. Segmentasi produk berdasarkan product_segmentation yang
---		 memisahkan produk dengan penjualan tinggi, sedang, dan rendah 
---		 untuk menentukan prioritas promosi.
----- 2. Evaluasi umur dan siklus hidup produk melalui kolom 
---		 product_age_months, time_span, dan last_sale_date untuk  
---		 membantu identifikasi produk usang atau baru.
----- 3. Menunjukkan seberapa laris dan profitabilitas produk melalui
---		 kolom total_sales, total_quantity, dan avg_selling_price.
----- 4. Menggambarkan seberapa luas produk digunakan  
---		 melalui kolom total_customers dan total_orders. 
----- 5. Menunjukkan kestabilan performa produk dari waktu ke waktu
---		 melalui kolom avg_order_revenue, avg_monthly_revenue, dan
---		 order_frequency_per_month.
----- 6. Membantu menentukan apakah produk perlu di-push, didiskon, 
---		 atau dihentikan (phase-out).

----------------------------------------------------------

IF OBJECT_ID('loading.product_report', 'V') IS NOT NULL
	DROP VIEW loading.product_report;
GO

CREATE VIEW loading.product_report AS
SELECT 
	-- PEMBEDA (KEY)
	ROW_NUMBER() OVER(ORDER BY tpdt.product_name) AS product_key,

	-- PRODUCT INFO
	tpdt.product_name AS product_name,
	tpdt.category AS category,
	tpdt.sub_category AS sub_category,
	tpdt.cost AS cost,

	-- TANGGAL PENJUALAN
	MIN(tsls.order_date) AS first_sale_date,
	MAX(tsls.order_date) AS last_sale_date,

	-- UMUR PRODUK DI PASAR
	DATEDIFF(DAY, MIN(tsls.order_date), GETDATE()) AS product_age_months,

	-- RECENCY PRODUK (HARI SEJAK TERJUAL TERAKHIR)
	DATEDIFF(DAY, MAX(tsls.order_date), GETDATE()) AS recency,

	-- SEGMENTASI PRODUK BERDASARKAN TOTAL SALES
	CASE
        WHEN SUM(tsls.sales) >= 100000 THEN 'High-Performer'
        WHEN SUM(tsls.sales) >= 50000 THEN 'Mid-Range'
        ELSE 'Low-Performer'
    END AS product_segmentation,

	-- RENTANG WAKTU PRODUK TERJUAL (dalam bulan)
    DATEDIFF(MONTH, MIN(tsls.order_date), MAX(tsls.order_date)) AS time_span,

	-- TOTAL PENJUALAN PRODUK 
	SUM(tsls.sales) AS total_sales,

	-- KUANTITAS PRODUK TERJUAL
	SUM(tsls.quantity) AS total_quantity,
	-- Jumlah unit produk yang terjual (misalnya: 5 pcs, 10 pcs, dst)

	-- JUMLAH CUST YANG MEMBELI PRODUK TERSEBUT
	COUNT(DISTINCT tsls.customer_key) AS total_customers,

	-- RATA-RATA HARGA JUAL / UNIT
    CASE 
        WHEN SUM(tsls.quantity) = 0 THEN 0
        ELSE SUM(tsls.sales) / SUM(tsls.quantity)
    END AS avg_selling_price,

    -- RATA-RATA PENDAPATAN PER BULAN
    CAST(
		CASE 
			WHEN DATEDIFF(MONTH, MIN(tsls.order_date), MAX(tsls.order_date)) = 0 THEN SUM(tsls.sales)
			ELSE SUM(tsls.sales) * 1.0 / DATEDIFF(MONTH, MIN(tsls.order_date), MAX(tsls.order_date))
		END AS INT)
	AS avg_monthly_revenue,

	-- FREKUENSI PENJUALAN PER BULAN
	CAST(
		CASE 
			WHEN DATEDIFF(MONTH, MIN(tsls.order_date), MAX(tsls.order_date)) = 0 THEN COUNT(DISTINCT tsls.order_number)
			ELSE COUNT(DISTINCT tsls.order_number) * 1.0 / DATEDIFF(MONTH, MIN(tsls.order_date), MAX(tsls.order_date))
		END AS INT)
	AS order_frequency_per_month,

	-- TOTAL ORDER PRODUK
	COUNT(DISTINCT tsls.order_number) AS total_orders,
	-- Jumlah pesanan (order) yang dilakukan (unik order_number)

	-- TERJUAL DALAM 30 HARI TERAKHIR (1 = YA, 0 = TIDAK)
	MAX(CASE WHEN DATEDIFF(DAY, tsls.order_date, GETDATE()) <= 30 THEN 'YES' ELSE 'NO' END) AS sold_last_30_days

	FROM transform.erp_products tpdt
	LEFT JOIN transform.crm_sales tsls ON tsls.product_key = tpdt.product_key
	LEFT JOIN transform.crm_customers tcst ON tsls.customer_key = tcst.customer_key
	GROUP BY 
		tpdt.product_key,
		tpdt.product_name,
		tpdt.category,
		tpdt.sub_category,
		tpdt.cost;

SELECT * FROM loading.product_report;