SHOW DATABASES;
USE uk_commerce;
SHOW TABLES;

SELECT * FROM dataset;

# 국가별, 상품별 구매자 수 및 매출액
SELECT Country, StockCode, COUNT(DISTINCT CustomerID) AS BU,
SUM(Quantity * UnitPrice) AS SALES
FROM data
GROUP BY 1,2
ORDER BY 3 DESC, 4 DESC;


# 특정 상품 구매자가 많이 구매한 상품
# 1) 가장 많이 판매된 2개 상품 조회(판매 상품 수 기준)
SELECT StockCode, SUM(Quantity) AS QTY
FROM dataset
GROUP BY 1;

SELECT *,
ROW_NUMBER() OVER(ORDER BY QTY DESC) AS RNK
FROM
(SELECT StockCode, SUM(Quantity) AS QTY
FROM dataset
GROUP BY 1) A;

SELECT StockCode
FROM
(SELECT *,
ROW_NUMBER() OVER(ORDER BY QTY DESC) AS RNK
FROM
(SELECT StockCode, SUM(Quantity) AS QTY
FROM dataset
GROUP BY 1) A) A
WHERE RNK BETWEEN 1 AND 2
;

# 2)가장 많이 판매된 2개 상품을 모두 구매한 구매자가 구매한 상품
CREATE TABLE BU_LIST AS
SELECT CustomerID FROM dataset
GROUP BY 1
HAVING MAX(CASE WHEN StockCode = "84077" THEN 1 ELSE 0 END) = 1
AND MAX(CASE WHEN StockCode = "85123A" THEN 1 ELSE 0 END) = 1
;

SELECT DISTINCT StockCode
FROM dataset
WHERE CustomerID IN
(SELECT CustomerID FROM BU_LIST)
AND StockCode NOT IN ("84077", "85123A");


# 국가별 재구매율 계산
SELECT A.Country, SUBSTR(A.InvoiceDate,1,4) AS YY,
COUNT(DISTINCT B.CustomerID) / COUNT(DISTINCT A.CustomerID) AS Retention_Rate
FROM
(SELECT DISTINCT CustomerID, InvoiceDate, country
FROM dataset) A
LEFT JOIN
(SELECT DISTINCT CustomerID, InvoiceDate, Country
FROM dataset) B
ON SUBSTR(A.InvoiceDate,1,4) = SUBSTR(B.InvoiceDate,1,4) - 1
AND A.Country = B.Country
AND A.CustomerID = B.CustomerId
GROUP BY 1,2
ORDER BY 1,2
;


# 코호트 분석
SELECT CustomerID, MIN(InvoiceDate) AS MNDT
FROM dataset
GROUP BY 1;

SELECT CustomerID, InvoiceDate, UnitPrice * Quantity AS SALES
FROM dataset;

SELECT * FROM
(SELECT CustomerID, MIN(InvoiceDate) AS MNDT
FROM dataset
GROUP BY 1) A
LEFT JOIN
(SELECT CustomerID, InvoiceDate, UnitPrice * Quantity AS SALES
FROM dataset) B
ON A.CustomerID = B.CustomerID;


SELECT SUBSTR(MNDT,1,7) AS MM,
TIMESTAMPDIFF(MONTH, MNDT, InvoiceDate) AS DATEDIFF,
# TIMESTAMPDIFF(MONTH/DAY, START, END)
COUNT(DISTINCT A.CustomerID) AS BU,
SUM(SALES) AS SALES
FROM
(SELECT CustomerID, MIN(InvoiceDate) AS MNDT
FROM dataset
GROUP BY 1) A
LEFT JOIN
(SELECT CustomerID, InvoiceDate, UnitPrice * Quantity AS SALES
FROM dataset) B
ON A.CustomerID = B.CustomerID
GROUP BY 1,2
;


# 고객 세그먼트
# 1) RFM
SELECT CustomerID, MAX(InvoiceDate) AS MXDT
FROM dataset
GROUP BY 1;

SELECT CustomerID, 
DATEDIFF("2011-12-02", MXDT) AS REGENCY
FROM
(SELECT CustomerID, MAX(InvoiceDate) AS MXDT
FROM dataset
GROUP BY 1) A;

SELECT CustomerID, COUNT(DISTINCT InvoiceNo) AS FREQUENCY,
SUM(Quantity * UnitPrice) AS Monetary
FROM dataset
GROUP BY 1;

SELECT CustomerID, 
DATEDIFF("2011-12-02", MXDT) AS REGENCY, FREQUENCY, MONETARY
FROM
(SELECT CustomerID, MAX(InvoiceDate) AS MXDT,
COUNT(DISTINCT InvoiceNo) AS FREQUENCY,
SUM(Quantity * UnitPrice) AS Monetary
FROM dataset
GROUP BY 1) A;

# 2) 재구매 Segment
SELECT CustomerID, StockCode, COUNT(DISTINCT SUBSTR(InvoiceDate,1,4)) AS unique_yy
FROM dataset
GROUP BY 1,2;

