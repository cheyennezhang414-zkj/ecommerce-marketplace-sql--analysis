-- Business question: How did delivered item revenue and demand change month to month?
-- Method: aggregate each delivered order first so multi-item orders are not double-counted.
WITH delivered_order_value AS (
    SELECT
        o.order_id,
        strftime('%Y-%m', o.order_purchase_timestamp) AS order_month,
        c.customer_unique_id,
        SUM(oi.price) AS item_revenue_brl
    FROM orders o
    INNER JOIN customers c ON o.customer_id = c.customer_id
    INNER JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp IS NOT NULL
    GROUP BY o.order_id, strftime('%Y-%m', o.order_purchase_timestamp), c.customer_unique_id
),
monthly AS (
    SELECT
        order_month,
        COUNT(*) AS delivered_orders,
        COUNT(DISTINCT customer_unique_id) AS active_customers,
        SUM(item_revenue_brl) AS item_revenue_brl,
        AVG(item_revenue_brl) AS average_order_value_brl
    FROM delivered_order_value
    GROUP BY order_month
),
with_previous_month AS (
    SELECT
        *,
        LAG(delivered_orders) OVER (ORDER BY order_month) AS previous_month_orders,
        LAG(item_revenue_brl) OVER (ORDER BY order_month) AS previous_month_revenue_brl,
        MAX(order_month) OVER () AS latest_observed_month
    FROM monthly
)
SELECT
    order_month,
    delivered_orders,
    active_customers,
    ROUND(item_revenue_brl, 2) AS item_revenue_brl,
    ROUND(average_order_value_brl, 2) AS average_order_value_brl,
    ROUND(
        100.0 * (item_revenue_brl - previous_month_revenue_brl)
        / NULLIF(previous_month_revenue_brl, 0),
        1
    ) AS revenue_mom_pct,
    ROUND(
        100.0 * (delivered_orders - previous_month_orders)
        / NULLIF(previous_month_orders, 0),
        1
    ) AS orders_mom_pct,
    CASE
        WHEN order_month = latest_observed_month THEN 'Latest observed month: interpret with care'
        ELSE 'Full historical month in source'
    END AS coverage_note
FROM with_previous_month
ORDER BY order_month;

