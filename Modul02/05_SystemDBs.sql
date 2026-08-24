/*

master
"herz"
Login, Datenbanken, Konfiguration

Backup: Backup..!


model
--Vorlage für neue DBs

create database testdb
--Änderungen an der model haben Auswirkung auf alle danach erzeugten DBS
--Einstellungen, Tabellen
--Backup der modelDB: nur notwendig , wenn Änderungen
--alternativ per Script

USE [master]
GO
ALTER DATABASE [model] MODIFY FILE ( NAME = N'modeldev', SIZE = 9216KB )
GO


msdb
DB für den Agent
Zeitpläne, Jobs, Proxykonten, Warnungen , DB Email
SSIS Pakete (SQL Server Integration Services)  Datenimport Export
Wartungsplan = SSSI Paet

Backup: regelmäßig



tempdb
#tab   ##tab
Zeilenversionierung
IX Rebuild 
Auslagerungen
--so schnell sein

Backup:  No


--welche tut am meisten weh:?
msdb


--------------------------------------
distribution (replikation)

mssqlsystemressources-versteckte DB .. black box


Sicherung der SystemDbs

Wartungsplan
Vollständige Sicherung --> SytemDbs --> einmal täglich -- > 
--> Unterordner anlegen lassen -->
--> Checksumme+Integritätsprüfung + Kompression + bei Fehler fortsetzen
--> Logfile + Email, wenn man will


V TTT D TTT D TTT DTT

*/
--Vollsicherung
BACKUP DATABASE [TestDb] TO  DISK = N'C:\_SQLBACKUP\TestDb1.bak' 
WITH NOFORMAT, NOINIT,  NAME = N'TestDb-Voll', 
SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO
--SQL Server Dienst
--per Job--> SQL Agent

--Diff
BACKUP DATABASE [TestDb] TO  DISK = N'C:\_SQLBACKUP\TestDb.bak' 
WITH  DIFFERENTIAL 
, NOFORMAT, NOINIT,  NAME = N'TestDb-Diff'
, SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO

--Tlog
BACKUP LOG [TestDb] TO  DISK = N'C:\_SQLBACKUP\TestDb.bak' 
WITH NOFORMAT, NOINIT,  NAME = N'TestDb-Tlog', 
SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO

-- V  TTT D TTT D TTT