SELECT CustomerID, MAX(unique_yy) AS mx_unique_yy
FROM
(SELECT CustomerID, StockCode, COUNT(DISTINCT SUBSTR(InvoiceDate,1,4)) AS unique_yy
FROM dataset
GROUP BY 1,2) A
GROUP BY 1
;

SELECT CustomerID,
CASE WHEN mx_unique_yy >= 2 THEN 1 ELSE 0 END AS Repurchase_segment
FROM
(SELECT CustomerID, MAX(unique_yy) AS mx_unique_yy
FROM
(SELECT CustomerID, StockCode, COUNT(DISTINCT SUBSTR(InvoiceDate,1,4)) AS unique_yy
FROM dataset
GROUP BY 1,2) A
GROUP BY 1) A
GROUP BY 1
;


# 일자별 첫 구매자 수
# 1) 고객별 첫 구매일
SELECT CustomerID, MIN(InvoiceDate) AS MNDT
FROM dataset
GROUP BY 1;

# 2) 일자별 첫 구매 고객 수


SELECT MNDT, COUNT(DISTINCT CustomerID) AS BU
FROM
(SELECT CustomerID, MIN(InvoiceDate) AS MNDT
FROM dataset
GROUP BY 1)A
GROUP BY 1;


# 상품별 첫 구매 고객 수
# 1) 고객별, 상품별 첫 구매 일자
SELECT CustomerID, StockCode, MIN(InvoiceDate) AS MNDT
FROM dataset
GROUP BY 1,2;

# 2) 고객별 구매와 기준 순위 생성(랭크)
SELECT *,
ROW_NUMBER() OVER(PARTITION BY CustomerID ORDER BY MNDT) AS RNK
FROM
(SELECT CustomerID, StockCode, MIN(InvoiceDate) AS MNDT
FROM dataset
GROUP BY 1, 2) A;

# 3) 고객별 첫 구매 내역 조회
SELECT * FROM
(SELECT *,
ROW_NUMBER() OVER(PARTITION BY CustomerID ORDER BY MNDT) AS RNK
FROM
(SELECT CustomerID, StockCode, MIN(InvoiceDate) AS MNDT
FROM dataset
GROUP BY 1, 2) A) A
WHERE RNK = 1
;

# 4) 상품별 첫 구매 고객 수 집계
SELECT StockCode, COUNT(DISTINCT CustomerID) AS FIRST_BU
FROM
(SELECT * FROM
(SELECT *,
ROW_NUMBER() OVER(PARTITION BY CustomerID ORDER BY MNDT) AS RNK
FROM
(SELECT CustomerID, StockCode, MIN(InvoiceDate) AS MNDT
FROM dataset
GROUP BY 1, 2) A) A
WHERE RNK = 1) A
GROUP BY 1
ORDER BY 2 DESC
;


# 첫 구매 후 이탈하는 고객의 비중
SELECT CustomerId, COUNT(DISTINCT InvoiceDate) AS F_DATE
FROM dataset
GROUP BY 1;

SELECT SUM(CASE WHEN F_DATE = 1 THEN 1 ELSE 0 END) / SUM(1) AS BOUNC_RATE
FROM
(SELECT CustomerId, COUNT(DISTINCT InvoiceDate) AS F_DATE
FROM dataset
GROUP BY 1) A;

# 국가별 첫 구매 후 이탈하는 고객의 비중

SELECT CustomerId, Country, COUNT(DISTINCT InvoiceDate) AS F_DATE
FROM dataset
GROUP BY 1,2;

SELECT Country,
SUM(CASE WHEN F_DATE = 1 THEN 1 ELSE 0 END) / SUM(1) AS BOUNC_RATE
FROM
(SELECT CustomerId, Country, COUNT(DISTINCT InvoiceDate) AS F_DATE
FROM dataset
GROUP BY 1,2) A
GROUP BY 1
ORDER BY Country;


# 판매 수량이 20% 이상 증가한 상품 리스트(YTD)
# 1) 2011년도 상품별 판매 수량
SELECT StockCode, SUM(Quantity) AS QTY
FROM dataset
WHERE SUBSTR(InvoiceDate,1,4) = "2011"
GROUP BY 1;

# 2) 2010년도 상품별 판매 수량
SELECT StockCode, SUM(Quantity) AS QTY
FROM dataset
WHERE SUBSTR(InvoiceDate,1,4) = "2010"
GROUP BY 1;

SELECT A.StockCode, A.QTY, B.QTY,
A.QTY / B.QTY AS QTY_INCREASE_RATE
FROM
(SELECT StockCode, SUM(Quantity) AS QTY
FROM dataset
WHERE SUBSTR(InvoiceDate,1,4) = "2011"
GROUP BY 1) A
LEFT JOIN
(SELECT StockCode, SUM(Quantity) AS QTY
FROM dataset
WHERE SUBSTR(InvoiceDate,1,4) = "2010"
GROUP BY 1) B
ON A.StockCode = B.StockCode;

