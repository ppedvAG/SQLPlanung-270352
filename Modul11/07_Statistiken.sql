/*
  Thema: Statistiken als Grundlage für den SQL Server Optimizer.
  Diese Datei erklärt, warum der Optimizer Schätzungen über Datenverteilungen braucht.
  Ohne gute Statistiken werden Abfragepläne oft langsam oder unpassend.
  Für Anfänger ist zentral: Statistiken steuern die Wahl zwischen Seek und Scan.
  Gezeigt werden Aufbau, Histogramm, Dichte und Aktualisierungsmechanismen.
  Auch automatische und manuelle Updates werden gegenübergestellt.
  Bei großen Tabellen können Stichproben zu ungenauen Schätzungen führen.
  Dann helfen gezielte FULLSCAN- oder Mehrspalten-Statistiken.
  Das Skript enthält Beispiele zum Erzeugen, Prüfen und Interpretieren der Werte.
  So lernst du, wie Statistikqualität direkt die Abfrageleistung beeinflusst.
*/

/*
  Wofür werden Statistiken benötigt?
  SQL Server muss VOR der Ausführung einer Abfrage einschätzen,
  wie viele Datensätze ungefähr zurückkommen werden.
  Diese Schätzung ist entscheidend für die Wahl des Ausführungsplans:
    - Wenige Zeilen erwartet → Index Seek (gezielter Zugriff, sehr schnell)
    - Viele Zeilen erwartet  → Table Scan oder Index Scan (sequenziell, günstiger bei vielen Zeilen)

  Häufige Probleme mit Statistiken:
  - Veraltete Statistiken → falsche Schätzung → falscher Plan (z. B. Scan statt Seek)
  - Statistiken nur über einzelne Spalten → Korrelationen zwischen Spalten nicht bekannt
  - Stichproben-basierte Erstellung → bei ungleichmäßiger Verteilung ungenau

  Arten von Statistiken:
  a) Indexstatistiken:   Automatisch beim Erstellen eines Indexes angelegt
  b) Spaltenstatistiken: Automatisch, wenn eine Spalte in einem WHERE-Filter vorkommt
  c) Manuelle Statistiken: Mit CREATE STATISTICS gezielt erstellen
  d) Gefilterte Statistiken: Nur für einen Teilbereich der Daten
*/

-- ============================================================================
-- Aufbau einer Statistik
-- ============================================================================
/*
  Eine Statistik besteht aus:
  1. Headerinformationen:
     - Zeilenanzahl (Rows)
     - Anzahl unterschiedlicher Werte (Distinct Values)
     - Dichte (Density = 1 / Distinct Values bei gleichmäßiger Verteilung)
     - Datum der letzten Aktualisierung

  2. Dichtevektor (Density Vector):
     Für jede Spaltenkombination wird die Dichte (Selectivity) berechnet.
     Dichte = 1 / Kardinalität (bei gleichmäßiger Verteilung)

  3. Histogramm (nur für die führende Spalte):
     Max. 200 Schritte (Buckets). Jeder Bucket enthält:
     - RANGE_HI_KEY:          Oberer Grenzwert des Bereichs
     - RANGE_ROWS:            Geschätzte Zeilen in diesem Bereich
     - EQ_ROWS:               Zeilen, die genau diesem Wert entsprechen
     - DISTINCT_RANGE_ROWS:   Eindeutige Werte im Bereich
     - AVG_RANGE_ROWS:        Durchschnittliche Zeilen pro Wert im Bereich
*/

-- ============================================================================
-- Automatischer Update-Schwellenwert
-- ============================================================================
-- Bis SQL Server 2014: Trigger bei 20 % + 500 Zeilen Änderung
-- Ab  SQL Server 2016: Dynamischer Schwellenwert (kleiner bei großen Tabellen)
--
-- Formeln:
-- Bis 2014:  Änderungen > 500 + (0,20 * n)
-- Ab  2016:  Änderungen > CEILING(500 * SQRT(n / 250000))
--
-- Effekt: Bei Millionen von Zeilen werden Statistiken viel häufiger aktualisiert.

