/*
Daten abfragen

a) select * from tabelle join ..join..join

b) select * from view

c) exec procdemo  schneller weil der Plan bereits beim 2ten Aufruf vorliegt

d) select * from f(wert)

A b c d

--langsam nach schnell----------->
d       ab            c

A b c d

--langsam nach schnell----------->es könnte auch das passieren
c                d       ab            



--------------------------
Sicht = gemerkte Abfrage, die sich wie ein Tabelle verhält
aber keine Daten besitzt
kann aber INS Update und delete

Prozedur
wie Windows Batchdatei.. kann Paramter haben
und kann verschiedenste mehrfache Anweisungen enthalten

zentraler Code
Businesslogik


F()
sind extrem praktisch

select f(sP)m f(Wert) from f(Wert) where f(sp) < f(wert)


*/

use northwind;
GO

create view vKundeumsatz
as
SELECT Customers.CompanyName, Customers.City, Customers.Country, 
   Orders.OrderID, Orders.OrderDate, Orders.Freight, Orders.CustomerID, 
   [Order Details].ProductID, [Order Details].UnitPrice, 
   [Order Details].Quantity, Products.ProductName
FROM Customers INNER JOIN
   Orders ON Customers.CustomerID = Orders.CustomerID INNER JOIN
   [Order Details] ON 
   Orders.OrderID = [Order Details].OrderID INNER JOIN
   Products ON [Order Details].ProductID = Products.ProductID
GO

select * from vKundeumsatz


create proc procDemo @par1 int
as
SELECT Customers.CompanyName, Customers.City, Customers.Country, 
   Orders.OrderID, Orders.OrderDate, Orders.Freight, Orders.CustomerID, 
   [Order Details].ProductID, [Order Details].UnitPrice, 
   [Order Details].Quantity, Products.ProductName
FROM Customers INNER JOIN
   Orders ON Customers.CustomerID = Orders.CustomerID INNER JOIN
   [Order Details] ON 
   Orders.OrderID = [Order Details].OrderID INNER JOIN
   Products ON [Order Details].ProductID = Products.ProductID
   where productid = @par
INS
UP
DEL
SEL
INS
UP
DEL


create function fRsumme(@bestnr int) returns money
as
Begin
return (select sum(unitprice * quantity) from [Order Details] where
			orderid = @bestnr)
end

select dbo.fRsumme(10248)

select dbo.frsumme(orderid), * from orders 


select * from [Order Details]


select * from customers where customerid like 'A%'

select * from customers where left(customerid,1) = 'A'





select * from customers where customerid ='ALFKI'

select * 
from 
		customers 
where	customerid ='ALFKI'



select * 
from 
		Customers 
where	Customerid ='ALFKI'

