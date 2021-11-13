USE mavenfuzzyfactory;
-- ANALYZING PRODUCT SALES

-- (1) Product-Level sales analysis

-- Pull monthly trends for number of sales, total revenue, and total margin generated (till '2013-01-01') 
-- Number of Sales = orders
-- Total Revenue = sum of price_usd
-- Margin = Revenue - COGS

SELECT * FROM orders;
SELECT * FROM website_sessions;
SELECT * FROM website_pageviews;

SELECT
	YEAR(created_at) AS year,
    MONTH(created_at) AS month,
    COUNT(DISTINCT order_id) AS number_of_sales,
	SUM(price_usd) AS revenue,
    SUM(price_usd) - SUM(cogs_usd) AS margin
FROM orders
WHERE created_at <= '2013-01-04'
GROUP BY 1, 2; 



-- ______________________________________________________________________________________________________________________________________ --


-- Analyzing Product Launches
-- Pull out monthly order volume, overall conversion rates, revevnue per session, and a breakdown of sales by product since '2012-04-01'

-- Order Volume = count of orders
-- Conversion Rates = orders / sessions
-- Revenue per Session (RPV) = revenue / sessions
-- Breakdown of sales by products (product 1 and product 2)

SELECT
	YEAR(website_sessions.created_at) AS year,
    MONTH(website_sessions.created_at) AS month,
    COUNT(DISTINCT orders.order_id) AS orders, -- Order Volume = count of orders
    COUNT(DISTINCT orders.order_id) / COUNT(DISTINCT website_sessions.website_session_id) AS conv_rate, -- Conversion Rates = orders / sessions
    SUM(orders.price_usd) / COUNT(DISTINCT website_sessions.website_session_id) AS rpv, -- Revenue per Session (RPV) = revenue / sessions
    COUNT(DISTINCT CASE WHEN orders.primary_product_id = 1 THEN order_id ELSE NULL END) AS product_1, -- Breakdown of sales by products
    COUNT(DISTINCT CASE WHEN orders.primary_product_id = 2 THEN order_id ELSE NULL END) AS product_2  -- Breakdown of sales by products 
FROM website_sessions 
	LEFT JOIN orders
		ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at >= '2012-04-01'
	AND website_sessions.created_at <= '2013-04-05'
GROUP BY 1, 2;




-- ______________________________________________________________________________________________________________________________________ --


-- PRODUCT-LEVEL WEBSITE PATHING 
-- Count the number of sessions that hit the /product page and count that went to the next page
-- Pull the clickthrough rates from /products page since the new product launch Jan. 6th 2013
-- Show the first 3 months before the launch and 3 months after the launch

-- STEP 1: isolate the time periods 3 months before launch and 3 months after launch
-- STEP 2: check to see which pageview_url that user clicked next after /products page 
-- STEP 3: use flags to count the number of pageviews for each session
-- STEP 4: count the number of flags for each pageview_url

-- before
CREATE TEMPORARY TABLE pre_launch
SELECT
	website_pageview_id,
    website_session_id,
    pageview_url
FROM website_pageviews
WHERE created_at >= '2012-10-06'
	AND created_at <= '2013-01-06'
    AND pageview_url = '/products';

-- only show the sessions that comes after /products
CREATE TEMPORARY TABLE pvs_after
SELECT
	MIN(website_pageviews.website_pageview_id) AS first_pv_after,
    website_pageviews.website_session_id
    -- website_pageviews.pageview_url
FROM pre_launch 
	LEFT JOIN website_pageviews
	ON website_pageviews.website_session_id = pre_launch.website_session_id
    AND website_pageviews.website_pageview_id > pre_launch.website_pageview_id
GROUP BY 2;

SELECT
	pvs_after.first_pv_after,
    pvs_after.website_session_id,
    website_pageviews.pageview_url
FROM pvs_after
	LEFT JOIN website_pageviews
		ON website_pageviews.website_pageview_id = pvs_after.first_pv_after;


