-- Drop the temporary table if it exists
DROP TABLE IF EXISTS TempChangeOfProgramStartDate;

-- Create the temporary table with the desired structure
CREATE TEMP TABLE TempChangeOfProgramStartDate (
    id INT,
    ChangeOfProgramStartDate CHAR(10),
    previous_program VARCHAR(50),
    current_program VARCHAR(50)
);

-- Insert data into the temporary table using your query
INSERT INTO TempChangeOfProgramStartDate (id, ChangeOfProgramStartDate, previous_program, current_program)
SELECT
    curr.id,
    CASE
      WHEN curr.sess = 'FA' THEN curr.yr || '-08-20'
      WHEN curr.sess = 'SP' THEN curr.yr || '-01-20'
      WHEN curr.sess = 'SU' THEN curr.yr || '-05-20'
      ELSE NULL
    END AS ChangeOfProgramStartDate,
    prev.prog AS previous_program,
    curr.prog AS current_program
FROM 
    stu_acad_rec AS curr
JOIN 
    stu_acad_rec AS prev ON curr.id = prev.id 
                         AND (
                             (curr.yr = prev.yr AND 
                              CASE curr.sess 
                                  WHEN 'SP' THEN 1
                                  WHEN 'SU' THEN 2
                                  WHEN 'FA' THEN 3
                              END > 
                              CASE prev.sess 
                                  WHEN 'SP' THEN 1
                                  WHEN 'SU' THEN 2
                                  WHEN 'FA' THEN 3
                              END) 
                             OR 
                             (curr.yr = prev.yr + 1 AND curr.sess = 'SP' AND prev.sess = 'FA')  -- Handle year transition
                         )
 JOIN prog_enr_rec AS prog ON curr.id=prog.id
WHERE 
    curr.prog <> prev.prog  -- Check for different programs
    --AND (prog.acst = 'RENR' OR prog.acst = 'ENRF' OR prog.acst = 'ENRP')
ORDER BY 
    curr.yr DESC, 
    CASE curr.sess 
        WHEN 'SP' THEN 1
        WHEN 'SU' THEN 2
        WHEN 'FA' THEN 3
    END DESC;  -- Order by year and session

SELECT * FROM TempChangeOfProgramStartDate;

-- Drop the temporary table if it exists
DROP TABLE IF EXISTS TempMain;

-- Create the temporary table with the desired structure
CREATE TEMP TABLE TempMain (
    ExternalStudentID INT,
    ExternalProgramID VARCHAR(10),
    Code VARCHAR(30),
    Description VARCHAR(50),
    ProgramType VARCHAR(30), 
    FirstProfessionalDegreeIndicator VARCHAR(10),
    College VARCHAR(6), 
    SpecialPrograms VARCHAR(5), 
    ProgramCipCode VARCHAR(20), 
    ProgramLengthMeasurementUnit VARCHAR(10), 
    ProgramNumberOfUnits VARCHAR(5),
    ProgramMeasurementUnit VARCHAR(6), 
    AssessedUnits FLOAT, 
    TotalRequiredUnits VARCHAR(5), 
    PrimaryLocation VARCHAR(10), 
    OpeID VARCHAR(8), 
    Modality VARCHAR(10),
    FaEligibleIndicator VARCHAR(10), 
    AcademicYearMeasurementUnit VARCHAR(10), 
    NumberOfUnits VARCHAR(5), 
    NumberOfInstructionalWeeks VARCHAR(5),
    PrimaryProgramIndicator VARCHAR(10), 
    Gpa DECIMAL(10, 2), 
    RequiredGpa DECIMAL(10, 2), 
    ProgramStartDate VARCHAR(10), 
    ChangeOfProgramStartDate VARCHAR(10), 
    AcademicCompletionDate CHAR(10),
    OfficialLastDateOfAttendance VARCHAR(10), 
    DateOfDetermination VARCHAR(10), 
    EnrollmentStatus VARCHAR(10), 
    EnrollmentStatusSubType VARCHAR(25), 
    EnrollmentStatusEffectiveDate VARCHAR(25), 
    AdmissionStatus VARCHAR(5), 
    AcademicStatus VARCHAR(5), 
    ManualSapEvalutationIndictator VARCHAR(50),
    SchoolName VARCHAR(50), 
    NSLDSSchoolcode VARCHAR(50), 
    AcceptedUnits VARCHAR(50), 
    StprCurrentStatus VARCHAR(50), 
    programstartDT VARCHAR(50), 
    programENDDT VARCHAR(50),
    enrstat VARCHAR(4)
);

