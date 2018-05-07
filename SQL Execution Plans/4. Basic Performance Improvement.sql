USE Sandpit;
GO

SET NOCOUNT ON;

DROP TABLE IF EXISTS dbo.Users;

CREATE TABLE dbo.Users (
	UserId INT NOT NULL IDENTITY(1,1)
	,UserFirstName VARCHAR(100) NOT NULL
	,UserLastName VARCHAR(100) NOT NULL
	);
GO

WITH FirstNames AS (
	SELECT c1 AS firstname
	FROM (VALUES('Mark'),('Sue'),('John'),('Marge'),('Matthew'),('Samantha'),('Peter')
		,('Florence'),('James'),('Janet'),('Jack'),('Wilma'),('Wally'),('Rachel'),('Fred'),('Lucy'),('Joe'),('Amy'),('Michael'),('Kate')
		,('Adam'),('Alice'),('Tom'),('Tanya'),('Chris'),('Maddie'),('Roy'),('Joyce')) t1(c1)
	)
,LastNames AS (
	SELECT c1 AS lastname
	FROM (VALUES('Smith'),('Jones'),('Taylor'),('Williams'),('Brown'),('Davies'),('Evans'),('Wilson'),('Thomas'),('Roberts'),('Johnson'),('Lewis'),('Walker'),('Robinson'),('Wood')
		,('Thompson'),('White'),('Watson'),('Jackson'),('Wright'),('Green'),('Harris'),('Cooper'),('King'),('Lee'),('Martin'),('Clarke'),('James'),('Morgan'),('Hughes'),('Edwards')
		,('Hill'),('Moore'),('Clark'),('Harrison'),('Scott'),('Young'),('Morris'),('Hall'),('Ward'),('Turner'),('Carter'),('Phillips'),('Mitchell'),('Patel'),('Adams'),('Campbell')
		,('Anderson'),('Allen'),('Cook')) t1(c1)
	)

INSERT INTO dbo.Users
SELECT	*
FROM	FirstNames
	CROSS JOIN LastNames
;
GO

--Check Users table has something in it
--SELECT * FROM dbo.Users;

DROP TABLE IF EXISTS dbo.Transactions;

CREATE TABLE dbo.Transactions (
	TransactionID INT NOT NULL IDENTITY(1,1) 
	,UserId INT NOT NULL
	,TransactionAmount DECIMAL(8,2) NULL DEFAULT(0)
	);
GO

DECLARE @start INT = 1
	,@end INT = 100000

WHILE @start <= @end
BEGIN

INSERT INTO dbo.Transactions
SELECT FLOOR(RAND()*(0-1300)+1300)
	,CAST(RAND()*(0-10000)+10000 AS DECIMAL(8,2))
;

SET @start = @start + 1;

END
GO

SET SHOWPLAN_XML ON;
GO

SELECT	*
FROM	dbo.Transactions t
	JOIN dbo.Users u
		ON t.UserId = u.UserId
WHERE	u.UserFirstName = 'Mark'
;
--Subtree Cost 5.25

SET SHOWPLAN_XML OFF;
GO

CREATE NONCLUSTERED INDEX NCIdx_Transaction_TransactionId ON
dbo.Transactions(TransactionID);

SET SHOWPLAN_XML ON;
GO

SELECT	*
FROM	dbo.Transactions t
	JOIN dbo.Users u
		ON t.UserId = u.UserId
WHERE	u.UserFirstName = 'Mark';
--Nothing happened, hmmmmm

SET SHOWPLAN_XML OFF;
GO

DROP INDEX dbo.Transactions.NCIdx_Transaction_TransactionId;

CREATE CLUSTERED INDEX Idx_Transaction_TransactionId ON
dbo.Transactions(TransactionID);

SET SHOWPLAN_XML ON;
GO

SELECT	*
FROM	dbo.Transactions t
	JOIN dbo.Users u
		ON t.UserId = u.UserId
WHERE	u.UserFirstName = 'Mark';
--Subtree cost 5.14 woohoo we're making progress

SET SHOWPLAN_XML OFF;
GO

--Add a nonclustered index on user id - that'll do it
CREATE NONCLUSTERED INDEX NCIdx_Transaction_UserId ON 
dbo.Transactions(UserID);

SET SHOWPLAN_XML ON;
GO

SELECT	*
FROM	dbo.Transactions t
	JOIN dbo.Users u
		ON t.UserId = u.UserId
WHERE	u.UserFirstName = 'Mark';
--What?

SET SHOWPLAN_XML OFF;
GO

DROP INDEX dbo.Transactions.NCIdx_Transaction_UserId;
GO

--Add a covering index
CREATE NONCLUSTERED INDEX NCIdx_Transaction_UserId ON 
dbo.Transactions(UserID)
INCLUDE(TransactionID,TransactionAmount);

SET SHOWPLAN_XML ON;
GO

SELECT	*
FROM	dbo.Transactions t
	JOIN dbo.Users u
		ON t.UserId = u.UserId
WHERE	u.UserFirstName = 'Mark';
--Subtree cost 0.406  Now we're cooking with gas

SET SHOWPLAN_XML OFF;
GO

CREATE UNIQUE CLUSTERED INDEX Idx_Users ON
dbo.Users(UserId)
;

SET SHOWPLAN_XML ON;
GO

SELECT	*
FROM	dbo.Transactions t
	JOIN dbo.Users u
		ON t.UserId = u.UserId
WHERE	u.UserFirstName = 'Mark';
--Subtree cost 0.406  Now we're cooking

--Add index for predicate
SET SHOWPLAN_XML OFF;
GO

CREATE NONCLUSTERED INDEX Idx_Users_UserFirstName ON
dbo.Users(UserFirstName)
;

SET SHOWPLAN_XML ON;
GO

SELECT	*
FROM	dbo.Transactions t
	JOIN dbo.Users u
		ON t.UserId = u.UserId
WHERE	u.UserFirstName = 'Mark';
--Hmmmm why?

SET SHOWPLAN_XML OFF;
GO

DROP INDEX dbo.Users.Idx_Users_UserFirstName;
GO

CREATE NONCLUSTERED INDEX Idx_Users_UserFirstName ON
dbo.Users(UserFirstName)
INCLUDE(UserLastName)
;

SET SHOWPLAN_XML ON;
GO

SELECT	*
FROM	dbo.Transactions t
	JOIN dbo.Users u
		ON t.UserId = u.UserId
WHERE	u.UserFirstName = 'Mark';
--0.401
--x estimated row count FIND THIS VALUE in Execution plan

SET SHOWPLAN_XML OFF;
GO

SELECT	*
FROM	dbo.Transactions t
	JOIN dbo.Users u
		ON t.UserId = u.UserId
WHERE	u.UserFirstName = 'Mark';
--Actual row count