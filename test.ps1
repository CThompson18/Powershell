Clear-Host
#######################

<#
.SYNOPSIS
Writes data only to SQL Server tables.
.DESCRIPTION
Writes data only to SQL Server tables. However, the data source is not limited to SQL Server; any data source can be used, as long as the data can be loaded to a DataTable instance or read with a IDataReader instance.
.INPUTS
None
    You cannot pipe objects to Write-DataTable
.OUTPUTS
None
    Produces no output
.EXAMPLE
$dt = Invoke-Sqlcmd2 -ServerInstance "Z003\R2" -Database pubs "select *  from authors"
Write-DataTable -ServerInstance "Z003\R2" -Database pubscopy -TableName authors -Data $dt
This example loads a variable dt of type DataTable from query and write the datatable to another database
.NOTES
Write-DataTable uses the SqlBulkCopy class see links for additional information on this class.
Version History
v1.0   - Chad Miller - Initial release
v1.1   - Chad Miller - Fixed error message
.LINK
http://msdn.microsoft.com/en-us/library/30c3y597%28v=VS.90%29.aspx
#>

function Write-DataTable
{
    [CmdletBinding()]
    param(
    [Parameter(Position=0, Mandatory=$true)] [string]$ServerInstance,
    [Parameter(Position=1, Mandatory=$true)] [string]$Database,
    [Parameter(Position=2, Mandatory=$true)] [string]$TableName,
    [Parameter(Position=3, Mandatory=$true)] $Data,
    [Parameter(Position=4, Mandatory=$false)] [string]$Username,
    [Parameter(Position=5, Mandatory=$false)] [string]$Password,
    [Parameter(Position=6, Mandatory=$false)] [Int32]$BatchSize=50000,
    [Parameter(Position=7, Mandatory=$false)] [Int32]$QueryTimeout=0,
    [Parameter(Position=8, Mandatory=$false)] [Int32]$ConnectionTimeout=15
    )
    
    $conn=new-object System.Data.SqlClient.SQLConnection

    if ($Username)
    { $ConnectionString = "Server={0};Database={1};User ID={2};Password={3};Trusted_Connection=False;Connect Timeout={4}" -f $ServerInstance,$Database,$Username,$Password,$ConnectionTimeout }
    else
    { $ConnectionString = "Server={0};Database={1};Integrated Security=True;Connect Timeout={2}" -f $ServerInstance,$Database,$ConnectionTimeout }

    $conn.ConnectionString=$ConnectionString

    try
    {
        $conn.Open()
        $bulkCopy = new-object ("Data.SqlClient.SqlBulkCopy") $connectionString
        $bulkCopy.DestinationTableName = $tableName
        $bulkCopy.BatchSize = $BatchSize
        $bulkCopy.BulkCopyTimeout = $QueryTimeOut
        $bulkCopy.WriteToServer($Data)
        $conn.Close()
    }
    catch
    {
        $ex = $_.Exception
        Write-Error "$ex.Message"
        continue
    }

} #Write-DataTable

#region variables - Database
## Servers
##**********************************************
$Server = "SLCDB16DW-D"

##Databases
##**********************************************
$Database = "SLCoDW_Staging"

##TableName
##**********************************************
#$TB_AssessorRoll = "AssessorRoll"
$Table = "Z_BIG_ALLEN"

##Schema
##**********************************************
$SchemaName = "dbo"

$UserName = "TalendSvc"

$Password = "Q*hu6aRUth6druwabe"
#endregion

#region variables
$EmployeeID = ""
$Email = "" 
$Division = ""
$Department = ""
#endregion

#############################################################################################################################################################################################################
CLEAR-HOST

$StartTime = [System.Datetime]::Now
Write-Host "Start Time: $StartTime"
""

#region Import-Modules

Import-Module ActiveDirectory
Import-Module SQLServer
#endregion


$ADUser  = Get-ADUser -Properties * -Filter {ObjectClass -eq "user"}; {Enabled -eq 'True'} | SELECT EmployeeID,UserPrincipalName,Division,Department 

#region datatable
#Create datatable
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    $dt = New-Object -TypeName System.Data.DataTable -ArgumentList "TableName"
    $col1 = New-Object system.Data.DataColumn EmployeeID, ([string])
    $col2 = New-Object system.Data.DataColumn Email, ([string])
    $col3 = New-Object system.Data.DataColumn Division, ([string])
    $col4 = New-Object system.Data.DataColumn Department,([string])
  

    $dt.Columns.Add($col1)
    $dt.Columns.Add($col2)
    $dt.Columns.Add($col3)
    $dt.Columns.Add($col4)
   
#Populate datatable
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

foreach ($AD in $ADUser)
    { 
        $row = $dt.NewRow()
        if($AD.EmployeeID -eq $NULL -OR $AD.EmployeeID -eq  "") {$row.EmployeeID = [string]$EmployeeID} else {$row.EmployeeID = [string]$AD.EmployeeID}
        if($AD.UserPrincipalName -eq $NULL -OR $AD.UserPrincipalName -eq  "") {$row.Email = [string]$Email} else {$row.Email = [string]$AD.UserPrincipalName}
        if($AD.Division -eq $NULL -OR $AD.Division -eq  "") {$row.Division = [string]$Division} else {$row.Division = [string]$AD.Division}
        if($AD.Department -eq $NULL -OR $AD.Department -eq  "") {$row.Department = [string]$Department} else {$row.Department = [string]$AD.Department}
        $dt.Rows.Add($row)
    }
#endregion


 Write-DataTable -ServerInstance $Server -Database $Database -TableName $Table -Data $dt 
 

$EndTime = [System.Datetime]::Now
Write-Host "End Time: $EndTime"
