/*
-
Agent: eig Dienst  mit eig Konto

Jobs, Aufträge, Zeitpläne, Warnungen, Operatoren, Email

Was man wissen sollte
 DOM\sqlAgent

 Backup um 2:30 auf C:\Backup    --NT service\sqlagent
 Backup um 2:30 auf \\NAS\Backup --DOM\sqlAgent

 Lokale Standardordner des SQL Server haben keine Vererbung aktiv

/*

Agent

----------------------------------------------------
Jobs per Zeitplan
----------------------------------------------------

Jobs bestehen aus einen oder mehreren Schritten
bei Erfolg bei Fehler bei Beendigung

--Bei Jobs emfiehlt es sich Testzeitpläne zu erstellen (Typ einmal)
--diese werden nach Ausführung automatisch deaktiviert



Operatoren

--------------------------------------------------
Operator
--------------------------------------------------
= Alias für eine Emailadresse oder Pager
DerChef = andreasr@ppedv.de

USE [msdb]
GO
EXEC msdb.dbo.sp_add_operator @name=N'SQLAdministrator', 
		@enabled=1, 
		@pager_days=0, 
		@email_address=N'sqlservice@sql.local'
GO


-----------------------------------------------
Datenbankmail
-----------------------------------------------
notwendig ist eibn SMTP Server

--Emailsystem SMTP und SMTP Zugangsdaten
--Zugriff--> Relay-->  Nur Computer Zugriff erlauben: 127.0.0.1

--Profil = Zugriffsdaten zum SMTP 

--man kann auch per TSQL Mails senden ;-)
exec sp_sendDBmail [GMX-profile]

Öfftl Profil  (mitlgied der Rolle msdb/DatabaseMailUserRole)

--der Operator bekommt aber noch keine Mail nach Abschluss eines Auftrags!

--1 Agent muss ein Mailprofil zugewiesen bekommen
--Eigeschaften des Agents--> Warnungsystem--> Mailprofil aktivieren Profil zuweisen

--2 Agent neu starten

-----------------------------------------------------------
----WARNUNGEN
-----------------------------------------------------------

Fehler werden in Kategorien eingeteilt und  bekommt eine best Fehlernummer
Ebenen = Kategorien = Secerity = Level

Ebene 16: Syntaxfehler Obejtk unbekannt
Ebene 15: Syntaxfehler falsches TSQL
Ebene 9:  bis 10 sind Erfolg
Ebene 14: Rechte
..bis Ebene 16 sind mir alle Fehler egal

ab Ebene 17 --> Admin

--max Ebene 25 Sytemausfall steht bevor

select * from sysmessages where msglangid = 1031

-------------------------------------------------------------------------
--Proxykonten
Proxykonten   Auftragsschritte mit anderen Konto ausführen  Ausführen als
-------------------------------------------------------------------------
--falls der Agent keine Rechte auf externe Systeme besitzt wie CMD PS SSAS Replikation usw

--Idee nr 1: Agent wird Dom Admin  keine gute Idee ;-)
--Idee nr2 : Ausführen als  , dann aber KOnto und Kennwort

1. zuerst unter Sicherheit --> Anmeldeinformation hinterlegen
			Name und Kennwort
2. Unter SQL Agent--> Proxykonto : Anmeldeinformation zuweisen einer best. Kategorie zuweisen
3. Einem Auftragsschritt das Proxykonto zuweisen









*/
select from test














*/

select * t1
--Meldung 102, Ebene 15, Status 1, Zeile 28

select * from t2
--Meldung 208, Ebene 16, Status 1, Zeile 31

--Wichtig Ebene:
-
--Ebene 14 Security
--Ebene 15 falsche Syntax
--Ebene 16 Objewkt gibts nicht
--unter 10: sind Infos
--Ebene 17: kack...
--Ebene 25 ist höchste Kategegorie

select * from sysmessages where msglangid=1031 order by 2 desc


