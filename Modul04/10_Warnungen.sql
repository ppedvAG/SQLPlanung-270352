/*
================================================================================
  Modul 04 – SQL Server Agent: Warnungen (Alerts) konfigurieren
================================================================================
  SQL Server Alerts sind automatische Benachrichtigungs- und Reaktionsmechanismen
  des SQL Server Agents. Sie überwachen das System kontinuierlich und lösen
  definierte Aktionen aus, sobald ein Fehler oder Schwellenwert erreicht wird.

  Alert-Typen im Überblick:
  ┌──────────────────────────┬────────────────────────────────────────────────┐
  │ SQL Server Event Alert   │ Reagiert auf Einträge im Windows-Ereignislog   │
  │                          │ basierend auf Fehlernummer oder Schweregrad.   │
  │ Performance Condition    │ Löst aus, wenn ein Leistungsindikator einen    │
  │ Alert                    │ definierten Schwellenwert über-/unterschreitet.│
  │ WMI Event Alert          │ Reagiert auf Systemereignisse über WMI         │
  │                          │ (z. B. Schema-Änderungen, Deadlocks).          │
  └──────────────────────────┴────────────────────────────────────────────────┘

  Schweregrad-Ebenen (Severity Levels):
  - Ebene  1-10 : Informationen und Erfolgsmeldungen (kein Handlungsbedarf)
  - Ebene 14    : Sicherheitsrechtfehler (fehlende Berechtigungen)
  - Ebene 15    : Syntaxfehler (falsches T-SQL)
  - Ebene 16    : Objekt nicht gefunden (Tabelle, Sicht usw. existiert nicht)
  - Ebene 17+   : Admin-relevante Fehler (Ressourcen zu gering, I/O-Probleme)
  - Ebene 23-24 : Schwere Datenbankfehler
  - Ebene 25    : Höchste Kategorie – Systemausfall steht unmittelbar bevor

  Empfehlung: Alerts für Ebenen 17-25 anlegen und an einen Operator senden.
================================================================================
*/

-- ============================================================================
-- Fehlermeldungen in Deutsch anzeigen (Sprach-ID 1031 = Deutsch)
-- ============================================================================
SELECT *
FROM   sysmessages
WHERE  msgLangid = 1031
ORDER BY severity DESC;

-- ============================================================================
-- Beispiel: Warnung für Sicherheitsfehler in der Northwind-Datenbank
-- ============================================================================
-- Diese Warnung reagiert auf alle Fehler der Ebene 14 (Zugriff verweigert)
-- in der Northwind-Datenbank.
USE [msdb];
GO

EXEC msdb.dbo.sp_add_alert
    @name                       = N'Security_Nwind_AccessDenied',
    @message_id                 = 0,          -- 0 = alle Fehlernummern dieser Ebene
    @severity                   = 14,         -- Ebene 14 = Sicherheitsrechtfehler
    @enabled                    = 1,
    @delay_between_responses    = 0,          -- Sekunden zwischen Benachrichtigungen
    @include_event_description_in = 0,
    @database_name              = N'Northwind',
    @category_name              = N'[Uncategorized]',
    @job_id                     = N'00000000-0000-0000-0000-000000000000';  -- Kein Job
GO

-- ============================================================================
-- Fehler-Simulation zum Testen der Warnungen
-- ============================================================================

-- Ebene 15: Syntaxfehler (fehlendes FROM)
-- SELECT FROM test;

-- Ebene 16: Objekt nicht gefunden
-- SELECT * FROM nichtvorhandenTabelle;
