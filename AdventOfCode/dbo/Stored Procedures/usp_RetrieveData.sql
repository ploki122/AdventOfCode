
CREATE   PROCEDURE usp_RetrieveData
	@Year SMALLINT = NULL,
	@Day TINYINT = NULL,
	@Type NVARCHAR(10) = 'Real',
	@ForceCacheRefresh BIT = 0
AS
BEGIN
	SET NOCOUNT ON;
	
	SELECT @Year = ISNULL(@Year, DATEPART(YEAR, CURRENT_TIMESTAMP));
	SELECT @Day = ISNULL(@Day, DATEPART(DAY, CURRENT_TIMESTAMP));

	IF(@ForceCacheRefresh = 1)
		DELETE CachedData WHERE Year = @Year AND Day = @Day AND Type = @Type;

	IF NOT EXISTS(SELECT Data FROM CachedData WHERE Year = @Year AND Day = @Day AND Type = @Type AND @Type = 'Real')
	BEGIN
		-- Declare the variable where the response will be saved
		DECLARE @responseTable TABLE (Result NVARCHAR(MAX));
		DECLARE @responseText NVARCHAR(max);

		--CONFIG
		------------------------
		DECLARE @contentType NVARCHAR(64) = 'application/text';
		DECLARE @method VARCHAR(20) = 'GET';
		DECLARE @url NVARCHAR(256) = 'https://adventofcode.com/' + FORMAT(@Year, '#') + '/day/' + FORMAT(@Day, '#') + '/input';
		------------------------
		
		PRINT 'Querying ' + @url;

		--VAR
		------------------------
		DECLARE @status NVARCHAR(32),
			@statusText NVARCHAR(32),
			@OAuthToken VARCHAR(150),
			@ResponseHeader VARCHAR(max),
			@Body VARCHAR(500) = '',
			@token INT,
			@ret INT
		------------------------

		SELECT @OAuthToken = 'session=' + KeyValue FROM SecretKeys WHERE KeyName = 'token';

		--API
		------------------------
		-- CREATE INSTANCE 
		-- The variable @token is saving the token of the instance
		EXEC @ret = sp_OACreate 'WinHttp.WinHttpRequest.5.1', @token OUT;
		EXEC @ret = sp_OAMethod @token, 'open' , NULL, @method, @url, 'false';
		-- Set Request Headers
		EXEC @ret = sp_OAMethod @token, 'setRequestHeader' , NULL, 'Content-type', @contentType;
		EXEC @ret = sp_OAMethod @token, 'setRequestHeader' , NULL, 'Cookie', @OAuthToken;

		-- Send request to API
		EXEC @ret = sp_OAMethod @token, 'send' , NULL, @Body;
 
		-- Get properties of response
		EXEC @ret = sp_OAGetProperty @token, 'status' , @status OUT; --status code example: 200, 400, 404
		EXEC @ret = sp_OAGetProperty @token, 'statusText' , @statusText OUT; -- Status text of the response example: 200 - Ok, 400 - Bad Request, 404 - Not Found
		-- Get Response Headers
		EXEC @ret = sp_OAGetProperty @token, 'getAllRequestHeaders' , @ResponseHeader OUT; 
		
		--Get response json 
		INSERT  @responseTable(Result) EXEC    @ret = dbo.sp_OAGetProperty @token, 'responseText' -- Insert response text into table
		
		-- DELETE INSTANCE
		EXEC @ret = sp_OADestroy @token;
		------------------------
		
		IF (@status = 200)
			INSERT CachedData(Year, Day, Type, Data)
			SELECT @Year, @Day, @Type, Result
			FROM @responseTable;
	END

	SELECT Data FROM CachedData WHERE Year = @Year AND Day = @Day AND Type = @Type;
END