-- Find if an event exists by its name
-- hree a deadlock report
SELECT s.name, se.event_name
 
FROM sys.dm_xe_sessions s
 
       INNER JOIN sys.dm_xe_session_events se ON (s.address = se.event_session_address) and (event_name = 'xml_deadlock_report')
 
WHERE name = 'system_health'


