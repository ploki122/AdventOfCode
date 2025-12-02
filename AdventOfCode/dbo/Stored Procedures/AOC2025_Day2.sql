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

	SELECT SUM(value)
	FROM #splits
	CROSS APPLY GENERATE_SERIES(CAST(RangeStart AS NUMERIC(10,0)), CAST(RangeEnd AS NUMERIC(10,0)), CAST(1 AS NUMERIC(10,0))) as series
	WHERE LEN(value)%2 = 0
		AND LEFT(value, LEN(value)/2) = RIGHT(value, LEN(value)/2);
	
	---------------------
	-- Phase 2 solving --
	---------------------
	DECLARE @RowNumber INT = 99999999;
	WITH ValidResults AS(
		SELECT DISTINCT TOP (@RowNumber) REPLICATE(racine.value, mult.value) AS value
		FROM GENERATE_SERIES(1, 99999, 1) AS racine
			, GENERATE_SERIES(2, 10) AS mult
		WHERE LEN(racine.value) * mult.value <= 10
	)
	SELECT SUM(CAST(value AS NUMERIC(20,0))) 
	FROM #splits splits INNER JOIN ValidResults ON ValidResults.value BETWEEN CAST(splits.RangeStart AS NUMERIC(10,0)) AND CAST(splits.RangeEnd AS NUMERIC(10,0))
	OPTION(OPTIMIZE FOR(@RowNumber = 100000));
END