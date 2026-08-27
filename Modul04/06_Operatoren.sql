/*
================================================================================
  Modul 04 – SQL Server Agent: Operatoren konfigurieren
================================================================================
  Operatoren sind benannte Kontakte (Alias für E-Mail-Adressen oder Pager),
  die innerhalb des SQL Server Agents als Empfänger für Benachrichtigungen
  verwendet werden. Ohne einen konfigurierten Operator können Jobs und
  Warnungen keine E-Mail-Benachrichtigungen verschicken.

  Typischer Anwendungsfall:
  - Ein Job schlägt fehl → Der konfigurierte Operator erhält eine E-Mail
  - Eine Warnung wird ausgelöst → Benachrichtigung an zuständigen Admin

  Voraussetzungen für den Versand:
  1. Operator anlegen (diese Datei)
  2. Datenbank-E-Mail konfigurieren (08_Dababasemail.sql)
  3. SQL Agent: Warnungssystem → Mailprofil zuweisen + Agent neustarten
  4. Dem Operator im Job oder in der Warnung als Empfänger eintragen

  Hinweis: Operatoren werden in der msdb-Datenbank gespeichert.
================================================================================
*/

USE [msdb];
GO

-- ============================================================================
-- Operator anlegen
-- ============================================================================
-- @name         = Anzeigename des Operators (erscheint im SSMS)
-- @enabled      = 1 → Operator ist aktiv
-- @pager_days   = 0 → keine Pager-Benachrichtigung
-- @email_address = Ziel-E-Mail-Adresse für Benachrichtigungen
EXEC msdb.dbo.sp_add_operator
    @name          = N'SQLAdmins',
    @enabled       = 1,
    @pager_days    = 0,
    @email_address = N'andreasr@ppedv.de';
GO
