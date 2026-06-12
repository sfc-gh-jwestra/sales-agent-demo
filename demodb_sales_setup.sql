-- =============================================================================
-- DEMO_DB.SALES Schema Setup
--
-- Run this script BEFORE demo_mcp_oauth_setup.sql.
-- Creates the database, schema, tables, data, semantic view, and Cortex Agent.
--
-- CONFIGURATION: Update these variables for your environment.
-- =============================================================================

-- ┌─────────────────────────────────────────────────────────────────────────────┐
-- │ CONFIGURABLE VARIABLES - Update these for your environment                  │
-- └─────────────────────────────────────────────────────────────────────────────┘

SET TARGET_DATABASE = 'DEMO_DB';
SET TARGET_SCHEMA = 'SALES';

USE ROLE ACCOUNTADMIN;

-- =============================================================================
-- STEP 1: Create Warehouse, Database, and Schema
-- =============================================================================

CREATE WAREHOUSE IF NOT EXISTS DEMO_WH
  WAREHOUSE_SIZE = 'XSMALL'
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE;

USE WAREHOUSE DEMO_WH;

CREATE DATABASE IF NOT EXISTS IDENTIFIER($TARGET_DATABASE);
CREATE SCHEMA IF NOT EXISTS IDENTIFIER($TARGET_DATABASE || '.' || $TARGET_SCHEMA);

USE DATABASE IDENTIFIER($TARGET_DATABASE);
USE SCHEMA IDENTIFIER($TARGET_SCHEMA);

-- =============================================================================
-- STEP 2: Create Tables
-- =============================================================================

CREATE OR REPLACE TABLE CUSTOMERS (
    CUSTOMER_ID NUMBER(38,0),
    CUSTOMER_NAME VARCHAR(100),
    SEGMENT VARCHAR(50),
    REGION VARCHAR(50),
    COUNTRY VARCHAR(50),
    SIGNUP_DATE DATE,
    EMAIL VARCHAR(150)
);

CREATE OR REPLACE TABLE MARKETS (
    MARKET_ID NUMBER(38,0),
    MARKET_NAME VARCHAR(100),
    COUNTRY VARCHAR(50),
    REGION VARCHAR(50),
    CURRENCY VARCHAR(10),
    TIMEZONE VARCHAR(50)
);

CREATE OR REPLACE TABLE PRODUCTS (
    PRODUCT_ID NUMBER(38,0),
    PRODUCT_NAME VARCHAR(100),
    CATEGORY VARCHAR(50),
    SUBCATEGORY VARCHAR(50),
    UNIT_PRICE NUMBER(10,2),
    COST NUMBER(10,2)
);

CREATE OR REPLACE TABLE ORDERS (
    ORDER_ID NUMBER(38,0),
    CUSTOMER_ID NUMBER(38,0),
    MARKET_ID NUMBER(38,0),
    ORDER_DATE DATE,
    SHIP_DATE DATE,
    STATUS VARCHAR(20),
    TOTAL_AMOUNT NUMBER(12,2)
);

CREATE OR REPLACE TABLE ORDER_ITEMS (
    ORDER_ITEM_ID NUMBER(38,0),
    ORDER_ID NUMBER(38,0),
    PRODUCT_ID NUMBER(38,0),
    QUANTITY NUMBER(38,0),
    UNIT_PRICE NUMBER(10,2),
    DISCOUNT_PCT NUMBER(5,2),
    LINE_TOTAL NUMBER(12,2)
);

-- =============================================================================
-- STEP 3: Insert Data
-- =============================================================================

