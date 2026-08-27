/*
================================================================================
  Modul 03 – Datenbankobjekte: Views, Prozeduren und Funktionen
================================================================================
  SQL Server bietet verschiedene Wege, Daten abzufragen und Geschäftslogik
  zu kapseln. Dieses Skript stellt die wichtigsten Objekte vor und zeigt,
  wie sie in der Praxis eingesetzt werden.

  Vergleich der Abfragemethoden (nach Geschwindigkeit):
  a) SELECT direkt aus Tabellen mit JOINs
  b) SELECT über eine View (gespeicherte Abfrage)
  c) Ausführen einer gespeicherten Prozedur (2. Aufruf nutzt gecachten Plan)
  d) Aufruf einer Funktion
  Reihenfolge (langsam → schnell): d, a/b, c – ABER: Pläne können variieren!

  Objekte im Überblick:
  - VIEW:      Gespeicherte Abfrage, die sich wie eine Tabelle verhält.
               Enthält keine eigenen Daten. Unterstützt INSERT, UPDATE, DELETE.
  - PROCEDURE: Wie eine Windows-Batch-Datei mit optionalen Parametern.
               Kann mehrere SQL-Anweisungen enthalten (Geschäftslogik).
  - FUNCTION:  Inline-Verwendung in SELECT-Statements möglich.
               Ideal für berechnete Werte pro Zeile (z. B. Bestellsumme).
================================================================================
*/

USE northwind;
GO

-- ============================================================================
-- View erstellen: Kunden-Umsatz-Übersicht
-- ============================================================================
-- Diese View verbindet Kunden, Bestellungen, Bestelldetails und Produkte.
-- Sie kann wie eine Tabelle abgefragt werden.
CREATE VIEW vKundeUmsatz
AS
SELECT c.CompanyName,
       c.City,
       c.Country,
       o.OrderID,
       o.OrderDate,
       o.Freight,
       o.CustomerID,
       od.ProductID,
       od.UnitPrice,
       od.Quantity,
       p.ProductName
FROM       Customers     AS c
INNER JOIN Orders        AS o  ON c.CustomerID = o.CustomerID
INNER JOIN [Order Details] AS od ON o.OrderID  = od.OrderID
INNER JOIN Products      AS p  ON od.ProductID = p.ProductID;
GO

-- View abfragen
SELECT * FROM vKundeUmsatz;
GO

-- ============================================================================
-- Gespeicherte Prozedur: Kunden-Umsatz mit Produktfilter
-- ============================================================================
-- Parameter @par1 enthält die gewünschte Produkt-ID.
-- Beim zweiten Aufruf wird der Ausführungsplan aus dem Cache genutzt → schneller.
CREATE PROC procDemo
    @par1 INT
AS
BEGIN
    SELECT c.CompanyName,
           c.City,
           c.Country,
           o.OrderID,
           o.OrderDate,
           o.Freight,
           o.CustomerID,
           od.ProductID,
           od.UnitPrice,
           od.Quantity,
           p.ProductName
    FROM       Customers     AS c
    INNER JOIN Orders        AS o  ON c.CustomerID = o.CustomerID
    INNER JOIN [Order Details] AS od ON o.OrderID  = od.OrderID
    INNER JOIN Products      AS p  ON od.ProductID = p.ProductID
    WHERE od.ProductID = @par1;
END;
GO

-- ============================================================================
-- Funktion: Bestellsumme für eine Bestellung berechnen
-- ============================================================================
-- Scalar-Funktion gibt einen einzelnen Wert zurück (Datentyp: money).
-- Kann direkt im SELECT-Statement aufgerufen werden.
CREATE FUNCTION dbo.fBestellSumme(@bestNr INT)
RETURNS MONEY
AS
BEGIN
    RETURN (
        SELECT SUM(UnitPrice * Quantity)
        FROM   [Order Details]
        WHERE  OrderID = @bestNr
    );
END;
GO

-- Funktion für eine einzelne Bestellung aufrufen
SELECT dbo.fBestellSumme(10248);

-- Funktion für alle Bestellungen aufrufen (pro Zeile)
SELECT dbo.fBestellSumme(OrderID) AS Bestellsumme,
       *
FROM   Orders;

-- ============================================================================
-- Demo: Verschiedene Filtermethoden (Performance-Vergleich)
-- ============================================================================

-- LIKE-Operator: Für Mustersuchen (langsamer als =, verhindert Index-Nutzung)
SELECT * FROM Customers WHERE CustomerID LIKE 'A%';

-- LEFT-Funktion: Ähnlich wie LIKE, aber verhindert ebenfalls Index-Nutzung
SELECT * FROM Customers WHERE LEFT(CustomerID, 1) = 'A';

-- Gleichheitsoperator: Schnellste Methode, nutzt Index vollständig
SELECT * FROM Customers WHERE CustomerID = 'ALFKI';

-- ============================================================================
-- Demo: Formatierungsbeispiele (Einrückung verbessert Lesbarkeit)
-- ============================================================================

-- Kompakte Schreibweise (schwer lesbar)
SELECT * FROM Customers WHERE CustomerID = 'ALFKI';

-- Empfohlene Schreibweise (gut lesbar, tabellenname und Bedingung getrennt)
SELECT *
FROM   Customers
WHERE  CustomerID = 'ALFKI';