-- Insert data into the temporary table using your query
INSERT INTO TempMain (ExternalStudentID, ExternalProgramID, Code, Description, ProgramType, FirstProfessionalDegreeIndicator,
                      College, SpecialPrograms, ProgramCipCode, ProgramLengthMeasurementUnit, ProgramNumberOfUnits,
                      ProgramMeasurementUnit, AssessedUnits, TotalRequiredUnits, PrimaryLocation, OpeID, Modality,
                      FaEligibleIndicator, AcademicYearMeasurementUnit, NumberOfUnits, NumberOfInstructionalWeeks,
                      PrimaryProgramIndicator, Gpa, RequiredGpa, ProgramStartDate, ChangeOfProgramStartDate, AcademicCompletionDate,
                      OfficialLastDateOfAttendance, DateOfDetermination, EnrollmentStatus, EnrollmentStatusSubType, 
                      EnrollmentStatusEffectiveDate, AdmissionStatus, AcademicStatus, ManualSapEvalutationIndictator,
                      SchoolName, NSLDSSchoolcode, AcceptedUnits, StprCurrentStatus, programstartDT, programENDDT, enrstat)
-- Main Query Gets all Data
SELECT DISTINCT
  id.id AS ExternalStudentID,
  prog.major1 AS ExternalProgramID,
   CASE
    WHEN prog.prog IN ('NONU','NONC','NONG','PREC','UPST','POST') THEN 'Non-credential' || 'Ground'
    WHEN prog.prog IN ('UNDG', 'UUDG','UUD2') THEN 'Bachelors' || 'Ground'
    WHEN prog.prog IN ('GRAD','GRA2','GRA3','EMBA') THEN 'Graduate' || 'Ground'
    WHEN prog.prog = 'CERT' THEN 'Certificate(Graduate)' || 'Ground'
    WHEN prog.prog IN ('DOCT', 'OTD') THEN 'Doctoral' || 'Ground'
  END AS Code,
  major.txt AS Description,
  CASE
    WHEN prog.prog IN ('NONU', 'NONC', 'NONG', 'PREC', 'UPST', 'POST')
         THEN 'Non-credential (' || prog.prog || ')'
    WHEN prog.prog IN ('UNDG', 'UUDG', 'UUD2')
         THEN 'Bachelors (' || prog.prog || ')'
    WHEN prog.prog IN ('GRAD', 'GRA2', 'GRA3', 'EMBA')
         THEN 'Graduate (' || prog.prog || ')'
    WHEN prog.prog = 'CERT'
         THEN 'Certificate (Graduate)'
    WHEN prog.prog IN ('DOCT', 'OTD')
         THEN 'Doctoral (' || prog.prog || ')'
  END AS ProgramType,
  CASE
    WHEN prog.prog IN ('UUD2', 'GRA2', 'GRA3') THEN 'TRUE'
    ELSE 'FALSE' 
  END AS FirstProfessionalDegreeIndicator,
  'Wagner' AS College,
  -- need to check for special programs
  'N' AS SpecialPrograms,
  major.cip_no AS ProgramCipCode,
  'Years' AS ProgramLengthMeasurementUnit,
  CASE
    WHEN prog.prog IN ('NONU', 'NONG', 'PREC', 'UPST', 'POST') THEN '0'
    WHEN prog.prog = 'NONC' THEN '2'
    WHEN prog.prog IN ('UNDG', 'UUDG', 'UUD2') THEN '4'
    WHEN prog.prog IN ('GRAD', 'GRA2', 'GRA3', 'EMBA', 'CERT', 'DOCT', 'OTD') THEN '2'
  END AS ProgramNumberOfUnits,
  'Credit' AS ProgramMeasurementUnit,
  CASE
    WHEN stat.trnsfr_earn_hrs IS NOT NULL THEN stat.trnsfr_earn_hrs
    ELSE CAST('0' AS FLOAT)
  END AS AssessedUnits,
  CASE
    WHEN prog.prog IN ('NONU', 'NONG', 'PREC', 'UPST', 'POST') THEN '1'
    WHEN prog.prog = 'NONC' THEN '8'
    WHEN prog.prog IN ('UNDG', 'UUDG', 'UUD2') THEN '36' -- UUD2 - nursing they transfer 20 units and they take 16
    WHEN (prog.prog = 'GRAD' OR prog.prog = 'GRA2' OR prog.prog = 'GRA3') AND (prog.major1='GAE' OR prog.major1='GACE' OR prog.major1='GECE') THEN '39' --education
    WHEN (prog.prog = 'GRAD' OR prog.prog = 'GRA2' OR prog.prog = 'GRA3') AND prog.major1='GCE' THEN '37'  --education
    WHEN (prog.prog = 'GRAD' OR prog.prog = 'GRA2' OR prog.prog = 'GRA3') AND prog.conc1='FNP' THEN '45'  --nursing
    WHEN (prog.prog = 'GRAD' OR prog.prog = 'GRA2' OR prog.prog = 'GRA3') AND prog.conc1='GNSE' THEN '44'  --nursing    prog.conc1=''
    WHEN (prog.prog = 'GRAD' OR prog.prog = 'GRA2' OR prog.prog = 'GRA3') AND (prog.conc1 IS NULL OR prog.conc1='') AND prog.major1='GNR' THEN '44'  --nursing undeclared concentration - they will declare
    WHEN (prog.prog = 'GRAD' OR prog.prog = 'GRA2' OR prog.prog = 'GRA3') AND prog.major1='GMI' THEN '34'  -- microbiology
    WHEN (prog.prog = 'GRAD' OR prog.prog = 'GRA2' OR prog.prog = 'GRA3') AND (prog.major1='GFIN' OR prog.major1='GMKT' OR prog.major1='GMGM') THEN '33'  -- business
    WHEN (prog.prog = 'GRAD' OR prog.prog = 'GRA2' OR prog.prog = 'GRA3') AND prog.deg='MS' AND prog.major1='GPA' THEN '36'  -- PA
    --WHEN prog.prog = 'EMBA' THEN ''
    WHEN prog.prog = 'CERT' AND prog.conc1='FNP' THEN '27'
    WHEN prog.prog = 'CERT' AND prog.conc1='GNSE' THEN '10'
    WHEN prog.prog = 'CERT' AND prog.conc1 IS NULL THEN '10'  -- before a student declares concentration in nursing
    WHEN prog.prog = 'DOCT' AND prog.deg='DNP' THEN '39'
    ELSE '1'
  END AS TotalRequiredUnits,
  prog.site AS PrimaryLocation,
  CAST('00002899' AS VARCHAR(8)) AS OpeID,
  'Ground' AS Modality,
  'True' AS FaEligibleIndicator,
  'Credit' AS AcademicYearMeasurementUnit,
  CASE
    WHEN prog.prog IN ('NONU', 'NONC', 'NONG', 'PREC', 'UPST', 'POST') THEN '1'
    WHEN prog.prog IN ('UNDG', 'UUDG', 'UUD2') THEN '9'
    WHEN prog.prog IN ('GRAD', 'GRA2', 'GRA3', 'EMBA', 'CERT', 'DOCT') THEN '18'
    ELSE '1'
  END AS NumberOfUnits, 
  '40' AS NumberOfInstructionalWeeks,
  CASE
    WHEN (prog.acst = 'RENR' OR prog.acst = 'ENRF' OR prog.acst = 'ENRP') THEN 'True'
    ELSE 'False'
  END AS PrimaryProgramIndicator,
  CASE
    WHEN stat.cum_gpa IS NOT NULL THEN CAST(stat.cum_gpa AS DECIMAL(10, 2)) 
    ELSE CAST('0' AS DECIMAL(10,2))
  END AS Gpa,
  CASE
    WHEN prog.prog IN ('NONU', 'NONC', 'NONG', 'PREC', 'UPST', 'POST', 'UNDG', 'UUDG', 'UUD2') THEN CAST(2.0 AS DECIMAL(10, 1))
    WHEN prog.prog = 'UUDG' AND (major.major = 'NR' OR major.major = 'PA') THEN CAST(3.2 AS DECIMAL(10, 1))
    WHEN prog.prog IN ('GRAD', 'GRA2', 'GRA3', 'EMBA', 'CERT', 'POST', 'DOCT', 'OTD') THEN CAST(3.0 AS DECIMAL(10, 1))
  END AS RequiredGpa,
  CASE
    WHEN prog.enr_date IS NULL THEN 
      CASE
        WHEN adm.plan_enr_yr < '2013' THEN '2013-07-30'
        WHEN adm.plan_enr_sess = 'FA' AND adm.plan_enr_yr > '2013' THEN TO_CHAR(adm.plan_enr_yr) || '-08-20'
        WHEN adm.plan_enr_sess = 'SP' AND adm.plan_enr_yr > '2013' THEN TO_CHAR(adm.plan_enr_yr) || '-01-15'
        WHEN adm.plan_enr_sess = 'SU' AND adm.plan_enr_yr > '2013' THEN TO_CHAR(adm.plan_enr_yr) || '-06-01'
      END
    WHEN prog.enr_date < '7/30/2013' THEN '2013-07-30'
    ELSE TO_CHAR(prog.enr_date, '%Y-%m-%d')
  END AS ProgramStartDate,
  t.ChangeOfProgramStartDate,
  CASE
    -- when null go by adm plan sess and yr and program type
    WHEN prog.deg_grant_date IS NOT NULL THEN TO_CHAR(prog.deg_grant_date, '%Y-%m-%d')
    WHEN prog.plan_grad_sess = 'FA' AND prog.plan_grad_yr <> '0' THEN prog.plan_grad_yr || '-12-18'
    WHEN prog.plan_grad_sess = 'SP' AND prog.plan_grad_yr <> '0' THEN prog.plan_grad_yr || '-05-15'
    WHEN prog.plan_grad_sess = 'SU' AND prog.plan_grad_yr <> '0' THEN prog.plan_grad_yr || '-08-26'
    WHEN prog.plan_grad_sess = 'WI' AND prog.plan_grad_yr <> '0' THEN prog.plan_grad_yr || '-01-26'
    WHEN (prog.plan_grad_yr IS NULL OR prog.plan_grad_yr='0')
      THEN CASE
        WHEN prog.prog IN ('NONU', 'NONC', 'NONG', 'PREC', 'UPST', 'POST') THEN 
          CASE
            WHEN prog.enr_date IS NOT NULL THEN TO_CHAR(prog.enr_date + INTERVAL(1) YEAR TO YEAR, '%Y-%m-%d')-- year + 1
            WHEN prog.enr_date IS NULL THEN 
              CASE
                WHEN adm.plan_enr_sess = 'FA' THEN TO_CHAR(adm.plan_enr_yr + 1) || '-08-20'
                WHEN adm.plan_enr_sess = 'SP' THEN TO_CHAR(adm.plan_enr_yr + 1) || '-01-15'
                WHEN adm.plan_enr_sess = 'SU' THEN TO_CHAR(adm.plan_enr_yr + 1) || '-06-01'
              END
          END
        WHEN prog.prog IN ('UNDG', 'UUDG', 'UUD2') THEN 
          CASE
            WHEN prog.enr_date IS NOT NULL THEN TO_CHAR(prog.enr_date + INTERVAL(4) YEAR TO YEAR, '%Y-%m-%d')-- year + 4
            WHEN prog.enr_date IS NULL THEN 
              CASE
                WHEN adm.plan_enr_sess = 'FA' THEN TO_CHAR(adm.plan_enr_yr + 4) || '-08-20'
                WHEN adm.plan_enr_sess = 'SP' THEN TO_CHAR(adm.plan_enr_yr + 4) || '-01-15'
                WHEN adm.plan_enr_sess = 'SU' THEN TO_CHAR(adm.plan_enr_yr + 4) || '-06-01'
              END
          END
        WHEN prog.prog IN ('GRAD', 'GRA2', 'GRA3', 'EMBA', 'CERT', 'DOCT', 'OTD') THEN 
          CASE
            WHEN prog.enr_date IS NOT NULL THEN TO_CHAR(prog.enr_date + INTERVAL(2) YEAR TO YEAR, '%Y-%m-%d')-- year + 2
            WHEN prog.enr_date IS NULL THEN 
              CASE
                WHEN adm.plan_enr_sess = 'FA' THEN TO_CHAR(adm.plan_enr_yr + 2) || '-08-20'
                WHEN adm.plan_enr_sess = 'SP' THEN TO_CHAR(adm.plan_enr_yr + 2) || '-01-15'
                WHEN adm.plan_enr_sess = 'SU' THEN TO_CHAR(adm.plan_enr_yr + 2) || '-06-01'
              END
          END
        END
    ELSE NULL
  END AS AcademicCompletionDate,
  CASE
    WHEN prog.acst = 'WD' THEN TO_CHAR(prog.lv_date, '%Y-%m-%d')
    ELSE NULL
  END AS OfficialLastDateOfAttendance,  -- when they leave the college
  CASE
    WHEN prog.acst = 'WD' THEN TO_CHAR(prog.lv_date, '%Y-%m-%d')
    ELSE NULL
  END AS DateOfDetermination,
  prog.acst AS EnrollmentStatus, -- acad_stat_table has descriptions
  -- UW, OW, AW
  CASE
    WHEN prog.reason = 'AW' THEN 'AW'
    WHEN prog.reason='SC' THEN 'AW'
    ELSE NULL
  END AS EnrollmentStatusSubType,
  CASE
    WHEN stat.upd_date IS NOT NULL THEN TO_CHAR(stat.upd_date, '%Y-%m-%d') 
    ELSE TO_CHAR(CURRENT, '%Y-%m-%d')
  END AS EnrollmentStatusEffectiveDate,
  adm.enrstat AS AdmissionStatus,  --enr_stat_table has descriptions
  prog.adm_stat AS AcademicStatus,
  'FALSE' AS ManualSapEvalutationIndictator,
  '' AS SchoolName,
  '' AS NSLDSSchoolcode,
  '' AS AcceptedUnits,
  '' AS StprCurrentStatus,
  '' AS programstartDT,
  '' AS programENDDT,
  adm.enrstat
