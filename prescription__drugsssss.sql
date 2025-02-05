--1. a. Which prescriber had the highest total number of claims (totaled over all drugs)? 
--Report the npi and the total number of claims. npi: 1356305197


SELECT SUM(p.total_claim_count) as total_claims, 
	b.npi, b.nppes_provider_last_org_name,
	b.nppes_provider_first_name
FROM prescription as p
INNER JOIN prescriber as b
USING (npi)
GROUP BY 	b.npi, b.nppes_provider_last_org_name,
	b.nppes_provider_first_name
ORDER BY total_claims DESC
LIMIT 1;


--b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name, 
--specialty_description, and the total number of claims.

WITH total_claims_per_npi AS 
	(SELECT SUM(total_claim_count) as total_claims, npi
	FROM prescription
	GROUP BY npi
	ORDER BY total_claims DESC)
SELECT t.total_claims, t.npi, 
	p.nppes_provider_first_name, 
	p.nppes_provider_last_org_name, 
	p.specialty_description
FROM total_claims_per_npi AS t
INNER JOIN prescriber AS p
USING (npi)
GROUP by NPI, t.total_claims, 	p.nppes_provider_first_name, 
	p.nppes_provider_last_org_name, 
	p.specialty_description
ORDER by total_claims DESC;

--hostess with the mostest
WITH mad_prescriber_deets AS 
(WITH total_claims_per_npi AS 
	(SELECT SUM(total_claim_count) as total_claims, npi
	FROM prescription
	GROUP BY npi
	ORDER BY total_claims DESC)
SELECT t.total_claims AS claim_count, t.npi AS npi,
	p.nppes_provider_first_name AS first_name,
	p.nppes_provider_last_org_name AS last_name, 
	p.specialty_description AS speciality
FROM total_claims_per_npi AS t
INNER JOIN prescriber AS P
USING (npi)
GROUP by NPI, t.total_claims, 	p.nppes_provider_first_name, 
	p.nppes_provider_last_org_name, 
	p.specialty_description
ORDER by total_claims DESC)
SELECT npi, claim_count, first_name, last_name, speciality
FROM mad_prescriber_deets
ORDER BY claim_count DESC 
LIMIT 1;

--2. partay with the mostest: INTERNAL MEDICINE

WITH mad_prescriber_deets AS 
(WITH total_claims_per_npi AS 
	(SELECT SUM(total_claim_count) as total_claims, npi
	FROM prescription
	GROUP BY npi
	ORDER BY total_claims DESC)
SELECT t.total_claims AS claim_count, t.npi AS npi,
	p.nppes_provider_first_name AS first_name,
	p.nppes_provider_last_org_name AS last_name, 
	p.specialty_description AS speciality
FROM total_claims_per_npi AS t
INNER JOIN prescriber AS P
USING (npi)
GROUP by NPI, t.total_claims, 	p.nppes_provider_first_name, 
	p.nppes_provider_last_org_name, 
	p.specialty_description
ORDER by total_claims DESC)
SELECT speciality, claim_count
FROM mad_prescriber_deets
ORDER BY claim_count DESC
LIMIT 1;

--2b: party with the mostest opioids: which speciality has the most claims for opioids?
--NURSE PRACTITIONERS 


WITH prescribed_opioids 
	AS 
	(SELECT p.npi, p.drug_name, d.opioid_drug_flag AS opioid, 
		s.specialty_description AS specialty
	FROM prescription as p
	INNER JOIN drug AS d
	USING (drug_name) 
	INNER JOIN prescriber AS s
	ON p.npi = s.npi
	WHERE d.opioid_drug_flag = 'Y')

SELECT COUNT(opioid) as kickback_kings, specialty
FROM prescribed_opioids
GROUP BY specialty
ORDER BY kickback_kings DESC
LIMIT 1;

--3a. Which drug (generic_name) had the highest total drug cost? Pirfernidone

SELECT d.generic_name, p.total_drug_cost
FROM drug AS d
INNER JOIN prescription AS p
USING(drug_name)
ORDER BY p.total_drug_cost DESC
LIMIT 1;


