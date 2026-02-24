
-- Creating table to import csv files for the Nashville Housing data
CREATE TABLE housingdata (
    uniqueid BIGINT,
    parcelid TEXT,
    landuse TEXT,
    propertyaddress TEXT,
    saledate DATE,
    saleprice TEXT,
    legalreference TEXT,
    soldasvacant TEXT,
    ownername TEXT,
    owneraddress TEXT,
    acreage TEXT,
    taxdistrict TEXT,
    landvalue TEXT,
    buildingvalue TEXT,
    totalvalue TEXT,
    yearbuilt TEXT,
    bedrooms TEXT,
    fullbath TEXT,
    halfbath TEXT
);

-- Cleaning Data
SELECT * FROM housingdata;

-- Populating the property address data
SELECT h1.parcelid, h1.propertyaddress, h2.parcelid, h2.propertyaddress, 
COALESCE(h1.propertyaddress, h2.propertyaddress) AS filled_address
FROM housingdata AS h1
JOIN housingdata AS h2
ON h1.parcelid = h2.parcelid
AND h1.uniqueid != h2.uniqueid
WHERE h1.propertyaddress IS NULL;

UPDATE housingdata h1
SET propertyaddress = h2.propertyaddress
FROM housingdata h2
WHERE h1.parcelid = h2.parcelid
  AND h1.uniqueid <> h2.uniqueid
  AND h1.propertyaddress IS NULL;
  
  
-- Creating individual columns for property address and city
SELECT propertyaddress, SUBSTRING(propertyaddress FROM 1 FOR POSITION(',' IN propertyaddress)-1) AS address,
SUBSTRING(propertyaddress FROM POSITION(',' IN propertyaddress)+1) AS city
FROM housingdata;
  
ALTER TABLE housingdata
ADD COLUMN address VARCHAR(250),
ADD COLUMN city VARCHAR(100);

UPDATE housingdata
SET
address = SUBSTRING(propertyaddress FROM 1 FOR POSITION(',' IN propertyaddress)-1),
city = SUBSTRING(propertyaddress FROM POSITION(',' IN propertyaddress)+1);

ALTER TABLE housingdata
RENAME COLUMN address TO property_address;

ALTER TABLE housingdata
RENAME COLUMN city TO property_city;


-- Creating individual columns for owners address, city and state
SELECT owneraddress,
TRIM(SPLIT_PART(owneraddress,',',1)),
TRIM(SPLIT_PART(owneraddress,',',2)),
TRIM(SPLIT_PART(owneraddress,',',3))
FROM housingdata

ALTER TABLE housingdata
ADD COLUMN owner_address VARCHAR(250),
ADD COLUMN owner_city VARCHAR(50),
ADD COLUMN owner_state VARCHAR(50);

UPDATE housingdata
SET
owner_address = TRIM(SPLIT_PART(owneraddress,',',1)),
owner_city = TRIM(SPLIT_PART(owneraddress,',',2)),
owner_state = TRIM(SPLIT_PART(owneraddress,',',3));


-- Changing 'Y' and 'N' to 'Yes' and 'No' in soldasvacant field
SELECT DISTINCT(soldasvacant), COUNT(soldasvacant)
FROM housingdata
GROUP BY soldasvacant
ORDER BY 2;

SELECT soldasvacant,
CASE WHEN soldasvacant = 'Y' THEN 'Yes'
	 WHEN soldasvacant = 'N' THEN 'No'
	 ELSE soldasvacant
	 END AS updated_field
FROM housingdata;
  
UPDATE housingdata
SET soldasvacant = CASE WHEN soldasvacant = 'Y' THEN 'Yes'
	 WHEN soldasvacant = 'N' THEN 'No'
	 ELSE soldasvacant
	 END;


-- Removing Duplicates
WITH row_num_CTE AS(
SELECT * ,
	ROW_NUMBER() OVER(
	PARTITION BY parcelid,
				 propertyaddress,
				 saleprice,
			   	 saledate,
				 legalreference
				 ORDER BY uniqueid) AS row_num
	FROM housingdata)
SELECT * FROM row_num_CTE 
WHERE row_num > 1;
  
WITH row_num_CTE AS(
SELECT uniqueid ,
	ROW_NUMBER() OVER(
	PARTITION BY parcelid,
				 propertyaddress,
				 saleprice,
			   	 saledate,
				 legalreference
				 ORDER BY uniqueid) AS row_num
	FROM housingdata)
DELETE FROM housingdata AS h
USING row_num_CTE AS r
WHERE h.uniqueid = r.uniqueid
AND row_num > 1;


-- Deleting Unused Columns
ALTER TABLE housingdata
DROP COLUMN propertyaddress,
DROP COLUMN owneraddress;
  




