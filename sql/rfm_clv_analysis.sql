CREATE OR REPLACE VIEW final_customer_table AS
WITH delivered_orders AS (
    SELECT
        customer_id,
        order_id,
        order_date,
        order_value
    FROM orders
    WHERE order_status = 'Delivered'
),

customer_metrics AS (
    SELECT
        customer_id,
        COUNT(order_id) AS total_orders,
        SUM(order_value) AS total_revenue,
        AVG(order_value) AS avg_order_value,
        MIN(order_date) AS first_order_date,
        MAX(order_date) AS last_order_date
    FROM delivered_orders
    GROUP BY customer_id
)

SELECT
    c.customer_id,
    c.region,
    cm.total_orders,
    cm.total_revenue,
    cm.avg_order_value,
    cm.first_order_date,
    cm.last_order_date,
    (CURRENT_DATE - cm.last_order_date) AS recency_days,
    CASE
        WHEN (CURRENT_DATE - cm.last_order_date) > 90 THEN 1
        ELSE 0
    END AS churn_flag
FROM customers c
LEFT JOIN customer_metrics cm
ON c.customer_id = cm.customer_id;
SELECT * FROM final_customer_table;
CREATE OR REPLACE VIEW rfm_base AS
SELECT
    customer_id,
    recency_days,
    total_orders AS frequency,
    total_revenue AS monetary,
    churn_flag
FROM final_customer_table;
SELECT * FROM rfm_base;
CREATE OR REPLACE VIEW rfm_scores AS
SELECT
    customer_id,
    recency_days,
    frequency,
    monetary,
    churn_flag,

    NTILE(5) OVER (ORDER BY recency_days DESC)    AS r_score,
    NTILE(5) OVER (ORDER BY frequency ASC)      AS f_score,
    NTILE(5) OVER (ORDER BY monetary ASC)       AS m_score
FROM rfm_base;
SELECT
    customer_id,
    recency_days,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score
FROM rfm_scores
ORDER BY customer_id;
CREATE OR REPLACE VIEW clv_scores AS
SELECT
    customer_id,
    r_score,
    f_score,
    m_score,
    (r_score + f_score + m_score) AS clv_score,
    churn_flag
FROM rfm_scores;
SELECT
    customer_id,
    r_score,
    f_score,
    m_score,
    clv_score
FROM clv_scores
ORDER BY clv_score DESC;
CREATE OR REPLACE VIEW clv_segments AS
SELECT
    customer_id,
    clv_score,
    churn_flag,
    CASE
        WHEN clv_score >= 12 THEN 'High CLV'
        WHEN clv_score BETWEEN 8 AND 11 THEN 'Medium CLV'
        ELSE 'Low CLV'
    END AS clv_segment
FROM clv_scores;
SELECT
    clv_segment,
    COUNT(*) AS customer_count
FROM clv_segments
GROUP BY clv_segment
ORDER BY customer_count DESC;
SELECT
    cs.clv_segment,
    ROUND(
        100.0 * SUM(f.total_revenue)
        / SUM(SUM(f.total_revenue)) OVER (),
        2
    ) AS revenue_percentage
FROM clv_segments cs
JOIN final_customer_table f
    ON cs.customer_id = f.customer_id
GROUP BY cs.clv_segment
ORDER BY revenue_percentage DESC;
SELECT
    clv_segment,
    ROUND(
        100.0 * SUM(churn_flag) / COUNT(*),
        2
    ) AS churn_percentage
FROM clv_segments
GROUP BY clv_segment
ORDER BY churn_percentage DESC;
SELECT
    ROUND(
        100.0 * SUM(f.total_revenue)
        FILTER (
            WHERE cs.clv_segment = 'High CLV'
              AND cs.churn_flag = 1
        )
        / SUM(f.total_revenue),
        2
    ) AS high_clv_revenue_at_risk_pct
FROM clv_segments cs
JOIN final_customer_table f
    ON cs.customer_id = f.customer_id;
SELECT
    f.customer_id,
    f.recency_days,
    f.total_orders AS frequency,
    f.total_revenue AS monetary,
    c.clv_score,
    s.clv_segment,
    f.churn_flag
FROM final_customer_table f
JOIN clv_scores c
    ON f.customer_id = c.customer_id
JOIN clv_segments s
    ON f.customer_id = s.customer_id;
