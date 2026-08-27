/*
================================================================================
  Modul 04 – SQL Server Agent: Jobs, Operatoren, Warnungen und Proxykonten
================================================================================
  Der SQL Server Agent ist ein eigenständiger Windows-Dienst mit eigenem
  Dienstkonto. Er ermöglicht das automatisierte Ausführen von Aufgaben nach
  Zeitplan oder als Reaktion auf Ereignisse.

  Funktionen des SQL Server Agents:
  - Jobs (Aufträge):        Mehrstufige Aufgaben mit Ausführungslogik
  - Zeitpläne:              Wann soll ein Job ausgeführt werden?
  - Warnungen (Alerts):     Automatische Reaktion auf Fehler oder Schwellenwerte
  - Operatoren:             Benannte Empfänger für Benachrichtigungen
  - Datenbank-E-Mail:       Versand von E-Mails über SMTP
  - Proxykonten:            Ausführen von Jobschritten unter anderem Konto

  Wichtig: Lokale Standardordner des SQL Servers haben keine Vererbung aktiv.
  → Für Netzwerk-Backup-Pfade (\\NAS\Backup) ein Domänenkonto als
    Agent-Dienstkonto verwenden (DOMAIN\sqlAgent statt NT SERVICE\sqlAgent).
================================================================================
*/

-- ============================================================================
-- Operator anlegen (Kontakt für Benachrichtigungen)
-- ============================================================================
USE [msdb];
GO

EXEC msdb.dbo.sp_add_operator
    @name          = N'SQLAdministrator',
    @enabled       = 1,
    @pager_days    = 0,
    @email_address = N'sqlservice@sql.local';
GO

-- ============================================================================
-- Datenbank-E-Mail (Überblick)
-- ============================================================================
-- Voraussetzung: Funktionierender SMTP-Server
-- Konfigurationsschritte:
--   1. E-Mail-Profil anlegen (SMTP-Zugangsdaten)
--   2. SMTP-Zugangsdaten: Relay nur für SQL Server IP erlauben (127.0.0.1 oder Server-IP)
--   3. Profil als öffentlich konfigurieren (Mitglied: msdb/DatabaseMailUserRole)
--
-- E-Mail per T-SQL senden (zum Testen):
-- EXEC sp_send_dbmail [Profilname];

-- ============================================================================
-- Warnungs-Ebenen (Alert Severity Levels)
-- ============================================================================
-- Ebene  9-10 : Information / Erfolg (kein Handlungsbedarf)
-- Ebene 14    : Sicherheitsrechtfehler (fehlende Berechtigungen)
-- Ebene 15    : T-SQL-Syntaxfehler (falsches SQL)
-- Ebene 16    : Objekt nicht gefunden (Tabelle, Sicht o. ä. existiert nicht)
-- Ebene 17+   : Administrativer Handlungsbedarf (Ressourcen zu gering)
-- Ebene 25    : Höchste Kategorie – Systemausfall steht bevor

-- Systemsicht für Fehlermeldungen in Deutsch (Sprach-ID 1031)
SELECT *
FROM   sysmessages
WHERE  msglangid = 1031
ORDER BY severity DESC;

-- ============================================================================
-- Beispiel: Fehler durch fehlende Tabellen (mit Ebenenkennzeichnung)
-- ============================================================================

-- Fehler Ebene 15: Syntaxfehler (fehlendes FROM-Schlüsselwort)
-- SELECT FROM test;
-- → Meldung 102, Ebene 15, Status 1

-- Fehler Ebene 16: Objekt nicht gefunden
-- SELECT * FROM t2;  -- Fehler Ebene 16 (zum Testen ausführen)
-- → Meldung 208, Ebene 16, Status 1

-- ============================================================================
-- Was tun, damit nach einem Job eine E-Mail versendet wird?
-- ============================================================================
-- Schritt 1: Operator anlegen (hat eine E-Mail-Adresse)
-- Schritt 2: Datenbank-E-Mail konfigurieren (SMTP-Zugangsdaten)
-- Schritt 3: Agent-Eigenschaften → Warnungssystem → Mailprofil aktivieren
-- Schritt 4: SQL Server Agent neustarten (damit das Profil greift)
-- Schritt 5: Im Job/Warnung den Operator als Empfänger eintragen

-- ============================================================================
-- Proxykonten (für Jobschritte mit erhöhten Rechten)
-- ============================================================================
-- Problem: Der Agent besitzt oft keine Rechte auf externe Systeme
--          (CMD, PowerShell, SSAS, Replikation, SSIS usw.)
-- Lösung:  Proxykonto anlegen – kein Bedarf, den Agent zum Domain-Admin zu machen!
--
-- Vorgehensweise:
--   1. Sicherheit → Anmeldeinformationen: Domänenkonto (Name + Kennwort) hinterlegen
--   2. SQL Agent → Proxykonten: Anmeldeinformation einem Subsystem zuweisen
--   3. Im Auftragsschritt: gewünschtes Subsystem + Proxykonto auswählen

