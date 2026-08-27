/*
================================================================================
  Modul 06 – Verwaiste Datenbankbenutzer (Orphaned Users) beheben
================================================================================
  Ein verwaister Benutzer (Orphaned User) ist ein Datenbankbenutzer, dessen
  zugehöriges Server-Login nicht mehr existiert oder eine andere SID besitzt.
  Dies passiert typischerweise bei:
  - Migration einer Datenbank auf einen neuen Server
  - Löschen und Neuanlegen eines SQL Server-Logins (neue SID!)
  - Wiederherstellung einer Datenbank auf einem anderen Server

  Lösungsansätze:
  A) Neues Login anlegen (neue SID) → User-Mapping schlägt fehl (Name existiert in DB)
  B) Neues Login anlegen und SID des Datenbankbenutzers anpassen (sp_change_users_login)
  C) Datenbankbenutzer löschen, neues Login anlegen, Benutzer neu erstellen (empfohlen)

  Empfehlung für Option C (sauberste Lösung):
  - Datenbankbenutzer löschen
  - Neues Login anlegen (neues Kennwort vergeben!)
  - Benutzer neu erstellen und Rollen neu zuweisen

  Werkzeuge:
  - sp_change_users_login  (veraltet, aber noch verwendbar)
  - sp_help_revlogin       (von Microsoft verfügbar, muss importiert werden)
  - dbatools (PowerShell)  → Export-DbaLogin / Sync-DbaLoginPermission
================================================================================
*/

-- ============================================================================
-- Bestandsanalyse: Verwaiste Benutzer in der aktuellen Datenbank anzeigen
-- ============================================================================
USE whoamiDB;
GO

-- Alle verwaisten Benutzer anzeigen (kein passendes Server-Login vorhanden)
EXEC sp_change_users_login 'Report';

-- ============================================================================
-- Option A: Automatische Reparatur (Auto_Fix)
-- ============================================================================
-- Sucht ein gleichnamiges Login und verknüpft es, oder legt ein neues an.
-- Achtung: Das Kennwort wird als Parameter übergeben – nur für SQL-Logins!
EXEC sp_change_users_login 'Auto_Fix', 'jamesbond', NULL, 'ppedv2019!';

-- ============================================================================
-- Option B: Benutzer mit einem anderen Login verknüpfen (SID-Update)
-- ============================================================================
-- Verknüpft den Datenbankbenutzer 'JamesBond' mit dem Server-Login 'JamesBond'
-- (Aktualisiert die SID des Datenbankbenutzers auf die SID des Logins)
EXEC sp_change_users_login 'Update_One', 'JamesBond', 'JamesBond';

-- ============================================================================
-- Option C: Sauberste Lösung – Benutzer löschen und neu anlegen
-- ============================================================================

-- Schritt 1: Datenbankbenutzer löschen
USE [whoamiDB];
GO
DROP USER [JamesBond];
GO

-- Schritt 2: Neues Login auf Serverebene anlegen (mit neuem Kennwort!)
USE [master];
GO
CREATE LOGIN [JamesBond]
    WITH PASSWORD         = 'NeuesSicheresKennwort!2024',
         DEFAULT_DATABASE = [whoamiDB],
         CHECK_EXPIRATION = OFF,
         CHECK_POLICY     = OFF;
GO

-- Schritt 3: Datenbankbenutzer neu erstellen und Rollen zuweisen
USE [whoamiDB];
GO
CREATE USER [JamesBond] FOR LOGIN [JamesBond];
ALTER USER  [JamesBond] WITH DEFAULT_SCHEMA = [dbo];
ALTER ROLE  [Personalabteilung] ADD MEMBER [JamesBond];
GO

-- ============================================================================
-- Logins mit SID auf anderen Server übertragen
-- ============================================================================
-- sp_help_revlogin gibt SQL-Skripte zum Neu-Erstellen der Logins aus
-- (inkl. Original-SID und Kennwort-Hash → SID-Problem wird vermieden!)
-- Muss von Microsoft heruntergeladen werden.
-- EXEC sp_help_revlogin;

-- Automatisierung per SQLCMD:
-- sqlcmd -S. -E -d master -Q "EXEC sp_help_revlogin" > C:\logins.sql

-- Alternative mit PowerShell (dbatools):
-- Export-DbaLogin -SqlInstance Server1 | Out-File C:\logins.sql

-- ============================================================================
-- Verwaiste Benutzer anzeigen (aktuelle SIDs vergleichen)
-- ============================================================================
SELECT * FROM sysusers;
-- Zeigt SIDs aller Datenbankbenutzer
-- Vergleich mit sys.server_principals (Serverebene) zeigt Orphans