FROM id_rec AS id
JOIN prog_enr_rec AS prog ON id.id = prog.id
JOIN adm_rec AS adm ON id.id = adm.id AND prog.prog = adm.prog
JOIN major_table AS major ON prog.major1 = major.major
LEFT JOIN stu_stat_rec AS stat ON id.id = stat.id AND stat.prog = prog.prog
JOIN cw_rec AS cw ON prog.id=cw.id
JOIN stu_acad_rec AS acad ON cw.id=acad.id AND cw.sess=acad.sess AND cw.yr=acad.yr AND cw.prog=acad.prog
LEFT JOIN (
    SELECT t1.*
    FROM TempChangeOfProgramStartDate t1
    JOIN (
        SELECT id, MAX(ChangeOfProgramStartDate) AS MaxDate
        FROM TempChangeOfProgramStartDate
        GROUP BY id
    ) t2 ON t1.id = t2.id AND t1.ChangeOfProgramStartDate = t2.MaxDate
) t ON id.id = t.id;
--WHERE (prog.acst = 'RENR' OR prog.acst = 'ENRF' OR prog.acst = 'ENRP') AND (adm.enrstat IN ('AD', 'WD'));

SELECT *
FROM TempMain;

-- Drop the temporary table if it exists
DROP TABLE IF EXISTS TempMain2;

