
--simple cursor in sql server 
-- declare a cursor
DECLARE update_cursor CURSOR FOR 
SELECT top 10 BeerId from [Pub].[dbo].[Beer] 
WHERE usuario is null

-- open cursor and fetch first row into variables
OPEN update_cursor
FETCH FROM update_cursor

-- check for a new row
WHILE @@FETCH_STATUS=0
BEGIN
-- do update operation
UPDATE [Pub].[dbo].[Beer] 
SET Usuario = 'Andrea'
WHERE CURRENT OF update_cursor 
-- get next available row into variables
FETCH NEXT FROM update_cursor
END
close update_cursor
Deallocate update_cursor