INSERT INTO CUSTOMERS (CUSTOMER_ID, CUSTOMER_NAME, SEGMENT, REGION, COUNTRY, SIGNUP_DATE, EMAIL) VALUES
(1, 'Acme Corporation', 'Enterprise', 'North America', 'United States', '2020-03-15', 'sales@acme.com'),
(2, 'GlobalTech Solutions', 'Enterprise', 'Europe', 'Germany', '2019-07-22', 'info@globaltech.de'),
(3, 'Pacific Traders', 'Mid-Market', 'Asia Pacific', 'Japan', '2021-01-10', 'contact@pacifictraders.jp'),
(4, 'Summit Industries', 'Enterprise', 'North America', 'Canada', '2018-11-05', 'orders@summit.ca'),
(5, 'Nordic Supply Co', 'Mid-Market', 'Europe', 'Sweden', '2020-06-18', 'sales@nordicsupply.se'),
(6, 'Southern Star Ltd', 'Small Business', 'Asia Pacific', 'Australia', '2022-02-28', 'hello@southernstar.au'),
(7, 'Atlas Manufacturing', 'Enterprise', 'North America', 'United States', '2019-04-12', 'procurement@atlas.com'),
(8, 'Rhine Logistics', 'Mid-Market', 'Europe', 'Netherlands', '2020-09-30', 'ops@rhinelogistics.nl'),
(9, 'Dragon Electronics', 'Enterprise', 'Asia Pacific', 'China', '2018-08-14', 'sales@dragonelec.cn'),
(10, 'MapleSoft Inc', 'Small Business', 'North America', 'Canada', '2021-05-20', 'info@maplesoft.ca'),
(11, 'Berlin Dynamics', 'Mid-Market', 'Europe', 'Germany', '2020-12-01', 'contact@berlindynamics.de'),
(12, 'Coastal Imports', 'Small Business', 'North America', 'United States', '2022-07-15', 'buy@coastalimports.com'),
(13, 'Tokyo Digital', 'Enterprise', 'Asia Pacific', 'Japan', '2019-02-08', 'enterprise@tokyodigital.jp'),
(14, 'Frontier Energy', 'Enterprise', 'North America', 'United States', '2018-05-22', 'contracts@frontier.com'),
(15, 'Mediterranean Foods', 'Mid-Market', 'Europe', 'Italy', '2021-03-17', 'orders@medfood.it'),
(16, 'Sahara Trading', 'Small Business', 'Middle East', 'UAE', '2022-01-09', 'trade@saharatrading.ae'),
(17, 'Andes Mining Corp', 'Enterprise', 'Latin America', 'Chile', '2019-10-25', 'ops@andesmining.cl'),
(18, 'Great Plains Agri', 'Mid-Market', 'North America', 'United States', '2020-08-11', 'sales@greatplainsagri.com'),
(19, 'Silk Road Ventures', 'Mid-Market', 'Asia Pacific', 'Singapore', '2021-06-30', 'deals@silkroadventures.sg'),
(20, 'Celtic Pharma', 'Enterprise', 'Europe', 'Ireland', '2018-12-19', 'supply@celticpharma.ie');

INSERT INTO MARKETS (MARKET_ID, MARKET_NAME, COUNTRY, REGION, CURRENCY, TIMEZONE) VALUES
(1, 'US East', 'United States', 'North America', 'USD', 'America/New_York'),
(2, 'US West', 'United States', 'North America', 'USD', 'America/Los_Angeles'),
(3, 'US Central', 'United States', 'North America', 'USD', 'America/Chicago'),
(4, 'Canada', 'Canada', 'North America', 'CAD', 'America/Toronto'),
(5, 'UK & Ireland', 'United Kingdom', 'Europe', 'GBP', 'Europe/London'),
(6, 'DACH', 'Germany', 'Europe', 'EUR', 'Europe/Berlin'),
(7, 'Nordics', 'Sweden', 'Europe', 'SEK', 'Europe/Stockholm'),
(8, 'Southern Europe', 'Italy', 'Europe', 'EUR', 'Europe/Rome'),
(9, 'Japan', 'Japan', 'Asia Pacific', 'JPY', 'Asia/Tokyo'),
(10, 'China', 'China', 'Asia Pacific', 'CNY', 'Asia/Shanghai'),
(11, 'Southeast Asia', 'Singapore', 'Asia Pacific', 'SGD', 'Asia/Singapore'),
(12, 'Australia & NZ', 'Australia', 'Asia Pacific', 'AUD', 'Australia/Sydney'),
(13, 'Middle East', 'UAE', 'Middle East', 'AED', 'Asia/Dubai'),
(14, 'Latin America', 'Chile', 'Latin America', 'CLP', 'America/Santiago'),
(15, 'Netherlands & Benelux', 'Netherlands', 'Europe', 'EUR', 'Europe/Amsterdam');