-- after 
CREATE TEMPORARY TABLE post_launch
SELECT
	website_pageview_id,
    website_session_id,
    pageview_url
FROM website_pageviews
WHERE created_at >= '2013-01-06'
	AND created_at <= '2013-04-06';
    
-- only show the sessions that comes after /products for after launch
CREATE TEMPORARY TABLE pvs_after_post
SELECT
	MIN(website_pageviews.website_pageview_id) AS first_pv_after,
    website_pageviews.website_session_id
    -- website_pageviews.pageview_url
FROM post_launch 
	LEFT JOIN website_pageviews
	ON website_pageviews.website_session_id = post_launch.website_session_id
    AND website_pageviews.website_pageview_id > post_launch.website_pageview_id
GROUP BY 2;


SELECT
	pvs_after_post.first_pv_after,
    pvs_after_post.website_session_id,
    website_pageviews.pageview_url
FROM pvs_after_post
	LEFT JOIN website_pageviews
		ON website_pageviews.website_pageview_id = pvs_after_post.first_pv_after;
        
-- ______________________________________________________________________________________________________________________________________ --


-- Pre post analysis for third launched item (2013-12-12)
-- Find the conversion rate, AOV, products per session and revenue per session
-- conversion rate = orders / sessions
-- AOV (average order value) = average of the order
-- products per session = number of products / sessions
-- revenue per session = revenue / sessions

-- STEP 1: gather all relevant information and categorize the time periods
		-- order_id, created_at, website_session_id, price_usd, cogs_usd
 
SELECT 
	-- website_sessions.website_session_id,
    CASE WHEN website_sessions.created_at BETWEEN '2013-11-12' AND '2013-12-12' THEN 'Pre_Bday_Bear'
		WHEN website_sessions.created_at BETWEEN '2013-12-12' AND '2014-01-12' THEN 'Post_Bday_Bear'
        ELSE 'logic check'
	END AS time_period,
	COUNT(DISTINCT orders.order_id) / COUNT(DISTINCT website_sessions.website_session_id) AS conv_rate,
    AVG(orders.price_usd) AS aov,
    SUM(orders.items_purchased) / COUNT(DISTINCT orders.order_id) AS products_per_order,
    SUM(orders.price_usd) / COUNT(DISTINCT website_sessions.website_session_id) AS revenue_per_session
FROM website_sessions
	LEFT JOIN orders
		ON orders.website_session_id = website_sessions.website_session_id
WHERE website_sessions.created_at >= '2013-11-12' 
	AND website_sessions.created_at <= '2014-01-12'
GROUP BY 1;  
    


-- ______________________________________________________________________________________________________________________________________ --


-- CALCULATE THE MONTHLY REFUND RATE FOR EACH PRODUCTS STARTING FROM 2012 THRU OCT. 15TH 2014

-- SELECT * FROM order_items;
-- SELECT * FROM order_item_refunds;

-- STEP 1: count the number of order_item_id
-- STEP 2: count the number of order_item_refund_id
-- STEP 3: count the number of order_item_id / count the number of order_item_refund_id to find the refund rate
-- STEP 4: do this for each products

SELECT DISTINCT product_id FROM order_items;
SELECT DISTINCT * FROM orders;


-- There are 4 distinct products: product_id 1, 2, 3, 4

