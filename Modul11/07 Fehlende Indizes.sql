/*
  Thema: Fehlende Indizes erkennen und richtig bewerten.
  Diese Datei zeigt, wie SQL Server Vorschläge für fehlende Indizes liefert.
  Solche Hinweise entstehen aus Ausführungsplänen und System-DMVs.
  Wichtig für Anfänger: Ein Vorschlag ist nur ein Hinweis, keine fertige Lösung.
  Die Reihenfolge von Spalten und konkrete Indexart müssen selbst geprüft werden.
  Nicht jeder empfohlene Index verbessert jede Abfrage dauerhaft.
  Außerdem haben zusätzliche Indizes immer Pflegekosten bei INSERT, UPDATE, DELETE.
  Das Skript demonstriert einfache und erweiterte Auswertungen der Rohdaten.
  Damit kann man Prioritäten nach Nutzen, Kosten und Häufigkeit setzen.
  Ziel ist, fundiert zu entscheiden, welche Indizes wirklich erstellt werden sollen.
*/

-- Bekannte Einschränkungen der DMV-Index-Empfehlungen:
-- - Kann keine Indexkonfiguration vollständig optimieren
-- - Erfasst maximal 500 fehlende Indexgruppen
-- - Gibt keine Spaltenreihenfolge innerhalb des Indexes an!
-- - Bei Ungleichheitsprädikaten weniger genaue Kostenschätzung
-- - Schlägt keine gefilterten Indizes vor
-- - Kann für dieselbe Indexgruppe unterschiedliche Kostenwerte zurückgeben

-- ============================================================================
-- Test-Setup: Index entfernen, dann fehlenden Index erzeugen
-- ============================================================================

-- Vorhandenen Index entfernen (damit ein Vorschlag entsteht)
DROP INDEX IX_T1_Nr ON T1;
GO

-- Abfrageplan mit fehlenden Index-Hinweisen anzeigen
SET SHOWPLAN_XML ON;
GO
SELECT *
FROM   T1
WHERE  Nr = 3000;
GO
SET SHOWPLAN_XML OFF;
GO

-- ============================================================================
-- Fehlende Indizes aus dem Plan-Cache abfragen
-- ============================================================================

