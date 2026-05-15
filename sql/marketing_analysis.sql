SELECT *
FROM marketing
LIMIT 10;

-- Channel/Campaign (input) -> spend (input) -> impressions (visibility) -> clicks (attention) -> leads (interest) -> orders (conversions) -> revenue (value output)

SELECT COUNT(*) FROM marketing;

DESCRIBE marketing;

SHOW CREATE TABLE marketing;

SELECT COUNT(*), COUNT(DISTINCT id) FROM marketing; 


-- DATA VALIDATION

-- Checking inconsistencies
SELECT DISTINCT(campaign_name)
FROM marketing;
SELECT DISTINCT(campaign_id)
FROM marketing;
SELECT DISTINCT(category)
FROM marketing;
SELECT DISTINCT(c_date)
FROM marketing;

SELECT campaign_id, COUNT(DISTINCT campaign_name)
FROM marketing
GROUP BY campaign_id
HAVING COUNT(DISTINCT campaign_name) > 1; -- Checking if there are multiple campaign names under a single campaign id

-- Checking missing values
SELECT SUM(CASE WHEN impressions IS NULL THEN 1 ELSE 0 END) AS missing_impressions,
SUM(CASE WHEN clicks IS NULL THEN 1 ELSE 0 END) AS missing_clicks,
SUM(CASE WHEN leads IS NULL THEN 1 ELSE 0 END) AS missing_leads,
SUM(CASE WHEN orders IS NULL THEN 1 ELSE 0 END) AS missing_orders,
SUM(CASE WHEN mark_spent IS NULL THEN 1 ELSE 0 END) AS missing_mark_spent,
SUM(CASE WHEN revenue IS NULL THEN 1 ELSE 0 END) AS missing_revenue
FROM marketing;

SELECT *
FROM marketing
WHERE impressions = 0
OR clicks = 0
OR leads = 0
OR orders = 0; -- The zeros exist in leads, orders, revenue which make sense considering a user interaction or behavior flow

-- Logical or numerical relationships
SELECT *
FROM marketing
WHERE orders = 0
AND revenue != 0; -- Order should produce revenue

SELECT *
FROM marketing
WHERE (mark_spent > 0 AND impressions = 0) OR (impressions > 0 AND mark_spent = 0); -- Spend should produce impression even at minimum

SELECT *
FROM marketing
WHERE (clicks > impressions) OR (leads > clicks) OR (orders > leads); -- interaction or behavior flow -> impressions -> clicks -> leads -> orders

-- Value ranges (basline ranges to understand overall spread of each variable)
SELECT MIN(mark_spent), MAX(mark_spent)
FROM marketing; -- MIN(169.75) MAX(880357) This is heavily skewed but in the context of money spent on marketing campaigns it is mainly based on different scale or volume and type of campaign they use
SELECT MIN(revenue), MAX(revenue)
FROM marketing; -- MIN(0) MAX(2812520)
SELECT MIN(orders), MAX(orders)
FROM marketing; -- MIN(0) MAX(369)
SELECT MIN(impressions), MAX(impressions)
FROM marketing; -- MIN(667) MAX(419970000)
SELECT MIN(clicks), MAX(clicks)
FROM marketing; -- MIN(20) MAX(61195)
SELECT MIN(leads), MAX(leads)
FROM marketing; -- MIN(0) MAX(1678)
-- Wide ranges across all variables cause are the result of each stage before them (spent -> impressions -> clicks -> leads -> orders -> revenue)

-- Checking if the ranges are valid and not extreme (to see the distibution of the variables)
SELECT AVG(mark_spent), MAX(mark_spent)
FROM marketing; -- AVG(~99321) MAX(880357)
SELECT AVG(revenue), MAX(revenue)
FROM marketing; -- AVG(~139251) MAX(2812520)
SELECT AVG(impressions), MAX(impressions)
FROM marketing; -- AVG(~5122475) MAX(419970000)
SELECT AVG(clicks), MAX(clicks) 
FROM marketing; -- AVG(~9739) MAX(61195)
-- Average is way less or too far away than the maximum values, for not just one but all of these variables, considering the marketing campaigns run on different level of scales

