/*
  Thema: Überflüssige Indizes identifizieren und abbauen.
  Diese Datei zeigt, wie wenig genutzte Indizes über System-DMVs gefunden werden.
  Für Anfänger ist wichtig: Jeder Index kostet Platz und Schreibaufwand.
  Wenn ein Index kaum gelesen, aber oft aktualisiert wird, ist er kritisch.
  Zu viele Indizes können INSERT, UPDATE und DELETE merklich verlangsamen.
  Die Abfragen vergleichen Nutzungsmuster wie Seeks, Scans und Updates.
  So erkennt man Kandidaten für Bereinigung oder Zusammenführung.
  Gleichzeitig darf man sinnvolle Scans nicht pauschal als schlecht bewerten.
  Entscheidend ist immer der Gesamtnutzen im realen Workload.
  Ziel ist eine schlanke, wirksame und wartbare Indexlandschaft.
*/

-- ============================================================================
-- Warum überflüssige Indizes problematisch sind
-- ============================================================================
-- Jeder Index auf einer Tabelle muss bei INSERT, UPDATE, DELETE aktualisiert werden.
-- Eine Transaktion endet erst, wenn ALLE betroffenen Indizes aktualisiert sind.
-- → Zu viele Indizes = hohe Schreiblast + Speicherverbrauch + Sperrkonflikte

-- Faustregel:
-- - user_updates >> user_seeks → Index kostet mehr als er bringt → Kandidat zum Löschen
-- - user_scans > 0, user_seeks = 0 → Index wird nur sequenziell genutzt (evtl. unnötig)
-- - user_seeks = 0, user_scans = 0, user_updates > 0 → "toter" Index → löschen!

-- ============================================================================
-- Überflüssige Indizes per DMV identifizieren
-- ============================================================================
-- Verknüpft sys.indexes mit sys.dm_db_index_usage_stats
-- Zeigt Nutzungsmuster aller Indizes auf Benutzertabellen

SELECT OBJECT_NAME(i.object_id)  AS Tabellenname,
       i.type_desc                AS Indextyp,
       i.name                     AS Indexname,
       us.user_seeks               AS AnzahlSeeks,     -- Gezielte Suchen (gut!)
       us.user_scans               AS AnzahlScans,     -- Sequenzielle Scans
       us.user_lookups             AS AnzahlLookups,   -- Key Lookups (kostspierig)
       us.user_updates             AS AnzahlUpdates,   -- Schreibvorgänge (Kosten)
       us.last_user_scan           AS LetzterScan,
       us.last_user_update         AS LetzterUpdate
FROM   sys.indexes AS i
LEFT OUTER JOIN sys.dm_db_index_usage_stats AS us
             ON i.index_id   = us.index_id
            AND i.object_id  = us.object_id
WHERE  OBJECTPROPERTY(i.object_id, 'IsUserTable') = 1;
GO

-- ============================================================================
-- Interpretation der Ergebnisse
-- ============================================================================
-- Optimierer wählt Index-Scan, wenn er günstiger als Table Scan ist:
--   → user_scan, user_scans > 0, aber user_seeks = 0 → Index wird nur als Scan genutzt
--   → Prüfen ob ein Index Seek durch anderen Index möglich wäre
--
-- Nie genutzte Indizes (user_seeks = 0, user_scans = 0, user_lookups = 0):
--   → Diese Indizes sind Kandidaten zum Löschen
--   → Aber: DMV-Werte werden beim Neustart zurückgesetzt!
--     → Ausreichend Zeit beobachten (mind. 1-2 Wochen Produktionsbetrieb)

-- ============================================================================
-- Weiterführendes Tool: Brent Ozar sp_BlitzIndex
-- ============================================================================
-- Kostenloses Analyse-Tool aus dem "First Responder Kit":
-- https://www.brentozar.com/blitz/
-- Analysiert Indizes umfassend:
--   - Überflüssige Indizes
--   - Fehlende Indizes
--   - Fragmentierung
--   - Overlapping Indizes (Duplikate)
-- EXEC sp_BlitzIndex @DatabaseName = 'Northwind', @SchemaName = 'dbo', @TableName = 'Orders';