-- Create the temporary table with the desired structure
CREATE TEMP TABLE TempMain2 (
    ExternalStudentID INT,
    ExternalProgramID VARCHAR(10),
    Code VARCHAR(30),
    Description VARCHAR(50),
    ProgramType VARCHAR(30), 
    FirstProfessionalDegreeIndicator VARCHAR(10),
    College VARCHAR(6), 
    SpecialPrograms VARCHAR(5), 
    ProgramCipCode VARCHAR(20), 
    ProgramLengthMeasurementUnit VARCHAR(10), 
    ProgramNumberOfUnits VARCHAR(5),
    ProgramMeasurementUnit VARCHAR(6), 
    AssessedUnits FLOAT, 
    TotalRequiredUnits VARCHAR(5), 
    PrimaryLocation VARCHAR(10), 
    OpeID VARCHAR(8), 
    Modality VARCHAR(10),
    FaEligibleIndicator VARCHAR(10), 
    AcademicYearMeasurementUnit VARCHAR(10), 
    NumberOfUnits VARCHAR(5), 
    NumberOfInstructionalWeeks VARCHAR(5),
    PrimaryProgramIndicator VARCHAR(10), 
    Gpa DECIMAL(10, 2), 
    RequiredGpa DECIMAL(10, 2), 
    ProgramStartDate VARCHAR(10), 
    ChangeOfProgramStartDate VARCHAR(10), 
    AcademicCompletionDate CHAR(10),
    OfficialLastDateOfAttendance VARCHAR(10), 
    DateOfDetermination VARCHAR(10), 
    EnrollmentStatus VARCHAR(10), 
    EnrollmentStatusSubType VARCHAR(25), 
    EnrollmentStatusEffectiveDate VARCHAR(25), 
    AdmissionStatus VARCHAR(5), 
    AcademicStatus VARCHAR(5), 
    ManualSapEvalutationIndictator VARCHAR(50),
    SchoolName VARCHAR(50), 
    NSLDSSchoolcode VARCHAR(50), 
    AcceptedUnits VARCHAR(50), 
    StprCurrentStatus VARCHAR(50), 
    programstartDT VARCHAR(50), 
    programENDDT VARCHAR(50),
    enrstat VARCHAR(4)
);