INSERT INTO PRODUCTS (PRODUCT_ID, PRODUCT_NAME, CATEGORY, SUBCATEGORY, UNIT_PRICE, COST) VALUES
(1, 'Enterprise Platform License', 'Software', 'Licenses', 25000.00, 5000.00),
(2, 'Cloud Storage (1TB)', 'Infrastructure', 'Storage', 1200.00, 400.00),
(3, 'Data Analytics Suite', 'Software', 'Analytics', 15000.00, 3000.00),
(4, 'Security Module', 'Software', 'Security', 8000.00, 2000.00),
(5, 'API Gateway Service', 'Infrastructure', 'Networking', 3500.00, 1000.00),
(6, 'Premium Support Plan', 'Services', 'Support', 5000.00, 2500.00),
(7, 'Implementation Services', 'Services', 'Consulting', 20000.00, 12000.00),
(8, 'Training Package', 'Services', 'Education', 2500.00, 800.00),
(9, 'IoT Connector', 'Hardware', 'Devices', 750.00, 300.00),
(10, 'Edge Computing Node', 'Hardware', 'Devices', 4500.00, 2000.00),
(11, 'Data Integration Tool', 'Software', 'Integration', 6000.00, 1500.00),
(12, 'Backup & Recovery', 'Infrastructure', 'Storage', 2000.00, 600.00),
(13, 'AI/ML Accelerator', 'Software', 'Analytics', 18000.00, 4500.00),
(14, 'Compliance Module', 'Software', 'Security', 10000.00, 2500.00),
(15, 'Collaboration Suite', 'Software', 'Productivity', 4000.00, 1000.00);

