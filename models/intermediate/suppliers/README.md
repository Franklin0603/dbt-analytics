# Supplier Intermediate Models

## Overview

This directory contains intermediate models that analyze supplier performance, inventory management, and supplier-part relationships. These models support supplier evaluation, inventory optimization, and supply chain management.

## Models

### 1. int_supplier_performance

Comprehensive supplier performance metrics:

- Delivery performance
- Order fulfillment rates
- Quality metrics
- Response time analysis

Key Metrics:

- Total parts supplied
- Order fulfillment rate
- Average delivery time
- Quality rating
- On-time delivery percentage

### 2. int_supplier_parts

Detailed supplier-part relationship analysis:

- Inventory levels
- Cost analysis
- Supplier preferences
- Supply chain metrics

Key Features:

- Current stock levels
- Supply costs
- Preferred supplier flags
- Part availability tracking

## Usage

These models are typically used for:

- Supplier performance evaluation
- Inventory management
- Supply chain optimization
- Cost analysis
- Supplier relationship management

## Dependencies

- Staging models:
  - `stg_tpch__supplier`
  - `stg_tpch__partsupp`
  - `stg_tpch__parts`
  - `stg_tpch__lineitem`

## Business Rules

1. Supplier Performance Rating:

   - Quality Rating (0-100):
     - Product quality: 40%
     - Delivery performance: 30%
     - Price competitiveness: 20%
     - Response time: 10%

2. Delivery Performance:

   - On-Time: Delivery within promised date
   - Early: Delivery before promised date - 2 days
   - Late: Delivery after promised date
   - Critical Late: Delivery after promised date + 5 days

3. Preferred Supplier Status:

   - Quality rating > 90
   - On-time delivery rate > 95%
   - Minimum 6 months relationship
   - No critical late deliveries in last 3 months

4. Stock Level Categories:

   - Out of Stock: 0 units
   - Low Stock: < 20% of target
   - Optimal: 20-80% of target
   - Overstocked: > 80% of target

5. Cost Evaluation:
   - Low Cost: < average cost for part
   - Medium Cost: within 15% of average
   - High Cost: > 15% above average
