create table if not exists wardstop5violations5yr as

WITH ranked AS (
	SELECT
		w.*,
		RANK () OVER ( PARTITION BY ward ORDER BY ticket_count DESC ) 
	FROM
		wardsviolations5yr w 
	) SELECT
	* 
FROM
	ranked 
WHERE
	RANK < 6 
ORDER BY
	ward

;