-- Insert data into the temporary table using your query
INSERT INTO TempMain2 (ExternalStudentID, ExternalProgramID, Code, Description, ProgramType, FirstProfessionalDegreeIndicator,
                      College, SpecialPrograms, ProgramCipCode, ProgramLengthMeasurementUnit, ProgramNumberOfUnits,
                      ProgramMeasurementUnit, AssessedUnits, TotalRequiredUnits, PrimaryLocation, OpeID, Modality,
                      FaEligibleIndicator, AcademicYearMeasurementUnit, NumberOfUnits, NumberOfInstructionalWeeks,
                      PrimaryProgramIndicator, Gpa, RequiredGpa, ProgramStartDate, ChangeOfProgramStartDate, AcademicCompletionDate,
                      OfficialLastDateOfAttendance, DateOfDetermination, EnrollmentStatus, EnrollmentStatusSubType, 
                      EnrollmentStatusEffectiveDate, AdmissionStatus, AcademicStatus, ManualSapEvalutationIndictator,
                      SchoolName, NSLDSSchoolcode, AcceptedUnits, StprCurrentStatus, programstartDT, programENDDT)


SELECT ExternalStudentID, ExternalProgramID, Code, Description, ProgramType, FirstProfessionalDegreeIndicator,
       College, SpecialPrograms, ProgramCipCode, ProgramLengthMeasurementUnit, ProgramNumberOfUnits,
       ProgramMeasurementUnit, AssessedUnits, TotalRequiredUnits, PrimaryLocation, OpeID, Modality,
       FaEligibleIndicator, AcademicYearMeasurementUnit, NumberOfUnits, NumberOfInstructionalWeeks,
       PrimaryProgramIndicator, Gpa, RequiredGpa, ProgramStartDate, ChangeOfProgramStartDate, AcademicCompletionDate,
       OfficialLastDateOfAttendance, DateOfDetermination, EnrollmentStatus, EnrollmentStatusSubType, 
       EnrollmentStatusEffectiveDate, AdmissionStatus, AcademicStatus, ManualSapEvalutationIndictator,
       SchoolName, NSLDSSchoolcode, AcceptedUnits, StprCurrentStatus, programstartDT, programENDDT
