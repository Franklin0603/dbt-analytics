# Product Intermediate Models

## Overview

This directory contains intermediate models that transform product data into meaningful categories and metrics. These models support product analysis, inventory management, and sales performance tracking.

## Models

### 1. int_product_metrics

Comprehensive product performance analytics:

- Sales metrics
- Inventory tracking
- Revenue analysis
- Order patterns

Key Metrics:

- Total orders and quantities
- Average unit price
- Total revenue
- Stock status
- Order frequency

### 2. int_product_categories

Product categorization and classification:

- Product hierarchy
- Size classifications
- Price tiers
- Product attributes

Key Features:

- Category hierarchy
- Size standardization
- Price tier assignment
- Product type grouping

## Usage

These models are typically used for:

- Product performance analysis
- Inventory management
- Pricing strategy
- Category management
- Product mix optimization

## Dependencies

- Staging models:
  - `stg_tpch__parts`
  - `stg_tpch__partsupp`
  - `stg_tpch__lineitem`

## Business Rules

1. Product Categories:

   - Main Categories:

     - Electronics
     - Machinery
     - Components
     - Supplies
     - Accessories

   - Subcategories:
     - Based on product type and use case
     - Minimum 3 products per subcategory
     - Maximum 50 products per subcategory

2. Size Categories:

   - XS: < 10 cm³
   - S: 10-100 cm³
   - M: 100-1000 cm³
   - L: 1000-5000 cm³
   - XL: > 5000 cm³

3. Price Tiers:

   - Economy: < $100
   - Standard: $100-500
   - Premium: $500-2000
   - Luxury: > $2000

4. Stock Level Rules:

   - Out of Stock: 0 units
   - Low Stock: < 10% of average monthly demand
   - In Stock: 10-200% of average monthly demand
   - Overstocked: > 200% of average monthly demand

5. Product Performance Metrics:
   - High Performing: > 120% of category average revenue
   - Average: 80-120% of category average revenue
   - Under Performing: < 80% of category average revenue
