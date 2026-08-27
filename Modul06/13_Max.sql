/*
================================================================================
  Modul 06 – Benutzerrechte und Schemas: Demo mit Benutzer Max
================================================================================
  Dieses Skript demonstriert die Zugriffsrechte für den Benutzer Max.
  Max hat Zugriff auf das Schema "it" (IT-Abteilung) und kann dort
  Mitarbeiterdaten und Projektdaten lesen.

  Im Gegensatz zu Evi (MA-Schema) hat Max nur Zugriff auf IT-Objekte.
  Schemabasierte Rechtevergabe ermöglicht klare Trennung von Zuständigkeiten.

  Szenario:
  - Max darf it.Personal lesen
  - Max darf it.Projekte lesen
  - Max hat keinen Zugriff auf das MA-Schema
  - Max hat keinen Zugriff auf dbo-Objekte (außer explizit gewährt)

  Empfehlung: Rechte immer über Rollen vergeben, nicht direkt an Benutzer!
================================================================================
*/

-- ============================================================================
-- Demo: Zugriffstest als Benutzer Max
-- ============================================================================

-- IT-Mitarbeiterdaten lesen (Max hat Zugriff auf it-Schema)
SELECT * FROM it.Personal;

-- IT-Projekte lesen
SELECT * FROM it.Projekte;

-- Versuch, alle Projekte ohne Schema-Angabe zu lesen
-- → Schlägt fehl, wenn kein Standard-Schema oder Standardschema kein Zugriff
SELECT * FROM Projekte;
