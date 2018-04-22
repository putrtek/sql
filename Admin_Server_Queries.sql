SELECT 
          SERVERPROPERTY('MachineName') as Host,
          SERVERPROPERTY('InstanceName') as Instance,
          SERVERPROPERTY('Edition') as Edition, /*shows 32 bit or 64 bit*/
          SERVERPROPERTY('ProductLevel') as ProductLevel, /* RTM or SP1 etc*/
          Case SERVERPROPERTY('IsClustered') when 1 then 'CLUSTERED' else 'STANDALONE' end as ServerType,
          @@VERSION as VersionNumber
	  serverproperty('Collation') as Collation
	  serverproperty('ServerName')
	  serverproperty('IsIntegratedSecurityOnly') --1 = Integrated security. 0 = Not Integrated security.
	  serverproperty('LicenseType')PER_SEAT = Per Seat mode ; PER_PROCESSOR = Per-processor mode; DISABLED = Licensing is disabled.
	  serverproperty('ProductVersion')
	  serverproperty('SQLSortOrderName')
	  serverproperty('EngineEdition') 1 = Personal ; 2 = Standard ; 3 = Enterprise ; 4 = Express ; 5 = SQL Database
---------------------------------------------------
Another important bit of information that you need to know as a DBA is all of the traces that are enabled. The following T-SQL statement will list all of the trace flags that are enabled gloabally on the server. Refer Fig 1.4

DBCC TRACESTATUS(-1);The following T-SQL statement will list all the trace flags that are enabled on the current sql server connection. Refer Fig 1.4

DBCC TRACESTATUS();
-------------------------------------------------
SELECT name,compatibility_level,recovery_model_desc,state_desc  FROM sys.databases
--------------------------------------------
Backup of a database is bread and butter for database administrators. The following T-SQL Statement lists all of the databases in the server and the last day the backup happened. This will help the database administrators to check the backup jobs and also to make sure backups are happening for all the databases. Refer Fig 1.10

SELECT  @@Servername AS ServerName ,
        d.Name AS DBName ,
        b.Backup_finish_date ,
        bmf.Physical_Device_name
FROM    sys.databases d
        INNER JOIN msdb..backupset b ON b.database_name = d.name AND b.[type] = 'D'
        INNER JOIN msdb.dbo.backupmediafamily bmf ON b.media_set_id = bmf.media_set_id
	ORDER BY d.NAME , b.Backup_finish_date DESC; 

--------------------------------------------------------------------------------------
-- Get records with MAX Date only
select OrderNO,
       PartCode,
       Quantity
from (select OrderNO,
             PartCode,
             Quantity,
             row_number() over(partition by OrderNO order by DateEntered desc) as rn
      from YourTable) as T
where rn = 1      
---------------------------------------

SELECT  sp1.[name] AS 'login' , sp2.[name] AS 'role' 
FROM  sys.server_principals sp1 
  JOIN sys.server_role_members srm ON sp1.principal_id = srm.member_principal_id 
  JOIN sys.server_principals sp2  ON srm.role_principal_id = sp2.principal_id 
WHERE sp2.[name] = 'sysadmin'; 
----------

-- Auditing SQL Server Permissions and Roles for the Server
SELECT SP1.[name] AS 'Login', 'Role: ' + SP2.[name] COLLATE DATABASE_DEFAULT AS 'ServerPermission'  
FROM sys.server_principals SP1 
  JOIN sys.server_role_members SRM     ON SP1.principal_id = SRM.member_principal_id 
  JOIN sys.server_principals SP2      ON SRM.role_principal_id = SP2.principal_id 
UNION ALL 
SELECT SP.[name] AS 'Login' , SPerm.state_desc + ' ' + SPerm.permission_name COLLATE DATABASE_DEFAULT AS 'ServerPermission'  FROM sys.server_principals SP  
  JOIN sys.server_permissions SPerm     ON SP.principal_id = SPerm.grantee_principal_id  
ORDER BY [Login], [ServerPermission]; 

----------------------------------

-- How to find out what SQL Server rights have been granted to the Public role

