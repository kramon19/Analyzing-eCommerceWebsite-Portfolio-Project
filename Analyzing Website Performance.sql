USE mavenfuzzyfactory;
-- SELECT * FROM website_pageviews;
-- SELECT * FROM website_sessions;
-- SELECT * FROM orders;

-- ANALYZING WEBSITE PERFORMANCE

-- (1) Most Viewed Website Pages

SELECT
	pageview_url,
    COUNT(DISTINCT website_pageview_id) AS pageviews
FROM website_pageviews
WHERE created_at <= '2012-06-09'
GROUP BY 1
ORDER BY pageviews DESC;

-- (2) Pull a list of the top entry pages

-- STEP 1: find the first pageview for each session
-- STEP 2: find the url that the customer saw on that first pageview

CREATE TEMPORARY TABLE first_pv_per_session
SELECT
	website_session_id,
    MIN(website_pageview_id) AS first_pageview
FROM website_pageviews
WHERE created_at < '2012-06-12'
GROUP BY 1;


-- LEFT JOIN first_pv_per_session TABLE TO website_pageviews TABLE ON first_pv TO SHOW LANDING URL
SELECT
	website_pageviews.pageview_url AS landing_url,
    COUNT(DISTINCT first_pv_per_session.website_session_id) AS sessions_hitting_page
FROM first_pv_per_session
	LEFT JOIN website_pageviews
		ON first_pv_per_session.first_pageview = website_pageviews.website_pageview_id
GROUP BY 1;
        

-- (3) CALCULATING TOTAL SESSIONS, BOUNCED SESSIONS, AND BOUNCE RATE FOR THE HOMEPAGE URL 

-- STEP 1: find the first pageview for each session
-- STEP 2: count the number of pageviews for each session
-- STEP 3: if pageviews = 1, then it is a bounced session. 


CREATE TEMPORARY TABLE first_pv
SELECT 
	website_session_id,
    MIN(website_pageview_id) AS first_pageview
FROM website_pageviews
WHERE created_at <= '2012-06-14'
GROUP BY 1;

-- ONLY GOING TO SHOW SESSIONS THAT HIT THE LANDING PAGE (/home)
SELECT
    website_pageviews.pageview_url AS landing_page,
    first_pv.website_session_id
FROM first_pv
	LEFT JOIN website_pageviews
		ON website_pageviews.website_pageview_id = first_pv.first_pageview;


CREATE TEMPORARY TABLE bounced_sessions
SELECT
	website_session_id,
    COUNT(DISTINCT website_pageview_id) AS pageviews
FROM website_pageviews
WHERE created_at <= '2012-06-14' 
GROUP BY 1
HAVING pageviews = 1;

SELECT
	COUNT(DISTINCT sessions_hit_lander.website_session_id) AS sessions,
    COUNT(bounced_sessions.pageviews) AS bounced_sessions,
    COUNT(bounced_sessions.pageviews) / COUNT(DISTINCT sessions_hit_lander.website_session_id) AS bounced_rate
FROM (SELECT
    website_pageviews.pageview_url AS landing_page,
    first_pv.website_session_id
FROM first_pv
	LEFT JOIN website_pageviews
		ON website_pageviews.website_pageview_id = first_pv.first_pageview) AS sessions_hit_lander
	LEFT JOIN bounced_sessions
		ON bounced_sessions.website_session_id = sessions_hit_lander.website_session_id;
        
        
-- (4) 50/50 TEST AGAINST THE HOMEPAGE (/home) AND NEW CUSTOM LANDING PAGE (/lander) FOR GSEARCH NONBRAND TRAFFIC
-- FIND THE TOTAL SESSIONS, BOUNCED SESSIONS, AND BOUNCED RATE

-- STEP 1: find the first pageview for lander-1 for comparison
-- STEP 2: find the first pageview for each session for each homepage
-- STEP 3: find the number of pageviews for each session
-- STEP 4: LIMIT TO 1 PAGEVIEW PER SESSION
-- STEP 5: COUNT TOTAL SESSIONS, BOUNCED SESSIONS, AND BOUNCED RATE FOR /home AND /lander-1


-- STEP 1: find the first pageview for lander-1 for comparison
SELECT
	MIN(website_pageview_id) AS lander1_first_pv
FROM website_pageviews
WHERE pageview_url = '/lander-1';

-- First pageview for '/lander-1' = 23504

-- STEP 2: find the first pageview for each session for /lander-1 and /home
CREATE TEMPORARY TABLE first_pvs
SELECT
	website_pageviews.website_session_id,
	MIN(website_pageviews.website_pageview_id) AS first_pageview
