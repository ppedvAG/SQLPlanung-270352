/*
  Thema: Indizes – Typen, Einsatz und Wartung in SQL Server.
  Diese Datei erklärt die verschiedenen Indexarten und ihre Anwendungsfälle.
  Ein Index ist eine sortierte Kopie von Daten, die gezielte Suchen beschleunigt.
  Der Clustered Index bestimmt die physische Reihenfolge der Tabellendaten.
  Non-Clustered Indizes sind separate Strukturen, die Lookups ermöglichen.
  Weitere Typen wie Columnstore oder gefilterte Indizes sind für spezielle Szenarien.
  Ein Schwerpunkt liegt auf abdeckenden Indizes, die Lookups vermeiden.
  Ein weiterer Schwerpunkt ist Columnstore für analytische Auswertungen.
  Die Beispiele zeigen, wie sich unterschiedliche Indexstrategien im Plan auswirken.
  Außerdem wird erläutert, wann Rebuild oder Reorganize sinnvoll ist.
  Ziel ist ein praxisnahes Verständnis für Auswahl, Nutzen und Pflege von Indizes.
*/

/*
  INDEX-TYPEN IM ÜBERBLICK

  Clustered Index (CL IX):
  - Die Tabelle selbst IS der Clustered Index → Daten in sortierter Form
  - Nur 1 Clustered Index pro Tabelle möglich
  - Gut bei Bereichsabfragen (BETWEEN, >, <), da Daten physisch sortiert sind
  - Niemals Lookups in einem Clustered Index → alle Spalten direkt verfügbar
  - SSMS setzt standardmäßig beim Primary Key einen Clustered Index
    → Oft unvorteilhaft! Besser: Clustered Index auf die am häufigsten gelesene Range-Spalte

  Non-Clustered Index (NCL IX):
  - Kopie ausgewählter Spalten in sortierter Form (separates B-Tree)
  - Bis zu ca. 999 NCL-Indizes pro Tabelle möglich (Limit: 1000 gesamt)
  - Gut für geringes Resultat-Set (WHERE id = 100)
  - Key Lookup: Falls benötigte Spalten nicht im Index → extra Seitenzugriff!

  Zusammengesetzter Index:
  - Max. 16 Spalten, max. 900 Byte Schlüssellänge
  - Meist nicht mehr als 4 Spalten sinnvoll
  - Spaltenreihenfolge entscheidend! Gleichheitsspalten zuerst, dann Bereichsspalten

  Gefilterter Index:
  - Nur ein Teilbereich der Datensätze wird indexiert (z. B. WHERE Land = 'USA')
  - Gut für Abfragen, die immer denselben Filter verwenden
  - Vorsicht: Ein ungefiltererter Index kann trotzdem günstiger sein (B-Tree-Tiefe beachten)

  Index mit eingeschlossenen Spalten (INCLUDE):
  - Schlüsselspalten = WHERE-Bedingung
  - Eingeschlossene Spalten = SELECT-Spalten (belastet den B-Tree nicht!)
  - Max. 1.023 eingeschlossene Spalten
  - Ideal für "abdeckende Indizes" → kein Lookup notwendig!

  Abdeckender Index (Covering Index):
  - Enthält alle benötigten Spalten → reiner Index Seek ohne Lookup
  - Idealfall: Keine zusätzlichen Seiten gelesen außer dem Index selbst

  Partitionierter Index:
  - Entspricht einem gefilterten Index auf physischer Ebene
  - Alle Werte werden auf bestimmte Bereiche (Partitionen) aufgeteilt
  - Im Gegensatz zum gefilterten Index werden ALLE Datensätze einbezogen

  Columnstore Index:
  - Daten spaltenweise gespeichert (statt zeilenweise)
  - Stark komprimiert → passt viel mehr in den RAM als Rowstore
  - Optimal für analytische Abfragen (GROUP BY, SUM, AVG über viele Zeilen)
  - Neue Zeilen landen zunächst im Delta Store (Heap), erst ab ~1 Mio. Zeilen
    werden sie in komprimierte Segmente überführt
  - Bei Massenimporten (ab ca. 100.000 Zeilen) direkter Eintrag in Columnstore

  Indizierte Sicht (Indexed View):
  - Erstellt auf das Ergebnis einer View einen gruppierten Index
  - Daten der View werden physisch gespeichert → sehr schnell für Aggregationen
  - Viele Einschränkungen: WITH SCHEMABINDING, COUNT_BIG(*), kein AVG,
    deterministische Ausdrücke, gleicher Besitzer von View und Basistabelle
*/

USE northwind;
GO

-- ============================================================================
-- Demo: Tabellen-Setup
-- ============================================================================

-- Kopie der KU-Tabelle als HEAP (kein Clustered Index)
SELECT * INTO ku2 FROM ku1;

-- Fragmentierungsanalyse: Veraltet (deprecated)
DBCC SHOWCONTIG('ku2');  -- Beispiel: 40.455 Seiten

-- Neue Spalte hinzufügen → erzeugt Forwarded Records im Heap
ALTER TABLE ku2 ADD id INT IDENTITY;

-- Nach ALTER TABLE: mehr Seiten durch Forwarded Records
DBCC SHOWCONTIG('ku2');  -- Beispiel: 41.092 Seiten

-- I/O-Statistiken aktivieren
SET STATISTICS IO, TIME ON;

