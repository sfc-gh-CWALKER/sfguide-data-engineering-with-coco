-- =====================================================================
-- Part 2 data: synthetic resident contacts for A2 (classification sweep)
--
-- 1. Set MY_INITIALS to the same initials you used in scripts/setup.sql.
-- 2. Run all.
--
-- Creates DEMO_DB.TPCH_<YOUR_INITIALS>.RESIDENT_CONTACTS: 40 made-up
-- residents with names, emails, phones, birth dates, income, IP addresses
-- and free-text service notes. None of it is real.
-- Kept out of the dbt project so Part 1 builds exactly what the guide builds.
-- =====================================================================

SET MY_INITIALS = 'XX';

USE ROLE DEMO_ROLE;
USE WAREHOUSE DEMO_WH;
-- Stops with an error if MY_INITIALS is still XX
EXECUTE IMMEDIATE $$
DECLARE
  bad_initials EXCEPTION (-20001, 'Set MY_INITIALS at the top of part2/resident_contacts.sql to the initials you used in scripts/setup.sql, then run the script again.');
  initials VARCHAR DEFAULT UPPER(TRIM($MY_INITIALS));
BEGIN
  IF (initials = 'XX' OR NOT REGEXP_LIKE(initials, '[A-Z]{2,4}')) THEN
    RAISE bad_initials;
  END IF;
  RETURN 'Loading into DEMO_DB.TPCH_' || initials;
END;
$$;

SET MY_SCHEMA = 'DEMO_DB.TPCH_' || UPPER(TRIM($MY_INITIALS));
USE SCHEMA IDENTIFIER($MY_SCHEMA);

CREATE OR REPLACE TABLE RESIDENT_CONTACTS (
  RESIDENT_ID VARCHAR,
  FIRST_NAME VARCHAR,
  LAST_NAME VARCHAR,
  EMAIL VARCHAR,
  PHONE VARCHAR,
  DATE_OF_BIRTH DATE,
  STREET_ADDRESS VARCHAR,
  CITY VARCHAR,
  STATE VARCHAR,
  ZIP VARCHAR,
  EMERGENCY_CONTACT_NAME VARCHAR,
  EMERGENCY_CONTACT_PHONE VARCHAR,
  MONTHLY_INCOME NUMBER(10,0),
  LAST_LOGIN_IP VARCHAR,
  SERVICE_NOTES VARCHAR
);

