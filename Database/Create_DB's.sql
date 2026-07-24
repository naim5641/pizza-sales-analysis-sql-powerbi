CREATE TABLE customers (
    custid INTEGER PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    phone BIGINT,
    address VARCHAR(255),
    city VARCHAR(50),
    state VARCHAR(50),
    postal_code INTEGER
);


CREATE TABLE order_details (
    order_details_id INTEGER PRIMARY KEY,
    order_id INTEGER,
    pizza_id VARCHAR(50),
    quantity INTEGER
);


CREATE TABLE orders (
    order_id INTEGER PRIMARY KEY,
    order_date DATE,
    order_time TIME,
    custid INTEGER,
    status VARCHAR(50)
);


CREATE TABLE pizza_types (
    pizza_type_id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100),
    category VARCHAR(50),
    ingredients TEXT
);



CREATE TABLE pizzas (
    pizza_id VARCHAR(50) PRIMARY KEY,
    pizza_type_id VARCHAR(50),
    size VARCHAR(10),
    price DECIMAL(10, 2)
);






