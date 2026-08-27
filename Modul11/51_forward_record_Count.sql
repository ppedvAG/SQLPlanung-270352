/*
Thema: Forwarded Records und ihre Performance-Folgen.
Diese Datei erklärt, warum HEAP-Tabellen nach Änderungen fragmentieren können.
Wenn Zeilen wachsen, werden sie teils verschoben und nur noch weitergeleitet.
Für Anfänger wichtig: Solche Weiterleitungen erhöhen Seitenzugriffe deutlich.
Dadurch werden Scans teurer und Abfragen insgesamt langsamer.
Das Skript zeigt Messungen mit DBCC und DMV-Auswertungen.
So wird sichtbar, warum gelesene Seiten oft höher sind als erwartet.
Ein zentraler Lösungsansatz ist ein passender Clustered Index.
Damit werden Forwarded Records vermieden oder reduziert.
Ziel ist, Speicherlayout und Laufzeitverhalten besser zu verstehen.
*/

--Design Phänomene

--forward Record Counts
--kommt durch Hinzufügen von Spalten zu bestehenden Tabellen
--14000 Seiten mehr als Tabelle hat???

--Alter  !!

--Table Scan 56000

dbcc showcontig('ku')--42186


--der dbcc ist veraltet.. hier hilft der Befehl 

select * from sys.dm_db_index_physical_stats
		(db_id(), object_id('ku'),null,null,'detailed')

--forwarded_record_count immer NUll oder 0 sein

-- der forwardRecordCount sollte immer NULL oder 0 sein

-- im Falle von Clustered Indizes wird es immer NULL sein

--sond forwardrecordcounts vorhanden--> CL IX erstellen
--und falls der nicht erwünscht ist wieder löschen
:-)

--TRIGGER: INS UP DEL   DML

--DDL: CR ALTER DROP