INSERT INTO RESIDENT_CONTACTS VALUES
  ('R00001', 'Mateo', 'Martinez', 'mateo.martinez1@example.com', '(555) 956-7499', '1955-01-08'::DATE, '4854 Desert Sage Ave', 'Charlotte', 'NC', '28264', 'Aisha Hernandez', '(555) 658-5129', 14500, '10.227.59.153', 'Prefers text over phone calls.'),
  ('R00002', 'Ravi', 'Moore', 'ravi.moore2@example.com', '(555) 982-2649', '1994-01-31'::DATE, '7555 Cedar Ridge Ln', 'Orlando', 'FL', '32832', 'Mateo Johnson', '(555) 255-6597', 10700, '10.63.37.179', 'Reported a medical condition; keep HVAC calls priority.'),
  ('R00003', 'Ravi', 'Johnson', 'ravi.johnson3@example.com', '(555) 662-5769', '1983-11-06'::DATE, '1815 Oak Hollow Dr', 'Nashville', 'TN', '37272', 'Jordan Kim', '(555) 337-5345', 16900, '10.107.215.135', 'Prefers text over phone calls.'),
  ('R00004', 'Maria', 'Ahmed', 'maria.ahmed4@example.com', '(555) 700-2613', '1991-01-30'::DATE, '6570 Magnolia Ct', 'Dallas', 'TX', '75279', 'Hannah Wilson', '(555) 346-2573', 17900, '10.221.224.99', 'Prefers text over phone calls.'),
  ('R00005', 'Kwame', 'Ahmed', 'kwame.ahmed5@example.com', '(555) 512-1038', '1999-07-11'::DATE, '2665 Desert Sage Ave', 'Charlotte', 'NC', '28248', 'Ravi Johnson', '(555) 661-2040', 5700, '10.81.245.11', 'Requested ADA-accessible entry ramp.'),
  ('R00006', 'Aisha', 'Ahmed', 'aisha.ahmed6@example.com', '(555) 466-4468', '1971-11-12'::DATE, '4736 Cedar Ridge Ln', 'Nashville', 'TN', '37287', 'Chloe Garcia', '(555) 378-9326', 10300, '10.80.82.218', 'Asked about payment plan options in March.'),
  ('R00007', 'Mateo', 'Taylor', 'mateo.taylor7@example.com', '(555) 973-8935', '1997-12-28'::DATE, '9062 Oak Hollow Dr', 'Nashville', 'TN', '37241', 'Aisha Brown', '(555) 638-2716', 14000, '10.128.169.232', 'Works night shifts; schedule visits after 2 PM.'),
  ('R00008', 'Jordan', 'Hernandez', 'jordan.hernandez8@example.com', '(555) 623-6696', '1966-09-17'::DATE, '7750 Oak Hollow Dr', 'Las Vegas', 'NV', '89183', 'Daniel Davis', '(555) 715-8752', 15300, '10.202.147.122', 'Spanish-speaking household; send notices in Spanish.'),
  ('R00009', 'Jordan', 'Ahmed', 'jordan.ahmed9@example.com', '(555) 968-4688', '1972-12-20'::DATE, '161 Magnolia Ct', 'Phoenix', 'AZ', '85096', 'James Brown', '(555) 630-8611', 18400, '10.216.4.82', 'Works night shifts; schedule visits after 2 PM.'),
  ('R00010', 'Maria', 'Chen', 'maria.chen10@example.com', '(555) 502-4370', '1968-07-15'::DATE, '2529 Palm Harbor Blvd', 'Orlando', 'FL', '32813', 'Lucas Taylor', '(555) 235-2328', 8800, '10.218.137.51', 'Requested ADA-accessible entry ramp.'),
  ('R00011', 'Maria', 'Singh', 'maria.singh11@example.com', '(555) 319-1338', '1985-10-15'::DATE, '9887 Palm Harbor Blvd', 'Las Vegas', 'NV', '89140', 'Ethan Singh', '(555) 780-1820', 4700, '10.43.150.158', 'Allergic to pest-control chemicals; use low-toxicity treatment.'),
  ('R00012', 'Carlos', 'Nguyen', 'carlos.nguyen12@example.com', '(555) 597-3128', '1977-12-05'::DATE, '9014 Palm Harbor Blvd', 'Phoenix', 'AZ', '85096', 'Ethan Okafor', '(555) 870-7506', 13800, '10.57.40.19', 'Requested ADA-accessible entry ramp.'),
  ('R00013', 'Omar', 'Ahmed', 'omar.ahmed13@example.com', '(555) 973-5545', '1992-10-04'::DATE, '8632 Oak Hollow Dr', 'Orlando', 'FL', '32867', 'Daniel Moore', '(555) 216-5595', 13800, '10.41.252.159', 'Allergic to pest-control chemicals; use low-toxicity treatment.'),
  ('R00014', 'Mei', 'Ahmed', 'mei.ahmed14@example.com', '(555) 892-4333', '1964-01-18'::DATE, '4529 Cedar Ridge Ln', 'Phoenix', 'AZ', '85047', 'Chloe Moore', '(555) 748-1299', 8300, '10.0.175.214', 'Has a service animal on file.'),
  ('R00015', 'Ethan', 'Clark', 'ethan.clark15@example.com', '(555) 409-9393', '1988-06-10'::DATE, '2224 Cedar Ridge Ln', 'Las Vegas', 'NV', '89113', 'Priya Wilson', '(555) 712-9246', 17000, '10.185.150.202', 'Has a service animal on file.'),
  ('R00016', 'Maria', 'Williams', 'maria.williams16@example.com', '(555) 433-7346', '1999-03-22'::DATE, '3025 Magnolia Ct', 'Atlanta', 'GA', '30375', 'Omar Kim', '(555) 780-4566', 8800, '10.227.1.211', 'Requested ADA-accessible entry ramp.'),
  ('R00017', 'Grace', 'Okafor', 'grace.okafor17@example.com', '(555) 338-7007', '1995-02-04'::DATE, '1155 Desert Sage Ave', 'Phoenix', 'AZ', '85031', 'Priya Garcia', '(555) 425-3721', 17700, '10.149.136.1', 'Spanish-speaking household; send notices in Spanish.'),
  ('R00018', 'Aisha', 'Davis', 'aisha.davis18@example.com', '(555) 902-3004', '1989-08-30'::DATE, '3865 Desert Sage Ave', 'Phoenix', 'AZ', '85077', 'Omar Chen', '(555) 510-6826', 12000, '10.158.169.82', 'Allergic to pest-control chemicals; use low-toxicity treatment.'),
  ('R00019', 'Priya', 'Davis', 'priya.davis19@example.com', '(555) 720-6923', '1980-02-14'::DATE, '3206 Palm Harbor Blvd', 'Dallas', 'TX', '75225', 'Ravi Johnson', '(555) 968-8568', 16600, '10.178.58.80', 'Requested ADA-accessible entry ramp.'),
  ('R00020', 'Priya', 'Garcia', 'priya.garcia20@example.com', '(555) 415-8296', '1970-11-01'::DATE, '1716 Desert Sage Ave', 'Phoenix', 'AZ', '85095', 'Ravi Moore', '(555) 765-6818', 14400, '10.245.195.109', 'Has a service animal on file.'),
  ('R00021', 'Ethan', 'Taylor', 'ethan.taylor21@example.com', '(555) 228-6128', '2000-05-02'::DATE, '998 Palm Harbor Blvd', 'Nashville', 'TN', '37264', 'Jordan Kim', '(555) 211-4090', 15900, '10.139.27.90', 'Allergic to pest-control chemicals; use low-toxicity treatment.'),
  ('R00022', 'Ravi', 'Davis', 'ravi.davis22@example.com', '(555) 430-3459', '1972-07-16'::DATE, '6899 Palm Harbor Blvd', 'Dallas', 'TX', '75223', 'Sofia Clark', '(555) 580-7003', 15700, '10.79.170.13', 'Spanish-speaking household; send notices in Spanish.'),
  ('R00023', 'Ravi', 'Davis', 'ravi.davis23@example.com', '(555) 304-5532', '1963-09-03'::DATE, '2542 Desert Sage Ave', 'Orlando', 'FL', '32842', 'Daniel Kim', '(555) 280-5244', 8000, '10.231.111.41', 'Has a service animal on file.'),
  ('R00024', 'James', 'Garcia', 'james.garcia24@example.com', '(555) 902-6279', '1958-01-24'::DATE, '6501 Magnolia Ct', 'Las Vegas', 'NV', '89150', 'James Nguyen', '(555) 917-7507', 11500, '10.14.86.9', 'Asked about payment plan options in March.'),
  ('R00025', 'Chloe', 'Clark', 'chloe.clark25@example.com', '(555) 983-4472', '1988-04-01'::DATE, '7617 Palm Harbor Blvd', 'Dallas', 'TX', '75249', 'Ethan Rodriguez', '(555) 203-8151', 5600, '10.238.98.117', 'Has a service animal on file.'),
  ('R00026', 'Omar', 'Hernandez', 'omar.hernandez26@example.com', '(555) 907-7806', '1964-04-13'::DATE, '7409 Magnolia Ct', 'Phoenix', 'AZ', '85070', 'Maria Martinez', '(555) 371-9738', 7900, '10.151.97.142', 'Reported a medical condition; keep HVAC calls priority.'),
  ('R00027', 'Mateo', 'Okafor', 'mateo.okafor27@example.com', '(555) 720-6681', '1959-11-06'::DATE, '464 Oak Hollow Dr', 'Charlotte', 'NC', '28245', 'Omar Brown', '(555) 313-8224', 17600, '10.126.92.1', 'Asked about payment plan options in March.'),
  ('R00028', 'Aisha', 'Taylor', 'aisha.taylor28@example.com', '(555) 382-5092', '1981-04-22'::DATE, '5086 Cedar Ridge Ln', 'Nashville', 'TN', '37243', 'Aisha Okafor', '(555) 404-1605', 16800, '10.203.58.176', 'Has a service animal on file.'),
  ('R00029', 'Sofia', 'Kim', 'sofia.kim29@example.com', '(555) 431-3218', '1983-02-25'::DATE, '3344 Cedar Ridge Ln', 'Dallas', 'TX', '75295', 'Kwame Okafor', '(555) 439-6055', 7000, '10.241.184.27', 'Reported a medical condition; keep HVAC calls priority.'),
  ('R00030', 'Aisha', 'Patel', 'aisha.patel30@example.com', '(555) 850-6456', '1979-06-25'::DATE, '7117 Cedar Ridge Ln', 'Tampa', 'FL', '33655', 'Jordan Singh', '(555) 742-7746', 11000, '10.103.35.96', 'Requested ADA-accessible entry ramp.'),
  ('R00031', 'Sofia', 'Lopez', 'sofia.lopez31@example.com', '(555) 795-4222', '1990-07-05'::DATE, '5173 Oak Hollow Dr', 'Dallas', 'TX', '75251', 'Ravi Wilson', '(555) 354-5850', 9600, '10.167.194.159', 'Spanish-speaking household; send notices in Spanish.'),
  ('R00032', 'Ethan', 'Okafor', 'ethan.okafor32@example.com', '(555) 803-3335', '1977-08-21'::DATE, '7272 Palm Harbor Blvd', 'Atlanta', 'GA', '30319', 'Priya Hernandez', '(555) 977-3586', 14600, '10.241.111.82', 'Allergic to pest-control chemicals; use low-toxicity treatment.'),
  ('R00033', 'Mei', 'Johnson', 'mei.johnson33@example.com', '(555) 347-8090', '1989-05-01'::DATE, '4901 Magnolia Ct', 'Orlando', 'FL', '32877', 'Jordan Martinez', '(555) 953-1846', 9500, '10.112.82.201', 'Has a service animal on file.'),
  ('R00034', 'Hannah', 'Kim', 'hannah.kim34@example.com', '(555) 543-7026', '1987-02-01'::DATE, '5484 Oak Hollow Dr', 'Phoenix', 'AZ', '85091', 'Emily Brown', '(555) 951-3133', 14900, '10.20.206.101', 'Allergic to pest-control chemicals; use low-toxicity treatment.'),
  ('R00035', 'Ethan', 'Rodriguez', 'ethan.rodriguez35@example.com', '(555) 962-9844', '1955-10-05'::DATE, '8206 Desert Sage Ave', 'Phoenix', 'AZ', '85062', 'Ravi Moore', '(555) 324-5087', 7400, '10.61.208.34', 'Spanish-speaking household; send notices in Spanish.'),
  ('R00036', 'Emily', 'Singh', 'emily.singh36@example.com', '(555) 532-4200', '1963-04-23'::DATE, '3806 Desert Sage Ave', 'Dallas', 'TX', '75282', 'Carlos Patel', '(555) 899-1544', 5800, '10.33.228.132', 'Allergic to pest-control chemicals; use low-toxicity treatment.'),
  ('R00037', 'Hannah', 'Nguyen', 'hannah.nguyen37@example.com', '(555) 279-5140', '1955-09-03'::DATE, '694 Cedar Ridge Ln', 'Charlotte', 'NC', '28217', 'Priya Garcia', '(555) 272-7097', 14400, '10.106.82.145', 'Requested ADA-accessible entry ramp.'),
  ('R00038', 'Maria', 'Davis', 'maria.davis38@example.com', '(555) 643-6927', '1969-06-04'::DATE, '7982 Cedar Ridge Ln', 'Orlando', 'FL', '32845', 'Fatima Williams', '(555) 615-8229', 5800, '10.230.145.38', 'Works night shifts; schedule visits after 2 PM.'),
  ('R00039', 'Kwame', 'Brown', 'kwame.brown39@example.com', '(555) 482-5334', '1979-11-25'::DATE, '1065 Oak Hollow Dr', 'Tampa', 'FL', '33668', 'Mei Martinez', '(555) 284-1640', 5500, '10.109.183.25', 'Reported a medical condition; keep HVAC calls priority.'),
  ('R00040', 'Carlos', 'Taylor', 'carlos.taylor40@example.com', '(555) 809-5776', '1971-07-02'::DATE, '3194 Palm Harbor Blvd', 'Orlando', 'FL', '32849', 'Mateo Taylor', '(555) 605-4434', 19000, '10.86.184.53', 'Asked about payment plan options in March.');

-- Check (expect 40)
SELECT COUNT(*) AS residents FROM RESIDENT_CONTACTS;
