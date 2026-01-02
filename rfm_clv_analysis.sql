/* ============================================================
   CUSTOMER LIFETIME VALUE & CHURN ANALYTICS
   Database: PostgreSQL
   ============================================================ */


/* ============================================================
   STEP 1: CUSTOMER-LEVEL AGGREGATION
   - Aggregate orders at customer level
   - Calculate recency, frequency, monetary value
   - Define churn flag
   ============================================================ */

CREATE OR REPLACE VIEW final_customer_table AS
SELECT
    c.customer_id,
    c.region,

    COUNT(o.order_id) AS total_orders,
    SUM(o.order_value) AS total_revenue,
    AVG(o.order_value) AS avg_order_value,

    MIN(o.order_date) AS first_order_date,
    MAX(o.order_date) AS last_order_date,

    CURRENT_DATE - MAX(o.order_date) AS recency_days,

    CASE
        WHEN CURRENT_DATE - MAX(o.order_date) > 90 THEN 1
        ELSE 0
    END AS churn_flag

FROM customers c
LEFT JOIN orders o
    ON c.customer_id = o.customer_id
    AND o.order_status = 'Delivered'

GROUP BY
    c.customer_id,
    c.region;


/* ============================================================
   STEP 2: RFM BASE METRICS
   - Rename metrics into standard RFM terminology
   ============================================================ */

CREATE OR REPLACE VIEW rfm_base AS
SELECT
    customer_id,
    recency_days,
    total_orders AS frequency,
    total_revenue AS monetary,
    churn_flag
FROM final_customer_table;


/* ============================================================
   STEP 3: RFM SCORING (CRITICAL LOGIC)
   - Higher score = better customer
   - Recency: lower days = better
   - Frequency: higher count = better
   - Monetary: higher spend = better
   ============================================================ */

CREATE OR REPLACE VIEW rfm_scores AS
SELECT
    customer_id,
    recency_days,
    frequency,
    monetary,
    churn_flag,

    /* Recency: lower recency_days = better */
    NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,

    /* Frequency: higher frequency = better */
    NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,

    /* Monetary: higher spend = better */
    NTILE(5) OVER (ORDER BY monetary ASC) AS m_score

FROM rfm_base;


/* ============================================================
   STEP 4: CLV SCORING
   - Combine R, F, M into a single CLV score
   ============================================================ */

CREATE OR REPLACE VIEW clv_scores AS
SELECT
    customer_id,
    r_score,
    f_score,
    m_score,
    (r_score + f_score + m_score) AS clv_score,
    churn_flag
FROM rfm_scores;


/* ============================================================
   STEP 5: CLV SEGMENTATION
   - Translate numeric CLV score into business segments
   ============================================================ */

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


/* ============================================================
   STEP 6: BUSINESS IMPACT ANALYSIS QUERIES
   (Run manually when needed)
   ============================================================ */


/* 6.1 Revenue contribution by CLV segment */
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


/* 6.2 Churn rate within each CLV segment */
SELECT
    clv_segment,
    ROUND(
        100.0 * SUM(churn_flag) / COUNT(*),
        2
    ) AS churn_percentage
FROM clv_segments
GROUP BY clv_segment;


/* 6.3 Revenue at risk due to churned High-CLV customers */
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
