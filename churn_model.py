# =====================================================
# SIMPLE & ROBUST CHURN PREDICTION SCRIPT
# =====================================================

import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import roc_auc_score

print("Step 1: Loading data...")

# Load CSV (relative path)
df = pd.read_csv("data/customer_churn_model.csv")

print("✔ Data loaded successfully")
print(df.head())
print("\nColumns:", list(df.columns))


# -----------------------------------------------------
# Step 2: Basic checks
# -----------------------------------------------------
print("\nStep 2: Checking churn distribution...")
print(df["churn_flag"].value_counts(normalize=True) * 100)


# -----------------------------------------------------
# Step 3: Feature selection
# -----------------------------------------------------
print("\nStep 3: Selecting features...")

features = ["recency_days", "frequency", "monetary", "clv_score"]

X = df[features]
y = df["churn_flag"]

print("✔ Features selected:", features)


# -----------------------------------------------------
# Step 4: Train-test split
# -----------------------------------------------------
print("\nStep 4: Splitting data...")

X_train, X_test, y_train, y_test = train_test_split(
    X,
    y,
    test_size=0.3,
    random_state=42,
    stratify=y
)

print("✔ Train-test split complete")


# -----------------------------------------------------
# Step 5: Train model
# -----------------------------------------------------
print("\nStep 5: Training Logistic Regression model...")

model = LogisticRegression(max_iter=1000)
model.fit(X_train, y_train)

print("✔ Model trained")


# -----------------------------------------------------
# Step 6: Evaluate model
# -----------------------------------------------------
print("\nStep 6: Evaluating model...")

y_prob = model.predict_proba(X_test)[:, 1]
roc = roc_auc_score(y_test, y_prob)

print("✔ ROC-AUC score:", round(roc, 3))


# -----------------------------------------------------
# Step 7: Churn probability for all customers
# -----------------------------------------------------
print("\nStep 7: Calculating churn probability for all customers...")

df["churn_probability"] = model.predict_proba(X)[:, 1]

print(df[["customer_id", "churn_probability"]].head())


# -----------------------------------------------------
# Step 8: Priority customers (High CLV + High Risk)
# -----------------------------------------------------
print("\nStep 8: Identifying priority customers...")

priority_customers = df[
    (df["clv_segment"] == "High CLV") &
    (df["churn_probability"] >= 0.6)
]

print("✔ Priority customers found:", len(priority_customers))
print(priority_customers[["customer_id", "clv_score", "churn_probability"]].head())


print("\n=== SCRIPT COMPLETED SUCCESSFULLY ===")
