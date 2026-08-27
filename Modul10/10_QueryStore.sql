Funktionen des Query Stores:
Verfolgen von Abfrageleistung im Zeitverlauf:

Der Query Store speichert sowohl die Ausführungspläne als auch die Laufzeitstatistiken von Abfragen im Zeitverlauf. Dies erlaubt es, Leistungsprobleme nachzuvollziehen und ihre Entwicklung zu analysieren.
Plan Regressionsanalyse:

Es kann vorkommen, dass der SQL Server aus unbekannten Gründen einen weniger effizienten Ausführungsplan verwendet. Der Query Store ermöglicht das Zurücksetzen auf frühere, effizientere Pläne, um die Leistung wiederherzustellen.
Automatisches Plan-Forcing:

Wenn der Server einen schlechteren Plan wählt, kann der Query Store so konfiguriert werden, dass er automatisch zu einem besseren Plan zurückkehrt, ohne dass der Administrator eingreifen muss.
Abfrageleistungs-Diagnose:

Durch das Sammeln von Informationen wie Ausführungszeiten, CPU- und Speicherverbrauch sowie Anzahl der gelesenen und geschriebenen Seiten ist es einfacher, problematische Abfragen zu identifizieren und zu optimieren.
Verlaufsspeicherung:

Der Query Store speichert Daten über mehrere Datenbankneustarts hinweg und bietet so eine konsistente Sicht auf die Performance-Daten.
Architektur:
Richtiger Speicherort: Der Query Store speichert seine Daten in der Datenbank selbst.
Datenquellen: Es gibt zwei Hauptkategorien von Daten:
Query Text: Der SQL-Text der Abfragen.
Execution Plans: Die Ausführungspläne, die der Server für die jeweilige Abfrage erstellt hat.
Laufzeitstatistiken: Informationen wie die Ausführungsdauer, CPU- und Speicherverbrauch.
Konfiguration und Nutzung:
Der Query Store kann auf Datenbankebene aktiviert und konfiguriert werden. Dabei können bestimmte Parameter festgelegt werden, wie z.B. wie lange Abfragedaten aufbewahrt werden sollen oder wie viel Speicherplatz für die gesammelten Daten zur Verfügung steht.

Ein typischer Workflow mit dem Query Store sieht so aus:

Aktivierung des Query Stores auf einer Datenbank.
Sammeln und Analysieren von Leistungsdaten über einen Zeitraum.
Identifizierung von regressiven Ausführungsplänen oder Abfragen mit schlechter Leistung.
Optimierung dieser Abfragen oder Erzwingen besserer Pläne durch Plan-Forcing.
Vorteile:
Langfristige Überwachung: Es werden nicht nur aktuelle, sondern auch historische Leistungsdaten gesammelt.
Transparenz: Der Query Store gibt Einblick in die Arbeitsweise des SQL Servers und macht es einfacher, Leistungsengpässe zu identifizieren und zu beheben.
Problembehebung ohne Unterbrechung: Durch Plan-Forcing können Probleme oft behoben werden, ohne dass die Datenbank neu gestartet oder andere invasive Maßnahmen ergriffen werden müssen.
Zusammengefasst ist der Query Store ein unverzichtbares Werkzeug für das Performance-Tuning und die Diagnose von Abfragen in SQL Server-Datenbanken.