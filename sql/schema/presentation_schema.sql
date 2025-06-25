-- Create a new schema named 'presentation_rental_marketplace'.
-- This schema contains highly aggregated and denormalized tables,
-- optimized for specific business intelligence dashboards and reports.
CREATE SCHEMA IF NOT EXISTS presentation_rental_marketplace;



-- Dimension Table: dim_date
-- This table stores date-related attributes, serving as a time dimension for analytical queries.
-- It helps in slicing and dicing data by various time granularities (day, week, month, quarter, year).
CREATE TABLE IF NOT EXISTS presentation_rental_marketplace.dim_date (
    date_key INTEGER PRIMARY KEY, -- Format: YYYYMMDD
    full_date DATE NOT NULL,
    day_of_week INTEGER,
    day_name VARCHAR(10),
    day_of_month INTEGER,
    day_of_year INTEGER,
    week_of_year INTEGER,
    month INTEGER,
    month_name VARCHAR(10),
    quarter INTEGER,
    year INTEGER,
    week_year VARCHAR(7),     -- For weekly KPI calculations
    month_year VARCHAR(7)     -- For monthly KPI calculations
);



-- Dimension Table: dim_user
-- This table stores unique user information, acting as a user dimension.
-- It holds unique identifiers for users, ensuring consistency across facts.
CREATE TABLE IF NOT EXISTS presentation_rental_marketplace.dim_user (
    user_key BIGINT IDENTITY(1,1) PRIMARY KEY, -- Surrogate Key
    user_id BIGINT NOT NULL UNIQUE -- Natural Key from source
);




-- Dimension Table: dim_apartment
-- This table combines and stores comprehensive attributes related to apartments,
-- acting as an apartment dimension. It denormalizes data from both
-- `curated_rental_marketplace.apartments` and `curated_rental_marketplace.apartment_attributes`.
CREATE TABLE IF NOT EXISTS presentation_rental_marketplace.dim_apartment (
    apartment_key BIGINT IDENTITY(1,1) PRIMARY KEY, -- Surrogate Key
    apartment_id BIGINT NOT NULL UNIQUE, -- Natural Key from source
    title VARCHAR(256),
    source VARCHAR(256),
    price DOUBLE PRECISION,
    currency VARCHAR(256),
    listing_created_on DATE,
    is_active BOOLEAN,
    last_modified_timestamp DATE,
    week_year VARCHAR(7),     -- For weekly KPI calculations
    month_year VARCHAR(7),    -- For monthly KPI calculations
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
    longitude REAL
);




-- Dimension Table: dim_booking_status
-- This table stores unique booking statuses, serving as a small lookup dimension.
CREATE TABLE IF NOT EXISTS presentation_rental_marketplace.dim_booking_status (
    booking_status_key INTEGER IDENTITY(1,1) PRIMARY KEY, -- Surrogate Key
    booking_status_name VARCHAR(256) NOT NULL UNIQUE -- Natural Key from source
);




-- Fact Table: fact_bookings
-- This is a core fact table storing measures and foreign keys related to individual booking events.
-- It's designed for analyzing booking performance and details, linking to relevant dimensions.
CREATE TABLE IF NOT EXISTS presentation_rental_marketplace.fact_bookings (
    booking_sk BIGINT IDENTITY(1,1) PRIMARY KEY, -- Surrogate Key for the fact record
    booking_id BIGINT NOT NULL UNIQUE, -- Natural Key from source
    apartment_key BIGINT NOT NULL REFERENCES presentation_rental_marketplace.dim_apartment(apartment_key),
    user_key BIGINT NOT NULL REFERENCES presentation_rental_marketplace.dim_user(user_key),
    booking_date_key INTEGER NOT NULL REFERENCES presentation_rental_marketplace.dim_date(date_key),
    checkin_date_key INTEGER REFERENCES presentation_rental_marketplace.dim_date(date_key),
    checkout_date_key INTEGER REFERENCES presentation_rental_marketplace.dim_date(date_key),
    booking_status_key INTEGER REFERENCES presentation_rental_marketplace.dim_booking_status(booking_status_key),
    total_price DOUBLE PRECISION,
    currency VARCHAR(256),
    booking_duration_days INTEGER,
    confirmed_revenue DOUBLE PRECISION,
    week_year VARCHAR(7),
    month_year VARCHAR(7)
);




-- Fact Table: fact_user_viewings
-- This fact table stores measures and foreign keys related to user viewing events of apartments.
-- It's used for analyzing user engagement and interaction patterns.
CREATE TABLE IF NOT EXISTS presentation_rental_marketplace.fact_user_viewings (
    user_viewing_sk BIGINT IDENTITY(1,1) PRIMARY KEY, -- Surrogate Key for the fact record
    -- Keeping natural keys for clarity/auditing, though joins are via surrogate keys
    user_id BIGINT NOT NULL,
    apartment_id BIGINT NOT NULL,
    viewing_date_key INTEGER NOT NULL REFERENCES presentation_rental_marketplace.dim_date(date_key),
    apartment_key BIGINT NOT NULL REFERENCES presentation_rental_marketplace.dim_apartment(apartment_key),
    user_key BIGINT NOT NULL REFERENCES presentation_rental_marketplace.dim_user(user_key),
    is_wishlisted BOOLEAN,
    call_to_action VARCHAR(256),
    week_year VARCHAR(7),
    month_year VARCHAR(7)
);

