# coding: utf-8

# # Capstone Project 1
# # Lending Club Loan Status Analysis
# ## Part 1: Data Wrangling
# 
# Data Source: Kaggle Dataset -- Lending Club Loan Data  
# URL: https://www.kaggle.com/wendykan/lending-club-loan-data  
# Analyst: Eugene Wen

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