# Shipping Intermediate Models

## Overview

This directory contains intermediate models that analyze shipping performance, costs, and delivery metrics. These models support logistics optimization, cost management, and delivery performance tracking.

## Models

### 1. int_shipping_performance

Shipping and delivery performance analytics:

- Delivery time tracking
- Delay analysis
- Performance metrics
- Status monitoring

Key Metrics:

- Actual vs. estimated shipping days
- Delay calculations
- Delivery status tracking
- Performance indicators

### 2. int_shipping_costs

Detailed shipping cost analysis:

- Base shipping costs
- Additional charges
- Cost ratios
- Cost optimization metrics

Key Features:

- Cost breakdown
- Charge categorization
- Cost-to-value ratios
- Shipping efficiency metrics

## Usage

These models are typically used for:

- Delivery performance tracking
- Cost optimization
- Carrier evaluation
- Route optimization
- Customer satisfaction analysis

## Dependencies

- Staging models:
  - `stg_tpch__orders`
  - `stg_tpch__lineitem`
  - `ref_shipping_modes`

## Business Rules

1. Shipping Modes:

   - Standard Ground (5-7 days)
   - Express (2-3 days)
   - Next Day Air
   - International (7-14 days)
   - Economy (7-10 days)

2. Delivery Status Categories:

   - In Transit: Shipment in movement
   - Delivered: Successfully delivered
   - Delayed: Beyond estimated delivery
   - Lost: Unable to locate package

3. Delay Classifications:

   - No Delay: On or before estimated date
   - Minor Delay: 1-2 days late
   - Moderate Delay: 3-5 days late
   - Severe Delay: > 5 days late

4. Cost Components:

   - Base Rate: Standard shipping cost
   - Weight Surcharge: For items > 50 lbs
   - Distance Factor: Based on shipping zones
   - Special Handling: For fragile/special items
   - Insurance: Value-based coverage

5. Performance Metrics:
   - On-Time Delivery Rate Target: > 95%
   - Cost Efficiency Target: < 10% of order value
   - Average Transit Time:
     - Domestic: < 5 days
     - International: < 12 days
