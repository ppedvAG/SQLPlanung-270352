/*
================================================================================
  Modul 01 – MAXDOP (Maximum Degree of Parallelism)
================================================================================
  MAXDOP steuert, wie viele CPU-Kerne eine einzelne Abfrage maximal nutzen darf.
  SQL Server kann Abfragen parallel über mehrere Kerne verteilen, um sie
  schneller zu berechnen. Dabei gilt: mehr Kerne sind nicht immer schneller –
  der Koordinationsaufwand (Exchange-Operatoren) kostet ebenfalls Zeit.

  Hierarchie der MAXDOP-Einstellungen (von geringster zu höchster Priorität):
    1. Server-Einstellung (sp_configure 'max degree of parallelism')
    2. Datenbank-Einstellung (ALTER DATABASE SCOPED CONFIGURATION SET MAXDOP)
    3. Abfrage-Hint (OPTION (MAXDOP n)) – hat immer Vorrang

  Empfehlung (SQL Server 2016+):
    - Kostenschwellwert für Parallelismus auf 25–50 setzen (Standard: 5)
    - MAXDOP = Anzahl der logischen Prozessoren pro NUMA-Knoten (max. 8)
    - Für Data-Warehouse-Workloads können höhere Werte sinnvoll sein.

  Seit SQL Server 2016 kann MAXDOP auch pro Datenbank eingestellt werden.
  Seit SQL Server 2022 ist SQL Server in der Lage, MAXDOP adaptiv zu steuern.
================================================================================
*/

-- I/O- und Zeitstatistiken aktivieren
-- IO   = Anzahl der gelesenen 8-KB-Seiten (entspricht RAM-Verbrauch 1:1)
-- time = Ausführungsdauer in Millisekunden (CPU-Zeit + Wartezeit)
SET STATISTICS IO, TIME ON;

-- ============================================================================
-- Beispielabfrage: Frachtkosten je Land und Stadt
-- Tabelle KU enthält ca. 62.000 Seiten (~496 MB)
-- ============================================================================
SELECT   ShipCountry,
         ShipCity,
         SUM(Freight) AS GesamtFracht
FROM     KU
GROUP BY ShipCountry, ShipCity
OPTION   (MAXDOP 6);     -- Diese Abfrage nutzt maximal 6 Kerne
-- Messergebnisse (Beispielwerte):
--   8 Kerne: CPU-Zeit = 923 ms, verstrichene Zeit =  144 ms
--   1 Kern:  CPU-Zeit = 406 ms, verstrichene Zeit =  419 ms
--   4 Kerne: CPU-Zeit = 625 ms, verstrichene Zeit =  166 ms
--
-- Fazit: Mehr Kerne senken die Laufzeit (verstrichene Zeit),
--        erhöhen aber die gesamte CPU-Zeit (Parallelisierungs-Overhead).
--        Am Ende entscheidet der Anwendungsfall.

-- ============================================================================
-- Parallelisierungs-Wartezeiten prüfen
-- CX-Waits zeigen Wartezeiten durch Parallelismus (Exchange-Operatoren)
-- ============================================================================
SELECT *
FROM   sys.dm_os_wait_stats
WHERE  wait_type LIKE 'CX%';

-- ============================================================================
-- Dieselbe Abfrage mit explizitem MAXDOP 8
-- ============================================================================
SELECT   Country,
         City,
         SUM(Freight) AS GesamtFracht
FROM     KU
GROUP BY Country, City
OPTION   (MAXDOP 8);

-- Prioritätsregel:
--   Server-MAXDOP(4) → DB-MAXDOP(6) → Abfrage-MAXDOP(8)  →  es gilt: 8
--   Der MAXDOP näher an der Abfrage hat immer Vorrang.

-- ============================================================================
-- Empfehlung: MAXDOP auf Datenbankebene setzen (ab SQL Server 2016)
-- ============================================================================
-- Kostenschwellwert für Parallelismus empfehlung: 25
-- → Abfragen unter 25 Kosteneinheiten werden nicht parallelisiert

USE [Northwind];
GO
-- MAXDOP für diese Datenbank auf 4 begrenzen
ALTER DATABASE SCOPED CONFIGURATION SET MAXDOP = 4;
GO

-- ============================================================================
-- MAXDOP-Übersicht
-- ============================================================================
-- MAXDOP =  0  → alle verfügbaren Kerne (kein Limit)
-- MAXDOP =  1  → keine Parallelisierung (serielle Ausführung)
-- MAXDOP =  8  → max. 8 Kerne (empfohlene Obergrenze)
-- Server-MAXDOP < DB-MAXDOP < Abfrage-MAXDOP  (letzterer hat Vorrang)
