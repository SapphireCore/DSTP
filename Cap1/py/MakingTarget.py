
# coding: utf-8

# # Capstone Project 1
# # Lending Club Loan Status Analysis
# ## Part 2: Data Storytelling with Engineered Features
# A few new features generated in data storytelling part.
# These are documented as MakingTarget.py.

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

# Added the new Target variable created in Part II.

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
