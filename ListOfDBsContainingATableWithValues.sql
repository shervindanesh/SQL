/***************************************************************************************
  Description:			Extracts list of DATABASES on a target server that have DATA in a specific TABLE
  Database:             MS SQL Server
  By:					SHERVIN
****************************************************************************************/
GO
--INPUT PARAMETERS----------------------------------
DECLARE @InputTblName AS NVARCHAR(max)
SET @InputTblName = 'Product' --Table name to search
----------------------------------------------------
if OBJECT_ID('tempdb..#myDBList1', N'U') is not null 
BEGIN
	drop table #myDBList1
	print N'table dropped';
END 

if OBJECT_ID('tempdb..#myDBList2', N'U') is not null 
BEGIN
	drop table #myDBList2
	print N'table dropped';
END 

declare @DBName1 NVarchar(100)
declare @SQLStr1 NVarchar(max)
create table #myDBList2 (DBNAME NVARCHAR(max),TBLNAME NVARCHAR(max), RESULT NVarchar(5), RowID int)
insert into #myDBList2 (DBNAME, RESULT, ROWID) VALUES ('BEGIN', '-1','0')

SELECT distinct db.name into #myDBList1
FROM sys.databases db INNER JOIN sys.master_files mf ON db.database_id = mf.database_id
WHERE db.state =0 --search in online db (not off-line)
and db.name not in ('master', 'tempdb', 'model','msdb') 

declare db_cursor CURSOR FOR SELECT NAME FROM #myDBList1
declare @counter1 int 
set @counter1 =1;
OPEN db_cursor FETCH NEXT FROM db_cursor INTO @DBName1
WHILE @@FETCH_STATUS = 0   
BEGIN 
	BEGIN TRY
		PRINT @DBNAME1
		SET @SQLStr1=''
		SET @SQLStr1 = 'select '''+@DBName1+''' AS DBNAME, '''+@InputTblName+''' AS TBLNAME , CASE WHEN EXISTS(select 1 from ['+@DBName1+'].dbo.'+@InputTblName+') THEN  1 ELSE 0 END AS RESULT, ' + cast(@counter1 as varchar(5))+ ' AS ROWID '
		SET @counter1= @counter1+ 1
		PRINT @SQLSTR1
		INSERT into #myDBList2 execute  (@SQLStr1)
	END TRY
	BEGIN CATCH
		SELECT ERROR_NUMBER() AS ErrorNumber ,ERROR_MESSAGE() AS ErrorMessage;
	END CATCH
	FETCH NEXT FROM db_cursor INTO @DBName1
END
-------------------------------------------------------------------------------
insert into #myDBList2 (DBNAME, RESULT, RowID) VALUES ('END', -1, '99999')
--PRINT RESULTS----------------------------------------------------------------
select distinct * from #myDBList2 
where RESULT = 1
order by rowID
-------------------------------------------------------------------------------
RETURN_POINT:
CLOSE db_cursor
DEALLOCATE db_cursor
drop table #myDBList1
drop table #myDBList2