•sys.database_principals - stores records relating to database principals ?name - name of the server principal 
?principal_id - id for the principal, used to link to sys.database_permissions 
?type - type of principal (in this case we're specifically interested in Database Role, signified by a value of 'R') 

•sys.database_permissions - returns a row for each permission in your SQL Server database ?class_desc - object type for the permission 
?major_id - ID of the object the permission is granted on foreign key for sys.sysobjects.id 
?grantee_principal_id - ID of the database principal for which the right is being granted 
?permission_name - such as SELECT, EXECUTE... 
?state_desc - permission state description

•sys.sysobjects - returns a row for each securable object in the SQL Server instance ?id - id of the object 
?name - name of the database object 
?type - type of object.  For a full listing of object type codes please consult Microsoft Books Online. 
?uid - id of the schema owner for the object

SELECT SDP.state_desc, SDP.permission_name, SSU.[name] AS "Schema" SSO.[name], SSO.[type] 
FROM sys.sysobjects SSO 
INNER JOIN sys.database_permissions SDP ON SSO.id = SDP.major_id  
INNER JOIN sys.sysusers SSU ON SSO.uid = SSU.uid 
ORDER BY SSU.[name], SSO.[name]

---------------------------------------
-- VIEWs
SELECT  @@Servername AS ServerName ,
        DB_NAME() AS DBName ,
        o.name AS ViewName ,
        o.[Type] ,
        o.create_date
FROM    sys.objects o
WHERE   o.[Type] = 'V' -- View  
ORDER BY o.NAME 

 

--OR  

SELECT  @@Servername AS ServerName ,
        DB_NAME() AS DBName ,
        Name AS ViewName ,
        create_date
FROM    sys.Views
ORDER BY Name  

--OR

SELECT  @@Servername AS ServerName ,
        TABLE_CATALOG ,
        TABLE_SCHEMA ,
        TABLE_NAME ,
        TABLE_TYPE
FROM     INFORMATION_SCHEMA.TABLES
WHERE   TABLE_TYPE = 'VIEW'
ORDER BY TABLE_NAME 

--OR  

-- View details (Show the CREATE VIEW Code)  

SELECT  @@Servername AS ServerName ,
        DB_NAME() AS DB_Name ,
        o.name AS 'ViewName' ,
        o.Type ,
        o.create_date ,
        sm.[DEFINITION] AS 'View script'
FROM    sys.objects o
        INNER JOIN sys.sql_modules sm ON o.object_id = sm.OBJECT_ID
WHERE   o.Type = 'V' -- View  
ORDER BY o.NAME;
GO
----------------------------------

-- Stored Procedures  

SELECT  @@Servername AS ServerName ,
        DB_NAME() AS DBName ,
        o.name AS StoredProcedureName ,
        o.[Type] ,
        o.create_date
FROM    sys.objects o
WHERE   o.[Type] = 'P' -- Stored Procedures 
ORDER BY o.name

--OR  

-- Stored Procedure details  

SELECT  @@Servername AS ServerName ,
        DB_NAME() AS DB_Name ,
        o.name AS 'ViewName' ,
        o.[type] ,
        o.Create_date ,
        sm.[definition] AS 'Stored Procedure script'
FROM    sys.objects o
        INNER JOIN sys.sql_modules sm ON o.object_id = sm.object_id
WHERE   o.[type] = 'P' -- Stored Procedures 
        -- AND sm.[definition] LIKE '%insert%'
        -- AND sm.[definition] LIKE '%update%'
        -- AND sm.[definition] LIKE '%delete%'
        -- AND sm.[definition] LIKE '%tablename%'
ORDER BY o.name;

GO
----------------------------------
-- Functions  

SELECT  @@Servername AS ServerName ,
        DB_NAME() AS DB_Name ,
        o.name AS 'Functions' ,
        o.[Type] ,
        o.create_date
FROM    sys.objects o
WHERE   o.Type = 'FN' -- Function  
ORDER BY o.NAME;

--OR  

-- Function details  

SELECT  @@Servername AS ServerName ,
        DB_NAME() AS DB_Name ,
        o.name AS 'FunctionName' ,
        o.[type] ,
        o.create_date ,
        sm.[DEFINITION] AS 'Function script'
FROM    sys.objects o
        INNER JOIN sys.sql_modules sm ON o.object_id = sm.OBJECT_ID
WHERE   o.[Type] = 'FN' -- Function  
ORDER BY o.NAME;

GO
----------------------------------------
-- Table Triggers  

SELECT  @@Servername AS ServerName ,
        DB_NAME() AS DBName ,
        parent.name AS TableName ,
        o.name AS TriggerName ,
        o.[Type] ,
        o.create_date
FROM    sys.objects o
        INNER JOIN sys.objects parent ON o.parent_object_id = parent.object_id
WHERE   o.Type = 'TR' -- Triggers  
ORDER BY parent.name , o.NAME 

--OR  

SELECT  @@Servername AS ServerName ,
        DB_NAME() AS DB_Name ,
        Parent_id ,
        name AS TriggerName ,
        create_date
FROM    sys.triggers
WHERE   parent_class = 1
ORDER BY name;

--OR  

-- Trigger Details  

SELECT  @@Servername AS ServerName ,
        DB_NAME() AS DB_Name ,
        OBJECT_NAME(Parent_object_id) AS TableName ,
        o.name AS 'TriggerName' ,
        o.Type ,
        o.create_date ,
        sm.[DEFINITION] AS 'Trigger script'
FROM    sys.objects o
        INNER JOIN sys.sql_modules sm ON o.object_id = sm.OBJECT_ID
WHERE   o.Type = 'TR' -- Triggers  
ORDER BY o.NAME;

GO
--------------------------------------------

-- Check Constraints  

SELECT  @@Servername AS ServerName ,
        DB_NAME() AS DBName ,
        parent.name AS 'TableName' ,
        o.name AS 'Constraints' ,
        o.[Type] ,
        o.create_date
FROM    sys.objects o
        INNER JOIN sys.objects parent
               ON o.parent_object_id = parent.object_id
WHERE   o.Type = 'C' -- Check Constraints 
ORDER BY parent.name ,

        o.name 

--OR  

--CHECK constriant definitions

SELECT  @@Servername AS ServerName ,
        DB_NAME() AS DBName ,
        OBJECT_SCHEMA_NAME(parent_object_id) AS SchemaName ,
        OBJECT_NAME(parent_object_id) AS TableName ,
        parent_column_id AS  Column_NBR ,
        Name AS  CheckConstraintName ,
        type ,
        type_desc ,
        create_date ,
        OBJECT_DEFINITION(object_id) AS CheckConstraintDefinition
FROM    sys.Check_constraints
ORDER BY TableName ,
        SchemaName ,
        Column_NBR 

GO
