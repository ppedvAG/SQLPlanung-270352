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