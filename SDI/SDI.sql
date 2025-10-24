-- Drop the temporary table if it exists
DROP TABLE IF EXISTS TempMain;

-- Create the temporary table with the desired structure
CREATE TEMP TABLE TempMain (
    Firstname VARCHAR(50),
    LastName VARCHAR(50),
    MiddleName VARCHAR(50),
    Suffix VARCHAR(10),
    Salutation VARCHAR(10),
    SSN VARCHAR(11),
    DOB VARCHAR(10),
    ExternalStudentId INT,
    Gender CHAR(6),
    AddressType VARCHAR(17),
    AddressLine1 VARCHAR(50),
    AddressLine2 VARCHAR(50),
    City VARCHAR(50),
    State CHAR(2),
    PostalCode VARCHAR(15),
    Country CHAR(2),
    PhoneType CHAR(6),
    PhoneNumber VARCHAR(20),
    EmailAddressType CHAR(6),
    EmailAddress VARCHAR(50),
    AnticipatedStartDate VARCHAR(10),
    FinancialAidRequested CHAR(4)
);

-- Insert data into the temporary table using your query
INSERT INTO TempMain (Firstname, LastName, MiddleName, Suffix, Salutation, SSN, DOB, ExternalStudentId, 
                      Gender, AddressType, AddressLine1, AddressLine2, City, State, PostalCode, Country,
                      PhoneType, PhoneNumber, EmailAddressType, EmailAddress, AnticipatedStartDate,
                      FinancialAidRequested)
SELECT DISTINCT
  CASE
    WHEN TRIM((REPLACE(id.firstname, ' ', ''))) = '' THEN NULL
    ELSE TRIM((REPLACE(id.firstname, ' ', '')))
  END AS Firstname,
  id.lastname AS LastName,
  id.middlename AS MiddleName,
  id.suffixname AS Suffix,
  id.title AS Salutation,
  CASE
    -- if the value is only spaces and dashes, then NULL
    WHEN TRIM(REPLACE(REPLACE(REPLACE(id.ss_no, ' ', ''), '-', ''), '_', '')) = '' THEN NULL
    ELSE TRIM(id.ss_no)  
  END AS SSN,
  TO_CHAR(prof.birth_date, '%Y-%m-%d') AS DOB,
  id.id AS ExternalStudentId,
  CASE
    WHEN prof.sex = 'F' THEN 'Female'
    WHEN prof.sex = 'M' THEN 'Male'
  END AS Gender,
  'Permanent Mailing' AS AddressType,
  id.addr_line1 AS AddressLine1,
  id.addr_line2 AS AddressLine2,
  id.city AS City,
  CASE
    WHEN TRIM((REPLACE(UPPER(id.st), ' ', ''))) = '' THEN NULL
    WHEN TRIM((UPPER(id.st))) = '--' THEN NULL
    ELSE UPPER(id.st)
  END AS State,
  id.zip AS PostalCode,
  ctry.usps_code AS Country,
  'Mobile' AS PhoneType,
  id.cphone AS PhoneNumber,
  'Wagner' AS EmailAddressType,
  CASE
    WHEN TRIM(id.email) IS NULL THEN NULL
    WHEN TRIM(id.email) NOT LIKE '%@%' THEN NULL
    WHEN TRIM(id.email) LIKE '%@aol' THEN TRIM(id.email) || '.com'
    WHEN TRIM(id.email) LIKE '%@hotmail' THEN TRIM(id.email) || '.com'
    WHEN TRIM(id.email) LIKE '%@gmail' THEN TRIM(id.email) || '.com'
    WHEN TRIM(id.email) LIKE '%@yahoo' THEN TRIM(id.email) || '.com'
    ELSE TRIM(id.email)
  END AS EmailAddress,
  CASE
    WHEN prog.enr_date IS NOT NULL THEN TO_CHAR(prog.enr_date, '%Y-%m-%d')
    WHEN prog.enr_date IS NULL THEN
      CASE
        WHEN adm.plan_enr_sess = 'FA' THEN plan_enr_yr || '-08-20'
        WHEN adm.plan_enr_sess = 'SP' THEN plan_enr_yr || '-01-15' 
        WHEN adm.plan_enr_sess = 'SU' THEN plan_enr_yr || '-06-01'
      END
  END AS AnticipatedStartDate,
  'TRUE' AS FinancialAidRequested
FROM id_rec AS id
-- add adm_rec students with AD stat and AW students
JOIN profile_rec AS prof ON id.id = prof.id
JOIN ctry_table AS ctry ON id.ctry = ctry.ctry
JOIN prog_enr_rec AS prog ON id.id = prog.id
JOIN adm_rec AS adm ON adm.id = id.id
WHERE (prog.acst IN ('RENR', 'ENRF', 'ENRP')); --OR ((adm.enrstat IN ('AD', 'WD')));

SELECT *
FROM TempMain
WHERE Firstname IS NOT NULL;

-- anticipatedstartdate has to be filled in
-- all states need to be capitalized