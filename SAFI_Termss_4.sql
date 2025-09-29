-- TERMPBEGINENDDATES ##############################################################################################################
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
    TermStartDate VARCHAR(10),
    TermEndDate VARCHAR(10)
);

-- Insert data into the temporary table
INSERT INTO TempBeginEndDates (id, prog, sess, subsess, yr, year_begin_date, year_end_date, TermStartDate, TermEndDate)
SELECT DISTINCT
  acad.id, 
  acad.prog,
  acad.sess, 
  cal.subsess,
  acad.yr,
  CASE 
    -- Standardize to August 26 of the year
    WHEN acad.sess = 'SP' THEN (acad.yr - 1) || '-08-23'
    WHEN acad.sess = 'FA' THEN acad.yr || '-08-23'
    WHEN acad.sess = 'SU' THEN acad.yr || '-08-23'
    ELSE TO_CHAR(cal.beg_date, 'YYYY-MM-DD')
  END AS year_begin_date,
  CASE 
    -- Standardize to May 20 of the year
    WHEN acad.sess = 'SP' THEN acad.yr || '-05-20'
    WHEN acad.sess = 'FA' THEN (acad.yr + 1) || '-05-20'
    WHEN acad.sess = 'SU' THEN (acad.yr + 1) || '-05-20'
    ELSE TO_CHAR(cal.end_date, 'YYYY-MM-DD')
  END AS year_end_date,
  COALESCE(MIN(TO_CHAR(cal.beg_date, '%Y-%m-%d')) OVER (PARTITION BY acad.id, acad.prog, acad.yr, acad.sess), TO_CHAR(cal.beg_date, '%Y-%m-%d')) AS TermStartDate,
  COALESCE(MAX(TO_CHAR(cal.end_date, '%Y-%m-%d')) OVER (PARTITION BY acad.id, acad.prog, acad.yr, acad.sess), TO_CHAR(cal.end_date, '%Y-%m-%d')) AS TermEndDate
FROM stu_acad_rec AS acad
JOIN acad_cal_rec AS cal ON cal.prog=acad.prog AND cal.yr=acad.yr AND cal.sess=acad.sess
JOIN cw_rec AS cw ON acad.id=cw.id AND cal.prog=cw.prog AND cal.yr=cw.yr AND cal.sess=cw.sess AND cal.subsess=cw.subsess
JOIN 
    (SELECT prog, yr, sess, MIN(subsess) AS subsess
     FROM acad_cal_rec
     --WHERE sess = 'SU'
     GROUP BY prog, yr, sess) AS first_subsess
  ON 
    cal.prog = first_subsess.prog 
    AND cal.yr = first_subsess.yr 
    AND cal.sess = first_subsess.sess 
    AND cal.subsess = first_subsess.subsess
WHERE (cal.prog = acad.prog AND cal.yr = acad.yr) AND acad.yr > 2003;

-- Check if the temporary table has data
SELECT * FROM TempBeginEndDates;

-- TEMPMAIN ############################################################################################################################

-- Drop the temporary table if it exists
DROP TABLE IF EXISTS TempMain;

-- Create the temporary table
CREATE TEMP TABLE TempMain (
    ExternalStudentID INT,
    ExternalProgramID CHAR(6),
    TermType VARCHAR(10),
    AcademicYears VARCHAR(1),
    AYNumber INT,
    AYStartDate VARCHAR(10),
    AYEndDate VARCHAR(10),
    TermPeriodDescription VARCHAR(8),
    TermStartDate VARCHAR(10),
    TermEndDate VARCHAR(10),
	  TermReportingYear VARCHAR(2),
    SttrCurrentStatus VARCHAR(1),
    StudentsTermStatusSubType VARCHAR(1),
    StudentsTermStatusEffectiveDate VARCHAR(1),
    OfficialLastDateOfAttendance VARCHAR(1),
    DateOfDetermination VARCHAR(1),
    ReturntoTitleIvSafiIndicator VARCHAR(1)
);

