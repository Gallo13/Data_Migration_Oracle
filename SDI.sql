SELECT 
  id.firstname AS Firstname,
  id.lastname AS LastName,
  id.middlename AS MiddleName,
  id.suffixname AS Suffix,
  id.title AS Salutation,
  id.ss_no AS SSN,
  prof.birth_date AS DOB,
  id.id AS ExternalStudentId,
  CASE
    WHEN prof.sex = 'F' THEN 'Female'
    WHEN prof.sex = 'M' THEN 'Male'
  END AS Gender,
  'Permanent Mailing' AS AddressType,
  id.addr_line1 AS AddressLine1,
  id.addr_line2 AS AddressLine2,
  id.city AS City,
  id.st AS State,
  id.zip AS PostalCode,
  ctry.usps_code AS Country,
  'Mobile' AS PhoneType,
  id.cphone AS PhoneNumber,
  'Wagner' AS EmailAddressType,
  id.email AS EmailAddress,
  prog.enr_date AS AnticipatedStartDate,
  'TRUE' AS FinancialAidRequested
FROM id_rec AS id
JOIN profile_rec AS prof ON id.id = prof.id
JOIN ctry_table AS ctry ON id.ctry = ctry.ctry
JOIN prog_enr_rec AS prog ON id.id = prog.id
WHERE prog.acst = 'RENR' OR prog.acst = 'ENRF' OR prog.acst = 'ENRP'