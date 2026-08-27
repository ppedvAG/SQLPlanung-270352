/*
================================================================================
  Modul 03 – DB-Design: Seiten und Blöcke in SQL Server
================================================================================
  Dieses Skript erläutert die physische Speicherorganisation in SQL Server.
  Das Verständnis von Seiten und Blöcken ist fundamental für Performance-Tuning,
  da I/O-Operationen immer auf Seitenebene stattfinden.

  Grundkonzepte:
  - Seite (Page):  Kleinste I/O-Einheit in SQL Server = 8.192 Byte (8 KB)
                   Davon nutzbar: max. 8.072 Byte für Daten
                   Ein Datensatz mit fixen Längen darf max. 8.060 Byte groß sein.
                   Maximal ca. 700 Datensätze passen auf eine Seite.
  - Block (Extent): 8 zusammenhängende Seiten = 64 KB
                   SQL Server weist Speicher immer in ganzen Blöcken zu.

  Parallelitätsproblem:
  - SQL Server kann mit nur einem Thread auf eine Seite zugreifen.
  - Greifen zwei Threads gleichzeitig zu → Latch oder Spinlock:
    - Latch  = Thread wird suspendiert (passiv wartend)
    - Spinlock = Thread wartet aktiv (CPU-intensiv)

  Praxisrelevanz:
  - Breite Datensätze (z. B. CHAR(4100)) füllen Seiten nicht vollständig aus
  - → Mehr Seiten werden benötigt → mehr I/O → schlechtere Performance
================================================================================
*/

USE northwind;
GO

-- ============================================================================
-- Demo: Breit angelegte Tabelle mit char(4100)
-- ============================================================================
-- Eine Zeile belegt durch char(4100) fast eine ganze Seite (8 KB).
-- Daher passen maximal 1-2 Datensätze pro Seite → viele Seiten nötig.
CREATE TABLE t1
(
    id  INT      IDENTITY,
    spx CHAR(4100)
);
GO

-- 20.000 Zeilen einfügen (Zeit messen!)
INSERT INTO t1
SELECT 'XY';
GO 20000

-- ============================================================================
-- Analyse: Veralteter Weg (dbcc showcontig – deprecated)
-- ============================================================================
-- dbcc showcontig gibt Informationen über Fragmentierung und Seitendichte
-- Hinweis: Tabellenname als String übergeben
DBCC SHOWCONTIG('t1');

-- ============================================================================
-- Analyse: Moderner Weg (empfohlen ab SQL Server 2005)
-- ============================================================================
-- sys.dm_db_index_physical_stats zeigt detaillierte Seiteninformationen:
-- avg_page_space_used_in_percent = durchschnittliche Seitenauslastung
-- forwarded_record_count         = weitergeleitete Datensätze (Heap-Problem)
SELECT *
FROM sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID('t1'), NULL, NULL, 'detailed');
GO

-- ============================================================================
-- Erklärung der Phänomene
-- ============================================================================
-- Warum hat die Tabelle t1 ~160 MB, obwohl die Daten nur ~80 MB groß sind?
--   → char(4100) belegt fast eine ganze Seite, obwohl nur 2 Zeichen gespeichert sind.
--   → Jede Seite ist nur zu ~50 % gefüllt → doppelter Platzbedarf.
--
-- Warum liest man aus der Tabelle KU 57.000 Seiten,
-- obwohl dbcc showcontig nur 41.000 Seiten angibt?
--   → Forwarded Records: Datensätze wurden verschoben (z. B. durch ALTER TABLE ADD COLUMN),
--   → der ursprüngliche Slot zeigt nur noch auf die neue Position → Extra-Seitenzugriffe.
