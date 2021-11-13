USE mavenfuzzyfactory;

/* --------------------------------------------------------------------------------------------------------------------------------------------- */

-- COUNT THE NUMBER OF REPEAT USERS.

-- STEP 1: gather all data relevant from Jan. 1 2014 to Nov. 1 2014
-- STEP 2: gather data pertaining to customers who has repeat sessions and no repeat sessions
-- STEP 3: count the number of sessions for each user_id
-- STEP 4: categorize the number of repeat sessions as the dimension and count how many users fall within each number of session

SELECT 
	created_at,
	website_session_id,
    user_id,
    is_repeat_session
FROM website_sessions
	WHERE created_at >= '2014-01-01'
		AND created_at <= '2014-11-01';

DROP TEMPORARY TABLE count_of_sessions_per_user;
CREATE TEMPORARY TABLE count_of_sessions_per_user
SELECT 
	user_id,
	COUNT(DISTINCT website_session_id) AS num_of_sessions
FROM (SELECT 
	created_at,
	website_session_id,
    user_id,
    is_repeat_session
FROM website_sessions
	WHERE created_at >= '2014-01-01'
		AND created_at <= '2014-11-01') AS customers
GROUP BY user_id;

-- SELECT * FROM count_of_sessions_per_user;

SELECT
	num_of_sessions,
    COUNT(user_id) AS users
FROM count_of_sessions_per_user
GROUP BY 1;

/* --------------------------------------------------------------------------------------------------------------------------------------------- */

-- FIND THE MINIMUM, MAXIMUM, AND AVERAGE TIME BETWEEN THE FIRST AND SECOND SESSION

-- STEP 1: restrict data from Jan. 01, 2014 to Nov. 3, 2014
-- STEP 2: figure out the users with multiple sessions (more than one) and what their next session were
-- STEP 3: what are their first date from their first session and their second date from their second session
-- STEP 4: find the min, max, and average from the time difference 

-- STEP 1: restrict data from Jan. 01, 2014 to Nov. 3, 2014
SELECT 
	created_at,
    website_session_id,
    user_id,
    is_repeat_session
FROM website_sessions
WHERE created_at >= '2014-01-01'
	AND created_at < '2014-11-03';


-- STEP 2: figure out the users with multiple sessions (more than one) and what their next session were
DROP TEMPORARY TABLE next_session;    
CREATE TEMPORARY TABLE next_session    
SELECT
    first_session.user_id,
    first_session.website_session_id AS first_session,
    MIN(website_sessions.website_session_id) AS next_session
FROM (SELECT 
	created_at,
    website_session_id,
    user_id,
    is_repeat_session
FROM website_sessions
WHERE created_at >= '2014-01-01'
	AND created_at < '2014-11-03') AS first_session
	LEFT JOIN website_sessions
		ON website_sessions.user_id = first_session.user_id
        AND website_sessions.website_session_id > first_session.website_session_id -- next session
        AND website_sessions.is_repeat_session = 1
WHERE first_session.is_repeat_session = 0 -- new session only
GROUP BY 1, 2;

-- STEP 3: what are their first date from their first session and their second date from their second session (second date)
CREATE TEMPORARY TABLE sessions_w_nxt_date
SELECT
	next_session.user_id,
    next_session.first_session,
    next_session.next_session,
    website_sessions.created_at AS next_date
FROM next_session 
	LEFT JOIN website_sessions
		ON website_sessions.website_session_id = next_session.next_session;
        
-- STEP 3: what are their first date from their first session and their second date from their second session (first date)
CREATE TEMPORARY TABLE users_w_first_second_sessions
SELECT
	sessions_w_nxt_date.user_id,
    sessions_w_nxt_date.first_session,
    sessions_w_nxt_date.next_session,
    sessions_w_nxt_date.next_date AS next_date,
    website_sessions.created_at AS first_date,
    DATEDIFF(sessions_w_nxt_date.next_date, website_sessions.created_at) AS datediff
FROM sessions_w_nxt_date
	LEFT JOIN website_sessions
		ON website_sessions.website_session_id = sessions_w_nxt_date.first_session;

-- STEP 4: find the min, max, and average from the time difference         
SELECT
	MIN(datediff) AS min_first_to_second,
    MAX(datediff) AS max_first_to_second,
    AVG(datediff) AS avg_first_to_second
