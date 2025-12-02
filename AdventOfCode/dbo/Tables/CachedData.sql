CREATE TABLE [dbo].[CachedData] (
    [Year] SMALLINT       NOT NULL,
    [Day]  TINYINT        NOT NULL,
    [Type] NVARCHAR (10)  NOT NULL,
    [Data] NVARCHAR (MAX) NOT NULL,
    CONSTRAINT [PK_CachedData] PRIMARY KEY CLUSTERED ([Year] ASC, [Day] ASC, [Type] ASC)
);

