CREATE   PROCEDURE dbo.AOC2025_Day2
(
	@Type varchar(10) = 'Real'
)
AS
BEGIN
	-------------------
	-- Data handling --
	-------------------
	DROP TABLE IF EXISTS #splits;
	DROP TABLE IF EXISTS #numSplits;

	DECLARE @StringData TABLE (DayData nvarchar(max));
	-- Workaround because the INSERT cannot happen during another INSERT
	EXEC usp_RetrieveData @Year=2025, @Day=2, @Type=@Type;
	
	INSERT INTO @StringData
	EXEC usp_RetrieveData @Year=2025, @Day=2, @Type=@Type;

	SELECT MIN(CASE WHEN secondSplit.ordinal = 1 THEN secondSplit.value END) AS RangeStart
		, REPLACE(MIN(CASE WHEN secondSplit.ordinal = 2 THEN secondSplit.value END), CHAR(10), '') AS RangeEnd
	INTO #splits
	FROM @StringData as StringData
	CROSS APPLY STRING_SPLIT(StringData.DayData, ',') as split
	CROSS APPLY STRING_SPLIT(split.value, '-', 1) as secondSplit
	WHERE split.value <> ''
	GROUP BY split.value;
	
	---------------------
	-- Phase 1 solving --
	---------------------
	WITH ValidResults AS(
		SELECT REPLICATE(racine.value, 2) AS value
		FROM GENERATE_SERIES(1, 99999, 1) AS racine
	)
	SELECT SUM(CAST(value AS NUMERIC(20,0))) 
	FROM #splits splits INNER JOIN ValidResults ON ValidResults.value BETWEEN CAST(splits.RangeStart AS NUMERIC(10,0)) AND CAST(splits.RangeEnd AS NUMERIC(10,0));

	---------------------
	-- Phase 2 solving --
	---------------------
	WITH ValidResults AS(
		SELECT DISTINCT REPLICATE(racine.value, mult.value) AS value
		FROM GENERATE_SERIES(1, 99999, 1) AS racine
			, GENERATE_SERIES(2, 10) AS mult
		WHERE LEN(racine.value) * mult.value <= 10
	)
	SELECT SUM(CAST(value AS NUMERIC(20,0))) 
	FROM #splits splits INNER JOIN ValidResults ON ValidResults.value BETWEEN CAST(splits.RangeStart AS NUMERIC(10,0)) AND CAST(splits.RangeEnd AS NUMERIC(10,0));
END