WITH names_and_addresses AS (
    SELECT DISTINCT
        first_na,
        last_na,
        adr_line_1_tx,
        adr_line_2_tx,
        city_na,
        state_cd,
        zip_cd,
        county_name,
        meehp_hh_id
    FROM t_tax_filer
    UNION ALL
    SELECT DISTINCT
        first_na,
        last_na,
        adr_line_1_tx,
        adr_line_2_tx,
        city_na,
        state_cd,
        zip_cd,
        county_name,
        meehp_hh_id
    FROM t_spouse
    UNION ALL
    SELECT DISTINCT
        first_na,
        last_na,
        adr_line_1_tx,
        adr_line_2_tx,
        city_na,
        state_cd,
        zip_cd,
        county_name,
        meehp_hh_id
    FROM t_other
),
counts_in_zip AS (
    SELECT
        zip_cd,
        COUNT(*) AS cnt
    FROM names_and_addresses
    GROUP BY zip_cd
),
largest_zip AS (
    -- NOTE: This is not consistent. Is there a tie?
    SELECT *
    FROM counts_in_zip
    ORDER BY cnt DESC
    LIMIT 1
),
group_small_zips AS (
    SELECT
        c.zip_cd AS zip_cd,
        CASE WHEN c.cnt < 10
            THEN c.zip_cd
            ELSE m.zip_cd
            END AS zip_cd_mod,
        c.cnt
    FROM counts_in_zip AS c
    CROSS JOIN largest_zip
),
grouped_counts AS (
    SELECT
        zip_cd_mod,
        SUM(cnt) AS cnt,
        ROUND(SUM(cnt) / 3, 0) AS sp_cnt
    FROM group_small_zips
    GROUP BY zip_cd_mod
),
annotated_final AS (
    SELECT
        t.*,
        f.zip_cd_mod AS zip_cd_mod,
        f.sp_cnt AS sp_cnt,
        ROW_NUMBER() OVER (PARTITION BY f.zip_cd_mod ORDER BY meehp_hh_id DESC) as rn
    FROM names_and_addresses AS t
    INNER JOIN grouped_counts AS f
    ON t.zip_cd = f.zip_cd
)
SELECT
    *,
    CEILING(rn / sp_cnt) AS sp_group
FROM annotated_final;
