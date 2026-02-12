# Project-2---Bicycle-Manufacturer-SQL-
# I. Introduction
- This is a sample Dataedo documentation - AdventureWorks - Microsoft SQL Server sample database.
- The AdventureWorks database supports standard online transaction processing scenarios for a fictitious bicycle
manufacturer (Adventure Works Cycles). Scenarios include Manufacturing, Sales, Purchasing, Product Management,
Contact Management, and Human Resources.
# II. Requirement
    - Google Cloud Platform account
    - Project on Google Cloud Platform
    - Google Bigquery API enabled
    - SQL query editor or IDE
# III. Dataset Access
The eCommerce dataset is available in a public Google BigQuery dataset. To access it, complete the following steps:
   - Sign in to your Google Cloud Platform account and create a new project.
   - Open the BigQuery console and choose the project you just created.
   - From the navigation menu, click Add Data, then select start a project by name.
   - Enter the adventureworks2019 and press Start

https://drive.google.com/file/d/1bwwsS3cRJYOg1cvNppc1K_8dQLELN16T/view?usp=sharing
# IV. Explore the Dataset
In this project, I will write 08 query in Bigquery base on Google Analytics dataset
## Query 01: Calc Quantity of items, Sales value & Order quantity by each Subcategory in L12M
- SQL code
```sql 
SELECT 
  FORMAT_DATETIME("%b %Y",saleorder.ModifiedDate) AS Period
  ,productsub.Name AS Category
  ,SUM(OrderQty) AS qty
  ,SUM(saleorder.LineTotal) AS total_sales
  ,COUNT(DISTINCT saleorder.SalesOrderID ) AS order_qty
FROM adventureworks2019.Sales.SalesOrderDetail saleorder
LEFT JOIN adventureworks2019.Production.Product product
  ON product.ProductID  = saleorder.ProductID
LEFT JOIN adventureworks2019.Production.ProductSubcategory productsub
  ON CAST(product.ProductSubcategoryID as int ) = productsub.ProductSubcategoryID
WHERE DATE(saleorder.ModifiedDate) >= 
          (SELECT DATE_SUB(MAX(DATE(ModifiedDate)), INTERVAL 12 month)
          FROM adventureworks2019.Sales.SalesOrderDetail)
GROUP BY Period, Category
ORDER BY Period DESC,Category;
```
- Query results


##  Query 02: Calc % YoY growth rate by SubCategory & release top 3 cat with highest grow rate. Can use metric: quantity_item. Round results to 2 decimal qty_diff = qty_item / prv_qty - 1
- SQL code
- Query results


##  Query 3: Ranking Top 3 TeritoryID with biggest Order quantity of every year. If there's TerritoryID with same quantity in a year, do not skip the rank number
- SQL code


- Query results


##  Query 04: Calc Total Discount Cost belongs to Seasonal Discount for each SubCategory

- SQL code


- Query results


##  Query 05: Retention rate of Customer in 2014 with status of Successfully Shipped (Cohort Analysis)
- SQL code


- Query results


##  Query 06: Trend of Stock level & MoM diff % by all product in 2011. If %gr rate is null then 0. Round to 1 decimal

- SQL code


- Query results


##  Query 07: Calc Ratio of Stock / Sales in 2011 by product name, by month. Order results by month desc, ratio desc. Round Ratio to 1 decimal mom yoy

- SQL code


- Query results


## Query 08: No of order and value at Pending status in 2014
- SQL code


- Query results