INSERT INTO ORDERS (ORDER_ID, CUSTOMER_ID, MARKET_ID, ORDER_DATE, SHIP_DATE, STATUS, TOTAL_AMOUNT) VALUES
(1001, 1, 1, '2024-01-15', '2024-01-18', 'Delivered', 75000.00),
(1002, 2, 6, '2024-01-22', '2024-01-26', 'Delivered', 48000.00),
(1003, 3, 9, '2024-02-03', '2024-02-07', 'Delivered', 32000.00),
(1004, 4, 4, '2024-02-10', '2024-02-14', 'Delivered', 95000.00),
(1005, 7, 2, '2024-02-18', '2024-02-22', 'Delivered', 120000.00),
(1006, 9, 10, '2024-03-01', '2024-03-05', 'Delivered', 88000.00),
(1007, 14, 1, '2024-03-12', '2024-03-15', 'Delivered', 145000.00),
(1008, 1, 1, '2024-03-20', '2024-03-24', 'Delivered', 62000.00),
(1009, 13, 9, '2024-04-02', '2024-04-06', 'Delivered', 55000.00),
(1010, 5, 7, '2024-04-10', '2024-04-14', 'Delivered', 28000.00),
(1011, 17, 14, '2024-04-18', '2024-04-23', 'Delivered', 72000.00),
(1012, 20, 5, '2024-05-01', '2024-05-05', 'Delivered', 110000.00),
(1013, 7, 2, '2024-05-12', '2024-05-16', 'Delivered', 85000.00),
(1014, 11, 6, '2024-05-20', '2024-05-24', 'Delivered', 41000.00),
(1015, 8, 15, '2024-06-01', '2024-06-05', 'Delivered', 35000.00),
(1016, 14, 3, '2024-06-10', '2024-06-14', 'Delivered', 98000.00),
(1017, 4, 4, '2024-06-18', '2024-06-22', 'Delivered', 67000.00),
(1018, 2, 6, '2024-07-01', '2024-07-05', 'Delivered', 53000.00),
(1019, 19, 11, '2024-07-08', '2024-07-12', 'Delivered', 45000.00),
(1020, 6, 12, '2024-07-15', '2024-07-19', 'Delivered', 22000.00),
(1021, 1, 2, '2024-07-22', '2024-07-26', 'Delivered', 91000.00),
(1022, 9, 10, '2024-08-01', '2024-08-05', 'Delivered', 115000.00),
(1023, 12, 1, '2024-08-10', '2024-08-14', 'Delivered', 18000.00),
(1024, 15, 8, '2024-08-18', '2024-08-22', 'Delivered', 37000.00),
(1025, 16, 13, '2024-09-01', '2024-09-05', 'Delivered', 29000.00),
(1026, 7, 1, '2024-09-10', '2024-09-14', 'Delivered', 78000.00),
(1027, 20, 5, '2024-09-18', '2024-09-22', 'Delivered', 92000.00),
(1028, 14, 2, '2024-09-25', '2024-09-29', 'Delivered', 130000.00),
(1029, 3, 9, '2024-10-03', '2024-10-07', 'Delivered', 48000.00),
(1030, 10, 4, '2024-10-10', '2024-10-14', 'Delivered', 15000.00),
(1031, 4, 4, '2024-10-18', '2024-10-22', 'Delivered', 82000.00),
(1032, 13, 9, '2024-10-25', '2024-10-29', 'Delivered', 64000.00),
(1033, 17, 14, '2024-11-01', '2024-11-05', 'Delivered', 58000.00),
(1034, 2, 6, '2024-11-08', '2024-11-12', 'Delivered', 71000.00),
(1035, 18, 3, '2024-11-15', '2024-11-19', 'Delivered', 33000.00),
(1036, 1, 1, '2024-11-22', '2024-11-26', 'Delivered', 105000.00),
(1037, 9, 10, '2024-12-01', '2024-12-05', 'Delivered', 96000.00),
(1038, 7, 2, '2024-12-08', '2024-12-12', 'Delivered', 68000.00),
(1039, 14, 1, '2024-12-15', '2024-12-19', 'Delivered', 142000.00),
(1040, 20, 5, '2024-12-20', '2024-12-24', 'Delivered', 87000.00);

