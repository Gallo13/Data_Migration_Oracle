SELECT
  acc.id AS StudentID,
  'Achieve' AS DocumentCode,
  '2025-2026' AS AcademicYear,
  CAST(acc.accomp AS VARCHAR(10)) AS FieldValue,
  'AccompCode' || ROW_NUMBER() OVER (PARTITION BY acc.id ORDER BY acc.accomp) AS FieldName
FROM accomp_rec AS acc
JOIN prog_enr_rec AS prog ON prog.id = acc.id
WHERE prog.acst IN ('RENR', 'ENRF', 'ENRP')

UNION ALL

SELECT
  acc.id AS StudentID,
  'Achieve' AS DocumentCode,
  '2025-2026' AS AcademicYear,
  CAST(acc.ctgry AS VARCHAR(10)) AS FieldValue,
  'Academic' || ROW_NUMBER() OVER (PARTITION BY acc.id ORDER BY acc.ctgry) AS FieldName
FROM accomp_rec AS acc
JOIN prog_enr_rec AS prog ON prog.id = acc.id
WHERE prog.acst IN ('RENR', 'ENRF', 'ENRP')

UNION ALL

SELECT
  acc.id AS StudentID,
  'Achieve' AS DocumentCode,
  '2025-2026' AS AcademicYear,
  CAST(acc.sess AS VARCHAR(2)) AS FieldValue,
  'Session' || ROW_NUMBER() OVER (PARTITION BY acc.id ORDER BY acc.sess) AS FieldName
FROM accomp_rec AS acc
JOIN prog_enr_rec AS prog ON prog.id = acc.id
WHERE prog.acst IN ('RENR', 'ENRF', 'ENRP') AND accomp<>'ZZZZ'

UNION ALL

SELECT
  acc.id AS StudentID,
  'Achieve' AS DocumentCode,
  '2025-2026' AS AcademicYear,
  CAST(acc.yr AS VARCHAR(10)) AS FieldValue,
  'Year' || ROW_NUMBER() OVER (PARTITION BY acc.id ORDER BY acc.yr) AS FieldName
FROM accomp_rec AS acc
JOIN prog_enr_rec AS prog ON prog.id = acc.id
WHERE prog.acst IN ('RENR', 'ENRF', 'ENRP') AND accomp<>'ZZZZ'

UNION ALL

SELECT
  acc.id AS StudentID,
  'Achieve' AS DocumentCode,
  '2025-2026' AS AcademicYear,
  CAST(acc.prog AS VARCHAR(10)) AS FieldValue,
  'Program' || ROW_NUMBER() OVER (PARTITION BY acc.id ORDER BY acc.prog) AS FieldName
FROM accomp_rec AS acc
JOIN prog_enr_rec AS prog ON prog.id = acc.id
WHERE prog.acst IN ('RENR', 'ENRF', 'ENRP') AND accomp<>'ZZZZ'
ORDER BY StudentID, FieldName;

--SELECT * FROM Temp;