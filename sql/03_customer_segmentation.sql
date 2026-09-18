-- Business question: Which customer segments create the most completed-order value?
-- Advanced SQL: CTEs build customer-level metrics; RANK, ROW_NUMBER, and NTILE
-- create reusable value and regional ranking features before segmenting customers.
WITH delivered_order_value AS (
    SELECT
        o.order_id,
        c.customer_unique_id,
        c.customer_state,
        DATE(o.order_purchase_timestamp) AS purchase_date,
        SUM(oi.price) AS item_revenue_brl
    FROM orders o
    INNER JOIN customers c ON o.customer_id = c.customer_id
    INNER JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp IS NOT NULL
    GROUP BY o.order_id, c.customer_unique_id, c.customer_state, DATE(o.order_purchase_timestamp)
),
customer_metrics AS (
    SELECT
        customer_unique_id,
        customer_state,
        COUNT(*) AS delivered_order_count,
        SUM(item_revenue_brl) AS customer_revenue_brl,
        MAX(purchase_date) AS last_purchase_date
    FROM delivered_order_value
    GROUP BY customer_unique_id, customer_state
),
benchmarks AS (
    SELECT
        AVG(customer_revenue_brl) AS average_customer_revenue_brl,
        MAX(last_purchase_date) AS analysis_snapshot_date
    FROM customer_metrics
),
scored_customers AS (
    SELECT
        cm.*,
        CAST(julianday(b.analysis_snapshot_date) - julianday(cm.last_purchase_date) AS INTEGER) AS recency_days,
        RANK() OVER (ORDER BY cm.customer_revenue_brl DESC) AS customer_revenue_rank,
        ROW_NUMBER() OVER (
            PARTITION BY cm.customer_state
            ORDER BY cm.customer_revenue_brl DESC, cm.customer_unique_id
        ) AS state_revenue_rank,
        NTILE(4) OVER (ORDER BY cm.customer_revenue_brl DESC) AS monetary_quartile,
        b.average_customer_revenue_brl
    FROM customer_metrics cm
    CROSS JOIN benchmarks b
),
segmented_customers AS (
    SELECT
        *,
        CASE
            WHEN delivered_order_count >= 2
             AND customer_revenue_brl >= average_customer_revenue_brl THEN 'High-value repeat buyer'
            WHEN delivered_order_count >= 2 THEN 'Repeat buyer'
            WHEN customer_revenue_brl >= average_customer_revenue_brl THEN 'High-value one-time buyer'
            ELSE 'One-time buyer'
        END AS customer_segment
    FROM scored_customers
)
SELECT
    customer_segment,
    COUNT(*) AS customers,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS customer_share_pct,
    SUM(delivered_order_count) AS delivered_orders,
    ROUND(SUM(customer_revenue_brl), 2) AS item_revenue_brl,
    ROUND(AVG(customer_revenue_brl), 2) AS average_customer_revenue_brl,
    ROUND(AVG(recency_days), 1) AS average_recency_days,
    SUM(CASE WHEN customer_revenue_rank <= 100 THEN 1 ELSE 0 END) AS customers_in_platform_top_100_revenue
FROM segmented_customers
GROUP BY customer_segment
ORDER BY item_revenue_brl DESC;