INSERT INTO ORDER_ITEMS (ORDER_ITEM_ID, ORDER_ID, PRODUCT_ID, QUANTITY, UNIT_PRICE, DISCOUNT_PCT, LINE_TOTAL) VALUES
(1, 1001, 1, 2, 25000.00, 0.00, 50000.00),
(2, 1001, 6, 5, 5000.00, 0.00, 25000.00),
(3, 1002, 3, 2, 15000.00, 5.00, 28500.00),
(4, 1002, 4, 2, 8000.00, 0.00, 16000.00),
(5, 1003, 1, 1, 25000.00, 10.00, 22500.00),
(6, 1003, 8, 4, 2500.00, 0.00, 10000.00),
(7, 1004, 1, 3, 25000.00, 5.00, 71250.00),
(8, 1004, 6, 5, 5000.00, 5.00, 23750.00),
(9, 1005, 1, 4, 25000.00, 0.00, 100000.00),
(10, 1005, 7, 1, 20000.00, 0.00, 20000.00),
(11, 1006, 3, 3, 15000.00, 5.00, 42750.00),
(12, 1006, 13, 2, 18000.00, 0.00, 36000.00),
(13, 1007, 1, 5, 25000.00, 0.00, 125000.00),
(14, 1007, 6, 4, 5000.00, 0.00, 20000.00),
(15, 1008, 3, 2, 15000.00, 10.00, 27000.00),
(16, 1008, 11, 3, 6000.00, 0.00, 18000.00),
(17, 1009, 13, 2, 18000.00, 5.00, 34200.00),
(18, 1009, 5, 6, 3500.00, 0.00, 21000.00),
(19, 1010, 4, 2, 8000.00, 0.00, 16000.00),
(20, 1010, 8, 5, 2500.00, 0.00, 12500.00),
(21, 1011, 1, 2, 25000.00, 5.00, 47500.00),
(22, 1011, 14, 2, 10000.00, 0.00, 20000.00),
(23, 1012, 1, 3, 25000.00, 0.00, 75000.00),
(24, 1012, 7, 1, 20000.00, 0.00, 20000.00),
(25, 1012, 6, 3, 5000.00, 0.00, 15000.00),
(26, 1013, 13, 3, 18000.00, 5.00, 51300.00),
(27, 1013, 5, 10, 3500.00, 0.00, 35000.00),
(28, 1014, 3, 2, 15000.00, 0.00, 30000.00),
(29, 1014, 11, 2, 6000.00, 0.00, 12000.00),
(30, 1015, 2, 10, 1200.00, 5.00, 11400.00),
(31, 1015, 12, 8, 2000.00, 0.00, 16000.00),
(32, 1016, 1, 3, 25000.00, 0.00, 75000.00),
(33, 1016, 14, 2, 10000.00, 5.00, 19000.00),
(34, 1017, 1, 2, 25000.00, 0.00, 50000.00),
(35, 1017, 8, 7, 2500.00, 0.00, 17500.00),
(36, 1018, 3, 2, 15000.00, 5.00, 28500.00),
(37, 1018, 4, 3, 8000.00, 0.00, 24000.00),
(38, 1019, 11, 4, 6000.00, 0.00, 24000.00),
(39, 1019, 5, 6, 3500.00, 0.00, 21000.00),
(40, 1020, 9, 15, 750.00, 5.00, 10687.50),
(41, 1020, 10, 2, 4500.00, 0.00, 9000.00),
(42, 1021, 1, 3, 25000.00, 0.00, 75000.00),
(43, 1021, 6, 3, 5000.00, 5.00, 14250.00),
(44, 1022, 13, 4, 18000.00, 5.00, 68400.00),
(45, 1022, 3, 2, 15000.00, 0.00, 30000.00),
(46, 1023, 8, 3, 2500.00, 0.00, 7500.00),
(47, 1023, 15, 2, 4000.00, 0.00, 8000.00),
(48, 1024, 4, 3, 8000.00, 5.00, 22800.00),
(49, 1024, 11, 2, 6000.00, 0.00, 12000.00),
(50, 1025, 2, 10, 1200.00, 0.00, 12000.00),
(51, 1025, 5, 5, 3500.00, 0.00, 17500.00),
(52, 1026, 1, 2, 25000.00, 5.00, 47500.00),
(53, 1026, 7, 1, 20000.00, 0.00, 20000.00),
(54, 1027, 1, 3, 25000.00, 0.00, 75000.00),
(55, 1027, 6, 3, 5000.00, 5.00, 14250.00),
(56, 1028, 1, 4, 25000.00, 0.00, 100000.00),
(57, 1028, 13, 1, 18000.00, 0.00, 18000.00),
(58, 1029, 3, 2, 15000.00, 0.00, 30000.00),
(59, 1029, 8, 7, 2500.00, 0.00, 17500.00),
(60, 1030, 15, 2, 4000.00, 0.00, 8000.00),
(61, 1030, 9, 10, 750.00, 0.00, 7500.00),
(62, 1031, 1, 2, 25000.00, 5.00, 47500.00),
(63, 1031, 14, 3, 10000.00, 0.00, 30000.00),
(64, 1032, 13, 2, 18000.00, 0.00, 36000.00),
(65, 1032, 5, 8, 3500.00, 0.00, 28000.00),
(66, 1033, 1, 2, 25000.00, 0.00, 50000.00),
(67, 1033, 4, 1, 8000.00, 0.00, 8000.00),
(68, 1034, 3, 3, 15000.00, 5.00, 42750.00),
(69, 1034, 11, 4, 6000.00, 0.00, 24000.00),
(70, 1035, 2, 12, 1200.00, 0.00, 14400.00),
(71, 1035, 12, 10, 2000.00, 0.00, 20000.00),
(72, 1036, 1, 3, 25000.00, 0.00, 75000.00),
(73, 1036, 7, 1, 20000.00, 5.00, 19000.00),
(74, 1037, 13, 3, 18000.00, 0.00, 54000.00),
(75, 1037, 3, 2, 15000.00, 5.00, 28500.00),
(76, 1038, 1, 2, 25000.00, 0.00, 50000.00),
(77, 1038, 6, 4, 5000.00, 0.00, 20000.00),
(78, 1039, 1, 5, 25000.00, 0.00, 125000.00),
(79, 1039, 6, 3, 5000.00, 5.00, 14250.00),
(80, 1040, 1, 3, 25000.00, 0.00, 75000.00),
(81, 1040, 8, 5, 2500.00, 0.00, 12500.00);

