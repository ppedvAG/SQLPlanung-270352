/*
================================================================================
  Modul 05 – Sicherung und Wiederherstellung (Backup & Restore)
================================================================================
  Dieses Skript beschreibt die Sicherungsstrategie für SQL Server-Datenbanken,
  die verschiedenen Wiederherstellungsmodelle und typische Restore-Szenarien.

  Wiederherstellungsmodelle (Recovery Models):
  1. Einfach (Simple):
     - Transaktionen werden protokolliert, aber nach COMMIT aus dem T-Log entfernt
     - T-Log kann NICHT gesichert werden → kein Point-in-Time-Restore möglich
     - Geeignet für: Testumgebungen, nicht kritische Datenbanken

  2. Massenprotokolliert (Bulk-Logged):
     - T-Log wird aufgezeichnet und gesichert
     - Massenoperationen (BULK INSERT, SELECT INTO) werden minimal protokolliert
     - Point-in-Time-Restore eingeschränkt, wenn BULK-Befehle vorkamen
     - Geeignet für: Massenimporte, ETL-Prozesse

  3. Vollständig (Full):
     - Alles wird exakt protokolliert → Point-in-Time-Restore bis auf Sekunden möglich
     - T-Log muss regelmäßig gesichert werden, sonst wächst er unbegrenzt!
     - Geeignet für: Alle Produktionsdatenbanken

  Sicherungsarten:
  - Vollsicherung (V):         Alle Datenbankdateien + Zeitpunkt
  - Differenzsicherung (D):    Alle Änderungen seit der letzten Vollsicherung
  - T-Log-Sicherung (T):       Alle Transaktionen seit der letzten T-Log-Sicherung
                               Leert das T-Log und ermöglicht genauen Restore-Zeitpunkt

  Empfohlenes Sicherungsschema: V TTT D TTT D TTT
  (Vollsicherung, dann mehrere T-Log-Sicherungen, dann Differenzsicherung usw.)

  Restore-Strategie richtet sich nach dem Recovery Time Objective (RTO)
  und Recovery Point Objective (RPO) der Anwendung.
================================================================================
*/

-- ============================================================================
-- Sicherungs-Skripte
-- ============================================================================

-- Vollsicherung (Full Backup)
-- Enthält: alle Datenbankdateien, Zeitpunkt der Sicherung
BACKUP DATABASE [Northwind]
    TO DISK = N'C:\_SQLBACKUP\northwind.bak'
    WITH NOFORMAT, NOINIT,
         NAME  = N'Northwind-Vollstaendige-Sicherung',
         SKIP, NOREWIND, NOUNLOAD,
         STATS = 10;
GO

-- Differenzsicherung (Differential Backup)
-- Sichert nur die Änderungen seit der letzten Vollsicherung → schneller, kleiner
BACKUP DATABASE [Northwind]
    TO DISK = N'C:\_SQLBACKUP\northwind.bak'
    WITH DIFFERENTIAL,
         NOFORMAT, NOINIT,
         NAME  = N'Northwind-Differenziell',
         SKIP, NOREWIND, NOUNLOAD,
         STATS = 10;
GO

-- T-Log-Sicherung (Transaction Log Backup)
-- Leert das Protokoll und ermöglicht minutengenaues Wiederherstellen
BACKUP LOG [Northwind]
    TO DISK = N'C:\_SQLBACKUP\northwind.bak'
    WITH NOFORMAT, NOINIT,
         NAME  = N'Northwind-TLog',
         SKIP, NOREWIND, NOUNLOAD,
         STATS = 10;
GO

-- ============================================================================
-- Restore-Szenarien
-- ============================================================================

/*
Szenario 1a: Server komplett ausgefallen, Datenträger aber intakt
    → Datenträgerdateien anfügen (sp_attach_db oder CREATE DATABASE FOR ATTACH)
    → Kein Restore aus Backup notwendig

Szenario 1b: Datendatei intakt, Protokolldatei defekt
    → Protokolldatei entfernen, dann anfügen
    → Es erfolgt ein automatischer Recovery-Prozess

Szenario 1c: Alle Dateien verloren
    → Backup an den erwarteten Pfad kopieren (spart Zeit beim Restore)
    → Falls Pfade abweichen: WITH MOVE anpassen

Szenario 2: Datenbank beschädigt
    → Restore aus Backup mit geringstmöglichem Datenverlust
    → Protokollfragmentsicherung vor dem Restore!

Szenario 3a: Benutzer hat versehentlich Daten geändert (weiß was betroffen ist)
    → Datenbank unter anderem Namen wiederherstellen
    → WITH NORECOVERY verwenden (bis zum gewünschten Zeitpunkt)
    → Dann gezielt Daten zurückschreiben (INSERT/UPDATE)

Szenario 3b: Benutzer hat etwas geändert (weiß nicht was betroffen ist)
    → Vollständigen Restore mit Zeitachse
    → Protokollfragmentsicherung zuerst (BACKUP LOG WITH NO_TRUNCATE)

Szenario 4: Vorsorge vor bekannt riskanter Aktion
    → Datenbank-Snapshot erstellen! (schnell rückgängig zu machen)

Zeitachsen-Beispiel:
    06:00  V  Vollsicherung
    10:00  D  Differenzsicherung
    10:10  T  T-Log-Sicherung
    10:20  T
    10:30  T
    10:34  !  Fehler tritt auf

  Option A (schnell):  Restore bis 10:30 → Datenverlust: ~4 Minuten
  Option B (genauer):  Manuelle T-Log-Sicherung um 10:35, dann Restore bis 10:33
                       → Datenverlust: ~1–2 Minuten
  Option C (optimal):  Protokollfragmentsicherung + Restore mit STOPAT-Zeit
                       → Datenverlust: minimal (Sekunden)
*/

-- ============================================================================
-- Datenbank-Snapshot als "Notfall-Backup" erstellen
-- ============================================================================
USE master;
GO

-- Snapshot erstellen (kopiert keine Daten – nur Zeiger auf Original-Seiten)
CREATE DATABASE SN_Northwind_1152 ON
(
    NAME     = Northwind,                      -- logischer Name der Datendatei
    FILENAME = 'C:\_SQLDB\SN_Northwind_1152.mdf'
)
AS SNAPSHOT OF Northwind;
GO

-- ============================================================================
-- Datenbank aus Snapshot wiederherstellen
-- ============================================================================
-- Alle anderen Snapshots der Originaldatenbank müssen vorher gelöscht werden!
USE MASTER;
GO

RESTORE DATABASE Northwind
FROM DATABASE_SNAPSHOT = 'SN_Northwind_1152';
GO
