--Q1
WITH YearlySales AS (
    SELECT 
        YEAR(i.InvoiceDate) AS Year,
        CAST(SUM(il.Quantity * il.UnitPrice) AS DECIMAL(18,2)) AS IncomePerYear,
        COUNT(DISTINCT MONTH(i.InvoiceDate)) AS NumberOfDistinctMonths
    FROM Sales.InvoiceLines il
    JOIN Sales.Invoices i ON il.InvoiceID = i.InvoiceID
    WHERE i.IsCreditNote = 0  -- מתעלם מזיכויים
    GROUP BY YEAR(i.InvoiceDate)
),
YearlyLinear AS (
    SELECT 
        Year,
        IncomePerYear,
        NumberOfDistinctMonths,
        CASE 
            WHEN NumberOfDistinctMonths = 12 THEN IncomePerYear
            ELSE CAST(ROUND((IncomePerYear / NumberOfDistinctMonths) * 12, 2) AS DECIMAL(18,2))
        END AS YearlyLinearIncome
    FROM YearlySales
)
SELECT 
    y1.Year,
    CAST(y1.IncomePerYear AS DECIMAL(18,2)) AS IncomePerYear,
    y1.NumberOfDistinctMonths,
    CAST(y1.YearlyLinearIncome AS DECIMAL(18,2)) AS YearlyLinearIncome,
    CASE 
        WHEN y2.YearlyLinearIncome IS NULL THEN NULL
        ELSE CAST(ROUND(((y1.YearlyLinearIncome - y2.YearlyLinearIncome) / y2.YearlyLinearIncome * 100), 2) AS DECIMAL(10,2))
    END AS GrowthRate
FROM YearlyLinear y1
LEFT JOIN YearlyLinear y2 ON y1.Year = y2.Year + 1
WHERE y1.Year BETWEEN 2013 AND 2016
ORDER BY y1.Year;


--Q2
--**** View for top customers per quarter
--create view TopQuarterlyCustomers
--as
WITH QuarterlyIncome AS (
    SELECT 
        YEAR(I.InvoiceDate) AS TheYear,
        CEILING(MONTH(I.InvoiceDate) / 3.0) AS TheQuarter,
        C.CustomerName,
        SUM(IL.ExtendedPrice - IL.TaxAmount) AS IncomePerQuarter
    FROM Sales.Invoices I
    JOIN Sales.InvoiceLines IL ON I.InvoiceID = IL.InvoiceID
    JOIN Sales.Customers C ON I.CustomerID = C.CustomerID
    GROUP BY YEAR(I.InvoiceDate), CEILING(MONTH(I.InvoiceDate) / 3.0), C.CustomerName
),
RankedIncome AS (
    SELECT 
        TheYear,
        TheQuarter,
        CustomerName,
        IncomePerQuarter,
        RANK() OVER (PARTITION BY TheYear, TheQuarter ORDER BY IncomePerQuarter DESC) AS DNR
    FROM QuarterlyIncome
)
SELECT 
    TheYear AS Year,
    TheQuarter AS Quarter,
    CustomerName,
    CAST(IncomePerQuarter AS DECIMAL(18, 2)) AS IncomePerQuarter,
    DNR
FROM RankedIncome
WHERE DNR <= 5
ORDER BY TheYear, TheQuarter, DNR;

--select * from TopQuarterlyCustomers


--Q3
--**** View for top 10 profitable products
--create view Top10ProfitableProducts
--as
WITH ProductProfits AS (
    SELECT 
        SI.StockItemID,
        SI.StockItemName,
        SUM(IL.ExtendedPrice - IL.TaxAmount) AS TotalProfit
    FROM Sales.InvoiceLines IL
    JOIN Warehouse.StockItems SI ON IL.StockItemID = SI.StockItemID
    GROUP BY SI.StockItemID, SI.StockItemName
)
SELECT TOP 10 
    StockItemID,
    StockItemName,
    CAST(TotalProfit AS DECIMAL(18, 2)) AS TotalProfit
FROM ProductProfits
ORDER BY TotalProfit DESC;

--select * from Top10ProfitableProducts