-- =============================================================================
-- STEP 4: Create Semantic View
-- =============================================================================

CREATE OR REPLACE SEMANTIC VIEW SALES_ANALYTICS
    TABLES (
        DEMO_DB.SALES.CUSTOMERS PRIMARY KEY (CUSTOMER_ID),
        DEMO_DB.SALES.MARKETS PRIMARY KEY (MARKET_ID),
        DEMO_DB.SALES.PRODUCTS PRIMARY KEY (PRODUCT_ID),
        DEMO_DB.SALES.ORDERS PRIMARY KEY (ORDER_ID),
        DEMO_DB.SALES.ORDER_ITEMS
    )
    RELATIONSHIPS (
        ORDERS_TO_CUSTOMERS AS ORDERS(CUSTOMER_ID) REFERENCES CUSTOMERS(CUSTOMER_ID),
        ORDERS_TO_MARKETS AS ORDERS(MARKET_ID) REFERENCES MARKETS(MARKET_ID),
        ORDER_ITEMS_TO_ORDERS AS ORDER_ITEMS(ORDER_ID) REFERENCES ORDERS(ORDER_ID),
        ORDER_ITEMS_TO_PRODUCTS AS ORDER_ITEMS(PRODUCT_ID) REFERENCES PRODUCTS(PRODUCT_ID)
    )
    FACTS (
        PRODUCTS.UNIT_PRICE AS UNIT_PRICE,
        PRODUCTS.COST AS COST,
        ORDERS.TOTAL_AMOUNT AS TOTAL_AMOUNT,
        ORDER_ITEMS.UNIT_PRICE AS UNIT_PRICE,
        ORDER_ITEMS.DISCOUNT_PCT AS DISCOUNT_PCT,
        ORDER_ITEMS.LINE_TOTAL AS LINE_TOTAL
    )
    DIMENSIONS (
        CUSTOMERS.CUSTOMER_ID AS CUSTOMER_ID,
        CUSTOMERS.CUSTOMER_NAME AS CUSTOMER_NAME,
        CUSTOMERS.SEGMENT AS SEGMENT,
        CUSTOMERS.REGION AS REGION,
        CUSTOMERS.COUNTRY AS COUNTRY,
        CUSTOMERS.EMAIL AS EMAIL,
        CUSTOMERS.SIGNUP_DATE AS SIGNUP_DATE,
        MARKETS.MARKET_ID AS MARKET_ID,
        MARKETS.MARKET_NAME AS MARKET_NAME,
        MARKETS.COUNTRY AS COUNTRY,
        MARKETS.REGION AS REGION,
        MARKETS.CURRENCY AS CURRENCY,
        MARKETS.TIMEZONE AS TIMEZONE,
        PRODUCTS.PRODUCT_ID AS PRODUCT_ID,
        PRODUCTS.PRODUCT_NAME AS PRODUCT_NAME,
        PRODUCTS.CATEGORY AS CATEGORY,
        PRODUCTS.SUBCATEGORY AS SUBCATEGORY,
        ORDERS.ORDER_ID AS ORDER_ID,
        ORDERS.CUSTOMER_ID AS CUSTOMER_ID,
        ORDERS.MARKET_ID AS MARKET_ID,
        ORDERS.STATUS AS STATUS,
        ORDERS.ORDER_DATE AS ORDER_DATE,
        ORDERS.SHIP_DATE AS SHIP_DATE,
        ORDER_ITEMS.ORDER_ITEM_ID AS ORDER_ITEM_ID,
        ORDER_ITEMS.ORDER_ID AS ORDER_ID,
        ORDER_ITEMS.PRODUCT_ID AS PRODUCT_ID,
        ORDER_ITEMS.QUANTITY AS QUANTITY
    )
    COMMENT = 'Sales analytics model for analyzing top customers, top markets, product performance, and sales trends across regions and customer segments.'
    AI_VERIFIED_QUERIES (
        TOP_10_CUSTOMERS_BY_REVENUE AS (
            QUESTION 'Who are the top 10 customers by revenue?'
            VERIFIED_AT 1780367039
            VERIFIED_BY 'Semantic Model Generator'
            ONBOARDING_QUESTION FALSE
            SQL 'SELECT c.CUSTOMER_NAME, SUM(o.TOTAL_AMOUNT) AS total_revenue FROM customers AS c JOIN orders AS o ON c.CUSTOMER_ID = o.CUSTOMER_ID GROUP BY c.CUSTOMER_NAME ORDER BY total_revenue DESC LIMIT 10'
        ),
        TOP_10_MARKETS_BY_SALES AS (
            QUESTION 'What are the top 10 markets by sales revenue?'
            VERIFIED_AT 1780367039
            VERIFIED_BY 'Semantic Model Generator'
            ONBOARDING_QUESTION FALSE
            SQL 'SELECT m.MARKET_NAME, SUM(o.TOTAL_AMOUNT) AS total_sales FROM markets AS m JOIN orders AS o ON m.MARKET_ID = o.MARKET_ID GROUP BY m.MARKET_NAME ORDER BY total_sales DESC LIMIT 10'
        ),
        PRODUCTS_BY_REVENUE AS (
            QUESTION 'Which products generate the most revenue?'
            VERIFIED_AT 1780367039
            VERIFIED_BY 'Semantic Model Generator'
            ONBOARDING_QUESTION FALSE
            SQL 'SELECT p.PRODUCT_NAME, p.CATEGORY, SUM(oi.LINE_TOTAL) AS total_revenue, SUM(oi.QUANTITY) AS total_units FROM products AS p JOIN order_items AS oi ON p.PRODUCT_ID = oi.PRODUCT_ID GROUP BY p.PRODUCT_NAME, p.CATEGORY ORDER BY total_revenue DESC'
        ),
        MONTHLY_SALES_TREND AS (
            QUESTION 'What is the monthly sales trend?'
            VERIFIED_AT 1780367039
            VERIFIED_BY 'Semantic Model Generator'
            ONBOARDING_QUESTION FALSE
            SQL 'SELECT DATE_TRUNC(''MONTH'', o.ORDER_DATE) AS month, SUM(o.TOTAL_AMOUNT) AS monthly_revenue, COUNT(DISTINCT o.ORDER_ID) AS order_count FROM orders AS o GROUP BY month ORDER BY month'
        ),
        REVENUE_BY_SEGMENT AS (
            QUESTION 'How does revenue break down by customer segment?'
            VERIFIED_AT 1780367039
            VERIFIED_BY 'Semantic Model Generator'
            ONBOARDING_QUESTION FALSE
            SQL 'SELECT c.SEGMENT, COUNT(DISTINCT c.CUSTOMER_ID) AS customer_count, SUM(o.TOTAL_AMOUNT) AS segment_revenue FROM customers AS c JOIN orders AS o ON c.CUSTOMER_ID = o.CUSTOMER_ID GROUP BY c.SEGMENT'
        )
    );

