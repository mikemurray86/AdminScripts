<# 
.SYNOPSIS
	a tool to collect logon and logoff events
.DESCRIPTION
	This checks the event logs for a record of all the logon and logoff events on a computer
.PARAMETER start
	the time to start looking in the logs 
.PARAMETER stop
    the time to stop looking in the logs
.PARAMETER user
    the account to check login records for
.EXAMPLE
	get-logonevents -Start $((get-date).AddDays(-14) -user 'Test'

    This would get the login and lock events by the Test user for the last 14 days.
.Notes 
    Script: Get-LogonEvents
    Author: Mike Murray

.Link 
     
#>

[cmdletbinding()]

param(
    [datetime]$start = $((Get-Date).AddDays(-14)),
    [datetime]$stop = $(Get-Date),
    [string]$user,
    [string]$computername = $env:COMPUTERNAME
)

$filter = @{ LogName   = 'Security'
             ID        = '4624','4647','4800'
             StartTime = $start
             EndTime   = $stop
           }

$events = Invoke-Command -ComputerName $computername -ScriptBlock { Get-WinEvent -FilterHashtable $using:filter }
$unlock = @()
$login  = @()
$remote = @()
$cached = @()
$logoff = @()
$lock   = @()

foreach($event in $events){
    if($event.ID -eq '4647'){
        if($event.Properties[1].Value -eq $user){
            Write-Verbose 'Found Logoff event'
            $logoff += [string]$event.TimeCreated
        }
        continue 
    }

    if($event.ID -eq '4800'){
        if($event.Properties[1].Value -eq $user){
            Write-Verbose 'Found Lock event'
            $lock += [string]$event.TimeCreated
        }
        continue
    }
    if($event.ID -eq '4624'){
        if($event.Properties[5].value -eq $user){
            switch($event.properties[8].value){
                '7'  { $unlock += [string]$event.TimeCreated }
                '2'  { $login += [string]$event.TimeCreated }
                '10' { $remote += [string]$event.TimeCreated }
                '11' { $cached += [string]$event.TimeCreated }
            }
        }
    }
}

[pscustomobject]@{Unlock=$unlock;Login=$login;Remote=$remote;Cached=$cached;Logoff=$logoff;Lock=$lock}
