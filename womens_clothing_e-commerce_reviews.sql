SHOW DATABASES;
USE mydata;
SHOW TABLES;

SELECT * FROM dataset_1;

# Division 별 평균 평점 계산
# 1) Division Name 별 평균 평점
SELECT `Division Name`, AVG(Rating) AS AVG_RATE
FROM dataset_1
GROUP BY 1
ORDER BY 1;
# -> 공란이 있는 것은 입력값이 없는 것으로 보고 무시

# 2) Department 별 평균 평점
SELECT `Department Name`, AVG(Rating) AS AVG_RATE
FROM dataset_1
GROUP BY 1
ORDER BY 1;

# 3) Trend 의 평점 3점 이하 리뷰
SELECT * FROM dataset_1
WHERE `Department Name` = "Trend"
AND Rating <= 3;

# 4) Trend 의 평점 3점 이하 연령별 리뷰
SELECT FLOOR(Age / 10) * 10 AS AGEBAND, Age
FROM dataset_1
WHERE `Department Name` = "Trend"
AND Rating <= 3
;

# 5) Trend 의 평점 3점 이하 리뷰의 연령 분포
SELECT FLOOR (Age / 10) * 10 AS AGEBAND,
COUNT(*) AS CNT
FROM dataset_1
WHERE `Department Name` = "Trend"
AND Rating <= 3
GROUP BY 1
ORDER BY 2 DESC;

# 6) Department 별 연령별 리뷰 수
SELECT FLOOR (Age / 10) * 10 AS AGEBAND,
COUNT(*) AS CNT
FROM dataset_1
WHERE `Department Name` = "Trend"
GROUP BY 1
ORDER BY 2 DESC;

# 7) 50대 3점 이하 Trend 리뷰
SELECT * FROM dataset_1
WHERE `Department Name` = "Trend"
AND Rating <= 3
AND Age BETWEEN 50 AND 59;


# 평점이 낮은 상품의 주요 Complain
# 1) Department Name, Clothing ID 별 평균 평점 계산
SELECT `Department Name`, `Clothing ID`, AVG(Rating) AS AVG_RATE
FROM dataset_1
GROUP BY 1,2;

# 2) Department 별 순위
SELECT *,
ROW_NUMBER() OVER(PARTITION BY `Department Name` ORDER BY AVG_RATE) AS RNK
FROM
(SELECT `Department Name`, `Clothing ID`, AVG(Rating) AS AVG_RATE
FROM dataset_1
GROUP BY 1,2) A
;

# 3) Department 별 1위 ~ 10위 데이터 조회
SELECT * FROM
(SELECT *,
ROW_NUMBER() OVER(PARTITION BY `Department Name` ORDER BY AVG_RATE) AS RNK
FROM
(SELECT `Department Name`, `Clothing ID`, AVG(Rating) AS AVG_RATE
FROM dataset_1
GROUP BY 1,2) A) A
WHERE RNK <= 10;

# 3-1) Department 별 평균 평점이 낮은 10개 상품
CREATE TABLE STAT AS
SELECT * FROM
(SELECT *,
ROW_NUMBER() OVER(PARTITION BY `Department Name` ORDER BY AVG_RATE) AS RNK
FROM
(SELECT `Department Name`, `Clothing ID`, AVG(Rating) AS AVG_RATE
FROM dataset_1
GROUP BY 1,2) A) A
WHERE RNK <= 10
;

## 평점이 낮은 10개 상품의 Clothing ID 조회
SELECT `Clothing ID` FROM STAT
WHERE `Department Name` = "Bottoms";

## 위의 Clothing ID 에 해당하는 리뷰 내용 조회
SELECT `Review Text` FROM dataset_1
WHERE `Clothing ID` IN 
(SELECT `Clothing ID` FROM STAT
WHERE `Department Name` = "Bottoms")
ORDER BY `Clothing ID`;


# 연령별 Worst Department
SELECT `Department Name`, FLOOR(Age / 10) * 10 AS AGEBAND,
AVG(Rating) AS AVG_RATING
FROM dataset_1
GROUP BY 1,2;

SELECT *,
ROW_NUMBER() OVER(PARTITION BY AGEBAND ORDER BY AVG_RATING) AS RNK
FROM
(SELECT `Department Name`, FLOOR(Age / 10) * 10 AS AGEBAND,
AVG(Rating) AS AVG_RATING
FROM dataset_1
GROUP BY 1,2) A
;

SELECT * FROM
(SELECT *,
ROW_NUMBER() OVER(PARTITION BY AGEBAND ORDER BY AVG_RATING) AS RNK
FROM
(SELECT `Department Name`, FLOOR(Age / 10) * 10 AS AGEBAND,
AVG(Rating) AS AVG_RATING
FROM dataset_1
GROUP BY 1,2) A) A
WHERE RNK = 1
;


# Size Complain
SELECT `Review Text`,
CASE WHEN `Review Text` LIKE "%SIZE%" THEN 1 ELSE 0 END AS SIZE_YN
FROM dataset_1;

SELECT SUM(CASE WHEN `Review Text` LIKE "%SIZE%" THEN 1 ELSE 0 END) AS N_SIZE,
COUNT(*) N_TOTAL
FROM dataset_1;

