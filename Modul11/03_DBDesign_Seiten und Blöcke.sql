/*
  Thema: DB-Design mit Seiten und Blöcken in SQL Server.
  Diese Datei erklärt die physische Speicherung von Daten auf der Festplatte.
  Eine Seite ist die kleinste I/O-Einheit und hat in SQL Server 8 KB.
  Mehrere zusammenhängende Seiten bilden einen Block (Extent).
  Wenn Datensätze zu breit sind, passen weniger Zeilen auf eine Seite.
  Dann steigen Seitenanzahl, Speicherbedarf und Leseaufwand bei Abfragen.
  Für Anfänger ist wichtig: Logisches Design beeinflusst direkt die Performance.
  Die Abfragen in diesem Skript zeigen, wie man Seitennutzung praktisch untersucht.
  Dazu werden klassische und moderne Analysewerkzeuge gegenübergestellt.
  So wird sichtbar, warum Seitendichte und Layout für schnelle Zugriffe wichtig sind.
*/

-- Seiten und Blöcke – physische Speichereinheiten in SQL Server
/*
  Grundwerte:
  1 Seite = 8.192 Byte (8 KB)
  Nutzbares Datenvolumen pro Seite: max. 8.072 Byte
  Ein Datensatz mit fixen Längen darf max. 8.060 Byte groß sein
    und muss in eine einzige Seite passen.
  Max. ca. 700 Datensätze pro Seite (bei kleinen Datensätzen)

  8 zusammenhängende Seiten = 1 Block (Extent = 64 KB)

  Seite = Page
  Block = Extent

  SQL Server kann nur mit einem Thread eine Seite gleichzeitig lesen.
  Greifen zwei Threads zur gleichen Zeit auf dieselbe Seite zu → Latch oder Spinlock:
    - Latch    = Thread wird suspendiert (passiv wartend, kein CPU-Verbrauch)
    - Spinlock = Thread wartet aktiv (CPU-intensiv!)
*/

USE northwind;
GO

-- Tabelle mit sehr breiten Zeilen anlegen (jede Zeile füllt fast eine ganze Seite)
-- char(4100) = 4.100 Byte → eine Seite fasst nur 1 Zeile
CREATE TABLE t1
(
    id  INT      IDENTITY,   -- automatisch hochzählender Primärschlüssel
    spx CHAR(4100)           -- bewusst breite Spalte für Demonstrationszwecke
);
GO

-- 20.000 Zeilen einfügen (Zeit messen!)
-- Erwartet: ca. 160 MB auf Festplatte, obwohl Daten nur ~80 MB groß sind
INSERT INTO t1
SELECT 'XY';
GO 20000

-- Veraltete Methode: dbcc showcontig (deprecated seit SQL Server 2005)
-- Zeigt Fragmentierungsgrad und Seitenauslastung
DBCC SHOWCONTIG('t1');

-- Moderne Methode (empfohlen ab SQL Server 2005):
-- sys.dm_db_index_physical_stats liefert detaillierte Seiteninformationen
-- avg_page_space_used_in_percent = durchschnittliche Auslastung der Seiten
SELECT *
FROM sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID('t1'), NULL, NULL, 'detailed');
GO

-- Erklärung der Phänomene:
-- Warum hat t1 ca. 160 MB, obwohl die eigentlichen Daten nur ~80 MB groß sind?
--   → char(4100) füllt fast eine ganze Seite (8 KB), auch wenn nur 2 Zeichen gespeichert sind.
--   → Die Seiten sind nur zu ~50 % gefüllt → doppelter Platzbedarf.

-- Warum liest eine Abfrage auf KU 57.000 Seiten, obwohl dbcc nur 41.000 zeigt?
--   → Forwarded Records: Datensätze wurden durch ALTER TABLE ADD COLUMN verschoben.
--   → Der ursprüngliche Slot zeigt nur noch als Zeiger auf die neue Position
--     → pro Datensatz ein zusätzlicher Seitenzugriff!
