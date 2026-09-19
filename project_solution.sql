--1. create stage schema 
drop schema if exists stage cascade;

create schema stage;

create table if not exists stage.customer(customer_id varchar(50),customer_unique_id varchar(50),
                             customer_zip_code_prefix int, customer_city varchar(50),
                             customer_state varchar(10));
                             
create table if not exists stage.geolocation(geolocation_zip_code_prefix int, geolocation_lat float(20),
                               geolocation_lng float(20),geolocation_city varchar(30),
                               geolocation_state varchar(10));
           
create table if not exists stage.order_items(order_id varchar(50),order_item_id int,product_id varchar(50),
                               seller_id varchar(50),shipping_limit_date timestamp,price float(20),
                               freight_value float(20));           

create table if not exists stage.order_payments(order_id varchar(50),payment_sequential int,payment_type varchar(30),
                                  payment_installments int,payment_value float(20));
                 
create table if not exists stage.order_reviews(review_id varchar(50),order_id varchar(50),review_score int,
                                 review_comment_title varchar(30),review_comment_message varchar(50),
                                 review_creation_date timestamp,review_answer_timestamp timestamp);

create table if not exists stage.orders(order_id varchar(50),customer_id varchar(50),order_status varchar(20),
                          order_purchase_timestamp timestamp,order_approved_at timestamp,order_delivered_carrier_date
                          timestamp,order_delivered_customer_date timestamp,order_estimated_delivery_date timestamp);

create table if not exists stage.products(product_id varchar(50),product_category_name varchar(30),product_name_lenght int,
                            product_description_lenght int,product_photos_qty int,product_weight_g int,
                            product_length_cm int,product_height_cm int,product_width_cm int);
       
create table if not exists stage.sellers(seller_id varchar(50),seller_zip_code_prefix int,seller_city varchar(30),
                           seller_state varchar(10));                            

create table if not exists stage.product_category_name_translation(product_category_name varchar(60),product_category_name_english
                                                     varchar(60));
-- to ensure there is no duplicated values 
truncate table stage.customer;
truncate table stage.geolocation;
truncate table stage.order_items;
truncate table stage.order_payments;
truncate table stage.order_reviews;
truncate table stage.orders;
truncate table stage.products;
truncate table stage.sellers;
truncate table stage.product_category_name_translation;
 
copy stage.customer 
from 'C:\project_sql\olist_customers_dataset.csv'
delimiter ',' csv header;  
--due the error in the varchar 30 is short for  geolocation_city I need to update it
alter table stage.geolocation alter column geolocation_city type varchar(50);

copy stage.geolocation 
from 'C:\project_sql\olist_geolocation_dataset.csv'
delimiter ',' csv header;  

copy stage.order_items
from 'C:\project_sql\olist_order_items_dataset.csv'
delimiter ',' csv header; 

copy stage.order_payments
from 'C:\project_sql\olist_order_payments_dataset.csv'
delimiter ',' csv header;  
--due the error in the varchar 30 is short for  review_comment_message I need to update it
alter table stage.order_reviews alter column review_comment_message type varchar(500);

copy stage.order_reviews
from 'C:\project_sql\olist_order_reviews_dataset.csv'
delimiter ',' csv header; 

copy stage.orders
from 'C:\project_sql\olist_orders_dataset.csv'
delimiter ',' csv header; 
--due the error in the varchar 30 is short for  product_category_name I need to update it
alter table stage.products alter column product_category_name type varchar(50);

copy stage.products
from 'C:\project_sql\olist_products_dataset.csv'
delimiter ',' csv header; 
--due the error in the varchar 30 is short for  seller_city I need to update it
alter table stage.sellers alter column seller_city type varchar(50);

copy stage.sellers
from 'C:\project_sql\olist_sellers_dataset.csv'
delimiter ',' csv header;  

copy stage.product_category_name_translation
from 'C:\project_sql\product_category_name_translation.csv'
delimiter ',' csv header;    
-------------------------------------
--check if loaded correctly
select count(*) from stage.customer; 
select count(*) from stage.geolocation;
select count(*) from stage.order_items;
select count(*) from stage.order_payments;
select count(*) from stage.order_reviews;
select count(*) from stage.orders;
select count(*) from stage.products;
select count(*) from stage.sellers;
select count(*) from stage.product_category_name_translation; 
-----------------------------------------
--implemnting star schema

drop schema if exists target cascade;

create schema target;

create table if not exists target.customer_dim(customer_key serial primary key,customer_id varchar(50),customer_unique_id varchar(50),
                             customer_zip_code_prefix int, customer_city varchar(50),
                             customer_state varchar(10));
                             
create table if not exists target.products_dim(products_key serial primary key,product_id varchar(50),product_category_name varchar(50),product_name_lenght int,
                            product_description_lenght int,product_photos_qty int,product_weight_g int,
                            product_length_cm int,product_height_cm int,product_width_cm int);  
                            
create table if not exists target.sellers_dim(sellers_key serial primary key,seller_id varchar(50),seller_zip_code_prefix int,seller_city varchar(50),
                           seller_state varchar(10)); 
                           
create table if not exists target.geolocation_dim(geolocation_key serial primary key,geolocation_zip_code_prefix int, geolocation_lat float(20),
                               geolocation_lng float(20),geolocation_city varchar(50),
                               geolocation_state varchar(10));
                               