-- Insert data into the temporary table
INSERT INTO TempMain (ExternalStudentID, ExternalProgramID, TermType, AcademicYears, AYNumber, AYStartDate, AYEndDate, 
                      TermPeriodDescription, TermStartDate, TermEndDate, TermReportingYear, SttrCurrentStatus, 
          					  StudentsTermStatusSubType, StudentsTermStatusEffectiveDate, 
          					  OfficialLastDateOfAttendance, DateOfDetermination, ReturntoTitleIvSafiIndicator)

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
  be.year_end_date AS AYEndDate,  -- 05-18-2024
  acad.sess||acad.yr AS TermPeriodDescription,  -- FA 2023
  be.TermStartDate,
  be.TermEndDate,
  '' AS TermReportingYear,
  '' AS SttrCurrentStatus,
  '' AS StudentsTermStatusSubType,
  '' AS StudentsTermStatusEffectiveDate,
  '' AS OfficialLastDateOfAttendance,
  '' AS DateOfDetermination,
  '' AS ReturntoTitleIvSafiIndicator  
FROM stu_acad_rec AS acad
JOIN acad_cal_rec AS cal ON acad.prog=cal.prog AND acad.yr=cal.yr and acad.sess=cal.sess
JOIN prog_enr_rec AS prog ON acad.id=prog.id AND acad.prog=prog.prog
JOIN TempBeginEndDates AS be ON acad.id=be.id and acad.yr=be.yr and acad.sess=be.sess AND cal.subsess=be.subsess
WHERE (prog.acst='RENR' OR prog.acst='ENRF' OR prog.acst='ENRP') AND acad.reg_hrs>0 AND acad.wd_code<>'WD' AND acad.sess<>'WI' AND acad.yr > 2021; -- and acad.id='603255';

-- Check if the temporary table has data
SELECT * FROM TempMain;

-- TEMPHASFA / TEMPHASSP ##############################################################################################################
DROP TABLE IF EXISTS TempMissingSemester;

-- Create the temporary table
CREATE TEMP TABLE TempMissingSemester (
    ExternalStudentID INT,
    AYNumber INT,
    TermCount INT,
    HasFA INT,
    HasSP INT
);
-- getting all students that have only a FA term or only a SP term in an AY
INSERT INTO TempMissingSemester(ExternalStudentID, AYNumber, TermCount, HasFA, HasSP)
SELECT *
FROM (
    SELECT 
        tm.ExternalStudentID,
        tm.AYNumber,
        COUNT(DISTINCT tm.TermPeriodDescription) AS TermCount,
        MAX(CASE WHEN tm.TermPeriodDescription LIKE 'FA%' THEN 1 ELSE 0 END) AS HasFA,
        MAX(CASE WHEN tm.TermPeriodDescription LIKE 'SP%' THEN 1 ELSE 0 END) AS HasSP
    FROM TempMain AS tm
    GROUP BY tm.ExternalStudentID, tm.AYNumber
) AS aggregated
WHERE TermCount = 1;

SELECT * FROM TempMissingSemester;

-- ##############################################################################################################################

DROP TABLE IF EXISTS TempMain2;

-- Create the temporary table
CREATE TEMP TABLE TempMain2 (
    ExternalStudentID INT,
    ExternalProgramID CHAR(6),
    TermType VARCHAR(10),
    AcademicYears VARCHAR(1),
    AYNumber INT,
    AYStartDate VARCHAR(10),
    AYEndDate VARCHAR(10),
    TermPeriodDescription VARCHAR(8),
    TermStartDate VARCHAR(10),
    TermEndDate VARCHAR(10),
    TermReportingYear VARCHAR(1),
    SttrCurrentStatus VARCHAR(1),
    StudentsTermStatusSubType VARCHAR(1),
    StudentsTermStatusEffectiveDate VARCHAR(1),
    OfficialLastDateOfAttendance VARCHAR(1),
    DateOfDetermination VARCHAR(1),
    ReturntoTitleIvSafiIndicator VARCHAR(1)
);

-- Insert the missing semester
INSERT INTO TempMain2 (ExternalStudentID, ExternalProgramID, TermType, AcademicYears, AYNumber, AYStartDate, AYEndDate, 
                      TermPeriodDescription, TermStartDate, TermEndDate, TermReportingYear, SttrCurrentStatus, 
          					  StudentsTermStatusSubType, StudentsTermStatusEffectiveDate, 
          					  OfficialLastDateOfAttendance, DateOfDetermination, ReturntoTitleIvSafiIndicator)
