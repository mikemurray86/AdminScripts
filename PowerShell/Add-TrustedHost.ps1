<# 
.SYNOPSIS
	This adds an entry to the local trusted hosts table
.DESCRIPTION
	This saves the current trusted hosts table and adds a new entry
.PARAMETER Computername
	The computer to add to the trusted hosts
.EXAMPLE
	Add-TrustedHost -computername 'something'

    This would add a computer named something to the trusted hosts list
.Notes 
    Script:
    Author:
    Last Edit:
    Comments: 

.Link 
     
#>

param(
    [Parameter(Mandatory=$true)]
    [string[]]$computername
)

process{
    foreach($computer in $computername){
        $trustedhosts = Get-ChildItem WSMan:\localhost\Client\TrustedHosts
        Set-Item WSMan:\localhost\Client\TrustedHosts -Value ($trustedhosts + ",$computer")
    }
}