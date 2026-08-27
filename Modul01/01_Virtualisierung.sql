/*
================================================================================
  Modul 01 – SQL Server auf virtualisierten Umgebungen (Hyper-V)
================================================================================
  Dieses Skript beschreibt die wichtigsten Planungsüberlegungen, wenn SQL Server
  in einer virtualisierten Umgebung (z. B. Hyper-V oder VMware) betrieben wird.

  Themen:
  - Ressourcen-Parität: Hat die VM dieselben Ressourcen wie ein physischer Server?
  - I/O-Optimierung: Festplatten-Trennung, I/O reduzieren
  - NUMA-Architektur und deren Abbildung in VMs
  - RAM-Verteilung zwischen Host und VMs
  - CPU-Konfiguration und Lizenzüberlegungen

  Grundsatz: Je weniger I/O, desto weniger RAM und CPU werden benötigt.
  I/O → CPU → RAM. Daher ist I/O-Optimierung oberste Priorität.

  Goldene Regel: Trenne Protokolldatei (LDF) von Datendatei (MDF)
  physikalisch – und das pro Datenbank!
================================================================================
*/

-- ============================================================================
-- Kernfrage bei Virtualisierung
-- ============================================================================
-- Hat die VM auch die Ressourcen, die sie auch ohne Virtualisierung hätte?
-- Virtualisierung → Konsolidierung → genug Festplattenleistung?

-- ============================================================================
-- I/O-Optimierung (höchste Priorität)
-- ============================================================================
-- Je weniger I/O, desto geringer der RAM- und CPU-Bedarf:
--   I/O reduzieren  →  weniger RAM-Auslagerungen  →  weniger CPU-Last
--
-- Goldene Regel:
--   Trenne Protokolldatei (LDF) von Datendatei (MDF) physikalisch!
--   Das gilt pro Datenbank, nicht nur global.

-- ============================================================================
-- CPU in Virtuellen Maschinen
-- ============================================================================
-- Bilde in der VM die reale Umgebung (CPU-Topologie) möglichst genau ab.
-- SQL Server nutzt CPU-Informationen für Parallelisierung und NUMA.

-- ============================================================================
-- NUMA (Non-Uniform Memory Access)
-- ============================================================================
-- NUMA-Architektur: Jedem RAM-Sockel (Knoten) gehört ein bestimmter Prozessor.
--   Vorteil: Sehr schneller lokaler Speicherzugriff
--   Nachteil: Zugriff auf RAM eines anderen Sockels erzeugt höhere Latenzzeit
--
-- Problem in VMs: Was, wenn die VM eine andere CPU-Topologie sieht als real?
--   → SQL Server könnte ineffiziente NUMA-Entscheidungen treffen
--
-- Ausnahme: Lizenzgründe (z. B. SQL Express: 1 Sockel / 4 Kerne,
--                          SQL Standard: 4 Sockel / 24 Kerne)

-- ============================================================================
-- RAM-Verteilung in Hyper-V (Beispielrechnung)
-- ============================================================================
-- Gesamt-RAM Host:  16 GB
-- Reserve Host-OS:   4 GB (immer für das Gast-BS reservieren)
-- Verfügbar:        12 GB
--
-- HV-DC   (Domaincontroller): dynamischer Speicher 1.024 MB bis max. 2.048 MB, 2 vCPUs
--                              Verbrauch: ~2 GB
--
-- HV-SQL1 (produktiver SQL):  fixer Speicher 6.000 MB, 4 vCPUs
--                              Hinweis: Fixer Speicher bei SQL Server empfohlen,
--                              damit der Buffer Pool nicht schrumpft.
--
-- HV-SQL2 (zweiter SQL):      fixer Speicher 4.000 MB, 4 vCPUs

-- ============================================================================
-- Aktuelle Beispielausstattung
-- ============================================================================
-- 16 GB RAM, 1 Socket, 1 CPU mit 2 Kernen und 4 logischen Prozessoren
-- NUMA-Zuweisung in Hyper-V entsprechend konfigurieren.
