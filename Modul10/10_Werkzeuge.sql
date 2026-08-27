1. Aktivitätsmonitor
Wann einsetzen:
Schnelle Ad-hoc-Diagnose, wenn z. B. eine Anwendung „hängt“ oder plötzliche Performanceprobleme auftreten.
Um Live-Übersicht zu Sessions, Sperren, Ausführungsplänen und Ressourcennutzung zu bekommen.

Vorteile:
Sofort verfügbar, visuell, einfach zu bedienen.
Gut für Einsteiger oder schnelle Checks.

Nachteile:
Erhöht leicht den Overhead auf dem Server.
Kein Logging über längere Zeit.
Eingeschränkte Detailtiefe.

2. Dynamische Verwaltungssichten (DMVs)
Wann einsetzen:
Für detaillierte Analysen direkt in T-SQL.
Bei Performance Tuning (z. B. Abfrage-Statistiken, Index-Nutzung, Wait-Statistiken).
Für eigene Monitoring-Skripte oder Berichte.
Vorteile:
Sehr granular, flexibel kombinierbar.
Kein oder kaum spürbarer Overhead.
Nachteile:
Erfordert SQL-Know-how.
Viele Werte sind Momentaufnahmen oder werden beim Server-Neustart zurückgesetzt.

3. Ablaufverfolgung & SQL Server Profiler
(Legacy – heute eher XEvents bevorzugen)
Wann einsetzen:
Wenn ältere Skripte oder Prozesse zwingend Profiler nutzen.
Für zielgerichtete Nachverfolgung einzelner Abfragen oder Events in Testumgebungen.
Vorteile:
Einfach einzurichten, sofortige Live-Anzeige.
Nachteile:
Hoher Overhead in produktiven Systemen.
Microsoft stuft es als veraltet ein – für neue Szenarien besser XEvents nutzen.

4. Windows Systemmonitor (Perfmon)
Wann einsetzen:
Wenn SQL Server- und OS-Metriken gemeinsam betrachtet werden müssen (CPU, RAM, Disk-I/O, Netzwerk).
Für Langzeitaufzeichnungen und historische Performance-Analysen.
Vorteile:
Betriebssystem- und SQL-Leistungsindikatoren in einem Tool.
Sehr geringe Systemlast, ideal für Dauerlogging.
Nachteile:
Weniger tiefe SQL-spezifische Details.
Auswertung kann sperrig sein (CSV-Export/Analyse nötig).

5. Statistische Systemfunktionen
Wann einsetzen:
Für schnelle Einzelwerte oder Ad-hoc-Abfragen innerhalb von Skripten.
Wenn DMVs zu „schwer“ erscheinen und nur ein konkreter Wert gebraucht wird (z. B. @@CPU_BUSY, @@IO_BUSY, @@PACK_RECEIVED).
Vorteile:
Extrem schnell, keine Zusatzlast.
Leicht in Skripte integrierbar.
Nachteile:
Sehr begrenzte Aussagekraft.
Keine Historie oder Korrelation mit anderen Daten.

6. Extended Events (XEvents)
Wann einsetzen:
Für moderne, flexible und performante Event-Nachverfolgung.
Um lang laufende Abfragen, Deadlocks, Wait-Events oder bestimmte Fehler präzise zu loggen.
Wenn Profiler-Funktionalität benötigt wird – aber effizienter.
Vorteile:
Geringer Overhead, auch produktiv nutzbar.
Sehr granular konfigurierbar.
Speicherung im Ring-Buffer oder Datei möglich.
Nachteile:
Einarbeitung nötig (GUI in SSMS oder T-SQL-Definitionen).


7. Datenbankoptimierungsratgeber

Der Datenbankoptimierungsratgeber (Database Tuning Advisor, DTA) ist ein Tool 
, das Empfehlungen zur Verbesserung der Abfrageleistung gibt. 
Der Query Store (QS) ist eine Funktion, die Verlaufsdaten zu Abfragen 
und Ausführungsplänen aufzeichnet und es Ihnen ermöglicht, 
Leistungsänderungen zu überwachen und Probleme zu diagnostizieren.


Der Datenbankoptimierungsratgeber (DTA) ist im Wesentlichen ein Analyse- 
und Empfehlungstool. Sie "füttern" ihn mit einer Sammlung von SQL-Abfragen 
(einer "Workload"), und der DTA analysiert diese Workload im Kontext 
Ihres aktuellen Datenbankschemas (Tabellen, vorhandene Indizes usw.).

Basierend auf dieser Analyse gibt der DTA konkrete Empfehlungen ab, 
um die Gesamtleistung dieser Workload zu optimieren.

Die Hauptaufgaben und Empfehlungen des DTA sind:

Index-Empfehlungen: Dies ist die häufigste Verwendung. 
Der DTA schlägt vor:

Neue Indizes zu erstellen (geclustert, nicht geclustert, 
gefiltert und Columnstore).

Bestehende Indizes zu löschen, die redundant sind 
oder nicht verwendet werden.

Indizierte Sichten zu erstellen, um komplexe Aggregationen 
oder Joins zu beschleunigen.

Statistiken: Er kann das Erstellen oder Aktualisieren 
von Spaltenstatistiken empfehlen, um dem Abfrageoptimierer 
bessere Informationen für die Planerstellung zu geben.

Partitionierung: Bei sehr großen Tabellen kann der DTA Strategien 
zur horizontalen Partitionierung vorschlagen.

Der DTA kann den Query Store als direkte Workload-Quelle verwenden. 
Anstatt mühsam eine Trace-Datei zu erstellen, können Sie dem DTA 
einfach sagen, er soll die "Top 1000" teuersten Abfragen direkt
aus dem Query Store analysieren. Dies ist oft der effizienteste Weg, 
um die realen, aktuellen Leistungsprobleme Ihrer Datenbank zu finden 
und zu beheben.


1 .QueryStore als Quelle wählen.
2. Auslastungs DB wählen , um Ergbnisse des DTA zu zwischenspeichern
3. DB auswählen und alle Tabelle angeben
4. Alle Indizes wählen evtl auch gefiltert und Columnstore
   Tipp:: Erweiterte optionen. Max empfohlenen Speicherplatz aktivieren
			und Wert übernehmen 
5. Analyse starten
6. nie abbrechen!
7. Empfehlungen untersuchen (Berichte und SQL Skripte generieren)

