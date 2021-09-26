--dropping columns that are either mostly empty or contain too many different data formats


ALTER TABLE coffee_data
DROP COLUMN column1

ALTER TABLE coffee_data
DROP COLUMN Unnamed_0

ALTER TABLE coffee_data
DROP COLUMN Lot_Number

ALTER TABLE coffee_data 
DROP COLUMN ICO_Number


--replacing some values in the in-country partner column for later use in tableau

UPDATE coffee_data SET In_Country_Partner = REPLACE(In_Country_Partner, 'Coffee Ass', 'Specialty Coffee Association')
UPDATE coffee_data SET In_Country_Partner = REPLACE(In_Country_Partner, 'Specialty Coffee Association o', 'Specialty Coffee Association')




--converting date type from 107 to 23


UPDATE coffee_data SET Grading_Date = CONVERT(DATE, Grading_Date, 23)
UPDATE coffee_data SET Expiration = CONVERT(DATE, Expiration, 23)


--creating a UDF that will capitalize the first letter of each word that either is at the start of a sentence or 
--comes after a special symbol or a space



IF OBJECT_ID('Capitalize_Initials') IS NOT NULL
   DROP FUNCTION Capitalize_Initials

GO   

CREATE FUNCTION [dbo].[Capitalize_Initials] ( @InputString varchar(4000) ) 
RETURNS VARCHAR(4000)
AS
BEGIN

DECLARE @Index          INT
DECLARE @Char           CHAR(1)
DECLARE @PrevChar       CHAR(1)
DECLARE @OutputString   VARCHAR(255)

SET @OutputString = LOWER(@InputString)
SET @Index = 1

WHILE @Index <= LEN(@InputString)
BEGIN
    SET @Char     = SUBSTRING(@InputString, @Index, 1)
    SET @PrevChar = CASE WHEN @Index = 1 THEN ' '
                         ELSE SUBSTRING(@InputString, @Index - 1, 1)
                    END

    IF @PrevChar IN (' ', ';', ':', '!', '?', ',', '.', '_', '-', '/', '&', '''', '(')
    BEGIN
        IF @PrevChar != '''' OR UPPER(@Char) != 'S'
            SET @OutputString = STUFF(@OutputString, @Index, 1, UPPER(@Char))
    END

    SET @Index = @Index + 1

END

RETURN @OutputString

END
GO


--using the above UDF on the columns that need it


UPDATE coffee_data
SET Owner =[dbo].[Capitalize_Initials](Owner)

UPDATE coffee_data
SET Farm_Name = [dbo].[Capitalize_Initials](Farm_Name)

UPDATE coffee_data
SET Mill = [dbo].[Capitalize_Initials](Mill)

UPDATE coffee_data
SET Company = [dbo].[Capitalize_Initials](Company)

UPDATE coffee_data
SET Region =[dbo].[Capitalize_Initials](Region)

UPDATE coffee_data
SET Producer =[dbo].[Capitalize_Initials](Producer)

UPDATE coffee_data
SET Owner_1 =[dbo].[Capitalize_Initials](Owner_1)


--take the last two characters of the entries in column Harvest_Year after stripping the of non_numeric characters 
--and then adding 2000 to the values we got because all of the years listed in the column are after 2000


UPDATE coffee_data
SET Harvest_Year =
  CASE WHEN Harvest_Year LIKE '%[0-9]%' THEN 
    CAST(RIGHT(Harvest_Year,2) AS SMALLINT) + 2000
  ELSE
    NULL
  END




--creating a udf that extracts and concatenates numerical values from a string


GO
CREATE FUNCTION dbo.Numeric
(
  @strAlphaNumeric VARCHAR(256)
)
RETURNS VARCHAR(256)
AS
BEGIN
  DECLARE @intAlpha INT
  SET @intAlpha = PATINDEX('%[^0-9]%', @strAlphaNumeric)
  BEGIN
    WHILE @intAlpha > 0
    BEGIN
      SET @strAlphaNumeric = STUFF(@strAlphaNumeric, @intAlpha, 1, '' )
      SET @intAlpha = PATINDEX('%[^0-9]%', @strAlphaNumeric )
    END
  END
  RETURN ISNULL(@strAlphaNumeric,0)
END
GO



--popoulating the newly created column according to whether the entries contain the substring 'ft' or not 
--because since most of the values are in meters we can assume the ones that don't have a specified 
--unit must be in meters by default 


ALTER TABLE coffee_data ADD Altitude_Unit VARCHAR(10)
GO


--populating the new column with units of measurement used in the Altitude column
--according to whether they contain the substring 'ft' or 'm'



UPDATE coffee_data
SET Altitude_Unit =
  CASE WHEN Altitude LIKE '%ft%' THEN
      'ft'
  ELSE
      'm'
  END



--creating a new column to which we will transfer the altitude values 



ALTER TABLE coffee_data ADD Altitude_Above VARCHAR(10) 
GO


--stripping the entries in column Altitude from non-numeric values and then trimming the spaces from the entries just in case


UPDATE coffee_data 
SET Altitude = [dbo].[Numeric](Altitude)

--changing the column data type to decimal in order to get it ready for unit conversion

ALTER TABLE coffee_data
ALTER COLUMN Altitude_Above DECIMAL(10,2)


UPDATE coffee_data SET Altitude_Above = CAST(LEFT(Altitude,4) AS SMALLINT)
ALTER TABLE coffee_data ALTER COLUMN Altitude_Above DECIMAL(10,2)


--disposing of the original column since we extracted everything we need from it


ALTER TABLE coffee_data DROP COLUMN Altitude


--converting ft to m where needed while keeping the assumption that the entries without a specified unit of measurement 
--are in meters above sea level by default


UPDATE coffee_data
SET Altitude_Above =
  CASE WHEN Altitude_Unit = 'ft' OR Altitude_Above > 2000 THEN
      Altitude_Above * 0.454
  ELSE 
      Altitude_Above
  END


--disposing of the unit column since we are done with the conversion where it was needed


ALTER TABLE coffee_data DROP COLUMN Altitude_Unit


--nullifying entries where the lower bound of altitude is 0 or 1


UPDATE coffee_data 
SET Altitude_Above = NULLIF(Altitude_Above, 0)

UPDATE coffee_data 
SET Altitude_Above = NULLIF(Altitude_Above, 1)


GO

--creating a new column for units of measurement (kg/lbs)



ALTER TABLE coffee_data ADD Bag_Weight_Unit VARCHAR(10) 
GO



--populating the new column with units of measurement used in the Bag_Weight column
--according to whether they contain the substring 'lb'



UPDATE coffee_data
SET Bag_Weight_Unit =
  CASE WHEN Bag_Weight LIKE '%lb%' THEN
      'lbs'
  ELSE
      'kg'
  END





--stripping the entries in column Bag_Weight from non-numeric values 


UPDATE coffee_data 
SET Bag_Weight = [dbo].[Numeric](Bag_Weight)

--changing the data type of the column to decimal in order to be able to perform unit conversions on it

ALTER TABLE coffee_data
ALTER COLUMN Bag_Weight DECIMAL(10,2)


--converting lbs to kgs where needed while keeping the assumption that the entries without a specified unit of measurement 
--are in kilograms by default


UPDATE coffee_data
SET Bag_Weight =
  CASE WHEN Bag_Weight_Unit = 'lbs' THEN
      Bag_Weight * 0.454
  ELSE 
      Bag_Weight
  END    


--disposing of the unit column since we are done with the conversion where it was needed


ALTER TABLE coffee_data DROP COLUMN Bag_Weight_Unit


--viewing the cleaned dataset 


SELECT * FROM coffee_data