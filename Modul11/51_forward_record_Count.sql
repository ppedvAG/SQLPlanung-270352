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

-- ============================================================================
-- Was sind Forwarded Records?
-- ============================================================================
-- Ursache: ALTER TABLE ADD COLUMN bei HEAP-Tabellen (ohne Clustered Index)
-- Ablauf:
--   1. Neue Spalte wird hinzugefügt
--   2. Zeilen, die nicht mehr auf die ursprüngliche Seite passen, werden verschoben
--   3. An der ursprünglichen Stelle verbleibt ein "Forwarding Pointer"
--      (Zeiger auf die neue Position)
--   4. Jede Abfrage muss nun:
--      a) Die ursprüngliche Seite lesen (Zeiger)
--      b) Die neue Seite lesen (eigentliche Daten)
--      → Doppelter I/O-Aufwand pro verschobener Zeile!

-- ============================================================================
-- Phänomen messen: DBCC SHOWCONTIG (veraltet, aber anschaulich)
-- ============================================================================
-- Beispiel: 42.186 Seiten in der Tabelle KU
DBCC SHOWCONTIG('ku');  -- Veraltet (deprecated), aber noch nutzbar

-- ============================================================================
-- Moderner Ansatz: sys.dm_db_index_physical_stats
-- ============================================================================
-- forwarded_record_count > 0 → Problem vorhanden!
-- forwarded_record_count = NULL → Clustered Index vorhanden (kein Forwarding möglich)
SELECT *
FROM sys.dm_db_index_physical_stats
    (
        DB_ID(),             -- Aktuelle Datenbank
        OBJECT_ID('ku'),     -- Tabelle 'ku'
        NULL,                -- Alle Indizes
        NULL,                -- Alle Partitionen
        'DETAILED'           -- Detaillierter Modus (zeigt forwarded_record_count)
    );

-- Interpretation:
-- forwarded_record_count = NULL → Clustered Index, kein Problem
-- forwarded_record_count = 0    → HEAP, aber keine verschobenen Zeilen
-- forwarded_record_count > 0    → Problem! Viele Weiterleitungen → Performance leidet

-- ============================================================================
-- Lösung: Clustered Index erstellen
-- ============================================================================
-- Ein Clustered Index reorganisiert die Daten physisch → keine Forwarded Records mehr

-- Clustered Index anlegen (auf geeignete Spalte, z. B. Bestelldatum)
-- CREATE CLUSTERED INDEX IX_KU_OrderDate ON ku (OrderDate);

-- Nach der Erstellung: forwarded_record_count = NULL (kein HEAP mehr)

-- Falls der Clustered Index nicht dauerhaft gewünscht ist:
-- Clustered Index anlegen → Forwarded Records werden automatisch aufgelöst
-- Clustered Index wieder löschen → Tabelle ist wieder ein HEAP, aber sauber

-- ============================================================================
-- Hinweis zu DDL vs. DML
-- ============================================================================
-- DDL (Data Definition Language):  CREATE, ALTER, DROP → Strukturänderungen
-- DML (Data Manipulation Language): INSERT, UPDATE, DELETE → Datenänderungen

-- Forwarded Records entstehen durch DDL auf HEAP-Tabellen (ALTER TABLE ADD COLUMN)
-- → Bevorzuge es, das finale Tabellenschema von Anfang an festzulegen!
