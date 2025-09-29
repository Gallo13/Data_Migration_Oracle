-- Drop the temporary table if it exists
DROP TABLE IF EXISTS TempBeginEndDates;

-- Create the temporary table
CREATE TEMP TABLE TempBeginEndDates (
    id INT,
    prog CHAR(6),
    major CHAR (6),
    sess VARCHAR(2),
    subsess VARCHAR(2),
    yr INT,
    year_begin_date VARCHAR(10),
    year_end_date VARCHAR(10),
    term_begin_date VARCHAR(10),
    term_end_date VARCHAR(10)
);

-- Insert data into the temporary table
INSERT INTO TempBeginEndDates (id, prog, major, sess, subsess, yr, year_begin_date, year_end_date, term_begin_date, term_end_date)
SELECT DISTINCT
  acad.id, 
  acad.prog,
  prog.major1,
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
JOIN prog_enr_rec AS prog ON cw.id=prog.id AND cw.prog=prog.prog
WHERE (prog.acst='RENR' OR prog.acst='ENRF' OR prog.acst='ENRP') AND (cal.prog = acad.prog AND cal.yr = acad.yr) AND acad.yr>2003 AND cw.stat <> 'L';

SELECT * FROM TempBeginEndDates;

-- Drop the temporary table if it exists
DROP TABLE IF EXISTS TempMain;

-- Create the temporary table
CREATE TEMP TABLE TempMain (
    ExternalStudentId INT, 
    ExternalProgramId VARCHAR(10), 
    ExternalCourseID VARCHAR(25), 
    Description VARCHAR(50), 
    SchedulingStatus VARCHAR(15), 
    StartDate VARCHAR(10), 
    EndDate VARCHAR(10), 
    FirstAraIndicator VARCHAR(5), 
    IncompleteResolutionDate VARCHAR(10), 
    Grade VARCHAR(2), 
    Units FLOAT, 
    DegreeApplicationUnits FLOAT, 
    Comments VARCHAR(50), 
    ProgramGpaAtCourseEnd VARCHAR(10),
    LastDateOfAttendance VARCHAR(10), 
    Location VARCHAR(15), 
    Modality VARCHAR(6), 
    SapApplicable VARCHAR(2), 
    RepeatIndicator VARCHAR(5), 
    TermStartDate VARCHAR(10), 
    TermEndDate VARCHAR(10), 
    Schedule VARCHAR(5),
    StcStartDates VARCHAR(10), 
    StcEndDate VARCHAR(10)
);

-- Insert data into the temporary table
INSERT INTO TempMain (ExternalStudentId, ExternalProgramId, ExternalCourseID, Description, SchedulingStatus, StartDate, EndDate, 
                      FirstAraIndicator, IncompleteResolutionDate, Grade, Units, DegreeApplicationUnits, Comments, ProgramGpaAtCourseEnd,
                      LastDateOfAttendance, Location, Modality, SapApplicable, RepeatIndicator, TermStartDate, TermEndDate, Schedule,
                      StcStartDates, StcEndDate)
SELECT DISTINCT
  cw.id AS ExternalStudentId,
  be.major AS ExternalProgramId,
  crs.crs_no AS ExternalCourseID,
  crs.title1 || crs.title2 || crs.title3 AS Description,
  CASE
    -- WHEN cw.stat='' THEN 'Projected'
    -- WHEN cw.sess='FA' THEN 'Scheduled'
    -- PASSED
    WHEN cw.stat='R' AND (cw.grd='P' OR cw.grd IN ('P','A','A-','B+','B','B-','C+','C','C-','D+','D','D-')) THEN 'Passed'
    -- WITHDRAWN
    WHEN cw.stat IN ('W','X') AND cw.grd IN ('IP','W') THEN 'Withdrawn'
    WHEN cw.stat='R' AND cw.grd='W' THEN 'Withdrawn'
    WHEN cw.stat='W' THEN 'Withdrawn'
    -- FAILED
    WHEN cw.stat='R' AND cw.grd='F' THEN 'Failed'
    -- INCOMPLETE
    WHEN cw.stat='R' AND cw.grd IN ('I','I/F','AU','NR') THEN 'Incomplete'  -- remove a D 
    --WHEN cw.stat='D' AND cw.grd IN ('IP','F') THEN 'Incomplete'
    --WHEN cw.stat='D' THEN 'Incomplete'  -- do not report these courses
    -- ENROLLED
    WHEN cw.stat='R' AND cw.grd='IP' THEN 'Enrolled'  -- R for registered = enrolled?
    --WHEN cw.stat='L' THEN 'Projected' -- L means waitlist
    
    -- scheduled: when courses didn't start 
    ELSE 'NULL'
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
  be.term_begin_date AS TermStartDate,  -- same as start date?
  be.term_end_date AS TermEndDate,
  '' AS Schedule, -- leave blank
  be.term_begin_date AS StcStartDates,  -- same as start date?
  be.term_end_date AS StcEndDate  -- same as end date?
FROM cw_rec AS cw 
JOIN crs_rec AS crs ON cw.crs_no=crs.crs_no AND cw.cat=crs.cat
JOIN stu_acad_rec AS acad ON cw.id=acad.id AND cw.yr=acad.yr AND cw.prog=acad.prog AND cw.sess=acad.sess
JOIN secmtg_rec AS secm ON cw.crs_no=secm.crs_no AND cw.cat=secm.cat AND cw.yr=secm.yr AND cw.sess=secm.sess AND cw.sec=secm.sec_no
JOIN mtg_rec AS mtg ON secm.mtg_no=mtg.mtg_no AND secm.yr=mtg.yr AND secm.sess=mtg.sess 
JOIN acad_cal_rec AS cal ON acad.prog=cal.prog AND acad.sess=cal.sess AND acad.yr=cal.yr --AND cw.subsess=cal.subsess
JOIN TempBeginEndDates AS be ON cw.id=be.id AND cw.yr=be.yr AND cw.sess=be.sess AND cw.subsess=be.subsess   --AND cal.subsess=be.subsess
WHERE cw.stat <> 'L'
ORDER BY cw.id, be.term_begin_date;

SELECT * 
FROM TempMain
WHERE SchedulingStatus IS NOT NULL;
