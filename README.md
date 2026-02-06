# Project-2---Bicycle-Manufacturer-SQL-
# I. Introduction
This project contains an eCommerce dataset that I will explore using SQL on Google BigQuery. The dataset is based on the Google Analytics public dataset and contains data from an eCommerce website.
# II. Requirement
    - Google Cloud Platform account
    - Project on Google Cloud Platform
    - Google Bigquery API enabled
    - SQL query editor or IDE
# III. Dataset Access
The eCommerce dataset is available in a public Google BigQuery dataset. To access it, complete the following steps:
   - Sign in to your Google Cloud Platform account and create a new project.
   - Open the BigQuery console and choose the project you just created.
   - From the navigation menu, click Add Data, then select Search a project.
   - Enter the project ID bigquery-public-data.google_analytics_sample.ga_sessions and press Enter.
   - Click on the ga_sessions_* table to view the data.

https://support.google.com/analytics/answer/3437719?hl=en
<img width="924" height="712" alt="Image" src="https://github.com/user-attachments/assets/e962f770-00d9-4764-b1d0-55a2832677dd" />
# IV. Explore the Dataset
In this project, I will write 08 query in Bigquery base on Google Analytics dataset
# Query 01: Calc Quantity of items, Sales value & Order quantity by each Subcategory in L12M
- SQL code


- Query results


# Query 02: Calc % YoY growth rate by SubCategory & release top 3 cat with highest grow rate. Can use metric: quantity_item. Round results to 2 decimal qty_diff = qty_item / prv_qty - 1
- SQL code
- Query results


# Query 3: Ranking Top 3 TeritoryID with biggest Order quantity of every year. If there's TerritoryID with same quantity in a year, do not skip the rank number
- SQL code


- Query results


# Query 04: Calc Total Discount Cost belongs to Seasonal Discount for each SubCategory

- SQL code


- Query results


# Query 05: Retention rate of Customer in 2014 with status of Successfully Shipped (Cohort Analysis)
- SQL code


- Query results


# Query 06: Trend of Stock level & MoM diff % by all product in 2011. If %gr rate is null then 0. Round to 1 decimal

- SQL code


- Query results


# Query 07: Calc Ratio of Stock / Sales in 2011 by product name, by month. Order results by month desc, ratio desc. Round Ratio to 1 decimal mom yoy

- SQL code


- Query results


# Query 08: No of order and value at Pending status in 2014
- SQL code


- Query results
