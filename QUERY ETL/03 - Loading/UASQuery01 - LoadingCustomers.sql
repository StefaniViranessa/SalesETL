IF OBJECT_ID('loading.DIM_CUSTOMERS', 'U') IS NOT NULL
    DROP TABLE loading.DIM_CUSTOMERS;
GO

--Query Loading Customers
CREATE TABLE loading.DIM_CUSTOMERS (
	customer_key INT,
	customer_id INT,
	customer_number VARCHAR(50),
	first_name VARCHAR(50),
	last_name VARCHAR(50),
	country VARCHAR(50),
	gender VARCHAR(50),
	marital_status VARCHAR(50),
	birth_date DATE,
	create_date DATE
)

SELECT * FROM loading.DIM_CUSTOMERS