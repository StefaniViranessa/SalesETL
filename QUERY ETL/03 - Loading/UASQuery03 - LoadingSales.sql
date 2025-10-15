IF OBJECT_ID('loading.FACT_SALES', 'U') IS NOT NULL
    DROP TABLE loading.FACT_SALES;
GO

--Query Loading Product
CREATE TABLE loading.FACT_SALES (
	order_number VARCHAR(50),
	customer_key INT,
	product_key INT,
	order_date DATE,
	shipping_date DATE,
	due_date DATE,
	sales INT,
	quantity INT,
	price INT,
)

SELECT * FROM loading.FACT_SALES