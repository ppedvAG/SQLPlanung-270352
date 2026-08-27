/*
================================================================================
  Modul 10 – Wait Statistics (Wartestatistiken) analysieren
================================================================================
  Wartestatistiken zeigen, worauf SQL Server-Threads warten, wenn sie gerade
  nicht aktiv arbeiten. Sie sind das wichtigste Diagnosewerkzeug für
  Performance-Probleme, da sie direkt auf den Engpass hinweisen:

  - PAGEIOLATCH_*:  Festplatten-I/O ist zu langsam (HDD-Problem)
  - CXPACKET:       Parallelisierungsprobleme (MAXDOP zu hoch)
  - LCK_M_*:        Sperrkonflikte zwischen Transaktionen (Blockierungen)
  - SOS_SCHEDULER:  CPU-Engpass (CPU-Überlastung)
  - WRITELOG:       Transaktionsprotokoll-Engpass (Log-I/O zu langsam)
  - RESOURCE_SEMAPHORE: Speicher zu knapp für Abfragen (RAM-Engpass)

  Wichtige Hinweise:
  - Wartezeiten werden kumulativ seit dem letzten Serverstart gespeichert
  - Ein Reset erfolgt beim Neustart von SQL Server
  - Systembedingte Wartezustände (Idle-Waits) sollten herausgefiltert werden
  - Referenz für alle Wait-Typen: https://www.sqlskills.com/help/waits/

  Auswertungsstrategie:
  1. Top-Wartezustände nach Prozentsatz identifizieren
  2. Benigne (systembedingte) Waits ausfiltern
  3. Bedeutung des führenden Wartezustands recherchieren
  4. Gezielt optimieren (Hardware, Konfiguration, Abfragen)
================================================================================
*/

-- ============================================================================
-- Top Wait Statistics (Prozent-Auswertung, benigne Waits herausgefiltert)
-- ============================================================================
-- Diese Abfrage filtert alle systeminternen, harmlosen Wartezustände heraus
-- und zeigt die relevanten Performance-Bottlenecks nach Prozentanteil.

