-- limit 5

SELECT
  StudentId, DocumentCode, AcademicYear, FieldValue, TRIM(Fieldname) || FieldOrder AS FieldName
FROM (
  -- Sessn
  SELECT
    s.id AS StudentID,
    'ResidencyHall' AS DocumentCode,
    '2025-2026' AS AcademicYear,
    s.sess AS FieldValue,
    --'Session' || ROW_NUMBER() OVER (PARTITION BY s.id ORDER BY s.sess) AS FieldName
    'Session' AS FieldName,
    ROW_NUMBER() OVER (PARTITION BY s.id ORDER BY s.yr DESC, s.sess DESC) AS FieldOrder
    --ROW_NUMBER() OVER (PARTITION BY s.id ORDER BY s.sess) AS FieldOrder
  FROM stu_serv_rec AS s
  JOIN prog_enr_rec AS prog ON prog.id = s.id
  WHERE prog.acst IN ('RENR', 'ENRF', 'ENRP')

  UNION ALL

  -- Year
  SELECT
    s.id,
    'ResidencyHall',
    '2025-2026',
    CAST(s.yr AS VARCHAR(4)) AS FieldValue,
    --'Year' || ROW_NUMBER() OVER (PARTITION BY s.id ORDER BY s.yr) AS FieldName
    'Year' AS FieldName,
    ROW_NUMBER() OVER (PARTITION BY s.id ORDER BY s.yr DESC) AS FieldOrder
  FROM stu_serv_rec AS s
  JOIN prog_enr_rec AS prog ON prog.id = s.id
  WHERE prog.acst IN ('RENR', 'ENRF', 'ENRP')

  UNION ALL

  -- ActualHousing
  SELECT
    s.id,
    'ResidencyHall',
    '2025-2026',
    s.cur_hsg_stat AS FieldValue,
    --'ActualHousing' || ROW_NUMBER() OVER (PARTITION BY s.id ORDER BY s.cur_hsg_stat) AS FieldName
    'ActualHousing' AS FieldName,
    ROW_NUMBER() OVER (PARTITION BY s.id ORDER BY s.cur_hsg_stat DESC) AS FieldOrder
  FROM stu_serv_rec AS s
  JOIN prog_enr_rec AS prog ON prog.id = s.id
  WHERE prog.acst IN ('RENR', 'ENRF', 'ENRP')

  UNION ALL

  -- Building
  SELECT
    s.id,
    'ResidencyHall',
    '2025-2026',
    s.bldg AS FieldValue,
    --'Building' || ROW_NUMBER() OVER (PARTITION BY s.id ORDER BY s.bldg) AS FieldName
    'Building' AS FieldName,
    ROW_NUMBER() OVER (PARTITION BY s.id ORDER BY s.bldg DESC) AS FieldOrder
  FROM stu_serv_rec AS s
  JOIN prog_enr_rec AS prog ON prog.id = s.id
  WHERE prog.acst IN ('RENR', 'ENRF', 'ENRP')

  UNION ALL

  -- Room
  SELECT
    s.id,
    'ResidencyHall',
    '2025-2026',
    s.room AS FieldValue,
    --'Room' || ROW_NUMBER() OVER (PARTITION BY s.id ORDER BY s.room) AS FieldName
    'Room' AS FieldName,
    ROW_NUMBER() OVER (PARTITION BY s.id ORDER BY s.room DESC) AS FieldOrder
  FROM stu_serv_rec AS s
  JOIN prog_enr_rec AS prog ON prog.id = s.id
  WHERE prog.acst IN ('RENR', 'ENRF', 'ENRP')

  UNION ALL

  -- Suite
  SELECT
    s.id,
    'ResidencyHall',
    '2025-2026',
    s.suite AS FieldValue,
    --'Suite' || ROW_NUMBER() OVER (PARTITION BY s.id ORDER BY s.suite) AS FieldName
    'Suite' AS FieldName,
    ROW_NUMBER() OVER (PARTITION BY s.id ORDER BY s.suite DESC) AS FieldOrder
  FROM stu_serv_rec AS s
  JOIN prog_enr_rec AS prog ON prog.id = s.id
  WHERE prog.acst IN ('RENR', 'ENRF', 'ENRP')
) AS combined
WHERE combined.StudentID <> '0' AND combined.FieldOrder <= 5
ORDER BY
  StudentID,
  FieldOrder,
  CASE FieldName
    WHEN 'Session' THEN 1
    WHEN 'Year' THEN 2
    WHEN 'ActualHousing' THEN 3
    WHEN 'Building' THEN 4
    WHEN 'Room' THEN 5
    WHEN 'Suite' THEN 6
    ELSE 7
  END;