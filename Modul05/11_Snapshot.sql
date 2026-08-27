/*
================================================================================
  Modul 05 – Datenbank-Snapshots (Database Snapshots)
================================================================================
  Ein Datenbank-Snapshot ist eine schreibgeschützte, statische Sicht auf eine
  Datenbank zu einem bestimmten Zeitpunkt. Snapshots nutzen Copy-on-Write:
  Geänderte Seiten werden erst in den Snapshot kopiert, wenn sie in der
  Originaldatenbank verändert werden.

  Wichtige Eigenschaften:
  - Snapshots sind NICHT sicherbar (kein BACKUP DATABASE möglich)
  - Die Originaldatenbank KANN gesichert werden (unabhängig vom Snapshot)
  - Mehrere Snapshots einer Datenbank gleichzeitig möglich
  - Ein Snapshot KANN NICHT direkt wiederhergestellt werden (kein normaler Restore)
  - Die Originaldatenbank KANN aus einem Snapshot wiederhergestellt werden,
    aber NUR wenn ALLE anderen Snapshots dieser DB vorher gelöscht werden

  Typischer Anwendungsfall:
  - Vor einer riskanten Aktion (z. B. großes UPDATE) einen Snapshot erstellen
  - Bei Fehler: Datenbank aus dem Snapshot wiederherstellen (schnell!)
  - Unterschiede zwischen Original und Snapshot analysieren (EXCEPT)

  Einschränkungen:
  - Wächst mit jeder Änderung in der Originaldatenbank (Copy-on-Write)
  - Auf demselben SQL Server wie die Originaldatenbank
================================================================================
*/

USE [master];
GO

-- ============================================================================
-- Alle Benutzer aus einer Datenbank trennen (für Admin-Aufgaben)
-- ============================================================================
ALTER DATABASE northwind SET MULTI_USER WITH NO_WAIT;
GO

-- ============================================================================
-- Snapshot erstellen (Syntaxvorlage)
-- ============================================================================
-- NAME     = logischer Name der Datendatei der Originaldatenbank
-- FILENAME = Pfad + Dateiname der neuen Snapshot-Datei (.mdf)
-- SNAPSHOT OF = Name der Originaldatenbank
CREATE DATABASE SnapshotDBName ON
(
    NAME     = LogischerNameDerOrigDatendatei,
    FILENAME = 'C:\PfadZumSnapshot\SnapshotDBName.mdf'
)
AS SNAPSHOT OF OrigDB;
GO

-- ============================================================================
-- Konkretes Beispiel: Snapshot der Northwind-Datenbank
-- ============================================================================
-- Snapshot zum Zeitpunkt 16:16 Uhr erstellen
CREATE DATABASE nw_1616 ON
(
    NAME     = Northwind,            -- logischer Name der Northwind-Datendatei
    FILENAME = 'C:\_SQLDATA\nw_1616.mdf'
)
AS SNAPSHOT OF northwind;
GO

-- ============================================================================
-- Demo: Änderung in der Originaldatenbank
-- ============================================================================
USE northwind;
GO

-- Stadt des Kunden ALFKI ändern (zum Testen des Snapshots)
UPDATE Customers
SET    City = 'XXX'
WHERE  CustomerID = 'ALFKI';

-- Geänderte Daten anzeigen
SELECT * FROM Customers WHERE CustomerID = 'ALFKI';

-- ============================================================================
-- Unterschied zwischen Original und Snapshot zeigen
-- ============================================================================
-- EXCEPT zeigt alle Zeilen, die in Original, aber NICHT im Snapshot vorhanden sind
SELECT * FROM Northwind..Customers
EXCEPT
SELECT * FROM [nw_1616]..Customers;

-- ============================================================================
-- Aktive Verbindungen prüfen
-- ============================================================================
-- Alle Verbindungen zur Northwind-DB und dem Snapshot anzeigen
SELECT *
FROM   sysprocesses
WHERE  spid > 50
  AND  dbid IN (DB_ID('northwind'), DB_ID('nw_1616'));

-- ============================================================================
-- Datenbank aus Snapshot wiederherstellen
-- ============================================================================
-- Voraussetzung: ALLE aktiven Verbindungen zur Originaldatenbank und zum
--               Snapshot müssen vorher getrennt werden!
--               Alle anderen Snapshots dieser DB müssen ebenfalls gelöscht sein.

USE master;
GO

-- Datenbank aus dem Snapshot wiederherstellen
RESTORE DATABASE northwind
FROM DATABASE_SNAPSHOT = 'nw_1616';
GO