create table if not exists target.order_items_fact(order_item_key serial primary key,order_id varchar(50),order_item_id int,product_id varchar(50),
                               seller_id varchar(50),shipping_limit_date timestamp,price float(20),freight_value float(20),
                               customer_key int , products_key int, sellers_key int,
                               constraint customer_key foreign key (customer_key) references target.customer_dim(customer_key),
                               constraint product_key foreign key (products_key) references target.products_dim(products_key),
                               constraint seller_key foreign key (sellers_key) references target.sellers_dim(sellers_key));                                                                                                                 
  
-- to ensure there is no duplicated values 
truncate table target.customer_dim;
truncate table target.products_dim;
truncate table target.sellers_dim;
truncate table target.geolocation_dim;
truncate table target.order_items_fact;   
-- insert data in the tables 
/*
insert into target.customer_dim (customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state)
select distinct customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state
from stage.customer; 

insert into target.products_dim (product_id, product_category_name, product_name_lenght, product_description_lenght, product_photos_qty, product_weight_g, product_length_cm, product_height_cm, product_width_cm)
select 
    p.product_id, 
    coalesce(t.product_category_name_english, p.product_category_name) as product_category_name, 
    p.product_name_lenght, 
    p.product_description_lenght, 
    p.product_photos_qty, 
    p.product_weight_g, 
    p.product_length_cm, 
    p.product_height_cm, 
    p.product_width_cm
from stage.products p
left join stage.product_category_name_translation t 
    on p.product_category_name = t.product_category_name;  
    
insert into target.sellers_dim (seller_id, seller_zip_code_prefix, seller_city, seller_state)
select distinct seller_id, seller_zip_code_prefix, seller_city, seller_state
from stage.sellers; 

insert into target.geolocation_dim (geolocation_zip_code_prefix, geolocation_lat, geolocation_lng, geolocation_city, geolocation_state)
select distinct geolocation_zip_code_prefix, geolocation_lat, geolocation_lng, geolocation_city, geolocation_state
from stage.geolocation; 

insert into target.order_items_fact (
    order_id, 
    order_item_id, 
    product_id, 
    seller_id, 
    shipping_limit_date, 
    price, 
    freight_value, 
    customer_key, 
    products_key, 
    sellers_key
)
select 
    oi.order_id,
    oi.order_item_id,
    oi.product_id,
    oi.seller_id,
    oi.shipping_limit_date,
    oi.price,
    oi.freight_value,
    cd.customer_key,
    pd.products_key,
    sd.sellers_key
from stage.order_items oi
join stage.orders o on oi.order_id = o.order_id
left join target.customer_dim cd on o.customer_id = cd.customer_id
left join target.products_dim pd on oi.product_id = pd.product_id
left join target.sellers_dim sd on oi.seller_id = sd.seller_id;   
-------------

merge into target.customer_dim t
using stage.customer s
on t.customer_id = s.customer_id
when matched then
    update set 
        customer_unique_id = s.customer_unique_id,
        customer_zip_code_prefix = s.customer_zip_code_prefix,
        customer_city = s.customer_city,
        customer_state = s.customer_state
when not matched then
    insert (customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state)
    values (s.customer_id, s.customer_unique_id, s.customer_zip_code_prefix, s.customer_city, s.customer_state); 
    
merge into target.products_dim t
using (
    select 
        p.product_id, 
        coalesce(tr.product_category_name_english, p.product_category_name) as product_category_name, 
        p.product_name_lenght, 
        p.product_description_lenght, 
        p.product_photos_qty, 
        p.product_weight_g, 
        p.product_length_cm, 
        p.product_height_cm, 
        p.product_width_cm
    from stage.products p
    left join stage.product_category_name_translation tr 
        on p.product_category_name = tr.product_category_name
) s
on t.product_id = s.product_id
when matched then
    update set 
        product_category_name = s.product_category_name,
        product_name_lenght = s.product_name_lenght,
        product_description_lenght = s.product_description_lenght,
        product_photos_qty = s.product_photos_qty,
        product_weight_g = s.product_weight_g,
        product_length_cm = s.product_length_cm,
        product_height_cm = s.product_height_cm,
        product_width_cm = s.product_width_cm
when not matched then
    insert (product_id, product_category_name, product_name_lenght, product_description_lenght, product_photos_qty, product_weight_g, product_length_cm, product_height_cm, product_width_cm)
    values (s.product_id, s.product_category_name, s.product_name_lenght, s.product_description_lenght, s.product_photos_qty, s.product_weight_g, s.product_length_cm, s.product_height_cm, s.product_width_cm);
    
merge into target.sellers_dim t
using stage.sellers s
on t.seller_id = s.seller_id
when matched then
    update set 
        seller_zip_code_prefix = s.seller_zip_code_prefix,
        seller_city = s.seller_city,
        seller_state = s.seller_state
when not matched then
    insert (seller_id, seller_zip_code_prefix, seller_city, seller_state)
    values (s.seller_id, s.seller_zip_code_prefix, s.seller_city, s.seller_state);
    
merge into target.geolocation_dim t
using (
    select distinct geolocation_zip_code_prefix, geolocation_lat, geolocation_lng, geolocation_city, geolocation_state
    from stage.geolocation
) s
on t.geolocation_zip_code_prefix = s.geolocation_zip_code_prefix 
   and t.geolocation_lat = s.geolocation_lat 
   and t.geolocation_lng = s.geolocation_lng
when matched then
    update set 
        geolocation_city = s.geolocation_city,
        geolocation_state = s.geolocation_state
when not matched then
    insert (geolocation_zip_code_prefix, geolocation_lat, geolocation_lng, geolocation_city, geolocation_state)
    values (s.geolocation_zip_code_prefix, s.geolocation_lat, s.geolocation_lng, s.geolocation_city, s.geolocation_state);
    
merge into target.order_items_fact t
using (
    select 
        oi.order_id,
        oi.order_item_id,
        oi.product_id,
        oi.seller_id,
        oi.shipping_limit_date,
        oi.price,
        oi.freight_value,
        cd.customer_key,
        pd.products_key,
        sd.sellers_key
    from stage.order_items oi
    join stage.orders o on oi.order_id = o.order_id
    left join target.customer_dim cd on o.customer_id = cd.customer_id
    left join target.products_dim pd on oi.product_id = pd.product_id
    left join target.sellers_dim sd on oi.seller_id = sd.seller_id
) s
on t.order_id = s.order_id and t.order_item_id = s.order_item_id
when matched then
    update set 
        shipping_limit_date = s.shipping_limit_date,
        price = s.price,
        freight_value = s.freight_value,
        customer_key = s.customer_key,
        products_key = s.products_key,
        sellers_key = s.sellers_key
when not matched then
    insert (order_id, order_item_id, product_id, seller_id, shipping_limit_date, price, freight_value, customer_key, products_key, sellers_key)
    values (s.order_id, s.order_item_id, s.product_id, s.seller_id, s.shipping_limit_date, s.price, s.freight_value, s.customer_key, s.products_key, s.sellers_key);
*/    
-- create procedure for loading customer table
CREATE OR REPLACE PROCEDURE target.load_customer_dim()