SELECT
SUM(CASE WHEN `Review Text` LIKE "%SIZE%" THEN 1 ELSE 0 END) AS N_SIZE,
SUM(CASE WHEN `Review Text` LIKE "%LARGE%" THEN 1 ELSE 0 END) AS N_LARGE,
SUM(CASE WHEN `Review Text` LIKE "%LOOSE%" THEN 1 ELSE 0 END) AS N_LOOSE,
SUM(CASE WHEN `Review Text` LIKE "%SMALL%" THEN 1 ELSE 0 END) AS N_SMALL,
SUM(CASE WHEN `Review Text` LIKE "%TIGHT%" THEN 1 ELSE 0 END) AS N_TIGHT,
SUM(1) AS N_TOTAL
FROM dataset_1;

SELECT `Department Name`, 
SUM(CASE WHEN `Review Text` LIKE "%SIZE%" THEN 1 ELSE 0 END) AS N_SIZE,
SUM(CASE WHEN `Review Text` LIKE "%LARGE%" THEN 1 ELSE 0 END) AS N_LARGE,
SUM(CASE WHEN `Review Text` LIKE "%LOOSE%" THEN 1 ELSE 0 END) AS N_LOOSE,
SUM(CASE WHEN `Review Text` LIKE "%SMALL%" THEN 1 ELSE 0 END) AS N_SMALL,
SUM(CASE WHEN `Review Text` LIKE "%TIGHT%" THEN 1 ELSE 0 END) AS N_TIGHT,
SUM(1) AS N_TOTAL
FROM dataset_1
GROUP BY 1
;

SELECT FLOOR(Age / 10) * 10 AS AGEBAND ,`Department Name`, 
SUM(CASE WHEN `Review Text` LIKE "%SIZE%" THEN 1 ELSE 0 END) AS N_SIZE,
SUM(CASE WHEN `Review Text` LIKE "%LARGE%" THEN 1 ELSE 0 END) AS N_LARGE,
SUM(CASE WHEN `Review Text` LIKE "%LOOSE%" THEN 1 ELSE 0 END) AS N_LOOSE,
SUM(CASE WHEN `Review Text` LIKE "%SMALL%" THEN 1 ELSE 0 END) AS N_SMALL,
SUM(CASE WHEN `Review Text` LIKE "%TIGHT%" THEN 1 ELSE 0 END) AS N_TIGHT,
SUM(1) AS N_TOTAL
FROM dataset_1
GROUP BY 1,2
ORDER BY 1,2
;

SELECT FLOOR(Age / 10) * 10 AS AGEBAND ,`Department Name`, 
SUM(CASE WHEN `Review Text` LIKE "%SIZE%" THEN 1 ELSE 0 END) / COUNT(*) AS N_SIZE,
SUM(CASE WHEN `Review Text` LIKE "%LARGE%" THEN 1 ELSE 0 END) / COUNT(*) AS N_LARGE,
SUM(CASE WHEN `Review Text` LIKE "%LOOSE%" THEN 1 ELSE 0 END) / COUNT(*) AS N_LOOSE,
SUM(CASE WHEN `Review Text` LIKE "%SMALL%" THEN 1 ELSE 0 END) / COUNT(*) AS N_SMALL,
SUM(CASE WHEN `Review Text` LIKE "%TIGHT%" THEN 1 ELSE 0 END) / COUNT(*) AS N_TIGHT
FROM dataset_1
GROUP BY 1,2
ORDER BY 1,2
;


# Clothing ID 별 Size Review
SELECT `Clothing ID`,
SUM(CASE WHEN `Review Text` LIKE "%SIZE%" THEN 1 ELSE 0 END) AS N_SIZE
FROM dataset_1
GROUP BY 1;

SELECT `Clothing ID`, 
SUM(CASE WHEN `Review Text` LIKE "%SIZE%" THEN 1 ELSE 0 END) / COUNT(*) AS N_SIZE,
SUM(CASE WHEN `Review Text` LIKE "%LARGE%" THEN 1 ELSE 0 END) / COUNT(*) AS N_LARGE,
SUM(CASE WHEN `Review Text` LIKE "%LOOSE%" THEN 1 ELSE 0 END) / COUNT(*) AS N_LOOSE,
SUM(CASE WHEN `Review Text` LIKE "%SMALL%" THEN 1 ELSE 0 END) / COUNT(*) AS N_SMALL,
SUM(CASE WHEN `Review Text` LIKE "%TIGHT%" THEN 1 ELSE 0 END) / COUNT(*) AS N_TIGHT
FROM dataset_1
GROUP BY 1
;

CREATE TABLE SIZE_STAT AS
SELECT `Clothing ID`, 
SUM(CASE WHEN `Review Text` LIKE "%SIZE%" THEN 1 ELSE 0 END) / COUNT(*) AS N_SIZE,
SUM(CASE WHEN `Review Text` LIKE "%LARGE%" THEN 1 ELSE 0 END) / COUNT(*) AS N_LARGE,
SUM(CASE WHEN `Review Text` LIKE "%LOOSE%" THEN 1 ELSE 0 END) / COUNT(*) AS N_LOOSE,
SUM(CASE WHEN `Review Text` LIKE "%SMALL%" THEN 1 ELSE 0 END) / COUNT(*) AS N_SMALL,
SUM(CASE WHEN `Review Text` LIKE "%TIGHT%" THEN 1 ELSE 0 END) / COUNT(*) AS N_TIGHT
FROM dataset_1
GROUP BY 1
;