FROM website_pageviews
	LEFT JOIN website_sessions
		ON website_sessions.website_session_id = website_pageviews.website_session_id
WHERE website_pageviews.created_at <= '2012-07-28'
	AND website_pageview_id >= 23504
    AND website_sessions.utm_source = 'gsearch'
    AND website_sessions.utm_campaign = 'nonbrand'
GROUP BY 1;

-- brings in the pageview_url to see which homepage each user is hitting
CREATE TEMPORARY TABLE first_pvs_url
SELECT
	first_pvs.website_session_id,
    first_pvs.first_pageview,
    website_pageviews.pageview_url
FROM first_pvs
	LEFT JOIN website_pageviews
		ON website_pageviews.website_pageview_id = first_pvs.first_pageview; -- joins data that meets the first pageview table criteria
        

-- STEP 3: find the number of pageviews for each session
CREATE TEMPORARY TABLE bounced
SELECT
	first_pvs_url.website_session_id,
    first_pvs_url.pageview_url,
    COUNT(DISTINCT website_pageviews.website_pageview_id) AS pvs
FROM first_pvs_url
	LEFT JOIN website_pageviews
		ON website_pageviews.website_session_id = first_pvs_url.website_session_id
GROUP BY 1, 2
HAVING pvs = 1; -- STEP 4: LIMIT TO 1 PAGEVIEW PER SESSION

-- STEP 5: COUNT TOTAL SESSIONS, BOUNCED SESSIONS, AND BOUNCED RATE FOR /home AND /lander-1

SELECT
	first_pvs_url.pageview_url,
    COUNT(DISTINCT first_pvs_url.website_session_id) AS total_sessions,
    COUNT(DISTINCT bounced.website_session_id) AS bounced_sessions,
    COUNT(DISTINCT bounced.website_session_id) / COUNT(DISTINCT first_pvs_url.website_session_id) AS bounced_rate
FROM first_pvs_url
	LEFT JOIN bounced
		ON bounced.website_session_id = first_pvs_url.website_session_id
GROUP BY 1;


-- (5) PULL PAID SEARCH NON TRAFFIC NONBRAND LANDING ON /home AND /landing-1 AND BOUNCE RATES TRENDED WEEKLY SINCE JUNE 1ST 2012

-- STEP 1: pull data for nonbrand gsearch starting from 2012-06-01 to 2012-08-31 and the first pageview for /lander-1 and /home
-- STEP 2: count the number of pageviews for /home and /lander-1
-- STEP 3: count pageviews if number of pageviews = 1 to either /home or /lander-1

DROP TEMPORARY TABLE home_lander;
CREATE TEMPORARY TABLE home_lander
SELECT
	website_sessions.website_session_id,
    website_pageviews.website_pageview_id,
    website_sessions.utm_source,
    website_sessions.utm_campaign,
    website_pageviews.pageview_url,
    website_sessions.created_at
FROM website_sessions
	LEFT JOIN website_pageviews
		ON website_sessions.website_session_id = website_pageviews.website_session_id
WHERE website_sessions.created_at BETWEEN '2012-06-01' AND '2012-09-01'
	AND website_sessions.utm_campaign = 'nonbrand'
    AND website_sessions.utm_source = 'gsearch'
    AND website_pageviews.pageview_url IN ('/home', '/lander-1');


-- first_pvs    
CREATE TEMPORARY TABLE first_pvs    
SELECT 
	home_lander.website_session_id,
    MIN(home_lander.website_pageview_id) AS first_pv
FROM home_lander
GROUP BY 1;

-- first_pvs with pageview_url (/home & /lander-1)    
CREATE TEMPORARY TABLE first_pvs_landing
SELECT
	first_pvs.website_session_id,
    first_pvs.first_pv,
    home_lander.pageview_url
FROM first_pvs
	LEFT JOIN home_lander
		ON home_lander.website_pageview_id = first_pvs.first_pv;

-- STEP 2: count the number of pageviews for /home and /lander-1
-- STEP 3: count pageviews if number of pageviews = 1 to either /home or /lander-1
DROP TEMPORARY TABLE bounced;
CREATE TEMPORARY TABLE bounced
SELECT 
    first_pvs_landing.website_session_id,
    COUNT(DISTINCT website_pageviews.website_pageview_id) AS bounced_pvs, -- count the pageviews associated with first_pvs_landing.website_session_id
	first_pvs_landing.pageview_url
FROM first_pvs_landing
	LEFT JOIN website_pageviews
		ON website_pageviews.website_session_id = first_pvs_landing.website_session_id
GROUP BY 1, 3 
HAVING bounced_pvs = 1;

