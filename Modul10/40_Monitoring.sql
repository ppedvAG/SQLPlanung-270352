/*
================================================================================
  Modul 10 – SQL Server Monitoring und Performance-Diagnose
================================================================================
  Dieses Skript zeigt einen strukturierten Ansatz zur Diagnose von
  SQL Server-Performanceproblemen. Es erläutert, welche Tools wann
  einzusetzen sind und demonstriert die wichtigsten DMV-Abfragen.

  Diagnose-Reihenfolge (von außen nach innen):
  1. Taskmanager: Ausschluss anderer Ursachen (Antivirensoftware, andere Prozesse)
  2. Aktivitätsmonitor: Live-Überblick über SQL Server-Aktivitäten
  3. DMVs: Detaillierte Analyse (Wait Stats, laufende Abfragen, I/O-Statistiken)
  4. Query Store / Verlaufsdaten: Historische Analyse über Zeitraum
  5. Perfmon / Extended Events: Langzeitaufzeichnung und tiefe Diagnose

  Wichtige DMVs für Monitoring:
  - sys.dm_os_wait_stats:         Wartestatistiken (kumulativ seit Neustart)
  - sys.dm_exec_requests:         Aktuell laufende Abfragen
  - sys.dm_exec_sessions:         Alle Verbindungen zum Server
  - sys.dm_db_index_usage_stats:  Nutzungsstatistiken der Indizes
  - sys.dm_io_virtual_file_stats: I/O-Statistiken pro Datenbankdatei

  Hinweis: DMVs werden beim Neustart des SQL Servers zurückgesetzt!
  → Für historische Analysen regelmäßig in eine Monitoring-Tabelle sichern.
================================================================================
*/

-- ============================================================================
-- 1. Wartestatistiken anzeigen (alle, kumulativ seit Neustart)
-- ============================================================================
-- Zeigt alle Wartezustände inkl. systeminterner Idle-Waits.
-- Für gefilterte Auswertung: siehe 10_WAIT_STATS.sql
SELECT *
FROM   sys.dm_os_wait_stats
ORDER BY wait_time_ms DESC;

-- ============================================================================
-- 2. Aktuell laufende Abfragen und Verbindungen anzeigen
-- ============================================================================
-- SPIDs > 50 sind Benutzer-Sessions (< 50 = interne SQL Server-Prozesse)
SELECT *
FROM   sysprocesses
WHERE  spid > 50;

-- ============================================================================
-- 3. I/O- und Zeitstatistiken für einzelne Abfragen messen
-- ============================================================================
-- Aktivieren der detaillierten Ausführungsstatistiken für die aktuelle Session
SET STATISTICS IO,  TIME ON;

-- Beispielabfrage: Bestellungen mit Fracht > 10
SELECT *
FROM   Orders
WHERE  Freight > 10;

-- Beispielabfrage: Abfrage aus einer View
-- SELECT * FROM custorders WHERE id = 100;
-- Erwartete Ausgabe (Beispiel):
--   Seiten: 60.240    CPU-Zeit: 250 ms    Dauer: 128 ms
-- Nach Index-Optimierung:
--   Seiten: 4         CPU-Zeit:   0 ms    Dauer:   0 ms

-- Statistiken wieder deaktivieren
SET STATISTICS IO, TIME OFF;

-- ============================================================================
-- 4. Index-Nutzungsstatistiken
-- ============================================================================
-- Zeigt, wie oft Indizes seit dem letzten Neustart genutzt wurden.
-- Wichtige Spalten:
-- user_seeks:    Anzahl Suchvorgänge (gezielt, effizient → wünschenswert)
-- user_scans:    Anzahl Scanvorgänge (sequenziell → kann verbessert werden)
-- user_lookups:  Anzahl Key Lookups (zusätzliche Seiten gelesen → evtl. Index erweitern)
-- user_updates:  Anzahl Schreibvorgänge auf den Index (je höher, desto teurer!)
SELECT *
FROM   sys.dm_db_index_usage_stats;

-- ============================================================================
-- 5. Wait-Statistiken für Zeitraumvergleiche (Delta-Analyse)
-- ============================================================================
-- Idee: Wartezeiten zu Zeitpunkt T1 und T2 speichern, dann Differenz berechnen
-- Beispiel: LCK_M_S-Werte zu verschiedenen Zeitpunkten:
--
-- Zeit   | wait_time_ms | Differenz
-- --------+--------------+----------
-- 10:00  | 5.894.499    | –
-- 10:10  | 5.894.499    | 0 (keine neuen Sperren)
-- 10:20  | 8.745.766    | 2.851.267 (Sperren zugenommen!)
--
-- So lassen sich Problemzeiträume eingrenzen.

-- ============================================================================
-- 6. Seit wann läuft der SQL Server? (Neustart ermitteln)
-- ============================================================================
-- Die Erstellungszeit der tempdb entspricht dem letzten Neustart
SELECT create_date AS ServerStartZeit
FROM   sys.databases
WHERE  name = 'tempdb';

-- ============================================================================
-- Wichtige DMV-Kategorien
-- ============================================================================
-- sys.dm_os_*   → Betriebssystem- und SQL Server-Interna
-- sys.dm_db_*   → Datenbankbezogene Informationen
-- sys.dm_exec_* → Abfragen, Sessions, Pläne
-- sys.dm_io_*   → I/O-Statistiken
