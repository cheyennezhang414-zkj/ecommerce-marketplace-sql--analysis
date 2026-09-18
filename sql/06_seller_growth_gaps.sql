-- Business question: Which merchants grew completed orders while item revenue did not keep pace?
-- A seller must have at least five orders in the prior active month, and the two observations
-- must be consecutive calendar months, to reduce noise from very small or inactive bases.
WITH seller_monthly AS (
    SELECT
        oi.seller_id,
        strftime('%Y-%m', o.order_purchase_timestamp) AS order_month,
        COUNT(DISTINCT oi.order_id) AS delivered_orders,
        SUM(oi.price) AS item_revenue_brl
    FROM order_items oi
    INNER JOIN orders o ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp IS NOT NULL
    GROUP BY oi.seller_id, strftime('%Y-%m', o.order_purchase_timestamp)
),
with_prior_month AS (
    SELECT
        *,
        LAG(order_month) OVER (PARTITION BY seller_id ORDER BY order_month) AS previous_month,
        LAG(delivered_orders) OVER (PARTITION BY seller_id ORDER BY order_month) AS previous_month_orders,
        LAG(item_revenue_brl) OVER (PARTITION BY seller_id ORDER BY order_month) AS previous_month_revenue_brl
    FROM seller_monthly
),
qualified_gaps AS (
    SELECT
        *,
        delivered_orders - previous_month_orders AS order_change,
        item_revenue_brl - previous_month_revenue_brl AS revenue_change_brl
    FROM with_prior_month
    WHERE previous_month_orders >= 5
      AND order_month = strftime('%Y-%m', DATE(previous_month || '-01', '+1 month'))
      AND delivered_orders > previous_month_orders
      AND item_revenue_brl <= previous_month_revenue_brl
)
SELECT
    ROW_NUMBER() OVER (ORDER BY order_change DESC, revenue_change_brl ASC, seller_id) AS opportunity_rank,
    seller_id,
    order_month,
    previous_month_orders,
    delivered_orders,
    ROUND(100.0 * order_change / previous_month_orders, 1) AS order_growth_pct,
    ROUND(previous_month_revenue_brl, 2) AS previous_month_revenue_brl,
    ROUND(item_revenue_brl, 2) AS item_revenue_brl,
    ROUND(100.0 * revenue_change_brl / previous_month_revenue_brl, 1) AS revenue_growth_pct,
    'Review mix, pricing, and traffic quality' AS recommended_diagnostic
FROM qualified_gaps
ORDER BY opportunity_rank
LIMIT 30;

