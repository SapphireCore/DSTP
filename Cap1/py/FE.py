# coding: utf-8

# # Capstone Project 1
# # Lending Club Loan Status Analysis

# Part I

# Load in Dataset
import pandas as pd
loan = pd.read_csv("../LendingClubLoan/loan.csv", low_memory=False)
pd.set_option('display.max_columns', 100)

# Drop variable without description
loan.drop(["verification_status_joint"], axis = 1, inplace = True)

# Check missing values
exclude_var = (loan.isnull().sum(axis = 0) / loan.shape[0]).sort_values(ascending = False)
exclude_var = exclude_var[exclude_var >= 0.95]
loan.drop(exclude_var.index, axis = 1, inplace = True)

toDrop = ['id', 'member_id', 'url','desc','title', 'zip_code','policy_code', 'pymnt_plan', 'application_type']
loan.drop(toDrop, axis = 1, inplace = True)

# Convert date string to datetime type.
loan['issue_d'] = pd.to_datetime(loan['issue_d'])
loan['last_pymnt_d'] = pd.to_datetime(loan['last_pymnt_d'])
loan['next_pymnt_d'] = pd.to_datetime(loan['next_pymnt_d'])
loan['last_credit_pull_d'] = pd.to_datetime(loan['last_credit_pull_d'])

# Strip term as numbers instead of strings.
# Convert interst rate to 0-1 range by dividing by 100.
loan['term'] = loan['term'].str.split(' ').str[1]
loan['int_rate'] = loan['int_rate'] / 100.0

# Part 2: Data Storytelling - Create New Target

# Recode the status to form a simpler status variable named loan_status_simple
# Good (0): Current, Fully Paid
# Bad (1):  Default, Late (all types), In Grace Period, Charge Off
# Issued: leave blank for scoring

loan_dict = {
    "Does not meet the credit policy. Status:Charged Off": "Bad",
    "Default": "Bad",
    "Does not meet the credit policy. Status:Fully Paid": "Good",
    "Late (16-30 days)": "Bad",
    "In Grace Period": "Bad",
    "Issued": "Issued",
    "Late (31-120 days)":"Bad",
    "Charged Off":"Bad",
    "Fully Paid": "Good",
    "Current": "Good"
}
loan["loan_status_simple"] = loan["loan_status"].map(loan_dict)

loan.drop(["loan_status"], axis = 1, inplace = True)

# Part 3: Exploratory Data Analysis

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

# Numerical Features
# Using the maximum values (excluding 9999 or 9999999) to replace these max-out values should be reasonable for standard scaling.

loan.dti.replace(9999.0, 1092.52, inplace=True)
loan.total_rev_hi_lim.replace(9999999.0, 2013133.0, inplace=True)

# Impute missing values of numerical features using column means
num_features = loan.select_dtypes(include=["float64"]).columns

for num_feature in num_features: 
    loan[num_feature] = loan[num_feature].fillna(loan[num_feature].mean())

# Drop features that have potential data leakage
dropped_num_features = ["loan_amnt", "funded_amnt_inv", "installment", "out_prncp_inv", "total_pymnt_inv", "total_rec_prncp", "total_rev_hi_lim","collection_recovery_fee"]
loan.drop(dropped_num_features, axis = 1, inplace = True)

# Categorical Features
# Construct a list of categorical features
cat_features = loan.select_dtypes(include=["object"]).columns

# Drop grade, sub_grade and emp_title.
loan.drop(["grade", "sub_grade", "emp_title"], axis = 1, inplace = True)

# Create emp_length_yr from emp_length.
import numpy as np

emp_length_dict = {
    "9 years": 9,
    "6 years": 6,
    "8 years": 8,
    "7 years": 7,
    "n/a": np.nan,
    "4 years": 4,
    "5 years": 5,
    "1 year" : 1,
    "3 years": 3,
    "< 1 year": 0,
    "2 years": 2,
    "10+ years": 10
}

loan["emp_length_yr"] = loan["emp_length"].map(emp_length_dict)
loan.drop("emp_length", axis = 1, inplace = True)

# Consolidate levels for home_ownership

home_own_dict = {
    "ANY": "OTHER",
    "NONE": "OTHER",
    "OTHER": "OTHER",
    "OWN": "OWN",
    "RENT": "RENT",
    "MORTGAGE": "MORTGAGE"
}

loan["home_owner_s"] = loan["home_ownership"].map(home_own_dict)
loan.drop("home_ownership", axis = 1, inplace = True)

# Calculate length of credit history in years (cr_hist_yr)

loan['cr_hist_yr'] = loan.issue_d.dt.year - loan.earliest_cr_line.str.split('-').str[1].astype("float")
loan.drop("earliest_cr_line", axis = 1, inplace = True)

# Drop date features
exclude = ["issue_d", "last_pymnt_d", "next_pymnt_d", "last_credit_pull_d"]
loan.drop(exclude, axis = 1, inplace = True)

# Construct a list of categorical features
cat_features = loan.select_dtypes(include=["object"]).columns.drop("loan_status_simple")

# Fill missing values of categorical features using MISSING as a category
for cat_feature in cat_features: 
    loan[cat_feature] = loan[cat_feature].fillna("MISSING")

# Two newly generated numerical features (in categorical feature section) still have missing values.
loan["emp_length_yr"] = loan["emp_length_yr"].fillna(loan["emp_length_yr"].mean())
loan["cr_hist_yr"] = loan["cr_hist_yr"].fillna(loan["cr_hist_yr"].mean())