-- Alle gecachten Pläne anzeigen, die fehlende Indizes enthalten
SELECT p.query_plan
FROM   sys.dm_exec_cached_plans
CROSS APPLY sys.dm_exec_query_plan(plan_handle) AS p
WHERE  p.query_plan.exist(
           'declare namespace mi="http://schemas.microsoft.com/sqlserver/2004/07/showplan";
            //mi:MissingIndexes') = 1;
GO

-- ============================================================================
-- Detaillierte Auswertung: Fehlende Indizes inkl. Spaltenangaben (XML-Parsing)
-- ============================================================================
-- Diese CTE-Kette parsed den XML-Abfrageplan und extrahiert Indexdetails

WITH XmlNameSpaces(
    'http://schemas.microsoft.com/sqlserver/2004/07/showplan' AS qp
)
,MissingIndexPlans(query_plan) AS
(
    -- Schritt 1: Alle Pläne mit fehlenden Indizes aus dem Cache holen
    SELECT p.query_plan
    FROM   sys.dm_exec_cached_plans
    CROSS APPLY sys.dm_exec_query_plan(plan_handle) AS p
    WHERE  p.query_plan.exist(
               'declare namespace mi="http://schemas.microsoft.com/sqlserver/2004/07/showplan";
                //mi:MissingIndexes') = 1
)
,Statements(StatementId, StatementText, StatementType,
             StatementCost, StatementRows, MissingIndexesXml) AS
(
    -- Schritt 2: Anweisungsebene auslesen
    SELECT stmt.value('(//qp:Statements/qp:StmtSimple)[1]/@StatementId',          'int')
          ,stmt.value('(//qp:Statements/qp:StmtSimple)[1]/@StatementText',         'nvarchar(max)')
          ,stmt.value('(//qp:Statements/qp:StmtSimple)[1]/@StatementType',         'nvarchar(80)')
          ,stmt.value('(//qp:Statements/qp:StmtSimple)[1]/@StatementSubTreeCost',  'float')
          ,stmt.value('(//qp:Statements/qp:StmtSimple)[1]/@StatementEstRows',      'float')
          ,stmt.query('//qp:MissingIndexes')
    FROM   MissingIndexPlans
    CROSS APPLY query_plan.nodes('//qp:StmtSimple') AS qp(stmt)
)
,MissingIndexGroup(StatementId, StatementText, StatementType,
                   StatementCost, StatementRows, Impact, MissingIndexXml) AS
(
    -- Schritt 3: Indexgruppen mit Impact-Wert auflösen
    SELECT StatementId, StatementText, StatementType,
           StatementCost, StatementRows,
           mi.value('@Impact', 'float'),
           mi.query('.[position()]/qp:MissingIndex')
    FROM   Statements
    CROSS APPLY MissingIndexesXml.nodes('//qp:MissingIndexGroup') AS mig(mi)
)
,MissingIndex(StatementId, StatementText, StatementType,
              StatementCost, StatementRows, Impact,
              DbName, TableName,
              EqualityColumnsXml, InEqualityColumnsXml, IncludeColumnsXml) AS
(
    -- Schritt 4: Details pro fehlendem Index
    SELECT StatementId, StatementText, StatementType,
           StatementCost, StatementRows, Impact,
           mi.value('@Database', 'sysname'),
           mi.value('@Table',    'sysname'),
           mi.query('//qp:ColumnGroup[@Usage="EQUALITY"]'),   -- Gleichheitsspalten (=)
           mi.query('//qp:ColumnGroup[@Usage="INEQUALITY"]'), -- Bereichsspalten (<, >, BETWEEN)
           mi.query('//qp:ColumnGroup[@Usage="INCLUDE"]')     -- Eingeschlossene Spalten (SELECT)
    FROM   MissingIndexGroup
    CROSS APPLY MissingIndexXml.nodes('//qp:MissingIndex') AS mig(mi)
)
,ColumnGroup(StatementId, StatementText, StatementType,
             StatementCost, StatementRows, Impact,
             DbName, TableName, IndexColumns, IncludeColumns) AS
(
    -- Schritt 5: Spalten zu Strings zusammenfügen
    SELECT StatementId, StatementText, StatementType,
           StatementCost, StatementRows, Impact, DbName, TableName,
           LTRIM(REPLACE(CAST(EqualityColumnsXml.query('data(//qp:Column/@Name)') AS nvarchar(max))
               + ' '
               + CAST(InEqualityColumnsXml.query('data(//qp:Column/@Name)') AS nvarchar(max)),
               '] [', '],['))  AS IndexColumns,
           REPLACE(CAST(IncludeColumnsXml.query('data(//qp:Column/@Name)') AS nvarchar(max)),
               '] [', '],[')  AS IncludeColumns
    FROM   MissingIndex
)
-- Schritt 6: Ergebnis ausgeben
SELECT StatementId, StatementText, StatementType,
       StatementCost, StatementRows, Impact,
       DbName, TableName, IndexColumns, IncludeColumns
FROM   ColumnGroup;
GO

-- ============================================================================
-- Einfachere Variante: Fehlende Indizes direkt über DMVs abfragen
-- ============================================================================
-- Verknüpft drei DMVs:
-- sys.dm_db_missing_index_groups        → Gruppierung der Vorschläge
-- sys.dm_db_missing_index_group_stats   → Statistiken (Kosten, Häufigkeit)
-- sys.dm_db_missing_index_details       → Details (Tabelle, Spalten)

SELECT DB_NAME(d.database_id)                           AS DatenbankName,
       d.statement                                      AS TabellenName,
       d.equality_columns                               AS GleichheitsSpalten,
       d.inequality_columns                             AS UngleichheitsSpalten,
       d.included_columns                               AS EingeschlosseneSpalten,
       CAST(gs.avg_total_user_cost AS DECIMAL(8,2))     AS DurchschnKosten,
       gs.avg_user_impact                               AS DurchschnImpact,
       gs.user_seeks                                    AS AnzahlSeeks,
       gs.user_scans                                    AS AnzahlScans,
       gs.last_user_seek                                AS LetzterSeek,
       gs.last_user_scan                                AS LetzterScan
FROM   sys.dm_db_missing_index_groups       AS g
JOIN   sys.dm_db_missing_index_group_stats  AS gs ON gs.group_handle = g.index_group_handle
JOIN   sys.dm_db_missing_index_details      AS d  ON g.index_handle  = d.index_handle
WHERE  d.database_id > 4          -- Nur Benutzerdatenbanken (keine Systemdatenbanken)
ORDER BY gs.avg_user_impact DESC;  -- Wichtigste Vorschläge zuerst
