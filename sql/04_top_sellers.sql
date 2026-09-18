-- Business question: How concentrated is completed-order item revenue among merchants?
-- Advanced SQL: RANK and cumulative window sums show both individual and cumulative share.
WITH seller_performance AS (
    SELECT
        oi.seller_id,
        s.seller_state,
        COUNT(DISTINCT oi.order_id) AS delivered_orders,
        COUNT(*) AS delivered_units,
        SUM(oi.price) AS item_revenue_brl,
        AVG(oi.price) AS average_item_price_brl
    FROM order_items oi
    INNER JOIN orders o ON oi.order_id = o.order_id
    INNER JOIN sellers s ON oi.seller_id = s.seller_id
    WHERE o.order_status = 'delivered'
    GROUP BY oi.seller_id, s.seller_state
),
ranked_sellers AS (
    SELECT
        *,
        RANK() OVER (ORDER BY item_revenue_brl DESC) AS seller_revenue_rank,
        100.0 * item_revenue_brl / SUM(item_revenue_brl) OVER () AS seller_revenue_share_pct,
        100.0 * SUM(item_revenue_brl) OVER (
            ORDER BY item_revenue_brl DESC, seller_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) / SUM(item_revenue_brl) OVER () AS cumulative_revenue_share_pct
    FROM seller_performance
)
SELECT
    seller_revenue_rank,
    seller_id,
    seller_state,
    delivered_orders,
    delivered_units,
    ROUND(item_revenue_brl, 2) AS item_revenue_brl,
    ROUND(average_item_price_brl, 2) AS average_item_price_brl,
    ROUND(seller_revenue_share_pct, 2) AS seller_revenue_share_pct,
    ROUND(cumulative_revenue_share_pct, 2) AS cumulative_revenue_share_pct
FROM ranked_sellers
WHERE seller_revenue_rank <= 20
ORDER BY seller_revenue_rank, seller_id;

