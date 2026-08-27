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

--Überflüssige Indizes identifizieren

--kosten Performance bei INSERT / DELETE

--Systemsichten
-- select * from sys.dm_db_index_physical_Stats verknüpft mikt sys.indexes


select object_name(i.object_id) as TableName
      ,i.type_desc,i.name
      ,us.user_seeks, us.user_scans
      ,us.user_lookups,us.user_updates
      ,us.last_user_scan, us.last_user_update
  from sys.indexes as i
       left outer join sys.dm_db_index_usage_stats as us
                    on i.index_id=us.index_id
                   and i.object_id=us.object_id
 where objectproperty(i.object_id, 'IsUserTable') = 1
go

--Optimierer entscheidet sich für Index-scan , wenn die der günstiger als Table-scan ist
-- user_scan, index_scan  ..nie gebrauchte Indizes evtl löschen
-- user_scan, index_scan  .. besser als table scan


-- Brent Ozar SP_blitzIndex