-- b. Which drug (generic_name) has the hightest total cost per day? 
-- Bonus: Round your cost per day column to 2 decimal places. 
-- Google ROUND to see how this works.
--ANSWER: IMMUN GLOB, $7141.11 per day
--first, finding total drug cost 
SELECT d.generic_name, p.total_drug_cost
FROM drug AS d
INNER JOIN prescription AS p
USING(drug_name)
ORDER BY p.total_drug_cost DESC
LIMIT 1;

--dividing total cost by day supply and rounding: 
SELECT d.generic_name, ROUND(p.total_drug_cost / p.total_day_supply, 2) AS total_cost_per_day
FROM drug AS d
INNER JOIN prescription AS p
USING(drug_name)
ORDER BY total_cost_per_day DESC
LIMIT 1;

--4. a. For each drug in the drug table, return the drug name and 
--then a column named 'drug_type' which says 'opioid' for drugs
--which have opioid_drug_flag = 'Y', says 'antibiotic' for those 
--drugs which have antibiotic_drug_flag = 'Y', and says 'neither'
--for all other drugs. Hint: You may want to use a CASE expression for this.


SELECT drug_name, 
	CASE
		  WHEN opioid_drug_flag = 'Y' THEN 'Y' 
		  WHEN antibiotic_drug_flag = 'Y' THEN 'Y'
		  ELSE 'neither'
		END AS drug_type
from drug
order by drug_type DESC;

-- b. Building off of the query you wrote for part a, 
-- determine whether more was spent (total_drug_cost) 
-- on opioids or on antibiotics. 
-- Hint: Format the total costs as 
-- MONEY for easier comparision.


WITH cost_comparison AS
(
WITH aandocost AS 
			(
	SELECT d.drug_name, 
		CASE
			  WHEN d.opioid_drug_flag = 'Y' THEN 'O' 
			  WHEN d.antibiotic_drug_flag = 'Y' THEN 'A'
			  ELSE NULL
			END AS drug_type, 
		sum(p.total_drug_cost) AS total_cost
	from drug as d
	inner join prescription as p
	USING (drug_name)
	GROUP BY  drug_type, d.drug_name
	ORDER BY drug_type, sum(p.total_drug_cost)
			)

SELECT sum(total_cost) AS spending, drug_type
FROM aandocost
WHERE drug_type = 'O' OR drug_type = 'A'
GROUP BY total_cost, drug_type)
SELECT sum(spending), drug_type
FROM cost_comparison
GROUP BY drug_type;


-- 5. a. How many CBSAs are in Tennessee? 
--Warning: The cbsa table contains information 
--for all states, not just Tennessee. 33

SELECT COUNT(*)
from cbsa
WHERE cbsaname ILIKE '%TN';
-- b. Which cbsa has the largest combined population? 
--Which has the smallest? Report the CBSA name and 
--total population.

SELECT c.cbsa, p.fipscounty, p.population, f.county
FROM cbsa AS c
INNER JOIN population AS p
USING (fipscounty)
INNER JOIN fips_county AS f
USING (fipscounty)
WHERE cbsaname ILIKE '%TN'
ORDER BY p.population DESC;
--step 2
SELECT c.cbsa, c.cbsaname,
		SUM(p.population)
FROM cbsa AS c
INNER JOIN population AS p
USING (fipscounty)
WHERE cbsaname ILIKE '%TN' 
GROUP BY c.cbsa, c.cbsaname
ORDER BY sum(p.population)DESC;



-- c. What is the largest (in terms of population) 
--county which is not included in a CBSA? 
--Report the county name and population.  SEVIER -  95,532

WITH tn_counties 
	AS 
	(
	SELECT f.county AS county, f.fipscounty AS cbsacounty, c.cbsa AS cbsa
	from fips_county as f
	FULL JOIN cbsa as c
	USING (fipscounty)
	WHERE f.state = 'TN'
	)
SELECT tn.county, 
	tn.cbsacounty, 
	tn.cbsa,
	p.population 
FROM tn_counties AS tn
INNER JOIN population as p
ON tn.cbsacounty = p.fipscounty
WHERE tn.cbsa IS NULL
ORDER By p.population DESC
LIMIT 1;




