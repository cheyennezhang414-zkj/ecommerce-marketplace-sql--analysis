-- Business question: Which product categories combine revenue, volume, and price potential?
-- Item revenue is the sum of item price and excludes freight, discounts, and platform fees.
WITH category_performance AS (
    SELECT
        COALESCE(ct.product_category_name_english, p.product_category_name, 'unknown') AS product_category,
        COUNT(*) AS delivered_units,
        COUNT(DISTINCT oi.order_id) AS delivered_orders,
        SUM(oi.price) AS item_revenue_brl,
        AVG(oi.price) AS average_item_price_brl
    FROM order_items oi
    INNER JOIN orders o ON oi.order_id = o.order_id
    INNER JOIN products p ON oi.product_id = p.product_id
    LEFT JOIN category_translation ct ON p.product_category_name = ct.product_category_name
    WHERE o.order_status = 'delivered'
    GROUP BY COALESCE(ct.product_category_name_english, p.product_category_name, 'unknown')
),
scored_categories AS (
    SELECT
        *,
        RANK() OVER (ORDER BY item_revenue_brl DESC) AS category_revenue_rank,
        NTILE(4) OVER (ORDER BY delivered_units DESC) AS volume_quartile,
        NTILE(4) OVER (ORDER BY average_item_price_brl ASC) AS price_quartile
    FROM category_performance
)
SELECT
    category_revenue_rank,
    product_category,
    delivered_units,
    delivered_orders,
    ROUND(item_revenue_brl, 2) AS item_revenue_brl,
    ROUND(100.0 * item_revenue_brl / SUM(item_revenue_brl) OVER (), 2) AS revenue_share_pct,
    ROUND(average_item_price_brl, 2) AS average_item_price_brl,
    CASE
        WHEN volume_quartile = 1 AND price_quartile = 1
            THEN 'High-volume, low-price: test bundles or cross-sell'
        WHEN category_revenue_rank <= 10
            THEN 'Top-revenue category: protect availability and seller quality'
        ELSE 'Monitor'
    END AS operating_signal
FROM scored_categories
ORDER BY category_revenue_rank, product_category;

