import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import classification_report, roc_auc_score


df = pd.read_csv("customer_churn_model.csv")
print(df.head())
print("\nChurn distribution (counts):")
print(df['churn_flag'].value_counts())

print("\nChurn distribution (percentages):")
print(df['churn_flag'].value_counts(normalize=True) * 100)
print("\nAverage feature values by churn status:")
print(
    df.groupby('churn_flag')[['recency_days', 'frequency', 'monetary', 'clv_score']].mean()
)
features = [
    'recency_days',
    'frequency',
    'monetary',
    'clv_score'
]

X = df[features]
y = df['churn_flag']
X_train, X_test, y_train, y_test = train_test_split(
    X,
    y,
    test_size=0.3,
    random_state=42,
    stratify=y
)
print("Train churn %:")
print(y_train.value_counts(normalize=True) * 100)

print("\nTest churn %:")
print(y_test.value_counts(normalize=True) * 100)
model = LogisticRegression(max_iter=1000)
model.fit(X_train, y_train)
y_pred = model.predict(X_test)
y_prob = model.predict_proba(X_test)[:, 1]
print("Classification Report:\n")
print(classification_report(y_test, y_pred))
roc = roc_auc_score(y_test, y_prob)
print("ROC AUC Score:", round(roc, 3))
coef_df = pd.DataFrame({
    'feature': features,
    'coefficient': model.coef_[0]
}).sort_values(by='coefficient', ascending=False)

print(coef_df)
df['churn_probability'] = model.predict_proba(X)[:, 1]
print(df[['customer_id', 'churn_probability']].head())
priority_customers = df[
    (df['clv_segment'] == 'High CLV') &
    (df['churn_probability'] >= 0.6)
].sort_values(by='churn_probability', ascending=False)
print(priority_customers[
    ['customer_id', 'clv_segment', 'clv_score', 'churn_probability']
].head(10))
total_high_clv = df[df['clv_segment'] == 'High CLV'].shape[0]
at_risk_high_clv = priority_customers.shape[0]

print(
    f"High-CLV customers at high churn risk: "
    f"{round(100 * at_risk_high_clv / total_high_clv, 2)}%"
)

