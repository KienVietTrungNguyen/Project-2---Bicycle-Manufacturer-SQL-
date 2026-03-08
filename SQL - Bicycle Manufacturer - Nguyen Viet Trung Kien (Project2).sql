---Q1: Calc Quantity of items, Sales value & Order quantity by each Subcategory in L12M
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

---Q2: Calc % YoY growth rate by SubCategory & release top 3 cat with highest grow rate. Can use metric: quantity_item. Round results to 2 decimal qty_diff = qty_item / prv_qty - 1
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

--- Q3: Ranking Top 3 TeritoryID with biggest Order quantity of every year. If there's TerritoryID with same quantity in a year, do not skip the rank number
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

---Q4: Calc Total Discount Cost belongs to Seasonal Discount for each SubCategory
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

---Q5: Retention rate of Customer in 2014 with status of Successfully Shipped (Cohort Analysis)
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

---Q6: Trend of Stock level & MoM diff % by all product in 2011. If %gr rate is null then 0. Round to 1 decimal
WITH month AS 
(
  SELECT
    EXTRACT(MONTH FROM workorder.ModifiedDate) AS mth
    ,EXTRACT(YEAR FROM workorder.ModifiedDate) AS yr
    ,product.Name AS name
    ,SUM(workorder.StockedQty) AS stock_qty
  FROM adventureworks2019.Production.WorkOrder workorder
  LEFT JOIN adventureworks2019.Production.Product product
    ON product.ProductID  = workorder.ProductID
  WHERE EXTRACT(YEAR FROM workorder.ModifiedDate) = 2011
  GROUP BY mth, yr, name
  ORDER BY name
),
pre_mth AS 
(
  SELECT
    mth
    ,yr
    ,name
    ,stock_qty
    ,LAG(stock_qty) OVER (PARTITION BY name ORDER BY  mth) AS stock_prv
  FROM month
  ORDER BY name , mth DESC
)
SELECT
  mth
  ,yr
  ,name
  ,stock_qty
  ,stock_prv
  ,CASE WHEN stock_prv IS NULL OR stock_prv = 0 THEN 0
    ELSE ROUND(100.0 * (stock_qty - stock_prv) / stock_prv,1) END AS diff
FROM pre_mth

---Q7:Calc Ratio of Stock / Sales in 2011 by product name, by month .Order results by month desc, ratio desc. Round Ratio to 1 decimal mom yoy
 WITH sum_sales AS    
 (
  SELECT
    EXTRACT(MONTH FROM saleorderdetail.ModifiedDate) AS mth
    ,EXTRACT(YEAR FROM saleorderdetail.ModifiedDate) AS yr
    ,product.ProductID 
    ,product.Name AS name
    ,SUM(saleorderdetail.OrderQty) AS sales
  FROM adventureworks2019.Sales.SalesOrderDetail saleorderdetail
  LEFT JOIN adventureworks2019.Production.Product product
    ON product.ProductID = saleorderdetail.ProductID
  WHERE EXTRACT(YEAR FROM saleorderdetail.ModifiedDate) = 2011
  GROUP BY mth, yr, name,ProductID 
), 
sum_stock AS 
(
  SELECT
  EXTRACT(MONTH FROM ModifiedDate) AS mth
  ,EXTRACT(YEAR FROM ModifiedDate) AS yr
  ,ProductID
  ,SUM(StockedQty) AS stock_qty
  FROM adventureworks2019.Production.WorkOrder
  WHERE EXTRACT(YEAR FROM ModifiedDate) = 2011
  GROUP BY ProductID, mth, yr
  ORDER BY mth DESC
)
SELECT
  sale.mth
  ,sale.yr
  ,sale.ProductID 
  ,sale.name
  ,sale.sales
  ,stock.stock_qty
  ,CASE WHEN stock.stock_qty IS NULL OR sale.sales IS NULL THEN 0 
  ELSE ROUND(stock.stock_qty /sale.sales,1) END as Ratio
FROM sum_sales sale
LEFT JOIN sum_stock stock
  ON sale.ProductID  = stock.ProductID 
    AND sale.mth = stock.mth 
    AND sale.yr =stock.yr
ORDER BY sale.mth DESC, Ratio DESC

---Q8: No of order and value at Pending status in 2014
SELECT 
  EXTRACT(YEAR FROM ModifiedDate) AS yr
  ,COUNT(PurchaseOrderID) AS Order_cnt
  ,SUM(TotalDue) AS value
FROM adventureworks2019.Purchasing.PurchaseOrderHeader 
WHERE Status = 1 AND EXTRACT(YEAR FROM ModifiedDate) = 2014
GROUP BY yr
