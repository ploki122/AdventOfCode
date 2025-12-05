

CREATE    PROCEDURE [dbo].[AOC2025_Day4]
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
	EXEC usp_RetrieveData @Year=2025, @Day=4, @Type=@Type;
	
	INSERT INTO @StringData
	EXEC usp_RetrieveData @Year=2025, @Day=4, @Type=@Type;

	SELECT value, ordinal
	INTO #splits
	FROM @StringData as StringData
	CROSS APPLY STRING_SPLIT(StringData.DayData, CHAR(10), 1) as split
	WHERE split.value <> '';

	--SELECT ordinal, value 
	--FROM #splits
	--ORDER BY 1;

	DECLARE @RowLength INT;
	DECLARE @FullGrid VARCHAR(MAX);
	SELECT @RowLength = MAX(LEN(value))+2 
		, @FullGrid = STRING_AGG('.'+value+'.', '') WITHIN GROUP(ORDER BY ordinal)
	FROM #splits;


	-----------------------
	---- Phase 1 solving --
	-----------------------

	WITH Fullgrid AS(
		SELECT SUBSTRING(@FullGrid, series.value, 1) AS value
			, CASE WHEN SUBSTRING(@FullGrid, series.value, 1) = '@' THEN 1 ELSE 0 END AS iValue
			, value AS pos
		FROM generate_series(1, @RowLength * @RowLength, 1) AS series
	), FullData AS (
		SELECT value
			, LAG(iValue, @RowLength + 1, 0) OVER (ORDER BY pos)
				+ LAG(iValue, @RowLength, 0) OVER (ORDER BY pos)
				+ LAG(iValue, @RowLength - 1, 0) OVER (ORDER BY pos)
				+ LAG(iValue, 1, 0) OVER (ORDER BY pos)
				+ LEAD(iValue, 1, 0) OVER (ORDER BY pos)
				+ LEAD(iValue, @RowLength - 1, 0) OVER (ORDER BY pos)
				+ LEAD(iValue, @RowLength, 0) OVER (ORDER BY pos)
				+ LEAD(iValue, @RowLength + 1, 0) OVER (ORDER BY pos) as nbRoll
		FROM Fullgrid
	)
	SELECT COUNT(*)
	FROM FullData
	WHERE value = '@'
		AND nbRoll < 4


	-----------------------
	---- Phase 2 solving --
	-----------------------
	DECLARE @InitialRolls INT;
	WITH Fullgrid AS(
		SELECT SUBSTRING(@FullGrid, series.value, 1) AS value
			, CASE WHEN SUBSTRING(@FullGrid, series.value, 1) = '@' THEN 1 ELSE 0 END AS iValue
			, value AS pos
		FROM generate_series(1, @RowLength * @RowLength, 1) AS series
	)
	SELECT @InitialRolls = COUNT(*) FROM Fullgrid WHERE value = '@';
	
	DECLARE @BeforeRolls INT = @InitialRolls;
	DECLARE @AfterRolls INT;

	DECLARE @Loop BIT = 1;

	WHILE @Loop = 1
	BEGIN
		WITH Fullgrid AS
		(
			SELECT SUBSTRING(@FullGrid, series.value, 1) AS value
				, CASE WHEN SUBSTRING(@FullGrid, series.value, 1) = '@' THEN 1 ELSE 0 END AS iValue
				, value AS pos
			FROM generate_series(1, @RowLength * @RowLength, 1) AS series
		), FullData AS 
		(
			SELECT value
				, iValue
				, pos
				, LAG(iValue, @RowLength + 1, 0) OVER (ORDER BY pos)
					+ LAG(iValue, @RowLength, 0) OVER (ORDER BY pos)
					+ LAG(iValue, @RowLength - 1, 0) OVER (ORDER BY pos)
					+ LAG(iValue, 1, 0) OVER (ORDER BY pos)
					+ LEAD(iValue, 1, 0) OVER (ORDER BY pos)
					+ LEAD(iValue, @RowLength - 1, 0) OVER (ORDER BY pos)
					+ LEAD(iValue, @RowLength, 0) OVER (ORDER BY pos)
					+ LEAD(iValue, @RowLength + 1, 0) OVER (ORDER BY pos) as nbRoll
			FROM Fullgrid
		)
		SELECT @FullGrid = STRING_AGG(CASE WHEN nbRoll < 4 THEN '.' ELSE value END, '') WITHIN GROUP(ORDER BY pos)
		FROM FullData;

		-- Count rolls
		WITH Fullgrid AS(
			SELECT SUBSTRING(@FullGrid, series.value, 1) AS value
				, CASE WHEN SUBSTRING(@FullGrid, series.value, 1) = '@' THEN 1 ELSE 0 END AS iValue
				, value AS pos
			FROM generate_series(1, @RowLength * @RowLength, 1) AS series
		)
		SELECT @AfterRolls = COUNT(*) FROM Fullgrid WHERE value = '@';
		
		IF @AfterRolls < @BeforeRolls
			SET @BeforeRolls = @AfterRolls
		ELSE
			SET @Loop = 0
	END
	
	SELECT @InitialRolls - @AfterRolls;
END