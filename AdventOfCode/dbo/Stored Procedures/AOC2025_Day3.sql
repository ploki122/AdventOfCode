
CREATE  PROCEDURE [dbo].[AOC2025_Day3]
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
	EXEC usp_RetrieveData @Year=2025, @Day=3, @Type=@Type;
	
	INSERT INTO @StringData
	EXEC usp_RetrieveData @Year=2025, @Day=3, @Type=@Type;

	SELECT value, ordinal
	INTO #splits
	FROM @StringData as StringData
	CROSS APPLY STRING_SPLIT(StringData.DayData, CHAR(10), 1) as split
	WHERE split.value <> '';


	-----------------------
	---- Phase 1 solving --
	-----------------------
	
	WITH Numbers AS(
		SELECT '1' AS n
		UNION ALL SELECT '2'
		UNION ALL SELECT '3'
		UNION ALL SELECT '4'
		UNION ALL SELECT '5'
		UNION ALL SELECT '6'
		UNION ALL SELECT '7'
		UNION ALL SELECT '8'
		UNION ALL SELECT '9'
		UNION ALL SELECT '0'
	), FirstPositions AS (
		SELECT value, ordinal, n, CHARINDEX(n, value) as Pos
		FROM #splits, Numbers
		WHERE CHARINDEX(n, value) > 0
			AND CHARINDEX(n, value) < LEN(value)
	), SecondPositions AS(
		SELECT value
			, ordinal
			, FirstPositions.n AS FirstDigit
			, Numbers.n AS SecondDigit
			, Pos
			, CHARINDEX(Numbers.n, value, FirstPositions.Pos+1) SeconPos
			, ROW_NUMBER() OVER(PARTITION BY value ORDER BY FirstPositions.n DESC, Numbers.n DESC) AS Prio
		FROM FirstPositions, Numbers
		WHERE CHARINDEX(Numbers.n, value, FirstPositions.Pos+1) > 0
	)
	SELECT value
		, ordinal
		, FirstDigit + SecondDigit
		, SUM(CAST(FirstDigit + SecondDigit AS INT)) OVER(ORDER BY ordinal) AS runningSum
	FROM SecondPositions
	WHERE Prio = 1;
	
	-----------------------
	---- Phase 2 solving --
	-----------------------
	
	
	WITH Numbers AS(
		SELECT '1' AS n
		UNION ALL SELECT '2'
		UNION ALL SELECT '3'
		UNION ALL SELECT '4'
		UNION ALL SELECT '5'
		UNION ALL SELECT '6'
		UNION ALL SELECT '7'
		UNION ALL SELECT '8'
		UNION ALL SELECT '9'
		UNION ALL SELECT '0'
	), Positions AS (
		SELECT value
			, ordinal
			, CAST(n AS VARCHAR(20)) AS n
			, CHARINDEX(n, value) as Pos
			, ROW_NUMBER() OVER(PARTITION BY value ORDER BY Numbers.n DESC) AS Prio
		FROM #splits, Numbers
		WHERE CHARINDEX(n, value) > 0
			AND CHARINDEX(n, value) < LEN(value)-10
		UNION ALL
		SELECT value
			, ordinal
			, CAST(OldPosition.n + Numbers.n AS VARCHAR(20)) AS n
			, CHARINDEX(Numbers.n, value, OldPosition.Pos+1) Pos
			, ROW_NUMBER() OVER(PARTITION BY value ORDER BY OldPosition.n DESC, Numbers.n DESC) AS Prio
		FROM Positions AS OldPosition, Numbers
		WHERE CHARINDEX(Numbers.n, value, OldPosition.Pos+1) > 0
			AND CHARINDEX(Numbers.n, value, OldPosition.Pos+1) < LEN(value)-10+LEN(OldPosition.n)
			AND Prio = 1
			AND LEN(OldPosition.n) < 12
	)
	SELECT value
		, ordinal
		, n
		, SUM(CAST(n AS NUMERIC(20, 0))) OVER(ORDER BY ordinal) AS runningSum
	FROM Positions
	WHERE Prio = 1
		AND LEN(n) = 12;
	
END