-- Proxykonto für PowerShell-Schritte erstellen
USE [msdb];
GO

EXEC msdb.dbo.sp_add_proxy
    @proxy_name     = N'PS_DomainAdmin',
    @credential_name = N'DomAdmin',
    @enabled        = 1;
GO

-- Proxykonto dem Subsystem "PowerShell" (ID 12) zuweisen
EXEC msdb.dbo.sp_grant_proxy_to_subsystem
    @proxy_name   = N'PS_DomainAdmin',
    @subsystem_id = 12;
GO

-- ============================================================================
-- Beispiel: Job-Schritte definieren (bestehenden Job ändern)
-- ============================================================================
-- Schritt 1: T-SQL – gibt Zahl 100 zurück, bei Erfolg weiter zu Schritt 2
EXEC msdb.dbo.sp_add_jobstep
    @job_id              = N'65185120-9aea-446c-ae60-03231b3d4a48',
    @step_name           = N'Gib mir 100',
    @step_id             = 1,
    @cmdexec_success_code = 0,
    @on_success_action   = 3,    -- 3 = nächsten Schritt ausführen
    @on_fail_action      = 2,    -- 2 = Job beenden (Fehler)
    @retry_attempts      = 0,
    @retry_interval      = 0,
    @os_run_priority     = 0,
    @subsystem           = N'TSQL',
    @command             = N'SELECT 100',
    @database_name       = N'master',
    @flags               = 0;
GO

-- Schritt 2: CmdExec – legt Ordner an (mit Proxykonto CMD_Admin)
EXEC msdb.dbo.sp_add_jobstep
    @job_id              = N'65185120-9aea-446c-ae60-03231b3d4a48',
    @step_name           = N'Ordner anlegen',
    @step_id             = 2,
    @cmdexec_success_code = 0,
    @on_success_action   = 3,
    @on_fail_action      = 2,
    @retry_attempts      = 0,
    @retry_interval      = 0,
    @os_run_priority     = 0,
    @subsystem           = N'CmdExec',
    @command             = N'md C:\XXX',
    @flags               = 0,
    @proxy_name          = N'CMD_Admin';
GO

-- Schritt 3: T-SQL – gibt Zahl 300 zurück
EXEC msdb.dbo.sp_add_jobstep
    @job_id              = N'65185120-9aea-446c-ae60-03231b3d4a48',
    @step_name           = N'Gib mir 300',
    @step_id             = 3,
    @cmdexec_success_code = 0,
    @on_success_action   = 3,
    @on_fail_action      = 2,
    @retry_attempts      = 0,
    @retry_interval      = 0,
    @os_run_priority     = 0,
    @subsystem           = N'TSQL',
    @command             = N'SELECT 300',
    @database_name       = N'master',
    @flags               = 0;
GO

-- Schritt 4: Bei Erfolg → Sprung zu Schritt 5 (nicht sequenziell)
EXEC msdb.dbo.sp_add_jobstep
    @job_id               = N'65185120-9aea-446c-ae60-03231b3d4a48',
    @step_name            = N'Gib mir 400',
    @step_id              = 4,
    @cmdexec_success_code = 0,
    @on_success_action    = 4,      -- 4 = springe zu einem bestimmten Schritt
    @on_success_step_id   = 5,
    @on_fail_action       = 2,
    @retry_attempts       = 0,
    @retry_interval       = 0,
    @os_run_priority      = 0,
    @subsystem            = N'TSQL',
    @command              = N'SELECT 400',
    @database_name        = N'master',
    @flags                = 0;
GO

-- Schritt 5: Letzter Schritt – gibt Zahl 500 zurück, Job endet erfolgreich
EXEC msdb.dbo.sp_add_jobstep
    @job_id              = N'65185120-9aea-446c-ae60-03231b3d4a48',
    @step_name           = N'Gib mir 500',
    @step_id             = 5,
    @cmdexec_success_code = 0,
    @on_success_action   = 1,    -- 1 = Job erfolgreich beenden
    @on_fail_action      = 2,
    @retry_attempts      = 0,
    @retry_interval      = 0,
    @os_run_priority     = 0,
    @subsystem           = N'TSQL',
    @command             = N'SELECT 500',
    @database_name       = N'master',
    @flags               = 0;
GO

-- Schritt 6: PowerShell-Schritt mit Proxykonto
EXEC msdb.dbo.sp_add_jobstep
    @job_id              = N'65185120-9aea-446c-ae60-03231b3d4a48',
    @step_name           = N'PowerShell-Schritt',
    @step_id             = 6,
    @cmdexec_success_code = 0,
    @on_success_action   = 1,
    @on_fail_action      = 2,
    @retry_attempts      = 0,
    @retry_interval      = 0,
    @os_run_priority     = 0,
    @subsystem           = N'PowerShell',
    @command             = N'Get-ChildItem',
    @database_name       = N'master',
    @flags               = 0,
    @proxy_name          = N'PS_DomainAdmin';
GO
