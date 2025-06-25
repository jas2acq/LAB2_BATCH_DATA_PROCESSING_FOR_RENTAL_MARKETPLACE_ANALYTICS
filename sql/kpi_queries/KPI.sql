-- =================================================================
-- RENTAL PERFORMANCE METRICS VIEWS
-- =================================================================

-- 1. Average Listing Price (Weekly)
CREATE OR REPLACE VIEW presentation_rental_marketplace.vw_avg_listing_price_weekly AS
SELECT 
    da.week_year,
    AVG(da.price) as avg_listing_price,
    COUNT(da.apartment_id) as total_active_listings,
    da.currency,
    CURRENT_TIMESTAMP as last_updated
FROM presentation_rental_marketplace.dim_apartment da
WHERE da.is_active = TRUE 
    AND da.price > 0
GROUP BY da.week_year, da.currency
ORDER BY da.week_year DESC;



-- 2. Occupancy Rate (Monthly)
CREATE OR REPLACE VIEW presentation_rental_marketplace.vw_occupancy_rate_monthly AS
WITH available_nights AS (
    -- Calculate total available nights per apartment per month
    SELECT 
        da.apartment_key,
        da.apartment_id,
        da.month_year,
        da.cityname,
        -- Assuming 30 days average per month for available nights
        30 as total_available_nights
    FROM presentation_rental_marketplace.dim_apartment da
    WHERE da.is_active = TRUE
),
booked_nights AS (
    -- Calculate total booked nights per apartment per month
    SELECT 
        fb.apartment_key,
        fb.month_year,
        SUM(fb.booking_duration_days) as total_booked_nights
    FROM presentation_rental_marketplace.fact_bookings fb
    WHERE fb.booking_duration_days > 0
    GROUP BY fb.apartment_key, fb.month_year
)
SELECT 
    an.month_year,
    an.cityname,
    SUM(an.total_available_nights) as total_available_nights,
    COALESCE(SUM(bn.total_booked_nights), 0) as total_booked_nights,
    CASE 
        WHEN SUM(an.total_available_nights) > 0 
        THEN (COALESCE(SUM(bn.total_booked_nights), 0) * 100.0 / SUM(an.total_available_nights))
        ELSE 0 
    END as occupancy_rate_percent,
    COUNT(DISTINCT an.apartment_key) as total_properties,
    CURRENT_TIMESTAMP as last_updated
FROM available_nights an
LEFT JOIN booked_nights bn ON an.apartment_key = bn.apartment_key 
    AND an.month_year = bn.month_year
GROUP BY an.month_year, an.cityname
ORDER BY an.month_year DESC, occupancy_rate_percent DESC;



-- 3. Most Popular Locations (Weekly)
CREATE OR REPLACE VIEW presentation_rental_marketplace.vw_popular_locations_weekly AS
SELECT 
    fb.week_year,
    da.cityname,
    da.state,
    COUNT(fb.booking_id) as total_bookings,
    SUM(fb.confirmed_revenue) as total_revenue,
    AVG(fb.total_price) as avg_booking_price,
    COUNT(DISTINCT fb.user_key) as unique_customers,
    RANK() OVER (PARTITION BY fb.week_year ORDER BY COUNT(fb.booking_id) DESC) as popularity_rank,
    CURRENT_TIMESTAMP as last_updated
FROM presentation_rental_marketplace.fact_bookings fb
JOIN presentation_rental_marketplace.dim_apartment da ON fb.apartment_key = da.apartment_key
WHERE fb.confirmed_revenue > 0
GROUP BY fb.week_year, da.cityname, da.state
ORDER BY fb.week_year DESC, total_bookings DESC;



-- 4. Top Performing Listings (Weekly)
CREATE OR REPLACE VIEW presentation_rental_marketplace.vw_top_performing_listings_weekly AS
SELECT 
    fb.week_year,
    da.apartment_id,
    da.title,
    da.cityname,
    da.state,
    da.price as listing_price,
    COUNT(fb.booking_id) as total_bookings,
    SUM(fb.confirmed_revenue) as weekly_confirmed_revenue,
    AVG(fb.total_price) as avg_booking_value,
    SUM(fb.booking_duration_days) as total_nights_booked,
    RANK() OVER (PARTITION BY fb.week_year ORDER BY SUM(fb.confirmed_revenue) DESC) as revenue_rank,
    CURRENT_TIMESTAMP as last_updated
FROM presentation_rental_marketplace.fact_bookings fb
JOIN presentation_rental_marketplace.dim_apartment da ON fb.apartment_key = da.apartment_key
WHERE fb.confirmed_revenue > 0
GROUP BY fb.week_year, da.apartment_id, da.title, da.cityname, da.state, da.price
ORDER BY fb.week_year DESC, weekly_confirmed_revenue DESC;




-- =================================================================
-- USER ENGAGEMENT METRICS VIEWS
-- =================================================================

-- 5. Total Bookings per User (Weekly)
CREATE OR REPLACE VIEW presentation_rental_marketplace.vw_user_bookings_weekly AS
SELECT 
    fb.week_year,
    fb.user_key,
    du.user_id,
    COUNT(fb.booking_id) as total_bookings,
    SUM(fb.confirmed_revenue) as total_revenue,
    AVG(fb.total_price) as avg_booking_value,
    SUM(fb.booking_duration_days) as total_nights_booked,
    MIN(dd.full_date) as first_booking_date,
    MAX(dd.full_date) as last_booking_date,
    CURRENT_TIMESTAMP as last_updated
