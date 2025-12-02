CREATE   PROCEDURE dbo.[AOC2025_Day1]
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
	EXEC usp_RetrieveData @Year=2025, @Day=1, @Type=@Type;
	
	INSERT INTO @StringData
	EXEC usp_RetrieveData @Year=2025, @Day=1, @Type=@Type;

	SELECT split.value, split.ordinal
	INTO #splits
	FROM @StringData as StringData
	CROSS APPLY STRING_SPLIT(StringData.DayData, CHAR(10), 1) as split
	WHERE split.value <> ''
	ORDER BY split.ordinal;

	INSERT INTO #splits
	VALUES('50', 0);

	SELECT value, CAST(REPLACE(REPLACE(value, 'R', ''), 'L', '-') AS SMALLINT) as iValue, ordinal
	INTO #numSplits
	FROM #splits;

	---------------------
	-- Phase 1 solving --
	---------------------
	WITH Phase1Data AS 
	(
		SELECT value
			, iValue
			, ordinal
			, SUM(iValue) OVER(ORDER BY ordinal) as runningSum
		FROM #numSplits
	)
	SELECT value
		, iValue
		, ordinal
		, runningSum
		, SUM(CASE WHEN runningSum%100 = 0 THEN 1 END) OVER(ORDER BY ordinal) AS NbZero
	FROM Phase1Data;
	
	---------------------
	-- Phase 2 solving --
	---------------------
	WITH Phase2Data AS
	(
		SELECT value
			, iValue
			, ordinal
			, (500000 + SUM(iValue) OVER(ORDER BY ordinal)) AS runningSum
			, (500000 + SUM(iValue) OVER(ORDER BY ordinal)) / 100 AS turns
			, (500000 + SUM(iValue) OVER(ORDER BY ordinal)) % 100 AS position
		FROM #numSplits
	), 
	ExtendedPhase2Data AS
	(
		SELECT *
			, LAG(runningSum, 1) OVER(ORDER BY ordinal) AS LastRunningSum
			, LAG(position, 1) OVER(ORDER BY ordinal) AS LastPosition
			, LAG(turns, 1) OVER(ORDER BY ordinal) AS LastTurns
		FROM Phase2Data
	)
	SELECT value, ordinal, runningSum, turns, CASE WHEN position = 0 THEN position END AS position
		, SUM(CASE WHEN position = 0 AND iValue < 0 THEN 1 ELSE 0 END + 
	      CASE WHEN LastPosition = 0 AND iValue < 0 THEN -1 ELSE 0 END + 
		  ABS(turns - LastTurns)) OVER(ORDER BY ordinal) AS Clicks
	FROM ExtendedPhase2Data;
END