/*
--Was muss man tgun, damit jemand am Ende eines Auftrags 
eine Mail bekommt?

1. Operator anlegen (hat Email)
USE [msdb]
GO
EXEC msdb.dbo.sp_add_operator @name=N'NamedesOp', 
		@enabled=1, 
		@pager_days=0, 
		@email_address=N'email@email.mail'
GO

2. Datenbankemail konfigurieren
Mailprofil einrichten SMTP ZUgangsdaten angeben


3. Warnsystem --> Mailprofil zuweisen

4. Agent neu starten




*/

use msdb
exec sp_send_dbmail

NT Service

Proxykonto für Auftragsschritt

1. Sicherheit--> Anmeldeinofmrationen
  hinterlegen vonn Usernbame aus NT und Kennwort
2. Proxyim Agent einrichten und Subsystem zuweisen
3. Im Auftragschritt Subsystem wähöen und Proxy zuweisen

USE [msdb]
GO
EXEC msdb.dbo.sp_add_proxy @proxy_name=N'PS_domadmin',@credential_name=N'DomAdmin', 
		@enabled=1
GO
EXEC msdb.dbo.sp_grant_proxy_to_subsystem @proxy_name=N'PS_domadmin', @subsystem_id=12
GO


USE [msdb]
GO
/****** Object:  Step [Gib mir 500]    Script Date: 25.07.2023 09:56:44 ******/
EXEC msdb.dbo.sp_delete_jobstep @job_id=N'65185120-9aea-446c-ae60-03231b3d4a48', @step_id=5
GO
USE [msdb]
GO
/****** Object:  Step [Gib mir 400]    Script Date: 25.07.2023 09:56:44 ******/
EXEC msdb.dbo.sp_delete_jobstep @job_id=N'65185120-9aea-446c-ae60-03231b3d4a48', @step_id=4
GO
USE [msdb]
GO
/****** Object:  Step [Gib mir 300]    Script Date: 25.07.2023 09:56:44 ******/
EXEC msdb.dbo.sp_delete_jobstep @job_id=N'65185120-9aea-446c-ae60-03231b3d4a48', @step_id=3
GO
USE [msdb]
GO
/****** Object:  Step [Mach Ordner]    Script Date: 25.07.2023 09:56:44 ******/
EXEC msdb.dbo.sp_delete_jobstep @job_id=N'65185120-9aea-446c-ae60-03231b3d4a48', @step_id=2
GO
USE [msdb]
GO
/****** Object:  Step [Gib mir 100]    Script Date: 25.07.2023 09:56:44 ******/
EXEC msdb.dbo.sp_delete_jobstep @job_id=N'65185120-9aea-446c-ae60-03231b3d4a48', @step_id=1
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_jobstep @job_id=N'65185120-9aea-446c-ae60-03231b3d4a48', @step_name=N'Gib mir 100', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_fail_action=2, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'select 100', 
		@database_name=N'master', 
		@flags=0
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_jobstep @job_id=N'65185120-9aea-446c-ae60-03231b3d4a48', @step_name=N'Mach Ordner', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_fail_action=2, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'CmdExec', 
		@command=N'md C:\XXX', 
		@flags=0, 
		@proxy_name=N'CMD_Admin'
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_jobstep @job_id=N'65185120-9aea-446c-ae60-03231b3d4a48', @step_name=N'Gib mir 300', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_fail_action=2, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'select 300', 
		@database_name=N'master', 
		@flags=0
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_jobstep @job_id=N'65185120-9aea-446c-ae60-03231b3d4a48', @step_name=N'Gib mir 400', 
		@step_id=4, 
		@cmdexec_success_code=0, 
		@on_success_action=4, 
		@on_success_step_id=5, 
		@on_fail_action=2, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'select 400', 
		@database_name=N'master', 
		@flags=0
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_jobstep @job_id=N'65185120-9aea-446c-ae60-03231b3d4a48', @step_name=N'Gib mir 500', 
		@step_id=5, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_fail_action=2, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'select 500', 
		@database_name=N'master', 
		@flags=0
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_jobstep @job_id=N'65185120-9aea-446c-ae60-03231b3d4a48', @step_name=N'PS', 
		@step_id=6, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_fail_action=2, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'PowerShell', 
		@command=N'get-list', 
		@database_name=N'master', 
		@flags=0, 
		@proxy_name=N'PS_domadmin'
GO
