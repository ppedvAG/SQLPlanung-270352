/*
================================================================================
  Modul 10 – Query Store (Abfragespeicher)
================================================================================
  Der Query Store ist ein Feature in SQL Server (ab Version 2016), das pro
  Datenbank Abfragen, Ausführungspläne und Laufzeitstatistiken speichert.
  Die Daten bleiben auch nach einem Neustart des Servers erhalten.

  Hauptfunktionen:
  - Abfrageleistung im Zeitverlauf verfolgen
  - Ausführungsplan-Regression erkennen und beheben (Plan Forcing)
  - Automatisches Plan-Forcing bei Regression (ab SQL Server 2017)
  - Diagnose von CPU-, RAM- und I/O-Engpässen pro Abfrage
  - Verlaufsspeicherung über Datenbankneustarts hinweg

  Architektur:
  - Daten werden direkt IN der Datenbank gespeichert (nicht in der msdb)
  - Query Text:          Der SQL-Text der Abfrage
  - Execution Plans:     Die verwendeten Ausführungspläne
  - Runtime Statistics:  Ausführungsdauer, CPU, Speicher, I/O

  Typischer Workflow:
  1. Query Store auf der Datenbank aktivieren
  2. Leistungsdaten über einen Zeitraum sammeln
  3. Abfragen mit schlechter Leistung oder Plan-Regressionen identifizieren
  4. Besseren Plan erzwingen (Plan Forcing) oder Abfrage optimieren

  Vorteile:
  - Historische Leistungsdaten (nicht nur aktueller Zeitpunkt)
  - Transparenz über Planänderungen durch Statistik-Updates oder Upgrades
  - Plan-Forcing ohne Datenbankänderungen oder Neustart möglich

  Hinweis: Der Query Store kann auch als Datenquelle für den
  Datenbankoptimierungsratgeber (DTA) verwendet werden.
================================================================================
*/

-- ============================================================================
-- Query Store für eine Datenbank aktivieren
-- ============================================================================
USE [master];
GO

ALTER DATABASE [Northwind] SET QUERY_STORE = ON;
GO

-- ============================================================================
-- Query Store konfigurieren
-- ============================================================================
ALTER DATABASE [Northwind] SET QUERY_STORE
(
    OPERATION_MODE          = READ_WRITE,   -- Aktiv (READ_ONLY zum Einfrieren)
    CLEANUP_POLICY          = (STALE_QUERY_THRESHOLD_DAYS = 30),  -- Daten 30 Tage behalten
    DATA_FLUSH_INTERVAL_SECONDS = 900,      -- Alle 15 min in DB schreiben
    INTERVAL_LENGTH_MINUTES = 60,           -- Statistikintervall: 1 Stunde
    MAX_STORAGE_SIZE_MB     = 500,          -- Maximale Größe: 500 MB
    QUERY_CAPTURE_MODE      = AUTO,         -- Nur relevante Abfragen erfassen
    SIZE_BASED_CLEANUP_MODE = AUTO          -- Alte Daten automatisch bereinigen
);
GO

-- ============================================================================
-- Query Store Status anzeigen
-- ============================================================================
SELECT *
FROM   sys.database_query_store_options;

-- ============================================================================
-- Teuerste Abfragen anzeigen (Top 10 nach CPU-Zeit)
-- ============================================================================
SELECT TOP (10)
    q.query_id,
    qt.query_sql_text                        AS AbfrageText,
    SUM(rs.avg_cpu_time)                     AS GesamtCPU_ms,
    SUM(rs.avg_duration)                     AS GesamtDauer_ms,
    SUM(rs.avg_logical_io_reads)             AS DurchschnittIO,
    COUNT(rs.execution_count)                AS Planvarianten
FROM       sys.query_store_query_text  AS qt
JOIN       sys.query_store_query       AS q  ON qt.query_text_id = q.query_text_id
JOIN       sys.query_store_plan        AS p  ON q.query_id       = p.query_id
JOIN       sys.query_store_runtime_stats AS rs ON p.plan_id      = rs.plan_id
GROUP BY   q.query_id, qt.query_sql_text
ORDER BY   GesamtCPU_ms DESC;

-- ============================================================================
-- Plan Forcing: Besten Plan für eine Abfrage erzwingen
-- ============================================================================
-- @query_id = ID der Abfrage aus sys.query_store_query
-- @plan_id  = ID des gewünschten Plans aus sys.query_store_plan
EXEC sys.sp_query_store_force_plan
    @query_id = 42,   -- Beispiel-ID anpassen!
    @plan_id  = 7;    -- Beispiel-ID anpassen!

-- Plan-Forcing rückgängig machen
-- EXEC sys.sp_query_store_unforce_plan @query_id = 42, @plan_id = 7;

-- ============================================================================
-- Query Store zurücksetzen (alle Daten löschen)
-- ============================================================================
-- ACHTUNG: Löscht alle gespeicherten Abfragen und Statistiken!
-- ALTER DATABASE [Northwind] SET QUERY_STORE CLEAR;
