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
- SQL code:
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
- Query results:
<img width="1043" height="433" alt="image" src="https://github.com/user-attachments/assets/b43c4ec0-132b-456c-a2e7-cc834cf581fe" />

##  Query 02: Calc % YoY growth rate by SubCategory & release top 3 cat with highest grow rate. Can use metric: quantity_item. Round results to 2 decimal qty_diff = qty_item / prv_qty - 1
- SQL code:
```sql
WITH year AS 
(
  SELECT
  EXTRACT(YEAR FROM saleorder.ModifiedDate) AS Period
    ,productsub.Name AS Category
    ,SUM(OrderQty) AS qty_item
  FROM adventureworks2019.Sales.SalesOrderDetail saleorder
  LEFT JOIN adventureworks2019.Production.Product product
    ON product.ProductID  = saleorder.ProductID
  LEFT JOIN adventureworks2019.Production.ProductSubcategory productsub
    ON CAST(product.ProductSubcategoryID as int ) = productsub.ProductSubcategoryID
  GROUP BY Period, Category
  ORDER BY Category ASC ,qty_item DESC
),
pre_year AS 
(
  SELECT
    Category
    ,qty_item
    ,LAG(qty_item) OVER (PARTITION BY Category ORDER BY Period) AS prv_qty
    ,ROUND(qty_item / LAG(qty_item) OVER (PARTITION BY Category ORDER BY Period),2) AS qty_diff
  FROM year
  ORDER BY qty_diff DESC
),
ranked_cte AS 
(
  SELECT
    Category
    ,qty_item
    ,prv_qty
    ,qty_diff
    ,DENSE_RANK() OVER(ORDER BY qty_diff DESC) AS ranked
  FROM pre_year
)
SELECT
  Category
  ,qty_item
  ,prv_qty
  ,qty_diff
FROM ranked_cte
WHERE ranked <=3
```
- Query results:
<img width="793" height="137" alt="image" src="https://github.com/user-attachments/assets/e52a5172-235d-4dc6-bcbe-8f1dad7a44f0" />

##  Query 3: Ranking Top 3 TeritoryID with biggest Order quantity of every year. If there's TerritoryID with same quantity in a year, do not skip the rank number
- SQL code
``` sql
WITH territory_cte AS 
(
  SELECT
  EXTRACT(YEAR FROM saleorder.ModifiedDate) AS yr
    ,salecus.TerritoryID
    ,SUM(OrderQty) AS order_cnt
  FROM adventureworks2019.Sales.SalesOrderDetail saleorder
  LEFT JOIN adventureworks2019.Sales.SalesOrderHeader saleorderheader
    ON  saleorder.SalesOrderID = saleorderheader.SalesOrderID
  LEFT JOIN adventureworks2019.Sales.Customer salecus
    ON saleorderheader.CustomerID = salecus.CustomerID
  GROUP BY yr, TerritoryID
  ORDER BY TerritoryID ASC ,order_cnt DESC
),
ranked_cte AS 
(
  SELECT
    yr
    ,TerritoryID
    ,order_cnt
    ,DENSE_RANK() OVER(PARTITION BY yr ORDER BY order_cnt DESC) AS ranked
  FROM territory_cte
)
SELECT
  yr
  ,TerritoryID
  ,order_cnt
  ,ranked
  FROM ranked_cte
WHERE ranked <=3
ORDER BY yr DESC;
```
- Query results:
<img width="698" height="437" alt="image" src="https://github.com/user-attachments/assets/02bcd634-15cd-4588-80ea-e34100e7700f" />


##  Query 04: Calc Total Discount Cost belongs to Seasonal Discount for each SubCategory

- SQL code:
```sql
SELECT 
  EXTRACT(YEAR FROM saleorder.ModifiedDate) AS Period
  ,productsub.Name AS SubCate_Name
  ,SUM(UnitPrice * OrderQty * DiscountPct) AS discount_cost
FROM adventureworks2019.Sales.SalesOrderDetail saleorder
LEFT JOIN adventureworks2019.Production.Product product
  ON product.ProductID  = saleorder.ProductID
LEFT JOIN adventureworks2019.Production.ProductSubcategory productsub
  ON CAST(product.ProductSubcategoryID as int ) = productsub.ProductSubcategoryID
LEFT JOIN adventureworks2019.Sales.SpecialOffer specialoffer
  ON saleorder.SpecialOfferID = specialoffer.SpecialOfferID
WHERE LOWER(specialoffer.Type) LIKE '%seasonal discount%'
GROUP BY Period, SubCate_Name
```
- Query results:
<img width="637" height="98" alt="image" src="https://github.com/user-attachments/assets/5485ca6f-3536-4e43-b3ae-01c1ab8a96cf" />

##  Query 05: Retention rate of Customer in 2014 with status of Successfully Shipped (Cohort Analysis)
- SQL code:
```sql
With infor AS 
(
  SELECT 
    EXTRACT(MONTH FROM ModifiedDate) AS mth_order
    ,EXTRACT(YEAR FROM ModifiedDate) AS yr
    ,CustomerID
    ,COUNT(DISTINCT SalesOrderID) as sale_count
  FROM adventureworks2019.Sales.SalesOrderHeader
  WHERE Status = 5 AND EXTRACT(YEAR FROM ModifiedDate) = 2014
  GROUP BY mth_order, yr,CustomerID
), 
number AS 
(
  SELECT 
    DISTINCT mth_order
    ,yr
    ,CustomerID
    ,sale_count
    ,ROW_NUMBER() OVER(PARTITION BY CustomerID ORDER BY mth_order ASC) as num
  FROM infor
),
first_month AS 
(
  SELECT 
    mth_order AS mth_join
    ,CustomerID
  FROM number
  WHERE num = 1
),
all_join AS 
(
  SELECT
    DISTINCT infor.mth_order
    ,infor.yr
    ,infor.CustomerID
    ,first_month.mth_join
    ,CONCAT('M','-' ,infor.mth_order - first_month.mth_join) AS month_diff
  FROM infor
  LEFT JOIN first_month
    ON infor.CustomerID = first_month.CustomerID
)
SELECT
   DISTINCT mth_join 
  ,month_diff
  ,COUNT(DISTINCT CustomerID) AS customer_cnt
FROM all_join
GROUP BY mth_join,month_diff
ORDER BY mth_join, month_diff;
```
- Query results
<img width="637" height="472" alt="image" src="https://github.com/user-attachments/assets/af9b5d54-71aa-41c7-bd78-2ddbcc6d64d5" />


##  Query 06: Trend of Stock level & MoM diff % by all product in 2011. If %gr rate is null then 0. Round to 1 decimal

- SQL code


- Query results


##  Query 07: Calc Ratio of Stock / Sales in 2011 by product name, by month. Order results by month desc, ratio desc. Round Ratio to 1 decimal mom yoy

- SQL code


- Query results


## Query 08: No of order and value at Pending status in 2014
- SQL code


- Query results