LANGUAGE plpgsql

AS '

BEGIN

merge into target.customer_dim t

using stage.customer s

on t.customer_id = s.customer_id

when matched then

update set

customer_unique_id = s.customer_unique_id,

customer_zip_code_prefix = s.customer_zip_code_prefix,

customer_city = s.customer_city,

customer_state = s.customer_state

when not matched then

insert (customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state)

values (s.customer_id, s.customer_unique_id, s.customer_zip_code_prefix, s.customer_city, s.customer_state);

COMMIT;

END;

';  

-- create procedure for loading products table
CREATE OR REPLACE PROCEDURE target.load_products_dim()

LANGUAGE plpgsql

AS '

BEGIN

merge into target.products_dim t
using (
    select 
        p.product_id, 
        coalesce(tr.product_category_name_english, p.product_category_name) as product_category_name, 
        p.product_name_lenght, 
        p.product_description_lenght, 
        p.product_photos_qty, 
        p.product_weight_g, 
        p.product_length_cm, 
        p.product_height_cm, 
        p.product_width_cm
    from stage.products p
    left join stage.product_category_name_translation tr 
        on p.product_category_name = tr.product_category_name
) s
on t.product_id = s.product_id
when matched then
    update set 
        product_category_name = s.product_category_name,
        product_name_lenght = s.product_name_lenght,
        product_description_lenght = s.product_description_lenght,
        product_photos_qty = s.product_photos_qty,
        product_weight_g = s.product_weight_g,
        product_length_cm = s.product_length_cm,
        product_height_cm = s.product_height_cm,
        product_width_cm = s.product_width_cm
when not matched then
    insert (product_id, product_category_name, product_name_lenght, product_description_lenght, product_photos_qty, product_weight_g, product_length_cm, product_height_cm, product_width_cm)
    values (s.product_id, s.product_category_name, s.product_name_lenght, s.product_description_lenght, s.product_photos_qty, s.product_weight_g, s.product_length_cm, s.product_height_cm, s.product_width_cm);
    
COMMIT;

END;

';  
   
-- create procedure for loading sellers table

CREATE OR REPLACE PROCEDURE target.load_sellers_dim()

LANGUAGE plpgsql

AS '

BEGIN

merge into target.sellers_dim t
using stage.sellers s
on t.seller_id = s.seller_id
when matched then
    update set 
        seller_zip_code_prefix = s.seller_zip_code_prefix,
        seller_city = s.seller_city,
        seller_state = s.seller_state
when not matched then
    insert (seller_id, seller_zip_code_prefix, seller_city, seller_state)
    values (s.seller_id, s.seller_zip_code_prefix, s.seller_city, s.seller_state);
    
COMMIT;

END;

';

-- create procedure for loading geolocation table

CREATE OR REPLACE PROCEDURE target.load_geolocation_dim()
LANGUAGE plpgsql
AS '
BEGIN
    MERGE INTO target.geolocation_dim t
    USING (
        SELECT DISTINCT ON (geolocation_zip_code_prefix, geolocation_lat, geolocation_lng) 
               geolocation_zip_code_prefix, 
               geolocation_lat, 
               geolocation_lng, 
               geolocation_city, 
               geolocation_state
        FROM stage.geolocation
        ORDER BY geolocation_zip_code_prefix, geolocation_lat, geolocation_lng
    ) s
    ON t.geolocation_zip_code_prefix = s.geolocation_zip_code_prefix 
       AND t.geolocation_lat = s.geolocation_lat 
       AND t.geolocation_lng = s.geolocation_lng
    WHEN MATCHED THEN
        UPDATE SET 
            geolocation_city = s.geolocation_city,
            geolocation_state = s.geolocation_state
    WHEN NOT MATCHED THEN
        INSERT (geolocation_zip_code_prefix, geolocation_lat, geolocation_lng, geolocation_city, geolocation_state)
        VALUES (s.geolocation_zip_code_prefix, s.geolocation_lat, s.geolocation_lng, s.geolocation_city, s.geolocation_state);
        
    COMMIT;
