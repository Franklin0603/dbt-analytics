# Customer Intermediate Models

## Overview

This directory contains intermediate models that transform customer data into business-ready metrics and segments. These models serve as the foundation for customer analytics, segmentation, and behavior analysis.

## Models

### 1. int_customer_profile

Enriched customer profile combining base attributes with derived metrics:

- Geographic information (nation, region)
- Account balance classification
- Phone number parsing
- Last update tracking

### 2. int_customer_orders

Customer-level order aggregations and behavior metrics:

- Order frequency metrics (total, yearly, quarterly, monthly)
- Order value metrics (total revenue, average order value)
- Time-based metrics (first/last order, order frequency)
- Performance metrics (fulfillment rate, on-time delivery)

### 3. int_customer_segments

Advanced customer segmentation using multiple methodologies:

- RFM (Recency, Frequency, Monetary) scoring
- Lifecycle stage classification
- Purchase frequency segmentation
- Value-based tiering
- Business segment categorization

## Usage

These models are typically used for:

- Customer segmentation analysis
- Marketing campaign targeting
- Customer value assessment
- Churn risk identification
- Geographic distribution analysis

## Dependencies

- Staging models:
  - `stg_tpch__customer`
  - `stg_tpch__orders`
  - `stg_tpch__nations`
  - `stg_tpch__regions`

## Business Rules

1. Balance Tiers:

   - Negative: < 0
   - Zero: = 0
   - Low: 1-1000
   - Medium: 1001-10000
   - High: > 10000

2. Lifecycle Stages:

   - New: First order within last 30 days
   - Active: Order within last 90 days
   - Loyal: > 5 orders and order within last 180 days
   - At Risk: No order in 180-365 days
   - Churning: No order in > 365 days

3. RFM Scoring:
   - Recency: Days since last order (1-5)
   - Frequency: Number of orders (1-5)
   - Monetary: Total spend (1-5)