SELECT
	YEAR(order_items.created_at) AS year,
    MONTH(order_items.created_at) AS month,
	-- order_items.order_item_id,
    COUNT(DISTINCT CASE WHEN order_items.product_id = 1 THEN order_items.order_item_id ELSE NULL END) AS product1_orders,
    COUNT(DISTINCT CASE WHEN order_items.product_id = 1 AND order_item_refunds.order_item_refund_id IS NOT NULL 
		THEN order_item_refunds.order_item_refund_id ELSE NULL END) AS product1_refunds,
    COUNT(DISTINCT CASE WHEN order_items.product_id = 2 THEN order_items.order_item_id ELSE NULL END) AS product2_orders,
    COUNT(DISTINCT CASE WHEN order_items.product_id = 2 AND order_item_refunds.order_item_refund_id IS NOT NULL 
		THEN order_item_refunds.order_item_refund_id ELSE NULL END) AS product2_refunds,
    COUNT(DISTINCT CASE WHEN order_items.product_id = 3 THEN order_items.order_item_id ELSE NULL END) AS product3_orders,
    COUNT(DISTINCT CASE WHEN order_items.product_id = 3 AND order_item_refunds.order_item_refund_id IS NOT NULL 
		THEN order_item_refunds.order_item_refund_id ELSE NULL END) AS product3_refunds,
    COUNT(DISTINCT CASE WHEN order_items.product_id = 4 THEN order_items.order_item_id ELSE NULL END) AS product4_orders,
    COUNT(DISTINCT CASE WHEN order_items.product_id = 4 AND order_item_refunds.order_item_refund_id IS NOT NULL 
		THEN order_item_refunds.order_item_refund_id ELSE NULL END) AS product4_refunds
FROM order_items
	LEFT JOIN order_item_refunds
		On order_items.order_item_id = order_item_refunds.order_item_id
WHERE order_items.created_at <= '2014-10-15'
GROUP BY 1, 2 ;

-- find the refund rate 
SELECT 
	year,
    month,
	product1_orders,
    product1_refunds / product1_orders AS p1_refund_rate,
    product2_orders,
    product2_refunds / product2_orders AS p2_refund_rate,
    product3_orders,
    product3_refunds / product3_orders AS p3_refund_rate,
    product4_orders,
    product4_refunds / product4_orders AS p4_refund_rate
FROM (SELECT
	YEAR(order_items.created_at) AS year,
    MONTH(order_items.created_at) AS month,
	-- order_items.order_item_id,
    COUNT(DISTINCT CASE WHEN order_items.product_id = 1 THEN order_items.order_item_id ELSE NULL END) AS product1_orders,
    COUNT(DISTINCT CASE WHEN order_items.product_id = 1 AND order_item_refunds.order_item_refund_id IS NOT NULL 
		THEN order_item_refunds.order_item_refund_id ELSE NULL END) AS product1_refunds,
    COUNT(DISTINCT CASE WHEN order_items.product_id = 2 THEN order_items.order_item_id ELSE NULL END) AS product2_orders,
    COUNT(DISTINCT CASE WHEN order_items.product_id = 2 AND order_item_refunds.order_item_refund_id IS NOT NULL 
		THEN order_item_refunds.order_item_refund_id ELSE NULL END) AS product2_refunds,
    COUNT(DISTINCT CASE WHEN order_items.product_id = 3 THEN order_items.order_item_id ELSE NULL END) AS product3_orders,
    COUNT(DISTINCT CASE WHEN order_items.product_id = 3 AND order_item_refunds.order_item_refund_id IS NOT NULL 
		THEN order_item_refunds.order_item_refund_id ELSE NULL END) AS product3_refunds,
    COUNT(DISTINCT CASE WHEN order_items.product_id = 4 THEN order_items.order_item_id ELSE NULL END) AS product4_orders,
    COUNT(DISTINCT CASE WHEN order_items.product_id = 4 AND order_item_refunds.order_item_refund_id IS NOT NULL 
		THEN order_item_refunds.order_item_refund_id ELSE NULL END) AS product4_refunds
FROM order_items
	LEFT JOIN order_item_refunds
		On order_items.order_item_id = order_item_refunds.order_item_id
WHERE order_items.created_at <= '2014-10-15'
GROUP BY 1, 2 ) AS refund_rate;

    

-- ______________________________________________________________________________________________________________________________________ --

-- SELECT * FROM website_pageviews;
-- select * from website_sessions;
-- select * from orders;