FROM presentation_rental_marketplace.fact_bookings fb
JOIN presentation_rental_marketplace.dim_user du ON fb.user_key = du.user_key
JOIN presentation_rental_marketplace.dim_date dd ON fb.booking_date_key = dd.date_key
WHERE fb.confirmed_revenue > 0
GROUP BY fb.week_year, fb.user_key, du.user_id
ORDER BY fb.week_year DESC, total_bookings DESC;



-- 6. Average Booking Duration (Over Time)
CREATE OR REPLACE VIEW presentation_rental_marketplace.vw_avg_booking_duration AS
SELECT 
    fb.week_year,
    fb.month_year,
    AVG(fb.booking_duration_days) as avg_duration_days,
    MEDIAN(fb.booking_duration_days) as median_duration_days,
    COUNT(fb.booking_id) as total_bookings,
    MIN(fb.booking_duration_days) as min_duration_days,
    MAX(fb.booking_duration_days) as max_duration_days,
    STDDEV(fb.booking_duration_days) as duration_stddev,
    -- Duration distribution
    SUM(CASE WHEN fb.booking_duration_days <= 3 THEN 1 ELSE 0 END) as short_stays_1_3_days,
    SUM(CASE WHEN fb.booking_duration_days BETWEEN 4 AND 7 THEN 1 ELSE 0 END) as medium_stays_4_7_days,
    SUM(CASE WHEN fb.booking_duration_days > 7 THEN 1 ELSE 0 END) as long_stays_8plus_days,
    CURRENT_TIMESTAMP as last_updated
FROM presentation_rental_marketplace.fact_bookings fb
WHERE fb.booking_duration_days > 0 
    AND fb.confirmed_revenue > 0
GROUP BY fb.week_year, fb.month_year
ORDER BY fb.week_year DESC;



-- 7. Repeat Customer Rate (Rolling 30 Days)
CREATE OR REPLACE VIEW presentation_rental_marketplace.vw_repeat_customer_rate AS
WITH user_booking_counts AS (
    -- Count bookings per user in rolling 30-day windows
    SELECT 
        dd.full_date as analysis_date,
        fb.user_key,
        du.user_id,
        COUNT(fb.booking_id) as bookings_last_30_days
    FROM presentation_rental_marketplace.dim_date dd
    CROSS JOIN presentation_rental_marketplace.fact_bookings fb
    JOIN presentation_rental_marketplace.dim_user du ON fb.user_key = du.user_key
    JOIN presentation_rental_marketplace.dim_date bd ON fb.booking_date_key = bd.date_key
    WHERE bd.full_date BETWEEN DATEADD(day, -30, dd.full_date) AND dd.full_date
        AND fb.confirmed_revenue > 0
        AND dd.full_date >= DATEADD(day, 30, (SELECT MIN(full_date) FROM presentation_rental_marketplace.dim_date))
    GROUP BY dd.full_date, fb.user_key, du.user_id
),
daily_customer_stats AS (
    SELECT 
        analysis_date,
        COUNT(DISTINCT user_key) as total_active_customers,
        COUNT(DISTINCT CASE WHEN bookings_last_30_days > 1 THEN user_key END) as repeat_customers,
        SUM(bookings_last_30_days) as total_bookings_30_days
    FROM user_booking_counts
    GROUP BY analysis_date
)
SELECT 
    analysis_date,
    total_active_customers,
    repeat_customers,
    total_bookings_30_days,
    CASE 
        WHEN total_active_customers > 0 
        THEN (repeat_customers * 100.0 / total_active_customers)
        ELSE 0 
    END as repeat_customer_rate_percent,
    EXTRACT(week FROM analysis_date) as week_number,
    EXTRACT(year FROM analysis_date) as year,
    CURRENT_TIMESTAMP as last_updated
FROM daily_customer_stats
WHERE total_active_customers > 0
ORDER BY analysis_date DESC;




-- =================================================================
-- SUMMARY DASHBOARD VIEW
-- =================================================================

-- 8. Executive Summary Dashboard (Weekly)
CREATE OR REPLACE VIEW presentation_rental_marketplace.vw_executive_summary_weekly AS
WITH weekly_metrics AS (
    SELECT 
        week_year,
        COUNT(DISTINCT apartment_key) as active_listings,
        COUNT(booking_id) as total_bookings,
        SUM(confirmed_revenue) as total_revenue,
        AVG(total_price) as avg_booking_value,
        SUM(booking_duration_days) as total_nights_booked,
        COUNT(DISTINCT user_key) as unique_customers
    FROM presentation_rental_marketplace.fact_bookings
    WHERE confirmed_revenue > 0
    GROUP BY week_year
)
SELECT 
    wm.week_year,
    wm.active_listings,
    wm.total_bookings,
    wm.total_revenue,
    wm.avg_booking_value,
    wm.total_nights_booked,
    wm.unique_customers,
    CASE 
        WHEN wm.active_listings > 0 
        THEN (wm.total_bookings * 100.0 / wm.active_listings)
        ELSE 0 
    END as booking_rate_percent,
    CASE 
        WHEN wm.total_bookings > 0 
        THEN (wm.total_revenue / wm.total_bookings)
        ELSE 0 
    END as revenue_per_booking,
    -- Week-over-week growth calculations
    LAG(wm.total_revenue) OVER (ORDER BY wm.week_year) as prev_week_revenue,
    CASE 
        WHEN LAG(wm.total_revenue) OVER (ORDER BY wm.week_year) > 0
        THEN ((wm.total_revenue - LAG(wm.total_revenue) OVER (ORDER BY wm.week_year)) * 100.0 / 
              LAG(wm.total_revenue) OVER (ORDER BY wm.week_year))
        ELSE 0
    END as revenue_growth_percent,
    CURRENT_TIMESTAMP as last_updated
FROM weekly_metrics wm
ORDER BY wm.week_year DESC;