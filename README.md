# Project 2 – Advanced SQL Analysis (WideWorldImporters)

This project includes a collection of advanced SQL queries and views based on the WideWorldImporters sample database. It focuses on extracting business insights, generating ranked reports, and identifying customer trends.

## 📌 Objectives:
- Practice writing complex SQL queries using CTEs and window functions.
- Analyze customer behavior, sales trends, and product profitability.
- Generate reports with rankings, pivots, and cumulative calculations.
- Identify potential churn and segment customers by category.

## 🗃️ Data Source:
- **Database:** [WideWorldImporters sample DB](https://github.com/Microsoft/sql-server-samples/tree/master/samples/databases/wide-world-importers)

## 🛠️ Technologies:
- Microsoft SQL Server
- T-SQL (Transact-SQL)
- SQL Server Management Studio (SSMS)

## 🔍 Highlights of Queries:
1. **Yearly Sales Trend & Forecasting** – Linearized income growth across years.
2. **Top Customers by Quarter** – Using `RANK()` and filtering top 5 per quarter.
3. **Top 10 Profitable Products** – Based on profit margin.
4. **Active Stock Items Profit Ranking** – Including nominal profit calculation.
5. **Supplier Product List** – Using nested string aggregation.
6. **Top 5 Customers by Total Purchases** – With geographic segmentation.
7. **Monthly + Cumulative Totals** – Using `UNION` + window functions.
8. **Pivot of Monthly Order Counts** – With zero-fill for missing months.
9. **Customer Churn Detection** – Based on average order frequency.
10. **Customer Category Risk Analysis** – With percentage distribution.

## 📁 File:
- `Eden_Sivan_Nizri_Project2.sql`: Contains all queries and views.

---

✅ This repository is part of the final portfolio submitted in the Data Analyst program.
