USE 222olist;
CREATE TABLE olist_customers_dataset (
    customer_id VARCHAR(50) PRIMARY KEY,
    customer_unique_id VARCHAR(50),
    customer_zip_code_prefix VARCHAR(10),
    customer_city VARCHAR(50),
    customer_state CHAR(2)
);
CREATE TABLE olist_orders_dataset (
    order_id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(50),
    order_status VARCHAR(20),
    order_purchase_timestamp VARCHAR(50),
    order_approved_at VARCHAR(50),
    order_delivered_carrier_date VARCHAR(50),
    order_delivered_customer_date VARCHAR(50),
    order_estimated_delivery_date VARCHAR(50)
);
CREATE TABLE olist_order_items_dataset (
    order_id VARCHAR(50),
    order_item_id INT,
    product_id VARCHAR(50),
    seller_id VARCHAR(50),
    shipping_limit_date VARCHAR(50),
    price DECIMAL(10,2),
    freight_value DECIMAL(10,2),
    PRIMARY KEY (order_id, order_item_id)
);
CREATE TABLE olist_order_payments_dataset (
    order_id VARCHAR(50),
    payment_sequential INT,
    payment_type VARCHAR(20),
    payment_installments INT,
    payment_value DECIMAL(10,2)
);
CREATE TABLE olist_order_reviews_dataset (
    review_id VARCHAR(50),
    order_id VARCHAR(50),
    review_score INT,
    review_comment_title VARCHAR(200),
    review_comment_message TEXT,
    review_creation_date VARCHAR(50),
    review_answer_timestamp VARCHAR(50),
    PRIMARY KEY (order_id, review_id)
);
CREATE TABLE olist_products_dataset (
    product_id VARCHAR(50) PRIMARY KEY,
    product_category_name VARCHAR(50),
    product_name_length INT,
    product_description_length INT,
    product_photos_qty INT,
    product_weight_g INT,
    product_length_cm INT,
    product_height_cm INT,
    product_width_cm INT
);
CREATE TABLE olist_sellers_dataset (
    seller_id VARCHAR(50) PRIMARY KEY,
    seller_zip_code_prefix VARCHAR(10),
    seller_city VARCHAR(50),
    seller_state CHAR(2)
);
CREATE TABLE olist_geolocation_dataset (
    geolocation_zip_code_prefix VARCHAR(10),
    geolocation_lat DECIMAL(10,8),
    geolocation_lng DECIMAL(11,8),
    geolocation_city VARCHAR(50),
    geolocation_state CHAR(2)
);
CREATE TABLE product_category_name_translation (
    product_category_name VARCHAR(50) PRIMARY KEY,
    product_category_name_english VARCHAR(50)
);
select count(*) from 222olist.olist_orders_dataset;
desc olist_order_reviews_dataset;

DELETE FROM olist_order_reviews_dataset
WHERE review_score = 'review_score';

ALTER TABLE olist_order_reviews_dataset
MODIFY COLUMN review_creation_date DATETIME;

SELECT order_status, COUNT(order_id) AS order_cnt
FROM olist_orders_dataset
GROUP BY order_status;  #口径定为delievered

SELECT MIN(review_score), MAX(review_score)
FROM olist_order_reviews_dataset; #数据集时间范围16-9-4~18-10-17

SELECT * FROM olist_order_reviews_dataset WHERE order_id = 'order_id';

SELECT COUNT(*) FROM olist_orders_dataset WHERE order_delivered_customer_date IS NULL;


CREATE VIEW view_valid_order AS
SELECT
    c.customer_unique_id,
    o.order_id,
    o.order_purchase_timestamp,
    o.order_delivered_customer_date,
    op.payment_value
FROM olist_orders_dataset o
INNER JOIN olist_customers_dataset c
    ON o.customer_id = c.customer_id
INNER JOIN olist_order_payments_dataset op
    ON o.order_id = op.order_id
WHERE o.order_status = 'delivered'
and o.order_purchase_timestamp<'2018-06-01';

SELECT * FROM view_valid_order LIMIT 10;
desc view_valid_order;

CREATE TABLE user_rfm_obs AS
SELECT
    customer_unique_id,
    MAX(order_purchase_timestamp) AS last_order_dt,
    DATEDIFF('2018-06-01', MAX(order_purchase_timestamp)) AS R,
    COUNT(DISTINCT order_id) AS F,
    SUM(payment_value) AS M,
    AVG(payment_value) AS avg_order_value -- 新增特征：平均客单价
FROM view_valid_order
GROUP BY customer_unique_id;

CREATE TABLE user_extra_features AS
SELECT
    c.customer_unique_id,
    AVG(DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp)) AS avg_delivery_days,
    SUM(CASE WHEN r.review_score <= 2 THEN 1 ELSE 0 END) AS bad_review_cnt,
    COUNT(r.review_score) AS total_review_cnt
FROM olist_orders_dataset o
INNER JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
LEFT JOIN olist_order_reviews_dataset r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
AND o.order_purchase_timestamp < '2018-06-01'
GROUP BY customer_unique_id;

CREATE VIEW user_obs_customer AS
SELECT DISTINCT customer_unique_id
FROM view_valid_order;

CREATE VIEW user_future_buy AS
SELECT DISTINCT c.customer_unique_id
FROM olist_orders_dataset o
INNER JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
AND o.order_purchase_timestamp >= '2018-06-01'
AND o.order_purchase_timestamp < '2018-09-01';

CREATE TABLE user_churn_label AS
SELECT
    obs.customer_unique_id,
    CASE WHEN fut.customer_unique_id IS NULL THEN 1 ELSE 0 END AS is_churn
FROM user_obs_customer obs
LEFT JOIN user_future_buy fut
ON obs.customer_unique_id = fut.customer_unique_id;

CREATE TABLE user_final_wide_table AS
SELECT
    rfm.customer_unique_id,
    rfm.R,
    rfm.F,
    rfm.M,
    rfm.avg_order_value,
    extra.avg_delivery_days,
    extra.bad_review_cnt,
    extra.total_review_cnt,
    lbl.is_churn
FROM user_rfm_obs rfm
LEFT JOIN user_extra_features extra
    ON rfm.customer_unique_id = extra.customer_unique_id
INNER JOIN user_churn_label lbl
    ON rfm.customer_unique_id = lbl.customer_unique_id;

SELECT * FROM user_final_wide_table LIMIT 10;
SELECT is_churn, COUNT(*) AS user_count FROM user_final_wide_table GROUP BY is_churn;

select count(*) from user_final_wide_table;
