
-- Code to (approximately) block on ZIP and Medicaid eligibility
-- and cluster on address
--
-- Assumes there is a table called `data` which has a schema ≈ like:
--
--  CREATE TABLE data (
--    id                   BIGINT,
--    name                 VARCHAR(255),
--    address1             VARCHAR(255),
--    address2             VARCHAR(255),
--    city                 VARCHAR(64),
--    state                CHAR(2),
--    zipcode              CHAR(5),
--    is_medicaid_eligible CHAR(1)
--  )
--
--  We assume:
--    * Everyone in the table is either Medicaid or QHP eligible
--    * If they are Medicaid eligible, then is_medicaid_eligible = 'Y' else it is 'N'
--    * ZIP codes are five-digit *strings*
--    * Addresses have been standardized via SmartyStreets
--    * There is exactly one row per household

-- Group the small ZIP codes into a single ZIP code
WITH small_zipcodes_counts AS (
  SELECT zipcode, COUNT(*) as the_count
  FROM data
  GROUP BY zipcode
),
small_zipcodes AS (
  SELECT zipcode, the_count
  FROM small_zipcodes_counts
  WHERE the_count < 50
)

-- Create the data along with their block ids
SELECT
  id,
  name,
  address1,
  address2,
  city,
  state,
  data.zipcode,
  CONCAT(
    CASE WHEN sz.the_count IS NULL THEN '00000' ELSE data.zipcode END,
    CASE WHEN data.is_medicaid_eligible = 'Y' THEN 'Medicaid' ELSE 'QHP' END
  ) AS block_id
INTO #blocking_table
FROM data
LEFT JOIN small_zipcodes AS sz
ON data.zipcode = sz.zipcode;

-- Get the distinct block ids and add a random salt
SELECT
  block_id,
  CONVERT(VARCHAR(255), NEWID()) as salt
INTO #block_ids
FROM #blocking_table
GROUP BY block_id;

-- Perform the randomization
SELECT
  bt.*,
  bi.salt,
  ABS(CONVERT(
    BIGINT,
    HASHBYTES(
      'MD5',
      -- NB: Here the address clustering is performed
      CONCAT(
        bt.block_id, '|:|',
        bi.salt, '|:|',
        bt.address1, '|:|',
        bt.address2, '|:|',
        bt.city, '|:|',
        bt.state, '|:|',
        bt.zipcode
      )
    )
  )) % 3 AS arm
INTO #randomizations
FROM #blocking_table AS bt
INNER JOIN #block_ids AS bi
ON bt.block_id = bi.block_id;


-- Bad blocks are those where some arm has a proportion of households not in [0.3, 0.36],
-- i.e., is > 10% larger/smaller than it should be
WITH count_per_arm AS (
  SELECT
    block_id,
    arm,
    COUNT(*) AS arm_count
  FROM #randomizations
  GROUP BY block_id, arm
),
count_per_block AS (
  SELECT
    block_id,
    COUNT(*) AS block_count
  FROM #randomizations
  GROUP BY block_id
),
proportion_per_arm AS (
  SELECT
    cpa.block_id,
    cpa.arm,
    CONVERT(REAL, cpa.arm_count) / CONVERT(REAL, cpb.block_count) AS proportion
  FROM count_per_block AS cpb
  INNER JOIN count_per_arm AS cpa
  ON cpb.block_id = cpa.block_id
),
bad_blocks_tmp AS (
  SELECT block_id, proportion
  FROM proportion_per_arm
  WHERE proportion < 0.3 OR proportion > 0.36
)
SELECT DISTINCT block_id
INTO #bad_blocks
FROM bad_blocks_tmp;


-- Try to fix the bad blocks. But limit the number of tries to 10
DECLARE @counter INT;
SET @counter = 0
WHILE (SELECT COUNT(*) FROM #bad_blocks) <> 0 AND @counter < 10
BEGIN
  -- get a new salt for the bad blocks
  UPDATE #block_ids
  SET salt = CONVERT(VARCHAR(255), NEWID())
  FROM #block_ids AS bi
  INNER JOIN #bad_blocks AS bb
  ON bi.block_id = bb.block_id;

  -- Recompute the arms for these blocks
  -- TODO(khw): Run faster by filtering on a join?
  UPDATE #randomizations
  SET
    salt = bi.salt,
    arm = ABS(CONVERT(
      BIGINT,
      HASHBYTES(
        'MD5',
        -- NB: Here the address clustering is performed
        CONCAT(
          r.block_id, '|:|',
          bi.salt, '|:|',
          r.address1, '|:|',
          r.address2, '|:|',
          r.city, '|:|',
          r.state, '|:|',
          r.zipcode
        )
      )
    )) % 3
   FROM #randomizations AS r
   INNER JOIN #block_ids AS bi
   ON r.block_id = bi.block_id;

  -- Compute remaining bad blocks
  DROP TABLE #bad_blocks;
  WITH count_per_arm AS (
    SELECT
      block_id,
      arm,
      COUNT(*) AS arm_count
    FROM #randomizations
    GROUP BY block_id, arm
  ),
  count_per_block AS (
    SELECT
      block_id,
      COUNT(*) AS block_count
    FROM #randomizations
    GROUP BY block_id
  ),
  proportion_per_arm AS (
    SELECT
      cpa.block_id,
      cpa.arm,
      CONVERT(REAL, cpa.arm_count) / CONVERT(REAL, cpb.block_count) AS proportion
    FROM count_per_block AS cpb
    INNER JOIN count_per_arm AS cpa
    ON cpb.block_id = cpa.block_id
  ),
  bad_blocks_tmp AS (
    SELECT block_id, proportion
    FROM proportion_per_arm
    WHERE proportion < 0.3 OR proportion > 0.36
  )
  SELECT DISTINCT block_id
  INTO #bad_blocks
  FROM bad_blocks_tmp;

  SET @counter = @counter + 1;

END;

-- Store the final output in a table called rwjf_randomizations
SELECT *
INTO rwjf_randomizations
FROM #randomizations;