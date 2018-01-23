<#
.SYNOPSIS
    Sets the thumbnail photo attribute in AD
.PARAMETER $File
    An optional file containing usernames to update
.PARAMETER $User
    The user account to update.
.PARAMETER $Photo
    The photo to set
.EXAMPLE
    Set-ADPhoto -User 'someone' -Photo 'C:\temp\pic.jpg'
    Sets the thumbnail photo for the someone user to pic.jpg
.NOTES
    Notes
.LINK
    https://social.technet.microsoft.com/wiki/contents/articles/19028.active-directory-add-or-update-a-user-picture-using-powershell.aspx
#>

#Requires -module ActiveDirectory

[cmdletbingind()]

param(
    [Parameter(Mandatory = $True, ParameterSetName = 'Single')]
    [string]$User,
    [Parameter(Mandatory = $True, ParameterSetName = 'Multiple')]
    [string]$File,
    [Parameter(Mandatory = $True)]
    [string]$Photo
)
begin{
    $image = [byte[]](Get-Content -Path $Photo -Encoding Byte)
}
Process{
    if($PSBoundParameters.ContainsKey('User')){
        Set-ADUser -Identity $User -Replace @{thumbnailPhoto=$image}
    }
    else{
        $people = Import-Csv -Path $File
        foreach($person in $people){
            Set-ADUser -Identity $person.UserName -Replace @{thumbnailPhoto=$image}
        }
    }
}
End{}