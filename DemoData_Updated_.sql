-- Drop the temporary table if it exists
DROP TABLE IF EXISTS TempTable;

-- Create a temporary table to assign row numbers
CREATE TEMP TABLE TempTable (
  id INT,
  txt CHAR(9),
  hispanic CHAR(24),
  phone VARCHAR(15),
  email CHAR(64),
  citz CHAR(64),
  visa_code CHAR(4),
  rn INTEGER
);

-- Insert into temporary table
INSERT INTO TempTable (id, txt, hispanic, phone, email, citz, visa_code, rn)
SELECT DISTINCT
  prof.id,
  r.txt,
  prof.hispanic,
  id.phone,
  aar.line1,
  prof.citz,
  prof.visa_code,
  ROW_NUMBER() OVER (PARTITION BY prof.id ORDER BY aar.line1)
FROM profile_rec AS prof
JOIN prog_enr_rec AS prog ON prog.id = prof.id
JOIN id_rec AS id ON prof.id = id.id
JOIN aa_rec AS aar ON prof.id = aar.id AND aar.aa = 'EMPV'
JOIN race_table AS r ON prof.race = r.race
WHERE prog.acst IN ('RENR', 'ENRF', 'ENRP') AND email IS NOT NULL;

SELECT *
FROM TempTable;

-- Final output
SELECT *
FROM (
  SELECT DISTINCT
    tt.id AS StudentID,
    'DemoData' AS DocumentCode,
    '2025-2026' AS AcademicYear,
    tt.txt AS FieldValue,
    'RaceDescription' || tt.rn AS FieldName
  FROM TempTable AS tt

  UNION

  SELECT DISTINCT
    tt.id,
    'DemoData',
    '2025-2026',
    tt.hispanic,
    'HispanicField' || tt.rn AS FieldName
  FROM TempTable AS tt

  UNION

  SELECT DISTINCT
    tt.id,
    'DemoData',
    '2025-2026',
    tt.phone,
    'Homephone' || tt.rn AS FieldName
  FROM TempTable AS tt

  UNION 

  SELECT DISTINCT
    tt.id,
    'DemoData',
    '2025-2026',
    tt.email,
    'PersonalEmail' || tt.rn AS FieldName
  FROM TempTable AS tt

  UNION

  SELECT DISTINCT
    tt.id,
    'DemoData',
    '2025-2026',
    tt.citz,
    'CitizenshipCountry' || tt.rn AS FieldName
  FROM TempTable AS tt

  UNION

  SELECT DISTINCT
    tt.id,
    'DemoData',
    '2025-2026',
    tt.visa_code,
    'VisaCode' || tt.rn AS FieldName
  FROM TempTable AS tt
) AS result
ORDER BY
  StudentID,
  CAST(SUBSTRING(FieldName FROM LENGTH(FieldName) FOR 1) AS INTEGER),
  CASE
    WHEN FieldName LIKE 'RaceDescription%' THEN 1
    WHEN FieldName LIKE 'HispanicField%' THEN 2
    WHEN FieldName LIKE 'Homephone%' THEN 3
    WHEN FieldName LIKE 'PersonalEmail%' THEN 4
    WHEN FieldName LIKE 'CitizenshipCountry%' THEN 5
    WHEN FieldName LIKE 'VisaCode%' THEN 6
    ELSE 7
  END;