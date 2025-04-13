# TPC-H Data Dictionary

## Fact Tables

### fct_orders

| Column Name    | Data Type     | Description                 | Business Rules       |
| -------------- | ------------- | --------------------------- | -------------------- |
| order_key      | integer       | Primary key for orders      | Unique identifier    |
| customer_key   | integer       | Foreign key to dim_customer | Not null             |
| order_date     | date          | Date when order was placed  | Not null             |
| order_status   | varchar(1)    | Order status code           | One of: 'O','F','P'  |
| total_price    | decimal(15,2) | Total order price           | > 0                  |
| order_priority | varchar(15)   | Priority level              | Valid values defined |

### fct_line_items

| Column Name    | Data Type     | Description                 | Business Rules    |
| -------------- | ------------- | --------------------------- | ----------------- |
| line_item_key  | integer       | Primary key                 | Unique identifier |
| order_key      | integer       | Foreign key to fct_orders   | Not null          |
| part_key       | integer       | Foreign key to dim_parts    | Not null          |
| supplier_key   | integer       | Foreign key to dim_supplier | Not null          |
| quantity       | decimal(15,2) | Quantity ordered            | > 0               |
| extended_price | decimal(15,2) | Line item total price       | > 0               |
| discount       | decimal(15,2) | Discount percentage         | Between 0 and 1   |

## Dimension Tables

### dim_customer

| Column Name     | Data Type     | Description               | Business Rules    |
| --------------- | ------------- | ------------------------- | ----------------- |
| customer_key    | integer       | Primary key               | Unique identifier |
| name            | varchar(25)   | Customer name             | Not null          |
| address         | varchar(40)   | Street address            | Not null          |
| nation_key      | integer       | Foreign key to dim_nation | Not null          |
| phone           | varchar(15)   | Phone number              | Valid format      |
| account_balance | decimal(15,2) | Current balance           | No constraint     |

### dim_supplier

| Column Name     | Data Type     | Description               | Business Rules    |
| --------------- | ------------- | ------------------------- | ----------------- |
| supplier_key    | integer       | Primary key               | Unique identifier |
| name            | varchar(25)   | Supplier name             | Not null          |
| address         | varchar(40)   | Street address            | Not null          |
| nation_key      | integer       | Foreign key to dim_nation | Not null          |
| phone           | varchar(15)   | Phone number              | Valid format      |
| account_balance | decimal(15,2) | Current balance           | No constraint     |

### dim_part

| Column Name  | Data Type   | Description        | Business Rules       |
| ------------ | ----------- | ------------------ | -------------------- |
| part_key     | integer     | Primary key        | Unique identifier    |
| name         | varchar(55) | Part name          | Not null             |
| manufacturer | varchar(25) | Manufacturer name  | Not null             |
| brand        | varchar(10) | Brand identifier   | Not null             |
| type         | varchar(25) | Part type          | Valid values defined |
| size         | integer     | Size specification | > 0                  |
| container    | varchar(10) | Container type     | Valid values defined |

### dim_date

| Column Name | Data Type  | Description      | Business Rules    |
| ----------- | ---------- | ---------------- | ----------------- |
| date_key    | integer    | Primary key      | Unique identifier |
| date        | date       | Calendar date    | Not null          |
| day_of_week | integer    | Day number (1-7) | Between 1 and 7   |
| day_name    | varchar(9) | Day name         | Valid day names   |
| month       | integer    | Month number     | Between 1 and 12  |
| month_name  | varchar(9) | Month name       | Valid month names |
| quarter     | integer    | Quarter number   | Between 1 and 4   |
| year        | integer    | Year             | Valid year range  |

### dim_nation

| Column Name | Data Type    | Description               | Business Rules    |
| ----------- | ------------ | ------------------------- | ----------------- |
| nation_key  | integer      | Primary key               | Unique identifier |
| name        | varchar(25)  | Nation name               | Not null          |
| region_key  | integer      | Foreign key to dim_region | Not null          |
| comment     | varchar(152) | Additional information    | Optional          |

### dim_region

| Column Name | Data Type    | Description            | Business Rules    |
| ----------- | ------------ | ---------------------- | ----------------- |
| region_key  | integer      | Primary key            | Unique identifier |
| name        | varchar(25)  | Region name            | Not null          |
| comment     | varchar(152) | Additional information | Optional          |

## Common Calculations

### Order Metrics

```sql
-- Total Order Value
SUM(extended_price * (1 - discount))

-- Order Fulfillment Time
DATE_DIFF('day', order_date, ship_date)
```

### Customer Metrics

```sql
-- Customer Lifetime Value
SUM(total_price) OVER (PARTITION BY customer_key)

-- Average Order Value
AVG(total_price) OVER (PARTITION BY customer_key)
```

### Supplier Metrics

```sql
-- Supplier Performance Score
AVG(CASE WHEN ship_date <= commit_date THEN 1 ELSE 0 END)

-- Supply Cost Ratio
SUM(supply_cost) / SUM(extended_price)
```
