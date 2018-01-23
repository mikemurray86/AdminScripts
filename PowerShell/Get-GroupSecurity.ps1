<# 
.SYNOPSIS
This Script will copy relevant user information.

.DESCRIPTION
this takes a Windows Group object and collects the SID information for the group and all groups that 
it belongs to. It uses this information to compile a list of NTFS access permissions to either a specified location
or by default it will collect information on the S:\ drive. 

The output of this command is a powershell object that contains the file permissions and groups that 
the it belongs to. 

This Script relies on the Active Directory and NTFSSecurity modules to run. Please ensure they are available prior
to running this.

.PARAMETER GroupName
This is the group account that will be checked. It will accept pipelined input or can be called with the -group switch

.PARAMETER SharePath
this is the location the command will check NTFS permissions for.

.Notes 
Script: Get-GroupSecurity.ps1  
Author: Mike Murray 
Last Edit: 12/19/2016
Comments: This is a very slow script. 
     
#> 

#Requires -Version 3.0
#Requires -Modules ActiveDirectory, NTFSSecurity

[cmdletBinding()]
[OutputType("PSCustomObject[]")]

Param(
    [Parameter(Mandatory = $True,ValueFromPipelineByPropertyName = $True)]
    [ValidateNotNullOrEmpty()]
    [Alias("Group")]
    [string[]]$GroupName,
    [string]$SharePath
    )

Begin{
        Write-Progress -Activity "Collecting Files"
    #This command uses cmdlets from the NTFSSecurity module. for portability I would like to remove this later.
    $Files = Get-ChildItem2 $SharePath -Recurse | 
             Get-NTFSInheritance | Where-Object{ $_.AccessInheritanceEnabled -eq $False}
    $Files += Get-NTFSInheritance $SharePath
    Write-Progress -Activity "Collecting Files" -Status "Done" -Completed
}

Process{
    foreach( $Group in $GroupName){
        #There are easier ways to get the SID but the below commands account for an edge case where the SID has changed.
        $objNTGroup = New-Object System.Security.Principal.NTAccount($Group)
        $objGroup = [pscustomobject]@{SID=$objNTGroup.Translate([System.Security.Principal.SecurityIdentifier])}

        Write-Verbose "Collected user: $Group SID as: $($objGroup.SID.Value)"

        $objADGroup = Get-ADGroup -Identity $Group -Properties * #TODO Need the right cmdlet here... 
        Add-Member -InputObject $objGroup -NotePropertyName Groups -NotePropertyValue $($objADGroup.memberof | Get-ADGroup)
        $grpSID = $($objADGroup.Memberof | Get-ADGroup).sid.value
        $grpSID += $objGroup.SID.Value
        Add-Member -InputObject $objGroup -NotePropertyName SIDCollection -NotePropertyValue $grpSID
        Add-Member -InputObject $objGroup -NotePropertyName Name -NotePropertyValue $objADGroup.Name

        $grpPerm = @()

        # collecting file permissions
        foreach($file in $files){
            Write-Progress -Activity "Checking Rights" -Status "File: $($File.FullName)"
                foreach($SID in $grpSID){
                    $perm = Get-NTFSAccess -Path $file.FullName -Account $SID
                    if($perm){
                        $grpPerm += $perm
                        switch -Wildcard ($(Get-NTFSAccess -Path $File.FullName -Account $SID).AccessRights){
                            "*FullControl*" { $Full += $File.FullName + '; '}
                            "*ReadAndExecute*" {$RE += $file.FullName + '; '}
                            "*Modify*" { $Modify += $File.FullName + '; '}
                            "*Read*" { $Read += $File.FullName + '; '}
                            "*Write*" {$Write += $File.FullName + '; '}
                            "*List*" { $List += $File.FullName + '; '}
                            default { $Other += $File.FullName + '; '}
                        }    
                    }
                } 
        }
        Write-Progress -Activity "Checking Rights" -Status "Done" -Completed
        #now that we have the permissions we assign them to the correct properties.
        Add-Member -InputObject $objGroup -NotePropertyName FullControlPerm -NotePropertyValue $Full
        Add-Member -InputObject $objGroup -NotePropertyName ReadAndExecutePerm -NotePropertyValue $RE
        Add-Member -InputObject $objGroup -NotePropertyName ModifyPerm -NotePropertyValue $Modify
        Add-Member -InputObject $objGroup -NotePropertyName ReadPerm -NotePropertyValue $Read
        Add-Member -InputObject $objGroup -NotePropertyName WritePerm -NotePropertyValue $Write
        Add-Member -InputObject $objGroup -NotePropertyName ListPerm -NotePropertyValue $List
        Add-Member -InputObject $objGroup -NotePropertyName OtherPerm -NotePropertyValue $Other
        if($grpPerm){
            Add-Member -InputObject $objGroup -NotePropertyName AllPerm -NotePropertyValue $grpPerm
        }
        else{
            Add-Member -InputObject $objGroup -NotePropertyName AllPerm -NotePropertyValue 'None' 
        }
        #output the user object
        $objGroup
    }
}