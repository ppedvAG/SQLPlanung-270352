/*

Wiederherstellungsmodel oder RecoveyModel

1. Einfach (Simple)
	..werden TX werden protokolliert, aber nach COMMIT oder ROllACB aus dem Tlog entfernt
	- kann nicht gesichert
	-- Testumgebung
2. Massenprotokolliert (Bulk)
	-- merkt sich die TX und es wirds nichts gelöscht
	-- man muss das Tlog sichern, um Platz zu schaffen, weil nur die TLOG Sicherung das TLOG leert
	-- man kann auf Sekunden restoren, aber nur wenn kein BULK BEfehl vorkam
3. Vollständige (Full)
	-- es wird alles exakt protkolliert
	-- man kann auf Sek restoren
	-- Produktion



Sicherungsarten  
Vollständig V
	-- sichert alle Dateien der DB (Pfade und Größe)
	-- Zeitpunkt

Differenz D
	merkt isch alle Blöcke, die sich seit dem letzten V verändert haben
	
Tlog T
	- Tlog merkt sich die Anweisung (I U D)


! V  (6:00)
	T
	T
	T
		
	T
	T
	T
!		
!	T
!	T
!	T (14:30)


Restore des V ist der schnelleste Restore
Das T kann solange brauchen wie das Sicherungsinterval des T ist
Das D sichert und verkürzt des Restore (ungemein)

Planen: 
Zu erst das V.. So fot wie möglich

Dann das T: wie lange darf die DB still stehen?
			wieviel Datenverlust  in Zeit darf ich erleiden?

Teste!!!!


Welche Fälle gibt es eigtl , um einen Restore machen zu müssen:

1. Server tot--> Restore auf anderen Server
	1.a aber die Datenträger sind 100 ok
	1.b nur die Datendatei ist ok, Log ist tot
	1.c alle Dateien hinüber
2. DB beschädigt --> Restore auf selben Server (ersetzen , weil reparieren versagt)
3. User hat versehentlich etwas versemmelt - DB ok
	3.a er weiss , was betroffen ist
	3.b er weiss nicht, welche DS betroffen
4. Wenn ich wüßte, dass gleich was passiert



*/
--VOLLSICHERUNG
BACKUP DATABASE [Northwind] TO  DISK = N'C:\_SQLBACKUP\northwind.bak' 
	WITH NOFORMAT, NOINIT,  NAME = N'Northwind-Vollständig Datenbank Sichern', 
	SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO
--DIFFSICHERUNG
BACKUP DATABASE [Northwind] TO  DISK = N'C:\_SQLBACKUP\northwind.bak' 
	WITH  DIFFERENTIAL , NOFORMAT, NOINIT,  NAME = N'Northwind-Differenziell',
		SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO
--LOGSICHERUNG
BACKUP LOG [Northwind] TO  DISK = N'C:\_SQLBACKUP\northwind.bak' 
	WITH NOFORMAT, NOINIT,  NAME = N'Northwind-Tlog', 
		SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO


Wir sichern : V TTT D TTT 

--RESTORE

1. Server tot--> Restore auf anderen Server
	1.a aber die Datenträger sind 100 ok
		Dateien anfügen

	1.b nur die Datendatei ist ok, Log ist tot
	  Logdatei entfernen , dann anfügen
	
	1.c alle Dateien hinüber
	--Tipp::
	--kopiere das Backup immer dorthin , wo der Server es auch erwartet
	-- Medium wählen und dann evtl Pfade anpassen

3. User hat versehentlich etwas versemmelt - DB ok
	3.a er weiss , was betroffen ist

	.unter anderern Namen restoren (auf Pfade und DAteinamen aufpassen- müssen geändert werden)
	!! Protkollfragmentsicherung deaktiveren
	--> restoren mit Update / insert / Delete weiterarbeiten

	3.b er weiss nicht, welche DS betroffen
		-- Restore der DB 
	3.b ist auch Fall 2 
	--> DB restoren mit geringstmöglichen DAtenverlust



V: 6 Uhr
D: 10:00
T: 10:10
T: 10:20
T: 10:30
Error : 10:34

--Theoretisch 10:30 mit best Sicherungen Datenverlust = 3-4 min

--Faul: Warten auf 10:40 T 
-- damit restore von 10:33 --> Datenverlust = 6-7 min

--besser:
-- manuell Sicherung von 10:35  Restore von 10:33
--Verlust Dauer der tLogSicherung von 10:35 = zB 90 Sek, Backup wird online gmacht

-- noch besser:
-- manuell Sicherung von 10:35  Restore von 10:33 mit der Zeitachse
-- aber wir wefen die User runter  

--Protokollfragmentsicherung regelt.
-- Beim  Restore angeben:
	--User von der DB trennen
	--DB with replace



	--4. Wenn ich wüsste:--> DB Momentaufnahme



	-- =============================================
-- Create Database Snapshot Template
-- =============================================
USE master
GO


-- Create the database snapshot
CREATE DATABASE SnapshotDBName  ON
( 
NAME = OrigDB, --der logische Name der Datendatei der OrigDB
FILENAME = 'C:\_SQLDB\SnapshotDBName.mdf' )
AS SNAPSHOT OF OrigDB;
GO

CREATE DATABASE SN_Northwind_1152 ON
(
NAME= Northwind,
FILENAME = 'C:\_SQLDB\SN_Northwind_1152.mdf'
)
AS SNAPSHOT OF Northwind;
GO



USE MASTER


RESTORE DATABASE NORTHWIND from database_Snapshot = 'SN_Northwind_1152' 






		