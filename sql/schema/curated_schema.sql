-- Create a new schema named 'curated_rental_marketplace'.
-- This schema will store data that has been cleaned, transformed, and enriched from the raw layer.
CREATE SCHEMA IF NOT EXISTS curated_rental_marketplace;


-- Create the 'apartments' table within the 'curated_rental_marketplace' schema.
-- This table likely combines and refines general apartment listing information from the raw layer.
CREATE TABLE IF NOT EXISTS curated_rental_marketplace.apartments (
    id BIGINT NOT NULL,
    title VARCHAR(256),
    source VARCHAR(256),
    price DOUBLE PRECISION,
    currency VARCHAR(256),
    listing_created_on DATE,
    is_active BOOLEAN,
    last_modified_timestamp DATE,
    week_year VARCHAR(7),     -- added for weekly KPI calculations 
    month_year VARCHAR(7),    -- added for monthly KPI calculations 
    PRIMARY KEY (id)
);


-- Create the 'apartment_attributes' table within the 'curated_rental_marketplace' schema.
-- This table holds detailed, cleaned attributes for apartments, separate from general listing info.
CREATE TABLE IF NOT EXISTS curated_rental_marketplace.apartment_attributes (
    id BIGINT NOT NULL,
    category VARCHAR(256),
    body VARCHAR(65535),
    amenities VARCHAR(65535),
    bathrooms REAL,
    bedrooms INTEGER,
    fee DOUBLE PRECISION,
    has_photo BOOLEAN,
    pets_allowed BOOLEAN,
    price_display VARCHAR(256), 
    price_type VARCHAR(256),
    square_feet INTEGER,
    address VARCHAR(256),
    cityname VARCHAR(256),
    state VARCHAR(256),
    latitude REAL,
    longitude REAL,
    PRIMARY KEY (id)
);


-- Create the 'user_viewing' table within the 'curated_rental_marketplace' schema.
-- This table tracks user interaction events with apartments, with cleansed data types.
CREATE TABLE IF NOT EXISTS curated_rental_marketplace.user_viewing (
    user_id BIGINT NOT NULL,
    apartment_id BIGINT NOT NULL,
    viewed_at DATE,
    is_wishlisted BOOLEAN,
    call_to_action VARCHAR(256),
    week_year VARCHAR(7),     -- added for weekly engagement tracking
    month_year VARCHAR(7),    -- added for monthly engagement tracking
    PRIMARY KEY (user_id, apartment_id, viewed_at)
);


-- Create the 'bookings' table within the 'curated_rental_marketplace' schema.
-- This table contains cleaned and enriched booking details, including derived metrics.
CREATE TABLE IF NOT EXISTS curated_rental_marketplace.bookings (
    booking_id BIGINT NOT NULL,
    user_id BIGINT,
    apartment_id BIGINT,
    booking_date DATE,
    checkin_date DATE,
    checkout_date DATE,
    total_price DOUBLE PRECISION,
    currency VARCHAR(256),
    booking_status VARCHAR(256),
    booking_duration_days INTEGER,        
    confirmed_revenue DOUBLE PRECISION,   
    week_year VARCHAR(7),                 -- added for weekly performance tracking
    month_year VARCHAR(7),                -- added for monthly performance tracking
    PRIMARY KEY (booking_id)
);