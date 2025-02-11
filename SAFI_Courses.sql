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

-- Main
SELECT DISTINCT
  cw.id AS ExternalStudentId,
  prog.major1 AS ExternalProgramId,
  crs.crs_no AS ExternalCourseID,
  crs.title1 || crs.title2 || crs.title3 AS Description,
  CASE
    -- WHEN cw.stat='' THEN 'Projected'
    -- WHEN cw.stat='' THEN 'Scheduled'
    -- WHEN cw.stat='' THEN 'Passed'
    WHEN cw.stat='W' THEN 'Withdrawn'
    -- WHEN cw.stat='' THEN 'Failed'
    WHEN cw.stat='D' THEN 'Incomplete'  -- D for dropped = incomplete?
    WHEN cw.stat='R' THEN 'Enrolled'  -- R for registered = enrolled?
  END AS SchedulingStatus,
  be.term_begin_date AS StartDate,
  be.term_end_date AS EndDate,
  '' AS FirstAraIndicator,  -- leave blank
  '' AS IncompleteResolutionDate,  -- leave blank
  cw.grd AS Grade,
  CAST(cw.hrs AS DECIMAL(10, 2)) AS Units,
  '' AS DegreeApplicationUnits,  -- leave blank
  '' AS Comments,  -- leave blank
  CAST(acad.gpa AS DECIMAL(10, 2)) AS ProgramGpaAtCourseEnd,
  '' AS LastDateOfAttendance,  -- leave blank
  cw.site AS Location,
  CASE
    WHEN mtg.campus='MAIN' THEN 'Ground' 
    WHEN mtg.campus='ONLN' THEN 'Online'
    ELSE 'Ground'
  END AS Modality,
  '' AS SapApplicable,  -- leave blank
  'FALSE' AS RepeatIndicator,  -- default False
  --be.term_begin_date AS TermStartDate,  -- same as start date?
  be.term_begin_date AS TermStartDate,
  '' AS Schedule,  -- leave blank
  be.term_begin_date AS ScheduledInstructionStartDate,  -- same as start date?
  be.term_end_date AS ScheduledInstructionEndDate  -- same as end date?
 FROM cw_rec AS cw 
 JOIN crs_rec AS crs ON cw.crs_no=crs.crs_no AND cw.cat=crs.cat --AND cw.prog=cr.prog
 JOIN stu_acad_rec AS acad ON cw.id=acad.id AND cw.sess=acad.sess AND cw.yr=acad.yr AND cw.prog=acad.prog
 JOIN secmtg_rec AS secm ON cw.crs_no=secm.crs_no AND cw.cat=secm.cat AND cw.yr=secm.yr AND cw.sess=secm.sess AND cw.sec=secm.sec_no
 JOIN mtg_rec AS mtg ON secm.mtg_no=mtg.mtg_no AND secm.yr=mtg.yr AND secm.sess=mtg.sess 
 JOIN prog_enr_rec AS prog ON cw.id=prog.id AND cw.prog=prog.prog
 JOIN acad_cal_rec AS cal ON acad.prog=cal.prog AND acad.sess=cal.sess AND acad.yr=cal.yr
 JOIN TempBeginEndDates AS be ON cw.id=be.id AND cw.sess=be.sess AND cw.yr=be.yr --AND cal.subsess=be.subsess
 WHERE (prog.acst='RENR' OR prog.acst='ENRF' OR prog.acst='ENRP') AND (acad.reg_hrs>0 AND acad.wd_code<>'WD') AND YEAR(TO_DATE(be.term_begin_date, '%Y-%m-%d'))>2003; -- AND cw.id='443154';