-- Query 1: Get distinct user IDs (for dim_user table)
-- This query extracts all unique user IDs from both the user viewing and bookings tables
-- in the curated layer to populate the 'dim_user' dimension table in the presentation layer.
-- This ensures that all users who have either viewed apartments or made bookings are included.
SELECT DISTINCT user_id
FROM (
    SELECT user_id FROM curated_rental_marketplace.user_viewing WHERE user_id IS NOT NULL
    UNION
    SELECT user_id FROM curated_rental_marketplace.bookings WHERE user_id IS NOT NULL
) AS distinct_users;




-- Query 2: Get apartment data with attributes (for dim_apartment table)
-- This query combines apartment listing details with their static attributes
-- from the curated layer to create a comprehensive 'dim_apartment' dimension table
-- in the presentation layer. This denormalization simplifies future analytical queries.
SELECT
    a.id AS apartment_id,
    a.title,
    a.source,
    a.price,
    a.currency,
    a.listing_created_on,
    a.is_active,
    a.last_modified_timestamp,
    a.week_year,
    a.month_year,
    aa.category,
    aa.body,
    aa.amenities,
    aa.bathrooms,
    aa.bedrooms,
    aa.fee,
    aa.has_photo,
    aa.pets_allowed,
    aa.price_display,
    aa.price_type,
    aa.square_feet,
    aa.address,
    aa.cityname,
    aa.state,
    aa.latitude,
    aa.longitude
FROM
    curated_rental_marketplace.apartments AS a
LEFT JOIN
    curated_rental_marketplace.apartment_attributes AS aa ON a.id = aa.id;




-- Query 3: Get distinct booking statuses (for dim_booking_status table)
-- This query extracts all unique booking statuses from the 'bookings' table
-- in the curated layer to populate the 'dim_booking_status' dimension table.
-- This ensures that all possible booking status values are captured for analysis.
SELECT DISTINCT booking_status AS booking_status_name
FROM curated_rental_marketplace.bookings
WHERE booking_status IS NOT NULL;




-- Query 4: Generate date dimension data (for dim_date table)
-- This query extracts distinct dates from various timestamp columns in the curated layer.
-- It computes various date attributes (day, week, month, year, etc.) for analytical purposes.
SELECT DISTINCT
    (EXTRACT(YEAR FROM d.full_date) * 10000 + 
     EXTRACT(MONTH FROM d.full_date) * 100 + 
     EXTRACT(DAY FROM d.full_date))::INTEGER AS date_key,
    d.full_date,
    EXTRACT(DOW FROM d.full_date)::INTEGER AS day_of_week,
    CASE EXTRACT(DOW FROM d.full_date)
        WHEN 0 THEN 'Sunday'
        WHEN 1 THEN 'Monday'
        WHEN 2 THEN 'Tuesday'
        WHEN 3 THEN 'Wednesday'
        WHEN 4 THEN 'Thursday'
        WHEN 5 THEN 'Friday'
        WHEN 6 THEN 'Saturday'
    END AS day_name,
    EXTRACT(DAY FROM d.full_date)::INTEGER AS day_of_month,
    EXTRACT(DOY FROM d.full_date)::INTEGER AS day_of_year,
    EXTRACT(WEEK FROM d.full_date)::INTEGER AS week_of_year,
    EXTRACT(MONTH FROM d.full_date)::INTEGER AS month,
    CASE EXTRACT(MONTH FROM d.full_date)
        WHEN 1 THEN 'January'
        WHEN 2 THEN 'February'
        WHEN 3 THEN 'March'
        WHEN 4 THEN 'April'
        WHEN 5 THEN 'May'
        WHEN 6 THEN 'June'
        WHEN 7 THEN 'July'
        WHEN 8 THEN 'August'
        WHEN 9 THEN 'September'
        WHEN 10 THEN 'October'
        WHEN 11 THEN 'November'
        WHEN 12 THEN 'December'
    END AS month_name,
    EXTRACT(QUARTER FROM d.full_date)::INTEGER AS quarter,
    EXTRACT(YEAR FROM d.full_date)::INTEGER AS year,
    EXTRACT(YEAR FROM d.full_date)::VARCHAR || '-' || 
    LPAD(EXTRACT(WEEK FROM d.full_date)::VARCHAR, 2, '0') AS week_year,
    EXTRACT(YEAR FROM d.full_date)::VARCHAR || '-' || 
    LPAD(EXTRACT(MONTH FROM d.full_date)::VARCHAR, 2, '0') AS month_year