--Q4
--**** View for active stock items with nominal profit
--create view ActiveStockItemsView
--as
WITH ActiveStockItems AS (
    SELECT 
        SI.StockItemID,
        SI.StockItemName,
        SI.UnitPrice,
        SI.RecommendedRetailPrice,
        (SI.RecommendedRetailPrice - SI.UnitPrice) AS NominalProfit
    FROM Warehouse.StockItems SI
    WHERE GETDATE() BETWEEN SI.ValidFrom AND SI.ValidTo
),
RankedStockItems AS (
    SELECT 
        StockItemID,
        StockItemName,
        UnitPrice,
        RecommendedRetailPrice,
        NominalProfit,
        RANK() OVER (ORDER BY NominalProfit DESC) AS Rn
    FROM ActiveStockItems
)
SELECT 
    Rn,
    StockItemID,
    StockItemName,
    CAST(UnitPrice AS DECIMAL(18, 2)) AS UnitPrice,
    CAST(RecommendedRetailPrice AS DECIMAL(18, 2)) AS RecommendedRetailPrice,
    CAST(NominalProfit AS DECIMAL(18, 2)) AS NominalProfit
FROM RankedStockItems
ORDER BY Rn;

--select * from ActiveStockItemsView

--Q5
--**** View for supplier product list without NULL rows
--create view SupplierProductListView
--as
SELECT 
    CONCAT(S.SupplierID, ' - ', S.SupplierName) AS SupplierDetails,
    STUFF(
        (SELECT ', ' + CONCAT(SI.StockItemID, ' ', SI.StockItemName)
         FROM Warehouse.StockItems SI
         WHERE SI.SupplierID = S.SupplierID
         FOR XML PATH('')), 1, 2, '') AS ProductDetails
FROM Purchasing.Suppliers S
WHERE EXISTS (
    SELECT 1 
    FROM Warehouse.StockItems SI
    WHERE SI.SupplierID = S.SupplierID
);

--select * from SupplierProductListView

--Q6
--**** View for top 5 customers by total purchases
--create view Top5CustomersByPurchases
--as
WITH CustomerExpenses AS (
    SELECT 
        C.CustomerID,
        C.CustomerName,
        City.CityName,
        SP.StateProvinceName,
        Country.CountryName,
        Country.Continent,
        Country.Region,
        SUM(IL.ExtendedPrice) AS TotalExtendedPrice
    FROM Sales.Customers C
    JOIN Sales.Invoices I ON C.CustomerID = I.CustomerID
    JOIN Sales.InvoiceLines IL ON I.InvoiceID = IL.InvoiceID
    JOIN Application.Cities City ON C.PostalCityID = City.CityID
    JOIN Application.StateProvinces SP ON City.StateProvinceID = SP.StateProvinceID
    JOIN Application.Countries Country ON SP.CountryID = Country.CountryID
    GROUP BY C.CustomerID, C.CustomerName, City.CityName, SP.StateProvinceName, Country.CountryName, Country.Continent, Country.Region
)
SELECT TOP 5
    CustomerID,
    CustomerName,
    CityName,
    StateProvinceName,
    CountryName,
    Continent,
    Region,
    CAST(TotalExtendedPrice AS DECIMAL(18, 2)) AS TotalExtendedPrice
FROM CustomerExpenses
ORDER BY TotalExtendedPrice DESC;

--select * from Top5CustomersByPurchases

--Q7
-- Drop the view if it already exists
IF OBJECT_ID('MonthlyAndCumulativeTotalsView', 'V') IS NOT NULL
    DROP VIEW MonthlyAndCumulativeTotalsView;
GO

-- Create the view
CREATE VIEW MonthlyAndCumulativeTotalsView AS
WITH MonthlyTotals AS (
    SELECT 
        YEAR(O.OrderDate) AS OrderYear,
        MONTH(O.OrderDate) AS OrderMonth,
        SUM(OL.Quantity * OL.UnitPrice) AS MonthlyTotal
    FROM Sales.Orders O
    JOIN Sales.OrderLines OL ON O.OrderID = OL.OrderID
    GROUP BY YEAR(O.OrderDate), MONTH(O.OrderDate)
),
CumulativeTotals AS (
    SELECT 
        OrderYear,
        OrderMonth,
        MonthlyTotal,
        SUM(MonthlyTotal) OVER (PARTITION BY OrderYear ORDER BY OrderMonth) AS CumulativeTotal
    FROM MonthlyTotals
),
GrandTotals AS (
    SELECT 
        OrderYear,
        'Grand Total' AS OrderMonth,
        SUM(MonthlyTotal) AS MonthlyTotal,
        SUM(MonthlyTotal) AS CumulativeTotal
    FROM MonthlyTotals
    GROUP BY OrderYear
)
SELECT 
    CAST(OrderYear AS NVARCHAR) AS OrderYear,
    CAST(OrderMonth AS NVARCHAR) AS OrderMonth,
    CAST(MonthlyTotal AS DECIMAL(18, 2)) AS MonthlyTotal,
    CAST(CumulativeTotal AS DECIMAL(18, 2)) AS CumulativeTotal
