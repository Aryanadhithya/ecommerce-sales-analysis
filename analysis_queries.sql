-- Q1: Total revenue, orders, and customers
SELECT
  ROUND(SUM(Quantity * UnitPrice), 2) AS total_revenue,
  COUNT(DISTINCT InvoiceNo) AS total_orders,
  COUNT(DISTINCT CustomerID) AS total_customers
FROM df
WHERE Quantity > 0 AND UnitPrice > 0;


-- Q2: Top 10 products by revenue
SELECT
  Description,
  ROUND(SUM(Quantity * UnitPrice), 2) AS revenue,
  SUM(Quantity) AS units_sold
FROM df
WHERE Quantity > 0 AND UnitPrice > 0
GROUP BY Description
ORDER BY revenue DESC
LIMIT 10;


-- Q3: Revenue by country
SELECT
  Country,
  ROUND(SUM(Quantity * UnitPrice), 2) AS revenue,
  COUNT(DISTINCT CustomerID) AS customers
FROM df
WHERE Quantity > 0 AND UnitPrice > 0
GROUP BY Country
ORDER BY revenue DESC
LIMIT 15;


-- Q4: Monthly revenue trend
SELECT
  SUBSTR(InvoiceDate, 1, 7) AS month,
  ROUND(SUM(Quantity * UnitPrice), 2) AS monthly_revenue,
  COUNT(DISTINCT InvoiceNo) AS orders
FROM df
WHERE Quantity > 0 AND UnitPrice > 0
GROUP BY month
ORDER BY month;


-- Q5: Top 10 customers by lifetime value
SELECT
  CustomerID,
  COUNT(DISTINCT InvoiceNo) AS total_orders,
  ROUND(SUM(Quantity * UnitPrice), 2) AS lifetime_value
FROM df
WHERE Quantity > 0 AND UnitPrice > 0
  AND CustomerID IS NOT NULL
GROUP BY CustomerID
ORDER BY lifetime_value DESC
LIMIT 10;


-- Q6: Cancellation rate (run against raw, uncleaned data)
SELECT
  COUNT(CASE WHEN InvoiceNo LIKE 'C%' THEN 1 END) AS cancelled,
  COUNT(CASE WHEN InvoiceNo NOT LIKE 'C%' THEN 1 END) AS completed,
  ROUND(COUNT(CASE WHEN InvoiceNo LIKE 'C%' THEN 1 END) * 100.0 / COUNT(*), 2) AS cancel_rate_pct
FROM df_raw;


-- Q7: Average order value by country
SELECT
  Country,
  ROUND(SUM(Quantity * UnitPrice) / COUNT(DISTINCT InvoiceNo), 2) AS avg_order_value
FROM df
WHERE Quantity > 0 AND UnitPrice > 0
GROUP BY Country
ORDER BY avg_order_value DESC
LIMIT 10;


-- Q8: Rank top product within each country (window function)
SELECT * FROM (
  SELECT
    Country, Description,
    ROUND(SUM(Quantity * UnitPrice), 2) AS revenue,
    RANK() OVER (PARTITION BY Country ORDER BY SUM(Quantity * UnitPrice) DESC) AS rnk
  FROM df
  WHERE Quantity > 0 AND UnitPrice > 0
  GROUP BY Country, Description
) ranked
WHERE rnk = 1
ORDER BY revenue DESC
LIMIT 10;


-- Q9: Month-over-month revenue growth % (using LAG)
WITH monthly AS (
  SELECT
    SUBSTR(InvoiceDate, 1, 7) AS month,
    ROUND(SUM(Quantity * UnitPrice), 2) AS revenue
  FROM df
  WHERE Quantity > 0 AND UnitPrice > 0
  GROUP BY month
)
SELECT
  month, revenue,
  LAG(revenue) OVER (ORDER BY month) AS prev_month,
  ROUND((revenue - LAG(revenue) OVER (ORDER BY month)) * 100.0
        / LAG(revenue) OVER (ORDER BY month), 2) AS growth_pct
FROM monthly;


-- Q10: Loyal customers — active in 3+ distinct months
SELECT
  CustomerID,
  COUNT(DISTINCT SUBSTR(InvoiceDate, 1, 7)) AS active_months,
  ROUND(SUM(Quantity * UnitPrice), 2) AS total_spent
FROM df
WHERE Quantity > 0 AND UnitPrice > 0
  AND CustomerID IS NOT NULL
GROUP BY CustomerID
HAVING active_months >= 3
ORDER BY active_months DESC, total_spent DESC
LIMIT 10;