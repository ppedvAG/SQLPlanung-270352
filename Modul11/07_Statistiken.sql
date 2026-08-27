Wofür Statistiken?
SQL Server muss bevor die Abfragen ausgeführt werden eine Information besitzten,
wieviele DAtensätze in etwa zurückkommen werden. Das ist wichtig für die Wahl 
von IX SEEK oder doch Table_SCAN.

Probleme:
- Sind die Statistiken nicht aktuell und daher ungenau, kann ein 
falscher Plan entstehen.

- SQL Server macht automatisch Statistiken über eine Spalte ,
aber nicht über Kombinationen. Dadurch können auch falsche Annahmen bzgl der 
Anzahl der Datensätze entstehen.  

-Bei der Erstellung von Statistiken wird bei größeren Tabellen nur Stichproben 
verwendet. Was wenn: Stichprobe nicht repräsentiv?  --> Falscher Plan möglich



1. Welche Statistiken generiert SQL Server?
SQL Server erzeugt und pflegt Statistiken für den Abfrageoptimierer, 
um Selektivitäten von Prädikaten abzuschätzen. 

Es gibt:

a) Indexstatistiken
Automatisch angelegt, sobald ein Index erstellt wird.

Enthalten Histogramme über den führenden Schlüssel des Indexes.

Beispiel: Bei 
CREATE INDEX idx_Test (Spalte1) --wird automatisch stat_idx_Test_Spalte1 erstellt.

b) Spaltenstatistiken (Auto-Stats)
Automatisch angelegt, wenn Abfragen Filter auf Spalten enthalten
, die noch nicht durch Statistiken abgedeckt sind.

Beispiel: 
SELECT ... WHERE Nachname = 'Müller' 
--→ SQL Server legt stat_Nachname an, falls nicht vorhanden.
Diese Statistiken sind bei größeren Mengen nicht genau. Es wird nur eine Samplerate verwendet

c) Manuelle Statistiken
Mit 
CREATE STATISTICS 
--können gezielt Statistiken erstellt werden, z. B. 
--auf mehreren Spalten oder mit Filterbedingungen.

d) Filterte Statistiken
Nur für einen Teilbereich der Daten, z. B. 
CREATE STATISTICS s1 ON Kunden(Region) WHERE Land = 'DE'

2. Wie sind Statistiken aufgebaut?
Eine Statistik besteht aus drei Hauptkomponenten:

-Headerinformationen
    -Zeilenanzahl (Rows)
    -Anzahl unterschiedlicher Werte (Distinct Values / DVs)
    -Dichte (Density = 1 / DVs bei eindeutiger Verteilung)
    -Datum der letzten Aktualisierung
-Dichtevektor (Density Vector)
    Für jede Spaltenkombination in einer Statistik wird 
    die gegenseitige Dichte berechnet.
    Dichte = 1 / Kardinalität bei gleichmäßiger Verteilung 
    (ansonsten geschätzt).
- Histogramm (für führende Spalte)
    Maximal 200 Schritte (Buckets).
    Jeder Bucket enthält:
        RANGE_HI_KEY – oberer Grenzwert des Bereichs
        RANGE_ROWS – geschätzte Zeilen in diesem Bereich
        EQ_ROWS – Zeilenanzahl, die genau diesem Wert entsprechen
        DISTINCT_RANGE_ROWS – eindeutige Werte im Bereich
       AVG_RANGE_ROWS – Durchschnittliche Zeilen pro Wert im Bereich

3. Wie werden Statistiken aktualisiert?
a) Automatische Aktualisierung (AUTO_UPDATE_STATISTICS)
    Standardmäßig aktiv.
     Wird ausgelöst, wenn genügend Datenänderungen stattfinden, um Schätzungen potenziell zu verfälschen.

    Schwellenwert (Formel)
    Für Tabellen mit n Zeilen gilt bis SQL Server 2014:

    Trigger bei ~20 % Änderung + 500 Zeilen

    Formel: Änderung > 500 + (0,20 * n)