FROM CumulativeTotals
UNION ALL
SELECT 
    CAST(OrderYear AS NVARCHAR) AS OrderYear,
    OrderMonth,
    CAST(MonthlyTotal AS DECIMAL(18, 2)) AS MonthlyTotal,
    CAST(CumulativeTotal AS DECIMAL(18, 2)) AS CumulativeTotal
FROM GrandTotals;

GO

-- Test the view
SELECT * 
FROM MonthlyAndCumulativeTotalsView
ORDER BY OrderYear, 
         CASE WHEN OrderMonth = 'Grand Total' THEN 13 ELSE CAST(OrderMonth AS INT) END;


--Q8
---**** View for pivot table of order counts with zeros
--create view OrderCountPivotWithZeros
--as
;WITH MonthlyOrders AS (
    SELECT 
        YEAR(O.OrderDate) AS OrderYear,
        MONTH(O.OrderDate) AS OrderMonth,
        COUNT(O.OrderID) AS OrderCount
    FROM Sales.Orders O
    GROUP BY YEAR(O.OrderDate), MONTH(O.OrderDate)
)
SELECT 
    OrderMonth,
    ISNULL([2013], 0) AS Year2013,
    ISNULL([2014], 0) AS Year2014,
    ISNULL([2015], 0) AS Year2015,
    ISNULL([2016], 0) AS Year2016
FROM MonthlyOrders
PIVOT (
    SUM(OrderCount)
    FOR OrderYear IN ([2013], [2014], [2015], [2016])
) AS PivotTable
ORDER BY OrderMonth;

-- Q9
--: Identify potential churn customers in a single query
WITH CustomerOrders AS (
    SELECT 
        C.CustomerID,
        C.CustomerName,
        O.OrderDate,
        LAG(O.OrderDate) OVER (PARTITION BY C.CustomerID ORDER BY O.OrderDate) AS PreviousOrderDate,
        DATEDIFF(DAY, LAG(O.OrderDate) OVER (PARTITION BY C.CustomerID ORDER BY O.OrderDate), O.OrderDate) AS DaysSinceLastOrder
    FROM Sales.Customers C
    JOIN Sales.Orders O ON C.CustomerID = O.CustomerID
),
AverageDaysBetweenOrders AS (
    SELECT 
        CustomerID,
        AVG(DaysSinceLastOrder) AS AvgDaysBetweenOrders
    FROM CustomerOrders
    WHERE DaysSinceLastOrder IS NOT NULL
    GROUP BY CustomerID
)
SELECT 
    CO.CustomerID,
    CO.CustomerName,
    CO.OrderDate,
    CO.PreviousOrderDate,
    CO.DaysSinceLastOrder,
    ADBO.AvgDaysBetweenOrders,
    CASE 
        WHEN CO.DaysSinceLastOrder > 2 * ADBO.AvgDaysBetweenOrders THEN 'Potential Churn'
        ELSE 'Active'
    END AS CustomerStatus
FROM CustomerOrders CO
LEFT JOIN AverageDaysBetweenOrders ADBO ON CO.CustomerID = ADBO.CustomerID
ORDER BY CO.CustomerID, CO.OrderDate;

--Q10
--**** View for customer category risk analysis with percentage factor
--create view CustomerCategoryRiskWithPercentage
--as
WITH CustomerCategoryDetails AS (
    SELECT 
        CC.CustomerCategoryName,
        COUNT(DISTINCT C.CustomerID) AS CustomerCOUNT
    FROM Sales.Customers C
    JOIN Sales.CustomerCategories CC ON C.CustomerCategoryID = CC.CustomerCategoryID
    GROUP BY CC.CustomerCategoryName
),
CategoryDistribution AS (
    SELECT
        CustomerCategoryName,
        CustomerCOUNT,
        SUM(CustomerCOUNT) OVER () AS TotalCustCount,
        CAST(CustomerCOUNT * 1.0 / SUM(CustomerCOUNT) OVER () * 100 AS DECIMAL(18, 2)) AS DistributionFactor
    FROM CustomerCategoryDetails
)
SELECT 
    CustomerCategoryName,
    CustomerCOUNT,
    TotalCustCount,
    CONCAT(CAST(DistributionFactor AS DECIMAL(18, 2)), '%') AS DistributionFactor
FROM CategoryDistribution
ORDER BY DistributionFactor DESC;

