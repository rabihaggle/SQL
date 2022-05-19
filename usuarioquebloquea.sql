USE [master]
GO
SELECT   w.session_id
 ,w.wait_duration_ms
 ,w.wait_type
 ,w.blocking_session_id
 ,w.resource_description
 ,s.program_name
 ,t.text
 ,t.dbid
 ,s.cpu_time
 ,s.memory_usage
FROM sys.dm_os_waiting_tasks w
INNER JOIN sys.dm_exec_sessions s
ON w.session_id = s.session_id
INNER JOIN sys.dm_exec_requests r
ON s.session_id = r.session_id
OUTER APPLY sys.dm_exec_sql_text (r.sql_handle) t
WHERE s.is_user_process = 1
GO

USE master
GO
EXEC sp_who 'active';
EXEC sp_who2 'active';
GO

USE MASTER
go

SELECT  bloqueante.session_id as SesionBloqueante,
bloqueante.client_net_address as HostBloqueante,
bloqueada.session_id as SesionBloqueada,
OBJECT_NAME(SUBSTRING(resource_description,
PATINDEX('%associatedObjectId%', resource_description) + 19,
LEN(resource_description))) as ObjetoBloqueado,
TSQLBloqueante.text as SentenciaBloqueante,
TSQLBloqueada.text as SentenciaBloqueada
FROM     sys.dm_exec_connections AS bloqueante
INNER JOIN sys.dm_exec_requests bloqueada ON bloqueante.session_id = bloqueada.blocking_session_id
INNER JOIN sys.dm_os_waiting_tasks waitstats ON waitstats.session_id = bloqueada.session_id
CROSS APPLY sys.dm_exec_sql_text(bloqueante.most_recent_sql_handle) AS TSQLBloqueante
CROSS APPLY sys.dm_exec_sql_text(bloqueada.sql_handle) AS TSQLBloqueada