Seit SQL Server 2016 (mit Traceflag 2371 bzw. Standard ab SP1):
     Dynamischer Schwellenwert bei großen Tabellen (prozentual sinkend, mindestens 500 Zeilen).
     Formel (vereinfacht):
    
    Änderungsschwelle = CEILING(500 + (0.0000000000001 * n))  
    -- exakte Formel siehe Docs
    Effekt: 
    Bei Millionen Zeilen werden Statistiken viel früher 
    aktualisiert als bei der alten 20%-Regel.

b) Manuelle Aktualisierung
Mit 
UPDATE STATISTICS tabelle [statistik] WITH FULLSCAN | SAMPLE X PERCENT
    FULLSCAN: alle Zeilen werden gelesen → genaues Histogramm.
    SAMPLE: nur ein Teil der Zeilen wird gelesen → schneller, aber ungenauer.

sp_updatestats: aktualisiert alle Statistiken in der Datenbank 
    basierend auf Änderungsrate.

c) Methoden der Aktualisierung
Sampling-basiert (Standard):
    SQL Server wählt automatisch eine Stichprobe aus Zeilen aus 
    und schätzt Verteilungen.

Vollständiger Scan (FULLSCAN):
Exakte Werte, teurer in großen Tabellen.

Incremental Statistics (ab Enterprise/Developer Edition):
Bei Partitionierten Tabellen werden nur geänderte Partitionen neu gescannt.

4. Welche Formeln nutzt SQL Server für Schätzungen?
a) Dichteberechnung
Für eine Spalte mit DVs (Distinct Values):

Density = 1 / DVs
Wenn Histogrammdaten vorliegen, nutzt SQL Server d
en Histogramm-Step, ansonsten die Dichte.

b) Selektivitätsschätzung
Für einen Wert, der im Histogramm existiert:


Selectivity = EQ_ROWS / Total_Rows
Für Werte zwischen Buckets:


Selectivity = AVG_RANGE_ROWS / Total_Rows
Für Werte außerhalb des Histogramms (unknown):

Schätzung basierend auf Dichtevektor oder Standardwerte 
(z. B. 9 % bei unbekannten Werten in alten Versionen).

c) Mehrspaltenstatistiken
Wenn nur führende Spalte im Prädikat: Histogramm
Wenn weitere Spalten gefiltert werden: 
Dichtevektor → Annahme Unabhängigkeit der Spalten

Schätzung:

Estimated Rows = Total_Rows * Density(col1) * Density(col2) * ...

Dies kann zu Fehlabschätzungen führen, wenn Spalten 
stark korreliert sind 
→ Lösung: Mehrspaltenstatistiken erstellen.

5. Änderungen in SQL Server 2014–2022
Traceflag 2371 
→ dynamische Schwelle für Auto-Stats (Standard ab SQL 2016 SP1).

Incremental Statistics für Partitionen.
Temporale Tabellen und Columnstore Indexe nutzen spezielle Statistikupdates.

Async Auto Update Stats (ASYNC) 
→ Abfrage läuft mit alten Stats weiter, 
während Update im Hintergrund erfolgt.

Auto Update Stats für Columnstore ab SQL Server 2014.

Neue Kardinalitätsschätzer (Cardinality Estimator, CE) 
in SQL Server 2014+ 
→ komplexere Formeln, bessere Annäherung bei Korrelationen.

Zusammenfassung
Statistiken = Histogramm + Dichteinformationen, automatisch 
oder manuell erstellt.

Update-Trigger: bis SQL2014 „20 % + 500 Zeilen“; 
seit SQL2016 dynamisch (Traceflag 2371 integriert).

Methoden: Sampling, FULLSCAN, inkrementell für Partitionen.

Formeln:
Density = 1 / DistinctValues
Selektivität = EQ_ROWS / TotalRows oder AVG_RANGE_ROWS / TotalRows
Bei unbekannten Werten: Dichte oder Defaultschätzung.
Mehrspaltenstatistiken reduzieren Fehlabschätzungen bei Korrelationen.

	----------------------------------------------
 --Tabelle erstellen
