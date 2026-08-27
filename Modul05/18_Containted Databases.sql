/*
================================================================================
  Modul 05 – Eigenständige Datenbanken (Contained Databases)
================================================================================
  Eine eigenständige Datenbank (Contained Database) speichert Benutzer und
  deren Authentifizierungsdaten direkt in der Datenbank – unabhängig vom
  SQL Server-Login auf Serverebene. Dadurch kann die Datenbank einfacher
  auf andere Server verschoben werden (keine Abhängigkeit zu Server-Logins).

  Containment-Typen:
  - NONE (Standard): Keine Eigenständigkeit – klassische Konfiguration
  - PARTIAL:         Benutzer können sich direkt an der Datenbank anmelden

  Vorteile:
  - Portabilität: Datenbank inkl. Benutzer verschieben ohne SID-Probleme
  - Einfachere Verwaltung bei Datenbankwechseln zwischen Servern

  Einschränkungen und wichtige Hinweise:
  - Keine Kerberos-Authentifizierung möglich
  - Keine Replikation, kein CDC/CDT, keine temporären Prozeduren
  - Datenbankübergreifende Zugriffe: Datenbank muss als TRUSTWORTHY markiert sein
  - Beim Anfügen: Zugriff auf Restricted User stellen (ungewollte Zugriffe vermeiden)
  - Vorsicht: Logins mit gleichem Namen wie Contained-DB-Benutzer vermeiden!

  Aktivierung auf dem Server (einmalig notwendig):
  - sp_configure 'contained database authentication' = 1
================================================================================
*/

-- ============================================================================
-- Eigenständige Datenbanken auf dem Server aktivieren
-- ============================================================================
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
GO

EXEC sp_configure 'contained database authentication', 1;
RECONFIGURE;
GO

-- ============================================================================
-- Datenbank auf Partial-Containment umstellen
-- ============================================================================
USE [master];
GO

ALTER DATABASE [Accounting] SET CONTAINMENT = PARTIAL;
GO

-- ============================================================================
-- Datenbankübergreifende Zugriffe erlauben (falls benötigt)
-- ============================================================================
-- Vorsicht: Nur aktivieren wenn wirklich notwendig!
-- ALTER DATABASE ContDB SET TRUSTWORTHY ON;

-- ============================================================================
-- Contained-Datenbankbenutzer erstellen
-- ============================================================================
-- Benutzer wird direkt in der Datenbank erstellt (kein Server-Login notwendig)
USE ContainedDatabase;
GO

CREATE USER Theo WITH PASSWORD = 'Geheim4711!';
GO

-- ============================================================================
-- Bestehende Datenbankbenutzer zu Contained-Benutzern migrieren
-- ============================================================================
-- sp_migrate_user_to_contained:
-- - keep_name:     Benutzername bleibt unverändert
-- - disable_login: Das zugehörige Server-Login wird deaktiviert

EXECUTE sp_migrate_user_to_contained
    @username     = N'Theo',
    @rename       = N'keep_name',
    @disablelogin = N'disable_login';
GO

-- ============================================================================
-- Alle Datenbankbenutzer automatisch migrieren (Cursor-Beispiel)
-- ============================================================================
USE ContainedDatabase;
GO

DECLARE @username SYSNAME;

DECLARE user_cursor CURSOR FOR
    SELECT dp.name
    FROM   sys.database_principals AS dp
    JOIN   sys.server_principals   AS sp ON dp.sid = sp.sid
    WHERE  dp.authentication_type = 1   -- SQL-Authentifizierung
      AND  sp.is_disabled = 0;          -- Nur aktive Logins

OPEN user_cursor;
FETCH NEXT FROM user_cursor INTO @username;

WHILE @@FETCH_STATUS = 0
BEGIN
    EXECUTE sp_migrate_user_to_contained
        @username     = @username,
        @rename       = N'keep_name',
        @disablelogin = N'disable_login';

    FETCH NEXT FROM user_cursor INTO @username;
END;

CLOSE user_cursor;
DEALLOCATE user_cursor;
GO

-- ============================================================================
-- Unkontrollierte (nicht eigenständige) Objekte prüfen
-- ============================================================================
-- Zeigt Objekte in der Datenbank, die externe Abhängigkeiten haben
-- (z. B. Views, die auf andere Datenbanken zugreifen → nicht contained!)
USE ContainedDatabase;
GO

SELECT  so.name AS ObjektName,
        ue.*
FROM    sys.dm_db_uncontained_entities AS ue
LEFT JOIN sys.objects AS so ON ue.major_id = so.object_id;
GO

-- Beispiel für eine View mit datenbanküberschreitendem Zugriff (problematisch!):
-- CREATE VIEW vwTorten
-- AS
-- SELECT * FROM TonisTortenTraum..TortenSatz;
-- → Diese View wäre NICHT contained, da sie auf eine andere DB zugreift!
