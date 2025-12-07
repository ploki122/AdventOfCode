
CREATE   PROCEDURE [dbo].[AOC2025_Day6]
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
	EXEC usp_RetrieveData @Year=2025, @Day=6--, @Type=@Type;
	
	INSERT INTO @StringData
	EXEC usp_RetrieveData @Year=2025, @Day=6--, @Type=@Type;

	SELECT value, ordinal
	INTO #lines
	FROM @StringData as StringData
	CROSS APPLY STRING_SPLIT(StringData.DayData, CHAR(10), 1) as split
	WHERE TRIM(split.value) NOT LIKE '';

	---------------------
	-- Phase 1 solving --
	---------------------

	WITH Positions AS
	(
		SELECT COUNT(c2.value) OVER(ORDER BY c1.ordinal, c2.ordinal) AS pos
			, ISNULL(SUM(DATALENGTH(c2.value)/2) OVER(ORDER BY c1.ordinal, c2.ordinal ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING), 0) + COUNT(c2.value) OVER(ORDER BY c1.ordinal, c2.ordinal) AS subStart
			, DATALENGTH(c2.value)/2+1 AS subEnd
		FROM #lines lines
		CROSS APPLY STRING_SPLIT(lines.value, '+', 1) AS c1
		CROSS APPLY STRING_SPLIT(c1.value, '*', 1) AS c2
		WHERE lines.ordinal = 5
			AND DATALENGTH(c2.value) > 0
	), Operations AS (
		SELECT pos
			, CAST(MIN(TRIM(CASE WHEN ordinal = 1 THEN SUBSTRING(value, subStart, subEnd) END)) AS BIGINT) as n1
			, CAST(MIN(TRIM(CASE WHEN ordinal = 2 THEN SUBSTRING(value, subStart, subEnd) END)) AS BIGINT) as n2
			, CAST(MIN(TRIM(CASE WHEN ordinal = 3 THEN SUBSTRING(value, subStart, subEnd) END)) AS BIGINT) as n3
			, CAST(MIN(TRIM(CASE WHEN ordinal = 4 THEN SUBSTRING(value, subStart, subEnd) END)) AS BIGINT) as n4
			, MIN(TRIM(CASE WHEN ordinal = 5 THEN SUBSTRING(value, subStart, subEnd) END)) as op
		FROM #lines, Positions
		GROUP BY pos
	)
	SELECT n1
		, n2
		, n3
		, n4
		, op
		, CASE WHEN op='+' THEN n1+n2+n3+n4 ELSE n1*n2*n3*n4 END AS total
		, SUM(CASE WHEN op='+' THEN n1+n2+n3+n4 ELSE n1*n2*n3*n4 END) OVER(ORDER BY pos) AS runningTotal
	FROM Operations;

	---------------------
	-- Phase 2 solving --
	---------------------

	WITH Columns AS
	(
		SELECT CAST(CONCAT(SUBSTRING(line1.value, ser.value, 1), SUBSTRING(line2.value, ser.value, 1), SUBSTRING(line3.value, ser.value, 1), SUBSTRING(line4.value, ser.value, 1)) AS INT) AS value
			,  SUBSTRING(line1.value, ser.value, 1) as l1
			, SUBSTRING(line2.value, ser.value, 1) as l2
			, SUBSTRING(line3.value, ser.value, 1) as l3
			, SUBSTRING(line4.value, ser.value, 1) as l4
			, TRIM(SUBSTRING(line5.value, ser.value, 1)) AS op
			, ser.value AS ordinal
		FROM (SELECT value FROM #lines WHERE ordinal = 1) line1
			, (SELECT value FROM #lines WHERE ordinal = 2) line2
			, (SELECT value FROM #lines WHERE ordinal = 3) line3
			, (SELECT value FROM #lines WHERE ordinal = 4) line4
			, (SELECT value FROM #lines WHERE ordinal = 5) line5
			, generate_series(1, (SELECT CAST(MAX(DATALENGTH(value)/2) AS INT) FROM #lines), 1) as ser
		WHERE SUBSTRING(line1.value, ser.value, 1) <> ''
			OR SUBSTRING(line2.value, ser.value, 1) <> ''
			OR SUBSTRING(line3.value, ser.value, 1) <> ''
			OR SUBSTRING(line4.value, ser.value, 1) <> ''
	), OperationLines AS
	(
		SELECT CAST(value AS BIGINT) AS value
			, op
			, COUNT(CASE WHEN op <> '' THEN 1 END) OVER(ORDER BY ordinal) AS rk
		FROM Columns
	), RankedOperations AS
	(
		SELECT value
			, op
			, rk
			, ROW_NUMBER() OVER(PARTITION BY rk ORDER BY rk) as rn
		FROM OperationLines
	)
	SELECT rk as opNo
		, MAX(op) AS op
		, MAX(CASE WHEN rn = 1 THEN value END) AS val1
		, MAX(CASE WHEN rn = 2 THEN value END) AS val2
		, MAX(CASE WHEN rn = 3 THEN value END) AS val3
		, MAX(CASE WHEN rn = 4 THEN value END) AS val4
		, CASE WHEN MAX(op) = '*' THEN ISNULL(MAX(CASE WHEN rn = 1 THEN value END), 1) * ISNULL(MAX(CASE WHEN rn = 2 THEN value END), 1) * ISNULL(MAX(CASE WHEN rn = 3 THEN value END), 1) * ISNULL(MAX(CASE WHEN rn = 4 THEN value END), 1) ELSE SUM(value) END
		, SUM(CASE WHEN MAX(op) = '*' THEN ISNULL(MAX(CASE WHEN rn = 1 THEN value END), 1) * ISNULL(MAX(CASE WHEN rn = 2 THEN value END), 1) * ISNULL(MAX(CASE WHEN rn = 3 THEN value END), 1) * ISNULL(MAX(CASE WHEN rn = 4 THEN value END), 1) ELSE SUM(value) END) OVER(ORDER BY rk) AS runningSum
	FROM RankedOperations
	GROUP BY rk
	ORDER BY rk
	
END