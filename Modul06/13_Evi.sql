/*
================================================================================
  Modul 06 – Benutzerrechte und Schemas: Demo mit Benutzerin Evi
================================================================================
  Dieses Skript demonstriert die Rechtevergabe für einen Datenbankbenutzer
  namens Evi. Es zeigt, welche Zugriffsrechte auf Schemas und Tabellen
  vergeben wurden und was zu beachten ist.

  Szenario:
  - Evi darf Tabellen im Schema "ma" anlegen
  - Evi darf Tabellen im Schema "it" lesen (nur Lesezugriff)
  - Evi darf NICHT auf dbo.Employees zugreifen (explizit verweigert)

  Wichtige Sicherheitsregel:
  → Normale Benutzer sollten NIEMALS das Recht erhalten,
    Views, Prozeduren oder Funktionen zu erstellen!
  → Begründung: Ein Benutzer mit CREATE VIEW-Rechten kann eine View erstellen,
    die auf Objekte zugreift, auf die er direkt keinen Zugriff hätte.
    Damit umgeht er effektiv die Rechteverwaltung!
================================================================================
*/

-- ============================================================================
-- Demo: Zugriffstest als Benutzer Evi
-- ============================================================================

-- Kunden lesen (allgemeine Tabelle)
SELECT * FROM Customers;

-- Schema-Zugriff: Mitarbeiterdaten (eigener Bereich)
SELECT * FROM ma.Personal;

-- Schema-Zugriff: Projekte im MA-Bereich (erlaubt)
SELECT * FROM ma.Projekte;

-- Schema-Zugriff: IT-Projekte (nur Lesezugriff)
SELECT * FROM it.Projekte;

-- ============================================================================
-- Evi legt eine Testtabelle im eigenen Schema an
-- ============================================================================
-- (Evi hat CREATE TABLE-Rechte im Schema "ma")
CREATE TABLE ma.Test (maTest INT);

-- ============================================================================
-- Evi versucht Tabellen zu verbinden (View-Erstellung)
-- ============================================================================
-- WARNUNG: Dieses Beispiel zeigt, warum CREATE VIEW gefährlich ist!
CREATE VIEW ma.vProjekte
AS
    SELECT * FROM it.Projekte    -- IT-Projekte (Evi hat Lesezugriff)
    UNION ALL
    SELECT * FROM ma.Projekte;   -- MA-Projekte (eigener Bereich)
GO

-- View anzeigen (funktioniert, da beide Quellen erlaubt sind)
SELECT * FROM ma.vProjekte;

-- ============================================================================
-- Sicherheitsproblem: View zeigt verbotene Daten
-- ============================================================================
-- Jetzt ändert Evi die View, um auf dbo.Employees zuzugreifen,
-- obwohl direkter Zugriff verweigert ist!
ALTER VIEW ma.vProjekte
AS
    SELECT * FROM dbo.Employees;  -- Direkter Zugriff wäre für Evi verboten!
GO

-- Evi kann jetzt trotzdem Employees-Daten über die View lesen:
SELECT * FROM ma.vProjekte;

-- ============================================================================
-- Fazit: Sicherheitsregel
-- ============================================================================
-- Gewähre niemals einem normalen Benutzer folgende Rechte:
--   - CREATE VIEW
--   - CREATE PROCEDURE
--   - CREATE FUNCTION
-- → Diese Rechte ermöglichen das Umgehen von Datenzugriffskontrollen!

-- Erlaubter Lesezugriff (MA-Projekte direkt)
SELECT * FROM ma.Projekte;
