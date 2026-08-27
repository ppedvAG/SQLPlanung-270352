/*
================================================================================
  Modul 10 – SQL Server Performance-Diagnose-Werkzeuge
================================================================================
  Für die Diagnose und Optimierung von SQL Server-Performanceproblemen stehen
  verschiedene Werkzeuge zur Verfügung, die sich in ihrer Detailtiefe,
  Systembelastung und Anwendungsgebiet unterscheiden.

  Überblick der Werkzeuge (und wann sie einzusetzen sind):
  1. Aktivitätsmonitor:    Schnelle Ad-hoc-Diagnose, einfach zu bedienen
  2. DMVs:                 Detaillierte T-SQL-Analysen, granular und flexibel
  3. SQL Server Profiler:  Veraltetes Trace-Tool (heute: Extended Events bevorzugen)
  4. Windows Perfmon:      OS + SQL Server-Metriken kombiniert, für Langzeitanalysen
  5. Statistikfunktionen:  Einfache Momentaufnahmen für Skripte (@@CPU_BUSY usw.)
  6. Extended Events:      Modernes, effizientes Event-Tracing (Nachfolger von Profiler)
  7. Datenbank-Optimierungsratgeber (DTA): Index- und Statistikempfehlungen

  Merksatz: Extended Events → für neues Tracing, Profiler → veraltet und overhead-intensiv
================================================================================
*/

/*
============================================================================
1. Aktivitätsmonitor
============================================================================
Wann einsetzen:
  - Schnelle Ad-hoc-Diagnose, wenn eine Anwendung "hängt" oder
    plötzliche Performanceprobleme auftreten
  - Live-Überblick über Sessions, Sperren, Ausführungspläne und Ressourcen

Vorteile:
  - Sofort verfügbar, visuell und einfach zu bedienen
  - Gut für Einsteiger und schnelle Checks

Nachteile:
  - Erhöht leicht den Overhead auf dem Server
  - Kein Logging über längere Zeit möglich
  - Eingeschränkte Detailtiefe

============================================================================
2. Dynamische Verwaltungssichten (DMVs – Dynamic Management Views)
============================================================================
Wann einsetzen:
  - Detaillierte Analysen direkt per T-SQL
  - Performance-Tuning (Abfragestatistiken, Index-Nutzung, Wait-Stats)
  - Eigene Monitoring-Skripte oder Berichte

Vorteile:
  - Sehr granular und flexibel kombinierbar
  - Kein oder kaum spürbarer Overhead

Nachteile:
  - Erfordert SQL-Kenntnisse
  - Viele Werte sind Momentaufnahmen oder werden beim Serverneustart zurückgesetzt

============================================================================
3. Ablaufverfolgung und SQL Server Profiler (VERALTET)
============================================================================
Wann einsetzen:
  - Nur noch wenn ältere Skripte/Prozesse zwingend Profiler nutzen
  - Für gezielte Nachverfolgung in Testumgebungen

Vorteile:
  - Einfach einzurichten, sofortige Live-Anzeige

Nachteile:
  - Hoher Overhead in produktiven Systemen!
  - Microsoft stuft es als veraltet ein → für neue Szenarien Extended Events nutzen

============================================================================
4. Windows Systemmonitor (Perfmon)
============================================================================
Wann einsetzen:
  - SQL Server- und OS-Metriken gemeinsam analysieren
    (CPU, RAM, Festplatten-I/O, Netzwerk)
  - Langzeitaufzeichnungen und historische Performance-Analysen

Vorteile:
  - Betriebs- und SQL-Metriken in einem Tool kombinierbar
  - Sehr geringe Systemlast, ideal für Dauerbetrieb

Nachteile:
  - Weniger tiefe SQL-spezifische Details
  - Auswertung kann umständlich sein (CSV-Export + Analyse nötig)

============================================================================
5. Statistische Systemfunktionen
============================================================================
Wann einsetzen:
  - Für schnelle Einzelwerte in Skripten
  - Beispiele: @@CPU_BUSY, @@IO_BUSY, @@PACK_RECEIVED

Vorteile:
  - Extrem schnell, keine Zusatzlast
  - Leicht in Skripte integrierbar

Nachteile:
  - Sehr begrenzte Aussagekraft
  - Keine Historie oder Korrelation mit anderen Daten

============================================================================
6. Extended Events (XEvents)
============================================================================
Wann einsetzen:
  - Modernes, flexibles und performantes Event-Tracing
  - Lang laufende Abfragen, Deadlocks, Wait-Events oder spezifische Fehler
  - Wenn Profiler-Funktionalität benötigt wird – aber effizienter

Vorteile:
  - Geringer Overhead, auch in Produktion nutzbar
  - Sehr granular konfigurierbar
  - Speicherung im Ring-Buffer oder Datei möglich

Nachteile:
  - Einarbeitung erforderlich (GUI in SSMS oder T-SQL-Definitionen)

============================================================================
7. Datenbankoptimierungsratgeber (Database Tuning Advisor – DTA)
============================================================================
Der DTA analysiert eine Workload (Sammlung von SQL-Abfragen) und gibt
Empfehlungen zur Verbesserung der Abfrageleistung.

Hauptempfehlungen des DTA:
  - Neue Indizes erstellen (geclustert, nicht geclustert, gefiltert, Columnstore)
  - Redundante oder ungenutzte Indizes entfernen
  - Indizierte Sichten erstellen
  - Statistiken erstellen oder aktualisieren
  - Partitionierungsstrategien für große Tabellen

Workflow mit DTA und Query Store:
  1. Query Store als Workload-Quelle auswählen
     (z. B. Top 1000 teuerste Abfragen direkt aus dem Query Store)
  2. Analyse-Datenbank auswählen (zum Zwischenspeichern der DTA-Ergebnisse)
  3. Zieldatenbank und alle Tabellen angeben
  4. Index-Typen auswählen (auch gefilterte Indizes und Columnstore)
     Tipp: Erweiterte Optionen → maximalen Speicherplatz aktivieren
  5. Analyse starten
  6. Analyse NIEMALS abbrechen!
     → Abbruch lässt unsichtbare "hypothetische" Indizes in der DB zurück
     → Diese können das Indexlimit (1000 pro Tabelle) aufbrauchen!
  7. Empfehlungen und SQL-Skripte prüfen und testen

Hinweis zu hypothetischen Indizes:
  Der DTA erstellt intern unsichtbare Indizes zum Testen.
  Nach vollständiger Analyse werden sie automatisch gelöscht.
  Bei Abbruch bleiben sie zurück → manuell bereinigen!
*/