-- ============================================================================
-- Test-Setup: Tabelle anlegen und befüllen
-- ============================================================================

DROP TABLE IF EXISTS dbo.Kunden;

CREATE TABLE dbo.Kunden
(
    KundenID INT           IDENTITY PRIMARY KEY,
    Nachname NVARCHAR(50),
    Land     NVARCHAR(50)
);

-- 10.000 Beispielzeilen mit Zufallsdaten einfügen
INSERT INTO dbo.Kunden (Nachname, Land)
SELECT TOP (10000)
    -- Zufälliger dreistelliger Großbuchstaben-Name
    CHAR(65 + ABS(CHECKSUM(NEWID())) % 26) +
    CHAR(65 + ABS(CHECKSUM(NEWID())) % 26) +
    CHAR(65 + ABS(CHECKSUM(NEWID())) % 26) AS Nachname,
    -- Verteilung: 70 % DE, 20 % AT, 10 % CH
    CASE
        WHEN RAND(CHECKSUM(NEWID())) < 0.7 THEN 'DE'
        WHEN RAND(CHECKSUM(NEWID())) < 0.9 THEN 'AT'
        ELSE 'CH'
    END AS Land
FROM sys.all_objects a
CROSS JOIN sys.all_objects b;

-- ============================================================================
-- Automatische Statistik erzeugen lassen
-- ============================================================================
-- Diese Abfrage erzeugt automatisch eine Statistik auf der Nachname-Spalte
SELECT COUNT(*)
FROM   dbo.Kunden
WHERE  Nachname = 'ABC';

-- ============================================================================
-- Statistik anzeigen (DBCC SHOW_STATISTICS)
-- ============================================================================
-- Zeigt Histogramm und Dichtevektor der Statistik
-- Statistikname muss an den tatsächlichen Namen angepasst werden (z. B. _WA_Sys_...)
DBCC SHOW_STATISTICS ('dbo.Kunden', '_WA_Sys_00000002_01142BA1');

-- ============================================================================
-- Statistiken manuell aktualisieren
-- ============================================================================

-- Standard (Sampling – schnell, aber ggf. ungenau)
UPDATE STATISTICS dbo.Kunden;

-- Vollständiger Scan (FULLSCAN – genau, aber teurer bei großen Tabellen)
UPDATE STATISTICS dbo.Kunden WITH FULLSCAN;

-- Nur eine bestimmte Statistik aktualisieren
-- UPDATE STATISTICS dbo.Kunden _WA_Sys_00000002_1234ABCD WITH FULLSCAN;

-- Alle Statistiken in der Datenbank aktualisieren
EXEC sp_updatestats;

-- ============================================================================
-- Schätzungsformeln des Optimizers
-- ============================================================================
-- Exakter Treffer im Histogramm:
--   Selectivity = EQ_ROWS / Total_Rows
--
-- Wert zwischen Buckets:
--   Selectivity = AVG_RANGE_ROWS / Total_Rows
--
-- Wert außerhalb des Histogramms (unbekannt):
--   Schätzung basierend auf Dichte (= 1 / Distinct Values)
--
-- Mehrere Spalten (Unabhängigkeit wird angenommen!):
--   Estimated_Rows = Total_Rows * Density(col1) * Density(col2)
--   → Bei stark korrelierten Spalten: Fehlerquelle! → Mehrspalten-Statistiken erstellen

-- ============================================================================
-- Versionsübersicht: Update-Schwellenwert und Besonderheiten
-- ============================================================================
/*
  SQL Server ≤ 2014 : 20 % + 500 Zeilen (fest)
  SQL Server 2016   : Dynamisch (TF 2371 optional), verbesserter Cardinality Estimator
  SQL Server 2016+  : Dynamisch (Standard), inkrementelle Statistiken für Partitionen
  SQL Server 2017+  : Async Auto Update Stats stabil
  SQL Server 2019+  : Adaptive Query Processing (IQP)
  SQL Server 2022   : Verbesserte CE, IQP-Erweiterungen
*/
