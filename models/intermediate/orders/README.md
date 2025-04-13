# Order Intermediate Models

## Overview

This directory contains intermediate models that transform order and line item data into comprehensive order analytics. These models provide detailed insights into order processing, fulfillment, and financial metrics.

## Models

### 1. int_order_items

Detailed order line item analysis combining orders, products, and suppliers:

- Line item details and identifiers
- Price calculations (original, discounted, final)
- Shipping status tracking
- Product and supplier relationships

Key Metrics:

- Line item pricing
- Discounts applied
- Tax calculations
- Shipping performance

### 2. int_order_metrics

Order-level aggregations and performance indicators:

- Order totals and counts
- Customer order history
- Shipping and fulfillment metrics
- Financial calculations

Key Features:

- Total order value
- Item count per order
- Shipping duration
- Discount impact

## Usage

These models are typically used for:

- Order processing analysis
- Revenue reporting
- Fulfillment performance tracking
- Discount and pricing analysis
- Customer order patterns

## Dependencies

- Staging models:
  - `stg_tpch__orders`
  - `stg_tpch__lineitem`
  - `stg_tpch__customer`
  - `stg_tpch__parts`
  - `stg_tpch__supplier`

## Business Rules

1. Order Status Categories:

   - Pending: Order received, not yet processed
   - Processing: Order being prepared
   - Shipped: Order in transit
   - Delivered: Order received by customer
   - Cancelled: Order cancelled before fulfillment

2. Price Calculations:

   - Base Price: Original item price
   - Discounted Price: Base price - (Base price × Discount rate)
   - Final Price: Discounted price + Tax
   - Total Order Value: Sum of all line item final prices

3. Shipping Performance:

   - On-Time: Delivered within estimated delivery date
   - Delayed: Delivered after estimated delivery date
   - Early: Delivered before estimated delivery date

4. Order Aggregation Rules:
   - Daily totals cut-off: 23:59:59 local time
   - Monthly totals: Calendar month
   - Quarterly totals: Calendar quarter
   - Yearly totals: Calendar year
