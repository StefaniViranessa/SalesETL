IF OBJECT_ID('loading.DIM_PRODUCTS', 'U') IS NOT NULL
    DROP TABLE loading.DIM_PRODUCTS;
GO

--Query Loading Product
CREATE TABLE loading.DIM_PRODUCTS (
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
)

SELECT * FROM loading.DIM_PRODUCTS