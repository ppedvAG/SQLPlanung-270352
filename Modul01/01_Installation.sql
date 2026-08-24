/*



RAM immer ausreichend
HDD meisten Tuning Optionen
CPU


Security
2 Auth-Verfahren:
Windows / gemischte Auth (Windows+SQL Logins)
--> Gemischte Auth:  sa (alle Rechte)
                     komplexes Kennwort(mind 14 bis 17 Zeichen) deaktivieren
					 dafür ein Ersatzkonto anlegen  saadmin   saMaria
-- Windows Admins sind kein SQL Admin


Diensten

SQL Server (DB)
SQL Agent (jobs)
SQL Volltextsuche 
SQL Browser = Rezeption (Port 1434 UDP)
Im Falle von mehereren INstanzen

KOnten brauchen vorab keine Rechte, aber nur lokal
svcSQL
svcAgent

Firewall!


Datenbankpfaden
TRenne Daten von Logfile physikalisch (2 HDDs oder mehr)
BackupPfad

TempDB
Mülleimer für vieles und viele
#t
RAM AUslagerungen beim Verschätzen von RAM Verbrauch der Abfragen
--Gib der Tempdb eig HDDs und denk dra: Trenne Daten von Log




16GB -4GB für Windows--> 12 GB  4 Kerne
HV-DC DOmController: 2 GB  2 Kerne  RAM Dyn  von 1024 bis 2048
HV-SQL1: 6GB   4 Kerne    RAM fix 6000
HV-SQL2: 4GB   4 Kerne    RAM fix 4000






1 HDD






*/


select * from Kunden where FamName like 'maier'

select soundex('maier')
select soundex('meyr')










