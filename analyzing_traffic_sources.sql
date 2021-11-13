-- ANALYZING TRAFFIC SOURCES

USE mavenfuzzyfactory;

-- Finding Top Traffic Sources
-- Where are all the bulk of traffic is comiong from?

SELECT 
	utm_source,
    utm_campaign,
    http_referer,
    COUNT(DISTINCT website_session_id) AS sessions
FROM website_sessions
WHERE created_at <= '2012-04-12'
GROUP BY 1, 2, 3
ORDER BY 4 DESC;


-- Calculate the the conversion rate from session to order for gsearch nonbrand.

SELECT
	COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
    COUNT(DISTINCT orders.order_id) AS orders,
    COUNT(DISTINCT orders.order_id) / COUNT(DISTINCT website_sessions.website_session_id) * 100 AS conv_rate
FROM website_sessions
	LEFT JOIN orders
		ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at <= '2012-04-14'
	AND website_sessions.utm_source = 'gsearch'
    AND website_sessions.utm_campaign = 'nonbrand';
    
-- gsearch nonbrand trended volume by week start
SELECT
	MIN(DATE(created_at)) AS week_start,
    COUNT(DISTINCT website_session_id) AS sessions
FROM website_sessions
WHERE created_at <= '2012-05-10'
	AND utm_source = 'gsearch'
    AND utm_campaign = 'nonbrand'
GROUP BY WEEK(created_at);

-- Weekly trends for Desktop and Mobile devices for gsearch nonbrand volume until 2012-06-09

SELECT
	MIN(DATE(created_at)) AS start_wk,
	COUNT(DISTINCT CASE WHEN device_type = 'desktop' THEN website_session_id ELSE NULL END) AS desktop_sessions,
    COUNT(DISTINCT CASE WHEN device_type = 'mobile' THEN website_session_id ELSE NULL END) AS mobile_sessions
FROM website_sessions
WHERE created_at <= '2012-06-09'
GROUP BY WEEK(created_at);

        