FROM TempMain t
WHERE t.ExternalStudentID IN (
    SELECT ExternalStudentID
    FROM TempMain
    WHERE PrimaryProgramIndicator = 'True' OR enrstat IN ('AD', 'WD')
)
ORDER BY ExternalStudentID,
         CASE PrimaryProgramIndicator
             WHEN 'True' THEN 0
             ELSE 1
         END;
         
SELECT ExternalStudentID, ExternalProgramID, Code, Description, ProgramType, FirstProfessionalDegreeIndicator,
       College, SpecialPrograms, ProgramCipCode, ProgramLengthMeasurementUnit, ProgramNumberOfUnits,
       ProgramMeasurementUnit, AssessedUnits, TotalRequiredUnits, PrimaryLocation, OpeID, Modality,
       FaEligibleIndicator, AcademicYearMeasurementUnit, NumberOfUnits, NumberOfInstructionalWeeks,
       'True' AS PrimaryProgramIndicator, Gpa, RequiredGpa, ProgramStartDate, ChangeOfProgramStartDate, AcademicCompletionDate,
       OfficialLastDateOfAttendance, DateOfDetermination, EnrollmentStatus, EnrollmentStatusSubType, 
       EnrollmentStatusEffectiveDate, AdmissionStatus, AcademicStatus, ManualSapEvalutationIndictator,
       SchoolName, NSLDSSchoolcode, AcceptedUnits, StprCurrentStatus, programstartDT, programENDDT
FROM TempMain2 as tm2;