-- STEP 4: count /home sessions and /lander-1 sessions and bounced rate grouped by week
SELECT
	MIN(DATE(home_lander.created_at)) AS min_start_week,
	COUNT(DISTINCT CASE WHEN home_lander.pageview_url = '/home' THEN home_lander.website_session_id
		ELSE NULL END) AS home_sessions,
	COUNT(DISTINCT CASE WHEN home_lander.pageview_url = '/lander-1' THEN home_lander.website_session_id
		ELSE NULL END) AS lander_sessions,
	COUNT(DISTINCT bounced.website_session_id) / COUNT(DISTINCT home_lander.website_session_id) AS bounced_rate   
FROM home_lander
	LEFT JOIN bounced
		ON bounced.website_session_id = home_lander.website_session_id
GROUP BY WEEK(created_at);
    
    
-- (6) ANALYZING CLICK THRU RATES. BUILD A FULL CONVERSION FUNNEL, ANALYZING HOW MANY CUSTOMERS MAKE IT TO EACH STEP FOR /lander-1.

-- STEP 1: gather relevant data based for gsearch and nonbrands vistors
-- STEP 2: find all the pageviews that start with /lander-1
-- STEP 3: flag all of the pageviews that follows after /lander-1
-- STEP 4: (OPTIONAL) compress the flags to each website_session_id 
-- STEP 5: count the number of times each user goes to each pageview_url

-- STEP 1: gather relevant data based for gsearch and nonbrands vistors
CREATE TEMPORARY TABLE gsearch_nonbrand
SELECT
	website_pageviews.website_session_id,
    website_pageviews.website_pageview_id,
    website_pageviews.pageview_url
FROM website_pageviews
	LEFT JOIN website_sessions
		ON website_sessions.website_session_id = website_pageviews.website_session_id
WHERE website_pageviews.created_at BETWEEN '2012-08-05' AND '2012-09-06'
	AND website_sessions.utm_source = 'gsearch'
    AND website_sessions.utm_campaign = 'nonbrand';
    
-- STEP 2: find all the pageviews that start with /lander-1    
DROP TEMPORARY TABLE first_pvs;
CREATE TEMPORARY TABLE first_pvs
SELECT
	website_session_id,
    MIN(website_pageview_id) AS first_pv,
    pageview_url
FROM gsearch_nonbrand
WHERE pageview_url = '/lander-1'
GROUP BY 1, 3;

-- STEP 3: flag all of the pageviews that follows after /lander-1 (checks where each customer click thru)
CREATE TEMPORARY TABLE clickthrus
SELECT
	first_pvs.website_session_id,
    CASE WHEN website_pageviews.pageview_url = '/lander-1' THEN 1 ELSE 0 END AS lander,
    CASE WHEN website_pageviews.pageview_url = '/products' THEN 1 ELSE 0 END AS products,
    CASE WHEN website_pageviews.pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS mrfuzzy,
    CASE WHEN website_pageviews.pageview_url = '/cart' THEN 1 ELSE 0 END AS cart,
    CASE WHEN website_pageviews.pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping,
	CASE WHEN website_pageviews.pageview_url = '/billing' THEN 1 ELSE 0 END AS billing,
    CASE WHEN website_pageviews.pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou
FROM first_pvs
	LEFT JOIN website_pageviews
		ON website_pageviews.website_session_id = first_pvs.website_session_id;

-- STEP 4: (OPTIONAL) compress the flags to each website_session_id         
-- compresses the website_session_id into one line that shows the clickthoughs for each pageview_url. If a 1, then the user clicked on that URL
-- If a 0, then the user did not reach that URL
SELECT
	website_session_id,
	MAX(lander) AS lander,
    MAX(products) AS products,
    MAX(mrfuzzy) AS myfuzzy,
    MAX(cart) AS cart,
    MAX(shipping) AS shipping,
    MAX(billing) AS thankyou
FROM clickthrus
GROUP BY 1;


-- STEP 5: count the number of times each user goes to each pageview_url
SELECT
	COUNT(DISTINCT CASE WHEN lander = 1 THEN website_session_id ELSE NULL END) AS sessions,
    COUNT(DISTINCT CASE WHEN products = 1 THEN website_session_id ELSE NULL END) AS to_products,
    COUNT(DISTINCT CASE WHEN mrfuzzy = 1 THEN website_session_id ELSE NULL END) AS to_mrfuzzy,
    COUNT(DISTINCT CASE WHEN cart = 1 THEN website_session_id ELSE NULL END) AS to_cart,
    COUNT(DISTINCT CASE WHEN shipping = 1 THEN website_session_id ELSE NULL END) AS to_shipping,
    COUNT(DISTINCT CASE WHEN billing = 1 THEN website_session_id ELSE NULL END) AS to_billing,
    COUNT(DISTINCT CASE WHEN thankyou = 1 THEN website_session_id ELSE NULL END) AS to_thankyou
