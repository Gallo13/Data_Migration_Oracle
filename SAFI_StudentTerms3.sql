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
SELECT 
  acad.id, 
  acad.prog,
  acad.sess, 
  cal.subsess,
  acad.yr,
  TO_CHAR( 
  CASE 
    WHEN acad.sess = 'SP' THEN ADD_MONTHS(cal.beg_date, -12)
    ELSE cal.beg_date 
  END, '%Y-%m-%d') AS year_begin_date,
  TO_CHAR( 
  CASE 
    WHEN acad.sess = 'FA' THEN ADD_MONTHS(cal.beg_date, +9)
    WHEN acad.sess = 'SU' THEN ADD_MONTHS(cal.beg_date, +11)
    ELSE cal.end_date 
  END, '%Y-%m-%d') AS year_end_date,
  TO_CHAR(cal.beg_date, '%Y-%m-%d') AS term_begin_date,
  TO_CHAR(cal.end_date, '%Y-%m-%d') AS term_end_date
FROM acad_cal_rec AS cal
JOIN stu_acad_rec AS acad ON cal.prog = acad.prog AND cal.yr = acad.yr
WHERE cal.prog = acad.prog AND cal.sess = 'FA' AND cal.yr = acad.yr;

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
  be.term_begin_date AS TermStartDate,  -- 08-26-2023
  be.term_end_date AS TermEndDate  -- 12-15-2023
FROM stu_acad_rec AS acad
JOIN acad_cal_rec AS cal ON acad.prog=cal.prog AND acad.sess=cal.sess AND acad.yr=cal.yr
JOIN prog_enr_rec AS prog ON acad.id=prog.id
JOIN TempBeginEndDates AS be ON acad.id=be.id AND acad.sess=be.sess AND acad.yr=be.yr AND cal.subsess=be.subsess
WHERE (prog.acst='RENR' OR prog.acst='ENRF' OR prog.acst='ENRP') AND acad.reg_hrs>0 AND acad.wd_code<>'WD' AND acad.sess<>'WI' AND acad.yr>2021; -- AND acad.id='214451';
