-- Executive-level marketplace KPIs used in the README and business recommendations.
WITH delivered_orders AS (
    SELECT o.order_id, c.customer_unique_id,
           DATE(o.order_purchase_timestamp) AS purchase_date,
           o.order_delivered_customer_date,
           o.order_estimated_delivery_date
    FROM orders o
    INNER JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
),
order_value AS (
    SELECT oi.order_id, SUM(oi.price) AS item_revenue_brl
    FROM order_items oi
    INNER JOIN delivered_orders d ON oi.order_id = d.order_id
    GROUP BY oi.order_id
),
seller_revenue AS (
    SELECT oi.seller_id, SUM(oi.price) AS item_revenue_brl
    FROM order_items oi
    INNER JOIN delivered_orders d ON oi.order_id = d.order_id
    GROUP BY oi.seller_id
),
ranked_sellers AS (
    SELECT
        item_revenue_brl,
        RANK() OVER (ORDER BY item_revenue_brl DESC) AS seller_revenue_rank
    FROM seller_revenue
),
customer_frequency AS (
    SELECT customer_unique_id, COUNT(*) AS delivered_order_count
    FROM delivered_orders
    GROUP BY customer_unique_id
),
delivery_metrics AS (
    SELECT
        COUNT(*) AS dated_deliveries,
        SUM(CASE
                WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 1
                ELSE 0
            END) AS late_deliveries
    FROM delivered_orders
    WHERE order_delivered_customer_date IS NOT NULL
      AND order_estimated_delivery_date IS NOT NULL
)
SELECT 'Delivered item revenue (BRL)' AS metric,
       ROUND((SELECT SUM(item_revenue_brl) FROM order_value), 2) AS value,
       'Sum of item price on delivered orders; excludes freight and platform fees.' AS definition
UNION ALL
SELECT 'Delivered orders',
       (SELECT COUNT(*) FROM delivered_orders),
       'Completed-order population.'
UNION ALL
SELECT 'Active sellers',
       (SELECT COUNT(*) FROM seller_revenue),
       'Sellers with at least one delivered order item.'
UNION ALL
SELECT 'Top 10 seller revenue share (%)',
       ROUND(100.0 * (SELECT SUM(item_revenue_brl) FROM ranked_sellers WHERE seller_revenue_rank <= 10)
             / (SELECT SUM(item_revenue_brl) FROM ranked_sellers), 2),
       'Concentration of delivered item revenue among the top ten sellers.'
UNION ALL
SELECT 'Repeat customer rate (%)',
       ROUND(100.0 * (SELECT COUNT(*) FROM customer_frequency WHERE delivered_order_count >= 2)
             / (SELECT COUNT(*) FROM customer_frequency), 2),
       'Share of unique customers with at least two delivered orders.'
UNION ALL
SELECT 'Late delivery rate (%)',
       ROUND(100.0 * (SELECT late_deliveries FROM delivery_metrics)
             / (SELECT dated_deliveries FROM delivery_metrics), 2),
       'Actual delivery date later than the estimated delivery date; only dated delivered orders.'
UNION ALL
SELECT 'Observed purchase window',
       (SELECT MIN(purchase_date) || ' to ' || MAX(purchase_date) FROM delivered_orders),
       'Delivered-order purchase dates present in the public source.';