-- Checking if there are unusally high returns 
SELECT *
FROM marketing
WHERE revenue > 10 * mark_spent;

-- Checking boundaries of the variables to spot any outliers if there are any
SELECT mark_spent
FROM marketing
ORDER BY mark_spent ASC
LIMIT 10;

SELECT revenue
FROM marketing
ORDER BY revenue DESC
LIMIT 10;

SELECT impressions
FROM marketing
ORDER BY impressions DESC
LIMIT 10;

SELECT clicks
FROM marketing
ORDER BY clicks DESC
LIMIT 10;
-- There weren't any sharp increase or decrease at once in the variables which confirms the campaigns are at different scales

-- system operates at mulitple scales -> campaigns vary in activity size (volume), they have different level of volume or scale for each campaign (not campaign type but a campaign individual scope they aim for each time)

-- METRICS CALCULATION

-- Attention metric or Click through rate (CTR)
SELECT SUM(clicks)/SUM(impressions) AS click_through_rate
FROM marketing; -- 0.0019 ~0.19% impressions -> clicks is extremely low that means most people don't click through impressions (visibility)
-- Might indicate either the visibility is low or the visibility is not effective enough

-- Interest metric or lead rate
SELECT SUM(leads)/SUM(clicks) AS lead_rate
FROM marketing; -- 0.0219 ~2.19% Even after clicking, very few become leads or show interest 
-- Might indicate if the channel or scale or aren't interested either irrelevant or not effective

-- Conversion metric or Conversion rate
SELECT SUM(orders)/SUM(leads) AS conversation_rate
FROM marketing; -- 0.1226 ~12.26% compared to earlier stages, decent amount people are converting

-- Spend per conversion or cost per acquisition (CPA)
SELECT SUM(mark_spent)/SUM(orders) AS cost_per_acquisition
FROM marketing; -- 3803.41661... 

-- Value per conversion or returns per order OR Average order value (AOV)
SELECT SUM(revenue)/SUM(orders) AS value_per_conversion
FROM marketing; -- 5332.5085...

-- 5332 - 3803 =~ +1500 per order which means each conversion is profitable

-- Return on investment (ROI)
SELECT (SUM(revenue)-SUM(mark_spent))/SUM(mark_spent) AS return_on_investment
FROM marketing; -- 0.402031... ~40%
-- ROI is positive 40% which means who convert are valuable enough even through the initial inefficiency 

-- ANALYSIS 
-- While impressions -> clicks -> leads -> orders are dependent or influenced by each other, the spent is the main input to analyze the behavior through scale
-- impressions (visibility or audience) depend on spent, campaign type, channel, scope. Clicks, leads, orders are dependent the user behavior, revenue is the outcomes of all these.
-- spent and campaign/category are the two main inputs for this data

SELECT spend_bucket, COUNT(*) AS bucket_count
FROM (SELECT CASE WHEN mark_spent < 50000 THEN 'low'
WHEN mark_spent < 150000 THEN 'mid'
WHEN mark_spent < 400000 THEN 'high'
ELSE 'very high'
END AS spend_bucket 
FROM marketing) t
GROUP BY spend_bucket
ORDER BY spend_bucket;
-- Most data points are at lower spend levels, but the higher spend range is much more spread out.
-- So I used finer grouping at the high end to capture meaningful differences in scale, instead of splitting the low end where values are more similar.
-- volume tells you how much data there is. spread tells you where differences exist. you split based on spread, not volume
-- Low side -> many rows, but values are relatively close, so less need to split further cause differences are small in spread or magnitude
-- High side -> fewer rows, but values are very far apart, more need to split, differences are large in magnitude or spread

