CREATE DATABASE raw_rental_marketplace;
CREATE TABLE raw_rental_marketplace.apartment_attributes (
    id INT PRIMARY KEY,
    category VARCHAR(50),
    body TEXT,
    amenities TEXT,
    bathrooms INT,
    bedrooms INT,
    fee DECIMAL(10,2),
    has_photo VARCHAR(10),
    pets_allowed VARCHAR(10),
    price_display VARCHAR(50),
    price_type VARCHAR(50),
    square_feet INT,
    address VARCHAR(255),
    cityname VARCHAR(100),
    state VARCHAR(100),
    latitude DECIMAL(10,6),
    longitude DECIMAL(10,6)
);
CREATE TABLE raw_rental_marketplace.apartments (
    id INT PRIMARY KEY,
    title VARCHAR(255),
    source VARCHAR(100),
    price DECIMAL(10,2),
    currency VARCHAR(10),
    listing_created_on VARCHAR(10),
    is_active VARCHAR(10),
    last_modified_timestamp VARCHAR(10)
);
CREATE TABLE raw_rental_marketplace.user_viewing (
    user_id INT,
    apartment_id INT,
    viewed_at VARCHAR(10),
    is_wishlisted VARCHAR(10),
    call_to_action VARCHAR(100),
    PRIMARY KEY (user_id, apartment_id, viewed_at),
    FOREIGN KEY (apartment_id) REFERENCES raw_rental_marketplace.apartment_attributes(id)
);
CREATE TABLE raw_rental_marketplace.bookings (
    booking_id INT PRIMARY KEY,
    user_id INT,
    apartment_id INT,
    booking_date VARCHAR(10),
    checkin_date VARCHAR(10),
    checkout_date VARCHAR(10),
    total_price DECIMAL(10,2),
    currency VARCHAR(10),
    booking_status VARCHAR(50),
    FOREIGN KEY (apartment_id) REFERENCES raw_rental_marketplace.apartments(id)
);