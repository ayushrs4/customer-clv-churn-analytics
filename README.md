Customer CLV & Churn Analytics

Overview:

-This project builds an end-to-end customer analytics pipeline to identify high-value customers, quantify revenue risk due to churn, and prioritize retention actions.
-The analysis combines SQL-based CLV modeling with Python-based churn prediction to move from raw transactional data to actionable business insights.

Business Problem:

Customer churn has a disproportionate impact on revenue when high-value customers disengage.
The goal of this project is to:
-Identify high-value (High-CLV) customers
-Measure revenue concentration and churn exposure
-Predict customer churn probability
-Prioritize high-value customers at risk for targeted retention

Data Description:

The dataset represents a mid-size e-commerce business.

Customers Table:-

-customer_id
-signup_date
-region

Orders Table:-

-order_id
-customer_id
-order_date
-order_value
-order_status
(Only delivered orders are used for revenue and churn analysis.)


Tools:

-PostgreSQL– Data modeling, aggregation, RFM & CLV analysis
-Python– Churn prediction and prioritization
 pandas, NumPy – Data manipulation
scikit-learn – Logistic regression modeling

Methodology:

1️-Customer-Level Aggregation (SQL)
Aggregated transactional data to the customer level

Computed:
Recency (days since last purchase)
Frequency (number of orders)
Monetary value (total revenue)
Defined churn based on customer inactivity

2️-RFM & CLV Modeling (SQL)
Applied RFM scoring using PostgreSQL window functions
Combined RFM scores into a composite CLV score
Segmented customers into:
High CLV
Medium CLV
Low CLV

3️-Business Impact Analysis (SQL)

Key insights from SQL analysis:
High-CLV customers contribute 67.17% of total revenue
High-CLV churn rate is 20%
12.94% of total revenue is at risk due to churn among high-value customers.

4️-Churn Prediction (Python)

Trained a Logistic Regression model to predict churn probability
Features used:
Recency
Frequency
Monetary value
CLV score

Model performance:

ROC-AUC: 1.00(this can be explained because of relatively sample size chosen for this project, ideal score lies around 0.7 to 0.8 when millions of customers are taken into account)


5️-Predictive Risk & Customer Prioritization

-Generated churn probabilities for all customers
-Combined churn probability with CLV segmentation
-Identified High-CLV customers with high churn risk
-Found that ~43% of high value customers are expected to churn in future if no retenting action is done.


Key Insights:

-A small segment of high-value customers constitutes a considerable amount of total revenue.
-Even moderate churn among high-CLV customers leads to significant financial risk
-Customer inactivity is the strongest driver of churn, while frequent and high-spending customers are more loyal


Final Outcome:-

This project demonstrates how SQL analytics and Python modeling can be integrated to:
-Move from raw data to customer segmentation
-Quantify both historical losses and future revenue risk
-Support data-driven retention decision-making