-- COMPARE MONTH BEFORE AND MONTH AFTER TO CROSS SELL WITH 2ND PRODUCT 
-- FIND CLICKTHROUGH RATES, AOV, REVENUE PER CART PAGEVIEW, AVERAGE PRODUCTS PER ORDER
-- CTR: clicked to next page / sessions
-- AOV: average revenue generated per order AVG(price)
-- REVENUE PER CART PAGEVIEW: revenue / pageview_session
-- AVERAGE PRODUCTS PER ORDER: number of products / orders

-- Date Range: (PRE-Cross Sell) 2013-08-25 to 2013-09-25 AND 2013-09-25 to 2013-10-25 (POST-Cross Sell)
-- STEP 1: find clickthru rate from /cart 

DROP TEMPORARY TABLE cart_pv;
CREATE TEMPORARY TABLE cart_pv
SELECT
	website_session_id,
    website_pageview_id,
    pageview_url,
    created_at, 
    CASE WHEN created_at <= '2013-09-25' THEN 'A. PRE-Cross Sell'
		 WHEN created_at >= '2013-09-25' THEN  'B. POST-Cross Sell'
         ELSE 'logic check'
	END AS time_period
FROM website_pageviews
WHERE created_at BETWEEN '2013-08-25' AND '2013-10-25'
	AND pageview_url = '/cart';
    
-- find the pageviews clicked after /cart
DROP TEMPORARY TABLE clicked_after_cart;
-- CREATE TEMPORARY TABLE clicked_after_cart
SELECT
	cart_pv.website_session_id,
    cart_pv.website_pageview_id AS cart_pv_id,
    MIN(website_pageviews.website_pageview_id) AS clickthrus,
    -- website_pageviews.pageview_url,
    time_period
FROM cart_pv
	LEFT JOIN website_pageviews
		ON website_pageviews.website_session_id = cart_pv.website_session_id
        AND website_pageviews.website_pageview_id > cart_pv.website_pageview_id
GROUP BY 1, 2, 4;


-- AVERAGE PRODUCTS PER ORDER: number of products / orders 
DROP TEMPORARY TABLE performance_num;
CREATE TEMPORARY TABLE performance_num
SELECT
	cart_pv.time_period,
    orders.items_purchased,
    orders.order_id,
    orders.price_usd, -- AOV
    cart_pv.website_pageview_id -- COUNT(DISTINCT cart_pv.website_pageview_id) AS cart_pv
FROM orders
	INNER JOIN cart_pv
		ON cart_pv.website_session_id = orders.website_session_id
WHERE orders.created_at BETWEEN '2013-08-25' AND '2013-10-25';
-- GROUP BY 1;


SELECT
	clicked_after_cart.time_period,
	COUNT(DISTINCT clicked_after_cart.website_session_id) AS cart_sessions,
    COUNT(DISTINCT clicked_after_cart.clickthrus) AS clickthroughs,
    COUNT(DISTINCT clicked_after_cart.clickthrus) / COUNT(DISTINCT clicked_after_cart.website_session_id) AS cart_ctr,
    -- SUM(performance_num.items_purchased) / COUNT(DISTINCT performance_num.order_id) AS products_per_order,
    ROUND(AVG(performance_num.price_usd), 2) AS aov
    -- ROUND(SUM(performance_num.price_usd) / COUNT(DISTINCT clicked_after_cart.cart_pv_id), 2) AS rev_per_cart_session
FROM clicked_after_cart
	INNER JOIN performance_num
		ON performance_num.time_period = clicked_after_cart.time_period
GROUP BY 1;
    
    
    





-- SELECT
-- 	website_session_id,
-- 	CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END AS cart,
--     CASE WHEN pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping,
--     CASE WHEN pageview_url = '/billing-2' THEN 1 ELSE 0 END AS billing,
--     CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou
-- FROM website_pageviews
-- WHERE created_at BETWEEN '2013-08-25' AND '2013-11-25'
-- 	AND pageview_url IN ('/cart', '/billing', 'billing-2', '/shipping', '/thank-you-for-your-order')




    























	
