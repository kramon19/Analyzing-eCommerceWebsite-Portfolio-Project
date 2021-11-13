-- MONTHLY OR SEASONAL TRENDS

USE mavenfuzzyfactory;

/*
1.	Gsearch seems to be the biggest driver of our business. Could you pull monthly 
trends for gsearch sessions and orders so that we can showcase the growth there? 
*/ 

/* 
SELECT * FROM website_pageviews;
SELECT * FROM website_sessions;
SELECT * FROM orders;
*/

/* 
	sessions	  orders
Jan		#			#
Feb		#			#
Mar		#			#
*/

SELECT
    CASE 
		WHEN MONTH(website_sessions.created_at) = 1 THEN 'Jan'
        WHEN MONTH(website_sessions.created_at) = 2 THEN 'Feb'
        WHEN MONTH(website_sessions.created_at) = 3 THEN 'Mar'
        WHEN MONTH(website_sessions.created_at) = 4 THEN 'Apr'
        WHEN MONTH(website_sessions.created_at) = 5 THEN 'May'
        WHEN MONTH(website_sessions.created_at) = 6 THEN 'June'
        WHEN MONTH(website_sessions.created_at) = 7 THEN 'July'
        WHEN MONTH(website_sessions.created_at) = 8 THEN 'Aug'
        WHEN MONTH(website_sessions.created_at) = 9 THEN 'Sept'
        WHEN MONTH(website_sessions.created_at) = 10 THEN 'Oct'
        WHEN MONTH(website_sessions.created_at) = 11 THEN 'Nov'
        WHEN MONTH(website_sessions.created_at) = 12 THEN 'Dec'
	END AS months,
	COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
    COUNT(DISTINCT orders.order_id) AS orders,
    MONTH(website_sessions.created_at) AS months_no
FROM website_sessions
	LEFT JOIN orders
		ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.utm_source = 'gsearch'
	-- AND website_sessions.utm_campaign = 'nonbrand'
    AND website_sessions.created_at < '2013-01-01'
GROUP BY 1, 4
ORDER BY 4;

/*
2.	Next, it would be great to see a similar monthly trend for Gsearch, but this time splitting out nonbrand 
and brand campaigns separately. I am wondering if brand is picking up at all. If so, this is a good story to tell. 
*/ 

/* 
	non_sessions	  non_orders
Jan		#				#
Feb		#				#
Mar		#				#
*/

SELECT
	MONTH(website_sessions.created_at) AS months,
    -- website_sessions.utm_source,
	COUNT(DISTINCT CASE WHEN website_sessions.utm_campaign = 'brand'
		AND website_sessions.utm_source = 'gsearch' THEN website_sessions.website_session_id ELSE NULL END) AS brand_sessions,
    COUNT(DISTINCT CASE WHEN website_sessions.utm_campaign = 'brand' 
		AND website_sessions.utm_source = 'gsearch' THEN orders.order_id ELSE NULL END) AS brand_orders,
    COUNT(DISTINCT CASE WHEN website_sessions.utm_campaign = 'nonbrand' 
		AND website_sessions.utm_source = 'gsearch' THEN website_sessions.website_session_id ELSE NULL END) AS nonbrand_sessions,
    COUNT(DISTINCT CASE WHEN website_sessions.utm_campaign = 'nonbrand' 
		AND website_sessions.utm_source = 'gsearch' THEN orders.order_id ELSE NULL END) AS nonbrand_orders
FROM website_sessions
	LEFT JOIN orders
		ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at < '2013-01-01'
	AND website_sessions.utm_source = 'gsearch'
    AND website_sessions.utm_campaign = 'nonbrand'
    OR website_sessions.utm_campaign = 'brand'
GROUP BY 1;


/*
3.	While we’re on Gsearch, could you dive into nonbrand, and pull monthly sessions and orders split by device type? 
I want to flex our analytical muscles a little and show the board we really know our traffic sources. 
*/ 

/* 
	nonbrand_sessions_mob	  nonbrand_orders_mob
Jan		#							#
Feb		#							#
Mar		#							#
*/

SELECT
	YEAR(website_sessions.created_at) AS year,
	MONTH(website_sessions.created_at) AS months,
	COUNT(DISTINCT CASE WHEN website_sessions.device_type = 'desktop' THEN website_sessions.website_session_id ELSE NULL END) 
		AS nonbrand_sessions_desk,
	COUNT(DISTINCT CASE WHEN website_sessions.device_type = 'desktop' THEN orders.order_id ELSE NULL END)
		AS nonbrand_orders_desk,
	COUNT(DISTINCT CASE WHEN website_sessions.device_type = 'mobile' THEN website_sessions.website_session_id ELSE NULL END) 
		AS nonbrand_sessions_mob,
	COUNT(DISTINCT CASE WHEN website_sessions.device_type = 'mobile' THEN orders.order_id ELSE NULL END)
		AS nonbrand_orders_mob
FROM website_sessions
	LEFT JOIN orders
		ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at < '2013-01-01'
	AND website_sessions.utm_source = 'gsearch'
GROUP BY 1, 2;


/*
4.	I’m worried that one of our more pessimistic board members may be concerned about the large % of traffic from Gsearch. 
Can you pull monthly trends for Gsearch, alongside monthly trends for each of our other channels?
*/ 


/* 
	gsesarch_sess	  bsearch_sess
Jan		#					#
Feb		#					#
Mar		#					#
*/


SELECT
	YEAR(created_at) AS year,
    MONTH(created_at) AS month,
	COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' THEN website_session_id ELSE NULL END) AS gsearch_sessions,
    COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' THEN website_session_id ELSE NULL END) AS bsearch_sessions
FROM website_sessions
WHERE created_at < '2013-01-01'
GROUP BY 1, 2;


/*
5.	I’d like to tell the story of our website performance improvements over the course of the first 8 months. 
Could you pull session to order conversion rates, by month? 
*/ 

SELECT
	YEAR(website_sessions.created_at) AS year,
    MONTH(website_sessions.created_at) AS month,
    COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
    COUNT(DISTINCT orders.order_id) AS orders,
    COUNT(DISTINCT orders.order_id) / COUNT(DISTINCT website_sessions.website_session_id) * 100 AS conv_rate
FROM website_sessions
	LEFT JOIN orders
		ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at < '2013-01-01'
GROUP BY 1, 2









