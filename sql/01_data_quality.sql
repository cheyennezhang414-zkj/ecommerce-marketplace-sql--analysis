-- Purpose: confirm the grain and integrity of the tables used by the analysis.
-- Business rule: a completed transaction is an order with order_status = 'delivered'.
WITH checks AS (
    SELECT 1 AS check_order, 'Orders in source' AS metric, COUNT(*) AS value,
           'All order-status records, including cancelled and unavailable orders.' AS interpretation
    FROM orders

    UNION ALL

    SELECT 2, 'Delivered orders', COUNT(*),
           'Completed-order population used for revenue and merchant analyses.'
    FROM orders
    WHERE order_status = 'delivered'

    UNION ALL

    SELECT 3, 'Order line items', COUNT(*),
           'Item-level records. One order can contain more than one line item.'
    FROM order_items

    UNION ALL

    SELECT 4, 'Orders without a matched customer', COUNT(*),
           'Expected to be zero after the orders-to-customers join.'
    FROM orders o
    LEFT JOIN customers c ON o.customer_id = c.customer_id
    WHERE c.customer_id IS NULL

    UNION ALL

    SELECT 5, 'Order items without a matched product', COUNT(*),
           'Expected to be zero after the order_items-to-products join.'
    FROM order_items oi
    LEFT JOIN products p ON oi.product_id = p.product_id
    WHERE p.product_id IS NULL

    UNION ALL

    SELECT 6, 'Order items without a matched seller', COUNT(*),
           'Expected to be zero after the order_items-to-sellers join.'
    FROM order_items oi
    LEFT JOIN sellers s ON oi.seller_id = s.seller_id
    WHERE s.seller_id IS NULL

    UNION ALL

    SELECT 7, 'Delivered orders missing actual delivery date', COUNT(*),
           'Excluded from delivery-timeliness calculations.'
    FROM orders
    WHERE order_status = 'delivered'
      AND order_delivered_customer_date IS NULL
)
SELECT metric, value, interpretation
FROM checks
ORDER BY check_order;

