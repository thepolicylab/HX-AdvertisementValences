DROP TABLE IF EXISTS T_FINAL;
CREATE TEMP TABLE T_FINAL AS
SELECT DISTINCT FIRST_NA,LAST_NA,ADR_LINE_1_TX,ADR_LINE_2_TX,CITY_NA,STATE_CD,ZIP_CD,COUNTY_NAME,MEEHP_HH_ID FROM T_TAX_FILER
UNION ALL SELECT DISTINCT FIRST_NA,LAST_NA,ADR_LINE_1_TX,ADR_LINE_2_TX,CITY_NA,STATE_CD,ZIP_CD,COUNTY_NAME,MEEHP_HH_ID FROM T_SPOUSE
UNION ALL SELECT DISTINCT FIRST_NA,LAST_NA,ADR_LINE_1_TX,ADR_LINE_2_TX,CITY_NA,STATE_CD,ZIP_CD,COUNTY_NAME,MEEHP_HH_ID FROM T_OTHER;

DROP TABLE IF EXISTS T_FINAL_CNT;
CREATE TEMP TABLE T_FINAL_CNT AS
SELECT ZIP_CD,ZIP_CD ZIP_CD_MOD,COUNT(1) CNT FROM T_FINAL GROUP BY ZIP_CD ORDER BY 3 DESC;

-- GET MAX ZIP CNT
DROP TABLE IF EXISTS T_FINAL_CNT_MAX;
CREATE TEMP TABLE T_FINAL_CNT_MAX AS
SELECT * FROM T_FINAL_CNT ORDER BY CNT DESC LIMIT 1;

UPDATE T_FINAL_CNT SET ZIP_CD_MOD= (SELECT ZIP_CD FROM T_FINAL_CNT_MAX) WHERE CNT<10;

DROP TABLE IF EXISTS T_FINAL_CNT_MOD;
CREATE TEMP TABLE T_FINAL_CNT_MOD AS
SELECT ZIP_CD_MOD,SUM(CNT) CNT FROM T_FINAL_CNT GROUP BY ZIP_CD_MOD ORDER BY 2 DESC;

DROP TABLE IF EXISTS T_FINAL_CNT_SPLIT;
CREATE TEMP TABLE T_FINAL_CNT_SPLIT AS
SELECT ZIP_CD_MOD,ROUND(CNT/3,0) SP_CNT, CNT FROM T_FINAL_CNT_MOD;

SELECT CEILING(RN/SP_CNT) SP_GROUP
,SP_CNT,B.* FROM (
SELECT T.*,ZIP_CD_MOD
,ROW_NUMBER() OVER(PARTITION BY ZIP_CD_MOD ORDER BY MEEHP_HH_ID DESC) AS RN
FROM T_FINAL T
JOIN T_FINAL_CNT F ON F.ZIP_CD=T.ZIP_CD
)B JOIN T_FINAL_CNT_SPLIT S ON S.ZIP_CD_MOD=B.ZIP_CD_MOD;