--6a. Find all rows in the prescription table where 
-- total_claims is at least 3000. Report the drug_name 
-- and the total_claim_count.


SELECT drug_name, total_claim_count
FROM prescription
WHERE total_claim_count >= 3000


-- b. For each instance that you found in part a,
-- add a column that indicates whether the drug
-- is an opioid.

WITH high_claim_count AS 
		(
		SELECT drug_name, total_claim_count
		FROM prescription
		WHERE total_claim_count >= 3000
		)
SELECT h.drug_name, 
	h.total_claim_count, 
	d.opioid_drug_flag
FROM high_claim_count AS h
INNER JOIN drug AS d
USING (drug_name);

-- c. Add another column to you answer from 
-- the previous part which gives the prescriber
-- first and last name associated with each row.

WITH high_claim_count AS 
			(
			SELECT npi, drug_name, total_claim_count
			FROM prescription
			WHERE total_claim_count >= 3000
			)
	SELECT h.npi, h.drug_name, 
		h.total_claim_count, 
		d.opioid_drug_flag, 
		p.nppes_provider_last_org_name,
		p.nppes_provider_first_name
		FROM high_claim_count AS h
	INNER JOIN drug AS d
	USING (drug_name)
	INNER JOIN prescriber AS p
	USING (npi)
	


-- 7. The goal of this exercise is to generate a full list of 
--all pain management specialists in Nashville and the number of 
--claims they had for each opioid. Hint: The results from all 3 parts
--will have 637 rows.

-- a. First, create a list of all npi/drug_name combinations for 
--pain management specialists (specialty_description = 'Pain Management) 
--in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug 
--is an opioid (opiod_drug_flag = 'Y'). Warning: Double-check your query before
--running it. You will only need to use the prescriber and drug tables since 
--you don't need the claims numbers yet.


SELECT d.drug_name,
	p.npi,
	p.nppes_provider_first_name, 
	p.nppes_provider_last_org_name
FROM drug AS d
CROSS JOIN prescriber as p
WHERE d.opioid_drug_flag = 'Y' 
	AND nppes_provider_city LIKE '%NASHVILLE%' 
	AND specialty_description LIKE '%Pain Management%';




-- b. Next, report the number of claims per drug per prescriber. 
--Be sure to include all combinations, whether or not the prescriber had any claims. 
--You should report the npi, the drug name, and the number of claims 
--(total_claim_count).


WITH all_possible_combos 
	AS 
	(

	SELECT d.drug_name AS drug,
		p.npi AS npi,
		p.nppes_provider_first_name AS first_name,
		p.nppes_provider_last_org_name AS last_name
	FROM drug AS d
	CROSS JOIN prescriber as p
	WHERE d.opioid_drug_flag = 'Y' 
		AND nppes_provider_city LIKE '%NASHVILLE%' 
		AND specialty_description LIKE '%Pain Management%'
	)
SELECT a.drug, a.npi, a.first_name, a.last_name, 
	SUM(p.total_claim_count) AS total_claims
FROM all_possible_combos AS a
INNER JOIN prescription AS p
ON a.npi = p.npi
GROUP BY a.drug, a.npi, a.first_name, a.last_name


-- c. Finally, if you have not done so already, 
--fill in any missing values for total_claim_count with 0. 
--Hint - Google the COALESCE function.

	

WITH all_possible_combos 
	AS 
	(

	SELECT d.drug_name AS drug,
		p.npi AS npi,
		p.nppes_provider_first_name AS first_name,
		p.nppes_provider_last_org_name AS last_name
	FROM drug AS d
	CROSS JOIN prescriber as p
	WHERE d.opioid_drug_flag = 'Y' 
		AND nppes_provider_city = 'NASHVILLE' 
		AND specialty_description = 'Pain Management'
	)
SELECT a.drug, a.npi, a.first_name, a.last_name, 
	SUM(p.total_claim_count) AS total_claims
FROM all_possible_combos AS a
INNER JOIN prescription AS p
ON a.npi = p.npi
GROUP BY a.drug, a.npi, a.first_name, a.last_name
ORDER BY total_claims DESC; 

	