-- =============================================================================
-- STEP 5: Create the Cortex Agent (SALES_DEMO_AGENT)
-- =============================================================================

CREATE OR REPLACE AGENT IDENTIFIER($TARGET_DATABASE || '.' || $TARGET_SCHEMA || '.SALES_DEMO_AGENT')
FROM SPECIFICATION $spec$
{
  "models": {
    "orchestration": "auto"
  },
  "orchestration": {
    "budget": {
      "seconds": 60,
      "tokens": 50000
    }
  },
  "instructions": {
    "orchestration": "You are a sales analytics assistant. Use the query_sales_data tool to answer questions about top customers by revenue, top markets by sales volume, product performance, monthly sales trends, and customer segment analysis. Always provide specific numbers and rankings when asked about top-N lists.",
    "response": "Present data clearly and concisely. When showing rankings or top-N lists, use tables with rank numbers. When showing trends over time, generate charts. Always include the total or summary figure alongside detailed breakdowns."
  },
  "tools": [
    {
      "tool_spec": {
        "type": "cortex_analyst_text_to_sql",
        "name": "query_sales_data",
        "description": "Query sales analytics data to answer questions about customers, markets, products, orders, and revenue. This tool accesses 5 tables: CUSTOMERS (customer details and segments), MARKETS (market regions and geographies), PRODUCTS (product catalog with categories and pricing), ORDERS (order headers with dates and totals), and ORDER_ITEMS (line items with quantities and discounts). Use this tool for questions about top customers by revenue, top markets by sales, product performance, sales trends, and segment analysis."
      }
    },
    {
      "tool_spec": {
        "type": "data_to_chart",
        "name": "data_to_chart",
        "description": "Generates visualizations from query results. Use for bar charts showing rankings, line charts showing trends over time, and pie charts showing segment breakdowns."
      }
    }
  ],
  "tool_resources": {
    "query_sales_data": {
      "semantic_view": "DEMO_DB.SALES.SALES_ANALYTICS",
      "execution_environment": {
        "type": "warehouse",
        "warehouse": "DEMO_WH",
        "query_timeout": 60
      }
    }
  }
}
$spec$
COMMENT = 'Sales analytics demo agent for top customers, markets, and product insights';

