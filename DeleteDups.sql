* SPRT DB Table Row Count */

select o.name , i.rows
from sysindexes i, sysobjects o
where o.id = i.id
and i.indid < 2
and o.type = 'U'
order by i.rows DESC


--Find how many DUPs there are
SELECT scau_row_guid, count(*)
FROM sprt_sc_audit
GROUP BY scau_row_guid
HAVING count(*) > 1
order by count(*)DESC

--Select the duplicate rows into a holding table, eliminating duplicates in the process. 
SELECT scau_row_guid, col3=count(*)
INTO holdkey
FROM sprt_sc_audit
GROUP BY scau_row_guid
HAVING count(*) > 1

/* At this point, the holddups table should have unique PKs, however, 
this will not be the case if t1 had duplicate PKs, yet unique rows (as in the SSN example above). 
Verify that each key in holddups is unique, and that you do not have duplicate keys, yet unique rows. 
If so, you must stop here and reconcile which of the rows you wish to keep for a given duplicate key value. 
For example, the query: */
			
SELECT DISTINCT sprt_sc_audit.*
INTO holddups
FROM sprt_sc_audit, holdkey
WHERE sprt_sc_audit.scau_row_guid = holdkey.scau_row_guid

/*
should return a count of 1 for each row. If yes, proceed to step 5 below. If no, 
you have duplicate keys, yet unique rows, and need to decide which rows to save. 
This will usually entail either discarding a row, or creating a new unique key value for this row. 
Take one of these two steps for each such duplicate PK in the holddups table.
*/

SELECT scau_row_guid, count(*)
FROM holddups
GROUP BY scau_row_guid

-- Delete the duplicate rows from the original table. For example:

DELETE sprt_sc_audit
FROM sprt_sc_audit, holdkey
WHERE sprt_sc_audit.scau_row_guid = holdkey.scau_row_guid

-- Put the unique rows back in the original table. For example:
INSERT sprt_sc_audit SELECT * FROM holddups


select Count(*) from sprt_sc_audit