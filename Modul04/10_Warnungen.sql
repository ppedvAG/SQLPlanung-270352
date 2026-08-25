--Warnungen


/* SQL Server Alerts  bzw Warnungen
SQL Server Alerts sind automatische Benachrichtigungs- und Reaktionsmechanismen, 
die vom SQL Server Agent bereitgestellt werden. Sie überwachen das Datenbanksystem
kontinuierlich und lösen definierte Aktionen aus, 
sobald ein bestimmtes Ereignis, ein Fehler 
oder ein Leistungsschwellenwert erreicht wird.

Alert-Typ                   | Auslöser / Beschreibung                                                                                                 | Typisches Beispiel
----------------------------+-------------------------------------------------------------------------------------------------------------------------+---------------------------------------------------------
SQL Server Event Alert      | Reagiert auf Ereignisse im Windows-Anwendungs- oder SQL Server-Fehlerprotokoll basierend auf Fehlernummer/Schweregrad.   | Schwerer Hardware-/I/O-Fehler (Fehler 825, Severity 19–25)
Performance Condition Alert | Löst aus, wenn ein Leistungsindikator (Performance Counter) einen definierten Schwellenwert über- oder unterschreitet.  | CPU-Auslastung > 90 % oder tempdb-Speicherplatz < 1000 KB
WMI Event Alert             | Reagiert auf Systemereignisse über Windows Management Instrumentation (WMI).                                            | Schema-Änderungen (ALTER/DROP TABLE) oder Deadlocks





/*
Ebenen:
16...  DAU
15 ..  DAU 
14... kein Zugriffsrecht
1-10  reine Infos
17.. Arbeit für den Admin (Ressourcen zu gering)
..
23.. je höher die Ebene
24.. desto schlimmer
25 .. bis zum Systemausfall

*/

select *  from xyz

select * from sysmessages where msgLangid = 1031

USE [msdb]
GO

/****** Object:  Alert [Security_Nwind_AccessDenied]    Script Date: 30.03.2022 12:11:21 ******/
EXEC msdb.dbo.sp_add_alert @name=N'Security_Nwind_AccessDenied', 
		@message_id=0, 
		@severity=14, 
		@enabled=1, 
		@delay_between_responses=0, 
		@include_event_description_in=0, 
		@database_name=N'Northwind', 
		@category_name=N'[Uncategorized]', 
		@job_id=N'00000000-0000-0000-0000-000000000000'
GO