FROM (
    SELECT booking_date::DATE AS full_date FROM curated_rental_marketplace.bookings WHERE booking_date IS NOT NULL
    UNION
    SELECT checkin_date::DATE AS full_date FROM curated_rental_marketplace.bookings WHERE checkin_date IS NOT NULL
    UNION
    SELECT checkout_date::DATE AS full_date FROM curated_rental_marketplace.bookings WHERE checkout_date IS NOT NULL
    UNION
    SELECT viewed_at::DATE AS full_date FROM curated_rental_marketplace.user_viewing WHERE viewed_at IS NOT NULL
) d
ORDER BY date_key;




-- Query 5: Populate fact_bookings table
-- This query populates the 'fact_bookings' table in the presentation layer
-- by joining data from the curated 'bookings' table with the relevant
-- dimension tables (dim_apartment, dim_user, dim_date, dim_booking_status)
-- using their respective natural and surrogate keys.
SELECT 
    b.booking_id,
    da.apartment_key,
    du.user_key,
    dd_booking.date_key AS booking_date_key,
    dd_checkin.date_key AS checkin_date_key,
    dd_checkout.date_key AS checkout_date_key,
    dbs.booking_status_key,
    b.total_price,
    b.currency,
    b.booking_duration_days,
    b.confirmed_revenue,
    b.week_year,
    b.month_year
FROM curated_rental_marketplace.bookings b
-- Join to get apartment_key
INNER JOIN presentation_rental_marketplace.dim_apartment da 
    ON b.apartment_id = da.apartment_id
-- Join to get user_key
INNER JOIN presentation_rental_marketplace.dim_user du 
    ON b.user_id = du.user_id
-- Join to get booking_date_key
INNER JOIN presentation_rental_marketplace.dim_date dd_booking 
    ON dd_booking.date_key = (EXTRACT(YEAR FROM b.booking_date) * 10000 + 
                              EXTRACT(MONTH FROM b.booking_date) * 100 + 
                              EXTRACT(DAY FROM b.booking_date))
-- Left join for checkin_date_key (optional)
LEFT JOIN presentation_rental_marketplace.dim_date dd_checkin 
    ON dd_checkin.date_key = (EXTRACT(YEAR FROM b.checkin_date) * 10000 + 
                              EXTRACT(MONTH FROM b.checkin_date) * 100 + 
                              EXTRACT(DAY FROM b.checkin_date))
-- Left join for checkout_date_key (optional)
LEFT JOIN presentation_rental_marketplace.dim_date dd_checkout 
    ON dd_checkout.date_key = (EXTRACT(YEAR FROM b.checkout_date) * 10000 + 
                               EXTRACT(MONTH FROM b.checkout_date) * 100 + 
                               EXTRACT(DAY FROM b.checkout_date))
-- Left join for booking_status_key (optional)
LEFT JOIN presentation_rental_marketplace.dim_booking_status dbs 
    ON b.booking_status = dbs.booking_status_name
WHERE b.booking_id IS NOT NULL
  AND b.apartment_id IS NOT NULL
  AND b.user_id IS NOT NULL
  AND b.booking_date IS NOT NULL;




-- Query 6: Populate fact_user_viewings table
-- This query populates the 'fact_user_viewings' table in the presentation layer
-- by joining data from the curated 'user_viewing' table with the relevant
-- dimension tables (dim_apartment, dim_user, dim_date).
-- It's used for analyzing user engagement metrics.
SELECT 
    uv.user_id,
    uv.apartment_id,
    dd.date_key AS viewing_date_key,
    da.apartment_key,
    du.user_key,
    uv.is_wishlisted,
    uv.call_to_action,
    uv.week_year,
    uv.month_year
FROM curated_rental_marketplace.user_viewing uv
-- Join to get apartment_key
INNER JOIN presentation_rental_marketplace.dim_apartment da 
    ON uv.apartment_id = da.apartment_id
-- Join to get user_key
INNER JOIN presentation_rental_marketplace.dim_user du 
    ON uv.user_id = du.user_id
-- Join to get viewing_date_key
INNER JOIN presentation_rental_marketplace.dim_date dd 
    ON dd.date_key = (EXTRACT(YEAR FROM uv.viewed_at) * 10000 + 
                      EXTRACT(MONTH FROM uv.viewed_at) * 100 + 
                      EXTRACT(DAY FROM uv.viewed_at))
WHERE uv.user_id IS NOT NULL
  AND uv.apartment_id IS NOT NULL
  AND uv.viewed_at IS NOT NULL;