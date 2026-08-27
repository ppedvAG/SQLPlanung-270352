/*
================================================================================
  Modul 01 – SQL Server Setup: Konfigurationsdetails nach der Installation
================================================================================
  Dieses Skript dokumentiert die wesentlichen Einstellungen, die während oder
  unmittelbar nach dem SQL Server Setup vorgenommen werden sollten.

  Themen:
  - Dienstkonten: NT Service vs. Domänenkonten
  - Dateiinitialisierung (Volumewartungsaufgabe)
  - Verzeichnistrennung: Daten- und Protokolldateien
  - MAXDOP-Empfehlung (eigenes Kapitel)
  - TempDB-Konfiguration: Dateienanzahl und Traceflags
  - Speicherlimits (MAX/MIN Server Memory)
  - Virtuelle Maschinen: Ressourcenzuweisung anpassen

  Wichtig: Wenn die VM nachträglich angepasst wird (RAM, CPUs), müssen
  auch die SQL Server-Einstellungen entsprechend aktualisiert werden!
================================================================================
*/

-- ============================================================================
-- Dienstkonten
-- ============================================================================
-- Option A: NT Service-Konten (lokale, selbstverwaltende Dienstkonten)
--   - Kein Kennwort notwendig
--   - Nur lokaler Zugriff – für Netzwerk-Backups ungeeignet
--
-- Option B: Domänenkonten (empfohlen für Produktionsumgebungen)
--   - Benötigen vorab keine besonderen Rechte
--   - Das Setup trägt die benötigten Rechte lokal ein
--   - Ermöglichen Netzwerkzugriff (z. B. auf Netzwerk-Backup-Shares)
--
-- Beispielkonten: svcSQL (DB-Engine), svcAgent (SQL Agent)

-- ============================================================================
-- Volumewartungsaufgabe (Instant File Initialization)
-- ============================================================================
-- Standard-Windows-Verhalten:
--   Jede Dateierweiterung erfordert das doppelte Schreibvolumen,
--   weil Windows die Datei zunächst mit Nullen füllt (Sicherheitsfeature).
--
-- Wenn die Volumewartungsaufgabe aktiviert ist:
--   → SQL Server kann Datendateien sofort erweitern ohne Nullen-Initialisierung
--   → Erheblich schnellere Dateioperationen
--   → Konfiguriert über: Lokale Sicherheitsrichtlinien
--                         → Zuweisen von Benutzerrechten
--                         → "Durchführen von Volumewartungsaufgaben"
--
-- Hinweis: Gilt NUR für Datendateien (.mdf/.ndf), NICHT für Protokolldateien.
-- Ein gutes I/O-Design macht dies weniger kritisch, aber es lohnt sich trotzdem.

-- ============================================================================
-- Verzeichnisse (Trennung von Daten und Protokoll)
-- ============================================================================
-- Bestes Vorgehen: Datendateien und Protokolldateien auf getrennten Laufwerken
-- Backup-Pfad auf einem dritten, separaten Laufwerk

-- ============================================================================
-- TempDB-Konfiguration
-- ============================================================================
-- TempDB wird genutzt für:
--   - Temporäre Tabellen (#temp, ##global)
--   - Zeilenversionierung (Snapshot-Isolation)
--   - Index-Rebuilds
--   - Auslagerungen beim Sortieren (wenn RAM knapp)
--
-- Empfehlungen:
--   - Eigene Laufwerke für TempDB
--   - Datendatei und Protokolldatei der TempDB trennen
--   - Anzahl der Datendateien = Anzahl der CPU-Kerne (max. 8)
--   - Traceflag 1117: Uniform Extents → kein gleichzeitiger Zugriff auf denselben Block
--   - Traceflag 1118: Gleichmäßige Dateigröße → Mechanismus nicht aushebeln!
--
-- Hinweis: Ab SQL Server 2016 sind TF 1117 und 1118 für TempDB standardmäßig aktiv.

-- ============================================================================
-- Arbeitsspeicher-Konfiguration (MAX/MIN Server Memory)
-- ============================================================================
-- MAX Server Memory IMMER einstellen!
--   Berechnung: Gesamt-RAM - OS-Bedarf - sonstige Dienste
--   Beispiel: 16 GB - 4 GB (OS) = 12 GB MAX Server Memory
--
-- MIN Server Memory: Nur sinnvoll bei mehreren SQL-Instanzen (Konkurrenz um RAM)
--   Der MIN-Wert wird erst belegt, wenn SQL Server entsprechend Daten geladen hat.
--
-- Sharepoint-Hinweis: SP drosselt Dienste bei >95 % RAM-Auslastung
-- → SQL Server RAM-Limit schützt das Gesamtsystem

-- ============================================================================
-- Konfigurationsübersicht: HV-SQL1 (Produktivserver)
-- ============================================================================
-- Gesamt-RAM:    6 GB (fixer Speicher in Hyper-V)
-- CPU-Kerne:     4 vCPUs
-- Laufwerk:      C:\ (Beispiel – in Produktion trennen!)
--
-- MAXDOP:        4 (entspricht der Kernanzahl)
-- MAX RAM:       3.800 MB (~3,8 GB, ca. 200 MB Reserve für OS)
-- TempDB:        4 Datendateien (entspricht Kernanzahl)
-- MDF + LDF:     physisch getrennte Laufwerke
-- Backup:        separater Pfad/Laufwerk
-- Authentifizierung: gemischte Auth (Windows + SQL)

-- ============================================================================
-- Konfigurationsübersicht: HV-SQL2 (zweiter Server)
-- ============================================================================
-- Gesamt-RAM:    4 GB (fixer Speicher in Hyper-V)
-- CPU-Kerne:     4 vCPUs

-- ============================================================================
-- RAM-Planung für Hyper-V-Host (Gesamtübersicht)
-- ============================================================================
-- Host gesamt:        16 GB
-- Reserve Host-OS:     4 GB
-- HV-DC:               dynamisch 1.024–2.048 MB, 2 vCPUs
-- HV-SQL1:             fix 5.000 MB, 4 vCPUs
-- HV-SQL2:             fix 4.500 MB, 4 vCPUs