SELECT
    tms.ExternalStudentID,
    tm.ExternalProgramID,
    tm.TermType,
    tm.AcademicYears,
    tms.AYNumber,
    CASE
      WHEN tms.HasFA = 0 AND tms.HasSP = 1  THEN tms.AYNumber - 1||'-08'||'-23'  -- Fall missing
      WHEN tms.HasFA = 1 AND tms.HasSP = 0 THEN tms.AYNumber - 1||'-08'||'-23'  -- Spring missing
      WHEN tms.HasFA = 0 AND tms.HasSP = 0 THEN tm.AYStartDate -- Fall & Spring missing
    END AS AYStartDate,
    CASE
      WHEN tms.HasFA = 0 AND tms.HasSP = 1  THEN tms.AYNumber||'-05'||'-20'  -- Fall missing
      WHEN tms.HasFA = 1 AND tms.HasSP = 0 THEN tms.AYNumber||'-05'||'-20'  -- Spring missing
      WHEN tms.HasFA = 0 AND tms.HasSP = 0 THEN tm.AYEndDate  -- Fall & Spring missing
    END AS AYEndDate,
    CASE
      WHEN tms.HasFA = 0 AND tms.HasSP = 0 THEN 'SU ' || ' ' || tms.AYNumber -1
      WHEN tms.HasFA = 0 AND tms.HasSP = 1 THEN 'FA' || ' ' || tms.AYNumber - 1
      WHEN tms.HasFA = 1 AND tms.HasSP = 0 THEN 'SP' || ' ' || tms.AYNumber
    END AS TermPeriodDescription,
    CASE
      WHEN tms.HasFA = 0 AND tms.HasSP = 0  THEN tm.TermStartDate  -- Summer term start
      WHEN tms.HasFA = 0 AND tms.HasSP = 1  THEN tms.AYNumber - 1 ||'-08'||'-23'  -- Fall term start
      WHEN tms.HasFA = 1 AND tms.HasSP = 0 THEN tms.AYNumber ||'-01'||'-23'  -- Spring term start
    END AS TermStartDate,
    CASE
      WHEN tms.HasFA = 0 AND tms.HasSP = 0  THEN tm.TermEndDate  -- Summer term end
      WHEN tms.HasFA = 0 AND tms.HasSP = 1  THEN tm.AYNumber - 1 ||'-12'||'-15'  -- Fall term end
      WHEN tms.HasFA = 1 AND tms.HasSP = 0 THEN tm.AYNumber ||'-05'||'-20'  -- Spring term end
    END AS TermEndDate,
	  tm.TermReportingYear,
    tm.SttrCurrentStatus,
    tm.StudentsTermStatusSubType,
    tm.StudentsTermStatusEffectiveDate,
    tm.OfficialLastDateOfAttendance,
    tm.DateOfDetermination,
    tm.ReturntoTitleIvSafiIndicator  
FROM TempMain AS tm
JOIN TempMissingSemester AS tms ON tm.ExternalStudentID = tms.ExternalStudentID AND tms.AYNumber = tm.AYNumber;

SELECT DISTINCT * FROM TempMain2;

-- TEMPHASSU ##############################################################################################################
DROP TABLE IF EXISTS TempMissingSUSemester;

-- Create the temporary table
CREATE TEMP TABLE TempMissingSUSemester (
    ExternalStudentID INT,
    AYNumber INT,
    TermCount INT,
    HasSU INT
);
-- getting all students that have only a FA term or only a SP term in an AY
INSERT INTO TempMissingSUSemester(ExternalStudentID, AYNumber, TermCount, HasSU)
SELECT *
FROM (
    SELECT 
        tm.ExternalStudentID,
        tm.AYNumber,
        COUNT(DISTINCT tm.TermPeriodDescription) AS TermCount,
        MAX(CASE WHEN tm.TermPeriodDescription LIKE 'SU%' THEN 1 ELSE 0 END) AS HasSU
    FROM TempMain2 AS tm
    GROUP BY tm.ExternalStudentID, tm.AYNumber
) AS aggregated
WHERE TermCount = 1 AND HasSU=1; -- only summer terms are counted

SELECT * FROM TempMissingSUSemester;

-- ##########################################################################################################################

DROP TABLE IF EXISTS TempMain3;

-- Create the temporary table
CREATE TEMP TABLE TempMain3 (
    ExternalStudentID INT,
    ExternalProgramID CHAR(6),
    TermType VARCHAR(10),
    AcademicYears VARCHAR(1),
    AYNumber INT,
    AYStartDate VARCHAR(10),
    AYEndDate VARCHAR(10),
    TermPeriodDescription VARCHAR(8),
    TermStartDate VARCHAR(10),
    TermEndDate VARCHAR(10),
    TermReportingYear VARCHAR(1),
    SttrCurrentStatus VARCHAR(1),
    StudentsTermStatusSubType VARCHAR(1),
    StudentsTermStatusEffectiveDate VARCHAR(1),
    OfficialLastDateOfAttendance VARCHAR(1),
    DateOfDetermination VARCHAR(1),
    ReturntoTitleIvSafiIndicator VARCHAR(1)
);