END;
';
-- create procedure for loading order_items table

CREATE OR REPLACE PROCEDURE target.load_order_items_fact()

LANGUAGE plpgsql

AS '

BEGIN

merge into target.order_items_fact t
using (
    select 
        oi.order_id,
        oi.order_item_id,
        oi.product_id,
        oi.seller_id,
        oi.shipping_limit_date,
        oi.price,
        oi.freight_value,
        cd.customer_key,
        pd.products_key,
        sd.sellers_key
    from stage.order_items oi
    join stage.orders o on oi.order_id = o.order_id
    left join target.customer_dim cd on o.customer_id = cd.customer_id
    left join target.products_dim pd on oi.product_id = pd.product_id
    left join target.sellers_dim sd on oi.seller_id = sd.seller_id
) s
on t.order_id = s.order_id and t.order_item_id = s.order_item_id
when matched then
    update set 
        shipping_limit_date = s.shipping_limit_date,
        price = s.price,
        freight_value = s.freight_value,
        customer_key = s.customer_key,
        products_key = s.products_key,
        sellers_key = s.sellers_key
when not matched then
    insert (order_id, order_item_id, product_id, seller_id, shipping_limit_date, price, freight_value, customer_key, products_key, sellers_key)
    values (s.order_id, s.order_item_id, s.product_id, s.seller_id, s.shipping_limit_date, s.price, s.freight_value, s.customer_key, s.products_key, s.sellers_key);
COMMIT;

END;

';  

call target.load_customer_dim();
call target.load_products_dim();
call target.load_sellers_dim();
call target.load_geolocation_dim();
call target.load_order_items_fact(); 


