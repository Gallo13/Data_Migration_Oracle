-- Drop the temporary table if it exists
DROP TABLE IF EXISTS TempChangeOfProgramStartDate;

-- Create the temporary table with the desired structure
CREATE TEMP TABLE TempChangeOfProgramStartDate (
    id INT,
    ChangeOfProgramStartDate VARCHAR(10),
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
    AND (prog.acst = 'RENR' OR prog.acst = 'ENRF' OR prog.acst = 'ENRP')
ORDER BY 
    curr.yr DESC, 
    CASE curr.sess 
        WHEN 'SP' THEN 1
        WHEN 'SU' THEN 2
        WHEN 'FA' THEN 3
    END DESC;  -- Order by year and session


-- Main Query
SELECT DISTINCT
  id.id AS ExternalStudentID,
  major.major AS ExternalProgramID,
   CASE
    WHEN prog.prog = 'NONU' THEN 'Non-credential' || 'Gound'
    WHEN prog.prog = 'NONC' THEN 'Non-credential' || 'Gound'
    WHEN prog.prog = 'NONG' THEN 'Non-credential' || 'Gound'
    WHEN prog.prog = 'PREC' THEN 'Non-credential' || 'Gound'
    WHEN prog.prog = 'UPST' THEN 'Non-credential' || 'Gound'
    WHEN prog.prog = 'POST' THEN 'Non-credential' || 'Gound'
    WHEN prog.prog = 'UUDG' THEN 'Bachelors' || 'Gound'
    WHEN prog.prog = 'UUD2' THEN 'Bachelors' || 'Gound'
    WHEN prog.prog = 'GRAD' THEN 'Graduate' || 'Gound'
    WHEN prog.prog = 'GRA2' THEN 'Graduate' || 'Gound'
    WHEN prog.prog = 'GRA3' THEN 'Graduate' || 'Gound'
    WHEN prog.prog = 'EMBA' THEN 'Graduate' || 'Gound'
    WHEN prog.prog = 'CERT' THEN 'Certificate (Graduate)' || 'Gound'
    WHEN prog.prog = 'DOCT' THEN 'Doctoral' || 'Gound'
  END AS Code,
  major.txt AS Description,
  CASE
    WHEN prog.prog = 'NONU' THEN 'Non-credential'
    WHEN prog.prog = 'NONC' THEN 'Non-credential'
    WHEN prog.prog = 'NONG' THEN 'Non-credential'
    WHEN prog.prog = 'PREC' THEN 'Non-credential'
    WHEN prog.prog = 'UPST' THEN 'Non-credential'
    WHEN prog.prog = 'POST' THEN 'Non-credential'
    WHEN prog.prog = 'UUDG' THEN 'Bachelors'
    WHEN prog.prog = 'UUD2' THEN 'Bachelors'
    WHEN prog.prog = 'GRAD' THEN 'Graduate'
    WHEN prog.prog = 'GRA2' THEN 'Graduate'
    WHEN prog.prog = 'GRA3' THEN 'Graduate'
    WHEN prog.prog = 'EMBA' THEN 'Graduate'
    WHEN prog.prog = 'CERT' THEN 'Certificate (Graduate)'
    WHEN prog.prog = 'DOCT' THEN 'Doctoral'    
  END AS ProgramType,
  CASE
    WHEN prog.prog = 'UUD2' THEN 'TRUE'
    WHEN prog.prog = 'GRA2' THEN 'TRUE'
    WHEN prog.prog = 'GRA3' THEN 'TRUE'
    ELSE 'FALSE' 
  END AS FirstProfessionalDegreeIndicator,
  'Wagner' AS College,
  -- need to check for special programs
  'N' AS SpecialPrograms,
  major.cip_no AS ProgramCipCode,
  'years' AS ProgramLengthMeasurementUnit,
  CASE
    WHEN prog.prog = 'NONU' THEN '0'
    WHEN prog.prog = 'NONC' THEN '2'
    WHEN prog.prog = 'NONG' THEN '0'
    WHEN prog.prog = 'PREC' THEN '0'
    WHEN prog.prog = 'UPST' THEN '0'
    WHEN prog.prog = 'POST' THEN '0'
    WHEN prog.prog = 'UUDG' THEN '4'
    WHEN prog.prog = 'UUD2' THEN '4'
    WHEN prog.prog = 'GRAD' THEN '2'
    WHEN prog.prog = 'GRA2' THEN '2'
    WHEN prog.prog = 'GRA3' THEN '2'
    WHEN prog.prog = 'EMBA' THEN '2'
    WHEN prog.prog = 'CERT' THEN '2'
    WHEN prog.prog = 'DOCT' THEN '2'
  END AS NumberOfUnits,
  'credit' AS ProgramMeasurementUnit,
  stat.trnsfr_earn_hrs AS AssessedUnits,
  CASE
    WHEN prog.prog = 'NONU' THEN '0'
    WHEN prog.prog = 'NONC' THEN '8'
    WHEN prog.prog = 'NONG' THEN '0'
    WHEN prog.prog = 'PREC' THEN '0'
    WHEN prog.prog = 'UPST' THEN '0'
    WHEN prog.prog = 'POST' THEN '0'
    WHEN prog.prog = 'UUDG' THEN '36'
    WHEN prog.prog = 'UUD2' THEN '36' -- nursing they transfer 20 units and they take 16
    WHEN (prog.prog = 'GRAD' OR prog.prog = 'GRA2' OR prog.prog = 'GRA3') AND (prog.major1='GAE' OR prog.major1='GACE' OR prog.major1='GECE') THEN '39' --education
    WHEN (prog.prog = 'GRAD' OR prog.prog = 'GRA2' OR prog.prog = 'GRA3') AND prog.major1='GCE' THEN '37'  --education
    WHEN (prog.prog = 'GRAD' OR prog.prog = 'GRA2' OR prog.prog = 'GRA3') AND prog.conc1='FNP' THEN '45'  --nursing
    WHEN (prog.prog = 'GRAD' OR prog.prog = 'GRA2' OR prog.prog = 'GRA3') AND prog.conc1='GNSE'THEN '44'  --nursing    prog.conc1=''
    WHEN (prog.prog = 'GRAD' OR prog.prog = 'GRA2' OR prog.prog = 'GRA3') AND prog.conc1='' THEN '0'  --nursing undeclared concentration - they will declare
    WHEN (prog.prog = 'GRAD' OR prog.prog = 'GRA2' OR prog.prog = 'GRA3') AND prog.major1='GMI' THEN '34'  -- microbiology
    WHEN (prog.prog = 'GRAD' OR prog.prog = 'GRA2' OR prog.prog = 'GRA3') AND prog.deg='MBA'THEN '33'  -- business
    WHEN (prog.prog = 'GRAD' OR prog.prog = 'GRA2' OR prog.prog = 'GRA3') AND prog.deg='MS' AND prog.major1='GPA' THEN '36'  -- PA
    --WHEN prog.prog = 'EMBA' THEN ''
    WHEN prog.prog = 'CERT' AND prog.conc1='FNP' THEN '27'
    WHEN prog.prog = 'CERT' AND prog.conc1='GNSE' THEN '10'
    WHEN prog.prog = 'CERT' AND prog.conc1='' THEN '0'  -- before a student declares concentration in nursing
    WHEN prog.prog = 'DOCT' AND prog.deg='DNP' THEN '39'
  END AS TotalRequiredUnits,
  prog.site AS PrimaryLocation,
  CAST('00002899' AS VARCHAR(8)) AS OpeID,
  'Ground' AS Modality,
  'True' AS FaEligibleIndicator,
  'credit' AS AcademicYearMeasurementUnit,
  CASE
    WHEN prog.prog = 'NONU' THEN '0'
    WHEN prog.prog = 'NONC' THEN '0'
    WHEN prog.prog = 'NONG' THEN '0'
    WHEN prog.prog = 'PREC' THEN '0'
    WHEN prog.prog = 'UPST' THEN '0'
    WHEN prog.prog = 'POST' THEN '0'
    WHEN prog.prog = 'UUDG' THEN '9'
    WHEN prog.prog = 'UUD2' THEN '9'
    WHEN prog.prog = 'GRAD' THEN '18'
    WHEN prog.prog = 'GRA2' THEN '18'
    WHEN prog.prog = 'GRA3' THEN '18'
    WHEN prog.prog = 'EMBA' THEN '18'
    WHEN prog.prog = 'CERT' THEN '18'
    WHEN prog.prog = 'DOCT' THEN '18' 
  END AS NumberOfUnits,
  '40' AS NumberOfInstructionalWeeks,
  CASE
    WHEN (prog.acst = 'RENR' OR prog.acst = 'ENRF' OR prog.acst = 'ENRP') THEN 'True'
    ELSE 'False'
  END AS PrimaryProgramIndicator,
  CAST(stat.cum_gpa AS DECIMAL(10, 2)) AS Gpa,
  CASE
    WHEN prog.prog = 'NONU' THEN CAST(2.0 AS DECIMAL(10, 1))
    WHEN prog.prog = 'NONC' THEN CAST(2.0 AS DECIMAL(10, 1))
    WHEN prog.prog = 'NONG' THEN CAST(2.0 AS DECIMAL(10, 1))
    WHEN prog.prog = 'PREC' THEN CAST(2.0 AS DECIMAL(10, 1))
    WHEN prog.prog = 'UPST' THEN CAST(2.0 AS DECIMAL(10, 1))
    WHEN prog.prog = 'POST' THEN CAST(2.0 AS DECIMAL(10, 1))
    WHEN prog.prog = 'UUDG' THEN CAST(2.0 AS DECIMAL(10, 1))
    WHEN prog.prog = 'UUDG' AND (major.major = 'NR' OR major.major = 'PA') THEN CAST(3.2 AS DECIMAL(10, 1))
    WHEN prog.prog = 'UUD2' THEN CAST(2.0 AS DECIMAL(10, 1))
    WHEN prog.prog = 'GRAD' THEN CAST(3.0 AS DECIMAL(10, 1))
    WHEN prog.prog = 'GRA2' THEN CAST(3.0 AS DECIMAL(10, 1))
    WHEN prog.prog = 'GRA3' THEN CAST(3.0 AS DECIMAL(10, 1))
    WHEN prog.prog = 'EMBA' THEN CAST(3.0 AS DECIMAL(10, 1))
    WHEN prog.prog = 'CERT' THEN CAST(3.0 AS DECIMAL(10, 1))
    WHEN prog.prog = 'DOCT' THEN CAST(3.0 AS DECIMAL(10, 1))
  END AS RequiredGpa,
  TO_CHAR(prog.enr_date, '%Y-%m-%d') AS ProgramStartDate,
  t.ChangeOfProgramStartDate,
  CASE
    WHEN prog.plan_grad_sess = 'FA' THEN prog.plan_grad_yr || '-12-18'
    WHEN prog.plan_grad_sess = 'SP' THEN prog.plan_grad_yr || '-05-15'
    WHEN prog.plan_grad_sess = 'SU' THEN prog.plan_grad_yr || '-08-26'
  END AS AcademicCompletionDate,
  CASE
    WHEN prog.acst = 'WD' THEN TO_CHAR(prog.lv_date, '%Y-%m-%d')
    ELSE NULL
  END AS OfficialLastDateOfAttendence,  -- when they leave the college
  CASE
    WHEN prog.acst = 'WD' THEN TO_CHAR(prog.lv_date, '%Y-%m-%d')
    ELSE NULL
  END AS DateOfDetermination,
  'F' AS EnrollmentStatus,
  -- UW, OW, AW
  CASE
    WHEN prog.reason = 'AW' THEN 'AW'
    WHEN prog.reason='SC' THEN 'AW'
    ELSE NULL
  END AS EnrollmentStatusSubType,
  TO_CHAR(stat.upd_date, '%Y-%m-%d') AS EnrollmentStatusEffectiveData,
  'Am' AS AdmissionStatus,
  'RG' AS AcademicStatus,
  'FALSE' AS ManualSapEvalutationIndictator,
  '' AS ReturnToTitleIvSafiIndicator
FROM id_rec AS id
JOIN prog_enr_rec AS prog ON id.id = prog.id
JOIN major_table AS major ON prog.major1 = major.major
JOIN stu_stat_rec AS stat ON id.id = stat.id AND stat.prog = prog.prog
LEFT JOIN (
    SELECT t1.*
    FROM TempChangeOfProgramStartDate t1
    JOIN (
        SELECT id, MAX(ChangeOfProgramStartDate) AS MaxDate
        FROM TempChangeOfProgramStartDate
        GROUP BY id
    ) t2 ON t1.id = t2.id AND t1.ChangeOfProgramStartDate = t2.MaxDate
) AS t ON id.id = t.id
WHERE (prog.acst = 'RENR' OR prog.acst = 'ENRF' OR prog.acst = 'ENRP') --AND id.id='593712'