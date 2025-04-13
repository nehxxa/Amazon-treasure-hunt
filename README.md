# Amazon-treasure-hunt

Key Features:

Treasure Score Calculation:
Created a custom metric, "Treasure Score," to rank products based on:
High average ratings (>4.5 stars) with low review counts (<50 reviews).
Competitive pricing (within 10% of category median price).
Rising sales trends (e.g., >20% month-over-month growth).
Used SQL window functions and aggregations to compute scores dynamically.
Sentiment Pulse:
Analyzed review text sentiment (simulated with a positivity flag) to identify products with enthusiastic customer feedback.
Built queries to flag "hype-worthy" products with a surge in positive reviews over the last 30 days.
Category Conquest:
Identified top-performing product categories by region, uncovering niche markets with high demand but low competition.
Used complex joins and subqueries to correlate sales, reviews, and customer demographics.
Price Elasticity Explorer:
Modeled how price changes impacted sales volume for top "treasure" products.
Employed SQL CASE statements and aggregations to segment products by elasticity profiles (e.g., "bargain gems" vs. "premium picks").
Seasonal Spotlight:
Detected seasonal trends in product popularity (e.g., holiday spikes) using date-based aggregations and time-series analysis in SQL.
Highlighted products likely to shine during upcoming shopping seasons.