FROM users_w_first_second_sessions;

/* --------------------------------------------------------------------------------------------------------------------------------------------- */

-- COMPARING NEW VS. REPEAT SESSIONS BY CHANNEL
-- COUNT THE NUMBER OF NEW SESSIONS AND REPEAT SESSIONS BY CHANNEL GROUP (ORGRANIC SEARCH, PAID BRAND, DIRECT TYPE IN, PAID NONBRAND,
-- & PAID SOCIAL

-- STEP 1: Identify the channel group/traffic sources
-- STEP 2: count the number of sessions grouped by each channel group

-- SELECT DISTINCT
-- 	utm_source,
--     utm_campaign,
--     utm_content,
--     http_referer
-- FROM website_sessions
-- ORDER BY utm_source DESC;

-- STEP 1: Identify the channel group/traffic sources
DROP TEMPORARY TABLE channel_group;
CREATE TEMPORARY TABLE channel_group
SELECT
	website_session_id,
    utm_source,
    utm_campaign,
    http_referer,
    CASE WHEN http_referer IS NOT NULL AND utm_source IS NULL THEN 'organic'
		 WHEN utm_source IS NOT NULL AND utm_campaign = 'brand' THEN 'paid brand'
         WHEN utm_source IS NULL AND utm_campaign IS NULL AND utm_content IS NULL AND http_referer IS NULL THEN 'direct type in'
         WHEN utm_source IS NOT NULL AND utm_campaign = 'nonbrand' THEN 'paid nonbrand'
         WHEN utm_source = 'socialbook' THEN 'paid social'
		 ELSE NULL
    END AS channel_group
FROM (SELECT
	created_at,
	website_session_id,
    utm_source,
    utm_content,
    utm_campaign,
    http_referer
FROM website_sessions
WHERE created_at >= '2014-01-01'
	AND created_at < '2014-11-05') AS traffic_sources;
    
-- STEP 2: count the number of sessions grouped by each channel group    
SELECT
	channel_group.channel_group,
	COUNT(DISTINCT CASE WHEN website_sessions.is_repeat_session = 0 THEN channel_group.website_session_id ELSE NULL END) AS new_sessions,
    COUNT(DISTINCT CASE WHEN website_sessions.is_repeat_session = 1 THEN channel_group.website_session_id ELSE NULL END) AS repeat_sessions
FROM channel_group
	LEFT JOIN website_sessions
		ON website_sessions.website_session_id = channel_group.website_session_id
GROUP BY 1;

/* --------------------------------------------------------------------------------------------------------------------------------------------- */

-- COMPARISION OF CONVERSION RATES AND REVENUE PER SESSION FOR REPEAT SESSIONS VS NEW SESSIONS FOR Jan. 01, 2014 to Nov. 08, 2014

-- STEP 1: Identify new and repeat sessions within Jan. 01, 2014 to Nov. 08, 2014
-- STEP 2: Count the number of sessions, conversion rate (orders / sessions), and revenue per session sum of price / session

-- SELECT * FROM website_sessions;
-- SELECT * FROM orders;

-- STEP 1: Identify new and repeat sessions within Jan. 01, 2014 to Nov. 08, 2014
SELECT
	website_sessions.website_session_id,
    website_sessions.is_repeat_session,
    orders.order_id,
    orders.price_usd,
    orders.cogs_usd
FROM website_sessions
	LEFT JOIN orders
		ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at >= '2014-01-01'
	AND website_sessions.created_at < '2014-11-08';


-- STEP 2: Count the number of sessions, conversion rate (orders / sessions), and revenue per session sum of price / session
    
SELECT
	is_repeat_session,
    COUNT(DISTINCT website_session_id) AS sessions,
    COUNT(DISTINCT order_id) / COUNT(DISTINCT website_session_id) AS conv_rate,
    ROUND(SUM(price_usd) / COUNT(DISTINCT website_session_id), 2) AS rev_per_session
FROM (SELECT
	website_sessions.website_session_id,
    website_sessions.is_repeat_session,
    orders.order_id,
    orders.price_usd,
    orders.cogs_usd
FROM website_sessions
	LEFT JOIN orders
		ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at >= '2014-01-01'
	AND website_sessions.created_at < '2014-11-08') AS sessions_w_orders
GROUP BY is_repeat_session

/* --------------------------------------------------------------------------------------------------------------------------------------------- */

	