-- Abfrage mit WHERE auf ID → erzwingt Table Scan (kein Index vorhanden)
-- Ergebnis: ~57.210 Seiten gelesen!
SELECT *
FROM   ku2
WHERE  id = 100;

-- Moderne Fragmentierungsanalyse (empfohlen)
-- forwarded_record_count sollte immer NULL oder 0 sein!
SELECT *
FROM sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID('ku2'), NULL, NULL, 'detailed');

-- ============================================================================
-- Demo: Index-Typen und ihre Wirkung
-- ============================================================================

-- Table Scan: Alle 57.206 Seiten gelesen (kein Index auf ID)
SELECT id FROM ku1 WHERE id = 100;

-- Nach dem Anlegen von NIX_ID (Non-Clustered Index auf ID):
-- Index Seek + Key Lookup → nur 4 Seiten gelesen!
-- CREATE INDEX NIX_ID ON ku1(id);
SELECT id FROM ku1 WHERE id = 100;

-- Key Lookup entsteht, wenn der Index ID hat, aber auch FREIGHT benötigt wird
-- Je mehr Lookups, desto teurer!
SELECT id, Freight FROM ku1 WHERE id = 100;

-- Abdeckender Index (zusammengesetzt) vermeidet den Lookup
-- CREATE INDEX NIX_ID_FR ON ku1(id, freight);
SELECT id, Freight FROM ku1 WHERE id < 900500;

-- ============================================================================
-- Demo: Abdeckende Indizes mit eingeschlossenen Spalten
-- ============================================================================

-- Filterbedingung: Country und Freight
-- Schlüsselspalten: Country, Freight
-- CREATE INDEX NIX_CYFR ON ku1(Country, Freight);
SELECT *
FROM   ku1
WHERE  Country = 'USA' AND Freight < 1;

-- Komplexere Abfrage: Gruppierung nach Land und Stadt pro Mitarbeiter
-- Schlüsselspalten: EmployeeID (WHERE)
-- Eingeschlossene Spalten: Country, City, UnitPrice, Quantity (SELECT + GROUP BY)
-- CREATE INDEX NIX_EID_inkl_cy_ci_up_qu ON ku1(EmployeeID) INCLUDE (Country, City, UnitPrice, Quantity);
SELECT   Country, City, SUM(UnitPrice * Quantity) AS Umsatz
FROM     ku1
WHERE    EmployeeID = 2
GROUP BY Country, City;

-- ============================================================================
-- Demo: Columnstore Index für analytische Abfragen
-- ============================================================================

-- Kopie der KU-Tabelle als Zeilenspeicher
SELECT * INTO ku3 FROM ku;

-- Columnstore Index auf ku3 anlegen:
-- CREATE COLUMNSTORE INDEX IX_CS ON ku3 (CompanyName, Quantity, Country, City);

-- Vergleich: Zeilenspeicher vs. Columnstore
-- Zeilenspeicher (ku1): ~600 MB
SELECT CompanyName, AVG(Quantity), MIN(Quantity)
FROM   ku1
WHERE  Country = 'Germany'
GROUP BY CompanyName;

-- Columnstore (ku3): ~4 MB → extrem komprimiert, optimal für Analysen
SELECT CompanyName, AVG(Quantity), MIN(Quantity)
FROM   ku3
WHERE  Country = 'Germany'
GROUP BY CompanyName;

-- ============================================================================
-- Demo: Indizierte Sicht (Indexed View)
-- ============================================================================

-- Einfache View ohne Index
CREATE VIEW vDemo AS
    SELECT Country, COUNT(*) AS Anzahl
    FROM   ku1
    GROUP BY Country;
GO

-- View mit Schema-Binding und Clustered Index (Indizierte Sicht)
CREATE OR ALTER VIEW vDemoIndexed WITH SCHEMABINDING AS
    SELECT Country, COUNT_BIG(*) AS Anzahl   -- COUNT_BIG(*) ist Pflicht!
    FROM   dbo.ku1                            -- Schema-Qualifizierung ist Pflicht!
    GROUP BY Country;
GO

-- Clustered Index auf die View erstellen → Daten werden physisch gespeichert
-- CREATE UNIQUE CLUSTERED INDEX IX_vDemoIndexed ON dbo.vDemoIndexed (Country);

-- ============================================================================
-- Index-Wartung
-- ============================================================================
-- Fragmented < 10 %:  Keine Maßnahme notwendig
-- Fragmented 10-30 %: REORGANIZE (online, weniger Ressourcen)
-- Fragmented > 30 %:  REBUILD    (offline oder online, vollständige Neustruktur)

-- Statistiken manuell aktualisieren (alle in der DB)
EXEC sp_updatestats;

-- Fragmentierung prüfen (Ausgabe: avg_fragmentation_in_percent)
SELECT *
FROM   sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED');

-- Index-Nutzung abfragen (für überflüssige Indizes)
-- user_updates >> user_seeks → Index kostet mehr als er bringt → Kandidat zum Löschen
SELECT *
FROM   sys.dm_db_index_usage_stats
WHERE  database_id = DB_ID();

-- ============================================================================
-- Tipp: Abdeckenden Index entwerfen
-- ============================================================================
-- Schlüsselspalten:       Spalten in der WHERE-Bedingung
-- Eingeschlossene Spalten: Spalten im SELECT (nicht für Filterung benötigt)
-- Clustered Index:        Nur 1x möglich → auf Bereichsspalte (nicht PK!)
