--use []; /*ingresar nombre de la base de datos*/
--go 
declare @Nombre_Esquema varchar(100) /*opcional*/
declare @Nombre_Tabla varchar(300) /*opcional*/
declare @Nombre_Indice varchar(300) /*opcional*/
declare @Incluye_Filas bit /*obligatorio. 0 (cero) para evitar*/
declare @Nombre_Columna varchar(200) /*opcional*/
declare @ID_Columna_Indice int /*obligatorio. 0 (cero) para evitar*/
declare @Incluye_Fragmentacion bit /*obligatorio. 0 (cero) para evitar*/
declare @Clave_Primaria smallint /*obligatorio. 0 (cero) para evitar | 1 para solo claves primarias | 2 sin claves primarias*/
declare @Incluye_Uso bit /*obligatorio. 0 (cero) para evitar*/set @Nombre_Esquema = ''
set @Nombre_Tabla = '   NOMBRE DE TABLA   '
set @Nombre_Indice = ''
set @Incluye_Filas = 1
set @Nombre_Columna = ''
set @ID_Columna_Indice = 0
set @Incluye_Fragmentacion = 1
set @Clave_Primaria = 0
set @Incluye_Uso = 1;WITH UsoIndice ([Objeto Tabla], [Objeto Indcie], [Cnt Accesos Seek], [Cnt Accesos Scan], [Cnt LookUps], [Ultimo Acceso Seek], [Ultimo Acceso Scan]) AS (
SELECT
object_id,
index_id,
isnull(user_seeks, 0),
isnull(user_scans, 0),
isnull(user_lookups, 0),
isnull(convert(varchar(20), last_user_seek), ''),
isnull(convert(varchar(20), last_user_scan), '')
FROM
sys.dm_db_index_usage_stats
WHERE database_id = DB_ID())/*INFORMACION DE LOS INDICES DE LA TABLA*/
select
o.object_id as [ID Objeto],
'[' + sch.name + ']' as [Nombre Esquema],
'[' + o.name + ']' as [Nombre Tabla],
isnull(convert(varchar, ind.index_id), '') as [ID indice],
'[' + isnull(ind.name, '') + ']' as [Nombre Indice],
case isnull(ind.name, '')
when '' then ''
else case ind.is_primary_key
when 0 then 'NO'
else 'SI'
end
end as [es clave primaria],
case isnull(ind.name, '')
when '' then ''
else case ind.is_unique
when 0 then 'NO'
else 'SI'
end
end as [es UNIQUE],
ind.fill_factor as [Factor de Relleno],
case isnull(ind.is_disabled, 0)
when 0 then 'NO'
else 'SI'
end as [Deshabilitado],
ind.type_desc as [Tipo Indice], --columnas del indice
LTRIM(RTRIM(ISNULL(STUFF((SELECT ', [' + ss.name + ']' +
case isnull(icol.is_descending_key, 0)
when 0 then ''
else ' DESC '
end
FROM sys.indexes x
left join sys.index_columns icol ON icol.index_id = x.index_id
and icol.object_id = o.object_id
left join sys.columns ss on ss.object_id = o.object_id
and ss.column_id = icol.column_id
WHERE x.object_id = o.object_id
and x.index_id = ind.index_id
and icol.is_included_column = 0
order by icol.index_column_id
FOR XML PATH('')),1,1,''), ''))) as [Columnas], --columnas incluidas del indice
ISNULL(STUFF((SELECT ', [' + ss.name + ']'
FROM sys.indexes x
left join sys.index_columns icol ON icol.index_id = x.index_id
and icol.object_id = o.object_id
left join sys.columns ss on ss.object_id = o.object_id
and ss.column_id = icol.column_id
WHERE x.object_id = o.object_id
and x.index_id = ind.index_id
and icol.is_included_column = 1
order by icol.index_column_id
FOR XML PATH('')),1,1,''), '') as [Columnas INCLUDE], case @Incluye_Filas
when 0 then ''
else (SELECT top 1 convert(varchar, p.rows) from sys.partitions p where p.object_id = o.object_id)
end as [Cnt Filas Tabla], ine.dpages [Paginas],
ine.reserved as [Paginas Reservadas],
ine.used as [Paginas usadas],
ine.rowcnt as [Cantidad Filas], /*fragmentacion*/
case @Incluye_Fragmentacion
when 0 then 0
else (select round(avg_fragmentation_in_percent,2) from sys.dm_db_index_physical_stats(DB_ID(), o.object_id, ind.index_id, null,null )
where alloc_unit_type_desc = 'IN_ROW_DATA')
end as [% Fragmentacion], /*uso del indice*/
case @Incluye_Uso
when 0 then ''
else CONVERT(varchar, usi.[Cnt Accesos Seek])
end as [Accesos Seek], case @Incluye_Uso
when 0 then ''
else CONVERT(varchar, usi.[Cnt Accesos Scan])
end as [Accesos Scan], case @Incluye_Uso
when 0 then ''
else CONVERT(varchar, usi.[Cnt LookUps])
end as [Cnt LookUps], case @Incluye_Uso
when 0 then ''
else CONVERT(varchar, usi.[Ultimo Acceso Seek])
end as [Ultimo Acceso Seek], case @Incluye_Uso
when 0 then ''
else CONVERT(varchar, usi.[Ultimo Acceso Scan])
end as [Ultimo Acceso Scan]from sys.objects o
inner join sys.schemas sch ON sch.schema_id = o.schema_id
inner join sys.indexes ind ON ind.object_id = o.object_id
inner join sysindexes ine ON ine.name = ind.name
AND ine.id = o.object_id
left join UsoIndice usi on usi.[Objeto Tabla] = o.object_id
and usi.[Objeto Indcie] = ind.index_id
where o.type = 'U'
and ISNULL(ind.name, '') <> ''
and ((@Nombre_Tabla = '') or (o.name = @Nombre_Tabla))
and ((@Nombre_Esquema = '') or (sch.name = @Nombre_Esquema))
and ((@Nombre_Indice = '') or (ind.name = @Nombre_Indice))
and ((@Clave_Primaria = 0) or (@Clave_Primaria = 1 and ind.is_primary_key = 1) or (@Clave_Primaria = 2 and ind.is_primary_key = 0))
and ((@Nombre_Columna = '') or (@Nombre_Columna in (SELECT cco.name
FROM sys.index_columns cc
INNER JOIN sys.columns cco ON cco.object_id = o.object_id
and cco.column_id = cc.column_id
WHERE cc.object_id = o.object_id
and cc.index_id = ind.index_id
and ((@ID_Columna_Indice = 0) or (cc.index_column_id = @ID_Columna_Indice)))))
order by sch.name, o.name, ind.is_primary_key desc, ind.index_id;