WITH [Waits] AS
(
    SELECT wait_type,
           wait_time_ms / 1000.0                          AS [WaitS],
           (wait_time_ms - signal_wait_time_ms) / 1000.0  AS [ResourceS],
           signal_wait_time_ms / 1000.0                   AS [SignalS],
           waiting_tasks_count                            AS [WaitCount],
           100.0 * wait_time_ms / SUM(wait_time_ms) OVER() AS [Percentage],
           ROW_NUMBER() OVER (ORDER BY wait_time_ms DESC) AS [RowNum]
    FROM   sys.dm_os_wait_stats WITH (NOLOCK)
    WHERE  [wait_type] NOT IN
    (
        -- Service Broker (interne Kommunikation, kein Performance-Problem)
        N'BROKER_EVENTHANDLER',         N'BROKER_RECEIVE_WAITFOR',
        N'BROKER_TASK_STOP',            N'BROKER_TO_FLUSH',
        N'BROKER_TRANSMITTER',
        -- Checkpoint und CLR (systembedingt)
        N'CHECKPOINT_QUEUE',            N'CHKPT',
        N'CLR_AUTO_EVENT',              N'CLR_MANUAL_EVENT',
        N'CLR_SEMAPHORE',
        -- Database Mirroring (systembedingt)
        N'DBMIRROR_DBM_EVENT',          N'DBMIRROR_EVENTS_QUEUE',
        N'DBMIRROR_WORKER_QUEUE',       N'DBMIRRORING_CMD',
        -- Dirty Pages und Dispatcher (systembedingt)
        N'DIRTY_PAGE_POLL',             N'DISPATCHER_QUEUE_SEMAPHORE',
        N'EXECSYNC',                    N'FSAGENT',
        -- Volltextsuche (systembedingt)
        N'FT_IFTS_SCHEDULER_IDLE_WAIT', N'FT_IFTSHC_MUTEX',
        -- Availability Groups (systembedingt)
        N'HADR_CLUSAPI_CALL',           N'HADR_FILESTREAM_IOMGR_IOCOMPLETION',
        N'HADR_LOGCAPTURE_WAIT',        N'HADR_NOTIFICATION_DEQUEUE',
        N'HADR_TIMER_TASK',             N'HADR_WORK_QUEUE',
        -- Lazy Writer, Log Manager, Memory (systembedingt)
        N'KSOURCE_WAKEUP',              N'LAZYWRITER_SLEEP',
        N'LOGMGR_QUEUE',                N'MEMORY_ALLOCATION_EXT',
        N'ONDEMAND_TASK_QUEUE',
        -- Preemptive OS-Aufrufe (systembedingt, vom OS verwaltet)
        N'PREEMPTIVE_HADR_LEASE_MECHANISM',
        N'PREEMPTIVE_SP_SERVER_DIAGNOSTICS',
        N'PREEMPTIVE_OS_LIBRARYOPS',    N'PREEMPTIVE_OS_COMOPS',
        N'PREEMPTIVE_OS_CRYPTOPS',      N'PREEMPTIVE_OS_PIPEOPS',
        N'PREEMPTIVE_OS_AUTHENTICATIONOPS',
        N'PREEMPTIVE_OS_GENERICOPS',    N'PREEMPTIVE_OS_VERIFYTRUST',
        N'PREEMPTIVE_OS_FILEOPS',       N'PREEMPTIVE_OS_DEVICEOPS',
        N'PREEMPTIVE_OS_QUERYREGISTRY', N'PREEMPTIVE_OS_WRITEFILE',
        -- Extended Events (systembedingt)
        N'PREEMPTIVE_XE_CALLBACKEXECUTE',
        N'PREEMPTIVE_XE_DISPATCHER',    N'PREEMPTIVE_XE_GETTARGETSTATE',
        N'PREEMPTIVE_XE_SESSIONCOMMIT', N'PREEMPTIVE_XE_TARGETINIT',
        N'PREEMPTIVE_XE_TARGETFINALIZE',
        -- Initialisierungswaits (nur beim Start, kein Performance-Problem)
        N'PWAIT_ALL_COMPONENTS_INITIALIZED',
        N'PWAIT_DIRECTLOGCONSUMER_GETNEXT',
        -- Query Store (interner Betrieb)
        N'QDS_PERSIST_TASK_MAIN_LOOP_SLEEP',
        N'QDS_ASYNC_QUEUE',
        N'QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP',
        -- Server-Idle-Waits (Leerlauf, kein Problem)
        N'REQUEST_FOR_DEADLOCK_SEARCH', N'RESOURCE_QUEUE',
        N'SERVER_IDLE_CHECK',           N'SLEEP_BPOOL_FLUSH',
        N'SLEEP_DBSTARTUP',             N'SLEEP_DCOMSTARTUP',
        N'SLEEP_MASTERDBREADY',         N'SLEEP_MASTERMDREADY',
        N'SLEEP_MASTERUPGRADED',        N'SLEEP_MSDBSTARTUP',
        N'SLEEP_SYSTEMTASK',            N'SLEEP_TASK',
        N'SLEEP_TEMPDBSTARTUP',         N'SNI_HTTP_ACCEPT',
        N'SP_SERVER_DIAGNOSTICS_SLEEP',
        -- SQL Trace / XEvent (systembedingt)
        N'SQLTRACE_BUFFER_FLUSH',       N'SQLTRACE_INCREMENTAL_FLUSH_SLEEP',
        N'SQLTRACE_WAIT_ENTRIES',
        -- Sonstige harmlose Leerlauf-Waits
        N'WAIT_FOR_RESULTS',            N'WAITFOR',
        N'WAITFOR_TASKSHUTDOWN',
        -- In-Memory OLTP (systembedingt)
        N'WAIT_XTP_HOST_WAIT',          N'WAIT_XTP_OFFLINE_CKPT_NEW_LOG',
        N'WAIT_XTP_CKPT_CLOSE',         N'WAIT_XTP_RECOVERY',
        -- Extended Events Dispatcher (systembedingt)
        N'XE_BUFFERMGR_ALLPROCESSED_EVENT',
        N'XE_DISPATCHER_JOIN',          N'XE_DISPATCHER_WAIT',
        N'XE_LIVE_TARGET_TVF',          N'XE_TIMER_EVENT'
    )
    AND waiting_tasks_count > 0
)
SELECT
    MAX(W1.wait_type)                                    AS [WaitType],
    CAST(MAX(W1.Percentage)        AS DECIMAL(5,2))      AS [Anteil %],
    CAST(MAX(W1.WaitS)  / MAX(W1.WaitCount) AS DECIMAL(16,4)) AS [DurchschnittWait_Sek],
    CAST(MAX(W1.ResourceS) / MAX(W1.WaitCount) AS DECIMAL(16,4)) AS [DurchschnittRessource_Sek],
    CAST(MAX(W1.SignalS) / MAX(W1.WaitCount)  AS DECIMAL(16,4)) AS [DurchschnittSignal_Sek],
    CAST(MAX(W1.WaitS)     AS DECIMAL(16,2))             AS [GesamtWait_Sek],
    CAST(MAX(W1.ResourceS) AS DECIMAL(16,2))             AS [GesamtRessource_Sek],
    CAST(MAX(W1.SignalS)   AS DECIMAL(16,2))             AS [GesamtSignal_Sek],
    MAX(W1.WaitCount)                                    AS [Anzahl Waits],
    CAST(N'https://www.sqlskills.com/help/waits/' + W1.wait_type AS XML) AS [Hilfe-URL]
FROM  Waits AS W1
INNER JOIN Waits AS W2 ON W2.RowNum <= W1.RowNum
GROUP BY   W1.RowNum, W1.wait_type
HAVING     SUM(W2.Percentage) - MAX(W1.Percentage) < 99  -- Zeige bis 99 % der Wartezeit
OPTION     (RECOMPILE);
