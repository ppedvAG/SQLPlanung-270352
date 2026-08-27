/*
================================================================================
  Modul 01 – SQL Server Installation: Planungsgrundlagen
================================================================================
  Dieses Skript fasst die wichtigsten Planungs- und Konfigurationsentscheidungen
  zusammen, die vor und während der Installation eines SQL Servers getroffen
  werden müssen.

  Themen:
  - Hardware-Anforderungen: RAM, CPU, Festplatten
  - Sicherheitsmodell: Windows-Auth vs. gemischte Authentifizierung
  - Dienste und Dienstkonten (SQL Server, SQL Agent, Browser usw.)
  - Firewall-Konfiguration (Port 1433 TCP / 1434 UDP)
  - Datenbankpfade: Trennung von Datendateien und Transaktionsprotokoll
  - TempDB-Konfiguration
  - Speicherzuweisung für Hyper-V-Umgebungen

  Hinweis: Der SQL Server SA-Account sollte deaktiviert und durch einen
  benannten Administrator-Account (z. B. "saAdmin") ersetzt werden.
  Windows-Administratoren sind NICHT automatisch SQL Server-Administratoren.
================================================================================
*/

-- ============================================================================
-- Hardware-Empfehlungen
-- ============================================================================
-- RAM:   Immer ausreichend dimensionieren; RAM ist der wichtigste Faktor
-- HDD:   Bietet die meisten Tuning-Optionen → I/O trennen und optimieren
-- CPU:   Ausreichend Kerne, aber nicht überdimensionieren (MAXDOP beachten)

-- ============================================================================
-- Sicherheit: Authentifizierungsverfahren
-- ============================================================================
-- SQL Server unterstützt zwei Authentifizierungsmodi:
--   1. Windows-Authentifizierung (empfohlen)
--   2. Gemischte Authentifizierung (Windows + SQL Logins)
--
-- Bei gemischter Authentifizierung:
--   - SA-Account: Besitzt alle Rechte → komplexes Passwort (mind. 14–17 Zeichen)
--   - SA-Account deaktivieren und Ersatzkonto anlegen (z. B. "saAdmin")
--   - Windows-Admins sind KEINE automatischen SQL Server-Admins!

-- ============================================================================
-- Dienste
-- ============================================================================
-- SQL Server (DB-Engine)   → Kernkomponente
-- SQL Server Agent         → Für geplante Jobs und Automatisierungen
-- SQL Server Volltextsuche → Für Volltextindizes
-- SQL Server Browser       → Rezeption für benannte Instanzen (Port 1434 UDP)
--                            Notwendig bei mehreren Instanzen auf einem Server

-- ============================================================================
-- Dienstkonten (vor der Installation anlegen)
-- ============================================================================
-- Konten benötigen vorab keine besonderen Rechte – das Setup richtet sie ein.
-- Beispiel-Konten: svcSQL (für DB-Engine), svcAgent (für SQL Agent)
-- Für Netzwerkzugriffe (z. B. Netzwerk-Backups) Domänenkonten verwenden.

-- ============================================================================
-- Firewall
-- ============================================================================
-- Standardport SQL Server: TCP 1433
-- SQL Server Browser:      UDP 1434 (nur bei benannten Instanzen notwendig)

-- ============================================================================
-- Datenbankpfade (Best Practice)
-- ============================================================================
-- Datendateien (.mdf/.ndf) und Protokolldateien (.ldf) PHYSISCH trennen!
-- → Separate Festplatten oder Storage-Volumes verwenden
-- Backup-Pfad auf eigenem Laufwerk

-- TempDB-Empfehlung:
-- TempDB wird für temporäre Tabellen, Zeilenversionierung,
-- Sortierungen und Index-Rebuilds verwendet.
-- → Eigene Festplatten für TempDB empfohlen
-- → Datendatei und Protokolldatei der TempDB ebenfalls trennen
-- → Anzahl der TempDB-Datendateien = Anzahl der CPU-Kerne (max. 8)

-- ============================================================================
-- RAM-Verteilung in einer Hyper-V-Umgebung (Beispielrechnung)
-- ============================================================================
-- Gesamt-RAM Host:  16 GB
-- Reserve Windows:   4 GB
-- Verfügbar:        12 GB
--
-- HV-DC (Domain Controller): dynamischer Speicher 1.024–2.048 MB, 2 vCPUs
-- HV-SQL1 (produktiver SQL): fixer Speicher 6.000 MB, 4 vCPUs
-- HV-SQL2 (zweiter SQL):     fixer Speicher 4.000 MB, 4 vCPUs

-- ============================================================================
-- Demo-Abfragen (Phonetische Suche mit SOUNDEX)
-- ============================================================================

-- Einfache Suche nach Nachnamen (Beispiel, Groß-/Kleinschreibung beachten)
SELECT *
FROM   Kunden
WHERE  FamName LIKE 'maier';

-- SOUNDEX-Vergleich: Findet klanglich ähnliche Namen
-- Beide Varianten erzeugen denselben SOUNDEX-Code → werden als gleich erkannt
SELECT SOUNDEX('maier');   -- M600
SELECT SOUNDEX('meyr');    -- M600