FROM (SELECT
	website_session_id,
	MAX(lander) AS lander,
    MAX(products) AS products,
    MAX(mrfuzzy) AS mrfuzzy,
    MAX(cart) AS cart,
    MAX(shipping) AS shipping,
    MAX(billing) AS billing,
    MAX(thankyou) AS thankyou
FROM clickthrus
GROUP BY 1) AS clickthroughs;


-- STEP 5: count the number of times each user goes to each pageview_url
-- or you can skip the compression in STEP 4 and count the flags in each column. Produces same results
SELECT 
	COUNT(DISTINCT CASE WHEN lander = 1 THEN website_session_id ELSE NULL END) AS sessions,
    COUNT(DISTINCT CASE WHEN products = 1 THEN website_session_id ELSE NULL END) AS to_products,
    COUNT(DISTINCT CASE WHEN mrfuzzy = 1 THEN website_session_id ELSE NULL END) AS to_mrfuzzy,
    COUNT(DISTINCT CASE WHEN cart = 1 THEN website_session_id ELSE NULL END) AS to_cart,
    COUNT(DISTINCT CASE WHEN shipping = 1 THEN website_session_id ELSE NULL END) AS to_shipping,
    COUNT(DISTINCT CASE WHEN billing = 1 THEN website_session_id ELSE NULL END) AS to_billing,
    COUNT(DISTINCT CASE WHEN thankyou = 1 THEN website_session_id ELSE NULL END) AS to_thankyou
FROM clickthrus;
        
    
SELECT
	to_products / sessions AS lander_click_rt, -- when user reaches products page
    to_mrfuzzy / to_products AS products_click_rt, -- when user reaches mrfuzzy page
    to_cart / to_mrfuzzy AS mrfuzzy_click_rt, -- when user reaches cart page
    to_shipping / to_cart AS cart_click_rt, -- when user reaches shipping page
    to_billing / to_shipping AS shipping_click_rt, -- when user reaches billing page
    to_thankyou / to_billing AS billing_click_rt -- when user reaches thank you page
FROM (SELECT 
	COUNT(DISTINCT CASE WHEN lander = 1 THEN website_session_id ELSE NULL END) AS sessions,
    COUNT(DISTINCT CASE WHEN products = 1 THEN website_session_id ELSE NULL END) AS to_products,
    COUNT(DISTINCT CASE WHEN mrfuzzy = 1 THEN website_session_id ELSE NULL END) AS to_mrfuzzy,
    COUNT(DISTINCT CASE WHEN cart = 1 THEN website_session_id ELSE NULL END) AS to_cart,
    COUNT(DISTINCT CASE WHEN shipping = 1 THEN website_session_id ELSE NULL END) AS to_shipping,
    COUNT(DISTINCT CASE WHEN billing = 1 THEN website_session_id ELSE NULL END) AS to_billing,
    COUNT(DISTINCT CASE WHEN thankyou = 1 THEN website_session_id ELSE NULL END) AS to_thankyou
FROM clickthrus) AS clickthru_rates;
	
-- SINCE CLICKTHROUGH RATES WERE LOW FOR /billing, THERE IS /billing-2
-- FIND THE PERCENTAGE OF ORDERS PLACED COMPARED TO /billing AND /billing-2 to see if conversion rate increased 

-- need to find when the first time /billing-2 was used to have a fair comparison with /billing
SELECT
	MIN(website_pageview_id) AS first_pv,
    MIN(created_at) AS first_date
FROM website_pageviews
WHERE pageview_url = '/billing-2';

-- first pageview for /billing-2 is '53550'
-- first date for /billing-2 is '2012-09-10 01:13:05'

SELECT
	website_pageviews.pageview_url AS billing_version_seen,
	COUNT(DISTINCT website_pageviews.website_session_id) AS sessions,
    COUNT(DISTINCT orders.order_id) AS orders,
	COUNT(DISTINCT orders.order_id) /  COUNT(DISTINCT website_pageviews.website_session_id) AS billing_to_order_rt
FROM website_pageviews
	LEFT JOIN orders
		ON orders.website_session_id = website_pageviews.website_session_id
WHERE website_pageviews.website_pageview_id > 53549
	AND pageview_url IN ('/billing', '/billing-2')
    AND website_pageviews.created_at < '2012-11-10'
GROUP BY 1;


        
        


