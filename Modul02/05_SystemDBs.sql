/*
================================================================================
  Modul 02 – SQL Server System-Datenbanken und Sicherungsstrategie
================================================================================
  SQL Server wird mit vier System-Datenbanken ausgeliefert, die für den Betrieb
  des gesamten Servers essenziell sind. Dieses Skript beschreibt Zweck,
  Inhalt und Sicherungsempfehlungen für jede dieser Datenbanken sowie die
  grundlegenden Sicherungsarten (Vollsicherung, Differenzsicherung, T-Log).

  System-Datenbanken im Überblick:
  - master:   Das "Herz" des SQL Servers – Login, Datenbanken, Konfiguration
  - model:    Vorlage für alle neu erstellten Datenbanken
  - msdb:     Datenbank für den SQL Server Agent (Jobs, Zeitpläne, DB-Mail, SSIS)
  - tempdb:   Temporärer Arbeitsbereich – wird bei jedem Neustart neu erstellt

  Empfohlene Sicherungsstrategie:
  - Vollsicherung täglich (z. B. nachts um 2:00 Uhr)
  - Differenzsicherung alle paar Stunden
  - T-Log-Sicherung mehrmals täglich (z. B. stündlich)
  - Motto: V TTT D TTT D TTT (Voll, dann mehrere T-Logs, dann Diff, usw.)
================================================================================
*/

-- ============================================================================
-- System-Datenbank: master
-- ============================================================================
-- Enthält: Login-Informationen, Datenbank-Registrierungen, Server-Konfiguration
-- Sicherung: Regelmäßig, nach jeder größeren Konfigurationsänderung
-- → Ohne master startet der SQL Server nicht!

-- ============================================================================
-- System-Datenbank: model
-- ============================================================================
-- Vorlage für alle neu erstellten Datenbanken.
-- Änderungen an der model-DB (Einstellungen, Tabellen) gelten für alle
-- zukünftig erstellten Datenbanken!
--
-- Beispiel: Dateigröße der model-Datendatei anpassen
USE [master];
GO
ALTER DATABASE [model] MODIFY FILE (NAME = N'modeldev', SIZE = 9216KB);
GO
-- Sicherung: Nur notwendig wenn Änderungen vorgenommen wurden.
-- Alternative: Änderungen per Skript dokumentieren.

-- ============================================================================
-- System-Datenbank: msdb
-- ============================================================================
-- Enthält: SQL Agent-Jobs, Zeitpläne, Proxykonten, Warnungen,
--          Datenbank-E-Mail-Konfiguration, SSIS-Pakete, Wartungspläne
-- Sicherung: Regelmäßig! msdb ist die Datenbank, die "am meisten weh tut"
--            wenn sie verloren geht.

-- ============================================================================
-- System-Datenbank: tempdb
-- ============================================================================
-- Enthält: #temp-Tabellen, ##globale Temp-Tabellen, Zeilenversionierung,
--          Index-Rebuild-Zwischenspeicher, Sortierauslagerungen
-- Sicherung: NICHT notwendig – wird bei jedem Neustart neu erstellt
-- Ziel: tempdb so schnell wie möglich machen (eigene Laufwerke!)

-- ============================================================================
-- Weitere Datenbanken (zur Info)
-- ============================================================================
-- distribution:       Wird bei Replikation verwendet
-- mssqlsystemresource: Versteckte System-DB (Black Box – nicht ändern!)

-- ============================================================================
-- Empfohlener Wartungsplan für System-Datenbanken
-- ============================================================================
-- Vollständige Sicherung → SystemDBs → täglich
-- → Unterordner anlegen lassen
-- → Optionen: Prüfsumme + Integritätsprüfung + Kompression
-- → Bei Fehler: Fortsetzen + E-Mail-Benachrichtigung (optional)
-- Sicherungsschema: V TTT D TTT D TTT

-- ============================================================================
-- Sicherungs-Skripte
-- ============================================================================

-- Vollsicherung (Full Backup)
BACKUP DATABASE [TestDb]
    TO DISK = N'C:\_SQLBACKUP\TestDb1.bak'
    WITH NOFORMAT, NOINIT,
         NAME  = N'TestDb-Vollstaendig',
         SKIP, NOREWIND, NOUNLOAD,
         STATS = 10;
GO

-- Differenzsicherung (Differential Backup)
-- Sichert nur die Änderungen seit der letzten Vollsicherung
BACKUP DATABASE [TestDb]
    TO DISK = N'C:\_SQLBACKUP\TestDb.bak'
    WITH DIFFERENTIAL,
         NOFORMAT, NOINIT,
         NAME  = N'TestDb-Differenziell',
         SKIP, NOREWIND, NOUNLOAD,
         STATS = 10;
GO

-- Transaktionsprotokoll-Sicherung (T-Log Backup)
-- Leert das Protokoll und ermöglicht Point-in-Time-Recovery
BACKUP LOG [TestDb]
    TO DISK = N'C:\_SQLBACKUP\TestDb.bak'
    WITH NOFORMAT, NOINIT,
         NAME  = N'TestDb-TLog',
         SKIP, NOREWIND, NOUNLOAD,
         STATS = 10;
GO

-- ============================================================================
-- Sicherungsschema: V TTT D TTT
-- ============================================================================
-- V = Vollsicherung, T = T-Log-Sicherung, D = Differenzsicherung
-- Dieses Schema bietet guten Schutz bei überschaubarem Backup-Volumen.
