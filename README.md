# final_project
End-to-end PostgreSQL data engineering pipeline and star schema for the Olist dataset. Includes CSV staging, PL/SQL stored procedures with automated error logging, incremental loads, query performance indexing, and advanced analytical SQL window functions.
# data source I used
https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce
# Olist Data Warehouse & ETL Project

An end-to-end PostgreSQL data engineering pipeline and star schema architecture built for the Olist e-commerce dataset. 

## Architecture & Schema Design
* **Staging Layer (`stage`)**: Direct CSV ingestion tables capturing raw records for customers, geolocation, order items, payments, reviews, orders, products, sellers, and English category translations.
* **Target Star Schema (`target`)**: Modeled dimensional tables (`customer_dim`, `products_dim`, `sellers_dim`, `geolocation_dim`) and fact table (`order_items_fact`) optimized for analytics.

## ETL Procedures & Packages
* **Full Load & Incremental Load**: Organized into dedicated execution packages (`pkg_full_load` and `pkg_incremental_load`) utilizing `MERGE` statements for efficient record updates and insertions.
* **Error Handling**: Built-in exception blocks (`EXCEPTION WHEN OTHERS`) catch runtime errors and log error codes, messages, and timestamps into `target.error_log`.

## Performance Tuning
* Indexes are established on all foreign key columns within the fact table to optimize query execution and join speeds:
  ```sql
  create index if not exists idx_order_items_customer_key on target.order_items_fact(customer_key);
  create index if not exists idx_order_items_products_key on target.order_items_fact(products_key);
  create index if not exists idx_order_items_sellers_key on target.order_items_fact(sellers_key);
