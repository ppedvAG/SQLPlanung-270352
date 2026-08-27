/*
================================================================================
  Modul 04 – Datenbank-E-Mail (Database Mail) konfigurieren
================================================================================
  Database Mail ist die integrierte E-Mail-Lösung in Microsoft SQL Server.
  Sie ermöglicht der Datenbank-Engine, E-Mail-Nachrichten über SMTP zu senden –
  ganz ohne MAPI-Client oder Outlook auf dem Server.

  Technischer Ablauf:
    T-SQL (sp_send_dbmail)
        ↓
    msdb: Service-Broker-Queue (asynchron!)
        ↓
    DatabaseMail.exe (externer Prozess)
        ↓
    SMTP-Server / Relay / Microsoft 365
        ↓
    Empfänger

  Wichtig: sp_send_dbmail kehrt sofort zurück – der Versand erfolgt asynchron!

  Kernkomponenten:
  - Konten (Accounts): SMTP-Verbindungsinformationen
  - Profile:           Fassen ein oder mehrere Konten zusammen
  - Failover:          Bei Ausfall des primären SMTP → nächstes Konto versuchen
  - Sicherheitsrolle:  DatabaseMailUserRole (msdb) für Sendeberechtigung

  SMTP-Dienste und Besonderheiten:
  ┌──────────────────────┬───────────────────────────────────────────┐
  │ Exchange on-premises │ Eigener Server, anonymes Relay per IP-Rule│
  │ Gmail                │ App-Passwort notwendig (2FA erforderlich) │
  │ Outlook.com / M365   │ Basic Auth oft deaktiviert → SMTP-Relay   │
  └──────────────────────┴───────────────────────────────────────────┘

  Konfigurationsschritte (nach der Installation):
  1. Datenbank-E-Mail-Assistent starten (SSMS: Verwaltung → Datenbank-E-Mail)
  2. Profil und Konto anlegen (SMTP-Zugangsdaten eintragen)
  3. Öffentliches Profil: Mitglied der Rolle DatabaseMailUserRole (msdb)
  4. Agent-Eigenschaften → Warnungssystem → Mailprofil aktivieren
  5. SQL Server Agent neustarten!

  Bekannte Fallstricke:
  - Service Broker muss aktiv sein → sonst keine Mails!
  - Systemparameter prüfen: Maximale Anhangsgröße (Standard 1 MB → auf 10 MB erhöhen)
  - Der GAST-Account in msdb sollte NICHT in DatabaseMailUserRole sein!
  - Öffentliches Profil: Gast wird Mitglied → alle Logins können senden!
================================================================================
*/

-- ============================================================================
-- E-Mail per T-SQL versenden (zum Testen)
-- ============================================================================
USE [msdb];
GO

-- Einfacher Test-E-Mail-Versand
EXEC sp_send_dbmail
    @profile_name  = N'MeinMailProfil',      -- Name des konfigurierten Profils
    @recipients    = N'admin@beispiel.de',   -- Empfänger
    @subject       = N'SQL Server Test-Mail',
    @body          = N'Diese E-Mail wurde automatisch von SQL Server versendet.';
GO

-- ============================================================================
-- Warnungssystem im SQL Agent aktivieren
-- ============================================================================
-- Das Mailprofil muss dem Agent zugewiesen werden, damit Warnungen und Jobs
-- E-Mails versenden können:
-- → SSMS: SQL Server Agent → Eigenschaften → Warnungssystem
--         → E-Mail aktivieren → Profil auswählen → Agent neustarten!

-- ============================================================================
-- Hinweis: Lokaler IIS-SMTP-Server als Relay
-- ============================================================================
-- Lokaler SMTP-Server (IIS):
--   - Zugriff und Relay nur für die IP des SQL Servers erlauben
--   - Smarthost eintragen (FQDN des eigentlichen Mailservers)
-- Verzeichnisstruktur des IIS-SMTP:
--   C:\inetpub\mailroot\
--     drop    → ankommende E-Mails
--     queue   → zu versendende E-Mails
--     badmail → fehlgeschlagene E-Mails
--     pickup  → manuell abgelegte E-Mails zum Versenden