-- Comparing different metrics to the different spend buckets
SELECT spend_bucket, COUNT(*) AS bucket_count, 
SUM(clicks)/SUM(impressions) AS click_through_rate,
SUM(leads)/SUM(clicks) AS lead_rate,
SUM(orders)/SUM(leads) AS conversion_rate,
SUM(mark_spent)/SUM(orders) AS cost_per_acquisition,
SUM(revenue)/SUM(orders) AS avg_order_value,
(SUM(revenue)-SUM(mark_spent))/SUM(mark_spent) AS roi
FROM (SELECT *, CASE WHEN mark_spent < 50000 THEN 'low'
WHEN mark_spent < 150000 THEN 'mid'
WHEN mark_spent < 400000 THEN 'high'
ELSE 'very high'
END AS spend_bucket
FROM marketing) t
GROUP BY spend_bucket
ORDER BY spend_bucket;
-- The efficiency improves with scale, particularly in lead and conversion stages, while ctr show more variability
-- Top of the funnel -> CTR (a dip in high spend_bucket), Middle of the funnel -> lead_rate or conversion_rate improves with scale, ROI does not cleanly follow the scale 
-- conversion improves more reliably than attention

SELECT campaign_name, spend_bucket, COUNT(*) AS bucket_count, 
SUM(clicks)/SUM(impressions) AS click_through_rate,
SUM(leads)/SUM(clicks) AS lead_rate,
SUM(orders)/SUM(leads) AS conversion_rate,
SUM(mark_spent)/SUM(orders) AS cost_per_acquisition,
SUM(revenue)/SUM(orders) AS avg_order_value,
(SUM(revenue)-SUM(mark_spent))/SUM(mark_spent) AS roi
FROM (SELECT *, CASE WHEN mark_spent < 50000 THEN 'low'
WHEN mark_spent < 150000 THEN 'mid'
WHEN mark_spent < 400000 THEN 'high'
ELSE 'very high'
END AS spend_bucket
FROM marketing) t
GROUP BY campaign_name, spend_bucket
ORDER BY campaign_name, spend_bucket;   
-- youtube_blogger, instagram_tier1, facebook_retargeting have consistently very high ROI because the cost per conversion is low and value per conversion is high, low cost + high value = strong profit
-- google_hot, instagram_blogger have moderate performance where cpa or cost per conversion is low and value per conversion or aov is high (CPA < AOV), roi is positive but still moderate
-- banner_partner have low performance where roi is positive but cpa and aov are close to each other so it gives stable but weak profit
-- facebook_lal, facebook_tier1, facebOOK_tier2, google_wide, instagram_tier2 have weak performance where cpa is high, aov is low or moderate, roi is consistently negative
-- This variation is driven by differences in cost per acquisition and value per order, rather than funnel behavior itself

-- While increasing spend improves funnel efficiency across campaigns, profitability varies significantly by campaign
-- Increasing spend improves how efficiently users move through the funnel (from attention to conversion), but it does not gurantee better profitability (cause it depends on cpa and aov)
-- Scale improves efficiency, but campaign determines whether that efficiency turns into profit or not

-- Just for my reference to notice the differences
SELECT category, spend_bucket, COUNT(*) AS bucket_count, 
SUM(clicks)/SUM(impressions) AS click_through_rate,
SUM(leads)/SUM(clicks) AS lead_rate,
SUM(orders)/SUM(leads) AS conversion_rate,
SUM(mark_spent)/SUM(orders) AS cost_per_acquisition,
SUM(revenue)/SUM(orders) AS avg_order_value,
(SUM(revenue)-SUM(mark_spent))/SUM(mark_spent) AS roi
FROM (SELECT *, CASE WHEN mark_spent < 50000 THEN 'low'
WHEN mark_spent < 150000 THEN 'mid'
WHEN mark_spent < 400000 THEN 'high'
ELSE 'very high'
END AS spend_bucket
FROM marketing) t
GROUP BY category, spend_bucket
ORDER BY category, spend_bucket;   

SELECT campaign_name, SUM(mark_spent)/SUM(orders) AS cost_per_acquisition,
SUM(revenue)/SUM(orders) AS avg_order_value
FROM marketing
GROUP BY campaign_name;