DROP TABLE IF EXISTS dbo.Kunden;
CREATE TABLE dbo.Kunden
(
    KundenID INT IDENTITY PRIMARY KEY,
    Nachname NVARCHAR(50),
    Land NVARCHAR(50)
);

-- 10000 Beispielzeilen
INSERT INTO dbo.Kunden (Nachname, Land)
SELECT TOP (10000)
    CHAR(65 + ABS(CHECKSUM(NEWID())) % 26) + '...' AS Nachname,
    CASE WHEN RAND(CHECKSUM(NEWID())) < 0.7 THEN 'DE'
         WHEN RAND(CHECKSUM(NEWID())) < 0.9 THEN 'AT'
         ELSE 'CH'
    END
FROM sys.all_objects a CROSS JOIN sys.all_objects b;



-- Abfrage auf Spalte ohne Index → Auto-Statistik wird erstellt
SELECT COUNT(*) 
FROM dbo.Kunden 
WHERE Nachname = 'A...';


---  Histogramm
DBCC SHOW_STATISTICS ('dbo.Kunden', '_WA_Sys_00000002_01142BA1');


Name                          Updated              Rows    Rows Sampled    Steps    Density   ...
----------------------------  ------------------  ------  -------------  ------  ---------  
_WA_Sys_00000002_1234ABCD      Aug 13 2025 16:30   10000   10000           200      0.0025


 All density   Avg. Length   Columns
-----------   -----------   --------
0.0025        6             Nachname



RANGE_HI_KEY  RANGE_ROWS   EQ_ROWS   DISTINCT_RANGE_ROWS   AVG_RANGE_ROWS
-----------   ----------   -------   -------------------   -------------
A...          0            150       0                     1
B...          45           120       40                    1.125
C...          60           100       55                    1.09
...
 EQ_ROWS = exakte Treffer
RANGE_ROWS = Werte zwischen Buckets
DENSITY = 1 / Anzahl unterschiedlicher Werte


 --UPDATE BIS 2014
Änderungen > 500 + (0.20 * n)


--UPDATE AB 2016    (Traceflag 2371 )
Änderungen > 500 * (n / 250000) ^ 0.5
==> Kleine Tabellen → fast wie alte Regel
Große Tabellen → Schwelle << 20 %



--Manuell:
-- Standard (Sampling)
UPDATE STATISTICS dbo.Kunden;

-- Genau (Fullscan)
UPDATE STATISTICS dbo.Kunden WITH FULLSCAN;

-- Nur bestimmte Statistik
UPDATE STATISTICS dbo.Kunden _WA_Sys_00000002_1234ABCD WITH FULLSCAN;

-- Alle Statistiken in der Datenbank
EXEC sp_updatestats;



4. Übersichtstabelle: Verhalten nach SQL-Version
SQL-Version	Auto Update Trigger	Besonderheiten
SQL Server ≤2014	20 % + 500 Zeilen	Feste Schwelle
SQL Server 2016	Dynamisch (TF 2371 optional)	Verbesserter CE (Cardinality Est.)
SQL Server 2016 SP1+	Dynamisch (Standard)	CE v2 Standard, Inkrementelle Stats
SQL Server 2017+	Dynamisch (Standard)	Async Auto Update Stats stabil
SQL Server 2019+	Dynamisch (Standard)	Adaptive Query Processing (IQP)
SQL Server 2022	Dynamisch (Standard)	Verbesserte CE, IQP-Features


--Wie wird gesucht?
Exakter Treffer im Histogramm
Selectivity = EQ_ROWS / Total_Rows

Wert dazwischen
Selectivity = AVG_RANGE_ROWS / Total_Rows

Werte , die nicht im Histogramm abgebildet werden
Selectivity ≈ Density  (oder Defaultschätzung bei alten Versionen)

Bei mehr Spalten
Estimated_Rows = Total_Rows * Density(col1) * Density(col2)



--BSP
/* 1) Testtabelle neu anlegen */
DROP TABLE IF EXISTS dbo.Kunden;
CREATE TABLE dbo.Kunden
(
    KundenID INT IDENTITY PRIMARY KEY,
    Nachname NVARCHAR(50),
    Land NVARCHAR(50)
);

