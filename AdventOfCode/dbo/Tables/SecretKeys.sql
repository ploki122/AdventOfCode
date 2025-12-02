CREATE TABLE [dbo].[SecretKeys] (
    [KeyName]  VARCHAR (50)  NOT NULL,
    [KeyValue] VARCHAR (500) NOT NULL,
    CONSTRAINT [PK_SecretKeys] PRIMARY KEY CLUSTERED ([KeyName] ASC)
);

