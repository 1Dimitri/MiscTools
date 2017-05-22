DECLARE @version int
SET @version = (@@microsoftversion / 0x1000000) & 0xff;
IF (@version = 10)
BEGIN
WITH SystemHealth
AS (
SELECT CAST(target_data as xml) AS TargetData
FROM sys.dm_xe_session_targets st
       JOIN sys.dm_xe_sessions s ON s.address = st.event_session_address
WHERE name = 'system_health'
       AND st.target_name = 'ring_buffer')
SELECT XEventData.XEvent.value('(data/value)[1]','VARCHAR(MAX)') AS DeadLockGraph
FROM SystemHealth
       CROSS APPLY TargetData.nodes('//RingBufferTarget/event') AS XEventData (XEvent)
WHERE XEventData.XEvent.value('@name','varchar(4000)') = 'xml_deadlock_report'
END
IF (@version > 10)
BEGIN
WITH SystemHealth
AS (
SELECT CAST(target_data as xml) AS TargetData
FROM sys.dm_xe_session_targets st
       JOIN sys.dm_xe_sessions s ON s.address = st.event_session_address
WHERE name = 'system_health'
AND st.target_name = 'ring_buffer')
SELECT XEventData.XEvent.query('(data/value/deadlock)[1]') AS DeadLockGraph
FROM SystemHealth
       CROSS APPLY TargetData.nodes('//RingBufferTarget/event') AS XEventData (XEvent)
WHERE XEventData.XEvent.value('@name','varchar(4000)') = 'xml_deadlock_report'
END