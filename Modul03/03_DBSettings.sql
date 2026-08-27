/*
================================================================================
  Modul 03 – Datenbank-Einstellungen und Optimierungsoptionen
================================================================================
  Dieses Skript zeigt verschiedene ALTER DATABASE-Einstellungen, die das
  Verhalten und die Performance einer SQL Server-Datenbank beeinflussen.

  Themen:
  - AUTO_CREATE_STATISTICS INCREMENTAL: Inkrementelle Statistiken für partitionierte Tabellen
  - DATE_CORRELATION_OPTIMIZATION: Optimierung bei korrelierten Datumsfeldern
  - DELAYED_DURABILITY: Verzögertes Schreiben ins Transaktionsprotokoll
  - MAXDOP (Datenbankebene): Parallelisierungsgrad pro Datenbank
  - QUERY_OPTIMIZER_HOTFIXES: Aktiviert neueste Optimizer-Korrekturen
  - ALLOW_SNAPSHOT_ISOLATION / READ_COMMITTED_SNAPSHOT: Optimistische Sperrstrategie
  - CLEAR PROCEDURE_CACHE: Plan-Cache gezielt leeren

  Alle Einstellungen gelten für die Datenbank "Northwind" (Demo-Datenbank).
================================================================================
*/

USE [master];
GO

-- ============================================================================
-- Inkrementelle Statistiken (für partitionierte Tabellen)
-- ============================================================================
-- INCREMENTAL = ON: Statistiken werden pro Partition getrennt gespeichert
-- → Bei Aktualisierungen werden nur die geänderten Partitionen neu berechnet
-- → Deutlich schnellere Statistik-Updates bei großen Tabellen
-- → Reduziert I/O und CPU beim Wartungsfenster
ALTER DATABASE [Northwind]
    SET AUTO_CREATE_STATISTICS ON (INCREMENTAL = ON);

-- Manuelles Update einer einzelnen Partition (Beispiel):
-- UPDATE STATISTICS [dbo].[Record] idx_record_name WITH RESAMPLE ON PARTITIONS (1);

-- ============================================================================
-- Datumskorrelations-Optimierung
-- ============================================================================
-- SQL Server erkennt Abhängigkeiten zwischen Datumsfeldern:
-- Beispiel: Termin2 liegt immer 14 Tage nach Termin1
-- → SQL Server erstellt spezielle Statistiken für diese Korrelation
-- → Abfragepläne werden genauer → effizienterer Datenzugriff
ALTER DATABASE [Northwind]
    SET DATE_CORRELATION_OPTIMIZATION ON WITH NO_WAIT;
GO

-- ============================================================================
-- Verzögerte Dauerhaftigkeit (Delayed Durability)
-- ============================================================================
-- Standard: Ein COMMIT ist erst dann abgeschlossen, wenn die TX ins T-Log
--           geschrieben wurde (SYNCHRON → sicher, aber langsam).
--
-- ALLOWED: Der Client erhält ein Commit-Signal, bevor die TX physisch ins
--          Log geschrieben wurde (ASYNCHRON → schneller, minimales Verlustrisiko).
--
-- Vorteile:
--   - Geringere Latenzzeit bei intensiven Schreibvorgängen
--   - Batchweises Schreiben → weniger Datenträgerkonflikte bei vielen TX
--
-- Einschränkungen / Risiken:
--   - Datenverlust bei Server-Absturz vor dem physischen Schreiben möglich
--   - Nicht geeignet für: Always On Availability Groups, gespiegelte DBs,
--     Datenbanken mit kritischen Konsistenzanforderungen
--
-- Wann sinnvoll?
--   → Hohe Konfliktrate bei Schreibvorgängen ins Log
--   → Engpässe beim Schreiben ins Transaktionsprotokoll
--   → Datenverlust in geringem Umfang ist vertretbar (z. B. Telemetrie)
--
-- Manuelles Leeren des verzögerten Logs (auf Anforderung):
-- EXECUTE sys.sp_flush_log;
ALTER DATABASE [Northwind]
    SET DELAYED_DURABILITY = ALLOWED WITH NO_WAIT;
GO

-- ============================================================================
-- MAXDOP auf Datenbankebene
-- ============================================================================
-- Überschreibt die Server-Einstellung für diese Datenbank
-- Wert 4: Diese Datenbank nutzt maximal 4 Kerne pro Abfrage
ALTER DATABASE SCOPED CONFIGURATION SET MAXDOP = 4;
GO

-- ============================================================================
-- Query Optimizer Hotfixes aktivieren
-- ============================================================================
-- Entspricht dem Aktivieren des Traceflags 4199.
-- Aktiviert Optimizer-Korrekturen, die nach dem Release eingeführt wurden.
-- → Empfohlen für Produktionssysteme nach ausgiebigen Tests
ALTER DATABASE SCOPED CONFIGURATION SET QUERY_OPTIMIZER_HOTFIXES = ON;
GO

-- ============================================================================
-- Snapshot-Isolation aktivieren
-- ============================================================================
-- Ermöglicht, dass Lesevorgänge nicht durch Schreibvorgänge blockiert werden.
-- Änderungen werden als Versionen in die tempdb kopiert.
-- → Vorteil: Keine gegenseitigen Blockierungen bei Lesen/Schreiben
-- → Nachteil: Erhöhte Last auf der tempdb (Versionsspeicher!)
ALTER DATABASE [Northwind]
    SET ALLOW_SNAPSHOT_ISOLATION ON;
GO

-- READ_COMMITTED_SNAPSHOT aktivieren
-- → Alle Lese-Transaktionen (READ COMMITTED) arbeiten mit Versionen
-- → Kein Locking zwischen Lesern und Schreibern
-- Voraussetzung: Keine aktiven Verbindungen zur Datenbank beim Ändern
ALTER DATABASE [Northwind]
    SET READ_COMMITTED_SNAPSHOT ON WITH NO_WAIT;
GO

-- ============================================================================
-- Plan-Cache für diese Datenbank leeren
-- ============================================================================
-- Löscht nur den Plan-Cache der aktuellen Datenbank (gezielt und sicher).
-- Alternative: DBCC FREEPROCCACHE → leert den GESAMTEN Server-Plan-Cache!
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