-- =============================================================================
-- STEP 6: Verify Setup
-- =============================================================================

SELECT 'Tables' AS object_type, COUNT(*) AS count FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = $TARGET_SCHEMA AND TABLE_CATALOG = $TARGET_DATABASE AND TABLE_TYPE = 'BASE TABLE'
UNION ALL
SELECT 'Rows in CUSTOMERS', COUNT(*) FROM DEMO_DB.SALES.CUSTOMERS
UNION ALL
SELECT 'Rows in MARKETS', COUNT(*) FROM DEMO_DB.SALES.MARKETS
UNION ALL
SELECT 'Rows in PRODUCTS', COUNT(*) FROM DEMO_DB.SALES.PRODUCTS
UNION ALL
SELECT 'Rows in ORDERS', COUNT(*) FROM DEMO_DB.SALES.ORDERS
UNION ALL
SELECT 'Rows in ORDER_ITEMS', COUNT(*) FROM DEMO_DB.SALES.ORDER_ITEMS;

SHOW SEMANTIC VIEWS IN SCHEMA IDENTIFIER($TARGET_DATABASE || '.' || $TARGET_SCHEMA);
SHOW AGENTS LIKE 'SALES_DEMO_AGENT' IN SCHEMA IDENTIFIER($TARGET_DATABASE || '.' || $TARGET_SCHEMA);

-- =============================================================================
-- SUMMARY
-- =============================================================================
--
-- Objects created:
--   Database:       DEMO_DB
--   Schema:         DEMO_DB.SALES
--   Tables:         CUSTOMERS, MARKETS, PRODUCTS, ORDERS, ORDER_ITEMS
--   Semantic View:  SALES_ANALYTICS
--   Agent:          SALES_DEMO_AGENT
--
-- Next: Run demo_mcp_oauth_setup.sql to create the MCP Server and OAuth integration.
-- =============================================================================
