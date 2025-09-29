-- Drop and create temp table
DROP TABLE IF EXISTS TempTable;

CREATE TEMP TABLE TempTable (
    id INT,
    hld VARCHAR(50),
    beg_date DATE,
    end_date DATE,
    rn INT
);

-- Insert into temp table with row numbers
INSERT INTO TempTable (id, hld, beg_date, end_date, rn)
SELECT
    hr.id,
    hr.hld,
    hr.beg_date,
    hr.end_date,
    ROW_NUMBER() OVER (
        PARTITION BY hr.id
        ORDER BY hr.beg_date
    ) AS rn
FROM hold_rec hr;


-- Final query: 10 max per student per field type
SELECT StudentId, DocumentCode, AcademicYear, FieldValue, FieldName
FROM (
  -- Hold Code
  SELECT
    hr.id AS StudentID,
    'Holds' AS DocumentCode,
    '2025-2026' AS AcademicYear,
    hr.hld AS FieldValue,
    'Hold Code ' || hr.rn AS FieldName,
    hr.rn AS RowNum
  FROM TempTable hr
  WHERE hr.rn <= 10

  UNION ALL

  -- Hold Start Date
  SELECT
    hr.id AS StudentID,
    'Holds' AS DocumentCode,
    '2025-2026' AS AcademicYear,
    TO_CHAR(hr.beg_date, '%Y-%m-%d') AS FieldValue,
    'Hold Start Date ' || hr.rn AS FieldName,
    hr.rn AS RowNum
  FROM TempTable hr
  WHERE hr.rn <= 10

  UNION ALL

  -- Hold End Date
  SELECT
    hr.id AS StudentID,
    'Holds' AS DocumentCode,
    '2025-2026' AS AcademicYear,
    TO_CHAR(hr.end_date, '%Y-%m-%d') AS FieldValue,
    'Hold End Date ' || hr.rn AS FieldName,
    hr.rn AS RowNum
  FROM TempTable hr
  WHERE hr.rn <= 10
) AS result
ORDER BY
  StudentID,
  RowNum,
  CASE
    WHEN FieldName LIKE 'Hold Code%' THEN 1
    WHEN FieldName LIKE 'Hold Start Date%' THEN 2
    WHEN FieldName LIKE 'Hold End Date%' THEN 3
    ELSE 4
  END;
