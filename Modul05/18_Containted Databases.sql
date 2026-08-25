--KOnfig auf dem Server
--Erweitert: Eigenständige DB auf true
EXEC SP_CONFIGURE 'show advanced options', 1;
RECONFIGURE;
GO
EXEC SP_CONFIGURE 'contained database authentication', 1;
RECONFIGURE;

/*
Datenbankübergreifende Zugriffe?
Ja, das ist möglich. Notwendig dazu ist, dass die Contained Database auf vertrauenswürdig gesetzt ist:

ALTER DATABASE ContDB SET TRUSTWORTHY ON
--------------*/

USE [master]
GO
ALTER DATABASE [Accounting] SET CONTAINMENT = PARTIAL
GO
/*
Einschränkungen und Tipps
Vermeiden Sie Logins mit gleichen Namen wie der Contained DB Benutzer. Falls doch, dann ändern sie beim Login die Standarddatenbank so, dass nicht gleich auf die ContDB zugegriffen wird. Sonst gibts Fehler bei der Anmeldung.
keine Kerberos Authentifizierung möglich
beim Anfügen einer Datenbank den Zugriff auf Restricted User stellen, um nicht unegwollte zugriffe auf dem SQL Server zu haben.
keine Replikation
kein CDT und CDC
keine temporären Prozeduren
*/
USE ContainedDatabase;

CREATE USER Theo WITH PASSWORD = 'Geheim4711';

EXECUTE sp_migrate_user_to_contained 
    @username = N'Theo', 
    @rename = N'keep_name',
    @disablelogin = N'disable_login';


USE ContainedDatabase;

DECLARE @username sysname ;
DECLARE user_cursor CURSOR
    FOR 
        SELECT dp.name 
        FROM sys.database_principals AS dp
        JOIN sys.server_principals AS sp 
        ON dp.sid = sp.sid
        WHERE dp.authentication_type = 1 AND sp.is_disabled = 0;
OPEN user_cursor
FETCH NEXT FROM user_cursor INTO @username
    WHILE @@FETCH_STATUS = 0
    BEGIN
        EXECUTE sp_migrate_user_to_contained 
        @username = @username,
        @rename = N'keep_name',
        @disablelogin = N'disable_login';
    FETCH NEXT FROM user_cursor INTO @username
    END
CLOSE user_cursor ;
DEALLOCATE user_cursor ;


USE ContainedDatabase;

-- Join mit sys.objects, um den Namen des Objekts ausgeben zu können
SELECT SO.name, UE.* FROM sys.dm_db_uncontained_entities AS UE
LEFT JOIN sys.objects AS SO
    ON UE.major_id = SO.object_id;

CREATE VIEW vwTorten
AS
SELECT * FROM TonisTortenTraum..TortenSatz