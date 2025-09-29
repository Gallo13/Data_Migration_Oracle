SELECT StudentId, DocumentCode, AcademicYear, FieldValue, FieldName
FROM (
  SELECT
    ir.id AS StudentID,
    'Involvement' AS DocumentCode,
    '2025-2026' AS AcademicYear,
    ir.ctgry AS FieldValue,
    'Category' || ROW_NUMBER() OVER (PARTITION BY ir.id ORDER BY ir.ctgry) AS FieldName,
    ROW_NUMBER() OVER (PARTITION BY ir.id ORDER BY ir.ctgry) AS FieldOrder
  FROM involve_rec AS ir
  JOIN invl_table AS it ON ir.invl = it.invl
  JOIN prog_enr_rec AS prog ON ir.id = prog.id
  WHERE (prog.acst = 'RENR' OR prog.acst = 'ENRF' OR prog.acst = 'ENRP')

  UNION ALL

  -- 
  SELECT
    ir.id AS StudentID,
    'Involvement' AS DocumentCode,
    '2025-2026' AS AcademicYear,
    it.invl AS FieldValue,
    'Code' || ROW_NUMBER() OVER (PARTITION BY ir.id ORDER BY it.invl) AS FieldName,
    ROW_NUMBER() OVER (PARTITION BY ir.id ORDER BY it.invl) AS FieldOrder
  FROM invl_table AS it
  JOIN involve_rec AS ir ON ir.invl = it.invl
  JOIN prog_enr_rec AS prog ON ir.id = prog.id
  WHERE (prog.acst = 'RENR' OR prog.acst = 'ENRF' OR prog.acst = 'ENRP')

  UNION ALL

  -- BEGIN DATE
  SELECT
    ir.id AS StudentID,
    'Involvement' AS DocumentCode,
    '2025-2026' AS AcademicYear,
    TO_CHAR(ir.beg_date, '%Y-%m-%d') AS FieldValue,
    'BeginDate' || ROW_NUMBER() OVER (PARTITION BY ir.id ORDER BY ir.beg_date) AS FieldName,
    ROW_NUMBER() OVER (PARTITION BY ir.id ORDER BY ir.beg_date) AS FieldOrder
  FROM involve_rec AS ir
  JOIN invl_table AS it ON ir.invl = it.invl
  JOIN prog_enr_rec AS prog ON ir.id = prog.id
  WHERE (prog.acst = 'RENR' OR prog.acst = 'ENRF' OR prog.acst = 'ENRP')

  UNION ALL

  -- END DATE
  SELECT
    ir.id AS StudentID,
    'Involvement' AS DocumentCode,
    '2025-2026' AS AcademicYear,
    TO_CHAR(ir.end_date, '%Y-%m-%d') AS FieldValue,
    'EndDate' || ROW_NUMBER() OVER (PARTITION BY ir.id ORDER BY ir.end_date) AS FieldName,
    ROW_NUMBER() OVER (PARTITION BY ir.id ORDER BY ir.end_date) AS FieldOrder
  FROM involve_rec AS ir
  JOIN invl_table AS it ON ir.invl = it.invl
  JOIN prog_enr_rec AS prog ON ir.id = prog.id
  WHERE (prog.acst = 'RENR' OR prog.acst = 'ENRF' OR prog.acst = 'ENRP')
) AS combined_result
WHERE StudentID <> '0' -- AND FieldValue IS NOT NULL
ORDER BY
  StudentID,
  FieldOrder,
  CASE FieldName
    WHEN 'Category' THEN 1
    WHEN 'Code' THEN 2
    WHEN 'BeginDate' THEN 3
    WHEN 'EndDate' THEN 4
    ELSE 5
  END;