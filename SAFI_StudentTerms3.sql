-- Drop the temporary table if it exists
DROP TABLE IF EXISTS TempBeginEndDates;

-- Create the temporary table
CREATE TEMP TABLE TempBeginEndDates (
    id INT,
    prog CHAR(6),
    sess VARCHAR(2),
    subsess VARCHAR(2),
    yr INT,
    year_begin_date VARCHAR(10),
    year_end_date VARCHAR(10),
    term_begin_date VARCHAR(10),
    term_end_date VARCHAR(10)
);

-- Insert data into the temporary table
INSERT INTO TempBeginEndDates (id, prog, sess, subsess, yr, year_begin_date, year_end_date, term_begin_date, term_end_date)
SELECT DISTINCT
  acad.id, 
  acad.prog,
  acad.sess, 
  cal.subsess,
  acad.yr,
  CASE 
    -- Standardize to August 26 of the year
    WHEN acad.sess = 'SP' THEN (acad.yr - 1) || '-08-26'
    WHEN acad.sess = 'FA' THEN acad.yr || '-08-26'
    WHEN acad.sess = 'SU' THEN acad.yr || '-08-26'
    ELSE TO_CHAR(cal.beg_date, 'YYYY-MM-DD')
  END AS year_begin_date,
  CASE 
    -- Standardize to May 14 of the year
    WHEN acad.sess = 'SP' THEN acad.yr || '-05-14'
    WHEN acad.sess = 'FA' THEN (acad.yr + 1) || '-05-14'
    WHEN acad.sess = 'SU' THEN (acad.yr + 1) || '-05-14'
    ELSE TO_CHAR(cal.end_date, 'YYYY-MM-DD')
  END AS year_end_date,
  TO_CHAR(cal.beg_date, '%Y-%m-%d') AS term_begin_date,
  TO_CHAR(cal.end_date, '%Y-%m-%d') AS term_end_date
FROM stu_acad_rec AS acad
JOIN acad_cal_rec AS cal ON cal.prog=acad.prog AND cal.yr=acad.yr AND cal.sess=acad.sess
JOIN cw_rec AS cw ON acad.id=cw.id AND cal.prog=cw.prog AND cal.yr=cw.yr AND cal.sess=cw.sess AND cal.subsess=cw.subsess
WHERE (cal.prog = acad.prog AND cal.yr = acad.yr) AND acad.yr>2003;

-- Main Query
SELECT
  acad.id AS ExternalStudentID,
  prog.major1 AS ExternalProgramID,
  CASE
    WHEN acad.sess = 'FA' or acad.sess = 'SP' THEN 'Semester' 
    WHEN acad.sess = 'SU' THEN 'Summer'
  END AS TermType,
  '' AS AcademicYears,
  CASE
    WHEN acad.sess='FA' OR acad.sess='SU' THEN acad.yr + 1
    ELSE acad.yr
  END AS AYNumber,  -- i.e. 2023
  be.year_begin_date AS AYStartDate,  -- 08-26-2023
  be.year_end_date AS AYEndDate,  -- 05-15-2024
  acad.sess || acad.yr AS TermPeriodDescription,  -- FA 2023
  TO_CHAR(cal.beg_date, '%Y-%m-%d') AS TermStartDate,
  TO_CHAR(cal.end_date, '%Y-%m-%d') AS TermEndDate
FROM stu_acad_rec AS acad
JOIN acad_cal_rec AS cal ON acad.prog=cal.prog AND acad.sess=cal.sess AND acad.yr=cal.yr
JOIN prog_enr_rec AS prog ON acad.id=prog.id AND acad.prog=prog.prog
JOIN TempBeginEndDates AS be ON acad.id=be.id AND acad.sess=be.sess AND acad.yr=be.yr AND cal.subsess=be.subsess
WHERE (prog.acst='RENR' OR prog.acst='ENRF' OR prog.acst='ENRP') AND acad.reg_hrs>0 AND acad.wd_code<>'WD' AND acad.sess<>'WI' AND acad.yr>2021; -- AND acad.id='587439'; 