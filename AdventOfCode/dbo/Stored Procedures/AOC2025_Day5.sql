
CREATE  PROCEDURE [dbo].[AOC2025_Day5]
(
	@Type varchar(10) = 'Real'
)
AS
BEGIN
	-------------------
	-- Data handling --
	-------------------
	DROP TABLE IF EXISTS #splits;
	DROP TABLE IF EXISTS #ranges;

	DECLARE @StringData TABLE (DayData nvarchar(max));
	-- Workaround because the INSERT cannot happen during another INSERT
	EXEC usp_RetrieveData @Year=2025, @Day=5, @Type=@Type;
	
	INSERT INTO @StringData
	EXEC usp_RetrieveData @Year=2025, @Day=5, @Type=@Type;

	
	SELECT CAST(value AS Numeric(20,0)) AS ID
	INTO #numbers
	FROM @StringData as StringData
	CROSS APPLY STRING_SPLIT(StringData.DayData, CHAR(10)) as split
	WHERE split.value NOT LIKE '%-%'
		AND TRIM(split.value) NOT LIKE '';
	
	SELECT CAST(LEFT(value, CHARINDEX('-', value)-1) AS Numeric(20,0)) AS rangeStart, CAST(SUBSTRING(value, CHARINDEX('-', value) + 1, 999) AS Numeric(20,0)) AS rangeEnd
	INTO #ranges
	FROM @StringData as StringData
	CROSS APPLY STRING_SPLIT(StringData.DayData, CHAR(10)) as split
	WHERE split.value LIKE '%-%';

	---------------------
	-- Phase 1 solving --
	---------------------
	
	SELECT DISTINCT ID
	FROM #ranges ranges
	INNER JOIN #numbers numbers ON ranges.rangeStart <= numbers.ID AND rangeEnd >= numbers.ID
	
	---------------------
	-- Phase 2 solving --
	---------------------
	
	SELECT * INTO #remainingRanges FROM #ranges;
	DECLARE @PoppedRangeStart NUMERIC(20, 0)
		, @PoppedRangeEnd NUMERIC(20, 0)
		, @Total NUMERIC(20, 0) = 0;

	WHILE EXISTS (SELECT 1 FROM #remainingRanges)
	BEGIN
		SELECT TOP 1 @PoppedRangeStart = rangeStart
			, @PoppedRangeEnd = rangeEnd
			, @Total += rangeEnd - rangeStart + 1
		FROM #remainingRanges
		ORDER BY rangeEnd - rangeStart + 1 DESC;

		DELETE #remainingRanges 
		WHERE rangeStart >= @PoppedRangeStart
			AND rangeEnd <= @PoppedRangeEnd;

		UPDATE #remainingRanges
			SET rangeStart = CASE WHEN rangeStart >= @PoppedRangeStart AND rangeStart <= @PoppedRangeEnd THEN @PoppedRangeEnd + 1 ELSE rangeStart END
				, rangeEnd = CASE WHEN rangeEnd >= @PoppedRangeStart AND rangeEnd <= @PoppedRangeEnd THEN @PoppedRangeStart - 1 ELSE rangeEnd END

		--SELECT *, rangeEnd - rangeStart + 1 as size FROM #remainingRanges 
		--ORDER BY rangeEnd - rangeStart + 1 DESC;
	END
	SELECT @Total;
	
END