-- Insert the missing semester
INSERT INTO TempMain3 (ExternalStudentID, ExternalProgramID, TermType, AcademicYears, AYNumber, AYStartDate, AYEndDate, 
                      TermPeriodDescription, TermStartDate, TermEndDate, TermReportingYear, SttrCurrentStatus, 
          					  StudentsTermStatusSubType, StudentsTermStatusEffectiveDate, 
          					  OfficialLastDateOfAttendance, DateOfDetermination, ReturntoTitleIvSafiIndicator)
SELECT
    tmss.ExternalStudentID,
    tm.ExternalProgramID,
    'Semester' AS TermType,
    tm.AcademicYears,
    tmss.AYNumber,
    tm.AYStartDate,
    tm.AYEndDate,
    -- AND tms.HasFA=0 AND tms.HasSP=0
    CASE
      WHEN tmss.HasSU = 1 THEN 'FA ' || (tmss.AYNumber - 1)  -- Fall term description
      WHEN tmss.HasSU = 1 THEN 'SP ' || (tmss.AYNumber)      -- Spring term description
    END AS TermPeriodDescription,
    CASE
      WHEN tmss.HasSU = 1 THEN (tmss.AYNumber - 1) || '-08-23'  -- Fall term start
      WHEN tmss.HasSU = 1 THEN tm.TermStartDate  -- Spring term start
    END AS TermStartDate,
    CASE
      WHEN tmss.HasSU = 1 THEN (tmss.AYNumber - 1) || '-12-15'  -- Fall term end
      WHEN tmss.HasSU = 1 THEN tm.AYEndDate  -- Spring term end
    END AS TermEndDate,
	  tm.TermReportingYear,
    tm.SttrCurrentStatus,
    tm.StudentsTermStatusSubType,
    tm.StudentsTermStatusEffectiveDate,
    tm.OfficialLastDateOfAttendance,
    tm.DateOfDetermination,
    tm.ReturntoTitleIvSafiIndicator  
FROM TempMain AS tm
JOIN TempMissingSUSemester AS tmss ON tm.ExternalStudentID = tmss.ExternalStudentID AND tmss.AYNumber = tm.AYNumber
JOIN TempMissingSemester AS tms ON tmss.ExternalStudentID = tms.ExternalStudentID AND tms.AYNumber = tmss.AYNumber;

SELECT DISTINCT * FROM TempMain3;

-- ##############################################################################################################################

-- Insert Fall and Spring rows for summer-only students
INSERT INTO TempMain3 (ExternalStudentID, ExternalProgramID, TermType, AcademicYears, AYNumber, AYStartDate, AYEndDate, 
                      TermPeriodDescription, TermStartDate, TermEndDate, TermReportingYear, SttrCurrentStatus, 
          					  StudentsTermStatusSubType, StudentsTermStatusEffectiveDate, 
          					  OfficialLastDateOfAttendance, DateOfDetermination, ReturntoTitleIvSafiIndicator)
SELECT
    tmss.ExternalStudentID,
    tm.ExternalProgramID,
    'Semester' AS TermType,
    tm.AcademicYears,
    tmss.AYNumber AS AYNumber,  -- Fall semester
    (tmss.AYNumber - 1) || '-08-23' AS AYStartDate,
    (tmss.AYNumber) || '-05-20' AS AYEndDate,
    'FA ' || (tmss.AYNumber-1) AS TermPeriodDescription,
    (tmss.AYNumber - 1) || '-08-23' AS TermStartDate,
    (tmss.AYNumber - 1) || '-12-15' AS TermEndDate,
    tm.TermReportingYear,
    tm.SttrCurrentStatus,
    tm.StudentsTermStatusSubType,
    tm.StudentsTermStatusEffectiveDate,
    tm.OfficialLastDateOfAttendance,
    tm.DateOfDetermination,
    tm.ReturntoTitleIvSafiIndicator  