-- error handling 
create table target.error_log (
    log_id SERIAL PRIMARY KEY,
    procedure_name VARCHAR(100),
    error_code VARCHAR(50),
    error_message TEXT,
    log_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE PROCEDURE target.log_error(
    p_proc_name VARCHAR, 
    p_err_code VARCHAR, 
    p_err_msg TEXT
)
LANGUAGE plpgsql
AS '
BEGIN
    INSERT INTO target.error_log (procedure_name, error_code, error_message)
    VALUES (p_proc_name, p_err_code, p_err_msg);
END;
';

create schema if not exists pkg_full_load;
-- create procedure for full load customer table
CREATE OR REPLACE PROCEDURE pkg_full_load.load_customer_dim()
LANGUAGE plpgsql
AS '
BEGIN

merge into target.customer_dim t
using stage.customer s
on t.customer_id = s.customer_id
when matched then
update set
customer_unique_id = s.customer_unique_id,
customer_zip_code_prefix = s.customer_zip_code_prefix,
customer_city = s.customer_city,
customer_state = s.customer_state
when not matched then
insert (customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state)
values (s.customer_id, s.customer_unique_id, s.customer_zip_code_prefix, s.customer_city, s.customer_state);
COMMIT;
EXCEPTION WHEN OTHERS THEN
    CALL target.log_error(''pkg_full_load.load_customer_dim'', SQLSTATE, SQLERRM);
END;
';
-- create procedure for full load products table
CREATE OR REPLACE PROCEDURE pkg_full_load.load_products_dim()
LANGUAGE plpgsql
AS '
BEGIN
merge into target.products_dim t
using (
    select 
        p.product_id, 
        coalesce(tr.product_category_name_english, p.product_category_name) as product_category_name, 
        p.product_name_lenght, 
        p.product_description_lenght, 
        p.product_photos_qty, 
        p.product_weight_g, 
        p.product_length_cm, 
        p.product_height_cm, 
        p.product_width_cm
    from stage.products p
    left join stage.product_category_name_translation tr 
        on p.product_category_name = tr.product_category_name
) s
on t.product_id = s.product_id
when matched then
    update set 
        product_category_name = s.product_category_name,
        product_name_lenght = s.product_name_lenght,
        product_description_lenght = s.product_description_lenght,
        product_photos_qty = s.product_photos_qty,
        product_weight_g = s.product_weight_g,
        product_length_cm = s.product_length_cm,
        product_height_cm = s.product_height_cm,
        product_width_cm = s.product_width_cm
when not matched then
    insert (product_id, product_category_name, product_name_lenght, product_description_lenght, product_photos_qty, product_weight_g, product_length_cm, product_height_cm, product_width_cm)
    values (s.product_id, s.product_category_name, s.product_name_lenght, s.product_description_lenght, s.product_photos_qty, s.product_weight_g, s.product_length_cm, s.product_height_cm, s.product_width_cm);
    
COMMIT;
EXCEPTION WHEN OTHERS THEN
    CALL target.log_error(''pkg_full_load.load_products_dim'', SQLSTATE, SQLERRM);
END;
';
 
 -- create procedure for full load geolocation table
CREATE OR REPLACE PROCEDURE pkg_full_load.load_geolocation_dim()
LANGUAGE plpgsql
AS '
BEGIN
merge into target.geolocation_dim t
using (
    select distinct geolocation_zip_code_prefix, geolocation_lat, geolocation_lng, geolocation_city, geolocation_state
    from stage.geolocation
) s
on t.geolocation_zip_code_prefix = s.geolocation_zip_code_prefix 
   and t.geolocation_lat = s.geolocation_lat 
   and t.geolocation_lng = s.geolocation_lng
when matched then
    update set 
        geolocation_city = s.geolocation_city,
        geolocation_state = s.geolocation_state
when not matched then
    insert (geolocation_zip_code_prefix, geolocation_lat, geolocation_lng, geolocation_city, geolocation_state)
    values (s.geolocation_zip_code_prefix, s.geolocation_lat, s.geolocation_lng, s.geolocation_city, s.geolocation_state);
    
COMMIT;
EXCEPTION WHEN OTHERS THEN
    CALL target.log_error(''pkg_full_load.load_geolocation_dim'', SQLSTATE, SQLERRM);
END;
';

 -- create procedure for full load order_items table
CREATE OR REPLACE PROCEDURE pkg_full_load.load_order_items_fact()
LANGUAGE plpgsql
AS '
BEGIN
merge into target.order_items_fact t
using (
    select 
        oi.order_id,
        oi.order_item_id,
        oi.product_id,
        oi.seller_id,
        oi.shipping_limit_date,
        oi.price,
        oi.freight_value,
        cd.customer_key,
        pd.products_key,
        sd.sellers_key
    from stage.order_items oi
    join stage.orders o on oi.order_id = o.order_id
    left join target.customer_dim cd on o.customer_id = cd.customer_id
    left join target.products_dim pd on oi.product_id = pd.product_id
    left join target.sellers_dim sd on oi.seller_id = sd.seller_id
) s
on t.order_id = s.order_id and t.order_item_id = s.order_item_id
when matched then
    update set 
        shipping_limit_date = s.shipping_limit_date,
        price = s.price,
        freight_value = s.freight_value,
        customer_key = s.customer_key,
        products_key = s.products_key,
        sellers_key = s.sellers_key
when not matched then
    insert (order_id, order_item_id, product_id, seller_id, shipping_limit_date, price, freight_value, customer_key, products_key, sellers_key)
    values (s.order_id, s.order_item_id, s.product_id, s.seller_id, s.shipping_limit_date, s.price, s.freight_value, s.customer_key, s.products_key, s.sellers_key);
COMMIT;

EXCEPTION WHEN OTHERS THEN
    CALL target.log_error(''pkg_full_load.load_order_items_fact'', SQLSTATE, SQLERRM);
END;
';
 
CALL target.load_customer_dim();
CALL target.load_products_dim();
CALL target.load_sellers_dim();
CALL target.load_geolocation_dim();
CALL target.load_order_items_fact();

CALL pkg_full_load.load_customer_dim();
CALL pkg_full_load.load_products_dim();
CALL pkg_full_load.load_geolocation_dim();
CALL pkg_full_load.load_order_items_fact();     

create index if not exists idx_order_items_customer_key on target.order_items_fact(customer_key);
create index if not exists idx_order_items_products_key on target.order_items_fact(products_key);
create index if not exists idx_order_items_sellers_key on target.order_items_fact(sellers_key); 

create schema if not exists pkg_incremental_load;

-- create procedure for pkg_incremental_load customer table
CREATE OR REPLACE PROCEDURE pkg_incremental_load.load_customer_dim()
LANGUAGE plpgsql
AS '
BEGIN

merge into target.customer_dim t
using stage.customer s
on t.customer_id = s.customer_id
when matched then
update set
customer_unique_id = s.customer_unique_id,
customer_zip_code_prefix = s.customer_zip_code_prefix,
customer_city = s.customer_city,
customer_state = s.customer_state
when not matched then
insert (customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state)
values (s.customer_id, s.customer_unique_id, s.customer_zip_code_prefix, s.customer_city, s.customer_state);
COMMIT;
EXCEPTION WHEN OTHERS THEN
    CALL target.log_error(''pkg_incremental_load.load_customer_dim'', SQLSTATE, SQLERRM);
END;
';
-- create procedure for pkg_incremental_load products table
CREATE OR REPLACE PROCEDURE pkg_incremental_load.load_products_dim()
LANGUAGE plpgsql
AS '
BEGIN
merge into target.products_dim t
using (
    select 
        p.product_id, 
        coalesce(tr.product_category_name_english, p.product_category_name) as product_category_name, 
        p.product_name_lenght, 
        p.product_description_lenght, 
        p.product_photos_qty, 
        p.product_weight_g, 
        p.product_length_cm, 
        p.product_height_cm, 
        p.product_width_cm
    from stage.products p
    left join stage.product_category_name_translation tr 
        on p.product_category_name = tr.product_category_name
) s
on t.product_id = s.product_id
when matched then
    update set 
        product_category_name = s.product_category_name,
        product_name_lenght = s.product_name_lenght,
        product_description_lenght = s.product_description_lenght,
        product_photos_qty = s.product_photos_qty,
        product_weight_g = s.product_weight_g,
        product_length_cm = s.product_length_cm,
        product_height_cm = s.product_height_cm,
        product_width_cm = s.product_width_cm
when not matched then
    insert (product_id, product_category_name, product_name_lenght, product_description_lenght, product_photos_qty, product_weight_g, product_length_cm, product_height_cm, product_width_cm)
    values (s.product_id, s.product_category_name, s.product_name_lenght, s.product_description_lenght, s.product_photos_qty, s.product_weight_g, s.product_length_cm, s.product_height_cm, s.product_width_cm);
    
COMMIT;
EXCEPTION WHEN OTHERS THEN
    CALL target.log_error(''pkg_incremental_load.load_products_dim'', SQLSTATE, SQLERRM);
END;
';
 
 -- create procedure for pkg_incremental_load geolocation table
CREATE OR REPLACE PROCEDURE pkg_incremental_load.load_geolocation_dim()
LANGUAGE plpgsql
AS '
BEGIN
merge into target.geolocation_dim t
using (
    select distinct geolocation_zip_code_prefix, geolocation_lat, geolocation_lng, geolocation_city, geolocation_state
    from stage.geolocation
) s
on t.geolocation_zip_code_prefix = s.geolocation_zip_code_prefix 
   and t.geolocation_lat = s.geolocation_lat 
   and t.geolocation_lng = s.geolocation_lng
when matched then
    update set 
        geolocation_city = s.geolocation_city,
        geolocation_state = s.geolocation_state
when not matched then
    insert (geolocation_zip_code_prefix, geolocation_lat, geolocation_lng, geolocation_city, geolocation_state)
    values (s.geolocation_zip_code_prefix, s.geolocation_lat, s.geolocation_lng, s.geolocation_city, s.geolocation_state);
    
COMMIT;
EXCEPTION WHEN OTHERS THEN
    CALL target.log_error(''pkg_incremental_load.load_geolocation_dim'', SQLSTATE, SQLERRM);
END;
';

 -- create procedure for pkg_incremental_load order_items table
CREATE OR REPLACE PROCEDURE pkg_incremental_load.load_order_items_fact()
LANGUAGE plpgsql
AS '
BEGIN
merge into target.order_items_fact t
using (
    select 
        oi.order_id,
        oi.order_item_id,
        oi.product_id,
        oi.seller_id,
        oi.shipping_limit_date,
        oi.price,
        oi.freight_value,
        cd.customer_key,
        pd.products_key,
        sd.sellers_key
    from stage.order_items oi
    join stage.orders o on oi.order_id = o.order_id
    left join target.customer_dim cd on o.customer_id = cd.customer_id
    left join target.products_dim pd on oi.product_id = pd.product_id
    left join target.sellers_dim sd on oi.seller_id = sd.seller_id
) s
on t.order_id = s.order_id and t.order_item_id = s.order_item_id
when matched then
    update set 
        shipping_limit_date = s.shipping_limit_date,
        price = s.price,
        freight_value = s.freight_value,
        customer_key = s.customer_key,
        products_key = s.products_key,
        sellers_key = s.sellers_key
when not matched then
    insert (order_id, order_item_id, product_id, seller_id, shipping_limit_date, price, freight_value, customer_key, products_key, sellers_key)
    values (s.order_id, s.order_item_id, s.product_id, s.seller_id, s.shipping_limit_date, s.price, s.freight_value, s.customer_key, s.products_key, s.sellers_key);
COMMIT;

EXCEPTION WHEN OTHERS THEN
    CALL target.log_error(''pkg_incremental_load.load_order_items_fact'', SQLSTATE, SQLERRM);
END;
';
  
  
CALL pkg_incremental_load.load_customer_dim();
CALL pkg_incremental_load.load_products_dim();
CALL pkg_incremental_load.load_geolocation_dim();
CALL pkg_incremental_load.load_order_items_fact(); 

SELECT * FROM target.error_log;   

--analytical functions 

select 
    p.product_category_name,
    sum(f.price) as total_revenue,
    dense_rank() over (order by sum(f.price) desc) as revenue_rank,
    round((sum(f.price) * 100.0 / sum(sum(f.price)) over ())::numeric, 2) as percentage_of_total
from target.order_items_fact f
join target.products_dim p on f.products_key = p.products_key
group by p.product_category_name
order by total_revenue desc;   

--Validate and reconcile the final target data

select customer_id, 
       row_number() over (partition by customer_id order by customer_unique_id) as row_num
from stage.customer;

select 
    'customer' as entity, 
    (select count(*) from stage.customer) as stage_count, 
    (select count(*) from target.customer_dim) as target_count
union all
select 
    'products', 
    (select count(*) from stage.products), 
    (select count(*) from target.products_dim)
union all
select 
    'sellers', 
    (select count(*) from stage.sellers), 
    (select count(*) from target.sellers_dim);   
    
-- create control table
create table if not exists target.etl_control_log (
    log_id serial primary key,
    procedure_name varchar(100),
    load_status varchar(20),       
    records_inserted int,
    start_time timestamp,
    end_time timestamp,
    duration_seconds numeric
);   

-- create procedure for loading customer table
create or replace procedure target.load_customer_dim()
language plpgsql
as '
declare
    v_start_time timestamp;
    v_end_time timestamp;
    v_rows_before int;
    v_rows_after int;
    v_inserted int;
begin
    v_start_time := clock_timestamp();
    select count(*) into v_rows_before from target.customer_dim;

    merge into target.customer_dim t
    using stage.customer s
    on t.customer_id = s.customer_id
    when matched then
    update set
    customer_unique_id = s.customer_unique_id,
    customer_zip_code_prefix = s.customer_zip_code_prefix,
    customer_city = s.customer_city,
    customer_state = s.customer_state
    when not matched then
    insert (customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state)
    values (s.customer_id, s.customer_unique_id, s.customer_zip_code_prefix, s.customer_city, s.customer_state);

    v_end_time := clock_timestamp();
    select count(*) into v_rows_after from target.customer_dim;
    v_inserted := v_rows_after - v_rows_before;

    insert into target.etl_control_log (procedure_name, load_status, records_inserted, start_time, end_time, duration_seconds)
    values (''load_customer_dim'', ''SUCCESS'', v_inserted, v_start_time, v_end_time, extract(epoch from (v_end_time - v_start_time)));
exception when others then
    insert into target.etl_control_log (procedure_name, load_status, records_inserted, start_time, end_time, duration_seconds)
    values (''load_customer_dim'', ''FAILED'', 0, v_start_time, clock_timestamp(), 0);
    raise;
end;
';  

-- create procedure for loading products table
create or replace procedure target.load_products_dim()
language plpgsql
as '
declare
    v_start_time timestamp;
    v_end_time timestamp;
    v_rows_before int;
    v_rows_after int;
    v_inserted int;
begin
    v_start_time := clock_timestamp();
    select count(*) into v_rows_before from target.products_dim;

    merge into target.products_dim t
    using (
        select 
            p.product_id, 
            coalesce(tr.product_category_name_english, p.product_category_name) as product_category_name, 
            p.product_name_lenght, 
            p.product_description_lenght, 
            p.product_photos_qty, 
            p.product_weight_g, 
            p.product_length_cm, 
            p.product_height_cm, 
            p.product_width_cm
        from stage.products p
        left join stage.product_category_name_translation tr 
            on p.product_category_name = tr.product_category_name
    ) s
    on t.product_id = s.product_id
    when matched then
        update set 
            product_category_name = s.product_category_name,
            product_name_lenght = s.product_name_lenght,
            product_description_lenght = s.product_description_lenght,
            product_photos_qty = s.product_photos_qty,
            product_weight_g = s.product_weight_g,
            product_length_cm = s.product_length_cm,
            product_height_cm = s.product_height_cm,
            product_width_cm = s.product_width_cm
    when not matched then
        insert (product_id, product_category_name, product_name_lenght, product_description_lenght, product_photos_qty, product_weight_g, product_length_cm, product_height_cm, product_width_cm)
        values (s.product_id, s.product_category_name, s.product_name_lenght, s.product_description_lenght, s.product_photos_qty, s.product_weight_g, s.product_length_cm, s.product_height_cm, s.product_width_cm);
        
    v_end_time := clock_timestamp();
    select count(*) into v_rows_after from target.products_dim;
    v_inserted := v_rows_after - v_rows_before;

    insert into target.etl_control_log (procedure_name, load_status, records_inserted, start_time, end_time, duration_seconds)
    values (''load_products_dim'', ''SUCCESS'', v_inserted, v_start_time, v_end_time, extract(epoch from (v_end_time - v_start_time)));
exception when others then
    insert into target.etl_control_log (procedure_name, load_status, records_inserted, start_time, end_time, duration_seconds)
    values (''load_products_dim'', ''FAILED'', 0, v_start_time, clock_timestamp(), 0);
    raise;
end;
';  
   
-- create procedure for loading sellers table
create or replace procedure target.load_sellers_dim()
language plpgsql
as '
declare
    v_start_time timestamp;
    v_end_time timestamp;
    v_rows_before int;
    v_rows_after int;
    v_inserted int;
begin
    v_start_time := clock_timestamp();
    select count(*) into v_rows_before from target.sellers_dim;

    merge into target.sellers_dim t
    using stage.sellers s
    on t.seller_id = s.seller_id
    when matched then
        update set 
            seller_zip_code_prefix = s.seller_zip_code_prefix,
            seller_city = s.seller_city,
            seller_state = s.seller_state
    when not matched then
        insert (seller_id, seller_zip_code_prefix, seller_city, seller_state)
        values (s.seller_id, s.seller_zip_code_prefix, s.seller_city, s.seller_state);
        
    v_end_time := clock_timestamp();
    select count(*) into v_rows_after from target.sellers_dim;
    v_inserted := v_rows_after - v_rows_before;

    insert into target.etl_control_log (procedure_name, load_status, records_inserted, start_time, end_time, duration_seconds)
    values (''load_sellers_dim'', ''SUCCESS'', v_inserted, v_start_time, v_end_time, extract(epoch from (v_end_time - v_start_time)));
exception when others then
    insert into target.etl_control_log (procedure_name, load_status, records_inserted, start_time, end_time, duration_seconds)
    values (''load_sellers_dim'', ''FAILED'', 0, v_start_time, clock_timestamp(), 0);
    raise;
end;
';

-- create procedure for loading geolocation table
create or replace procedure target.load_geolocation_dim()
language plpgsql
as '
declare
    v_start_time timestamp;
    v_end_time timestamp;
    v_rows_before int;
    v_rows_after int;
    v_inserted int;
begin
    v_start_time := clock_timestamp();
    select count(*) into v_rows_before from target.geolocation_dim;

    merge into target.geolocation_dim t
    using (
        select distinct on (geolocation_zip_code_prefix, geolocation_lat, geolocation_lng) 
               geolocation_zip_code_prefix, 
               geolocation_lat, 
               geolocation_lng, 
               geolocation_city, 
               geolocation_state
        from stage.geolocation
        order by geolocation_zip_code_prefix, geolocation_lat, geolocation_lng
    ) s
    on t.geolocation_zip_code_prefix = s.geolocation_zip_code_prefix 
       and t.geolocation_lat = s.geolocation_lat 
       and t.geolocation_lng = s.geolocation_lng
    when matched then
        update set 
            geolocation_city = s.geolocation_city,
            geolocation_state = s.geolocation_state
    when not matched then
        insert (geolocation_zip_code_prefix, geolocation_lat, geolocation_lng, geolocation_city, geolocation_state)
        values (s.geolocation_zip_code_prefix, s.geolocation_lat, s.geolocation_lng, s.geolocation_city, s.geolocation_state);
        
    v_end_time := clock_timestamp();
    select count(*) into v_rows_after from target.geolocation_dim;
    v_inserted := v_rows_after - v_rows_before;

    insert into target.etl_control_log (procedure_name, load_status, records_inserted, start_time, end_time, duration_seconds)
    values (''load_geolocation_dim'', ''SUCCESS'', v_inserted, v_start_time, v_end_time, extract(epoch from (v_end_time - v_start_time)));
exception when others then
    insert into target.etl_control_log (procedure_name, load_status, records_inserted, start_time, end_time, duration_seconds)
    values (''load_geolocation_dim'', ''FAILED'', 0, v_start_time, clock_timestamp(), 0);
    raise;
end;
';

-- create procedure for loading order_items table
create or replace procedure target.load_order_items_fact()
language plpgsql
as '
declare
    v_start_time timestamp;
    v_end_time timestamp;
    v_rows_before int;
    v_rows_after int;
    v_inserted int;
begin
    v_start_time := clock_timestamp();
    select count(*) into v_rows_before from target.order_items_fact;

    merge into target.order_items_fact t
    using (
        select 
            oi.order_id,
            oi.order_item_id,
            oi.product_id,
            oi.seller_id,
            oi.shipping_limit_date,
            oi.price,
            oi.freight_value,
            cd.customer_key,
            pd.products_key,
            sd.sellers_key
        from stage.order_items oi
        join stage.orders o on oi.order_id = o.order_id
        left join target.customer_dim cd on o.customer_id = cd.customer_id
        left join target.products_dim pd on oi.product_id = pd.product_id
        left join target.sellers_dim sd on oi.seller_id = sd.seller_id
    ) s
    on t.order_id = s.order_id and t.order_item_id = s.order_item_id
    when matched then
        update set 
            shipping_limit_date = s.shipping_limit_date,
            price = s.price,
            freight_value = s.freight_value,
            customer_key = s.customer_key,
            products_key = s.products_key,
            sellers_key = s.sellers_key
    when not matched then
        insert (order_id, order_item_id, product_id, seller_id, shipping_limit_date, price, freight_value, customer_key, products_key, sellers_key)
        values (s.order_id, s.order_item_id, s.product_id, s.seller_id, s.shipping_limit_date, s.price, s.freight_value, s.customer_key, s.products_key, s.sellers_key);
        
    v_end_time := clock_timestamp();
    select count(*) into v_rows_after from target.order_items_fact;
    v_inserted := v_rows_after - v_rows_before;

    insert into target.etl_control_log (procedure_name, load_status, records_inserted, start_time, end_time, duration_seconds)
    values (''load_order_items_fact'', ''SUCCESS'', v_inserted, v_start_time, v_end_time, extract(epoch from (v_end_time - v_start_time)));
exception when others then
    insert into target.etl_control_log (procedure_name, load_status, records_inserted, start_time, end_time, duration_seconds)
    values (''load_order_items_fact'', ''FAILED'', 0, v_start_time, clock_timestamp(), 0);
    raise;
end;
';

call target.load_customer_dim();
call target.load_products_dim();
call target.load_sellers_dim();
call target.load_geolocation_dim();
call target.load_order_items_fact();

select * from target.etl_control_log; 

--clear out target tables (fact table first because of foreign keys)
truncate table target.order_items_fact cascade;
truncate table target.customer_dim cascade;
truncate table target.products_dim cascade;
truncate table target.sellers_dim cascade;
truncate table target.geolocation_dim cascade;   

--run your procedures again from a clean slate
call target.load_customer_dim();
call target.load_products_dim();
call target.load_sellers_dim();
call target.load_geolocation_dim();
call target.load_order_items_fact();  

select * from target.etl_control_log order by log_id desc;  
--inserting new data
insert into stage.customer (customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state)
values ('test_id_999', 'unique_id_999', '12345', 'Muscat', 'MS'); 

call target.load_customer_dim(); 
select * from target.etl_control_log order by log_id desc limit 1;  

                                                                                                                                                                                                                                                                                                                                                                   