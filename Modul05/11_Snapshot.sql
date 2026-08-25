USE [master]
GO
ALTER DATABASE northwind SET  Multi_USER WITH NO_WAIT
GO

GO


-- =============================================
-- Create Database Snapshot Template
-- =============================================
USE master
GO


-- Create the database snapshot
CREATE DATABASE SnapshotDBName ON
( NAME = logNamederOrgDatendatei, 
FILENAME = 'PfadundDateiname der Snapshotdatendatei.mdf')
AS SNAPSHOT OF OrgDb;
GO

create database  nw_1616
ON
(
	NAME=Northwind, --alte mdf
	FILENAME='c:\_SQLDATA\nw_1616 .mdf'  --StdPfad des SQL Server
)   as snapshot of northwind


use northwind;
GO

update customers set city = 'XXX' where customerid = 'ALFKI'

select * from customers


--Snapshot-----------------TSQL

--Kann man mehrere SN machen?
--ja

--Kann man einen SN backupen?
--Nö

--Kann man die OrgDB backupen?
--Ja klar

select * from Northwind..customers
except
select * from [SN_nwind_1220]..customers


--kann man den SN restoren?
--nö

--kann man die OrgDB restoren?
--jein--kein normaler restore
--für den normal restore müssen alle SN gelöscht werden
--Restore von SN möglich

--alle user müssen von allen DBs (northwind und Snapshot) verscheucht werden
use master;
GO

--der Restore geht nur, wenn alle Connections beendet wurden

restore database northwind
from database_snapshot ='nw_1616'


select * from sysprocesses where spid > 50 and dbid in(11,5)

select db_id('nw_1400')

kill 56


--oder so 

--alle laufenden Prozesse der Benutzer
select * from sysprocesses 
	where 
			spid > 50 AND
			dbid in (db_id('northwind'), db_id('SN_nwind_1220'))


kill 81