# 2010년 대비 2011년 증가율이 0.2 이상인 경우
SELECT * FROM
(SELECT A.StockCode, A.QTY AS QTY_2011, B.QTY AS QTY_2010,
A.QTY / B.QTY -1 AS QTY_INCREASE_RATE
FROM
(SELECT StockCode, SUM(Quantity) AS QTY
FROM dataset
WHERE SUBSTR(InvoiceDate,1,4) = "2011"
GROUP BY 1) A
LEFT JOIN
(SELECT StockCode, SUM(Quantity) AS QTY
FROM dataset
WHERE SUBSTR(InvoiceDate,1,4) = "2010"
GROUP BY 1) B
ON A.StockCode = B.StockCode) BASE
WHERE QTY_INCREASE_RATE >= 0.2;


# 주차별 매출액
# SELECT WEEKOFYEAR("2020-01-01")
SELECT WEEKOFYEAR(InvoiceDate) AS WK,
SUM(Quantity * UnitPrice) AS SALES
FROM dataset
WHERE SUBSTR(InvoiceDate,1,4) = "2011"
GROUP BY 1
ORDER BY 1;


# 신규 / 기존고객의 2011년 월별 매출액
SELECT CustomerId, MIN(InvoiceDate) AS MNDT
FROM dataset
GROUP BY 1;

SELECT CASE WHEN SUBSTR(MNDT,1,4) = "2011" THEN "NEW" ELSE "EXI" END AS NEW_EXI,
CustomerId
FROM
(SELECT CustomerId, MIN(InvoiceDate) AS MNDT
FROM dataset
GROUP BY 1) A
;

SELECT A.CustomerId, B.NEW_EXI, A.InvoiceDate, A.UnitPrice, A.Quantity
FROM dataset A
LEFT JOIN
(SELECT CASE WHEN SUBSTR(MNDT,1,4) = "2011" THEN "NEW" ELSE "EXI" END AS NEW_EXI,
CustomerId
FROM
(SELECT CustomerId, MIN(InvoiceDate) AS MNDT
FROM dataset
GROUP BY 1) A) B
ON A.CustomerId = B.CustomerId
WHERE SUBSTR(A.InvoiceDate,1,4) = "2011"
;

SELECT B.NEW_EXI, SUBSTR(InvoiceDate,1,7) AS MM,
SUM(A.UnitPrice * A.Quantity) AS SALES
FROM dataset A
LEFT JOIN
(SELECT CASE WHEN SUBSTR(MNDT,1,4) = "2011" THEN "NEW" ELSE "EXI" END AS NEW_EXI,
CustomerId
FROM
(SELECT CustomerId, MIN(InvoiceDate) AS MNDT
FROM dataset
GROUP BY 1) A) B
ON A.CustomerId = B.CustomerId
WHERE SUBSTR(A.InvoiceDate,1,4) = "2011"
GROUP BY 1,2
;


# 기존 고객의 2011년 월 누적 리텐션
SELECT CustomerID FROM dataset
GROUP BY 1
HAVING MIN(SUBSTR(InvoiceDate,1,4)) = "2010"
;

SELECT * FROM dataset
WHERE CustomerId IN
(SELECT CustomerID FROM dataset
GROUP BY 1
HAVING MIN(SUBSTR(InvoiceDate,1,4)) = "2010")
AND SUBSTR(InvoiceDate,1,4) = "2011"
;

SELECT CustomerID,
SUBSTR(InvoiceDate,1,7) AS MM
FROM 
(SELECT * FROM dataset
WHERE CustomerID IN
(SELECT CustomerID FROM dataset
GROUP BY 1
HAVING MIN(SUBSTR(InvoiceDate,1,4)) = "2010")
AND SUBSTR(InvoiceDate,1,4) = "2011") A
GROUP BY 1,2;

SELECT MM, COUNT(CustomerID) AS N_CUSTOMERS
FROM 
(SELECT CustomerID,
SUBSTR(InvoiceDate,1,7) AS MM
FROM 
(SELECT * FROM dataset
WHERE CustomerID IN
(SELECT CustomerID FROM dataset
GROUP BY 1
HAVING MIN(SUBSTR(InvoiceDate,1,4)) = "2010")
AND SUBSTR(InvoiceDate,1,4) = "2011") A
GROUP BY 1,2) A
GROUP BY 1
ORDER BY 1
;


# LTV(Lift Time Value)
## AMV(Average Member Value) = 전체 매출액 / 구매 고객수
## Retention Rate = t1 and t0 구매 고객 수 / t0 시점 구매 고객 수

SELECT COUNT(B.CustomerID) / COUNT(A.CustomerID) AS RETENTION_RATE
FROM
(SELECT DISTINCT CustomerID
FROM dataset
WHERE SUBSTR(InvoiceDate,1,4) = "2010") A
LEFT
JOIN
(SELECT DISTINCT CustomerID
FROM dataset
WHERE SUBSTR(InvoiceDate,1,4) = "2011") B
ON A.CustomerID = B.CustomerID
;

SELECT SUM(Quantity * UnitPrice) / COUNT(DISTINCT CustomerID) AS AMV
FROM dataset
WHERE SUBSTR(InvoiceDate,1,4) = "2011";

SELECT COUNT(DISTINCT CustomerID) AS N_BU
FROM dataset
WHERE SUBSTR(InvoiceDate,1,4) = "2011";