/* 2) Mit Zufallsdaten füllen (10.000 Zeilen) */
INSERT INTO dbo.Kunden (Nachname, Land)
SELECT TOP (10000)
    CHAR(65 + ABS(CHECKSUM(NEWID())) % 26) + 
    CHAR(65 + ABS(CHECKSUM(NEWID())) % 26) + 
    CHAR(65 + ABS(CHECKSUM(NEWID())) % 26) AS Nachname,
    CASE 
        WHEN RAND(CHECKSUM(NEWID())) < 0.7 THEN 'DE'
        WHEN RAND(CHECKSUM(NEWID())) < 0.9 THEN 'AT'
        ELSE 'CH'
    END
FROM sys.all_objects a CROSS JOIN sys.all_objects b;

/* 3) Abfrage, um Auto-Statistik anzulegen */
SELECT COUNT(*) 
FROM dbo.Kunden 
WHERE Nachname LIKE 'A%';

/* 4) Alle Statistiken der Tabelle auflisten */
SELECT 
    s.name, 
    s.auto_created, 
    s.user_created, 
    sp.last_updated, 
    sp.rows, 
    sp.rows_sampled
FROM sys.stats AS s
CROSS APPLY sys.dm_db_stats_properties(s.object_id, s.stats_id) AS sp
WHERE s.object_id = OBJECT_ID('dbo.Kunden');

/* 5) Detailansicht der Statistik (Name ggf. aus obiger Abfrage kopieren) */
DBCC SHOW_STATISTICS ('dbo.Kunden', '_WA_Sys_00000002_02FC7413');

/* 6) Schwellenwert berechnen (bis SQL2014) */
DECLARE @n BIGINT = (SELECT COUNT(*) FROM dbo.Kunden);
SELECT Trigger_Change_2014 = 500 + (0.20 * @n);
 /* 7) Für SQL2016+ dynamischer Schwellenwert */
-- grob angenähert: 500 * SQRT(n/250000)
SELECT Trigger_Change_2016plus = 500 * SQRT(@n / 250000.0);

/* 8) Manuelles Statistik-Update (optional) */
-- Sampling (Standard)
UPDATE STATISTICS dbo.Kunden;

-- Fullscan (präzis, aber langsam bei großen Tabellen)
UPDATE STATISTICS dbo.Kunden WITH FULLSCAN;

/* 9) Anzeige nach Update erneut prüfen */
SELECT 
    s.name, 
    sp.last_updated, 
    sp.modification_counter
FROM sys.stats AS s
CROSS APPLY sys.dm_db_stats_properties(s.object_id, s.stats_id) AS sp
WHERE s.object_id = OBJECT_ID('dbo.Kunden');
 -------------------
 DBCC SHOW_STATISTICS zeigt Header, Dichtevektor, Histogramm.

sys.dm_db_stats_properties zeigt last_updated und modification_counter.

Trigger-Berechnung zeigt, ab wie vielen Änderungen ein Auto-Update passiert.

   +-------------------------------------------+
|  Statistik-Header                         |
|  - Gesamtzeilen (Rows)                    |
|  - Letzte Aktualisierung (LastUpdated)     |
|  - Rows Sampled (wie genau ist es?)        |
|  - Dichte (Density)                       |
+-------------------------------------------+
|  Dichtevektor                             |
|  - All density: 0.0025                    |
|  - Columns: Nachname                      |
+-------------------------------------------+
|  Histogramm (max. 200 Schritte)           |
|  RANGE_HI_KEY | RANGE_ROWS | EQ_ROWS ...  |
|  'AAB'        |    0       |   150       |
|  'ABC'        |   45       |   120       |
|  'ADD'        |   60       |   100       |
|  ...                                       |
+-------------------------------------------+
 Dichtevektor: Zeigt, wie "gleichmäßig" Werte verteilt sind.

Histogramm: Zeigt konkrete Häufigkeiten einzelner Werte oder Wertbereiche.

EQ_ROWS: Exakte Treffer für Schlüsselwerte.

RANGE_ROWS: Werte zwischen bekannten Schlüsseln → SQL Server interpoliert.