FROM TempMain AS tm
JOIN TempMissingSUSemester AS tmss ON tm.ExternalStudentID = tmss.ExternalStudentID AND tmss.AYNumber = tm.AYNumber;

-- Insert Spring semester row
INSERT INTO TempMain3 (ExternalStudentID, ExternalProgramID, TermType, AcademicYears, AYNumber, AYStartDate, AYEndDate, 
                      TermPeriodDescription, TermStartDate, TermEndDate, TermReportingYear, SttrCurrentStatus, 
          					  StudentsTermStatusSubType, StudentsTermStatusEffectiveDate, 
          					  OfficialLastDateOfAttendance, DateOfDetermination, ReturntoTitleIvSafiIndicator)
SELECT DISTINCT
    tmss.ExternalStudentID,
    tm.ExternalProgramID,
    'Semester' AS TermType,
    tm.AcademicYears,
    tmss.AYNumber AS AYNumber,  -- Spring semester
    tm.AYStartDate AS AYStartDate,
    tm.AYEndDate AS AYEndDate,
    'SP ' || (tmss.AYNumber) AS TermPeriodDescription,
    (tmss.AYNumber) || '-01-14' AS TermStartDate,
    (tmss.AYNumber) || '-05-20' AS TermEndDate,
--    tm.AYStartDate AS TermStartDate,  -- currently 08-26 needs to be 01-26
--    tm.AYEndDate AS TermEndDate,
    tm.TermReportingYear,
    tm.SttrCurrentStatus,
    tm.StudentsTermStatusSubType,
    tm.StudentsTermStatusEffectiveDate,
    tm.OfficialLastDateOfAttendance,
    tm.DateOfDetermination,
    tm.ReturntoTitleIvSafiIndicator  
FROM TempMain AS tm
JOIN TempMissingSUSemester AS tmss ON tm.ExternalStudentID = tmss.ExternalStudentID AND tmss.AYNumber = tm.AYNumber;

SELECT DISTINCT * FROM TempMain3;

-- ##############################################################################################################################
-- INSERT ROWS FROM TEMPMAIN2 INTO TEMPMAIN
INSERT INTO TempMain (ExternalStudentID, ExternalProgramID, TermType, AcademicYears, AYNumber, AYStartDate, AYEndDate, 
                      TermPeriodDescription, TermStartDate, TermEndDate, TermReportingYear, SttrCurrentStatus, 
          					  StudentsTermStatusSubType, StudentsTermStatusEffectiveDate, 
          					  OfficialLastDateOfAttendance, DateOfDetermination, ReturntoTitleIvSafiIndicator)
SELECT DISTINCT
    ExternalStudentID,
    ExternalProgramID,
    TermType,
    AcademicYears,
    AYNumber,
    AYStartDate,
    AYEndDate,
    TermPeriodDescription,
    TermStartDate, -- needs to be standardized
    TermEndDate,  -- needs to be standardized
  	TermReportingYear,
  	SttrCurrentStatus,
    StudentsTermStatusSubType,
    StudentsTermStatusEffectiveDate,
    OfficialLastDateOfAttendance,
    DateOfDetermination,
    ReturntoTitleIvSafiIndicator
FROM TempMain2;

-- ##############################################################################################################################
-- INSERT ROWS FROM TEMPMAIN3 INTO TEMPMAIN
INSERT INTO TempMain (ExternalStudentID, ExternalProgramID, TermType, AcademicYears, AYNumber, AYStartDate, AYEndDate, 
                      TermPeriodDescription, TermStartDate, TermEndDate, TermReportingYear, SttrCurrentStatus, 
          					  StudentsTermStatusSubType, StudentsTermStatusEffectiveDate, 
          					  OfficialLastDateOfAttendance, DateOfDetermination, ReturntoTitleIvSafiIndicator)
SELECT 
    ExternalStudentID,
    ExternalProgramID,
    TermType,
    AcademicYears,
    AYNumber,
    AYStartDate,
    AYEndDate,
    TermPeriodDescription,
    TermStartDate, -- needs to be standardized
    TermEndDate,  -- needs to be standardized
  	TermReportingYear,
  	SttrCurrentStatus,
    StudentsTermStatusSubType,
    StudentsTermStatusEffectiveDate,
    OfficialLastDateOfAttendance,
    DateOfDetermination,
    ReturntoTitleIvSafiIndicator
FROM TempMain3;

SELECT DISTINCT * FROM TEMPMAIN; -- WHERE externalstudentid = '601022';